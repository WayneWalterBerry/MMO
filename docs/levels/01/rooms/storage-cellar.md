# Room Design: The Storage Cellar

**Room ID:** `storage-cellar`  
**File:** `src/meta/world/storage-cellar.lua` *(not yet created)*  
**Status:** 🔴 New — Design Only  
**Author:** Moe (World Builder)  
**Date:** 2026-07-21  
**Level:** 1 — The Awakening  
**Act:** II — Descent  

---

## 1. Physical Reality

**Space type:** Underground provisions store beneath a medieval manor house  
**Era/style:** Late medieval. Purpose-built storage vault — long, narrow, vaulted ceiling. Better constructed than the cellar above (this room was designed to protect goods from moisture and vermin). The masonry is more regular, the ceiling slightly higher.  
**Dimensions (implied):** Roughly 8m × 3m — long and narrow, almost a corridor. Vaulted ceiling ~2.5m at the crown, lower at the walls. The length gives the room a sense of depth; the player moves THROUGH it, not around it.  
**Materials:**
- **Walls:** Coursed ashlar limestone — dressed and fitted, a step up from the cellar's rough granite. Mortar joints visible. Some efflorescence (white salt deposits) from centuries of moisture.
- **Floor:** Flagstone, better-laid than the cellar. Dust and grit cover everything. Old straw scattered in patches (once used as insulation for goods).
- **Ceiling:** Barrel-vaulted stone (self-supporting arch). Cobwebs in every corner and draped between shelving.
- **Shelving:** Heavy oak shelves along both long walls, floor to ceiling. Warped and sagging from age and moisture. Some collapsed.
- **Doors:** Iron-bound oak (south, from cellar; north, to deep cellar). Both heavy, both locked.

**Architectural logic:** This is the manor's main provisions store. In a medieval household, the cellar (wine/beer), the buttery (ale and daily provisions), and the pantry (bread and dry goods) were separate spaces. This room serves as the dry-goods pantry — or rather, it did. It hasn't been restocked in years, maybe decades. The goods are rotting, the shelving is failing, the rats have moved in. But the architecture is sound — well-built vaults don't collapse easily. The two heavy doors (south from cellar, north to deep cellar) suggest this room was a security barrier — you had to pass through it to reach whatever lies beyond.

---

## 2. Sensory Design

### description (lit)
> "A long, narrow vault stretches before you, its barrel-vaulted ceiling disappearing into shadow at both ends. Heavy oak shelves line both walls from floor to ceiling, most sagging under the weight of years. Dust covers everything — the flagstone floor, the collapsed crates, the remnants of rope and sacking scattered like shed skin. The air tastes of old wood, stale grain, and the sweet-sour tang of decay. Something scurries in the darkness beyond the reach of your light."

**Design notes:** Permanent features: vault shape, shelves, flagstone floor, dust. The scurrying sound hints at rats without naming them (the rat is an object, not architecture). The "sweet-sour tang of decay" gives the room a distinct smell profile — this is a place where food once was and has since rotted.

### feel (dark)
> "A long space. Your outstretched hands find wooden shelves on both sides — rough, splintery, sagging. The floor is stone under a layer of grit and something that crunches underfoot — old straw? Broken glass? The air is cold but drier than the cellar behind you. Dust tickles your nose. You smell old grain, wood rot, and something sweetly rotten. From deeper in the room: a scratching sound, small and quick, like tiny claws on stone."

### smell
> "Stale grain — the ghost of flour and barley, long turned to dust and mold. Old wood, dried out and crumbling. The sweet-sour smell of fruit or vegetables that rotted years ago and left their essence in the stone. And beneath it all, the sharp, musky tang of rodent: droppings, fur, and the faint ammonia of urine in corners."

### sound
> "Scratching. Small, quick, furtive — rats in the walls or under the shelving. The creak of old wood under its own weight. Your footsteps crunching on grit and straw. And occasionally, from the north end of the room, a faint draft that makes the cobwebs sway — air moving through the gap around the far door."

---

## 3. Spatial Layout

```
    North Wall (Iron Door → Deep Cellar)
    ┌──────────────────────────────────────┐
    │   [iron door — locked]               │
    │                                      │
    │ [shelf] ┌─────────────────┐ [shelf]  │
    │         │                 │          │
    │ [wine-  │   [large-crate] │ [rope-   │
    │  rack]  │   (on floor,    │  coil]   │
    │         │    center)      │ (hanging │
    │         │                 │  on hook) │
    │ [shelf] │   [small-crate] │ [shelf]  │
    │ (oil-   │   (on top of    │ (rusty   │
    │  lantern│    large crate) │  tools:  │
    │  here)  │                 │  crowbar,│
    │         │   [grain-sack]  │  shovel) │
    │         │   (on floor,    │          │
    │         │    beside       │          │
    │         │    crates)      │          │
    │         └─────────────────┘          │
    │                                      │
    │   [iron door — from cellar]          │
    └──────────────────────────────────────┘
    South Wall (Iron Door from Cellar)
```

**Placement logic:**
- **Shelving** runs along both long walls, creating a natural corridor down the center.
- **Large crate** — center of the room, on the floor. Too heavy to easily move. Closed/nailed shut.
- **Small crate** — stacked on top of the large crate. Lighter, also closed.
- **Grain sack** — slumped on the floor beside the crates. Heavy, lumpy, partially rotted.
- **Wine rack** — built into the west wall shelving. Holds bottles (some intact, some broken).
- **Wine bottle** — in the wine rack. Could contain wine or oil.
- **Oil lantern** — on a shelf on the west wall, partially hidden behind collapsed shelf section. Better light source than candle.
- **Rope coil** — hanging from an iron hook on the east wall. Useful tool for later.
- **Crowbar** — on a shelf on the east wall, among other rusty tools. THE key tool for opening crates.
- **Iron key** — hidden inside the large crate, inside a smaller box or sack within it. The critical-path item.
- **Rat** — skitters around the room. Ambient creature. Flees when approached.

---

## 4. Exits

### South — Iron Door → Cellar
- **Type:** `door`
- **Passage ID:** `cellar-storage-door` (matches cellar's north exit)
- **State:** Open (player just came through; door was unlocked from cellar side with brass key)
- **Constraints:** max_carry_size 4, player_max_size 5
- **Design note:** Once unlocked from the cellar side, this door stays open. The player can return to the cellar freely.

### North — Iron Door → Deep Cellar
- **Type:** `door`
- **Passage ID:** `storage-deep-door`
- **State:** Closed, LOCKED (key_id: iron-key), NOT breakable
- **Constraints:** max_carry_size 4, player_max_size 5
- **Mutations:** unlock (with iron-key), open, close
- **Description (locked):** "A second iron-bound door blocks the north end of the vault. This one is different — heavier, older, with a lock plate of black iron. A large keyhole waits, dark and empty."
- **Description (unlocked):** "The iron-bound door stands unlocked, its heavy lock plate hanging loose."
- **Description (open):** "The iron door stands open, revealing a passage into older, darker stone beyond."
- **on_feel:** "Cold iron bands over oak. Heavier than the door behind you. The keyhole is large — meant for an iron key, not the delicate brass one. The door does not yield to pushing."

**Design note:** This is the second lock-and-key gate. The iron key is hidden in the large crate (Puzzle 009). The player must find the crowbar, break open the crate, find the key, then unlock this door. This reinforces container hierarchy and tool usage.

---

## 5. Environmental Properties

| Property | Value | Rationale |
|----------|-------|-----------|
| `temperature` | 11°C | Underground, similar to cellar but slightly warmer due to sealed doors on both sides trapping air. |
| `moisture` | 0.5 | MODERATE — better construction than the cellar (ashlar vs rough-hewn), but still underground. Drier than cellar (0.8) because the vaulted ceiling and dressed stone shed water better. |
| `light_level` | 0 | Total darkness. No windows, no fixed light sources. Player must carry light. |

**Material interactions at moisture 0.5:**
- Iron (tools, door hardware): Moderate rust risk. Crowbar is described as "rusty" — long-term exposure.
- Wood (shelves, crates, barrel staves): Moderate dampness. Shelves are warped and sagging. Crate wood is soft but intact.
- Fabric (grain sack): Partially rotted from decades of moderate moisture + organic contents decomposing.
- Paper/parchment: Would deteriorate over time, but no paper objects are native to this room.
- Glass (wine bottles): Unaffected by moisture. Some broken from shelf collapse, not deterioration.
- Rope (hemp): Still functional — hemp resists moderate moisture well. But stiff and slightly mildewed.

---

## 6. Objects Inventory

All objects are **🔴 NEW** (need to be designed by Flanders).

### Room-Level Objects

| Object | Type | Spatial Position | Status | Notes |
|--------|------|------------------|--------|-------|
| large-crate | Large Crate | Floor, center of room | 🔴 NEW | Heavy wooden shipping crate. Nailed shut. Breakable with crowbar. Contains iron key (nested in smaller container). |
| small-crate | Small Crate | On top of large crate | 🔴 NEW | Lighter wooden crate. Nailed shut. Contains mundane supplies (cloth, candle stubs?). Stackable. |
| grain-sack | Grain Sack | Floor, beside crates | 🔴 NEW | Heavy burlap sack. Partially rotted. Contains old grain (useless) and possibly something hidden at the bottom. |
| wine-rack | Wine Rack | West wall, built into shelving | 🔴 NEW | Wooden rack holding wine bottles. Immovable (built in). Some slots empty, some hold bottles, some hold broken glass. |
| wine-bottle | Wine Bottle | In wine-rack | 🔴 NEW | Glass bottle. May contain wine, oil, or be empty. Breakable. Could serve as container or weapon. |
| oil-lantern | Oil Lantern | West wall shelf, partially hidden | 🔴 NEW | Better light source than candle. Requires oil to function. FSM: empty → filled → lit → spent. |
| rope-coil | Rope Coil | East wall, hanging from iron hook | 🔴 NEW | Hemp rope, ~10m. Tool for climbing, tying, lowering. Stiff but functional. |
| crowbar | Crowbar | East wall shelf, among rusty tools | 🔴 NEW | Iron crowbar. Rusty but functional. Enables BREAK and PRY actions. Critical for opening crates. |
| iron-key | Iron Key | Inside large-crate (nested) | 🔴 NEW | Large iron key. Unlocks deep cellar door. CRITICAL PATH item. |
| rat | Rat | Roaming (under shelves) | 🔴 NEW | Small brown rat. Ambient creature. Flees when player approaches. Atmospheric detail. May be catchable? (Wayne decision) |

### Potential Nested Objects (inside crates)

| Object | Location | Notes |
|--------|----------|-------|
| iron-key | large-crate (inside nested sack or box) | Critical path item. Discovery requires: find crowbar → break crate → search contents → find key. |
| cloth-scraps | small-crate | Mundane supplies. Could be used as bandage or fuel. |
| candle-stubs | small-crate | Partially used candles. Backup light source (teaches resource awareness). |
| oil-flask | wine-rack or shelf | Small flask of lamp oil. Needed to fill the oil lantern. |

**Total: ~10-12 object instances** (10 unique types + nested contents)

**Flanders coordination notes:**
- Large crate needs FSM: sealed → broken-open (via crowbar). Breaking should scatter wood splinters.
- Oil lantern needs FSM: empty → filled (with oil) → lit → spent (oil consumed). Fill action = POUR oil INTO lantern.
- Crowbar should have `provides_tool = "pry"` and/or `provides_tool = "break_tool"`.
- Rat needs basic creature behavior: present in room, flees on approach, returns after a time. Ambient.
- Wine bottle needs FSM: sealed → opened → empty. Breaking spawns glass-shard.

---

## 7. Puzzle Hooks

| Puzzle ID | Name | Difficulty | Status | Description |
|-----------|------|------------|--------|-------------|
| 009 | Crate Puzzle | ⭐⭐ | 🔴 New | Find crowbar → use crowbar on large crate → crate breaks open → search contents → find iron key (possibly in nested container). Teaches: tool use (crowbar), container hierarchy, breaking mechanics. CRITICAL PATH. |
| 010 | Light Upgrade | ⭐⭐ | 🔴 New | Find oil lantern → find oil flask → pour oil into lantern → light lantern with match/candle. Better light source than candle (longer lasting, brighter). OPTIONAL but rewarding. |

**Bob's design notes:**
- **Puzzle 009** should have multiple solution paths: (a) crowbar on crate (intended), (b) knife on crate (harder, slower), (c) drop crate to break it (creative but noisy — alerts rats? consequences?).
- **Puzzle 010** requires two separate discoveries (lantern + oil) and a combination action. The oil flask might be on a high shelf (requires stacking crates to reach?) or hidden behind wine bottles.
- The **rope coil** is NOT part of a Level 1 puzzle but should be takeable — it enables solutions in later levels (climbing, tying, lowering through wells, etc.).
- The **rat** is atmospheric but could become a puzzle element: rats might have stolen a small item and hidden it in their nest (behind shelving).

---

## 8. Map Context

### Player Journey Through This Room
1. **Arrival:** Player unlocks the iron door in the cellar with the brass key and steps through.
2. **First impression:** Long, narrow vault. Shelving on both sides. Crates and sacks in the center. The smell of decay and rodent.
3. **Exploration:** Search shelves, discover tools (crowbar, rope), find oil lantern. Examine crates.
4. **Puzzle 009:** Use crowbar to break open large crate. Find iron key inside.
5. **Optional - Puzzle 010:** Find oil, fill lantern, light it. Superior light source.
6. **Progression:** Unlock north door with iron key. Proceed to deep cellar.

### Connections
- **South → Cellar:** Through the iron door the player just unlocked. Return path is always open.
- **North → Deep Cellar:** Through a second iron door. Locked, requires iron key found in this room.

### Environment Role
The storage cellar is a **moderate-complexity reinforcement room**:
1. **Object density increases** from cellar (2) to storage (10-12) — but it's still far less than the bedroom (28). The pacing is deliberate.
2. **Tool discovery:** Crowbar and rope are new tool types the player hasn't seen. The crowbar is immediately useful (crate puzzle); the rope is for later (teaching players to carry useful tools forward).
3. **Container hierarchy deepened:** The bedroom introduced nested containers (nightstand → matchbox → matches). Here, the nesting is more complex: crate → sack → iron key. And you need a TOOL (crowbar) to access the outer container.
4. **Environmental storytelling:** The rotting provisions, the rats, the collapsed shelves — this room tells the story of abandonment. Whoever maintained this house stopped doing so. When? Why?
5. **Resource opportunity:** Oil lantern is an UPGRADE that rewards thorough exploration. Players who rush through miss it; players who search are rewarded with a better light source for the deeper, darker rooms ahead.

### Adjacency Notes
- **South:** Cellar (simpler, sparser — the player just came from here)
- **North:** Deep Cellar (older, grander, narrative pivot — the architecture changes here)
- This room is the MIDDLE of the cellar sequence: Cellar → Storage Cellar → Deep Cellar. Each step takes the player deeper underground and further back in time (newer manor → older cellars → ancient foundations).
