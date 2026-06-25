#!/usr/bin/env bash
# Bootstrap cross-harness agent memory on this machine.
#
# Installs ~/.agent/GLOBAL.md from firstmate seed, hardlinks (or symlinks) it
# into Grok/Codex/OpenCode harness homes, writes Claude's @-import, copies
# Walrus wremember/wrecall skills, patches memwal MCP config, and optionally
# builds ~/.memwal/credentials.json from 1Password.
#
# Idempotent: safe to re-run after git pull or on a new machine.
#
# Usage: fm-setup-memory.sh [--force] [--skip-creds]
#   --force       overwrite ~/.agent/GLOBAL.md from seed and replace conflicting harness links
#   --skip-creds  skip 1Password / memwal credential bootstrap
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FM_ROOT="${FM_ROOT_OVERRIDE:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SEED="$FM_ROOT/seed/agent-memory"
GLOBAL_REL=".agent/GLOBAL.md"

FORCE=0
SKIP_CREDS=0

usage() {
  echo "usage: fm-setup-memory.sh [--force] [--skip-creds]" >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --force)
      FORCE=1
      ;;
    --skip-creds)
      SKIP_CREDS=1
      ;;
    *)
      usage
      exit 1
      ;;
  esac
  shift
done

is_windows() {
  case "$(uname -s 2>/dev/null || true)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
  esac
  [ -n "${WINDIR:-}" ] && return 0
  return 1
}

path_for_claude_import() {
  local path=$1
  if is_windows && command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$path"
    return 0
  fi
  printf '%s\n' "$path"
}

toml_escape_cwd() {
  local dir=$1
  if is_windows && command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$dir" | sed 's/\\/\\\\/g'
    return 0
  fi
  printf '%s\n' "$dir"
}

install_global() {
  local global=$1 seed_global=$2
  mkdir -p "$(dirname "$global")"
  if [ ! -f "$global" ]; then
    cp "$seed_global" "$global"
    echo "installed: $global"
    return 0
  fi
  if cmp -s "$global" "$seed_global"; then
    echo "unchanged: $global"
    return 0
  fi
  if [ "$FORCE" -eq 1 ]; then
    cp "$seed_global" "$global"
    echo "updated: $global (from seed)"
    return 0
  fi
  echo "kept: $global (differs from seed; pass --force to replace)" >&2
}

link_global() {
  local target=$1 global=$2 label=$3
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -f "$target" ] && cmp -s "$target" "$global"; then
      echo "unchanged: $label -> GLOBAL.md"
      return 0
    fi
    if [ "$FORCE" -eq 0 ]; then
      echo "skipped: $label (existing file differs; pass --force to replace)" >&2
      return 0
    fi
    rm -f "$target"
  fi
  if ln "$global" "$target" 2>/dev/null; then
    echo "linked: $label (hardlink)"
    return 0
  fi
  rm -f "$target"
  ln -s "$global" "$target"
  echo "linked: $label (symlink)"
}

write_claude_import() {
  local global=$1 claude_md=$2
  local import_path expected
  import_path=$(path_for_claude_import "$global")
  expected="@${import_path}"
  mkdir -p "$(dirname "$claude_md")"
  if [ -f "$claude_md" ] && [ "$(tr -d '\r' <"$claude_md")" = "$expected" ]; then
    echo "unchanged: claude CLAUDE.md import"
    return 0
  fi
  if [ -e "$claude_md" ] && [ "$FORCE" -eq 0 ]; then
    echo "skipped: claude CLAUDE.md (existing file; pass --force to replace)" >&2
    return 0
  fi
  printf '%s\n' "$expected" >"$claude_md"
  echo "installed: claude CLAUDE.md import"
}

install_skill() {
  local src=$1 dest=$2
  mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    echo "unchanged: skill $(basename "$(dirname "$src")") -> $(dirname "$dest")"
    return 0
  fi
  cp "$src" "$dest"
  echo "installed: skill $(basename "$(dirname "$src")") -> $(dirname "$dest")"
}

ensure_toml_memwal() {
  local cfg=$1 harness=$2
  mkdir -p "$(dirname "$cfg")"
  touch "$cfg"
  if grep -q 'mcp_servers\.memwal' "$cfg" 2>/dev/null || grep -q '\[mcp_servers\.memwal\]' "$cfg" 2>/dev/null; then
    echo "unchanged: $harness memwal MCP"
    return 0
  fi
  local cwd
  cwd=$(toml_escape_cwd "$HOME")
  cat >>"$cfg" <<EOF

[mcp_servers.memwal]
command = "npx"
args = ["-y", "@mysten-incubation/memwal-mcp"]
cwd = "$cwd"
startup_timeout_sec = 60
enabled = true
EOF
  echo "patched: $harness memwal MCP"
}

patch_json_memwal() {
  local harness=$1 cfg=$2
  command -v node >/dev/null 2>&1 || {
    echo "skipped: $harness memwal MCP (node not found)" >&2
    return 0
  }
  local patcher=$SEED/scripts/patch-harness-mcp.mjs
  local home_for_cfg
  if is_windows && command -v cygpath >/dev/null 2>&1; then
    home_for_cfg=$(cygpath -w "$HOME")
  else
    home_for_cfg=$HOME
  fi
  node "$patcher" "$harness" "$cfg" "$home_for_cfg"
}

install_memwal_creds() {
  local creds="$HOME/.memwal/credentials.json"
  if [ -f "$creds" ]; then
    echo "unchanged: memwal credentials"
    return 0
  fi
  if is_windows; then
    local ps1=$SEED/scripts/setup-memwal-creds.ps1
    if command -v pwsh >/dev/null 2>&1; then
      pwsh -NoProfile -File "$ps1" && return 0
    fi
    if command -v powershell >/dev/null 2>&1; then
      powershell -NoProfile -File "$ps1" && return 0
    fi
  else
    local sh=$SEED/scripts/setup-memwal-creds.sh
    if [ -x "$sh" ] || chmod +x "$sh" 2>/dev/null; then
      bash "$sh" && return 0
    fi
  fi
  echo "skipped: memwal credentials (run seed scripts manually or memwal_login in a harness)" >&2
}

[ -f "$SEED/GLOBAL.md" ] || {
  echo "error: missing seed at $SEED/GLOBAL.md" >&2
  exit 1
}

GLOBAL="$HOME/$GLOBAL_REL"
install_global "$GLOBAL" "$SEED/GLOBAL.md"

link_global "$HOME/.grok/Agents.md" "$GLOBAL" "grok Agents.md"
link_global "$HOME/.codex/AGENTS.md" "$GLOBAL" "codex AGENTS.md"
link_global "$HOME/.config/opencode/AGENTS.md" "$GLOBAL" "opencode AGENTS.md"
write_claude_import "$GLOBAL" "$HOME/.claude/CLAUDE.md"

for skill in wremember wrecall; do
  src="$SEED/skills/$skill/SKILL.md"
  [ -f "$src" ] || continue
  install_skill "$src" "$HOME/.grok/skills/$skill/SKILL.md"
  install_skill "$src" "$HOME/.claude/skills/$skill/SKILL.md"
  install_skill "$src" "$HOME/.codex/skills/$skill/SKILL.md"
done

ensure_toml_memwal "$HOME/.grok/config.toml" "grok"
ensure_toml_memwal "$HOME/.codex/config.toml" "codex"
patch_json_memwal claude "$HOME/.claude.json"
patch_json_memwal opencode "$HOME/.config/opencode/opencode.json"

if [ "$SKIP_CREDS" -eq 0 ]; then
  install_memwal_creds
else
  echo "skipped: memwal credentials (--skip-creds)"
fi

echo "done: agent memory wired for $(uname -s 2>/dev/null || echo unknown)"