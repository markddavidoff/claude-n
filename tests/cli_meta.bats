#!/usr/bin/env bats
# Run from the repo root: bats tests/

@test "--version prints a semver" {
  run bin/claude-n --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^claude-n\ [0-9]+\.[0-9]+\.[0-9]+$ ]] || false
}

@test "--help prints usage and lists subcommands" {
  run bin/claude-n --help
  [ "$status" -eq 0 ]
  for sub in install uninstall init ls rm which; do
    [[ "$output" =~ (^|$'\n')[[:space:]]+"$sub"[[:space:]] ]] || false
  done
}

@test "unknown subcommand exits non-zero with a message" {
  run bin/claude-n bogus
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown"* ]] || false
}
