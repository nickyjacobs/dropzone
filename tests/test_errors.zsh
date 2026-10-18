# Error codes: every code in lib/ is in the catalog and the other way round, docs/errors.md
# is up to date, the format on screen, and dz --explain.

local -a used=(${(u)${(f)"$(grep -ohE '_dz_(err|warn) [EW][0-9]{3}' $_dz_repo/lib/*.zsh | awk '{print $2}')"}})
local -a known=(${(k)_dz_err_title}) missing=() unused=() c
for c in $used; do (( $+_dz_err_title[$c] )) || missing+=($c); done
for c in $known; do (( $used[(Ie)$c] )) || unused+=($c); done
eq  "every code in lib/ is in the catalog" "" "$missing"
eq  "every catalog code is used in lib/" "" "$unused"
for c in $known; do [[ -n $_dz_err_why[$c] && -n $_dz_err_fix[$c] ]] || missing+=($c); done
eq  "every code has a why and a fix" "" "$missing"
eq  "no plain 'print -u2 \"dz:' left in lib/" "" "$(grep -n 'print -u2 "dz:' $_dz_repo/lib/*.zsh)"
eq  "docs/errors.md is made from the catalog (zsh scripts/errors-doc.zsh > docs/errors.md)" "" \
  "$(zsh $_dz_repo/scripts/errors-doc.zsh | diff - $_dz_repo/docs/errors.md)"

# On screen
eq  "an error: dz [code] message" "dz [E202] no box 'nope' in $HOME/boxes" "$(dz -l nope 2>&1)"
has "an unknown option" "dz [E101] unknown option '--nope'" "$(dz --nope 2>&1)"
nok "an error exits 1" dz -l nope
dz -n alpha -ip 10.10.10.1 >/dev/null
DZ_VPNCHECK=yes; ip() { return 1 }; commands[ip]=ip
has "a warning: • [code] message" "• [W201] tun0 doesn't exist" "$(_dz_vpn_check 10.10.10.1 2>&1)"
DZ_VPNCHECK=no

# dz --explain
out=$(dz --explain E201)
has "--explain: title" "E201" "$out"
has "--explain: why" "no box is loaded in this terminal" "$out"
has "--explain: fix" "dz -l <name>" "$out"
has "--explain: lower case and number only work too" "no box loaded" "$(dz --explain e201)$(dz --explain 201)"
has "--explain alone lists every code" "W701   config line skipped" "$(dz --explain)"
nok "--explain an unknown code fails" dz --explain E999
