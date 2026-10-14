#!/usr/bin/env zsh
# Runs all tests: every tests/test_*.zsh in a clean zsh with a temporary HOME.
#   zsh tests/run.zsh            all
#   zsh tests/run.zsh config     only test_config.zsh

emulate -L zsh
repo=${0:A:h:h}
local -i failed=0
local f
for f in $repo/tests/test_${1:-*}.zsh(N); do
  print "\n${f:t}"
  zsh -f -c "source ${(q)repo}/tests/helpers.zsh; _t_setup ${(q)repo}; source ${(q)f} || fail \"test file stopped early (exit \$?)\"; _t_done" || (( failed++ ))
done
print
(( failed )) && { print "✗ $failed test file(s) failed"; exit 1 }
print "✓ all tests passed"
