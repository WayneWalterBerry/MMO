# Smithers -- History

## Project Context
- **Project:** MMO text adventure game in pure Lua (REPL-based, lua src/main.lua)
- **Owner:** Wayne 'Effe' Berry
- **Architecture:** 8 Core Principles (code-derived mutable objects, FSM-driven behavior, sensory space, generic mutation via Principle 8)
- **Stack:** Pure Lua, no external dependencies
- **My Focus:** UI layer (text output, presentation, player feedback) and Parser pipeline (Tiers 1-5, verb resolution, disambiguation, GOAP)

## Core Context (Archived Sessions Summary)

This section summarizes 50+ prior sessions covering UI architecture, web deployment, parser pipeline optimization, and web performance.

**Key Accomplishments (Cumulative):**
- Built 3x UI architecture documentation (README, text-presentation, parser-overview)
- Deployed three-layer web architecture (bootstrapper.js -> engine.lua.gz -> JIT-loaded meta)
- Fixed web performance: 16MB bundle -> 135KB initial load
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

**Parser Recent Work (Phase 3):**
- Parser pipeline expansion prep work (Tier 4-5 design docs)
- Phrase system implementation (Pass037/038 ordering)
- Web bundle optimization completed
- Documentation for text presentation and verb system

**File Paths (Ongoing Responsibility):**
- src/engine/parser/ - parser pipeline (Tiers 1-5)
- src/engine/ui/ - UI module, text formatting
- src/engine/verbs/init.lua - verb dispatch (text output)
- docs/architecture/ui/ - UI architecture docs
- web/ - web build pipeline, browser wrapper

**Known Issues/Patterns:**
- Parallel output from concurrent linters interleaves - D-MUTATION-LINT-PARALLEL addresses this via sequential collection
- Parser Tier 4 context window needs testing at scale
- Web performance gains hold at 135KB initial load + progressive hydration

## Learnings

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

---

## Archives

- Prior detailed session logs: .squad/log/
- Linked decisions: .squad/decisions.md (search 'D-*' keys)

