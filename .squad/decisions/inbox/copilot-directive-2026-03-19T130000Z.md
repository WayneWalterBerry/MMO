### 2026-03-19T130000Z: User directive — Sensory Descriptions + Start Time + Poison
**By:** Wayne "Effe" Berry (via Copilot)

**Part 1 — Game Start Time:**
Don't start at dawn. Start BEFORE dawn (middle of the night — say 2 AM or 3 AM). The room is truly dark. Dawn comes later (6 AM = after ~3-4 minutes real time at 1hr=1day rate). The match/candle puzzle MATTERS because the player is in real darkness and dawn is NOT imminent. They NEED to light the candle to see. Dawn eventually rescues them if they can't solve it, but that's minutes of fumbling in the dark.

**Part 2 — Multi-Sensory Object Descriptions:**
Every object should have multiple sensory descriptions:
- `on_look` / `description` — what it looks like (requires light)
- `on_feel` — what it feels like by touch (works in dark!)
- `on_smell` — what it smells like (works in dark!)
- `on_taste` — what it tastes like (works always, but risky...)
- `on_listen` — what it sounds like (works in dark!)

This means in the dark, players can FEEL, SMELL, TASTE, and LISTEN to identify objects without seeing them. This is the core dark-room mechanic:
- FEEL nightstand → "Your hands find a smooth wooden surface with a small drawer."
- SMELL candle → "Waxy, slightly sweet. Definitely a candle."
- TASTE bottle → "BITTER! You spit it out. That tasted like poison." (consequences!)

**Part 3 — Poison Bottle:**
Add a bottle of poison on the nightstand. This creates a deadly puzzle in the dark:
- Player feels around → finds bottle on nightstand
- If they TASTE it in the dark (trying to identify it) → POISONED
- If they can see (have light) → LOOK at bottle reveals skull and crossbones label
- SMELL bottle → "Smells acrid and chemical. Something dangerous."
- This is a consequence-driven design: tasting unknown things in the dark can kill you

**Why:** User request — transforms the dark room from frustration into rich sensory gameplay. Every sense is a tool. Tasting is dangerous. The poison bottle is the first lethal puzzle.
