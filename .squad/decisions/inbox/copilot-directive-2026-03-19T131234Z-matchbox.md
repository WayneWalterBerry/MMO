### 2026-03-19T131234Z: User directive — Matchbox as Container (not separate empty file)
**By:** Wayne "Effe" Berry (via Copilot)
**What:** The matchbox should NOT have a matchbox.lua + matchbox-empty.lua pattern. The matchbox is a CONTAINER (like the sack) with a contents array listing what's inside it (individual matches). When all matches are used, the matchbox is just empty — same object, empty contents array. No separate "empty" variant file. This is different from the file-per-state decision for objects like candle/nightstand — the matchbox isn't changing STATE, it's just having items removed from it. It's a container, not a state machine.

**Clarification on file-per-state:** File-per-state is for objects that CHANGE WHAT THEY ARE (candle → candle-lit, nightstand → nightstand-open). Containers that just have stuff taken out of them don't need variant files — their contents array changes.

**Why:** User request — simplifies container objects. Aligns with containment model. The sack doesn't have a sack-empty.lua, so neither should the matchbox.
