# Room Design: The Cellar

**Room ID:** `cellar`  
**File:** `src/meta/rooms/cellar.lua`  
**Status:** 🟢 Implemented  
**Author:** Moe (World Builder)  
**Date:** 2026-07-21  
**Level:** 1 — The Awakening  
**Act:** II — Descent  

---

## 1. Physical Reality

**Space type:** Underground cellar beneath a medieval manor house  
**Era/style:** Late medieval. Rough-hewn — this is a working space, not a living one. Older construction than the bedroom above; the stone is cruder, the ceiling lower.  
**Dimensions (implied):** Roughly 5m × 4m, ceiling barely 2m. Claustrophobic. You can touch the ceiling without stretching.  
**Materials:**
- **Walls:** Rough-hewn granite, unfinished, slick with moisture
- **Floor:** Packed earth with scattered flagstone patches (uneven, treacherous in the dark)
- **Ceiling:** Low stone vault, cobwebbed, dripping
- **Stairway:** Narrow spiral stone stairs from bedroom above (carved into the bedrock)
- **Iron door:** North wall — heavy oak planks banded with black iron, padlocked

**Architectural logic:** This is the manor's original cellar, dug into bedrock when the house was built. The narrow stairway from the bedroom was a private access point — unusual, suggesting the room above was always connected to whatever lies below. The iron-bound door to the north suggests something worth securing. The rough-hewn granite walls and low ceiling say "utility" — this was for storage, not habitation.

---

## 2. Sensory Design

### description (lit)
> "You stand at the foot of a narrow stone stairway in a low-ceilinged cellar. The walls are rough-hewn granite, slick with moisture that catches what little light there is. Water drips somewhere in the darkness, a slow and patient rhythm. The air is cold and heavy, thick with the smell of damp earth, old stone, and something faintly metallic. Cobwebs hang in thick curtains from the ceiling, swaying in a draft you cannot feel."

**Design notes:** Permanent features only. The moisture on walls, the dripping water, the cobwebs — all architectural/environmental. No objects mentioned. The "something faintly metallic" creates unease (blood? iron? rust?).

### feel (dark)
> "Cold. The air hits you like stepping into a grave. The stone steps under your feet are slick and uneven. You reach out — rough stone walls, wet to the touch, gritty under your fingers. The ceiling is close, barely above your head. Cobwebs brush your face like dead fingers. The floor is hard-packed earth, cold through your shoes. Somewhere ahead, water drips — slow, measured, endless."

### smell
> "Damp earth, cold stone, and something faintly metallic — iron, perhaps, or old blood. The air is thick and stale, as if it has not moved in a very long time."

*(This is the implemented `on_smell` from cellar.lua.)*

### sound
> "Water dripping. A slow, patient rhythm — one drop every three or four seconds, echoing off stone. Your own footsteps on packed earth. The creak of old wood somewhere above. And beneath it all, a deep silence — the silence of underground places, where sound goes to die."

---

## 3. Spatial Layout

```
    North Wall (Iron-Bound Door → Storage Cellar)
    ┌──────────────────────────────────┐
    │                                  │
    │   [iron-bound door]              │
    │   (locked, padlocked)            │
    │                                  │
    │                                  │
    │              [barrel]            │
    │              (against east wall) │
    │                                  │
    │                                  │
    │   [torch-bracket]                │
    │   (on west wall, empty)          │
    │                                  │
    │        [stone stairway ↑]        │
    │        (spiral stairs to         │
    │         bedroom above)           │
    │                                  │
    └──────────────────────────────────┘
    South Wall
```

**Placement logic:**
- **Stone stairway** — south end of room, spiraling up through the trap door to the bedroom. The player descends here.
- **Barrel** — against the east wall. Old, sealed, rusted hoops. A forgotten cask of something.
- **Torch bracket** — on the west wall, roughly at shoulder height. Empty iron bracket, pitted with rust. Could hold a torch or candle if the player gets creative.
- **Iron-bound door** — dominates the north wall. Heavy, dark, padlocked. The visual (and tactile) centerpiece of the room.

---

## 4. Exits

### Up — Stone Stairway → Bedroom
- **Type:** `stairway`
- **Passage ID:** `cellar-bedroom-stairway`
- **State:** Open, always passable
- **Constraints:** max_carry_size 3, player_max_size 5
- **Design note:** Narrow spiral stairs. The passage_id relates to the bedroom's "down" exit but note the passage IDs differ between the two sides (`bedroom-cellar-trapdoor` vs `cellar-bedroom-stairway`). The bedroom side is a trap door; the cellar side is a stairway — asymmetric by design.

### North — Iron-Bound Door → Storage Cellar
- **Type:** `door`
- **Passage ID:** `cellar-deep-door`
- **State:** Closed, LOCKED (key_id: brass-key), NOT breakable
- **Constraints:** max_carry_size 4, player_max_size 5
- **Mutations:** open (after unlock)
- **Design note:** This is the first lock-and-key puzzle the player encounters AFTER descending. If they forgot the brass key (under the rug in the bedroom), they must go back up. The door is described as leading to "deep-cellar" in the current .lua — **CBG's master design inserts a Storage Cellar between cellar and deep cellar.** The `target` field will need updating when storage-cellar is built.

**⚠️ IMPLEMENTATION NOTE:** The current `cellar.lua` has `target = "deep-cellar"` for the north exit. Per CBG's Level 1 design, this should become `target = "storage-cellar"` when the storage cellar room is implemented. The passage_id `cellar-deep-door` should also be renamed to `cellar-storage-door` for clarity.

---

## 5. Environmental Properties

| Property | Value | Rationale |
|----------|-------|-----------|
| `temperature` | 10°C | Underground, no heat source. Noticeably colder than the bedroom (14°C). Medieval cellar temperatures were consistent ~10-12°C year-round. |
| `moisture` | 0.8 | HIGH — underground, rough-hewn stone, water dripping visibly. Walls are slick with condensation. |
| `light_level` | 0 | Total darkness. No windows, no fixed light sources. Player must bring light from bedroom. |

**Material interactions at moisture 0.8:**
- Iron (barrel hoops, torch bracket, door hardware): HIGH rust risk. The bracket is already described as "pitted with rust."
- Wood (barrel staves, door planks): Softening, potential rot. The barrel may be compromised.
- Fabric (if player carries cloak): Will slowly absorb moisture — becomes damp.
- Paper (if player carries paper): Deterioration risk at this moisture level.
- Brass (key): Tarnishing accelerated, but functional.

**Material interactions at temperature 10°C:**
- All materials stable thermally. No melting, no freezing.
- The cold is ATMOSPHERIC — it makes the player uncomfortable, reinforcing the hostile environment.

---

## 6. Objects Inventory

All objects are **🟢 EXISTING** (implemented in `src/meta/objects/`).

### Room-Level Objects (location = "room")

| Object | Type | Spatial Position | Notes |
|--------|------|------------------|-------|
| barrel | Barrel | Against east wall | Old wooden cask with rusted iron hoops. Sealed. Container — what's inside? (TBD). Breakable. |
| torch-bracket | Torch Bracket | West wall, shoulder height | Empty iron wall fixture, pitted with rust. Can hold a torch or candle. Atmospheric detail + potential utility. |

**Total: 2 objects** — deliberately sparse. This is a breathing room after the dense bedroom.

### Object Design Notes
- **Barrel:** Currently a sealed container. Potential for hidden contents (wine? water? something darker?). Breaking it could yield staves (wood) and liquid. Flanders should consider FSM states: sealed → opened → broken.
- **Torch bracket:** An empty holder. If the player places a candle or (later) a torch in it, it becomes a fixed light source for the room. Smart players will use this.

---

## 7. Puzzle Hooks

| Puzzle ID | Name | Difficulty | Status | Description |
|-----------|------|------------|--------|-------------|
| 006 | Iron Door Unlock | ⭐⭐ | 🟢 Built | Use brass key (from bedroom, under rug) on padlock → unlock iron door → open → proceed north. Teaches: lock-and-key mechanic, bringing items between rooms. |

**Potential additional hooks (for Bob):**
- **Barrel contents:** What happens if the player breaks or opens the barrel? Could contain a useful item, liquid, or nothing (teaching that not everything hides treasure).
- **Torch bracket utility:** Placing a candle in the bracket frees a hand while keeping the room lit. This is an emergent solution, not a formal puzzle — but it rewards spatial thinking.
- **Returning for forgotten items:** If the player descends without the brass key, they learn the lesson of preparation. The stairway is always open — they can go back.

---

## 8. Map Context

### Player Journey Through This Room
1. **Arrival:** Player descends narrow spiral stairway from bedroom. Atmospheric `on_enter` text: "You descend the narrow stone stairway, each step taking you deeper into cold, damp air. The smell of earth and old stone grows stronger with every step."
2. **Exploration:** Room is dark (unless player brought light). FEEL around — discover barrel, torch bracket, iron door.
3. **The locked door:** Player encounters the iron-bound door. If they have the brass key → unlock → proceed. If not → must return to bedroom for it.
4. **Transition:** Once through the iron door, the player moves deeper underground.

### Connections
- **Up → Bedroom:** Return path. Always open. The stairway is carved from bedrock.
- **North → Storage Cellar:** Through the iron-bound door. The critical-path gate. Locked until player uses brass key.

### Environment Role
The cellar is a **transition space** — a palate cleanser between the dense bedroom and the moderate storage cellar. Its purpose:
1. **Introduce underground environment:** Cold, damp, dark. The environmental properties (moisture 0.8) begin interacting with carried objects.
2. **First lock-and-key gate:** The iron door teaches that some exits require specific items.
3. **Atmosphere escalation:** From uncomfortable bedroom → oppressive cellar. The descent metaphor: going deeper = going darker.
4. **Breathing room:** Only 2 objects, 1 puzzle. Let the player absorb what they learned in the bedroom.

### Adjacency Notes
- The cellar sits DIRECTLY below the bedroom (connected by trap door / stairway).
- The iron door leads north to the storage cellar (in CBG's design; currently coded as deep-cellar).
- There is no east/west/south exit besides the stairway. The player is funneled north.
