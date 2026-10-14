#!/usr/bin/env bash
# Takes dropzone out of your zsh. Your boxes, notes and config stay.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
zshrc=$HOME/.zshrc

if grep -qE "$repo/(dropzone\.plugin|zsh/init)\.zsh" "$zshrc" 2>/dev/null; then
  cp "$zshrc" "$zshrc.bak.$(date +%Y%m%d-%H%M%S)"
  sed -i.dzbak "\#$repo/dropzone.plugin.zsh#d; \#$repo/zsh/init.zsh#d; /^# dropzone\$/d" "$zshrc" && rm -f "$zshrc.dzbak"
  echo "• dropzone taken out of ~/.zshrc (backup made)"
else
  echo "• ~/.zshrc doesn't load dropzone"
fi

echo "• your boxes, notes and ~/.config/dropzone stay"
echo "• open a new terminal to get dropzone out of your shell"
echo "• a \$(_dz_prompt) in your PROMPT prints nothing without dropzone, remove it whenever you like"
