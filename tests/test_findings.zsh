# Findings (dz --finding) and evidence under the active finding.

DISPLAY=:0
_dz_shot_tool() { REPLY=fake }
_dz_shot_take() { print png > $2 }

# The exam template: a Findings table.
dz -n exam -ip 10.10.10.1 --template exam >/dev/null
dz -t dc01 -ip 10.10.10.5 >/dev/null
dz -t dc01 >/dev/null
N=~/vault/Boxes/exam.md
has "--finding alone without findings" "no findings in exam yet" "$(dz --finding)"
out=$(dz --finding SMB signing disabled)
has "--finding: number, title and host" "F1 · SMB signing disabled (dc01)" "$out"
ok  "a heading under Findings" grep -qx '### F1 · SMB signing disabled' $N
ok  "with host and status" grep -qx '\*\*Host:\*\* dc01 · \*\*Status:\*\* open' $N
ok  "a row in the table, example row gone" grep -qx '| F1 | SMB signing disabled | dc01 | | 0 | open |' $N
nok "the empty example row is gone" grep -qx '| | | | | | |' $N
eq  "the active finding is stored" 1 "$(<~/boxes/exam/.finding)"
has "timeline line" "· finding F1: SMB signing disabled (dc01)" "$(cat $N)"

# Evidence goes under the finding.
dz -s nxc output >/dev/null
f=(~/boxes/exam/evidence/exam_*_nxc-output.png(N))
eq  "-s: still saved in evidence/" 1 "$#f"
sec=$(sed -n '/^### F1/,/^## /p' $N)
has "-s: embedded under F1" "![[Boxes/attachments/exam/${f[1]:t}]]" "$sec"
has "-s: the timeline points to it" "· screenshot: nxc output → F1" "$(sed -n '/^## Timeline/,/^## /p' $N)"
nok "-s: no embed in the timeline" grep -q 'attachments' <<< "$(sed -n '/^## Timeline/,/^## /p' $N)"
_dz_log_preexec "nxc smb \$TARGETS | dz -e signing"
out=$(print 'SMB 10.10.10.5 signing:False' | dz -e signing)
has "-e: says where it went" "under F1" "$out"
has "-e: code block under F1" $'  ````text\n  $ nxc smb $TARGETS\n  SMB 10.10.10.5 signing:False' "$(sed -n '/^### F1/,/^## /p' $N)"
ok  "Evidence column counts" grep -qx '| F1 | SMB signing disabled | dc01 | | 2 | open |' $N
has "-s with a desktop and a finding says so" "under F1" "$(dz -s again)"

# A second finding, special characters in the title.
dz --finding 'Weak | password $(id) `id` policy' >/dev/null
ok  "title kept in the heading" grep -qxF '### F2 · Weak | password $(id) `id` policy' $N
ok  "a | is escaped in the table" grep -qF '| F2 | Weak \| password $(id) `id` policy | dc01 |' $N
eq  "the new one is active" 2 "$(<~/boxes/exam/.finding)"
eq  "F1 keeps its evidence count" 1 "$(grep -c '^| F1 .* | 3 | open |$' $N)"
out=$(dz --finding)
has "list: the active one marked" "▶ F2" "$out"
has "list: evidence count" "3 evidence  SMB signing disabled" "$out"
dz -s pw policy >/dev/null
nok "F1 doesn't get F2's evidence" grep -q 'pw policy' <<< "$(sed -n '/^### F1/,/^### F2/p' $N)"
has "F2 gets it" "screenshot: pw policy" "$(sed -n '/^### F2/,/^## /p' $N)"

# Switch, off, done.
has "--finding 1 makes F1 active" "active: F1" "$(dz --finding 1)"
has "F2 works too" "active: F2" "$(dz --finding F2)"
nok "an unknown number fails" dz --finding 9
has "off stops it" "no active finding (was F2)" "$(dz --finding off)"
ok  "off removes .finding" test ! -e ~/boxes/exam/.finding
dz -s after off >/dev/null
has "without a finding: back in the timeline" "![[Boxes/attachments/exam/" "$(sed -n '/^## Timeline/,/^## /p' $N)"
nok "done without an active one fails" dz --finding done
has "done <nr>" "F1 done" "$(dz --finding done 1)"
ok  "done: status in the heading line" grep -qx '\*\*Host:\*\* dc01 · \*\*Status:\*\* done' $N
ok  "done: status in the table" grep -q '^| F1 .* | done |$' $N
has "done again says so" "already done" "$(dz --finding done F1)"
dz --finding 2 >/dev/null
has "done of the active one clears it" "no active finding now" "$(dz --finding done)"
ok  "and removes .finding" test ! -e ~/boxes/exam/.finding

# A heading removed by hand: W404, evidence back to the timeline.
dz --finding 2 >/dev/null
perl -0pi -e 's/^### F2 · .*\n//m' $N
has "a missing finding warns" "W404" "$(print x | dz -e gone 2>&1)"
ok  "and .finding goes" test ! -e ~/boxes/exam/.finding
print 'rm -rf ~' > ~/boxes/exam/.finding
has "a removed finding's number isn't reused" "F3 · Reuse" "$(dz --finding Reuse)"
perl -0pi -e 's/^### F3 · .*\n//m; s/^\| F3 .*\n//m' $N
has "a .finding with junk is ignored" "no active finding" "$(print 'rm -rf ~' > ~/boxes/exam/.finding; dz --finding)"

# The bundled box template: no table, just headings.
dz -n plain -ip 10.10.20.1 --template $_dz_repo/templates/box-note.md >/dev/null
P=~/vault/Boxes/plain.md
dz --finding Anonymous FTP >/dev/null
eq  "heading inside the Findings section" "## Findings|### F1 · Anonymous FTP|## Timeline" "$(grep -E '^##' $P | grep -A1 -B1 'F1' | paste -sd'|' -)"
has "single box: host is the box" "**Host:** plain" "$(cat $P)"
dz --finding Second one >/dev/null
eq  "F2 comes after F1" "### F1 · Anonymous FTP|### F2 · Second one" "$(grep '^### F' $P | paste -sd'|' -)"

# A note without a Findings section gets one; not with add_sections = no.
dz -n bare -ip 10.10.30.1 >/dev/null
B=~/vault/Boxes/bare.md
dz --finding X >/dev/null
ok  "Findings section added" grep -qx '## Findings' $B
dz -n bare2 -ip 10.10.30.2 >/dev/null
DZ_ADD_SECTIONS=no
nok "add_sections = no: --finding fails" dz --finding X
has "and says which heading" "'## Findings'" "$(dz --finding X 2>&1)"
DZ_ADD_SECTIONS=yes

# Folder notes: relative embed under the finding.
DZ_NOTE_MODE=folder
dz -n folder -ip 10.10.40.1 --template $_dz_repo/templates/box-note.md >/dev/null
dz --finding LFI >/dev/null
dz -s lfi proof >/dev/null
has "folder: relative embed under F1" "![lfi proof](evidence/folder_" "$(sed -n '/^### F1/,/^## /p' ~/boxes/folder/notes.md)"
DZ_NOTE_MODE=off
nok "--finding with notes = off fails" dz --finding x
has "-s with notes = off still saves" "screenshot:" "$(dz -s off 2>&1)"
DZ_NOTE_MODE=vault

# dz -i shows the active finding; dz -i <host> its findings.
dz -l exam >/dev/null
dz --finding Kerberoastable svc >/dev/null
has "-i: the active finding" "F4 · Kerberoastable svc (dc01)" "$(dz -i)"
has "-i <host>: findings of the host" "F4  open  0 evidence  Kerberoastable svc" "$(dz -i dc01)"
nok "-i <main host>: not dc01's findings" grep -q Kerberoastable <<< "$(dz -i exam)"

# Creds that work on a host, in dz -i <host>, without the secret.
DZ_CREDS=yes
dz -c 'corp\svc_sql:S3cret!' kerberoast --valid dc01 >/dev/null
dz -c 'other:pw' >/dev/null
out=$(dz -i dc01)
has "-i <host>: creds that work there" 'corp\svc_sql  (kerberoast)' "$out"
nok "-i <host>: never the secret" grep -q 'S3cret' <<< "$out"
nok "-i <host>: not creds without that host" grep -q 'other' <<< "$out"
has "-c prints a backslash user as typed" 'corp\svc_sql' "$(dz -c)"
DZ_CREDS=no
nok "creds = no: no creds block" grep -q 'Creds that work' <<< "$(dz -i dc01)"

# SysReptor: -e under a finding names it.
reptor() { print -r -- "$*" >> ~/reptor.calls; [[ $* == *note* ]] && cat >> ~/reptor.calls; return 0 }
commands[reptor]=reptor; DZ_SYSREPTOR=yes
print 'out' | dz -e asrep >/dev/null; sleep 1
has "sysreptor: the finding in the caption" "**F4 · asrep**" "$(cat ~/reptor.calls)"
unset 'commands[reptor]'; unfunction reptor; DZ_SYSREPTOR=no

# Review fixes.
dz -n rev -ip 10.10.50.1 --template $_dz_repo/templates/box-note.md >/dev/null
V=~/vault/Boxes/rev.md
dz --finding One >/dev/null
perl -pi -e 's/^### F1 · One/### F1 renamed/' $V
dz -i >/dev/null 2>&1
ok  "dz -i doesn't clear a stale finding" test -f ~/boxes/rev/.finding
has "the next -s still warns" "W404" "$(dz -s x 2>&1)"
perl -pi -e 's/^### F1 renamed/### F1 · One/' $V
dz --finding done 1 >/dev/null
has "picking a done finding opens it again" "open again" "$(dz --finding 1)"
ok  "status open in the note" grep -qx '\*\*Host:\*\* rev · \*\*Status:\*\* open' $V
has "OFF in capitals stops it" "no active finding" "$(dz --finding OFF)"
nok "and isn't a finding" grep -q '### F2 · OFF' $V
DZ_ADD_SECTIONS=no
perl -0pi -e 's/## Timeline\n//' $V
has "-s without a timeline says not in the note" "not in the note" "$(dz -s y 2>/dev/null)"
has "-e without a timeline says not in the note" "not in the note" "$(print z | dz -e z 2>/dev/null)"
DZ_ADD_SECTIONS=yes

# dz -i <main host> counts the user and root slots.
dz -n single -ip 10.10.60.1 --template $_dz_repo/templates/box-note.md >/dev/null
dz -f 0123456789abcdef0123456789abcdef >/dev/null
has "-i <box>: user flag counted" "flags      1" "$(dz -i single)"

# Review round 2: done without a Status line fails; the menu form always creates.
dz -l rev >/dev/null
dz --finding Two >/dev/null
perl -0pi -e 's/\*\*Host:\*\* rev · \*\*Status:\*\* open\n\n(?=- |\n*$)//; s/(### F\d+ · Two\n\n)\*\*Host:\*\*[^\n]*\n/$1/' $V
nok "done without a Status line fails" dz --finding done
has "with E419" "E419" "$(dz --finding done 2>&1)"
has "the menu form makes '2' a title" "· 2 (rev)" "$(_dz_finding 2 new)"
has "and 'off' too" "· off (rev)" "$(_dz_finding off new)"

# Review round 3.
dz -n r3 -ip 10.10.70.1 --template exam >/dev/null
X=~/vault/Boxes/r3.md
dz --finding One >/dev/null; dz --finding Two >/dev/null; dz --finding 1 >/dev/null
perl -0pi -e 's/(### F2 · Two\n\n)\*\*Host:\*\*[^\n]*\n/$1/' $X
nok "done without a Status line fails" dz --finding done 2
ok  "and the table row is untouched" grep -q '^| F2 | Two | r3 | | 0 | open |$' $X
eq  "the active finding stays" 1 "$(<~/boxes/r3/.finding)"
perl -pi -e 's/^(\*\*Host:\*\* r3 · \*\*Status:\*\*) open/$1 Done/' $X
has "Done by hand reads as done" "already done" "$(dz --finding done 1)"
has "a copy of a heading outside Findings is left alone" "F3 done" "$(print -r -- $'\n## Notes\n\n### F3 · Copy\n\n**Host:** r3 · **Status:** open\n' >> $X; dz --finding Three >/dev/null; dz --finding done 3; true)"
ok  "the copy keeps open" grep -qx '\*\*Host:\*\* r3 · \*\*Status:\*\* open' <(sed -n '/^## Notes/,$p' $X)
nok "a blank menu title makes nothing" _dz_finding '   ' new
nok "no empty finding heading" grep -qE '^### F[0-9]+ · *$' $X

# A note that can't be written: E420, not E413. Root writes anyway (the Kali container in
# CI), so only as a normal user.
if (( EUID )); then
dz -n ro -ip 10.10.71.1 >/dev/null
chmod a-w ~/vault/Boxes/ro.md
has "read-only note: E420" "E420" "$(dz --finding X 2>&1)"
nok "and no E413" grep -q E413 <<< "$(dz --todo x 2>&1)"
chmod u+w ~/vault/Boxes/ro.md
fi

# Review round 4: a read-only note changes nothing, leading zeros.
dz -n ro2 -ip 10.10.72.1 --template exam >/dev/null
O2=~/vault/Boxes/ro2.md
dz --finding One >/dev/null; dz --todo first >/dev/null
cp $O2 ~/ro2.before
if (( EUID )); then
chmod a-w $O2
for c in "dz --finding done 1" "dz --todo done 1" "dz --finding Two" "dz -j x" "dz -f $_dz_repo"; do
  has "read-only: '${c[1,20]}' says E420" "E420" "$(eval $c 2>&1)"
done
has "read-only: -e says E420" "E420" "$(print x | dz -e cap 2>&1)"
chmod u+w $O2
ok  "read-only: the note is unchanged" cmp -s $O2 ~/ro2.before
fi
has "--finding 01 is F1" "active: F1" "$(dz --finding 01)"

# Review round 5: a code block with '#' lines inside a finding; numbers never reused.
dz -n r5 -ip 10.10.73.1 --template $_dz_repo/templates/box-note.md >/dev/null
Q=~/vault/Boxes/r5.md
dz --finding SQL injection >/dev/null
perl -0pi -e 's/(\*\*Status:\*\* open\n)/$1\n```bash\n# dump the users table\nsqlmap -u x --dump\n```\n/' $Q
print 'db dumped' | dz -e sqlmap >/dev/null
eq  "evidence after the code block, not inside it" "sqlmap -u x --dump|\`\`\`|" "$(grep -A2 '^sqlmap -u x' $Q | paste -sd'|' - | cut -d'|' -f1-3)"
has "evidence is under the finding" "output: sqlmap" "$(sed -n '/^### F1/,/^## /p' $Q)"
has "the count sees it" "1 evidence" "$(dz --finding)"
dz --finding Two >/dev/null
perl -0pi -e 's/^### F2 · Two\n.*?(?=^## )//sm' $Q
has "a removed last finding's number isn't reused" "F3 · Three" "$(dz --finding Three 2>/dev/null)"

# -s / -e with no timeline and no finding: W403 names the heading.
dz --finding off >/dev/null
DZ_ADD_SECTIONS=no; perl -0pi -e 's/^## Timeline\n//m' $Q
has "-e: W403 with the heading" "W403" "$(print x | dz -e nowhere 2>&1)"
DZ_ADD_SECTIONS=yes

# Review round 6: fences in a list item, inline triple backticks, an Evidence cell of your own.
dz -n r6 -ip 10.10.74.1 --template $_dz_repo/templates/box-note.md >/dev/null
W=~/vault/Boxes/r6.md
dz --finding One >/dev/null
perl -0pi -e 's/(\*\*Status:\*\* open\n)/$1\nRepro:\n\n- ```bash\n  smbclient -L x -N\n  ```\n\n```id``` returned uid=0\n/' $W
print 'Sharename' | dz -e shares >/dev/null
has "list-item fence: evidence under F1, before the timeline" "output: shares" "$(sed -n '/^### F1/,/^## Timeline/p' $W)"
dz --finding Two >/dev/null
eq  "inline backticks: F2 lands before the timeline" "### F2 · Two|## Timeline" "$(grep -E '^(### F2|## Timeline)' $W | paste -sd'|' -)"
perl -0pi -e 's/\*\*Status:\*\* open\n\n(?=- )/**Status:** open\n\n```\nnever closed\n/' $W
dz --finding 2 >/dev/null; print x | dz -e unclosed >/dev/null
has "an unclosed fence masks nothing" "output: unclosed" "$(sed -n '/^### F2/,/^## Timeline/p' $W)"
dz -n r6b -ip 10.10.74.2 --template exam >/dev/null
E=~/vault/Boxes/r6b.md
dz --finding Kerberoast >/dev/null
perl -pi -e 's/^\| F1 \| Kerberoast \| r6b \| \| 0 \| open \|$/| F1 | Kerberoast | r6b | High | [[kerb.png]] | open |/' $E
print hash | dz -e roast >/dev/null
ok  "an Evidence cell with your own text stays" grep -qF '| F1 | Kerberoast | r6b | High | [[kerb.png]] | open |' $E
