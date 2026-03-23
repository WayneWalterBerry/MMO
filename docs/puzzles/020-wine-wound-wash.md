# Puzzle 020: Wine Wound Wash

**Status:** 🔴 Theorized  
**Difficulty:** ⭐⭐⭐ Level 3  
**Cruelty Rating:** Polite (always recoverable)  
**Author:** Sideshow Bob (Puzzle Master)  
**Last Updated:** 2026-07-28  
**Uses Effects Pipeline:** ✅ Yes — injury treatment via structured effect  
**New Objects Needed:** None (requires new verb/transition on wine-bottle)

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Any room with wine-bottle + bleeding player |
| **Objects Required** | wine-bottle (existing), cloth or bandage (existing) |
| **Objects Created** | wine-bottle transitions to "empty" after pouring |
| **Prerequisite Puzzles** | Player must be bleeding (any source) |
| **GOAP Compatible?** | Partial — GOAP can resolve "treat bleeding" but won't suggest wine as antiseptic |
| **Multiple Solutions?** | 3 (wine wash + bandage, water wash + bandage, bandage only — slower heal) |
| **Estimated Time** | 3–8 min (first-time), 1–2 min (repeat) |

---

## Real-World Logic

**Premise:** Throughout history, wine and spirits have been used as wound antiseptics. Roman soldiers washed wounds with wine. Medieval battlefield medicine used alcohol when clean water was unavailable. The acidity and alcohol content of wine provides genuine (if imperfect) disinfection.

**Why it's satisfying:** The player is bleeding. The nearest clean water (rain barrel, well) is several rooms away — and every turn ticking means health loss. They're holding a wine bottle they picked up earlier. The "aha" moment: *wine is alcohol. Alcohol cleans wounds.* They pour wine on the wound, then bandage it. The treatment is faster and more effective than a dry bandage alone.

**What makes it real:** People actually do this. It's not game logic — it's survival logic. The game rewards players who think like a person in danger, not like a player looking for a "use item" prompt.

---

## Overview

The player has sustained a bleeding injury (from glass shard, knife, bear trap, or any source) and needs treatment. Clean water is available but distant — several rooms and turns away. The bleeding tick is eroding health every turn. The player has (or can find) a wine bottle nearby.

The puzzle's core insight: **wine is an antiseptic**. Pouring wine on a wound before bandaging provides a "clean wound" bonus that accelerates healing and prevents the wound from worsening. A dry bandage alone works, but slowly. Wine + bandage is the optimal solution.

This puzzle teaches: objects have *secondary uses* beyond their obvious purpose. Wine isn't just for drinking — it's medicine.

---

## Solution Path

### Primary Solution (Wine + Bandage)
1. Player is bleeding (any source — prerequisite injury)
2. Player has wine-bottle (sealed or open) and cloth/bandage
3. `OPEN wine-bottle` — removes cork, exposes wine
4. `POUR wine ON wound` — wine splashes on wound; stings; narration confirms cleaning
5. `APPLY bandage TO wound` — bandage applied to cleaned wound
6. **Result:** Wound heals faster (clean_wound bonus), bleeding stops sooner

### Alternative Solution A (Water + Bandage — if water is reachable)
1. Travel to rain-barrel or well (costs turns — health ticking)
2. `FILL bucket FROM well` or `TAKE water FROM rain-barrel`
3. `POUR water ON wound` — cleans wound with water
4. `APPLY bandage TO wound`
5. **Result:** Same clean_wound bonus, but cost turns traveling

### Alternative Solution B (Dry Bandage Only)
1. `APPLY bandage TO wound` — direct application without cleaning
2. **Result:** Bleeding stops, but wound heals more slowly (no clean bonus). Risk of "infected wound" status if infection mechanic is active.

### Alternative Solution C (Cloth Scraps + Wine — No Proper Bandage)
1. `TEAR blanket` or `TEAR cloth` — get cloth scraps
2. `POUR wine ON cloth-scraps` — create wine-soaked cloth
3. `APPLY cloth-scraps TO wound` — improvised wine-soaked dressing
4. **Result:** Slightly less effective than proper bandage, but still gets clean bonus

---

## Failure Modes

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Drink the wine instead of pouring it | Wine is consumed; bottle is now empty; no antiseptic available | Find water source instead (longer path) |
| Pour wine but don't bandage | Wound is cleaned but still open; bleeding continues (slower) | Find cloth/bandage and apply |
| Waste all cloth on other tasks | No bandage material; wine alone doesn't stop bleeding | Tear bedsheets, blanket, or grain sack for cloth |
| Ignore the wound entirely | Health drains per tick; eventual unconsciousness or death | Any treatment at any time stops the spiral |
| Try to bandage in darkness | Works (bandaging is tactile) but player can't see wound condition | Light a source first for full feedback |

---

## What the Player Learns

1. **Objects have secondary uses** — wine isn't just for drinking; it's an antiseptic
2. **Treatment quality matters** — clean wound + bandage > dry bandage alone
3. **Time pressure creates triage decisions** — do I travel for water or use what I have?
4. **Resource trade-offs are real** — using wine for medicine means you can't drink it later
5. **Sensory feedback confirms actions** — pouring wine stings (FEEL), smells sharp (SMELL)
6. **The game rewards real-world thinking** over abstract puzzle logic

---

## Sensory Hints

| Sense | Hint | When |
|-------|------|------|
| **SMELL** | Wine smells sharp, acidic — "There's a bite to it, almost medicinal" | When wine bottle is opened |
| **FEEL** | "The wound throbs. Each movement sends fresh pain through your arm" | While bleeding, every turn |
| **LOOK** | "Blood is seeping through your sleeve. It's getting worse" | Visual reminder of urgency |
| **TASTE** | If player tastes the wine: "Sharp, acidic. This wine has turned to vinegar — harsh but clean" | Tasting confirms antiseptic quality |
| **LOOK at wine** | "A dark bottle of wine. The liquid sloshes when you move it" | Standard examine — no direct hint |
| **SMELL wound** | "The wound smells metallic — blood. It needs cleaning" | Smell the wound itself |

**The "aha" trigger:** The combination of "wound needs cleaning" + "wine smells medicinal/sharp" should click for players thinking in real-world terms.

---

## Prerequisite Chain

**Objects:** wine-bottle (✅ exists), bandage (✅ exists), cloth/cloth-scraps (✅ exists)  
**Verbs:** POUR (needs "pour on" variant targeting body/wound), APPLY (✅ exists for bandage)  
**Mechanics:** Bleeding injury active (✅ injury system exists), wound-cleaning bonus (❌ new — needs "clean_wound" treatment modifier)  
**Puzzles:** None required, but player must have sustained a bleeding injury from any source

---

## Objects Required

| Object | Type | State(s) | Key Properties | Built? |
|--------|------|----------|----------------|--------|
| wine-bottle | consumable | sealed, open, empty | `provides: antiseptic` (when poured on wound), `is_consumable: true` | ✅ (needs new transition) |
| bandage | treatment | clean, applied, soiled | `heals: bleeding`, `healing_boost: 2` (or 3 with clean_wound) | ✅ |
| cloth / cloth-scraps | craftable | normal | `can_become: bandage`, `absorbs_liquid: true` | ✅ |

**New transitions needed on wine-bottle:**
```lua
-- New transition: pour wine on wound
{
    from = "open", to = "empty", verb = "pour",
    requires_target = "wound",  -- or body_part
    effect = {
        type = "add_status",
        status = "clean_wound",
        duration = -1,  -- permanent until wound heals
        message = "The wine burns as it hits the wound — sharp, stinging pain — but the bleeding seems cleaner now.",
    },
}
```

---

## Design Rationale

**Why wine?** Wine is already in the game. It's a natural secondary-use object — players who think "what would I actually do?" will reach for the alcohol before traveling three rooms for water. This rewards real-world intuition.

**Why this difficulty?** Level 3 — the core insight (wine = antiseptic) isn't obvious to all players. It requires connecting two pieces of information: "wound needs cleaning" + "wine is alcohol." GOAP won't suggest this path. The player must think laterally.

**Why not just water?** Water IS a solution — but it's the obvious, slow one. Wine is the clever, fast one. Having both validates the player who thinks creatively while not punishing the player who plays it safe.

---

## GOAP Analysis

GOAP can resolve `treat bleeding` → find bandage → apply bandage. This gives the "dry bandage" solution automatically. But GOAP will NOT suggest pouring wine on the wound first — that's a lateral-thinking step outside the standard treatment chain.

**Manual puzzle part:** Realizing wine can be used as wound wash. This is the core insight.

**GOAP-resolved part:** Finding and applying bandage after wound is cleaned.

---

## Effects Pipeline Integration

This puzzle uses the Effects Pipeline for the wine-on-wound interaction:

```lua
-- Wine poured on wound triggers structured effect
effect = {
    type = "add_status",
    status = "clean_wound",
    duration = -1,
    severity = "beneficial",
    message = "The wine burns fiercely, but the wound looks cleaner.",
}
```

The `clean_wound` status modifies healing calculations in the injury system — bandages applied to a clean wound heal faster. All logic lives in object metadata (Principle 8 compliant).

---

## Notes & Edge Cases

- **Timing:** Wine cleaning is only useful if done BEFORE bandaging. Wine on a bandaged wound is wasted.
- **Resource scarcity:** Only one wine bottle in Level 1. Using it as medicine means you can't use it for other purposes (distraction, offering, drinking).
- **Multiple wounds:** If player has two bleeding wounds, one wine bottle can clean both (pour divides).
- **Infection mechanic (future):** If infection is added, dry bandages could cause wound infection — making wine wash nearly essential for serious wounds.
- **Player softlock:** No. Dry bandage always works. Wine is an optimization, not a requirement.

---

## Status

🔴 Theorized — Awaiting Wayne's review.

**Owner:** Sideshow Bob  
**Next:** Wayne approves → Flanders adds POUR ON WOUND transition to wine-bottle.lua
