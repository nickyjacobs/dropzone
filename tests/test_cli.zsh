# dz from the command line: create, change IP, load, view, remove.

B=~/boxes
eq  "tests use their own hosts file" $HOME/hosts "$DZ_HOSTS"
eq  "--version" "dropzone v$(cat $_dz_repo/VERSION)" "$(dz --version)"
has "--help shows Usage" "Usage" "$(dz --help)"
has "-h alone shows help" "Usage" "$(dz -h)"
has "--help anywhere wins" "Usage" "$(dz -n x --help)"
nok "unknown option fails" dz --bogus
nok "-n without -ip fails" dz -n alpha
nok "-n without name fails" dz -n
nok "two actions at once fail" dz -n x -ip 1.1.1.1 -r y
nok "invalid IP fails" dz -n alpha -ip 10.10.10
nok "octet above 255 fails" dz -n alpha -ip 999.10.10.1
ok  "no folder for an invalid IP" test ! -e $B/alpha

dz -n alpha -ip 10.10.10.1 >/dev/null
ok  "box folder created" test -d $B/alpha/loot
ok  "box file is .dropzone" test -f $B/alpha/.dropzone
ok  "no .env any more" test ! -e $B/alpha/.env
ok  "note created" test -f ~/vault/Boxes/alpha.md
eq  "BOX set" alpha "$BOX"
eq  "TARGET_IP set" 10.10.10.1 "$TARGET_IP"
eq  "cd into the box" $B/alpha "$PWD"
eq  "\$TARGET_IP filled in the note" 0 "$(grep -c '\$TARGET_IP' ~/vault/Boxes/alpha.md)"
eq  "title in the note" 'title: "alpha"' "$(grep '^title' ~/vault/Boxes/alpha.md)"

print "neighbours 10.10.10.15 and 110.10.10.1" >> ~/vault/Boxes/alpha.md
dz -ip 10.10.10.9 >/dev/null
eq  "-ip changes the box file" "ip=10.10.10.9" "$(grep ^ip= $B/alpha/.dropzone)"
eq  "-ip changes the note (frontmatter)" "ip: 10.10.10.9" "$(grep '^ip:' ~/vault/Boxes/alpha.md)"
eq  "-ip changes the note (commands)" "nmap 10.10.10.9" "$(grep '^nmap' ~/vault/Boxes/alpha.md)"
has "-ip leaves neighbours alone" "10.10.10.15 and 110.10.10.1" "$(cat ~/vault/Boxes/alpha.md)"

dz -n beta -ip 10.10.10.2 >/dev/null
has "-v shows both boxes" "alpha" "$(dz -v)"
has "-v marks the loaded box" "▶ beta" "$(dz -v)"
dz -l alpha >/dev/null
eq  "-l loads a box" alpha "$BOX"
has "-i shows info" "target     10.10.10.9" "$(dz -i)"
has "-i shows status" "status     active" "$(dz -i)"
dz -l beta -ip 10.10.10.22 >/dev/null
eq  "-l <box> -ip changes another box" "ip=10.10.10.22" "$(grep ^ip= $B/beta/.dropzone)"
dz -x >/dev/null
eq  "-x unloads the box" "" "$BOX"
eq  "-x clears INTERFACE and ATTACKER_IP" "|" "${INTERFACE-}|${ATTACKER_IP-}"
nok "-i without a box fails" dz -i
nok "-ip without a box fails" dz -ip 1.2.3.4

# Names are checked on every route, also -l and the state file.
mkdir -p ~/evil; print 'touch ~/pwned' > ~/evil/.dropzone; print 'touch ~/pwned' > ~/evil/.env
nok "-l ../evil is refused" dz -l ../evil
print -r -- ../evil > $DZ_STATE; _dz_autoload
ok  "state file with ../ is not loaded" test -z "$BOX"
# A target's .env in a box folder is never run.
print 'touch ~/pwned' > $B/beta/.env
dz -l beta >/dev/null
ok  "a .env in the box is never run" test ! -e ~/pwned
eq  "box still loads" beta "$BOX"
# A hand-edited, broken box file is refused.
print 'name=beta\nip=$(touch ~/pwned)' > $B/beta/.dropzone
nok "broken box file is refused" dz -l beta
ok  "and nothing ran" test ! -e ~/pwned
dz -n beta -ip 10.10.10.22 >/dev/null 2>&1

nok "-r .. is refused" dz -r ..
nok "-r . is refused" dz -r .
nok "-r unknown box fails" dz -r gamma
nok "-r without -y and without a terminal fails" dz -r beta </dev/null
dz -r alpha -y --note >/dev/null 2>&1
ok  "-r removes the box folder" test ! -d $B/alpha
ok  "-r --note moves the note to .trash" test -f ~/vault/.trash/alpha.md
dz -r beta -y --keep-note >/dev/null 2>&1
ok  "-r --keep-note keeps the note" test -f ~/vault/Boxes/beta.md

# Old boxes (.env from older versions) are converted, a foreign .env is left alone.
mkdir -p $B/old $B/foreign
print -r -- $'BOX=old\nTARGET_IP=10.10.10.7\nDOMAIN=old.htb' > $B/old/.env
print -r -- $'APP_KEY=base64:abc\nDB_PASSWORD=x' > $B/foreign/.env
_dz_migrate
eq  "old .env converted" $'name=old\nip=10.10.10.7\nhosts=old.htb' "$(grep -v '^#' $B/old/.dropzone)"
ok  "old .env removed" test ! -e $B/old/.env
ok  "foreign .env left alone" test -f $B/foreign/.env
ok  "foreign folder is no box" test ! -e $B/foreign/.dropzone

# User options don't break dz (emulate -L zsh).
plain=$(dz -v)
eq  "same output with ksh_arrays" "$plain" "$(setopt ksh_arrays; dz -v 2>&1)"
eq  "same output with nounset" "$plain" "$(setopt nounset; dz -v 2>&1)"
eq  "same output with sh_word_split" "$plain" "$(setopt sh_word_split; dz -v 2>&1)"
