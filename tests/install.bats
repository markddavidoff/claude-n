#!/usr/bin/env bats
# Run from the repo root: bats tests/

EVAL_LINE='eval "$(claude-n init zsh)"'

@test "install adds the eval line once and is idempotent" {
  CLAUDE_N_RC="$BATS_TEST_TMPDIR/zshrc" run bin/claude-n install
  CLAUDE_N_RC="$BATS_TEST_TMPDIR/zshrc" run bin/claude-n install
  [ "$(grep -c 'claude-n init zsh' "$BATS_TEST_TMPDIR/zshrc")" -eq 1 ]
  grep -qxF "$EVAL_LINE" "$BATS_TEST_TMPDIR/zshrc"
}

@test "install creates the rc file if absent" {
  CLAUDE_N_RC="$BATS_TEST_TMPDIR/new-zshrc" run bin/claude-n install
  [ "$status" -eq 0 ]
  [ -f "$BATS_TEST_TMPDIR/new-zshrc" ]
}

@test "install appends after existing content and keeps it" {
  printf 'eval "$(mise activate zsh)"\nexport FOO=1\n' > "$BATS_TEST_TMPDIR/zshrc"
  CLAUDE_N_RC="$BATS_TEST_TMPDIR/zshrc" run bin/claude-n install
  [ "$status" -eq 0 ]
  [ "$(sed -n 1p "$BATS_TEST_TMPDIR/zshrc")" = 'eval "$(mise activate zsh)"' ]
  [ "$(sed -n 2p "$BATS_TEST_TMPDIR/zshrc")" = 'export FOO=1' ]
  [ "$(tail -n 1 "$BATS_TEST_TMPDIR/zshrc")" = "$EVAL_LINE" ]
}

@test "install handles an rc file with no trailing newline" {
  printf 'export FOO=1' > "$BATS_TEST_TMPDIR/zshrc"
  CLAUDE_N_RC="$BATS_TEST_TMPDIR/zshrc" run bin/claude-n install
  [ "$(sed -n 1p "$BATS_TEST_TMPDIR/zshrc")" = 'export FOO=1' ]
  [ "$(tail -n 1 "$BATS_TEST_TMPDIR/zshrc")" = "$EVAL_LINE" ]
}

@test "install prints a restart-shell / hash -r hint" {
  CLAUDE_N_RC="$BATS_TEST_TMPDIR/zshrc" run bin/claude-n install
  [[ "$output" == *"hash -r"* ]]
}

@test "install defaults to \${ZDOTDIR}/.zshrc when CLAUDE_N_RC is unset" {
  mkdir -p "$BATS_TEST_TMPDIR/zd"
  env -u CLAUDE_N_RC ZDOTDIR="$BATS_TEST_TMPDIR/zd" bin/claude-n install
  grep -qxF "$EVAL_LINE" "$BATS_TEST_TMPDIR/zd/.zshrc"
}

@test "uninstall removes exactly the eval line" {
  CLAUDE_N_RC="$BATS_TEST_TMPDIR/zshrc" bin/claude-n install
  printf 'echo keep-me\n' >> "$BATS_TEST_TMPDIR/zshrc"
  CLAUDE_N_RC="$BATS_TEST_TMPDIR/zshrc" run bin/claude-n uninstall
  [ "$(grep -c 'claude-n init zsh' "$BATS_TEST_TMPDIR/zshrc")" -eq 0 ]
  grep -q 'keep-me' "$BATS_TEST_TMPDIR/zshrc"
}

@test "uninstall leaves similar-looking lines untouched" {
  printf '# eval "$(claude-n init zsh)"\neval "$(claude-n init zsh)" # x\necho keep\n%s\n' "$EVAL_LINE" > "$BATS_TEST_TMPDIR/zshrc"
  CLAUDE_N_RC="$BATS_TEST_TMPDIR/zshrc" run bin/claude-n uninstall
  [ "$status" -eq 0 ]
  [ "$(wc -l < "$BATS_TEST_TMPDIR/zshrc" | tr -d ' ')" -eq 3 ]
  ! grep -qxF "$EVAL_LINE" "$BATS_TEST_TMPDIR/zshrc"
  grep -qxF 'echo keep' "$BATS_TEST_TMPDIR/zshrc"
}

@test "uninstall succeeds when the rc file does not exist" {
  CLAUDE_N_RC="$BATS_TEST_TMPDIR/missing" run bin/claude-n uninstall
  [ "$status" -eq 0 ]
  [ ! -e "$BATS_TEST_TMPDIR/missing" ]
}
