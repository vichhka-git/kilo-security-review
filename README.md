# Kilo Security Review Skill

A full-stack security review skill for **Kilo CLI and OpenCode** that produces **pentest-grade reports** — not
checklist output. Every finding includes a working exploit PoC, real code fix, CVSS 3.1
score, and a HackerOne bug-bounty reference showing real-world payout for that class of bug.

---

## What makes this different

Most security skills are static checklists. They tell the AI to "look for SQL injection" —
which causes false positives on server-controlled config values that look like injection sinks
but aren't attacker-reachable.

This skill teaches the AI **how to think** about security:

| Approach | Checklist skills | This skill |
|---|---|---|
| Methodology | Pattern-match forward | Sink-backward data flow tracing |
| False positives | High — flags server config as SSRF | Low — confirms attacker control before reporting |
| PoC requirement | Optional / vague | Mandatory for every HIGH+ finding |
| Fixes | Generic advice ("use parameterized queries") | Exact replacement code, paste-ready |
| H1 integration | ❌ | ✅ Real disclosed reports + payout amounts |
| CVSS scoring | Inconsistent | CVSS 3.1 on every Critical and High |
| Reference architecture | Single file | 5 stack-specific reference files, loaded on demand |
| Coverage | Web only or Android only | Web · API · Android · iOS · React Native · Cloud/IaC |

---

## Features

- 🎯 **Confidence system** — HIGH / MEDIUM / LOW gates what gets reported. No false positives from server-side config values.
- 🔍 **Sink-backward analysis** — finds dangerous sinks first, then traces upstream to confirm attacker control
- 💥 **Mandatory PoCs** — every HIGH+ finding ships with a working `curl` / `adb` / `grep` command
- 🔗 **HackerOne references** — each finding links to a real disclosed H1 report showing payout
- 📊 **CVSS 3.1 scoring** — professional severity ratings with full vector string
- 🔑 **Git history scanning first** — committed `.env` files and keys are caught before any code review
- 🧰 **6 reference files** — web-api, android, ios, cloud-infra, secrets-and-config, hackerone-reports — loaded only for the relevant stack
- 📱 **Full mobile coverage** — Android (APK, SharedPreferences, Manifest) + iOS (Keychain, ATS, UserDefaults) + React Native bundle extraction
- 🏗️ **Cloud/IaC** — Docker, Kubernetes, AWS IAM, S3, Terraform, CI/CD pipelines
- 📄 **Professional report format** — executive summary + per-finding tables + OWASP matrix + remediation roadmap

---

## Requirements

- **Kilo CLI** — [kilo.ai/cli](https://kilo.ai/cli) — recommended
- **OpenCode** — [opencode.ai](https://opencode.ai/) — supported
- **Optional tools** (auto-detected, skipped gracefully if missing):
  - `gitleaks` — git history secret scanning
  - `semgrep` — SAST pattern scanning
  - `bandit` — Python SAST
  - `trivy` — dependency + container scanning
  - `gosec` — Go SAST

---

## Installation

### Option A — Kilo CLI (recommended)

```bash
git clone https://github.com/vichhka-git/kilo-security-review.git
cd kilo-security-review
./install.sh
```

The installer detects your environment and copies the skill to the right location:
- Kilo CLI → `~/.kilocode/skills/kilo-security-review/`
- OpenCode → `~/.opencode/skills/kilo-security-review/`

### Option B — Manual Install

```bash
# For Kilo CLI
mkdir -p ~/.kilocode/skills/kilo-security-review
cp -r SKILL.md references/ ~/.kilocode/skills/kilo-security-review/

# For OpenCode
mkdir -p ~/.config/opencode/skills/kilo-security-review
cp -r SKILL.md references/ ~/.config/opencode/skills/kilo-security-review/
```

---

## Usage

### Kilo CLI

```bash
# Review a local project
kilo run --dir /path/to/project "Security review for bug bounty"

# Review a specific file
kilo run "Security review of auth.py" < src/auth.py

# Focused scan
kilo run --dir . "Check for SQL injection and SSRF"
```

---

## Output Example

```
# Security Review: vulnbank-api

| Field     | Value                                    |
|-----------|------------------------------------------|
| Target    | backend/app.py                           |
| Stack     | Python · Flask · PostgreSQL              |
| Date      | 2026-03-15                               |
| Findings  | 🔴 2 Critical · 🟠 1 High · 🟡 2 Medium |

## Executive Summary
The backend API exposes a SQL injection vulnerability in the login endpoint
that enables full authentication bypass and database exfiltration without
credentials. A committed .env file containing the JWT secret and database
password compounds this to a complete system compromise reachable by anyone
who can clone the repository.

---

## Findings

### [VULN-001] SQL Injection in Login Endpoint — 🔴 CRITICAL

| Field        | Value                                                                  |
|--------------|------------------------------------------------------------------------|
| Location     | `backend/app.py:155`                                                   |
| CVSS 3.1     | 9.8 (AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H)                           |
| CWE          | CWE-89 — SQL Injection                                                 |
| OWASP        | A03:2021 Injection / API3:2023                                         |
| Confidence   | HIGH                                                                   |
| H1 Reference | [SQLi → $25k at Valve](https://hackerone.com/reports/383127) — $25,000 |

**What**
The login route concatenates `request.json['username']` directly into a SQL
string. No sanitisation, no parameterization.

**Why it matters**
Unauthenticated attacker can log in as any user including admin, and dump
the full users table including hashed passwords and active session tokens.

**Evidence**
```python
# backend/app.py:155 — username is request.json['username'], no sanitisation
query = f"SELECT * FROM users WHERE username='{username}' AND password='{password}'"
```

**Proof of Concept**
```bash
curl -X POST http://target:5000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin'\''--", "password": "x"}'
# Returns: {"token":"eyJhbGci...","is_admin":true,"balance":50000}
```

**Fix**
```python
from sqlalchemy import text
user = db.execute(
    text("SELECT * FROM users WHERE username = :u AND password_hash = :p"),
    {"u": username, "p": hash_password(password)}
).fetchone()
```
```

---

# Skill Architecture

```
kilo-security-review/
├── SKILL.md                      ← Core: 6-phase methodology, confidence system, report template
└── references/
    ├── secrets-and-config.md     ← Git scanning, secret strength, IaC patterns (always loaded)
    ├── web-api.md                ← Injection, auth, authz, CORS, business logic
    ├── android.md                ← Manifest flags, SharedPreferences, APK extraction, build config
    ├── ios.md                    ← ATS, Keychain vs UserDefaults, jailbreak, screenshot protection
    ├── cloud-infra.md            ← Docker, Kubernetes, AWS IAM, S3, CI/CD, Terraform
    └── hackerone-reports/        ← Local H1 bug bounty reports (git pull to update)
```

Reference files are loaded **on demand** — a web review only loads `web-api.md` and
`secrets-and-config.md`. An Android review loads `android.md` and `secrets-and-config.md`.
This keeps the context window clean and the review focused.

---

## The 6-Phase Methodology

| Phase | Name | What happens |
|---|---|---|
| 0 | Scope & Git History | Map entry points, scan git log for committed secrets |
| 1 | Automated Scanning | gitleaks, semgrep, bandit, trivy, dependency audits |
| 2 | Sink-Backward Analysis | Find sinks → trace upstream → confirm attacker control |
| 3 | Confidence Classification | HIGH / MEDIUM / LOW — gates what gets reported |
| 4 | PoC Requirement | Working exploit command mandatory for HIGH+ |
| 5 | Report | CVSS + CWE + OWASP + evidence + fix + roadmap |
| 6 | H1 Cross-Reference | Link each finding to a real paid bug-bounty report |

---

## OWASP Coverage

| Standard | Categories Covered |
|---|---|
| OWASP Top 10 (2021) | All 10 |
| OWASP API Security Top 10 (2023) | All 10 |
| OWASP Mobile Top 10 (2024) | All 10 |

---

## HackerOne Intelligence

Every HIGH+ finding links to a real disclosed HackerOne report for the same
vulnerability class. This answers "is this actually exploitable in the wild and
worth fixing?" with evidence rather than theory.

Reference database: [reddelexc/hackerone-reports](https://github.com/reddelexc/hackerone-reports)

---

## Contributing

Issues and PRs welcome. When adding a new vulnerability pattern to a reference
file, include:
1. The vulnerable code pattern with a `# FLAG` comment
2. The safe replacement with a `# SAFE` comment
3. The data-flow question that distinguishes real from theoretical
4. An H1 report link for that pattern

---

## Credits

- [HackerOne Disclosed Reports](https://github.com/reddelexc/hackerone-reports) — bug bounty intelligence
- [OWASP MSTG](https://owasp.org/www-project-mobile-security-testing-guide/) — mobile testing guidance
- [Semgrep Rules](https://semgrep.dev/r) — SAST pattern reference

---

## License

MIT — use it, improve it, share it.
