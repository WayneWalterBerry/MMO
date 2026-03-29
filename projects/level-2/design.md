# Level 2 Design Reference

**Owner:** Moe (World & Level Builder)  
**Created:** 2026-03-29  
**Source:** Wayne's locked decisions (session 2026-03-29)  
**Status:** 🔒 FINAL — All decisions locked, ready for room design

---

## 1. Level Overview

**Theme:** Garden & grounds exterior  
**Setting:** Estate surrounding the manor house (Level 1)  
**Room Count:** 8–12 rooms (confirmed)  
**Difficulty:** Gradual progression from Level 1 endgame (no major mechanic jumps)  
**Atmosphere:** Natural outdoor environment with weather mechanics, one supernatural element  
**First-Time Lighting:** Natural light becomes mechanically relevant (2 AM dark, noon bright)

---

## 2. Level Topology Map (FINAL)

```
┌─ LEVEL 1 INTERIOR ─────────────┐
│  Bedroom (window portal #199)   │
│  ↓ (sheet-rope puzzle gate)     │
│  ↓                              │
├─ COURTYARD ──────────────────┐  ├─────────────────────────────┐
│ (transition room)            │  │ LEVEL 1 DEEP CELLAR (end)   │
│                              │  │ Staircase ascending ↑       │
└─→ GARDEN ROOMS ──→ Gatehouse │  └─────────────────────────────┘
    (8-12 rooms)       ↓       │           ↑
    including:         │       │    (staircase ascends THROUGH
    - Mausoleum ←──────┴───────┤     mausoleum floor)
    - Greenhouse               │
    - Stables                  │
    - Hedge maze (exit)        │
    - Natural garden zones     │
                               │
                    ↓ (Level 3 entry)
                 MAUSOLEUM PUZZLE GATE
                    (Sideshow Bob designs)
                               │
                               ↓
                          LEVEL 3 VILLAGE

Legend:
- Mausoleum: Dual-role freestanding structure (arrival + Level 3 gate)
- Courtyard: Hub connecting Level 1 bedroom (via window) to garden
- Gatehouse: Estate boundary → moorland / wilderness (Level 4+)
- Hedge maze: Uncontrolled exit to Level 2→4 transition
```

### Level 1 Entry Points to Level 2 (Two Paths)

1. **Early-Access Shortcut:** Bedroom window → Courtyard (requires sheet-rope puzzle)
2. **Canonical Progression:** Deep cellar staircase → Mausoleum (Level 1 finale)

---

## 3. Key Structures & Rooms

### **Mausoleum** (Room, not movable object)
- **Role:** Freestanding stone structure in the garden
- **Dual function:**
  - **Arrival room** — Where the deep cellar staircase emerges (Level 1 completion)
  - **Level 3 gate** — Contains puzzle-locked descent to Level 3
- **Sensory:** Stone/masonry interior, crypts or burial chambers, architectural detail
- **Flavor:** Landmark visible from garden, inviting exploration
- **Interactions:** Mausoleum interior puzzle (Flanders + Sideshow Bob)
- **Ownership:** Moe (room), Flanders (objects), Sideshow Bob (puzzle)

### **Courtyard** (Room)
- **Role:** Connective hub between manor (Level 1) and garden (Level 2)
- **Connectivity:**
  - Accessible from Level 1 bedroom window via sheet-rope puzzle
  - Connects to garden rooms (garden gate, archway, or path portal)
- **Placement:** Adjacent to manor exterior (patio, formal courtyard, walled garden possible)
- **Sensory:** Paved or gravel surface, walls, sky, transition from interior to exterior
- **Design intent:** First room player experiences in Level 2 if using early-access shortcut
- **Ownership:** Moe (placement + connectivity)

### **Garden Rooms** (6-10 rooms)
- **Examples:** Greenhouse, stables, fountain area, herb garden, orchard, hedge maze
- **Distribution:** Spread around the estate grounds
- **Interconnections:** Natural layout reflecting real-world manor estate topology
- **Anchor point:** Mausoleum as visual landmark
- **Exit structure:** Hedge maze → moorland (Level 2→4 transition)
- **Ownership:** Moe (layout + descriptions)

### **Gatehouse** (Room)
- **Role:** Estate boundary, Level 2→3 exit
- **Placement:** At edge of Level 2 garden/grounds
- **Portal target:** Level 3 Village (primary exit)
- **Flavor:** Transition structure, marks civilization boundary
- **Ownership:** Moe (room design)

---

## 4. Transitions & Portals

### **Bedroom Window ↔ Courtyard (Early-Access Shortcut)**

**Status:** Currently implemented (#199 portal), needs prerequisites  

**Mechanics:**
- Player can LOOK at bedroom window → sees courtyard description (teaser mechanic)
- Window portal checks for sheet prerequisite before allowing `exit window`
- **GOAP prerequisite:** `exit window requires sheet-tied-to-window`

**Puzzle Gate:**
- Player finds bed sheet (Level 1 object, already exists)
- Returns to bedroom window
- Uses/ties/attaches sheet at window as makeshift rope
- Sheet enters `sheet-tied` state (Flanders mutation)
- Exit portal now allows traversal → Courtyard
- Design intent: "I can see it but can't reach it yet" discovery → puzzle → reward

**Implementation Notes:**
- Portal template needs `show_destination_on_look = true` flag (Flanders)
- Window object checks for sheet-in-hand or sheet-tied state (Moe/portal logic)
- Sheet object gains `sheet-tied` mutation (Flanders)
- Window look-through is a reusable pattern for all transparent portals (windows, grates, archways)

**Ownership:**
- Flanders: Portal template `show_destination_on_look`, sheet `sheet-tied` mutation
- Moe: Portal prerequisite checking, courtyard description accessible via window look-through
- Sideshow Bob: Aware this is a mini-puzzle (discoverable + solvable)

---

### **Deep Cellar Staircase → Mausoleum (Canonical Progression)**

**Status:** Level 1 staircase already exists, needs to connect to mausoleum  

**Mechanics:**
- Player completes Level 1 underground puzzles in deep cellar
- Climbs staircase that ascends THROUGH the mausoleum floor
- Emerges in mausoleum (dramatic climax)
- Mausoleum becomes Level 2 starting room for canonical playthrough

**Implementation:**
- Deep cellar staircase (Level 1) has exit portal pointing to mausoleum
- Mausoleum room is the destination
- Portal is always-open (no prerequisites, no gate)
- Player can return to Level 1 via reverse portal (two-way travel)

**Ownership:**
- Moe: Mausoleum room design, portal connectivity
- Lisa: Portal TDD (#205, hallway staircase scope changed to upper floors, NOT Level 2)

---

### **Courtyard ↔ Garden (Transition Portal)**

**Status:** Design-time, needs implementation  

**Mechanics:**
- Portal object connects courtyard (interior transition) to first garden room
- Options: garden gate, archway, winding path, decorative doors
- Always-open, no prerequisites
- Thematic transition from formal courtyard → natural garden

**Design Choices (Moe to decide):**
- Single gate/archway or multi-room connection?
- Garden gate → main garden hub?
- Or winding path through intermediate zones?

**Ownership:** Moe (placement + portal design)

---

### **Garden Rooms ↔ Adjacent Garden Rooms (Internal Topology)**

**Status:** Design-time, Moe to define spatial relationships  

**Mechanics:**
- 6-10 garden rooms interconnected naturally
- Mausoleum is a visual/spatial anchor
- Hedge maze exits to moorland (Level 2→4 transition)
- Natural topology reflects real estate layout

**Ownership:** Moe (room connectivity, spatial relationships)

---

### **Gatehouse → Level 3 Village (Primary Exit)**

**Status:** Portal placeholder, destination (Level 3) TBD  

**Mechanics:**
- Gatehouse room has exit portal to Level 3
- Primary exit from Level 2
- Always-open, no prerequisites
- Marks transition from manor estate → village civilization

**Implementation:** Portal object in gatehouse (Moe/Flanders)  
**Ownership:** Moe (gatehouse room)

---

### **Mausoleum → Level 3 (Puzzle-Locked Gate)**

**Status:** Design-time, puzzle TBD  

**Mechanics:**
- Mausoleum room contains puzzle-locked descent/portal to Level 3
- Sideshow Bob designs the puzzle
- Puzzle gates access to Level 3 via mausoleum route
- Players may reach Level 3 via:
  1. Gatehouse (primary, direct)
  2. Mausoleum puzzle (alternative, hidden depth)

**Ownership:**
- Sideshow Bob: Puzzle design
- Flanders: Puzzle object(s)
- Moe: Portal placement in mausoleum

---

## 5. Window Viewport Mechanic (Reusable Pattern)

**Status:** 🟢 Ready to implement, no engine changes needed  

**Mechanic:**
- Players LOOK AT transparent portals (windows, grates, archways) → see destination room description
- Uses existing `on_look` handler on portal objects

**Pattern:**
- Portal template gains optional flag: `show_destination_on_look = true`
- When player examines portal with this flag, engine fetches destination room's description
- Fetches via `registry:get(portal.target)` → returns destination room table → displays room description

**Example:** Bedroom window portal
- Player: `look at window`
- Response: "Through the glass, you see the courtyard below. Paving stones, weathered walls, and—farther away—trees..."
- This is the courtyard room's description, rendered as a preview

**Design Intent:** Teaser mechanic — players preview Level 2 before solving the sheet puzzle. Builds anticipation.

**Applies To:**
- Windows ✓ (always transparent)
- Grates ✓ (metal lattice, see-through)
- Archways ✓ (open passages)
- DO NOT apply to: Doors (solid), gates (closed), walls (opaque)

**Implementation:**
- Flanders: Add `show_destination_on_look` flag to portal template
- Bart (possibly): Ensure `on_look` handlers can fetch destination room descriptions
- Moe: Use flag on transparent portals (window, courtyard archway, etc.)

**Ownership:**
- Flanders: Portal template flag
- Bart: Portal `on_look` pattern validation
- Moe: Apply flag to Level 2 transparent portals

---

## 6. Sheet-Rope Puzzle

**Status:** 🟢 Locked, ready for implementation  

**Mechanic:**
- Player finds bed sheet in Level 1 bedroom (already exists as object)
- Player returns to bedroom window
- Player ties/uses sheet at window → sheet enters `sheet-tied` state
- Window portal prerequisite checked: "sheet-tied" present?
- If yes: Player can `exit window` → Courtyard
- If no: "You can't climb down from here without something to hold onto."

**GOAP Prerequisite:**
- Verb: `exit window`
- Requires: `sheet-tied-to-window` (or equivalent state on sheet object)
- Action: Tie/use sheet at window location

**Design Implications:**
- Sheet object needs two states:
  1. `untied` (initial) — can be picked up, carried, used on bed
  2. `sheet-tied` (mutated) — tied to window, visually attached, blocks re-picking
- Player may untie sheet later (reversible state)
- OR sheet stays tied for entire Level 2 playthrough (permanent within that session)

**Implementation:**
- Flanders: Sheet object gains `sheet-tied` state + mutation path (`untied` → `sheet-tied`)
- Moe: Window portal checks for sheet-tied prerequisite
- Sideshow Bob: Note as mini-puzzle in puzzle spec

**Difficulty:** Simple (discovery-based, not logic-based)  
**Reward:** Early access to Level 2 courtyard + garden exploration

**Ownership:**
- Flanders: Sheet mutation + states
- Moe: Window portal prerequisites
- Sideshow Bob: Puzzle awareness

---

## 7. Lighting & Time-of-Day

**Status:** 🟢 Locked, system exists (game clock)  

**Mechanics:**
- Game starts at 2 AM (darkness)
- 1 real-world hour = 1 game day
- Daytime: 6 AM–6 PM (natural light)
- Nighttime: 6 PM–6 AM (darkness or moonlight)
- Level 2 (exterior) is FIRST level where natural light becomes relevant mechanically

**Implementation (existing):**
- Game clock already tracks time
- Light sources (candles, matches) provide artificial light
- Room descriptions should mention light conditions (dawn, daylight, dusk, nightfall)

**Design for Moe:**
- Room descriptions vary by time:
  - Daytime: "Bright sunlight illuminates the garden. You can see clearly."
  - Nighttime: "Darkness. You need a light source to see."
- Objects' `casts_light` properties are time-aware (optional, if implemented)
- Weather affects lighting (fog may dim even daytime)

**Ownership:**
- Moe: Room descriptions (time-aware text)
- Flanders: Object light-casting (existing system)
- Bart: Time system (already implemented)

---

## 8. Weather System (Mechanical)

**Status:** 🔲 Needs engine implementation (Bart)  

**Mechanical Effects:**

### Rain
- **Effect:** Extinguishes fire-based light sources (candles, matches)
- **Room text:** "Rain falls steadily. Your candle flickers and goes out."
- **Gameplay:** Players must find indoor shelter or alternative light
- **Implementation:** Triggered at random intervals or fixed schedule

### Wind
- **Effect:** Muffles sounds (affects `on_listen` descriptions)
- **Room text:** "The wind howls through the garden. Sounds are hard to hear."
- **Gameplay:** Sound-based creature warnings become unclear
- **Implementation:** Modifies sensory output, affects creature behavior narration

### Fog
- **Effect:** Limits visibility (affects visual range, `on_look` clarity)
- **Room text:** "Thick fog obscures the distant parts of the garden."
- **Gameplay:** Reduced lookahead descriptions, harder to navigate
- **Implementation:** Portal descriptions truncated or unclear in fog

**Design Approach:**
- Weather cycles naturally (morning clear, afternoon cloudy, evening rain)
- OR triggered by puzzles/events
- OR random for replayability

**Implementation (Bart owns):**
- New weather subsystem in `src/engine/`
- Accessible via `context.weather` (current weather state + effects)
- Applied to room descriptions + effects pipeline
- Mechanical, not cosmetic — changes gameplay

**Design for Moe:**
- Write weather-aware room descriptions (conditional text)
- Example: `if context.weather.raining then ... "rain falls" ... else ... "clear sky" ...`
- Coordinate with Bart on API surface

**Ownership:**
- Bart: Weather subsystem engine implementation
- Moe: Weather-aware room text + integration
- Flanders: Creature narration aware of wind effects

---

## 9. Creatures

**Status:** 🔲 Design TBD (Flanders + CBG)  

**Approved Mix:**
- **Natural creatures:** Appropriate to garden setting (owls, snakes, foxes, insects, birds, etc.)
- **One supernatural element:** Non-humanoid (ghost, phantom, ethereal being, etc.)
- **No Phase 5 humanoids:** Werewolves and NPCs deferred to Phase 5+

**Count:** 6-8 creature types (estimate, Flanders + CBG to define)

**Integration:**
- Creatures use Phase 5 behavior engine (stagger attacks, alpha by health, simplified pack tactics)
- Creatures behave naturally (wander, attack, flee, drop loot)
- Environmental behavior (respond to weather, time of day)

**Design Ownership:**
- Flanders: Creature object definitions (.lua files)
- CBG: Creature selection + narrative role
- Moe: Creature placement in rooms (spatial distribution)

---

## 10. Objects & Materials

**Status:** 🟡 Partial — Core objects identified, full spec TBD  

### New Objects (15-25 per Level 2 area)
- **Exterior furniture:** Benches, planters, fountains, gates
- **Garden structures:** Sheds, trellises, pergolas, sculptures
- **Natural items:** Plants, rocks, fallen branches
- **Interactive:** Keys, locks, puzzles, containers
- **Mausoleum:** Burial chambers, stonework, religious artifacts

**Ownership:** Flanders (object definitions) + Moe (placement)

### Existing Objects Repurposed
- **Sheet** (Level 1 bed sheet) → New state: `sheet-tied` (Flanders mutation)
- **Window** (Level 1 bedroom window) → Portal with `show_destination_on_look` + prerequisites (Flanders/Moe)
- **Candles/matches** → Light sources affected by weather (rain extinguishes)

### Materials
- **Standard palette:** Stone, iron, wood, tallow, wool, leather (existing)
- **No new material types** in MVP
- **Material interactions:** Existing system (rust, rot, wear, etc.)

**Ownership:** Flanders (object .lua), Moe (placement)

---

## 11. Puzzles & Interactions

**Status:** 🔲 Design TBD (Sideshow Bob)  

### Known Puzzles

1. **Sheet-rope puzzle** (bedroom window shortcut) — Simple, discoverable, mini-puzzle
2. **Mausoleum puzzle** (Level 3 gate) — Escalated complexity (Sideshow Bob designs)

### Design Constraints
- **Escalated difficulty** vs Level 1 endgame (multi-room dependencies)
- **Garden-themed mechanics** (natural elements, outdoor logic)
- **Creature interaction puzzles** (optional, narrative depth)

### Design Ownership
- Sideshow Bob: Full puzzle chain design
- Flanders: Puzzle object definitions (locks, keys, gates, etc.)
- Moe: Spatial layout supporting puzzle (room adjacency, visibility, traversal)

---

## 12. Open Questions for Moe (Design Time)

These decisions are IN SCOPE for Moe's design process:

1. **Exact Room Layout:** Which specific rooms constitute the 8-12? (greenhouse, stables, orchard, fountain area, etc.?)
2. **Room Adjacency:** How do garden rooms connect? Linear, hub-and-spoke, interconnected mesh?
3. **Mausoleum Placement:** Where in the garden? Central landmark? Hidden? Visible from other rooms?
4. **Courtyard Role:** Is courtyard Room 1 of Level 2, or a bridge between levels? Does player typically START in courtyard (shortcut path) or mausoleum (canonical path)?
5. **Gatehouse Location:** Where relative to garden rooms? At the edge? Central? Separate zone?
6. **Hedge Maze:** Is it a major puzzle or optional side-content? Leads to Level 2→4 transition (moorland).
7. **Garden Hub:** Is there a central garden room all others connect to, or organic topology?
8. **Portal Placement:** Where exactly are courtyard-to-garden portals? Single gate or multiple entrances?
9. **Visual Anchors:** What makes Level 2 feel distinct from Level 1? Mausoleum, garden aesthetic, lighting, weather?

**Recommendation:** Design in layers:
1. **Layer 1:** Sketch room map (boxes + labels) — 8-12 rooms, Mausoleum, Courtyard, Gatehouse
2. **Layer 2:** Draw connections (exits, portals) — Trace player journeys
3. **Layer 3:** Write room descriptions — Sensory detail, time/weather variants
4. **Layer 4:** Specify object placement — Where does Flanders put things?
5. **Layer 5:** Validate with CBG — Does flow make narrative sense?

---

## 13. Superseded Decisions (What Changed)

### ❌ SUPERSEDED: "Courtyard as Level 2 entry via staircase"
**Old:** Hallway staircase connects to Level 2 courtyard  
**New:** Hallway staircase connects to upper floors (attic, tower, servant quarters) — FUTURE level  
**Reason:** Architectural logic — manors don't access gardens via staircases. Courtyard is natural transition point.  
**Impact:** Issue #205 scope changed. Mausoleum is now Level 2 entry (via deep cellar).

### ❌ SUPERSEDED: "Level 2→4 via mausoleum puzzle gate"
**Old:** Mausoleum gate directly leads to Level 4 moorland  
**New:** Mausoleum gate leads to Level 3 Village. Separate L2→L4 path via hedge maze → moorland.  
**Reason:** Level 3 village is thematic interlude. Mausoleum becomes Level 2→3 primary gate. Hedge maze is alternative exit.

### ❌ SUPERSEDED: "Hedge maze is locked puzzle"
**Old:** Hedge maze exit requires puzzle unlock  
**New:** Hedge maze exit is always-open, leads to Level 2→4+ transition (moorland/wilderness)  
**Reason:** Simplifies Level 2 exit logic. Allows non-linear exploration without gating L4 access behind L3 completion.

---

## 14. Success Criteria (Moe's Gating)

### GATE-0: Vision + Layout Locked
- ✅ Design file created (this document)
- ⏳ Room map approved (8-12 rooms, connections, starting rooms)
- ⏳ CBG narrative flow validated

### GATE-1: Infrastructure Ready
- ✅ Level 1 T0 bugs fixed (Marge verified)
- ⏳ Portal TDD refactors complete (#203-208, Lisa signed off)
- ⏳ Weather subsystem API finalized (Bart + Moe)

### GATE-2: Design Assets Created
- ⏳ Room definitions (.lua files) in `src/meta/rooms/`
- ⏳ Level 2 definition (.lua file) in `src/meta/levels/`
- ⏳ Creature types implemented (Flanders)
- ⏳ Objects created + placed (Flanders + Moe)

### GATE-3: Integration + Testing
- ⏳ All rooms load + traverse correctly
- ⏳ Portals connect + work
- ⏳ Weather mechanics functional
- ⏳ 300+ total tests passing (no regression)

---

## 15. Deliverables Checklist (Moe's Responsibility)

- [ ] Room map (ASCII or visual) — 8-12 rooms + topology
- [ ] Room .lua files — `src/meta/rooms/level-2-*.lua` (one per room)
- [ ] Level 2 definition — `src/meta/levels/level-02.lua`
- [ ] Portal objects — Window, courtyard gate, mausoleum stairs, gatehouse, etc.
- [ ] Room descriptions — Sensory text for all lighting/weather states
- [ ] Object placement specs — "Nightstand has X, Y, Z" → Flanders implements
- [ ] Creature placement specs — "Garden room has owls, fox tracks" → Flanders places
- [ ] Test coverage — Room load tests, portal traversal tests, geography validation
- [ ] Integration with Board — Level 2 board.md updated with design decisions

---

## 16. Key Contacts & Ownership

| Role | Name | Responsibility |
|------|------|-----------------|
| **World Builder** | Moe | Room design, topology, placement, coordination |
| **Object Designer** | Flanders | Objects, mutations, creature instances |
| **Puzzle Master** | Sideshow Bob | Mausoleum puzzle, garden puzzle chains |
| **Game Designer** | CBG | Narrative flow, difficulty pacing, coherence |
| **Portal Engineer** | Lisa | Portal TDD #203-208, integration |
| **Architect** | Bart | Weather subsystem, engine integration |
| **Test Lead** | Nelson | Smoke tests, regression, Level 2 acceptance |
| **Documentation** | Brockman | Room docs, design patterns, update after delivery |

---

## 17. Timeline & Gates

**Phase 1: Design Lock** (Current)
- ✅ Design file created
- ⏳ Room map + topology finalized
- ⏳ CBG review + approval

**Phase 2: Infrastructure** (1 week)
- Portal TDD #203-208
- Weather subsystem API
- Level 1 T0 bug fixes
- **Gate:** All infrastructure ready

**Phase 3: Asset Creation** (2–3 weeks)
- Room .lua files
- Objects + creatures
- Puzzle implementation
- **Gate:** All assets load + integrate

**Phase 4: Integration + Testing** (1–2 weeks)
- End-to-end traversal
- Weather mechanics validation
- Full test suite
- **Gate:** 300+ tests passing

**Phase 5: Beta Polish** (1 week)
- Documentation
- LLM walkthrough
- Design review
- **Gate:** Ready for playtester feedback

**Estimate:** 6–9 weeks from design lock (GATE-0) to beta (GATE-4)

---

## Notes for Future Moe

This document is your **working reference** for Level 2 design. Refer to:

- `.squad/decisions.md` — Full locked decisions (D-LEVEL2-DESIGN-LOCK, D-LEVEL2-MAUSOLEUM-PORTAL, D-LEVEL2-COURTYARD-PORTAL, D-LEVEL-TOPOLOGY-MAP)
- `projects/level-2/board.md` — Project board, dependencies, gates
- `.squad/agents/moe/charter.md` — Your role definition
- `docs/architecture/objects/core-principles.md` — The 9 inviolable design principles
- `docs/architecture/rooms/` — Room architecture standards

**When designing rooms:**
1. Sketch topology first (boxes + labels)
2. Write descriptions (lit + dark sensory states)
3. Define exits + portals
4. Specify object placement ("nightstand contains X, Y, Z")
5. Validate with CBG (narrative + flow)
6. Create .lua files + tests
7. Lint before commit

Good luck! 🏗️

---

*Moe's working reference document. Treat as source of truth for Level 2 design.*
