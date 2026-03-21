### 2026-07-22: Player architecture revision — Derived health, first-class inventory, injury-specific healing
**By:** Bart (Lead Engineer)
**Directive:** Wayne directive 2026-03-21T19:17Z

**What was decided:**

1. **Health is derived, not stored.** The `health` field has been removed from `player.lua`. Health is now computed on every read: `max_health - sum(injury.damage)`. This is a fundamental architectural shift — health is an emergent property of injuries, not a separate value to keep in sync.

2. **Inventory is first-class in player.lua.** Carried objects are stored as a nested array in `player.lua`. Containers hold items (bag contains bandage). The engine mutates this array directly on pickup/drop. No external inventory system. New file: `docs/architecture/player/inventory.md`.

3. **Healing is injury-specific.** Healing objects cure specific injury types by exact match. `antidote-nightshade` cures `poisoned-nightshade`, not `poisoned-spider-venom`. The relationship is encoded on both the healing object (`cures` field) and the injury definition (`healing_interactions`).

4. **player.lua is the single source of truth.** Injuries, inventory, effects, visited rooms — all in one file. The engine reads and mutates only this file.

**Files changed:**
- `docs/architecture/player/health.md` — Full rewrite (v1 → v2)
- `docs/architecture/player/injuries.md` — Full rewrite (v1 → v2)
- `docs/architecture/player/README.md` — Updated canonical structure, design philosophy
- `docs/architecture/player/inventory.md` — NEW file

**Decisions introduced/revised:**
- D-HEALTH001 (revised): Health is derived, not stored
- D-HEALTH002 (revised): No generic "heal N HP"
- D-HEALTH003 (new): Health computed on read
- D-HEALTH004 (new): Damage recorded on injury instances
- D-HEALTH005 (revised): Death at derived health ≤ 0
- D-INJURY003 (revised): Healing matches by EXACT injury type
- D-INJURY007 (new): Each injury carries .damage field
- D-INJURY008 (new): Dual-side healing validation
- D-INJURY009 (new): Injury types are specific, not generic
- D-INV001 through D-INV006 (new): First-class inventory architecture

**Impact on other systems:**
- **Engine loop** must compute derived health after injury ticking (no more `player.health -= damage`)
- **Object authors (Flanders)** use `cures = "injury-type"` instead of `heal = N` on healing objects
- **Injury definitions** use specific types (`poisoned-nightshade.lua` not `poisoned.lua`)
- **Status bar** calls `compute_health(player)` instead of reading `player.health`
- **Cloud persistence** no longer persists `health` — it's recomputed on load

**Why:** Wayne's directives establish that player.lua is the canonical mutable state, and that health/injuries/inventory are all data structures within it — not separate engine systems. Derived health eliminates sync bugs. Injury-specific healing creates puzzle depth.
