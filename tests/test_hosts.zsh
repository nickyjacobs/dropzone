# /etc/hosts (against a writable hosts file of our own), standard variables, --config show.

DZ_HOSTS=$HOME/hosts
print -r -- $'127.0.0.1\tlocalhost\n10.0.0.5\tother.htb' > $DZ_HOSTS

dz -n alpha -ip 10.10.10.1 -h alpha.htb >/dev/null
eq  "hosts line added" $'10.10.10.1\talpha.htb\t# dz:alpha' "$(grep 'dz:alpha' $DZ_HOSTS)"
ok  "backup made" test -f $DZ_HOSTS.dz.bak
eq  "backup is the original" 0 "$(grep -c dz:alpha $DZ_HOSTS.dz.bak)"
eq  "DOMAIN set" alpha.htb "$DOMAIN"

dz -ip 10.10.10.2 >/dev/null
eq  "new IP replaces the line" $'10.10.10.2\talpha.htb\t# dz:alpha' "$(grep 'dz:alpha' $DZ_HOSTS)"
eq  "exactly one line per box" 1 "$(grep -c 'dz:alpha' $DZ_HOSTS)"
has "other lines stay" "other.htb" "$(cat $DZ_HOSTS)"

# -n on an existing box without -h keeps the hostnames (was: DOMAIN wiped, old IP in hosts).
dz -n alpha -ip 10.10.10.3 >/dev/null
eq  "-n existing box keeps hostnames" "hosts=alpha.htb" "$(grep ^hosts= ~/boxes/alpha/.dropzone)"
eq  "and moves the hosts line" $'10.10.10.3\talpha.htb\t# dz:alpha' "$(grep 'dz:alpha' $DZ_HOSTS)"

# Several hostnames, and changing only the hostnames.
dz -h dc01.alpha.htb,alpha.htb >/dev/null
eq  "-h alone changes hostnames" $'10.10.10.3\tdc01.alpha.htb alpha.htb\t# dz:alpha' "$(grep 'dz:alpha' $DZ_HOSTS)"
eq  "DOMAIN is the first hostname" dc01.alpha.htb "$DOMAIN"
eq  "IP unchanged" 10.10.10.3 "$TARGET_IP"
has "-v shows all hostnames" "dc01.alpha.htb alpha.htb" "$(dz -v)"
nok "invalid hostname fails" dz -h 'bad_host!'
dz -h none >/dev/null
eq  "-h none clears the hosts line" 0 "$(grep -c 'dz:alpha' $DZ_HOSTS)"
ok  "-h none clears DOMAIN" test -z "${DOMAIN-}"
dz -h alpha.htb >/dev/null

has "warns about a host outside dropzone" "already in" "$(dz -n beta -ip 10.10.10.4 -h other.htb 2>&1)"

eq  "\$TARGET = \$TARGET_IP" "$TARGET_IP" "$TARGET"
eq  "\$INTERFACE = iface" tun0 "$INTERFACE"

# A '.' in a box name is no wildcard in the hosts tag.
print -r -- $'10.1.1.1\tx.htb\t# dz:aXb' >> $DZ_HOSTS
dz -n a.b -ip 10.10.10.5 -h ab.htb >/dev/null
dz -r a.b -y --keep-note >/dev/null 2>&1
eq  "removing a.b leaves dz:aXb alone" 1 "$(grep -c 'dz:aXb' $DZ_HOSTS)"

dz -r alpha -y --keep-note >/dev/null 2>&1
eq  "rm removes the hosts line" 0 "$(grep -c 'dz:alpha' $DZ_HOSTS)"
has "rm leaves the rest" "localhost" "$(cat $DZ_HOSTS)"

dz -x >/dev/null
eq  "prompt is empty without a box" "" "$(_dz_prompt)"
dz -l beta >/dev/null
has "prompt shows box and IP" "beta%b%f %F{118}10.10.10.4" "$(_dz_prompt)"
DZ_PROMPT=no
eq  "prompt = no hides the segment" "" "$(_dz_prompt)"
DZ_PROMPT=yes

# ATTACKER_IP is refreshed before the prompt, at most every 10 seconds.
_dz_attacker_ip() { print 10.10.14.99 }
_dz_ip_ts=$(( EPOCHSECONDS - 5 )); _dz_precmd
ok  "no refresh within 10 s" test "${ATTACKER_IP-}" != 10.10.14.99
_dz_ip_ts=$(( EPOCHSECONDS - 11 )); _dz_precmd
eq  "refresh after 10 s" 10.10.14.99 "$ATTACKER_IP"

out=$(dz --config show)
has "--config show lists iface" "iface" "$out"
has "--config show: ping from config" "ping          no" "$out"
has "--config show: notes is default" "Boxes" "$out"

# The exam template and hosts behind a pivot.
dz -n exam -ip 10.129.5.10 -h web.inlanefreight.local --template exam >/dev/null
E=~/vault/Boxes/exam.md
ok  "--template exam: the bundled exam note" grep -q '^## Findings' $E
has "--template: placeholders filled" "| exam | 10.129.5.10 | web.inlanefreight.local | | | | |" "$(cat $E)"
dz -t web01 -ip 172.16.5.15 >/dev/null
out=$(dz -t ms01 -ip 172.16.5.10 --via web01)
has "--via: said when adding" "via web01" "$out"
has "--via: Via column in the Hosts table" "| ms01 | 172.16.5.10 | | web01 | | | |" "$(cat $E)"
has "--via: in dz -t" "(via web01)" "$(dz -t | grep ms01)"
has "--via: in dz -i" "via web01" "$(dz -i | grep ms01)"
has "host notes: a heading per new host" $'### exam\n\n### web01\n\n### ms01' "$(cat $E)"
dz -t dc01 -ip 172.16.5.5 >/dev/null
dz -t dc01 --via ms01 >/dev/null
has "--via on an existing host: row updated" "| dc01 | 172.16.5.5 | | ms01 |" "$(cat $E)"
has "--via change: timeline line" "host dc01: via ms01" "$(cat $E)"
eq  "--via alone doesn't switch the target" "" "$DZ_ACTIVE"
nok "--via an unknown pivot fails" dz -t dc01 --via nope
nok "--via itself fails" dz -t dc01 --via dc01
nok "the main host has no pivot" dz -t exam --via web01
dz -t dc01 --via none >/dev/null
nok "--via none clears it" eval 'dz -t | grep dc01 | grep -q via'
dz -t ms01 --drop >/dev/null
nok "dropping a pivot clears the hosts behind it" test -s ~/boxes/exam/.via
has "--template missing: message" "template 'nope' not found" "$(dz -n other2 -ip 10.1.1.2 --template nope 2>&1)"
ok  "--template missing: no note" test ! -f ~/vault/Boxes/other2.md
mkdir -p ~/.config/dropzone/templates; print -r -- $'---\nstatus: active\n---\nmine {{name}}' > ~/.config/dropzone/templates/exam.md
dz -n other3 -ip 10.1.1.3 --template exam >/dev/null
has "--template: your own copy wins" "mine other3" "$(cat ~/vault/Boxes/other3.md)"
