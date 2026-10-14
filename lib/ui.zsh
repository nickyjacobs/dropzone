# ui: the block layout of help and overviews (dz --help, dz -i, dz --config show/check):
#
#   ────────────────────────────────────────────────────────────────
#   [+] Boxes
#       -n <name> -ip <ip>       new box
#
# Colour only on a terminal without NO_COLOR (_dz_color in config.zsh).

_dz_ui() {
  if _dz_color; then
    typeset -g _ug=$'\e[1;38;5;46m' _uk=$'\e[38;5;118m' _ud=$'\e[38;5;246m' _ul=$'\e[38;5;28m' _ur=$'\e[0m'
  else
    typeset -g _ug='' _uk='' _ud='' _ul='' _ur=''
  fi
}

# A rule line.
_dz_rule() { print -r -- "${_ul}${(l:64::─:)${:-}}${_ur}" }

# _dz_head <title> [extra]: '[+] Title', with an optional dimmed extra.
_dz_head() { print -r -- "${_ug}[+] $1${_ur}${2:+  ${_ud}$2${_ur}}" }

# _dz_row <key> <text> [width]: an indented row, key padded to width (default 24).
_dz_row() { printf '    %s%-*s%s %s\n' "$_uk" ${3:-24} "$1" "$_ur" "$2" }
