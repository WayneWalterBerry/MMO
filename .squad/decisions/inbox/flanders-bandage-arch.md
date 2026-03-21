# Decision: Bandage Object & Injury Targeting Architecture

**Author:** Flanders (Object & Injury Systems Engineer)  
**Date:** 2026-07-25  
**Status:** PROPOSED  
**Requested by:** Wayne Berry (copilot-directive-2026-03-21T20-05Z)

---

## Summary

Two deliverables implementing Wayne's treatment directives (Directives 1–5):

1. **Bandage `.lua` rewrite** (`src/meta/objects/bandage.lua`) — Full FSM treatment object with clean/applied/soiled states, reusable lifecycle, dual-bind to injury instances.
2. **Injury targeting architecture** (`docs/architecture/player/injury-targeting.md`) — Spec for "apply X to Y" resolution, dual binding, removal, and accumulative damage math.

---

## Decisions

### D-BANDAGE001: Bandage is a reusable FSM object, not consumable
**Decision:** Bandage has three states (clean → applied → soiled) and cycles back to clean via WASH. It is never consumed/destroyed.

**Rationale:** Wayne's Directive 4 explicitly states bandages are NOT consumable. They attach to one injury at a time and can be reused. This distinguishes bandages (reusable strategic resource) from salves (consumable one-shot). Creates resource management gameplay.

### D-BANDAGE002: `applied_to` field tracks injury attachment
**Decision:** The bandage instance carries `applied_to = injury.instance_id` when in "applied" state. This is nil in clean and soiled states.

**Rationale:** Wayne's Directive 5 — treatment items are object instances with state. The bandage's FSM must track which injury it's attached to. This is the object-side of the dual binding.

### D-BANDAGE003: `cures` is a table of injury type IDs
**Decision:** `cures = { "bleeding", "minor-cut" }` — the bandage declares which injury types it treats.

**Rationale:** Multi-cure objects use tables (established pattern from healing-poultice in injury-template-example.md). Bandages logically treat physical wounds that need compression/covering.

### D-TARGET001: Priority-ordered injury targeting resolution
**Decision:** When player says "apply bandage to X", the engine resolves X against injuries using: instance ID → display name → body location → injury type → ordinal index.

**Rationale:** Players will use natural language ("bleeding wound", "left arm", "first wound"). Priority order ensures the most specific match wins. Mirrors the object resolution pattern from inventory.md.

### D-TARGET002: Auto-targeting for single-injury cases
**Decision:** If player has only one treatable injury, bare "apply bandage" works without specifying target.

**Rationale:** Wayne's Directive 2 — same context-resolution pattern as objects. Reduces friction for the common case.

### D-TARGET003: Dual binding between treatment and injury
**Decision:** On apply: `bandage.applied_to = injury.id` AND `injury.treatment = { type, item_id, healing_boost }`. Both sides reference each other.

**Rationale:** Wayne's Directive 5 — the bandage's FSM knows which injury it's on, and the injury's FSM knows it has a bandage accelerating healing. Dual binding prevents orphaned references and lets the engine traverse either direction.

### D-TARGET004: healing_boost as timer multiplier
**Decision:** `healing_boost = 2` means the injury's heal timer counts down at 2× speed while bandaged.

**Rationale:** Clean separation of concerns — the bandage doesn't reduce damage, it accelerates healing. A 40-turn heal becomes 20 turns. The damage model stays untouched.

### D-TARGET005: Removal resumes injury drain
**Decision:** When a bandage is removed from an injury, the injury reverts to its state's defined `damage_per_tick`. If the wound was still in "treated" state, removing the bandage doesn't revert the state — but the treatment boost is lost.

**Rationale:** Creates consequences for premature removal. Players must weigh "do I move this bandage to the worse wound?" against "the first wound loses its healing boost."

### D-TARGET006: Drop blocked for applied treatments
**Decision:** The engine rejects DROP commands for items with `applied_to ~= nil`. Player must REMOVE first, then DROP.

**Rationale:** Prevents silently orphaning the injury-side treatment reference. Explicit is better than implicit.

---

## Files Changed

| File | Action | Description |
|---|---|---|
| `src/meta/objects/bandage.lua` | **Rewritten** | Full FSM with clean/applied/soiled states, cures, healing_boost, applied_to |
| `docs/architecture/player/injury-targeting.md` | **Created** | Targeting resolution, dual binding, removal, accumulation math |

## For Bart

The architecture doc (`injury-targeting.md`) contains complete function signatures, implementation pseudocode, and a data flow diagram. Key functions to implement:

- `injury_targeting.resolve()` — targeting resolution
- `injury_treatment.apply()` — dual bind
- `injury_treatment.remove()` — unbind + state transition
- `injury_system.tick_injury()` — per-tick with healing_boost
- `injury_system.compute_total_drain()` — accumulation sum

Verb handler changes needed for: `apply`, `remove`, `wash`, `drop` (block if applied).
