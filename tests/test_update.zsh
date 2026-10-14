# dz --update against a local copy of the repo: pulls, shows the changelog, touches nothing else.

U=~/upstream R=~/clone
if ! (( $+commands[git] )) || [[ ! -d $_dz_repo/.git ]]; then
  pass "dz --update (skipped: no git or no git checkout)"
  return 0
fi
git clone -q --no-hardlinks $_dz_repo $U 2>/dev/null
git -C $U checkout -q -B main 2>/dev/null
git -C $U -c user.name=t -c user.email=t@t commit -q --allow-empty -m base
git clone -q $U $R
cd $R; old=$(<VERSION)

_dz_repo=$R _dz_version=$old
has "up to date" "is up to date" "$(_dz_update)"

# A new version upstream.
print 9.9.9 > $U/VERSION
perl -0777 -pi -e 's/## \[Unreleased\]\n/## [Unreleased]\n\n## [9.9.9] - 2099-01-01\n\n### Added\n- something new\n/' $U/CHANGELOG.md
git -C $U -c user.name=t -c user.email=t@t commit -qam "Release: v9.9.9"
cp $DZ_CONFIG ~/config.before
out=$(_dz_update)
has "shows old and new version" "v$old → v9.9.9" "$out"
has "shows the changelog in between" "something new" "$out"
eq  "pulled" 9.9.9 "$(<$R/VERSION)"
ok  "config untouched" cmp -s $DZ_CONFIG ~/config.before

print junk >> $R/README.md
nok "refuses with local changes" _dz_update
_dz_repo=/nonexistent; nok "refuses outside a git clone" _dz_update
