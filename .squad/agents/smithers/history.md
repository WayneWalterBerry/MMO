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
