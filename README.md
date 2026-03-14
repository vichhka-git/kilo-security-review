# Kilo Security Review Skill

AI-powered security vulnerability scanner for Kilo CLI with three-layer analysis:
1. **Semgrep** - Fast pattern matching
2. **CodeQL** - Deep semantic analysis  
3. **YOU (the AI)** - Analyze findings, find logic flaws, identify attack chains

## Features

- 🔍 **Bug Bounty Focused** - Designed to find exploitable vulnerabilities
- 🏴‍☠️ **IDOR Detection** - Insecure Direct Object Reference scanning
- ⚡ **SSRF Detection** - Server-Side Request Forgery scanning
- 🔑 **Secret Detection** - Hardcoded API keys, passwords, tokens
- 🧠 **Direct Analysis** - YOU analyze results, no context loss
- 🎯 **Attack Chain Analysis** - Identify how vulnerabilities can be chained
- ⚡ **Single Session** - Complete scan without re-running

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

## Three-Layer Analysis

### Layer 1: Semgrep (Fast Pattern Scan)
- OWASP Top 10 detection
- Known vulnerability patterns
- CWE coverage

### Layer 2: CodeQL (Deep Semantic)
- Data flow analysis
- Taint tracking
- Custom query support

### Layer 3: YOU Analyze (Direct)
After Layers 1 & 2 complete:
- YOU parse the results
- YOU use grep/ast_grep to find what tools missed
- YOU identify attack chains
- YOU provide the final report

No context loss - everything stays in one session!

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
