# Level 1 — Storage Cellar Objects

**Room:** The Storage Cellar / The Supply Room  
**Room ID:** `storage-cellar`  
**Author:** Flanders (Object Designer)  
**Date:** 2026-07-21  
**Status:** Specification — Ready for Build  
**Source:** `docs/levels/level-01-intro.md` (CBG Master Design)

---

## Room Context

A long, narrow cellar lined with wooden shelves and stacked crates. Dust coats everything. The air smells of old wood, stale grain, and decay. Cobwebs drape across corners. Faint scratching sounds suggest rats in the walls. Abandoned for years — supplies forgotten, left to rot.

**Connections:**
- SOUTH → Cellar (iron door — player just came through)
- NORTH → Deep Cellar (iron door — locked, requires iron key from this room)

**Puzzle Support:**
- **Puzzle 009 (Crate Puzzle):** Critical path. Find iron key hidden in nested containers: large-crate → grain-sack → iron-key. Requires crowbar to pry open crate.
- **Puzzle 010 (Light Upgrade):** Optional. Find oil-lantern + oil (in wine bottle), combine for better light source.

**Total Objects:** 10 new base objects

**New Materials Needed:**
- `hemp` — for rope-coil (not in current material registry)
- `burlap` — for grain-sack (not in current material registry; could use `fabric` as fallback)

---

## Object 1: large-crate

### Identity
| Field | Value |
|-------|-------|
| **id** | `large-crate` |
| **name** | "a large wooden crate" |
| **keywords** | crate, large crate, wooden crate, box, shipping crate |
| **categories** | container, wooden, furniture, breakable |
| **weight** | 25 (kg — heavy pine crate, nailed shut) |
| **size** | 5 (large) |
| **portable** | No |

### Material
`wood` — ✓ In registry. Pine planks, rough-hewn, nailed together with iron nails.

### FSM States & Transitions

```
sealed → pried-open → broken (terminal)
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell | on_listen |
|-------|--------------------|--------------------|----------|-----------|
| sealed | A large wooden crate, roughly four feet on a side. The lid is nailed shut with iron nails, rusted but firm. Stenciled letters on one side read "PROVISIONS" in faded ink. Dust lies thick on the top. | Heavy wooden planks, rough-sawn. Iron nail-heads along the seams, prickly with rust. The lid doesn't budge when you push — nailed fast. | Old wood and dust. Faintly sour, like grain gone stale. | Silent. Something shifts faintly inside when you thump it. |
| pried-open | The crate's lid has been wrenched off, splintered around the nail holes. Inside, a heavy sack of grain slumps against the walls, half-buried in straw packing and wood shavings. | Splintered wood edges around the opening. Inside: coarse fabric of a sack, loose straw, wood shavings. | Stale grain, sawdust, and the musty smell of long storage. | Faint rustling from the straw. |
| broken | The crate has been smashed apart. Splintered planks and bent nails litter the floor around a burst grain sack. | Splinters and broken planks. Sharp nail-ends — careful. | Grain dust, sawdust, damp wood. | Nothing. |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| sealed | pried-open | pry, open | `requires_tool = "prying_tool"` | "You jam the crowbar under the lid and heave. Nails shriek as they pull free, and the lid comes away in a shower of splinters and rust. Inside: a heavy sack nestled in straw packing." | `keywords = { add = "open" }` |
| sealed | pried-open | open | — (no tool) | — | — |
| pried-open | broken | break, smash | `requires_tool = "prying_tool"` OR `requires_tool = "blunt_weapon"` | "You bring the crowbar down hard. The crate shatters into splintered planks and bent nails. The contents spill across the floor." | `weight = 5, keywords = { add = "broken" }, categories = { remove = "container" }` |

**Fail Messages:**
- `open` without tool (sealed): "The lid is nailed shut. You'd need something to pry it open."
- `break` without tool (sealed): "The crate is solidly built. You'll need a tool to break it."

### Surfaces
```lua
surfaces = {
    inside = {
        capacity = 6, max_item_size = 4, weight_capacity = 30,
        contents = {"grain-sack-1"},
        accessible = false,  -- sealed state
    },
}
```
- `accessible` toggles to `true` on `pried-open` state
- On `broken` state, contents are ejected to room floor

### Spatial Context
- **Location:** Room floor, east wall, under shelving
- **room_presence (sealed):** "A large wooden crate sits against the east wall, its lid nailed firmly shut."
- **room_presence (pried-open):** "A pried-open crate sits against the east wall, its lid torn free."
- **room_presence (broken):** "Splintered remains of a crate litter the floor by the east wall."

### GOAP Prerequisites
```lua
prerequisites = {
    open = { requires = {"prying_tool"}, auto_steps = {"take crowbar"} },
}
```

### Puzzle Role
- **Puzzle 009 (Crate Puzzle):** First layer of nested containers. Player must find crowbar, then pry open this crate to access the grain-sack inside.

### Principle 8 Compliance
All behavior declared in metadata: FSM states, transitions with requires_tool guards, mutate fields for weight/keywords/categories changes, surface accessibility toggling per state.

---

## Object 2: small-crate

### Identity
| Field | Value |
|-------|-------|
| **id** | `small-crate` |
| **name** | "a small wooden crate" |
| **keywords** | crate, small crate, wooden crate, box, small box |
| **categories** | container, wooden, breakable |
| **weight** | 8 (kg) |
| **size** | 3 (medium) |
| **portable** | Yes (heavy but liftable) |

### Material
`wood` — ✓ In registry.

### FSM States & Transitions

```
closed → open ↔ closed   (also: any state → broken)
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell |
|-------|--------------------|--------------------|----------|
| closed | A small wooden crate, about the size of a bread loaf. The lid sits loosely on top, held by a simple latch. Something rattles faintly inside. | Smooth-planed wood, lighter than the big crate. A small iron latch on one side. The lid moves slightly when pushed. | Sawdust and old varnish. |
| open | A small crate with its lid propped open. Inside: a tangle of old rags and wood shavings. Nothing of obvious value. | Open box. Inside: soft rags, scratchy wood shavings. The bottom is bare wood. | Musty fabric, sawdust. |
| broken | The small crate has been smashed. Thin planks and a bent latch lie scattered. | Thin splinters and bent metal. | Sawdust. |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| closed | open | open | — (no tool needed, latch is simple) | "You flip the latch and lift the lid. Inside: a nest of old rags and wood shavings. Nothing remarkable." | `keywords = { add = "open" }` |
| open | closed | close | — | "You close the lid and flip the latch shut." | `keywords = { remove = "open" }` |
| closed | broken | break, smash | `requires_tool = "prying_tool"` OR `requires_tool = "blunt_weapon"` | "The small crate splinters easily under the blow." | `weight = 2, keywords = { add = "broken" }, categories = { remove = "container" }` |
| open | broken | break, smash | `requires_tool = "prying_tool"` OR `requires_tool = "blunt_weapon"` | "The open crate crunches apart." | `weight = 2, keywords = { add = "broken" }, categories = { remove = "container" }` |

### Surfaces
```lua
surfaces = {
    inside = {
        capacity = 3, max_item_size = 2, weight_capacity = 10,
        contents = {},  -- rags and shavings are flavor text, not objects
        accessible = false,  -- closed
    },
}
```

### Spatial Context
- **Location:** Stacked on top of large-crate, or on a shelf
- **room_presence (closed):** "A small wooden crate sits atop a shelf, its latch rusted shut."

### GOAP Prerequisites
None — latch opens by hand.

### Puzzle Role
- **Red herring / exploration reward.** The player may investigate this before or after the large crate. It contains nothing critical but teaches the container system on a simpler object. Could contain a rag (crafting material) via instance override.

### Principle 8 Compliance
All behavior in metadata. Simple toggle FSM + breakable transition.

---

## Object 3: grain-sack

### Identity
| Field | Value |
|-------|-------|
| **id** | `grain-sack` |
| **name** | "a heavy sack of grain" |
| **keywords** | sack, grain sack, grain, burlap sack, bag, feed sack, heavy sack |
| **categories** | container, fabric |
| **weight** | 15 (kg — full of grain) |
| **size** | 3 (medium) |
| **portable** | Yes (barely — very heavy) |

### Material
`burlap` — ⚠️ **NEW MATERIAL NEEDED.** Coarse woven jute fabric. Suggested properties: density 350, ignition_point 280, hardness 1, flexibility 0.6, absorbency 0.5, opacity 0.8, flammability 0.5, conductivity 0.0, fragility 0.1, value 1. (Fallback: use `fabric` from registry.)

### FSM States & Transitions

```
tied → cut-open (terminal, if knife used)
tied → untied → open (if untied by hand)
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell |
|-------|--------------------|--------------------|----------|
| tied | A heavy burlap sack, cinched tight with twine at the neck. The weave bulges with grain — you can feel individual kernels through the fabric. A faded stamp reads "BARLEY" in block letters. | Rough burlap, coarse weave. Hard lumps underneath — grain. The neck is tied tightly with scratchy twine. Heavy. Very heavy. | Stale grain, dusty burlap. A hint of mildew. |
| untied | The burlap sack's neck hangs loose, twine dangling. Golden-brown barley fills it nearly to the top. You could reach inside. | Rough burlap, open top. Grain shifts under your fingers — dry, cool kernels. | Barley and dust. Stronger now that it's open. |
| cut-open | The sack has been slashed open. Barley spills across the floor in a golden drift, and something glints among the kernels. | Rough burlap, torn edges. Grain everywhere — on the floor, in the sack. Something hard and metallic in the grain. | Barley dust, sharp and ticklish in the nose. |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| tied | untied | untie, open | — (by hand, but fiddly) | "You work the twine loose with your fingers — it takes a while, the knot is tight and old. The neck of the sack falls open, revealing barley grain nearly to the brim." | `keywords = { add = "open" }` |
| tied | cut-open | cut | `requires_tool = "cutting_edge"` | "You slash the sack with the knife. Burlap parts easily, and barley pours out in a rush, scattering across the floor. Something metallic clinks among the kernels." | `weight = 3, keywords = { add = "cut", add = "open" }` |
| untied | untied | search, reach in, rummage | — | "You plunge your hand into the barley. The grain shifts and flows around your fingers... and closes around something hard and cold. A key." | — |

**Note:** The `search` interaction on the `untied` state is not a state transition — it's a sensory/discovery action that reveals the iron-key inside the sack's contents. The engine handles this through the normal TAKE FROM or SEARCH IN mechanic on the `inside` surface.

### Surfaces
```lua
surfaces = {
    inside = {
        capacity = 2, max_item_size = 1, weight_capacity = 5,
        contents = {"iron-key-1"},  -- hidden among grain
        accessible = false,  -- tied
    },
}
```
- `accessible` toggles to `true` on `untied` or `cut-open` state

### Spatial Context
- **Location:** Inside large-crate (nested container)
- **room_presence:** Not visible until large-crate is opened

### GOAP Prerequisites
```lua
prerequisites = {
    cut = { requires = {"cutting_edge"}, auto_steps = {"take knife"} },
    -- untie requires no tools
}
```

### Puzzle Role
- **Puzzle 009 (Crate Puzzle):** Second layer of nested containers. Iron key is hidden inside the grain. Player must open/cut the sack and search inside to find it.

### Principle 8 Compliance
All behavior in metadata. FSM states control accessibility. The key is a normal contained object discovered through standard container interaction.

---

## Object 4: wine-rack

### Identity
| Field | Value |
|-------|-------|
| **id** | `wine-rack` |
| **name** | "a wooden wine rack" |
| **keywords** | wine rack, rack, wine shelf, bottle rack, shelving |
| **categories** | furniture, wooden |
| **weight** | 30 (kg — heavy timber frame) |
| **size** | 5 (large) |
| **portable** | No |

### Material
`wood` — ✓ In registry. Heavy timber frame, darkened with age.

### FSM States & Transitions
None — static object. No state changes.

### Sensory Properties

| Sense | Description |
|-------|-------------|
| description | A tall wooden wine rack against the west wall, built of dark-stained timber. Circular slots hold bottles in rows — most empty, a few still occupied. Cobwebs bridge the gaps between bottles like silk hammocks. The wood is warped with damp. |
| on_feel | Rough timber, damp-swollen. The circular slots are smooth-worn from years of bottles sliding in and out. Cobwebs cling to your fingers, sticky and old. |
| on_smell | Old wine — vinegar, oak tannins, and must. The wood itself smells of damp rot. |
| on_listen | Bottles clink softly when you brush against the rack. |

### Surfaces
```lua
surfaces = {
    inside = {
        capacity = 12, max_item_size = 2, weight_capacity = 25,
        contents = {"wine-bottle-1", "wine-bottle-2", "wine-bottle-3"},
        accessible = true,
        accepts = {"bottle"},  -- only bottles fit in rack slots
    },
}
```

### Spatial Context
- **Location:** West wall of storage cellar
- **room_presence:** "A tall wine rack stands against the west wall, a few dusty bottles still resting in its slots."

### Puzzle Role
- **Puzzle 010 (Light Upgrade):** Holds wine bottles, one of which contains lamp oil. Player must examine bottles to find the right one.

### Principle 8 Compliance
Pure furniture — surfaces and containment declared in metadata. No engine-specific code.

---

## Object 5: wine-bottle

### Identity
| Field | Value |
|-------|-------|
| **id** | `wine-bottle` |
| **name** | "a dusty wine bottle" |
| **keywords** | bottle, wine bottle, wine, glass bottle, dusty bottle |
| **categories** | container, fragile, glass, bottle |
| **weight** | 1.5 (kg — full) |
| **size** | 2 (small) |
| **portable** | Yes |

### Material
`glass` — ✓ In registry. Dark green glass, thick-walled.

### FSM States & Transitions

```
sealed → open → empty
sealed/open → broken (terminal)
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell | on_listen |
|-------|--------------------|--------------------|----------|-----------|
| sealed | A dark green glass bottle, sealed with a wax-dipped cork. Dust furs the shoulders. A faded label clings to the belly — the text is illegible. Liquid sloshes when tilted. | Cool glass, smooth and heavy. Wax seal at the neck. Liquid shifts inside when tilted. | Faintly vinegary through the seal. | Liquid glugs when tilted. |
| open | An open wine bottle, the cork removed. Dark liquid is visible inside. The neck is stained with drips. | Cool glass, open top. Liquid weight still inside. Wine-sticky neck. | Sharp vinegar and old grape. The wine has long turned. | Quiet slosh if tilted. |
| empty | An empty wine bottle. A few red-purple dregs stain the inside. The cork sits beside it. | Light glass, hollow. Sticky residue inside. | Stale wine residue. | Hollow ring when tapped. |
| broken | Shattered glass and spreading liquid on the stone floor. | Sharp glass fragments — dangerous to touch! | Wine and wet stone. | — |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| sealed | open | open, uncork | — (pull cork by hand) | "You prise the wax seal and work the cork free with a hollow pop. The sharp smell of old wine rises from the neck." | `weight = function(w) return w - 0.05 end, keywords = { add = "open" }` |
| open | empty | pour | — | "You upend the bottle. Dark wine glugs out and splashes across the stone floor, staining it purple-black." | `weight = 0.4, keywords = { add = "empty" }, categories = { remove = "container" }` |
| sealed | broken | break, smash, throw | — (throw at wall/floor) | "The bottle shatters on the stone floor. Glass and wine spray across the flagstones." | — (object destroyed, spawns glass-shard) |
| open | broken | break, smash, throw | — | "The open bottle shatters. Glass and the dregs of wine scatter." | — |

**Instance Overrides (for oil variant):**
One wine-bottle instance in the wine rack will have overrides to contain lamp oil instead of wine:
```lua
-- Instance override for oil-bearing bottle
{
    type_id = "wine-bottle",  -- same base object
    overrides = {
        name = "a dark glass bottle",
        keywords = {"bottle", "dark bottle", "glass bottle", "oil bottle"},
        -- Sensory overrides per state to reflect oil instead of wine:
        states = {
            sealed = {
                on_smell = "Something oily, not vinegar. Mineral. Lamp oil?",
                description = "A dark glass bottle, sealed with a wax-dipped cork. Unlike the wine bottles, this one has no label. The liquid inside moves more sluggishly — thicker than wine.",
            },
            open = {
                on_smell = "Unmistakable: lamp oil. Rich, mineral, slightly acrid.",
                description = "An open dark bottle. The liquid inside is pale gold and viscous — definitely not wine. Lamp oil.",
            },
        },
        contents_type = "lamp-oil",  -- engine flag for POUR target resolution
    },
}
```

### Spatial Context
- **Location:** In wine-rack slots (inside surface)
- **room_presence:** Not individually visible — described as part of the wine rack. Visible when taken from rack or examined.

### GOAP Prerequisites
```lua
prerequisites = {
    pour = { requires_state = "open" },
}
```

### Puzzle Role
- **Puzzle 010 (Light Upgrade):** One bottle contains lamp oil. Player must examine bottles to distinguish oil from wine (sensory clues: smell, viscosity, no label). Pour oil into lantern to fuel it.

### Principle 8 Compliance
All behavior in metadata. Instance overrides handle the oil variant without a separate base object. Sensory distinctions between wine and oil are state-level descriptions.

---

## Object 6: rope-coil

### Identity
| Field | Value |
|-------|-------|
| **id** | `rope-coil` |
| **name** | "a coil of rope" |
| **keywords** | rope, coil, coil of rope, hemp rope, line, cord |
| **categories** | tool |
| **weight** | 3 (kg) |
| **size** | 3 (medium — bulky coil) |
| **portable** | Yes |

### Material
`hemp` — ⚠️ **NEW MATERIAL NEEDED.** Natural plant fiber rope. Suggested properties: density 350, ignition_point 300, hardness 2, flexibility 0.9, absorbency 0.5, opacity 0.8, flammability 0.4, conductivity 0.0, fragility 0.0, value 2.

### FSM States & Transitions
None — static object. No state changes. The rope is a pure tool.

### Sensory Properties

| Sense | Description |
|-------|-------------|
| description | A thick coil of hemp rope, looped neatly and hung on an iron peg in the wall. The fibers are rough but sound — not rotted. About twenty feet of it, by the look. |
| on_feel | Rough hemp fibers, thick as your thumb. The coils are stiff but pliable — not rotted through. The rope is strong. |
| on_smell | Hemp and tar. A working rope, treated against damp. |

### Tool Capabilities
```lua
provides_tool = {"rope", "binding"},
```
- `rope` — enables CLIMB, TIE, LOWER, RAPPEL actions where applicable
- `binding` — enables TIE actions on objects (bundle items, secure doors)

### Spatial Context
- **Location:** Hanging on an iron peg on the south wall
- **room_presence:** "A coil of rope hangs from an iron peg on the wall."

### GOAP Prerequisites
None — take and use.

### Puzzle Role
- **Puzzle 013 (Courtyard Entry, optional):** If player reaches the courtyard, rope could enable safe climbing or descent.
- **General utility:** Enables alternate puzzle solutions in future rooms. Strategic carry decision (heavy, bulky, but opens options).

### Principle 8 Compliance
Tool capability declared as metadata. The engine resolves `provides_tool = "rope"` for any verb that requires it.

---

## Object 7: iron-key

### Identity
| Field | Value |
|-------|-------|
| **id** | `iron-key` |
| **name** | "a heavy iron key" |
| **keywords** | key, iron key, heavy key, black key, iron, rusty key |
| **categories** | metal, small |
| **weight** | 0.5 (kg — heavier than brass key, befitting an iron door) |
| **size** | 1 (small) |
| **portable** | Yes |

### Material
`iron` — ✓ In registry. Black iron, pitted with age but structurally sound. Slight rust.

### FSM States & Transitions
None — static object. Keys don't change state.

### Sensory Properties

| Sense | Description |
|-------|-------------|
| description | A heavy iron key, nearly black with age and pitted with rust. The bow is a simple ring, large enough to thread a finger through. The bit is thick and crude — clearly made for a heavy lock. This key means business. |
| on_feel | Cold, heavy iron. Rough with pitting and slight rust. The ring bow is large — you could wear it on a finger. The teeth are thick and blunt. |
| on_smell | Iron and rust. A faint metallic tang. |
| on_taste | Metallic. Blood-like. The sour bite of old iron. (Not recommended.) |

### Spatial Context
- **Location:** Hidden inside grain-sack, buried in barley
- **Discovery:** Player must open large-crate, then open/cut grain-sack, then search inside to find this key

### GOAP Prerequisites
None — it's a key. UNLOCK door WITH iron-key.

### Puzzle Role
- **Puzzle 009 (Crate Puzzle):** The prize. Finding this key is the goal of the crate → sack → key chain.
- **Critical path gate:** Unlocks the iron door leading NORTH to the Deep Cellar.

### Principle 8 Compliance
Static metadata object. The door's `requires_key` field references this key's capability. No engine-specific code.

---

## Object 8: oil-lantern

### Identity
| Field | Value |
|-------|-------|
| **id** | `oil-lantern` |
| **name** | "an iron oil lantern" |
| **keywords** | lantern, oil lantern, lamp, iron lantern, hurricane lamp |
| **categories** | light source, tool, metal |
| **weight** | 1.2 (kg — empty iron frame with glass panel) |
| **size** | 2 (small) |
| **portable** | Yes |

### Material
`iron` — ✓ In registry. Iron frame with a small glass window panel. Medieval-style hanging lantern.

### FSM States & Transitions

```
empty → fueled → lit ↔ extinguished → (relit) → spent (terminal)
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell | on_listen | Special |
|-------|--------------------|--------------------|----------|-----------|---------|
| empty | An iron oil lantern with a small glass window, hinged door, and a carrying ring on top. The oil reservoir is bone dry — the wick is a brown crisp. It's useless without fuel. | Cold iron frame, glass panel on one side. A small hinged door. The reservoir inside is dry — rough metal. A carry ring on top. | Old metal and the ghost of lamp oil. | Creaks slightly when lifted — the hinged door swings. | `casts_light = false` |
| fueled | The lantern's reservoir glistens with oil. The wick has soaked it up — dark and saturated, ready to burn. The glass panel shows a distorted view of the wick. | Cold iron frame. Inside, the wick is wet and oily to the touch. The reservoir is heavy with oil. | Lamp oil — mineral, slightly acrid. | — | `casts_light = false` |
| lit | The lantern burns with a bright, steady flame behind its glass panel. Warm amber light radiates in all directions — brighter and more reliable than a candle. The iron frame heats up. | Warm iron. The glass panel radiates heat. The carry ring is still cool enough to hold. | Burning lamp oil — clean, mineral smoke. | A low, steady hiss from the wick. The flame purrs. | `casts_light = true, light_radius = 3, provides_tool = "fire_source"` |
| extinguished | The lantern has been put out. The glass panel is fogged with soot, and the wick smolders faintly. Oil remains in the reservoir — it could be relit. | Warm iron, cooling quickly. The glass is sooty. Wick still warm. Oil in the reservoir — you can feel its weight. | Smoke and cooling oil. Hot metal. | A faint tick as the metal contracts. | `casts_light = false` |
| spent | The lantern's reservoir is dry. The wick is a charred black thread. The glass panel is opaque with soot. It would need more oil to function again. | Cold iron. Dry reservoir. Dead wick — brittle and charred. Sooty glass. | Stale smoke and burnt oil residue. | Silent. Dead. | `casts_light = false, terminal = true` |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| empty | fueled | pour, fill, fuel | `requires_tool = "lamp-oil"` (oil must be poured in) | "You carefully pour the oil into the lantern's reservoir. The wick darkens as it soaks up the fuel. The lantern is ready to light." | `weight = function(w) return w + 0.5 end` |
| fueled | lit | light, ignite | `requires_tool = "fire_source"` | "You open the hinged door and touch the flame to the wick. It catches immediately — a bright, steady flame blooms behind the glass. Warm amber light pushes the darkness back. Much better than a candle." | — |
| lit | extinguished | extinguish, put out, blow out, snuff | — | "You lift the glass door and blow out the flame. The wick smolders and dies. Darkness reclaims its territory." | `weight = function(w) return math.max(w * 0.85, 1.2) end, keywords = { add = "sooty" }` |
| extinguished | lit | light, relight, ignite | `requires_tool = "fire_source"` | "The oily wick catches again. Light returns, steady and warm behind the sooty glass." | — |
| lit | spent | — | `trigger = "auto", condition = "timer_expired"` | "The lantern flame sputters, shrinks, and dies. The oil is exhausted. The last of the light fades to a dull orange glow, then nothing." | `weight = 1.2, categories = { remove = "light source" }, keywords = { add = "spent" }` |

**Fail Messages:**
- `light` (empty): "The lantern has no oil. The wick is bone dry — lighting it would accomplish nothing."
- `pour` with wrong liquid: "That's not lamp oil. The lantern needs oil to burn."

**Timer:**
```lua
burn_duration = 14400,   -- 4 hours game time (40 ticks) — much longer than candle (7200s/20 ticks)
remaining_burn = 14400,
```

### Spatial Context
- **Location:** On a shelf, east wall
- **room_presence (empty):** "An iron lantern sits on a shelf, its glass panel dark and dusty."
- **room_presence (lit):** "An iron lantern burns with a bright amber glow."

### GOAP Prerequisites
```lua
prerequisites = {
    light = {
        requires = {"fire_source"},
        requires_state = "fueled",  -- must be fueled before lighting
    },
    fuel = {
        requires = {"lamp-oil"},
    },
}
```

### Puzzle Role
- **Puzzle 010 (Light Upgrade):** The prize. Once fueled and lit, the lantern is superior to the candle: brighter (radius 3 vs 2), longer-lasting (4 hours vs 2), and enclosed (wind-resistant). Rewards optional exploration.

### Principle 8 Compliance
All behavior in metadata. FSM with 5 states, tool requirements, timer-based auto-depletion, mutate fields for weight/keywords. The "fueling" mechanic uses requires_tool = "lamp-oil" — the engine checks if the player has an oil source.

---

## Object 9: crowbar

### Identity
| Field | Value |
|-------|-------|
| **id** | `crowbar` |
| **name** | "an iron crowbar" |
| **keywords** | crowbar, bar, pry bar, iron bar, jimmy, lever |
| **categories** | tool, metal, weapon |
| **weight** | 3 (kg) |
| **size** | 3 (medium — about two feet long) |
| **portable** | Yes |

### Material
`iron` — ✓ In registry. Solid iron bar, slightly curved at one end with a flat claw.

### FSM States & Transitions
None — static object. The crowbar is a pure tool.

### Sensory Properties

| Sense | Description |
|-------|-------------|
| description | A heavy iron crowbar, nearly two feet long, with a flat claw at one end and a chisel point at the other. The iron is dark with age but solid — no rust deep enough to weaken it. Scratches and dents mark a life of hard use. |
| on_feel | Cold, heavy iron bar. Smooth from use in the middle — the grip. One end curves to a flat claw, the other tapers to a blunt chisel point. Solid. Reassuring. |
| on_smell | Iron and old grease. |
| on_listen | Rings like a bell when tapped against stone. |

### Tool Capabilities
```lua
provides_tool = {"prying_tool", "blunt_weapon", "leverage"},
```
- `prying_tool` — PRY open crates, doors, lids
- `blunt_weapon` — STRIKE, BREAK objects
- `leverage` — LEVER heavy objects, move stone lids

### Spatial Context
- **Location:** Leaning against the west wall, near the wine rack. Partially hidden behind barrels.
- **room_presence:** "An iron crowbar leans against the wall by the wine rack."

### GOAP Prerequisites
None — take and use.

### Puzzle Role
- **Puzzle 009 (Crate Puzzle):** Required tool to pry open the sealed large-crate. Without it, the player cannot access the grain-sack and iron key.
- **General utility:** Enables breaking, prying in future rooms. Strategic carry decision.

### Principle 8 Compliance
Tool capabilities declared as metadata. The engine resolves `provides_tool = "prying_tool"` when verbs require it.

---

## Object 10: rat

### Identity
| Field | Value |
|-------|-------|
| **id** | `rat` |
| **name** | "a brown rat" |
| **keywords** | rat, rodent, mouse, vermin, creature |
| **categories** | creature, small, ambient |
| **weight** | 0.3 (kg) |
| **size** | 1 (small) |
| **portable** | No (it runs away) |

### Material
None — living creature, not a manufactured object.

### FSM States & Transitions

```
hidden → visible → fleeing → gone (terminal)
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell | on_listen |
|-------|--------------------|--------------------|----------|-----------|
| hidden | — (not visible, only audible) | — | A rank, musky animal smell. Something lives here. | Scratching in the walls. Small claws on stone. Something is moving behind the shelves. |
| visible | A large brown rat perches on a broken shelf, watching you with bright black eyes. Its whiskers twitch. It's not afraid — not yet. | — (too fast to catch) | Rank musk. Close. | A low chittering. Claws clicking on wood. |
| fleeing | The rat bolts — a brown blur along the baseboard, vanishing behind a crate. | — | — | Frantic scrabbling, then silence. |
| gone | — (the rat has fled the room) | — | Fading musk. The rat smell lingers. | Silence. The scratching has stopped. |

**Transitions:**

| From | To | Trigger | Condition | Message |
|------|-----|---------|-----------|---------|
| hidden | visible | auto | Player enters room OR examines shelves | "Something moves on the shelf — a large brown rat sits up on its haunches, watching you with bead-black eyes." |
| visible | fleeing | player action near rat | Any loud action (BREAK, MOVE, TAKE near rat) | "The rat bolts. It's a brown streak along the baseboard, gone behind the crates in an instant." |
| visible | gone | auto | After 3 ticks if undisturbed, rat leaves on its own | "The rat loses interest and slips away between the stones. The scratching fades." |
| fleeing | gone | auto | Immediate | — |

**Notes:**
- The rat is atmospheric. It cannot be caught, killed, or meaningfully interacted with (per CBG: "ambient life").
- It provides environmental storytelling — this room has been abandoned long enough for vermin to move in.
- Its sounds are audible in darkness (on_listen in hidden state), adding tension.

### Spatial Context
- **Location:** On a shelf, then behind crates, then gone
- **room_presence (hidden):** — (only audible via on_listen)
- **room_presence (visible):** "A brown rat watches you from a broken shelf."

### Puzzle Role
None — atmospheric object. Teaches observation and adds life to an otherwise dead room.

### Principle 8 Compliance
FSM-driven behavior. Auto-transitions handle movement. No engine-specific creature code — the rat is just an object with states, like everything else.

---

## Object Interaction Map

```
                    Storage Cellar — Object Relationships

    [crowbar] ──provides_tool──→ PRY ──opens──→ [large-crate]
                                                      │
                                                   contains
                                                      │
                                                      ▼
                                                [grain-sack]
                                                      │
                                           cut(knife) or untie(hand)
                                                      │
                                                   contains
                                                      │
                                                      ▼
                                                 [iron-key]
                                                      │
                                                  unlocks
                                                      ▼
                                          (iron door → Deep Cellar)


    [wine-rack] ──contains──→ [wine-bottle] × 3
                                    │
                              (one has oil)
                                    │
                               pour oil
                                    │
                                    ▼
    [oil-lantern] ←── fueled ──── (oil)
         │
    light (fire_source)
         │
         ▼
    (superior light source)


    [rope-coil] ── utility tool, no puzzle dependency here
    [small-crate] ── red herring / exploration
    [rat] ── atmospheric
```

---

## Summary

| # | Object | Material | FSM? | Portable | Puzzle |
|---|--------|----------|------|----------|--------|
| 1 | large-crate | wood ✓ | Yes (3 states) | No | 009 |
| 2 | small-crate | wood ✓ | Yes (3 states) | Yes | — |
| 3 | grain-sack | burlap ⚠️ NEW | Yes (3 states) | Yes (heavy) | 009 |
| 4 | wine-rack | wood ✓ | No | No | 010 |
| 5 | wine-bottle | glass ✓ | Yes (4 states) | Yes | 010 |
| 6 | rope-coil | hemp ⚠️ NEW | No | Yes | 013 (future) |
| 7 | iron-key | iron ✓ | No | Yes | 009, critical path |
| 8 | oil-lantern | iron ✓ | Yes (5 states) | Yes | 010 |
| 9 | crowbar | iron ✓ | No | Yes | 009 |
| 10 | rat | — (creature) | Yes (4 states) | No | — |
