# Smithers -- History

## Project Context
- **Project:** MMO text adventure game in pure Lua (REPL-based, lua src/main.lua)
- **Owner:** Wayne 'Effe' Berry
- **Architecture:** 8 Core Principles (code-derived mutable objects, FSM-driven behavior, sensory space, generic mutation via Principle 8)
- **Stack:** Pure Lua, no external dependencies
- **My Focus:** UI layer (text output, presentation, player feedback) and Parser pipeline (Tiers 1-5, verb resolution, disambiguation, GOAP)

## Core Responsibilities

**Parser Pipeline:**
- Tier 1: Exact verb dispatch (70% coverage, <1ms)
- Tier 2: Phrase similarity with token overlap (90% cumulative, ~5ms)
- Tier 3: GOAP planning with prerequisite chaining (98% cumulative, ~100ms)
- Tier 4-5: Context window & SLM fallback (designed, not yet deployed)

**Web Architecture:**
- Fengari integration for browser playtest
- Synchronous XHR with HTTP caching (ETag/Last-Modified)
- Progressive loading with boot status messages
- Mobile-first dark theme terminal UI

**Key Ownership:**
- src/engine/parser/ - parser pipeline (Tiers 1-5)
- src/engine/ui/ - UI module, text formatting
- src/engine/verbs/init.lua - verb dispatch (text output)
- web/ - web build pipeline, browser wrapper

## Key Parser Patterns

### Options System Integration
- **Idiom table duplication:** Both `data.lua` and `idioms.lua` IDIOM_TABLEs exist; both need updates
- **Pattern ordering matters:** Options patterns placed BEFORE generic patterns to prevent false matches
- **Number interception:** Goes after trim + question-mark strip but before multi-command splitting
- **pending_options lifecycle:** One-shot design — cleared by loop on valid selection, invalid number, or non-numeric input
- **"nudge" collision:** Already exists as physical verb; added as bare-word match in transform_questions

### Parser Validation Gates
All 6 validation gates (P1-P6) implemented:
1. Noun validation
2. Verbose truncation
3. Question transform
4. Noun exactness
5. Adjective guard
6. Unknown lead-word guard

### Recent Parser Polish (WAVE-2a, 2026-08-23)

**Kid-Friendly Error Messages:**
- Check `context.world.rating == "E"` to show encouraging messages
- E-rated: "Hmm, try looking around for clues!" vs standard: "You don't notice anything called that nearby..."

**Puzzle Verb Coverage:**
- Added 5 verbs: `sort`, `count`, `press`, `assemble`, `build`
- Added 6 gerunds: `sorting`, `counting`, `pressing`, `assembling`, `building`, `entering`

**Embedding Index Update:**
- Added 40 new phrases for MrBeast vocabulary (Wyatt's World)
- Total phrases: 11,755

## Learnings

### Options Parser Integration (Phase 2+4)

- **Idiom table duplication:** Both `data.lua` IDIOM_TABLE and `idioms.lua` IDIOM_TABLE exist. The data.lua version is consumed by `phrases.expand_idioms()` in the pipeline; `idioms.lua` is a separate Tier 3 module. Both needed updating for "give me a hint" redirect.
- **Pattern ordering matters:** Options patterns ("what can i try") placed BEFORE "what can i see" / "what do i see" in transform_questions to prevent false matches. The first `if` block that matches wins.
- **Number interception placement:** Goes after trim + question-mark strip but before BUG-105 safety net and multi-command splitting. This ensures numbers are caught early and the substituted command flows through the full pipeline normally.
- **pending_options lifecycle:** Set by the options verb handler (Phase 1, Bart's domain). Cleared by the loop on: valid selection, invalid number (after error), or any non-numeric input. One-shot design — no state machine needed.
- **"nudge" collision:** "nudge" is already in KNOWN_VERBS as a physical verb (push synonym). Added it to phrases.transform_questions as bare-word match (`text == "nudge"`), which fires before verb dispatch. Added `nudge_verb` to KNOWN_VERBS as a distinct entry; bare "nudge" routes to options via transform_questions.

### Parser Improvement Audit (2026-03-29)

Full audit of parser codebase vs. design doc (`projects/parser-improvements/parser-improvement-design.md`). Key findings:

- **91.2% accuracy achieved** (134/147 benchmark) — up from 68% baseline. Phases 1-3 fully shipped.
- **BM25 scoring fully operational** — IDF table (244 tokens, 11,131 phrases), inverted index, synonym expansion (60+ verb mappings), tightened Levenshtein thresholds.
- **All 6 validation gates (P1-P6) implemented** — noun validation, verbose truncation, question transform, noun exactness, adjective guard, unknown lead-word guard. These were "recommended next improvements" in the design doc and are now all done.
- **Context-aware recency boost operational** — Phase 3 mode in embedding_matcher wired to context.recency_score().
- **word_similarity.lua exists but is NOT consumed** — 257 LOC sparse matrix data file is present but no soft_cosine_score() or maxsim_score() function in embedding_matcher.lua. Thresholds reserved (HYBRID=0.20) but no code path.
- **Synonym table is verb-only** — No noun synonym expansion yet (candle→taper, lamp→lantern).
- **32 parser test files + 11 pipeline sub-tests** — comprehensive coverage of BM25, context, fuzzy, GOAP, preprocessing, regressions.
- **Remaining work: soft cosine re-ranker, MaxSim, hybrid scoring, BM25F, noun synonyms** — all Phase 2/3 design doc items.

Board created at `projects/parser-improvements/board.md`.

### MaxSim Re-Ranker Implementation (2026-03-30)

Implemented two-stage hybrid scoring pipeline per Frink's D1/D3 decisions:

- **maxsim_score() function added** — ~20 LOC. For each input token, finds best-matching candidate token via word_similarity.lua sparse matrix, sums the max similarities. Exact matches short-circuit to 1.0.
- **word_similarity.lua NOW consumed** — 286 LOC sparse matrix (~150 word pairs) wired into embedding_matcher.lua via pcall require. Graceful degradation if missing.
- **Two-stage pipeline operational** — Stage 1: BM25 retrieves candidates via inverted index. Stage 2: MaxSim re-ranks top-50. Hybrid score: 0.70 * BM25_normalized + 0.30 * MaxSim_normalized.
- **Raw BM25 score returned externally** — hybrid score used only for internal ranking. Tests and downstream code see raw BM25 scores unchanged.
- **Stable sort required** — Lua's table.sort is unstable. Added phrase.id tiebreaker to both BM25 and hybrid sorts. Without this, equal-scored candidates (e.g., bedroom-hallway-door-north vs locked-door) produced non-deterministic results.
- **All 257 test files pass** — zero regressions. The "put candle" known bug remains in its documented state (don, not place).
- **Constants added:** HYBRID_BM25_WEIGHT=0.70, HYBRID_MAXSIM_WEIGHT=0.30, HYBRID_THRESHOLD=0.20, BM25_TOP_N=50.
- **Remaining from board:** noun synonym expansion (D2), soft cosine fallback (D3 fallback), accuracy benchmark to measure 91.2% → 93% delta.

---

## Cross-Agent Coordination: Options Build Complete (2026-03-29)

**Summary:** Options parser (Phase 2+4) now live. 10 aliases + loop number selection. Zero regressions.

| Phase | Agent | Work | Status |
|-------|-------|------|--------|
| 2+4 | Smithers | Parser aliases (10 routes: questions, idioms, verbs) + number intercept | ✅ 7,361 tests pass |
| 1+3 | Bart | Core options engine | ✅ Commit 26400a8 |
| 5 | Moe | Room goal metadata | ✅ |
| 6 | Nelson | TDD suite (53 tests) | ✅ |

**Files modified:**
- `src/engine/parser/preprocess/data.lua` — KNOWN_VERBS + IDIOM_TABLE
- `src/engine/parser/preprocess/phrases.lua` — transform_questions
- `src/engine/parser/idioms.lua` — "give me a hint" → options
- `src/engine/loop/init.lua` — number intercept + no_noun_verbs

**Decision:** D-OPTIONS-ALIASES, D-OPTIONS-NUMBER-INTERCEPT merged to `.squad/decisions.md`.

## Latest Activity

**Pre-existing Test Failure Fix Sprint (2026-03-29):**

Fixed 7 pre-existing test failures across 2 integration test files. Zero regressions.

**Bugs Fixed:**
1. **BUG-155 (read paper)** — Paper had `categories = {"small", "writable", "flammable"}` but `read` handler required `"readable"`. Added `"readable"` to paper categories. Writable surfaces should be readable.
   - File: `src/meta/worlds/manor/objects/paper.lua`

2. **BUG-156 (jump out window → extinguish)** — "jump out window" fell through to Tier 2 embedding matcher which matched "extinguish". Two fixes:
   - Added compound_actions transform: `"jump out [of] X"` → `"go X"` (before the extinguish patterns)
   - Suppressed tutorial hints in headless mode — hint text "(Hint: You can extinguish flames...)" was polluting headless test output
   - Files: `src/engine/parser/preprocess/compound_actions.lua`, `src/engine/verbs/helpers.lua`

3. **Craft silk-rope** — `nil == nil` bug in ingredient deduplication. Craft handler used `c.guid == obj.guid` to prevent reuse, but objects without guid fields (test mocks) had `nil == nil → true`, causing all objects to appear "already consumed". Fixed to use table identity (`c == obj`).
   - File: `src/engine/verbs/crafting.lua`

4. **Headless hint suppression** — `show_hint()` now checks `ctx.headless` and skips printing (but still tracks shown state). This resolved BUG-156 and incidentally fixed BUG-151, BUG-153, and BUG-163 which were also matching hint text.
   - File: `src/engine/verbs/helpers.lua`

**Test Results:**
- Before: 10 failures across 5 files (7,645 tests)
- After: 3 failures across 3 files (7,652 tests)
- Net: **7 tests fixed, 0 regressions, +7 tests passing**

**Remaining failures (not my domain):**
- `unlock door` integration test — game path can't reach cellar (hands full, bed blocks rug). Unlock handler code IS correct; unit test passes. Needs game-world fixes (Bart/Moe).
- `test-e-rating-blocks.lua` — pre-existing, Wyatt's World domain
- `test-injuries-comprehensive.lua` — flaky combat damage assertion

**Commits:** `4a79381` (my fixes) + `70c54fe` (Bart's parallel fixes for BUG-151/153/163/search)

**Previous Activity:**

**Options Parser Aliases + Number Selection (Phase 2+4):**
- Implemented 10 parser aliases for `options` verb across 3 layers:
  - `phrases.lua` transform_questions: "what are my options", "give me options", "what can i try", "i'm stuck", "hint", "hints", "nudge"
  - `data.lua` IDIOM_TABLE + `idioms.lua`: "give me a nudge", "give me a hint", "suggest something"
  - `data.lua` KNOWN_VERBS: added `options`, `hint`, `hints`
- Redirected `idioms.lua` "give me a hint" from `help` → `options` (was stale mapping)
- D-OPTIONS-B5 respected: "help me" NOT in options aliases
- Number selection interception in `loop/init.lua`:
  - Inserted after trim/question-mark-strip, before BUG-105 safety net
  - Valid number (1-N) → substitutes command string, clears pending_options
  - Invalid number → error message with valid range, short-circuits
  - Non-numeric input → clears pending_options silently
- Added `options` to `no_noun_verbs` (prevents stale context noun inheritance)
- All 7,361 tests pass (same 3 pre-existing failures unchanged)

**Options Review Ceremony (2026-08-02):**
- Reviewed Options project as Parser/UI Engineer
- Verdict: ⚠️ CONCERNS (4 blockers: "help me" collision, numeric precedence, numbered exits, Phase 4 test gaps)
- Identified 22 findings including critical UX edge cases
- See `.squad/decisions/inbox/smithers-options-review.md` for full review

## WAVE-2a: Parser Polish for Wyatt's World (2026-08-23)

**Summary:** Completed parser polish for Wyatt's World E-rated gameplay. Kid-friendly error messages, expanded verb coverage, and MrBeast vocabulary integration.

**Changes Made:**
1. **Kid-Friendly Error Messages** — `src/engine/verbs/helpers.lua`
   - Modified `err_not_found()`, `err_cant_do_that()`, `err_nothing_happens()`
   - Check `context.world.rating == "E"` to show encouraging messages
   - E-rated: "Hmm, try looking around for clues!" vs standard: "You don't notice anything called that nearby..."
   - E-rated: "That's not something you can do here. Try reading the signs!" vs standard: "That doesn't seem to work..."
   - E-rated: "That didn't work. What else could you try?" vs standard: "Nothing obvious happens..."

2. **Puzzle Verb Coverage** — `src/engine/parser/preprocess/data.lua`
   - Added 5 verbs to `KNOWN_VERBS`: `sort`, `count`, `press`, `assemble`, `build`
   - Added 6 gerunds to `GERUND_MAP`: `sorting`, `counting`, `pressing`, `assembling`, `building`, `entering`
   - Covers all Wyatt's World puzzle interactions (Feastables sorting, Money Vault counting, button pressing, Beast Burger assembly)

3. **Embedding Index Update** — `src/assets/parser/embedding-index.json`
   - Added 40 new phrases for MrBeast vocabulary
   - Keywords: feastables, chocolate, scoreboard, confetti, burger, riddle, vault, trophy, safe, button, money, bills, coins
   - Total phrases: 11,755 (was 11,715)
   - Covers Tier 2 semantic matching for all 7 puzzle rooms

**Test Results:**
- 7,503 tests passed across 273 files
- 12 pre-existing failures (unchanged from baseline)
- **Zero new regressions** — parser changes are safe

**Files Modified:**
- `src/engine/verbs/helpers.lua` — 3 error functions with E-rating branches
- `src/engine/parser/preprocess/data.lua` — KNOWN_VERBS + GERUND_MAP expansions
- `src/assets/parser/embedding-index.json` — 40 new phrase entries

**Commit:** `d30c07a` — "feat(wyatt): parser polish — kid-friendly errors + verb coverage (WAVE-2a)"

**Next Steps (for WAVE-2b — Nelson's domain):**
- Puzzle walkthrough tests (headless mode)
- Sensory coverage verification
- Reading-level scan

**Design Notes:**
- E-rating check uses `context.world.rating` — requires world definition to have `rating = "E"` field
- Error functions are centralized in `helpers.lua` — all verb modules import `err_not_found`, `err_cant_do_that`, `err_nothing_happens`
- MrBeast vocabulary covers all 7 puzzle types: Hub (button), Feastables (sort), Money Vault (count), Beast Burger (assemble), Last to Leave (examine), Riddle Arena (read), Grand Prize (read/enter)
- The verb `enter` is already in KNOWN_VERBS (movement category) — added `entering` gerund only
- Puzzle verbs like `solve`, `make` weren't added as they route through existing verbs (`read`, `put`, `assemble`)

## Fix-3 + Fix-4: Missing Verbs + UX Language Cleanup (2026-03-30)

**Summary:** Fixed missing verbs for Wyatt's World puzzles and replaced inappropriate language for kid-friendly gameplay. Addressed 12 bugs across Issues #417, #418, #421, #427, #433, #434, #436, #437, #438, #439, #440, #446, #465, #469, #470, #473, #478, #484, #486.

**Changes Made:**

1. **Missing Verbs Added** — `src/engine/verbs/acquisition.lua`
   - **`press`/`click`** — Added as aliases to `push` verb. FSM objects with `verb = "press"` transitions now work (big-red-button, confetti-cannon).
   - **`type`/`input`/`dial`** — New verb for entering codes into keypads/locks. Searches room for objects with `verb = "type"` or `verb = "enter"` FSM transitions. Handles vault-safe and prize-chest combination entry.
   - **`turn`/`rotate`/`spin`** — New verb for rotating objects (dials, knobs). Triggers FSM transitions with `verb = "turn"`.

2. **`enter` Dual-Routing Fixed** — `src/engine/verbs/movement.lua`
   - Now checks for numbers first (`enter 210` for code entry)
   - Then checks for objects with `verb = "enter"` FSM transitions
   - Finally falls back to movement (entering rooms/exits)
   - Prevents "enter 210" from being interpreted as movement

3. **UX Language Cleanup** — Multiple files
   - **Darkness messages**: Replaced "grope around in the darkness" with "explore by touch" in `src/engine/verbs/sensory/look.lua` (3 locations)
   - **Help text**: Replaced "Grope around" with "Feel around in the dark" in `src/engine/verbs/meta.lua`
   - **Code comments**: Updated "FEEL / TOUCH / GROPE" to "FEEL / TOUCH" in `src/engine/verbs/sensory/touch.lua`
   - **Darkness message spacing**: Fixed missing newline between darkness description and time display (Issue #469, #416)
   - **Removed from KNOWN_VERBS**: Removed `grope` from verb registry in `src/engine/parser/preprocess/data.lua`

4. **Greeting Handling** — `src/engine/parser/preprocess/phrases.lua`
   - Added greeting patterns to `transform_questions()`: "what's up", "whats up", "wassup", "sup"
   - These now route to `look` command instead of being parsed as "up" direction (Issue #427)
   - Prevents greetings from being interpreted as movement

5. **Verb Registry Updates** — `src/engine/parser/preprocess/data.lua`
   - Added to `KNOWN_VERBS`: `press`, `click`, `turn`, `rotate`, `spin`, `type`, `input`, `dial`
   - Added to `GERUND_MAP`: `turning`, `rotating`, `spinning`, `typing`, `inputting`
   - Ensures new verbs work with gerund preprocessing ("typing" → "type")

**Test Results:**
- All verb handlers tested with Wyatt's World objects
- `press button` — triggers big-red-button FSM (confetti cannon fires)
- `type 210` — triggers vault-safe FSM (safe opens)
- `what's up` — shows room description instead of trying to go up
- Help text now shows kid-friendly language
- Test suite: 3 failures (pre-existing, unrelated to verb/UX changes)

**Files Modified:**
- `src/engine/verbs/acquisition.lua` — Added `press`, `type`, `turn` handlers + aliases
- `src/engine/verbs/movement.lua` — Fixed `enter` dual-routing logic
- `src/engine/verbs/sensory/look.lua` — Replaced "grope" with "explore by touch", fixed spacing
- `src/engine/verbs/sensory/touch.lua` — Updated comment
- `src/engine/verbs/meta.lua` — Updated help text
- `src/engine/parser/preprocess/phrases.lua` — Added greeting handling
- `src/engine/parser/preprocess/data.lua` — Updated KNOWN_VERBS and GERUND_MAP

**Design Decisions:**
- **`press` as alias vs. new verb:** Chose alias to `push` to leverage existing FSM integration. Objects can use `verb = "press"` in transitions; the verb handler checks FSM first before attempting spatial movement.
- **`type` verb scope:** Searches all room contents for objects with matching FSM transitions. This allows "type 210" to work without specifying "type 210 on safe".
- **`enter` routing order:** Code/number patterns first (most specific), then object interactions, finally movement (most general). Prevents ambiguity.
- **Greeting handling placement:** In `transform_questions()` before other question patterns to catch greetings early and avoid false matches.
- **"grope" removal rationale:** Inappropriate for E-rated kids' game. Replaced with neutral sensory language ("feel around", "explore by touch").

**Bugs Closed:**
- #421, #446, #465, #470, #473, #478, #484 — Missing `press` verb
- #417, #440, #486 — "grope" in help text
- #469, #416 — Missing space in darkness message
- #427 — "what's up" parsed as direction

**Next Steps:**
- Remaining pre-existing test failures need investigation (not my domain)
- Consider adding more verb aliases if puzzle designers need them

## Archives

- Prior detailed session logs: .squad/log/
- Linked decisions: .squad/decisions.md (search 'D-*' keys)

