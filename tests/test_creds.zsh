# Creds per box: opt-in, store, recognise hashes, pick the active one, note table, log masking.

print -r -- $'---\nstatus: active\n---\n## Credentials & secrets\n\n| Source | Username | Secret | Valid on | Remark |\n|---|---|---|---|---|\n| | | | | |\n\n> [!info]- Columns\n\n## 1. Enumeration\n| a | b |\n|---|---|\n| | |' > ~/vault/Templates/Box-note.md
dz -n alpha -ip 10.10.10.1 >/dev/null
N=~/vault/Boxes/alpha.md F=~/boxes/alpha/creds L=~/boxes/alpha/logs/commands.log

nok "creds is off by default" dz -c bob:x
has "says how to turn it on" "creds = yes" "$(dz -c bob:x 2>&1)"
ok  "no creds file yet" test ! -e $F

DZ_CREDS=yes
dz -c 'alex:lol123!mD' NFS >/dev/null
eq  "TARGET_USER set" alex "$TARGET_USER"
eq  "PASSWORD set" 'lol123!mD' "$PASSWORD"
eq  "creds file chmod 600" 600 "$(stat -c %a $F 2>/dev/null || stat -f %Lp $F)"
eq  "note row added" '| NFS | alex | lol123!mD | | |' "$(grep '| alex |' $N)"
nok "empty example row gone" grep -qx '| | | | | |' <<< "$(sed -n '/## Credentials/,/Columns/p' $N)"
eq  "other tables untouched" 1 "$(grep -c '^| | |$' $N)"

dz -c 'admin:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0' >/dev/null
eq  "LM:NT becomes NT_HASH" 31d6cfe0d16ae931b73c59d7e0c089c0 "$NT_HASH"
eq  "PASSWORD empty with a hash" "" "${PASSWORD-}"
dz -c 'svc:pa:ss|wd' SMB >/dev/null
eq  "secret with : stays whole" 'pa:ss|wd' "$PASSWORD"
has "| escaped in the note" 'pa:ss\|wd' "$(cat $N)"

has "-c lists" "alex" "$(dz -c)"
has "-c marks the active one" "▶  3" "$(dz -c)"
dz -c 1 >/dev/null
eq  "-c 1 makes #1 active" alex "$TARGET_USER"
nok "-c 9 doesn't exist" dz -c 9
nok "-c user without a terminal fails" dz -c onlyuser </dev/null
has "and says how" "dz -c <user>:<secret>" "$(dz -c onlyuser 2>&1 </dev/null)"

dz -x >/dev/null
eq  "-x clears the cred variables" "||" "${TARGET_USER-}|${PASSWORD-}|${NT_HASH-}"
dz -l alpha >/dev/null
eq  "loading restores the active cred" alex "$TARGET_USER"
has "-i shows the cred" "alex (dz -c)" "$(dz -i)"

: > $L
for c in "dz -c root:Secret1 ssh" "dz --creds 'root:Secret2'" $'dz -c\troot:Secret3' "id; dz -c root:Secret4"; do
  _dz_log_preexec $c
done
nok "no secret in commands.log" grep -q Secret $L
eq  "masked lines" "4" "$(grep -c '<hidden>' $L)"
has "-c masked" 'dz -c <hidden>' "$(cat $L)"
has "--creds masked" 'dz --creds <hidden>' "$(cat $L)"
has "rest of the line before dz stays" 'id; dz -c <hidden>' "$(cat $L)"

# Domain users and where a cred works.
dz -t dc01 -ip 10.10.10.5 >/dev/null
dz -c 'corp\svc_sql:Summer2026!' MSSQL >/dev/null
eq  "domain\\\\user: domain and user split" "corp|svc_sql" "$CRED_DOMAIN|$TARGET_USER"
dz -c 'jdoe@corp.local:Welcome1' >/dev/null
eq  "user@domain: domain and user split" "corp.local|jdoe" "$CRED_DOMAIN|$TARGET_USER"
dz -c 1 >/dev/null
eq  "plain user: no domain" "|alex" "${CRED_DOMAIN-}|$TARGET_USER"
dz -c 1 --valid alpha,dc01 >/dev/null
has "--valid with a number: in the list" "→ alpha, dc01" "$(dz -c | grep alex)"
eq  "--valid: the Valid on column of that row" '| NFS | alex | lol123!mD | alpha, dc01 | |' "$(grep '| alex |' $N)"
dz -c 1 --valid dc01,ms01 >/dev/null 2>&1
has "--valid adds, no doubles" "→ alpha, dc01, ms01" "$(dz -c | grep alex)"
has "--valid: unknown host is a note, not an error" "ms01 is not a host" "$(dz -c 1 --valid ms01 2>&1)"
nok "--valid: a bad name fails" dz -c 1 --valid 'a;b'
dz -c 3 >/dev/null; dz -c --valid dc01 >/dev/null
has "--valid without a number: the active cred" "→ dc01" "$(dz -c | grep 'svc ')"
ok  "--valid: row with an escaped | in the secret" grep -qF '| SMB | svc | pa:ss\|wd | dc01 | |' $N
has "domain user stored as typed" 'corp\svc_sql' "$(dz -c)"
dz -c 'web:S3cr3t' HTTP --valid alpha >/dev/null
eq  "--valid while storing" '| HTTP | web | S3cr3t | alpha | |' "$(grep '| web |' $N)"
ok  "an old 4-field creds file still loads" eval 'dz -c 2 >/dev/null && [[ $TARGET_USER == admin ]]'
dz -x >/dev/null
eq  "-x clears CRED_DOMAIN" "" "${CRED_DOMAIN-}"
