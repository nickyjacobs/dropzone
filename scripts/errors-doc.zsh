#!/usr/bin/env zsh
# Writes docs/errors.md from lib/errors.zsh, so the docs and 'dz --explain' always agree.
#   zsh scripts/errors-doc.zsh > docs/errors.md
# tests/test_errors.zsh fails when docs/errors.md is out of date.
emulate -L zsh
source ${0:A:h:h}/lib/errors.zsh

_dz_errors_doc() {
local -A area=(
  1 "Using dz" 2 "Boxes" 3 "Hosts in a box (dz -t)" 4 "Notes, flags and evidence"
  5 "Creds" 6 "Tools and ports" 7 "Setup, config and update" 8 "Deadline")
local -a codes=(${(ko)_dz_err_title})
local c a last=''

print -r -- '# Errors

[README](../README.md) · [Guide](guide.md) · [Commands](commands.md) · [Notes](notes.md) · [Config](config.md) · **Errors** · [Testing](testing.md) · [Development](development.md)

When something goes wrong, dz says so in one line with a code:

```
dz [E201] no box loaded
• [W202] the route to 10.10.10.77 goes through eth0, not tun0
```

- **E** is an error: the command stopped and changed nothing more (exit status 1).
- **W** is a warning: dz tells you something and carries on.

`dz --explain E201` shows why it happens and what to do, right in your terminal; `dz --explain` lists every code. The same text is below.

<!-- Made by scripts/errors-doc.zsh from lib/errors.zsh. Change it there, not here. -->

## Overview
'
for a in {1..8}; do
  print -r -- "| ${a}xx | ${area[$a]} |"
done | { print -r -- '| Codes | Area |'; print -r -- '|---|---|'; cat }
print
# Per area: errors first, then the warnings of that area.
local -a order=()
for a in {1..8}; do
  order+=(${(M)codes:#E$a??} ${(M)codes:#W$a??})
done
print -r -- '| Code | Meaning |'
print -r -- '|---|---|'
for c in $order; do print -r -- "| [$c](#${(L)c}) | ${_dz_err_title[$c]} |"; done

for c in $order; do
  a=${c[2]}
  if [[ $a != $last ]]; then print; print -r -- "## ${a}xx · ${area[$a]}"; last=$a; fi
  print
  print -r -- "<a id=\"${(L)c}\"></a>"
  print -r -- "### $c · ${_dz_err_title[$c]}"
  print
  [[ $c == E* ]] && print -r -- "**Error.** ${_dz_err_why[$c]}" || print -r -- "**Warning.** ${_dz_err_why[$c]}"
  print
  print -r -- "**What to do:** ${_dz_err_fix[$c]}"
done
}
# Commands in 'quotes' (as in the terminal) become `code` in the docs; it's / doesn't stay.
_dz_errors_doc | perl -pe 's/(?<![A-Za-z])\x27([^\x27\n]+?)\x27(?![A-Za-z])/`$1`/g'
