# Puzzle 016: Wine Drink

**Status:** 🔴 Theorized  
**Difficulty:** ⭐ Level 1 (Trivial)  
**Zarfian Cruelty:** Merciful (no failure state, purely optional)  
**Classification:** 🔴 Theorized  
**Pattern Type:** Discovery + Sensory Rewards (Safe Interaction)  
**Author:** Sideshow Bob  
**Last Updated:** 2026-07-22  
**Critical Path:** NO — entirely optional flavor interaction

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Storage Cellar |
| **Objects Required** | Wine bottle (existing, on wine rack) |
| **Objects Created** | None — wine bottle mutates from `open` → `empty` (FSM transition) |
| **Prerequisite Puzzles** | 006 (Iron Door Unlock — must reach Storage Cellar) |
| **Unlocks** | Nothing mechanically — teaches DRINK verb, contrasts with poison |
| **GOAP Compatible?** | Partial — GOAP can resolve "open bottle" but DRINK is a terminal action, not a tool chain |
| **Multiple Solutions?** | N/A — not a puzzle with a "solution," just an available interaction |
| **Estimated Time** | < 30 sec |

---

## Overview

Three wine bottles sit in the wine rack in the Storage Cellar. In Puzzle 010 (Light Upgrade), the player learns to distinguish bottles by SMELL — one contains lamp oil, the others contain wine (sour, spoiled, but wine). Currently, the wine bottles are pure flavor objects. This mini-puzzle makes one of them drinkable.

When the player opens a wine bottle and drinks from it, they get a mouthful of sour, old wine — unpleasant but harmless. The wine is bad but not dangerous. This is a deliberate contrast with the poison bottle in the Bedroom (Puzzle 002), where TASTE meant instant death. Here, DRINK means mild discomfort and a moment of dark humor. The player learns: not all liquids are lethal. DRINK is distinct from TASTE. Context matters — a wine bottle in a wine rack is exactly what it claims to be.

This interaction is entirely optional. The player can ignore the wine bottles completely (they're flavor props for Puzzle 010). But the player who decides to drink teaches themselves the DRINK verb through natural curiosity — precisely how Level 1's tutorial design works.

---

## Solution Path

### The Interaction: Open and Drink

1. **Examine wine rack** — Player sees bottles in the rack. Already explored during Puzzle 010 (oil discovery).
2. **TAKE wine bottle** — Player picks up a wine bottle from the rack.
3. **OPEN wine bottle** or **UNCORK wine bottle** — Player removes the wax-sealed cork. The bottle transitions from `sealed` → `open`. Message: "You peel away the crumbling wax seal and pull the cork free with a soft pop. A sharp, vinegary smell rises from the bottle."
4. **DRINK wine** or **DRINK from bottle** — The key interaction.
   - **Message:** "You raise the bottle and take a swig. The wine is sour and old — turned halfway to vinegar years ago. It's rough, harsh on the throat, and tastes of dust and neglect. But it's unmistakably wine, and it's unmistakably not poison. It warms your belly despite the cellar's chill. You've had worse."
   - **Effect:** Wine bottle transitions from `open` → `empty`. Player gains no mechanical benefit — this is a teaching moment, not a power-up.
5. **Optional follow-up: TASTE wine** — If the player uses TASTE instead of DRINK:
   - **Message:** "You wet your lips with the wine. Sour, acidic, old — but recognizably wine, not poison. A cautious sip. Your tongue puckers at the vinegar tang."
   - **Effect:** No state change (TASTE is investigation, not consumption). The bottle remains `open` with wine inside.
   - **Teaching moment:** TASTE investigates. DRINK consumes. Two different verbs, two different outcomes.

---

## The Poison Contrast (The Real Lesson)

This mini-puzzle exists because of Puzzle 002 (Poison Bottle). In the Bedroom, the player learned:

> **TASTE unknown liquid = DEATH.**

That lesson was important — it established consequences. But it may have created a lasting fear: *all liquids in this game are dangerous.* If Level 2 introduces potions, healing drinks, or water sources, a player conditioned by the poison bottle may refuse to drink anything.

Puzzle 016 corrects this overcorrection:

| Interaction | Puzzle 002 (Poison) | Puzzle 016 (Wine) |
|-------------|---------------------|-------------------|
| **Object** | Unlabeled bottle on nightstand | Wine bottle in wine rack |
| **Context clues** | Dark room, no label visible, chemical smell | Wine rack in cellar, vinegar smell, cork seal |
| **SMELL** | "Sharp, acrid chemical smell" (warning) | "Faintly vinegary" (unpleasant but identifiable) |
| **TASTE** | Instant death | Sour but safe (investigation, no consumption) |
| **DRINK** | Would also be death (if implemented) | Safe consumption, bottle empties |
| **Lesson** | Don't consume unknown substances | Context tells you what's safe — use your senses |

The combined lesson: **investigate before you consume, but don't be afraid of everything.** Wine smells like wine. Poison smells like chemicals. The player who uses SMELL first (as Puzzle 002 taught) can tell the difference. The senses are tools for risk assessment, not just puzzle-solving.

---

## What the Player Learns

1. **DRINK is a verb** — The engine supports DRINK (and aliases: quaff, sip). The player discovers this through natural curiosity, not forced tutorial.
2. **DRINK ≠ TASTE** — TASTE is sensory investigation (safe, non-consuming). DRINK is consumption (state-changing, bottle empties). The distinction matters for Level 2+ potion mechanics.
3. **Not all liquids are deadly** — After the poison bottle, the player may fear all drinkable objects. This interaction says: wine is wine. Context and sensory investigation reveal safety.
4. **Context clues signal safety** — A wine bottle in a wine rack, with a vinegar smell, sealed with a cork — every contextual clue says "this is wine." The player learns to read environmental context, not just object properties.
5. **The engine supports consumption** — Drinking empties the bottle. The contents are consumed. This prepares the player for potions, water, and other consumable liquids in later levels.

---

## Failure Modes & Consequences

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Player never drinks the wine | No consequence — misses a verb tutorial | Verb learned in Level 2 organically |
| Player drinks ALL three bottles | Three empty bottles, mild humor | "Your stomach protests the quantity, but you'll live." |
| Player tries to DRINK the oil bottle | Oil isn't drinkable — "You gag on the thick, acrid oil. That's fuel, not drink. You spit it out." | No lasting effect — flavor rejection |
| Player drinks wine in darkness | Works fine — DRINK doesn't require light | Same message, same effect |
| Player pours wine out instead of drinking | Bottle empties, wine on floor | Lost opportunity but no penalty |

### Failure Reversibility

**No failure is possible.** The wine is harmless. Drinking it has no negative consequence. Not drinking it has no impact on any puzzle. This is Zarfian Merciful in its purest form.

---

## Objects Required

### Existing Objects (Modifications Needed)

| Object | Current State | Change Needed |
|--------|---------------|---------------|
| **wine-bottle** | States: `sealed → open → empty`. Has `open` and `pour` transitions. No `drink` transition. | Add `drink` verb transition in `open` state. See spec below. |

### Wine Bottle FSM Addition (for Flanders)

Add the following transition to the wine-bottle's existing FSM:

```lua
-- New transition: DRINK from open wine bottle
{
    from = "open",
    to = "empty",
    verb = "drink",
    aliases = { "quaff", "sip", "swig" },
    message = "You raise the bottle and take a swig. The wine is sour and old — turned halfway to vinegar years ago. It's rough, harsh on the throat, and tastes of dust and neglect. But it's unmistakably wine, and it's unmistakably not poison. It warms your belly despite the cellar's chill. You've had worse.",
    mutate = {
        contains = nil,      -- bottle is now empty
        weight = 0.5         -- lighter without liquid
    }
}
```

Also add a TASTE interaction for the `open` state (sensory, non-consuming):

```lua
-- Sensory: TASTE open wine bottle (investigation, not consumption)
-- Add to the open state's sensory properties:
on_taste = "Sour, acidic, old — but recognizably wine, not poison. Your tongue puckers at the vinegar tang."
```

And a TASTE interaction for the `sealed` state:

```lua
-- Sensory: TASTE sealed wine bottle
on_taste = "You lick the wax seal. It tastes of dust, old wax, and nothing useful. You'd need to open it first."
```

### DRINK Rejection for Oil Bottle (for Flanders)

The oil bottle (from Puzzle 010) should reject DRINK attempts:

```lua
-- Oil bottle: DRINK rejection in open state
on_drink_reject = "You gag on the thick, acrid oil. That's lamp fuel, not drink. You spit it out, grimacing.",
-- No state change. Oil bottle remains open with oil inside.
```

### No Room Changes Needed (for Moe)

The wine bottles are already placed on the wine rack in the Storage Cellar. No room modifications required. The wine rack holds 3 wine bottles (wine-bottle-1, wine-bottle-2, wine-bottle-3). All three can be drinkable — they're all wine, just varying degrees of sour.

---

## Sensory Hints

| Sense | Clue | What It Reveals |
|-------|------|-----------------|
| **LOOK (wine rack)** | "Dusty bottles, labels peeling. They all look much the same." | Bottles exist, visual alone doesn't distinguish |
| **SMELL (wine bottle, sealed)** | "Faintly vinegary through the seal." | This is wine — recognizably not poison, not oil |
| **SMELL (wine bottle, open)** | "Sharp, vinegary. Old wine, long past its prime." | Confirmed wine — safe to drink, though unpleasant |
| **FEEL (wine bottle)** | "Cool glass, smooth and heavy. Wax seal at the neck. Liquid shifts inside." | Container with liquid — drinkable? |
| **TASTE (wine, open)** | "Sour, acidic, old — but recognizably wine." | Safe investigation — doesn't consume |
| **DRINK (wine, open)** | Full consumption message — bottle empties | DRINK is consumption, bottle state changes |

---

## Design Rationale

### Why Wine?

**It's already there.** The wine bottles exist in the Storage Cellar for Puzzle 010 (oil discovery). They're currently flavor props — you smell them to confirm they're NOT oil. Making them drinkable costs one FSM transition and adds a teaching moment. Minimal effort, meaningful coverage.

**Cultural literacy.** A wine bottle in a wine rack in a medieval cellar is one of the most self-explanatory objects possible. No player will wonder "what is this?" or "is this safe?" — the context screams "wine." Per Frink §4.1 [26]: real-world knowledge should transfer into the game. Everyone knows you can drink wine from a wine bottle.

**Narrative grounding.** The manor's cellar would absolutely contain wine. Medieval households stored wine, ale, and cider underground for temperature stability. The wine has gone sour because nobody's maintained the cellar in years — consistent with the abandoned-manor narrative. The sourness is authentic: wine left unsealed for decades turns to vinegar through acetic acid bacteria. Frink would approve.

### Why Not a Health Benefit?

CBG's gap analysis asked: "health benefit? courage? just flavor text?" The answer is flavor text only, for three reasons:

1. **No health system exists yet.** Adding a health benefit implies a health/stamina system that doesn't exist in the engine. That's scope creep.
2. **The teaching is the DRINK verb, not a reward system.** The purpose is "DRINK exists and is distinct from TASTE." A reward would distract from the lesson.
3. **Consistency with Puzzle 002.** The poison bottle teaches "TASTE = death" with no gradation — no partial damage, no "you feel sick." The wine should be equally binary: DRINK = safe, bottle empties. Clean lesson.

**Future hook:** If Level 2 introduces a health/stamina system, the wine interaction can be retroactively enhanced with a small warmth bonus ("you feel slightly warmer"). For now, flavor text is sufficient.

### Why Three Drinkable Bottles?

All three wine bottles on the rack should support DRINK. Reasons:

1. **Consistency.** If one wine bottle is drinkable and two aren't, the player gets confused about WHY.
2. **Humor potential.** Drinking all three yields a mild humor response: "Your stomach protests the quantity, but you'll live."
3. **Resource for Level 2.** Empty wine bottles could be useful later (fill with water, use as container, throw as distraction). Three empties = three future resources.

### Per-Bottle Flavor Variation

To reward thorough exploration, each bottle can have a slightly different DRINK message:

- **Bottle 1:** "Sour and old — turned halfway to vinegar years ago. Rough, harsh on the throat. But it warms your belly. You've had worse."
- **Bottle 2:** "Thinner than the first. More vinegar than wine. Barely drinkable, but drinkable."
- **Bottle 3:** "The last bottle is the worst of the three — practically pure vinegar. You grimace and lower the bottle. Even you have standards."

These are instance overrides on the same base object — per-bottle `on_drink` messages. Follows Principle 5 (multiple instances, same base, independent state).

---

## GOAP Analysis

### What GOAP Resolves
- "OPEN wine bottle" → standard container open (uncork)
- "TAKE wine bottle" → standard take action

### What GOAP Cannot Resolve (The Interaction)
- Deciding to DRINK is a player choice, not a GOAP-planned action. GOAP doesn't plan consumption — it plans tool chains. Drinking wine solves no prerequisite; it's pure exploration behavior.

### GOAP Interaction
GOAP is irrelevant. DRINK is a terminal action (consumes contents, no downstream tool benefit). This is correct — the "puzzle" is the player's curiosity, not a mechanical gate.

---

## Related Puzzles

- **Contrasts with:** Puzzle 002 (Poison Bottle) — death vs. safety, TASTE vs. DRINK
- **Builds on:** Puzzle 010 (Light Upgrade) — same room, same wine rack, player already explored these bottles by SMELL
- **Teaches toward:** Level 2 potion/water mechanics — DRINK as a verb with effects
- **Same object set:** Wine bottles are multi-use: Puzzle 010 (smell to distinguish from oil) + Puzzle 016 (drink to learn the verb)

---

## Handoff Notes

### For Flanders (Object Designer)
Add a `drink` verb transition to wine-bottle.lua in the `open` state. Transition: `open → empty`, with message and mutate (contains = nil, weight reduced). Also add `on_taste` sensory properties for `sealed` and `open` states. Optionally: per-instance `on_drink` overrides for the 3 bottles in storage-cellar to vary the flavor text. Additionally: add a DRINK rejection response to oil-bottle.lua so the player gets useful feedback if they try to drink lamp oil.

### For Moe (World Builder)
No room changes needed. Wine bottles are already on the wine rack in storage-cellar. If per-bottle flavor variation is desired, add `overrides` to each wine-bottle instance in the room's `instances` array with unique `on_drink` messages.

### For Nelson (Tester)
Test: DRINK sealed bottle (should fail — need to open first). DRINK open bottle (should succeed — message + empty). TASTE open bottle (should give sensory message, NOT consume). DRINK empty bottle (should fail — "The bottle is empty."). DRINK oil bottle (should reject with specific message). Verify SMELL still distinguishes oil from wine after DRINK is added.

---

*"The poison bottle teaches fear. The wine bottle teaches discrimination. Together, they teach the player that this game respects their intelligence — investigate, assess, then act. That's not just a tutorial. That's a philosophy." — Sideshow Bob*
