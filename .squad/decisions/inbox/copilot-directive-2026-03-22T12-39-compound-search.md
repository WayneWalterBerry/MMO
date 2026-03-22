### 2026-03-22T12:39: User directive — Compound search syntax patterns
**By:** Wayne (Effe) Berry (via Copilot)
**What:** These compound search phrases MUST all work:
1. "Search the nightstand for the matchbox" — scoped search with target
2. "Search the nightstand for matches" — scoped + fuzzy target (matchbox contains matches)
3. "Find the matchbox in the nightstand" — target + scope (reversed syntax)
4. "Search for a match, light it and light the candle" — search + chained commands via multi-command parser

Parser must handle:
- `search [scope] for [target]` — "search the nightstand for the matchbox"
- `find [target] in [scope]` — "find the matchbox in the nightstand"
- `search for [target]` — undirected room-wide search
- Chained: search result feeds into next command via context ("light it" = light the thing you just found)
- Fuzzy: "matches" should match "match" inside "matchbox" — the engine should search recursively into containers

**Why:** Natural language flexibility — players shouldn't need to know the exact object hierarchy
