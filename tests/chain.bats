#!/usr/bin/env bats
# Run from the repo root: bats tests/
bats_require_minimum_version 1.5.0

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export CLAUDE_N_HOME="$BATS_TEST_TMPDIR/home/.claude-n"
  mkdir -p "$HOME"
}

@test "a prior handler is still called on a non-match" {
  run -127 zsh -c 'command_not_found_handler(){ echo "PRIOR:$1"; return 127; }; eval "$(bin/claude-n init zsh)"; totallymissing'
  [[ "$output" == *"PRIOR:totallymissing"* ]]
}

@test "re-sourcing init does not recurse or double-chain" {
  run -127 zsh -c 'command_not_found_handler(){ echo "PRIOR:$1"; return 127; }; eval "$(bin/claude-n init zsh)"; eval "$(bin/claude-n init zsh)"; totallymissing'
  [ "$(grep -c PRIOR: <<<"$output")" -eq 1 ]
}

@test "re-sourcing init with no prior handler does not recurse" {
  run zsh -c 'eval "$(bin/claude-n init zsh)"; eval "$(bin/claude-n init zsh)"; totallymissing; echo "rc=$?"'
  [[ "$output" == *"not found"* ]]
  [[ "$output" == *"rc=127"* ]]
}

@test "no prior handler: non-match prints not-found and returns 127" {
  run zsh -c 'eval "$(bin/claude-n init zsh)"; totallymissing; echo "rc=$?"'
  [[ "$output" == *"not found"* ]]
  [[ "$output" == *"rc=127"* ]]
}
