# Decision: Phase 3 Implementation Plan

**Filed by:** Bart (Architecture Lead)
**Date:** 2026-08-16
**Status:** 📋 DRAFT — Awaiting team review + Wayne approval

---

## D-PHASE3-PLAN: Phase 3 NPC+Combat Implementation Plan Written

**Category:** Planning
**Affects:** All team members (Bart, Flanders, Smithers, Moe, Nelson, Brockman)

Phase 3 implementation plan written to `plans/npc-combat/npc-combat-implementation-phase3.md`. 6 waves, 5 gates, ~190 new tests estimated. Covers: death consequences (corpse mutation), creature inventory + loot drops, full food system + cook verb, combat polish + cure system, creature respawning.

**Needs:** Team review (all reviewers per implementation-plan skill Pattern 5) + Wayne approval on 6 Open Questions before execution begins.

---

## D-COMBAT-MODULE-SPLIT: Combat Module Exceeds 500 LOC Limit

**Category:** Architecture
**Severity:** Blocking (must resolve before Phase 3 WAVE-1)
**Affects:** Bart, Nelson

`src/engine/combat/init.lua` has grown to 695 LOC (39% over the 500 LOC guard from implementation-plan skill Pattern 13). Phase 3 WAVE-0 addresses this with a split:

- **Extract:** `src/engine/combat/resolution.lua` (~250 LOC) — `resolve_damage()`, `resolve_exchange()`, layer penetration, severity mapping
- **Retain:** `src/engine/combat/init.lua` (~445 LOC) — combat FSM orchestration, turn management, entry points

**Also flagged (not blocking but concerning):**
- `src/engine/verbs/crafting.lua`: 629 LOC (will grow to ~679 after cook verb addition)
- `src/engine/verbs/survival.lua`: 715 LOC (over limit, growing)
- `src/engine/combat/narration.lua`: 457 LOC (approaching limit)

These verb module sizes should be addressed in Phase 4 pre-flight or a dedicated cleanup wave.

---

## D-DEATH-MUTATION-OPT-IN: mutations.die is Backward-Compatible Opt-In

**Category:** Architecture
**Affects:** Flanders (creature files), Bart (engine)

The new creature death → corpse mutation path uses `mutations.die` metadata on creature `.lua` files. This is OPT-IN:
- Creatures WITH `mutations.die`: engine calls `mutation.mutate()` → replaces creature with corpse object
- Creatures WITHOUT `mutations.die`: existing FSM dead state behavior continues unchanged

No existing behavior changes. Backward-compatible by design.

---

## D-PHASE3-OPEN-QUESTIONS: 6 Questions for Wayne

**Category:** Planning
**Status:** Awaiting Wayne input

| # | Question | Recommendation |
|---|----------|---------------|
| Q1 | Corpse as container vs scatter to floor? | Corpse as container (Option B) |
| Q2 | Respawn: timer-based vs event-based? | Timer-based with player-not-in-room guard (Option A) |
| Q3 | Fire source location in Level 1 for cooking? | Cellar brazier (Option B) |
| Q4 | Dead wolf portable or furniture? | Furniture/not portable (Option B) |
| Q5 | Stress injury: 2-tier or 3-tier? | 2-tier minimal (Option A) |
| Q6 | Loot tables in Phase 3 or Phase 4? | Phase 4 — fixed inventory only in Phase 3 (Option A) |

See full analysis with trade-offs in `plans/npc-combat/npc-combat-implementation-phase3.md` Section 10.
