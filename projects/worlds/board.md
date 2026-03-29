# Worlds — Board

**Owner:** 🏗️ Bart (Architecture Lead) + 🏗️ Moe (World & Level Builder)
**Last Updated:** 2026-03-29
**Overall Status:** 📋 DESIGNED — Not yet implemented

---

## Next Steps

| Priority | Task | Owner | Status |
|----------|------|-------|--------|
| **P0** | Implement world loader (`src/engine/world/init.lua`) | Bart | ⏳ Not started |
| **P0** | Create `test/worlds/` directory + register in test runner | Nelson | ⏳ Not started |
| **P1** | Write world loader tests (discover, select, validate) | Nelson | ⏳ Not started |
| **P1** | Integrate boot sequence (`main.lua` reads world → level) | Bart | ⏳ Not started |
| **P2** | Architecture docs (`docs/architecture/engine/world-system.md`) | Brockman | ⏳ Not started |
| **P2** | LLM walkthrough (verify no gameplay regression) | Nelson | ⏳ Not started |

**Blocking question:** Should Worlds ship before or after Phase 5? It's independent work but touches `main.lua` boot sequence.

---

## Implementation Status

| Wave | Name | Status | Gate |
|------|------|--------|------|
| WAVE-0 | Pre-Flight (dirs + test runner) | ⏳ Pending | — |
| WAVE-1 | World Loader + Data | ⏳ Pending | GATE-1 |
| WAVE-2 | Boot Integration | ⏳ Pending | GATE-2 |
| WAVE-3 | Documentation + Verification | ⏳ Pending | GATE-3 |

---

## What Already Exists

| Artifact | Status |
|----------|--------|
| Design doc (`docs/design/worlds.md`, 496 lines) | ✅ Complete |
| World template (`src/meta/templates/world.lua`) | ✅ Exists |
| World 1 data (`src/meta/worlds/world-01.lua` — The Manor) | ✅ Exists |
| `src/meta/worlds/` directory | ✅ Exists |
| Decision: D-WORLDS-CONCEPT | ✅ Active |
| World loader engine module | ❌ Not started |
| Boot sequence integration | ❌ Not started |
| Tests | ❌ Not started |

---

## Concept: The Manor (World 1)

- **Theme:** Gothic domestic horror, medieval 1450s
- **Levels:** 3 (Level 1 bedroom start, Level 2 expansion in Phase 5, Level 3 future)
- **8-field theme system:** pitch, era, aesthetic, atmosphere, mood, tone, constraints, design_notes
- **Purpose:** Organizational hierarchy (World → Level → Room → Object) for 100+ levels

---

## Scope

**Phase 1 (this board):** World loader, boot integration, The Manor wired
**Phase 2+ (deferred):** Multi-world selection UI, rift mechanics, theme enforcement linting, difficulty modes

---

## Ownership

| Domain | Owner |
|--------|-------|
| World loader engine (`src/engine/world/`) | Bart |
| World template + data (`src/meta/worlds/`, `src/meta/templates/world.lua`) | Moe |
| Tests | Nelson |
| Docs | Brockman |

---

## Plan Files

| File | Purpose |
|------|---------|
| `projects/worlds/worlds-design.md` | Full design spec |
| `projects/worlds/worlds-implementation-phase1.md` | 4-wave implementation plan |

---

*Board maintained by Coordinator. Update after each wave.*
