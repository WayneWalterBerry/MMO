# Daily Plan — 2026-03-22

**Owner:** Wayne "Effe" Berry
**Focus:** Search/find bug fixes, regression testing, Prime Directive foundation

---

## Currently Running

| Agent | Task | Status |
|-------|------|--------|
| ⚛️ Smithers (P0) | Fix 5 hangs + scoped search + articles + adverbs + sweep keywords + doubled articles (BUG-078–088) | 🔄 Running |
| ⚛️ Smithers (P1) | Fix spent match priority, match counter, drawer scope bleed, "hunt" synonym (BUG-089–092) | 🔄 Running |
| 🧪 Nelson | Write regression unit tests from Pass 025/026 findings | 🔄 Running |

---

## Completed Today

- [x] ⚛️ Smithers — Deployed BUG-073-077 fixes + Prime Directive quick wins (politeness, adverbs, questions, error messages)
- [x] 🏗️ Bart — Prime Directive roadmap (`docs/architecture/engine/parser/prime-directive-roadmap.md`, 917 lines, 6 tiers)
- [x] 🏗️ Bart — Parser strategy doc (`docs/architecture/engine/parser/parser-strategy.md` — buzzword analysis, pipeline architecture)
- [x] 🧪 Nelson — Pass 025 (search/find creative phrasing, 31 tests) + Pass 026 (nightstand regression, 13 tests)
- [x] Pipeline refactor added to PD roadmap section 6 (extensible interpretation pipeline)
- [x] Test passes reorganized (26 files → correct `gameplay/` subfolder, `YYYY-MM-DD-pass-NNN.md` naming)
- [x] Nelson charter updated — references README.md in any directory before writing files
- [x] LLM play testing extracted to skill (`.squad/skills/llm-play-testing/SKILL.md`)
- [x] Bug report lifecycle skill updated — mandatory regression unit tests before closing issues

---

## Pipeline — After Current Agents Complete

### Phase 1: Verify Fixes
- [ ] Run all unit tests (existing 302+ plus Nelson's new ones)
- [ ] Verify Smithers' fixes didn't break anything
- [ ] Merge Nelson's tests with Smithers' fixes — all should pass

### Phase 2: Retest
- [ ] Nelson Pass 027 — retest BUG-078–092 after fixes
- [ ] Fix anything Nelson finds (second fix cycle if needed)

### Phase 3: Nightstand Regression
- [ ] Nelson focused nightstand chain test (feel → open → find → take → light → see room)
- [ ] Verify `light candle` works end-to-end (BUG-090 was release blocker)
- [ ] Write nightstand-specific unit tests

### Phase 4: Deploy
- [ ] Run `deploy.ps1` to push fixes live
- [ ] Verify live site at waynewalterberry.github.io/play/

---

## Backlog (Not Today Unless Time Permits)

### Pending Todos
- [ ] `container-sensory-gating` — Engine checks open/closed before revealing contents
- [ ] `chest-object` — Create chest.lua + GUID + docs (two-handed carry)

### Prime Directive Roadmap
- [ ] **Prerequisite:** Refactor `preprocess.lua` into extensible table-driven pipeline
- [ ] Tier 0: Politeness/adverb stripping (partially done by Smithers)
- [ ] Tier 1: Question transforms (partially done)
- [ ] Tier 2: Error message overhaul (partially done)
- [ ] Tier 3: Idiom library ("set fire to X" → "light X")
- [ ] Tier 4: Context window (discovery memory)
- [ ] Tier 5: Fuzzy noun resolution ("the wooden thing")

### Other
- [ ] Combat precursor: stab/cut/slash deeper testing
- [ ] Treatment objects: salve, nightshade antidote
- [ ] Wine FSM (BUG-061 still broken)
- [ ] Scribe: merge ~15 pending decisions from inbox

---

## Decisions Made Today

- **No AI buzzwords needed** — Decision Matrix, Humanizer, Orchestration rejected as formal patterns. The pipeline IS the orchestration. The narrator IS the humanizer. GOAP IS the decision matrix.
- **Extensible pipeline** — Refactor preprocess.lua into table of composable transform functions before implementing PD tiers
- **Mandatory regression tests** — Every player-reported bug gets a unit test before closing. No exceptions.
- **LLM play testing is a skill** — Extracted from Nelson's charter to `.squad/skills/llm-play-testing/SKILL.md` for reuse
- **README compliance** — All agents must read README.md before writing to any directory
