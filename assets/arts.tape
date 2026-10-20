# The 10 banner arts, one after the other. Rendered by .github/workflows/demo.yml (VHS),
# after assets/demo-env.sh. Taller than the other demos: the menu shows the big art
# only when the terminal has room for it. No animation, which keeps the GIF small.
Output assets/arts.gif

Set Shell "zsh"
Set FontSize 13
Set Width 1200
Set Height 700
Set Padding 20
Set Theme "Dracula"
Set Framerate 10

Hide
Type "source /tmp/dzdemo/.zshrc; DZ_ANIMATE=no; dz -n jacops -ip 10.129.42.190 >/dev/null; clear" Enter
Sleep 1s
Type "DZ_ART=1 dz" Enter
Sleep 300ms
Show
Sleep 2.2s
Hide
Type "q"
Type "clear; DZ_ART=2 dz" Enter
Sleep 300ms
Show
Sleep 2.2s
Hide
Type "q"
Type "clear; DZ_ART=3 dz" Enter
Sleep 300ms
Show
Sleep 2.2s
Hide
Type "q"
Type "clear; DZ_ART=4 dz" Enter
Sleep 300ms
Show
Sleep 2.2s
Hide
Type "q"
Type "clear; DZ_ART=5 dz" Enter
Sleep 300ms
Show
Sleep 2.2s
Hide
Type "q"
Type "clear; DZ_ART=6 dz" Enter
Sleep 300ms
Show
Sleep 2.2s
Hide
Type "q"
Type "clear; DZ_ART=7 dz" Enter
Sleep 300ms
Show
Sleep 2.2s
Hide
Type "q"
Type "clear; DZ_ART=8 dz" Enter
Sleep 300ms
Show
Sleep 2.2s
Hide
Type "q"
Type "clear; DZ_ART=9 dz" Enter
Sleep 300ms
Show
Sleep 2.2s
Hide
Type "q"
Type "clear; DZ_ART=10 dz" Enter
Sleep 300ms
Show
Sleep 2.2s
Hide
Type "q"
