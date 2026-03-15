#!/usr/bin/env bash
# kilo-security-review installer
# Supports: Claude Code, Kilo CLI, OpenCode, and manual .skill install
# Usage: ./install.sh [--target claude|kilo|opencode|skill]

set -euo pipefail

# ── colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${BLUE}ℹ${RESET}  $*"; }
success() { echo -e "${GREEN}✓${RESET}  $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET}  $*"; }
error()   { echo -e "${RED}✗${RESET}  $*" >&2; }
header()  { echo -e "\n${BOLD}$*${RESET}"; }

# ── resolve script directory (works with symlinks) ────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="kilo-security-review"

header "Kilo Security Review — Installer"
echo "  Source: $SCRIPT_DIR"

# ── parse flags ───────────────────────────────────────────────────────────────
TARGET="${1:-auto}"   # auto | claude | kilo | opencode | skill

# ── detect available runtimes ─────────────────────────────────────────────────
detect_runtimes() {
  RUNTIMES=()
  [[ -d "$HOME/.claude"    ]] && RUNTIMES+=("claude")
  command -v kilo    &>/dev/null && RUNTIMES+=("kilo")
  command -v kilocode &>/dev/null && RUNTIMES+=("kilo")
  command -v opencode &>/dev/null && RUNTIMES+=("opencode")
}

detect_runtimes

# ── determine install destination ─────────────────────────────────────────────
determine_target() {
  if [[ "$TARGET" != "auto" ]]; then
    INSTALL_TARGET="$TARGET"
    return
  fi

  if [[ ${#RUNTIMES[@]} -eq 0 ]]; then
    warn "No supported runtime detected. Falling back to .skill file packaging."
    INSTALL_TARGET="skill"
    return
  fi

  if [[ ${#RUNTIMES[@]} -eq 1 ]]; then
    INSTALL_TARGET="${RUNTIMES[0]}"
    info "Auto-detected runtime: ${RUNTIMES[0]}"
    return
  fi

  # Multiple runtimes — ask user
  header "Multiple runtimes detected. Where should the skill be installed?"
  local i=1
  for rt in "${RUNTIMES[@]}"; do
    echo "  $i) $rt"
    ((i++))
  done
  echo "  $i) Build .skill file only (works with any interface)"
  read -rp "Choice [1-$i]: " choice

  if (( choice >= 1 && choice <= ${#RUNTIMES[@]} )); then
    INSTALL_TARGET="${RUNTIMES[$((choice-1))]}"
  else
    INSTALL_TARGET="skill"
  fi
}

determine_target

# ── install functions ─────────────────────────────────────────────────────────

install_claude_code() {
  local dest="$HOME/.claude/skills/$SKILL_NAME"
  header "Installing to Claude Code: $dest"

  mkdir -p "$dest/references"
  cp "$SCRIPT_DIR/SKILL.md"     "$dest/SKILL.md"
  cp "$SCRIPT_DIR/references/"*.md "$dest/references/" 2>/dev/null || true

  success "Installed to $dest"
  echo ""
  echo "  Usage in Claude Code:"
  echo "    Claude will use this skill automatically when you ask for a security review."
  echo "    Or explicitly: 'Run a security review on this project'"
  echo ""
  echo "  To verify:"
  echo "    ls $dest"
}

install_kilo() {
  # Support both ~/.kilo/skills and ~/.config/kilo/skills
  local dest
  if [[ -d "$HOME/.kilo" ]]; then
    dest="$HOME/.kilo/skills/$SKILL_NAME"
  elif [[ -d "$HOME/.config/kilo" ]]; then
    dest="$HOME/.config/kilo/skills/$SKILL_NAME"
  else
    dest="$HOME/.kilo/skills/$SKILL_NAME"
  fi

  header "Installing to Kilo CLI: $dest"
  mkdir -p "$dest/references"
  cp "$SCRIPT_DIR/SKILL.md"         "$dest/SKILL.md"
  cp "$SCRIPT_DIR/references/"*.md  "$dest/references/" 2>/dev/null || true

  success "Installed to $dest"
  echo ""
  echo "  Usage with Kilo CLI:"
  echo "    kilo run --dir /path/to/project 'Security review for bug bounty'"
  echo "    kilo run --dir . 'Find SQL injection and SSRF'"
}

install_opencode() {
  local dest="$HOME/.opencode/skills/$SKILL_NAME"
  header "Installing to OpenCode: $dest"

  mkdir -p "$dest/references"
  cp "$SCRIPT_DIR/SKILL.md"         "$dest/SKILL.md"
  cp "$SCRIPT_DIR/references/"*.md  "$dest/references/" 2>/dev/null || true

  success "Installed to $dest"
  echo ""
  echo "  Usage with OpenCode:"
  echo "    Start a session and ask: 'Security review this project for bug bounties'"
}

build_skill_file() {
  local output="$SCRIPT_DIR/$SKILL_NAME.skill"
  header "Building .skill file: $output"

  if ! command -v zip &>/dev/null; then
    error "zip not found. Please install zip and re-run."
    exit 1
  fi

  cd "$SCRIPT_DIR"
  rm -f "$output"
  zip -r "$output" SKILL.md README.md references/ \
    --exclude "*.DS_Store" --exclude "*__pycache__*" -q

  success "Built: $output ($(du -sh "$output" | cut -f1))"
  echo ""
  echo "  Install with:"
  echo "    npx skills install $SKILL_NAME.skill"
  echo ""
  echo "  Or for Claude.ai: copy SKILL.md into your Project instructions"
  echo "    and add reference files as Project documents."
}

# ── optional tools check ──────────────────────────────────────────────────────
check_optional_tools() {
  header "Optional scanning tools (used by the skill if available)"
  local tools=("gitleaks" "semgrep" "bandit" "trivy" "gosec" "trufflehog" "pip-audit")
  local missing=()

  for tool in "${tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
      success "$tool — found"
    else
      warn "$tool — not found (skill will skip this tool)"
      missing+=("$tool")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo ""
    info "Install missing tools for better coverage:"
    echo "  gitleaks:   https://github.com/gitleaks/gitleaks#installation"
    echo "  semgrep:    pip install semgrep"
    echo "  bandit:     pip install bandit"
    echo "  trivy:      https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
    echo "  gosec:      go install github.com/securego/gosec/v2/cmd/gosec@latest"
    echo "  trufflehog: https://github.com/trufflesecurity/trufflehog#installation"
    echo "  pip-audit:  pip install pip-audit"
  fi
}

# ── verify install ────────────────────────────────────────────────────────────
verify_install() {
  local dest="$1"
  local required_files=("SKILL.md")
  local ok=true

  for f in "${required_files[@]}"; do
    if [[ ! -f "$dest/$f" ]]; then
      error "Missing: $dest/$f"
      ok=false
    fi
  done

  local ref_count
  ref_count=$(find "$dest/references" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  if (( ref_count < 4 )); then
    warn "Only $ref_count reference files found (expected 5). Some coverage may be missing."
  else
    success "$ref_count reference files installed"
  fi

  $ok && success "Installation verified" || error "Installation incomplete"
}

# ── run ───────────────────────────────────────────────────────────────────────

case "$INSTALL_TARGET" in
  claude)
    install_claude_code
    verify_install "$HOME/.claude/skills/$SKILL_NAME"
    ;;
  kilo)
    install_kilo
    if [[ -d "$HOME/.kilo" ]]; then
      verify_install "$HOME/.kilo/skills/$SKILL_NAME"
    elif [[ -d "$HOME/.config/kilo" ]]; then
      verify_install "$HOME/.config/kilo/skills/$SKILL_NAME"
    fi
    ;;
  opencode)
    install_opencode
    verify_install "$HOME/.opencode/skills/$SKILL_NAME"
    ;;
  skill)
    build_skill_file
    ;;
  *)
    error "Unknown target: $INSTALL_TARGET. Valid values: claude, kilo, opencode, skill"
    exit 1
    ;;
esac

check_optional_tools

header "Done"
echo ""
echo "  The skill teaches Claude to:"
echo "    • Trace data flow source→sink before reporting any vulnerability"
echo "    • Require a working PoC for every HIGH+ finding"
echo "    • Link each finding to a real HackerOne bug-bounty report"
echo "    • Apply CVSS 3.1 scoring to Critical and High findings"
echo "    • Load only the reference files relevant to your stack"
echo ""
echo "  Full docs: https://github.com/vichhka-git/kilo-security-review"
