# Level 1 — Courtyard Objects

**Room:** The Inner Courtyard / The Manor Yard  
**Room ID:** `courtyard`  
**Author:** Flanders (Object Designer)  
**Date:** 2026-07-21  
**Status:** Specification — Ready for Build  
**Source:** `docs/levels/level-01-intro.md` (CBG Master Design)

---

## Room Context

A small, cobblestone courtyard enclosed by the manor's walls. Open to the sky — stars visible, moonlight casting shadows. A stone well stands at the center. Ivy climbs the walls. The air smells of rain and chimney smoke. The bedroom window is visible far above — a dangerous drop. This room is **optional** — only accessible via the window escape (Puzzle 008).

**Connections:**
- WINDOW (up) → Bedroom (if player broke/opened bedroom window — dangerous climb)
- DOOR → Kitchen or Servants' Hall (locked — could connect to manor ground floor, TBD)

**Puzzle Support:**
- **Puzzle 013 (Courtyard Entry):** Optional. Player reaches courtyard via window escape, must find a way to enter the manor from outside.

**Total Objects:** 6 new base objects

**New Materials Needed:**
- `stone` — for stone-well, cobblestone (needed by Deep Cellar spec too — shared entry)

---

## Object 1: stone-well

### Identity
| Field | Value |
|-------|-------|
| **id** | `stone-well` |
| **name** | "a stone well" |
| **keywords** | well, stone well, water well, wishing well, well shaft |
| **categories** | furniture, stone, container |
| **weight** | — (architectural, immovable) |
| **size** | 6 (massive — stone ring about four feet across) |
| **portable** | No |

### Material
`stone` — ⚠️ **NEW MATERIAL NEEDED.** (Same entry as stone-altar/sarcophagus.)

### FSM States & Transitions
None — static object. The well itself doesn't change. The bucket is the interactive element.

### Sensory Properties

| Sense | Description |
|-------|-------------|
| description | A stone well stands at the center of the courtyard — a low ring of moss-covered granite, about four feet across, with a wooden crossbeam and a rusted iron winding handle. A frayed rope descends into darkness. When you lean over the edge, you can see nothing — only black. But you can hear water, far below. |
| on_feel | Cold, rough stone, slimy with moss on the outside. The rim is worn smooth on top from centuries of hands and elbows. The crossbeam is weathered wood. The winding handle is cold iron, rough with rust. |
| on_smell | Damp stone and moss. A breath of cool, mineral-scented air rises from the shaft — underground water, clean and old. |
| on_listen | Water. Distant, echoing. A drip... then silence... then another drip. The sound bounces up the stone shaft like a whispered secret. |
| on_taste | (If player licks the stone:) Wet granite, moss, and mineral water. Cold. |

### Surfaces
```lua
surfaces = {
    top = {  -- the rim
        capacity = 2, max_item_size = 2, weight_capacity = 10,
        contents = {},
        accessible = true,
    },
    inside = {  -- the well shaft — special: extremely deep, contains water
        capacity = 1, max_item_size = 3, weight_capacity = 50,
        contents = {"well-bucket-1"},  -- bucket hangs on rope inside
        accessible = true,
    },
}
```

**Special note:** Dropping objects INTO the well should produce a splash message and make the object irretrievable (fell into deep water). This would be a guard or `on_transition` behavior: items dropped into the well's `inside` surface beyond the bucket are lost.

### Spatial Context
- **Location:** Center of the courtyard
- **room_presence:** "A stone well stands at the courtyard's center, its crossbeam dark against the stars."

### Puzzle Role
- **Puzzle 013 (Courtyard Entry):** The well could conceal a key or passage (Wayne TBD). At minimum, it provides water (via bucket) for various uses.
- **Environmental detail:** The well is the courtyard's defining feature — it grounds the space.

### Principle 8 Compliance
Static furniture with surfaces. Special "drop into well" behavior declared as container metadata with a depth/loss-on-drop flag.

---

## Object 2: well-bucket

### Identity
| Field | Value |
|-------|-------|
| **id** | `well-bucket` |
| **name** | "a wooden bucket" |
| **keywords** | bucket, well bucket, pail, wooden bucket, water bucket |
| **categories** | container, wooden, tool |
| **weight** | 2 (kg — empty wooden bucket with iron bands) |
| **size** | 3 (medium) |
| **portable** | Yes (if detached from rope) |

### Material
`wood` — ✓ In registry. Oak staves with iron bands. Attached to well rope.

### FSM States & Transitions

```
raised-empty → lowered → raised-full
                           ↓ (pour/empty)
                       raised-empty
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell | on_listen |
|-------|--------------------|--------------------|----------|-----------|
| raised-empty | A wooden bucket hangs from the well's crossbeam by a frayed rope. It's empty, dry inside, with dark water stains marking past use. The iron bands are rusted but intact. | A wooden bucket, round, iron-banded. Empty inside — dry and rough. The rope above is frayed hemp, damp. | Old wood and hemp rope. | The rope creaks against the crossbeam when the bucket swings. |
| lowered | The bucket has been lowered into the well. The rope unspools from the winding handle, creaking and groaning. You can hear the bucket splash far below. | The rope is taut and wet where it emerges from the shaft. The winding handle is cold. | Damp air rising from the shaft. | A distant splash, then dripping. The bucket is in the water. |
| raised-full | A wooden bucket, brimming with cold, dark water. Droplets trace down the iron bands. The rope is taut with the weight. | Heavy now — the water sloshes inside. The wood is wet and cold. The iron bands are slippery. | Fresh water — clean, mineral, cold. Like underground stone. | Water sloshes and drips. |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| raised-empty | lowered | lower, drop, send down | — | "You turn the winding handle. The rope unspools with a rhythmic creak, and the bucket descends into darkness. A long pause... then a distant splash echoes up the shaft." | — |
| lowered | raised-full | raise, pull up, wind up, crank | — | "You crank the handle. The rope tightens and strains. Slowly, the bucket rises — heavy with water. It clears the rim, dripping and full. Cold, dark water nearly to the brim." | `weight = function(w) return w + 8 end` |
| raised-full | raised-empty | pour, empty, dump, tip | — | "You upend the bucket. Cold water splashes across the cobblestones, darkening the stone and releasing a brief mineral scent." | `weight = 2, keywords = { remove = "full" }` |

**Note:** The bucket is attached to the well rope by default. The player could CUT the rope to detach the bucket (requires cutting_edge), making it a portable water container.

### Spatial Context
- **Location:** Hanging from the well's crossbeam (inside the well when raised)
- **room_presence:** Described as part of the well.

### GOAP Prerequisites
```lua
prerequisites = {
    pour = { requires_state = "raised-full" },
}
```

### Puzzle Role
- **Puzzle 013:** Could provide water for extinguishing fire, cleaning, or filling a container.
- **Utility:** Portable water source if detached from rope.

### Principle 8 Compliance
Three-state FSM. Weight changes via mutate on raise (adds water weight). All behavior in metadata.

---

## Object 3: ivy

### Identity
| Field | Value |
|-------|-------|
| **id** | `ivy` |
| **name** | "thick ivy" |
| **keywords** | ivy, vines, vine, climbing ivy, creeper, plant, growth |
| **categories** | environmental, plant |
| **weight** | — (attached to wall, immovable) |
| **size** | 6 (massive — covers entire wall face) |
| **portable** | No |

### Material
None — living plant. Not a manufactured object.

### FSM States & Transitions

```
growing → climbed (player used it to climb)
growing → torn (player tore some off)
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell | on_listen |
|-------|--------------------|--------------------|----------|-----------|
| growing | Thick, dark ivy blankets the manor's east wall from ground to roofline. The stems are as thick as your wrist at the base, woody and gnarled from decades of growth. Leaves rustle faintly in the night air. Higher up, near the bedroom window, the ivy thins — but it looks climbable. Maybe. | Thick stems, rough and woody. Leaves — smooth on top, rough underneath. The vine grips the stonework tightly. You can tug it — it holds. Strong, but how strong? | Green and vegetal. Crushed leaf smell when you grip. Damp earth at the base. | Leaves whisper in the breeze. Insects rustle in the deeper growth. |
| climbed | The ivy has been climbed — broken leaves and snapped tendrils mark a rough path up the wall. The vine still holds, but it's damaged. | Broken stems, snapped tendrils. The vine is weaker where climbed — some stems have pulled free from the stone. | Crushed green sap. Damaged plant. | Wind through damaged leaves. |
| torn | A section of ivy has been ripped from the wall, exposing bare stone and leaving a trail of broken stems and torn roots. | Bare stone where the ivy was. Loose stems and leaves in your hand. | Strong green sap, torn roots, damp stone. | — |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| growing | climbed | climb | guard: player has rope (safe) OR no rope (risky, injury chance) | (With rope:) "You loop the rope around a thick stem and haul yourself up. The ivy groans but holds. Hand over hand, you climb — ten feet, fifteen, twenty. Your fingers find the bedroom windowsill." / (Without rope:) "You grab the ivy and climb. Halfway up, a stem snaps. You lunge, catch another — it holds. Barely. Your heart hammers as you reach the windowsill." | — |
| growing | torn | tear, pull, rip | — | "You grab a fistful of ivy and pull. It comes away from the wall with a ripping sound, trailing roots and mortar dust. A few feet of woody vine in your hands." | — (spawns ivy-strand, a rope-like tool) |

**Notes on Climbing:**
- Climbing UP the ivy from the courtyard to the bedroom window is the reverse of the window escape.
- With rope: safe climb. Without rope: risky — possible injury (fall damage, per Wayne's decision on Puzzle 013).
- The guard function checks for rope tool capability.
- Climbing from courtyard to bedroom requires the window to be already broken/open.

### Spatial Context
- **Location:** East wall of courtyard, from ground to bedroom window
- **room_presence:** "Thick ivy blankets the east wall, climbing to the bedroom window far above."

### Puzzle Role
- **Puzzle 013 (Courtyard Entry):** Primary interaction. Player climbs ivy to re-enter the bedroom (or uses rope + ivy for safe climb).
- **Alternative:** Tear ivy for a rope-like tool if player doesn't have rope.

### Principle 8 Compliance
FSM states for climbed/torn. Guard function checks tool capability. Spawn behavior (ivy-strand) declared in transition metadata.

---

## Object 4: cobblestone

### Identity
| Field | Value |
|-------|-------|
| **id** | `cobblestone` |
| **name** | "a loose cobblestone" |
| **keywords** | cobblestone, stone, rock, paving stone, cobble, loose stone |
| **categories** | tool, stone, weapon |
| **weight** | 2 (kg) |
| **size** | 2 (small — fist-sized) |
| **portable** | Yes |

### Material
`stone` — ⚠️ **NEW MATERIAL NEEDED.** (Same entry as altar/well.)

### FSM States & Transitions
None — static object.

### Sensory Properties

| Sense | Description |
|-------|-------------|
| description | A cobblestone has worked loose from the courtyard floor, leaving a dark gap in the paving. It's roughly the size of your fist — rounded on top, flat on the bottom, worn smooth by feet and weather. Heavy for its size. |
| on_feel | Smooth on top from centuries of foot traffic. Rough and flat on the bottom. Heavy, dense stone — it fills your palm solidly. Cool and slightly damp. |
| on_smell | Wet stone and earth. |

### Tool Capabilities
```lua
provides_tool = {"blunt_weapon", "weight", "hammer"},
```
- `blunt_weapon` — STRIKE, THROW at targets
- `weight` — weigh down objects, break things by dropping
- `hammer` — pound, smash (crude but effective)

### Spatial Context
- **Location:** Courtyard floor, near the well. One stone is loose.
- **room_presence:** "One cobblestone near the well has worked loose, leaving a dark gap."

### Puzzle Role
- **Puzzle 013:** Could be thrown to break a window for re-entry, or used as a tool/weapon.
- **General utility:** Improvised blunt instrument.

### Principle 8 Compliance
Static tool object with `provides_tool` capabilities. Standard metadata.

---

## Object 5: wooden-door

### Identity
| Field | Value |
|-------|-------|
| **id** | `wooden-door` |
| **name** | "a heavy wooden door" |
| **keywords** | door, wooden door, kitchen door, servants door, back door |
| **categories** | architecture, wooden |
| **weight** | — (architectural, immovable) |
| **size** | 6 (massive) |
| **portable** | No |

### Material
`oak` — ✓ In registry. Heavy oak planks, iron-banded, with a simple latch and lock.

### FSM States & Transitions

```
locked → unlocked → open
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell | on_listen |
|-------|--------------------|--------------------|----------|-----------|
| locked | A heavy wooden door set into the manor's ground-floor wall. Iron bands cross it, and a large iron latch holds it shut. The lock is a simple keyhole type — but you don't have the key. Through the gaps, you smell cooking fires and stale food. | Heavy oak planks, iron bands. The latch doesn't move — locked. A keyhole, large and simple. Cold iron. | Through the gaps: old cooking smoke, stale bread, grease. A kitchen? | Silence beyond. No one home. |
| unlocked | The door's latch lifts freely now. Push to open. | The latch moves. The door shifts in its frame. | Same kitchen smells, stronger. | A creak from the hinges. |
| open | The door stands open, revealing a dark corridor leading into the manor's service areas. Cold air drifts through. | The door is ajar. Beyond: stone floor, cooler air. | Kitchen smells: stale food, cold hearth, old grease. | Distant dripping. The manor's plumbing. |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| locked | unlocked | unlock | TBD — requires a specific key OR can be forced | "The lock clicks and the latch frees. The door is unlocked." | `keywords = { add = "unlocked" }` |
| locked | locked | break, force | `requires_tool = "prying_tool"` or `"blunt_weapon"` — but very hard | "The door shudders but holds. These iron bands are serious. You'd need something stronger — or the right key." | — |
| unlocked | open | open, push | — | "You push the door open. It swings inward with a long groan, revealing a dark corridor. The smell of a cold kitchen drifts out." | `keywords = { add = "open" }` |

**Design note:** How the player unlocks this door is TBD (Wayne/Bob). Options: a key found in the courtyard, picking the lock, or forcing it with sufficient tool capabilities. This connects to Puzzle 013.

### Spatial Context
- **Location:** North wall of courtyard, leading to the manor's service areas
- **room_presence:** "A heavy wooden door is set into the north wall, leading into the manor."

### Puzzle Role
- **Puzzle 013 (Courtyard Entry):** One of the potential re-entry points. Player must unlock or force this door to enter the manor from the courtyard.

### Principle 8 Compliance
Three-state FSM with tool requirements. Behavior declared in metadata.

---

## Object 6: rain-barrel

### Identity
| Field | Value |
|-------|-------|
| **id** | `rain-barrel` |
| **name** | "a rain barrel" |
| **keywords** | barrel, rain barrel, water barrel, cask, tub |
| **categories** | container, wooden, furniture |
| **weight** | 40 (kg — full of water; 10 kg empty) |
| **size** | 5 (large) |
| **portable** | No (too heavy when full) |

### Material
`wood` — ✓ In registry. Oak staves with iron hoops. Standard barrel construction.

### FSM States & Transitions

```
full → half-full → empty
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell | on_listen |
|-------|--------------------|--------------------|----------|-----------|
| full | A large wooden barrel stands under a downspout, brimming with dark rainwater. Dead leaves float on the surface. The water reflects the stars. | Wooden staves, iron hoops. The water inside is cold — shockingly cold. Your hand breaks the surface and the chill runs up your arm. | Clean rainwater, old wood, a hint of iron from the hoops. Leaf decay. | Water sloshes against the sides when you touch the barrel. |
| half-full | The rain barrel is about half full. The water level has dropped, revealing a dark ring of algae on the inner staves. | Wooden staves. Water lower now — you have to reach further in. Still cold. | Damp wood, stale water, faint algae. | A hollow slosh when bumped. |
| empty | The rain barrel is empty. The inside is dark and slimy with old algae. Mosquito larvae twitch in a shallow puddle at the bottom. | Wooden staves, slimy inside. Damp at the bottom. | Stagnant water residue. Rot. | A hollow boom when tapped. |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| full | half-full | fill (bucket), scoop, take water | Player uses container to take water | "You dip the [container] into the barrel. Cold water fills it, and the barrel's level drops noticeably." | `weight = function(w) return w - 15 end` |
| half-full | empty | fill (bucket), scoop, take water | — | "You scoop the last of the water from the barrel. It gurgles and drains to a shallow puddle at the bottom." | `weight = 10, keywords = { add = "empty" }` |

### Surfaces
```lua
surfaces = {
    inside = {
        capacity = 1, max_item_size = 2, weight_capacity = 5,
        contents = {},  -- water is a fluid, not an object
        accessible = true,
    },
}
```

### Spatial Context
- **Location:** Against the south wall, under a downspout from the roof
- **room_presence:** "A rain barrel stands against the wall under a downspout, dark water brimming at the top."

### Puzzle Role
- **Puzzle 013:** Provides water for extinguishing fire, washing, or filling containers. Could be used to break a fall (jump into barrel from height?).
- **Utility:** Alternate water source to the well (easier to access).

### Principle 8 Compliance
Three-state depletion FSM. Weight changes via mutate. Container behavior in metadata.

---

## Object Interaction Map

```
                    Courtyard — Object Relationships

    [stone-well] ── contains ── [well-bucket]
         │                           │
         │                    lower/raise → water
         │
    [ivy] ── CLIMB (with/without rope) → bedroom window
         │
         └── TEAR → ivy-strand (improvised rope)
    
    [cobblestone] ── THROW → break window / weapon
    
    [wooden-door] ── UNLOCK (key?) → manor interior
    
    [rain-barrel] ── water source (scoop with bucket/container)
    
    CLIMB IVY ←── [rope-coil] from Storage Cellar makes it safe
```

---

## Summary

| # | Object | Material | FSM? | Portable | Puzzle |
|---|--------|----------|------|----------|--------|
| 1 | stone-well | stone ⚠️ NEW | No | No | 013 |
| 2 | well-bucket | wood ✓ | Yes (3 states) | Yes (if cut free) | 013 |
| 3 | ivy | — (plant) | Yes (3 states) | No | 013 (climbing) |
| 4 | cobblestone | stone ⚠️ NEW | No | Yes | 013 (tool) |
| 5 | wooden-door | oak ✓ | Yes (3 states) | No | 013 (entry) |
| 6 | rain-barrel | wood ✓ | Yes (3 states) | No | — (utility) |
