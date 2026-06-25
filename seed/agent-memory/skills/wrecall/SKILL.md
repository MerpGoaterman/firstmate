---
name: wrecall
description: Search Walrus Memory for relevant facts. Use when the user runs /wrecall or asks what you remember from Walrus or global memory.
argument-hint: optional search query
when-to-use: /wrecall, what do you remember, recall from walrus, search walrus memory
compatibility: Requires memwal MCP server
---

# Walrus Recall

Search Walrus Memory and summarize what is relevant.

## Steps

1. Build a query from the user's `/wrecall` argument, or from the current task if none was given.
2. Call `memwal_recall` with:
   - `query`: the search query
   - `namespace`: `davec`
   - `limit`: 10
3. If Walrus is not signed in, call `memwal_login` once, then retry `memwal_recall`.
4. Summarize matching memories grouped by relevance. If none match, say so.