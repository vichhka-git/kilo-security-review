---
name: security-review
description: Comprehensive security vulnerability analysis - matches Claude Code /security-review methodology with parallel agent execution and false positive filtering
version: 3.0.0
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

**Search patterns:**
```
grep -rn "jwt\.|JWT" --include="*.py" --include="*.js"
grep -rn "session|cookie|token" --include="*.py" --include="*.js" | grep -v "test"
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
grep -rn "SharedPreferences|MODE_PRIVATE" --include="*.java" --include="*.kt"
grep -rn "allowBackup|debuggable|usesCleartextTraffic|exported" --include="AndroidManifest.xml"
grep -rn "password=|secret=|key=" --include="*.java" --include="*.kt"
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

For each CONFIRMED vulnerability, provide:

```
# Vuln: [Type] - `file:line`

* Severity: [CRITICAL/HIGH/MEDIUM]
* Category: [e.g., sql_injection, xss, auth_bypass]
* Confidence: [7-10]
* Description: [What the vulnerability is]
* Exploit Scenario: [How to exploit]
* Recommendation: [How to fix]
```

---

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
