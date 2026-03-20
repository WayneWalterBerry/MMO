# Decision: Composite Object Implementation Patterns

**Author:** Bart (Architect)  
**Date:** 2026-03-25  
**Status:** Implemented  
**Affects:** Object architecture, verb dispatch, hand/carry system

## Decisions Made

### 1. Direct State Application for Part Transitions
Detach/reattach transitions bypass `fsm.transition()` and apply state directly. Reason: FSM's `transition()` finds the first from→to match, which is ambiguous when multiple transitions share the same from/to states (e.g., both "open" and "detach_part" go from sealed→open on the bottle). The detach helpers know exactly which transition they want, so they apply state properties directly.

### 2. Factory GUIDs Use math.random
Factory functions in object files run inside the sandbox (no `os` access). GUIDs for instantiated parts use `math.random(100000, 999999)`. Sufficient for single-player; multiverse will need proper UUID generation at the engine level.

### 3. Search Priority: Real Objects > Parts
`find_visible` returns real objects (room, surface, hand) before parts. This means a detached drawer on the floor takes priority over the nightstand's drawer part definition. This prevents stale part descriptions from masking the actual independent object.

### 4. Two-Handed Items Occupy Both Hand Slots
A two-handed item sets both `ctx.player.hands[1]` and `[2]` to the same object ID. DROP and PUT clear both. This is simpler than a separate tracking field and naturally blocks all single-hand operations.

### 5. Reattachment Via PUT Verb
Reattachment uses the existing PUT verb handler. When `item.reattach_to == target.id`, the handler delegates to `reattach_part()` instead of containment logic. No new verb needed.

## Team Impact
- **Content creators:** Composite objects define `parts = {}` table. Each detachable part needs a `factory` function, `detach_verbs` list, and appropriate FSM states on the parent.
- **QA:** Test `pull drawer` only after `open drawer`. Test `uncork bottle` directly. Test two-handed carry blocks with full hands.
- **Game designer:** Reversibility is per-part (`reversible = true/false`). Cork is irreversible. Drawer is reversible.
