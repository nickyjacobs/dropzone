# Status, done, archive, restore, open the note.

N=~/vault/Boxes
print -r -- $'---\ntitle: "{{title}}"\nupdated: {{date}}\nip: \n---\nbody' > ~/vault/Templates/Box-note.md
dz -n alpha -ip 10.10.10.1 >/dev/null
dz -n beta -ip 10.10.10.2 >/dev/null

eq  "status without a status line is -" "-" "$(_dz_status alpha)"
dz -d alpha >/dev/null
eq  "-d sets status done (added)" done "$(_dz_status alpha)"
eq  "-d sets updated to today" "updated: $(date +%F)" "$(grep '^updated:' $N/alpha.md)"
eq  "status lives in the frontmatter" 1 "$(awk 'NR>1 && /^---$/{exit} /^status:/' $N/alpha.md | wc -l | tr -d ' ')"
dz -d alpha >/dev/null
eq  "-d twice: one status line" 1 "$(grep -c '^status:' $N/alpha.md)"
dz -d >/dev/null
eq  "-d without a name = loaded box" done "$(_dz_status beta)"
has "-v shows the status" "done" "$(dz -v)"
nok "-d unknown box fails" dz -d gamma

sed -i.bak 's/^status: .*/status: af/' $N/beta.md
eq  "old status af reads as done" done "$(_dz_status beta)"

dz -l alpha >/dev/null
dz -a alpha >/dev/null
ok  "-a moves to _archive" test -f ~/boxes/_archive/alpha/.dropzone
ok  "-a: folder gone from boxes" test ! -e ~/boxes/alpha
ok  "-a: note stays" test -f $N/alpha.md
eq  "-a unloads the loaded box" "" "${BOX-}"
nok "-a: no longer in -v" grep -q alpha <<< "$(dz -v)"
has "-v mentions the archive" "1 archived" "$(dz -v)"
has "-v --all shows the archive" "archived" "$(dz -v --all)"
nok "-a again fails" dz -a alpha
nok "-a without a name fails" dz -a

dz -l alpha >/dev/null
ok  "-l restores an archived box" test -f ~/boxes/alpha/.dropzone
eq  "restore: status active" active "$(_dz_status alpha)"
eq  "restore: box loaded" alpha "$BOX"

has "-o gives an obsidian link without a GUI" "obsidian://open?vault=vault&file=Boxes%2Falpha" "$(DISPLAY= WAYLAND_DISPLAY= dz -o)"
nok "-o without a note fails" dz -o gamma
eq  "urlenc spaces" "My%20Boxes%2Fa" "$(_dz_urlenc 'My Boxes/a')"
