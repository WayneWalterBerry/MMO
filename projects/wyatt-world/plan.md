# Wyatt's World — Implementation Plan

## Overview

**Wyatt's World** is a new, standalone world designed for Wayne's 10-year-old nephew Wyatt. The project leverages the existing MMO engine (no engine changes needed) but introduces a complete new world with Mr. Beast–themed rooms, objects, and puzzles.

### Target Outcomes

- **7 rooms** with Mr. Beast challenge course aesthetics
- **Age 10 experience:** 3rd-grade reading, 5th-grade puzzle difficulty
- **Educational element:** STEM/strategy, not scary
- **Playable prototype:** Wayne + Wyatt can complete all rooms and puzzles

---

## Architecture

### File Organization

```
src/meta/worlds/wyatt-world/
├── rooms/
│   ├── start-room.lua          # Entry point
│   ├── room-2.lua
│   ├── room-3.lua
│   ├── room-4.lua
│   ├── room-5.lua
│   ├── room-6.lua
│   └── room-7.lua
├── objects/
│   ├── challenge-object-1.lua
│   ├── challenge-object-2.lua
│   └── ... (all Mr. Beast themed)
└── level-wyatt.lua             # Level definition (references all 7 rooms + objects)
```

### No Engine Changes

- Uses existing object system (Principle 0–9)
- Uses existing room template
- Uses existing verb handlers
- Uses existing parser pipeline
- **All behavior is object/room metadata** — no code mutations needed

### Objects Are New

All 74+ existing objects (candles, furniture, weapons, medieval artifacts) are **NOT imported**. Wyatt's World has:
- Challenge props (themed to Mr. Beast challenges)
- Tools/items (Mr. Beast branded)
- Containers (challenge boxes, chests, etc.)
- Decorative objects (themed to rooms)

---

## Constraints (Enforce These)

| Constraint | Owner | Enforcement |
|-----------|-------|------------|
| **3rd-grade reading level** | Wayne | Final text audit before Testing phase |
| **5th-grade puzzle difficulty** | Sideshow Bob | Nelson playtests with 5th-grade difficulty baseline |
| **Single-room puzzles only** | Bob | Each puzzle solvable without leaving room |
| **7 rooms exactly** | CBG | Design doc locks to 7; no exceptions |
| **Not scary** | Wayne + CBG | Content review before Testing |

---

## Implementation Phases

### Phase 1: Research (Frink) — 🔄 In Progress

**Goal:** Identify Mr. Beast thematic elements, character archetypes, and challenge mechanics.

**Deliverable:** 1-page research summary
- Key characters / roles
- Recurring challenge mechanics (TeamTree planting, charity, competition, innovation)
- Visual / atmospheric themes
- Age-appropriate adaptations

**Done When:** Summary shared with Comic Book Guy

---

### Phase 2: Design (Comic Book Guy) — 🔄 In Progress

**Goal:** Define the 7-room world map, core concept, and puzzle philosophy.

**Deliverable:** Design document including:
- World theme & narrative (why are we here? what's the challenge?)
- 7-room map (spatial layout, interconnections)
- Room descriptions (what's in each room? what makes it challenging?)
- 7 puzzle concepts (one per room, SINGLE-ROOM scope, 5th-grade difficulty)
- Core mechanics (what verbs are used? what objects drive challenge?)

**Done When:** Design doc reviewed + approved by Wayne

---

### Phase 3: Room Building (Moe) — ⏳ Blocked on Design

**Goal:** Implement 7 room .lua files in `src/meta/worlds/wyatt-world/rooms/`.

**Constraints:**
- Each room uses existing room template
- Deep-nesting syntax for spatial relationships
- Permanent features in `description`; movable objects in `instances`
- All room text: 3rd-grade reading level (reviewed by Wayne)

**Done When:** 7 rooms built, Nelson playtest walkthrough passes

---

### Phase 4: Puzzle Design (Sideshow Bob) — ⏳ Blocked on Design

**Goal:** Design 7 single-room puzzles, one per room.

**Constraints:**
- Each puzzle solvable within a single room
- Puzzle difficulty: 5th grade
- Use only objects available in that room
- No multi-room fetch chains

**Deliverable:** Puzzle design spec (7 puzzles)
- Puzzle name
- Room location
- Goal (what does the player need to do?)
- Solution path (how many steps? what verbs?)
- Objects involved
- Success message

**Done When:** Bob + Nelson verify all 7 puzzles are solvable with 5th-grade logic

---

### Phase 5: Object Building (Flanders) — ⏳ Blocked on Puzzles + Rooms

**Goal:** Implement all Mr. Beast–themed objects for 7 rooms.

**Constraints:**
- All objects use existing templates (small-item, furniture, container, etc.)
- Every object has `on_feel` (tactile description, primary dark sense)
- All sensory descriptions: 3rd-grade reading level
- Objects tagged with room/puzzle they belong to

**Deliverable:** 40+ object .lua files
- Challenge props (tokens, badges, containers)
- Tools (keys, tools, gadgets)
- Decorative objects (themed to rooms)
- Puzzle-critical objects (what the player needs to solve)

**Done When:** All objects built, tested for containment + sensory consistency

---

### Phase 6: Testing (Nelson) — ⏳ Blocked on Build

**Goal:** Full playtest of all 7 rooms + puzzles.

**Test Plan:**
- Walkthrough all 7 rooms, verify exits work
- Solve all 7 puzzles (Nelson runs scenarios)
- Verify all sensory descriptions work (look, feel, smell, listen, taste)
- Check for reading level violations (flag to Wayne)
- Verify no scary content (flag to Wayne)
- Regression test (ensure engine passes existing test suite)

**Done When:** Nelson + CBG sign off "Playable"

---

### Phase 7: Review (CBG + Wayne) — ⏳ Blocked on Testing

**Goal:** Creative sign-off + Wayne prepares for Wyatt playdate.

**Deliverables:**
- CBG: Creative review (tone, theme, fun factor)
- Wayne: Final text audit (3rd-grade appropriateness)
- Wayne: Prepare Wyatt introduction (how to play, what to expect)

**Done When:** Wayne + CBG approve "Ready for Wyatt"

---

### Phase 8: Deploy (Gil) — ⏳ Blocked on Review

**Goal:** Add Wyatt's World to web build + GitHub Pages.

**Deliverables:**
- Web build includes `level-wyatt.lua`
- Selector updated so Wyatt can start Wyatt's World
- GitHub Pages live

**Done When:** Web live, Wayne + Wyatt can play on browser

---

## Key Dependencies

```
Phase 2 Design ──┬──> Phase 3 Rooms
                 └──> Phase 4 Puzzles

Phase 3 + 4 ───> Phase 5 Objects ───> Phase 6 Testing ───> Phase 7 Review ───> Phase 8 Deploy
```

---

## Decisions Made

1. **Separate world directory** — `src/meta/worlds/wyatt-world/` keeps Wyatt's content isolated from other worlds
2. **New level file** — `level-wyatt.lua` loads only Wyatt's rooms and objects (no medieval clutter)
3. **No engine changes** — All behavior is object/room metadata; engine stays unchanged
4. **Age-gate: Wayne audits all text** — 3rd-grade reading level is non-negotiable; Wayne is final arbiter

---

## Success Criteria

- [x] Plan written
- [ ] Research complete (Frink)
- [ ] Design doc approved (CBG)
- [ ] 7 rooms built (Moe)
- [ ] 7 puzzles solved (Bob + Nelson)
- [ ] All objects built (Flanders)
- [ ] Full playtest pass (Nelson)
- [ ] CBG + Wayne review complete
- [ ] Deployed to web (Gil)
- [ ] Wayne + Wyatt play + approve

---

## Timeline

**Estimate:** 3–4 weeks (parallel work in Phases 3–5)

| Week | Phase | Owner(s) | Status |
|------|-------|---------|--------|
| 1 | Design + Research | CBG + Frink | In Progress |
| 2–3 | Rooms + Puzzles + Objects | Moe + Bob + Flanders | Parallel |
| 3 | Testing | Nelson | Post-build |
| 4 | Review + Deploy | CBG + Wayne + Gil | Final gate |

---

## References

- **Project board:** `projects/wyatt-world/board.md`
- **Core principles:** `docs/architecture/objects/core-principles.md`
- **Room pattern:** `docs/architecture/objects/deep-nesting-syntax.md`
- **Object design:** `docs/design/object-design-patterns.md`

---

**Plan Version:** 1.0  
**Last Updated:** 2026-03-27 (Kirk)
