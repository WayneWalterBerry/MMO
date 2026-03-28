# Smithers — History

## Project Context
- **Project:** MMO text adventure game in pure Lua (REPL-based, lua src/main.lua)
- **Owner:** Wayne "Effe" Berry
- **Architecture:** 8 Core Principles (code-derived mutable objects, FSM-driven behavior, sensory space, generic mutation via Principle 8)
- **Reference Model:** Dwarf Fortress (property-bag architecture, emergent behavior from metadata)
- **Stack:** Pure Lua, no external dependencies
- **My Focus:** UI layer (text output, presentation, player feedback) and Parser pipeline (Tiers 1-6, verb resolution, disambiguation, GOAP)

## Onboarding
- Hired 2026-03-21 as UI Engineer in Engineering Department
- Need to read all architecture docs, newspapers, and directives to understand UI scope
- Primary output: docs/architecture/ui/ documentation

## Core Context (Archived Sessions Summary)

This section summarizes 50+ prior sessions covering UI architecture, web deployment, parser pipeline optimization, and web performance. For detailed session logs, see .squad/log/.

**Key Accomplishments (Cumulative):**
- Built 3x UI architecture documentation (README, text-presentation, parser-overview)
- Deployed three-layer web architecture (bootstrapper.js → engine.lua.gz → JIT-loaded meta)
- Fixed web performance: 16MB bundle → 135KB initial load
- Implemented parser phrase-routing refactor (7-stage pipeline)
- Fixed 5 parser bugs (issues #35-39) with Pass038 phrase ordering
- 45+ test files, 880+ total tests passing
- Web site live at github.io/play/ with cache-busting strategy

**Parser Pipeline Highlights:**
- Tier 1: Exact verb dispatch (70% coverage, <1ms)
- Tier 2: Phrase similarity with token overlap (90% cumulative, ~5ms)
- Tier 3: GOAP planning with prerequisite chaining (98% cumulative, ~100ms)
- Tier 4-5: Context window & SLM fallback (designed, not yet deployed)

**Web Architecture:**
- Fengari integration for browser playtest
- Synchronous XHR with HTTP caching (ETag/Last-Modified)
- Progressive loading with boot status messages
- Mobile-first dark theme terminal UI
- Cache-busting via build timestamp injection

---

## Archives

- `history-archive-2026-03-20T22-40Z-smithers.md` — Full archive (2026-03-18 to 2026-03-20T22:40Z): UI architecture, parser pipeline implementation, web performance optimization, 880+ tests

- `history-archive.md` — Entries before 2026-07-13 (2026-03-23 to 2026-03-29)

## Learnings

### Phase 4 WAVE-3: Stress Narration Integration

**What shipped:** Full stress narration UI for the WAVE-3 stress injury system.

**Task 1 — Status Display:** Modified `src/engine/ui/status.lua` to show the capitalized stress level name (Shaken/Distressed/Overwhelmed) on the status bar's right side, separated from health by a pipe. No clutter when unstressed — stress indicator only appears at or above the "shaken" threshold.

**Task 2 — Stress Event Narration:** Added trigger-specific narration (`"The sight of death shakes you."`, `"A wave of terror washes over you..."`, `"The gore turns your stomach."`), level-crossing narration (`"Your hands begin to tremble."`, `"Your breathing quickens..."`, `"Panic overwhelms you."`), and cure narration (`"With rest and safety, the panic slowly fades."`). All print via `print()` matching existing injury narration patterns.

**Task 3 — Integration:** Extended Bart's skeleton `add_stress()` to include narration + level tracking (`player.stress_level`, `player.stress_effects`), updated `cure_stress()` to accept `ctx` for safe-room checks and print cure message, enhanced `injuries.list()` to display stress description alongside physical injuries. Fixed `load_stress_def()` to check `_cache` (test injection path via `register_definition`), and forward-declared the function so `injuries.list()` can call it.

**Key pattern:** Stress narration follows the same `print()` passthrough used by rabies/venom infliction messages and injury tick messages. The WAVE-0 narration pipeline design (`ctx.narrate()`) remains the future migration target but is not needed for WAVE-3 scope.

**Files modified:**
- `src/engine/injuries/init.lua` — Narration tables, `add_stress` narration, `cure_stress` narration + ctx param, `injuries.list` stress display, forward-declared `load_stress_def`
- `src/engine/ui/status.lua` — Stress indicator in status bar right side

**Files created:**
- `test/stress/test-stress-narration.lua` — 11 tests covering trigger narration (3), level-change narration (4), cure narration (1), status bar (2), injuries list (1)

**Test results:** All 19 stress tests pass (8 pre-existing + 11 new). Full suite: 1 pre-existing failure (`verbs/test-combat-verbs.lua`), zero new regressions.


### Phase 4 WAVE-0: Embedding Collision Audit + Narration Pipeline Design

**What shipped:** Two WAVE-0 deliverables for Phase 4 pre-flight.

**Embedding Collision Audit:** Scanned 11,131 embedding phrases and all object keyword lists for 10 Phase 4 keywords. Found 3 HIGH-risk collisions (knife/butcher-knife, rope/silk-rope, bandage/silk-bandage — each has 117 existing phrases blocking the bare keyword), 3 MEDIUM-risk (bone/gnawed-bone keyword overlap, meat 4-way ambiguity, hide verb/noun homograph), and 4 clear entries (web, butcher, craft, silk).

**Key rule established:** Phase 4 objects MUST use adjective-first disambiguation (`{adjective} {noun}` as primary keyword). Bare single-word keywords are reserved for the FIRST object of that type. Critical finding: gnawed-bone.lua claims "wolf bone" keyword which directly collides with incoming wolf-bone — must be removed when wolf-bone ships.

**Narration Pipeline Design:** Designed `ctx.narrate(source, type, message, opts)` convention with 10 sources, 8 message types, 4-stage pipeline (Collect → Batch → Format → Display), and incremental migration strategy (stub in WAVE-1, full pipeline by WAVE-3). Documented at `docs/architecture/ui/narration-pipeline.md`. Pending Bart co-sign.

**Files created:**
- `.squad/decisions/inbox/smithers-embedding-audit.md` — Full audit with per-keyword analysis and action items
- `docs/architecture/ui/narration-pipeline.md` — Narration pipeline interface design


### P1-P5 Tier 2 Parser Improvements— 144/147 (98.0%) Benchmark

**What shipped:** Five parser improvements to the Tier 2 embedding matcher, taking the benchmark from 134/147 (91.2%) to 144/147 (98.0%). Branch: `squad/parser-p1-noun-gate`.

**P1 (Noun validation gate, +5):** Added `token_matches()` and `noun_overlap()` helpers. Classifies input tokens into verb-like vs noun-like using a `verb_tokens` set (union of canonical verbs, phrase first words, synonym keys). Skips phrases where no input noun token matches any phrase token. Fuzzy matching (Levenshtein) prevents "take candel" regression.

**P2 (Verbose input truncation, +1):** For inputs >5 tokens after stop-word removal, keeps top 5 by known-noun priority then IDF. Built `known_noun_tokens` set from all phrase noun_tokens plus hyphen-component parts.

**P3 (Question transform, +1):** "what is X" → "examine X" in both Tier 2 (`match()`) and Tier 1 (`preprocess.lua`, `questions.lua`).

**P4 (Noun exactness tiebreaker, +1):** Exact noun match (score=2) wins ties. Noun match bonus (+0.5 in BM25) helps when IDF scores are nearly identical but user names the exact object.

**P5 (Adjective-only guard, +2):** Generic adjectives (small, big, large, colors) → nil. Material/descriptive adjectives (heavy, dirty, wooden) kept since they identify specific objects.

**Key learnings:**
- IDF values for many tokens are nearly identical (matchbox=4.541, dirty=4.549, dusty=4.541). Pure IDF sorting doesn't reliably distinguish nouns from adjectives — need `known_noun_tokens` priority.
- Verb preservation in truncation can HURT: keeping "examine" gives both correct and incorrect phrases equal verb boost, then the wrong adjective wins by 0.008 IDF. Better to let IDF competition naturally drop the verb when nouns are more discriminating.
- Noun match bonus (+0.5) is more robust than epsilon-based tie detection. It integrates into scoring rather than requiring approximate equality checks.
- Branch switching by other agents can lose uncommitted work. Commit immediately after verifying benchmark scores.
- Stop words "something/anything/everything" needed for "get something small" → nil (P5 combo).
- The `goto continue` pattern works well for noun gate skip logic in Lua 5.2+.


### Issue #174: SLM Embedding Index Overhaul (Sections 1-4)

**What shipped:** Full embedding index overhaul with BM25 scoring, synonym expansion, inverted index, and 56 new object entries. 51 TDD tests pass, 131 total test files pass, zero regressions.

**Section 1 (Strip vectors):** Already done on main — slim index (883KB, no vectors) exists at `src/assets/parser/embedding-index.json`. Full 15MB archive at `resources/parser/embedding-index-full.json` and `resources/archive/`. Build script (`scripts/build_embedding_index.py`) already outputs both.

**Section 2 (Audit staleness):** Found 56 objects with zero embedding coverage out of 87 total. Added all 56 missing objects (6,552 new phrases). Index grew from 4,579 → 11,131 phrases. Key objects added: mirror, drawer, chest, silver-dagger, torch, barrel, skull, sarcophagus, crowbar, rope-coil, trousers, oil-flask, wine-bottle, bear-trap, tattered-scroll, bronze-ring, and 40 more.

**Section 3 (Phrase variants):** Added synonym mappings: gimme→get, hold→get, lift→get, peer→look, use→ignite. Existing index already had phrase-level variants (gimme/hold/lift/peer/check-out/inspect) for all 40 original nouns; these now also cover the 56 new nouns. Removed "check"→"examine" from synonyms to preserve "check out" → look routing.

**Section 4 (Tiebreaker):** `prefer_base_state()` function already existed inline. Refactored to a clean extracted function with `STATE_SUFFIXES` table. Works for all state variants: `-lit`, `-open`, `-broken`, `-closed`. 8 tiebreaker tests pass.

**Architecture changes:**
- `src/engine/parser/embedding_matcher.lua` — Upgraded from Jaccard-only to BM25+inverted-index with Jaccard fallback. Added synonym expansion, IDF-aware typo correction, extracted tiebreaker function.
- `src/engine/parser/bm25_data.lua` — Restored (was on feature branches but missing from main). Regenerated: 244 tokens, avgdl=3.67.
- `src/engine/parser/synonym_table.lua` — Restored and updated with 3 new mappings (gimme, hold, lift, use→ignite), peer→look fix.

**Key learnings:**
- The bm25_data.lua and synonym_table.lua files existed on feature branches (commit 82cf1d8, c76688b) but were never merged to main. This caused the matcher to silently fall back to Jaccard scoring, missing the Phase 1 improvements entirely on main.
- BM25's IDF-aware typo correction is critical — without it, tokens like "gimme" (5 chars) get aggressively corrected to verbs like "time" (dist=2).
- The inverted index candidate retrieval is a huge performance win: instead of scoring 11,131 phrases for every input, we only score phrases that share at least one token with the input (typically <500).
- Door disambiguation is hard: 4 door objects compete for "door". Players need to use adjectives ("oak door", "trap door") to disambiguate. The embedding index uses the object's display name, not its file ID.

### 2026-07-20: Issue #106 Phase 3 — Prime Directive Tiers 1-5 Implementation

**What shipped:** All 5 Prime Directive parser tiers, passing 73/73 TDD tests with zero regressions across 129 test files.

**New modules:**
- `src/engine/parser/idioms.lua` — 55+ natural language idioms (Tier 3)
- `src/engine/parser/questions.lua` — Priority-ordered question→command mapping (Tier 1)
- `src/engine/errors.lua` — 7-category structured error template system (Tier 2)

**Enhanced modules:**
- `src/engine/parser/context.lua` — Command repeat, direction history, recency scoring, "the other one" disambiguation (Tier 4)
- `src/engine/parser/fuzzy.lua` — Confidence scoring (0.0-1.0), context-integrated scoring, 4-char typo tolerance (Tier 5)

**Key learnings:**
- Data-driven pattern tables with priority ordering prevent ambiguity between similar patterns (e.g., "where am I bleeding" vs "where am I").
- Typo scoring formula needs to ensure all accepted Levenshtein matches meet the minimum confidence threshold. Changed from `4 - dist` to `max_dist - dist + 3` so distance-2 matches still score ≥ 0.3 confidence.
- The 4-char typo threshold change (distance 0 → 1) required updating the existing test-fuzzy-nouns.lua, which was the only regression.
- All 5 tiers are standalone modules testable in isolation — no cross-module integration was needed for the TDD tests to pass.
- Implementation order (3→1→2→4→5) was correct: additive-only tiers first, stateful changes last.

### 2026-07-19: Issue #167 — Meta-check V2 (full meta type coverage)

**What shipped:** Extended `scripts/meta-check/check.py` with ~160 new validation rules covering all 4 remaining meta types: templates (27 rules), injuries (69 rules), materials (24 rules), and levels (41 rules), plus 11 cross-reference checks. Fixed MAT-02 false positives by reading material names from `src/meta/materials/*.lua` filenames instead of parsing the engine registry file.

**Key learning:** The Lua parser already handled nil values correctly, which meant material fields like `melting_point = nil` were properly distinguished from missing. Template/level GUIDs use bare format while injury/object GUIDs use braced format — established convention. The ~160 rule IDs match Lisa's V2 acceptance criteria exactly.

**Files changed:** `scripts/meta-check/check.py`, `docs/meta-check/rules.md`, `docs/meta-check/schemas.md`

**Tests:** 130 files scanned, 0 errors, 0 regressions.

### 2026-07-19: Issue #106 — Prime Directive Architecture Doc (Tiers 1-5)

**What shipped:** `docs/architecture/engine/prime-directive-architecture.md` — full technical architecture for all 5 parser enhancement tiers: Question Transforms (Tier 1), Error Message Overhaul (Tier 2), Idiom Library (Tier 3), Context Window Expansion (Tier 4), and Fuzzy Noun Resolution Enhancement (Tier 5).

**Key learnings:**
- The existing preprocess.lua pipeline is already table-driven (11 stages) and well-structured. Tiers 1 and 3 enhance existing stages (transform_questions, expand_idioms) by extracting data tables to separate backing modules (questions.lua, idioms.lua). No pipeline rewrite needed.
- context.lua is more mature than the roadmap suggested — push/peek/discovery tracking already works. Tier 4 is mostly additive ("again" support, verb history, context-as-disambiguation-signal).
- fuzzy.lua already has material matching (30 adjectives), property matching (7 adjectives), Levenshtein with length-ratio guard, and disambiguation prompts. Tier 5 enhancement is confidence normalization + context integration, not a rewrite.
- Tier 2 (error messages) is the most scattered change — ~50 error sites across verb handlers. A central `errors.lua` template system reduces the per-site change to one function call.
- Implementation order: Tier 3 → 1 → 2 → 4 → 5, driven by risk (additive-only first, stateful changes last).

**Files created:** `docs/architecture/engine/prime-directive-architecture.md`

**Scope:** ~300 lines new code (3 modules), ~170 lines modified, ~450 lines new tests across 5 test files.


### 2026-07-18: Issue #168 — Compound commands only execute first part

**What shipped:** Two fixes so compound commands like "get candle, and light it" execute both parts. (1) Enhanced `split_commands` in preprocess.lua to handle `, and` and `and then` as compound separators, stripping leftover "and" prefixes from segments. (2) Added `split_compound` — a verb-aware ` and ` splitter that only splits when the word after "and" is a recognized verb. Prevents breaking multi-object commands like "get candle and matchbox".

**The fix (two layers):**
1. **split_commands** (`preprocess.lua`): Added ` and then ` as a compound separator (checked before ` then `). After splitting on commas, strips leading "and " from each segment. This handles ", and light it" → "light it".
2. **split_compound** (`preprocess.lua`): New function with a static `KNOWN_VERBS` table (~100 verbs). Iteratively finds ` and ` positions and only splits when the next word after "and" is in KNOWN_VERBS. Replaces the naive ` and ` loop in the game loop.
3. **Game loop** (`loop/init.lua`): Replaced 20-line naive ` and ` while-loop with a 4-line call to `preprocess.split_compound()`.

**Key learning:** Pronoun resolution ("it" → last object) already worked via `context.last_noun` set after each sub-command executes (line 492 of loop). The bug was entirely in splitting — "and light it" was arriving as verb="and" which has no handler. The KNOWN_VERBS heuristic is the right trade-off: it's a static set that doesn't need runtime context, covers all registered handlers, and correctly distinguishes "take sword and shield" (no split) from "take sword and examine shield" (split).

**Files changed:** `src/engine/parser/preprocess.lua`, `src/engine/loop/init.lua`, `test/parser/test-compound-commands.lua` (new, 29 tests)

**Tests:** 29 new tests, 0 regressions. 3 pre-existing failures in unrelated files (sack-capacity, light-burn-redirect, light-fire-source) unchanged.

### 2026-07-18: Issue #170 — Exit door resolution + lock handler

**What shipped:** Three fixes for door interaction: (1) FSM failure messages now explain WHY a door can't be opened (e.g., "A heavy oak door is barred. It won't budge.") instead of generic "You can't open that." Uses on_push from current FSM state if available. (2) Added `lock` handler — mirrors unlock, searches exits by keyword, auto-closes open doors, validates key_id. (3) 16 TDD tests covering door object intercepts, exit-only open/close/lock/unlock with key, exit keyword resolution.

**The fix (two layers):**
1. **Open handler FSM failure** (`containers.lua`): When no "open" transition from current state, checks state's `on_push` field first (Principle 8 — objects declare behavior). Falls back to "{Name} is {state}. It won't budge." Generic message only when state is "closed" or no state info.
2. **Lock handler** (`containers.lua`): New `handlers["lock"]` mirrors `unlock` — iterates exits with `exit_matches`, validates key, auto-closes open doors before locking.

**Key learning:** Exit-only doors (no coexisting instance object) already worked — open/close/unlock handlers all have exit fallback loops that fire when `find_visible` returns nil. The bug was specifically about rooms where a door FSM OBJECT coexists with an exit definition. The FSM path intercepts, fails (no transition), and returns before the exit loop runs. The fix improves the error message quality rather than changing the control flow, because the FSM and exit represent the same physical door and should stay synchronized.

**Files changed:** `src/engine/verbs/containers.lua`, `test/verbs/test-door-resolution.lua` (new, 16 tests)

**Tests:** 16 new tests, 0 regressions. Pre-existing failure in injuries/test-weapon-pipeline.lua (dagger damage 12 vs expected 8) is unrelated.

### 2026-07-18: Issues #169 + #172 — Fire.lua light handler broken

**What shipped:** Two related fixes in the light handler. (1) "light candle" now finds fire_source tools in the player's hands automatically, and "light candle with match" preserves the explicit tool noun. (2) "light sack" on a flammable non-light-source now redirects to the burn handler instead of refusing.

**The fix (three layers):**
1. **Game loop** (`loop/init.lua`): Extended tool_noun extraction to cover light/ignite/burn verbs. Previously "with X" was stripped but discarded; now saved as `context.tool_noun` (same pattern as open/pry from #49).
2. **Light handler** (`fire.lua`): Added `find_fire_source()` helper that checks: (a) explicit `ctx.tool_noun`, (b) direct hand scan for `provides_tool` or `has_striker`, (c) fallback to `find_tool_in_inventory` + `find_visible_tool`. Follows the same hand-scanning pattern as `handle_self_infliction()` for stab weapons. Applied to both FSM and mutation requires_tool paths.
3. **Light handler fallback** (`fire.lua`): Before printing "You can't light that", checks material flammability ≥ 0.3 and redirects to `handlers["burn"]`. No recursion risk — burn handler already redirects TO light for objects with light FSM states, and the light handler only redirects TO burn when no light states exist.

**Key learning:** The "with X" prepositional parsing was inconsistent — open/pry saved tool_noun, but light/ignite/burn only stripped it. The hand-scanning pattern from self-infliction (#49) is the right model for any "find tool the player is holding" scenario. BURN_THRESHOLD moved to top of M.register so both light and burn handlers share it.

**Files changed:** `src/engine/verbs/fire.lua`, `src/engine/loop/init.lua`

**Tests:** 121 existing test files, 0 regressions.

### 2026-07-17: Issue #119 — Match no-relight on extinguish

**What shipped:** Spent matches can no longer be relit. The `light` handler in `fire.lua` now checks for terminal FSM states before attempting transitions. A spent match yields: "The match is spent. You can't relight it." The `strike` handler already had this check.

**The fix (one layer):**
1. **Light handler** (`fire.lua`): Added terminal-state guard between the "already lit" check and the FSM transition search. If `obj.states[obj._state].terminal` is true, prints spent message and returns early. This is generic — any FSM object with a terminal state gets caught, not just matches.

**Key learning:** The match FSM was already correct (`unlit → lit → spent` with `terminal = true` on spent). The `strike` handler already caught spent matches. Only the `light` handler was missing the terminal check — it fell through to a generic "You can't light that" message instead of explaining WHY. The `fsm.get_transitions()` function filters by current state, so no transitions were found from "spent", but the error message lacked context.

**Files changed:** `src/engine/verbs/fire.lua`, `test/verbs/test-match-no-relight.lua` (new)

**Tests:** 5 new tests covering full lifecycle (strike → lit, extinguish → spent, light spent → error, strike spent → error, full lifecycle chain). 15 existing fire tests unchanged. 0 regressions.

### 2026-07-14: Issue #111 — PUSH/LIFT/SLIDE verb coverage

**What shipped:** Full spatial movement verb coverage for furniture and heavy objects. PUSH, LIFT, SLIDE, MOVE verbs now support puzzle chains (push bed → reveals rug, lift rug → reveals trap door). Added aliases heave, drag, nudge, and preprocess transforms for compound phrases.

**Three layers of change:**
1. **Verb handlers** (`acquisition.lua`): SLIDE gets own handler (was aliased to MOVE) so it passes `"slide"` as verb for distinct narrative. LIFT strips trailing `"up"` ("lift rug up" works). New aliases: `heave→lift`, `drag→move`, `nudge→push`.
2. **Helper** (`helpers.lua`): `move_spatial_object` now checks `{verb}_message` (e.g. `slide_message`, `lift_message`) before `move_message` fallback. Added `on_move(self, ctx, verb)` callback support for objects declaring custom spatial movement behavior.
3. **Preprocess** (`preprocess.lua`): Gerund mappings: `lifting`, `sliding`, `shoving`, `heaving`, `dragging`, `nudging`. Compound transforms: `heave X up` → `lift X`, `drag X across/along` → `move X`, `shove/nudge X aside/away/over` → `push X`.

**Key learning:** The existing `move_spatial_object` helper was already well-structured for the covering/underneath reveal pattern. The main gaps were: (a) `slide` was aliased to `move` which lost the verb name in the fallback message, (b) the message lookup was hardcoded to only check `push_message`, now generalized to `{verb}_message`, and (c) no `on_move` callback for custom object behavior. The verb-specific message key pattern (`push_message`, `slide_message`, `lift_message`) keeps objects declarative per Principle 8.

**Files changed:** `src/engine/verbs/acquisition.lua`, `src/engine/verbs/helpers.lua`, `src/engine/parser/preprocess.lua`, `test/verbs/test-spatial-verbs.lua`

**Tests:** 46 new tests. 112 test files passing, 0 regressions.

### 2026-07-26: EP3 — Unified Effect Processing Pipeline

**Task:** Implement `src/engine/effects.lua` per Bart's architecture doc (D-EFFECTS-PIPELINE).

**What was built:**
- `effects.process(raw, ctx)` — main dispatcher. Normalizes input, runs before interceptors, dispatches to handler by type, runs after interceptors.
- `effects.normalize(raw)` — converts legacy string effects (e.g. `"poison"`) and single tables to normalized arrays. Critical for backward compat.
- `effects.register(type, handler_fn)` — plugin pattern. New effect types register without modifying pipeline.
- Before/after interceptor pattern (`add_interceptor`, `clear_interceptors`) — empty day-one, infrastructure ready.
- 5 built-in handlers: `inflict_injury`, `narrate`, `add_status`, `remove_status`, `mutate`.

**Verb handler changes (surgical):**
- **Drink handler** (~line 4840): Replaced 20-line inline `"poison"` check + `injuries.inflict()` with `effects.process(trans.effect, ctx)`. Now handles any structured effect table, not just hardcoded poison string.
- **Taste handler** (~line 2146): Replaced 15-line inline death sequence (including `os.exit(0)`) with `effects.process(obj.on_taste_effect, ctx)`. Taste now routes through injury system properly.

**Critical finding:** The taste handler's `os.exit(0)` path was actually unreachable for poison-bottle because `apply_state()` copies the structured table `{ type = "inflict_injury", ... }` to `obj.on_taste_effect`, so `obj.on_taste_effect == "poison"` was always false. The structured format from Flanders was silently making the old code a no-op. The pipeline now properly processes the structured table.

**Test results:** 116/116 poison bottle tests pass. 1361/1362 full suite pass (1 pre-existing failure in search auto-open, unrelated). Zero regressions.

**Key architectural insight:** The FSM `apply_state()` function copies all state-level properties to the top-level object on transition. This means `states.open.on_taste_effect` becomes `obj.on_taste_effect` after transitioning to "open". Verb handlers read top-level fields, which is correct — they don't need to dig into FSM state definitions.

---

### #43/#44 (P0/P1): Matchbox unfindable in dark bedroom
**Root cause:** Nightstand `categories` was `{"furniture", "wooden"}` — missing `"container"`. The search traverse code at line 330 checks `containers.is_container(parent)` before allowing peek into inaccessible surfaces. Without `"container"`, the nightstand's drawer (inside surface with `accessible = false`) was silently skipped.

**Fix:** Added `"container"` to nightstand.lua categories. The nightstand IS a container — it has a drawer. This lets `containers.is_container()` return true, enabling search to peek into the drawer and find the matchbox via deeper-match logic.

### #40 (P1): Contradictory "nothing there" + "Inside you find..."
**Root cause:** The search queue includes both an object entry and surface entries for the nightstand. The object entry was processed as a regular non-container object → generated "nothing there" via `narrator.step_narrative()`. Then surface entries reported contents normally.

**Fix:** Added early return in `traverse.step()` for objects with surfaces: suppress narration for undirected search (surfaces handle it), still check target match for targeted search. 20 lines added to traverse.lua.

### #42 (P2): "sleep to dawn" not recognized
**Root cause:** Verb handler only matched `noun:match("until%s+dawn")`. Natural English variants "to", "til", "till" weren't handled.

**Fix:** Added 3 idiom transforms to `preprocess.lua` IDIOM_TABLE: `sleep to/til/till X → sleep until X`. These normalize before the verb handler runs.

### Tests: 21 new regression tests
- `test/search/test-search-playtest-bugs.lua` — 11 tests for #40/#43/#44
- `test/parser/test-sleep-transforms.lua` — 10 tests for #42
- Full suite: 48/48 files pass

### Key Learnings
1. **Surface-based furniture needs "container" category** — without it, inaccessible surfaces are invisible to search. Any furniture with a drawer/compartment needs this.
2. **Object entries vs surface entries in search queue** — furniture with surfaces generates BOTH, creating duplicate/contradictory narration. The fix suppresses the object entry.
3. **Parser idiom transforms are the cleanest way to handle natural language variants** — no verb handler changes needed for #42.

---

### Root Cause (Third Recurrence)

**The bug was NEVER in the search/container code.** It was in the verb handler's scope detection. The Tier 5 fuzzy resolver (`engine/parser/fuzzy.lua`) matched "match" to the rug's keyword "mat" via Levenshtein distance 2 (within threshold for 5-letter words). The search handler then scoped an undirected search to the rug → found nothing.

**Chain:** "search for a match" → preprocess → "search match" → handler calls `find_visible("match")` → exact match fails → Tier 5 fuzzy: levenshtein("match", "mat")=2 ≤ threshold=2 → returns rug → handler does `search(nil, rug.id)` → "Nothing interesting."

### Fix

`ctx._exact_only = true` flag in the search handler suppresses fuzzy resolution during scope detection. The `find_visible` wrapper checks `ctx._exact_only` and skips Tier 5 when set.

- `src/engine/verbs/init.lua` lines 2012-2019: Set flag before `find_visible`, clear after
- `src/engine/verbs/init.lua` line 704: Check flag in fuzzy gate

### Tests

`test/search/test-search-fuzzy-scope-bug146.lua` — 6 regression tests:
1. Targeted search for 'match' finds matchbox (not rug)
2. Deeper-match finds actual match inside matchbox
3. Search does NOT scope-search the rug
4. Search works in darkness (light_level=0)
5. Levenshtein precondition verified
6. Exact scope search still works

**53/53 test files pass.**

### Key Learning

4. **Fuzzy noun resolution (Tier 5) must NOT participate in search scope detection.** The search handler's scope-vs-target heuristic ("is this noun a visible object?") needs exact matching only. Fuzzy false positives (e.g., "match"→"mat" Levenshtein 2) cause catastrophic misrouting — the entire search gets scoped to the wrong object. Use `ctx._exact_only` flag pattern for any handler that needs exact-only noun resolution.

5. **Why it kept recurring:** Each previous fix (#43/#44) addressed the search engine's container/surface traversal logic, which was correct all along. The real bug was in the verb handler layer ABOVE the search engine. The mismatch between where the bug appeared (search results) and where it lived (verb handler scope detection) made it invisible to targeted fixes.

---

### Problem
Search results dumped in a block. Player should see items appear one-by-one with game time advancing per item.

### Fix
- `src/engine/search/init.lua`: Each `search.tick()` now advances `ctx.time_offset` by `MINUTES_PER_STEP / 60` hours (1 game-minute per step), matching the sleep verb convention
- Added `search.set_on_tick(fn)` hook for future clock system integration — callback receives `(ctx, step_number, queue_entry)` per tick
- Search was already tick-based (one queue entry per `search.tick()` call), so output was already line-by-line; the missing piece was clock advancement

### Tests
`test/search/test-search-streaming.lua` — 14 regression tests:
- Line-by-line output verification (2 tests)
- Clock advancement per step (4 tests)
- on_tick hook behavior (3 tests)
- Backward compatibility (5 tests)

### Key Learning
6. **Time advancement follows the sleep pattern**: `ctx.time_offset += hours`. The presentation layer reads this offset in `get_game_time(ctx)`. Any verb that "takes time" should increment `ctx.time_offset`.

---

## Systemic Parser/Resolver Overhaul — #66 #67 #69 #70 #71 (2026-07-26)

**Status:** ✅ COMPLETE — Commit 009a935, pushed to main

### #66 P0: "stab yourself" no injury created
**Root cause:** `handle_self_infliction()` bypassed the effects pipeline entirely. It called `injury_mod.inflict()` directly, ignoring `weapon.effects_pipeline` and `profile.pipeline_effects`. The pipeline_effects data in knife.lua/silver-dagger.lua was dead code.
**Fix:** Added effects pipeline routing — when `weapon.effects_pipeline == true` and `profile.pipeline_effects` exists, builds contextualized effect list and calls `effects.process()`. Legacy weapons without pipeline_effects still use direct path.

### #67: "hit your head" not recognized
**Root cause:** `parse_self_infliction()` only stripped "my" prefix, not "your". Preprocessor had no possessive stripping.
**Fix:** (1) Added `strip_possessives` preprocessor stage at end of pipeline (after phrase routing to preserve "check my wounds" etc). (2) Added "your" to `parse_self_infliction()`.

### #69/#70: Pronoun "it"/"that" not resolved + wear auto-pickup
**Root cause:** Context window pronoun resolution was already working. The real issue was the wear verb only searching hands — no fallback to room.
**Fix:** Wear handler now falls through to `find_visible()` for wearable items, auto-picks up from room (Infocom pattern).

### #71: "pick up cloak" resolves to oak vanity
**Root cause:** Two issues in fuzzy.lua: (1) Levenshtein("cloak","oak")=2 was within threshold because length ratio check was too lenient. (2) `score_object` checked matchable strings sequentially — name "a moth-eaten wool cloak" matched as "partial" (4) before keyword "cloak" could score as "exact" (10).
**Fix:** (1) Added 75% length ratio requirement for typo tolerance. (2) Two-pass scoring: exact match first across all strings, then partial.

### Tests: 26 new tests
`test/integration/test-bugs-066-067-069-070-071.lua`:
- 5 tests for #66 (pipeline routing, injury creation, body area, description, effects.process called)
- 7 tests for #67 (possessive stripping, backward compat with health/inventory phrases)
- 6 tests for #69/#70 (context_window resolve, wear auto-pickup, hands-full guard, non-wearable guard)
- 5 tests for #71 (Levenshtein distance, length ratio, exact vs partial scoring, legitimate typo)
- 3 integration tests (full parser→verb→effects→injury chain)

**62/62 test files pass — zero regressions.**

### Key Learnings
7. **Effects pipeline must be wired at ALL call sites.** `handle_self_infliction()` predated `effects.lua` and was never updated. Any new verb handler that creates injuries must check `effects_pipeline` flag.
8. **Preprocessor stage ordering matters.** Possessive stripping must run AFTER phrase routing stages that depend on "my" (e.g., "check my wounds" → health).
9. **Fuzzy scoring needs two-pass: exact first, then partial.** Single-pass sequential matching over `matchable_strings` (name→id→keywords) can miss exact keyword matches when the name also contains the search term as a substring.
10. **Levenshtein typo tolerance needs length ratio guard.** Without it, short words in multi-word keywords match long search terms (e.g., "oak" in "oak vanity" matches "cloak").

---

## Bug Fixes #68, #74 — Category Synonyms + Composite Child Preference (2026-07-26)

**Status:** ✅ COMPLETE — Commit 6cad8d0, pushed to main

### #68 P2: 'find clothing' doesn't match wool cloak
**Root cause:** `matches_target()` only checked id, name, substring, and keywords. Category-level synonyms ('clothing' → 'wearable') were not resolved.
**Fix:** (1) Added `CATEGORY_SYNONYMS` table mapping common search terms to category names. `matches_target()` now checks this table after keyword matching. (2) Added 'clothing'/'apparel' keywords to wool-cloak.lua as a direct fix.

### #74 P2: 'find candle' finds candle holder but not the candle itself
**Root cause:** `find_deeper_match()` only worked for `containers.is_container()` objects. The candle-holder is a composite object with `parts` and FSM-state `contents`, but no "container" category. So deeper match was never attempted.
**Fix:** (1) Removed `is_container` guard from `find_deeper_match()`. (2) Added `matches_exact()` helper for strict matching (id/name/keyword only, no substring). (3) Three-pass deeper match: exact in contents → exact in parts → any in contents. When parent substring-matches target but child exact-matches, child wins.

### Tests: 24 new regression tests

---

### 2026-07-30: WAVE-5 Track 5B — Eat/Drink Verb Extensions

**What shipped:** Extended eat/drink verb handlers in `src/engine/verbs/survival.lua` for food system PoC. All 191 test files pass, zero regressions.

**Eat handler changes:**
- Check `food.edible` (WAVE-5 food table) with fallback to legacy `obj.edible` for backward compatibility
- Injury restriction check via `injuries.get_restrictions(player)` — `restricts.eat` blocks eating
- Spoiled food warning: `_state == "spoiled"` prints warning but still allows consumption
- `on_taste` sensory text emitted on successful eat
- `food.nutrition` applied to `player.nutrition` accumulator
- WAVE-5 food objects (with `food` table) require holding; legacy `edible` objects grandfathered to preserve on_eat hook tests (#102)

**Drink handler changes:**
- Rabies hydrophobia check: `restricts.drink` blocks drinking with thematic message, checked before object resolution
- Added food-as-drink path for objects with `food.drinkable` (future extensibility)
- Hoisted `injury_mod` pcall to module scope (shared with eat handler, avoids redundant require in FSM path)

**Backward compatibility decision:** The old eat handler searched inventory then visible. The WAVE-5 spec says "object must be in player's hands." Resolved by requiring holding only for new `food` table objects while grandfathering legacy `edible` objects. This preserves all existing on_eat hook tests (test-engine-hooks-102.lua) while new food tests (test-eat-drink.lua) enforce holding.

**Files changed:** `src/engine/verbs/survival.lua` (+81/-21 lines)
**Tests:** All 191 test files pass (15/15 eat-drink tests, 20/20 hook tests)
`test/search/test-search-bugs-068-074.lua`:
- 9 tests for #68 (category synonyms, keyword match, full search integration)
- 11 tests for #74 (matches_exact, find_deeper_match, composite parts, full search integration)
- 4 cross-cutting regressions (keyword, substring, ID, unknown synonym)

**65/65 test files pass — zero regressions.**

### Key Learnings
11. **Category-level search needs a synonym table.** Players use natural language categories ("clothing", "weapons") but objects use internal categories ("wearable", "weapon"). A simple synonym table bridges this gap without changing the object model.
12. **Composite objects need deeper-match too, not just containers.** `find_deeper_match()` was gated on `is_container()` but composite `parts` objects (candle-holder with parts.candle) need the same child-preference logic. The guard should check for any children (contents or parts), not just container status.
13. **Exact match vs substring match matters for parent/child disambiguation.** When "candle" substring-matches "candle holder" but exact-matches the child candle object, the exact match should always win. The `matches_exact()` helper enables this three-pass priority.

---

## P0 FIX #78: Game fails to load after deep nesting refactor (2026-07-26)

**Status:** ✅ COMPLETE — Commit b867eb6, pushed to main

### Root Cause
Room files were refactored from flat `location = "room"` strings to deep nesting (`on_top`, `contents`, `nested`, `underneath`). The `src/engine/loader/init.lua` has `flatten_instances()` which walks the tree and assigns `.location` to each instance. `src/main.lua` was updated to call it (line 244), but `web/game-adapter.lua` was not. Result: `inst.location` was nil for all nested objects, causing `loc:match()` to crash at line 398.

### Fix (3 changes to web/game-adapter.lua)
1. **Call `loader.flatten_instances()`** after `resolve_template()` and before object-fetching loop — converts nested tree to flat array with `.location` set on every instance
2. **Nil guard for `loc`** — if location is somehow missing, treat as room-level instead of crashing
3. **Port "inside" surface routing** from `src/main.lua` — when parent has `surfaces.inside`, route there instead of bare `parent.contents`

### Key Learning
14. **Web adapter must mirror main.lua loading phases.** The adapter duplicates the room-loading pipeline (flatten → fetch objects → resolve → wire containment). When the pipeline changes in main.lua, the adapter MUST be updated in lockstep. The adapter's `load_room()` function should always follow the same phase ordering as `src/main.lua`'s Phase 0/1/2 sequence.

---

### Root Cause
After the deep nesting refactor, `nested` objects (like the drawer in the nightstand) can themselves be containers with `contents`. The search engine's `matches_target()` only recursed into **open** containers — the `containers.is_open(object)` gate prevented peeking into closed containers like the drawer and matchbox. So "find match" reported "Inside you feel a small drawer, but no match" — it found the drawer but couldn't look inside it.

### Fix (3 changes to traverse.lua)
1. **`matches_target`**: Removed `containers.is_open()` gate — search now recurses into closed containers, matching the peek semantics the engine already uses elsewhere
2. **`find_deeper_match`**: Made Pass 3 recursive — when a child matches, recursively check if an even deeper child is a better (exact) match. This finds match-1 (exact keyword "match") inside matchbox inside drawer, rather than stopping at matchbox.
3. **`matches_direct` helper + surface objects**: New `matches_direct()` checks only the object's own properties (no child recursion). Used at the surface-object entry point to prevent a parent (nightstand) from falsely claiming a match via its children's contents — those children are handled by their own surface queue entries.

### Tests: 14 new regression tests
`test/search/test-search-nested-containers-084.lua`:
- 3 tests: `matches_target` recurses into closed containers
- 3 tests: `find_deeper_match` recurses through multiple nesting levels
- 3 tests: Full search traversal (find match, find matchbox, find drawer)
- 3 tests: `traverse.step` unit tests for nested targets
- 2 tests: `flatten_instances` handles 3-level nesting

**66/66 test files pass — zero regressions.**

### Key Learnings
15. **Search peek semantics must be consistent.** The engine already peeked into closed surfaces (#24), but `matches_target` gated on `is_open`. Removing the gate aligns matching with the existing peek behavior.
16. **Surface-parent objects need direct matching.** When a parent has both `surfaces` and `contents`, removing the `is_open` gate from `matches_target` makes the parent match via children's contents. But children are handled by surface queue entries, not the parent entry. The `matches_direct` helper prevents this double-matching.
17. **Recursive deeper-match finds the most specific item.** Single-level `find_deeper_match` returned matchbox for "find match". Recursive deeper-match follows the chain drawer→matchbox→match-1 to return the actual match object with exact keyword match.

---

## Put Verb Parser Gaps — #81 #82 #83 (2026-07-27)

**Status:** ✅ COMPLETE — Commit 7c638e2, pushed to main

### #81 P2: Pronoun 'that'/'it' not resolved in put verb
**Root cause:** The put handler's item lookup searched hands using `matches_keyword(candidate, kw)` directly on the raw noun string. Unlike `find_visible()` (which wraps `context_window.resolve()`), the hand search had no pronoun resolution. "put it on nightstand" would try to find keyword "it" in hands — no match.
**Fix:** Added pronoun resolution via `context_window.resolve()` before hand search. If the item_word is a pronoun ("it", "that", "this", "one"), it resolves to the context window's most recent object, then uses that object's ID for the hand search.

### #82 P2: Put verb needs 'under' and 'inside' prepositions
**Root cause:** Parser only matched `^(.+)%s+in%s+(.+)$` and `^(.+)%s+on%s+(.+)$`. No patterns for under/underneath/beneath/inside.
**Fix:** (1) Added pattern matching for "underneath", "beneath", "under" (all map to prep="under") and "inside" (maps to prep="in"). (2) Surface routing: prep="under" maps to `surfaces.underneath` zone. (3) For objects without surfaces, creates flat `target.underneath` array. Order matters: "underneath" and "beneath" must be matched before "under" to avoid greedy substring issues.

### #83 P2: Missing placement verb aliases
**Root cause:** Only "place" was aliased to put handler. Natural English placement verbs (set, drop, hide, stuff, toss, slide) with directional prepositions had no routing.
**Fix:** Added transform patterns in `transform_compound_actions` for 6 verb families, each with multiple preposition variants. Careful not to break existing transforms: "set fire to" stays as light, bare "drop X" stays as drop, "set clock" stays as set.

### Tests: 27 new regression tests
`test/integration/test-bugs-081-082-083.lua`:
- 4 tests for #81 (pronoun resolution: it/that/this + non-pronoun regression)
- 7 tests for #82 (under/underneath/beneath/inside preps + surface routing + in/on regression)
- 16 tests for #83 (6 alias transforms + 4 variant preps + 6 regressions)

**67/67 test files pass — zero regressions.**

### Key Learnings
15. **Hand-search in put handler must go through pronoun resolution.** Unlike most verbs that use `find_visible()` (which has context_window integration), the put handler does a direct hand-slot scan with `matches_keyword()`. Any verb handler that searches inventory directly must also resolve pronouns first.
16. **Preposition pattern ordering: longest first.** "underneath" must be matched before "under", otherwise "under" greedily matches "underneath rug" as item="key underneath", target="rug". Same applies to "inside" before "in".
17. **Placement verb aliases need preposition guards.** "set X on Y" → put, but bare "set X" → clock/adjustment handler. "drop X on Y" → put, but bare "drop X" → drop handler. The preposition is the discriminator — without it, the command stays with the original verb.

---

### 2026-07-17: Search Slow-Reveal Timing × 3

**Change:** `TRICKLE_DELAY_MS` in `web/bootstrapper.js` (and `web/dist/bootstrapper.js`) controls the real-time (user-time) delay between revealing each line of search output in the browser UI. Wayne wanted search to feel more deliberate — 3× slower.

- **Old value:** 350 ms per line
- **New value:** 1050 ms per line (350 × 3)
- **Files changed:** `web/bootstrapper.js` line 48, `web/dist/bootstrapper.js` line 48
- **Tests:** All 76 test files pass (tests are Lua-side; the trickle is JS-side presentation only).

---

### P0 Fixes Complete (Commit referenced in logs)
- **TDD Hit Head Fix (#133):** 14 tests, 3 code fixes, zero regressions
- **Search Container Fix (P0 #135+#132):** D-SEARCH-ACCESSIBLE decision merged
- **Decisions:** D-SELF-INFLICT-CEILING (self-harm can't kill), search timing 3× slower (1050ms)
- **Search Timing:** TRICKLE_DELAY_MS multiplied by 3 in web/bootstrapper.js

### Team Context
- TDD directive enforced team-wide — all bug fixes must have tests first
- Search is now 3× slower deliberately to make it feel deliberate (Wayne directive)
- Self-infliction verbs safely bounded — can't reduce health below 1

---

### Team Context
- Bart's architecture doc and CBG's design doc provided clear specs — formula, multipliers, degradation model
- Nelson's TDD tests defined the contract precisely — 8 test suites covering all armor behaviors
- 	est/armor/ directory is NOT yet in 	est/run-tests.lua directory list — Nelson should add it

### 2026-07-22: Issue #112 — Wash verb for soiled bandages

**What shipped:** WASH verb handler with clean/rinse/scrub aliases. Requires nearby water source (rain-barrel, well-bucket). Supports FSM-driven soiled→clean transitions on bandages and any object declaring a `wash` transition with `requires_tool = "water_source"`.

**Five layers of change:**
1. **Preprocess** (`transform_compound_actions`): clean/rinse/scrub → wash synonym conversion; "wash X with Y" → "wash X in Y" canonical form; handles both bare synonyms and prepositional variants in one pass to avoid double-return issues.
2. **Gerund map**: Added washing→wash, cleaning→clean, rinsing→rinse, scrubbing→scrub.
3. **Game loop** (`loop/init.lua`): Extract "in Y" target for wash verb → `context.wash_target` (follows pour_target/apply_target pattern).
4. **Verb handler** (`survival.lua`): WASH handler following the fire/light tool-check pattern — finds FSM transition, checks `requires_tool`, resolves water source via `find_tool_in_inventory` then `find_visible_tool`, rejects empty water sources. Also handles "wash hands" (clears bloody/dirty player state). Explicit target via `ctx.wash_target` validates the target is actually a water source.
5. **Water source objects**: Added `provides_tool = "water_source"` to rain-barrel.lua and well-bucket.lua so `find_visible_tool` can discover them.

**Key learning:** Synonym replacement + preposition normalization must happen in one pass. Initially had synonym replacement returning first (e.g., "scrub X with Y" → "wash X with Y"), then the "with→in" normalization never ran because `transform_compound_actions` already returned. Fix: unified handler checks "in Y" and "with Y" patterns before falling through to bare synonym replacement.

**Files changed:** `src/engine/parser/preprocess.lua`, `src/engine/loop/init.lua`, `src/engine/verbs/survival.lua`, `src/meta/objects/rain-barrel.lua`, `src/meta/objects/well-bucket.lua`, `test/parser/pipeline/test-wash-patterns.lua`, `test/verbs/test-wash-verb.lua`

**Tests:** 22 preprocess + 12 verb handler = 34 new tests, 0 regressions. Full suite: 115 files passing.

### 2026-07-18: Issue #123 — Material data migration: engine → meta

**What shipped:** Migrated 23 hardcoded material definitions from the monolithic `src/engine/materials/init.lua` into individual `.lua` files under `src/meta/materials/`. The engine file became a thin loader that discovers and loads material files at require-time using the same `io.popen` + `dofile` pattern used elsewhere in the codebase (test-material-audit, main.lua loader).

**Migration pattern:**
1. Created `src/meta/materials/` with 23 files (wax.lua, wood.lua, ceramic.lua, etc.)
2. Each file returns `{ name = "material_name", density = ..., hardness = ..., ... }` — the `name` field is used as the registry key, then stripped from the property table to maintain API compatibility.
3. `src/engine/materials/init.lua` reduced from 333 lines of hardcoded data to 54 lines of loader code.
4. Public API unchanged: `materials.get()`, `materials.get_property()`, `materials.registry` all work identically.

**Key learning:** Material property tables must NOT contain a `name` key after loading — the original registry stored properties only (density, hardness, etc.) without the material name as a table field. Stripping `mat.name = nil` after using it as the key maintains exact API parity. Iron and steel have an extra `rust_susceptibility` property beyond the standard 11; the loader handles this transparently since it loads the full table.

**Files changed:** `src/engine/materials/init.lua` (rewritten), 23 new files in `src/meta/materials/`

**Tests:** All 121 test files pass. Material audit (#163): 86/86 objects validated. Material properties (#123): 23 materials × 11 properties validated. meta-check clean. 0 regressions.


### 2026-07-27: WAVE-3 Track 3C — Combat Witness Narration

**What shipped:** Witness narration system for NPC-vs-NPC combat, implementing proximity-based text output with narration budget protocol. All 16 witness narration tests pass, 186 total test files, zero regressions.

**Four narration tiers:**
1. **Same room + light:** Third-person visual templates via describe_exchange(result, opts). Five severity tiers (DEFLECT→CRITICAL) with 3 templates each. Uses ctor_name() for third-person framing ("The cat strikes the rat").
2. **Same room + dark:** Audio-only templates keyed to severity. GRAZE→scuffle sounds, HIT→yelps/thuds, CRITICAL→shrieks/silence. No visual detail — pure audio narration.
3. **Adjacent room:** Distant audio with direction label. 1 line max via describe_adjacent(direction).
4. **Out of range:** Nothing emitted (nil return).

**Narration budget protocol:**
- 
ew_budget(cap) / create_budget(cap) factory returns {count, cap, overflow_emitted} table.
- mit(result, budget, opts) — budget-aware dispatch. Generates text via describe_exchange then applies budget rules.
- Non-critical (GRAZE/DEFLECT) suppressed when count >= cap. Critical (HIT/SEVERE/CRITICAL) always passes even over budget.
- Player combat exempt via opts.player_combat = true — never counted against cap.
- overflow_text(budget) available as separate method for deferred "[The melee continues...]" indicator.
- Morale break narration via mit_morale_break(name, direction, light) counts toward budget.

**Dual calling convention:** mit() detects whether first arg is table (budget-aware path) or string (simple/legacy path for mit_witness integration). This lets Bart's mit_witness() use the simple path with module-level budget while tests use the explicit budget object.

**Key learnings:**
- Lua string.find("glancing", "glance") returns nil! "glancing" = g-l-a-n-c-**i**-n-g vs "glance" = g-l-a-n-c-**e**. The 6th character differs. Must audit ALL templates against test keyword lists for literal substring matches.
- Template audio keywords must match the test's exact keyword list (hear, sound, thud, crack, squeal, hiss, scrape, crunch, shriek, yelp, whimper, impact, wet, etc.). "cry" and "echoes" are NOT in the list.
- Budget overflow marker "[The melee continues...]" counts as a visible output line. Tests expect ≤cap total visible outputs, so the marker must either replace the last normal line or be deferred to a separate overflow_text() call. Chose the deferred approach to keep budget arithmetic clean.

**Files changed:** src/engine/combat/narration.lua (355 lines added — witness templates, budget system, proximity logic)

**Tests:** 16/16 witness narration tests pass. 186 test files total, 0 new regressions.

### 2026-03-27: Phase 3 WAVE-3 — Cook verb handler + eat handler extensions

**What shipped:** Cook verb handler in cooking.lua and eat handler extensions in consumption.lua, implementing the full cook→eat gameplay arc for the food system. Added heal effect handler to effects.lua.

**Cook verb handler (cooking.lua, +71 LOC):**
- `cook` verb with `roast`, `bake`, `grill` aliases — all registered and pointing to same handler
- Finds food object in inventory first, then visible scope; requires holding to cook
- Checks `obj.crafting.cook` recipe on the object (Principle 8 — objects declare behavior)
- Searches for fire_source tool: `find_tool_in_inventory` then `find_visible_tool` (covers brazier as room furniture)
- Performs mutation via `perform_mutation()` for raw→cooked object swap (legitimate file-swap, not reshape)
- Consumes tool charge on fire source if applicable
- Prints `recipe.message` or `recipe.fail_message_no_tool`
- Follows sew pattern from crafting.lua for consistency

**Eat handler extensions (consumption.lua, +59 LOC):**
- **Raw meat with consequences:** If `food.raw == true` and `food.category == "meat"` and `food.cookable == true` and `food.edible ~= true`: allows eating but inflicts food-poisoning injury via `injury_mod.inflict()`. Prints taste warning (`obj.on_taste`) then "You choke it down. Your stomach rebels almost immediately."
- **Raw non-meat cookable rejection:** If `food.raw == true` and `food.cookable == true` and category is NOT meat: rejects with `obj.on_eat_reject or "You can't eat that raw. Try cooking it first."` — handles grain and similar.
- **Non-raw cookable rejection:** Fallthrough for items with `cookable == true` but `raw ~= true` and `edible ~= true`.
- **Food effects pipeline:** After successful eat, processes `obj.food.effects` array through `effects.process()` — supports `narrate`, `heal`, `inflict_injury` effect types.
- Moved injury restriction check (jaw injuries) before food category gating for cleaner flow.

**Effects pipeline (effects.lua, +31 LOC):**
- Added `heal` effect handler: reduces accumulated injury damage by `effect.amount`. Iterates player injuries, reduces damage on each until heal amount exhausted. Optional `effect.nutrition` for general health benefit.

**Key design decision:** Category-based gating (`food.category == "meat"` vs grain/other) determines whether raw food can be force-eaten with consequences vs rejected outright. The spec said `food.raw ~= true` for grain rejection, but grain objects have `food.raw = true` — the actual distinguishing factor is the food category. Meat is animal flesh you can choke down raw; grain needs cooking to become edible.

**Files changed:** `src/engine/verbs/cooking.lua` (+71 LOC), `src/engine/verbs/consumption.lua` (+59 LOC net), `src/engine/effects.lua` (+31 LOC)

**Tests:** All 43 food tests pass (15 cook-verb, 8 cookable-gating, 12 eat-effects, 8 eat-drink baseline). 0 new regressions. Pre-existing failures: 2 test files (creature-combat #346, injuries-comprehensive order-dependent).

### 2026-03-27: Phase 3 WAVE-4 — Kick verb + combat sound narration API

**What shipped:** Kick verb alias in verbs/init.lua and combat sound propagation narration API in combat/narration.lua.

**Kick verb alias (verbs/init.lua, +1 LOC):**
- Added handlers["kick"] = handlers["hit"] alongside existing aliases (punch, bash, bonk, etc.)
- Routes kick rat through existing combat pipeline — no new handler logic needed

**Combat sound narration API (combat/narration.lua, +44 LOC):**
- mit_combat_sound(room, intensity, witness_text, opts) — player-perspective sound narration by distance:
  - Same room: returns nil (combat narration already covers it)
  - Adjacent room (1 exit away): "You hear violent sounds from the [direction]. Something crashes." — direction resolved from exit graph via existing ind_direction() helper
  - 2+ exits away: returns nil (sound doesn't propagate that far)
  - Reuses existing M.proximity() and local ind_direction() — zero duplication
- creature_flee_sound(creature_name, light) — fleeing creature narration, visible only: "[name] skitters away from the noise."
- creature_investigate_sound(creature_name, light) — investigating predator narration, visible only: "[name] perks up, drawn toward the sounds."
- All three functions return nil when player can't see (dark), matching spec

**Integration surface:** Bart calls mit_combat_sound() from combat/init.lua after NARRATE phase. Stimulus pipeline triggers creature reactions; these narration functions provide the player-facing text.

**Tests:** 0 new regressions. Pre-existing failures (12 movement/exit/lock tests in 1 file) unrelated to these changes.

**Commit:** 6eb1978 — "Phase 3 WAVE-4: kick verb + combat sound narration"

### goto Admin/Debug Teleport Command

**What shipped:** `goto <room-id>` verb — an admin/debug command that teleports the player to any room by ID, preserving inventory (hands, worn items). Also aliased as `teleport`.

**Implementation:** Added to `src/engine/verbs/movement.lua` inside `M.register()`. The handler:
- Validates noun (empty → usage hint, invalid room → "No room called 'xyz' exists.")
- Looks up target in `ctx.rooms` by ID
- Fires `on_exit_room` / `on_enter_room` hooks
- Records previous room for `go back` support
- Tracks visited_rooms for first-visit auto-look
- Prints "You materialize in {room name}." confirmation

**Tests:** `test/verbs/test-goto.lua` — 7 tests, all passing:
- goto valid room (cellar, crypt) — moves player, triggers enter
- goto invalid room → error message
- goto with no argument → usage hint
- Inventory preserved (hands + worn items)
- goto same room — no crash

**Commit:** 5aa5066 — "feat: goto admin command for room teleportation (debug)"

### Session — Fix 4 Bugs: goto + combat text (#287, #288, #289, #290)

**Date:** 2025-07-25
**Requested by:** Wayne Berry

**#287: goto bedroom fails (room ID is start-room)**
- `goto` handler in `movement.lua` only did exact `ctx.rooms[target_id]` lookup
- Added fallback: iterates all rooms, matches by `room.name` (substring) and `room.keywords` (exact)
- `goto bedroom` now finds `start-room` via its keywords `{"bedroom", "room", "chamber", "bedchamber"}`

**#288: goto with no argument gets polluted by parser context**
- Tier 4 context window in `loop/init.lua` re-injected `last_noun` into bare `goto`
- Added `goto = true, teleport = true` to `no_noun_verbs` table — prevents context injection
- Bare `goto` now correctly prints "Goto where? Usage: goto <room-name>"

**#289: Combat says "Someone" instead of "You"**
- `actor_name()` in `narration.lua` checked `name:lower() == "you"` but player has `id = "player"`
- Added `is_player` check: `if actor.id == "player" or actor.is_player then return "You" end`
- Player combat narration now reads "You punch..." / "You kick..." as intended

**#290: Duplicate "into into" in bite narration**
- Creature weapons (rat, bat, cat, spider) have `message = "sinks its teeth into"`
- Templates like `"{attacker} {verb} into {zone}..."` produced "sinks its teeth into into your arm"
- Added post-render dedup in `render()`: `text:gsub("into into", "into")`

**Tests:** All 7 goto tests pass, all 22 narration tests pass, no regressions introduced.
**Commit:** 37a72ed — "fix: goto keyword search + combat text polish (#287, #288, #289, #290)"

### Session — Phase 4 WAVE-1: Butcher Verb Handler
**Date:** 2026-03-27
**Requested by:** Wayne Berry

**Implemented butcher verb handler** (src/engine/verbs/butchery.lua):
- New file, split from crafting.lua for clean separation (167 LOC)
- Validates: dead creature + death_state.butchery_products + tool with "butchering" capability
- Advances game time by 5 minutes via ctx.time_offset (follows rest.lua pattern)
- Ticks FSMs during butchery (candles burn, spoilage advances)
- Instantiates products via object_sources + loader (production path)
- Corpse removal matches by both id and guid for test/engine compatibility
- Error messages: "You can't butcher that." / "There's nothing useful to carve from this corpse." / "You need a knife to butcher this."

**Verb aliases registered:** butcher, carve, skin, fillet

**Embedding index updated:** 380 new phrases (IDs 11132-11511) — 4 aliases × 95 nouns, all with verb="butcher" and adjective-first noun IDs per collision audit.

**Registration:** crafting.lua delegates to butchery.lua (same pattern as cooking/placement delegation).

**Tests:** 4/4 butchery TDD tests pass. No regressions (2 pre-existing failures in injuries/combat unchanged).

### Phase 4 WAVE-4: Craft Verb Extensions + Weapon Combat Metadata
**Date:** 2025-07-25
**Requested by:** Wayne Berry

**Task 1 — Craft Verb Handler:** Added `craft`/`make`/`create` handlers to `src/engine/verbs/crafting.lua` using Tier 1 recipe-ID dispatch. Player types `craft silk-rope` — noun IS the recipe ID. Handler validates ingredients from player inventory/room, consumes them, spawns results via `spawn_objects()`. Two recipes added:
- `silk-rope`: 2× silk-bundle → 1× silk-rope ("You twist the silk bundles together into a strong, lightweight rope.")
- `silk-bandage`: 1× silk-bundle → 2× silk-bandage ("You tear the silk into strips suitable for bandaging wounds.")

Recipe table is module-level (`crafting_recipes`), extensible for future recipes. `craft X from Y` syntax deferred to Phase 5 per decision.

**Task 2 — Embedding Index:** Added 12 new phrases (IDs 11512-11523) — 3 verb aliases (craft, make, create) × 2 surface forms (natural "a silk rope" + ID "silk-rope") × 2 items. All entries map verb="craft" per Tier 2 dispatch.

**Task 3 — Weapon Combat Metadata:** Added `combat` tables to 4 weapon-like objects missing them:
- `cobblestone.lua` — blunt, force=3, "bashes" (light improvised weapon, matches wolf-bone)
- `crowbar.lua` — blunt, force=5, "smashes" (heavy iron, highest blunt force)
- `candle-holder.lua` — blunt, force=4, "cracks" (brass, medium weight)
- `glass-shard.lua` — edged, force=2, "slashes" (fragile, low force but sharp)

Pattern follows existing combat metadata: `{ type, force, message, two_handed }`. The `reach` field was NOT added — no existing weapons use it yet (future Phase 5 extension).

**Files modified:**
- `src/engine/verbs/crafting.lua` — craft/make/create handlers + recipe table
- `src/assets/parser/embedding-index.json` — 12 new craft/make/create phrases
- `src/meta/objects/cobblestone.lua` — combat metadata
- `src/meta/objects/crowbar.lua` — combat metadata
- `src/meta/objects/candle-holder.lua` — combat metadata
- `src/meta/objects/glass-shard.lua` — combat metadata

**Tests:** 0 new regressions. 3 pre-existing test file failures unchanged (spider-web/creatures, integration playtest-bugs, verb-handler WIP tests).
