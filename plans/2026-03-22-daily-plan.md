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
- [x] Full test suite: **479 pass / 0 fail** ✅

---

## Phase 1: Fix Last 2 Test Failures
- [ ] Fix `examine matchbox → shows 7 matches` test (output format mismatch)
- [ ] Fix `BUG-091 take match` test (spent match priority — test setup issue)
- [ ] Run full test suite → **421 pass / 0 fail**
- [ ] `git commit && git push`

### 🧪 Nelson Sanity Check: Pass 027
- [ ] Nelson plays the game — verify BUG-078–092 all fixed
- [ ] Creative search phrases, nightstand chain, candle lighting end-to-end
- [ ] Write results to `test-pass/gameplay/2026-03-22-pass-027.md`
- [ ] Fix anything found → rerun tests → commit+push

---

## Phase 2: Deploy
- [ ] Run `deploy.ps1` to push fixes live
- [ ] Verify live site at waynewalterberry.github.io/play/
- [ ] `git commit && git push`

---

## Phase 3: Engine Work
- [ ] `container-sensory-gating` — Engine checks open/closed before revealing contents
- [ ] `chest-object` — Create chest.lua + GUID + docs (two-handed carry)
- [ ] Run full test suite → zero regressions
- [ ] `git commit && git push`

### 🧪 Nelson Sanity Check: Pass 028
- [ ] Nelson tests container behavior — open/closed gating, chest interactions
- [ ] Write results to `test-pass/gameplay/2026-03-22-pass-028.md`
- [ ] Fix anything found → rerun tests → commit+push

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
- [ ] **Trace each hang to its actual loop.** For BUG-080, 084, 086, 087, 090 — what exact code path loops? Is it the same function every time or different entry points?
- [ ] **Map the embedding matcher.** What is its algorithm? Does it have a termination guarantee? If it's comparing against all objects × all verbs, what stops it from cycling?
- [ ] **Map the goal planner.** Can prerequisite chains form cycles? (A needs B, B needs A) Is there a visited-set? What's the maximum plan depth and is it enforced?
- [ ] **Map container traversal.** Can search traverse visit the same container twice? Is there a visited-set or does it rely on tree structure (which breaks if objects have backlinks)?
- [ ] **Propose the real fix.** Options to consider:
  - **State tracking:** visited-set for any recursive walk (search, GOAP, embedding matcher)
  - **Cycle detection:** if the same state is seen twice, the algorithm terminates with a clear message
  - **Algorithm redesign:** maybe the embedding matcher shouldn't recurse at all — it should be a single-pass score-and-rank
  - **Separation of concerns:** the parser fallback path should NEVER call the same parser again (no re-entrant parsing)
- [ ] **Document findings** in a short write-up: what's actually happening, what the real fix is, why depth limits are insufficient
- [ ] **If depth limits are actually the right answer**, explain WHY — what about the problem structure makes them correct (not just convenient)
- [ ] **Implement the real fix** (not depth limits unless justified)
- [ ] Run full test suite → zero regressions
- [ ] **Verify previously-hanging tests:** Run all tests that were hanging (BUG-080, 084, 086, 087, 090). Confirm they now: (a) complete without hanging, (b) produce correct output (not truncated/empty from a depth limit), (c) report results back in this plan with before/after comparison
- [ ] `git commit && git push`

### 🧪 Nelson Sanity Check: Pass 029
- [ ] Nelson specifically tests hang-prone phrases: "check X", "look at X", "find a match and light it", "what can I find?", nested container searches
- [ ] Verify NO hangs — game should always respond within 2 seconds
- [ ] Write results to `test-pass/gameplay/2026-03-22-pass-029.md`
- [ ] Fix anything found → rerun tests → commit+push

**This investigation blocks Phase 5.** We don't want to refactor the pipeline and carry forward a broken fallback path into the new architecture.

---

## Phase 5: Parser North Star — Path to Prime Directive (A / 95%)

**Current:** C+ (65%) → **Target:** A (95%)
**Philosophy:** Feel like Copilot, cost like Zork. Zero tokens. Pure pipeline.
**Reference:** `docs/architecture/engine/parser/prime-directive-roadmap.md`

#### Step 0: Extensible Pipeline Refactor (PREREQUISITE — do this first)
- [ ] Refactor `preprocess.lua` from monolithic function → table-driven pipeline
- [ ] Each transform stage = separate function in a table
- [ ] Stages can be reordered, disabled, hot-swapped without touching other code
- [ ] Add per-stage debug logging (input/output at each step)
- [ ] Write pipeline unit tests before and after refactor
- [ ] Run full test suite → zero regressions
- [ ] `git commit && git push`
- [ ] **📊 GRADE:** Reevaluate PD alignment → record in Completed Today (expected: still C+, refactor is structural not behavioral)
```lua
local pipeline = {
    strip_politeness,     -- Tier 0
    strip_adverbs,        -- Tier 0
    transform_questions,  -- Tier 1
    expand_idioms,        -- Tier 3
    resolve_pronouns,     -- Existing
    disambiguate_nouns,   -- Tier 5
}
```

#### Step 0.5: Per-Stage Unit Tests (IMMEDIATELY after refactor — before any Tier work)
Each pipeline stage gets its own test file with deep coverage. These are the regression guards that prevent one stage's changes from silently breaking another.

- [ ] `test/parser/pipeline/test-strip-politeness.lua`
- [ ] `test/parser/pipeline/test-strip-adverbs.lua`
- [ ] `test/parser/pipeline/test-transform-questions.lua`
- [ ] `test/parser/pipeline/test-expand-idioms.lua`
- [ ] `test/parser/pipeline/test-resolve-pronouns.lua`
- [ ] `test/parser/pipeline/test-disambiguate-nouns.lua`
- [ ] `test/parser/pipeline/test-pipeline-integration.lua`
- [ ] Run full test suite → all new + existing pass
- [ ] `git commit && git push`

### 🧪 Nelson Sanity Check: Pass 030
- [ ] Nelson play tests after pipeline refactor — make sure nothing broke
- [ ] Same phrases that worked before should still work
- [ ] Write results to `test-pass/gameplay/2026-03-22-pass-030.md`
- [ ] Fix anything found → rerun tests → commit+push

#### Tier 0: Stripping Layer (HIGH impact, LOW risk)
- [~] Politeness stripping — "please", "could you", "let me" (done by Smithers, needs testing)
- [~] Adverb stripping — "carefully", "thoroughly", "quickly" (done, incomplete list — BUG-085)
- [ ] Verify stripping doesn't break compound patterns (BUG-083: "could you search for matches")
- [ ] Add missing adverbs: "thoroughly", "slowly", "gently", "firmly", "softly"
- [ ] Ensure strip order: politeness BEFORE adverbs BEFORE compound extraction
- [ ] **TEST GATE:** Write Tier 0 unit tests → run ALL tests → zero regressions
- [ ] `git commit && git push`
- [ ] **📊 GRADE:** Reevaluate PD alignment → record in Completed Today (expected: C+ → B-, politeness/adverbs now covered)

#### Tier 1: Question Transforms (HIGH impact, LOW risk)
- [~] "what's in the X?" → "examine X" (done, needs more patterns)
- [~] "is there anything in X?" → "search X" (done)
- [~] "can I open X?" → "open X" (done)
- [ ] "what can I find?" → "search" (BUG-084: currently hangs)
- [ ] "where is the X?" → "search for X"
- [ ] "how do I X?" → contextual help
- [ ] "what is this?" → "examine" with context resolution
- [ ] **TEST GATE:** Write Tier 1 unit tests → run ALL tests → zero regressions
- [ ] `git commit && git push`
- [ ] **📊 GRADE:** Reevaluate PD alignment → record in Completed Today (expected: B- → B, questions now handled)
- [ ] Nelson tests polite phrasing + questions after Tier 0-1
- [ ] Write results to `test-pass/gameplay/2026-03-22-pass-031.md`
- [ ] Fix anything found → rerun tests → commit+push

#### Tier 2: Error Message Overhaul (HIGH impact, LOW risk)
- [~] "I don't understand" → "I'm not sure what you mean. Try 'help'..." (done by Smithers)
- [~] "You can't do that" → "That doesn't seem to work. Try a different approach..." (done)
- [ ] Every error message should suggest a valid action
- [ ] Never echo the failed parse back literally ("No the matchbox found" — BUG-081)
- [ ] Context-aware errors: "You can't see in the dark — try 'feel' instead"
- [ ] **TEST GATE:** Write Tier 2 unit tests → run ALL tests → zero regressions
- [ ] `git commit && git push`
- [ ] **📊 GRADE:** Reevaluate PD alignment → record in Completed Today (expected: B → B+, errors now guide instead of punish)(MEDIUM impact, LOW risk)
- [ ] "set fire to X" → "light X"
- [ ] "pick up X" → "take X" (already done)
- [ ] "put down X" → "drop X"
- [ ] "blow out X" → "extinguish X"
- [ ] "have a look" → "look"
- [ ] "take a peek" → "look"
- [ ] Table-driven: each idiom = `{ pattern, replacement }`
- [ ] **TEST GATE:** Write Tier 3 unit tests → run ALL tests → zero regressions
- [ ] `git commit && git push`
- [ ] **📊 GRADE:** Reevaluate PD alignment → record in Completed Today (expected: B+ → A-, idioms expand natural phrasing)
- [ ] Nelson tests error messages + idioms after Tier 2-3
- [ ] Tries intentionally wrong commands — are error messages helpful?
- [ ] Tries idiom phrases — "set fire to candle", "have a look", "take a peek"
- [ ] Write results to `test-pass/gameplay/2026-03-22-pass-032.md`
- [ ] Fix anything found → rerun tests → commit+push

#### Tier 4: Context Window (HIGH impact, MEDIUM risk)
- [ ] Track last 3-5 discovered/interacted objects
- [ ] "it", "that", "this" resolve to most recent context (partially done)
- [ ] "the thing I found" → resolve from search discovery memory
- [ ] Bare "pick up" after discovery → take the discovered item
- [ ] "go back" → return to previous room
- [ ] Integrate with search module's found_items tracking
- [ ] **TEST GATE:** Write Tier 4 unit tests → run ALL tests → zero regressions
- [ ] `git commit && git push`
- [ ] **📊 GRADE:** Reevaluate PD alignment → record in Completed Today (expected: A- → A-, context makes discovery feel remembered)Fuzzy Noun Resolution (MEDIUM impact, MEDIUM risk)
- [ ] "the wooden thing" → match objects by `material = "wood"`
- [ ] "the heavy one" → match by weight/size properties
- [ ] "that bottle" → partial name match when unambiguous
- [ ] Disambiguation prompt when multiple matches: "Which do you mean: the glass bottle or the wine bottle?"
- [ ] Levenshtein distance for typo tolerance: "nighstand" → "nightstand"
- [ ] **TEST GATE:** Write Tier 5 unit tests → run ALL tests → zero regressions
- [ ] `git commit && git push`
- [ ] **📊 GRADE:** Reevaluate PD alignment → record in Completed Today (expected: A- → A, typos and vague nouns now tolerated)
- [ ] Nelson tests context + fuzzy resolution after Tier 4-5
- [ ] "examine nightstand" → "open it" → "take that" — pronouns work?
- [ ] "the wooden thing" → resolves correctly?
- [ ] Write results to `test-pass/gameplay/2026-03-22-pass-033.md`
- [ ] Fix anything found → rerun tests → commit+push

#### Tier 6: Generalized GOAP (MEDIUM impact, MEDIUM risk)
- [ ] Extend beyond fire_source prerequisite chain
- [ ] "unlock the door" → auto-find key, auto-use key
- [ ] "read the book" → auto-light candle if dark
- [ ] Property-based goal matching (not hardcoded verb chains)
- [ ] Safety limits on plan depth (BUG-090 root cause)
- [ ] **TEST GATE:** Write Tier 6 unit tests → run ALL tests → zero regressions
- [ ] `git commit && git push`
- [ ] **📊 GRADE:** Reevaluate PD alignment → record in Completed Today (expected: A → A+, GOAP handles multi-step goals beyond fire)
- [ ] Nelson tests GOAP chains — "light candle" from cold start, "unlock door"
- [ ] Full critical path playthrough: wake up → light candle → explore → interact
- [ ] Write results to `test-pass/gameplay/2026-03-22-pass-034.md`
- [ ] Fix anything found → rerun tests → commit+push

---

## Phase 6: Remaining Game Systems
- [ ] Combat precursor: stab/cut/slash deeper testing
- [ ] Treatment objects: salve, nightshade antidote
- [ ] Wine FSM (BUG-061 still broken)
- [ ] Scribe: merge ~15 pending decisions from inbox
- [ ] Run full test suite → zero regressions
- [ ] `git commit && git push`

### 🧪 Nelson Sanity Check: Pass 035
- [ ] Nelson full playthrough — all systems together
- [ ] Write results to `test-pass/gameplay/2026-03-22-pass-035.md`

---

## Phase 7: Final Deploy
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
