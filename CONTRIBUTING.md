# Contributing

Thanks for wanting to help. dropzone is a small zsh tool, so contributing is quick to set up.

## Before you start

- **Bug or idea?** Open an [issue](https://github.com/nickyjacobs/dropzone/issues/new/choose) first, so we can agree on the approach before you write code.
- **Security problem?** Don't open an issue, see [SECURITY.md](SECURITY.md).
- **Scope**: dropzone does admin for a box (folders, notes, variables, hosts entries, logs). It never scans or exploits on its own, so it stays allowed in exams like OSCP. Features that attack a target are out of scope.

## Setup

```bash
git clone https://github.com/nickyjacobs/dropzone.git
cd dropzone
git checkout develop
zsh tests/run.zsh          # all tests, in a temporary HOME
```

You need zsh 5.8+ and perl. The tests never touch your own config, boxes or `/etc/hosts`.

## Branches and pull requests

- `main` holds releases only. Work on a branch from `develop` and open your pull request against `develop`.
- One topic per pull request. Add a line under `## [Unreleased]` in [CHANGELOG.md](CHANGELOG.md).
- CI must pass: syntax, shellcheck, the tests on Ubuntu and Kali, and a secret scan.

## Code

The conventions are in [docs/development.md](docs/development.md). The short version:

- Internal names start with `_dz_`, settings are `DZ_*` variables filled from the config.
- Every function that does real work starts with `emulate -L zsh`.
- Files are read, never sourced. Validate names, IPs and hostnames with the `_dz_valid_*` helpers.
- No personal defaults: everything about a user's setup comes from their config.
- All text is English. Errors and warnings go to stderr with a code (`_dz_err E201 "..."`), explained in `lib/errors.zsh`; see [Add an error code](docs/development.md#add-an-error-code).
- A new option touches `dz()`, `_dz_help`, `_dz_complete`, `docs/commands.md` and a test. Something the tests can't check (a desktop, a network, another tool) gets a row in [docs/testing.md](docs/testing.md).

## Commits

Short imperative subject with a prefix: `Add:`, `Fix:`, `Update:`, `Refactor:` or `Docs:`. For example `Fix: keep hostnames on dz -n for an existing box`.
