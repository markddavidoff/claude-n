# Contributing to claude-n

claude-n is one bash script plus a bats test suite. Changes are small and
test-first.

## Setup

You need **zsh** (the tool's target shell), **bash** (runs the CLI), and these two
tools:

- [bats-core](https://github.com/bats-core/bats-core) ≥ 1.5 — the test runner
- [shellcheck](https://www.shellcheck.net/) — the linter

On macOS:

```sh
brew install bats-core shellcheck
```

## Run the checks

Both must pass; CI runs the same two commands:

```sh
bats tests/              # the test suite
shellcheck bin/claude-n  # the linter
```

## Layout

| Path | What it is |
|---|---|
| `bin/claude-n` | The entire CLI. `init zsh` emits the `command_not_found_handler` as a single-quoted heredoc. |
| `tests/*.bats` | The suite — one file per concern (resolve, chain, install, accounts, cli_meta). |

## Conventions

- The CLI is bash with `set -euo pipefail` and stays **shellcheck-clean**.
- The emitted zsh handler and resolver live **inside the single-quoted heredoc** so
  shellcheck doesn't parse them as bash. Keep them there.
- Account-number handling (leading-zero stripping via `10#`, the bounded digit count)
  must stay **identical** between the emitted handler and the CLI's `which`/`rm`. If you
  change one, change the other.
- Tests that trigger the handler must sandbox `HOME` and `CLAUDE_N_HOME` under
  `$BATS_TEST_TMPDIR`. A test must never read or write the real `~/.claude-n`.
- Guard every bats assertion so it fails the test under macOS's bash 3.2 (end a bare
  `[[ … ]]` with `|| false`). An unguarded assertion can pass silently there.

## Making a change

1. Branch off `main` (`git switch -c <type>/<slug>`).
2. Write a failing bats test for the behavior first; run it and watch it fail.
3. Implement the smallest change that makes it pass; keep test output pristine.
4. Run both checks above.
5. Open a pull request into `main`.

## Out of scope

These are deliberate non-goals — please open an issue before reintroducing any of them:
bash/fish support, third-party launcher or wrapper integrations, install-time conflict
detection, named (non-numeric) accounts, and any handling of OAuth tokens (isolation is
`CLAUDE_CONFIG_DIR` only).
