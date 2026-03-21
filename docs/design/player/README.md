# Player Health & Injury System — Design Overview

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-23  
**Status:** DESIGN  
**Audience:** All designers, Bart (engine), Flanders (objects), Nelson (testing)

---

## What This System Is

The Player Health & Injury system transforms the player from an invulnerable adventurer into a *fragile, mortal body navigating a dangerous world*. Currently, the player exists as a skill-holder and item-carrier; health and injury give them **stakes**. Every dark corridor, every unknown bottle, every sharp edge now carries weight.

This is not an action RPG health bar. This is a **text adventure survival system** — health is communicated through *narrative*, injuries create *puzzle constraints*, and healing items become *strategic resources*. The player doesn't watch a number tick down; they feel their character deteriorating through increasingly desperate prose.

## Design Documents

| Document | What It Covers |
|----------|---------------|
| [health-system.md](./health-system.md) | Health scale, damage model, narrative voice at each health tier, death/game-over design, damage scenarios from Level 1 |
| [injury-catalog.md](./injury-catalog.md) | Catalog of injury types — each with cause, symptoms, treatment, FSM states. Level 1 injuries implemented first. |
| [healing-items.md](./healing-items.md) | Healing objects — bandages, potions, medicine, food. Design guidelines for how healing interacts with puzzles. |

## Core Design Principles

### 1. Health Is Felt, Not Displayed
There is no HUD, no health bar, no number on screen. The player *experiences* their health through text:
- At full health: silence. No messages. The body is invisible when it works.
- At low health: the prose shifts. Descriptions get shorter, more desperate. The player's body intrudes on every action.
- At critical health: the world narrows. Sensory descriptions fade. The player is dying, and the text tells them so.

### 2. Injuries Are Puzzle States
Every injury is a constraint that shapes what the player can do. A bleeding wound creates time pressure ("find a bandage before you bleed out"). A broken arm blocks physical actions ("too weak to climb"). Poison demands specific treatment ("find the antidote"). Injuries are not just damage — they are **puzzle gates**.

### 3. Treatment Is Interaction, Not Magic
Healing items work through the same verb/object system as everything else. You don't "use healing potion" — you `drink potion` and the FSM handles the effect. You `apply bandage to wound` using the same tool-resolution the engine already supports. Healing is gameplay, not a menu.

### 4. Death Is Meaningful But Not Cruel
Death in a text adventure must teach, not punish. The player who drinks poison learns "investigate before consuming." The player who bleeds out learns "treat injuries promptly." Death is a **lesson with dramatic flair**, not a "gotcha." Recovery mechanisms exist to prevent frustration while preserving stakes.

### 5. The System Serves Puzzles
Health and injury exist to create puzzle opportunities. Every mechanic in this system should generate at least one interesting puzzle scenario. If a mechanic doesn't create a puzzle, it's flavor — nice but not essential. If it *blocks* puzzles, it's wrong.

## How It Connects to Existing Systems

| Existing System | Connection |
|----------------|------------|
| **FSM Engine** | Injuries are FSM states on the player (active → treated → healed). Healing items trigger FSM transitions. |
| **Verb Handlers** | `drink`, `eat`, `apply`, `bandage` — healing verbs route through existing dispatch. `cut self`, `prick self` already produce bleed_ticks. |
| **GOAP Planner** | GOAP can auto-resolve "apply bandage" chains (open medical kit → take bandage → apply). The *discovery* of needing treatment remains the puzzle. |
| **Object Metadata** | Healing properties declared on objects: `heals = 20`, `cures_injury = "poison"`, `stops_bleeding = true`. Zero engine special-casing. |
| **Sensory System** | Health state modifies sensory output. At critical health, `on_look` descriptions shorten. In the dark with an injury, `on_feel` reports pain instead of object textures. |
| **Blood Writing** | The existing prick/cut → bleed → write chain is the *first health mechanic already in the game*. This system formalizes and extends it. |
| **Poison Death** | The existing `on_taste_effect = "poison"` → `game_over` is the *first death mechanic*. This system makes death richer and more recoverable. |

## Implementation Priority

| Phase | What | Why |
|-------|------|-----|
| **Phase 1** | Health points (HP), basic damage, health-tier narrative | Foundation — everything else depends on this |
| **Phase 2** | One-time injuries (cut, bruise) with treatment | Extends existing bleed_ticks into full injury FSM |
| **Phase 3** | Over-time injuries (bleeding, poisoning) | Creates time-pressure puzzles |
| **Phase 4** | Healing items (bandage, potion, antidote) | Completes the damage → treatment → recovery loop |
| **Phase 5** | Degenerative injuries (infection) | Advanced puzzle mechanics for Level 2+ |

## Open Questions for Wayne / CBG

1. **Permadeath vs. Respawn:** The current `game_over` is terminal. Do we want a checkpoint/respawn system, or is death always final (restart from beginning)?
2. **Health visibility:** Should the player ever see their actual HP number (via a `status` command), or is narrative-only the rule?
3. **Injury stacking:** Can the player have multiple simultaneous injuries? (Design says yes — each is independent FSM — but this needs engine confirmation.)
4. **GOAP and healing:** Should GOAP auto-resolve "I need to bandage my wound" chains, or should treatment always be player-initiated?

---

## See Also

- `docs/design/game-design-foundations.md` §4 — Player Model (stats, HP, death)
- `docs/design/player-skills.md` §8 — Blood Writing Mechanic (existing injury/bleed chain)
- `docs/design/00-design-requirements.md` REQ-034 — Game Over on Poison
- `docs/design/fsm-object-lifecycle.md` — FSM patterns that injuries will follow
- `docs/design/tool-objects.md` — injury_source capability on knife/pin
