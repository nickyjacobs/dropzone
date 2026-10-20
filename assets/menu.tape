# dropzone menu demo. Rendered by .github/workflows/demo.yml (VHS), after assets/demo-env.sh.
Output assets/menu.gif

Set Shell "zsh"
Set FontSize 15
Set Width 1200
Set Height 680
Set Padding 20
Set Theme "Dracula"
Set TypingSpeed 60ms

# Demo shell (no banner animation, keeps the GIF small) and a dozen boxes to scroll through.
Hide
Type "source /tmp/dzdemo/.zshrc; DZ_ANIMATE=no" Enter
Sleep 1s
Type "for b in lame legacy blue devel optimum bashed knife shocker beep sense popcorn active; do dz -n $b -ip 10.129.30.$((RANDOM % 250)) >/dev/null; done; dz -x >/dev/null; cd; clear" Enter
Sleep 3s
Show

Type "dz" Sleep 300ms Enter
Sleep 3s

# New box: the form
Enter
Sleep 1s
Type "corp" Enter
Sleep 500ms
Type "10.129.5.10" Enter
Sleep 500ms
Type "corp.htb" Sleep 500ms Enter
Sleep 2s

# A second host, so the Target submenu can switch to it
Hide
Type "dz -t dc01 -ip 10.129.5.11 >/dev/null; clear" Enter
Sleep 1s
Show

# Load box: the list scrolls
Type "dz" Sleep 300ms Enter
Sleep 2s
Down Sleep 600ms
Enter
Sleep 1.2s
Down@250ms 6
Sleep 800ms
Escape
Sleep 800ms

# Target › Switch host: dc01 becomes the target
Type "3"
Sleep 1.5s
Type "2"
Sleep 1.5s
Down Sleep 800ms
Enter
Sleep 2s

# Notes › Timeline entry
Type "dz" Sleep 300ms Enter
Sleep 2s
Type "4"
Sleep 1.5s
Type "2"
Sleep 800ms
Type "smb signing off on dc01" Sleep 400ms Enter
Sleep 2s

# Mark done: the Yes/No choice
Type "dz" Sleep 300ms Enter
Sleep 1.5s
Type "5"
Sleep 1.2s
Right Sleep 600ms
Left Sleep 1s
Escape
Sleep 800ms
Type "q"
Sleep 1s
