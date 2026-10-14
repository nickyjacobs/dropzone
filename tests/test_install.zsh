# install.sh and uninstall.sh against a fake ~/.zshrc.

line="[[ -f \"$_dz_repo/dropzone.plugin.zsh\" ]] && source \"$_dz_repo/dropzone.plugin.zsh\""
cnt() { grep -cF -- "$1" ~/.zshrc }

print -r -- $'export FOO=1\n# dropzone\n'"[[ -f $_dz_repo/zsh/init.zsh ]] && source $_dz_repo/zsh/init.zsh"$'\nalias ll=ls' > ~/.zshrc
bash $_dz_repo/install.sh >/dev/null
eq "old line switched exactly" 1 "$(cnt $line)"
eq "old line gone" 0 "$(cnt zsh/init.zsh)"
eq "rest of .zshrc intact" "export FOO=1|alias ll=ls" "$(grep -E '^(export FOO|alias ll)' ~/.zshrc | paste -sd'|' -)"
ok "config created" test -f ~/.config/dropzone/config
ok "note template created" test -f ~/.config/dropzone/templates/box-note.md
print '# mine' > ~/.config/dropzone/templates/box-note.md; print 'iface = wg0' > ~/.config/dropzone/config

bash $_dz_repo/install.sh >/dev/null
eq "second run: no double line" 1 "$(cnt $line)"
eq "second run: template not overwritten" "# mine" "$(cat ~/.config/dropzone/templates/box-note.md)"
eq "second run: config not overwritten" "iface = wg0" "$(cat ~/.config/dropzone/config)"

print 'export BAR=2' > ~/.zshrc
bash $_dz_repo/install.sh >/dev/null
eq "new install adds the line" 1 "$(cnt $line)"
ok "the line itself works" zsh -fc "HOME=$HOME; $line; (( \$+functions[dz] ))"

bash $_dz_repo/uninstall.sh >/dev/null
eq "uninstall removes the line" 0 "$(cnt dropzone)"
eq "uninstall leaves the rest" "export BAR=2" "$(grep BAR ~/.zshrc)"
ok "config stays after uninstall" test -f ~/.config/dropzone/config
