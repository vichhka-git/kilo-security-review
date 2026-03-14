#!/bin/bash

echo "🔒 Kilo Security Review Skill Installer"
echo "========================================"

if ! command -v kilocode &> /dev/null && ! command -v opencode &> /dev/null; then
    echo "❌ Kilo CLI or OpenCode not found!"
    echo "Please install from: https://kilo.ai/cli"
    exit 1
fi

echo "✅ Found Kilo/OpenCode"

echo ""
echo "📦 Installing Semgrep..."
if command -v semgrep &> /dev/null; then
    echo "✅ Semgrep already installed"
else
    pip install semgrep --break-system-packages
    echo "✅ Semgrep installed"
fi

CODEQL_DIR="$HOME/.local/codeql"
if [ -d "$CODEQL_DIR" ]; then
    echo "✅ CodeQL already installed"
else
    echo "⏭️  CodeQL not installed (optional)"
fi

SKILL_DIR="$HOME/.config/kilo/skills/security-review"
mkdir -p "$SKILL_DIR"

echo ""
echo "📦 Installing skill files..."
cp -f SKILL.md "$SKILL_DIR/"
echo "✅ Skill installed to $SKILL_DIR"

echo ""
echo "🤖 AI Model Selection"
echo "====================="
echo "Discovering available models..."

MODELS=$(kilo models 2>/dev/null | grep -E "free|Free" | head -10)

if [ -z "$MODELS" ]; then
    echo "⚠️  Could not fetch models, using default"
    SELECTED_MODEL="kilo/kilo-auto/free"
else
    echo ""
    echo "Available FREE models:"
    echo "$MODELS" | nl -w2 -s". "
    echo ""
    echo -n "Select model number [1]: "
    read -r SELECTION
    
    if [ -z "$SELECTION" ]; then
        SELECTION=1
    fi
    
    SELECTED_MODEL=$(echo "$MODELS" | sed -n "${SELECTION}p")
    
    if [ -z "$SELECTED_MODEL" ]; then
        SELECTED_MODEL="kilo/kilo-auto/free"
    fi
fi

echo ""
echo "✅ Selected model: $SELECTED_MODEL"

CONFIG_FILE="$HOME/.config/kilo/kilo.json"
mkdir -p "$HOME/.config/kilo"

cat > "$CONFIG_FILE" << 'EOF'
{
  "$schema": "https://kilo.ai/config.json",
  "skills": {
    "security-review": {
      "path": "~/.config/kilo/skills/security-review",
      "model": "SELECTED_MODEL_PLACEHOLDER"
    }
  }
}
EOF

sed -i "s/SELECTED_MODEL_PLACEHOLDER/$SELECTED_MODEL/" "$CONFIG_FILE"

echo "✅ Config created at $CONFIG_FILE"

echo ""
echo "🎉 Installation complete!"
echo ""
echo "Usage:"
echo "  kilocode"
echo "  # Then type: Run a security scan for bug bounty"
echo ""
echo "Current model: $SELECTED_MODEL"
