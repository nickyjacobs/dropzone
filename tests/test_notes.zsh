# Flags, timeline and screenshots in the box note.

print -r -- $'---\ntitle: "{{title}}"\nupdated: {{date}}\nstatus: active\n---\n## Vragen\n\n## Flags\n\n**User flag**\n> [!success]- Flag\n> \n\n**Root flag**\n> [!success]- Flag\n> \n\n## Geleerd\n\n- ' > ~/vault/Templates/Box-note.md
dz -n alpha -ip 10.10.10.1 >/dev/null
N=~/vault/Boxes/alpha.md
U=0123456789abcdef0123456789abcdef R=fedcba9876543210fedcba9876543210

# Timeline
dz -j found an NFS share >/dev/null
has "-j without quotes: whole line" "· found an NFS share" "$(cat $N)"
ok  "timeline section added before Flags" grep -q '## Timeline' $N
eq  "timeline sits right before Flags" "## Timeline|## Flags" "$(grep -E '^## (Timeline|Flags)' $N | paste -sd'|' -)"
dz -j "creds in backup.zip --help" >/dev/null
has "-j keeps --help as text" "creds in backup.zip --help" "$(cat $N)"
eq  "entries in order" "2" "$(sed -n '/## Timeline/,/## Flags/p' $N | grep -c '^- ')"
ok  "entry has date and time" grep -qE '^- [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} · found' $N
has "-j alone shows the timeline" "found an NFS share" "$(dz -j)"
eq  "updated: today" "updated: $(date +%F)" "$(grep '^updated:' $N)"

# Flags
dz -f $U >/dev/null
eq  "first flag goes to user" "$U|" "$(_dz_flags_get $N; print -r -- "$reply[1]|$reply[2]")"
has "user flag in the callout" $'**User flag**\n> [!success]- Flag\n> '$U "$(cat $N)"
has "timeline: user flag" "· user flag" "$(cat $N)"
nok "user flag twice fails" dz -f user $R
dz -f $R >/dev/null
eq  "second flag goes to root" "$U|$R" "$(_dz_flags_get $N; print -r -- "$reply[1]|$reply[2]")"
eq  "root flag marks done" done "$(_dz_status alpha)"
nok "a third flag fails" dz -f $R
has "-f alone shows the flags" "root  $R" "$(dz -f)"
has "odd flag format warns" "not the usual HTB flag" "$(dz -n beta -ip 10.10.10.2 >/dev/null; dz -f 'HTB{x}' 2>&1)"
nok "flag with a space fails" dz -f root 'a b'

# A note without a Flags section gets one.
dz -l beta >/dev/null
print -r -- $'---\nupdated: x\n---\nbody' > ~/vault/Boxes/beta.md
dz -f root $R >/dev/null
eq  "Flags section added" "$R" "$(_dz_flags_get ~/vault/Boxes/beta.md; print -r -- $reply[2])"

# Screenshots (the tool is faked).
dz -l alpha >/dev/null
DISPLAY= WAYLAND_DISPLAY=
nok "-s without a desktop fails" dz -s x
has "-s says why without a desktop" "no desktop session" "$(dz -s x 2>&1)"
DISPLAY=:0
_dz_shot_tool() { REPLY=fake }
_dz_shot_take() { print png > $2 }
dz -s SMB share: listing! >/dev/null
f=(~/boxes/alpha/evidence/alpha_*_smb-share-listing.png(N))
eq  "screenshot in evidence/ with caption slug" 1 "$#f"
ok  "copy in the vault" test -f ~/vault/Boxes/attachments/alpha/${f[1]:t}
has "embedded in the timeline" "  ![[Boxes/attachments/alpha/${f[1]:t}]]" "$(cat $N)"
has "caption in the timeline" "· screenshot: SMB share: listing!" "$(cat $N)"
_dz_shot_take() { : }
has "cancelled screenshot says so" "no screenshot taken" "$(dz -s 2>&1)"
eq  "and leaves no empty file" 1 "$(print -l ~/boxes/alpha/evidence/*.png | wc -l | tr -d ' ')"

DZ_SHOT=nothere; unfunction _dz_shot_tool; source $_dz_repo/lib/notes.zsh
has "missing configured tool is reported" "'nothere' not found" "$(dz -s 2>&1)"
nok "-j without a box fails" eval 'BOX= dz -j x'
has "--config show lists [notes]" "timeline      Timeline" "$(dz --config show)"

# Flags per host: a box with more hosts keeps a list and is never marked done by a flag.
dz -n corp -ip 10.10.10.10 >/dev/null
dz -t dc01 -ip 10.10.10.5 >/dev/null
C=~/vault/Boxes/corp.md
DZ_FLAG_GOAL=3
out=$(dz -f $U)
has "flag without a kind goes to the active host" "flag 1/3 stored for corp" "$out"
ok  "line in the Flags section" grep -qE "^- [0-9-]+ [0-9:]+ · corp · $U\$" $C
dz -t dc01 >/dev/null
has "the active host follows dz -t" "for dc01" "$(dz -f $R)"
nok "the same flag twice fails" dz -f corp $R
nok "a flag for an unknown host fails" dz -f nope $R
has "and says so" "no host 'nope'" "$(dz -f nope 22222222222222222222222222222222 2>&1)"
nok "a host name alone isn't stored as a flag" dz -f dc01
dz -f root 11111111111111111111111111111111 >/dev/null
eq  "root flag on a box with hosts: not done" active "$(_dz_status corp)"
out=$(dz -f)
has "-f lists the host flags" "dc01         $R" "$out"
has "-f counts against flag_goal" "3/3 flags" "$out"
has "timeline line with the count" "· flag 2/3 (dc01)" "$(cat $C)"
has "a blank line between the callout and the list" $'> 11111111111111111111111111111111\n\n- ' "$(cat $C)"
eq  "the flags stay inside the Flags section" "" "$(sed -n '/^## Flags/,$p' $C | sed -n '/^## [^F]/,$p' | grep '· corp ·')"
DZ_FLAG_GOAL=0
eq  "without a goal: just the number" "  3 flags" "$(dz -f | tail -1)"
