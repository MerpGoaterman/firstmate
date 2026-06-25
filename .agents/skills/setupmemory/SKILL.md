---
name: setupmemory
description: Bootstrap cross-harness agent memory on this machine. Use when the captain invokes /setupmemory (e.g. "/setupmemory", "set up agent memory", "wire up global memory", "bootstrap walrus on this machine"). Installs GLOBAL.md, harness links, Walrus skills, and memwal MCP config from firstmate seed.
user-invocable: true
---

# setupmemory

Bootstrap agent memory on the captain's machine.
This is the one-command path for a new Windows or Mac box: static instructions from firstmate seed, dynamic facts from Walrus after sign-in.

## What it does

Run:

```sh
bin/fm-setup-memory.sh
```

On Windows PowerShell (no bash in PATH):

```powershell
bin/fm-setup-memory.ps1
```

The script:

1. Installs `~/.agent/GLOBAL.md` from `seed/agent-memory/GLOBAL.md` (keeps an existing file unless `--force`).
2. Hardlinks (or symlinks) that file into Grok, Codex, and OpenCode harness homes.
3. Writes Claude's `~/.claude/CLAUDE.md` as an `@` import of the same file.
4. Copies `wremember` and `wrecall` skills into each harness skills dir.
5. Patches memwal MCP config for Grok, Codex, Claude, and OpenCode when missing.
6. Builds `~/.memwal/credentials.json` from 1Password when possible (skip with `--skip-creds`).

Idempotent: safe to re-run after `/updatefirstmate` pulls a newer seed.

## Flags

- `--force` - replace `GLOBAL.md` and conflicting harness links from seed.
- `--skip-creds` - skip 1Password / memwal credential bootstrap.

## After setup

Tell the captain plainly what landed.
If credentials were skipped, remind them to run `memwal_login` once in any harness, or to store Walrus keys in 1Password item `walrus memory` (Claude vault) and re-run without `--skip-creds`.

On a machine where recall returns nothing but facts were saved elsewhere, run `memwal_restore` for namespace `davec`, then `/wrecall`.