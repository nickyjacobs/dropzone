# To-dos (dz --todo) and the Next block of dz -i.

# The test vault template has no To do section: dz adds it before the timeline.
dz -n alpha -ip 10.10.10.1 >/dev/null
N=~/vault/Boxes/alpha.md
dz -j started >/dev/null
out=$(dz --todo check the web root for backups)
has "--todo: says the number" "to-do #1: check the web root for backups" "$out"
ok  "--todo: a checklist line" grep -qx -- '- \[ \] check the web root for backups' $N
eq  "--todo: section added before the timeline" "## To do|## Timeline" "$(grep -E '^## (To do|Timeline)' $N | paste -sd'|' -)"
dz --todo "try 'admin:admin' on /login --help \$(id) \`id\` a|b back\\slash" >/dev/null
ok  "--todo: text kept as typed" grep -qF -- "- [ ] try 'admin:admin' on /login --help \$(id) \`id\` a|b back\\slash" $N
has "--todo: output keeps a backslash" 'back\slash' "$(dz --todo)"
dz --todo zz >/dev/null
out=$(dz --todo)
has "--todo lists the open ones" "  1  check the web root" "$out"
has "--todo counts" "3 open" "$out"
nok "--todo: no host column in a single box" grep -q ' alpha ' <<< "$out"

# Tick off.
has "done <nr> ticks it off" "done: check the web root" "$(dz --todo done 1)"
ok  "done: [x] in the note" grep -qx -- '- \[x\] check the web root for backups' $N
has "done: a timeline line" "· done: check the web root for backups" "$(cat $N)"
nok "done: no longer listed" grep -q 'web root' <<< "$(dz --todo)"
has "the count leaves out the done one" "2 open, 1 done" "$(dz --todo)"
has "--all shows it with a tick" "✓   1  check the web root" "$(dz --todo --all)"
nok "done twice fails" dz --todo done 1
has "and says so" "already done" "$(dz --todo done 1 2>&1)"
nok "done of an unknown number fails" dz --todo done 9
nok "done without a number fails" dz --todo done
dz --todo done with the nmap scan >/dev/null
ok  "'done' with words is a to-do" grep -qx -- '- \[ \] done with the nmap scan' $N
has "numbers stay the same after ticking off" "  4  done with the nmap scan" "$(dz --todo)"
dz --todo done 3 >/dev/null
ok  "done 3 ticks the third, not the third open one" grep -qx -- '- \[x\] zz' $N

# Ticked in Obsidian (by hand): dz reads the note.
perl -pi -e 's/^- \[ \] try/- [X] try/' $N
nok "ticked by hand: not open" grep -q "admin:admin" <<< "$(dz --todo)"

# A box with more hosts: tagged with the active host.
dz -n corp -ip 10.10.20.1 >/dev/null
dz -t dc01 -ip 10.10.20.5 >/dev/null
C=~/vault/Boxes/corp.md
has "main host tag" "to-do #1 (corp)" "$(dz --todo enum shares)"
dz -t dc01 >/dev/null
dz --todo kerberoast >/dev/null
ok  "the active host tags it" grep -qx -- '- \[ \] dc01 · kerberoast' $C
out=$(dz --todo)
has "list with a host column" "2  dc01  kerberoast" "$out"
print -r -- '- [ ] web · not a host, just text' >> $C   # outside the section: ignored
perl -0pi -e 's/(- \[ \] dc01 · kerberoast\n)/$1- [ ] smb · not a host tag\n/' $C
has "an unknown tag stays text" "smb · not a host tag" "$(dz --todo)"

# dz -i: the Next block, and one host.
out=$(dz -i)
has "-i: Next block" "[+] Next" "$out"
has "-i: open to-dos with their host" "#2  dc01 · kerberoast" "$out"
has "-i: the last timeline lines" "last" "$out"
out=$(dz -i dc01)
has "-i <host>: the host" "[+] dc01" "$out"
has "-i <host>: target" "target" "$out"
has "-i <host>: its to-dos" "#2  kerberoast" "$out"
nok "-i <host>: not the other host's" grep -q 'enum shares' <<< "$out"
has "-i <main host>: untagged and tagged to-dos" "#1  enum shares" "$(dz -i corp)"
nok "-i unknown host fails" dz -i nope
has "-i <host> completes" "dc01" "$(_dz_box_read ~/boxes/corp; print -r -- ${_dz_bh%% *})"

# With more than 5 open to-dos, -i shows 5.
for i in {1..6}; do dz --todo item $i >/dev/null; done
has "-i: at most 5 to-dos" "more (dz --todo)" "$(dz -i)"

# add_sections = no: no section is added, the note stays as it is.
dz -n gamma -ip 10.10.30.1 >/dev/null
G=~/vault/Boxes/gamma.md
cp $G ~/gamma.before
DZ_ADD_SECTIONS=no
nok "add_sections = no: --todo fails without the section" dz --todo x
has "and names the heading" "'## To do'" "$(dz --todo x 2>&1)"
has "-j: E413 instead of adding a timeline" "E413" "$(dz -j x 2>&1)"
has "a timeline line on the side: W403" "W403" "$(dz --deadline 10d 2>&1; dz --deadline none >/dev/null 2>&1)"
ok  "the note is untouched" cmp -s $G ~/gamma.before
print -r -- $'\n## To do\n' >> $G
ok  "with the heading it works" dz --todo x
DZ_ADD_SECTIONS=yes
print 'add_sections = no' >> ~/.config/dropzone/config
eq  "config takes add_sections" no "$(_dz_config_load 2>&1; print $DZ_ADD_SECTIONS)"
has "--config show lists it" "add_sections" "$(_dz_config_load 2>/dev/null; dz --config show)"

# Notes off, no box.
DZ_NOTE_MODE=off; nok "--todo with notes = off fails" dz --todo x; DZ_NOTE_MODE=vault
dz -x >/dev/null
nok "--todo without a box fails" dz --todo x

# Review fixes: spaces around the text, a heading on the last line, the timeline warning.
dz -n delta -ip 10.10.40.1 >/dev/null
D=~/vault/Boxes/delta.md
dz --todo first >/dev/null
has "leading spaces: 'done 1' still ticks off" "done: first" "$(dz --todo '  done 1 ')"
has "only spaces: lists, adds nothing" "no open to-dos" "$(dz --todo '   ')"
nok "only spaces: no blank to-do" grep -qx -- '- \[ \] *' $D
print -rn -- $'---\nupdated: x\n---\n## To do' > $D
has "a To do heading on the last line works" "to-do #1" "$(dz --todo last line)"
DZ_ADD_SECTIONS=no
print -r -- $'---\nupdated: x\n---\nbody' > $D
dz --deadline 10d >/dev/null 2>&1
eq  "add_sections = no: --deadline still succeeds" 0 "$?"
has "-j without a timeline: E413" "E413" "$(dz -j x 2>&1)"
DZ_ADD_SECTIONS=yes; dz --deadline none >/dev/null
