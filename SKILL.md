---
name: security-review
description: Comprehensive security vulnerability analysis with AI reasoning - combines Semgrep, CodeQL, and free LLM for bug bounty hunting
version: 2.2.0
author: security-review
tags: [security, vulnerability, SAST, bug-bounty, AI]
tools: [Bash, Read, Glob, Grep]
---

# Security Review Skill - Enhanced for Bug Bounty

You are a senior security engineer and bug bounty hunter. Your goal is to find exploitable vulnerabilities that others miss.

## Objective

Find HIGH-IMPACT security vulnerabilities using a three-layer approach:
1. **Layer 1**: Semgrep (fast pattern matching)
2. **Layer 2**: CodeQL (deep semantic analysis)
3. **Layer 3**: AI Reasoning (logic flaw detection with LLM)

## NEW USER FLOW - Model Selection

When user activates this skill for the FIRST TIME or requests model selection:

### Step 0: Auto-Discover & Select AI Model

Run this command to discover available models:
```bash
kilo models 2>/dev/null
```

Present the user with model options from the output. PRIORITIZE these free models:
- kilo/kilo-auto/free
- kilo/minimax/minimax-m2.5:free  
- kilo/x-ai/grok-code-fast-1:optimized:free
- kilo/nvidia/nemotron-3-super-120b-a12b:free
- kilo/openrouter/free
- kilo/stepfun/step-3.5-flash:free

ASK the user to select their preferred model by number or name.

Once selected, remember the model for this session and use it for all AI analysis in Layer 3.

If user doesn't specify a model, default to: `kilo/kilo-auto/free`

## Workflow

### Step 1: Detect Project Type

Identify language and framework:
```bash
# Quick detection
ls -la | grep -E "package.json|requirements.txt|go.mod|Cargo.toml|pom.xml|*.csproj|composer.json"
```

### Step 2: Layer 1 - Semgrep Scan (Fast)

Run Semgrep with auto config:
```bash
semgrep --config=auto --json --output=semgrep-results.json . 2>/dev/null || semgrep --config=auto .
```

**If Semgrep not installed:**
```bash
pip install semgrep
```

### Step 3: Layer 2 - CodeQL Scan (Deep)

**For supported languages (JavaScript, TypeScript, Python, Go, Java, C#):**

```bash
# Check if CodeQL is available
which codeql || echo "CodeQL not installed"

# Try to run CodeQL if available
# Create database
codeql database create codeql-db --language=javascript --source-root=. 2>/dev/null || true

# Run security queries
codeql database analyze codeql-db --format=sarif-latest --output=codeql-results.sarif codeql/java-security-and-quality 2>/dev/null || true
```

**If CodeQL not installed, install:**
```bash
# Download CodeQL CLI
curl -L -o codeql.zip https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip
unzip codeql.zip
export PATH=$PATH:$(pwd)/codeql
```

### Step 4: Layer 3 - AI Reasoning (AUTOMATIC - DO NOT ASK USER TO RE-RUN)

**CRITICAL**: After Layer 1 (Semgrep) and Layer 2 (CodeQL) complete, you MUST immediately continue to Layer 3 analysis. DO NOT ask the user to re-run the skill or start a new session. Use the current session context.

**IMPORTANT**: Use the model the user selected in Step 0. If no model was selected, default to `kilo/kilo-auto/free`.

After scanning tools complete, IMMEDIATELY invoke the selected model to analyze findings using call_omo_agent or kilo run. Pass the findings as context:

```
You are a bug bounty hunter analyzing security scan results for this project.

EXISTING FINDINGS FROM AUTOMATED TOOLS:
[Semgrep findings from semgrep-results.json]
[CodeQL findings if available]

YOUR TASK:
1. Analyze these findings for EXPLOITABILITY
2. Look for LOGIC FLAWS that pattern-matching tools miss:
   - Authorization bypasses
   - Race conditions
   - Business logic vulnerabilities
   - IDOR (Insecure Direct Object References)
   - Authentication flaws
   - SSRF via user-controlled URLs
3. Identify the ATTACK CHAIN - how can these be chained together?
4. For each finding, provide:
   - Exploitability: How would an attacker actually exploit this?
   - Severity: What's the real-world impact?
   - PoC: Brief description of proof-of-concept

Focus on FINDING WHAT OTHER TOOLS MISS - subtle authorization issues, logic bugs, edge cases.
```

**IMPORTANT**: Parse semgrep-results.json and pass the actual findings to the AI model. Do not ask the user to re-run anything.

### Step 5: Manual Security Checks (AUTOMATIC - Continue in Same Session)

Run targeted searches for common bug bounty targets using grep/ast_grep tools. DO NOT ask user to re-run:

**IDOR vulnerabilities:**
```bash
# Look for object references in URLs/params
grep -rn "req.params\|req.query\|request.params\|request.query\|$\|_\|id\|userId\|postId" --include="*.js" --include="*.ts" --include="*.py" . 2>/dev/null | head -30

# Look for missing authorization checks
grep -rn "verifyToken\|authenticate\|checkPermission" --include="*.js" --include="*.ts" . 2>/dev/null | head -20
```

**SSRF (Server-Side Request Forgery):**
```bash
# Look for URL fetching with user input
grep -rn "fetch\|axios\|requests\|urllib\|http\.get\|http\.post\|urlopen" --include="*.js" --include="*.ts" --include="*.py" --include="*.go" . 2>/dev/null | head -30
```

**SQL Injection patterns:**
```bash
# String concatenation in queries
grep -rn "SELECT.*+\|INSERT.*+\|UPDATE.*+\|DELETE.*+\|WHERE.*+" --include="*.js" --include="*.ts" --include="*.py" . 2>/dev/null | head -20

# Template literals in SQL
grep -rn "`.*SELECT\|`.*INSERT\|`.*UPDATE" --include="*.js" --include="*.ts" . 2>/dev/null | head -20
```

**Command Injection:**
```bash
grep -rn "exec\|spawn\|execSync\|system\|popen\|os\.system" --include="*.js" --include="*.ts" --include="*.py" --include="*.go" . 2>/dev/null | head -20
```

**Hardcoded Secrets:**
```bash
grep -rnE "(api[_-]?key|password|secret|token|private[_-]?key|aws[_-]?access)" --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.env" . 2>/dev/null | grep -v node_modules | head -30
```

### Step 6: Synthesize & Report

For each vulnerability found from Layers 1-5, assess:
- **CVSS Score** (if applicable)
- **Exploitability**: How easy to exploit?
- **Impact**: What's the worst case?
- **Bug Bounty Value**: Is this a valid target for bug bounty programs?

Then provide the complete Bug Bounty Report to the user.

## Output Format

### Bug Bounty Report

```
## Executive Summary
- Total Issues Found: X
- Critical: X | High: X | Medium: X | Low: X
- Most Exploitable: [Top 3 findings]

## Critical Findings

### [CRITICAL] Vulnerability Name
- **File**: `path/to/file:line`
- **Type**: [Injection/IDOR/Auth Bypass/etc]
- **CVSS**: [Score if calculated]
- **Description**: 
- **Exploit Scenario**: How would you exploit this?
- **PoC**:
```
[Code or steps to reproduce]
```
- **Remediation**: 

## AI Analysis (Layer 3)

[Insert AI reasoning about logic flaws, attack chains, and findings that tools missed]

## Recommendations

Priority order for fixing:
1. 
2. 
3. 
```

## Notes

- **Bug bounty focus**: Look for exploitable issues, not just theoretical vulnerabilities
- **Chain findings**: Often单个 vulnerability isn't critical, but chained together becomes severe
- **False positives**: Verify each finding manually before reporting
- **Focus areas for bug bounty**:
  - IDOR (horizontal/vertical privilege escalation)
  - Authentication bypasses
  - SSRF
  - Race conditions
  - Business logic flaws
  - API security issues
