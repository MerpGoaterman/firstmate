# Agent memory seed (public machinery only)

Personal `GLOBAL.md` does **not** live here.
Keep it in a **private** git repo and point firstmate at it.

## Split

| What | Where |
| --- | --- |
| `GLOBAL.md` (personal) | Private repo, e.g. `agent-memory` |
| Walrus facts | Walrus namespace (encrypted cloud) |
| Setup script, skills, MCP patchers | `firstmate/seed/agent-memory/` (public) |

## Configure your private seed

```sh
mkdir -p ~/.config/firstmate
printf '%s\n' 'git@github.com:YOU/agent-memory.git' > ~/.config/firstmate/memory-seed-repo
```

Or set `FM_MEMORY_SEED_REPO` / `FM_MEMORY_SEED_DIR` for one-off runs.

Copy `GLOBAL.md.example` to your private repo as `GLOBAL.md` and customize.

## Bootstrap

```sh
bin/fm-setup-memory.sh
```