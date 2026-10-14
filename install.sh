#!/usr/bin/env bash
# Hooks dropzone into your zsh and sets up a config. Safe to run twice.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
plugin=$repo/dropzone.plugin.zsh
line="[[ -f \"$plugin\" ]] && source \"$plugin\""
zshrc=$HOME/.zshrc
touch "$zshrc"

if grep -qF "$plugin" "$zshrc"; then
  echo "• ~/.zshrc already loads dropzone"
elif grep -qF "$repo/zsh/init.zsh" "$zshrc"; then
  cp "$zshrc" "$zshrc.bak.$(date +%Y%m%d-%H%M%S)"
  # &, | and \ mean something in a sed replacement: escape them.
  esc=$(printf '%s' "$line" | sed 's/[&|\\]/\\&/g')
  sed -i.dzbak "s|.*$repo/zsh/init.zsh.*|$esc|" "$zshrc" && rm -f "$zshrc.dzbak"
  echo "• old load line in ~/.zshrc switched to dropzone.plugin.zsh (backup made)"
else
  cp "$zshrc" "$zshrc.bak.$(date +%Y%m%d-%H%M%S)"
  printf '\n# dropzone\n%s\n' "$line" >> "$zshrc"
  echo "• line added to ~/.zshrc (backup made)"
fi

conf=${XDG_CONFIG_HOME:-$HOME/.config}/dropzone/config
if [[ -f $conf ]]; then
  echo "• config already exists: $conf"
else
  mkdir -p "$(dirname "$conf")" && cp "$repo/config.example" "$conf"
  echo "• config created: $conf (change it with: dz --config)"
fi

# Your own copy of the note template: edit it freely, updates never overwrite it.
tpl=$(dirname "$conf")/templates/box-note.md
if [[ -f $tpl ]]; then
  echo "• note template already exists: $tpl"
else
  mkdir -p "$(dirname "$tpl")" && cp "$repo/templates/box-note.md" "$tpl"
  echo "• note template created: $tpl"
fi

for dep in zsh perl ip; do
  command -v "$dep" >/dev/null || echo "• missing: '$dep' (required)"
done
for dep in sudo gio xdg-open; do
  command -v "$dep" >/dev/null || echo "• note: '$dep' not found (optional)"
done
if command -v zsh >/dev/null && ! zsh -fc 'autoload -Uz is-at-least; is-at-least 5.8'; then
  echo "• note: dropzone is tested on zsh 5.8 and newer, you have $(zsh --version)"
fi

echo "• done. Open a new terminal or run: exec zsh"
