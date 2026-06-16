# Amber zsh extras — sourced from ~/.zshrc (after `starship init`, before syntax-highlighting).
#
# Ghostwheel's hands in the shell:
#   0. `walk` — the intention mechanic. Sets the Shadow Matthew rides toward; the
#      MOTD reads it back on every new terminal.
#   1. Transient prompt: once a command is accepted, its two-line starship frame
#      collapses to a minimal "✶ cmd" line, so scrollback stays clean.
#      Disable with `export TRANSIENT_PROMPT=0` before this is sourced.
#   2. command-not-found, in Ghost's voice.
#   3. macOS notification when a foreground command runs ≥30s — skips editors/REPLs/ssh.
#
# Voice: Ghost addresses Matthew by name; eager, lucid, never menacing. The
# retired HAL 9000 originals are preserved in a commented block at the foot.

zmodload zsh/datetime 2>/dev/null

# --- 0. walk: set / show / clear the day's Shadow ----------------------------
# The Shadow is the purpose Matthew rides toward, kept as one plain line in
# ~/.amber/shadow and read back by the MOTD. Graceful on a fresh machine.
#   walk "ship the chainproof ledger spec"   set it
#   walk                                      show the current Shadow
#   walk --arrived                            clear it, in-world
walk() {
  emulate -L zsh
  local dir="$HOME/.amber" file="$HOME/.amber/shadow"
  local gold=$'\033[38;2;224;175;104m' gray=$'\033[3;38;2;86;95;137m' reset=$'\033[0m'

  if [[ $1 == --arrived || $1 == --done ]]; then
    if [[ -s $file ]]; then
      local was; was=$(<$file); rm -f -- "$file"
      print -r -- "${gold}Arrived, Matthew. ${was} lies behind you now.${reset}"
    else
      print -r -- "${gray}No Shadow to leave behind, Matthew.${reset}"
    fi
    return 0
  fi

  if (( $# == 0 )); then
    if [[ -s $file ]]; then
      print -r -- "${gold}The Shadow you ride toward:${reset} $(<$file)"
    else
      print -r -- "${gray}No Shadow set, Matthew. Name the one you mean to walk to.${reset}"
    fi
    return 0
  fi

  mkdir -p -- "$dir"
  print -r -- "$*" > "$file"
  print -r -- "${gold}The road is set, Matthew — you ride toward:${reset} $*"
}

# --- 1. transient prompt (romkatv's recursive-edit technique) ----------------
# Works with starship's promptsubst rendering: we briefly swap PROMPT to the
# short form, repaint, then restore before the next prompt renders fully.
if [[ "${TRANSIENT_PROMPT:-1}" == 1 ]]; then
  _ghost_zle_line_init() {
    emulate -L zsh
    [[ $CONTEXT == start ]] || return 0

    while true; do
      zle .recursive-edit
      local -i ret=$?
      [[ $ret == 0 && $KEYS == $'\4' ]] || break
      [[ -o ignore_eof ]] || exit 0
    done

    local saved_prompt=$PROMPT saved_rprompt=$RPROMPT
    PROMPT='%F{#e0af68}✶ %f' RPROMPT=''      # Amber gold pattern-spark
    zle .reset-prompt
    PROMPT=$saved_prompt RPROMPT=$saved_rprompt

    if (( ret )); then zle .send-break; else zle .accept-line; fi
    return ret
  }
  zle -N zle-line-init _ghost_zle_line_init
fi

# --- 2. command not found ----------------------------------------------------
command_not_found_handler() {
  print -ru2 -- $'\033[3;38;2;247;118;142m'"That path leads nowhere in Shadow, Matthew."$'\033[0m'
  print -ru2 -- "zsh: command not found: $1"
  return 127
}

# --- 3. long-command notifications -------------------------------------------
typeset -g _ghost_t0=0 _ghost_cmd=""
_ghost_preexec() { _ghost_t0=$EPOCHSECONDS; _ghost_cmd=$1; }
_ghost_precmd() {
  local t0=$_ghost_t0
  _ghost_t0=0
  (( t0 )) || return 0
  local dur=$(( EPOCHSECONDS - t0 ))
  (( dur >= 30 )) || return 0
  case $_ghost_cmd in
    (vim*|nvim*|nano*|less*|man*|ssh*|claude*|top*|htop*|tmux*|fg*) return 0 ;;
  esac
  local cmd=${_ghost_cmd//[^a-zA-Z0-9 ._\/-]/ }   # strip anything that could break osascript quoting
  osascript -e "display notification \"${cmd[1,60]} — ${dur}s\" with title \"Ghostwheel: the work is done, Matthew.\"" >/dev/null 2>&1 &!
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _ghost_preexec
add-zsh-hook precmd _ghost_precmd

# ─────────────────────────────────────────────────────────────────────────────
# HAL 9000 — retired to Shadow; uncomment to recall.
#
# The original HAL-voiced forms of the three sections above, preserved verbatim.
# To bring HAL back: restore these in place of their Ghost counterparts (the
# function names were _hal_* and the transient glyph was the dharma wheel ☸).
#
#   # --- 1. transient prompt glyph ------------------------------------------
#   PROMPT='%F{cyan}☸ %f' RPROMPT=''
#   zle -N zle-line-init _hal_zle_line_init      # was _hal_zle_line_init
#
#   # --- 2. command not found -----------------------------------------------
#   command_not_found_handler() {
#     print -ru2 -- $'\033[3;38;2;247;118;142m'"I'm sorry, Dave. I'm afraid I can't do that."$'\033[0m'
#     print -ru2 -- "zsh: command not found: $1"
#     return 127
#   }
#
#   # --- 3. long-command notification ---------------------------------------
#   typeset -g _hal_t0=0 _hal_cmd=""
#   _hal_preexec() { _hal_t0=$EPOCHSECONDS; _hal_cmd=$1; }
#   _hal_precmd() { ...same body... }
#   osascript -e "display notification \"${cmd[1,60]} — ${dur}s\" with title \"Processing complete, Dave.\"" ...
#   add-zsh-hook preexec _hal_preexec
#   add-zsh-hook precmd  _hal_precmd
# ─────────────────────────────────────────────────────────────────────────────
