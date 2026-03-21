# Puzzle 012: The Altar Puzzle (Optional)

**Status:** 🔴 Theorized  
**Difficulty:** ⭐⭐⭐ Level 3 (Intermediate)  
**Zarfian Cruelty:** Polite (clear clues available, failure is recoverable)  
**Classification:** 🔴 Theorized  
**Pattern Type:** Environmental Interaction + Deduction (Pattern Recognition) + Sequence  
**Author:** Sideshow Bob  
**Last Updated:** 2026-07-22  
**Critical Path:** NO — optional, unlocks Crypt (bonus content)

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Deep Cellar |
| **Objects Required** | Stone altar, offering bowl, tattered scroll (clue text), candle/fire source, incense burner, silver key (reward) |
| **Objects Created** | None (silver key revealed from hidden compartment) |
| **Prerequisite Puzzles** | 009 (must enter Deep Cellar) |
| **Unlocks** | Crypt (west archway — stone door opens) |
| **GOAP Compatible?** | No — GOAP cannot resolve symbolic/ritualistic actions; this is a pure knowledge gate |
| **Multiple Solutions?** | 1 primary (complete the offering ritual); 1 partial (find silver key without ritual via exhaustive search) |
| **Estimated Time** | 5–12 min (includes reading scroll, experimenting) |

---

## Overview

The Deep Cellar is dominated by a stone altar that predates the manor above. On the altar sits an offering bowl (empty), an incense burner (cold, filled with old ash), and a tattered scroll. The scroll, when read, describes an ancient rite: "Light the incense. Make an offering of flame. The sleepers grant passage to those who honor the old ways."

The puzzle requires the player to perform a simple ritual: relight the incense burner using their fire source, then place a lit candle (or other flame) in the offering bowl. When both conditions are met — incense burning AND flame offered — a hidden mechanism activates: a stone panel behind the altar slides aside, revealing a silver key that unlocks the crypt archway to the west.

This is the first puzzle in Level 1 that requires the player to *interpret* written text and *perform a symbolic action* based on their interpretation. It's not a lock-and-key or a container puzzle — it's an environmental interaction puzzle grounded in environmental storytelling. The scroll IS the clue. The player must read it, understand it, and act on it.

This design embodies Frink's key finding (§6.2): "GOAP makes simple inventory chains obsolete. Knowledge gates become primary." The player has all the tools they need (fire source in hand). The gate is *understanding what to do with them*.

---

## Solution Path

### Primary Solution: Complete the Ancient Rite

1. **Explore the Deep Cellar** — Player examines the altar and its objects. LOOK: "A stone altar dominates the center of the chamber, carved from a single block of grey granite. Symbols are chiseled into its surface — spirals, crossed lines, a crescent moon. Upon it: a blackened incense burner filled with ash, an empty stone bowl, and a tattered scroll."
2. **READ scroll** — "The parchment is brittle and yellowed. You carefully unroll it. The handwriting is cramped and archaic but legible: *'Light the incense of remembrance. Offer flame to the sleepers. Those who honor the old ways shall find the path unsealed.'*"
   - This is the puzzle clue. "Light the incense" = relight the incense burner. "Offer flame" = place a burning object in the offering bowl. "Path unsealed" = the crypt door opens.
3. **EXAMINE incense burner** — "A heavy bronze burner, blackened with centuries of use. Cold ash fills its bowl. A few fragments of unburned incense resin cling to the sides." SMELL: "Faint traces of sandalwood and myrrh — ghosts of old prayers."
   - The presence of unburned incense resin means it CAN be relit.
4. **LIGHT incense burner** or **LIGHT incense WITH candle** — Player applies fire to the incense remnants. Message: "You hold the candle flame to the old resin. It catches slowly, then begins to smolder. A thin thread of fragrant smoke rises — sandalwood and myrrh, ancient and solemn."
   - Incense burner transitions from `cold` → `smoldering` state. `on_smell` changes to active fragrance.
5. **EXAMINE offering bowl** — "A shallow stone bowl, worn smooth. Empty. It looks like it's meant to hold something." FEEL: "Cold stone, smooth interior. A slight depression in the center, like a candleholder."
   - The "depression like a candleholder" is a hint about WHAT to offer.
6. **PUT candle IN bowl** or **PLACE candle IN offering bowl** — Player places their lit candle (or candle-holder) in the offering bowl. Message: "You set the candle in the offering bowl. Its flame steadies in the still air, casting flickering shadows across the altar symbols."
   - The offering bowl now contains a fire source. Both conditions are met: incense burning + flame offered.
7. **Mechanism activates** — Message: "A deep grinding sound echoes through the chamber. Behind the altar, a stone panel slides slowly aside, revealing a dark recess. Inside, resting on a velvet cloth faded to grey, lies a silver key."
   - Silver key becomes visible and takeable.
8. **TAKE silver key** — Player retrieves the silver key.
9. **UNLOCK west archway** or **USE silver key ON stone door** — Player unlocks the crypt entrance. Message: "The silver key turns smoothly in the ancient lock. The stone door swings inward with barely a sound, revealing a passage beyond."

### Alternative: Exhaustive Search (Partial)

A thorough player might FEEL behind the altar, PUSH the altar, or EXAMINE the wall closely enough to notice the seam of the hidden panel. If they find the panel:
- "You feel a seam in the stone behind the altar — a panel, fitted so closely you'd never see it. But it won't budge. There must be a mechanism to open it."
- This confirms the hidden compartment exists but does NOT open it. The ritual is still required.
- However, a player who finds the seam knows they're looking for a trigger, narrowing the solution space.

### What Doesn't Work

- Placing non-flame objects in the bowl (food, coins, etc.) → "Nothing happens. The bowl seems to be waiting for something specific."
- Lighting only the incense but not offering flame → "The smoke rises, but nothing else changes. The rite feels incomplete."
- Offering flame but not lighting incense → "The candle flame flickers in the bowl, but the altar remains inert. Something more is needed."
- Each partial attempt gives feedback, guiding the player toward the full solution (progressive hinting per Frink's §5.2 [29]).

---

## What the Player Learns

1. **Written clues are actionable** — The scroll isn't just lore — it's a puzzle solution encoded in narrative language. Players learn to read ALL text carefully. Per Frink's Riven analysis (§2.6 [19]): "Environmental storytelling IS the puzzle."
2. **Symbolic actions have mechanical effects** — Placing a candle in a bowl isn't a random action — it's "offering flame" as described in the scroll. The game world responds to symbolically meaningful actions, not just mechanical ones.
3. **Multi-step environmental interaction** — Two simultaneous conditions must be met (incense + flame). This is the first Boolean-AND puzzle: neither condition alone triggers the result. Per Frink's escape room pyramid flow (§3.2): parallel tracks converging at a key point.
4. **GOAP can't solve understanding** — The player has fire. The incense is right there. The bowl is empty. GOAP could mechanically "light incense" if told to, but it cannot interpret "offer flame to the sleepers." The knowledge gate is the human-only step.
5. **Optional exploration reveals deep content** — The crypt is behind this puzzle. Only players who engage with the narrative earn access. This teaches that the game rewards engagement, not just mechanical skill.

---

## Failure Modes & Consequences

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Don't read the scroll | No clue about what the altar wants | READ scroll; or experiment with altar objects |
| Light incense but don't offer flame | "The rite feels incomplete" | Try placing flame in bowl |
| Offer flame but don't light incense | "The altar remains inert" | Light the incense |
| Place wrong object in bowl | "Nothing happens" | Try a burning/lit object instead |
| Use up all fire sources before this puzzle | Can't light incense or offer flame | Must have fire source; backtrack for matches if needed |
| Skip this puzzle entirely | Miss the crypt and its lore | No gameplay consequence; lore-only loss |

### Failure Reversibility

**Fully recoverable.** The incense can be relit if it goes out. The offering bowl can be cleared and refilled. The scroll doesn't degrade. The only risk is running out of fire sources (matches/candle), which would also affect other puzzles. No new consumable resources are introduced.

**Note on candle sacrifice:** Placing the candle in the offering bowl means the player temporarily gives up their primary light source. If the lantern was found (Puzzle 010), this is painless. If not, the player must choose: sacrifice the candle for the ritual, then rely on matches for light. This creates a micro-decision that rewards Puzzle 010 completion — a satisfying cross-puzzle payoff.

---

## Objects Required

### Existing Objects
- **Candle/candle-holder** — fire source and offering
- **Matches** — backup fire source
- **Oil lantern** (if Puzzle 010 was solved) — alternate light while candle is in bowl

### New Objects Needed (for Flanders)

| Object | Type | Key Properties | Notes |
|--------|------|----------------|-------|
| **stone-altar** | Furniture (immovable) | Large, central, inscribed with symbols, `surfaces: {top: [incense-burner, offering-bowl, tattered-scroll]}` | Anchor object for the room. Rich LOOK/FEEL descriptions. Symbols are decorative/lore, not puzzle-functional. |
| **offering-bowl** | Container (on altar) | `states: {empty, offering_placed}`, `container: {accepts_category: ["light_source", "fire_source"]}`, depression in center hints at candle | Triggers ritual when flame is placed AND incense is burning. |
| **incense-burner** | Object (on altar) | `states: {cold, smoldering, spent}`, `on_smell` changes per state, contains residual incense resin, lightable with fire source | Bronze burner. `smoldering` state required for ritual. Timer: burns for long time (won't run out during puzzle). |
| **tattered-scroll** | Readable object | `on_read: "Light the incense of remembrance. Offer flame to the sleepers..."`, portable, fragile | The puzzle clue. Can be taken from altar. Reading it in any room works. |
| **silver-key** | Key object | `key_id: "crypt-door"`, hidden behind altar (revealed by ritual), small, silver | Inside hidden compartment. Only appears after ritual completes. |
| **stone-panel** | Hidden mechanism | `states: {sealed, open}`, behind altar, triggered by ritual completion | The hidden compartment. `on_feel`: "A seam in the stone" (if player searches). Transitions sealed→open when both conditions met. |
| **unlit-sconce** (×2) | Furniture (wall) | `states: {empty, lit}`, iron wall fixtures, can hold torch/candle | Atmospheric. Player CAN light these for ambiance, but they're not puzzle-critical. |

### Ritual Mechanism (Technical Note for Bart/Flanders)

The ritual requires a compound trigger: `incense-burner._state == "smoldering" AND offering-bowl._state == "offering_placed"`. This is a Boolean-AND condition check. Implementation options:

1. **Transition guard on offering-bowl:** The `offering_placed` transition has a guard: `guard = function(ctx) return ctx.room:find("incense-burner")._state == "smoldering" end`. If incense is NOT smoldering, the offering is placed but mechanism doesn't trigger — player gets "incomplete" feedback.
2. **Room-level event listener:** The room checks both conditions on each state change. When both are met, it triggers the stone-panel transition.

Recommend option 2 for cleanliness — it keeps the logic in room metadata, not on individual objects. Aligns with Principle 8.

---

## Design Rationale

### Why This Puzzle?

**Research grounding:** This puzzle is directly inspired by two of Frink's research findings:

1. **Knowledge gates as primary design tool (§6.2, §5.1 [28]):** GOAP makes inventory puzzles obsolete. The altar puzzle has zero inventory gates — the player already possesses fire, the incense is on the altar, the bowl is right there. The gate is purely *understanding what to do*. The scroll provides the knowledge, but the player must interpret "offer flame" as "put a burning candle in the bowl." This is a genuine "aha!" moment per the neuroscience of insight (Frink §3.5 [25]): brief impasse ("what does the altar want?") → reframing ("the scroll said 'offer flame' — what if I literally offer my candle?") → dopamine reward.

2. **Riven's integrated puzzle design (§2.6 [19][20]):** "Puzzles emerge organically from culture, history, and decaying technology." The altar isn't an arbitrary game mechanism — it's a religious artifact with a ritual purpose. The puzzle makes sense in-world because it IS the ritual. The player isn't "solving a puzzle" — they're "performing an ancient rite." This is the gold standard of narrative-integrated puzzle design.

**Sensory engagement:** The incense introduces SMELL as a *feedback channel*, not just a discovery channel. When the incense lights, the room smells different. This is the first puzzle where completing a step produces a sensory change that confirms progress (sandalwood smoke = "you did something right"). Per Frink's §6.4: our 5-sense system enables "sensory feedback progression."

**Cross-puzzle synergy:** If the player found the lantern (Puzzle 010), sacrificing the candle to the offering bowl is painless — they have backup light. If they didn't, it's a meaningful choice: give up your candle and risk darkness, or skip the crypt. This creates an organic difficulty modifier based on prior exploration. Per Emily Short (Frink §1.3 [7]): "Complicate with purpose."

### Level Boundary Consideration

The **silver key** unlocks the crypt door and is consumed by use (stays in lock). No boundary concern.

The **tattered scroll** is portable lore. It should be allowed to cross levels — it's purely informational and adds narrative continuity. Flag as "SHOULD cross" in the boundary audit.

---

## GOAP Analysis

### What GOAP Resolves
- "LIGHT incense" → find fire source → apply fire to incense (standard fire-chain)
- "TAKE silver key" → standard take action (after it's revealed)
- "UNLOCK crypt door" → standard key-lock resolution

### What GOAP Cannot Resolve (The Puzzle)
- That the incense should be lit (requires interpreting the scroll)
- That a flame should be placed in the offering bowl (requires interpreting "offer flame")
- That both conditions must be met simultaneously (Boolean-AND logic)
- That a hidden compartment exists behind the altar (spatial discovery)

### GOAP Depth Analysis
- Individual steps are shallow (depth 1-2 each). But the puzzle isn't a chain — it's a parallel-AND condition. GOAP plans linear chains, not parallel condition satisfaction. This is architecturally outside GOAP's design.

---

## Sensory Hints

| Sense | Clue | What It Reveals |
|-------|------|-----------------|
| **LOOK (altar)** | "Symbols: spirals, crossed lines, crescent moon. Incense burner, empty bowl, scroll." | Altar is significant; objects arranged deliberately |
| **READ (scroll)** | "Light the incense... Offer flame... Path unsealed." | Direct solution clue |
| **SMELL (incense burner, cold)** | "Faint sandalwood and myrrh — ghosts of old prayers" | Incense existed; could be relit |
| **SMELL (incense burner, lit)** | "Rich sandalwood and myrrh fill the chamber" | Confirmation: step 1 complete |
| **FEEL (offering bowl)** | "Depression in the center, like a candleholder" | Hints at what goes in the bowl |
| **FEEL (wall behind altar)** | "A seam in the stone — a panel, fitted closely" | Hidden compartment exists (alternate discovery path) |
| **LISTEN (after ritual)** | "A deep grinding sound echoes through the chamber" | Mechanism activated — something changed |

---

## Related Puzzles

- **Prerequisite:** Puzzle 009 (Crate Puzzle) — must have iron key to enter Deep Cellar
- **Enhanced by:** Puzzle 010 (Light Upgrade) — lantern provides backup light during candle sacrifice
- **Unlocks:** Puzzle 014 (Sarcophagus Puzzle) — silver key opens crypt
- **Narrative chain:** Scroll hints at "sleepers" → Crypt contains sarcophagi of the "sleepers" → Tome reveals who they were

---

*"The moment a player reads 'offer flame to the sleepers' and thinks, 'What if I literally put my candle in the bowl?' — that's the most satisfying kind of insight. The answer was always right there in the text. They just had to see it." — Sideshow Bob*
