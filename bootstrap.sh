#!/usr/bin/env bash
# Bootstrap a Mac with my terminal setup:
#   - Homebrew + starship, jq, ghostty
#   - Starship prompt config  (~/.config/starship.toml)
#   - Ghostty config, TokyoNight Night  (~/.config/ghostty/config)
#   - Claude Code TokyoNight statusline  (~/.claude/hooks/statusline.sh + settings.json)
#
# Usage:
#   git clone https://github.com/vajramatt/dotfiles.git ~/dotfiles
#   ~/dotfiles/bootstrap.sh
#
# Re-runnable (idempotent): existing files are backed up to *.bak before linking.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

log() { printf '\033[1;32m[bootstrap]\033[0m %s\n' "$*"; }

# Backup whatever is at $dest (unless it's already the symlink we want), then symlink src -> dest.
link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    log "ok    $dest (already linked)"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
    log "backup $dest -> $dest.bak.*"
  fi
  ln -s "$src" "$dest"
  log "link  $dest -> $src"
}

# 1. Homebrew --------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  log "installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Make brew available in this shell (Apple Silicon default prefix)
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -x /usr/local/bin/brew ]    && eval "$(/usr/local/bin/brew shellenv)"

# 2. Packages --------------------------------------------------------------
log "installing packages: starship, jq, ghostty..."
brew install starship jq
brew install --cask ghostty || log "ghostty cask already present (skipping)"

# 3. Starship prompt -------------------------------------------------------
link "$REPO_DIR/config/starship.toml" "$CONFIG_DIR/starship.toml"

# 4. Ghostty ---------------------------------------------------------------
link "$REPO_DIR/config/ghostty/config" "$CONFIG_DIR/ghostty/config"

# 5. Claude Code TokyoNight statusline ------------------------------------
chmod +x "$REPO_DIR/claude/hooks/statusline.sh"
link "$REPO_DIR/claude/hooks/statusline.sh" "$CLAUDE_DIR/hooks/statusline.sh"

SETTINGS="$CLAUDE_DIR/settings.json"
mkdir -p "$CLAUDE_DIR"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.bak"
tmp="$(mktemp)"
jq --arg cmd "$CLAUDE_DIR/hooks/statusline.sh" \
   '.statusLine = {type: "command", command: $cmd, refreshInterval: 30}' \
   "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
log "merged statusLine into $SETTINGS (backup: $SETTINGS.bak)"

# 6. Ensure starship initializes in zsh -----------------------------------
ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"
if ! grep -q 'starship init zsh' "$ZSHRC"; then
  printf '\neval "$(starship init zsh)"\n' >> "$ZSHRC"
  log "added 'starship init zsh' to $ZSHRC"
fi

log "done — open a new terminal or run: exec zsh"
