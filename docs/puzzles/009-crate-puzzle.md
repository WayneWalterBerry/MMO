# Puzzle 009: The Crate Puzzle

**Status:** 🔴 Theorized  
**Difficulty:** ⭐⭐ Level 2 (Introductory)  
**Zarfian Cruelty:** Polite (multiple recovery paths, no permanent failure)  
**Classification:** 🔴 Theorized  
**Pattern Type:** Discovery (Nested Containers) + Lock-and-Key (Tool-Gated)  
**Author:** Sideshow Bob  
**Last Updated:** 2026-07-22  
**Critical Path:** YES — required to complete Level 1

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Storage Cellar |
| **Objects Required** | Large crate, grain sack (inside crate), iron key (inside grain sack), crowbar (on shelf) |
| **Objects Created** | Crate fragments (broken crate state) |
| **Prerequisite Puzzles** | 006 (Iron Door Unlock — must enter Storage Cellar first) |
| **Unlocks** | Deep Cellar (north iron door) |
| **GOAP Compatible?** | Partial — GOAP can auto-resolve "open crate with crowbar" once player locates both, but cannot resolve the discovery of which crate or that the key is nested inside grain sack |
| **Multiple Solutions?** | 2 (crowbar pry-open vs. brute-force break) |
| **Estimated Time** | 3–8 min (first-time player) |

---

## Overview

The Storage Cellar is a long, dusty chamber lined with shelves and stacked crates. Somewhere in this room is the iron key that unlocks the door to the Deep Cellar — the next step on the critical path. But the key is nested three layers deep: inside a grain sack, inside a large sealed crate. The player must locate a crowbar, use it to pry open the correct crate, then search the grain sack inside.

This puzzle reinforces the container hierarchy system the player first encountered with the nightstand→matchbox→match chain in the Bedroom, but now applies it to a larger-scale environment. The key design insight: the player already knows HOW containers work (Bedroom taught that), so this puzzle tests whether they apply that knowledge to a new context. GOAP can resolve the mechanical steps once the player identifies the target, but the *discovery* — which crate? what's inside? — is the real puzzle.

---

## Solution Path

### Primary Solution: Crowbar on Large Crate

1. **Enter Storage Cellar** — Player arrives from the Cellar through the now-unlocked iron door. The room is dark unless the player brought a light source.
2. **Explore the room** — LOOK (with light) or FEEL (in darkness) reveals shelves, crates of various sizes, a wine rack, coiled rope, and general storage detritus.
3. **Locate the crowbar** — A rusted crowbar hangs from a hook on the wall. Visible on LOOK; discoverable by FEEL ("Your hand brushes cold iron — a heavy, curved tool hanging from a wall hook. A crowbar.").
4. **TAKE crowbar** — Player picks up the crowbar. It's a one-handed tool.
5. **Examine crates** — Two crates are prominent: a large sealed crate (nailed shut) and a small crate (lid sitting loose). The small crate is a red herring — it contains only straw packing. The large crate is the target.
6. **OPEN large crate** — Engine responds: "The lid is nailed shut. You'll need a tool to pry it open."
7. **PRY crate WITH crowbar** or **OPEN crate WITH crowbar** — The player uses the crowbar to lever the nailed lid off. Message: "You wedge the crowbar under the lid and heave. Nails screech as they pull free from old wood. The lid comes away, revealing the crate's contents: a heavy grain sack, packed tight."
   - Crate transitions from `sealed` → `open` state. Contents become accessible.
8. **EXAMINE grain sack** or **FEEL grain sack** — "A coarse burlap sack, heavy with grain. Something hard shifts inside as you prod it."
   - The sensory clue ("something hard shifts inside") signals a hidden object.
9. **OPEN grain sack** or **SEARCH grain sack** — Player opens or reaches into the grain sack. Message: "You untie the sack and push your hand through loose grain. Your fingers close around something cold and metallic at the bottom."
10. **TAKE iron key** — Player retrieves the iron key from the grain sack. Message: "You pull an iron key from the grain. It's dark with age but solid."
11. **Use iron key on north door** — Player proceeds to unlock the Deep Cellar door (this is a simple lock-and-key interaction, continuation of the critical path).

### Alternative Solution: Brute-Force Break

1. **BREAK crate** or **KICK crate** or **HIT crate** — Player attempts to smash the crate without tools.
   - Message: "You slam your fist/foot into the crate. The old wood splinters and cracks. After several blows, the side caves in."
   - Consequence: Takes 2-3 attempts (multi-command), makes noise ("The crashing echoes through the cellars"), and the crate is destroyed rather than opened cleanly.
   - Trade-off: Works without crowbar but is louder and messier. Grain spills everywhere. The iron key tumbles out onto the floor among debris.
   - Note: This respects real-world logic — old wooden crates CAN be kicked apart. No arbitrary "you need a tool" gate on a rotten crate.

### GOAP Behavior

- If the player types "OPEN crate," GOAP detects the `requires_tool: prying_tool` guard. If crowbar is in room (not in hand), GOAP plans: take crowbar → pry open crate.
- If the player types "GET iron key" and the engine knows the key exists inside the grain sack inside the crate, the chain exceeds comfortable GOAP depth (pry crate → open sack → take key = 3+ steps with discovery). The player must drive the discovery.
- GOAP does NOT resolve "which crate" — the player must choose to investigate the large crate.

---

## What the Player Learns

1. **Nested containers at scale** — The Bedroom taught nightstand→drawer→matchbox→match. This teaches crate→sack→key. Same principle, different scale. Reinforcement through variation (Witness-style scaffolding, per Frink's research §2.1 [11]).
2. **Tool-gated containers** — Some containers can't be opened by hand. You need the right tool capability (`prying_tool`). The crowbar is the solution. This extends the compound tool action concept from Puzzle 001.
3. **Sensory clues guide discovery** — The grain sack's "something hard shifts inside" is a FEEL/EXAMINE clue. Players learn that sensory descriptions aren't flavor text — they're puzzle hints (per Frink's §6.4: sensory system enables unique puzzles).
4. **Search thoroughly** — The small crate is a false lead (straw only). The large crate holds the prize. Teaches exhaustive exploration.
5. **Multiple approaches exist** — Crowbar is elegant; brute force is crude but works. Players learn the game respects creative problem-solving (per Frink's §4.2: real-world constraints beat arbitrary game logic).

---

## Failure Modes & Consequences

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Search only the small crate | Find nothing useful | LOOK/FEEL around room to discover large crate |
| Try to open large crate without tool | Engine hints at needing a tool ("nailed shut") | Find crowbar on wall; or use brute force |
| Miss the "something hard" clue in grain sack | May discard sack without finding key | Examine/feel sack again; pour out grain |
| Waste time searching wine bottles, shelves, etc. | No penalty, just time spent | Continue exploring; all non-puzzle objects give clear "decorative" signals |
| Never find Storage Cellar (didn't unlock cellar door) | Can't progress | Must solve Puzzle 006 first (backtrack to bedroom for brass key) |

### Failure Reversibility

**Fully recoverable.** No consumable resources are involved. The crowbar doesn't break. The crate can be opened by force if needed. The iron key is permanent once found. This puzzle cannot softlock the player.

---

## Objects Required

### Existing Objects
- None from previous rooms (player brings only inventory items)

### New Objects Needed (for Flanders)

| Object | Type | Key Properties | Notes |
|--------|------|----------------|-------|
| **large-crate** | Container (sealed) | `states: {sealed, open, broken}`, `container: {max_item_size: 4}`, nailed shut, requires `prying_tool` to transition sealed→open | FSM with 3 states. `on_feel` in sealed state: "Rough planks, nailed tight. Heavy." |
| **small-crate** | Container (loose lid) | `states: {closed, open}`, contains straw-packing only | Red herring. Opens easily. `on_feel`: "A smaller crate with a loose-fitting lid." |
| **grain-sack** | Container (tied) | `states: {tied, open, empty}`, contains iron-key, `on_feel`: "Coarse burlap, heavy with grain. Something hard shifts inside." | Inside large-crate. The "something hard" clue is critical. |
| **iron-key** | Key object | `key_id: "deep-cellar-door"`, small, metallic | Inside grain-sack. Unlocks Deep Cellar north door. |
| **crowbar** | Tool | `provides_tool: "prying_tool"`, `hands_required: 1`, iron, heavy | On wall hook. Also useful as weapon/lever in future puzzles. |
| **straw-packing** | Flavor object | Non-interactive filler | Inside small-crate. `on_feel`: "Dry straw. Nothing else." |
| **wine-rack** | Furniture (immovable) | Holds wine bottles, decorative | Environmental detail. Shelves with dusty bottles. |
| **wine-bottle** | Container (breakable) | `states: {sealed, open, broken}`, contains wine or is empty | On wine rack. Optional — could contain oil for Puzzle 010. |
| **rope-coil** | Tool | `provides_tool: "rope"`, `hands_required: 1` | On wall. Useful for Puzzle 013 (courtyard descent) and future. |

---

## Design Rationale

### Why This Puzzle?

**Research grounding:** Frink's research identifies nested containers as a core escape room chaining pattern (§3.3 [24]: "unlock drawer → find riddle → riddle answer opens safe"). Our version translates the physical "hidden compartment" escape room element into our container/spatial system. The research also confirms that "chaining: solution to puzzle A becomes a tool for puzzle B" is a proven engagement pattern.

**GOAP interaction:** Per Frink's key finding (§6.2), GOAP makes simple inventory chains obsolete. This puzzle respects that: GOAP can handle the mechanical steps once the player identifies the target, but the discovery moment ("the key is in the grain sack in the large crate") is a genuine knowledge gate that GOAP cannot shortcut. The player must explore and deduce.

**Scaffolding principle (The Witness model, §2.1 [11]):** The Bedroom taught container nesting at small scale (drawer → matchbox → match). The Storage Cellar teaches it at larger scale with an added tool requirement. Same concept, one step harder. Progressive complexity without introducing new systems.

**Real-world grounding (§4.2):** Prying open a nailed crate with a crowbar is something any player understands from real life. Finding something hidden in a sack of grain is plausible. No arbitrary game logic required.

### Level Boundary Consideration

The **iron key** unlocks the Deep Cellar door and is consumed by use (key stays in lock) or becomes irrelevant after the door is opened. No level-boundary destruction mechanism needed — the key's purpose is fulfilled within Level 1.

The **crowbar** and **rope-coil** are tools that COULD cross into Level 2. If this would break Level 2 puzzles, design a natural consumption mechanism (e.g., use rope in courtyard descent, crowbar breaks on a particularly stubborn obstacle). Flag for CBG's level boundary audit.

---

## GOAP Analysis

### What GOAP Resolves
- "OPEN crate WITH crowbar" → if crowbar is visible but not in hand, GOAP plans: take crowbar → pry crate
- "TAKE iron key" → if iron key is visible (sack open, crate open), GOAP plans: take iron key
- "UNLOCK north door WITH iron key" → standard key-lock resolution

### What GOAP Cannot Resolve (The Puzzle)
- Which crate to investigate (large vs. small)
- That the grain sack contains a hidden object
- That the crowbar is needed (player must observe "nailed shut" and connect to tool)

### GOAP Depth Analysis
- Worst case: take crowbar (1) → pry crate (2) → open sack (3) → take key (4) = depth 4 (within MAX_DEPTH=5)
- But GOAP would need to know the key is inside the sack inside the crate — this is a discovery problem, not a planning problem

---

## Sensory Hints

| Sense | Clue | What It Reveals |
|-------|------|-----------------|
| **FEEL (large crate)** | "Rough planks, nailed tight. Heavy." | Container is sealed, needs tool |
| **FEEL (grain sack)** | "Coarse burlap, heavy with grain. Something hard shifts inside." | Hidden object inside |
| **FEEL (crowbar)** | "Cold iron — a heavy, curved tool." | Tool available |
| **SMELL (room)** | "Old wood, stale grain, and decay." | Environmental atmosphere |
| **LISTEN (room)** | "Faint scratching. Rats in the walls." | Ambient life, atmosphere |
| **LOOK (small crate)** | "A smaller crate with a loose lid." | Easy to open — but it's the wrong one |

---

## Related Puzzles

- **Prerequisite:** Puzzle 006 (Iron Door Unlock) — must enter Storage Cellar
- **Teaches toward:** Puzzle 012 (Altar Puzzle) — environmental interaction, searching for hidden objects
- **Tool reuse:** Crowbar may be useful in Puzzle 013 (Courtyard Entry) or Puzzle 014 (Sarcophagus Puzzle)
- **Key chain:** Brass key (Bedroom) → Iron key (Storage) → Silver key (Deep Cellar) — escalating key discovery

---

*"The satisfaction of finding a key inside a sack of grain inside a sealed crate is the text-game equivalent of the Russian nesting doll — each layer peeled back with increasing anticipation." — Sideshow Bob*
