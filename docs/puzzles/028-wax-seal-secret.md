# Puzzle 028: Wax Seal Secret

**Status:** 🔴 Theorized  
**Difficulty:** ⭐⭐⭐⭐ Level 4  
**Cruelty Rating:** Polite (no unwinnable states)  
**Author:** Sideshow Bob (Puzzle Master)  
**Last Updated:** 2026-07-28  
**Uses Effects Pipeline:** ❌ No (uses fire/heat system, not injury pipeline)  
**New Objects Needed:** ✅ wax-sealed-letter, charcoal/soot (for invisible writing reveal)

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Study, crypt, or bedroom — near candle and paper |
| **Objects Required** | candle (existing), tattered-scroll or paper (existing), wax-sealed-letter (new) |
| **Objects Created** | Revealed message (scroll state mutation — hidden → visible) |
| **Prerequisite Puzzles** | 001 Light the Room (fire source available) |
| **GOAP Compatible?** | No — hidden message discovery is outside GOAP modeling |
| **Multiple Solutions?** | 2 (heat reveal with candle flame, or soot-rubbing technique) |
| **Estimated Time** | 10–20 min (first-time), 3–5 min (repeat) |

---

## Real-World Logic

**Premise:** Invisible ink written in wax, lemon juice, or milk has been used for secret communication for centuries. The technique: write with a substance that's invisible when dry but becomes visible when heated or dusted with a contrasting powder. Wax writing is revealed by heat (the wax melts and becomes shiny/visible) or by rubbing soot/charcoal over the surface (the powder sticks to the wax but not the paper, revealing the message in relief).

**Why it's satisfying:** The player finds a seemingly blank scroll in a crypt. It looks like worthless old paper. But when they hold it near a candle flame, words begin to appear — a message written in candle wax, invisible until heated. The message reveals a crucial clue: a combination, a name, a warning. The player who treated a blank scroll as trash just discovered a secret. The player who held onto it "just in case" is rewarded.

---

## Overview

A scroll or letter found in the game appears blank or unreadable. Standard examination reveals nothing useful — "a piece of old parchment, yellowed and apparently blank." But the scroll has a hidden message written in candle wax (invisible wax writing).

Two methods reveal the hidden writing:
1. **Heat:** Hold the scroll near a candle flame. The heat makes the wax shiny and visible against the parchment.
2. **Soot rubbing:** Rub charcoal, soot, or pencil graphite across the surface. The powder adheres to the wax but slides off the bare parchment, revealing the message in relief.

The revealed message contains a critical clue for another puzzle — a combination, a password, a map fragment, or a warning.

---

## Solution Path

### Primary Solution (Heat Reveal)
1. Player has the scroll/letter (found earlier — appeared blank)
2. Player has a lit candle (from Puzzle 001 or any fire source)
3. `HOLD scroll NEAR candle` — or `HEAT scroll WITH candle`
4. **Engine response:** "As you hold the parchment near the flame, something appears. Faint at first, then clearer — letters shimmer on the surface, written in melted wax. A message, hidden until now."
5. `READ scroll` — the hidden message is now visible and readable
6. **Result:** Critical clue obtained. Scroll state mutated from "blank" to "revealed."

### Alternative Solution A (Soot Rubbing)
1. Player has charcoal, pencil, or can collect soot from a burnt-out torch/fire
2. `RUB charcoal ON scroll` — or `DUST scroll WITH soot`
3. **Engine response:** "Dark powder adheres to raised lines on the parchment. Letters appear in relief — words written in wax, now visible as dark text against the lighter paper."
4. `READ scroll`
5. **Result:** Same clue, different technique

### Alternative Solution B (Accidental Discovery)
1. Player places scroll on a warm surface (near fireplace, on heated stone)
2. Engine provides ambient hint: "You notice something odd — faint marks appearing on the parchment as it warms."
3. Player investigates: `EXAMINE scroll` — now shows partial text
4. `HOLD scroll NEAR fire` — completes the reveal
5. **Result:** Serendipitous discovery for observant players

---

## Failure Modes

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Hold scroll TOO close to flame | Scroll catches fire! Paper burns — message partially destroyed | Quick action: `DROP scroll` and `STOMP` to extinguish. Partial message readable if fast enough. |
| Never think to heat the scroll | Scroll remains "blank" — puzzle unsolved | Soot/charcoal method is second chance. Environmental hints (warm room causing partial reveal) also help. |
| Discard the "blank" scroll as trash | Scroll is gone from inventory | Player must return to where they found it (if still there). Teaches: don't discard items impulsively. |
| Use all fire sources before finding scroll | Can't heat it — must use soot method or find more fire | Soot method works without fire. Charcoal from any burnt wood/torch. |
| Rub too hard with charcoal | Smudges the message — harder to read but not destroyed | Blow off excess charcoal. Message is still legible with effort. |

---

## What the Player Learns

1. **"Blank" doesn't mean empty** — objects can have hidden information
2. **Heat reveals secrets** — wax and invisible inks respond to temperature
3. **Multiple techniques exist for the same goal** — heat vs. soot-rubbing
4. **Fire has uses beyond light and warmth** — it's a forensic tool
5. **Don't discard seemingly useless items** — the "blank" scroll is the most valuable paper in the game
6. **Observation of ambient effects** — noticing marks appearing near heat sources

---

## Sensory Hints

| Sense | Hint | When |
|-------|------|------|
| **FEEL scroll** | "The parchment feels oddly waxy in places, like something was smeared on it" | First tactile hint — wax residue |
| **SMELL scroll** | "A faint smell of beeswax and old parchment" | Second hint — wax is on the paper |
| **LOOK at scroll** | "Old yellowed parchment, apparently blank. Faded with age" | No visual hint (wax is invisible) |
| **LOOK at scroll (near fire)** | "Wait — is that... there are faint marks on the parchment. They seem to shimmer in the firelight" | Proximity hint if near any heat source |
| **FEEL scroll (near fire)** | "The parchment is warm. The waxy texture seems more pronounced" | Thermal hint |
| **SMELL charcoal/soot** | "Bitter, smoky carbon. It would leave marks on anything it touches" | Hints at rubbing technique |

**Sensory escalation:** FEEL detects wax texture → SMELL detects beeswax → proximity to heat shows faint marks → direct heat reveals message. Each sense adds one more piece of the puzzle.

---

## Prerequisite Chain

**Objects:** wax-sealed-letter or wax-written-scroll (❌ new), candle (✅), charcoal/soot (❌ new), pencil (✅ — graphite works)  
**Verbs:** HOLD NEAR (compound — "hold X near Y"), RUB ON (compound), HEAT WITH (alias)  
**Mechanics:** Temperature proximity detection (❌ new — "near fire" state), object state mutation on heat exposure  
**Puzzles:** 001 Light the Room (fire source), or any fire-producing puzzle

---

## Objects Required

| Object | Type | State(s) | Key Properties | Built? |
|--------|------|----------|----------------|--------|
| wax-written-scroll | readable | blank, partial-reveal, revealed, burned | `has_hidden_writing: true`, `reveal_method: heat OR soot` | ❌ New |
| candle | fire source | lit | `provides: fire_source, heat_source` | ✅ |
| charcoal | material | normal | `provides: marking_tool, abrasive`, `color: black` | ❌ New |
| pencil | tool | normal | `provides: writing_tool, marking_tool` (graphite = soft marking) | ✅ |

**New object: wax-written-scroll**
```lua
return {
    id = "wax-written-scroll",
    name = "old parchment",
    keywords = { "scroll", "parchment", "paper", "blank" },
    description = "Old yellowed parchment. It appears blank.",
    has_hidden_writing = true,
    reveal_method = { "heat", "soot" },
    hidden_message = "The key lies beneath the third stone from the east wall.",
    states = {
        blank = {
            on_feel = "The parchment feels oddly waxy in places.",
            on_smell = "Faint scent of beeswax and old parchment.",
        },
        revealed = {
            description = "Parchment with shimmering wax text, now visible.",
            on_read = "The message reads: 'The key lies beneath the third stone...'",
        },
    },
}
```

---

## Design Rationale

**Why wax writing?** It's a real historical technique. It connects to the candle (already in the game) — the same object that provides light can also reveal secrets. It teaches that objects have properties beyond their primary use (candle = light AND heat AND wax source).

**Why Level 4?** The core insight — "blank paper might have invisible writing" — is a genuine lateral thinking challenge. Players must connect "waxy feel" + "near heat, marks appear" + "candle provides heat." The pencil/soot alternative provides a second path for players who don't make the heat connection.

**Why is the scroll found earlier?** Delayed payoff. The scroll is found 2–3 puzzles before it's needed. Players who examine everything will notice the waxy feel. Players who rush will pick it up and forget it. When they reach the locked area that needs the clue, they must re-examine their inventory and think: "What haven't I fully investigated?"

---

## GOAP Analysis

GOAP cannot resolve hidden message discovery. The planner doesn't model "invisible content" or "heat reveals writing." The entire puzzle is:

1. Find the scroll (exploration)
2. Notice it feels waxy (sensory investigation — FEEL)
3. Connect wax + heat = visible writing (lateral thinking)
4. Apply heat or soot (execution)
5. Read the revealed message (standard verb)

Steps 2 and 3 are the puzzle. Everything else is GOAP-compatible.

---

## Notes & Edge Cases

- **Burning the scroll:** If held too long over flame, it burns. Partial message survives (enough to guess the full clue). Teaches fire management.
- **Pencil as soot alternative:** The pencil's graphite can work for soot-rubbing, connecting to Puzzle 003 (Write in Blood — writing tools).
- **Multiple hidden messages:** Future scrolls could use the same mechanic. Once taught, players check all blank paper near fire.
- **Wax seal as separate puzzle element:** A wax seal on a letter bears an emblem — the emblem itself is a clue (coat of arms, symbol, initials). Breaking the seal to read the letter vs. preserving the seal for its emblematic clue.
- **No softlock:** The clue revealed by the scroll should have a brute-force alternative (trial and error, other lore sources).

---

## Status

🔴 Theorized — Awaiting Wayne's review.

**Owner:** Sideshow Bob  
**Next:** Wayne approves → Flanders builds wax-written-scroll and charcoal objects → Bart designs heat-proximity system
