# Flanders — Level 1 Object Build Decisions

**Author:** Flanders (Object Designer)
**Date:** 2026-07-21
**Context:** Built all 37 Level 1 .lua object files from specifications

---

## D-BUILD-L1-001: Objects Use Material Strings Not Yet in Registry

**Status:** Needs Coordination
**Affects:** 15 objects across all Level 1 rooms

The following material strings are referenced in new objects but do NOT exist in `src/engine/materials/init.lua`:
- `stone` (7 objects), `silver` (4 objects), `hemp` (1), `bone` (1), `burlap` (1), `tallow` (1)

**Decision needed from Bart/Frink:** Add these materials to the registry. Stone is critical — used by altar, sarcophagus, well, cobblestone, wall-inscription. Until added, `material` field lookups will fail.

---

## D-BUILD-L1-002: Sarcophagus Has Two Base Objects

**Status:** Implemented
**Affects:** Crypt + Deep Cellar

Two separate sarcophagus base objects exist:
- `stone-sarcophagus.lua` — Deep Cellar version (1 instance)
- `sarcophagus.lua` — Crypt version (5 instances via overrides)

Both share nearly identical FSM (closed → open, requires leverage). The crypt version has more generic descriptions suitable for instance overrides. This is intentional per the spec — the deep cellar one is a standalone discovery, the crypt ones are a puzzle set.

---

## D-BUILD-L1-003: Offering Bowl Guard is Placeholder

**Status:** Needs Bob/Wayne Decision
**Affects:** Puzzle 012 (Altar Puzzle)

The offering-bowl's `offering-placed` transition has no guard function on what constitutes a valid offering. The spec lists candidates: lit candle, wine/libation, player blood, or a coin. Bob needs to define the acceptable offering and add `offering_valid` to that item's categories.

---

## D-BUILD-L1-004: Locked Door Has No Unlock Transition

**Status:** Intentional (Level 1 boundary)
**Affects:** Hallway locked-door objects

The `locked-door.lua` has an empty transitions table. It's a permanent boundary in Level 1. In Level 2, the FSM should expand to `locked → unlocked → open` with appropriate key requirements. This is by design per the spec.

---

## D-BUILD-L1-005: Wooden Door Unlock Key is TBD

**Status:** Needs Wayne/Bob Decision
**Affects:** Courtyard wooden-door, Puzzle 013

The `wooden-door.lua` has an unlock transition but no `requires_key` guard. The spec says "TBD" for what key or mechanism unlocks it. Bob/Wayne need to define this before Puzzle 013 is playable.

---

## D-BUILD-L1-006: Rat Uses Auto-Trigger Conditions Not Yet in Engine

**Status:** Needs Bart Confirmation
**Affects:** rat.lua

The rat's transitions use conditions: `player_enters`, `loud_action_nearby`, `timer_expired`. The engine handles `timer_expired` (per candle pattern), but `player_enters` and `loud_action_nearby` may need new trigger hooks. Bart to confirm if these exist or need implementation.

---

## D-BUILD-L1-007: Instance Overrides Not Built as Separate Files

**Status:** Intentional — Moe's Responsibility
**Affects:** wine-bottle (oil variant), portrait (3 subjects), sarcophagus (5 instances)

The specs define instance overrides for several objects (oil wine-bottle, portrait subjects, sarcophagus contents). These are NOT separate .lua files — they're runtime instance overrides applied by the world builder (Moe) in room definition files. The base objects are built to support overrides via the states table structure.
