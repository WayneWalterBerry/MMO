# Wyatt's World Project Board

**Project:** Wyatt's World — Mr. Beast Challenge Course  
**Owner:** Comic Book Guy (Creative Director)  
**Team:** Moe (Rooms), Sideshow Bob (Puzzles), Flanders (Objects)  
**Target Player:** Wyatt, age 10  
**Created:** 2026-03-27  
**Overall Status:** 🔄 In Progress (Phase 1–2 active)

## Constraints (HARD)

- **7 rooms** (no more, no less)
- **Reading level:** 3rd grade max
- **Puzzle difficulty:** 5th grade
- **Content:** Not scary, age-appropriate
- **Puzzle scope:** Single-room puzzles only (no multi-room chains)
- **Theme:** Semi-educational, Mr. Beast inspired

## Phase Overview

| Phase | Owner | Description | Status |
|-------|-------|-------------|--------|
| Research | Frink | Research Mr. Beast content, themes, characters | 🔄 In Progress |
| Design | Comic Book Guy | World concept, 7 room designs, puzzle philosophy | 🔄 In Progress |
| Room Building | Moe | Build 7 room .lua files | ⏳ Blocked on Design |
| Puzzle Design | Sideshow Bob | Design 7 single-room puzzles | ⏳ Blocked on Design |
| Object Building | Flanders | Build all objects for 7 rooms | ⏳ Blocked on Puzzles + Rooms |
| Testing | Nelson | Playtest all rooms and puzzles | ⏳ Blocked on Build |
| Review | CBG + Wayne | Creative review + Wayne plays with Wyatt | ⏳ Blocked on Testing |
| Deploy | Gil | Add world to web build | ⏳ Blocked on Review |

## Next Steps

1. **Frink:** Complete Mr. Beast research and share findings with CBG (theme recommendations, character archetypes, challenge mechanics)
2. **Comic Book Guy:** Complete world design document (7-room map, core challenge concept, puzzle philosophy)
3. **Design kickoff:** Share design doc with Moe, Bob, Flanders for implementation planning

## Key Decisions

- **Single world, new level file:** Will be a separate level (e.g., `level-wyatt.lua`)
- **New room directory:** Rooms isolated in `src/meta/worlds/wyatt-world/rooms/`
- **All new objects:** No reuse of existing (medieval) objects; all objects are Mr. Beast themed
- **Reading-level audit:** Wayne reviews ALL text (descriptions, messages, hints) for 3rd-grade appropriateness
- **Puzzle simplicity:** 7 puzzles, each solvable within a single room (no fetch chains)

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Reading level creep | Wayne does final text audit before testing phase |
| Overly complex puzzles | Bob designs for 5th grade; Nelson playtests; CBG verifies fun |
| Scope creep (>7 rooms) | CBG owns 7-room constraint in design doc |
| Timeline slip | Daily standup w/ CBG, Moe, Bob until Deploy complete |

## Success Criteria

- [x] Board created
- [ ] Research complete (Frink)
- [ ] Design doc approved (CBG + Wayne)
- [ ] 7 rooms built + tested (Moe + Nelson)
- [ ] 7 puzzles designed + solved (Bob + Nelson)
- [ ] All objects built (Flanders)
- [ ] Full playthrough tested (Nelson + Wayne)
- [ ] Wayne + Wyatt approval (Wayne)
- [ ] Deployed to web (Gil)

---

**Last Updated:** 2026-03-27 (Kirk)
