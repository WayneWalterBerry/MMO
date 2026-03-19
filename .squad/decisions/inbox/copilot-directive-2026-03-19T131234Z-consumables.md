### 2026-03-19T131234Z: User directive — Consumables System
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Objects can be consumable — when consumed, they are REMOVED from the universe entirely:
- Candles burn down over time (consumed by burning)
- Food can be eaten (consumed by eating)
- Paper can be burned (consumed by fire)
- Matches are consumed when struck and burned out
- When consumed, the object is removed from the registry. It no longer exists. Gone.

This is different from mutation (object becomes something else) — consumption is DESTRUCTION. The object ceases to exist. No variant file, no replacement. Just gone.

**Engine implications:**
- Registry needs a `destroy(id)` or `remove(id)` method (already has `remove` — verify it works for this)
- Candles need a burn timer — after N turns of being lit, candle is consumed (dark again!)
- EAT verb needed (future)
- BURN verb needed (future — burn paper, burn cloth, etc.)
- Matches consumed after one use (strike → light something → match gone)

**Gameplay implications:**
- Candles are FINITE. You can't leave one burning forever. Resource management.
- Matches are one-use. 7 matches = 7 chances to light things.
- Food is survival. Eat it and it's gone.
- This creates urgency and scarcity — core to good puzzle design.

**Why:** User request — adds resource management and scarcity to the game. Objects are precious because they can be permanently lost.
