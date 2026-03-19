### 2026-03-19T125251Z: User directive — Matchbox/Match Interaction Rethink
**By:** Wayne "Effe" Berry (via Copilot)
**What:** The matchbox interaction needs to be richer and more realistic:
1. The matchbox is a CONTAINER that holds individual match objects (7 in this room, varies per matchbox)
2. The matchbox has a STRIKER on the side
3. To light a match, you STRIKE the match ON the matchbox — two objects are required
4. The lit match is then the fire_source tool you use to light the candle
5. This raises the question: is the match the tool? The matchbox? Both?

Wayne's answer (implied): BOTH are required for different steps:
- Matchbox = container + striker surface (not a tool itself, but a required surface)
- Match = the item that becomes a fire_source AFTER being struck on the matchbox
- Lit match = the actual fire_source tool (mutation: match → match-lit)
- Match-lit burns out after one use (consumed)

This creates a richer puzzle chain:
OPEN matchbox → TAKE match → STRIKE match ON matchbox → match-lit (fire_source) → LIGHT candle WITH match

This REPLACES the current "matchbox with charges" design. Individual matches as objects, not a counter.

**Why:** User request — design philosophy: realistic object interactions create better puzzles. Two-tool interactions add depth. Challenges the simple "charges" model.
