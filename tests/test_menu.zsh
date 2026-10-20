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

# Main menu without a box: Target, Notes, done and unload are grey.
dz -x >/dev/null
_dz_sel=1; _dz_set_main
eq  "main menu has 8 items" 8 "$#_dz_items"
eq  "without a box: Target, Notes, Mark done, Unload are off" "0 0 1 1 1 0 1 0" "$_dz_off"
has "status line without a box" "no box loaded" "$(_dz_draw 1)"

# With a box: the submenus.
dz -l box1 >/dev/null
_dz_set_main
eq  "with a box everything is on" "0 0 0 0 0 0 0 0" "$_dz_off"
has "main menu shows the Target submenu" "Target ›" "$(_dz_draw 1)"
_dz_set_sub target
eq  "target submenu" "Change IP|Switch host|Add host|Deadline" "${(j:|:)_dz_items}"
eq  "Switch host is off with only the main host" 1 "$_dz_off[2]"
has "submenu has a title" "Target · box1" "$(_dz_draw 1)"
_dz_set_sub notes
eq  "notes submenu" "Open note|Timeline entry|Add flag|Creds" "${(j:|:)_dz_items}"
eq  "Creds is off with creds = no" 1 "$_dz_off[4]"
DZ_CREDS=yes; _dz_set_sub notes
eq  "and on with creds = yes" 0 "$_dz_off[4]"
DZ_NOTE_MODE=off; _dz_set_sub notes
eq  "notes = off: the note items are off" "1 1 1 0" "$_dz_off"
DZ_CREDS=no; _dz_set_main
eq  "notes = off and creds = no: Notes › is off" 1 "$_dz_off[4]"
DZ_NOTE_MODE=vault DZ_CREDS=no

# Switch host: the main host and the extra hosts, the active one marked.
dz -t dc01 -ip 10.10.20.5 >/dev/null; dz -t dc01 >/dev/null
_dz_set_sub target
eq  "Switch host is on with more hosts" 0 "$_dz_off[2]"
_dz_set_hosts
eq  "host list: main host and dc01" "box1 dc01" "$_dz_boxnames"
has "the active host is marked" "active" "$_dz_items[2]"
eq  "and selected" 2 "$_dz_sel"
has "host list has a title" "Switch host · box1" "$(_dz_draw 1)"
out=$(_dz_draw 1)
has "status line shows the active host" "10.10.20.5 (dc01)" "$out"
dz --deadline 10d >/dev/null
plain=$(_dz_draw 1 | perl -pe 's/\e\[[0-9;?]*[A-Za-z]//g')
[[ $plain == *'left '(9d23h|10d0h)* ]] && pass "status line shows the time left" || fail "status line shows the time left"
has "status line: box and target" "box box1   target 10.10.20.5 (dc01)" "$plain"
dz --deadline none >/dev/null; dz -t box1 >/dev/null

# Arts: 10, each with equal lines (the menu centres and reveals by the first one), at
# most 76 wide and 14 high, no tabs. Widths in characters, so a UTF-8 locale (the Kali
# container has none set).
export LC_ALL=C.UTF-8
eq  "10 arts" 10 "$_dz_art_count"
for i in {1..$_dz_art_count}; do
  a=("${(@P)${:-_dz_art_$i}}")
  w=${#a[1]} bad=''
  for l in $a; do (( ${#l} == w )) || bad="line '$l' is ${#l} wide, not $w"; [[ $l == *$'\t'* ]] && bad="tab in '$l'"; done
  [[ -z $bad ]] && pass "art $i: equal lines" || fail "art $i: $bad"
  (( w <= 76 && $#a <= 14 )) && pass "art $i: fits (${w}x$#a)" || fail "art $i: ${w}x$#a is too big"
done
print 'art = 10' >> ~/.config/dropzone/config
eq  "config takes art 10 (checked against the real count)" 10 "$(_dz_config_load 2>&1; print $DZ_ART)"
