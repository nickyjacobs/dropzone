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
Type "jacops" Enter
Sleep 500ms
Type "10.129.42.190" Enter
Sleep 500ms
Type "jacops.htb" Sleep 500ms Enter
Sleep 2.5s

# Back in the menu with the box loaded: load another one from the list
Type "dz" Sleep 300ms Enter
Sleep 2.5s
Down Sleep 600ms
Enter
Sleep 1.5s
Down@300ms 6
Sleep 1s
Up@300ms 2
Sleep 1s
Escape
Sleep 1s

# The Target submenu: switch the target to another host
Type "3"
Sleep 1.5s
Down Sleep 600ms
Escape
Sleep 800ms
Escape
Sleep 800ms

# Mark done: the Yes/No choice
Type "5"
Sleep 1.5s
Right Sleep 600ms
Left Sleep 1s
Escape
Sleep 800ms
Type "q"
Sleep 1s
