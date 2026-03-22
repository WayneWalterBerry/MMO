### 2026-03-22T12:25: User directive — Search/Find is a progressive traverse
**By:** Wayne (Effe) Berry (via Copilot)
**What:**
- Search is NOT instant — it's a progressive TRAVERSE of the room
- Engine walks through objects near→far, narrating as it goes
- Auto-opens containers that can be opened during search
- Narrative output: "You feel a nightstand, it has a drawer... you open it... you find inside... you have found a matchbox."
- Does NOT go into full description of each item — just mentions them in passing
- Starts closest to player, expands outward (proximity-based)
- Goal-oriented search: "Find something that can light the candle" — GOAP-driven
- Stops when target is found (or room exhausted)
- Syntax: "Find matchbox", "Search for matchbox", "Find something that can light the candle", "Search the room"
**Why:** Core gameplay mechanic — search should feel like physically exploring, not a database query
