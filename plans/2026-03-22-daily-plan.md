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

### Parser North Star — Path to Prime Directive (A / 95%)

**Current:** C+ (65%) → **Target:** A (95%)
**Philosophy:** Feel like Copilot, cost like Zork. Zero tokens. Pure pipeline.
**Reference:** `docs/architecture/engine/parser/prime-directive-roadmap.md`

#### Step 0: Extensible Pipeline Refactor (PREREQUISITE — do this first)
- [ ] Refactor `preprocess.lua` from monolithic function → table-driven pipeline
- [ ] Each transform stage = separate function in a table
- [ ] Stages can be reordered, disabled, hot-swapped without touching other code
- [ ] Add per-stage debug logging (input/output at each step)
- [ ] Write pipeline unit tests before and after refactor
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

- [ ] `test/parser/pipeline/test-strip-politeness.lua` — "please X", "could you X", "can I X", "would you X", "let me X", "try to X", "I want to X", "I'd like to X", combinations, edge cases (word "please" inside a noun like "please-note"), no-op on already clean input
- [ ] `test/parser/pipeline/test-strip-adverbs.lua` — "carefully X", "thoroughly X", "quickly X", "slowly X", "gently X", position variants (start/middle/end), multi-adverb ("very carefully X"), adverb-like nouns preserved ("carefully" vs object named "careful")
- [ ] `test/parser/pipeline/test-transform-questions.lua` — "what's in X?", "is there X?", "can I X?", "where is X?", "what is this?", "how do I X?", "what can I find?", question marks stripped, non-questions pass through unchanged
- [ ] `test/parser/pipeline/test-expand-idioms.lua` — "set fire to X" → "light X", "pick up X" → "take X", "put down X" → "drop X", "blow out X" → "extinguish X", "have a look" → "look", partial matches don't fire, order independence
- [ ] `test/parser/pipeline/test-resolve-pronouns.lua` — "it" → last object, "that" → last object, "this" → context, "them" → plural context, no context = no resolution, context resets on room change
- [ ] `test/parser/pipeline/test-disambiguate-nouns.lua` — partial name match, material match, typo tolerance, ambiguity prompt, no-match fallthrough
- [ ] `test/parser/pipeline/test-pipeline-integration.lua` — full pipeline end-to-end: "please carefully search the nightstand for the matchbox" → "search nightstand for matchbox", stage ordering verification, disabled stage skipped, custom stage injection

#### Tier 0: Stripping Layer (HIGH impact, LOW risk)
- [~] Politeness stripping — "please", "could you", "let me" (done by Smithers, needs testing)
- [~] Adverb stripping — "carefully", "thoroughly", "quickly" (done, incomplete list — BUG-085)
- [ ] Verify stripping doesn't break compound patterns (BUG-083: "could you search for matches")
- [ ] Add missing adverbs: "thoroughly", "slowly", "gently", "firmly", "softly"
- [ ] Ensure strip order: politeness BEFORE adverbs BEFORE compound extraction
- [ ] **TEST GATE:** Write Tier 0 unit tests → run ALL tests → zero regressions before proceeding

#### Tier 1: Question Transforms (HIGH impact, LOW risk)
- [~] "what's in the X?" → "examine X" (done, needs more patterns)
- [~] "is there anything in X?" → "search X" (done)
- [~] "can I open X?" → "open X" (done)
- [ ] "what can I find?" → "search" (BUG-084: currently hangs)
- [ ] "where is the X?" → "search for X"
- [ ] "how do I X?" → contextual help
- [ ] "what is this?" → "examine" with context resolution
- [ ] **TEST GATE:** Write Tier 1 unit tests → run ALL tests → zero regressions before proceeding

#### Tier 2: Error Message Overhaul (HIGH impact, LOW risk)
- [~] "I don't understand" → "I'm not sure what you mean. Try 'help'..." (done by Smithers)
- [~] "You can't do that" → "That doesn't seem to work. Try a different approach..." (done)
- [ ] Every error message should suggest a valid action
- [ ] Never echo the failed parse back literally ("No the matchbox found" — BUG-081)
- [ ] Context-aware errors: "You can't see in the dark — try 'feel' instead"
- [ ] **TEST GATE:** Write Tier 2 unit tests → run ALL tests → zero regressions before proceeding

#### Tier 3: Idiom Library (MEDIUM impact, LOW risk)
- [ ] "set fire to X" → "light X"
- [ ] "pick up X" → "take X" (already done)
- [ ] "put down X" → "drop X"
- [ ] "blow out X" → "extinguish X"
- [ ] "have a look" → "look"
- [ ] "take a peek" → "look"
- [ ] Table-driven: each idiom = `{ pattern, replacement }`
- [ ] **TEST GATE:** Write Tier 3 unit tests → run ALL tests → zero regressions before proceeding

#### Tier 4: Context Window (HIGH impact, MEDIUM risk)
- [ ] Track last 3-5 discovered/interacted objects
- [ ] "it", "that", "this" resolve to most recent context (partially done)
- [ ] "the thing I found" → resolve from search discovery memory
- [ ] Bare "pick up" after discovery → take the discovered item
- [ ] "go back" → return to previous room
- [ ] Integrate with search module's found_items tracking
- [ ] **TEST GATE:** Write Tier 4 unit tests → run ALL tests → zero regressions before proceeding

#### Tier 5: Fuzzy Noun Resolution (MEDIUM impact, MEDIUM risk)
- [ ] "the wooden thing" → match objects by `material = "wood"`
- [ ] "the heavy one" → match by weight/size properties
- [ ] "that bottle" → partial name match when unambiguous
- [ ] Disambiguation prompt when multiple matches: "Which do you mean: the glass bottle or the wine bottle?"
- [ ] Levenshtein distance for typo tolerance: "nighstand" → "nightstand"
- [ ] **TEST GATE:** Write Tier 5 unit tests → run ALL tests → zero regressions before proceeding

#### Tier 6: Generalized GOAP (MEDIUM impact, MEDIUM risk)
- [ ] Extend beyond fire_source prerequisite chain
- [ ] "unlock the door" → auto-find key, auto-use key
- [ ] "read the book" → auto-light candle if dark
- [ ] Property-based goal matching (not hardcoded verb chains)
- [ ] Safety limits on plan depth (BUG-090 root cause)
- [ ] **TEST GATE:** Write Tier 6 unit tests → run ALL tests → zero regressions before proceeding

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
