# claude-n

`claude-n` launches Claude Code under isolated, per-account config directories, so
several Claude accounts can run side by side on one machine without sharing
`~/.claude` state. It is a zsh-first tool with no runtime dependencies beyond bash and
coreutils. See `docs/claude-n-design.md` for the design.

Status: early development (v0.1.0 skeleton). The subcommands `install`, `uninstall`,
`init`, `ls`, `rm`, and `which` are not implemented yet.
