# Sound Project Board

**Owner:** 🏗️ Bart (Architecture Lead) + ⚙️ Gil (Web Engineer)
**Last Updated:** 2026-07-31
**Overall Status:** 📋 PLAN v1.1 REVIEWED — Awaiting Wayne final review

---

## Next Steps (Prioritized)

| Priority | Task | Owner | Status |
|----------|------|-------|--------|
| **P0** | Full team review of implementation plan (per implementation-plan skill Pattern 5) | CBG, Marge, Chalmers, Flanders, Smithers, Moe | ✅ Complete — **Bart: ⚠️** (7 concerns), **CBG: ✅** (2 concerns), **Marge: ⚠️** (3 blockers, 5 concerns), **Chalmers: ⚠️** (3 blockers, 3 concerns), **Flanders: ⚠️** (3 blockers, 2 concerns), **Moe: ✅** (2 blockers, 2 concerns), **Smithers: ⚠️** (2 blockers, 3 concerns) |
| **P0a** | Consolidate all review findings → plan v1.1 | Bart (author) | ✅ Complete — 10 blockers + 11 concerns resolved. Plan v1.1 committed. |
| **P0b** | Wayne final review of v1.1 plan | Wayne | ⏳ Pending |
| **P0c** | Wayne final review (documentation gaps, missing deliverables) | Wayne | ⏳ Blocked by P0b (merged into P0b flow) |
| **P1** | **WAVE-0** — Sound manager module + platform drivers | Bart, Gil, Nelson | ⏳ Blocked by P0b |
| **P2** | **WAVE-1** — Object metadata + room ambients + asset sourcing | Flanders, Moe, CBG, Nelson | ⏳ Pending |
| **P3** | **WAVE-2** — Event integration + engine hooks | Bart, Smithers, Nelson | ⏳ Pending |
| **P4** | **WAVE-3** — Build pipeline + deploy + documentation | Gil, Nelson, Brockman | ⏳ Pending |

---

## Overall Status

**🟡 REVIEW RESOLVED — Plan v1.1 committed. 10 blockers + 11 concerns from 7-agent review addressed. Awaiting Wayne's final review (P0b).**

---

## What Already Exists

| Document | Status | Key Content |
|----------|--------|------------|
| **sound-design-notes.md** (CBG) | ✅ Complete | Game design philosophy, 3-tier priority system (24 MVP sounds), accessibility-first principles, per-object sound audit |
| **sound-implementation-plan.md** (Bart) | ✅ Complete | 4-wave roadmap, team assignments, dependency graph, API specs, risk register |
| **sound-web-pipeline-notes.md** (Gil) | ✅ Complete | Web Audio API integration, OGG Opus compression strategy (@48kbps), lazy loading, Fengari bridge design, deploy pipeline |

---

## Execution Status

### Wave Tracker

| Wave | Phase | Parallel Tracks | Gate Criteria | Status |
|------|-------|-----------------|---------------|--------|
| **WAVE-0** | Infrastructure | 3 | Sound manager loads, no-op works, web bridge connects, zero regressions | ⏳ Pending |
| **WAVE-1** | Metadata + Assets | 4 | 15+ objects/creatures have sounds tables, 7 rooms declare ambients, 24 files sourced + compressed | ⏳ Pending |
| **WAVE-2** | Engine Integration | 3 | FSM/verb/mutation hooks wired, combat dispatch working, integration tests pass | ⏳ Pending |
| **WAVE-3** | Deploy + Polish | 3 | Build pipeline works, sounds deploy to web, LLM walkthroughs pass, docs shipped | ⏳ Pending |

---

## Ownership Map

| Owner | Domain | Wave(s) |
|-------|--------|---------|
| **Bart** | Engine sound module (`src/engine/sound/`), FSM/verb/mutation hooks | 0, 2 |
| **Gil** | Web Audio bridge (bootstrapper.js, game-adapter.lua), build pipeline | 0, 3 |
| **Flanders** | Object/creature sound metadata (`sounds` tables) | 1 |
| **Moe** | Room ambient declarations | 1 |
| **CBG** | Sound design review, asset sourcing guidance | 1 |
| **Smithers** | Verb handler narration integration | 2 |
| **Nelson** | Test scaffolding (all waves), LLM walkthroughs, integration tests | 0, 1, 2, 3 |
| **Brockman** | Architecture + design documentation | 3 |

---

## Scope — Phase 1 (This Board)

**MVP Target:** 24 sounds, OGG Opus @ 48 kbps mono, ~230 KB total.

### Sound Categories (All Tier 1 + Tier 2)

| Category | Count | Examples |
|----------|-------|----------|
| Creature vocalizations | 8 | Rat, cat, wolf, bat, spider — per-state sounds |
| Door/passage transitions | 5 | Creak, lock click, gate clang, trapdoor, lock unlock |
| Fire/light ignition | 3 | Match strike, candle ignite, torch crackle |
| Combat impacts | 2 | Blunt hit, slash hit |
| Ambient loops (rooms) | 6 | Bedroom silence, hallway torches, cellar drip, storage scratch, deep cellar void, crypt void |

**Total: ~24 files, ~230 KB compressed.**

### Phase 1 Deliverables

- ✅ Engine sound manager (`src/engine/sound/init.lua` + drivers)
- ✅ Web Audio bridge (bootstrapper.js + game-adapter.lua)
- ✅ Object sound metadata (`sounds` tables)
- ✅ Room ambient declarations
- ✅ 24 MVP sound files sourced, compressed to Opus
- ✅ Event integration hooks (FSM, verbs, mutations, room transitions)
- ✅ Build pipeline + deploy integration
- ✅ Documentation + LLM walkthroughs

### Phase 2+ (Deferred)

- Vorbis fallback (legacy Safari support)
- Time-of-day ambient variation
- LRU cache for sound buffers (if count >50)
- Advanced mixer UI (per-category volume controls)

---

## Key Design Decisions

1. **Text is canonical, sound is additive.** Every sound event has a text equivalent. Zero gameplay information exclusive to audio. Game fully playable on mute.

2. **Accessibility first.** Deaf players miss nothing. Screen reader compatible. Master volume + toggles for effects, ambients, creatures, text-only mode.

3. **Lazy loading.** Sounds load when their object/room loads — no bulk preload. Room transitions queue sounds in background (~30–80 KB per room).

4. **Pre-compressed.** OGG Opus @ 48 kbps (not MP3, not WAV). Browser's `decodeAudioData()` handles decompression natively. ~60% smaller than Vorbis.

5. **Platform abstraction.** Platform-agnostic Lua sound manager with swappable drivers: Web Audio (Fengari bridge), terminal (os.execute), no-op (headless).

6. **Autoplay policy:** First keypress unlocks AudioContext (browser policy). Game requires typing anyway — no "click to enable" banner needed.

7. **Fire-and-forget integration.** Sound is wrapped in `pcall()` everywhere. Sound failure never crashes the game.

8. **Dead = silence.** Creatures that die produce NO death sound. Absence of sound is the signal. Hunting cat in silence = intentional tension.

---

## Plan Files

- [sound-design-notes.md](./sound-design-notes.md) — Game design perspective, priority tiers, sound audit per object
- [sound-implementation-plan.md](./sound-implementation-plan.md) — Full 4-wave roadmap, API specs, dependencies, risk register
- [sound-web-pipeline-notes.md](./sound-web-pipeline-notes.md) — Web Audio architecture, compression, lazy load, Fengari bridge, deploy pipeline

---

## Success Criteria (Gate Definitions)

### GATE-0: Infrastructure Ready
- Sound manager loads without errors
- No-op mode runs silently during tests
- Web bridge (6 JS functions) exposed
- Lua bridge calls JS via pcall without crash
- Headless mode: ctx.sound_manager is nil (zero overhead)
- Mock driver tests pass
- Zero regressions

### GATE-1: Metadata + Assets Ready
- 15+ objects/creatures have `sounds` tables (correct prefixes: `on_state_*`, `ambient_*`, `on_verb_*`, `on_mutate`)
- 7 rooms declare ambient sounds
- 24 sound files sourced + compressed to Opus + stored in `assets/sounds/`
- Metadata validation tests pass
- Zero regressions

### GATE-2: Event Integration Complete
- FSM transition → sound triggers (mock driver records)
- Verb on object → correct sound triggered
- Verb fallback → default sound triggered
- Room entry/exit → ambient starts/stops
- Mutation → old sounds stop, new object scanned
- Combat hit → impact sound fires
- Headless mode: zero sound calls
- Integration tests pass
- Zero regressions

### GATE-3: Deployment Ready
- `build-sounds.ps1` validates + copies to `web/dist/sounds/`
- Sounds deploy alongside engine + meta
- LLM headless walkthroughs pass (5 scenarios)
- Architecture + design docs shipped
- Object design patterns updated with `sounds` table
- Full test suite passes
- Zero regressions

---

## Team Charter Reminders

- **Bart** (Architect): Engine design, module boundaries, system composition. Owns `src/engine/sound/`.
- **Gil** (Web Engineer): Build pipeline, browser integration, deployment. Owns `web/build-sounds.ps1` + Web Audio layer.
- **Flanders** (Content Lead): Object definitions. Adds `sounds` tables to 15+ objects/creatures.
- **Moe** (Room Designer): Room definitions. Adds ambient sound declarations to 7 rooms.
- **CBG** (Game Designer): Sound philosophy, priority tiers, asset sourcing direction.
- **Smithers** (Parser/UI): Verb system, text presentation. Verifies sound + text coexist cleanly.
- **Nelson** (QA Lead): Test scaffolding, integration tests, LLM walkthroughs, regression prevention.
- **Brockman** (Documentarian): Architecture docs, design docs, design patterns update.

---

## Timeline Estimate

| Wave | Estimated Hours | Critical Path |
|------|-----------------|----------------|
| WAVE-0 | 8–10 (Bart: 3, Gil: 5, Nelson: 2) | Bart's sound module blocks Gil's bridge |
| WAVE-1 | 6–8 (Flanders: 2, Moe: 1, CBG: 2, Nelson: 2) | Asset sourcing by CBG |
| WAVE-2 | 6–8 (Bart: 2, Smithers: 1, Nelson: 3) | Bart's engine hooks block integration tests |
| WAVE-3 | 4–5 (Gil: 2, Nelson: 2, Brockman: 1) | Docs can run in parallel |
| **Total** | **24–31 hours** | |

**Recommendation:** WAVE-2 Track 2A (Bart: engine hooks) can start after GATE-0 in parallel with WAVE-1 — hooks are structural and don't need sound files. WAVE-2 Tracks 2B + 2C wait for GATE-1. Asset sourcing (1B) can also start immediately after GATE-0.

---

## Risk Register (Abbreviated)

| Risk | Likelihood | Mitigation |
|------|------------|-----------|
| Browser autoplay policy | Low | First keypress unlocks; game requires typing anyway |
| Sound files too large for mobile | Low | 48 kbps Opus; lazy load; ~230 KB total MVP |
| Web Audio not supported (rare old browser) | Very Low | Silent no-op; game works; text output unaffected |
| Sounds cut off during combat | Low | Max 3 concurrent; ambient ducked; priority slots |
| Memory pressure (50+ sounds) | Very Low | Phase 2 LRU cache; MVP stays ~900 KB decoded |

---

**Board Last Updated:** 2026-07-31 (Bart, Architect)  
**For questions:** See `.squad/agents/bart/charter.md` or `.squad/decisions.md`
