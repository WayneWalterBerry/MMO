# Wyatt's World Project Board

**Project:** Wyatt's World — Mr. Beast Challenge Course  
**Owner:** Comic Book Guy (Creative Director)  
**Team:** Bart (Engine), Moe (Rooms), Flanders (Objects), Sideshow Bob (Puzzles), Smithers (Parser), Nelson (Testing), Gil (Web)  
**Target Player:** Wyatt, age 10  
**Created:** 2026-03-27  
**Updated:** 2026-03-29  
**Overall Status:** 🔄 In Progress — Implementation plan v2.1 complete (review fixes applied)  
**Plan:** `projects/wyatt-world/plan.md` (Bart v2.1)

## Constraints (HARD)

- **7 rooms** (no more, no less)
- **Reading level:** 3rd grade max
- **Puzzle difficulty:** 5th grade
- **Content:** Not scary, age-appropriate
- **Puzzle scope:** Single-room puzzles only (no multi-room chains)
- **Theme:** Semi-educational, Mr. Beast inspired
- **Rating:** E for Everyone — engine-enforced combat/harm verb blocking (D-RATING-TWO-LAYER)

## Wave Overview

| Wave | Owner(s) | Description | Gate | Status |
|------|----------|-------------|------|--------|
| Research | Frink | Mr. Beast content research | — | ✅ Complete |
| Design | CBG | World concept, 7 rooms, puzzle philosophy | — | ✅ Complete |
| **WAVE-0** | **Bart** | Multi-world engine loader (`--world` flag, content paths) | GATE-0 | ⏳ Ready |
| **WAVE-1a** | **Moe** | 7 room .lua files | GATE-1 | ⏳ Blocked on GATE-0 |
| **WAVE-1b** | **Flanders** | ~70 object .lua files + level file | GATE-1 | ⏳ Blocked on GATE-0 |
| **WAVE-1c** | **Bob** | 7 puzzle specs (.md) | GATE-1 | ⏳ Blocked on GATE-0 |
| **WAVE-1d** | **Nelson** | Test scaffolding (room/object/safety tests) | GATE-1 | ⏳ Blocked on GATE-0 |
| **WAVE-2a** | **Smithers** | Parser polish, embedding index, kid-friendly errors | GATE-2 | ⏳ Blocked on GATE-1 |
| **WAVE-2b** | **Nelson** | Puzzle walkthroughs, sensory coverage, reading-level scan | GATE-2 | ⏳ Blocked on GATE-1 |
| **WAVE-3a** | **CBG** | Creative review | GATE-3 | ⏳ Blocked on GATE-2 |
| **WAVE-3b** | **Wayne** | Reading-level text audit | GATE-3 | ⏳ Blocked on GATE-2 |
| **WAVE-3c** | **Gil** | Web world selector + deploy | GATE-3 | ✅ Complete |

## Next Steps

1. **Bart:** Execute WAVE-0 — multi-world engine loader
2. **GATE-0 pass:** Both worlds boot, Manor unchanged
3. **WAVE-1 kickoff:** Moe + Flanders + Bob + Nelson in parallel

## Key Decisions

- **Multi-world engine support in WAVE-0** — Wayne overruled Kirk's "no engine changes" (the engine errors on 2+ worlds)
- **`content_root` convention** — each world .lua specifies where its content lives. Manor uses legacy paths. Wyatt uses `worlds/wyatt-world/`
- **`--world <id>` CLI flag** — required for world selection with 2+ worlds
- **New room directory:** `src/meta/worlds/wyatt-world/rooms/`
- **All new objects:** No reuse of medieval objects; all Mr. Beast themed
- **Reading-level audit:** Wayne reviews ALL text for 3rd-grade appropriateness
- **Puzzle simplicity:** 7 puzzles, each solvable within a single room
- **Player-state scoreboard (LOCKED):** Track solved puzzles in `player.state.puzzles_completed` — confirmed approach
- **E-rating two-layer enforcement:** Engine hard-blocks combat/harm verbs; design soft-enforces no-poison/no-scary
- **GUID pre-assignment:** ~80 GUIDs reserved in `bart-wyatt-guids.md` before WAVE-1

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Main.lua refactoring breaks Manor | Full regression suite + headless Manor boot at GATE-0 |
| Reading level creep | Nelson automated scan (WAVE-2) + Wayne final audit (WAVE-3) |
| GUID collisions between worlds | GUID pre-assignment before WAVE-1 |
| Overly complex puzzles | Bob designs for 5th grade; Nelson LLM walkthroughs; CBG reviews |
| Scope creep (>7 rooms) | CBG owns 7-room constraint in design doc |

## Success Criteria

- [x] Board created
- [x] Research complete (Frink)
- [x] Design doc approved (CBG)
- [x] Implementation plan v2.0 (Bart)
- [x] Implementation plan v2.1 — review fixes (Bart)
- [x] GUID pre-assignment block (Bart)
- [ ] GATE-0: Multi-world engine boots both worlds (Bart)
- [ ] GATE-1: 7 rooms + ~70 objects + 7 puzzle specs (Moe/Flanders/Bob/Nelson)
- [ ] GATE-2: All puzzles solvable, safety audit pass (Smithers/Nelson)
- [ ] GATE-3: Creative + reading-level sign-off + web live (CBG/Wayne/Gil)
- [ ] Wayne + Wyatt play + approve

## Playable URLs

| World | URL |
|-------|-----|
| The Manor (default) | https://waynewalterberry.github.io/play/ |
| Wyatt's World | https://waynewalterberry.github.io/play/?world=wyatt-world |

---

**Last Updated:** 2026-03-29 (Gil — WAVE-3c web deploy)
