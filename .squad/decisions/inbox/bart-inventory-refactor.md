# Decision: Inventory Stores Object Instances (D-INV007)

**Author:** Bart (Lead Engineer)  
**Date:** 2026-07-22  
**Status:** Implemented  
**Triggered by:** Wayne Berry directives (copilot-directive-2026-03-21T19-17Z, copilot-directive-2026-03-21T19-19Z)

## Decision

`player.hands[i]` stores the **object instance table** (same reference as the registry entry), not a string ID. Each picked-up object receives a unique `instance_id`.

## Rationale

Wayne's directive: *"Inventory items are OBJECT INSTANCES, not object references/IDs. An object instance can be a modified version of its base object (e.g., a candle that's been lit has a different FSM state than the template candle)."*

Previously, `player.hands[1] = "candle"` (string) — the engine had to look up the registry on every read. Now, `player.hands[1]` IS the candle object with its current `_state`, properties, and `instance_id`.

## What Changed

- **Take handler:** Stores `obj` (table) instead of `obj.id` (string). Assigns `instance_id` on pickup.
- **Drop handler:** Reads object directly from hand. Puts `obj.id` back in `room.contents`.
- **Inventory display:** Reads `obj.name` directly from hand, no registry lookup needed.
- **All hand readers:** Updated to use `_hid(hand)` / `_hobj(hand, reg)` accessors that handle both object tables and legacy string IDs.

## Scope

| What | Storage format | Changed? |
|------|---------------|----------|
| `player.hands[i]` | Object instance (table) | ✅ Yes |
| `player.worn` | String IDs | No |
| `room.contents` | String IDs | No |
| `container.contents` | String IDs | No |
| Registry | Object tables (keyed by ID) | No |

## Test Results

126 tests pass (0 failures) across all test suites.

## Files Modified

- `src/engine/verbs/init.lua` — Core change + all hand accessors
- `src/engine/ui/presentation.lua` — `get_all_carried_ids`
- `src/engine/loop/init.lua` — Post-command tick phase
- `src/engine/parser/goal_planner.lua` — GOAP hand queries
- `src/main.lua` — Burnable tick handler
- `test/inventory/test-inventory.lua` — Assertions updated
