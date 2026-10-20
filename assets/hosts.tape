# An AD set or exam with dz: hosts, a pivot, flags per host, the deadline. Rendered by
# .github/workflows/demo.yml (VHS), after assets/demo-env.sh.
Output assets/hosts.gif

Set Shell "zsh"
Set FontSize 15
Set Width 1200
Set Height 680
Set Padding 20
Set Theme "Dracula"
Set TypingSpeed 35ms
Set Framerate 24

Hide
Type "source /tmp/dzdemo/.zshrc; dz -x >/dev/null; cd; clear" Enter
Sleep 1s
Show

Type "dz -n cpts -ip 10.129.5.10 -h inlanefreight.local --template exam --deadline 10d" Sleep 300ms Enter
Sleep 2.5s
Type "dz -t web01 -ip 172.16.5.15" Sleep 300ms Enter
Sleep 1.5s
Type "dz -t dc01 -ip 172.16.5.5 -h dc01.inlanefreight.local --via web01" Sleep 300ms Enter
Sleep 2s
Type "clear; dz -t" Sleep 300ms Enter
Sleep 2.5s
Type "dz -t dc01" Sleep 300ms Enter
Sleep 1.5s
Type "echo $TARGET_IP $DOMAIN" Sleep 300ms Enter
Sleep 1.5s
Type "dz -f 9b2c4e6f8a0b1c3d5e7f9a1b3c5d7e9f" Sleep 300ms Enter
Sleep 2s
Type "dz -j kerberoasted svc_sql on dc01" Sleep 300ms Enter
Sleep 1.2s
Type "clear; dz -i" Sleep 300ms Enter
Sleep 4s
Type "dz -g svc_sql" Sleep 300ms Enter
Sleep 3s
