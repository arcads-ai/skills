#!/usr/bin/env bash
# =============================================================================
# Arcads Skills Installer
# https://github.com/arcads-ai/skills
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/arcads-ai/skills/main/install.sh | bash
#
# Options (env vars):
#   TARGET=opencode|claude|cursor|codex|all   (default: all detected)
#   SKILLS_DIR=/custom/path                   (override install directory)
# =============================================================================
set -euo pipefail

REPO_URL="https://github.com/arcads-ai/skills.git"
RAW_BASE="https://raw.githubusercontent.com/arcads-ai/skills/main"
MANIFEST_URL="$RAW_BASE/skills.json"

# Default install dirs (auto-loaded without config by opencode + Claude Code)
DEFAULT_AGENTS_DIR="$HOME/.agents/skills"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[arcads-skills]${NC} $*"; }
success() { echo -e "${GREEN}[arcads-skills]${NC} $*"; }
warn()    { echo -e "${YELLOW}[arcads-skills]${NC} $*"; }
error()   { echo -e "${RED}[arcads-skills]${NC} $*" >&2; exit 1; }

# =============================================================================
# Helpers
# =============================================================================

require_cmd() {
  command -v "$1" &>/dev/null || error "'$1' is required but not found. Please install it."
}

fetch_manifest() {
  if command -v curl &>/dev/null; then
    curl -fsSL "$MANIFEST_URL"
  elif command -v wget &>/dev/null; then
    wget -qO- "$MANIFEST_URL"
  else
    error "Neither curl nor wget is available."
  fi
}

list_skills_from_manifest() {
  # Returns newline-separated list of skill names from skills.json
  fetch_manifest | python3 -c "
import json, sys
data = json.load(sys.stdin)
for s in data.get('skills', []):
    print(s['name'])
" 2>/dev/null || echo "winning-ad"  # fallback if python3 unavailable
}

clone_or_update() {
  local target_dir="$1"
  if [ -d "$target_dir/.git" ]; then
    info "Updating existing clone at $target_dir..."
    git -C "$target_dir" pull --ff-only --quiet
  else
    info "Cloning into $target_dir..."
    git clone --depth 1 --quiet "$REPO_URL" "$target_dir"
  fi
}

fetch_skill_md() {
  local skill_name="$1"
  local url="$RAW_BASE/$skill_name/SKILL.md"
  if command -v curl &>/dev/null; then
    curl -fsSL "$url"
  else
    wget -qO- "$url"
  fi
}

# =============================================================================
# Platform installers
# =============================================================================

install_opencode_claude() {
  # opencode + Claude Code both auto-load ~/.agents/skills/**/SKILL.md
  # No config change needed — just clone there.
  local install_dir="${SKILLS_DIR:-$DEFAULT_AGENTS_DIR}/arcads"
  mkdir -p "$(dirname "$install_dir")"
  clone_or_update "$install_dir"
  success "Skills installed at $install_dir"
  echo ""
  echo "  opencode and Claude Code will auto-load skills from this location."
  echo "  Restart the tool to pick up the changes."
  echo ""
  echo "  You can also reference this directory explicitly in opencode.json:"
  echo "    \"skills\": { \"paths\": [\"$install_dir\"] }"
  echo ""
  echo "  Or use URL-based discovery (no local clone needed):"
  echo "    \"skills\": { \"urls\": [\"$MANIFEST_URL\"] }"
}

install_cursor() {
  # Cursor uses .cursor/rules/*.mdc files (project-scoped)
  local rules_dir=".cursor/rules"
  mkdir -p "$rules_dir"

  info "Fetching skill list..."
  local skills
  skills=$(list_skills_from_manifest)

  while IFS= read -r skill; do
    local out="$rules_dir/arcads-${skill}.mdc"
    info "Writing $out..."
    {
      echo "---"
      echo "description: Arcads skill: $skill"
      echo "globs: \"**/*\""
      echo "alwaysApply: false"
      echo "---"
      echo ""
      fetch_skill_md "$skill"
    } > "$out"
    success "Created $out"
  done <<< "$skills"

  echo ""
  echo "  Cursor rules written to $rules_dir/"
  echo "  In Cursor, open Settings > Rules and they will appear automatically."
}

install_codex() {
  # GitHub Copilot / Codex: append to AGENTS.md (project root)
  # Also supports .github/copilot-instructions.md for Copilot-specific config
  local agents_file="AGENTS.md"
  local copilot_file=".github/copilot-instructions.md"

  info "Fetching skill list..."
  local skills
  skills=$(list_skills_from_manifest)

  # AGENTS.md
  {
    echo ""
    echo "<!-- arcads-skills: auto-generated, do not edit manually -->"
    echo "<!-- source: https://github.com/arcads-ai/skills -->"
    while IFS= read -r skill; do
      echo ""
      fetch_skill_md "$skill"
    done <<< "$skills"
    echo ""
    echo "<!-- /arcads-skills -->"
  } >> "$agents_file"
  success "Appended skills to $agents_file"

  # Copilot instructions
  mkdir -p ".github"
  {
    echo ""
    echo "<!-- arcads-skills: auto-generated -->"
    while IFS= read -r skill; do
      echo ""
      fetch_skill_md "$skill"
    done <<< "$skills"
    echo ""
    echo "<!-- /arcads-skills -->"
  } >> "$copilot_file"
  success "Appended skills to $copilot_file"
}

# =============================================================================
# Detection
# =============================================================================

detect_platforms() {
  local platforms=()
  command -v opencode &>/dev/null && platforms+=("opencode")
  [ -d "$HOME/.claude" ] && platforms+=("claude")
  [ -d "$HOME/.cursor" ] || [ -f ".cursor/settings.json" ] && platforms+=("cursor")
  command -v codex &>/dev/null && platforms+=("codex")
  # Always install to ~/.agents/skills as the universal fallback
  [ ${#platforms[@]} -eq 0 ] && platforms+=("opencode")
  echo "${platforms[@]}"
}

# =============================================================================
# Main
# =============================================================================

main() {
  echo ""
  echo "  Arcads Skills Installer"
  echo "  https://github.com/arcads-ai/skills"
  echo ""

  require_cmd git

  local target="${TARGET:-auto}"

  if [ "$target" = "auto" ]; then
    read -r -a detected <<< "$(detect_platforms)"
    info "Detected platforms: ${detected[*]}"
    target="all"
  fi

  case "$target" in
    opencode|claude)
      info "Installing for opencode / Claude Code..."
      install_opencode_claude
      ;;

    cursor)
      info "Installing for Cursor..."
      install_cursor
      ;;

    codex)
      info "Installing for Codex / GitHub Copilot..."
      install_codex
      ;;

    all)
      info "Installing for opencode / Claude Code..."
      install_opencode_claude

      if [ -d ".cursor" ]; then
        info "Installing for Cursor..."
        install_cursor
      else
        warn "Skipping Cursor — no .cursor/ directory found in cwd. Run with TARGET=cursor to force."
      fi

      if command -v codex &>/dev/null; then
        info "Installing for Codex / GitHub Copilot..."
        install_codex
      else
        warn "Skipping Codex — not detected. Run with TARGET=codex to force."
      fi
      ;;

    *)
      error "Unknown target '$target'. Use: opencode, claude, cursor, codex, or all."
      ;;
  esac

  echo ""
  success "Installation complete."
  echo ""
}

main "$@"
