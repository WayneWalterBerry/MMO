# Phase 5 Review — Moe (World & Level Builder)

**Reviewer:** Moe (World & Level Builder)  
**Date:** 2026-03-28  
**Document:** `plans/npc-combat/npc-combat-implementation-phase5.md`  
**Scope:** Level 2 room design (7 rooms), exit wiring, brass key transition, creature placement, biome consistency, room descriptions, spatial relationships, environment design  

---

## Executive Summary

**Overall Assessment:** ⚠️ **CONCERNS IDENTIFIED — Plan is viable but incomplete for world-building hand-off**

The Phase 5 plan specifies 7 Level 2 rooms with good topology and creature placement strategy. However, **critical environmental design details are missing** that I (Moe) need to proceed with actual .lua file creation. Room descriptions lack sensory depth, spatial relationships are underspecified, and environment design documentation is deferred. The plan is **code-ready** (Bart, Flanders, Smithers can proceed) but **not world-design-ready** (I need more).

**Recommendation:** Plan proceeds to WAVE-1 with **blocking task for Moe to author environmental specifications doc** before I write room .lua files. This unblocks parallel work while ensuring consistency.

---

## Finding 1: Room Specifications — Well-Structured Topology ✅

**Status:** ✅ **GOOD**

### What Works

The 7-room layout is **topologically sound** and strategically designed:

| Room | Biome | Design Quality | Notes |
|------|-------|---|---|
| `catacombs-entrance` | catacombs | ✅ Excellent | Clear transition point from Level 1, acts as gateway |
| `bone-gallery` | catacombs | ✅ Excellent | Central hub connecting 3 destinations; atmosphere rich |
| `underground-stream` | water | ✅ Excellent | Environmental hazard (extinguishes flames); creates detour |
| `collapsed-cellar` | rubble | ✅ Good | Hazard room; loops to spider-cavern via hole; history-grounded |
| `wolf-den` | den | ✅ Excellent | Creature hub; territorial markers; 2-exit design feels natural |
| `werewolf-lair` | lair | ✅ Excellent | Boss room; single exit forces confrontation; highest position |
| `spider-cavern` | web | ✅ Good | Atmospheric; loops via crack (clever size-based gate) |

**Biome types align with Phase 4 systems:**
- `catacombs` → sound propagation (combat alerts)
- `water` → flame extinguish mechanic
- `web` → fire-effective traps
- `den` & `lair` → creature respawn/territory

**Topology prevents softlocks:** Two paths to werewolf-lair (direct via bone-gallery stone door OR longer via stream+wolf-den) = good pacing variety. Spider-cavern crack creates a size-based gate (future mechanic).

---

## Finding 2: Exit Wiring — Topology Correct, Portal Details Missing ⚠️

**Status:** ⚠️ **CONCERN — Needs implementation clarity**

### What Works

**Exit connections are logically sound:**
```
catacombs-entrance → [S: hallway(L1), N: bone-gallery, E: collapsed-cellar]
bone-gallery      → [S: catacombs-entrance, W: underground-stream, N: werewolf-lair(stone door)]
underground-stream → [E: bone-gallery, N: wolf-den(narrow)]
collapsed-cellar  → [W: catacombs-entrance, Down: spider-cavern(hole)]
wolf-den          → [S: underground-stream, E: werewolf-lair(tunnel)]
werewolf-lair     → [S: bone-gallery(stone door), W: wolf-den(tunnel)]
spider-cavern    → [Up: collapsed-cellar, N: wolf-den(crack, size-limited)]
```

**All bidirectional, no orphans.** The layout is **graph-valid**.

### What's Missing

**Portal object specifications are underspecified:**

1. **Stone door (bone-gallery ↔ werewolf-lair):**
   - ⚠️ Is it locked by default? Requires breaking/unlocking?
   - ⚠️ Does it have an FSM state (closed/open/broken)?
   - ⚠️ Who wires the `traversable` flag check?
   - ⚠️ Does werewolf-lair feel threatened if door is opened from north?

2. **Tunnel (wolf-den ↔ werewolf-lair):**
   - ⚠️ Is it always traversable or blocked by webbing/debris?
   - ⚠️ Does wolf-den control access (alpha marks territory)?

3. **Hole (collapsed-cellar ↔ spider-cavern, down/up):**
   - ⚠️ Does it require a climbing object (rope) or free?
   - ⚠️ Hazard: falling damage on descent?

4. **Narrow passage (underground-stream → wolf-den):**
   - ⚠️ Does width constraint affect creature movement?
   - ⚠️ Can werewolf fit through?

5. **Crack (spider-cavern → wolf-den, north, size-limited):**
   - ⚠️ Size-limit explicitly declared? How is it enforced in engine?
   - ⚠️ Does player squeeze through with items, or drop them?

**Decision point:** These are **optional for WAVE-1** (can be simple first pass: all traversable). But they signal mechanical depth I need to design around. **Recommendation: Bart clarifies in gate review — do portal specs go in room .lua or separate portal .lua files?**

---

## Finding 3: Brass Key Transition (L1→L2) — Wiring Incomplete ⚠️

**Status:** ⚠️ **CONCERN — Dependency chain blocking**

### What Works

The brass key mechanic is **conceptually clear:**
- Brass key found in L1 (on rug in start-room)
- Unlocks L1 hallway north exit → L2 catacombs-entrance
- Boundary crossing triggers loader to instantiate level-02.lua

### What's Missing (Bart's WIRING BUG, noted in plan)

**From PRE-WAVE dependency list:**

> | **Brass key/padlock FSM** | `unlock door with brass-key` in deep-cellar doesn't trigger FSM transition for Level 2 stairs | Exit wiring incomplete — `hallway-level2-stairs-up` exit target undefined; FSM transition missing `provides_tool` on brass-key or transition not declared on exit object | Bart |

**Translation (Moe perspective):** I need to know:
1. **Which room contains the Level 2 entry point?** ("deep-cellar" in bug description, but plan says "hallway north → catacombs-entrance")
2. **Is there a physical object (stairs, door, gate) in the hallway that requires unlocking?** Or is the brass key just checked at boundary?
3. **Does the brass-key object declare `provides_tool = "key"` or similar?**
4. **Does the hallway north exit portal declare an FSM transition requiring the tool?**

**Impact on Moe:** I can design the **catacombs-entrance room** (it will be the L2 entry), but I need clarity on **how the brass-key gate room is modeled** so I don't collide with Bart/Smithers' portal design.

**Recommendation:** Bart resolves wiring bug in PRE-WAVE (Gate-0). Moe waits for clarity before finalizing catacombs-entrance description.

---

## Finding 4: Creature Placement — Good Biome Alignment ✅

**Status:** ✅ **GOOD**

### Placement Matrix

| Room | Creature | Count | Reasoning | Quality |
|------|----------|-------|-----------|---------|
| `wolf-den` | Wolf | 3 | Pack size; territory home; easy respawn | ✅ Excellent |
| `underground-stream` | Wolf | 1–2 | Hunting ground; water hazard deters player | ✅ Good |
| `werewolf-lair` | Werewolf | 1 | Boss; territorial; solitary alpha | ✅ Excellent |
| `spider-cavern` | Spider | 2 | Web biome; traps align; small numbers fit space | ✅ Good |
| **Catacombs (bone-gallery, catacombs-entrance)** | *None specified* | — | Empty? Safe passage? | ⚠️ Ambiguous |

### What Works

1. **Territorial logic is sound:** Werewolf owns lair + bone-gallery patrol. Wolves own den + stream hunting. Spiders own cavern. No overlap conflict.
2. **Pack size (wolf=3) scales combat:** Phase 4 foundation (pack.lua, stagger attacks, alpha selection) can handle 3 wolves + 1–2 stragglers.
3. **Werewolf isolation (count=1):** Boss status respected; forces 1v1 confrontation if player reaches lair solo.
4. **Spider placement (count=2):** Small, manageable; web environment is thematic.

### Ambiguity

**Catacombs (bone-gallery, catacombs-entrance) are creature-empty.** Is this intentional?

- **Option A (intended):** Safe passage; player can navigate without combat.
- **Option B (oversight):** Should have lesser creatures (rats, bats) as ambient threats?

**Flanders coordination:** If Option B, I need to hand specs to Flanders for creature objects. If Option A, rooms remain clear.

**Recommendation:** Plan assumes Option A (safe catacombs passages). Keep it. **Moe note: Ensure room descriptions reflect quietness/emptiness explicitly.**

---

## Finding 5: Biome Consistency — Strong Thematic Design ✅

**Status:** ✅ **GOOD**

### Biome Matrix vs. World Theme ("The Manor")

| Biome | Expected Material Palette | Plan Alignment | Theme Consistency |
|-------|--------------------------|--|--|
| `catacombs` | Stone, bone, lime, dust | "Vaulted corridor, bone-patterned walls, niches, lime-dust air" | ✅ Perfect (medieval manor **has** catacombs) |
| `water` | Limestone, moss, mineral deposits | "Natural cavern, limestone stream" | ✅ Perfect (underground geology) |
| `rubble` | Rotted wood, stone, broken casks | "Snapped beams, broken casks, vinegar-rot" | ✅ Perfect (collapsed **wine cellar** — explains contents) |
| `den` | Earth, bone, fur, claw marks | "Packed earth, gnawed bones, musky predator stink, claw marks" | ✅ Perfect (wolf habitat realism) |
| `web` | Silk, desiccated insect husks, stone | "Thick webs wall-to-wall, desiccated husks, sticky air" | ✅ Perfect (spider ecology) |
| `lair` | Stone, bone, torn fabric, lantern wreckage | "Rough pillars, human artifacts (torn clothing, broken lantern), deep stone gouges, rank musk" | ✅ Perfect (werewolf lair as corrupted human space) |

**Temperature annotations** (6°C–11°C) are **realistic and useful** for material system integration (e.g., ice formation, condensation, wood swelling).

**Material consistency with World theme:** All materials are **period-appropriate** (stone, bone, wood, iron). **No anachronisms.** ✅

---

## Finding 6: Room Descriptions — INCOMPLETE (Blocker for Implementation) ❌

**Status:** ❌ **BLOCKER — Descriptions lack sensory depth required for .lua files**

### What the Plan Provides

Short **atmosphere summaries** (25–40 words each):
- `catacombs-entrance`: "Narrow stone passage, carved arch, faded inscriptions, cold draft, dust"
- `bone-gallery`: "Vaulted corridor, bone-patterned walls, niches, lime-dust air. 6°C"
- `underground-stream`: "Natural cavern, limestone stream, echoing water, mineral smell, dripping. 5°C, moisture 0.8"

**These are good starting points, but insufficient for room .lua files.**

### What's Missing (Per My Charter)

Every room MUST have (per `Moe Charter` § Room Design Checklist):

1. **Physical reality:** Era? Style? Material composition? ✅ *Implied but not explicit*
2. **Sensory design:** Description (lit), **on_feel (dark)**, **on_smell**, **on_listen** — *for each lighting state* ❌ **NOT PROVIDED**
3. **Spatial layout:** Where are objects placed? (on, in, under, against) ❌ **NOT PROVIDED (need explicit nesting tree)**
4. **Exits:** Portal details? Locked/hidden/conditional? ⚠️ **UNDERSPECIFIED** (see Finding 2)
5. **Environmental properties:** Temp, moisture, light level — ✅ *Partially* (temps given, light=0 all rooms)
6. **Objects inventory:** What's in each room? ⚠️ **VAGUE** (e.g., "provisions, old supplies" in deep-storage)
7. **Puzzle hooks:** What puzzle opportunities? ❌ **NOT PROVIDED**
8. **Map context:** How does it connect to adjacent rooms? ✅ *Topology clear*

### Example: What I (Moe) Need to Write `bone-gallery.lua`

**Currently (from plan):**
```
| `bone-gallery` | Vaulted corridor, bone-patterned walls, niches, lime-dust air. 6°C
```

**What I need:**

```lua
return {
    -- ... metadata ...
    
    -- DESCRIPTION (permanent features only, per docs/architecture/rooms/dynamic-room-descriptions.md)
    description = "You stand in a vaulted corridor of pale limestone. High ribs of stone arch overhead, creating a skeletal geometry that seems almost intentional — or perhaps just what time has made of this place. The walls are pierced by deep niches, each one bone-white from centuries of mineral seepage. Faint air currents move through the passage, carrying the smell of lime dust and underground stone. A cold draft emanates from the north. The silence is absolute — only the sound of your own breathing breaks it.",
    
    -- SENSORY FIELDS (for dark navigation)
    on_feel = "Cold, smooth limestone under your fingertips. The arches are rough with mineral deposits.",
    on_smell = "Acrid lime dust and mineral-rich stone. Faintly metallic undertones.",
    on_listen = "Your footsteps echo unnaturally in this vaulted space. A faint dripping sound comes from somewhere distant.",
    
    -- INSTANCES (spatial layout — where do objects go?)
    instances = {
        { id = "bone-pile", type_id = "{guid}", on_top = { ... }, nested = { ... } },
        -- ... etc ...
    },
    
    -- ... exits table ...
}
```

**Current plan provides NONE of these sensory fields or instance trees.**

### Impact on WAVE-1

**Blocking:** I cannot write the 7 room .lua files without these specs. Bart/Flanders/Smithers can proceed (they have enough detail in the plan). But **Moe is stuck waiting for environmental design specs.**

**Recommendation:** **Create blocking task for Moe in PRE-WAVE: Produce `level2-environmental-specifications.md` document detailing sensory descriptions, object inventories, spatial layouts, and puzzle hooks for all 7 rooms.** This should be completed **before WAVE-1**, freeing me to write room .lua files in parallel with Bart's engine work.

---

## Finding 7: Spatial Relationships — Underspecified ⚠️

**Status:** ⚠️ **CONCERN — Instance trees not detailed**

### What Works

**Topology (room-to-room connections) is clear.** Exits are well-wired.

### What's Missing

**Spatial relationships WITHIN rooms** (per Moe's charter: "Design room descriptions for all sensory states" and "Specify what objects belong in each room and where").

**Example: `wolf-den.lua` needs:**

```lua
instances = {
    { id = "scattered-bones", type_id = "{guid}",
        on_top = { { id = "claw-marks-on-bone", ... } },  -- what objects are ON bones?
        underneath = { ... }  -- what's buried?
    },
    { id = "bone-pile-1", type_id = "{guid}", on_top = { ... } },
    { id = "bone-pile-2", type_id = "{guid}", contents = { ... } },
    { id = "scent-marker", type_id = "{guid}" },  -- wolf territory marker object?
    -- ... etc ...
}
```

**Current plan provides only:** "Low ceiling, packed earth, gnawed bones, musky predator stink, claw marks."

**This is atmospheric flavor, NOT a spatial instance tree.**

### Why It Matters

Per `docs/architecture/rooms/dynamic-room-descriptions.md`:
- **Part 1 (description):** Permanent features → written in plan ✅
- **Part 2 (room_presence):** Objects contribute their presence → **REQUIRES instance tree** ❌
- **Part 3 (exits):** Auto-composed ✅

If I don't have the instance tree, I can't wire the object presences into the room.

### Recommendation

**Same as Finding 6:** Environment design specs doc must include explicit instance trees for all 7 rooms. Flanders will then hand me the object .lua files, and I'll integrate them into room instances.

---

## Finding 8: Environment Design Documentation — Deferred ⚠️

**Status:** ⚠️ **CONCERN — Documentation path unclear**

### What's Required (Per My Charter)

> "Write room/world design docs in `docs/design/rooms/` and `docs/rooms/`"

> "Every room MUST be documented in `docs/rooms/`—one .md per room"

> "Room DESIGN methodology goes in `docs/design/rooms/`"

> "Map overviews (how rooms connect) go in `docs/design/rooms/map-overview.md`"

### What the Plan Specifies

From `Section 8: Deliverables → WAVE-4`:

> | Brockman | **Level 2 ecology doc** | Write `docs/design/level2-ecology.md`. Content: L2 room descriptions, creature habitats, biome types, treasure placement, navigation map |

**This is correct but DEFERRED to WAVE-4.** By then, Moe will have written 7 room .lua files without documented methodology.

### Recommendation

**Create a PRE-WAVE documentation task for Moe:** Write `docs/design/level2-design-methodology.md` and spatial/sensory templates **before WAVE-1**. This enables:
1. Consistent room definitions across all 7 files
2. Artifact that Brockman can reference for final Level 2 ecology doc
3. Clear team understanding of Level 2's design language

**Does NOT require a separate PR** — can be committed alongside room .lua files in WAVE-1.

---

## Finding 9: Light Levels & Dark Navigation — Well-Specified ✅

**Status:** ✅ **GOOD**

The plan specifies: **"All L2 rooms start dark (light=0)."**

This is **correct and thematic:**
- Level 1 starts at 2 AM (darkness, but some ambient light)
- Level 2 catacombs have **zero natural light** (underground, no windows)
- Player must use candles/torches to navigate
- Feeds dark-navigation system (on_feel is primary sense)

**Material system integration:** Cold temps (5–11°C) + darkness + moisture = **perfect for touch-based navigation testing.**

---

## Finding 10: Brass Key Continuity (L1→L2 Progression) — Clear ✅

**Status:** ✅ **GOOD** (pending Bart's wiring clarity)

### What Works

1. **Brass key is a gate object:** Found in L1, enables L2 entry ✅
2. **Progression logic:** Player completes L1 → earns brass key → unlocks L2 ✅
3. **Narrative flow:** "descends to Level 2 catacombs" signals escalation ✅
4. **No softlock:** Alternative paths (stone door, tunnels) prevent sequence-breaking ✅

### Dependency

Wiring clarity needed from Bart (see Finding 3). Once resolved, progression is **solid**.

---

## Finding 11: Creature Loot Integration — Good but Flanders-Dependent ⚠️

**Status:** ⚠️ **CONCERN — Loot placement strategy incomplete**

### What Works

Werewolf loot table is specified:
- Always: hide, claw
- Weighted: silver-pendant (25%), torn-journal-page (35%), nothing (40%)
- Variable: gnawed-bone ×1–3

**Supports narrative depth** (journal page hints at past, pendant is mystery item).

### What's Missing

**Placement of loot objects in rooms:**

- ⚠️ Does werewolf-pelt appear in werewolf-lair as ambient object (trophy)? Or only from corpse?
- ⚠️ Does the torn-journal-page refer to a specific room/history? Should copies exist elsewhere?
- ⚠️ Silver-pendant — is there lore tying it to bone-gallery (burial site?) or werewolf (keepsake?)?

**Impact:** Minor. Loot is dropped on death, not fixed-placement. But **room atmosphere could reference these items** (e.g., "pelt stretched on cave wall" → clues werewolf is dangerous).

### Recommendation

Flanders and I (Moe) should **sync briefly on loot narrative placement.** No blockers, but will improve Level 2 cohesion.

---

## Finding 12: Level 2 Biome Narrative — Excellent Conceptual Foundation ✅

**Status:** ✅ **GOOD**

### Why Level 2 Works Thematically

| Narrative Arc | Biome Progression | Design Excellence |
|---|---|---|
| L1: "Waking in bedroom" | Domestic (wood, fabric, familiar) | Claustrophobic, intimate |
| L2 PRE: "Descending via brass key" | Transition (stone stairs, cold) | Liminal, danger escalates |
| L2 MAIN: "Deep dungeon" | Catacombs (bone, vaults, ceremony?) | Ancient, mysterious, hostile |
| L2 BRANCH: "Natural cavern" | Stream/water | Escape route? Or trap? |
| L2 APEX: "Werewolf lair" | Corrupted space (human artifacts + beast territory) | Hybrid terror, confrontation |

**Each biome tells a story** without explicit dialogue. The player *feels* deeper underground, more primitive danger. Level 2 escalates from L1's domestic horror to **ecological horror** (wild creatures in wild spaces).

**World theme ("The Manor") is stretched here — underground passages exist beneath manors, but catacombs + werewolves suggest older history.** ✅ *Explained by plan's note: "human artifacts in werewolf-lair" suggests this space predates the manor itself.*

---

## Summary: Blockers & Recommendations

### ❌ Critical Blockers

**None that prevent WAVE-1 from starting.** Bart, Flanders, Smithers have enough detail.

### ⚠️ Blockers for Moe (WAVE-1 completion)

1. **Brass key wiring clarity** (Bart) — Low priority; catacombs-entrance can be written speculatively.
2. **Environmental specifications doc** (Moe, PRE-WAVE) — HIGH PRIORITY. Blocks me from writing room .lua files confidently.

### ⚠️ Clarifications Needed

| Item | Owner | Priority | Impact |
|------|-------|----------|--------|
| Portal object specs (stone door, tunnel, hole, crack) | Bart | Medium | Affects room description flavor |
| Instance tree templates for 7 rooms | Moe | HIGH | Blocks spatial layout design |
| Sensory fields (on_feel, on_smell, on_listen) for 7 rooms | Moe | HIGH | Blocks .lua file creation |
| Object inventory per room (creatures, items, fixtures) | Flanders/Moe collab | HIGH | Blocks instance instantiation |
| Puzzle hooks and hazard mechanics | Bob/Moe | Low | Phase 6 (future trap work) |

### ✅ Recommendations for Plan Approval

1. **Proceed with Phase 5 as designed.** Topology and creature placement are solid.
2. **Add PRE-WAVE task for Moe:** Write environmental specifications doc (sensory fields, instance trees, object inventory, spatial layouts) for all 7 rooms.
3. **Bart clarifies brass key wiring** in PRE-WAVE gate review (low blocking priority, but important for narrative continuity).
4. **Flanders and Moe sync on object placement** (15-min sync) before WAVE-1 kicks off — ensures no collision on creature habitat assumptions.
5. **Plan assumes all catacombs/bone-gallery rooms are creature-empty** — confirm with Flanders (Option A vs. Option B per Finding 4).

---

## Confidence Assessment

| Dimension | Confidence | Reasoning |
|-----------|-----------|-----------|
| **Topology** | 🟢 100% | Exit wiring is graph-valid, bidirectional, no orphans |
| **Creature placement** | 🟢 95% | Good biome alignment; werewolf placement excellent; minor ambiguity on catacombs creature-emptiness |
| **Biome consistency** | 🟢 100% | Materials, temperatures, atmosphere all align with world theme |
| **Environmental design** | 🟡 60% | Room descriptions exist but lack sensory depth and instance trees required for .lua implementation |
| **L1→L2 transition** | 🟡 75% | Brass key mechanic clear but wiring details pending Bart clarification |
| **Overall plan viability** | 🟢 90% | Code-ready for Bart/Flanders/Smithers; documentation-ready with minor gaps |

---

## Final Recommendation

**APPROVE Phase 5 plan for WAVE-1 launch.** Add **PRE-WAVE environmental specifications task for Moe** to unblock room .lua file creation. Plan is well-structured, topology is solid, and creature placement is strategic. World-building can proceed in parallel with engine/creature work once Moe completes environmental specs.

---

**Status:** Ready for Bart's gate review.  
**Next Steps:** Moe authors `level2-environmental-specifications.md` (PRE-WAVE blocking task).

