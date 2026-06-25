#!/usr/bin/env bash
# Bootstrap WezTerm + tmux + Helix captain stack on this machine.
#
# Config source (first match):
#   1. FM_CAPTAIN_SEED_DIR/<platform>/
#   2. Private memory-seed repo captain/<platform>/ (same repo as GLOBAL.md)
#   3. firstmate seed/captain-stack/<platform>/ (public template)
#
# Usage: fm-setup-captain.sh [--install-brew]
#   --install-brew  brew install wezterm tmux helix (asks nothing; run when captain approved)
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FM_ROOT="${FM_ROOT_OVERRIDE:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PUBLIC_SEED="$FM_ROOT/seed/captain-stack"
MEMORY_SEED_CONFIG="${FM_MEMORY_SEED_CONFIG:-$HOME/.config/firstmate/memory-seed-repo}"
MEMORY_SEED_CACHE="${FM_MEMORY_SEED_CACHE:-$HOME/.cache/firstmate/memory-seed}"

INSTALL_BREW=0

usage() {
  echo "usage: fm-setup-captain.sh [--install-brew]" >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --install-brew)
      INSTALL_BREW=1
      ;;
    *)
      usage
      exit 1
      ;;
  esac
  shift
done

detect_platform() {
  case "$(uname -s 2>/dev/null || true)" in
    Darwin) echo mac ;;
    MINGW*|MSYS*|CYGWIN*) echo win ;;
    Linux) echo linux ;;
    *) echo unknown ;;
  esac
}

install_file() {
  local src=$1 dest=$2
  mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    echo "unchanged: $dest"
    return 0
  fi
  cp "$src" "$dest"
  echo "installed: $dest"
}

resolve_captain_seed_dir() {
  local platform=$1
  if [ -n "${FM_CAPTAIN_SEED_DIR:-}" ] && [ -d "$FM_CAPTAIN_SEED_DIR" ]; then
    printf '%s\n' "$FM_CAPTAIN_SEED_DIR"
    return 0
  fi
  if [ -d "$MEMORY_SEED_CACHE/captain/$platform" ]; then
    printf '%s\n' "$MEMORY_SEED_CACHE/captain/$platform"
    return 0
  fi
  if [ -d "$PUBLIC_SEED/$platform" ]; then
    echo "note: using public captain template from firstmate seed" >&2
    printf '%s\n' "$PUBLIC_SEED/$platform"
    return 0
  fi
  echo "error: no captain seed for platform $platform" >&2
  echo "  add captain/$platform/ to your private agent-memory repo, or set FM_CAPTAIN_SEED_DIR" >&2
  exit 1
}

maybe_brew_install() {
  [ "$INSTALL_BREW" -eq 1 ] || return 0
  command -v brew >/dev/null 2>&1 || {
    echo "error: Homebrew not found; install from https://brew.sh" >&2
    exit 1
  }
  local pkg missing=""
  for pkg in wezterm tmux helix; do
    brew list "$pkg" >/dev/null 2>&1 || missing="$missing $pkg"
  done
  if [ -n "$missing" ]; then
    # shellcheck disable=SC2086
    brew install $missing
  else
    echo "unchanged: brew packages (wezterm tmux helix)"
  fi
}

PLATFORM=$(detect_platform)
SEED_DIR=$(resolve_captain_seed_dir "$PLATFORM")

maybe_brew_install

[ -f "$SEED_DIR/wezterm.lua" ] && install_file "$SEED_DIR/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
[ -f "$SEED_DIR/tmux.conf" ] && install_file "$SEED_DIR/tmux.conf" "$HOME/.tmux.conf"
if [ -f "$SEED_DIR/helix/config.toml" ]; then
  install_file "$SEED_DIR/helix/config.toml" "$HOME/.config/helix/config.toml"
fi

echo "done: captain stack for $PLATFORM"
echo "next: open WezTerm (or run: wezterm start --cwd ~/firstmate)" >&2
echo "      inside tmux session 'captain', launch your harness (claude, grok, codex, ...)" >&2
echo "      firstmate bootstrap: bin/fm-bootstrap.sh" >&2