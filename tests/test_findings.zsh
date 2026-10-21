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
has "-i: the active finding" "F3 · Kerberoastable svc (dc01)" "$(dz -i)"
has "-i <host>: findings of the host" "F3  open  0 evidence  Kerberoastable svc" "$(dz -i dc01)"
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
has "sysreptor: the finding in the caption" "**F3 · asrep**" "$(cat ~/reptor.calls)"
unset 'commands[reptor]'; unfunction reptor; DZ_SYSREPTOR=no
