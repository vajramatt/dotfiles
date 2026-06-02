#!/usr/bin/env bash
# Bootstrap a Mac with my terminal setup:
#   - Homebrew + starship, jq, zsh-autosuggestions, zsh-syntax-highlighting, ghostty
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
log "installing packages: starship, jq, eza, zsh plugins, ghostty..."
brew install starship jq eza zsh-autosuggestions zsh-syntax-highlighting
brew install --cask ghostty || log "ghostty cask already present (skipping)"
brew install --cask font-jetbrains-mono-nerd-font || log "nerd font cask already present (skipping)"

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

# 6. Ensure starship + zsh plugins initialize in zsh ----------------------
ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"

# Append a line to ~/.zshrc only if a marker isn't already present.
append_once() {  # $1 = grep marker, $2 = line to append
  if ! grep -q "$1" "$ZSHRC"; then
    printf '\n%s\n' "$2" >> "$ZSHRC"
    log "added to $ZSHRC: $2"
  fi
}

# Use the literal ${HOMEBREW_PREFIX:-/opt/homebrew} so it resolves at shell
# startup (works on both Apple Silicon and Intel) without a slow `brew --prefix`.
BREW='${HOMEBREW_PREFIX:-/opt/homebrew}'
append_once 'zsh-autosuggestions'     "source \"$BREW/share/zsh-autosuggestions/zsh-autosuggestions.zsh\""
append_once 'starship init zsh'       'eval "$(starship init zsh)"'

# eza — modern ls replacement (colors, icons, git status). Add aliases as one block.
append_once '# eza aliases' '# eza aliases
alias ls='\''eza --icons --group-directories-first'\''
alias la='\''eza -a --icons --group-directories-first'\''
alias ll='\''eza -la --git --icons --group-directories-first'\''
alias lt='\''eza --tree --level=2 --icons'\'''

# zsh-syntax-highlighting must be sourced LAST — append it after everything else.
append_once 'zsh-syntax-highlighting' "source \"$BREW/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\""

log "done — open a new terminal or run: exec zsh"
