#!/usr/bin/env bats
# Run from the repo root: bats tests/
bats_require_minimum_version 1.5.0

setup() {
  # Every handler-triggering test runs against a sandboxed HOME so mkdir -p
  # never touches the real home directory.
  export HOME="$BATS_TEST_TMPDIR/home"
  export CLAUDE_N_HOME="$BATS_TEST_TMPDIR/home/.claude-n"
  mkdir -p "$HOME" "$BATS_TEST_TMPDIR/bin"
  # Hermetic PATH: system dirs plus the fake bin only, so a developer's own
  # claudeN executable (e.g. ~/.local/bin/claude2) cannot shadow the handler.
  export SANE_PATH="$BATS_TEST_TMPDIR/bin:/usr/bin:/bin"
  # Fake `claude`: prints its config dir (or "unset") and its arguments.
  cat >"$BATS_TEST_TMPDIR/bin/claude" <<'FAKE'
#!/bin/sh
echo "dir=${CLAUDE_CONFIG_DIR-unset} args=$*"
FAKE
  chmod +x "$BATS_TEST_TMPDIR/bin/claude"
}

resolve() { zsh -c 'eval "$(bin/claude-n init zsh)"; if __claude_n_resolve "'"$1"'"; then :; else echo __PASSTHROUGH__; fi'; }

@test "claude1 and claude-1 resolve to default" {
  [ "$(HOME=/tmp/h resolve claude1)" = default ]
  [ "$(HOME=/tmp/h resolve claude-1)" = default ]
}

@test "claude2 / claude-2 / claude007 resolve to normalized account dirs" {
  [ "$(HOME=/tmp/h CLAUDE_N_HOME=/tmp/h/.claude-n resolve claude2)" = /tmp/h/.claude-n/2 ]
  [ "$(HOME=/tmp/h CLAUDE_N_HOME=/tmp/h/.claude-n resolve claude-2)" = /tmp/h/.claude-n/2 ]
  [ "$(HOME=/tmp/h CLAUDE_N_HOME=/tmp/h/.claude-n resolve claude007)" = /tmp/h/.claude-n/7 ]
}

@test "CLAUDE_N_HOME unset falls back to \$HOME/.claude-n" {
  [ "$(unset CLAUDE_N_HOME; HOME=/tmp/h resolve claude3)" = /tmp/h/.claude-n/3 ]
}

@test "claude0, claude-0, and non-matches pass through" {
  [ "$(resolve claude0)" = __PASSTHROUGH__ ]
  [ "$(resolve claude-0)" = __PASSTHROUGH__ ]
  [ "$(resolve ls)" = __PASSTHROUGH__ ]
  [ "$(resolve claude)" = __PASSTHROUGH__ ]
  [ "$(resolve claude2x)" = __PASSTHROUGH__ ]
}

@test "claude2 execs real claude with CLAUDE_CONFIG_DIR set" {
  run zsh -c 'PATH="$SANE_PATH"; eval "$(bin/claude-n init zsh)"; claude2 --flag x'
  [ "$status" -eq 0 ]
  [ "$output" = "dir=$CLAUDE_N_HOME/2 args=--flag x" ]
  [ -d "$CLAUDE_N_HOME/2" ]
}

@test "claude1 execs real claude without overriding CLAUDE_CONFIG_DIR" {
  run zsh -c 'unset CLAUDE_CONFIG_DIR; PATH="$SANE_PATH"; eval "$(bin/claude-n init zsh)"; claude1 hi'
  [ "$status" -eq 0 ]
  [ "$output" = "dir=unset args=hi" ]
  [ ! -e "$CLAUDE_N_HOME" ]
}

@test "claude2 with no claude on PATH errors non-zero" {
  # PATH holds only mkdir, so zsh resolves the handler's mkdir but not claude.
  mkdir -p "$BATS_TEST_TMPDIR/nobin"
  ln -s "$(command -v mkdir)" "$BATS_TEST_TMPDIR/nobin/mkdir"
  run -127 zsh -c 'eval "$(bin/claude-n init zsh)"; PATH="$BATS_TEST_TMPDIR/nobin"; claude2'
  [ "$status" -ne 0 ]
  [[ "$output" == *"claude"*"not found"* ]]
}

@test "init rejects a non-zsh shell" {
  run bin/claude-n init bash
  [ "$status" -ne 0 ]
  [[ "$output" == *"zsh"* ]]
}
