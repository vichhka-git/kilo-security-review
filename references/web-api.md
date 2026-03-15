# Web & API Security Reference

## Injection — Confirm Attacker Control Before Reporting

### SQL Injection
```python
# FLAG — raw string concat, user-controlled
query = f"SELECT * FROM users WHERE name='{request.args['name']}'"

# FLAG — format string with user input
cursor.execute("SELECT * FROM users WHERE id=" + user_id)

# SAFE — parameterized
cursor.execute("SELECT * FROM users WHERE name = %s", (name,))

# SAFE — ORM
User.query.filter_by(name=name).first()
```
Confirm: Is the variable derived from `request.*`, URL params, headers, or
any data that crosses a trust boundary? If yes and there's no sanitisation
layer, flag it.

### Command Injection
```python
# FLAG
os.system(f"convert {filename} output.png")
subprocess.run(f"ffmpeg -i {user_path}", shell=True)

# SAFE
subprocess.run(["convert", filename, "output.png"], shell=False)
```

### SSRF
```python
# FLAG — user-controlled URL
requests.get(request.json['url'])
requests.get(f"http://{user_host}/data")

# SAFE — server-controlled config
requests.get(settings.WEBHOOK_URL)
requests.get(f"{settings.CDN_BASE}/{resource_id}")  # CHECK: is resource_id user-supplied?
```
Blocklist to check in SSRF fixes: `169.254.0.0/16` (AWS metadata), `10.0.0.0/8`,
`192.168.0.0/16`, `127.0.0.0/8`, `fd00::/8`, `file://` scheme.

### XSS
```javascript
// FLAG — direct innerHTML with user data
element.innerHTML = userComment;
document.write(req.query.name);
// React
<div dangerouslySetInnerHTML={{__html: userContent}} />

// SAFE
element.textContent = userComment;  // text node, not HTML
// React — just render normally
<div>{userContent}</div>  // React escapes by default
```
Django templates auto-escape — `{{ value }}` is safe. `{{ value|safe }}` is NOT.

### Path Traversal
```python
# FLAG
open(os.path.join(BASE, request.args['file']))
send_file(user_filename)

# SAFE
safe_path = os.path.realpath(os.path.join(BASE, filename))
if not safe_path.startswith(BASE):
    abort(400)
```

### Template Injection (SSTI)
```python
# FLAG — Jinja2 / Mako / Twig rendering user input
render_template_string(user_input)
Template(user_input).render()

# SAFE — always render from file, never from user string
render_template("safe_template.html", value=user_input)
```

---

## Authentication

### JWT Vulnerabilities
```python
# FLAG — algorithm confusion
jwt.decode(token, key, algorithms=["HS256", "RS256"])  # attacker can switch to HS256 + pubkey

# FLAG — none algorithm accepted
jwt.decode(token, options={"verify_signature": False})

# FLAG — weak secret (dictionary word, short string)
jwt.encode(payload, "secret", algorithm="HS256")

# SAFE — explicit algorithm, strong secret, verify exp
jwt.decode(token, settings.JWT_SECRET, algorithms=["HS256"])
# Secret: secrets.token_hex(64)  # 512-bit
# Always include: {"sub": uid, "exp": now + timedelta(minutes=15), "jti": uuid4()}
```

### Password Hashing
```python
# FLAG — fast hashes
hashlib.md5(password.encode()).hexdigest()
hashlib.sha1(password.encode()).hexdigest()
hashlib.sha256(password.encode()).hexdigest()  # fast, no work factor

# SAFE — bcrypt
import bcrypt
bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))

# SAFE — argon2
from argon2 import PasswordHasher
ph = PasswordHasher(time_cost=2, memory_cost=65536, parallelism=2)
ph.hash(password)
```

### Session Management
- Session ID regenerated on login? (`request.session.cycle_key()` in Django)
- HttpOnly + Secure + SameSite=Strict on session cookies?
- Absolute session timeout (e.g., 8 hours max regardless of activity)?

---

## Authorization

### BOLA / IDOR Pattern
```python
# FLAG — no ownership check
@app.get("/api/invoices/{invoice_id}")
def get_invoice(invoice_id: int, current_user = Depends(get_current_user)):
    return Invoice.get(invoice_id)  # Any user can read any invoice

# SAFE — ownership enforced
def get_invoice(invoice_id: int, current_user = Depends(get_current_user)):
    invoice = Invoice.query.filter_by(
        id=invoice_id,
        owner_id=current_user.id  # ← ownership check
    ).first_or_404()
    return invoice
```

### Mass Assignment
```python
# FLAG — Flask/Django accepting all request fields
user = User(**request.json)
user.save()

# SAFE — explicit allowlist
ALLOWED = {"name", "email", "phone"}
data = {k: v for k, v in request.json.items() if k in ALLOWED}
user = User(**data)
```

---

## API-Specific

### Rate Limiting (check on these endpoints always)
- `/login`, `/register`, `/forgot-password`, `/verify-otp`
- Any endpoint that sends email/SMS
- Any financial transaction endpoint

```python
# Flask-Limiter
@limiter.limit("10 per minute")
@app.route('/api/login', methods=['POST'])
def login(): ...
```

### CORS
```python
# FLAG — wildcard CORS with credentials
CORS(app, origins="*", supports_credentials=True)  # credentials + wildcard = invalid but dangerous

# SAFE
CORS(app, origins=["https://app.example.com"], supports_credentials=True)
```

### GraphQL-Specific
- Introspection enabled in production? (disable in prod)
- Depth limiting in place? (prevent deeply nested query DoS)
- Query complexity limits?
- Batch query abuse possible?

---

## Sensitive Data Exposure

### Logging
```python
# FLAG — tokens/passwords in logs
logger.info(f"Login: user={username}, password={password}")
logger.debug(f"Token: {token}")

# SAFE — log only non-sensitive identifiers
logger.info(f"Login attempt: user_id={user_id}")
```

### Error Handling
```python
# FLAG — stack traces in production response
@app.errorhandler(500)
def server_error(e):
    return str(e), 500  # leaks internal paths, libraries, code

# SAFE
def server_error(e):
    logger.exception("Internal error")
    return {"error": "Internal server error"}, 500
```

### Security Headers Checklist
Every HTTP response should include:
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'self'; ...
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=()
```

---

## Business Logic Patterns

### Numeric Validation
```python
# FLAG — no sign check on financial amounts
amount = request.json["amount"]
account.balance -= amount  # negative amount → self-credit

# SAFE
if not isinstance(amount, (int, float)) or amount <= 0:
    abort(400, "Amount must be positive")
if amount > account.balance:
    abort(400, "Insufficient funds")
```

### Race Conditions (TOCTOU)
```python
# FLAG — read-check-write without lock
balance = db.get_balance(user_id)
if balance >= amount:
    db.debit(user_id, amount)  # concurrent request can pass the check twice

# SAFE — atomic update with constraint
db.execute(
    "UPDATE accounts SET balance = balance - %s WHERE id = %s AND balance >= %s",
    (amount, user_id, amount)
)
if db.rowcount == 0:
    abort(400, "Insufficient funds")
```
