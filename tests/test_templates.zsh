# The four bundled templates: every dz command finds its place, and no section is added.

DISPLAY=:0
_dz_shot_tool() { REPLY=fake }
_dz_shot_take() { print png > $2 }
DZ_CREDS=yes
U=0123456789abcdef0123456789abcdef R=fedcba9876543210fedcba9876543210
local -i i=0
for t in templates/box-note.md templates/box-note-extended.md examples/obsidian/Box-note.md examples/obsidian/Box-note-extended.md; do
  (( i++ )); b=tpl$i; N=~/vault/Boxes/$b.md
  dz -n $b -ip 10.10.9$i.10 -h $b.htb --template $_dz_repo/$t >/dev/null
  heads=$(grep -c '^## ' $N)
  dz -t dc01 -ip 10.10.9$i.11 -h dc01.$b.htb >/dev/null
  mkdir -p ~/boxes/$b/scans
  print -r -- "<?xml version=\"1.0\"?><nmaprun><host><address addr=\"10.10.9$i.10\" addrtype=\"ipv4\"/><ports>
<port protocol=\"tcp\" portid=\"445\"><state state=\"open\"/><service name=\"microsoft-ds\" product=\"Samba smbd\" version=\"4.6.2\"/></port>
</ports></host></nmaprun>" > ~/boxes/$b/scans/all.xml
  dz -p >/dev/null 2>&1
  dz -c "svc_sql:Passw0rd" config --valid dc01 >/dev/null
  dz --todo kerberoast svc_sql >/dev/null
  dz --finding SMB signing disabled >/dev/null
  dz -s relay >/dev/null
  print 'signing:False' | dz -e nxc >/dev/null
  dz -j found the share >/dev/null
  dz -f user $U >/dev/null
  n=${t:t}
  eq  "$n: no section added" "$heads" "$(grep -c '^## ' $N)"
  ok  "$n: dc01 row in Hosts" grep -qE '^\| dc01 \| 10\.10\.9'$i'\.11 \| dc01\.'$b'\.htb \|' $N
  ok  "$n: port 445 in Ports" grep -qE '^\| 445 ' $N
  ok  "$n: cred row, valid on dc01" grep -qE '^\| config \| svc_sql \| Passw0rd \| dc01 \|' $N
  has "$n: to-do in To do" "kerberoast svc_sql" "$(sed -n '/^## To do/,/^## /p' $N)"
  has "$n: evidence under F1" "output: nxc" "$(sed -n '/^### F1/,/^## /p' $N)"
  has "$n: timeline line" "found the share" "$(sed -n '/^## Timeline/,/^## /p' $N)"
  eq  "$n: user flag" "$U" "$(_dz_flags_get $N; print -r -- $reply[1])"
  dz -f root $R >/dev/null
  eq  "$n: root flag" "$R" "$(_dz_flags_get $N; print -r -- $reply[2])"
done
has "the extended template has 8 phases" "## 8. Post-Engagement" "$(cat $_dz_repo/templates/box-note-extended.md)"
has "--template box-note-extended finds the bundled one" "note:" "$(dz -n extbox -ip 10.10.99.1 --template box-note-extended 2>&1)"
ok  "and uses it" grep -q '^## 8. Post-Engagement' ~/vault/Boxes/extbox.md
