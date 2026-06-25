#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT=

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'ok - %s\n' "$1"
}

cleanup() {
  if [ -n "${TMP_ROOT:-}" ]; then
    rm -rf "$TMP_ROOT"
  fi
}

trap cleanup EXIT

TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/fm-setup-memory-tests.XXXXXX")
FIXTURE_SEED="$ROOT/tests/fixtures/memory-seed"

run_setup() {
  local home=$1
  shift
  HOME="$home" FM_ROOT_OVERRIDE="$ROOT" FM_MEMORY_SEED_DIR="$FIXTURE_SEED" \
    "$ROOT/bin/fm-setup-memory.sh" --skip-creds "$@"
}

test_installs_global_and_links() {
  local home="$TMP_ROOT/home-a"
  mkdir -p "$home"
  run_setup "$home"

  [ -f "$home/.agent/GLOBAL.md" ] || fail "GLOBAL.md not installed"
  [ -f "$home/.grok/Agents.md" ] || fail "grok Agents.md not linked"
  [ -f "$home/.codex/AGENTS.md" ] || fail "codex AGENTS.md not linked"
  [ -f "$home/.config/opencode/AGENTS.md" ] || fail "opencode AGENTS.md not linked"
  [ -f "$home/.claude/CLAUDE.md" ] || fail "claude CLAUDE.md not written"
  [ -f "$home/.grok/skills/wremember/SKILL.md" ] || fail "wremember skill not installed"
  [ -f "$home/.grok/skills/wrecall/SKILL.md" ] || fail "wrecall skill not installed"

  cmp -s "$home/.agent/GLOBAL.md" "$home/.grok/Agents.md" \
    || fail "grok link does not match GLOBAL.md"
  cmp -s "$home/.agent/GLOBAL.md" "$home/.codex/AGENTS.md" \
    || fail "codex link does not match GLOBAL.md"

  pass "setup installs GLOBAL.md, harness links, and skills"
}

test_idempotent_second_run() {
  local home="$TMP_ROOT/home-b"
  mkdir -p "$home"
  run_setup "$home" >/dev/null
  out=$(run_setup "$home" 2>&1)
  printf '%s\n' "$out" | grep -q 'unchanged: .*GLOBAL.md' \
    || fail "second run did not report unchanged GLOBAL.md"
  pass "second run is idempotent"
}

test_keeps_custom_global_without_force() {
  local home="$TMP_ROOT/home-c"
  mkdir -p "$home"
  run_setup "$home" >/dev/null
  printf 'custom\n' >>"$home/.agent/GLOBAL.md"
  out=$(run_setup "$home" 2>&1)
  printf '%s\n' "$out" | grep -q 'kept: .*GLOBAL.md' \
    || fail "custom GLOBAL.md was not kept without --force"
  grep -q 'custom' "$home/.agent/GLOBAL.md" \
    || fail "custom GLOBAL.md content was lost"
  pass "keeps customized GLOBAL.md unless --force"
}

test_force_replaces_global() {
  local home="$TMP_ROOT/home-d"
  mkdir -p "$home"
  run_setup "$home" >/dev/null
  printf 'custom\n' >>"$home/.agent/GLOBAL.md"
  run_setup "$home" --force >/dev/null
  grep -q 'custom' "$home/.agent/GLOBAL.md" \
    && fail "custom GLOBAL.md survived --force"
  cmp -s "$home/.agent/GLOBAL.md" "$FIXTURE_SEED/GLOBAL.md" \
    || fail "GLOBAL.md does not match seed after --force"
  pass "--force replaces GLOBAL.md from seed"
}

test_requires_private_seed_without_config() {
  local home="$TMP_ROOT/home-f"
  mkdir -p "$home"
  if HOME="$home" FM_ROOT_OVERRIDE="$ROOT" "$ROOT/bin/fm-setup-memory.sh" --skip-creds >/dev/null 2>&1; then
    fail "setup succeeded without private memory seed configured"
  fi
  pass "refuses to run without private memory seed"
}

test_patches_json_mcp_configs() {
  local home="$TMP_ROOT/home-e"
  mkdir -p "$home/.config/opencode"
  printf '{}\n' >"$home/.claude.json"
  printf '{}\n' >"$home/.config/opencode/opencode.json"
  run_setup "$home" >/dev/null
  grep -q '"memwal"' "$home/.claude.json" || fail "claude.json missing memwal"
  grep -q '"memwal"' "$home/.config/opencode/opencode.json" || fail "opencode.json missing memwal"
  pass "patches claude and opencode memwal MCP config"
}

test_installs_global_and_links
test_idempotent_second_run
test_keeps_custom_global_without_force
test_force_replaces_global
test_patches_json_mcp_configs
test_requires_private_seed_without_config