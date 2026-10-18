# Config: defaults, parsing, error messages, reloading.

C=$DZ_CONFIG
eq "default boxes" $HOME/boxes "$DZ_ROOT"
eq "default folders" "scans loot exploits evidence logs" "$DZ_DIRS"
eq "default iface" tun0 "$DZ_IFACE"
eq "default pivot" 'ligolo*' "$DZ_PIVOT"

cp $_dz_repo/config.example $C
_dz_config_load
eq "config.example = defaults" "$HOME/boxes||Boxes|scans loot exploits evidence logs|tun0|yes||yes" \
  "$DZ_ROOT|$DZ_VAULT|$DZ_NOTES|$DZ_DIRS|$DZ_IFACE|$DZ_AUTOLOAD|$DZ_ART|$DZ_ANIMATE"

print -r -- '   [paths]
boxes=~/work        # comment after it
   vault   =   /data/vault
notes =
[box]
folders =  nmap   loot
autoload = maybe
colour = green
no line
[menu]
art = 12
animate = no
[paths]
boxes = relative/path' > $C
out=$(_dz_config_load 2>&1); _dz_config_load 2>/dev/null
eq  "~ and spaces" $HOME/work "$DZ_ROOT"
eq  "spaces around =" /data/vault "$DZ_VAULT"
eq  "empty value = default" Boxes "$DZ_NOTES"
eq  "folders with spaces" "nmap loot" "$DZ_DIRS"
eq  "wrong yes/no = default" yes "$DZ_AUTOLOAD"
eq  "animate = no" no "$DZ_ANIMATE"
has "wrong yes/no with line number" "line 7: autoload must be yes or no" "$out"
has "unknown key reported" "line 8: unknown setting 'colour'" "$out"
has "line without = reported" "line 9:" "$out"
has "art out of range reported" "line 11: art must" "$out"
has "relative boxes refused" "line 14: boxes must be an absolute path" "$out"

sed -i.bak '/^folders/d' $C && _dz_config_load 2>/dev/null
eq "removed line = default after reload" "scans loot exploits evidence logs" "$DZ_DIRS"

print 'pivot = ligolo* tun9' > $C && _dz_config_load
eq "pivot: patterns, not expanded" 'ligolo* tun9' "$DZ_PIVOT"
print 'pivot = none' > $C && _dz_config_load
eq "pivot = none" 0 "$#DZ_PIVOT"

print 'art = 7' > $C && _dz_config_load
eq "art = 7" 7 "$DZ_ART"
f() { print $DZ_ART }
eq "DZ_ART=3 for one call" 3 "$(DZ_ART=3 f)"
eq "config value again after" 7 "$DZ_ART"

# $EDITOR with options ('code -w') works.
print -r -- $'#!/bin/sh\necho "$@" > '$HOME/editor-args > ~/ed; chmod +x ~/ed
VISUAL= EDITOR="$HOME/ed -w" _dz_config_edit >/dev/null
eq "EDITOR with options" "-w $C" "$(cat ~/editor-args)"

# NO_COLOR and pipes: no escape codes.
nok "no colour when piped" grep -q $'\e' <<< "$(dz --help)"
