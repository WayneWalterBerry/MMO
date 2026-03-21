### 2026-03-21T19:35Z: User directive — Verb-dependent object search order
**By:** Wayne Berry (via Copilot)
**What:** The `find_visible` search order should be verb-dependent:
- **Interaction verbs** (use, light, drink, open, close, pour, eat): Check HANDS first, then bags, then room, then surfaces. The player is acting on something they hold.
- **Acquisition verbs** (take, examine, look, search, feel): Check ROOM first, then surfaces, then containers. The player is reaching for something in the world.
- This replaces the current fixed search order (room→surfaces→containers→hands→bags→worn).
**Why:** If a player is holding a candle and there's one on the table, "light candle" should target the held one. But "take candle" should target the table one. The search order must match the player's intent.
