#!/usr/bin/env bash
# muzak — Claude Code skill that bundles sonoscli + spogo for Sonos/Spotify control.
# Install: curl -fsSL https://raw.githubusercontent.com/mberg/muzak/main/install.sh | bash
set -euo pipefail

REPO="mberg/muzak"
REF="${MUZAK_REF:-main}"
SKILL_NAME="muzak"
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
DEST="$SKILLS_DIR/$SKILL_NAME"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf '\033[33m  ! %s\033[0m\n' "$*"; }
ok()   { printf '\033[32m  ✓ %s\033[0m\n' "$*"; }

bold "Installing muzak skill → $DEST"

mkdir -p "$SKILLS_DIR"

# Fetch the tarball — works without git installed.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

TARBALL_URL="https://codeload.github.com/$REPO/tar.gz/refs/heads/$REF"
info "Downloading $TARBALL_URL"
if ! curl -fsSL "$TARBALL_URL" | tar -xz -C "$TMP"; then
  echo "Failed to download $TARBALL_URL" >&2
  exit 1
fi

SRC="$(find "$TMP" -maxdepth 1 -type d -name "muzak-*" | head -1)"
SKILL_SRC="$SRC/skills/muzak"
if [ -z "$SRC" ] || [ ! -f "$SKILL_SRC/SKILL.md" ]; then
  echo "Couldn't find skills/muzak/SKILL.md in downloaded archive" >&2
  exit 1
fi

# Replace any existing install.
if [ -e "$DEST" ]; then
  warn "Replacing existing $DEST"
  rm -rf "$DEST"
fi
mkdir -p "$DEST"

# Copy only what the skill needs at runtime.
cp "$SKILL_SRC/SKILL.md" "$DEST/SKILL.md"
[ -d "$SKILL_SRC/references" ] && cp -R "$SKILL_SRC/references" "$DEST/references"

ok "Skill installed: $DEST/SKILL.md"

# Dependency check.
bold "Checking required CLIs"
missing=()
if command -v sonos >/dev/null 2>&1; then
  ok "sonos: $(sonos --version 2>&1 | head -1)"
else
  warn "sonos not found"; missing+=("sonoscli")
fi
if command -v spogo >/dev/null 2>&1; then
  ok "spogo: $(spogo --version 2>&1 | head -1)"
else
  warn "spogo not found"; missing+=("spogo")
fi

if [ ${#missing[@]} -gt 0 ]; then
  echo
  bold "Install missing dependencies:"
  if command -v brew >/dev/null 2>&1; then
    for m in "${missing[@]}"; do
      info "brew install steipete/tap/$m"
    done
  else
    info "Homebrew not detected. See https://sonoscli.sh and https://spogo.sh for install options."
  fi
fi

echo
bold "Done."
info "Restart Claude Code (or run /reload-skills) to pick up the new skill."
info "Skill triggers on phrases like: \"play X in the kitchen\", \"what's playing\", \"queue this song\"."
