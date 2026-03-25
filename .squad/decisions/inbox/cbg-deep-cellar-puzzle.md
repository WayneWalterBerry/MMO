# D-CHAIN-PUZZLE-DESIGN

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-07-23  
**Status:** Proposed  
**Issue:** #126

## Decision

The Deep Cellar chain mechanism (Puzzle 017) opens a hidden stone alcove in the west wall containing ceremonial incense sticks (×3) and beeswax altar candles (×2). This solves the "chain puzzle undefined" and "incense/candles missing" parts of Issue #126 in one design.

## Key Points

1. **Chain → Alcove:** Pulling the chain triggers a counterweight that slides open a concealed stone panel, revealing a wall alcove. One-way ratchet — cannot be undone.

2. **Incense gates Puzzle 012:** The incense burner's old ash is SPENT — not relightable. Fresh ceremonial incense from the alcove is required for the altar ritual. This makes the chain puzzle a prerequisite for the ritual path to the silver key.

3. **Two paths to silver key remain:**
   - Path A (Ritual): Chain → incense → altar ritual → key behind altar
   - Path B (Brute Force): Crowbar → open sarcophagus → key among bones

4. **Beeswax candles are multi-purpose:** Room lighting (sconces), ritual offering (bowl), personal light (backup). Player allocates 2 candles across these uses — inventory micro-management.

5. **New material: beeswax.** Beeswax altar candles introduce a new material (vs. existing tallow). Higher quality, cleaner burn, honey scent. Material properties needed in materials registry.

## Who Should Know

- **Bob (Puzzle):** Puzzle 012 gains a new prerequisite (chain provides incense). Update 012 doc to note this dependency.
- **Flanders (Objects):** 3 new object types needed: `incense-stick`, `altar-candle`, `stone-alcove`. Specs in puzzle doc.
- **Moe (Rooms):** `deep-cellar.lua` needs: (a) stone-alcove added to instances with `hidden = true`, (b) room-level `on_state_change` listener for chain → alcove reveal, (c) room `on_feel` updated to mention chain.
- **Bart (Engine):** Room-level `on_state_change` triggers may need engine support if not already implemented. The pattern: "when object X enters state Y, set object Z property to value."
- **Nelson (Tests):** Chain puzzle needs tests: pull chain → alcove revealed → items accessible. Integration test: chain → incense → ritual → key.
