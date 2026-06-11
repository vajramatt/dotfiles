# HAL zsh extras — sourced from ~/.zshrc (after `starship init`, before syntax-highlighting).
#
#   1. Transient prompt: once a command is accepted, its two-line starship frame
#      collapses to a minimal "☸ cmd" line, so scrollback stays clean.
#      Disable with `export TRANSIENT_PROMPT=0` before this is sourced.
#   2. command-not-found, in character.
#   3. macOS notification when a foreground command runs ≥30s
#      ("Processing complete, Dave.") — skips editors/REPLs/ssh.

zmodload zsh/datetime 2>/dev/null

# --- 1. transient prompt (romkatv's recursive-edit technique) ----------------
# Works with starship's promptsubst rendering: we briefly swap PROMPT to the
# short form, repaint, then restore before the next prompt renders fully.
if [[ "${TRANSIENT_PROMPT:-1}" == 1 ]]; then
  _hal_zle_line_init() {
    emulate -L zsh
    [[ $CONTEXT == start ]] || return 0

    while true; do
      zle .recursive-edit
      local -i ret=$?
      [[ $ret == 0 && $KEYS == $'\4' ]] || break
      [[ -o ignore_eof ]] || exit 0
    done

    local saved_prompt=$PROMPT saved_rprompt=$RPROMPT
    PROMPT='%F{cyan}☸ %f' RPROMPT=''
    zle .reset-prompt
    PROMPT=$saved_prompt RPROMPT=$saved_rprompt

    if (( ret )); then zle .send-break; else zle .accept-line; fi
    return ret
  }
  zle -N zle-line-init _hal_zle_line_init
fi

# --- 2. command not found ----------------------------------------------------
command_not_found_handler() {
  print -ru2 -- $'\033[3;38;2;247;118;142m'"I'm sorry, Dave. I'm afraid I can't do that."$'\033[0m'
  print -ru2 -- "zsh: command not found: $1"
  return 127
}

# --- 3. long-command notifications -------------------------------------------
typeset -g _hal_t0=0 _hal_cmd=""
_hal_preexec() { _hal_t0=$EPOCHSECONDS; _hal_cmd=$1; }
_hal_precmd() {
  local t0=$_hal_t0
  _hal_t0=0
  (( t0 )) || return 0
  local dur=$(( EPOCHSECONDS - t0 ))
  (( dur >= 30 )) || return 0
  case $_hal_cmd in
    (vim*|nvim*|nano*|less*|man*|ssh*|claude*|top*|htop*|tmux*|fg*) return 0 ;;
  esac
  local cmd=${_hal_cmd//[^a-zA-Z0-9 ._\/-]/ }   # strip anything that could break osascript quoting
  osascript -e "display notification \"${cmd[1,60]} — ${dur}s\" with title \"Processing complete, Dave.\"" >/dev/null 2>&1 &!
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _hal_preexec
add-zsh-hook precmd _hal_precmd
