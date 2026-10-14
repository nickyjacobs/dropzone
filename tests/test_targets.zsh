# More hosts in one box (dz -t): variables, active target, /etc/hosts, note, persistence.

DZ_HOSTS=$HOME/hosts
print -r -- $'127.0.0.1\tlocalhost' > $DZ_HOSTS
cp $_dz_repo/templates/box-note.md ~/vault/Templates/Box-note.md
dz -n corp -ip 10.10.10.10 -h corp.htb >/dev/null
N=~/vault/Boxes/corp.md F=~/boxes/corp/.dropzone

nok "-t without a box fails" eval 'BOX= dz -t'
has "-t lists the main host" "▶ corp" "$(dz -t)"
has "-t says how to add one" "no extra hosts yet" "$(dz -t)"
nok "new host without -ip fails" dz -t dc01
nok "invalid host name fails" dz -t DC_01 -ip 10.10.10.5
nok "invalid IP fails" dz -t dc01 -ip 10.10.10.500
nok "main host can't be changed with -t" dz -t corp -ip 10.10.10.99

# Add hosts
dz -t dc01 -ip 10.10.10.5 -h dc01.corp.local,corp.local >/dev/null
dz -t ms-02 -ip 10.10.10.6 >/dev/null
eq  "\$DC01_IP" 10.10.10.5 "$DC01_IP"
eq  "\$MS_02_IP" 10.10.10.6 "$MS_02_IP"
eq  "\$TARGETS has all IPs" "10.10.10.10 10.10.10.5 10.10.10.6" "$TARGETS"
eq  "adding doesn't change the target" 10.10.10.10 "$TARGET_IP"
eq  "box file keeps the main host" "ip=10.10.10.10" "$(grep '^ip=' $F)"
eq  "box file has both hosts" "host=dc01 10.10.10.5 dc01.corp.local corp.local|host=ms-02 10.10.10.6" "$(grep '^host=' $F | paste -sd'|' -)"
eq  "hosts line for dc01" $'10.10.10.5\tdc01.corp.local corp.local\t# dz:corp/dc01' "$(grep 'dz:corp/dc01' $DZ_HOSTS)"
eq  "no hosts line without hostnames" 0 "$(grep -c 'dz:corp/ms-02' $DZ_HOSTS)"
eq  "main hosts line untouched" $'10.10.10.10\tcorp.htb\t# dz:corp' "$(grep 'dz:corp$' $DZ_HOSTS)"
has "note: row in the Hosts table" "| dc01 | 10.10.10.5 | dc01.corp.local, corp.local | | |" "$(cat $N)"
has "note: row for ms-02" "| ms-02 | 10.10.10.6 | | | |" "$(cat $N)"
has "note: timeline line" "· host dc01 added: 10.10.10.5 (dc01.corp.local, corp.local)" "$(cat $N)"
has "-t lists them" "dc01         10.10.10.5" "$(dz -t)"
has "-t shows the variable" '$DC01_IP' "$(dz -t)"
has "-v counts the hosts" "(+2 hosts)" "$(dz -v)"
has "-i lists the hosts" "dc01       10.10.10.5  \$DC01_IP" "$(dz -i)"

# Switch the target
dz -t dc01 >/dev/null
eq  "-t dc01: TARGET_IP" 10.10.10.5 "$TARGET_IP"
eq  "-t dc01: TARGET" 10.10.10.5 "$TARGET"
eq  "-t dc01: DOMAIN follows" dc01.corp.local "$DOMAIN"
eq  "-t dc01: DZ_ACTIVE" dc01 "$DZ_ACTIVE"
has "prompt shows the host" "%F{46}dc01%f %F{118}10.10.10.5" "$(_dz_prompt)"
has "-i shows the active host" "10.10.10.5 (dc01)" "$(dz -i)"
nok "-t unknown host fails" dz -t nope
dz -t ms-02 >/dev/null
eq  "host without hostnames keeps the box DOMAIN" corp.htb "$DOMAIN"

# The active host survives a new terminal (autoload) and dz -l.
dz -t dc01 >/dev/null
unset BOX TARGET_IP DC01_IP; _dz_autoload
eq  "autoload restores the active host" "dc01 10.10.10.5" "$DZ_ACTIVE $TARGET_IP"
eq  "autoload restores the host variables" 10.10.10.5 "$DC01_IP"
dz -t corp >/dev/null
eq  "-t <box> goes back to the main host" "|10.10.10.10" "$DZ_ACTIVE|$TARGET_IP"
eq  "and the prompt has no host" "[%B%F{46}corp%b%f %F{118}10.10.10.10%f]-" "$(_dz_prompt)"

# Change a host
print "dc01 seen at 10.10.10.5, not 10.10.10.55" >> $N
dz -t dc01 -ip 10.10.10.15 >/dev/null
eq  "new IP for a host" 10.10.10.15 "$DC01_IP"
eq  "hostnames stay" $'10.10.10.15\tdc01.corp.local corp.local\t# dz:corp/dc01' "$(grep 'dz:corp/dc01' $DZ_HOSTS)"
has "note: host IP replaced exactly" "dc01 seen at 10.10.10.15, not 10.10.10.55" "$(cat $N)"
dz -t dc01 -h dc01.corp.local >/dev/null
eq  "new hostnames for a host" $'10.10.10.15\tdc01.corp.local\t# dz:corp/dc01' "$(grep 'dz:corp/dc01' $DZ_HOSTS)"

# The main host and extra hosts don't overwrite each other.
dz -ip 10.10.10.11 >/dev/null
eq  "dz -ip keeps the extra hosts" 2 "$(grep -c '^host=' $F)"
eq  "dz -ip changes only the main host" "10.10.10.11|10.10.10.15" "$(grep '^ip=' $F | cut -d= -f2)|$DC01_IP"
dz -n corp -ip 10.10.10.12 >/dev/null
eq  "dz -n on the box keeps the extra hosts" 2 "$(grep -c '^host=' $F)"

# Drop
dz -t dc01 >/dev/null
dz -t dc01 --drop >/dev/null
eq  "--drop removes the host" 0 "$(grep -c '^host=dc01' $F)"
eq  "--drop removes its hosts line" 0 "$(grep -c 'dz:corp/dc01' $DZ_HOSTS)"
ok  "--drop unsets the variable" test -z "${DC01_IP-}"
eq  "--drop of the active host goes back to main" "|10.10.10.12" "$DZ_ACTIVE|$TARGET_IP"
nok "--drop of an unknown host fails" dz -t dc01 --drop

# Archive, restore, remove: all hosts lines of the box.
dz -t dc02 -ip 10.10.10.7 -h dc02.corp.local >/dev/null
cd ~; dz -a corp >/dev/null
eq  "archive removes every hosts line of the box" 0 "$(grep -c 'dz:corp' $DZ_HOSTS)"
dz -l corp >/dev/null
eq  "restore puts them back" 2 "$(grep -c 'dz:corp' $DZ_HOSTS)"
eq  "restored host variable" 10.10.10.7 "$DC02_IP"
dz -n other -ip 10.10.20.1 >/dev/null
ok  "loading another box unsets the old host variables" test -z "${DC02_IP-}"
dz -r corp -y --keep-note >/dev/null 2>&1
eq  "rm removes every hosts line of the box" 0 "$(grep -c 'dz:corp' $DZ_HOSTS)"
has "rm leaves the rest" "localhost" "$(cat $DZ_HOSTS)"

# A broken host line makes the box file invalid (never half-read).
dz -n tidy -ip 10.10.30.1 >/dev/null
print 'host=dc01 $(touch ~/pwned)' >> ~/boxes/tidy/.dropzone
nok "broken host line is refused" dz -l tidy
ok  "and nothing ran" test ! -e ~/pwned

# Another table layout: Hostname / FQDN and a notes column, no Host column.
print -r -- $'---\nupdated: x\n---\n### Hosts\n\n| IP | Hostname / FQDN | OS | Role / notes |\n|---|---|---|---|\n| $TARGET_IP | | | |\n\n## Next' > ~/vault/Templates/Box-note.md
dz -n lab -ip 10.10.40.1 >/dev/null
dz -t web01 -ip 10.10.40.2 -h web01.lab.local >/dev/null
has "other layout: IP, FQDN and name in the notes column" "| 10.10.40.2 | web01.lab.local | | web01 |" "$(cat ~/vault/Boxes/lab.md)"
