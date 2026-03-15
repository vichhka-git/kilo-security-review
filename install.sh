#!/usr/bin/env bash
# kilo-security-review installer
# Supports: Kilo CLI, OpenCode
# Usage: ./install.sh [--target kilo|opencode]

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
TARGET="${1:-auto}"   # auto | kilo | opencode

# ── detect available runtimes ─────────────────────────────────────────────────
detect_runtimes() {
  RUNTIMES=()
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

  header "Cloning HackerOne reports database..."
  if [[ ! -d "$SCRIPT_DIR/references/hackerone-reports" ]]; then
    git clone --depth 1 https://github.com/reddelexc/hackerone-reports.git "$SCRIPT_DIR/references/hackerone-reports" 2>/dev/null || {
      warn "Failed to clone H1 reports. Install will continue without local H1 data."
    }
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

  header "Cloning HackerOne reports database..."
  if [[ ! -d "$SCRIPT_DIR/references/hackerone-reports" ]]; then
    git clone --depth 1 https://github.com/reddelexc/hackerone-reports.git "$SCRIPT_DIR/references/hackerone-reports" 2>/dev/null || {
      warn "Failed to clone H1 reports. Install will continue without local H1 data."
    }
  fi

  header "Installing to OpenCode: $dest"

  mkdir -p "$dest/references"
  cp "$SCRIPT_DIR/SKILL.md"         "$dest/SKILL.md"
  cp "$SCRIPT_DIR/references/"*.md   "$dest/references/" 2>/dev/null || true

  success "Installed to $dest"
  echo ""
  echo "  Usage with OpenCode:"
  echo "    Start a session and ask: 'Security review this project for bug bounties'"
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
  *)
    error "Unknown target: $INSTALL_TARGET. Valid values: kilo, opencode"
    exit 1
    ;;
esac

check_optional_tools

header "Done"
echo ""
  echo "  The skill teaches the AI to:"
echo "    • Trace data flow source→sink before reporting any vulnerability"
echo "    • Require a working PoC for every HIGH+ finding"
echo "    • Link each finding to a real HackerOne bug-bounty report"
echo "    • Apply CVSS 3.1 scoring to Critical and High findings"
echo "    • Load only the reference files relevant to your stack"
echo ""
  echo "  Full docs: https://github.com/vichhka-git/kilo-security-review"
  echo ""
  echo "  Note: This skill is for Kilo CLI and OpenCode only."
