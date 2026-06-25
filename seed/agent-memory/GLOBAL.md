# Global Agent Instructions
Grok · Codex · Claude Code · OpenCode

## Code Search
Zoekt first: http://100.106.248.97:6070. Local search only if Zoekt fails. Pull before work, push after.

## Memory (Walrus)
Namespace `davec`. Only memory store — no Grok native memory.
Save: `/wremember` · Recall: `/wrecall`. Recall first turn if helpful; full-text remember on ask; durable prefs only.

## Tool Preference (AXI first)
When a task touches an external service, check for an **AXI** (Agent eXperience Interface) before MCP or raw CLI.

**Priority:** AXI > MCP > raw CLI. Fall back only when no AXI covers the domain or the AXI is unavailable.

Catalog: https://axi.md

| AXI | Domain | Notes |
| --- | --- | --- |
| `gh-axi` | GitHub | Issues, PRs, workflow runs, releases. Wraps `gh`. |
| `chrome-devtools-axi` | Browser automation | Navigate, click, fill, extract. Wraps chrome-devtools-mcp. |
| `lavish-axi` | Human review | Agent HTML artifacts into collaborative review surfaces. |
| `npm-axi` | npm | Search/inspect registry packages, versions, deps, README previews. |
| `sqlite-axi` | SQLite | Schema introspection, row samples, capped read-only queries. |
| `slack-axi` | Slack | Read, search, sweep, safely draft messages. |
| `gws-axi` | Google Workspace | Gmail, Calendar, Docs, Drive, Slides. Drafts mail, never sends. |
| `harvest-axi` | Time tracking | Review, log, edit Harvest time entries. |
| `specops` | Spec-driven dev | Spec-driven development; AXI embedded in a skill. |
| `gitsheets-axi` | Git-backed data | Read/mutate git-backed record sheets; idempotent commits. |
| `metabase-axi` | Analytics / BI | SQL/MBQL, saved questions, schema introspection, export. |
| `otter-axi` | Meetings | Find and pull Otter.ai meeting transcripts. |

Run the AXI with no args first for live state and contextual next-step hints.

## Lavish (HTML review)
Use `lavish-axi` for plans, comparisons, diagrams, tables, reports, or anything easier to review visually than prose. Repo: https://github.com/kunchenguid/lavish-axi

**Workflow:**
1. Write HTML to `.lavish/<name>.html` (or user-specified path).
2. `lavish-axi <html-file>` - open browser review session.
3. `lavish-axi poll <html-file>` - long-poll for annotations and feedback (leave running; re-run if interrupted).
4. Fix `layout_warnings` before involving the human.
5. `lavish-axi poll <html-file> --agent-reply "..."` - reply in browser and continue.
6. `lavish-axi end <html-file>` - finish review.

**Before writing HTML:** run matching playbooks (`lavish-axi playbook <id>`): `diagram`, `table`, `comparison`, `plan`, `code`, `input`, `slides`. Run `lavish-axi design` for Tailwind/DaisyUI CDN fallback.

Skill installed globally (`/lavish` in Claude Code). Session hooks active for Claude Code, Codex, and OpenCode.

## Engineering
- Tech decisions: favor quality, simplicity, robustness, scalability, maintainability over development cost.
- Bug fixes: reproduce E2E as an end user would first; fix the real problem, not a symptom.
- E2E/UI: be picky and pixel-perfect; fix anything that looks off, even if unrelated to the task.
- Lint, test failures, flakiness: fix on sight, even if not caused by your current work.
- Never use the em dash (—). Use a plain hyphen (-) instead.
- Commits: never add your agent name as co-author.