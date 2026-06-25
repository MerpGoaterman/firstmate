---
name: setupcaptain
description: Bootstrap WezTerm, tmux, and Helix for the captain agent workflow. Use when the captain invokes /setupcaptain or asks to set up wezterm, tmux, helix, or the terminal ship for firstmate.
user-invocable: true
---

# setupcaptain

Wire the captain terminal stack: WezTerm opens into tmux session `captain` at `~/firstmate`, Helix is the default editor.

## Prerequisite

Private `agent-memory` repo should include `captain/mac/` (or `captain/linux/`). Same repo as `GLOBAL.md`.

Pull latest private seed first if you just added captain configs:

```sh
git -C ~/.cache/firstmate/memory-seed pull --ff-only
```

## Run

```sh
bin/fm-setup-captain.sh --install-brew
```

`--install-brew` installs wezterm, tmux, and helix via Homebrew on Mac (only when captain approved).

## After setup

1. Open WezTerm (or `wezterm start`).
2. You should land in tmux session `captain` inside `~/firstmate`.
3. Launch your harness (`claude`, `grok`, etc.).
4. Run `bin/fm-bootstrap.sh` on first firstmate session to detect gh, treehouse, no-mistakes, AXIs.

Crewmates spawn as `fm-*` tmux windows in the same session.