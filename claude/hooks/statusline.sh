#!/bin/bash
# Claude Code status bar — TokyoNight Night palette
# https://github.com/vajramatt/claude-tokyonight-statusline

INPUT=$(head -c 8192)

jq_val() {
  command -v jq &>/dev/null && printf '%s' "$INPUT" | jq -r "$1 // empty" 2>/dev/null || true
}

# ── Data extraction ───────────────────────────────────────────────────────────
CWD=$(jq_val '.cwd // .workspace.current_dir')
CWD="${CWD:-$PWD}"
PROJECT=$(basename "$CWD")

MODEL=$(jq_val '.model.display_name')

BRANCH=$(jq_val '.git.branch // .git_branch')
[ -z "$BRANCH" ] && BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null)
[ -z "$BRANCH" ] && BRANCH="—"

DUR_MS=$(jq_val '.cost.total_duration_ms')
SESSION_TIME="0m"
if [ -n "$DUR_MS" ]; then
  DUR_S=$(printf '%s' "$DUR_MS" | tr -cd '0-9')
  DUR_S=${DUR_S:-0}
  DUR_S=$((DUR_S / 1000))
  H=$((DUR_S / 3600))
  M=$(( (DUR_S % 3600) / 60 ))
  [ "$H" -gt 0 ] && SESSION_TIME="${H}h${M}m" || SESSION_TIME="${M}m"
fi

fmt_k() {
  local n
  n=$(printf '%s' "${1:-0}" | tr -cd '0-9')
  n=${n:-0}
  [ "$n" -ge 1000 ] && printf '%dk' $((n / 1000)) || printf '%d' "$n"
}

IN_TOK=$(jq_val  '.context_window.total_input_tokens')
OUT_TOK=$(jq_val '.context_window.total_output_tokens')
CR_TOK=$(jq_val  '.context_window.current_usage.cache_read_input_tokens')
CW_TOK=$(jq_val  '.context_window.current_usage.cache_creation_input_tokens')
CTX_PCT=$(jq_val '.context_window.used_percentage')

IN_F=$(fmt_k  "${IN_TOK:-0}")
OUT_F=$(fmt_k "${OUT_TOK:-0}")
CR_F=$(fmt_k  "${CR_TOK:-0}")
CW_F=$(fmt_k  "${CW_TOK:-0}")

RAW_COST=$(jq_val '.cost.total_cost_usd')
COST=""
[ -n "$RAW_COST" ] && COST=$(printf '$%.2f' "$RAW_COST" 2>/dev/null)

# ── TokyoNight Night palette (24-bit ANSI) ────────────────────────────────────
RS=$'\033[0m'
BD=$'\033[1m'
DM=$'\033[2m'

CP=$'\033[38;2;187;154;247m'   # #bb9af7 purple   — project
CM=$'\033[38;2;125;207;255m'   # #7dcfff sky      — model
CG=$'\033[38;2;158;206;106m'   # #9ece6a green    — branch
CB=$'\033[38;2;122;162;247m'   # #7aa2f7 blue     — tokens in
CY=$'\033[38;2;224;175;104m'   # #e0af68 yellow   — tokens out
CC=$'\033[38;2;115;218;202m'   # #73daca teal     — session time + cache read
CO=$'\033[38;2;255;158;100m'   # #ff9e64 orange   — cache write
CR=$'\033[38;2;247;118;142m'   # #f7768e red      — cost
CD=$'\033[38;2;86;95;137m'     # #565f89 comment  — separators + dim labels

SEP=" ${CD}▏${RS} "

# ── Context gauge ─────────────────────────────────────────────────────────────
# Gradient-filled bar, green → yellow → orange → red across the full width.
GAUGE_CELLS=10

grad_rgb() { # $1: cell index 0..GAUGE_CELLS-1 → "R;G;B" along the gradient
  local i=$1 t seg f r g b
  local R=(158 224 255 247) G=(206 175 158 118) B=(106 104 100 142)
  t=$(( i * 300 / (GAUGE_CELLS - 1) ))
  seg=$(( t / 100 )); f=$(( t % 100 ))
  [ "$seg" -ge 3 ] && { seg=2; f=100; }
  r=$(( ${R[$seg]} + ( (${R[$((seg+1))]} - ${R[$seg]}) * f ) / 100 ))
  g=$(( ${G[$seg]} + ( (${G[$((seg+1))]} - ${G[$seg]}) * f ) / 100 ))
  b=$(( ${B[$seg]} + ( (${B[$((seg+1))]} - ${B[$seg]}) * f ) / 100 ))
  printf '%d;%d;%d' "$r" "$g" "$b"
}

CTX_GAUGE=""
if [ -n "$CTX_PCT" ]; then
  P=$(printf '%s' "${CTX_PCT%%.*}" | tr -cd '0-9'); P=${P:-0}
  [ "$P" -gt 100 ] && P=100
  FILLED=$(( (P * GAUGE_CELLS + 50) / 100 ))
  [ "$P" -gt 0 ] && [ "$FILLED" -eq 0 ] && FILLED=1
  BAR="" PCOL="$CG" i=0
  while [ "$i" -lt "$GAUGE_CELLS" ]; do
    if [ "$i" -lt "$FILLED" ]; then
      RGB=$(grad_rgb "$i")
      BAR+=$'\033[38;2;'"${RGB}m▰"
      PCOL=$'\033[38;2;'"${RGB}m"
    else
      BAR+="${CD}▱"
    fi
    i=$((i + 1))
  done
  CTX_GAUGE="${BAR}${RS} ${PCOL}${P}%${RS}"
fi

# ── Render ────────────────────────────────────────────────────────────────────
printf '%s' "${CP}${BD} ${PROJECT}${RS}"
[ -n "$MODEL" ] && printf '%s' " ${CM}${DM}${MODEL}${RS}"
printf '%s' "$SEP"
printf '%s' "${CG} ${BRANCH}${RS}"
printf '%s' "$SEP"
printf '%s' "${CD}in${RS}${CB}${IN_F}${RS} ${CD}out${RS}${CY}${OUT_F}${RS}"
printf '%s' "$SEP"
printf '%s' "${CC}⏱ ${SESSION_TIME}${RS}"
printf '%s' "$SEP"
printf '%s' "${CC}▼${CR_F}${RS}${CD}/${RS}${CO}▲${CW_F}${RS}"
if [ -n "$COST" ]; then
  printf '%s' "$SEP"
  printf '%s' "${CR}${COST}${RS}"
fi
if [ -n "$CTX_GAUGE" ]; then
  printf '%s' "$SEP"
  printf '%s' "$CTX_GAUGE"
fi
