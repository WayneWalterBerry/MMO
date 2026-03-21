# Room Design: The Bedroom (start-room)

**Room ID:** `start-room`  
**File:** `src/meta/world/start-room.lua`  
**Status:** 🟢 Implemented  
**Author:** Moe (World Builder)  
**Date:** 2026-07-21  
**Level:** 1 — The Awakening  
**Act:** I — The Awakening  

---

## 1. Physical Reality

**Space type:** Upper-floor bedchamber in a medieval manor house  
**Era/style:** Late medieval English (~14th–15th century). Functional, not luxurious — servant's quarters or guest room, not a lord's chamber. Stone construction with wooden furnishings.  
**Dimensions (implied):** Roughly 4m × 5m. Low-to-moderate ceiling (~2.5m). Intimate, not grand.  
**Materials:**
- **Walls:** Dressed stone (limestone or sandstone), bare, no plaster or hangings
- **Floor:** Cold flagstone (large, irregular slabs), with a wool rug covering the center
- **Ceiling:** Timber beams with plaster between (not visible in description — implied by era)
- **Door:** Heavy oak with iron hinges and latch (north wall)
- **Window:** Leaded diamond-pane glass set deep in stone embrasure (far wall)

**Architectural logic:** The room is on the ground floor or first floor of the manor. The trap door in the floor leads down to cellars — this is consistent with medieval manor houses where cellar access was sometimes through floor hatches in utility rooms. The stone walls, cold flagstones, and heavy oak door all speak to a building designed for defense and durability, not comfort.

---

## 2. Sensory Design

### description (lit)
> "You stand in a dim bedchamber that smells of tallow, old wool, and the faintest ghost of lavender. The stone walls are bare save for the shadows that cling to them like ivy. Cold flagstones line the floor, and pale grey light filters in from somewhere, barely enough to see by. The air is still and heavy, as though the room has been holding its breath for a very long time."

**Design notes:** The description establishes PERMANENT features only — stone walls, flagstone floor, atmosphere. No objects mentioned. The "pale grey light" suggests moonlight through the window but doesn't name the window. The lavender smell hints at prior habitation. The "holding its breath" metaphor creates unease.

### feel (dark — player's starting condition)
> "You lie on something soft. Fabric — a blanket, rough wool. Beneath it, a mattress that sags. The air is cold on your face. Your fingers find the edges of a wooden frame around you. You smell tallow and old wool, and something faintly floral — lavender? The room is utterly dark. You hear nothing but your own breathing and the faintest creak of old wood settling."

**Design notes:** The player wakes IN the bed, in total darkness. The feel description orients them through touch and smell. They discover they're in a bed before they know they're in a room.

### smell
> "Tallow — the waxy, animal-fat smell of cheap candles. Old wool, slightly musty. And beneath it all, the ghost of lavender, as if someone laid dried flowers here long ago and the scent outlived the person."

### sound
> "Silence, mostly. The faint creak of old timber settling. Your own breathing. And from somewhere beyond the walls — nothing. No wind, no voices, no footsteps. The silence of a building that has been empty for a long time."

---

## 3. Spatial Layout

```
    North Wall (Oak Door)
    ┌──────────────────────────────────┐
    │                                  │
    │   [wardrobe]          [vanity]   │
    │                                  │
    │           [rug]                  │
    │        (trap-door               │
    │         hidden beneath)          │
    │                                  │
    │   [bed]                          │
    │   (pillow, sheets,    [chamber   │
    │    blanket on top;     pot]      │
    │    knife underneath)             │
    │                                  │
    │   [nightstand]                   │
    │   (candle-holder+candle on top;  │
    │    poison bottle on top;         │
    │    matchbox inside drawer)       │
    │                                  │
    └──────────────────────────────────┘
    South Wall (Window with Curtains)
```

**Placement logic:**
- **Bed** — against the west wall, center-ish. Dominates the room (it's a four-poster). Player starts here.
- **Nightstand** — beside the bed (south side), within arm's reach. This is where you'd put a candle and personal items.
- **Vanity** — against the east wall. Writing surface with paper, pen. Pencil in drawer. Mirror (breakable).
- **Wardrobe** — against the west wall, far corner from door. Heavy, wooden, closed. Contains cloak and sack.
- **Rug** — center of the floor, covering the trap door. Must be moved to reveal the hatch.
- **Trap door** — in the floor beneath the rug. Hidden by default. Leads down to cellar.
- **Window** — south wall, set deep in stone. Leaded glass with curtains. Looks out over courtyard.
- **Chamber pot** — corner of room, near bed foot. Functional medieval detail.

---

## 4. Exits

### North — Oak Door → Hallway
- **Type:** `door`
- **Passage ID:** `bedroom-hallway-door`
- **State:** Open (slightly ajar), unlockable with brass-key
- **Constraints:** max_carry_size 4, player_max_size 5
- **Mutations:** open/close/lock/unlock/break
- **Design note:** CBG's master design recommends this eventually be LOCKED (key in deep cellar) to force cellar exploration. Currently open per implementation.

### Window — Leaded Glass → Courtyard
- **Type:** `window`
- **Passage ID:** `bedroom-courtyard-window`
- **State:** Closed, locked (iron latch), breakable
- **Constraints:** max_carry_size 2, requires_hands_free, player_max_size 4
- **Mutations:** unlock/open/close/break (break spawns glass-shard ×2)
- **Design note:** Dangerous alternate exit. Direction hint: DOWN (courtyard is below). Breaking costs glass shards and injury risk.

### Down — Trap Door → Cellar
- **Type:** `trap_door`
- **Passage ID:** `bedroom-cellar-trapdoor`
- **State:** Closed, hidden (must move rug first)
- **Constraints:** max_carry_size 3, player_max_size 5
- **Design note:** Primary critical-path exit. Discovery sequence: move rug → reveal trap door → open trap door → descend stairs.

---

## 5. Environmental Properties

| Property | Value | Rationale |
|----------|-------|-----------|
| `temperature` | 14°C | Cool spring/autumn night in stone building. Not freezing, but uncomfortable without clothing. |
| `moisture` | 0.2 | Low — upper floor, stone walls keep moisture down. Dry enough for fabric and paper. |
| `light_level` | 0 | **TOTAL DARKNESS at game start.** No light source active. Moonlight through window provides atmospheric description text but NOT functional light. |

**Material interactions:**
- Wax candle: stable at 14°C (melting point 60°C) — no auto-transitions
- Iron (hinges, latch): very low rust risk at moisture 0.2
- Fabric (blanket, cloak, curtains): dry, no dampness effects
- Paper: safe — no moisture deterioration
- Glass (window): stable

---

## 6. Objects Inventory

All objects are **🟢 EXISTING** (implemented in `src/meta/objects/`).

### Room-Level Objects (location = "room")

| Object | Type | Spatial Position | Notes |
|--------|------|------------------|-------|
| bed | Four-Poster Bed | West wall, center | Player starts here. Surfaces: top, underneath |
| nightstand | Nightstand | Beside bed (south) | Surfaces: top, inside (drawer) |
| vanity | Oak Vanity | East wall | Surfaces: top, inside. Has breakable mirror |
| wardrobe | Wardrobe | West wall, far corner | Container: inside. Closed by default |
| rug | Rug | Center floor | Covers trap-door. Surface: underneath |
| trap-door | Trap Door | Floor, under rug | Hidden until rug moved. FSM: hidden → revealed → open |
| window | Window | South wall | FSM: closed/locked ↔ open. Breakable |
| curtains | Curtains | South wall, over window | Decorative/functional |
| chamber-pot | Chamber Pot | Corner, near bed foot | Atmospheric detail |

### Nested Objects

| Object | Type | Location | Notes |
|--------|------|----------|-------|
| pillow | Pillow | bed.top | Contains pin (hidden inside) |
| bed-sheets | Bed Sheets | bed.top | Functional, takeable |
| blanket | Blanket | bed.top | Warmth item |
| knife | Knife | bed.underneath | Hidden — requires "look under bed" |
| pin | Pin | pillow.inside | Hidden inside pillow — requires tearing/examining |
| candle-holder | Candle Holder | nightstand.top | Holds candle |
| candle | Candle | candle-holder | Light source (requires match to light) |
| poison-bottle | Poison Bottle | nightstand.top | Hazard — TASTE kills? Teaches caution |
| matchbox | Matchbox | nightstand.inside | Contains 7 matches. In drawer — must open nightstand |
| match-1 through match-7 | Match | matchbox | Consumable fire sources (7 total) |
| paper | Paper | vanity.top | Writing surface |
| pen | Pen | vanity.top | Writing tool |
| pencil | Pencil | vanity.inside | Writing tool (in drawer) |
| wool-cloak | Wool Cloak | wardrobe.inside | Wearable, warmth |
| sack | Sack | wardrobe.inside | Container for sewing supplies |
| needle | Needle | sack | Sewing/pricking tool |
| thread | Thread | sack | Sewing material |
| sewing-manual | Sewing Manual | sack | Readable — teaches sewing skill |
| brass-key | Brass Key | rug.underneath | CRITICAL ITEM — unlocks cellar iron door |

**Total: 28 object instances** (23 unique types, 7 identical matches)

---

## 7. Puzzle Hooks

| Puzzle ID | Name | Difficulty | Status | Description |
|-----------|------|------------|--------|-------------|
| 001 | Light the Room | ⭐⭐ | 🟢 Built | Open nightstand → find matchbox → open matchbox → take match → strike match on matchbox → light candle. Teaches: darkness navigation, containers, compound tool use. |
| 002 | Poison Bottle | ⭐⭐ | 🟢 Built | Identify poison bottle through SMELL/TASTE. Teaches: sensory verbs, hazard identification. |
| 003 | Write in Blood | ⭐⭐ | 🟢 Built | PRICK finger with pin/needle → use blood as ink → write on paper. Teaches: creative tool use, body-as-resource. |
| 004 | Inventory Management | ⭐⭐ | 🟢 Built | 2-hand limit forces strategic carrying choices. Teaches: weight/size constraints. |
| 005 | Bedroom Escape | ⭐⭐⭐ | 🟢 Built | Meta-puzzle combining 001, 004, 007. Get light + find trap door + descend. |
| 006 | Iron Door Unlock | ⭐⭐ | 🟢 Built | Brass key (found under rug) unlocks cellar iron door. Key is HERE, lock is in cellar. |
| 007 | Trap Door Discovery | ⭐⭐ | 🟢 Built | Move rug → reveal trap door → open it. Teaches: spatial manipulation, hidden objects. |
| 008 | Window Escape | ⭐⭐⭐⭐ | 🟢 Built | Break/open window → climb out → dangerous drop to courtyard. Alternate path. |

**Bob's notes:** All 8 puzzles are implemented. This room is the teaching ground — every core system gets introduced here.

---

## 8. Map Context

### Player Journey Through This Room
1. **Arrival:** Player wakes here at 2 AM in total darkness. This is the STARTING ROOM.
2. **Phase 1 (Dark):** Fumble, FEEL, SMELL, LISTEN. Discover bed, nightstand, matchbox.
3. **Phase 2 (Lit):** Light candle. Explore the room visually. Find all objects.
4. **Phase 3 (Escape):** Move rug, find brass key, open trap door, descend to cellar.
5. **Revisit:** Player may return from cellar if they forgot something. Room should acknowledge revisit (candle still lit? door states preserved?).

### Connections
- **North → Hallway:** Through oak door. The "normal" exit — leads to manor proper.
- **Down → Cellar:** Through trap door. The critical path — leads to underground exploration.
- **Window → Courtyard:** Dangerous alternate. Exterior space below the window.

### Environment Role
The bedroom is the ANCHOR of Level 1. Everything radiates from here. It's the densest room in the game — 28 objects, 8 puzzles — because it teaches ALL core systems. Every subsequent room is simpler by design. The player leaves this room as a competent adventurer.
