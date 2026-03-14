#!/bin/bash

echo "Kilo Security Review Skill Installer"
echo "===================================="

if ! command -v kilocode &> /dev/null && ! command -v opencode &> /dev/null; then
    echo "Kilo CLI or OpenCode not found!"
    echo "Please install from: https://kilo.ai/cli"
    exit 1
fi

echo "Found Kilo/OpenCode"

echo ""
echo "Installing Semgrep..."
if command -v semgrep &> /dev/null; then
    echo "Semgrep already installed"
else
    pip install semgrep --break-system-packages
    echo "Semgrep installed"
fi

SKILL_DIR="$HOME/.config/kilo/skills/security-review"
mkdir -p "$SKILL_DIR"

echo ""
echo "Installing skill files..."
cp -f SKILL.md "$SKILL_DIR/"
echo "Skill installed to $SKILL_DIR"

echo ""
echo "Cloning HackerOne reports..."
H1_DIR="$SKILL_DIR/h1-reports"
if [ -d "$H1_DIR/.git" ]; then
    cd "$H1_DIR"
    git pull origin master 2>/dev/null
    echo "H1 reports updated"
else
    git clone --depth 1 https://github.com/reddelexc/hackerone-reports.git "$H1_DIR"
    echo "H1 reports cloned"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Usage:"
echo "  kilo run --dir /path/to/project --model kilo/kilo-auto/free \"Security scan\""
