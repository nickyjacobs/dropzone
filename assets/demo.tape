# dropzone tour for the README: a box, a second host, the menu (to-do and finding),
# evidence under the finding, dz -i, the lists and the note.
# Rendered by .github/workflows/demo.yml (VHS), after assets/demo-env.sh.
Output assets/demo.gif

Set Shell "zsh"
Set FontSize 15
Set Width 1200
Set Height 720
Set Padding 20
Set Theme "Dracula"
Set TypingSpeed 35ms
Set Framerate 20

# Demo shell (assets/demo-env.sh), no banner animation (keeps the GIF small).
Hide
Type "source /tmp/dzdemo/.zshrc; DZ_ANIMATE=no; cd; clear" Enter
Sleep 1s
Show

# A box in one command, and a second host
Type "dz -n jacops -ip 10.129.42.190 -h jacops.htb" Sleep 300ms Enter
Sleep 2.5s
Type "dz -t dc01 -ip 10.129.42.191 -h dc01.jacops.htb" Sleep 300ms Enter
Sleep 2s
Type "dz -j found an NFS share with backups" Sleep 300ms Enter
Sleep 1.5s

# The menu stays open: a to-do, then a finding, from Notes ›
Type "clear; dz" Sleep 300ms Enter
Sleep 2s
Type "4"
Sleep 1.2s
Type "4"
Sleep 800ms
Type "try the backup creds on winrm" Sleep 400ms Enter
Sleep 2s
Type "5"
Sleep 800ms
Type "SMB signing disabled" Sleep 400ms Enter
Sleep 2.5s
Type "q"
Sleep 600ms
Type "q"
Sleep 800ms

# Evidence lands under the active finding
Type "clear; nxc smb $TARGETS | dz -e smb signing" Sleep 300ms Enter
Sleep 2s
Type "dz -f 3f9a1c0e8b7d6a5f4e3d2c1b0a998877" Sleep 300ms Enter
Sleep 1.5s

# What's next, and the lists
Type "clear; dz -i" Sleep 300ms Enter
Sleep 4.5s
Type "clear; dz --todo; dz --finding" Sleep 300ms Enter
Sleep 4s

# The note: the finding with its evidence
Type "clear; sed -n '/^## Findings/,/^## Timeline/p' notes.md" Sleep 300ms Enter
Sleep 5s
