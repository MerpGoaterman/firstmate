---
name: setupmemory
description: Bootstrap cross-harness agent memory on this machine. Use when the captain invokes /setupmemory (e.g. "/setupmemory", "set up agent memory", "wire up global memory", "bootstrap walrus on this machine"). Pulls GLOBAL.md from a private seed repo, installs harness links, Walrus skills, and memwal MCP config.
user-invocable: true
---

# setupmemory

Bootstrap agent memory on the captain's machine.
Static instructions come from a **private** `agent-memory` repo; dynamic facts come from Walrus after sign-in.
Public firstmate only ships the wiring script and generic skills.

## Prerequisite (once per machine)

```sh
mkdir -p ~/.config/firstmate
printf '%s\n' 'git@github.com:YOU/agent-memory.git' > ~/.config/firstmate/memory-seed-repo
```

## Run

```sh
bin/fm-setup-memory.sh
```

If zsh reports `permission denied`, either:

```sh
chmod +x bin/fm-setup-memory.sh
bin/fm-setup-memory.sh
```

or:

```sh
bash bin/fm-setup-memory.sh
```

Windows PowerShell:

```powershell
bin/fm-setup-memory.ps1
```

The script:

1. Pulls `GLOBAL.md` from the private memory-seed repo (config, env, or cache).
2. Installs `~/.agent/GLOBAL.md` (keeps existing unless `--force`).
3. Hardlinks (or symlinks) into Grok, Codex, and OpenCode harness homes.
4. Writes Claude's `~/.claude/CLAUDE.md` as an `@` import.
5. Copies `wremember` and `wrecall` skills from firstmate `seed/agent-memory/`.
6. Patches memwal MCP config when missing.
7. Builds `~/.memwal/credentials.json` from 1Password when possible.

## Flags

- `--force` - replace `GLOBAL.md` and conflicting harness links from private seed.
- `--skip-creds` - skip 1Password / memwal credential bootstrap.

## After setup

If credentials were skipped, remind the captain to run `memwal_login` once, or store Walrus keys in 1Password (`walrus memory`, Claude vault) and re-run.

If recall is empty on a new machine but facts exist elsewhere: `memwal_restore` (namespace from `GLOBAL.md`), then `/wrecall`.