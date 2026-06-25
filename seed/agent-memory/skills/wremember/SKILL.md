---
name: wremember
description: Save a fact to Walrus Memory (cross-agent). Use when the user runs /wremember or asks to remember/save something to Walrus or global memory.
argument-hint: fact to save
when-to-use: /wremember, remember in walrus, save to walrus, global memory
compatibility: Requires memwal MCP server
---

# Walrus Remember

Save the user's fact to Walrus Memory so all agents can recall it later.

## Steps

1. If no text was provided after `/wremember`, ask the user what to save.
2. Call `memwal_remember` with:
   - `text`: the full fact exactly as the user stated it — never summarize or shorten
   - `namespace`: `davec`
3. If Walrus is not signed in, call `memwal_login` once, then retry `memwal_remember`.
4. Confirm briefly: "Saved to Walrus (namespace: davec)."