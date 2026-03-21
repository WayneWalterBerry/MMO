# Level 1 — Crypt Objects

**Room:** The Crypt / The Burial Chamber  
**Room ID:** `crypt`  
**Author:** Flanders (Object Designer)  
**Date:** 2026-07-21  
**Status:** Specification — Ready for Build  
**Source:** `docs/levels/level-01-intro.md` (CBG Master Design)

---

## Room Context

A small, stone chamber with vaulted ceilings. Five stone sarcophagi line the walls, their lids carved with effigies of robed figures. The air is cold and still, heavy with dust and old wax. Candle stubs sit in wall niches, unlit for decades. Symbols cover the walls — religious iconography, names, dates. This is a family crypt, the burial place of the manor's original inhabitants.

This room is **optional** — accessible only by finding the silver key in the Deep Cellar and unlocking the stone archway.

**Connections:**
- EAST → Deep Cellar (stone archway — player just came through)

**Puzzle Support:**
- **Puzzle 014 (Sarcophagus Puzzle):** Optional. Open sarcophagi to find burial goods, lore, and the critical tome.

**Total Objects:** 9 new base objects (sarcophagus has 5 instances from 1 base)

**New Materials Needed:**
- `stone` — for sarcophagus, wall-inscription (shared with Deep Cellar spec)
- `silver` — for silver-dagger, burial-jewelry (shared with silver-key)
- `bone` — for skull

---

## Object 1: sarcophagus

### Identity
| Field | Value |
|-------|-------|
| **id** | `sarcophagus` |
| **name** | "a stone sarcophagus" |
| **keywords** | sarcophagus, coffin, stone coffin, tomb, casket, stone box |
| **categories** | furniture, stone, container |
| **weight** | 500 (kg — immovable carved granite) |
| **size** | 6 (massive) |
| **portable** | No |

### Material
`stone` — ⚠️ **NEW MATERIAL NEEDED.** (Same entry as deep-cellar stone objects.)

### FSM States & Transitions

```
closed → open
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell | on_listen |
|-------|--------------------|--------------------|----------|-----------|
| closed | A stone sarcophagus, its massive lid carved with the effigy of a robed figure. The hands are crossed over the chest, holding [instance-specific: a book / a sword / a cross / a chalice / nothing]. The face is serene but worn — features smoothed by time. Carved text runs along the base. | Cold stone. The effigy's features are faint under your fingers — robes, folded hands, a face worn nearly smooth. The seam between lid and base is sealed tight. You can trace carved letters along the base. | Sealed stone. Dust. The faintest suggestion of something old and dry beyond. | Stone holds silence like a prayer. |
| open | The sarcophagus lid has been pushed aside with great effort. Inside, old bones rest on a bed of rotted silk. [Instance-specific contents description.] The air that escapes is dry and impossibly old. | The lid is askew. Inside: dry bones, crumbling fabric. [Instance-specific: metallic objects, a leather-bound book, coins, nothing but dust.] | Dry death. Not rot — too old for that. Dust and mineral decay. Old fabric. And beneath it, a faint sweetness — embalming herbs, still detectable after centuries. | A soft sigh of ancient air when opened. Then silence. |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| closed | open | push, open, lift, slide | `requires_tool = "leverage"` — crowbar provides this. Without tool, two hands needed + strength check. | "You brace against the lid and push. Stone grinds against stone — a sound like the earth itself groaning. The lid shifts, slides, and comes to rest half-off. Ancient air exhales from the gap, carrying the scent of centuries. Inside: [instance-specific contents]." | `keywords = { add = "open" }` |

**Fail Messages:**
- Without leverage tool: "The lid must weigh hundreds of pounds. You strain against it until your arms tremble, but it won't budge. You need a lever."
- Without two free hands (even with tool): "You need both hands for this."

### Instance Overrides (5 sarcophagi)

Each sarcophagus has unique contents and effigy descriptions:

```lua
-- Sarcophagus 1: The Founder (contains tome)
{ type_id = "sarcophagus", id = "sarcophagus-1", overrides = {
    name = "the largest sarcophagus",
    states = {
        closed = {
            description = "The largest sarcophagus, set in the center of the north wall. The effigy depicts a bearded man in layered robes, hands clasping a thick book to his chest. The carving is the finest here — detailed and deliberate. Text along the base reads: 'ALDRIC BLACKWOOD — FOUNDER — REQUIESCAT IN PACE — 1197.'",
        },
        open = {
            description = "Inside: a skeleton in rotted robes, hands crossed where the book once lay. But the book is real — a thick, leather-bound tome rests beside the bones, remarkably preserved. Gold leaf glints on the cover. A silver ring encircles one bony finger.",
        },
    },
    surfaces = { inside = { contents = {"tome-1", "burial-jewelry-1"} } },
}}

-- Sarcophagus 2: The Scholar
{ type_id = "sarcophagus", id = "sarcophagus-2", overrides = {
    name = "a slender sarcophagus",
    states = {
        closed = {
            description = "A narrower sarcophagus against the east wall. The effigy shows a woman with long hair, hands folded over a quill and scroll. Text reads: 'ELEANOR BLACKWOOD — KEEPER OF THE WORD — 1221.'",
        },
        open = {
            description = "Inside: delicate bones in the remnants of a blue gown. A silver dagger lies across the skeleton's chest — ceremonial, ornate, sharp even after centuries. Coins are scattered around the skull.",
        },
    },
    surfaces = { inside = { contents = {"silver-dagger-1", "burial-coins-1"} } },
}}

-- Sarcophagus 3: The Warrior
{ type_id = "sarcophagus", id = "sarcophagus-3", overrides = {
    name = "a broad sarcophagus",
    states = {
        closed = {
            description = "A broad, heavy sarcophagus. The effigy shows a man in chain mail, hands gripping a sword hilt. The face is scarred even in stone. Text reads: 'EDMUND BLACKWOOD — SHIELD OF THE FAMILY — 1189.'",
        },
        open = {
            description = "Inside: a large skeleton in the corroded remnants of mail armor. The sword is gone — only a rust stain remains where it lay. But the skull grins up at you, and a single gold coin sits in each empty eye socket.",
        },
    },
    surfaces = { inside = { contents = {"skull-1", "burial-coins-2"} } },
}}

-- Sarcophagus 4: The Child
{ type_id = "sarcophagus", id = "sarcophagus-4", overrides = {
    name = "a small sarcophagus",
    states = {
        closed = {
            description = "A small sarcophagus — too small for an adult. The effigy depicts a child, hands clasping a flower. The carving is tender, grieving. Text reads: 'THOMAS BLACKWOOD — TAKEN TOO SOON — 1172.'",
        },
        open = {
            description = "Inside: small bones on a bed of rotted silk. A wooden toy horse, remarkably intact, lies beside the tiny skull. Nothing of material value. Only sadness.",
        },
    },
    surfaces = { inside = { contents = {} } },  -- toy horse is flavor text, not a useful object
}}

-- Sarcophagus 5: The Unknown
{ type_id = "sarcophagus", id = "sarcophagus-5", overrides = {
    name = "a plain sarcophagus",
    states = {
        closed = {
            description = "A plain sarcophagus in the corner, rougher than the others — less decorated. The effigy is crude, the face barely suggested. No text. No name. Whoever this was, they were important enough to be buried here but not important enough to be remembered.",
        },
        open = {
            description = "Inside: bones. Just bones. No fabric, no goods, no decoration. The skeleton's arms are not crossed — they're raised, hands clawing at the inside of the lid. This person was buried alive.",
        },
    },
    surfaces = { inside = { contents = {} } },
}}
```

### Surfaces
```lua
surfaces = {
    inside = {
        capacity = 4, max_item_size = 3, weight_capacity = 30,
        contents = {},  -- instance override determines contents
        accessible = false,  -- closed
    },
    top = {  -- the lid surface
        capacity = 2, max_item_size = 2, weight_capacity = 10,
        contents = {},
        accessible = true,
    },
}
```

### Spatial Context
- **Location:** Lining the walls of the crypt. 5 instances positioned north, east (×2), west, and corner.
- **room_presence:** "Five stone sarcophagi line the walls, their carved effigies staring upward in eternal repose."

### GOAP Prerequisites
```lua
prerequisites = {
    open = { requires = {"leverage"}, auto_steps = {"take crowbar"} },
}
```

### Puzzle Role
- **Puzzle 014 (Sarcophagus Puzzle):** Core interaction. Each sarcophagus is a mini-discovery — some rewarding (tome, dagger, coins, jewelry), some atmospheric (child's grave), one disturbing (buried alive). The Founder's sarcophagus contains the critical tome.

### Principle 8 Compliance
Single base object with 5 instance overrides. FSM controls lid state and surface accessibility. Tool requirement (`leverage`) declared in metadata. Contents declared per-instance. No engine-specific code.

---

## Object 2: candle-stub

### Identity
| Field | Value |
|-------|-------|
| **id** | `candle-stub` |
| **name** | "a candle stub" |
| **keywords** | candle, candle stub, stub, wax stub, old candle, nub |
| **categories** | light source, small |
| **weight** | 0.1 (kg — barely any wax left) |
| **size** | 1 (tiny) |
| **portable** | Yes |

### Material
`tallow` — ✓ In registry. Old tallow, yellowed and cracked with age.

### FSM States & Transitions

```
unlit → lit → spent (terminal)
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell | Special |
|-------|--------------------|--------------------|----------|---------|
| unlit | A candle stub in a wall niche, barely an inch of yellowed tallow clinging to a blackened wick. It's been here for decades — maybe centuries. The wax is cracked and discolored. But the wick looks intact. | A tiny nub of hard wax, cracked and brittle. The wick protrudes — stiff and charred. It's been a long time since this burned. | Old tallow — stale, waxy, faintly rancid. | `casts_light = false` |
| lit | The candle stub burns with a small, trembling flame. The old tallow melts quickly — this won't last long. A thin pool of liquid wax forms around the base. The light is feeble but precious in this dark place. | Warm, soft wax. The stub is melting fast — your fingers get sticky. | Burning tallow — sharper than a fresh candle. Old wax has a rancid edge. | `casts_light = true, light_radius = 1, provides_tool = "fire_source"` |
| spent | A flat disc of hardened wax and a charred wick. The candle stub is consumed. | A thin wafer of hard wax. The wick is a carbon thread. | Ghost of tallow. | `casts_light = false, terminal = true` |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| unlit | lit | light, ignite | `requires_tool = "fire_source"` | "The ancient wick catches — reluctantly, as if it had forgotten how. A small, trembling flame. It won't last long, but it's light." | — |
| lit | spent | — | `trigger = "auto", condition = "timer_expired"` | "The candle stub sputters and dies. The old tallow is consumed. Darkness returns." | `weight = 0.02, categories = { remove = "light source" }, keywords = { add = "spent" }` |

**Timer:**
```lua
burn_duration = 1800,    -- 30 minutes game time (5 ticks) — very short, ancient wax
remaining_burn = 1800,
```

**Notes:**
- Multiple instances in wall niches around the crypt (3-4 stubs).
- Very short burn time — these are ancient candles, not fresh ones. They provide emergency light, not sustained illumination.
- Follows the candle consumable pattern but simplified (no extinguish/relight — too short to bother).

### Spatial Context
- **Location:** In small wall niches around the crypt. 3-4 instances.
- **room_presence:** "Candle stubs sit in wall niches, dark and forgotten."

### GOAP Prerequisites
```lua
prerequisites = {
    light = { requires = {"fire_source"} },
}
```

### Puzzle Role
- **Puzzle 014:** Emergency light sources for exploring the crypt if the player's main light source is running low. Very short-lived — adds urgency.

### Principle 8 Compliance
Simplified consumable cycle. Timer-based auto-depletion. All behavior in metadata.

---

## Object 3: skull

### Identity
| Field | Value |
|-------|-------|
| **id** | `skull` |
| **name** | "a human skull" |
| **keywords** | skull, head, bone, bones, cranium, death's head |
| **categories** | bone, small, macabre |
| **weight** | 0.5 (kg) |
| **size** | 2 (small) |
| **portable** | Yes |

### Material
`bone` — ⚠️ **NEW MATERIAL NEEDED.** Suggested properties: density 1900, melting_point nil, ignition_point 800 (bone chars at very high temp), hardness 5, flexibility 0.0, absorbency 0.1, opacity 1.0, flammability 0.05, conductivity 0.1, fragility 0.4, value 1.

### FSM States & Transitions
None — static object.

### Sensory Properties

| Sense | Description |
|-------|-------------|
| description | A human skull, yellowed with age and missing the lower jaw. The cranium is smooth and intact. Empty eye sockets stare at nothing. The teeth in the upper jaw are mostly intact — worn but present. It weighs less than you'd expect. |
| on_feel | Smooth bone, cool and dry. The dome of the skull fits in your palm. Eye sockets — smooth-edged, hollow. Teeth: small, hard bumps along the upper jaw. A crack runs along the left temple. Light. Fragile. |
| on_smell | Dry bone. Dust. Nothing organic remains — this skull is very, very old. |
| on_taste | (If player tries:) Dry, chalky, slightly gritty. This is the taste of mortality. Please stop. |

### Spatial Context
- **Location:** Inside sarcophagus instances (contents of opened sarcophagi). Also possibly on a shelf or in an alcove as atmospheric detail.
- **room_presence:** Not independently present — found inside sarcophagi.

### Puzzle Role
- None directly. Environmental/atmospheric object. Could be used as a macabre container (place objects in skull — hat-tip to Hamlet) or thrown as improvised projectile.

### Principle 8 Compliance
Static metadata object. Standard property pattern.

---

## Object 4: burial-jewelry

### Identity
| Field | Value |
|-------|-------|
| **id** | `burial-jewelry` |
| **name** | "a tarnished silver ring" |
| **keywords** | ring, silver ring, jewelry, burial ring, treasure, band |
| **categories** | treasure, metal, small, wearable |
| **weight** | 0.05 (kg) |
| **size** | 1 (tiny) |
| **portable** | Yes |

### Material
`silver` — ⚠️ **NEW MATERIAL NEEDED.** (Same entry as silver-key.)

### FSM States & Transitions
None — static object.

### Sensory Properties

| Sense | Description |
|-------|-------------|
| description | A silver ring, tarnished nearly black. It's a simple band with a small engraved symbol — the same eye-and-triangle motif from the deep cellar altar. Inside the band, tiny letters are inscribed: "CUSTOS" — Latin for "guardian" or "keeper." |
| on_feel | A thin metal band, smooth inside, with a raised engraving on the outside. Light. Cold. It fits your finger. |
| on_smell | Tarnished silver — faint, sweet-metallic. |

### Spatial Context
- **Location:** Inside Sarcophagus 1 (The Founder). On the skeleton's finger.
- **Instance overrides** could create additional jewelry items (necklace, brooch) for other sarcophagi.

### Puzzle Role
- **Lore delivery:** The inscription "CUSTOS" and the eye-triangle symbol connect to the deep cellar altar symbolism.
- **Possible future use:** The ring might be needed for a Level 2 puzzle (identity proof, lock mechanism, offering).
- **Treasure:** Has economic value if a trade system is implemented.

### Principle 8 Compliance
Static metadata object with lore description.

---

## Object 5: burial-coins

### Identity
| Field | Value |
|-------|-------|
| **id** | `burial-coins` |
| **name** | "a handful of old coins" |
| **keywords** | coins, money, gold coins, silver coins, treasure, currency, obol |
| **categories** | treasure, metal, small |
| **weight** | 0.3 (kg — a small handful) |
| **size** | 1 (small) |
| **portable** | Yes |

### Material
`silver` — ⚠️ **NEW MATERIAL NEEDED.** (Mix of silver and copper coins; primary material silver for property resolution.)

### FSM States & Transitions
None — static object.

### Sensory Properties

| Sense | Description |
|-------|-------------|
| description | A handful of old coins — some silver, some copper, all tarnished and corroded. The faces stamped on them are unfamiliar — no king or saint you recognize. The dates are illegible. These coins are ancient, from a currency that no longer exists. They might be worth something to a collector, if you ever find one. |
| on_feel | Small, thin metal discs, rough with corrosion. Different sizes and weights. Some have raised designs — faces, crosses, symbols. They clink together satisfyingly. |
| on_smell | Tarnished metal — copper and silver. A green patina on the copper ones. |
| on_taste | Metallic. Sour copper and sweet silver. Old money tastes the same as new money — disappointing. |

### Spatial Context
- **Location:** Inside sarcophagi. Scattered around the bones. Multiple instances in different sarcophagi.

### Puzzle Role
- **Treasure:** Economic value for future trade system.
- **Lore:** The unfamiliar currency suggests the Blackwood family predates the current kingdom/era.
- **Possible offering:** Coins could be a valid offering for the altar bowl (Puzzle 012) if placed before accessing the crypt — but the player would need to discover this through experimentation.

### Principle 8 Compliance
Static metadata object.

---

## Object 6: tome

### Identity
| Field | Value |
|-------|-------|
| **id** | `tome` |
| **name** | "a leather-bound tome" |
| **keywords** | tome, book, leather book, ledger, volume, manuscript, diary, journal |
| **categories** | readable, treasure |
| **weight** | 2 (kg — thick, heavy, leather-bound) |
| **size** | 3 (medium) |
| **portable** | Yes |

### Material
`leather` — ✓ In registry. Thick leather binding, gilt edges, vellum pages.

### FSM States & Transitions

```
closed → open (readable)
```

**States:**

| State | description (sight) | on_feel (touch/dark) | on_smell |
|-------|--------------------|--------------------|----------|
| closed | A thick, leather-bound tome. The cover is embossed with the eye-and-triangle symbol in gold leaf, much of it flaked away. The spine is cracked but intact. Iron clasps hold it shut — not locked, just stiff with age. This book has been sealed in a sarcophagus for centuries, yet it's remarkably well-preserved. | Heavy, thick leather. The embossed symbol is raised under your fingertips — an eye in a triangle. Iron clasps, cold and stiff. The pages are thick — parchment, not paper. | Old leather, aged vellum, and a hint of iron-gall ink. The smell of preserved knowledge. Centuries of silence. |
| open | The tome lies open, its pages thick and yellowed. The handwriting is cramped and archaic but readable — the author intended this to be understood. The text is a mixture of Latin and the common tongue, illustrated with diagrams and symbols. This is a chronicle — the history of the Blackwood family and their purpose. | Thick vellum pages, smooth but fragile. The ink is raised slightly — hand-written with care. The binding creaks when turned. | Stronger ink smell now. Old vellum. The breath of centuries released. |

**Transitions:**

| From | To | Verb | Guard / Requires | Message | Mutate |
|------|-----|------|-----------------|---------|--------|
| closed | open | open, read, unclasp | — | "You work the iron clasps free — they resist, then give with a dry click. The cover opens heavily, releasing a breath of ancient air. The pages within are covered in dense, careful handwriting." | `keywords = { add = "open" }` |

**Readable Text (when READ in open state):**

```
THE CHRONICLE OF THE BLACKWOOD FAMILY
As set down by Lord Aldric Blackwood, Founder and First Keeper

In the year of our Lord 1138, I, Aldric, did discover beneath this hill
a chamber of ancient making — older than memory, older than the faith
that now claims these lands. The symbols upon its walls spoke of a duty:
to guard what sleeps below, and to ensure it never wakes.

I built this manor above the chamber, and my family has kept the vigil
ever since. We are the Custodes — the Keepers. Each generation inherits
the burden. The altar is our covenant. The offering is our oath.

If you read these words, I am gone. The vigil has passed to you, whether
you chose it or not. Guard well. Speak the words at the altar. And never,
never open the [final pages are torn out — the text ends abruptly].
```

**Design note:** The exact lore text is Wayne's domain. This is placeholder that establishes the Blackwood family as guardians of something sealed beneath the manor. The torn-out pages are a deliberate hook for Level 2+.

### Spatial Context
- **Location:** Inside Sarcophagus 1 (The Founder). Beside the skeleton.
- **room_presence:** Not independently present — found inside the sarcophagus.

### GOAP Prerequisites
```lua
prerequisites = {
    read = { requires_state = "open" },
}
```

### Puzzle Role
- **Puzzle 014 (Sarcophagus Puzzle):** The ultimate reward. The tome reveals the manor's purpose and the player's (unwitting) new role.
- **Critical lore item:** This is the most important narrative object in Level 1. Finding it transforms the player's understanding of the story.
- **Hook for Level 2+:** The torn-out pages and the warning ("never open the...") create urgency and mystery.

### Principle 8 Compliance
Two-state FSM (closed/open). Readable text in state metadata. All behavior declared.

---

## Object 7: silver-dagger

### Identity
| Field | Value |
|-------|-------|
| **id** | `silver-dagger` |
| **name** | "a silver dagger" |
| **keywords** | dagger, silver dagger, knife, blade, weapon, ceremonial dagger |
| **categories** | weapon, tool, metal, treasure, sharp |
| **weight** | 0.5 (kg) |
| **size** | 2 (small) |
| **portable** | Yes |

### Material
`silver` — ⚠️ **NEW MATERIAL NEEDED.** (Same entry as silver-key/burial-jewelry.)

### FSM States & Transitions
None — static object.

### Sensory Properties

| Sense | Description |
|-------|-------------|
| description | A silver dagger, tarnished but sharp. The blade is leaf-shaped and double-edged, about eight inches long. The hilt is wrapped in wire and set with a small dark stone — garnet, perhaps. Symbols are etched along the blade — the same recurring motifs from the altar and walls. This is a ceremonial weapon, not a battlefield one. But it would still cut. |
| on_feel | Cold metal, smooth. The blade has edges — sharp, even after centuries. The wire-wrapped hilt fits your hand well. The pommel stone is smooth and cool. Lighter than an iron knife but well-balanced. |
| on_smell | Tarnished silver. A faint, sweet metallic scent — different from the iron of the crowbar or the brass of the key. |
| on_listen | A faint ring when tapped — silver sings. |

### Tool Capabilities
```lua
provides_tool = {"cutting_edge", "injury_source", "ritual_blade"},
```
- `cutting_edge` — CUT, SLASH, CARVE actions
- `injury_source` — can cause injury (to self or others)
- `ritual_blade` — for ritual/ceremonial interactions (future Level 2+ puzzles)

### Spatial Context
- **Location:** Inside Sarcophagus 2 (The Scholar). Lying across the skeleton's chest.

### Puzzle Role
- **Treasure:** Functional weapon/tool with ceremonial significance.
- **Future use:** The `ritual_blade` capability hints at Level 2+ puzzle requirements.
- **Upgrade:** Better cutting tool than the iron knife from the bedroom (sharper, ceremonial significance, lighter).

### Principle 8 Compliance
Static tool object with `provides_tool` capabilities. Standard metadata pattern.

---

## Object 8: wall-inscription

### Identity
| Field | Value |
|-------|-------|
| **id** | `wall-inscription` |
| **name** | "a wall inscription" |
| **keywords** | inscription, writing, carving, text, words, engraving, epitaph |
| **categories** | readable, architecture |
| **weight** | — (part of the wall, immovable) |
| **size** | 6 (covers a wall section) |
| **portable** | No |

### Material
`stone` — ⚠️ **NEW MATERIAL NEEDED.** (Carved into the stone walls.)

### FSM States & Transitions
None — static examinable object.

### Sensory Properties

| Sense | Description |
|-------|-------------|
| description | Carved text covers a section of the crypt's south wall. The letters are deep-cut and filled with faded gold paint. The text is in Latin, with some words in the common tongue. Names, dates, blessings — and warnings. |
| on_feel | Deep-carved letters in stone. Your fingers trace the grooves — each letter is about an inch tall, precise and deliberate. Gold paint flakes away at your touch. |
| on_smell | Old stone and dust. |

**Readable Text (when EXAMINE or READ):**

```
HERE LIE THE CUSTODES — THE KEEPERS OF THE COVENANT

ALDRIC BLACKWOOD — FOUNDER — 1138-1197
"I built this house upon the secret, and the secret kept us all."

ELEANOR BLACKWOOD — KEEPER OF THE WORD — 1165-1221
"She wrote the truth when others would forget."

EDMUND BLACKWOOD — SHIELD OF THE FAMILY — 1142-1189
"He stood between the world and what lies below."

THOMAS BLACKWOOD — TAKEN TOO SOON — 1168-1172
"The innocent see what the wise refuse to."

[A fifth name has been chiseled away. Only fragments remain:
"------- BLACKWOOD — THE L---T — 11---12--"
"Struck from the record by order of the K------"]
```

**Design note:** The erased name is a mystery hook — who was removed from the family record, and why? This connects to the nameless portrait in the hallway and the fifth sarcophagus (plain, no inscription, buried alive).

### Spatial Context
- **Location:** South wall of the crypt, between two sarcophagi
- **room_presence:** "Carved inscriptions cover the south wall in deep-cut gold letters."

### Puzzle Role
- **Lore delivery:** The most concentrated lore source in Level 1. Names match the portraits in the hallway and the sarcophagus effigies. The erased name is a mystery.
- **Cross-referencing:** Players who examined the hallway portraits, the altar scroll, and now these inscriptions can piece together the Blackwood family history.

### Principle 8 Compliance
Static readable object. Text is metadata. No engine-specific code.

---

## Object Interaction Map

```
                    Crypt — Object Relationships

    [sarcophagus] × 5 ── OPEN (requires leverage/crowbar) ──→ contents:
         │
         ├── #1 (Founder): [tome], [burial-jewelry]
         ├── #2 (Scholar): [silver-dagger], [burial-coins]
         ├── #3 (Warrior): [skull], [burial-coins]
         ├── #4 (Child): (empty — narrative impact)
         └── #5 (Unknown): (empty — buried alive, horror)
    
    [candle-stub] × 3-4 ── LIGHT (fire_source) → brief illumination
    
    [wall-inscription] ── READ → lore (names match portraits + sarcophagi)
    
    [tome] ── READ → critical narrative (Blackwood history, player's new role)
    
    Cross-references:
    ├── [wall-inscription] names ←→ [portrait] names (Hallway)
    ├── [wall-inscription] symbols ←→ [stone-altar] symbols (Deep Cellar)
    ├── [burial-jewelry] "CUSTOS" ←→ [tome] "Custodes"
    └── [sarcophagus-5] unnamed ←→ erased inscription ←→ nameless portrait
```

---

## Summary

| # | Object | Material | FSM? | Portable | Puzzle |
|---|--------|----------|------|----------|--------|
| 1 | sarcophagus (×5) | stone ⚠️ NEW | Yes (2 states) | No | 014 |
| 2 | candle-stub (×3-4) | tallow ✓ | Yes (3 states) | Yes | — (utility) |
| 3 | skull | bone ⚠️ NEW | No | Yes | — (atmospheric) |
| 4 | burial-jewelry | silver ⚠️ NEW | No | Yes | Lore |
| 5 | burial-coins | silver ⚠️ NEW | No | Yes | Treasure |
| 6 | tome | leather ✓ | Yes (2 states) | Yes | 014 (critical lore) |
| 7 | silver-dagger | silver ⚠️ NEW | No | Yes | Tool/treasure |
| 8 | wall-inscription | stone ⚠️ NEW | No | No | Lore |
| 9 | — (effigy) | stone ⚠️ NEW | No | No | (part of sarcophagus) |

**Note on effigy:** The effigy is NOT a separate object. It is part of the sarcophagus's `closed` state description. The carved figure on the lid is described in each sarcophagus instance's sensory properties. This avoids an unnecessary object and follows the principle that descriptions should paint the scene, not fragment it into disconnected parts.
