# Level 2 — Board

**Owner:** 📊 Kirk (PM coordination) + 🎮 CBG (Game Design lead) + 🏗️ Moe (World Building lead)  
**Last Updated:** 2026-03-30  
**Overall Status:** 🟡 Planning

---

## Next Steps (Prioritized)

| Priority | Task | Owner | Status | Directive Source |
|----------|------|-------|--------|---------|
| **P0** | **LOCKED: Moe to detail room topology** — Implement Level 2 room map per Wayne's directives: Mausoleum (start) → 8–12 garden rooms → Gatehouse (exit). Coordinate courtyard placement, weather integration, window portal prerequisites. | Moe | ⏳ Pending | Wayne design lock |
| **P0** | **LOCKED: CBG to document Level 2 vision** — Confirm difficulty curve (slightly harder than L1), creature mix (natural + one supernatural), puzzle escalation vs Level 1. Update vision doc with weather mechanics, game-time lighting, and two-way travel design. | CBG | ⏳ Pending | Wayne design lock |
| **P1** | **Window mechanic implementation** — Flanders: Add `sheet-tied` mutation to sheet object. Moe: Implement `show_destination_on_look` for window portals. Bart: Formalize `on_look` pattern in portal template. | Flanders, Moe, Bart | ⏳ Pending | Copilot decision: window-look-through + sheet-puzzle |
| **P1** | **Creature design lock** — Flanders to spec natural creatures + one supernatural element. Coordinate with Moe on creature distributions in garden area. | Flanders | ⏳ Pending | Wayne scope lock |
| **P2** | Infrastructure gate: Ensure Level 1 stability (T0 bugs fixed, 257 tests green) | Marge + Nelson | 📋 In Progress | GATE-1 (zero regressions) |

---

## Overall Status

🟢 **Design LOCKED** — Wayne's design directives finalized 2026-03-29. Scope, topology, portal mechanics, weather, and creature mix all confirmed. Moe now works from concrete specifications. CBG and Flanders have clear targets. Ready to move rapidly to GATE-0 (topology detail + vision doc) and then infrastructure validation (GATE-1).

---

## Scope — What Level 2 Includes (LOCKED per Wayne's Decisions)

### Theme & Setting
- **Exterior setting:** Garden & grounds surrounding a manor estate
- **Freestanding structures:** Mausoleum (Level 2 start), greenhouse, stables, gatehouse, hedge maze (no hedge maze exit)
- **Environment:** Natural outdoor threats (weather, creatures) + one supernatural element
- **Room count:** 8–12 rooms (confirmed)
- **Lighting:** Game-time dependent — player navigates with dynamic day/night cycle using existing game clock

### Topography (LOCKED)
**Vertical sequence:**
1. Level 1 Room 7 → Staircase UP → **Mausoleum** (Level 2 entry)
2. Mausoleum → **Garden & grounds** (8–12 rooms of exploration)
3. **Gatehouse** → Level 3 (Village)

**Shortcuts:**
- Level 1 bedroom window (via sheet puzzle) → Courtyard (Level 2)
- Courtyard: Hub connecting manor and garden (placement TBD by Moe)

### Weather System (Mechanical)
- **Rain:** Extinguishes fire-based light sources
- **Wind:** Muffles sounds (affects `on_listen` descriptions)
- **Fog:** Limits visibility (affects visual range, `on_look` clarity)
- All weather mechanics integrated into room descriptions and object effects

### Creature Mix
- **Natural creatures:** Appropriate to garden setting (as designed by Flanders)
- **One supernatural element:** TBD by Flanders (examples: ghost, phantom, other non-humanoid entity)
- **No Phase 5 humanoids in Level 2** (werewolves, NPCs deferred to Phase 5+)

### Portal System — Window Mechanics
- **Window look-through:** Player can LOOK at bedroom window, see Level 2 courtyard (teaser mechanic)
- **Window traversal:** Requires sheet-as-rope puzzle to unlock
  - Sheet must be tied/attached to window before exit allowed
  - Player discovers sheet, returns to window, solves simple puzzle, gains shortcut
  - GOAP prerequisite: `exit window requires sheet-tied`

### Puzzle Chains
- **Sheet + window puzzle:** Simple, discoverable, unlocks shortcut
- **Garden area puzzles:** Escalated complexity vs Level 1, multi-room dependencies (Sideshow Bob to design)
- **Creature interactions:** Puzzle elements involving natural + supernatural creatures

### New Objects + Materials
- **Objects:** ~15–25 new objects per Level 2 area (Flanders)
- **Existing objects repurposed:** Sheet (Level 1 bed sheet with `sheet-tied` mutation), window (existing portal mechanics)
- **Materials:** Standard (stone, iron, wood, tallow, wool, leather) — no new material types in MVP
- **Mutations:** Sheet gains `sheet-tied` state variant (Flanders action item)

### Portal System Integration (LOCKED)
- **Level 1 → Level 2 boundary:** Room 7 staircase → Mausoleum (portal TDD #205)
- **Two-way travel:** Player can return to Level 1 via staircase (no one-way trap)
- **Portal unification:** All portals follow unified system per #203-208
- **No multiplayer in MVP:** Single-player only

---

## Dependencies

### Must Complete Before Level 2 Starts

| Dependency | Current Status | Owner | Impact |
|------------|---|---|---|
| **Level 1 Stability (T0 bugs fixed)** | 🟢 In progress (#406, #315) | Moe, Lisa | Cannot ship beta with broken Level 1 |
| **Portal TDD Refactors (#203-208)** | 🟡 Pending (Wave 2 ready) | Lisa, Moe | Hallway-level2 staircase needs unified portal system |
| **Creature behavior engine (Phase 5)** | 📋 Planned | Bart | Level 2 creatures use Phase 5 behavior system |
| **World system (WAVE-2 boot integration)** | 📋 Pending (Bart + Moe) | Bart, Moe | Level 2 defined as world-01 level-02 (or new world) |

### Non-Blocking (Can Parallel)

| Item | Owner | Timeline |
|------|-------|----------|
| Sound system integration | Bart + Gil | WAVE-0-3 (phases 2026-08+) |
| NPC combat Phase 5 (advanced) | Bart | After creature basics |
| Clothing/wardrobe system | CBG + Flanders | Phase 6 (deferred) |

---

## Wayne's Design Directives (LOCKED)

**By:** Wayne "Effe" Berry  
**Decided:** 2026-03-29  
**Status:** 🔒 FINAL — All team members bound by these decisions

### Theme & Scope
- **Setting:** Garden & grounds (exterior, greenhouse, hedge maze, stables possible)
- **Room count:** 8–12 rooms (vs Level 1's 7)
- **Difficulty:** Slightly harder than Level 1 endgame (escalated puzzle complexity, mix of natural + one supernatural creature element)
- **Creatures:** Mix of natural + one supernatural element (no Phase 5 humanoid NPCs in Level 2 — those deferred to Phase 5+)
- **Lighting:** Game-time dependent — if 2 AM it's dark, noon it's daylight (uses game clock)
- **Weather:** Mechanical and ACTIVE
  - Rain extinguishes fire
  - Wind muffles sounds
  - Fog limits visibility
- **Two-way travel:** Full connection to Level 1 (player can return via staircase)

### Level Topology (SUPERSEDES all prior versions)

**Vertical Axis:**
- Level 1 Room 7 → staircase UP → Mausoleum (Level 2 START)
- Mausoleum: Freestanding structure in the garden where player emerges from Level 1
- Garden & grounds: 8–12 rooms of exterior exploration
- Gatehouse: At estate boundary → Level 3 (Village)

**NO hedge maze exit, NO moorland, NO Level 4 gate in Level 2**

### Portal Mechanics & Shortcuts

**Bedroom Window Shortcut (complex puzzle gate):**
- Bedroom window in Level 1 → Courtyard (Level 2)
- Requires SHEET (already exists in Level 1 as bed sheet) as makeshift rope
- Player must LEAVE/TIE/USE sheet at window before traversal allowed
- GOAP prerequisite: `exit window` requires `sheet attached to window`
- Flanders action: Mutate sheet to `sheet-tied` state (or equivalent)
- Sideshow Bob action: Acknowledge this as mini-puzzle in puzzle spec
- Moe action: Window portal checks for sheet prerequisite before allowing exit

**Window Look-Through Viewport (reusable mechanic):**
- Players can LOOK AT bedroom window and see Level 2 courtyard description
- Uses existing portal `on_look` mechanic — no engine changes
- Pattern: Any transparent portal (windows, grates, archways) can optionally show destination room description
- Template flag: `show_destination_on_look = true` for opt-in behavior
- Design intent: "I can see it but can't reach it yet" teaser design — builds anticipation before puzzle unlock
- Applies to: Windows, grates, archways with line-of-sight (NOT doors or solid portals)

**Courtyard Placement:**
- Courtyard is connective tissue between manor and garden
- Part of Level 2 or directly connected to garden (Moe to place in topology)
- Accessible via: Level 1 bedroom window shortcut (puzzle-gated) OR by exploring garden normally

### Key Structures

- **Mausoleum:** Level 2 arrival point (from Level 1) — NOT a Level 3 gate
- **Gatehouse:** Level 2 exit to Level 3 (Village) — primary exit from Level 2
- **Courtyard:** Hub connective to manor and garden

---

## Design Directive Assignments (for Moe)

| Directive | Owner | Action | Gate |
|-----------|-------|--------|------|
| Topology lock (8–12 rooms, mausoleum start, gatehouse exit) | Moe | Design room map per LOCKED topology | GATE-0 |
| Weather mechanics (rain, wind, fog) | Moe (coordinates with Bart for FX) | Integrate weather into room descriptions + effects | GATE-2 |
| Game-time lighting | Moe (coordinates with Bart for time system) | Light objects respond to game clock (2 AM dark, noon bright) | GATE-2 |
| Courtyard placement | Moe | Decide: isolated room or garden hub? Map connections | GATE-0 |
| Window portal prerequisites | Moe (with Flanders) | Window checks for sheet tie before allowing exit | GATE-2 |
| Bedroom window look-through | Moe | Implement `show_destination_on_look = true` on window portal | GATE-1 |

---

## ✅ Resolved Questions

✅ **Theme:** Garden & grounds exterior (locked)  
✅ **Rooms:** 8–12 rooms (locked)  
✅ **Difficulty:** Slightly harder than Level 1 (locked)  
✅ **Creatures:** Natural + one supernatural element (locked)  
✅ **Lighting/Weather:** Mechanical, game-time dependent (locked)  
✅ **Topology:** Mausoleum → garden → gatehouse (locked)  
✅ **Shortcuts:** Window + sheet puzzle to courtyard (locked)  
✅ **Boundary:** Staircase up from Level 1 Room 7 (locked)

---

## Success Criteria (Gating)

### GATE-0: Vision + Layout Locked
- ✅ CBG vision document approved (themes, difficulty, mechanics, 2–3 page narrative)
- ✅ Moe room map approved (room count, connections, descriptions, starting_room)
- ✅ Wayne sign-off on scope (no scope creep mid-design)

### GATE-1: Infrastructure Ready
- ✅ Level 1 T0 bugs fixed + 257 tests green (Marge verified)
- ✅ Portal TDD refactors complete (#203-208, Lisa + Moe signed off)
- ✅ World system WAVE-2 boot integration complete (Bart + Moe)
- ✅ Flanders creature design spec ready (new creature types + behaviors)

### GATE-2: Design Assets Created
- ✅ Creature types implemented + tested (Flanders)
- ✅ Room definitions + topology (Moe)
- ✅ Puzzle chains designed (Sideshow Bob)
- ✅ Objects created + integrated (Flanders, Moe)

### GATE-3: Integration Complete
- ✅ All Level 2 objects, creatures, rooms load + play
- ✅ Portal (hallway → level-2) connects + works
- ✅ Puzzle chains playable end-to-end
- ✅ 300+ total tests passing (no regression)

### GATE-4: Beta Ready
- ✅ Sound ambients + creature sounds (if Phase 2+ prioritized)
- ✅ LLM walkthrough (Nelson) — full Level 2 playthrough
- ✅ Documentation updated (Brockman)
- ✅ Ready for beta playtester feedback

---

## Roadmap — Estimated Timeline

**Phase Breakdown (subject to GATE-0 approval):**

| Phase | Weeks | Owner(s) | Gate | Notes |
|-------|-------|----------|------|-------|
| **Vision + Design** | 1–2 | CBG, Moe, Kirk | GATE-0 | Design docs locked, no code work |
| **Infrastructure Ready** | 1 | Lisa, Bart, Moe, Nelson | GATE-1 | Portal TDD, world boot, L1 stability |
| **Asset Creation** | 2–3 | Flanders, Moe, Sideshow Bob | GATE-2 | Creatures, rooms, objects, puzzles |
| **Integration + Testing** | 1–2 | All | GATE-3 | Full suite pass, regression check |
| **Beta Polish** | 1 | Gil, Brockman, Nelson | GATE-4 | Docs, sounds (if prioritized), LLM walkthrough |

**Total Estimate:** 6–9 weeks (after GATE-0 lock)

---

## Ownership & Charter Alignment

| Role | Owner | Responsibility | Charter |
|------|-------|---|---|
| **PM Coordination** | Kirk | Cross-project scheduling, blocker escalation | Project Manager |
| **Game Design Lead** | CBG | Theme, difficulty curve, mechanics | Game Designer |
| **World Building Lead** | Moe | Room layout, topology, world data | World & Level Builder |
| **Creature Design** | Flanders | New creature types, behaviors, objects | Content Lead |
| **Puzzle Design** | Sideshow Bob | Puzzle chains, multi-room mechanics | Puzzle Designer |
| **Portal Implementation** | Lisa | #205 hallway-level2 staircase TDD | Portal System (assigned in #203-208) |
| **Infrastructure (world system)** | Bart | World WAVE-2 boot integration | Architecture Lead |
| **Infrastructure (portal system)** | Moe + Lisa | #203-208 portal TDD refactors | World Building / Portal System |
| **QA & Regression** | Marge + Nelson | 300+ test pass gate, LLM walkthrough | Test & QA Lead |
| **Documentation** | Brockman | Architecture docs, design patterns update | Documentation Lead |

---

## Priority in Project Portfolio

**Tier:** 🟡 Background (Future work, after T0-T4)

Per `projects/priorities.md`:
- **T0:** Testing (steady state)
- **T1:** Worlds (design ready, pre-WAVE-1)
- **T2:** Sound (design complete, team review pending)
- **T3:** Food (90% done)
- **T4:** NPC Combat (Phase 5 plan reviewed)
- **Background:** Level 2, Parser Improvements

**Why background?** Level 1 must be stable + portal system unified before Level 2 design locks. Expected to move to T0-T1 after Phase 5 / portal TDD completion (~3-4 weeks).

---

## Key Decisions Affecting This Project

| ID | Decision | Status | Impact on Level 2 |
|----|----------|--------|---|
| **D-14** | Code mutation is state change | 🟢 Active | Level 2 object state changes via mutation |
| **D-INANIMATE** | Objects are inanimate (no NPCs yet) | 🟢 Active | Level 2 creatures (Phase 5) separate from objects |
| **D-WORLDS-CONCEPT** | Worlds are top-level containers | 🟢 Active | Level 2 is world-01 level-02 (or new world) |
| **D-WAYNE-PHASE5-DECISIONS** | Phase 5 scope: werewolf NPC, salt preservation, simplified pack tactics | 🟢 Active | Level 2 creatures use Phase 5 behavior engine |
| **D-DEPLOY-ON-MERGE** | Deploy-on-merge to GitHub Pages | 🟢 Active | Level 2 ships on main branch merge |

---

## Plan Files

| File | Purpose |
|------|---------|
| `projects/level-2/board.md` | This board — roadmap, dependencies, gating |
| (Future) `projects/level-2/vision.md` | CBG design vision (themes, difficulty, mechanics) |
| (Future) `projects/level-2/world-layout.md` | Moe's room topology + connections |
| (Future) `projects/level-2/creature-spec.md` | Flanders creature types + behaviors |
| (Future) `projects/level-2/puzzle-chains.md` | Sideshow Bob puzzle design |

---

*Board created by Kirk (Project Manager). Update after each gate completion.*
