# dropzone menu demo. Rendered by .github/workflows/demo.yml (VHS), after assets/demo-env.sh.
Output assets/menu.gif

Set Shell "zsh"
Set FontSize 15
Set Width 1200
Set Height 720
Set Padding 20
Set Theme "Dracula"
Set TypingSpeed 60ms

# Demo shell (no banner animation, keeps the GIF small), a dozen boxes to scroll through,
# and a box with a second host.
Hide
Type "source /tmp/dzdemo/.zshrc; DZ_ANIMATE=no" Enter
Sleep 1s
Type "for b in lame legacy blue devel optimum bashed knife shocker beep sense popcorn active; do dz -n $b -ip 10.129.30.$((RANDOM % 250)) >/dev/null; done; dz -n corp -ip 10.129.5.10 >/dev/null; dz -t dc01 -ip 10.129.5.11 >/dev/null; cd; clear" Enter
Sleep 3s
Show

Type "dz" Sleep 300ms Enter
Sleep 2.5s

# Load box: the list scrolls
Type "2"
Sleep 1.2s
Down@250ms 6
Sleep 800ms
Escape
Sleep 800ms

# Target › Switch host: dc01 becomes the target, the menu stays open
Type "3"
Sleep 1.2s
Type "2"
Sleep 1.2s
Down Sleep 600ms
Enter
Sleep 2s
Type "q"
Sleep 800ms

# Notes ›: a timeline line, a to-do and a finding in a row
Type "4"
Sleep 1.2s
Type "2"
Sleep 600ms
Type "smb signing off on dc01" Sleep 400ms Enter
Sleep 1.8s
Type "4"
Sleep 600ms
Type "relay to ms01" Sleep 400ms Enter
Sleep 1.8s
Type "5"
Sleep 600ms
Type "SMB signing disabled" Sleep 400ms Enter
Sleep 2s
Type "q"
Sleep 800ms

# Mark done: the Yes/No choice
Type "5"
Sleep 1.2s
Right Sleep 600ms
Left Sleep 1s
Escape
Sleep 800ms
Type "q"
Sleep 1s
