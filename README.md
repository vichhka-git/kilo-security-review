# Kilo Security Review Skill

AI-powered security vulnerability scanner for Kilo CLI - matches Claude Code /security-review methodology with HackerOne bug bounty intelligence.

## Features

- 🔍 **Comprehensive** - Full project security scan (not just git diffs)
- 🤖 **Parallel Scanning** - Multiple agents scan different vulnerability types simultaneously
- 🎯 **False Positive Filtering** - Excludes theoretical issues, focuses on real exploits
- 📊 **CVSS Scoring** - Professional severity ratings (0-10)
- 🔗 **HackerOne Integration** - Real bug bounty references with paid amounts
- 🏴‍☠️ **Bug Bounty Focus** - Find exploitable vulnerabilities worth money
- 📱 **Mobile Security** - Android & iOS specific checks
- ⚡ **Fast** - Smart caching, git pull for H1 updates
- 🆓 **FREE** - No paid subscriptions needed

## Comparison vs Claude Code

| Feature | Claude Code | Kilo Security Skill |
|---------|-------------|---------------------|
| Price | $20+/month | FREE |
| Project Scan | Partial | Full |
| H1 References | ❌ | ✅ Real bounties |
| CVSS Scores | ✅ | ✅ |
| Parallel Agents | ✅ | ✅ |
| Mobile Coverage | Partial | Full |

## Requirements

- [Kilo CLI](https://kilo.ai/cli) or [OpenCode](https://opencode.ai/)
- [Semgrep](https://semgrep.dev/) (optional, for pattern scanning)

## Installation

```bash
git clone https://github.com/vichhka-git/kilo-security-review.git ~/kilo-security-review
cd ~/kilo-security-review
./install.sh
```

## Usage

```bash
kilo run --dir /path/to/project --model kilo/kilo-auto/free "Security scan for bug bounty"
```

Or interactively:
```bash
kilocode
# Type: Run a security scan for bug bounty
```

## Output Format

```
## CRITICAL Vulnerabilities

| # | Vulnerability | CVSS | H1 Reference |
|---|---------------|------|---------------|
| 1 | SQL Injection (Login) | 9.8 | [Blind SQLi → RCE](https://hackerone.com/reports/592400) - $25,000 |
| 2 | Hardcoded JWT Token | 9.1 | [Access all auth tokens](https://hackerone.com/reports/158330) |

### [VULN #1] SQL Injection - backend/app.py:155

| Field | Detail |
|---|---|
| **Severity** | 🔴 CRITICAL |
| **CVSS 3.1** | 9.8 |
| **CWE** | CWE-89 |

**Code:**
```python
query = f"SELECT * FROM users WHERE username='{username}'"
```

**Exploitation:**
```
POST /login
username=admin' OR '1'='1
```

**Remediation:**
```python
query = "SELECT * FROM users WHERE username = %s"
```

**H1 Reference:** [SQL Injection at Valve](https://hackerone.com/reports/383127) - $25,000
```

## Methodology (6 Phases)

1. **Update H1 Reports** - Smart git pull (cached after first run)
2. **Parallel Scanning** - 6 agents scan different vuln types
3. **Vulnerability Assessment** - CVSS scoring, exploitability
4. **False Positive Filtering** - Remove theoretical issues
5. **H1 Cross-Reference** - Match findings to real bug bounties
6. **Report Synthesis** - Professional output with remediation

## Supported Languages

- JavaScript / TypeScript / React Native
- Python / Flask / Django
- Go, Java, Kotlin, C#, Ruby, PHP

## Credits

- [Kilo CLI](https://kilo.ai/cli) - AI agent framework
- [HackerOne Reports](https://github.com/reddelexc/hackerone-reports) - Bug bounty intelligence
