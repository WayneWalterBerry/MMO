# Room Design: The Deep Cellar

**Room ID:** `deep-cellar`  
**File:** `src/meta/rooms/deep-cellar.lua` *(not yet created)*  
**Status:** 🔴 New — Design Only  
**Author:** Moe (World Builder)  
**Date:** 2026-07-21  
**Level:** 1 — The Awakening  
**Act:** III — The Deep Secret  

---

## 1. Physical Reality

**Space type:** Ancient subterranean chamber beneath the manor — pre-dates the building above. Part ceremonial space, part crypt antechamber.  
**Era/style:** Early medieval or older (~10th–12th century). The stonework here is DIFFERENT from the rooms above — older, more sophisticated in some ways (vaulted ceiling, carved stone), cruder in others (no mortar, dry-stacked megalithic blocks). This was built by different hands, for a different purpose.  
**Dimensions (implied):** Roughly 6m × 6m — nearly square. Vaulted ceiling rises to ~3.5m at the crown. The room feels spacious after the cramped cellar and narrow storage vault. There's a sense of solemn grandeur — a chapel or ritual space, not a storeroom.  
**Materials:**
- **Walls:** Dry-stacked megalithic limestone blocks — enormous, precision-fitted, no mortar. Carved symbols and inscriptions visible on some blocks. The stone is darker than the ashlar above — deeper stratum, older geology.
- **Floor:** Large, flat flagstones — some with carved borders or symbols. Well-fitted. Remarkably even for their age.
- **Ceiling:** Ribbed vault, rising to a central boss carved with a face or symbol (hard to see without good light). The vaulting is sophisticated — someone with skill and resources built this.
- **Stairway:** A stone stairway ascends through the north wall to the hallway above. Wider and better-constructed than the spiral stairs from the bedroom — this was a formal entrance.
- **Archway:** A stone archway in the west wall, sealed with an iron gate. Beyond it: the crypt.

**Architectural logic:** This chamber pre-dates the manor above. The manor was built ON TOP of an older structure — a chapel, a hermitage, or something more esoteric. The stairway leading UP to the hallway was the original entrance to this space, before the manor was built over it. The iron gate to the crypt suggests the crypt was always here — this chamber was the antechamber to a burial place. The architectural shift (from rough cellar granite to precision-fitted megalithic blocks) is deliberate and unmistakable. The player should feel that they've gone somewhere fundamentally different.

---

## 2. Sensory Design

### description (lit)
> "The architecture changes here. Where the cellars above were rough-hewn and practical, this chamber is built from massive limestone blocks, dry-stacked with a precision that speaks of older and more deliberate hands. The ceiling rises into a ribbed vault, its central boss carved into a face that stares downward with blank stone eyes. Iron sconces line the walls, unlit and cold. Against the south wall stands a stone altar, its surface inscribed with symbols you cannot read. The air is still and heavy with the smell of ancient dust, old wax, and something fainter — incense, or the memory of incense, burned decades or centuries ago."

**Design notes:** The description MUST communicate the architectural shift — this is THE narrative pivot of Level 1. The player should understand, from the description alone, that they've entered a space that's older, grander, and more purposeful than anything above. The carved face on the vault boss, the altar, the inscriptions — all signal "this place has meaning."

### feel (dark)
> "Smooth stone — worked, polished, precise. Not the rough granite of the cellars. Your fingers find joints between massive blocks, fitted so tightly a knife blade wouldn't pass between them. The ceiling is higher here; you reach up and find only air. The floor is flat and even — large flagstones, some with raised edges that feel like carved borders. Against one wall, your hands find a broad stone surface at waist height — an altar or table, cold as ice, its surface covered in grooves and ridges that might be letters or symbols. The air smells of dust and something older — wax and incense, faint and ancient."

### smell
> "Dust — not the organic dust of the storage cellar, but mineral dust, the slow erosion of stone on stone. Old wax, from candles burned out years ago, their residue soaked into the stone. And beneath it, a ghost of incense — frankincense or myrrh, the kind burned in churches and temples. It clings to the stone like a memory that refuses to fade."

### sound
> "Silence. A deeper silence than the cellar — no dripping water, no scratching rats. The stone walls absorb sound; your own breathing seems muffled, as if the room is swallowing it. When you speak, there's a faint echo from the vaulted ceiling, delayed and hollow, like a cathedral whisper. The silence feels intentional, curated — this is a place built for quiet contemplation or prayer."

---

## 3. Spatial Layout

```
    North Wall (Stairway Up → Hallway)
    ┌──────────────────────────────────────┐
    │                                      │
    │     [stone stairway ↑]               │
    │     (wide stone steps ascending      │
    │      to hallway above)               │
    │                                      │
    │  [unlit     ┌────────────┐  [unlit   │
    │   sconce]   │            │   sconce] │
    │             │  [chain]   │           │
    │  [stone-    │  (hanging  │           │
    │   sarco-    │   from     │           │
    │   phagus]   │   ceiling) │           │
    │             │            │           │
    │             └────────────┘           │
    │                                      │
    │   ┌──────────────────────┐           │
    │   │  [stone altar]       │           │
    │   │  (incense-burner,    │           │
    │   │   tattered-scroll,   │           │
    │   │   offering-bowl      │           │
    │   │   on top)            │           │
    │   └──────────────────────┘           │
    │                                      │
    │   [iron door — from storage cellar]  │
    └───────────────────┬──────────────────┘
    South Wall          │
                        West Wall: [stone archway
                        with iron gate → Crypt]
```

**Placement logic:**
- **Stone altar** — against the south wall, facing north (toward the stairway). This is the focal point of the room. On it: incense burner, tattered scroll, offering bowl.
- **Stone stairway** — north wall, wide stone steps ascending to the hallway. This is the MAIN EXIT upward — the path out of the cellars.
- **Unlit sconces** — two iron wall sconces on the east and west walls, flanking the center space. Empty. Could hold torches or candles.
- **Stone sarcophagus** — against the east wall. Single stone coffin with a carved lid. Heavy, sealed. Contains... something (connects to crypt theme).
- **Chain** — hanging from the vault ceiling, center of room. Iron chain with a ring at the bottom. Pulling it... does what? (Puzzle hook for Bob — could ring a bell, open a mechanism, lower a fixture).
- **Iron gate/archway** — west wall. Stone archway sealed with an iron gate. Gate is locked (silver key). Beyond: the crypt.
- **Silver key** — hidden behind or inside the sarcophagus. Unlocks the crypt gate. Optional discovery.

---

## 4. Exits

### South — Iron Door → Storage Cellar
- **Type:** `door`
- **Passage ID:** `storage-deep-door` (matches storage cellar's north exit)
- **State:** Open (player just came through; unlocked from storage cellar side with iron key)
- **Constraints:** max_carry_size 4, player_max_size 5
- **Design note:** Return path to storage cellar is always available.

### Up — Stone Stairway → Hallway
- **Type:** `stairway`
- **Passage ID:** `deep-cellar-hallway-stairway`
- **State:** Open, always passable. Wide stone steps.
- **Constraints:** max_carry_size 4, player_max_size 5
- **Description:** "Wide stone steps ascend through the north wall, curving upward toward a faint warmth and the suggestion of light. The stairway is older than the cellars above — carved from the living rock, worn smooth by centuries of passage."
- **Design note:** This is the MAIN EXIT from the cellars. The critical path leads HERE → UP → Hallway. Puzzle 011 (Ascent to Manor) is simply navigation — no locked gate, no puzzle. The reward IS the ascent.

### West — Stone Archway → Crypt (OPTIONAL)
- **Type:** `archway` (with iron gate)
- **Passage ID:** `deep-cellar-crypt-archway`
- **State:** Closed, LOCKED (key_id: silver-key). Iron gate in stone archway.
- **Constraints:** max_carry_size 3, player_max_size 5
- **Mutations:** unlock (with silver-key), open, close
- **Description (locked):** "A stone archway is set into the west wall, its rounded top carved with symbols that match those on the altar. An iron gate blocks the passage, secured with a silver padlock that gleams dully in the light. Beyond the gate, stone steps descend into darkness."
- **Description (open):** "The iron gate stands open in the stone archway. Beyond it, worn stone steps descend into a narrow passage that leads west into profound darkness."
- **on_feel:** "Iron bars, closely spaced, cold to the touch. A padlock — small, silver, finely made, unlike the crude iron locks above. The bars are solid; this gate was built to last. Through the gaps, you feel colder air and smell something older — dust and dry stone."
- **Design note:** OPTIONAL EXIT. Leads to the crypt. Requires silver key (hidden in this room). Players who skip this miss the crypt entirely — and its lore/treasures.

---

## 5. Environmental Properties

| Property | Value | Rationale |
|----------|-------|-----------|
| `temperature` | 9°C | Deepest underground chamber. Coldest room in Level 1. Ancient stone retains cold. |
| `moisture` | 0.3 | LOW for an underground space. The precision-fitted stone blocks shed water effectively. The room is dry — deliberately so (built to preserve whatever it contains). |
| `light_level` | 0 | Total darkness. Iron sconces are present but unlit. Player must carry light. |

**Material interactions at moisture 0.3, temperature 9°C:**
- Iron (sconces, gate, chain): Low rust risk — this room is drier than the cellars above. The iron fittings are old but well-preserved.
- Stone (altar, sarcophagus, walls): Stable. The low moisture preserves the carved inscriptions.
- Wax (old candle residue in sconces): Solidified, brittle at 9°C. No auto-transition.
- Fabric (scroll, if player carries cloak): Dry. No dampness effects. The tattered scroll survives because the room is dry.
- Paper/parchment (scroll): Preserved by low moisture — this is WHY the scroll is still readable.

**Environmental design insight:** The low moisture in this room (0.3 vs cellar's 0.8 and storage's 0.5) is a STORY detail. Whoever built this chamber knew how to build dry — they wanted to preserve what's inside (the altar, the scroll, the sarcophagus contents). This room was engineered for permanence.

---

## 6. Objects Inventory

All objects are **🔴 NEW** (need to be designed by Flanders).

### Room-Level Objects

| Object | Type | Spatial Position | Status | Notes |
|--------|------|------------------|--------|-------|
| stone-altar | Stone Altar | Against south wall | 🔴 NEW | Massive limestone altar, immovable. Surface inscribed with symbols. Surfaces: top (holds objects). Focal point of room. |
| unlit-sconce-east | Unlit Sconce | East wall | 🔴 NEW | Iron wall fixture, empty. Can hold torch or candle. Pair with west sconce. |
| unlit-sconce-west | Unlit Sconce | West wall | 🔴 NEW | Iron wall fixture, empty. Same as east sconce. |
| stone-sarcophagus | Stone Sarcophagus | Against east wall | 🔴 NEW | Single stone coffin with carved lid. Heavy (cannot carry). Lid can be pushed/lifted. Contains remains + silver key. |
| chain | Chain | Hanging from vault ceiling | 🔴 NEW | Iron chain with ring at bottom. Pullable. Effect TBD (mechanism? bell? hidden compartment?). |

### Objects On Altar (location = "stone-altar.top")

| Object | Type | Location | Status | Notes |
|--------|------|----------|--------|-------|
| incense-burner | Incense Burner | stone-altar.top | 🔴 NEW | Bronze or iron censer. Cold. Contains cold ash. Examinable — ash is from frankincense/myrrh. Could be re-lit if player has fire source + incense material. |
| tattered-scroll | Tattered Scroll | stone-altar.top | 🔴 NEW | Old parchment, crumbling at edges. Readable — contains lore about the manor's founding, the original builders, hints at the crypt's purpose. First major lore delivery. |
| offering-bowl | Offering Bowl | stone-altar.top | 🔴 NEW | Stone bowl, shallow, carved. Empty. Could accept items — puzzle hook for Puzzle 012 (Altar Puzzle). Placing the right offering might trigger a mechanism (unlock crypt? reveal hidden text? light sconces?). |

### Hidden Objects

| Object | Type | Location | Status | Notes |
|--------|------|----------|--------|-------|
| silver-key | Silver Key | stone-sarcophagus.inside (with remains) | 🔴 NEW | Small, finely made silver key. Unlocks crypt gate. Found by opening sarcophagus and searching. OPTIONAL item — only needed for crypt access. |

**Total: ~10-11 object instances** (9 unique types + 2 sconces of same type)

**Flanders coordination notes:**
- Stone altar: immovable, no FSM needed. But it needs rich `on_look`, `on_feel`, `on_smell` descriptions. The inscriptions should be partially readable (Puzzle 012 hook).
- Sarcophagus: needs FSM: sealed → open (lid pushed aside). Lid is HEAVY — requires strength or a lever (crowbar from storage cellar?). Inside: bones/remains + silver key.
- Chain: pullable object. Effect TBD by Bob/Wayne. Could be: (a) rings a bell in the hallway above, (b) opens a hidden compartment in the wall, (c) lowers a chandelier/fixture from the ceiling, (d) does nothing (red herring — but we don't do false affordances per D-BUG022).
- Sconces: same object type, different instances. Should accept any fire-bearing object (lit candle, lit torch) placed in them. When filled + lit, they increase room light_level.
- Offering bowl: container that accepts objects. Puzzle 012 trigger when the "right" offering is placed. Bob to specify what the offering is.

---

## 7. Puzzle Hooks

| Puzzle ID | Name | Difficulty | Status | Description |
|-----------|------|------------|--------|-------------|
| 011 | Ascent to Manor | ⭐⭐ | 🔴 New | Navigate the stairway UP to the hallway. No lock, no puzzle — just navigation. The reward is the transition itself: from dark cellars to warm hallway. CRITICAL PATH. |
| 012 | Altar Puzzle | ⭐⭐⭐ | 🔴 New | OPTIONAL. Interact with altar objects to trigger a mechanism. Possible solutions: place candle in offering bowl → light → sconces ignite → crypt gate opens. Or read scroll → discover offering → place correct item. Teaches: environmental interaction, symbolic/ritual actions. |

**Bob's design notes:**
- **Puzzle 011** is deliberately simple — the player has earned their escape. The stairway is open and obvious. No gate-keeping.
- **Puzzle 012** should be multi-step and interpretive:
  1. Read scroll → learn about offerings/rituals
  2. Examine altar inscriptions → find clues to what offering is needed
  3. Place correct item in offering bowl → mechanism triggers
  4. Possible correct offerings: candle (light = sanctity), wine bottle (libation), blood (self-sacrifice using pin/needle), or silver key itself (offering the key to receive access)
- **Chain** needs a defined effect. Suggest: pulling the chain rings a bell in the hallway above (foreshadowing — player hears it when they reach the hallway). Or: lowers a stone platform revealing a hidden niche in the wall.
- **Sarcophagus** requires the player to push/lift a heavy lid. Could require tool (crowbar as lever) or just strength. Inside: remains (bones, rotted cloth) + silver key among them. Teaches heavy-object manipulation.

---

## 8. Map Context

### Player Journey Through This Room
1. **Arrival:** Player enters from storage cellar through the south door. Immediate impact: the architecture is DIFFERENT. Older, grander, purposeful.
2. **Awe and exploration:** The vaulted ceiling, the altar, the carved stone — the player knows this place is important. They've left the utilitarian cellars and entered something sacred (or profane).
3. **Lore discovery:** Read the scroll. Examine the altar. Study the inscriptions. First major narrative beat of the game.
4. **Main exit (critical path):** Ascend the stairway to the hallway. This is the way out. Most players will take this.
5. **Optional exploration:** Find and open the sarcophagus → silver key → unlock crypt gate → enter crypt. This is high-effort, high-reward optional content.

### Connections
- **South → Storage Cellar:** Return path. The player came from here.
- **Up → Hallway:** The critical-path exit. Wide stairway ascending to the manor proper. This is where Level 1 ends for most players.
- **West → Crypt:** Optional. Through the locked iron gate. Requires silver key (found in sarcophagus in this room).

### Environment Role
The deep cellar is the **narrative climax** of Level 1:
1. **Architectural revelation:** The shift from rough cellar to precision-fitted megalithic stone tells the player that the manor hides something old and important.
2. **Lore delivery:** The scroll and inscriptions provide the first story content. Who built this? Why? What happened to them?
3. **Progression split:** The room offers TWO forward paths — up (critical, easy) and west (optional, harder). This is the first real CHOICE the player makes beyond "explore more or move on."
4. **Atmosphere peak:** This is the most atmospheric room in Level 1. The silence, the carved stone, the altar — it should feel like entering a place that hasn't been disturbed in centuries. The player is the first visitor in a very long time.
5. **Temperature/moisture contrast:** Coldest room (9°C) but driest underground room (0.3). This is engineered space — built to preserve. The environmental properties tell a story the description doesn't need to state explicitly.
