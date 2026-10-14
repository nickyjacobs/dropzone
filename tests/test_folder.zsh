# notes = folder (the default) and notes = off, template order, old config keys, --config check.

C=$DZ_CONFIG B=~/boxes
print -r -- $'[box]\nping = no' > $C; _dz_config_load
eq  "no vault in the config = folder" folder "$DZ_NOTE_MODE"

dz -n alpha -ip 10.10.10.1 -h alpha.htb >/dev/null 2>&1
N=$B/alpha/notes.md
ok  "note in the box folder" test -f $N
ok  "no vault note" test ! -e ~/vault/Boxes/alpha.md
eq  "bundled template used" '# alpha' "$(grep '^# ' $N)"
has "{{ip}} and {{hosts}} filled" "| 10.10.10.1 | alpha.htb |" "$(cat $N)"
dz -ip 10.10.10.2 >/dev/null 2>&1
eq  "IP change updates the note" "ip: 10.10.10.2" "$(grep '^ip:' $N)"

# Flags in the plain layout, timeline, screenshot next to the note.
dz -f 0123456789abcdef0123456789abcdef >/dev/null
eq  "plain flag layout" "- **User flag:** 0123456789abcdef0123456789abcdef" "$(grep 'User flag' $N)"
dz -f root fedcba9876543210fedcba9876543210 >/dev/null
eq  "root flag in the plain layout" "- **Root flag:** fedcba9876543210fedcba9876543210" "$(grep 'Root flag' $N)"
eq  "root flag marks done (folder note)" done "$(_dz_status alpha)"
dz -j found it >/dev/null
has "timeline in the bundled template" "· found it" "$(sed -n '/^## Timeline/,/^## Flags/p' $N)"
DISPLAY=:0; _dz_shot_tool() { REPLY=fake }; _dz_shot_take() { print png > $2 }
dz -s 'web [login] page' >/dev/null
ok  "screenshot: plain Markdown embed next to the note" grep -qE '^  !\[web login page\]\(evidence/alpha_.*_web-login-page\.png\)$' $N
ok  "no vault copy" test ! -e ~/vault/Boxes/attachments
DZ_CREDS=yes; dz -c 'bob:pw1' SSH >/dev/null
eq  "creds row in the folder note" "| SSH | bob | pw1 | | |" "$(grep '| bob |' $N)"
has "-o without editor or desktop prints the path" "note: $N" "$(DISPLAY= VISUAL= EDITOR= dz -o)"

# Archived box: status still read from the note in _archive/.
cd ~; dz -a alpha >/dev/null
eq  "status of an archived folder note" done "$(_dz_status alpha)"
dz -l alpha >/dev/null

# Remove: the note goes along with the folder, no question about it.
dz -r alpha -y >/dev/null 2>&1
ok  "rm takes the folder note along" test ! -e $N

# Template order: config > ~/.config/dropzone/templates > bundled.
mkdir -p ${C:h}/templates; print -r -- '# mine {{name}}' > ${C:h}/templates/box-note.md
dz -n beta -ip 10.10.10.3 >/dev/null 2>&1
eq  "user template wins over the bundled one" "# mine beta" "$(head -1 $B/beta/notes.md)"
print -r -- '# config {{name}}' > ${C:h}/other.md
print -r -- 'template = other.md' >> $C; _dz_config_load
dz -n gamma -ip 10.10.10.4 >/dev/null 2>&1
eq  "template from the config wins" "# config gamma" "$(head -1 $B/gamma/notes.md)"
print -r -- 'template = missing.md' >> $C; _dz_config_load
has "missing template is reported" "template not found" "$(dz -n delta -ip 10.10.10.5 2>&1)"

# notes = off
print -r -- $'[box]\nping = no\n[notes]\nnotes = off' > $C; _dz_config_load
dz -n eps -ip 10.10.10.6 >/dev/null 2>&1
ok  "notes = off: no note" test ! -e $B/eps/notes.md
nok "notes = off: -j fails" dz -j x
has "and says why" "notes are off" "$(dz -j x 2>&1)"
dz -s shot >/dev/null
ok  "notes = off: screenshot still in evidence/" test -n "$(print $B/eps/evidence/*.png(N))"

# Old config key 'notes = <folder>' still means vault.
print -r -- $'[paths]\nvault = '$HOME$'/vault\nnotes = Boxes' > $C; _dz_config_load
eq  "old 'notes = Boxes' = vault mode" "vault|Boxes" "$DZ_NOTE_MODE|$DZ_NOTES"
has "--config check reports the old form" "old form" "$(dz --config check)"
print -r -- $'[paths]\nvault = '$HOME$'/vault' > $C; _dz_config_load
eq  "vault without notes = vault mode" vault "$DZ_NOTE_MODE"
print -r -- $'notes = vault' > $C
has "notes = vault without a vault is reported" "needs 'vault" "$(_dz_config_load 2>&1)"
_dz_config_load 2>/dev/null
eq  "and falls back to folder" folder "$DZ_NOTE_MODE"

# --config check lists settings that aren't in the config.
out=$(dz --config check)
has "--config check lists a missing key" "iface = tun0" "$out"
has "with its comment" "Network interface" "$out"
cp $_dz_repo/config.example $C
has "complete config: nothing missing" "every setting" "$(dz --config check)"
