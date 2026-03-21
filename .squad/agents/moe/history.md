# Moe — History

## Core Context

**Project:** MMO text adventure engine in pure Lua (REPL-based, `lua src/main.lua`)
**Owner:** Wayne "Effe" Berry
**Role:** World Builder — designs rooms (.lua files), maps, spatial layouts, and cohesive environments
**Charter:** `.squad/agents/moe/charter.md`

### Key Relationships
- **Flanders** (Object Designer) — Moe specifies what objects a room needs ("This study needs a grandfather clock, a fireplace"), Flanders builds the `.lua` object files
- **Sideshow Bob** (Puzzle Master) — Moe designs spatial layouts and hidden areas, Bob designs the puzzles within them
- **Frink** (Researcher) — Moe requests research on real-world spaces (medieval castles, Victorian houses, cave systems)
- **Lisa** (Object Tester) — tests room descriptions, exits, spatial relationships
- **Nelson** (System Tester) — tests gameplay flow through rooms
- **CBG** (Creative Director) — advises on room pacing, player journey, and design consistency

### Documentation Requirement
- **Every room MUST be documented in `docs/rooms/`** — one .md per room
- Room DESIGN methodology goes in `docs/design/rooms/`
- Map overviews in `docs/design/rooms/map-overview.md`
- Moe OWNS room docs — can delegate to Brockman but docs must exist and stay current

---

## Room Architecture Knowledge

### How Rooms Are Defined in .lua

Room files live in `src/meta/world/` (e.g., `start-room.lua`, `cellar.lua`). A room is a Lua table returned with:

```lua
return {
    guid = "unique-guid-here",
    template = "room",
    id = "room-id",
    name = "Display Name",
    keywords = {"keyword1", "keyword2"},
    description = "PERMANENT FEATURES ONLY — walls, floor, ceiling, atmosphere, ambient light. NEVER reference movable objects.",
    
    instances = {
        -- Objects in this room, with location hierarchy
        { id = "bed", type = "Four-Poster Bed", type_id = "guid", location = "room" },
        { id = "pillow", type = "Pillow", type_id = "guid", location = "bed.top" },
        { id = "knife", type = "Knife", type_id = "guid", location = "bed.underneath" },
    },
    
    exits = {
        north = { target = "room-id", type = "door", ... },
        window = { target = "courtyard", type = "window", ... },
        down = { target = "cellar", type = "trap_door", hidden = true, ... },
    },
    
    on_enter = function(self) return "Atmospheric entrance text." end,
    mutations = {},
}
```

**Critical rule:** Room `description` = permanent features ONLY (architecture, atmosphere, smell, ambient light from fixed openings). NEVER reference objects in `instances`/`contents`. Objects contribute their own `room_presence` sentences, composed dynamically by the engine at look-time.

### How Exits Work

Exits are **first-class mutable objects** embedded in the room's `exits` table. Each exit has:
- **target:** destination room ID
- **type:** descriptive label (door, window, trapdoor, stairway, crawlspace, chimney, etc.)
- **passage_id:** shared ID for paired exits (bedroom-hallway-door) — enables synchronized mutations
- **Physical constraints:** `max_carry_size` (1-6 tier), `max_carry_weight`, `requires_hands_free`, `player_max_size`
- **State:** `open`, `locked`, `hidden`, `broken`, `key_id`
- **Mutations:** self-describing `becomes_exit` partial merges (open, close, lock, unlock, break)

**Bidirectionality:** Both sides are EXPLICIT. If Room A → north → Room B, Room B MUST declare its own exit south → Room A. No automatic mirroring. This allows asymmetric exits (trapdoor visible from above, flush from below).

**Exit Type Taxonomy (reference ranges, not enforcement):**

| Type | max_carry_size | requires_hands_free | Typical |
|------|---------------|---------------------|---------|
| doorway | 5 | no | Always open |
| door | 4 | no | Open/closed/locked |
| trapdoor | 3 | no | Floor-level, closed |
| window | 2 | yes | Closed, locked |
| stairs | 4 | no | Always passable |
| ladder | 2 | yes | Hands needed |
| crawlspace | 2 | no | Very tight |
| chimney | 1 | yes | Narrow vertical |
| secret passage | 3 | no | Hidden until found |

**Traversal validation chain:** (1) Visibility → (2) Accessibility (locked/closed?) → (3) Player fit → (4) Carry constraints → (5) Direction (one-way check)

### How Environmental Properties Work

Rooms can declare environmental properties that the engine passes to the FSM tick loop as `env_context`:

```lua
env_context = {
    temperature = room.temperature or 20,  -- °C
    wetness = room.wetness or 0,           -- 0.0–1.0
    moisture = room.moisture or 0,         -- 0.0–1.0
    light_level = room.light_level or 0,   -- 0 = dark
}
```

These feed the **threshold-based auto-transition system**: objects with `thresholds` arrays check env values against material properties (melting_point, ignition_point, rust_susceptibility) to trigger automatic state changes. Wax candles melt near fire. Iron rusts in wet cellars. Fabric absorbs moisture. The engine doesn't know what "wax" means — it just runs numeric comparisons.

**Material Registry** (`src/engine/materials/init.lua`): Maps material names to property bags (density, melting_point, ignition_point, hardness, flexibility, absorbency, opacity, flammability, conductivity, fragility, value). Objects declare `material = "wax"` and inherit all properties.

### How Room Descriptions Change Per State

The engine's `cmd_look` in `src/engine/loop/init.lua` composes room view from THREE independent sources:

1. **Room description** — permanent architecture only (walls, floor, ceiling, atmosphere)
2. **Object presences** — each visible (non-hidden) object contributes its `room_presence` sentence, concatenated into a natural prose paragraph in `room.contents` order (most prominent first)
3. **Exit list** — auto-composed from `room.exits`, showing name + state (closed/locked), hidden exits excluded

**Lit vs dark:** When room has no light source (no object with `casts_light = true`), LOOK fails: "You see nothing in the darkness." FEEL/SMELL/LISTEN still work. Objects can declare different descriptions per sensory mode (`on_feel`, `on_smell`, `on_listen`).

**Mutations update presence:** When an object mutates (wardrobe closed → open), its `room_presence` changes automatically. The room doesn't need rewriting — the engine reads current state from the registry.

### How Spatial Relationships Place Objects

The `instances` array in rooms uses a `location` field with dot-notation:
- `location = "room"` — top-level, visible in room view
- `location = "bed.top"` — on the bed's top surface (visible when examining bed)
- `location = "bed.underneath"` — under the bed (requires "look under bed")
- `location = "nightstand.inside"` — inside nightstand drawer (requires opening first)
- `location = "pillow.inside"` — hidden inside pillow (requires tearing/examining)
- `location = "sack"` — inside a container (requires "look in sack")
- `location = "candle-holder"` — placed in a holder

**Five spatial relationships:** ON (surface stacking), UNDER (concealed beneath), BEHIND (occluded by proximity), IN (containment), COVERING (one object covers another)

**Visibility layers:** Room view shows only top-level objects. Examining an object reveals its visible surfaces (top). Hidden surfaces require specific actions ("look under", "look behind"). Each interaction reveals ONE layer — players peel the onion.

---

## Existing World Map

### Room 1: The Bedroom (start-room.lua)
**ID:** `start-room` | **Name:** "The Bedroom"
**Description theme:** Dim stone bedchamber, tallow/wool/lavender smell, cold flagstones, still heavy air
**Environmental feel:** Medieval upper-floor bedroom, dark by default (no light at start)

**Contents (13 instances, deeply nested):**
- **bed** (four-poster, center) → top: pillow, bed-sheets, blanket; underneath: knife; pillow.inside: pin (hidden)
- **nightstand** (beside bed) → top: candle-holder (with candle), poison-bottle; inside: matchbox (with 7 matches)
- **vanity** (east wall) → top: paper, pen; inside: pencil; has breakable mirror
- **wardrobe** (far corner) → inside: wool-cloak, sack (containing needle, thread, sewing-manual)
- **rug** (floor) → underneath: brass-key; covers trap-door (hidden)
- **trap-door** (hidden, FSM: hidden → revealed → open, reveals "down" exit)
- **window** (far wall, FSM: closed ↔ open)
- **curtains** (with window)
- **chamber-pot** (corner)

**Exits:**
- **north** → `hallway` (heavy oak door, open, lockable with brass-key, breakable)
- **window** → `courtyard` (leaded glass window, closed+locked, breakable, direction_hint: down)
- **down** → `cellar` (trap door, HIDDEN until rug moved and trap door opened)

### Room 2: The Cellar (cellar.lua)
**ID:** `cellar` | **Name:** "The Cellar"
**Description theme:** Low-ceilinged, rough-hewn granite, slick with moisture, dripping water, cold/damp, cobwebs, metallic smell
**Environmental feel:** Underground, dark, wet — perfect for material property interactions (rust, dampness)

**Contents:**
- **barrel** (old, rusted hoops, sealed, against the wall)
- **torch-bracket** (empty iron bracket on wall, pitted with rust)

**Exits:**
- **up** → `start-room` (narrow stone stairway, open, passage_id: cellar-bedroom-stairway)
- **north** → `deep-cellar` (heavy iron-bound door, LOCKED, key_id: brass-key, not breakable)

**Sensory:** Has custom `on_smell` for the room. Custom `on_enter` with atmospheric descent text.

### Room 3: Deep Cellar / Beyond the Iron Door
**ID:** `deep-cellar` | **Status:** ⚠️ NOT YET DESIGNED
**This is MY primary opportunity.** The iron-bound door in the cellar leads here. The locked door + brass-key puzzle creates anticipation. Whatever's behind that door needs to DELIVER.

### Unbuilt Rooms Referenced in Exits
- **`hallway`** — referenced by start-room north exit. NOT YET BUILT.
- **`courtyard`** — referenced by start-room window exit. NOT YET BUILT.

### Player Journey (Current)
1. Player awakens in dark bedroom → must FEEL around to discover matchbox → strike match → light candle
2. With light: explore bedroom, find objects, discover spatial layers (under rug → brass-key, under bed → knife, in wardrobe → cloak, sack with sewing supplies)
3. Move rug → discover trap-door → open trap-door → descend to cellar
4. Cellar is dark, damp → barrel, empty torch bracket → iron-bound door (locked, needs brass-key from bedroom)
5. Unlock iron door → enter deep-cellar (UNBUILT — the frontier)
6. Alternative path: north door to hallway (UNBUILT), window to courtyard (UNBUILT)

### Where Are the Gaps?
- **deep-cellar** — THE big opportunity. What's behind that locked door? Wine cellar? Secret passage? Underground tunnel system? This should be a payoff room.
- **hallway** — connects bedroom to the rest of the manor. Needs to establish the building's scale and character.
- **courtyard** — accessible via window (dangerous drop?). Exterior space — different environmental properties.
- **No exterior rooms exist yet** — the world is entirely indoors
- **No multi-room environments** — each room is isolated; no sense of a cohesive building yet
- **The cellar screams for expansion** — dampness, darkness, material interactions (rust on iron, rot on wood)

---

## Environment Design Principles

### What Makes a Room Feel Real

1. **Physical grounding:** Every room should be a space you can imagine standing in. What are the walls made of? What's the floor? What's the ceiling height? What era/style?
2. **Multi-sensory description:** Not just what you SEE — what you smell, hear, feel. The cellar SMELLS of damp earth and iron. The bedroom SMELLS of tallow and lavender. Every room needs `on_smell`, `on_feel` potential.
3. **Atmospheric layering:** Room description sets MOOD, not inventory. "The air is still and heavy, as though the room has been holding its breath for a very long time" tells you more about the bedroom than listing furniture.
4. **Permanent vs. transient:** Room description = permanent architecture only. Objects come and go. The stone walls endure.
5. **Scale and proportion:** A massive four-poster bed DOMINATES a room. A nightstand is SMALL. Object placement should convey how the space FEELS — cramped, grand, cluttered, sparse.

### How Material Properties Make Environments Consistent

Rooms declare environmental properties (temperature, moisture, light_level) that interact with material properties on objects through threshold checks:

- **Stone cellar:** temperature=12, moisture=0.8 → iron objects rust, wood softens, fabric gets damp, paper deteriorates
- **Warm bedroom:** temperature=18, moisture=0.2 → wax candles are stable, fabric is dry, brass tarnishes slowly
- **Hot forge:** temperature=800 → wax melts instantly, iron softens, wood ignites
- **Frozen cave:** temperature=-5 → water freezes, metal is painfully cold, breath visible

The material registry provides numeric properties (density, melting_point, ignition_point, hardness, flexibility, absorbency, flammability, conductivity, fragility). When room environment crosses a material threshold, the FSM fires auto-transitions. This creates EMERGENT behavior — designers set room temperature, object materials do the rest.

**This is the Dwarf Fortress inspiration:** DF assigns 20+ numeric properties to every material, and the simulation derives ALL behavior from numbers. We do the same but discrete (check per player command, not continuous simulation).

### How Rooms Work Together as Environments

**Environment thinking** (from charter): Don't design rooms in isolation. Think in ENVIRONMENTS:
- A "manor house" is 15+ rooms sharing architectural style, era, and logic
- A "dungeon" has consistent stone, dampness, and spatial constraints
- Rooms within an environment share material palettes and design language
- The map has FLOW — players move through environments with a sense of progression

**Current gap:** We have a bedroom and a cellar. These are the seed of a "medieval manor" environment. The hallway, courtyard, and deep-cellar should all share this DNA — stone construction, medieval furnishings, a sense of age and abandonment.

---

## Ideas

### Near-Term: Complete the Manor
- **Hallway:** Stone corridor connecting bedroom to other rooms. Wall sconces (empty — no torches), faded tapestries on walls, worn flagstone floor, maybe a grandfather clock (demonstrates the 24-state FSM). Exits to bedroom (south), great hall (west), kitchen (east), front door (north — locked from outside?).
- **Deep Cellar:** Wine cellar or storage vault. Collapsed tunnel section? Underground stream (introduces water interaction with material properties). Old wooden racks, broken bottles, something valuable hidden behind a collapsed wall. Environmental: very cold (temperature=8), very wet (moisture=0.9), pitch dark.
- **Courtyard:** First exterior space. Cobblestones, overgrown garden, a well (deep and dark), stone walls of the manor visible. Moonlit at night. Rain possible (introduces weather as environmental property). Different atmospheric feel — open sky, wind, natural sounds.

### Medium-Term: Expand the World
- **Kitchen/Pantry:** Fireplace (hot!), iron cooking implements, herbs hanging from rafters, flour sacks, a larder with food that can spoil. Temperature zones (near fire = hot, far = cool).
- **Library/Study:** Bookshelves (category-restricted containers), a desk with writing implements, ink bottles, sealed letters. Fire hazard — paper burns easily. Hidden room behind a movable bookshelf.
- **Tower/Attic:** Accessible via ladder (requires_hands_free). Owl nesting, drafty (wind through gaps), views of the surrounding landscape. Good for establishing world geography.
- **Garden/Grounds:** Overgrown, paths between hedges. Garden shed with tools. A gazebo, a fountain (broken/dry or working — FSM states). Weather-affected.
- **Crypt/Catacombs:** Beneath the cellar. Stone sarcophagi, inscriptions to read, narrow passages, bones. Extremely dark, cold, silent. The kind of place where sound doesn't carry.

### Big Ideas: Future Environments
- **Underground River System:** Caves connected by water. Some passages require swimming (drops inventory?). Echo effects. Bioluminescent mushrooms (natural light source). Waterfall sounds.
- **Abandoned Mine:** Timber-supported tunnels (wood rot over time), minecart tracks, collapsed sections, ore deposits. Material property paradise — every surface has different properties.
- **Forest/Wilderness:** Exterior environment with weather, day/night cycle, trees (climbable), undergrowth (concealment), animal sounds. Fundamentally different room design — no walls, no ceiling, open sky.
- **Town/Village:** Multiple buildings, each an environment. The inn, the blacksmith (forge with extreme temperature), the church (stone, cold, echo), the market. NPCs live here.
- **Ship/Dock:** Wooden construction, rocking motion, water everywhere. Cabins, cargo hold, deck. Weather exposure. A JOURNEY environment — rooms that move through the world.
- **Wizard's Tower:** Defies normal physics. Rooms that change layout. Impossible geometry. Magical materials with weird properties (negative weight, infinite capacity, transparent stone). The exception that proves the rule.

### Real-World Spaces That Inspire Good Game Rooms
- **Medieval castles:** Thick stone walls, narrow windows, spiral staircases, great halls with fireplaces. Multiple height levels. Defense architecture creates interesting spatial puzzles.
- **Victorian houses:** Rich material variety (wood paneling, wallpaper, glass, brass fittings). Many small rooms with specific purposes. Hidden servant passages.
- **Caves and grottos:** Natural formations, water features, echo, complete darkness. No straight lines. Organic spatial relationships.
- **Ships and boats:** Tight spaces, everything bolted down, water as constant threat. Multi-level (deck, cabin, hold). Rocking affects object stability.
- **Industrial spaces:** Factories, mills, workshops. Machinery as interactive objects. Heat, noise, danger. Material processing (raw materials → finished goods).
- **Gardens and greenhouses:** Living material (plants that grow, bloom, die). Glass architecture. Temperature control. Seasons.

---

## Learnings

### Key File Paths
- `src/meta/world/*.lua` — room definition files (currently: `start-room.lua`, `cellar.lua`)
- `src/meta/objects/*.lua` — object definitions (37 objects currently)
- `src/engine/loop/init.lua` — game loop, `cmd_look` room composition, FSM tick dispatch, env_context assembly
- `src/engine/fsm/init.lua` — FSM engine, threshold checking, timer system, material property resolution
- `src/engine/materials/init.lua` — material registry (wax, iron, fabric, wood, glass, brass, etc.)
- `docs/architecture/rooms/` — dynamic-room-descriptions.md, room-exits.md
- `docs/architecture/objects/core-principles.md` — THE constitution (8 principles)
- `docs/architecture/engine/material-properties.md` — env properties + threshold system architecture
- `docs/architecture/engine/containment-constraints.md` — 5-layer validation, multi-surface containment
- `docs/architecture/player/` — player-model.md, player-movement.md, player-sensory.md
- `docs/design/spatial-system.md` — ON/UNDER/BEHIND/COVERING/IN relationships
- `docs/design/material-properties-system.md` — designer-facing material properties guide

### Patterns for Room .lua Files
- Always declare `guid`, `template = "room"`, `id`, `name`, `keywords`
- `description` = permanent features ONLY. Stone walls, floor, ceiling, atmosphere. NEVER mention objects.
- Use `instances` array with `location` dot-notation for spatial hierarchy
- Exits are inline objects with full mutation support (open/close/lock/unlock/break)
- Both sides of every passage must be explicitly declared
- Use `passage_id` for exits that share a physical passage (synchronized mutations)
- `on_enter` function returns atmospheric entrance text
- NO custom `on_look` — let the engine compose dynamically (unless truly special room)
- Order objects in contents by visual prominence (biggest → smallest)

### Wayne's Preferences
- Rooms should feel like REAL PLACES, not game levels
- Material properties create environmental consistency — a stone cellar is cold and damp
- "Players can't see stuff in sacks unless they look in the sack" — layered discovery
- Think in ENVIRONMENTS — sets of rooms that share DNA, not isolated levels
- Dwarf Fortress is the GOAT — property-bag objects, data-driven definitions, emergent behavior
- Get to playable test fast — don't over-design, iterate
- Every interaction should feel physically grounded
- Mutation model: code IS state, no boolean flags

### Object Inventory (37 objects in `src/meta/objects/`)
bandage, barrel, bed, bed-sheets, blanket, brass-key, candle, candle-holder, chamber-pot, cloth, curtains, glass-shard, knife, match, matchbox, matchbox-open, needle, nightstand, paper, pen, pencil, pillow, pin, poison-bottle, rag, rug, sack, sewing-manual, terrible-jacket, thread, torch-bracket, trap-door, vanity, wall-clock, wardrobe, window, wool-cloak

### Room Design Checklist (from charter)
1. Physical reality: What space? What era/style? What materials?
2. Sensory design: Description (lit), feel (dark), smell, sound — per lighting state
3. Spatial layout: Where are objects placed? (on, in, under, against, hanging from)
4. Exits: Where do they lead? Locked/hidden/conditional?
5. Environmental properties: Temperature, moisture, light_level
6. Objects inventory: What's in this room? (existing objects + new objects needed from Flanders)
7. Puzzle hooks: What puzzle opportunities? (hand to Bob)
8. Map context: How does this room connect to adjacent rooms? Player journey?

### Level 1 Room Design Docs (2026-07-21)

Completed full room design documentation for all 7 Level 1 rooms in `docs/rooms/`:

| Room | File | Status | Objects | Key Design Decision |
|------|------|--------|---------|---------------------|
| Bedroom | `docs/rooms/start-room.md` | 🟢 Existing | 28 instances | Anchor room — all core systems taught here |
| Cellar | `docs/rooms/cellar.md` | 🟢 Existing | 2 | Transition/breathing room, first lock-and-key |
| Storage Cellar | `docs/rooms/storage-cellar.md` | 🔴 New | ~12 | Moderate complexity, tool discovery (crowbar, rope), iron key in nested crate |
| Deep Cellar | `docs/rooms/deep-cellar.md` | 🔴 New | ~11 | Narrative pivot — architecture shifts to ancient megalithic. Altar, scroll, offering bowl. Driest underground room (0.3 moisture = preservation). |
| Hallway | `docs/rooms/hallway.md` | 🔴 New | ~7 | REWARD room — warm, lit, wood-paneled. Zero puzzles. Torches, portraits for lore. Level 2 transition via grand staircase. |
| Courtyard | `docs/rooms/courtyard.md` | 🔴 New (optional) | ~6 | First exterior room. Moonlit. Well, ivy, cobblestones. Only accessible via window escape (alternate path). |
| Crypt | `docs/rooms/crypt.md` | 🔴 New (optional) | ~16 | Deepest/oldest space. 5 sarcophagi with generational story. Tome = major lore reward. Dead-end by design. |

**Environmental property gradient across Level 1:**

| Room | Temp (°C) | Moisture | Light | Character |
|------|-----------|----------|-------|-----------|
| Bedroom | 14 | 0.2 | 0 (dark start) | Comfortable but locked |
| Cellar | 10 | 0.8 | 0 | Cold, wet, oppressive |
| Storage Cellar | 11 | 0.5 | 0 | Moderate, dusty, abandoned |
| Deep Cellar | 9 | 0.3 | 0 | Cold but DRY — engineered preservation |
| Crypt | 8 | 0.1 | 0 | Coldest, driest — perfect preservation |
| Courtyard | 8 | 0.7 | 1 (moonlit) | Cold, wet, exposed — first outdoor |
| Hallway | 18 | 0.15 | 3 (torchlit) | WARM, DRY, LIT — reward/relief |

**Key design patterns discovered:**
1. **Environmental properties tell stories** — the deep cellar's low moisture (0.3) compared to the cellar's high moisture (0.8) says "someone built this to preserve things" without the description needing to state it.
2. **Contrast is the tool** — the hallway's warmth (18°C) only works because the cellars were cold (9-11°C). Every room's properties are defined in relation to neighbors.
3. **The architectural timeline** — Bedroom (14th-15th century) → Cellar (older) → Storage (same era) → Deep Cellar (10th-12th century) → Crypt (8th-10th century). The player literally descends through time.
4. **Dead ends have purpose** — the crypt is a dead-end room by design. One exit. The constraint focuses the player on CONTENT (lore) rather than NAVIGATION.
5. **Asymmetric exits work** — the bedroom-cellar connection (trap door down, stairway up) is different from each side. This adds realism.

**Handoff items for team:**
- **Flanders:** ~40 new objects needed across 5 new rooms. Priority: storage cellar objects (critical path), then deep cellar, then hallway, then courtyard/crypt.
- **Bob:** 6 new puzzles (009-014). Puzzles 009, 011 are critical path. Rest are optional.
- **Implementation note:** ~~`cellar.lua` north exit currently targets `deep-cellar` — needs to be changed to `storage-cellar` when that room is built.~~ **DONE** — cellar.lua updated: target → `storage-cellar`, passage_id → `cellar-storage-door`.

### Level 1 Room Build (2026-07-21)

Built all 5 new room .lua files in `src/meta/world/`:

| Room | File | Objects | Exits | Environmental |
|------|------|---------|-------|---------------|
| Storage Cellar | `storage-cellar.lua` | 13 instances (10 room-level + 3 nested) | south→cellar, north→deep-cellar (locked, iron-key) | temp=11, moisture=0.5, light=0 |
| Deep Cellar | `deep-cellar.lua` | 9 instances (5 room + 3 altar + 1 hidden) | south→storage-cellar, up→hallway, west→crypt (locked, silver-key) | temp=9, moisture=0.3, light=0 |
| Hallway | `hallway.lua` | 7 instances (2 torches + 3 portraits + table + vase) | south→start-room, down→deep-cellar, north→level-2, west/east→locked | temp=18, moisture=0.15, light=3 |
| Courtyard | `courtyard.lua` | 5 instances (well, bucket, ivy, cobblestone, rain-barrel) | up→start-room (window), east→manor-kitchen (locked) | temp=8, moisture=0.7, light=1 |
| Crypt | `crypt.lua` | 14 instances (5 sarcophagi + 3 niche items + 4 hidden burial goods + inscription + tome) | west→deep-cellar | temp=8, moisture=0.1, light=0 |

**Build notes:**
1. All object type_ids are placeholders for Flanders. Engine warns "base class not found" for each — expected until object .lua files exist.
2. Updated `cellar.lua` north exit: target `deep-cellar` → `storage-cellar`, passage_id `cellar-deep-door` → `cellar-storage-door`.
3. All passage_ids are synchronized across bidirectional exits (e.g., `storage-deep-door` used by both storage-cellar.north and deep-cellar.south).
4. Hallway is the only room with `light_level = 3` (self-lit by torches). Courtyard has `light_level = 1` (moonlit). All cellar rooms are `light_level = 0`.
5. Room descriptions follow the "permanent features only" rule — no movable objects referenced.
6. All 5 files + updated cellar.lua pass Lua syntax validation. Engine boots successfully with all rooms loaded.

**Flanders dependency — placeholder GUIDs that need matching object files:**
- Storage cellar: large-crate, small-crate, grain-sack, wine-rack, wine-bottle, oil-lantern, rope-coil, crowbar, iron-key, rat, oil-flask, cloth-scraps, candle-stub
- Deep cellar: stone-altar, unlit-sconce, stone-sarcophagus, chain, incense-burner, tattered-scroll, offering-bowl, silver-key
- Hallway: lit-torch, portrait, side-table, vase
- Courtyard: stone-well, well-bucket, ivy, loose-cobblestone, rain-barrel
- Crypt: crypt-sarcophagus, candle-stub, burial-coins, bronze-ring, silver-dagger, burial-necklace, tome, wall-inscription

### Bedroom North Exit Shortcut Fix (2026-03-21)

**Bug:** Nelson's Pass-014 found that `start-room.lua` north exit was `open = true, locked = false`, allowing players to walk straight into the hallway and skip the entire Level 1 cellar puzzle chain.

**Fix:** Barred the door from the hallway side using an iron bar in brackets.

- **Bedroom side (start-room.lua):** `open = false, locked = true, key_id = nil`. No keyhole on this side — the player cannot open or unlock the door from the bedroom. Description mentions the bar on the far side. Removed `lock`/`unlock` mutations. Added `condition` to `open` mutation. Break mutation preserved (difficulty 3) as a high-cost alternate path.
- **Hallway side (hallway.lua):** `open = false, locked = true, key_id = nil`. The bar is accessible from this side. `unlock` mutation lifts the bar (no key required). `lock` mutation replaces it. Player arrives via deep cellar stairway and can unbar the door to reconnect rooms.
- **Docs updated:** start-room.md, hallway.md, level-01-intro.md.

**Design principle learned:** When gating a door, consider whether a bar or a lock is more appropriate. A bar is one-directional by nature (accessible from one side only) and doesn't require a key item to exist in the world. A lock creates a key-finding puzzle. Choose based on narrative intent: bars for imprisonment, locks for restricted access.

### Puzzle 015 Wind Effect Metadata (2026-07-22)

**Task:** Added on_traverse wind effect metadata to the deep-cellar / hallway stairway for Puzzle 015 (Draft Extinguish).

**Note:** Task referenced "storage cellar" but the actual stairway connects deep-cellar (up) to hallway, not storage-cellar. Followed the actual room topology and puzzle design doc.

**Changes:**
- **deep-cellar.lua up exit:** Added on_traverse.wind_effect block with strength gust, extinguishes candle, spares wind_resistant objects. Messages for extinguish, spared, and no-light cases. Updated exit description to mention the draught.
- **hallway.lua down exit:** Added matching on_traverse.wind_effect block with direction-appropriate messages (chill updraft from below vs. warm downdraft from above). Updated exit description to mention the draught.
- **deep-cellar.lua room description:** Added foreshadowing sentence about the draught from the north wall stairway.

**Design principle learned:** Environmental effects on exits (on_traverse) are a new pattern. The exit declares the effect; the engine resolves it against carried object properties. This is the first instance. Always add the effect to BOTH sides of a bidirectional passage, with direction-appropriate descriptions.
