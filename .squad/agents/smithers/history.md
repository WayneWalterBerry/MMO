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

## Learnings

### 2026-03-23: Wave2 — Decision Documentation

**Wave2 Spawn:** Scribe merged decision documents into decisions.md

**Decisions Documented:**
- **D-PHRASE001:** Specific phrase patterns must precede generic patterns in parser pipeline (most-specific-first)
- **D-PHRASE002:** Appearance verb exists as standalone handler (no mirror required for self-inspection)

**Key Insight:** These decisions are pure documentation of existing implementation. No code changes required in this wave. Future phrase additions must follow the pattern ordering established in Pass038.

**Cross-Agent Status:** Marge verified all 5 Phase1 issues and closed them. Ready for Scribe merge phase.

---

## EFFECTS PIPELINE IMPLEMENTATION (EP3, 2026-03-23T17:05Z)

**Status:** ✅ COMPLETE

Implemented unified Effects Pipeline as per Bart's D-EFFECTS-PIPELINE architecture:

**Deliverable:** `src/engine/effects.lua` (232 lines) — Effect processor with:
- Handler dispatch and registration mechanism
- Before/after interceptor framework
- Effect normalization (single effects + legacy strings both normalize to arrays)
- Day-one handlers: `inflict_injury`, `narrate`, `add_status`, `remove_status`, `mutate`

**Integration:** Modified `src/engine/verbs/init.lua` (52 lines removed, 52 lines added)
- Wired drink/taste verb handlers into pipeline
- Fixed taste verb injury routing (legacy `os.exit(0)` dead code path)
- Maintained backward compatibility with existing FSM behavior

**Key Design Decisions:**
1. **Handler context** (`ctx`) constructed at call site, not implicitly from globals (stateless per D-APP-STATELESS)
2. **Normalization** returns arrays always — single effects and legacy strings both normalize to `[ {...} ]`
3. **Death check** stays in verb handler after `effects.process()` returns (handler sets `ctx.game_over = true`, verb handler does authoritative check)
4. **Legacy code path:** FSM `apply_state()` copies structured tables from state definitions. Poison bottle already uses structured format, so `obj.on_taste_effect == "poison"` was always false. Pipeline now correctly processes the structured table.

**Test Results:**
- 116/116 poison bottle regression tests passing ✓
- 1361/1362 full suite pass (1 pre-existing unrelated failure) ✓
- Zero regressions introduced ✓

**Verified by:** Nelson (EP4 independent verification) + Marge (EP4 gate approval)

**Ready for EP5:** Flanders can proceed with poison-bottle.lua refactoring with high confidence

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

## Play-test Bug Fixes (2026-03-23, Wayne iPhone session)

**Status:** ✅ COMPLETE — Commit 491f9a8, pushed to main

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

## BUG-146 (#46): "search for a match" Fuzzy Scope Hijack (2026-03-24)

**Status:** ✅ COMPLETE — Regression tests committed a67141c, pushed to main

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

## #48: Search Streaming with Clock Advance (2026-03-24)

**Status:** ✅ COMPLETE — Commit 26f0912, pushed to main

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

## FIX #84: Search doesn't recurse into nested containers (2026-03-23)

**Status:** ✅ COMPLETE — Commit 7e177cd, pushed to main, deployed

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
