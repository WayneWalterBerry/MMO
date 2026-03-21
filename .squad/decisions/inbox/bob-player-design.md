# Decision: Player Health & Injury System Design

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-23  
**Status:** PROPOSED  
**Scope:** Gameplay design — how health, injuries, and healing play from the player's perspective  
**Documents:** `docs/design/player/` (README.md, health-system.md, injury-catalog.md, healing-items.md)

---

## Decisions Proposed

### D-HEALTH-01: 100-Point Health Scale with 5 Narrative Tiers
Health is 100 HP max. Five tiers drive narrative output: Full (100), Scratched (75–99), Wounded (40–74), Critical (15–39), Near-Death (1–14). Players never see numbers by default — health is communicated through prose.

### D-HEALTH-02: Injuries as Independent Player-Attached FSMs
Each injury is an independent FSM (active → treated → healed) attached to the player. Multiple injuries can stack. Each has its own timers, HP drain, treatment requirements, and narrative messages. Follows the same FSM architecture used for objects.

### D-HEALTH-03: Treatment ≠ Healing (Two-Step Recovery)
Stopping an injury (bandage stops bleeding) is separate from restoring HP (potion restores HP). The player may need both. This creates a two-step recovery loop that adds strategic depth.

### D-HEALTH-04: Healing Items Use Standard Object Metadata
Healing properties declared on objects via `healing = {}` table — same pattern as `provides_tool`, `casts_light`. Engine reads metadata, no special-casing. Bandage: `stops_bleeding = true`. Potion: `hp_restore = 30`.

### D-HEALTH-05: GOAP Must Not Auto-Heal
GOAP may auto-resolve preparation chains (open kit → take bandage) but MUST NOT auto-apply treatment to the player. Treatment is always player-initiated. The healing decision is the puzzle.

### D-HEALTH-06: Instant Death Preserved for Extreme Hazards
Poison bottle and long falls bypass HP — remain instant death. These are player-initiated or clearly telegraphed. All other damage uses the HP system and is survivable with treatment.

### D-HEALTH-07: Level 1 Has Primitive Healing Only
No potions or medicine in Level 1. Healing comes from: cloth bandages (tear from blanket/cloak/curtains), wine (5 HP), water (5 HP, cleans wounds), rest/sleep. Teaches fundamentals before introducing powerful items in Level 2.

### D-HEALTH-08: Permadeath for V1, Checkpoints for V2
Death is currently final (restart the game). Matches existing `game_over` behavior. Checkpoint respawn will be implemented in V2 when save/load system exists.

---

## Rationale

The health system serves puzzles, not combat. Every mechanic creates at least one puzzle scenario. Injuries are constraints that shape what the player can do. Treatment items are keys that unlock recovery. The system extends existing mechanics (bleed_ticks, poison death, blood writing) rather than replacing them.

## Affected Systems

- **Game Loop:** New "injury tick" phase after timer tick, before game_over check
- **Player State:** New fields: `hp`, `max_hp`, `injuries`, `health_tier`
- **Verb Handlers:** Health-tier guards on strenuous actions. New verbs: `bandage`, `status`
- **Object Metadata:** New `healing = {}` table on medical/food objects
- **Display/Narrative:** Health-tier narrative messages appended to command output

## For Review By

- **Wayne:** Overall direction, permadeath vs. respawn, narrative tone
- **CBG:** Balance, pacing, integration with level design
- **Bart:** Engine feasibility — injury FSM, tick integration, verb guards
- **Flanders:** Object metadata patterns for healing items
