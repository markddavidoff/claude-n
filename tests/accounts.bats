#!/usr/bin/env bats
# Run from the repo root: bats tests/
bats_require_minimum_version 1.5.0


# Bash 3.2 does not trip errexit on a failed [[ ]], so every [[ ]] assertion
# below ends in "|| false" to fail the test mid-body too.
setup() {
  # Every test runs against a temp account home; nothing touches the real one.
  export HOME="$BATS_TEST_TMPDIR/realhome"
  export H="$BATS_TEST_TMPDIR/h"
  mkdir -p "$HOME"
}

@test "which prints the normalized account dir" {
  run env CLAUDE_N_HOME=/tmp/h/.claude-n bin/claude-n which 007
  [ "$status" -eq 0 ]
  [ "$output" = /tmp/h/.claude-n/7 ]
}

@test "which falls back to \$HOME/.claude-n when CLAUDE_N_HOME is unset" {
  run env -u CLAUDE_N_HOME HOME=/tmp/hh bin/claude-n which 3
  [ "$status" -eq 0 ]
  [ "$output" = /tmp/hh/.claude-n/3 ]
}

@test "which 1 prints a default-account note, not a path" {
  run env CLAUDE_N_HOME="$H" bin/claude-n which 1
  [ "$status" -eq 0 ]
  [[ "$output" == *"default"* ]] || false
  [[ "$output" != *"$H"* ]] || false
}

@test "which rejects 0, non-numeric, and missing arguments" {
  run env CLAUDE_N_HOME="$H" bin/claude-n which 0
  [ "$status" -ne 0 ]
  run env CLAUDE_N_HOME="$H" bin/claude-n which abc
  [ "$status" -ne 0 ]
  run env CLAUDE_N_HOME="$H" bin/claude-n which 2x
  [ "$status" -ne 0 ]
  run env CLAUDE_N_HOME="$H" bin/claude-n which
  [ "$status" -ne 0 ]
}

@test "ls shows logged-in identity and 'not logged in'" {
  mkdir -p "$H/2" "$H/3"
  printf '{"oauthAccount":{"emailAddress":"a@b.com"}}' > "$H/2/.claude.json"
  run env CLAUDE_N_HOME="$H" bin/claude-n ls
  [ "$status" -eq 0 ]
  [[ "$output" == *"2"*"a@b.com"* ]] || false
  [[ "$output" == *"3"*"not logged in"* ]] || false
}

@test "ls reads the email from a pretty-printed .claude.json" {
  mkdir -p "$H/4"
  cat > "$H/4/.claude.json" <<'JSON'
{
  "numStartups": 3,
  "oauthAccount": {
    "accountUuid": "abc",
    "emailAddress": "pretty@example.com",
    "displayName": "P"
  }
}
JSON
  run env CLAUDE_N_HOME="$H" bin/claude-n ls
  [[ "$output" == *"4"*"pretty@example.com"* ]] || false
}

@test "ls treats a .claude.json without an oauthAccount email as not logged in" {
  mkdir -p "$H/2" "$H/3"
  printf '{"other":{"emailAddress":"x@y.com"}}' > "$H/2/.claude.json"
  printf '{"oauthAccount":{}}' > "$H/3/.claude.json"
  run env CLAUDE_N_HOME="$H" bin/claude-n ls
  [ "$status" -eq 0 ]
  [[ "$output" != *"x@y.com"* ]] || false
  [[ "$output" == *"2"*"not logged in"* ]] || false
  [[ "$output" == *"3"*"not logged in"* ]] || false
}

@test "ls lists accounts in numeric order and skips non-account dirs" {
  mkdir -p "$H/10" "$H/2" "$H/.trash-5-20260101000000" "$H/notes"
  run env CLAUDE_N_HOME="$H" bin/claude-n ls
  [ "$status" -eq 0 ]
  [[ "$output" != *"notes"* ]] || false
  [[ "$output" != *"trash"* ]] || false
  [ "$(printf '%s\n' "$output" | awk '{print $1}' | tr '\n' ' ')" = "2 10 " ]
}

@test "ls with no accounts or no home exits 0 with a note" {
  run env CLAUDE_N_HOME="$H" bin/claude-n ls
  [ "$status" -eq 0 ]
  [[ "$output" == *"no accounts"* ]] || false
}

@test "rm refuses account 1 and missing accounts, deletes with --yes" {
  run env CLAUDE_N_HOME="$H" bin/claude-n rm 1
  [ "$status" -ne 0 ]
  mkdir -p "$H/5"
  run env CLAUDE_N_HOME="$H" bin/claude-n rm 5 --yes
  [ "$status" -eq 0 ]
  [ ! -d "$H/5" ]
}

@test "rm errors clearly on a missing account and a bad number" {
  mkdir -p "$H"
  run env CLAUDE_N_HOME="$H" bin/claude-n rm 9 --yes
  [ "$status" -ne 0 ]
  [[ "$output" == *"9"*"not found"* ]] || false
  run env CLAUDE_N_HOME="$H" bin/claude-n rm abc --yes
  [ "$status" -ne 0 ]
  run env CLAUDE_N_HOME="$H" bin/claude-n rm
  [ "$status" -ne 0 ]
}

@test "rm backs the account up to a .trash- sibling inside the home" {
  mkdir -p "$H/5"
  echo keep > "$H/5/marker"
  run env CLAUDE_N_HOME="$H" bin/claude-n rm 005 --yes
  [ "$status" -eq 0 ]
  [ ! -e "$H/5" ]
  [[ "$output" == *".trash-"* ]] || false
  trash=$(find "$H" -mindepth 1 -maxdepth 1 -name '.trash-*' | head -1)
  [ -n "$trash" ]
  [ "$(cat "$trash/marker")" = keep ]
}

@test "rm without --yes aborts unless the answer is yes" {
  mkdir -p "$H/5"
  run env CLAUDE_N_HOME="$H" bin/claude-n rm 5 <<<"n"
  [ "$status" -ne 0 ]
  [ -d "$H/5" ]
  # No input at all (EOF) must also abort, not delete.
  run env CLAUDE_N_HOME="$H" bin/claude-n rm 5 </dev/null
  [ "$status" -ne 0 ]
  [ -d "$H/5" ]
  run env CLAUDE_N_HOME="$H" bin/claude-n rm 5 <<<"y"
  [ "$status" -eq 0 ]
  [ ! -d "$H/5" ]
}

@test "rm accepts --yes before the account number" {
  mkdir -p "$H/6"
  run env CLAUDE_N_HOME="$H" bin/claude-n rm --yes 6
  [ "$status" -eq 0 ]
  [ ! -d "$H/6" ]
}

@test "which and rm reject account numbers longer than 15 digits" {
  run env CLAUDE_N_HOME="$H" bin/claude-n which 1234567890123456
  [ "$status" -ne 0 ]
  mkdir -p "$H/5"
  run env CLAUDE_N_HOME="$H" bin/claude-n rm 1234567890123456 --yes
  [ "$status" -ne 0 ]
  [ -d "$H/5" ]
  run env CLAUDE_N_HOME="$H" bin/claude-n which 999999999999999
  [ "$status" -eq 0 ]
  [ "$output" = "$H/999999999999999" ]
}

@test "ls prints no raw error for an unreadable .claude.json" {
  [ "$(id -u)" -ne 0 ] || skip "root ignores file modes"
  mkdir -p "$H/2"
  printf '{"oauthAccount":{"emailAddress":"a@b.com"}}' > "$H/2/.claude.json"
  chmod 000 "$H/2/.claude.json"
  run env CLAUDE_N_HOME="$H" bin/claude-n ls
  chmod 644 "$H/2/.claude.json"
  [ "$status" -eq 0 ]
  [[ "$output" != *"ermission"* ]] || false
  [[ "$output" == *"2"*"not logged in"* ]] || false
}
