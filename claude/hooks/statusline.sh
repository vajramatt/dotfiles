#!/bin/bash
# Claude Code status bar — TokyoNight Night palette
# https://github.com/vajramatt/claude-tokyonight-statusline
#
# Reads Claude Code's status JSON on stdin, prints one colored line.
# Segments are priority-ranked and drop out on narrow terminals ($COLUMNS).

shopt -s extglob
{ export LC_ALL=en_US.UTF-8 || export LC_ALL=C.UTF-8; } 2>/dev/null   # ${#s} counts chars, not bytes
export LC_NUMERIC=C

INPUT=$(cat)

# ── TokyoNight Night palette (24-bit ANSI) ────────────────────────────────────
RS=$'\033[0m'
BD=$'\033[1m'
DM=$'\033[2m'

CP=$'\033[38;2;187;154;247m'   # #bb9af7 purple   — project
CM=$'\033[38;2;125;207;255m'   # #7dcfff sky      — model
CG=$'\033[38;2;158;206;106m'   # #9ece6a green    — branch, lines added, ok
CB=$'\033[38;2;122;162;247m'   # #7aa2f7 blue     — tokens in, worktree
CY=$'\033[38;2;224;175;104m'   # #e0af68 yellow   — tokens out, warn
CC=$'\033[38;2;115;218;202m'   # #73daca teal     — session time, cache
CO=$'\033[38;2;255;158;100m'   # #ff9e64 orange   — high
CR=$'\033[38;2;247;118;142m'   # #f7768e red      — cost, critical, lines removed
CD=$'\033[38;2;86;95;137m'     # #565f89 comment  — separators + dim labels
CT=$'\033[38;2;59;66;97m'      # #3b4261 fg_gutter — empty gauge cells, separators

CK=$'\033[38;2;26;27;38m'      # #1a1b26 bg       — text on pills
BP=$'\033[48;2;187;154;247m'   # #bb9af7 purple   — project pill
BH=$'\033[48;2;41;46;66m'      # #292e42 bg_hl    — model pill
CH=$'\033[38;2;41;46;66m'      # #292e42 as fg    — model pill caps

# ── Icons: Nerd Font glyphs (byte escapes so they survive copy/paste) ─────────
# TOKYONIGHT_ICONS=1|0 forces; default on for terminals that bundle the symbols.
case "${TOKYONIGHT_ICONS:-auto}" in
  1|on|true) ICONS=1 ;;
  0|off|false) ICONS=0 ;;
  *) case "$TERM_PROGRAM" in ghostty|WezTerm) ICONS=1 ;; *) ICONS=0 ;; esac ;;
esac
if [ "$ICONS" = 1 ]; then
  I_CAPL=$'\xEE\x82\xB6' I_CAPR=$'\xEE\x82\xB4'
  I_DIR=$'\xEF\x81\xBC ' I_BRANCH=$'\xEE\x82\xA0 ' I_PR=$'\xEF\x90\x87 '
  I_CLOCK=$'\xEF\x80\x97 ' I_FAST=$'\xEF\x83\xA7' I_CACHE=$'\xEF\x87\x80 '
  I_LIMIT=$'\xEF\x83\xA4 ' I_TREE=$'\xEF\x86\xBB '
else
  I_CAPL="" I_CAPR="" I_DIR="" I_BRANCH="⎇ " I_PR="" I_CLOCK="⏱ " I_FAST="↯"
  I_CACHE="cache " I_LIMIT="" I_TREE="⧉ "
fi

if ! command -v jq &>/dev/null; then
  printf '%s' "${CR}statusline: jq not found${RS}"
  exit 0
fi

# ── Data extraction (single jq pass, \x1f-separated so empty fields survive) ──
IFS=$'\x1f' read -r CWD MODEL EFFORT FAST WT DUR_S COST LINES_ADD LINES_DEL \
  IN_F OUT_F CTX_PCT CACHE_HIT CACHE_WARM \
  RL5_PCT RL5_RESET RL7_PCT RL7_RESET PR_NUM PR_URL PR_STATE VIM \
  <<< "$(printf '%s' "$INPUT" | jq -r '
  def k:   (. // 0) as $n
           | if $n >= 1000000 then (($n / 100000 | floor) / 10 | tostring) + "M"
             elif $n >= 1000  then ($n / 1000 | floor | tostring) + "k"
             else ($n | floor | tostring) end;
  def pct: if . == null then "" else (. + 0.5 | floor) end;
  def mins_until: if . == null then "" else ((. - now) / 60 | floor) end;
  [
    (.workspace.current_dir // .cwd // ""),
    (.model.display_name // ""),
    (.effort.level // ""),
    (.fast_mode // false),
    (.workspace.git_worktree // .worktree.name // ""),
    ((.cost.total_duration_ms // 0) / 1000 | floor),
    (.cost.total_cost_usd // ""),
    (.cost.total_lines_added // 0),
    (.cost.total_lines_removed // 0),
    (.context_window.total_input_tokens | k),
    (.context_window.total_output_tokens | k),
    (.context_window.used_percentage | pct),
    (if .prompt_cache.hit_ratio == null then null else .prompt_cache.hit_ratio * 100 end | pct),
    (if .prompt_cache == null then "" else (.prompt_cache.warm // false) end),
    (.rate_limits.five_hour.used_percentage | pct),
    (.rate_limits.five_hour.resets_at | mins_until),
    (.rate_limits.seven_day.used_percentage | pct),
    (.rate_limits.seven_day.resets_at | mins_until),
    (.pr.number // ""),
    (.pr.url // ""),
    (.pr.review_state // ""),
    (.vim.mode // "")
  ] | map(tostring) | join("\u001f")
' 2>/dev/null)"

CWD="${CWD:-$PWD}"
PROJECT=$(basename "$CWD")
[ "${#PROJECT}" -gt 24 ] && PROJECT="${PROJECT:0:23}…"

# ── Git: branch, ahead/behind, dirty — one process ────────────────────────────
BRANCH="" AHEAD=0 BEHIND=0 DIRTY=""
while IFS= read -r line; do
  case "$line" in
    "# branch.head "*) BRANCH=${line#\# branch.head } ;;
    "# branch.ab "*)   set -- ${line#\# branch.ab }; AHEAD=${1#+}; BEHIND=${2#-} ;;
    "#"*) ;;
    *) DIRTY="*" ;;
  esac
done < <(git --no-optional-locks -C "$CWD" status --porcelain=v2 --branch -uno 2>/dev/null)
[ "$BRANCH" = "(detached)" ] && BRANCH=$(git -C "$CWD" rev-parse --short HEAD 2>/dev/null)

# ── Helpers ───────────────────────────────────────────────────────────────────
# Severity color for a 0–100 percentage
heat() {
  local p=${1:-0}
  if   [ "$p" -ge 90 ]; then printf '%s' "$CR"
  elif [ "$p" -ge 75 ]; then printf '%s' "$CO"
  elif [ "$p" -ge 50 ]; then printf '%s' "$CY"
  else                       printf '%s' "$CG"; fi
}

# 10-cell gauge, each filled cell tinted by its own position: green → red
gauge() {
  local p=${1:-0} n i out=""
  n=$(( (p * 10 + 50) / 100 )); [ "$n" -gt 10 ] && n=10
  for ((i = 0; i < n; i++)); do out+="$(heat $(( i * 10 + 5 )))▰"; done
  out+="$CT"
  for ((i = n; i < 10; i++)); do out+="▱"; done
  printf '%s' "$out$RS"
}

# 75 → 1h15m, 42 → 42m, 3000 → 2d2h
dur() {
  local m=${1:-0}
  [ "$m" -lt 0 ] && m=0
  if   [ "$m" -ge 1440 ]; then printf '%dd%dh' $((m / 1440)) $(( (m % 1440) / 60 ))
  elif [ "$m" -ge 60 ];   then printf '%dh%dm' $((m / 60)) $((m % 60))
  else                         printf '%dm' "$m"; fi
}

# ── Segments: SEG_TXT[i] rendered, SEG_PRI[i] (1 = keep longest) ──────────────
SEG_TXT=() SEG_PRI=()
seg() { SEG_PRI+=("$1"); SEG_TXT+=("$2"); }

# Project · model · effort · fast · vim — rendered as a two-tone pill with icons
m="$MODEL"
[ -n "$EFFORT" ] && m+="${CD}·${EFFORT}"
[ "$FAST" = "true" ] && m+=" ${CY}${I_FAST}"
if [ "$ICONS" = 1 ]; then
  s="${CP}${I_CAPL}${BP}${CK}${BD}${I_DIR}${PROJECT} ${RS}"
  if [ -n "$MODEL" ]; then
    s+="${BH}${CP}${I_CAPR}${CM} ${m} ${RS}${CH}${I_CAPR}${RS}"
  else
    s+="${CP}${I_CAPR}${RS}"
  fi
else
  s="${CP}${BD}${PROJECT}${RS}"
  [ -n "$MODEL" ] && s+=" ${CM}${m}${RS}"
fi
case "$VIM" in
  NORMAL) s+=" ${CB}${BD}N${RS}" ;;
  INSERT) s+=" ${CG}${BD}I${RS}" ;;
  VISUAL*) s+=" ${CP}${BD}V${RS}" ;;
esac
seg 1 "$s"

# Context gauge
[ -n "$CTX_PCT" ] && seg 1 "$(gauge "$CTX_PCT") $(heat "$CTX_PCT")${CTX_PCT}%${RS}"

# Branch · ahead/behind · worktree
if [ -n "$BRANCH" ]; then
  s="${CG}${I_BRANCH}${BRANCH}${RS}"
  [ -n "$DIRTY" ] && s+="${CY}${DIRTY}${RS}"
  [ "$AHEAD"  -gt 0 ] 2>/dev/null && s+=" ${CC}↑${AHEAD}${RS}"
  [ "$BEHIND" -gt 0 ] 2>/dev/null && s+=" ${CO}↓${BEHIND}${RS}"
  [ -n "$WT" ] && s+=" ${CB}${I_TREE}${WT}${RS}"
  seg 2 "$s"
fi

# Pull request — clickable via OSC 8, colored by review state
if [ -n "$PR_NUM" ]; then
  case "$PR_STATE" in
    approved)          c=$CG ;;
    changes_requested) c=$CR ;;
    draft)             c=$CD ;;
    *)                 c=$CY ;;
  esac
  if [ -n "$PR_URL" ]; then
    seg 3 "${c}"$'\033]8;;'"${PR_URL}"$'\033\\'"${I_PR}#${PR_NUM}"$'\033]8;;\033\\'"${RS}"
  else
    seg 3 "${c}${I_PR}#${PR_NUM}${RS}"
  fi
fi

# Plan usage — 5h always, 7d once it matters; reset countdown when running hot
if [ -n "$RL5_PCT" ]; then
  s="${CD}${I_LIMIT}5h${RS}$(heat "$RL5_PCT")${RL5_PCT}%${RS}"
  [ "$RL5_PCT" -ge 75 ] && [ -n "$RL5_RESET" ] && s+="${CD}↻$(dur "$RL5_RESET")${RS}"
  if [ -n "$RL7_PCT" ] && [ "$RL7_PCT" -ge 50 ]; then
    s+=" ${CD}7d${RS}$(heat "$RL7_PCT")${RL7_PCT}%${RS}"
    [ "$RL7_PCT" -ge 75 ] && [ -n "$RL7_RESET" ] && s+="${CD}↻$(dur "$RL7_RESET")${RS}"
  fi
  seg 2 "$s"
fi

# Cost
[ -n "$COST" ] && seg 3 "${CR}$(printf '$%.2f' "$COST")${RS}"

# Prompt cache — hit ratio while warm, flag when cold
case "$CACHE_WARM" in
  true)  [ -n "$CACHE_HIT" ] && seg 4 "${CD}${I_CACHE}${RS}${CC}${CACHE_HIT}%${RS}" ;;
  false) seg 4 "${CD}${I_CACHE}${RS}${CB}cold${RS}" ;;
esac

# Session time
[ "${DUR_S:-0}" -gt 0 ] 2>/dev/null && seg 4 "${CC}${I_CLOCK}$(dur $((DUR_S / 60)))${RS}"

# Lines changed
[ "${LINES_ADD:-0}" != 0 ] || [ "${LINES_DEL:-0}" != 0 ] &&
  seg 5 "${CG}+${LINES_ADD}${RS} ${CR}-${LINES_DEL}${RS}"

# Tokens in context / last output
[ "${IN_F:-0}" != 0 ] && seg 6 "${CD}in${RS}${CB}${IN_F}${RS} ${CD}out${RS}${CY}${OUT_F}${RS}"

# ── Fit to width: drop lowest-priority segments until the line fits ───────────
SEP=" ${CT}│${RS} "
# Status-line commands often get COLUMNS unset or 0 — treat that as "no limit".
# TOKYONIGHT_WIDTH overrides.
W=${TOKYONIGHT_WIDTH:-$COLUMNS}
[[ "$W" =~ ^[0-9]+$ ]] && [ "$W" -ge 40 ] || W=1000
MAX=$(( W - 6 ))

visible_len() {
  local s=$1
  s=${s//$'\033]8;;'*([^$'\033'])$'\033\\'/}   # OSC 8 hyperlinks
  s=${s//$'\033['*([0-9;])m/}                   # SGR colors
  printf '%d' "${#s}"
}

LEN=() total=0
for i in "${!SEG_TXT[@]}"; do
  LEN[i]=$(visible_len "${SEG_TXT[i]}")
  total=$(( total + LEN[i] + 3 ))
done
total=$(( total - 3 ))

for pri in 6 5 4 3 2; do
  [ "$total" -le "$MAX" ] && break
  for ((i = ${#SEG_TXT[@]} - 1; i >= 0; i--)); do
    [ "$total" -le "$MAX" ] && break
    if [ "${SEG_PRI[i]}" = "$pri" ] && [ -n "${SEG_TXT[i]}" ]; then
      total=$(( total - LEN[i] - 3 ))
      SEG_TXT[i]=""
    fi
  done
done

# ── Render ────────────────────────────────────────────────────────────────────
out=""
for s in "${SEG_TXT[@]}"; do
  [ -z "$s" ] && continue
  [ -n "$out" ] && out+="$SEP"
  out+="$s"
done
printf '%s' "$out"
