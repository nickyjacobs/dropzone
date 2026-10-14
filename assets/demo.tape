# dropzone demo. Rendered by .github/workflows/demo.yml (VHS), after assets/demo-env.sh.
Output assets/demo.gif

Set Shell "zsh"
Set FontSize 15
Set Width 1200
Set Height 680
Set Padding 20
Set Theme "Dracula"
Set TypingSpeed 35ms
Set Framerate 24

# Load the demo shell (assets/demo-env.sh) and make two older boxes for dz -v.
Hide
Type "source /tmp/dzdemo/.zshrc" Enter
Sleep 1s
Type "dz -n lame -ip 10.129.30.12 >/dev/null && dz -d lame >/dev/null && dz -n legacy -ip 10.129.30.14 >/dev/null && cd && clear" Enter
Sleep 1s
Show

Type "dz -n jacops -ip 10.129.42.190 -h jacops.htb" Sleep 300ms Enter
Sleep 2.5s
Type "dz -j found an NFS share with backups" Sleep 300ms Enter
Sleep 1.5s
Type "dz -f 3f9a1c0e8b7d6a5f4e3d2c1b0a998877" Sleep 300ms Enter
Sleep 1.5s
Type "dz -v" Sleep 300ms Enter
Sleep 2.5s
Type "sed -n '/^## Timeline/,/^## Lessons/p' notes.md" Sleep 300ms Enter
Sleep 3.5s
Type "clear; dz" Sleep 300ms Enter
Sleep 4s
Down Sleep 600ms
Down Sleep 1.2s
Type "q"
Sleep 1s
