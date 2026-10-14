#!/usr/bin/env bash
# Release a new version: VERSION, CHANGELOG, commit and tag in one go. Pushing the tag
# makes the GitHub Release (.github/workflows/release.yml); the README badge follows it.
#   scripts/release.sh 1.1.0
# Put your changes under "## [Unreleased]" in CHANGELOG.md first.
set -euo pipefail

new=${1:?usage: scripts/release.sh <version>}
[[ $new =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "not a valid version: $new"; exit 1; }
cd "$(dirname "${BASH_SOURCE[0]}")/.."
old=$(<VERSION)
today=$(date +%F)

[[ -z $(git status --porcelain) ]] || { echo "working tree not clean, commit first"; exit 1; }
[[ $(git branch --show-current) == main ]] || { echo "release from main (merge develop first)"; exit 1; }
git rev-parse -q --verify "refs/tags/v$new" >/dev/null && { echo "tag v$new already exists"; exit 1; }
zsh tests/run.zsh >/dev/null || { echo "tests fail, no release"; exit 1; }

echo "$new" > VERSION
sed -i.bak "s|^## \[Unreleased\]|## [Unreleased]\n\n## [$new] - $today|" CHANGELOG.md
sed -i.bak "s|^\[Unreleased\]: \(.*\)/compare/v$old...HEAD|[Unreleased]: \1/compare/v$new...HEAD\n[$new]: \1/compare/v$old...v$new|" CHANGELOG.md
rm -f CHANGELOG.md.bak

git add VERSION CHANGELOG.md
git commit -qm "Release: v$new"
git tag -a "v$new" -m "dropzone $new"
echo "• v$new done. Push: git push && git push origin v$new"
