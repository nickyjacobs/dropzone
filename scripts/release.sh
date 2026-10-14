#!/usr/bin/env bash
# Release in two steps, because main only takes pull requests:
#
#   scripts/release.sh 1.1.0   on develop: VERSION + CHANGELOG, commit "Release: v1.1.0"
#                              then push develop and merge it into main with a pull request
#   scripts/release.sh --tag   on main, after the merge: tag v<VERSION> and push the tag
#
# The tag makes the GitHub Release (.github/workflows/release.yml); the README badge follows.
# Put your changes under "## [Unreleased]" in CHANGELOG.md first.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

[[ -z $(git status --porcelain) ]] || { echo "working tree not clean, commit first"; exit 1; }
branch=$(git branch --show-current)

if [[ ${1:-} == --tag ]]; then
  [[ $branch == main ]] || { echo "--tag runs on main, after the release pull request is merged"; exit 1; }
  git pull -q --ff-only
  ver=$(<VERSION)
  git rev-parse -q --verify "refs/tags/v$ver" >/dev/null && { echo "tag v$ver already exists"; exit 1; }
  grep -q "^## \[$ver\]" CHANGELOG.md || { echo "no '## [$ver]' in CHANGELOG.md"; exit 1; }
  git tag -a "v$ver" -m "dropzone $ver"
  git push -q origin "v$ver"
  echo "• v$ver tagged and pushed, the release workflow makes the GitHub Release"
  exit 0
fi

new=${1:?usage: scripts/release.sh <version> | --tag}
[[ $new =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "not a valid version: $new"; exit 1; }
[[ $branch == develop ]] || { echo "prepare a release on develop"; exit 1; }
old=$(<VERSION)
today=$(date +%F)
git rev-parse -q --verify "refs/tags/v$new" >/dev/null && { echo "tag v$new already exists"; exit 1; }
zsh tests/run.zsh >/dev/null || { echo "tests fail, no release"; exit 1; }

echo "$new" > VERSION
sed -i.bak "s|^## \[Unreleased\]|## [Unreleased]\n\n## [$new] - $today|" CHANGELOG.md
sed -i.bak "s|^\[Unreleased\]: \(.*\)/compare/v$old...HEAD|[Unreleased]: \1/compare/v$new...HEAD\n[$new]: \1/compare/v$old...v$new|" CHANGELOG.md
rm -f CHANGELOG.md.bak

git add VERSION CHANGELOG.md
git commit -qm "Release: v$new"
echo "• v$new prepared on develop. Next:"
echo "    git push"
echo "    gh pr create --base main --head develop --title 'Release v$new' --fill"
echo "    gh pr merge --merge          (when CI is green)"
echo "    git checkout main && scripts/release.sh --tag"
echo "    git checkout develop && git merge --ff-only main && git push"
