# Menu drawing (without a terminal): items, and a long box list that scrolls.

for i in {1..30}; do dz -n box$i -ip 10.10.10.$i >/dev/null; done
cd ~; dz -a box30 >/dev/null
COLUMNS=100 LINES=30
_dz_art=("${_dz_art_1[@]}") _dz_reveal=()
local -a _dz_items _dz_boxnames _dz_off; local _dz_mode _dz_title _dz_purpose _dz_tun; local -i _dz_sel=1 _dz_formrow _dz_fpad

_dz_set_main
has "main menu in English" "New box" "$(_dz_draw 1)"

_dz_set_boxes load
eq  "load list includes the archive" 30 "$#_dz_items"
has "archived box marked" "archived" "$_dz_items[30]"
out=$(_dz_draw 1)
has "long list shows 'more' below" "↓" "$out"
nok "long list hides the last box" grep -q 'box29 ' <<< "$out"
ok  "frame fits the terminal" test $(print -r -- "$out" | wc -l) -le $LINES
_dz_sel=30; out=$(_dz_draw 1)
has "selection at the end scrolls down" "box30" "$out"
has "and shows 'more' above" "↑" "$out"

_dz_set_boxes delete
eq  "remove list skips the archive" 29 "$#_dz_items"
