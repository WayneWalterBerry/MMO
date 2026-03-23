# Puzzle 026: Poisoned Offering

**Status:** 🔴 Theorized  
**Difficulty:** ⭐⭐⭐⭐⭐ Level 5  
**Cruelty Rating:** Tough (resource consumption is permanent; moral consequence persists)  
**Author:** Sideshow Bob (Puzzle Master)  
**Last Updated:** 2026-07-28  
**Uses Effects Pipeline:** ✅ Yes — poison effect chain on NPC via offering consumption  
**New Objects Needed:** ✅ bread-loaf or food item (as poison vehicle), NPC/creature with eat behavior

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Altar room, guarded passage, creature's lair |
| **Objects Required** | poison-bottle (existing), wine-bottle or food (existing/new), offering-bowl (existing) |
| **Objects Created** | poisoned-wine or poisoned-food (composite), NPC state change on consumption |
| **Prerequisite Puzzles** | 002 Poison Bottle (teaches poison identification) |
| **GOAP Compatible?** | No — ethical reasoning and NPC manipulation are outside GOAP |
| **Multiple Solutions?** | 4 (poison, distraction, stealth, negotiation/puzzle) |
| **Estimated Time** | 15–30 min (first-time), 5–10 min (repeat) |

---

## Real-World Logic

**Premise:** Poisoning food or drink to eliminate a threat is as old as human conflict. The Borgias. Ancient siege warfare. Even fairy tales (Snow White's apple). It's effective, premeditated, and morally complex. The player has a poison bottle they've been warned about. They have a guardian blocking their path. The offering bowl sits on an altar. The pieces are all there.

**Why it's satisfying:** This isn't a clean puzzle with a clean solution. The player must make a *choice*. They have the knowledge (poison is deadly), the tool (poison bottle), and the opportunity (guardian eats offerings). But doing it means killing — deliberately, calculatedly. The game doesn't judge, but the game *remembers*. The satisfaction comes from the player confronting who they are willing to be.

**What makes it real:** People have actually done this throughout history. The moral weight is genuine. This is the darkest puzzle in the game — by design.

---

## Overview

A passage or chamber is guarded by a hostile entity (creature, corrupted guardian, feral animal) that the player cannot defeat in direct confrontation. The entity is aggressive — it attacks if the player enters its territory. But the entity also has a behavioral pattern: it eats food left on the altar/offering bowl in the room.

The player has encountered the poison bottle earlier (Puzzle 002). They know what it does — it kills. They can:
1. **Poison the offering** — pour poison on food/wine, leave it on the altar. Guardian eats it, dies. Path is clear.
2. **Distract the guardian** — use food without poison to lure it away, sneak past.
3. **Find another route** — bypass the guarded passage entirely (longer, harder path).
4. **Solve the guardian's puzzle** — some guardians can be reasoned with or appeased through non-violent means.

The puzzle is multi-solution by design. Poisoning is the *easiest* and *fastest* path. But it's also the most morally compromised.

---

## Solution Path

### Solution A: Poisoned Offering (Direct, Dark)
1. Player has poison-bottle (open or sealed)
2. Player has wine-bottle or food item
3. `POUR poison ON wine` — creates poisoned-wine (composite mutation)
4. `PUT poisoned-wine ON offering-bowl` — place the tainted offering
5. `HIDE` or `LEAVE room` and `WAIT`
6. **Guardian approaches offering, drinks/eats → poison effect fires → guardian dies/incapacitated**
7. `ENTER room` — guardian is down. Path is clear.
8. **Moral note:** The game narrates what happened without flinching. "The creature lies still. Its eyes are open, glassy. You did this."

### Solution B: Distraction (Non-Lethal, Moderate Difficulty)
1. Player has food item (un-poisoned)
2. `PUT food ON offering-bowl` or `THROW food` into adjacent room
3. Guardian follows food, leaving path temporarily open
4. `RUN through passage` while guardian is distracted
5. **Result:** Guardian alive but may pursue. Time-limited window.
6. **Risk:** If player is too slow, guardian returns and attacks

### Solution C: Alternate Route (Non-Confrontational, High Difficulty)
1. Player finds a hidden passage, ventilation shaft, or collapsed section
2. Requires solving another puzzle to open the alternate path
3. **Result:** Bypasses guardian entirely. No moral compromise.
4. **Cost:** More time, more resources, harder puzzles

### Solution D: Appeasement (Negotiation, Highest Difficulty)
1. Guardian is not mindless — it has a demand or desire
2. Player discovers (through lore, inscriptions, NPC dialogue) what the guardian wants
3. Provide the correct offering (not food — something symbolic: silver dagger returned, burial coins placed, ritual performed)
4. **Result:** Guardian stands down peacefully. Most satisfying narrative resolution.
5. **Cost:** Requires extensive exploration and lore discovery

---

## Failure Modes

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Drink the poisoned wine yourself | Player is poisoned (nightshade — lethal) | Find antidote (Puzzle 002 knowledge) |
| Put un-poisoned food; guardian eats it and wants more | Guardian satisfied temporarily but doesn't leave | Find more food or try different approach |
| Try to fight the guardian | Severe injury, likely death | Flee, heal, try non-combat approach |
| Poison the offering but guardian doesn't eat | Guardian ignores the offering (wrong food type?) | Observe guardian's preferences; try different bait |
| Use poison but bottle is already empty (drank or poured earlier) | No poison available — must use non-poison solution | Alternate solutions always available |
| Enter room too early after poisoning | Guardian is dying but still dangerous — lashes out | Wait longer; dying creature is unpredictable |

---

## What the Player Learns

1. **Moral choices exist** — the game presents genuinely uncomfortable options
2. **Multiple solution paths have different costs** — easy/dark vs. hard/clean
3. **Objects have emergent combinations** — poison + food = weapon
4. **NPC behavior is observable** — watching patterns reveals vulnerabilities
5. **The game remembers your choices** — moral consequences may surface later
6. **Puzzle 002 knowledge pays forward** — understanding poison mechanics enables new strategies
7. **"Easiest" is not always "best"** — efficiency vs. ethics

---

## Sensory Hints

| Sense | Hint | When |
|-------|------|------|
| **LOOK at guardian** | "A massive figure blocks the passage. Its eyes track your movement — hostile, hungry" | First encounter |
| **LOOK at offering-bowl** | "A stone bowl on the altar, stained with old food remnants. Someone — or something — has been eating from it" | Discovery of behavioral pattern |
| **SMELL offering-bowl** | "Rancid meat and old wine. The bowl has been used recently" | Confirms guardian eats offerings |
| **LISTEN** (hiding after placing offering) | "Heavy footsteps approach the altar. Snuffling. The sound of liquid being slurped" | Guardian consuming the offering |
| **LOOK at dead guardian** | "The creature lies on its side, mouth still wet. The offering bowl is empty. Its eyes are open but unseeing" | Aftermath — the game doesn't look away |
| **EXAMINE inscription near altar** | "These carvings show a figure offering something to a guardian-spirit. The offering is not food — it looks like a blade being returned" | Clue for Solution D (appeasement) |

---

## Prerequisite Chain

**Objects:** poison-bottle (✅), wine-bottle (✅), offering-bowl (✅), food item (❌ new — bread, meat, or fruit)  
**Verbs:** POUR ON (✅), PUT ON (✅), HIDE (❌ new), WAIT (needs time-passage mechanic)  
**Mechanics:** NPC behavior system (❌ new — guardian has eat/patrol patterns), NPC injury/death (❌ new — Effects Pipeline on NPC), moral tracking (❌ new — game remembers choice)  
**Puzzles:** 002 Poison Bottle (teaches poison identification and danger)

---

## Objects Required

| Object | Type | State(s) | Key Properties | Built? |
|--------|------|----------|----------------|--------|
| poison-bottle | consumable/weapon | sealed, open, empty | `effects_pipeline: true`, `injury_type: poisoned-nightshade` | ✅ |
| wine-bottle | consumable/vehicle | sealed, open, empty, poisoned | Needs new "poisoned" state via mutation | ✅ (needs state) |
| offering-bowl | container | empty, filled | `accepts_food: true`, `accepts_liquid: true` | ✅ |
| bread-loaf | consumable | whole, torn, poisoned | `is_food: true`, `absorbs_liquid: true` | ❌ New |
| guardian-creature | NPC | patrolling, eating, dying, dead | Behavior pattern: patrol → detect food → approach → eat | ❌ New (NPC system) |

---

## Design Rationale

**Why poison as a weapon?** The poison bottle is established as deadly in Puzzle 002. The player has *experienced* its effects (or at least its warnings). Using it offensively is a natural — but dark — extension. This is the payoff of teaching poison mechanics early.

**Why Level 5?** Four distinct solution paths. Moral weight. NPC behavior observation. Resource management (using poison means it's gone). Multi-room exploration for alternate routes. This puzzle has the highest skill ceiling in the game.

**Why the ethical dimension?** Games that present hard choices without judging the player create memorable experiences. The game shows the consequence ("Its eyes are open, glassy. You did this.") and lets the player sit with it. No lecture. No morality meter. Just consequence.

**Why multiple solutions?** The poison path is the "easy" answer. Players who feel uncomfortable with it SHOULD have alternatives. The game rewards both ruthless efficiency and moral determination, just at different costs.

---

## GOAP Analysis

GOAP cannot resolve this puzzle in any form. All four solutions require strategic reasoning, moral judgment, or behavioral observation — none of which GOAP models. The player must:

1. Observe the guardian's behavior pattern
2. Assess their inventory (do they have poison? food? the right symbolic offering?)
3. Choose a moral path
4. Execute a multi-step plan with timing

Entirely manual. This is the game's ultimate player-agency puzzle.

---

## Effects Pipeline Integration

**Poison effect on guardian (NPC consumes poisoned offering):**
```lua
-- Offering bowl triggers consumption event when guardian interacts
-- Poisoned wine/food carries the pipeline effect forward
effect = {
    type = "inflict_injury",
    injury_type = "poisoned-nightshade",
    source = "poisoned-wine",
    damage = 10,
    message = "The creature drinks deeply from the bowl. After a moment, it staggers. Its legs buckle.",
}
```

The same `poisoned-nightshade` injury type used on the player now fires on the NPC — consistent system, consistent consequences. The Effects Pipeline doesn't care about the target.

---

## Notes & Edge Cases

- **Poison scarcity:** There's only one poison bottle in the game (currently). Using it here means it's gone. This is the ultimate resource trade-off.
- **Moral tracking:** If implemented, the game could track that the player chose to poison. Future NPCs might comment on it. A mirror reflection might show something different.
- **NPC immunities (future):** Some creatures might be resistant to nightshade. Player learns that not all poisons work on all targets.
- **Wine vs. food as vehicle:** Both should work. Wine is quicker (pour poison in), food requires soaking or coating.
- **Player drinks their own poisoned creation:** Should absolutely be possible and lethal. The game is consistent.
- **Ethical dialogue (future):** If the game adds NPC companions, they might object to the poison plan.
- **No softlock:** Alternate solutions always available. Even if guardian can't be poisoned, it can be distracted, bypassed, or appeased.

---

## Status

🔴 Theorized — Awaiting Wayne's review. (Note: This is the most complex theorized puzzle — may need significant engine work for NPC behavior.)

**Owner:** Sideshow Bob  
**Next:** Wayne reviews ethical dimension → Bart designs NPC behavior system → Flanders builds food objects and guardian
