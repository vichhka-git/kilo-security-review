# Kilo Security Review Skill

AI-powered security vulnerability scanner for Kilo CLI - matches Claude Code /security-review methodology.

## Features

- 🔍 **Comprehensive** - Full project security scan (not just git diffs)
- 🤖 **Parallel Scanning** - Multiple agents scan different vulnerability types simultaneously
- 🎯 **False Positive Filtering** - Excludes theoretical issues, focuses on real exploits
- 📊 **Confidence Scoring** - Rate findings 1-10, report only 7+
- 🔒 **Mobile Security** - Android & iOS specific checks
- 🏴‍☠️ **Bug Bounty Focus** - Find exploitable vulnerabilities
- ⚡ **Fast** - Grep-based scanning (no external tools required)
- 🆓 **FREE** - No paid subscriptions needed

## Requirements

- [Kilo CLI](https://kilo.ai/cli) or [OpenCode](https://opencode.ai/)
- [Semgrep](https://semgrep.dev/) (for pattern scanning)
- [CodeQL](https://codeql.github.com/) (optional, for deep analysis)

## Installation

### Step 1: Install Security Tools

```bash
# Install Semgrep
pip install semgrep

# Install CodeQL (optional but recommended)
cd /tmp
curl -L -o codeql.zip https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip
unzip -o codeql.zip -d ~/.local/
echo 'export PATH="$HOME/.local/codeql:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Step 2: Clone & Install

```bash
git clone https://github.com/vichhka-git/kilo-security-review.git ~/kilo-security-review

# Run installer
cd ~/kilo-security-review
./install.sh
```

The installer will:
1. Install Semgrep (if not already installed)
2. Check for CodeQL
3. Create the config automatically
  }
}
```

## Usage

### Method 1: Interactive Chat

```bash
kilocode
```

Then type:
```
Run a security scan for bug bounty
```

### Method 2: Direct Command

```bash
kilocode run "Perform security vulnerability scan on this codebase"
```

### Method 3: With Specific Model

```bash
kilocode --model kilo/kilo-auto/free run "Security review for vulnerabilities"
```

## Methodology (5 Phases)

### Phase 1: Repository Context
- Map directory structure
- Identify technologies & frameworks
- Map trust boundaries

### Phase 2: Parallel Vulnerability Scanning
- Agent 1: Input Validation (SQLi, Command Injection, XXE)
- Agent 2: Auth & Authorization (JWT, Session, IDOR)
- Agent 3: Secrets & Crypto (Hardcoded, Weak Crypto)
- Agent 4: Injection & Code Execution (RCE, Pickle, XSS)
- Agent 5: Data Exposure (Logging, PII, Debug Info)
- Agent 6: Mobile (Android/iOS specific)

### Phase 3: Vulnerability Assessment
- Exploitability analysis
- Impact assessment
- Confidence scoring (1-10)

### Phase 4: False Positive Filtering
- Excludes DOS, rate limiting, theoretical issues
- Assumes safe: env vars, UUIDs, client-side validation

### Phase 5: Report Synthesis
- Structured output with severity & recommendations

## Output Example

```
## Bug Bounty Security Report

### Summary
- Critical: 2 | High: 5 | Medium: 8 | Low: 3

### Critical Findings

#### [CRITICAL] SQL Injection
- **File**: src/db/user.js:42
- **Type**: SQL Injection
- **Exploit**: Attacker can manipulate SQL query via user input
- **PoC**: `GET /api/users?id=' OR '1'='1`

#### [CRITICAL] IDOR - Vertical Privilege Escalation
- **File**: src/api/admin.js:15
- **Type**: Broken Access Control
- **Exploit**: Regular user can access admin endpoints by modifying userId

## AI Analysis
[Logic flaws and attack chains identified by AI]
```

## Supported Languages

- JavaScript / TypeScript
- Python
- Go
- Java
- C#
- Ruby
- PHP

## License

MIT License - Free to use, modify, and distribute.

## Credits

- [Semgrep](https://semgrep.dev/) - Pattern-based scanning
- [CodeQL](https://codeql.github.com/) - Semantic analysis
- [Kilo CLI](https://kilo.ai/cli) - AI agent framework
