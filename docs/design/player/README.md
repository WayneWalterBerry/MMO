# Player Health & Injury System — Design Overview

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-23  
**Revised:** 2026-07-24 (Wayne directive 2026-03-21T19:17Z — derived health, injury-specific healing)  
**Status:** DESIGN  
**Audience:** All designers, Bart (engine), Flanders (objects), Nelson (testing)

---

## What This System Is

The Player Health & Injury system transforms the player from an invulnerable adventurer into a *fragile, mortal body navigating a dangerous world*. Health and injury give the player **stakes**. Every dark corridor, every unknown bottle, every sharp edge now carries weight.

**There is no health bar.** There is no HP number on screen. The player's "health" is the sum of their injuries — it is *derived*, not stored. A healthy player has no injuries. A dying player is a collection of untreated wounds, poisons, and bruises. The player experiences their condition through the `injuries` verb, which reads like a field medic's assessment of their own body.

**This is the puzzle:** every injury has a *specific* cure. A bandage stops bleeding but does nothing for poison. An antidote cures nightshade poisoning but not viper venom. The player must *examine their injuries*, *investigate available treatments*, and *match the right cure to the right wound*. That matching — that moment of "aha, THIS herb treats THAT bite" — is the core healing puzzle.

## Design Documents

| Document | What It Covers |
|----------|---------------|
| [health-system.md](./health-system.md) | Derived health model, the `injuries` verb, narrative voice at each severity level, death/game-over design, damage scenarios from Level 1 |
| [injury-catalog.md](./injury-catalog.md) | Catalog of injury types — each with cause, symptoms, SPECIFIC cure, discovery clues, and FSM states. This is the puzzle design surface. |
| [healing-items.md](./healing-items.md) | Healing objects — each lists EXACTLY which injuries it treats. No generic "heals X HP." Matching treatment to injury is the puzzle. |

## Core Design Principles

### 1. Health Is Derived from Injuries — Never Displayed
There is no HUD, no health bar, no number on screen. Health is not stored — it is the *aggregate of active injuries*. The player *experiences* their condition through narrative:
- With no injuries: silence. The body is invisible when it works.
- With minor injuries: occasional pain reminders. The body nags.
- With serious injuries: the prose shifts. Descriptions get desperate. The body intrudes on every action.
- Near death: the world narrows. Sensory descriptions fragment. The player is dying, and the text tells them so.

The `injuries` verb is how players check themselves — like `inventory` but for your body.

### 2. Injury-Specific Healing Is the Core Puzzle
Every injury has a *specific* cure. Not "use healing potion to restore HP" — but "apply this bandage to that bleeding gash" or "drink this nightshade antidote to neutralize that specific poison." The player must:
- **Identify** the injury (examine symptoms, use `injuries` verb)
- **Find** the correct treatment (explore, read clues, experiment)
- **Apply** the treatment (use the right verb with the right object)

Wrong treatment wastes the item. Generic treatments don't exist. This is the puzzle.

### 3. Treatment Is Interaction, Not Magic
Healing works through the same verb/object system as everything else. You don't "use healing potion" — you `drink antidote` and the FSM handles the transition. You `bandage arm` using the same tool-resolution the engine already supports. Healing is gameplay, not a menu.

### 4. Death Is Meaningful But Not Cruel
Death in a text adventure must teach, not punish. The player who drinks poison learns "investigate before consuming." The player who bleeds out learns "treat injuries promptly." Death is a **lesson with dramatic flair**, not a "gotcha."

### 5. The System Serves Puzzles
Health and injury exist to create puzzle opportunities. Every injury type should generate at least one interesting puzzle scenario — specifically, the puzzle of *discovering which treatment cures it*. If an injury doesn't create a treatment-matching puzzle, it's flavor. If it *blocks* puzzles, it's wrong.

### 6. Inventory Is Nested (Containers)
Players carry items, and items can contain items — a bag holds a pouch, the pouch holds a vial. This creates new puzzle possibilities: the antidote is INSIDE the locked medical kit, which is inside the satchel. The player must navigate the container hierarchy under injury time-pressure.

## How It Connects to Existing Systems

| Existing System | Connection |
|----------------|------------|
| **FSM Engine** | Injuries are FSM states on the player (active → treated → healed). Healing items trigger FSM transitions specific to the injury they cure. |
| **Verb Handlers** | `drink`, `eat`, `apply`, `bandage`, `injuries` — healing verbs route through existing dispatch. `cut self`, `prick self` already produce bleed_ticks. |
| **GOAP Planner** | GOAP can auto-resolve "apply bandage" chains (open medical kit → take bandage → apply). The *discovery* of which treatment matches which injury remains the puzzle. |
| **Sensory System** | Injury severity modifies sensory output. With serious injuries, `on_look` descriptions shorten. In the dark with an injury, `on_feel` reports pain instead of object textures. |
| **Blood Writing** | The existing prick/cut → bleed → write chain is the *first health mechanic already in the game*. This system formalizes and extends it. |
| **Poison Death** | The existing `on_taste_effect = "poison"` → `game_over` is the *first death mechanic*. This system makes death richer with injury-specific treatment. |
| **Nested Inventory** | Healing items can be inside containers. The antidote is in the locked box, in the bag. Time pressure from injuries makes container navigation urgent. |

## Open Questions for Wayne / CBG

1. **Permadeath vs. Respawn:** The current `game_over` is terminal. Do we want a checkpoint/respawn system, or is death always final?
2. **Injury stacking:** Multiple simultaneous injuries are designed (each is independent FSM). Confirmed?
3. **GOAP and healing:** Should GOAP auto-resolve "I need to bandage my wound" chains, or should treatment always be player-initiated discovery?

---

## See Also

- `docs/design/game-design-foundations.md` §4 — Player Model
- `docs/design/player-skills.md` §8 — Blood Writing Mechanic (existing injury/bleed chain)
- `docs/design/00-design-requirements.md` REQ-034 — Game Over on Poison
- `docs/design/fsm-object-lifecycle.md` — FSM patterns that injuries follow
- `docs/design/tool-objects.md` — injury_source capability on knife/pin
