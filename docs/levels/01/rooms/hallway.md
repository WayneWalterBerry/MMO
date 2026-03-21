# Room Design: The Manor Hallway

**Room ID:** `hallway`  
**File:** `src/meta/world/hallway.lua` *(not yet created)*  
**Status:** 🔴 New — Design Only  
**Author:** Moe (World Builder)  
**Date:** 2026-07-21  
**Level:** 1 — The Awakening  
**Act:** IV — Emergence  

---

## 1. Physical Reality

**Space type:** Ground-floor corridor of a medieval manor house  
**Era/style:** Late medieval English (~14th–15th century), but well-maintained — unlike the abandoned spaces below. This is the manor's public face: polished, presentable, designed to impress visitors. The contrast with the cellars is immediate and deliberate.  
**Dimensions (implied):** Roughly 12m × 3m — a proper corridor, wide enough for two people to walk abreast. Ceiling ~3m, higher than any room the player has seen. The width and height create a sense of openness after the cramped underground spaces.  
**Materials:**
- **Walls:** Plastered stone, whitewashed, with dark oak wainscoting (wood paneling) on the lower half. Above the wainscoting: hung portraits in heavy frames, and iron torch brackets (some lit).
- **Floor:** Polished oak boards — warm, clean, a world apart from the flagstone and packed earth below. Creaks underfoot.
- **Ceiling:** Exposed timber beams with plastered panels between them. High enough to feel spacious.
- **Doors:** Oak doors (multiple) lead to other rooms. Most are locked. One (south) connects to the bedroom.
- **Stairway entry:** A stone archway in the floor/south-east corner leads DOWN to the deep cellar stairway.

**Architectural logic:** This is the manor's main ground-floor corridor. In a medieval manor house, the screens passage connected the great hall to the kitchens and service areas, with doors leading to the buttery, pantry, and outside. This hallway serves a similar function — it's the spine of the ground floor, connecting private rooms (bedroom) to public spaces (great hall, study). The torch brackets suggest regular habitation (someone keeps them lit), but the silence and locked doors suggest the occupants are absent. The hallway should feel like a place that was recently lived in — not centuries-abandoned like the cellars, but empty RIGHT NOW, as if the inhabitants stepped out moments ago and haven't returned.

---

## 2. Sensory Design

### description (lit — room has its own light from torches)
> "Warmth. After the cellars, the warmth is the first thing you notice. You stand in a wide, wood-paneled corridor lit by torches in iron brackets. The floor is polished oak that gleams in the firelight, and the walls are plastered white above dark wainscoting. Portraits hang at regular intervals — stern faces in heavy frames, watching. Doors lead off to left and right, all of them closed. The air smells of beeswax, old wood, and the faint char of torch smoke. At the far end, a grand staircase ascends into shadow."

**Design notes:** This description must CONTRAST with everything below. Warmth vs. cold. Light vs. darkness. Wood vs. stone. Clean vs. dusty. The player has emerged from an ordeal; this room should feel like safety — but an uneasy safety (the portraits watch, the doors are closed, nobody is home).

### feel (dark — unlikely, as torches provide light, but included for completeness)
> "Smooth wood underfoot — not stone, not earth, but warm, polished boards that creak beneath your weight. The walls are smooth plaster above and carved wood below — wainscoting, you think, running your fingers along the grooves. The air is warm. You smell beeswax and wood smoke. Ahead and to both sides, your hands find closed doors — smooth oak, latched. The corridor is wide; you can stretch both arms without touching the walls."

### smell
> "Beeswax polish on the wooden floor and paneling — the warm, honey-sweet scent of a well-maintained home. Torch smoke, acrid but not unpleasant, curling from the iron brackets. Old wood — oak, seasoned and oiled. And beneath it all, the faintest trace of absence: dust settling on surfaces that were recently clean, the smell of a house where the fires have been tended but the people have gone."

### sound
> "The crackle and hiss of the torches in their brackets — living fire, the first you've heard since the bedroom. Your footsteps on the oak floor, loud and hollow after the muffled earth of the cellars. The creak of old timbers above. And silence where there should be people: no voices, no footsteps, no doors opening. The manor is warm and lit, but utterly empty."

---

## 3. Spatial Layout

```
    North Wall (Grand Staircase → Level 2)
    ┌──────────────────────────────────────────────────────┐
    │                                                      │
    │              [grand staircase ↑]                     │
    │              (wide oak stairs ascending               │
    │               to upper floors / Level 2)             │
    │                                                      │
    │   [locked     [portrait-1]  [portrait-2]  [locked    │
    │    door]                                   door]     │
    │   (west wall)                             (east wall)│
    │                                                      │
    │              [side-table]                             │
    │              (against east wall,                      │
    │               vase on top)                            │
    │                                                      │
    │   [torch in     [portrait-3]              [torch in  │
    │    bracket]                                bracket]  │
    │   (west wall)                             (east wall)│
    │                                                      │
    │   [oak door]              [stone archway ↓]          │
    │   (south wall,            (south-east,               │
    │    → bedroom)              → deep cellar stairway)   │
    │                                                      │
    └──────────────────────────────────────────────────────┘
    South Wall
```

**Placement logic:**
- **Grand staircase** — north end of the hallway. Wide oak stairs ascending. This is the Level 2 transition.
- **Oak door (south)** — south wall. Connects to the bedroom. This is the other side of the bedroom's north exit.
- **Stone archway (down)** — south-east area. Stone steps descending to deep cellar. Where the player just came from.
- **Locked doors** — west and east walls. Lead to other manor rooms (study, library, kitchen, etc.) — all locked, not accessible in Level 1. Foreshadowing for Level 2.
- **Portraits** — 3 hanging on the walls between doors. Stern faces. Examinable for lore.
- **Side table** — against the east wall, between portraits. Oak table with a decorative vase.
- **Torches** — in iron brackets on the walls. Lit. Provide the room's light. At least one is removable.

---

## 4. Exits

### South — Oak Door → Bedroom
- **Type:** `door`
- **Passage ID:** `bedroom-hallway-door` (matches bedroom's north exit)
- **State:** Matches bedroom door state (open/closed/locked per gameplay). From this side, it's a normal door.
- **Constraints:** max_carry_size 4, player_max_size 5
- **Mutations:** open/close/lock/unlock (synchronized with bedroom side via passage_id)
- **Design note:** This is the other side of the bedroom's north door. If the bedroom door was open, this is open. If the player locked it with the brass key, it's locked from both sides. If CBG's recommendation is followed (door locked, key in deep cellar), the player arrives here via the stairway and can now unlock this door from the hallway side.

### Down — Stone Stairway → Deep Cellar
- **Type:** `stairway`
- **Passage ID:** `deep-cellar-hallway-stairway` (matches deep cellar's up exit)
- **State:** Open, always passable
- **Constraints:** max_carry_size 4, player_max_size 5
- **Description:** "Stone steps descend through an archway in the floor, curving down into the cool darkness of the cellars below."
- **Design note:** Return path to the cellars. Always open. The player came up this way.

### North — Grand Staircase → Level 2
- **Type:** `stairway`
- **Passage ID:** `hallway-level2-staircase`
- **State:** Open, always passable
- **Constraints:** max_carry_size 5, player_max_size 5
- **Description:** "A grand staircase of polished oak ascends to the upper floors. The bannister is carved with the same symbols you saw in the deep cellar — familiar now, unsettling. The stairs curve upward out of sight."
- **Design note:** This is the LEVEL TRANSITION. Ascending these stairs takes the player to Level 2. The shared symbols (deep cellar → staircase bannister) tie the manor's above-ground and below-ground spaces together narratively.

### West — Locked Door → Manor West Wing (NOT accessible in Level 1)
- **Type:** `door`
- **Passage ID:** `hallway-west-door`
- **State:** Closed, LOCKED (no key available in Level 1)
- **Description:** "A heavy oak door, closed and locked. Through the keyhole, you glimpse a darkened room beyond — bookshelves? A study?"
- **Design note:** Foreshadowing for Level 2. The player can't enter, but examining the keyhole hints at what's beyond.

### East — Locked Door → Manor East Wing (NOT accessible in Level 1)
- **Type:** `door`
- **Passage ID:** `hallway-east-door`
- **State:** Closed, LOCKED (no key available in Level 1)
- **Description:** "A lighter oak door, closed and latched. A warm smell seeps from underneath — old cooking fires, herbs, grease. The kitchen, perhaps."
- **Design note:** Foreshadowing for Level 2. The smell under the door is sensory storytelling — the player can SMELL what's beyond before they can see it.

---

## 5. Environmental Properties

| Property | Value | Rationale |
|----------|-------|-----------|
| `temperature` | 18°C | WARM. Torches radiate heat. Enclosed wooden corridor retains warmth. The contrast with 9-11°C cellars is immediate and comforting. |
| `moisture` | 0.15 | VERY LOW. Dry, well-maintained interior. Wood paneling, wax polish, warm air — everything conspires to keep moisture down. |
| `light_level` | 3 | LIT. Torches in brackets provide flickering orange-yellow light. This is the first room in Level 1 with its own light source. The player does NOT need to carry a light here. |

**Material interactions at moisture 0.15, temperature 18°C:**
- Wood (floor, wainscoting, doors, furniture): Excellent condition. The low moisture and warm temperature preserve wood perfectly. This is a well-maintained space.
- Iron (torch brackets, door hardware): Minimal rust. Warm, dry conditions prevent oxidation.
- Fabric (portrait canvas, if player carries items): Dry and stable.
- Wax (beeswax polish on floor): Stable at 18°C. Contributes to the honey-sweet smell.
- Glass (vase, if present): Stable.

**Environmental design insight:** The hallway's environmental properties (warm, dry, lit) are the OPPOSITE of the cellars (cold, damp, dark). This is the payoff — the player has earned warmth and light. The material system reinforces the narrative: carried items stop deteriorating, the player feels safe, the world becomes legible.

---

## 6. Objects Inventory

All objects are **🔴 NEW** (need to be designed by Flanders).

### Room-Level Objects

| Object | Type | Spatial Position | Status | Notes |
|--------|------|------------------|--------|-------|
| torch-lit | Lit Torch | West wall bracket | 🔴 NEW | Burning torch in iron bracket. Provides room light. Removable (player can take it). FSM: lit → spent (burns out over time). Better than candle — brighter, longer-lasting. |
| torch-bracket-hallway | Torch Bracket | East wall | 🔴 NEW | Iron bracket, holds second torch (lit). Same as cellar bracket but occupied. |
| portrait-1 | Portrait | West wall | 🔴 NEW | Oil painting in heavy frame. Depicts a stern man in medieval clothing. Examine reveals name, dates, lore hint. |
| portrait-2 | Portrait | Center wall | 🔴 NEW | Oil painting. Depicts a woman with the same face shape as portrait-1 (family). Examine reveals name, relationship, lore. |
| portrait-3 | Portrait | East wall | 🔴 NEW | Oil painting. Depicts a younger figure — child? Priest? Last of the family? Examine reveals the most significant lore clue. |
| side-table | Side Table | Against east wall | 🔴 NEW | Small oak table. Surface: top. Decorative. Holds vase. |
| vase | Vase | side-table.top | 🔴 NEW | Ceramic or glass vase. Decorative. Breakable. Empty (or contains dried flowers — atmospheric). |

### Locked Doors (exits, not inventory objects — but they have descriptions)
- West locked door, east locked door — these are EXIT objects with locked state, not room objects.

**Total: ~7 object instances** (6 unique types + 2 torches of same type)

**Flanders coordination notes:**
- Lit torch: needs FSM: lit → guttering → spent. Removable from bracket. When removed, becomes a handheld light source AND a fire source. Brighter and longer-lasting than candle. Duration: substantial (much longer than candle — reward for reaching the hallway).
- Portraits: Examinable objects. `on_look` reveals detailed descriptions of the painted figures + names + dates. These are LORE VEHICLES — they tell the manor's story. Each portrait should have unique `on_look` text (Bob/Wayne to write lore content).
- Side table: Simple furniture, surface container. Similar to nightstand but decorative.
- Vase: Breakable decorative object. Breaking it spawns ceramic shards? Or it's empty and just shatters. Mostly atmospheric — the player CAN break it, but there's no reason to (teaches that not everything is a puzzle).

---

## 7. Puzzle Hooks

**None.** This is a REWARD SPACE, not a puzzle space.

The hallway has ZERO required puzzles by design. The player has completed Level 1's challenges. This room is where they breathe, absorb lore (portraits), and prepare for Level 2.

**Potential interactions (not puzzles):**
- Examine portraits → learn manor history (lore delivery, not a puzzle)
- Take torch → acquire best light source in Level 1 (resource acquisition, not a puzzle)
- Try locked doors → learn that the manor has more to explore (foreshadowing, not a puzzle)
- Break vase → learn that not everything hides a secret (anti-puzzle — subverting expectations)

---

## 8. Map Context

### Player Journey Through This Room
1. **Arrival:** Player ascends the wide stone stairway from the deep cellar. Immediate sensory impact: WARMTH, LIGHT, WOOD, CLEAN AIR. The contrast with the cellars is the single most dramatic environmental shift in Level 1.
2. **Relief:** The player has made it. They're out of the dark, cold underground. The torchlight, the warm oak floor, the beeswax smell — all signal safety.
3. **Exploration:** Look at portraits (lore). Examine locked doors (foreshadowing). Take torch (resource). Try to open locked doors (learn boundaries).
4. **Recognition:** The south door leads to the bedroom — the player recognizes it from the other side. If locked, they now know why they needed the key.
5. **Transition:** The grand staircase at the north end leads to Level 2. The player climbs up and the level ends.

### Connections
- **Down → Deep Cellar:** Return path to the cellars. Always open.
- **South → Bedroom:** Through the oak door. Connects to bedroom's north exit (shared passage_id).
- **North → Level 2:** Grand staircase. The level transition.
- **West → Manor West Wing:** Locked. Level 2 content.
- **East → Manor East Wing:** Locked. Level 2 content.

### Environment Role
The hallway is the **emotional resolution** of Level 1:
1. **Contrast payoff:** Every environmental property is the opposite of the cellars. The material system, the temperature, the light — all reward the player for escaping.
2. **Narrative bridge:** The portraits connect above-ground and below-ground stories. The symbols on the staircase bannister tie the hallway to the deep cellar. The manor is one place, not separate rooms.
3. **Level boundary:** This is where Level 1 ends and Level 2 begins. The locked doors say "there's more" without blocking progress. The grand staircase says "this way."
4. **Pacing rest:** Zero puzzles. After 20-40 minutes of problem-solving in darkness, the player needs a moment to just BE in a safe, lit, warm space. This room provides that.
5. **Resource refresh:** The lit torch is a generous gift — a better light source than anything the player has found so far. It says: "You'll need this where you're going next."
