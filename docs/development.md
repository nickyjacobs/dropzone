# Development

[README](../README.md) · [Guide](guide.md) · [Commands](commands.md) · [Notes](notes.md) · [Config](config.md) · [Errors](errors.md) · [Testing](testing.md) · **Development**

## Layout

| Path | What lives there |
|---|---|
| `dropzone.plugin.zsh` | entry point: sets `_dz_repo` and `_dz_version`, loads `lib/errors.zsh`, `lib/art.zsh` and `lib/config.zsh`, then the rest of `lib/` |
| `lib/errors.zsh` | the error and warning codes (`_dz_err`, `_dz_warn`), their explanations and `dz --explain`; loaded first |
| `lib/config.zsh` | defaults, config parser, `dz --config` |
| `lib/box.zsh` | box folders, notes, `/etc/hosts`, load and unload |
| `lib/cli.zsh` | `dz`, flag parsing, `--help`, tab completion |
| `lib/menu.zsh` | interactive menu |
| `lib/art.zsh` | the 10 banner arts: equal lines, at most 76×14 (`tests/test_menu.zsh` checks it) |
| `lib/creds.zsh` | creds per box (`dz -c`), opt-in |
| `lib/log.zsh` | command log (`preexec` hook) and `script(1)` recording |
| `lib/prompt.zsh` | `_dz_prompt`, the prompt segment |
| `lib/ports.zsh` | open ports from nmap output into the note (`dz -p`) |
| `lib/tools.zsh` | `dz serve` and `dz -cp` |
| `lib/hosts.zsh` | more hosts in a box (`dz -t`) |
| `lib/ui.zsh` | the block layout of `--help`, `dz -i` and `dz --config show/check` |
| `scripts/` | `release.sh` and `errors-doc.zsh` (makes `docs/errors.md`) |
| `assets/` | banner, GIFs and the VHS tapes they're made from |
| `lib/notes.zsh` | flags, timeline, screenshots and command output in the note, search (`dz -f`, `-j`, `-s`, `-e`, `-g`); `_dz_section_ensure` adds a missing section (`add_sections`) |
| `lib/todo.zsh` | to-dos in the note (`dz --todo`) |
| `lib/findings.zsh` | findings, and where `dz -s` / `dz -e` put their evidence (`dz --finding`) |
| `lib/clock.zsh` | the deadline of a box (`dz --deadline`) |
| `lib/sysreptor.zsh` | evidence to SysReptor with reptor, opt-in |
| `lib/status.zsh` | box status, done, archive, open the note |
| `templates/box-note.md` | the note template that ships with dropzone |
| `templates/exam-note.md` | the exam template (`dz -n ... --template exam`) |
| `examples/obsidian/` | Obsidian template, dashboard and setup notes |
| `tests/` | `run.zsh`, `helpers.zsh` and one `test_*.zsh` per area |

Everything internal is prefixed `_dz_`. User settings live in `DZ_*` variables, filled from the config.

Conventions:

- Every function that does real work starts with `emulate -L zsh`, so the user's zsh options (`ksh_arrays`, `nounset`, ...) can't change its behaviour ([Zsh Plugin Standard](https://wiki.zshell.dev/community/zsh_plugin_standard)).
- Files dropzone writes are read, never sourced: the config, `.dropzone` and `creds`. Validate what you read.
- Box names always go through `_dz_valid_name`, IPs through `_dz_valid_ip`, hostnames through `_dz_valid_host`.
- Errors to stderr with a code: `_dz_err E201 "no box loaded"` (stops: `return 1` after it), `_dz_warn W202 "..."` (carries on). Output to stdout. Colour only through `_dz_color`.
- Overviews you read (help, info, config) use the blocks from `lib/ui.zsh` (`_dz_rule`, `_dz_head`, `_dz_row`); lists you scan or pipe (`dz -v`, `dz -t`, `dz -c`) stay one line per item.
- All text is English.
- Nothing personal in defaults: everything about the user's setup comes from their config.
- User files live outside the repo (`~/.config/dropzone/`, `~/boxes/`, the vault), so an update can never touch them. Never write into `$_dz_repo` at runtime.

## Run the tests

```bash
zsh tests/run.zsh          # all
zsh tests/run.zsh hosts    # only tests/test_hosts.zsh
```

Each test file runs in a clean `zsh -f` with a temporary `HOME`, a fake vault and its own config. Helpers in `tests/helpers.zsh`:

| Helper | Passes when |
|---|---|
| `ok <desc> <cmd>` | the command succeeds |
| `nok <desc> <cmd>` | the command fails |
| `eq <desc> <expected> <actual>` | both are equal |
| `has <desc> <part> <text>` | the text contains the part |

GitHub Actions (`.github/workflows/ci.yml`) runs on every push with a read-only token: a syntax check, shellcheck on the bash scripts and all tests on Ubuntu, and all tests again in a Kali container (same zsh and util-linux `script` as the VM). Dependabot keeps the actions up to date.

## Add a flag

1. Parse it in `dz()` in `lib/cli.zsh`.
2. Add it to `_dz_help` and `_dz_complete`.
3. Document it in `docs/commands.md`.
4. Add a test.

## Add an error code

1. Pick the next free code in the right range (E1xx using dz, E2xx boxes, E3xx hosts, E4xx notes, E5xx creds, E6xx tools, E7xx setup, E8xx deadline; W for a warning) and add it to `lib/errors.zsh` with `_dz_def <code> <title> <why> <fix>`. Write *why* and *fix* for someone who has never seen the code.
2. Use it: `_dz_err E204 "'$ip' is not an IPv4 address"; return 1`. Reuse an existing code when it's the same problem.
3. `zsh scripts/errors-doc.zsh > docs/errors.md`.

`tests/test_errors.zsh` fails when a code is used but not explained, explained but never used, or when `docs/errors.md` is out of date.

## Add a setting

1. Default in `_dz_config_defaults`, a `case` branch in `_dz_config_load` (`lib/config.zsh`).
2. A row in `_dz_config_show`.
3. The key with a one-line comment in `config.example`.
4. A row in `docs/config.md`, and a test in `tests/test_config.zsh`.

## Versions

[Semantic Versioning](https://semver.org/):

| Bump | When | Example |
|---|---|---|
| patch `x.y.Z` | fixes, docs, small tweaks | 1.0.0 → 1.0.1 |
| minor `x.Y.0` | a new feature or setting, old configs keep working | 1.0.1 → 1.1.0 |
| major `X.0.0` | a change that breaks existing configs, notes or commands | 1.4.2 → 2.0.0 |

Not every change needs a release right away; several fixes can go out together.

## Branches

- `main`: releases only. Every commit on it is a released version.
- `develop`: daily work. Feature branches start here, pull requests go here.

From `develop` to `main` through a pull request with green CI, merged with a merge commit (`gh pr merge --merge`). A ruleset on `main` blocks direct pushes, force-pushes and deleting the branch.

## Release

`main` only takes pull requests with green CI (`test`, `kali`, `scan`), so a release goes in two steps. Put the changes under `## [Unreleased]` in `CHANGELOG.md` first.

```bash
# on develop
scripts/release.sh 1.1.0          # tests, VERSION, changelog, commit "Release: v1.1.0"
git push
gh pr create --base main --head develop --title "Release v1.1.0" --fill
gh pr merge --merge               # when CI is green

# on main
git checkout main
scripts/release.sh --tag          # tag v1.1.0 and push it
git checkout develop && git merge --ff-only main && git push
```

The tag runs `.github/workflows/release.yml`: it checks that `VERSION` matches the tag and creates the GitHub Release with that version's CHANGELOG section as notes. The release badge in the README follows by itself.

## Workflows

| Workflow | Runs | Does |
|---|---|---|
| `ci.yml` | every push and PR | syntax, shellcheck, tests on Ubuntu and in a Kali container |
| `gitleaks.yml` | every push and PR | secret scan over the full history |
| `lychee.yml` | Markdown changes, weekly | checks every link in the docs |
| `release.yml` | tag `v*.*.*` | GitHub Release from the CHANGELOG |
| `demo.yml` | change to `assets/*.tape` | renders `demo.gif`, `menu.gif`, `arts.gif` and `hosts.gif` with [VHS](https://github.com/charmbracelet/vhs) as an artifact (a fixed tun0 IP and a stand-in `nxc`, see `assets/demo-env.sh`); download them, check them, commit them. Render again after `scripts/release.sh`, so the menu shows the new version |

Dependabot keeps the actions up to date, with pull requests against `develop`.
