# Room Design: The Crypt

**Room ID:** `crypt`  
**File:** `src/meta/rooms/crypt.lua` *(not yet created)*  
**Status:** 🔴 New — Design Only (OPTIONAL ROOM)  
**Author:** Moe (World Builder)  
**Date:** 2026-07-21  
**Level:** 1 — The Awakening  
**Act:** III — The Deep Secret (Optional Branch)  

---

## 1. Physical Reality

**Space type:** Family crypt / burial chamber beneath the manor — the oldest space in the entire building  
**Era/style:** Pre-medieval (~8th–10th century). Saxon or early Norman. The stonework here is the most ancient in the manor complex — enormous, rough-cut blocks with chisel marks still visible. This space was carved out of bedrock and lined with stone centuries before the manor was built above. It has the feel of a catacomb or early Christian burial vault — functional, solemn, timeless.  
**Dimensions (implied):** Roughly 8m × 4m — long and narrow, like a nave. Vaulted ceiling ~2.5m. Five stone sarcophagi line the walls (three on the left/south, two on the right/north), with a narrow central aisle between them. The proportions are deliberate: this is a procession space, built so mourners could walk between the tombs.  
**Materials:**
- **Walls:** Massive rough-cut limestone blocks, toolmarks visible. Dry (despite depth — the construction channels water away). Some blocks have carved inscriptions — names, dates, religious symbols, blessings or warnings.
- **Floor:** Flat bedrock, smoothed but not polished. Grit and dust. No flagstones — the floor IS the rock.
- **Ceiling:** Low barrel vault, carved from bedrock. Soot stains near the entrance from centuries of candle and torch smoke.
- **Sarcophagi:** Five stone coffins, each carved from a single block of limestone. Lids carved with full-length effigies of robed figures — hands folded, faces serene. Heavy enough that a single person would struggle to move them.
- **Wall niches:** Small rectangular recesses in the walls between sarcophagi. Some contain candle stubs. Some contain small objects (offerings? mementos?).

**Architectural logic:** This is the oldest part of the manor complex — the reason the manor exists at all. A family or religious order chose this site for burial, carved the crypt from bedrock, and over centuries built the chapel (deep cellar), the cellars, and eventually the manor house above. The crypt is the foundation — literally and narratively. The five sarcophagi represent five generations of the founding family (or five members of a religious order). The inscriptions, if the player can decipher them, tell the story of who these people were and why the manor was built here. This is the deepest lore repository in Level 1.

---

## 2. Sensory Design

### description (lit)
> "Five stone coffins line the walls of a narrow vault carved from the living rock. Their lids bear the carved likenesses of robed figures, hands folded over chests that will never rise again, faces worn smooth by time until they are almost featureless. Small niches are cut into the walls between the tombs, some holding candle stubs burned down to waxy puddles, others empty. The air is perfectly still, cold, and dry — the kind of stillness that comes from being sealed away from the world for centuries. Dust motes hang motionless in your light. Inscriptions cover every available surface — names, dates, prayers, and symbols that repeat like a chorus."

**Design notes:** The description should evoke REVERENCE, not horror. These are not monsters in coffins — they are people, once loved, now forgotten. The "featureless" faces communicate great age without being ghoulish. The candle stubs show that someone used to visit and light candles for the dead. The inscriptions are everywhere — this room is WRITTEN ON, like a book in stone.

### feel (dark)
> "Cold stone on all sides. Your hands find smooth surfaces rising from the floor — coffins, waist-high, their lids carved into shapes that feel like sleeping figures when your fingers trace them. Folded hands. A face, worn smooth, features eroded to suggestions. Between the coffins, small square holes in the wall — niches — containing waxy lumps and grit. The floor is bare rock, cold and gritty. The air is utterly still. No draft, no drip, no breath but your own. It smells of dust and old stone and the faint sweetness of ancient wax. You are in a tomb."

### smell
> "Dust — mineral, ancient, the fine powder of stone slowly eroding. Old wax — not fresh beeswax like the hallway, but candle wax burned years ago, its residue soaked into the stone niches. Dry stone — clean, cold, absent of moisture or life. No decay, no rot — whatever remains are in these coffins, they have long since returned to dust. The air smells of endings — not violent ones, but the quiet, patient ending of all things."

### sound
> "Nothing. Absolute, profound silence. Not the muffled silence of the deep cellar, but a silence that feels INTENTIONAL — as if the room was built to contain it. No water drips. No rats scratch. No wind reaches here. When you hold your breath, you hear only the blood in your own ears. This silence is so complete it has weight — it presses against you, reminding you that you are a living thing in a place built for the dead."

---

## 3. Spatial Layout

```
    West Wall (Stone archway → Deep Cellar)
    ┌──────────────────────────────────────────┐
    │                                          │
    │  [stone archway / entrance]              │
    │                                          │
    │  ┌───────────┐          ┌───────────┐    │
    │  │sarcoph-1  │  [niche] │sarcoph-4  │    │
    │  │(effigy:   │  (candle │(effigy:   │    │
    │  │ oldest)   │   stub)  │ younger)  │    │
    │  └───────────┘          └───────────┘    │
    │                                          │
    │  ┌───────────┐  [niche] ┌───────────┐    │
    │  │sarcoph-2  │  (empty) │sarcoph-5  │    │
    │  │(effigy:   │          │(effigy:   │    │
    │  │ second    │          │ youngest, │    │
    │  │ generation│          │ TOME      │    │
    │  │ )         │          │ inside)   │    │
    │  └───────────┘          └───────────┘    │
    │                                          │
    │  ┌───────────┐  [niche]                  │
    │  │sarcoph-3  │  (burial                  │
    │  │(effigy:   │   coins)                  │
    │  │ third gen)│                            │
    │  └───────────┘                            │
    │                                          │
    │            [wall-inscription]             │
    │            (east wall, large              │
    │             carved text panel)            │
    │                                          │
    └──────────────────────────────────────────┘
    East Wall (Back of crypt — inscribed wall)
```

**Placement logic:**
- **Sarcophagi** — five total, arranged along the long walls (3 south, 2 north), with a narrow aisle between. Numbered 1-5 from entrance (west) to back (east), representing chronological order (oldest burial nearest the entrance, youngest at the back).
- **Wall niches** — between sarcophagi, in the walls. Small rectangular recesses. Some hold candle stubs (evidence of visits), some hold small objects (coins, trinkets), some are empty.
- **Wall inscription** — large carved text panel on the east (back) wall. The most significant piece of readable text in the crypt. Contains the family/order motto, a prayer, or a warning.
- **Stone archway** — west wall. Entrance from the deep cellar. The iron gate is on the deep cellar side.

---

## 4. Exits

### East — Stone Archway → Deep Cellar
- **Type:** `archway`
- **Passage ID:** `deep-cellar-crypt-archway` (matches deep cellar's west exit)
- **State:** Open (player unlocked the iron gate from the deep cellar side with silver key)
- **Constraints:** max_carry_size 3, player_max_size 5
- **Design note:** This is the ONLY exit. The crypt is a dead end. The player must return the way they came. This creates a sense of finality and isolation — you're at the deepest, farthest point of Level 1.

**No other exits.** The crypt is a terminal room. There is no secret passage, no hidden tunnel, no way out except back through the deep cellar. This is intentional — the crypt feels sealed, final, separate from the living world above.

---

## 5. Environmental Properties

| Property | Value | Rationale |
|----------|-------|-----------|
| `temperature` | 8°C | Deepest space, bedrock. Constant temperature — cave-like conditions. Cold but stable year-round. |
| `moisture` | 0.1 | EXTREMELY LOW. The builders deliberately channeled water away from the crypt. The stone is dry to the touch. This is why the remains, the inscriptions, and the tome are preserved. |
| `light_level` | 0 | Total darkness. The candle stubs in the niches are unlit. Player must carry light. |

**Material interactions at moisture 0.1, temperature 8°C:**
- Stone (sarcophagi, walls, floor): Perfectly preserved. The inscriptions are still legible after centuries. Low moisture prevents erosion.
- Wax (candle stubs): Solid, brittle at 8°C. Could be relit if player has fire source, but they're short — won't burn long.
- Iron (none in this room — deliberately): The builders used NO iron in the crypt. All stone. This is a design detail: iron rusts; stone endures. They wanted this place to last.
- Parchment (tome): Remarkably preserved. The low moisture and sealed environment created ideal conservation conditions. The tome is readable after centuries.
- Fabric (burial shrouds, if present): Mostly deteriorated to fragments, but traces remain in the sarcophagi.
- Bone (remains): Dry, clean, reduced to skeletal form. No decay smell — the organic material decomposed centuries ago.

**Environmental design insight:** The crypt's environmental properties (0.1 moisture, 8°C, sealed) are PRESERVATION conditions. This is the driest room in Level 1 — the builders knew what they were doing. The tome survives because the room was built to preserve it. This isn't accident; it's engineering.

---

## 6. Objects Inventory

All objects are **🔴 NEW** (need to be designed by Flanders).

### Sarcophagi (each is a container with carved lid)

| Object | Type | Location | Status | Notes |
|--------|------|----------|--------|-------|
| sarcophagus-1 | Stone Sarcophagus | South wall, nearest entrance | 🔴 NEW | Oldest burial. Effigy: robed figure with a staff. Inside: bones, dust, fragments of cloth. No treasure. The first to be buried here. |
| sarcophagus-2 | Stone Sarcophagus | South wall, middle | 🔴 NEW | Second generation. Effigy: robed figure with a book. Inside: bones, a corroded bronze ring. Lore: a scholar or scribe. |
| sarcophagus-3 | Stone Sarcophagus | South wall, farthest | 🔴 NEW | Third generation. Effigy: robed figure with a sword. Inside: bones, the silver dagger (burial good). Lore: a warrior or guardian. |
| sarcophagus-4 | Stone Sarcophagus | North wall, nearest entrance | 🔴 NEW | Fourth generation. Effigy: robed figure with folded hands (no object). Inside: bones, burial jewelry (necklace). Lore: a person of peace. |
| sarcophagus-5 | Stone Sarcophagus | North wall, farthest | 🔴 NEW | YOUNGEST burial, most recent. Effigy: robed figure with an open book on chest. Inside: bones AND the tome (placed with the body). This is the KEY sarcophagus — the tome is the major lore prize. |

### Wall Niche Contents

| Object | Type | Location | Status | Notes |
|--------|------|----------|--------|-------|
| candle-stub-1 | Candle Stub | wall-niche-1 (between sarcoph-1 & sarcoph-2) | 🔴 NEW | Short candle, old wax. Relightable but burns for only minutes. Evidence someone visited. |
| candle-stub-2 | Candle Stub | wall-niche-3 (between sarcoph-2 & sarcoph-3) | 🔴 NEW | Same as above. |
| burial-coins | Burial Coins | wall-niche-2 (between sarcoph-4 & sarcoph-5) | 🔴 NEW | A few tarnished copper/silver coins. Offerings for the dead. Takeable but feel morally weighted. |

### Sarcophagus Contents (nested, hidden until lid opened)

| Object | Type | Location | Status | Notes |
|--------|------|----------|--------|-------|
| bronze-ring | Bronze Ring | sarcophagus-2.inside | 🔴 NEW | Corroded bronze ring. Wearable? Lore item. Inscription on inner band. |
| silver-dagger | Silver Dagger | sarcophagus-3.inside | 🔴 NEW | Short blade, silver, tarnished but sharp. Tool/weapon. Valuable. Ceremonial. |
| burial-necklace | Burial Necklace | sarcophagus-4.inside | 🔴 NEW | Delicate chain with a pendant (symbol matching altar inscriptions). Lore item. |
| tome | Tome | sarcophagus-5.inside | 🔴 NEW | THE major lore item of Level 1. Leather-bound book, aged but readable (dry conditions preserved it). Contains the history of the founding family, the purpose of the crypt, and hints about the manor's dark secret. Bob/Wayne to write lore content. |

### Other Objects

| Object | Type | Spatial Position | Status | Notes |
|--------|------|------------------|--------|-------|
| wall-inscription | Wall Inscription | East wall (back of crypt) | 🔴 NEW | Large carved text panel. Readable. Contains family/order name, dates, motto, prayer, or curse. Examinable — READ INSCRIPTION reveals text. A second major lore delivery (complementing the tome). |

**Total: ~14-16 object instances** (12 unique types, multiple sarcophagi of same type)

**Flanders coordination notes:**
- All 5 sarcophagi share a base type but need UNIQUE instances (different effigies, different contents). Each effigy should have detailed `on_look` text describing the carved figure.
- Sarcophagus lids are HEAVY. FSM: sealed → open (lid pushed aside). Opening requires effort — crowbar as lever, or two hands + strength. Once opened, cannot be re-closed (lid is too heavy to push back).
- Tome: Readable object with LONG text. `on_read` should deliver 2-3 paragraphs of lore. This is the narrative payoff for reaching the crypt. Wayne to approve/write lore content.
- Silver dagger: Tool/weapon. `provides_tool = "blade"` (same as knife). Also has intrinsic value. Could be used in future levels.
- Wall inscription: Readable scenic object (not takeable). `on_read` reveals carved text. Could also have `on_feel` for tracing the carved letters in the dark.
- Candle stubs: Relightable but SHORT duration (2-3 minutes). Atmospheric detail showing the crypt was once visited.

---

## 7. Puzzle Hooks

| Puzzle ID | Name | Difficulty | Status | Description |
|-----------|------|------------|--------|-------------|
| 014 | Sarcophagus Puzzle | ⭐⭐⭐ | 🔴 New | OPTIONAL. Open sarcophagi to find burial goods and the tome. Teaches: heavy-object manipulation (PUSH/LIFT lid), exploration reward (treasures inside), moral choice (rob the dead?). |

**Bob's design notes:**
- **Puzzle 014** is less a puzzle and more an exploration challenge. The "puzzle" is figuring out that you CAN open the sarcophagi (PUSH LID, LIFT LID, PRY LID with crowbar) and then deciding WHICH to open and WHAT to take.
- **Multiple sarcophagi, different rewards:** Not every coffin contains treasure. Sarcophagus-1 has only bones — the player learns that exploration doesn't always pay off. Sarcophagus-3 has the silver dagger — a tangible reward. Sarcophagus-5 has the tome — the narrative reward.
- **Moral weight:** Taking burial goods should feel morally significant. The descriptions should make the player think about what they're doing — robbing graves. No mechanical penalty, but the tone should be respectful/uncomfortable.
- **Heavy lids:** Opening requires effort. The crowbar from the storage cellar is ideal as a lever. Without it, the player needs to PUSH the lid (harder, maybe requires two attempts, or triggers a strain message). This rewards players who brought the right tools.

---

## 8. Map Context

### Player Journey Through This Room
1. **Arrival:** Player passes through the iron gate from the deep cellar. Descends worn stone steps into the narrow burial chamber.
2. **Impact:** Five stone coffins. Carved faces staring at the ceiling. Absolute silence. The player knows they've reached the DEEPEST, OLDEST point of the manor.
3. **Exploration:** Examine effigies (lore from carved details). Read wall inscription (names, dates, history). Light candle stubs (atmosphere).
4. **Discovery:** Open sarcophagi one by one. Find bones, burial goods, and ultimately the tome.
5. **Lore payoff:** Read the tome. Learn the manor's founding story. Understand why the crypt exists.
6. **Return:** Exit back through the archway to the deep cellar. Continue upward to the hallway.

### Connections
- **East → Deep Cellar:** The only exit. Back through the stone archway and iron gate.

### Environment Role
The crypt is the **narrative climax and deepest exploration point** of Level 1:
1. **Lore repository:** This room exists to TELL THE STORY. The tome, the inscriptions, the effigies, the burial goods — everything here is narrative content. The player who reaches the crypt is rewarded with understanding.
2. **Atmospheric culmination:** The silence, the cold, the dry air, the ancient stone — this is the most atmospheric room in Level 1. It should feel like a place outside of time.
3. **Exploration reward:** Only accessible to players who found the silver key in the deep cellar and unlocked the iron gate. This is high-effort, high-reward optional content. Completionists will find it; casual players won't.
4. **Dead end by design:** No secret passages, no hidden tunnels. The crypt is a terminus. You come here, you learn, you leave. The simplicity of the room layout (one entrance, five coffins, one inscription) focuses the player on CONTENT, not navigation.
5. **Chronological journey:** The five sarcophagi tell a generational story (oldest to youngest). The player walks through time as they walk through the room. The tome in the final sarcophagus is the last chapter — the most recent burial, with the most recent knowledge.

### Adjacency Notes
- **East:** Deep cellar (via stone archway). The only way in and out.
- The crypt is the DEEPEST point of Level 1 — both physically (underground) and narratively (oldest history). Everything from here is UP and OUT.
