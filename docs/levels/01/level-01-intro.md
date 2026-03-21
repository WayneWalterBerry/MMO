# Level 1: The Awakening (Intro Level)

**Version:** 1.0  
**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-07-21  
**Status:** Master Design — Ready for Room & Puzzle Design  

---

## Executive Summary

Level 1 is the player's introduction to the game world and core mechanics. The player wakes at 2 AM in a locked bedroom of a medieval manor house, trapped and confused. Through exploration, they must learn the fundamental systems — sensory interaction in darkness, tool usage, spatial manipulation, resource management, and problem-solving — to escape the bedroom, navigate the cellars beneath, and ultimately emerge into the manor proper.

**Narrative Arc:** Confusion → Discovery → Mastery → Escape  
**Player Journey:** Wake trapped → Light the darkness → Explore the room → Find the hidden path → Navigate the cellars → Unlock the deep secrets → Emerge into the manor  
**Core Theme:** "Nothing is as it seems; look beneath the surface"

**Estimated Playtime:** 20-45 minutes (first-time player)

---

## Level 1 Vision

### What is Level 1 About?

Level 1 is a **tutorial disguised as a mystery**. The player doesn't realize they're being taught — they're simply trying to survive and escape. Every puzzle teaches a core game system while advancing a narrative of confinement, discovery, and emergence.

**Thematic Core:** The player is trapped in a place they don't understand, with no memory of how they arrived. The bedroom feels staged, like a prison cell disguised as comfort. The cellars beneath suggest something darker — this is not a normal household. The player must move from confusion (total darkness, sensory deprivation) to understanding (light, exploration, tool mastery) to agency (escape).

### What Does the Player Learn?

**Core Systems Taught:**
1. **Sensory Interaction** — FEEL, SMELL, LISTEN, TASTE work in darkness
2. **Light and Darkness** — Light sources are consumable resources; darkness is navigable but limits interaction
3. **Container System** — Objects contain other objects; nested containers; opening/closing
4. **Tool Usage** — Compound tool actions (strike match ON matchbox); tool requirements (key unlocks door)
5. **Spatial Manipulation** — Moving objects reveals hidden things (rug → trap door)
6. **Inventory Management** — 2-hand limit; weight/size constraints; strategic carrying
7. **Risk and Consequence** — Choices have outcomes (waste matches = darkness; break window = injury)
8. **Material Properties** — Objects have temperature, moisture, breakability, flammability
9. **Environmental Storytelling** — Rooms tell stories through object placement and descriptions

### Narrative Arc

**Act I: The Awakening (Bedroom)**
- Player wakes in total darkness
- Sensory confusion → gradual understanding
- Discovery of tools and resources
- Revelation: there's a hidden exit (trap door)

**Act II: Descent (Cellar & Storage Cellar)**
- Player descends into underground chambers
- Environment becomes colder, damper, more oppressive
- New tools and challenges (locked iron door)
- Clues suggest this is not a normal home

**Act III: The Deep Secret (Deep Cellar & Crypt)**
- Player unlocks the forbidden door
- Discovery of something dark/mysterious (details TBD by Wayne)
- Final challenge before escaping to the manor proper
- Transition: from prisoner to explorer

**Act IV: Emergence (Hallway & Exit)**
- Player emerges from the cellars into the manor
- Light, warmth, signs of life (or recent life)
- Transition to Level 2 (the manor proper)

### Mood & Atmosphere

**Bedroom:** Disorienting, claustrophobic, mysterious. Like waking in a stranger's home — nothing is familiar. The darkness is oppressive but not hostile. There's a sense of abandonment, as if whoever lived here left in a hurry.

**Cellar:** Cold, damp, industrial. This is a working space, not a living space. The air smells of earth and stone. Water drips. The darkness feels heavier here, more ancient. The player is descending into the bones of the building.

**Storage Cellar:** Utilitarian but neglected. Barrels, crates, forgotten supplies. Dust and cobwebs. A sense that this place hasn't been visited in a long time. Faint traces of activity — old footprints in dust, disturbed surfaces.

**Deep Cellar:** Forbidden. The iron-bound door signals "stay out." Once inside, the atmosphere changes — older architecture, different stonework, a faint smell of must and something else (incense? decay?). This is a secret space.

**Crypt (optional final room):** Ancient. Pre-dates the manor. Stone sarcophagi, old religious symbols, a sense of sanctity violated. This is where the manor's original purpose is revealed (whatever Wayne decides that to be).

**Hallway (exit):** Relief. Warmer air, signs of recent habitation (lit torches, clean floors). The transition from "trapped below" to "free to explore" is palpable.

---

## Room Map

### ASCII Layout

```
                    LEVEL 1: THE AWAKENING
                    (Medieval Manor — Underground & Ground Floor)

        ╔══════════════════════════════════════════════════╗
        ║              GROUND FLOOR (Exit)                 ║
        ╠══════════════════════════════════════════════════╣
        ║                                                  ║
        ║        [Manor Hallway]──────────→ Level 2       ║
        ║              ▲ (oak door)                        ║
        ║              │                                   ║
        ║              │ (stairway up)                     ║
        ╚══════════════╪══════════════════════════════════╝
                       │
        ╔══════════════╪══════════════════════════════════╗
        ║              │         CELLARS                   ║
        ╠══════════════╪══════════════════════════════════╣
        ║              │                                   ║
        ║         [Cellar]                                 ║
        ║              ▲ (trap door / stairway)            ║
        ║              │                                   ║
        ║              │ (iron door — locked)              ║
        ║              ▼                                   ║
        ║        [Storage Cellar]                          ║
        ║              │                                   ║
        ║              │ (iron door — locked)              ║
        ║              ▼                                   ║
        ║        [Deep Cellar]                             ║
        ║              │                                   ║
        ║              │ (stone archway)                   ║
        ║              ▼                                   ║
        ║          [Crypt] (optional)                      ║
        ║                                                  ║
        ╚══════════════════════════════════════════════════╝

        ╔══════════════════════════════════════════════════╗
        ║              GROUND FLOOR (Start)                ║
        ╠══════════════════════════════════════════════════╣
        ║                                                  ║
        ║         [Bedroom] (START HERE)                   ║
        ║              ║ (north — oak door)                ║
        ║              ▼                                   ║
        ║         [Hallway] (leads to manor)               ║
        ║              ║                                   ║
        ║              ║ (window — alternate/dangerous)    ║
        ║              ▼                                   ║
        ║         [Courtyard] (outside — optional)         ║
        ║                                                  ║
        ╚══════════════════════════════════════════════════╝

```

### Room Connections

**Primary Path (Critical Path):**
1. **Bedroom** (start) → DOWN (trap door) → **Cellar** → NORTH (iron door) → **Storage Cellar** → NORTH (iron door) → **Deep Cellar** → UP (stairs) → **Hallway** → NORTH → **Level 2**

**Alternate Paths:**
- **Bedroom** → NORTH (oak door — locked? TBD) → **Hallway** → NORTH → **Level 2** (shortcut if player has key)
- **Bedroom** → WINDOW (breakable) → **Courtyard** (dangerous, leads to exterior exploration — optional)

**Optional Exploration:**
- **Deep Cellar** → WEST (stone archway) → **Crypt** (secret lore/treasure room)

### Total Rooms in Level 1

**Core Rooms:** 7  
1. Bedroom (🟢 Implemented)
2. Cellar (🟢 Implemented)
3. Storage Cellar (🔴 New)
4. Deep Cellar (🔴 New)
5. Hallway (🔴 New)
6. Courtyard (🔴 New — optional)
7. Crypt (🔴 New — optional)

---

## Room Summaries

### 1. Bedroom (START ROOM) — 🟢 Implemented

**Full Name:** "The Bedroom" / "The Bedchamber"

**Description:** A dim bedchamber that smells of tallow, old wool, and lavender. Stone walls, cold flagstones, sparse furniture. Feels like a guest room or servant's quarters — functional but not luxurious. The player wakes here at 2 AM in complete darkness.

**Mood:** Disorienting, claustrophobic, mysterious. The darkness is oppressive. The room feels staged, like someone prepared it for a specific purpose.

**Key Objects (23 total):**
- **Furniture:** Bed (player starts here), nightstand, vanity, wardrobe, rug, window, curtains, chamber pot
- **Light sources:** Candle, matchbox (with 7 matches)
- **Tools:** Knife (under bed), needle + thread (in sack), pin (in pillow), pen, pencil, paper
- **Hazards:** Poison bottle (nightstand), glass shards (if window broken)
- **Keys:** Brass key (under rug — unlocks cellar iron door)
- **Hidden exits:** Trap door (under rug)

**Connections:**
- NORTH → Hallway (oak door — open but could be locked by design choice)
- DOWN → Cellar (trap door — hidden until rug moved)
- WINDOW → Courtyard (breakable glass — dangerous drop)

**Puzzles (8 total, all 🟢):**
- Puzzle 001: Light the Room (⭐⭐)
- Puzzle 002: Poison Bottle (⭐⭐)
- Puzzle 003: Write in Blood (⭐⭐)
- Puzzle 004: Inventory Management (⭐⭐)
- Puzzle 005: Bedroom Escape (⭐⭐⭐)
- Puzzle 006: Iron Door Unlock (⭐⭐) — key is here
- Puzzle 007: Trap Door Discovery (⭐⭐)
- Puzzle 008: Window Escape (⭐⭐⭐⭐) — alternate path

**Design Notes:** This is the most dense room in the game. It teaches ALL core systems. Every subsequent room is simpler by design — the player has already learned the fundamentals here.

---

### 2. Cellar — 🟢 Implemented

**Full Name:** "The Cellar" / "The Wine Cellar"

**Description:** A low-ceilinged cellar at the bottom of a stone stairway. Rough-hewn granite walls slick with moisture. Water drips in the darkness. Cold, damp, heavy with the smell of earth and stone (and something metallic — blood?). Cobwebs hang from the ceiling.

**Mood:** Cold, oppressive, ancient. The player has descended into the bones of the building. This is not a place for the living.

**Key Objects (2 total):**
- **Barrel** — large wooden cask (container? breakable?)
- **Torch bracket** — iron wall fixture (could hold a torch if player finds one)

**Connections:**
- UP → Bedroom (stone stairway through trap door)
- NORTH → Storage Cellar (iron door — locked with brass key from bedroom)

**Puzzles:**
- Puzzle 006: Iron Door Unlock (⭐⭐) — uses brass key from bedroom

**Design Notes:** This is a transitional space. Simpler than bedroom (only 2 objects) but teaches spatial navigation in darkness. The locked iron door is the first "you need a key" puzzle the player encounters AFTER descending. They must return to bedroom if they forgot the key, or continue exploring if they brought it.

---

### 3. Storage Cellar (NEW — 🔴 Theorized)

**Full Name:** "The Storage Cellar" / "The Supply Room"

**Description:** A long, narrow cellar lined with wooden shelves and stacked crates. Dust coats everything. The air smells of old wood, stale grain, and decay. Cobwebs drape across corners. Faint scratching sounds suggest rats in the walls. The room feels abandoned — supplies forgotten, left to rot.

**Mood:** Neglected, utilitarian, eerie. This was once a working storage space for the manor's provisions, but it hasn't been maintained. The player feels like an intruder in a forgotten place.

**Key Objects (8-10 new objects needed):**
- **Large crate** (container — closed, breakable)
- **Small crate** (container — closed, lighter than large crate)
- **Sack of grain** (heavy, could contain hidden objects or pests)
- **Wine rack** (contains bottles — some intact, some broken)
- **Wine bottle** (container — could be empty, or contain wine/oil)
- **Rope coil** (tool — hanging on wall; enables climbing/tying)
- **Iron key** (hidden in crate — unlocks deep cellar door)
- **Oil lantern** (on shelf — better light source than candle; requires oil)
- **Rusty tools** (shovel, crowbar — useful for breaking/prying)
- **Rat** (creature — flees if player moves too quickly; ambient life)

**Connections:**
- SOUTH → Cellar (iron door — player just came through)
- NORTH → Deep Cellar (iron door — locked, requires iron key from this room)

**Puzzles (NEW — 🔴 Theorized):**
- **Puzzle 009: Crate Puzzle (⭐⭐)** — Find the iron key hidden in one of the crates. Teaches container hierarchy (crate → sack → key) and breaking mechanics (crowbar on crate).
- **Puzzle 010: Light Upgrade (⭐⭐)** — Find oil lantern + oil, combine to create a superior light source. Teaches tool upgrading and resource combination. OPTIONAL.

**Design Rationale:**
- **Pacing:** After the dense bedroom and the simple cellar, this room offers moderate complexity. More objects than cellar, fewer than bedroom.
- **Skill reinforcement:** Player practices container interactions, tool discovery, and spatial search.
- **Progression gate:** The iron key is critical path — player can't proceed without it.
- **Optional depth:** Oil lantern is optional but rewarding. Rope is optional but opens alternate solutions in later rooms.

---

### 4. Deep Cellar (NEW — 🔴 Theorized)

**Full Name:** "The Deep Cellar" / "The Old Cellar"

**Description:** The architecture changes here — older stonework, different masonry. The walls are carved from bedrock, not stacked stones. The ceiling is vaulted, like a chapel or crypt. Iron sconces line the walls, unlit. The air smells of old incense, wax, and something musty. Symbols are carved into the stone — religious or occult, hard to tell. This place pre-dates the manor above.

**Mood:** Sacred or profane (player can't tell which). Oppressive but grand. This is a place of significance, built for a purpose the player doesn't yet understand. The darkness here feels intentional, not accidental.

**Key Objects (6-8 new objects needed):**
- **Stone altar** (large, immovable — ancient, inscribed with symbols)
- **Unlit sconce** (wall fixture — could be lit with torch/candle)
- **Incense burner** (on altar — cold, but contains ash)
- **Tattered scroll** (on altar — readable text: lore/clues)
- **Silver key** (hidden behind altar — unlocks crypt door, optional)
- **Stone sarcophagus** (against wall — closed, heavy lid — contains ???)
- **Offering bowl** (on altar — empty, but could accept items)
- **Chain** (hanging from ceiling — could be pulled to trigger mechanism?)

**Connections:**
- SOUTH → Storage Cellar (iron door — player just came through)
- UP → Hallway (stone stairway — leads to manor ground floor) **MAIN EXIT**
- WEST → Crypt (stone archway — locked, requires silver key) **OPTIONAL**

**Puzzles (NEW — 🔴 Theorized):**
- **Puzzle 011: Ascent to Manor (⭐⭐)** — Navigate the stairway up to the hallway. Simple transition, but teaches vertical navigation and signals progression.
- **Puzzle 012: Altar Puzzle (⭐⭐⭐)** — OPTIONAL. Interact with altar objects (scroll, incense burner, offering bowl) to unlock the crypt. Teaches environmental storytelling and non-obvious interactions. Could require placing an object (candle? wine?) in the offering bowl.

**Design Rationale:**
- **Narrative pivot:** This room reveals that the manor has a secret history. The architecture change signals "something important."
- **Progression split:** Main exit (up to hallway) is obvious and simple. Optional content (crypt) is hidden and requires exploration.
- **Atmosphere shift:** From utilitarian (storage) to ceremonial (deep cellar). The player transitions from "escaping a prison" to "exploring a mystery."

---

### 5. Hallway (NEW — 🔴 Theorized)

**Full Name:** "The Manor Hallway" / "The Ground Floor Corridor"

**Description:** A wide, wood-paneled corridor lit by flickering torches in wall brackets. The floor is polished oak, clean and well-maintained. Portraits line the walls — stern faces staring down. The air is warmer here, almost welcoming after the cold cellars. Doors lead off to other rooms (locked, not accessible yet). At the far end, a grand staircase ascends to the manor's upper floors.

**Mood:** Relief, warmth, transition. The player has escaped the cellars. This feels like civilization — a real home, not a prison. But the locked doors and silent portraits suggest the manor is empty (or watching).

**Key Objects (4-6 new objects needed):**
- **Torch** (in wall bracket — lit, removable)
- **Portrait** (on wall — depicts manor residents; examine reveals lore)
- **Side table** (furniture — holds decorative objects)
- **Vase** (on side table — breakable, decorative)
- **Locked door** (leads to manor study/library/etc — not accessible in Level 1)
- **Oak door** (leads back to bedroom — from the other side)

**Connections:**
- DOWN → Deep Cellar (stone stairway — player just came through)
- SOUTH → Bedroom (oak door — connects to bedroom's NORTH exit)
- NORTH → Level 2 (grand staircase or main corridor — transitions to next level)

**Puzzles:**
- **None (transition room)** — This is a reward space, not a puzzle space. The player has completed Level 1. They can rest here, examine portraits for lore, and prepare for Level 2.

**Design Rationale:**
- **Completion signal:** The warm light, clean floors, and open space signal "you've made it." The contrast with the cellars is deliberate.
- **World building:** Portraits and furniture establish that this is a real manor with a history and inhabitants (who are mysteriously absent).
- **Level transition:** The grand staircase or main corridor clearly leads to "the next chapter."

---

### 6. Courtyard (NEW — 🔴 Theorized, Optional)

**Full Name:** "The Inner Courtyard" / "The Manor Yard"

**Description:** A small, cobblestone courtyard enclosed by the manor's walls. Open to the sky — stars visible above, moonlight casting shadows. A stone well stands at the center. Ivy climbs the walls. The air smells of rain and chimney smoke. Doors lead into the manor's ground floor (kitchen, servants' quarters?). The bedroom window is visible far above — a dangerous drop.

**Mood:** Exposed, cold, eerie. The player is outside for the first time, but still trapped within the manor's walls. The height of the bedroom window above emphasizes the danger of the window escape route.

**Key Objects (4-6 new objects needed):**
- **Stone well** (container — contains water; could conceal hidden objects)
- **Well bucket** (on rope — can be lowered/raised)
- **Ivy** (growing on walls — climbable? breakable?)
- **Cobblestones** (floor — loose stone could be tool/weapon)
- **Wooden door** (leads to kitchen or servants' area — locked or open?)
- **Rain barrel** (contains water — alternate to well)

**Connections:**
- WINDOW (up) → Bedroom (if player broke/opened bedroom window)
- DOOR → Kitchen or Servants' Hall (could connect to manor ground floor — optional content)

**Puzzles (NEW — 🔴 Theorized):**
- **Puzzle 013: Courtyard Entry (⭐⭐⭐⭐)** — OPTIONAL. Player reaches courtyard via window escape (Puzzle 008). Must find a way to enter the manor from outside (locked doors, climbable ivy, break window?).

**Design Rationale:**
- **Reward for exploration:** Only accessible if player takes the risky window escape route. Rewards lateral thinking.
- **Alternate content:** Offers a different perspective on the manor (outside vs. inside). Could contain unique lore or items.
- **Danger reinforcement:** The drop from the bedroom window is emphasized here, validating the "harsh consequence" warning.

---

### 7. Crypt (NEW — 🔴 Theorized, Optional)

**Full Name:** "The Crypt" / "The Burial Chamber"

**Description:** A small, stone chamber with vaulted ceilings. Five stone sarcophagi line the walls, their lids carved with effigies of robed figures. The air is cold and still, heavy with the smell of dust and old wax. Candle stubs sit in wall niches, unlit for decades. Symbols cover the walls — religious iconography, names, dates. This is a family crypt, the burial place of the manor's original inhabitants.

**Mood:** Sacred, mournful, ancient. The player is trespassing in a place of death. The silence is profound. The darkness feels respectful, not hostile.

**Key Objects (6-8 new objects needed):**
- **Sarcophagus** (5 total — stone containers, heavy lids, contain remains or treasures)
- **Effigy** (carved on sarcophagus lid — depicts deceased, examine reveals names/dates)
- **Candle stub** (in wall niche — unlit, old, usable if player has fire)
- **Skull** (inside sarcophagus — remains of deceased)
- **Burial goods** (inside sarcophagus — jewelry, coins, religious items)
- **Tome** (hidden in sarcophagus — lore book, reveals manor's history)
- **Silver dagger** (burial good — tool/weapon)
- **Wall inscription** (carved text — names, dates, blessings or curses)

**Connections:**
- EAST → Deep Cellar (stone archway — player just came through)

**Puzzles (NEW — 🔴 Theorized):**
- **Puzzle 014: Sarcophagus Puzzle (⭐⭐⭐)** — OPTIONAL. Open the sarcophagi to find burial goods and lore. Teaches heavy object manipulation (lift lid) and exploration rewards. Some sarcophagi contain treasures, some contain only bones, one contains the tome with critical lore.

**Design Rationale:**
- **Lore repository:** This room exists to tell the manor's backstory. The tome and inscriptions reveal who built the manor, why it was abandoned, and what secrets it holds.
- **Reward for exploration:** Only accessible if player finds the silver key in the deep cellar and unlocks the archway. High-effort, high-reward.
- **Atmospheric climax:** The crypt is the deepest, oldest, most mysterious space in Level 1. Reaching it feels like uncovering a secret.

---

## Puzzle Overview

### Existing Puzzles (All 🟢 In Game)

| ID | Name | Room | Difficulty | Pattern | Status |
|----|------|------|------------|---------|--------|
| 001 | Light the Room | Bedroom | ⭐⭐ | Discovery + Sensory + Compound Tools | 🟢 In Game |
| 002 | Poison Bottle | Bedroom | ⭐⭐ | Sensory + Hazard Identification | 🟢 In Game |
| 003 | Write in Blood | Bedroom | ⭐⭐ | Creative Tool Use + Self-Harm | 🟢 In Game |
| 004 | Inventory Management | Bedroom | ⭐⭐ | Constraint Puzzle | 🟢 In Game |
| 005 | Bedroom Escape | Bedroom | ⭐⭐⭐ | Meta-Puzzle (combines 001-004) | 🟢 In Game |
| 006 | Iron Door Unlock | Cellar | ⭐⭐ | Lock-and-Key | 🟢 In Game |
| 007 | Trap Door Discovery | Bedroom | ⭐⭐ | Spatial Manipulation | 🟢 In Game |
| 008 | Window Escape | Bedroom → Courtyard | ⭐⭐⭐⭐ | Alternate Path + Risk/Consequence | 🟢 In Game |

### New Puzzles Needed (All 🔴 Theorized)

| ID | Name | Room | Difficulty | Pattern | What It Teaches |
|----|------|------|------------|---------|-----------------|
| 009 | Crate Puzzle | Storage Cellar | ⭐⭐ | Container Hierarchy + Breaking | Nested containers, tool use (crowbar), finding hidden keys |
| 010 | Light Upgrade | Storage Cellar | ⭐⭐ | Resource Combination | OPTIONAL. Combining objects (lantern + oil) for better tools |
| 011 | Ascent to Manor | Deep Cellar → Hallway | ⭐⭐ | Navigation | Vertical navigation (stairs up), progression signaling |
| 012 | Altar Puzzle | Deep Cellar | ⭐⭐⭐ | Environmental Interaction | OPTIONAL. Symbolic actions (place offering), unlocking secrets |
| 013 | Courtyard Entry | Courtyard → Manor | ⭐⭐⭐⭐ | Alternate Path | OPTIONAL. Re-entry after window escape (locked doors, climbing) |
| 014 | Sarcophagus Puzzle | Crypt | ⭐⭐⭐ | Heavy Object Manipulation | OPTIONAL. Opening heavy lids, finding treasures and lore |

### Puzzle Progression Map

**Critical Path (Required to Complete Level 1):**
1. **Bedroom:** Puzzles 001 (Light) → 007 (Trap Door) → 006 (Get Key) → 005 (Escape)
2. **Cellar:** Puzzle 006 (Unlock Door)
3. **Storage Cellar:** Puzzle 009 (Find Iron Key)
4. **Deep Cellar:** Puzzle 011 (Ascend to Hallway)
5. **Hallway:** Exit to Level 2

**Optional Branches:**
- **Window Escape Branch:** Puzzle 008 (Break Window) → Courtyard → Puzzle 013 (Re-enter Manor)
- **Crypt Branch:** Puzzle 012 (Altar Offering) → Crypt → Puzzle 014 (Open Sarcophagi)

### Puzzle Density by Room

| Room | Total Puzzles | Required | Optional |
|------|---------------|----------|----------|
| Bedroom | 8 | 4 | 4 |
| Cellar | 1 | 1 | 0 |
| Storage Cellar | 2 | 1 | 1 |
| Deep Cellar | 2 | 1 | 1 |
| Courtyard | 1 | 0 | 1 |
| Crypt | 1 | 0 | 1 |
| Hallway | 0 | 0 | 0 |
| **TOTAL** | **15** | **8** | **7** |

**Design Philosophy:** Front-load complexity in the bedroom (teaching), then taper off. Later rooms are simpler but deeper (narrative focus).

---

## Object Requirements

### Objects by Room (New Objects Only)

#### Storage Cellar (8-10 new objects)
- **large-crate** — Container, breakable, heavy, contains nested objects
- **small-crate** — Container, breakable, lighter, can stack on large crate
- **grain-sack** — Container, heavy, contains grain (consumable?) and potentially key
- **wine-rack** — Furniture, immovable, holds wine bottles
- **wine-bottle** — Container, breakable, contains wine or oil
- **rope-coil** — Tool, enables tying/climbing actions
- **iron-key** — Key object, unlocks deep cellar door
- **oil-lantern** — Light source object, requires oil to function
- **crowbar** — Tool, enables breaking/prying actions
- **rat** (optional) — Creature, ambient, flees when disturbed

#### Deep Cellar (6-8 new objects)
- **stone-altar** — Furniture, immovable, central object, inscribed
- **unlit-sconce** — Furniture, wall fixture, accepts torch/candle
- **incense-burner** — Container, on altar, contains ash
- **tattered-scroll** — Readable object, lore text
- **silver-key** — Key object, unlocks crypt archway
- **stone-sarcophagus** — Container, heavy, immovable (in this room, not crypt)
- **offering-bowl** — Container, on altar, accepts objects
- **chain** (optional) — Pullable object, triggers mechanism?

#### Hallway (4-6 new objects)
- **torch-lit** — Light source, in wall bracket, removable
- **portrait** — Decorative object, examinable, reveals lore
- **side-table** — Furniture, surface, holds decorative objects
- **vase** — Decorative object, breakable
- **locked-door** — Exit object (not accessible in Level 1)

#### Courtyard (4-6 new objects)
- **stone-well** — Furniture, container (water), immovable
- **well-bucket** — Container, on rope, raises/lowers
- **ivy** — Environmental object, climbable or decorative
- **cobblestone** — Takeable object (loose stone), tool/weapon
- **wooden-door** — Exit object, locked
- **rain-barrel** — Container, holds water

#### Crypt (6-8 new objects)
- **stone-sarcophagus-1 through 5** — Containers, heavy lids, contain remains/treasures
- **effigy** — Decorative object (part of sarcophagus), examinable
- **candle-stub** — Consumable light source, old, still usable
- **skull** — Decorative object, remains
- **burial-jewelry** — Treasure object, takeable
- **burial-coins** — Treasure object, takeable
- **tome** — Readable object, lore book (critical)
- **silver-dagger** — Tool/weapon object
- **wall-inscription** — Examinable object (text)

**Total New Objects Needed:** ~40-50 (across 5 new rooms)

---

## Player Progression

### Intended Path (Critical Path)

**Phase 1: Orientation & Learning (Bedroom — 10-15 min)**
1. Player wakes in darkness
2. Learns FEEL, SMELL, LISTEN verbs through fumbling
3. Finds nightstand, discovers matchbox and candle
4. Solves Puzzle 001 (Light the Room) — first victory
5. Explores lit bedroom, discovers objects and dangers (poison bottle)
6. Experiments with tools (knife, pen, needle)
7. Discovers rug, moves it, reveals trap door (Puzzle 007)
8. Finds brass key under rug
9. Opens trap door, descends to cellar

**Phase 2: Descent & Exploration (Cellar & Storage Cellar — 5-10 min)**
10. Navigates dark cellar (light source may be running low — tension)
11. Encounters locked iron door (Puzzle 006)
12. Uses brass key to unlock door, enters storage cellar
13. Explores storage room, discovers crates and supplies
14. Solves Puzzle 009 (Crate Puzzle) — finds iron key in nested containers
15. (Optional) Finds oil lantern, upgrades light source (Puzzle 010)
16. Uses iron key to unlock deep cellar door

**Phase 3: Revelation & Emergence (Deep Cellar & Hallway — 5-10 min)**
17. Enters deep cellar, notices architectural change (older, grander)
18. Examines altar, reads scroll, learns manor's history (lore)
19. (Optional) Solves Puzzle 012 (Altar Puzzle), unlocks crypt
20. (Optional) Explores crypt, opens sarcophagi (Puzzle 014), finds tome
21. Ascends stairway from deep cellar to hallway (Puzzle 011)
22. Emerges into warm, lit hallway — relief and accomplishment
23. Examines portraits, absorbs lore
24. Proceeds north to Level 2

**Alternate Path 1: Window Escape (Risk-takers)**
- From Bedroom: Puzzle 008 (Window Escape) → Courtyard → Puzzle 013 (Re-entry) → Manor ground floor
- **Consequence:** Dangerous, possible injury, but rewards with alternate lore and items
- **Rejoins:** Main path at hallway or manor ground floor (Level 2 entry)

**Alternate Path 2: Direct to Hallway (If oak door is unlocked)**
- From Bedroom: NORTH through oak door → Hallway → Level 2
- **Design Note:** This shortcut bypasses all cellars. Wayne must decide if oak door is locked by default or if player needs a key (which key? where?). Recommend: door is locked, key is in deep cellar (forces critical path).

### Skills Learned in Order

1. **Sensory Navigation** (Bedroom, dark phase) — FEEL, SMELL, LISTEN
2. **Container Interaction** (Bedroom, nightstand) — OPEN, CLOSE, TAKE FROM
3. **Tool Usage** (Bedroom, matchbox) — STRIKE match ON matchbox
4. **Light Sources** (Bedroom, candle) — LIGHT candle WITH match
5. **Inventory Constraints** (Bedroom, multiple objects) — 2-hand limit, weight
6. **Spatial Manipulation** (Bedroom, rug) — MOVE rug, reveal hidden
7. **Lock-and-Key** (Cellar, iron door) — UNLOCK door WITH key
8. **Nested Containers** (Storage Cellar, crates) — Crate → sack → key
9. **Breaking Objects** (Storage Cellar, crate) — BREAK crate WITH crowbar
10. **Resource Upgrading** (Storage Cellar, lantern) — Combine objects for better tools
11. **Environmental Storytelling** (Deep Cellar, altar) — Examine to learn lore
12. **Heavy Object Manipulation** (Crypt, sarcophagus) — LIFT lid, PUSH lid
13. **Vertical Navigation** (Deep Cellar to Hallway) — UP stairs, DOWN stairs

### Critical Path vs. Optional Exploration

**Critical Path Objects (Required):**
- Matchbox, matches, candle (light)
- Brass key (cellar door)
- Iron key (deep cellar door)
- Rug (hides trap door)
- Trap door (exit to cellars)

**Optional Objects (Enhance experience, not required):**
- Poison bottle (teaches caution, not required)
- Knife, needle, thread (crafting/self-harm, optional puzzles)
- Rope, crowbar (tools for alternate solutions)
- Oil lantern (upgrade, not required if candle still lit)
- Silver key, crypt contents (lore and treasures, optional)

**Pacing Philosophy:** The critical path should take 20-30 minutes for a new player. Optional content adds 10-15 minutes. Total playtime: 30-45 minutes for completionists.

---

## Level 1 Completion Criteria

### Primary Victory Condition

**Player completes Level 1 when they reach the Hallway via the main staircase from the Deep Cellar.**

At this point:
- Player has navigated all critical-path rooms
- Player has solved all required puzzles (001, 006, 007, 009, 011)
- Player has learned all core systems
- Player has transitioned from "trapped prisoner" to "active explorer"

**Transition to Level 2:** From the hallway, the player proceeds NORTH (through a door, up a grand staircase, or down a corridor) to enter the manor proper. A clear message signals the transition: "You have completed the cellars. The manor awaits."

### Alternate Victory Condition

**Player completes Level 1 when they reach the Hallway via the courtyard re-entry (Puzzle 013) after window escape.**

This is a riskier, non-canonical path that bypasses the cellars entirely. The player still reaches the hallway, but via a different route. Wayne must decide if this path grants the same lore/items as the cellar path, or if it's a "shortcut with consequences" (faster but less complete).

### Failure Conditions (Wayne to decide)

**Soft Failures (Recoverable):**
- Waste all matches → wait for dawn (time passes, but player can still proceed)
- Lose the brass key → search for alternate key or break the cellar door (harder but possible)
- Lose the iron key → break the deep cellar door or find alternate path

**Hard Failures (Unwinnable — should be AVOIDED per design philosophy):**
- Player permanently locks themselves out of a required room with no recovery
- **RECOMMENDATION:** No hard failures in Level 1. Every mistake should have a recovery path, even if it's tedious or costly.

### Success Indicators

When the player reaches the hallway, the game should provide clear feedback:
- **Atmospheric shift:** Warmer air, brighter light, cleaner space
- **Narrative acknowledgment:** "You have escaped the cellars. The air here is warmer, the light steadier. You are no longer trapped — only lost."
- **Mechanical signal:** New exits become available, old exits close (trap door behind you, new doors ahead)
- **Lore revelation:** Portraits in hallway provide context: "These are the faces of the manor's former residents. Their eyes follow you."

---

## Design Principles for Level 1

### Core Design Tenets

1. **Tutorial Disguised as Mystery** — Every teaching moment must feel like discovery, not instruction.
2. **Sensory First** — Darkness is not a wall; FEEL, SMELL, LISTEN are first-class verbs.
3. **Real-World Logic** — Everything behaves as it would in reality. No arbitrary puzzles.
4. **No Softlocks** — Every mistake is recoverable. Failure teaches, not punishes.
5. **Layered Depth** — Critical path is simple; optional content rewards exploration.
6. **Atmosphere Through Scarcity** — Light is limited, space is confined, the player feels vulnerable.
7. **Environmental Storytelling** — Rooms tell stories without explicit exposition.
8. **Escalating Agency** — Player moves from helpless (dark bedroom) to empowered (exploring cellars with light and tools).

### Pacing Guidelines

**Density Curve:**
- **Bedroom:** DENSE (23 objects, 8 puzzles) — overwhelming but educational
- **Cellar:** SPARSE (2 objects, 1 puzzle) — breathing room, transition
- **Storage Cellar:** MODERATE (10 objects, 2 puzzles) — reinforcement
- **Deep Cellar:** NARRATIVE (8 objects, 2 puzzles) — story focus, less mechanics
- **Hallway:** MINIMAL (6 objects, 0 puzzles) — reward, transition

**Difficulty Curve:**
- **Early (Bedroom):** ⭐⭐ puzzles (teaching)
- **Middle (Cellars):** ⭐⭐ to ⭐⭐⭐ puzzles (reinforcement)
- **Optional:** ⭐⭐⭐⭐ puzzles (challenge for explorers)

**Emotional Curve:**
- **Confusion (Bedroom, dark):** Disorientation, fear, caution
- **Mastery (Bedroom, lit):** Control, confidence, curiosity
- **Tension (Cellars):** Darkness returns, resources depleting, locked doors
- **Revelation (Deep Cellar):** Mystery unfolds, lore discovered, purpose revealed
- **Relief (Hallway):** Warmth, light, safety, accomplishment

### Recommended Development Order

**Phase 1: Complete Critical Path**
1. Build Storage Cellar (Puzzle 009 — Crate Puzzle)
2. Build Deep Cellar (Puzzle 011 — Ascent to Manor)
3. Build Hallway (transition room, no puzzles)
4. **Milestone:** Player can complete critical path from Bedroom → Hallway

**Phase 2: Optional Content (Crypt Branch)**
5. Implement Puzzle 012 (Altar Puzzle) in Deep Cellar
6. Build Crypt room
7. Implement Puzzle 014 (Sarcophagus Puzzle) in Crypt
8. **Milestone:** Optional crypt exploration complete

**Phase 3: Alternate Path (Courtyard Branch)**
9. Build Courtyard room
10. Implement Puzzle 013 (Courtyard Entry)
11. Connect courtyard to hallway or manor ground floor
12. **Milestone:** Window escape path fully functional

**Phase 4: Polish & Testing**
13. Add ambient details (rats, dripping water, wind sounds)
14. Balance light source duration (candle vs. lantern)
15. Playtest all paths (critical, optional, alternate)
16. Tune difficulty based on playtester feedback

---

## Narrative & Lore Integration

### The Central Mystery (Level 1 Reveals)

**What the player discovers in Level 1:**
- The manor is abandoned (or appears to be)
- The bedroom was prepared for someone — the player? A prisoner? A guest?
- The cellars are older than the manor itself
- The deep cellar contains religious/occult symbols
- The crypt reveals the manor was built by a family who is now dead or missing
- The tome (if found) provides the first clues to the manor's true purpose

**What remains mysterious (for Level 2+):**
- Why is the player here?
- Who prepared the bedroom?
- Where are the manor's inhabitants?
- What is the significance of the altar and crypt?
- Is the manor haunted, cursed, or simply abandoned?

### Lore Delivery Methods

**Inscriptions & Text:**
- Tattered scroll (deep cellar) — describes the manor's founding
- Tome (crypt) — reveals the family's history and their dark secret
- Wall inscriptions (crypt) — names, dates, blessings or curses
- Portraits (hallway) — faces and names of the manor's residents

**Environmental Storytelling:**
- Object placement (bedroom staged like a cell)
- Architectural changes (manor → old cellar → ancient crypt)
- Material decay (fresh bedroom, dusty storage, ancient crypt)
- Sensory clues (incense in deep cellar, lavender in bedroom)

**Object Descriptions:**
- Sarcophagus effigies (crypt) — reveal who is buried and when
- Altar symbols (deep cellar) — religious or occult iconography
- Burial goods (crypt) — items that reveal the family's status and beliefs

---

## Handoff Notes for Team

### For Moe (World Builder)

**Your tasks:**
1. Build 5 new room files: `storage-cellar.lua`, `deep-cellar.lua`, `hallway.lua`, `courtyard.lua`, `crypt.lua`
2. Use `start-room.lua` and `cellar.lua` as templates for structure
3. Follow the room summaries above for descriptions, mood, and connections
4. Reference `docs/design/rooms/room-design-research.md` for best practices
5. Coordinate with Flanders on object IDs and placement

**Key design notes:**
- Every room must work in darkness (provide FEEL, SMELL, LISTEN descriptions)
- Exits must be clearly described (both locked and unlocked states)
- Rooms should feel like real places with history, not game levels

### For Bob (Puzzle Master)

**Your tasks:**
1. Formalize Puzzles 009-014 (currently 🔴 Theorized → 🟡 Wanted)
2. Create puzzle docs in `docs/puzzles/` following the template
3. Specify exact solution paths, failure modes, and object requirements
4. Coordinate with Flanders on object properties needed for each puzzle
5. Ensure puzzles are GOAP-compatible where appropriate

**Key design notes:**
- Puzzles 009 and 011 are critical path — must be solvable by all players
- Puzzles 010, 012, 013, 014 are optional — can be harder and more obscure
- Every puzzle should teach or reinforce a game system
- No softlocks — every failure must have a recovery path

### For Flanders (Object Designer)

**Your tasks:**
1. Create ~40-50 new objects for the 5 new rooms
2. Follow object lists in "Object Requirements" section above
3. Use existing objects (candle, matchbox, key) as templates for new objects
4. Ensure all objects have complete sensory descriptions (FEEL, SMELL, LISTEN, TASTE)
5. Implement FSM states where needed (e.g., lantern unlit/lit)
6. Coordinate with Bob on puzzle-specific object behaviors

**Key design notes:**
- Objects must be grounded in real-world logic (no magic unless explained)
- Every object should be interactable in darkness (FEEL is mandatory)
- Tools should have clear capabilities (rope enables CLIMB, crowbar enables BREAK)
- Containers should have realistic capacity constraints (weight, size)

### For Nelson (Tester)

**Your tasks (after implementation):**
1. Test critical path (Bedroom → Cellar → Storage → Deep → Hallway)
2. Test alternate path (Bedroom → Window → Courtyard → Manor)
3. Test optional content (Crypt branch)
4. Verify all puzzles are solvable and have recovery paths
5. Check for softlocks, dead ends, and unwinnable states
6. Test edge cases (waste all matches, lose keys, break windows, etc.)
7. Provide difficulty feedback (are puzzles too hard/easy?)

**Key design notes:**
- Level 1 should take 20-45 minutes for first-time players
- No puzzle should be impossible to solve without outside help
- Every failure should provide feedback guiding the player to recovery

---

## Appendix: Quick Reference Tables

### Room Summary Table

| # | Room Name | Status | Objects | Puzzles | Connections | Difficulty |
|---|-----------|--------|---------|---------|-------------|------------|
| 1 | Bedroom | 🟢 Built | 23 | 8 | Hallway (N), Cellar (D), Courtyard (W) | ⭐⭐⭐ |
| 2 | Cellar | 🟢 Built | 2 | 1 | Bedroom (U), Storage (N) | ⭐⭐ |
| 3 | Storage Cellar | 🔴 New | 10 | 2 | Cellar (S), Deep (N) | ⭐⭐ |
| 4 | Deep Cellar | 🔴 New | 8 | 2 | Storage (S), Hallway (U), Crypt (W) | ⭐⭐⭐ |
| 5 | Hallway | 🔴 New | 6 | 0 | Deep (D), Bedroom (S), Level 2 (N) | ⭐ |
| 6 | Courtyard | 🔴 New | 6 | 1 | Bedroom (U), Kitchen (?) | ⭐⭐⭐⭐ |
| 7 | Crypt | 🔴 New | 8 | 1 | Deep (E) | ⭐⭐⭐ |

### Puzzle Summary Table

| ID | Name | Room | Difficulty | Status | Type |
|----|------|------|------------|--------|------|
| 001 | Light the Room | Bedroom | ⭐⭐ | 🟢 Built | Core |
| 002 | Poison Bottle | Bedroom | ⭐⭐ | 🟢 Built | Optional |
| 003 | Write in Blood | Bedroom | ⭐⭐ | 🟢 Built | Optional |
| 004 | Inventory Management | Bedroom | ⭐⭐ | 🟢 Built | Core |
| 005 | Bedroom Escape | Bedroom | ⭐⭐⭐ | 🟢 Built | Core |
| 006 | Iron Door Unlock | Cellar | ⭐⭐ | 🟢 Built | Core |
| 007 | Trap Door Discovery | Bedroom | ⭐⭐ | 🟢 Built | Core |
| 008 | Window Escape | Bedroom | ⭐⭐⭐⭐ | 🟢 Built | Optional |
| 009 | Crate Puzzle | Storage | ⭐⭐ | 🔴 New | Core |
| 010 | Light Upgrade | Storage | ⭐⭐ | 🔴 New | Optional |
| 011 | Ascent to Manor | Deep → Hallway | ⭐⭐ | 🔴 New | Core |
| 012 | Altar Puzzle | Deep | ⭐⭐⭐ | 🔴 New | Optional |
| 013 | Courtyard Entry | Courtyard | ⭐⭐⭐⭐ | 🔴 New | Optional |
| 014 | Sarcophagus Puzzle | Crypt | ⭐⭐⭐ | 🔴 New | Optional |

### Object Count by Room

| Room | Existing | New Needed | Total |
|------|----------|------------|-------|
| Bedroom | 23 | 0 | 23 |
| Cellar | 2 | 0 | 2 |
| Storage Cellar | 0 | 10 | 10 |
| Deep Cellar | 0 | 8 | 8 |
| Hallway | 0 | 6 | 6 |
| Courtyard | 0 | 6 | 6 |
| Crypt | 0 | 8 | 8 |
| **TOTALS** | **25** | **38** | **63** |

---

## Wayne's Decision Points

The following design questions require Wayne's input before finalization:

### Critical Decisions

1. **Oak Door (Bedroom → Hallway):** Is it locked by default, or open? If locked, where is the key? (Recommend: locked, key in deep cellar to force cellar exploration)

2. **Courtyard Access:** Should window escape be lethal by default, or merely injurious? Should rope from storage cellar enable safe descent? (Recommend: injurious but survivable with consequences)

3. **Crypt Purpose:** What is the manor's dark secret revealed in the crypt? (Cultists? Cursed family? Ancient order?) This shapes the tome's text and the altar's symbolism.

4. **Level 2 Preview:** What does the player glimpse when they reach the hallway? Locked rooms? Upper floors? NPCs? (This sets expectations for Level 2)

5. **Resource Scarcity:** Should candle duration be tuned so it runs out mid-cellars, forcing the player to find the lantern? Or should it last through Level 1? (Recommend: tight but sufficient for critical path; optional content requires lantern)

### Optional Decisions

6. **Rat Behavior:** Should rats in storage cellar be interactive (catchable, tameable) or purely atmospheric?

7. **Burial Goods Value:** Should items in crypt have gameplay value (silver dagger as weapon) or only lore value?

8. **Altar Mechanism:** What does placing an offering on the altar actually do? Unlock crypt? Reveal hidden text? Summon something?

9. **Hallway Portraits:** Should portraits be just flavor, or interactive (examine reveals detailed lore, pull reveals secret passage)?

10. **Time Progression:** Does game time pass during Level 1? If so, does dawn break at 6 AM and provide natural light through bedroom window?

---

## Version History

**v1.0 (2026-07-21):** Initial master design document. Covers all 7 rooms, 15 puzzles, narrative arc, progression paths, and object requirements. Ready for team review and room/puzzle design phase.

---

**END OF DOCUMENT**

*"Worst. Tutorial level. Ever. (Except for all the others.)" — Comic Book Guy*
