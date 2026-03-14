# Kilo Security Review Skill

AI-powered security vulnerability scanner for Kilo CLI with three-layer analysis:
1. **Semgrep** - Fast pattern matching
2. **CodeQL** - Deep semantic analysis  
3. **AI Reasoning** - Logic flaw detection

## Features

- 🔍 **Bug Bounty Focused** - Designed to find exploitable vulnerabilities
- 🏴‍☠️ **IDOR Detection** - Insecure Direct Object Reference scanning
- ⚡ **SSRF Detection** - Server-Side Request Forgery scanning
- 🔑 **Secret Detection** - Hardcoded API keys, passwords, tokens
- 🧠 **AI Reasoning** - Find logic flaws that pattern-matching tools miss
- 🎯 **Attack Chain Analysis** - Identify how vulnerabilities can be chained
- 🤖 **Auto Model Discovery** - Automatically finds available AI models and lets you choose

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
git clone https://github.com/YOUR_USERNAME/kilo-security-review.git ~/kilo-security-review

# Run installer - it will auto-discover AI models and ask you to select one
cd ~/kilo-security-review
./install.sh
```

The installer will:
1. Install Semgrep (if not already installed)
2. Check for CodeQL
3. **Auto-discover available AI models**
4. **Ask you to select your preferred model**
5. Create the config automatically
  }
}
```

## Auto Model Selection

**NEW!** When you first run a security scan, the skill will automatically:

1. 🔍 **Discover** available AI models by running `kilo models`
2. 📋 **Present** you with free model options
3. ✅ **Remember** your choice for the session

### Available Free Models

The skill will find and present these options (and more):

| Model | Description |
|-------|-------------|
| `kilo/kilo-auto/free` | Best overall - auto selects best model |
| `kilo/minimax/minimax-m2.5:free` | Fast reasoning |
| `kilo/x-ai/grok-code-fast-1:optimized:free` | Code-focused |
| `kilo/nvidia/nemotron-3-super-120b-a12b:free` | High capacity |

### Manual Model Selection (Optional)

If you prefer a specific model, you can set it manually:

```json
{
  "skills": {
    "security-review": {
      "path": "~/kilo-security-review",
      "model": "kilo/kilo-auto/free"
    }
  }
}
```

**Option C: Grok Code (Free)**
```json
{
  "skills": {
    "security-review": {
      "path": "~/kilo-security-review",
      "model": "kilo/x-ai/grok-code-fast-1:optimized:free"
    }
  }
}
```

**Option D: Paid Models (More Powerful)**
```json
{
  "skills": {
    "security-review": {
      "path": "~/kilo-security-review",
      "model": "anthropic/claude-sonnet-4-20250514"
    }
  }
}
```

### Available Free Models

| Model | Command |
|-------|---------|
| Kilo Auto | `kilo/kilo-auto/free` |
| MiniMax | `kilo/minimax/minimax-m2.5:free` |
| Grok Code | `kilo/x-ai/grok-code-fast-1:optimized:free` |
| Nvidia Nemotron | `kilo/nvidia/nemotron-3-super-120b-a12b:free` |

### Full Example Config

```json
{
  "$schema": "https://kilo.ai/config.json",
  "skills": {
    "security-review": {
      "path": "~/kilo-security-review",
      "model": "kilo/kilo-auto/free"
    }
  },
  "mcp": {}
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

### Layer 3: AI Reasoning
- Exploitability assessment
- Logic flaw detection
- Attack chain identification

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
