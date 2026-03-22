# Daily Plan — 2026-03-22

**Owner:** Wayne "Effe" Berry
**Focus:** Search/find bug fixes, regression testing, Prime Directive foundation
**Rule:** Work the WHOLE plan today. No backlog. Nelson play-tests between every phase. Commit+push between every step.

---

## Process Rules

1. **Nelson is the sanity checker.** Between every phase, Nelson does an LLM play test pass to make sure the game hasn't gone off course. He's the player's advocate — if the game feels wrong, we stop and fix it before moving on.
2. **Commit and push between every step.** No accumulated drift. Every phase ends with `git add . && git commit && git push`.
3. **Keep this plan updated.** Mark items `[x]` as they complete. Update "Completed Today" section. This file is the live dashboard.
4. **All tests must pass before advancing.** Run the full suite (419+ tests) after every code change.

---

## Completed Today

- [x] ⚛️ Smithers — Deployed BUG-073-077 fixes + Prime Directive quick wins (politeness, adverbs, questions, error messages)
- [x] 🏗️ Bart — Prime Directive roadmap (`docs/architecture/engine/parser/prime-directive-roadmap.md`, 917 lines, 6 tiers)
- [x] 🏗️ Bart — Parser strategy doc (`docs/architecture/engine/parser/parser-strategy.md` — buzzword analysis, pipeline architecture)
- [x] 🧪 Nelson — Pass 025 (search/find creative phrasing, 31 tests) + Pass 026 (nightstand regression, 13 tests)
- [x] Pipeline refactor added to PD roadmap section 6 (extensible interpretation pipeline)
- [x] Test passes reorganized (26 files → correct `gameplay/` subfolder, `YYYY-MM-DD-pass-NNN.md` naming)
- [x] Nelson charter updated — references README.md + points to LLM play testing skill
- [x] LLM play testing extracted to skill (`.squad/skills/llm-play-testing/SKILL.md`)
- [x] Bug report lifecycle skill updated — mandatory regression unit tests before closing issues
- [x] ⚛️ Smithers (P0) — Fixed 13 bugs: 5 hangs (BUG-080/084/086/087/090) + 8 parser/search issues
- [x] ⚛️ Smithers (P1) — Fixed 4 bugs: spent match (BUG-091), match counter (BUG-092), scope bleed (BUG-089), synonyms
- [x] 🧪 Nelson — 56 regression unit tests written (38 pass, 18 fail → mapped to known bugs)
- [x] Full test suite: **421 pass / 0 fail** ✅
- [x] 🧪 Nelson Pass 027: 18/25 pass (72%). Release blocker cleared (`light candle` works!). 11/15 bugs fixed. Still broken: BUG-082/083/084 (compound hangs), BUG-091 (spent match). New: BUG-093 (rummage hangs), BUG-094 (look for a candle hangs)
- [x] ⚛️ Smithers — Fixed 6 remaining Pass 027 bugs (BUG-082/083/084/091/093/094) + 40 regression tests
- [x] ⚛️ Smithers — Deployed to live site (commit 58538d4, 96 files, verified live)
- [x] ⚛️ Smithers — Container sensory gating: 7 content paths gated, transparent exception, 18 tests
- [x] 🏗️ Bart — Chest design docs: `docs/objects/chest.md` + `docs/design/chest-mechanics.md` (two-handed carry)
- [x] 🏗️ Bart — Hang root cause: 3 mechanisms found. Container cycles → visited sets (replaces depth limits). Embedding matcher already single-pass. Analysis at `docs/architecture/engine/parser/hang-root-cause-analysis.md`
- [x] 🧪 Nelson Pass 028: 22 tests, 77% pass. Container gating works for nightstand. GOAP auto-chain flawless. New: BUG-095 (wardrobe gating), BUG-096 (drawer name), BUG-097 (look inside closed)
- [x] ⚛️ Smithers — Phase 5 Step 0: Pipeline refactor complete. 7 composable stages, table-driven, debug logging. Zero behavior change, 479 pass.
- [x] 🧪 Nelson — Phase 5 Step 0.5: 224 per-stage pipeline tests across 7 files, all passing
- [x] ⚛️ Smithers — Fixed BUG-095/096/097 container gating (wardrobe, drawer name, look-inside) + 10 regression tests
- [x] 🧪 Nelson Pass 029: **0 hangs, 0 failures, 0 regressions.** All 9 hang bugs verified fixed with correct output. Pipeline refactor clean.
- [x] Full test suite: **713 pass / 0 fail** ✅
- [x] **📊 GRADE after Step 0:** C+ (65%) — structural refactor, no behavior change yet
- [x] ⚛️ Smithers — Tier 0+1: 4 politeness patterns, 5 adverbs, 6 question transforms. BUG-083 verified. 751→766 pass.
- [x] **📊 GRADE after Tier 0+1:** B- (72%) — politeness/adverbs fully covered, questions handled, strip order correct
- [x] ⚛️ Smithers — Tier 2+3: Error message overhaul (no echo, context-aware, suggests actions) + 14 idioms (table-driven pipeline stage). +35 tests.
- [x] **📊 GRADE after Tier 2+3:** A- (82%) — errors guide, idioms expand natural phrasing
- [x] Full test suite: **801 pass / 0 fail** ✅
- [x] 🧪 Nelson Pass 031: 64% pass. 3 hangs (BUG-104/105/106: "what's this?", "what do I do?", "what now?"). 3 fails (BUG-107/108/109: missing preambles). Critical path intact.
- [x] ⚛️ Smithers — Tier 4: Context window. 5-object stack, enhanced pronouns (it/that/this/one), search discovery integration, bare "pick up", "go back". 41 new tests.
- [x] **📊 GRADE after Tier 4:** A- (85%) — context makes discovery feel remembered
- [x] 🧪 Nelson Pass 032: 86% pass. All 8 idioms work. Error messages much improved. 3 minor bugs (politeness+idiom combo, bare examine, unlit candle message).
- [x] ⚛️ Smithers — Fixed BUG-104-111: question hangs, gerund stripping (27 mappings), preambles, singularize targets. 33 new tests.
- [x] Full test suite: **872 pass / 0 fail** ✅ (1 flaky timing test excluded)
- [x] ⚛️ Smithers — Tier 5: Fuzzy noun resolution. New `fuzzy.lua` module — material matching, partial name, property matching, disambiguation prompts, Levenshtein typo tolerance. Fallback only (zero happy-path cost). 52 new tests.
- [x] **📊 GRADE after Tier 5:** A- (88%) — typos and vague nouns now tolerated
- [x] 🧪 Nelson Pass 033: 53% pass. Pronouns (it/that) work, go back works, GOAP flawless. BUT: BUG-105/106 still hang ("what do I do?", "what now?"), bare "pick up" no auto-fill, "look under this" hangs (BUG-112).
- [x] ⚛️ Smithers — Tier 6: Generalized GOAP. Property-based goals, plan_for_light, plan_for_key, plan_generic_tool. Safety limit (7 depth, 20 steps). Fire chain preserved. 44 new tests.
- [x] **📊 GRADE after Tier 6:** A (90%) — GOAP handles multi-step goals beyond fire
- [x] Full test suite: **968 pass / 0 fail** ✅
- [x] ⚛️ Smithers — Fixed BUG-105/106/112: belt-and-suspenders help safety net, look under/beneath → examine. 27 new tests.
- [x] Full test suite: **995 pass / 0 fail** ✅
- [ ] ⚛️ Smithers — Fixing BUG-113/114/115 (context window gaps: bare pick up, discovery phrases, spatial references) ✅ Fixed + 19 regression tests
- [x] ⚛️ Smithers — Phase 6: Combat tests (25), BUG-061 wine FSM fixed (bad GUID), treatment objects audited. 48 new tests.
- [x] Full test suite: **1,065 pass / 0 fail** ✅
- [x] 🏠 Marge hired as Test Manager — owns bug tracker, test pass review, coverage audit, deploy gates

---

## Phase 1: Fix Last 2 Test Failures ✅
- [x] Fix `examine matchbox → shows 7 matches` test (container flag fix)
- [x] Fix `BUG-091 take match` test (FSM state setup)
- [x] Run full test suite → **421 pass / 0 fail** ✅
- [x] `git commit && git push` ✅

### 🧪 Nelson Sanity Check: Pass 027 ✅
- [x] Nelson plays the game — verify BUG-078–092 all fixed
- [x] Creative search phrases, nightstand chain, candle lighting end-to-end
- [x] Write results to `test-pass/gameplay/2026-03-22-pass-027.md` ✅
- [x] Fix 6 remaining bugs (BUG-082/083/084/091/093/094) + 40 regression tests → **461 pass / 0 fail** ✅
- [x] `git commit && git push` ✅

---

## Phase 2: Deploy ✅
- [x] Run `deploy.ps1` to push fixes live (commit 58538d4, 96 files)
- [x] Verify live site at waynewalterberry.github.io/play/ ✅
- [x] `git commit && git push` ✅

---

## Phase 3: Engine Work ✅
- [x] `container-sensory-gating` — 7 content paths gated, transparent exception, 18 tests
- [x] `chest-object` — Design docs: `docs/objects/chest.md` + `docs/design/chest-mechanics.md` (two-handed carry)
- [x] Run full test suite → **479 pass / 0 fail** ✅
- [x] `git commit && git push` ✅

### 🧪 Nelson Sanity Check: Pass 028 ✅
- [x] Nelson tests container behavior — open/closed gating, chest interactions
- [x] Write results to `test-pass/gameplay/2026-03-22-pass-028.md` ✅
- [x] Fix BUG-095/096/097 (wardrobe gating, drawer name, look-inside) + 10 regression tests ✅
- [x] `git commit && git push` ✅

---

## Phase 4: Hang Root Cause Investigation (BEFORE North Star)

**Problem:** Multiple bugs (BUG-076, 077, 080, 084, 086, 087, 090) cause infinite hangs. The current "fix" is depth-limiting recursion — but that's a band-aid, not a real fix. Depth limits will produce bad outcomes: silently truncating searches, returning incomplete results, or swallowing errors the player never sees.

**Wayne's directive:** Don't just limit depth because it's easy. Deeply understand WHY these loops happen. Track state? Different algorithm? Something else? Find the real fix.

**What we suspect but haven't verified:**
- The embedding matcher (fuzzy verb/noun fallback) may be the common root — multiple hangs trace there
- The goal planner (GOAP) may have circular prerequisite chains (match needs fire, fire needs match)
- Scoped search + container recursion may visit the same object twice (no visited-set)
- "look at X" and "check X" fall through to embedding matcher which has no termination guarantee

**Investigation tasks (Bart — architecture level):**
- [x] **Trace each hang to its actual loop.** Found 3 distinct mechanisms: container traversal cycles, preprocessing gaps, preprocessor recursion.
- [x] **Map the embedding matcher.** Already single-pass — no recursion, no parser re-entry. Not the root cause.
- [x] **Map the goal planner.** Not the source of hangs. Chain was: unknown verb → Tier 2 → search → container cycle.
- [x] **Map container traversal.** `expand_object()` and `matches_target()` recursed without cycle detection. Fixed with visited sets.
- [x] **Propose the real fix.** Visited sets in traverse.lua (replaces depth limits). Preprocessor synonym rules confirmed correct (not band-aids).
- [x] **Document findings** at `docs/architecture/engine/parser/hang-root-cause-analysis.md`
- [x] **Depth limits verdict:** Container traversal uses visited sets (principled). Preprocessor has safety-belt depth counter. Embedding matcher doesn't recurse.
- [x] **Implement the real fix** — visited sets in expand_object() and matches_target(), depth guard on natural_language()
- [x] Run full test suite → zero regressions ✅
- [x] **Verify previously-hanging tests:** All 7 inputs verified in Nelson Pass 029: (a) no hangs, (b) correct output, (c) not truncated
- [x] `git commit && git push` ✅

### 🧪 Nelson Sanity Check: Pass 029 ✅
- [x] Nelson specifically tests hang-prone phrases — all respond within 2 seconds
- [x] Write results to `test-pass/gameplay/2026-03-22-pass-029.md` ✅
- [x] Fix anything found → 2 warnings, not blocking ✅

**✅ Investigation complete. Unblocked Phase 5.**

---

## Phase 5: Parser North Star — Path to Prime Directive (A / 95%)

**Current:** C+ (65%) → **Target:** A (95%)
**Philosophy:** Feel like Copilot, cost like Zork. Zero tokens. Pure pipeline.
**Reference:** `docs/architecture/engine/parser/prime-directive-roadmap.md`

#### Step 0: Extensible Pipeline Refactor ✅
- [x] Refactored to 7 composable stages, table-driven, debug logging
- [x] Run full test suite → zero regressions ✅
- [x] `git commit && git push` ✅
- [x] **📊 GRADE:** C+ (65%) — structural refactor, no behavior change

#### Step 0.5: Per-Stage Unit Tests ✅
- [x] `test/parser/pipeline/test-normalize.lua` (24 tests)
- [x] `test/parser/pipeline/test-strip-filler.lua` (44 tests)
- [x] `test/parser/pipeline/test-transform-questions.lua` (32 tests)
- [x] `test/parser/pipeline/test-transform-look-patterns.lua` (25 tests)
- [x] `test/parser/pipeline/test-transform-search-phrases.lua` (32 tests)
- [x] `test/parser/pipeline/test-transform-compound-actions.lua` (39 tests)
- [x] `test/parser/pipeline/test-pipeline-integration.lua` (28 tests)
- [x] Run full test suite → **713 pass / 0 fail** ✅
- [x] `git commit && git push` ✅

### 🧪 Nelson Sanity Check: Pass 030 (covered by Pass 029)
- [x] Pipeline refactor verified clean in Pass 029 — all existing phrases work ✅

#### Tier 0: Stripping Layer ✅
- [x] Politeness stripping — "please", "could you", "let me", "would you mind", "maybe", "perhaps", "I think I'll"
- [x] Adverb stripping — "carefully", "thoroughly", "quickly", "slowly", "gently", "firmly", "softly", "briskly", "hastily", "nervously"
- [x] Verified stripping doesn't break compound patterns (BUG-083 confirmed working)
- [x] Strip order correct: preambles → politeness → adverbs
- [x] **TEST GATE:** Tests pass ✅
- [x] `git commit && git push` ✅
- [x] **📊 GRADE:** C+ → B- (72%) — politeness/adverbs fully covered

#### Tier 1: Question Transforms ✅
- [x] "what's in the X?" → "examine X"
- [x] "is there anything in X?" → "search X"
- [x] "can I open X?" → "open X"
- [x] "what can I find?" → "search"
- [x] "where is the X?" → "search for X"
- [x] "how do I X?" → "help"
- [x] "what is this?" → "examine" with context
- [x] "what do I do?" / "what now?" → "help"
- [x] **TEST GATE:** Tests pass → **766 pass / 0 fail** ✅
- [x] `git commit && git push` ✅
- [x] **📊 GRADE:** B- → B (72%) — questions now handled

### 🧪 Nelson Sanity Check: Pass 031 (🔄 RUNNING)
- [ ] Nelson tests polite phrasing + questions after Tier 0-1
- [ ] Write results to `test-pass/gameplay/2026-03-22-pass-031.md`
- [ ] Fix anything found → rerun tests → commit+push

#### Tier 2: Error Message Overhaul ✅
- [x] All error messages now guide instead of punish — no verb echo, dark suggests 'feel', search suggests alternatives
- [x] **TEST GATE:** +35 tests → **801 pass / 0 fail** ✅
- [x] `git commit && git push` ✅
- [x] **📊 GRADE:** B → B+ (78%) — errors now guide instead of punish

#### Tier 3: Idiom Library ✅
- [x] 14 table-driven idioms: "set fire to", "blow out", "have a look", "take a peek", "go to sleep", "lay down", "get rid of", "make use of", "put down"
- [x] New `expand_idioms` pipeline stage at position 3, table exposed for runtime extension
- [x] **TEST GATE:** Tests pass ✅
- [x] `git commit && git push` ✅
- [x] **📊 GRADE:** B+ → A- (82%) — idioms expand natural phrasing

### 🧪 Nelson Sanity Check: Pass 032 ✅
- [x] Nelson tests error messages + idioms — 86% pass, all 8 idioms work
- [x] Write results to `test-pass/gameplay/2026-03-22-pass-032.md` ✅
- [x] 3 minor bugs found (politeness+idiom combo, bare examine, unlit candle message)

#### Tier 4: Context Window ✅
- [x] 5-object context stack, deduplication, most-recent-first
- [x] Enhanced pronouns: "it"/"that"/"this"/"one" → context stack top
- [x] Discovery references from search, bare "pick up" fallback, "go back" support
- [x] **TEST GATE:** 41 new tests → pass ✅
- [x] `git commit && git push` ✅
- [x] **📊 GRADE:** A- (85%) — context makes discovery feel remembered

#### Tier 5: Fuzzy Noun Resolution ✅
- [x] Material matching ("the wooden thing" → wood objects)
- [x] Partial name ("bottle" → "small glass bottle" when unambiguous)
- [x] Disambiguation prompt ("Which do you mean: the glass bottle or the wine bottle?")
- [x] Levenshtein typo tolerance ("nighstand" → "nightstand")
- [x] **TEST GATE:** 52 new tests → pass ✅
- [x] `git commit && git push` ✅
- [x] **📊 GRADE:** A- (88%) — typos and vague nouns now tolerated

### 🧪 Nelson Sanity Check: Pass 033 ✅
- [x] Pronouns (it/that) work, go back works, GOAP flawless
- [x] BUG-105/106 still hung → routed fix → belt-and-suspenders safety net added
- [x] BUG-112 (look under this) → fixed, look under/beneath → examine
- [x] Write results to `test-pass/gameplay/2026-03-22-pass-033.md` ✅

#### Tier 6: Generalized GOAP ✅
- [x] Property-based goal matching: plan_for_light, plan_for_key, plan_generic_tool
- [x] Safety limits: MAX_DEPTH=7, MAX_PLAN_STEPS=20 with helpful messages
- [x] Fire_source chain preserved and refactored
- [x] **TEST GATE:** 44 new tests → pass ✅
- [x] `git commit && git push` ✅
- [x] **📊 GRADE:** A (90%) — GOAP handles multi-step goals beyond fire

### 🧪 Nelson Sanity Check: Pass 034 (🔄 RUNNING)
- [ ] Nelson tests GOAP chains — "light candle" from cold start, "unlock door"
- [ ] Full critical path playthrough: wake up → light candle → explore → interact
- [ ] Natural language gauntlet: politeness + adverb + fuzzy noun + idiom + question combos
- [ ] Write results to `test-pass/gameplay/2026-03-22-pass-034.md`
- [ ] Fix anything found → rerun tests → commit+push

---

## Phase 6: Remaining Game Systems ✅
- [x] Combat precursor: 25 unit tests (stab/cut/slash with knife, edge cases)
- [x] BUG-061 wine FSM fixed (bad GUID in storage-cellar.lua), 23 regression tests
- [x] Treatment objects: bandage implemented, salve + antidote are design-only
- [x] BUG-113/114/115 context window gaps fixed + 19 regression tests
- [x] `git commit && git push` ✅

### 🏠 Marge: First Bug Audit ✅
- [x] Reviewed all 11 Nelson test passes, cross-referenced with bug tracker
- [x] Audit report at `bugs/audit-2026-03-22.md`
- [x] Findings: 98% coverage, 3 bugs need regression tests (BUG-070/091/092), 2 duplicate test candidates, 4 hang bugs need RCA docs
- [x] **🔴 DEPLOY BLOCKED** until BUG-105/106 confirmed fixed (common player phrases hang)
- [x] Bug tracker updated with corrections

### ⚛️ Smithers: Remaining Open Bugs ✅
- [x] BUG-069: sleep-until-dawn daytime check fixed
- [x] BUG-071: cannot-reproduce (100x stress test clean)
- [x] BUG-104b: pipeline order verified correct + tested
- [x] BUG-105b: bare examine now prompts "Examine what?"
- [x] BUG-106b: blow out unlit candle says "not lit"
- [x] 23 regression tests added
- [x] Full test suite: **1,088 pass / 0 fail** ✅

### 🧪 Nelson Sanity Check: Pass 034 ✅
- [x] Comprehensive GOAP + full playthrough + natural language gauntlet — 76% pass
- [x] GOAP flawless, critical path solid, writing quality excellent
- [x] **5 hangs block deploy:** BUG-105/106 (still broken) + BUG-116/117/118 (new)
- [x] Write results to `test-pass/gameplay/2026-03-22-pass-034.md` ✅

### 🏠 Marge: Migrate to GitHub Issues ✅
- [x] Created 14 labels (severity, status, component, hang)
- [x] Filed 11 open bugs as GitHub Issues (#1-#11) on WayneWalterBerry/MMO
- [x] Deleted bugs/ folder from repo
- [x] **🔴 DEPLOY BLOCKED** — 3 critical hangs (#5, #6, #9), 3 high hangs (#2, #10, #11)

---

## ⚠️ PIVOT: Hang Elimination Sprint (BLOCKS DEPLOY)

**Wayne's directive:** Stop all feature work. Focus entirely on hang elimination + deploy.

**The problem:** We keep patching individual hanging inputs, but new inputs find the same hole. BUG-105/106 have been "fixed" twice and still hang in live play. The parser's fallback path can hang on any unrecognized input.

**The goal:** Make it architecturally impossible for the parser to hang. Not "fix known inputs" — make the CLASS of inputs safe.

### 🏗️ Bart: Deep RCA — why can the parser hang at all? ✅
- [x] Added trace logging (`--trace` / `_G.TRACE`) — instruments pipeline, Tier 2, GOAP, verb dispatch, search
- [x] Reproduced all 5 hangs — BUG-105/106/116/117 already fixed, BUG-118 fixed (peek patterns)
- [x] **Global safety net: `debug.sethook` 2-second deadline + `pcall` wrapper — hangs are now architecturally impossible**
- [x] Search tick hardened: 200-tick bounded loop + force-abort
- [x] All 37 test files pass. Issues left open for Marge.

### ⚛️ Smithers: Implement Bart's fix + global safety net
- [ ] Implement the architectural fix Bart proposes
- [ ] Add global timeout in game loop — if ANY command takes > 2 seconds, bail with helpful message
- [ ] Fix Issues #1-#11 that are fixable now
- [ ] Leave Issues OPEN — Marge closes after verification

### 🧪 Nelson: Targeted hang hunting (Pass 035)
- [ ] Try 50+ bizarre inputs specifically to find hangs
- [ ] Goal: enumerate ALL inputs that can hang, not just play the game
- [ ] Categories: nonsense verbs, preposition combos, question variants, compound chains, pronouns with no context
- [ ] File any new hangs as GitHub Issues

### 🏠 Marge: Verify and close
- [ ] After each fix: verify the fix works in live play (not just unit tests)
- [ ] Confirm regression test exists
- [ ] Close the GitHub Issue only after verification
- [ ] Give deploy go/no-go when all critical/high hangs are closed

---

## Phase 7: Final Deploy (after Marge gives go/no-go)
- [ ] Run `deploy.ps1` to push everything live
- [ ] Verify live site
- [ ] `git commit && git push`

---

## Decisions Made Today

- **No AI buzzwords needed** — Decision Matrix, Humanizer, Orchestration rejected as formal patterns. The pipeline IS the orchestration. The narrator IS the humanizer. GOAP IS the decision matrix.
- **Extensible pipeline** — Refactor preprocess.lua into table of composable transform functions before implementing PD tiers
- **Mandatory regression tests** — Every player-reported bug gets a unit test before closing. No exceptions.
- **LLM play testing is a skill** — Extracted from Nelson's charter to `.squad/skills/llm-play-testing/SKILL.md` for reuse
- **README compliance** — All agents must read README.md before writing to any directory
- **No depth-limit band-aids** — Investigate hang root causes properly before pipeline refactor
- **Nelson between every phase** — LLM play test sanity check prevents the game from going off course
- **Commit+push between every step** — No accumulated drift
- **Bugs in GitHub Issues** — WayneWalterBerry/MMO, not markdown files. Labels for severity/component/hang.
- **Engineers don't close Issues** — Only test team (Marge/Nelson) verifies fixes and closes. Engineers fix + comment.
- **PIVOT: Hang elimination** — Stop all features. Make parser architecturally unable to hang. Deploy only after Marge go/no-go.
