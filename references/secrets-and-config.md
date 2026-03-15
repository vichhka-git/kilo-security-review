# Secrets & Configuration Reference

## Git History Scanning — Always Run First

```bash
# Fast: check if any .env was ever committed
git log --all --full-history -- '*.env' '.env' '*.pem' '*.key' '*.p12' '*.pfx'

# If hits found, show content from a specific commit
git show <commit-sha>:backend/.env

# Thorough: scan entire history for high-entropy strings
trufflehog git file://. --only-verified --format json | jq '.SourceMetadata'

# Faster secret scan with gitleaks
gitleaks detect --source . --verbose --report-format json --report-path leaks.json

# Manual grep for common secret patterns
grep -rE '(password|passwd|secret|api_key|apikey|auth_token)\s*[:=]\s*["\x27][^"'\'']{8,}' \
  . --include='*.{py,js,ts,java,kt,swift,rb,go,env,yaml,yml,json,toml,ini,cfg}'

# JWT tokens anywhere in codebase
grep -rE 'eyJ[A-Za-z0-9._-]{20,}\.[A-Za-z0-9._-]{20,}\.[A-Za-z0-9._-]{20,}' .
```

## Committed Files to Flag Immediately

Any of these in the repo = Critical severity:
```
.env                     # DB credentials, API keys, JWT secrets
.env.production
*.pem / *.key / *.pfx   # TLS private keys or certificate stores
id_rsa / id_ecdsa        # SSH private keys
*.p12                    # iOS distribution certificates
credentials.json         # GCP service account keys
serviceAccountKey.json   # Firebase admin keys
secrets.json / secrets.yaml
config/database.yml      # Rails DB config with password
application-prod.properties  # Spring Boot production config
terraform.tfvars         # Terraform secrets
```

## .gitignore Audit

Check that these are excluded:
```gitignore
# Secrets
.env
.env.*
!.env.example  # template is OK
secrets/
*.pem
*.key
*.p12
id_rsa

# Build artifacts that embed secrets
android/app/google-services.json  # contains API keys
ios/GoogleService-Info.plist      # contains API keys
```

## Secret Strength Requirements

| Secret Type | Minimum Length | Generation |
|---|---|---|
| JWT signing secret | 256 bits (32 bytes) | `secrets.token_hex(32)` |
| API key | 128 bits (16 bytes) | `secrets.token_urlsafe(24)` |
| Session secret | 256 bits (32 bytes) | `secrets.token_hex(32)` |
| Database password | 128 bits | password manager random |
| Encryption key (AES-256) | 256 bits (32 bytes) | `os.urandom(32)` |

Dictionary words, company names, or anything in `rockyou.txt` → Critical.
Hashcat mode 16500 cracks HS256 JWTs against rockyou in seconds.

## Environment Variable Patterns (Correct)

```python
# Python — python-dotenv for local dev, real env vars in prod
import os
from dotenv import load_dotenv
load_dotenv()  # only loads if .env exists; no-op in prod

JWT_SECRET = os.environ["JWT_SECRET"]  # KeyError if not set — fail fast
DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///dev.db")  # with default for dev
```

```javascript
// Node.js
const jwtSecret = process.env.JWT_SECRET;
if (!jwtSecret) throw new Error("JWT_SECRET is required");
```

```kotlin
// Android — build config (for non-secret build-time values only)
// Never put secrets in BuildConfig — they end up in the DEX
buildConfigField("String", "API_BASE_URL", '"https://api.example.com"')

// Secrets should be fetched from auth server at runtime
```

## Cloud Secrets Management (Recommended for Production)

```python
# AWS Secrets Manager
import boto3
client = boto3.client("secretsmanager", region_name="us-east-1")
secret = client.get_secret_value(SecretId="prod/app/jwt-secret")
JWT_SECRET = json.loads(secret["SecretString"])["value"]

# Google Secret Manager
from google.cloud import secretmanager
client = secretmanager.SecretManagerServiceClient()
name = f"projects/{PROJECT_ID}/secrets/jwt-secret/versions/latest"
JWT_SECRET = client.access_secret_version(name=name).payload.data.decode("utf-8")

# HashiCorp Vault
import hvac
client = hvac.Client(url="https://vault.example.com", token=os.environ["VAULT_TOKEN"])
JWT_SECRET = client.secrets.kv.read_secret_version(path="app/jwt")["data"]["data"]["value"]
```

## Environment-Specific Config Separation

```
config/
├── settings_base.py     # shared, no secrets
├── settings_dev.py      # imports base, adds dev-only overrides
├── settings_prod.py     # imports base, reads all secrets from env vars
└── settings_test.py     # imports base, in-memory DB, fake secrets
```

Never use the same database, secret key, or API key across environments.

## Docker / Container Secrets

```yaml
# FLAG — secret in Dockerfile (persists in image layers)
ENV JWT_SECRET=supersecret123
RUN echo "password" > /root/.pgpass

# SAFE — use Docker secrets or runtime env vars
# docker-compose.yml
services:
  api:
    image: myapp:latest
    secrets:
      - jwt_secret
    environment:
      JWT_SECRET_FILE: /run/secrets/jwt_secret

secrets:
  jwt_secret:
    file: ./secrets/jwt_secret.txt  # excluded from repo
```

## IaC (Terraform) Secret Anti-Patterns

```hcl
# FLAG — secret in Terraform source
resource "aws_db_instance" "main" {
  password = "hardcoded_password"  # ends up in .tfstate (plaintext!)
}

# SAFE — use data source from secrets manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/password"
}
resource "aws_db_instance" "main" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

Note: `.tfstate` files contain all resource attributes in plaintext — ensure
state is stored encrypted (S3 + KMS or Terraform Cloud) and excluded from git.
