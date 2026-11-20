# claude-n

[![CI](https://github.com/markddavidoff/claude-n/actions/workflows/ci.yml/badge.svg)](https://github.com/markddavidoff/claude-n/actions/workflows/ci.yml)

Type `claude2` to run Claude Code as a second account, `claude3` for a third, and so on. Each number gets its own config directory, so accounts do not share credentials or settings. There is no per-account setup: the first time you run a new number, you run `/login` inside Claude Code.

`claude1` is your normal account and uses your default Claude Code config.

## Install

claude-n needs zsh (the macOS default) and Claude Code on your `PATH`.

1. Clone the repo and put `bin/claude-n` on your `PATH`. Any directory on your `PATH` works; `~/.local/bin` is an example.

   ```sh
   git clone https://github.com/markddavidoff/claude-n.git
   ln -s "$PWD/claude-n/bin/claude-n" ~/.local/bin/claude-n
   ```

2. Add the shell hook to your zsh rc:

   ```sh
   claude-n install
   ```

   This appends one line to `$ZDOTDIR/.zshrc` (or `~/.zshrc` when `ZDOTDIR` is unset), after your existing content:

   ```sh
   eval "$(claude-n init zsh)"
   ```

   Running `install` again does not add a second line.

3. Restart your shell, or run `exec zsh`, then run `hash -r`.

## Usage

```sh
claude1      # your default account, no override
claude2      # isolated account 2
claude-2     # account 2, hyphenated spelling
claude7      # isolated account 7
```

`claude2` and `claude-2` are the same account. Leading zeros are ignored, so `claude007` is account 7. Arguments pass through to Claude Code: `claude2 --resume` runs `claude --resume` under account 2.

`claude0`, `claude-0`, and any name that is not `claude` followed by a number fall through to your shell's normal "command not found" behavior.

An account you have not used before starts logged out. Run `/login` once; after that the account stays logged in.

## How isolation works

For each account N of 2 or more, claude-n creates `~/.claude-n/N` and launches Claude Code with `CLAUDE_CONFIG_DIR` set to that directory. Claude Code keeps the account's credentials and settings there. claude-n never reads or writes tokens itself.

Account 1 sets no override, so it uses Claude Code's default config location.

To keep account directories somewhere other than `~/.claude-n`, set `CLAUDE_N_HOME`. Export it, for example `export CLAUDE_N_HOME=~/accounts` in `.zshrc` above the `eval` line. It must be exported: `ls`, `rm`, and `which` run as child processes and only see exported variables, so an unexported value makes the shell hook and the CLI disagree about where accounts live.

## Commands

| Command | What it does |
|---|---|
| `claude-n install` | Add the hook line to your zsh rc. |
| `claude-n uninstall` | Remove the hook line from your zsh rc. |
| `claude-n init zsh` | Print the zsh integration. The rc line evaluates this output. |
| `claude-n ls` | List accounts under `~/.claude-n` with the email each is logged in as, or `not logged in`. |
| `claude-n rm <N> [--yes]` | Remove account N. Asks for confirmation unless you pass `--yes`. Refuses account 1. |
| `claude-n which <N>` | Print the config directory for account N. For account 1, prints a note that it uses the default Claude config (no managed directory). |
| `claude-n --help`, `claude-n --version` | Show usage or the version. |

`rm` moves `~/.claude-n/N` to `~/.claude-n/.trash-N-<timestamp>` instead of deleting it. That backup still holds the account's OAuth credentials, so delete it yourself when you no longer want them on disk.

## Uninstall

```sh
claude-n uninstall
```

This removes the hook line from your zsh rc. Account directories stay where they are; remove each one with `claude-n rm <N>`. Then delete the `claude-n` symlink and the clone.

## Caveats

**An existing `claudeN` command wins.** claude-n runs from zsh's `command_not_found_handler`, which fires only for names that resolve to nothing else. If a `claude2` alias, shell function, or executable on your `PATH` already exists (from another tool, for example), zsh runs that and claude-n never sees the call. When a number does not route to the account you expect, check what zsh resolves it to:

```sh
type claude2
```

Remove or rename the conflicting alias, function, or binary.

**Other not-found handlers keep working.** If another tool already defined a `command_not_found_handler` (mise and Homebrew's command-not-found are common), claude-n saves it and calls it for every name that is not `claudeN`. Keep the `eval` line after those tools in your rc so claude-n can capture their handler. One known edge: if the earlier handler is a zsh autoload stub that has not loaded yet, claude-n may fail to capture it, and the chain breaks.

**zsh only.** bash and fish are not supported yet, and `claude-n init` rejects any shell other than `zsh`.

## License

MIT. See `LICENSE`.
