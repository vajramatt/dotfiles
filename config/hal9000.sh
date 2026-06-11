#!/usr/bin/env zsh
# HAL 9000 eye, rendered in truecolor — run it, or source it from the MOTD.
# Pure zsh math (zsh/mathfunc), no figlet/toilet dependency. Must stay fast and sourceable.
#
# Each text cell is TWO pixels via the ▀ half-block (fg = top, bg = bottom),
# so an N-row eye renders from a 2N-pixel-tall grid — that's what keeps the
# circle round at MOTD size.
#
# Usage: hal9000.sh [rows] [nocaption]
#   rows       eye height in text lines, odd looks best (default 19)
#   nocaption  skip the "H A L 9 0 0 0" line (the MOTD passes this)

zmodload zsh/mathfunc 2>/dev/null

# Color of the pixel at (px, py) -> $reply as "r;g;b", or "" outside the eye.
# Reads cx/cy from the caller's scope (zsh dynamic scoping).
_hal_px() {
  local fx=$(( ($1 - cx) / cx )) fy=$(( ($2 - cy) / cy ))
  local d=$(( sqrt(fx * fx + fy * fy) )) t r g b
  if (( d > 0.985 )); then                # outside the eye
    reply=""; return
  elif (( d > 0.88 )); then               # brushed-metal rim, lit from above
    r=$(( int(150 - fy * 55) )); g=$r; b=$(( r + 6 ))
  elif (( d > 0.76 )); then               # black bezel between rim and glass
    r=16; g=16; b=18
  elif (( fy < -0.40 && fy > -0.66 && d > 0.50 && d < 0.64 )); then
    r=225; g=212; b=205                   # thin specular arc on the upper glass
  elif (( d < 0.06 )); then               # the burning center
    r=255; g=225; b=120
  elif (( d < 0.13 )); then               # orange corona around the center
    r=255; g=150; b=40
  else                                    # red sphere, bright core -> dark edge
    t=$(( d / 0.76 ))
    r=$(( int(70 + 185 * (1.0 - t)) ))
    g=$(( int(70 * (1.0 - t) * (1.0 - t)) ))
    b=$(( int(28 * (1.0 - t) * (1.0 - t)) ))
  fi
  reply="${r};${g};${b}"
}

hal9000() {
  emulate -L zsh
  local rows=${1:-19}
  local H=$(( rows * 2 )) W=$(( rows * 2 + 1 ))   # pixel grid; cell aspect ~1:2 makes pixels ~square
  local cx=$(( (W - 1) / 2.0 )) cy=$(( (H - 1) / 2.0 ))
  local x ty out top bot reply

  for (( ty = 0; ty < rows; ty++ )); do
    out=""
    for (( x = 0; x < W; x++ )); do
      _hal_px $x $(( 2 * ty ));     top=$reply
      _hal_px $x $(( 2 * ty + 1 )); bot=$reply
      if [[ -z $top && -z $bot ]]; then
        out+=$'\033[0m '
      elif [[ -n $top && -n $bot ]]; then
        out+=$'\033[38;2;'"${top}"$';48;2;'"${bot}"$'m▀'
      elif [[ -n $top ]]; then
        out+=$'\033[0m\033[38;2;'"${top}"$'m▀'
      else
        out+=$'\033[0m\033[38;2;'"${bot}"$'m▄'
      fi
    done
    print -r -- "${out}"$'\033[0m'
  done

  if [[ "${2:-}" != nocaption ]]; then
    local cap="H  A  L    9  0  0  0" pad=$(( (W - 21) / 2 ))
    (( pad < 0 )) && pad=0
    printf '%*s\033[38;2;150;150;156m%s\033[0m\n' $pad "" "$cap"
  fi
}

hal9000 "$@"
unset -f hal9000 _hal_px
