# Deadline per box (dz --deadline): stored, shown in dz -i and the prompt.

dz -n exam -ip 10.129.5.10 --deadline 10d >/dev/null
D=~/boxes/exam/.deadline
ok  "-n with --deadline: file written" grep -q '^end=' $D
eq  "10 days from now" 864000 "$(( $(sed -n 's/^end=//p' $D) - $(sed -n 's/^start=//p' $D) ))"
has "-i shows the clock" "day 1/10 · " "$(dz -i)"
DZ_PROMPT=yes
ok  "prompt shows what's left" eval '[[ "$(_dz_prompt)" == *(10d0h|9d23h)* ]]'
has "--deadline alone shows it" "exam: day 1/10" "$(dz --deadline)"
s=$(sed -n 's/^start=//p' $D)
dz --deadline 48h >/dev/null
eq  "a new end keeps the start" "$s" "$(sed -n 's/^start=//p' $D)"
dz --deadline '2030-01-02 03:04' >/dev/null
eq  "a date and time" "2030-01-02 03:04" "$(strftime '%F %H:%M' $(sed -n 's/^end=//p' $D))"
dz --deadline 2030-01-02 >/dev/null
eq  "a date alone is 23:59" "2030-01-02 23:59" "$(strftime '%F %H:%M' $(sed -n 's/^end=//p' $D))"
nok "a date in the past fails" dz --deadline 2001-01-01
nok "nonsense fails" dz --deadline soon
has "and says what works" "10d, 48h" "$(dz --deadline soon 2>&1)"
has "timeline line" "· deadline: 2030-01-02 23:59" "$(cat ~/vault/Boxes/exam.md)"
print -r -- $'start=100\nend=200' > $D; dz -l exam >/dev/null
has "after the end: time's up" "time's up" "$(dz -i)"
has "prompt: time's up" "time's up" "$(_dz_prompt)"
dz --deadline none >/dev/null
ok  "none removes it" test ! -e $D
nok "and the prompt stops showing it" eval '[[ "$(_dz_prompt)" == *up* ]]'
dz -x >/dev/null
nok "--deadline without a box fails" dz --deadline 10d
