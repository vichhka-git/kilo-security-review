---
name: security-review
description: Comprehensive security vulnerability analysis - matches Claude Code /security-review methodology with parallel agent execution, false positive filtering, and HackerOne cross-reference
version: 3.6.0
author: security-review
tags: [security, vulnerability, SAST, bug-bounty, AI]
tools: [Bash, Read, Glob, Grep, call_omo_agent]
---

# Security Review Skill - v3.0.0

You are a senior security engineer. Your goal is comprehensive security vulnerability analysis.

## Key Difference from v2.x

v3.0 uses **parallel agent execution** and **false positive filtering** - matching Claude Code's methodology.

## Objective

Perform comprehensive security review to identify HIGH-CONFIDENCE vulnerabilities with real exploitation potential.

---

## Phase 1: Repository Context Research

**IMPORTANT**: Clone fresh HackerOne reports for each scan to get latest data:

```bash
# Clone or update HackerOne reports (run fresh each time for latest data)
cd ~/.config/kilo/skills/security-review/h1-reports

# Smart update - git pull if exists, else clone
if [ -d ".git" ]; then
    git pull origin master 2>/dev/null || echo "Already up to date"
else
    # First time - clone
    git clone --depth 1 https://github.com/reddelexc/hackerone-reports.git .
fi
```

Before analyzing, understand the codebase:

1. **Map directory structure:**
```bash
ls -la
Glob "**/*"
```

2. **Identify technologies:**
```bash
ls -la | grep -E "package.json|requirements.txt|go.mod|Cargo.toml|pom.xml|*.csproj|composer.json"
```

3. **Identify frameworks & security libraries:**
- What web frameworks? (Express, Flask, Django, Gin, Spring)
- What auth is used? (JWT, Session, OAuth)
- What databases? (SQL, NoSQL)

4. **Map trust boundaries:**
- Where does client trust server?
- Where does server trust client?
- What crosses network unencrypted?

---

## Phase 2: Parallel Vulnerability Scanning

Launch MULTIPLE parallel searches for different vulnerability categories:

### Agent 1: Input Validation Vulnerabilities
- SQL injection (string concatenation in queries)
- Command injection (exec, spawn, system calls)
- XXE injection (XML parsing)
- Template injection (Jinja2, Handlebars)
- NoSQL injection
- Path traversal (file operations with user input)

**Search patterns:**
```
grep -rn "SELECT.*+|INSERT.*+|UPDATE.*+|DELETE.*+" --include="*.py" --include="*.js" --include="*.ts"
grep -rn "exec\(|spawn\(|system\(|os\.system" --include="*.py" --include="*.js" --include="*.go"
grep -rn "open\(|read\(|file" --include="*.py" --include="*.js" | grep -v "test"
```

### Agent 2: Authentication & Authorization
- Authentication bypass logic
- Privilege escalation paths
- Session management flaws
- JWT vulnerabilities (no expiry, weak secret, algorithm confusion)
- Authorization bypasses (IDOR, BOLA)
- Mass Assignment (arbitrary field injection)
- Weak PIN/password reset mechanisms
- File upload validation bypasses

**Search patterns:**
```
# Mass Assignment
grep -rn "for.*key.*in.*data|for.*k.*v.*items|\.update\(" --include="*.py" --include="*.js"
grep -rn "is_admin|role|permission" --include="*.py" | grep -v "check\|verify"

# Weak PIN/password reset
grep -rn "randint.*999|random.*pin|pin.*=" --include="*.py"
grep -rn "forgot.*password|reset.*pin" --include="*.py"

# File upload
grep -rn "file\.save|upload|filename" --include="*.py" | grep -v "secure_filename\|validate"

# JWT issues
grep -rn "jwt\.|JWT" --include="*.py" --include="*.js"
grep -rn "session|cookie|token" --include="*.py" --include="*.js" | grep -v "test"

# Routes without auth
grep -rn "@app.route|def " --include="*.py" | grep -v "auth\|verify\|token"
```

### Agent 3: Secrets & Cryptography
- Hardcoded API keys, passwords, tokens
- Weak crypto (MD5, SHA-1, DES)
- Improper key storage
- Certificate validation bypasses

**Search patterns:**
```
grep -rnE "(api[_-]?key|password|secret|token)\s*=\s*['\"]" --include="*.py" --include="*.js" --include="*.java"
grep -rnE "hashlib\.(md5|sha1)|Crypto\.Cipher" --include="*.py"
grep -rn ".env|DATABASE_URL|JWT_SECRET|SECRET_KEY" --include="*.py" --include="*.js"
```

### Agent 4: Injection & Code Execution
- Remote code execution (deserialization)
- Pickle/YAML deserialization vulnerabilities
- Eval injection
- XSS (reflected, stored, DOM)

**Search patterns:**
```
grep -rn "pickle\.|yaml\.load|eval\(|exec\(" --include="*.py"
grep -rn "dangerouslySetInnerHTML|bypassSecurityTrust" --include="*.ts" --include="*.tsx"
grep -rn "innerHTML|\.html\(" --include="*.js" --include="*.ts"
```

### Agent 5: Data Exposure
- Sensitive data logging
- PII handling violations
- API data leakage
- Debug information exposure

**Search patterns:**
```
grep -rn "console\.log\|print\(|logger" --include="*.py" --include="*.js" --include="*.ts"
grep -rn "debug\|trace\|error" --include="*.py" | grep -E "password|token|secret"
grep -rn "return.*error|jsonify.*error" --include="*.py"
```

### Agent 6: Mobile-Specific (Android/iOS)

**Android patterns:**
```
# Insecure data storage
grep -rn "SharedPreferences|MODE_PRIVATE" --include="*.java" --include="*.kt"
grep -rn "putString.*password|putString.*token|putString.*secret" --include="*.java" --include="*.kt"

# Manifest security settings
grep -rn "allowBackup|debuggable|usesCleartextTraffic|exported" --include="AndroidManifest.xml"

# Hardcoded secrets in code
grep -rn "password=|secret=|key=|JWT|api[_-]?key" --include="*.java" --include="*.kt"

# Certificate pinning
grep -rn "pinning|TrustManager|HostnameVerifier" --include="*.java" --include="*.kt" | grep -v "true"

# ProGuard/R8 disabled
grep -rn "minifyEnabled|proguard" --include="build.gradle" | grep -v "true"
```

**iOS patterns:**
```
grep -rn "UserDefaults" --include="*.swift"
grep -rn "NSAppTransportSecurity|ATS" --include="*.plist"
grep -rn "Keychain" --include="*.swift"
```

---

## Phase 3: Vulnerability Assessment

For each finding, assess:

1. **Exploitability**: Can this be exploited? What's the attack path?
2. **Impact**: What's the worst case? Data breach? RCE? Account takeover?
3. **Confidence**: Rate 1-10
   - 7-10: Report it (clear vulnerability pattern)
   - 4-6: Flag for manual review
   - 1-3: Skip (too speculative)

---

## Phase 4: False Positive Filtering

**EXCLUDE these findings:**
- Denial of Service (DOS) vulnerabilities
- Rate limiting concerns
- Theoretical issues without clear attack path
- Memory safety issues in memory-safe languages (Rust, Go)
- Unit test files
- Log spoofing concerns
- Lack of audit logs
- Lack of hardening measures (not a vulnerability)

**ASSUME SAFE:**
- Environment variables (trusted)
- UUIDs (unguessable)
- Client-side validation (server handles it)
- React/Angular XSS (unless dangerouslySetInnerHTML)
- Path-only SSRF (must control host/protocol)

---

## Phase 5: Comprehensive Output

For each CONFIRMED vulnerability, provide a detailed report matching professional security review standards:

```
# [VULN #X] [Type] - `file:line`

| Field | Detail |
|---|---|
| **Severity** | 🔴 CRITICAL / 🟠 HIGH / 🟡 MEDIUM / 🔵 INFO |
| **OWASP Category** | [e.g., A03:2021 - Injection] |
| **CVSS Score** | [0.0 - 10.0] |
| **Location** | `file:line` |
| **Confidence** | [7-10]/10 |

**Description**
[Brief description of the vulnerability]

**Vulnerable Pattern**
```[language]
// Show the actual vulnerable code
```

**Impact**
[Real-world impact - what can an attacker achieve?]

**Exploitation**
```bash
# Show how to exploit this vulnerability
```

**Remediation**
- Step 1 to fix
- Step 2 to fix
- Step 3 to fix

**HackerOne Cross-Reference**
- [Similar report on H1] - [bounty amount]
- [Another similar report] - [bounty amount]

---

## CVSS Scoring Reference

Assign CVSS scores based on impact:

| Vulnerability Type | Typical Score | Rationale |
|-------------------|---------------|-----------|
| SQL Injection (auth bypass) | 9.8 | Network exploit, no auth, full compromise |
| Hardcoded JWT/secret | 9.1 | Extract from APK, forge tokens |
| IDOR (financial) | 8.5 | Access any user's financial data |
| Auth bypass (unauthenticated) | 8.6 | No login required |
| Hardcoded password in code | 7.5 | Easy to find, no exploit needed |
| Insecure storage (SharedPrefs) | 7.1 | Requires physical/ADB access |
| Cleartext HTTP | 7.5 | Network interception possible |
| Debug mode enabled | 6.5 | Information disclosure |
| Missing rate limiting | 5.3 | DoS possible |

**Severity Thresholds:**
- CRITICAL: 9.0 - 10.0
- HIGH: 7.0 - 8.9
- MEDIUM: 4.0 - 6.9
- LOW: 0.1 - 3.9
- INFO: 0.0
```

## Summary Output Format

```
## Security Review Summary

### Findings
| Severity | Count |
|----------|-------|
| CRITICAL | X    |
| HIGH     | X    |
| MEDIUM   | X    |
| LOW      | X    |

### By Category
| Category | Count |
|----------|-------|
| SQL Injection | X |
| Auth Bypass   | X |
| ...           | X |

### Top Exploitable
1. [Finding 1]
2. [Finding 2]
3. [Finding 3]

### Recommendations
1. Fix [Critical]
2. Fix [High]
3. Fix [Medium]
```

---

## Notes

- **MINIMIZE NOISE**: Better to miss theoretical issues than flood with false positives
- **FOCUS ON IMPACT**: Prioritize vulnerabilities leading to data breach, RCE, or auth bypass
- **PARALLEL IS FASTER**: Launch multiple grep searches simultaneously
- **MANUAL VERIFY**: Read the actual code to confirm vulnerability before reporting

---

## Phase 6: HackerOne Cross-Reference (OPTIONAL)

When you find a vulnerability, cross-reference with REAL HackerOne reports to:

1. **Validate** - Confirm the vulnerability type is exploitable
2. **Get context** - See what similar issues paid
3. **Generate payload ideas** - Learn from real PoCs

### HackerOne Reports Location
```
/home/kali/Downloads/hackerone-reports/tops_by_bug_type/
```

### Mapping Vulnerability Types to Files

| Vulnerability | HackerOne File |
|--------------|----------------|
| SQL Injection | `TOPSQLI.md` |
| XSS | `TOPXSS.md` |
| IDOR | `TOPIDOR.md` |
| SSRF | `TOPSSRF.md` |
| RCE | `TOPRCE.md` |
| XXE | `TOPXXE.md` |
| CSRF | `TOPCSRF.md` |
| Business Logic | `TOPBUSINESSLOGIC.md` |
| Account Takeover | `TOPACCOUNTTAKEOVER.md` |
| Auth Bypass | `TOPAUTH.md` |
| Authorization | `TOPAUTHORIZATION.md` |
| Open Redirect | `TOPOPENREDIRECT.md` |
| Subdomain Takeover | `TOPSUBDOMAINTAKEOVER.md` |
| Race Condition | `TOPRACECONDITION.md` |
| File Upload | `TOPUPLOAD.md` |
| Information Disclosure | `TOPINFODISCLOSURE.md` |
| REST API | `TOPAPI.md` |
| GraphQL | `TOPGRAPHQL.md` |
| HTTP Request Smuggling | `TOPREQUESTSMUGGLING.md` |
| SSTI | `TOPSSTI.md` |
| Mobile | `TOPMOBILE.md` |
| Clickjacking | `TOPCLICKJACKING.md` |

### Example Usage

When you find an IDOR vulnerability, read the TOPIDOR.md file:
```
Read ~/.config/kilo/skills/security-review/h1-reports/tops_by_bug_type/TOPIDOR.md
```

Then include in your report:
```
### HackerOne Cross-Reference
Similar IDOR vulnerabilities that paid:
- [Report #1234] - $5000 - Company X paid for IDOR on /api/user/{id}
- [Report #5678] - $3000 - Company Y paid for IDOR on /api/balance
```

### Bug Bounty Value Assessment

Use HackerOne data to assess if your finding is valuable:
- Check if similar issues paid in your target's program
- Look at bounty ranges for that vulnerability type
- Identify if the target accepts that category
