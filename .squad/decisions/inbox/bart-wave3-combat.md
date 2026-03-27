# D-WAVE3-COMBAT — WAVE-3 NPC Combat + Morale Decisions

**Author:** Bart (Architecture Lead)
**Date:** 2026-08
**Status:** Active

## Decisions

### D-ACTIVE-FIGHTS: Combat fight tracking lives on context

`context.active_fights` is the canonical location for active fight state. Each fight has `{ id, combatants, room_id, round }`. Combat module owns the lifecycle (start/end/join/remove). This keeps fight state accessible to both combat and creatures modules without circular deps.

**Affects:** Smithers (narration needs fight context), Nelson (test mocks must include active_fights).

### D-TURN-ORDER: Speed → Size → Player-last

Multi-combatant turn order: highest speed first, smallest size breaks ties, player always goes last among equals. This prevents the player from dominating initiative in 3+ creature fights.

**Affects:** All combat resolution paths. Tests use `math.randomseed(42)` for determinism.

### D-MORALE-DUAL-API: check_morale vs attempt_flee

Two public APIs for morale:
- `creatures.check_morale(creature)` — pure threshold check (no context), returns bool
- `creatures.attempt_flee(context, creature)` — full flee/cornered execution with movement

This split keeps the simple check testable without mocking context, while the full flee needs room exits and movement helpers.

**Affects:** Nelson (tests use both APIs), Smithers (narration from morale messages).

### D-FLEE-THRESHOLD-PATH: combat.behavior.flee_threshold is canonical

Health-based flee threshold reads from `creature.combat.behavior.flee_threshold` (decimal 0.0-1.0). Falls back to `creature.behavior.flee_threshold` (integer, auto-normalized to ratio). The `behavior.flee_threshold` integer is for fear-based scoring in `score_actions()`; the `combat.behavior.flee_threshold` decimal is for health-based morale.

**Affects:** Flanders (creature data files already have both), Nelson (tests validate decimal path).

### D-CORNERED-FLAG: _cornered is a runtime flag, not FSM state

`creature._cornered = true` is set when a creature has no valid exits and health < flee_threshold. It's a runtime flag that npc-behavior.lua checks for stance override (→ aggressive) and defense override (flee → counter). The `alive-cornered` FSM state is informational.

**Affects:** npc-behavior.lua reads `_cornered`, combat/init.lua passes `cornered_bonus` in opts.

### D-NAV-EXTRACTION: Navigation helpers in creatures/navigation.lua

Extracted exit resolution, BFS room distance, exit passability, and valid exit listing into `creatures/navigation.lua`. Uses `get_room_fn` parameter to avoid circular deps. Keeps creatures/init.lua under 500 LOC budget.

**Affects:** Any module needing creature navigation should require navigation.lua, not duplicate the logic.
