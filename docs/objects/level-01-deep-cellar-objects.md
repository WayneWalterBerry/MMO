# Level 1 — Deep Cellar Objects

**Room:** The Deep Cellar / The Old Cellar  
**Room ID:** `deep-cellar`  
**Author:** Flanders (Object Designer)  
**Date:** 2026-07-21  
**Status:** Specification — Ready for Build  
**Source:** `docs/levels/level-01-intro.md` (CBG Master Design)

---

## Room Context

The architecture changes here — older stonework, carved from bedrock rather than stacked stones. Vaulted ceiling like a chapel or crypt. Iron sconces line the walls, unlit. The air smells of old incense, wax, and something musty. Symbols are carved into the stone — religious or occult. This place pre-dates the manor above.

**Connections:**
- SOUTH → Storage Cellar (iron door — player just came through)
- UP → Hallway (stone stairway — main exit, critical path)
- WEST → Crypt (stone archway — locked, requires silver key, optional)

**Puzzle Support:**
- **Puzzle 011 (Ascent to Manor):** Critical path. Navigate stairway up to hallway.
- **Puzzle 012 (Altar Puzzle):** Optional. Interact with altar objects (scroll, incense burner, offering bowl) to unlock the crypt archway.

**Total Objects:** 8 new base objects

**New Materials Needed:**
- `stone` — for stone-altar, stone-sarcophagus (not in current material registry)

---

## Object 1: stone-altar

### Identity
| Field | Value |
|-------|-------|
| **id** | `stone-altar` |
| **name** | "a stone altar" |
| **keywords** | altar, stone altar, slab, sacrificial altar, table, stone table |
| **categories** | furniture, stone |
| **weight** | 200 (kg — immovable carved stone) |
| **size** | 6 (massive) |
| **portable** | No |

### Material
`stone` — ⚠️ **NEW MATERIAL NEEDED.** Carved granite/limestone. Suggested properties: density 2700, melting_point 1200, ignition_point nil, hardness 7, flexibility 0.0, absorbency 0.05, opacity 1.0, flammability 0.0, conductivity 0.1, fragility 0.2, value 5.

### FSM States & Transitions
None — static object. The altar itself does not change state. Its contents (offering-bowl, incense-burner, scroll) are the interactive elements.

### Sensory Properties

| Sense | Description |
|-------|-------------|
| description | A massive stone altar dominates the center of the chamber, carved from a single block of pale granite. Its surface is smooth and slightly concave — worn by centuries of use. Symbols are inscribed around the edges: spirals, crosses, and a repeating motif of an eye within a triangle. Wax drippings and ash stains mark its surface. Three objects rest upon it — a brass bowl, a small burner, and a rolled scroll. |
| on_feel | Cold, smooth stone. The surface dips slightly in the center — worn from use or designed as a basin. The carved symbols are shallow grooves under your fingertips — spirals, lines, geometric shapes. The stone holds the cold of centuries. |
| on_smell | Old incense — sandalwood and myrrh, faded almost to memory. Candle wax. Stone dust. And beneath it all, something organic and ancient — must, or decay, or very old blood. |
| on_listen | Your touch on the stone produces no echo. The altar absorbs sound. |
| on_taste | (If player tries:) Cold stone and grit. The taste of geology. |

### Surfaces
```lua
surfaces = {
    top = {
        capacity = 5, max_item_size = 3, weight_capacity = 20,
        contents = {"offering-bowl-1", "incense-burner-1", "tattered-scroll-1"},
        accessible = true,
    },
    behind = {
        capacity = 2, max_item_size = 1, weight_capacity = 5,
        contents = {"silver-key-1"},
        accessible = true,  -- hidden by default, revealed on "look behind altar"
    },
}
```

### Spatial Context
- **Location:** Center of the deep cellar chamber
- **room_presence:** "A massive stone altar stands at the center of the chamber, pale granite carved with ancient symbols."

### Puzzle Role
- **Puzzle 012 (Altar Puzzle):** The altar is the hub. Its surface holds the three key objects (bowl, burner, scroll). The silver key is hidden behind it. Placing the correct offering in the bowl triggers the crypt archway to unlock.

### Principle 8 Compliance
Pure furniture with surfaces. No engine-specific code. The puzzle mechanism (placing offering → unlocking archway) is handled through transition guards on the archway door, not hardcoded in the altar.

---

## Object 2: wall-sconce

### Identity
| Field | Value |
|-------|-------|
| **id** | `wall-sconce` |
| **name** | "an iron wall sconce" |
| **keywords** | sconce, wall sconce, torch holder, bracket, iron bracket, light fixture |
| **categories** | furniture, metal |
| **weight** | 2 (kg — iron bracket bolted to wall) |
| **size** | 2 (small) |
| **portable** | No (wall-mounted) |

### Material
`iron` — ✓ In registry. Wrought iron, simple cup-and-arm design bolted into the stone.

### FSM States & Transitions

```
empty → occupied (when player places light source in it)
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell |
|-------|--------------------|--------------------|----------|
| empty | An iron wall sconce, a simple cup-and-arm bracket bolted into the stone. Empty — whatever torch or candle it held has long since burned away. Soot stains the stone above it in a dark tongue. | Cold iron bracket jutting from the wall. A cup shape at the top — empty. Soot crumbles under your fingers on the stone above. | Old soot and cold iron. |
| occupied | An iron wall sconce holding a [light source]. The flame casts dancing shadows across the vaulted ceiling and illuminates the carved symbols on the walls. | Warm iron bracket. The [light source] above radiates heat. | Burning [wax/oil/pitch] and warm iron. |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| empty | occupied | put, place, insert | Player places a light source (candle, torch) in sconce | "You set the [light source] into the iron cup. The flame steadies, and light fills the alcove." | — |
| occupied | empty | take, remove | Player removes the light source | "You lift the [light source] from the sconce." | — |

**Notes:**
- The sconce is a container that accepts only light source objects (candle, torch, candle-stub).
- Multiple sconce instances line the walls (4-6 instances).
- Placing a lit light source in a sconce effectively provides room illumination without requiring the player to hold it.

### Surfaces
```lua
surfaces = {
    inside = {
        capacity = 1, max_item_size = 2, weight_capacity = 3,
        contents = {},
        accessible = true,
        accepts = {"light source"},  -- category filter
    },
}
```

### Spatial Context
- **Location:** Bolted into stone walls at intervals around the chamber (4-6 instances)
- **room_presence (empty):** "Iron sconces line the walls, all dark and empty."
- **room_presence (occupied):** "A [light source] burns in a wall sconce, casting flickering light across the carved stone."

### Puzzle Role
- Utility — frees up the player's hands by providing a fixed mounting point for light sources.
- Atmosphere — multiple empty sconces reinforce the sense of abandonment.

### Principle 8 Compliance
Container with category filter (`accepts`). State changes driven by standard PUT/TAKE verbs. No special engine code.

---

## Object 3: incense-burner

### Identity
| Field | Value |
|-------|-------|
| **id** | `incense-burner` |
| **name** | "a brass incense burner" |
| **keywords** | incense burner, burner, censer, incense, brass burner, brazier |
| **categories** | container, metal, small |
| **weight** | 1.5 (kg) |
| **size** | 2 (small) |
| **portable** | Yes |

### Material
`brass` — ✓ In registry. Tarnished brass, ornately cast with pierced geometric patterns.

### FSM States & Transitions
None — static object. The incense has long since burned to ash. This is an environmental storytelling object.

**Design note:** If Puzzle 012 requires relighting incense, a future FSM could be added (cold → lit). For now, it's a cold artifact containing ash.

### Sensory Properties

| Sense | Description |
|-------|-------------|
| description | A small brass incense burner, its bowl dark with carbon and half-filled with grey ash. The lid is perforated with geometric patterns — stars and hexagons — that once let fragrant smoke spiral upward. The brass is tarnished to a dull greenish-brown. Whatever ceremony last used this was a long time ago. |
| on_feel | Ornate brass, cold. The pierced lid has sharp geometric cutouts — stars and hexagons. Inside: fine, silky ash. Weightless between your fingers. |
| on_smell | Old incense — the ghost of sandalwood and myrrh. The ash itself smells of nothing, but the brass retains the memory. |
| on_listen | The ash whispers when disturbed — a soft sifting sound. |

### Surfaces
```lua
surfaces = {
    inside = {
        capacity = 1, max_item_size = 1, weight_capacity = 0.5,
        contents = {},  -- ash is flavor text, not an object
        accessible = true,
    },
}
```

### Spatial Context
- **Location:** On top of stone-altar
- **room_presence:** Described as part of the altar's contents, not independently.

### Puzzle Role
- **Puzzle 012 (Altar Puzzle):** Part of the altar trio. Examining it provides lore clues (religious/ceremonial use). If the puzzle requires relighting incense (Bob to decide), this object's FSM would need expansion.
- **Environmental storytelling:** Proves the deep cellar was used for ceremonies.

### Principle 8 Compliance
Static metadata object with sensory descriptions per the standard pattern.

---

## Object 4: tattered-scroll

### Identity
| Field | Value |
|-------|-------|
| **id** | `tattered-scroll` |
| **name** | "a tattered scroll" |
| **keywords** | scroll, tattered scroll, parchment, document, text, writing, manuscript |
| **categories** | readable, paper, small |
| **weight** | 0.1 (kg) |
| **size** | 1 (small — rolled up) |
| **portable** | Yes |

### Material
`paper` — ✓ In registry. Old parchment (vellum), brittle with age.

### FSM States & Transitions

```
rolled → unrolled (readable)
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell |
|-------|--------------------|--------------------|----------|
| rolled | A scroll of yellowed parchment, tightly rolled and tied with a faded ribbon. The edges are frayed and spotted with age. It looks very old — and very fragile. | Dry, brittle parchment rolled tight. A thin ribbon ties it closed — silk, by the feel. The edges crumble slightly at your touch. | Old paper, dust, and a trace of iron-gall ink. Ancient. |
| unrolled | A sheet of yellowed parchment, covered in faded script. The handwriting is spidery and archaic, the ink brown with age. Much of the text is illegible, eaten by damp and time, but fragments remain. | Flat, brittle parchment. Crinkly and fragile — it could tear at any moment. The surface is rough where ink has been applied. | Iron-gall ink, old vellum, must. |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| rolled | unrolled | read, open, unroll, untie | — | "You carefully untie the ribbon and unroll the parchment. It crackles ominously but holds together. Faded script covers the page — most is illegible, but fragments emerge from the decay..." | `keywords = { add = "open" }` |

**Readable Text (when READ in unrolled state):**
```
"...in the year of our Lord 1143, this cellar was consecrated to the keeping
of the [illegible]... The family of [smudged] did build above, unknowing
of what lay beneath... Let no hand disturb what is sealed here, for the
[illegible] watches still... The key to the inner chamber rests with
the guardian, behind the place of offering..."
```

**Design note:** The text provides lore (the deep cellar pre-dates the manor, built 1143) and a puzzle hint ("behind the place of offering" = silver key behind the altar). The exact lore text is Wayne's domain — this is placeholder.

### Spatial Context
- **Location:** On top of stone-altar
- **room_presence:** Described as part of the altar's contents.

### GOAP Prerequisites
```lua
prerequisites = {
    read = { requires_state = "unrolled" },
}
```

### Puzzle Role
- **Puzzle 012 (Altar Puzzle):** Provides the hint that the silver key is behind the altar ("behind the place of offering").
- **Lore delivery:** First major narrative text in the game. Establishes the deep cellar's age and purpose.

### Principle 8 Compliance
FSM state controls readability. Readable text is metadata (description content in the `unrolled` state's `on_read` field). No engine-specific code.

---

## Object 5: silver-key

### Identity
| Field | Value |
|-------|-------|
| **id** | `silver-key` |
| **name** | "a small silver key" |
| **keywords** | key, silver key, small key, silver, ornate key |
| **categories** | metal, small, treasure |
| **weight** | 0.3 (kg — lighter than iron key, silver is decorative) |
| **size** | 1 (small) |
| **portable** | Yes |

### Material
`silver` — ⚠️ **NEW MATERIAL NEEDED.** Precious metal. Suggested properties: density 10490, melting_point 962, ignition_point nil, hardness 5, flexibility 0.2, absorbency 0.0, opacity 1.0, flammability 0.0, conductivity 0.9, fragility 0.15, value 30.

### FSM States & Transitions
None — static key object.

### Sensory Properties

| Sense | Description |
|-------|-------------|
| description | A small key of tarnished silver, its bow wrought in the shape of a cross — or perhaps a sword. The bit is delicate, almost ornamental, but the teeth are precisely cut. This is no common key — it was made for a special lock. |
| on_feel | Cool metal, lighter than iron. Smooth and finely made. The bow has a cross shape — you can trace the arms. The teeth are sharp and precise. |
| on_smell | Tarnished silver — a faint, sweet metallic scent. |
| on_taste | Clean metal. Slightly sweet, unlike the sour tang of iron or brass. |

### Spatial Context
- **Location:** Hidden behind the stone-altar (in the altar's `behind` surface)
- **Discovery:** Player must LOOK BEHIND ALTAR to find it. The tattered scroll provides a hint.

### Puzzle Role
- **Puzzle 012 (Altar Puzzle):** Finding this key unlocks the crypt archway (WEST exit). Optional content gate.
- **Alternative discovery:** The scroll hints at its location. Observant players can find it without the hint by systematically searching around the altar.

### Principle 8 Compliance
Static metadata object. The archway door's `requires_key` references this key's capability.

---

## Object 6: stone-sarcophagus

### Identity
| Field | Value |
|-------|-------|
| **id** | `stone-sarcophagus` |
| **name** | "a stone sarcophagus" |
| **keywords** | sarcophagus, coffin, stone coffin, tomb, stone box, casket |
| **categories** | furniture, stone, container |
| **weight** | 500 (kg — immovable, carved granite) |
| **size** | 6 (massive) |
| **portable** | No |

### Material
`stone` — ⚠️ **NEW MATERIAL NEEDED.** (Same as stone-altar — shared material entry.)

### FSM States & Transitions

```
closed → open
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell | on_listen |
|-------|--------------------|--------------------|----------|-----------|
| closed | A stone sarcophagus stands against the north wall, its massive lid carved with the effigy of a robed figure. The face is worn smooth by time — only the suggestion of features remains. The lid must weigh as much as a man. | Cold, rough stone. The lid has a carved figure — you can trace the outline of robes, folded hands, a smooth featureless face. The seam between lid and base is tight. | Old stone and something sealed away — dust, must, the faintest hint of decay. | Silence. Stone holds its secrets. |
| open | The sarcophagus lid has been pushed aside, revealing the interior. Inside, old bones rest on a bed of rotted fabric. The skull stares upward with empty sockets. Fragments of burial goods surround the remains. | The lid is askew. Inside: dry bones, crumbling fabric, smooth objects among the remains. The interior stone is rougher than the exterior. | Dust and old death. Not unpleasant — too old for that. Dry and mineral. | — |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| closed | open | push, open, lift, slide | `requires_tool = "leverage"` OR guard: player strength check (two hands needed) | "You brace yourself against the lid and push. The stone grinds against stone with a sound like a groan. Inch by inch, the lid slides aside, revealing the dark interior. Dust billows upward. Inside: old bones, rotted fabric, and the glint of metal." | `keywords = { add = "open" }` |

**Fail Messages:**
- Without leverage tool and insufficient strength: "The lid is impossibly heavy. You can't budge it with bare hands. You'd need a lever — or something to pry with."

**Notes:**
- The crowbar from the Storage Cellar provides `leverage` tool capability, enabling this transition.
- This is the deep cellar sarcophagus (1 instance). The crypt has 5 more.
- Contents are determined by instance override — in the deep cellar, this sarcophagus might be empty or contain minor lore items.

### Surfaces
```lua
surfaces = {
    inside = {
        capacity = 4, max_item_size = 3, weight_capacity = 30,
        contents = {},  -- instance override determines contents
        accessible = false,  -- closed
    },
    top = {  -- the lid surface, for placing objects on top
        capacity = 2, max_item_size = 2, weight_capacity = 10,
        contents = {},
        accessible = true,
    },
}
```

### Spatial Context
- **Location:** Against the north wall of the deep cellar
- **room_presence (closed):** "A stone sarcophagus stands against the north wall, its lid carved with a worn effigy."
- **room_presence (open):** "An open sarcophagus reveals old bones and the glint of burial goods."

### Puzzle Role
- **Exploration reward:** Opening it reveals lore and possibly minor treasure. Not required for critical path.
- **Skill bridge:** Teaches the heavy-lid mechanic used extensively in the Crypt (Puzzle 014).

### Principle 8 Compliance
FSM with tool requirement for opening. Surface accessibility toggled by state. Effigy is described as part of the lid (sensory description), not a separate object.

---

## Object 7: offering-bowl

### Identity
| Field | Value |
|-------|-------|
| **id** | `offering-bowl` |
| **name** | "a stone offering bowl" |
| **keywords** | bowl, offering bowl, stone bowl, basin, dish, offering |
| **categories** | container, stone, small |
| **weight** | 2 (kg) |
| **size** | 2 (small) |
| **portable** | Yes |

### Material
`ceramic` — ✓ In registry. Glazed ceramic, dark with age. (Alternative: `stone` if we want it to match the altar.)

### FSM States & Transitions

```
empty → offering-placed (when correct item placed inside)
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell |
|-------|--------------------|--------------------|----------|
| empty | A shallow bowl of dark ceramic, sitting on the altar's surface. The inside is smooth and clean — almost too clean for this dusty chamber. A faint circular stain marks the center, as if something once sat here. Symbols are painted around the rim in faded gold. | Smooth ceramic, cool. Shallow — your palm fits inside. The rim has raised bumps — painted symbols, worn almost flat. | Clean ceramic. No residue. |
| offering-placed | The bowl holds [offering object]. The gold symbols around the rim seem to catch the light differently — or is that your imagination? | The object sits in the bowl. The ceramic feels slightly warm — warmer than it should be. | A faint scent of incense, as if triggered by the offering. |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| empty | offering-placed | put, place, offer | Player places an acceptable item inside | "You place the [object] in the offering bowl. For a moment, nothing happens. Then — did the symbols on the rim just flicker? A sound like a sigh echoes through the chamber, and you hear stone grinding against stone somewhere to the west." | — |

**Puzzle Mechanism (Puzzle 012):**
When the correct offering is placed, the crypt archway (WEST) unlocks. The acceptable offering item is TBD (Bob/Wayne decision) — candidates:
- A lit candle (light offering)
- Wine from a wine bottle (libation)
- The player's blood (via self-harm with knife — ties to Puzzle 003 mechanic)
- A coin or treasure item

This is declared as a guard on the transition:
```lua
guard = function(obj, context)
    -- context.item is the placed object
    return context.item and context.item.categories and
           table_contains(context.item.categories, "offering_valid")
end
```
The acceptable items would have `"offering_valid"` in their categories (set by Bob during puzzle finalization).

### Surfaces
```lua
surfaces = {
    inside = {
        capacity = 1, max_item_size = 2, weight_capacity = 5,
        contents = {},
        accessible = true,
    },
}
```

### Spatial Context
- **Location:** On top of stone-altar
- **room_presence:** Described as part of the altar's contents.

### Puzzle Role
- **Puzzle 012 (Altar Puzzle):** Central puzzle object. Placing the correct offering triggers the crypt archway to unlock. Coordinate with Bob on the exact offering item and guard logic.

### Principle 8 Compliance
Container with guard function on the offering-placed transition. The archway unlock is triggered by a side effect declared in metadata (e.g., `on_transition` callback that sets the archway state). All logic in object metadata.

---

## Object 8: chain

### Identity
| Field | Value |
|-------|-------|
| **id** | `chain` |
| **name** | "an iron chain" |
| **keywords** | chain, iron chain, hanging chain, pull chain, chains |
| **categories** | metal, furniture |
| **weight** | 5 (kg — heavy iron links) |
| **size** | 4 (large — hangs from ceiling to chest height) |
| **portable** | No (attached to ceiling mechanism) |

### Material
`iron` — ✓ In registry. Heavy iron links, rusted but functional.

### FSM States & Transitions

```
hanging → pulled
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell | on_listen |
|-------|--------------------|--------------------|----------|-----------|
| hanging | A heavy iron chain hangs from the vaulted ceiling, dangling to about chest height. The links are thick and rust-spotted. It ends in a large ring — clearly meant to be pulled. The chain disappears into a dark slot in the ceiling, connected to some mechanism above. | Heavy iron links, rough with rust. The chain sways slightly when touched. A large ring at the bottom — meant to be grasped. The chain is taut, connected to something above. | Rust and old iron. | The chain clinks softly when disturbed. A faint creaking from above — the mechanism. |
| pulled | The chain has been pulled down about two feet and holds there with a click. Above, something heavy shifts and groans in the ceiling. The sound of stone grinding against stone echoes from the west wall. | The chain is extended, taut. The ring is lower now. Something clicked into place — you can't push it back up. | Same rust and iron. | Echoing grinding from the west — stone on stone. Then silence. |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| hanging | pulled | pull, yank, tug | — | "You grasp the iron ring and pull. The chain resists, then gives with a heavy CLUNK. Something mechanical shifts in the ceiling above. From the west wall comes the sound of stone grinding against stone — slow, deliberate, final." | `keywords = { add = "pulled" }` |

**Effect:**
Pulling the chain is an alternate mechanism that could:
- Unlock the crypt archway (alternative to offering-bowl puzzle)
- Reveal a hidden alcove in the west wall
- Be purely atmospheric (the mechanism is broken, nothing visible happens)

**Design note:** The exact effect is TBD (Bob/Wayne). The chain exists as a physical puzzle element — a lever the player can interact with. Its effect can be declared in the transition's `on_transition` callback.

### Spatial Context
- **Location:** Hanging from the vaulted ceiling, east side of the chamber
- **room_presence:** "An iron chain hangs from the ceiling, ending in a heavy ring at chest height."

### Puzzle Role
- **Puzzle 012 (Altar Puzzle):** Possibly an alternate trigger or a supporting mechanism. Coordinate with Bob.
- **Environmental storytelling:** Proves this chamber had mechanical elements — it was designed for a purpose.

### Principle 8 Compliance
Simple two-state FSM. The side effect (if any) is declared in `on_transition` metadata. No engine-specific code.

---

## Object Interaction Map

```
                    Deep Cellar — Object Relationships

    [stone-altar] ── surfaces ── top: [offering-bowl], [incense-burner], [tattered-scroll]
         │                         behind: [silver-key]
         │
         │  [tattered-scroll] ──READ──→ hint: "behind the place of offering"
         │                                          │
         │                                      leads to
         │                                          ▼
         │                              LOOK BEHIND ALTAR → [silver-key]
         │                                          │
         │                                      unlocks
         │                                          ▼
         │                              (stone archway → Crypt)
         │
         │  [offering-bowl] ──PLACE offering──→ triggers archway unlock
         │
    [chain] ──PULL──→ ??? (alternate mechanism, TBD)
    
    [wall-sconce] × 4-6 ── accepts light sources (candle, torch)
    
    [stone-sarcophagus] ──OPEN (requires leverage/crowbar)──→ lore/treasure
    
    STAIRWAY UP → Hallway (critical path, no object gate)
```

---

## Summary

| # | Object | Material | FSM? | Portable | Puzzle |
|---|--------|----------|------|----------|--------|
| 1 | stone-altar | stone ⚠️ NEW | No | No | 012 |
| 2 | wall-sconce | iron ✓ | Yes (2 states) | No | — (utility) |
| 3 | incense-burner | brass ✓ | No | Yes | 012 (lore) |
| 4 | tattered-scroll | paper ✓ | Yes (2 states) | Yes | 012 (hint) |
| 5 | silver-key | silver ⚠️ NEW | No | Yes | 012 (gate) |
| 6 | stone-sarcophagus | stone ⚠️ NEW | Yes (2 states) | No | — (exploration) |
| 7 | offering-bowl | ceramic ✓ | Yes (2 states) | Yes | 012 (trigger) |
| 8 | chain | iron ✓ | Yes (2 states) | No | 012 (mechanism) |
