# Wiggum — Project History

## Project Context
- **Project:** MMO — Lua text adventure game inspired by Zork
- **Owner:** Wayne "Effe" Berry
- **Tech:** Pure Lua engine, zero external dependencies, Fengari browser compat
- **My role:** Linter Engineer — I own the entire meta-lint system and mutation-edge validation pipeline

## Core Context
- The meta-lint system (`scripts/meta-lint/`) has 306 rules across 20 categories, ~1,900 LOC in lint.py
- The mutation-edge extractor (`scripts/mutation-edge-check.lua`) scans 206 meta files, finds 66 edges, 5 broken, 1 dynamic
- Pipeline: Lua edge extractor → Python meta-lint, composed via wrapper scripts (ps1/sh)
- Parallel execution per D-MUTATION-LINT-PARALLEL: per-file parallel lint, sequential output display
- CI: edge check in squad-ci.yml (continue-on-error), pre-deploy gate in run-before-deploy.ps1
- Test infrastructure: pytest at test/linter/, Lua tests at test/meta/
- Key decisions: D-MUTATION-LINT-PIVOT, D-PARALLEL-EXPAND-LINT, D-LINTER-IMPL-WAVES, D-MUTATION-LINT-PARALLEL
- Linter improvement plan: plans/linter/linter-improvement-design.md (6 waves, 5 gates — partially complete)
- Known broken edges: poison-gas-vent-plugged, wood-splinters (4 sources) — issues #403, #404, #405

## Learnings

### System Overview
- **Total Rules:** 220 unique rule IDs across 20 categories (was documented as 306 but counts 220 in current lint.py)
- **Rule Distribution:**
  - creature: 20 (animation, behavior, health, driving, reactions, loot, room spawning)
  - injury: 66 (damage types, states, transitions, healing, unconsciousness)
  - level: 38 (level structure, connections, spawn points)
  - material: 22 (material refs, consistency, fabric types)
  - template: 25 (template definitions, inheritance)
  - cross-ref: 10 (GUID references, type ID resolution)
  - exit-portal: 7 (portal FSM, bidirectional, traversability)
  - loot: 5 (loot tables, item spawning)
  - guid-xref: 3 (GUID uniqueness, orphan detection, instance IDs)
  - transition: 2 (state transitions)
  - sensory: 2 (on_feel required, sensory completeness)
  - structure: 8 (basic fields, id/guid/name/template)
  - material-ref: 3 (material registry validation)
  - fsm: 2 (initial_state presence, state definition)
  - room: 1 (room structure)
  - cross-file: 2 (cross-file checks)
  - exit: 2 (inline exits)
  - guid: 1 (GUID format)
  - parse: 1 (Lua parsing)

### Rule Severity & Safety
- **Error:** 176 rules (blocking merges)
- **Warning:** 93 rules (non-blocking but reviewed)
- **Info:** 37 rules (style suggestions)
- **Fixable:** 124 rules (auto-fixable via --fix flag)
- **Safety levels:** 77 "safe" (idempotent), 47 "unsafe" (need human review), 96 non-fixable

### Architecture — 6-Phase Pipeline
1. **Phase 1 (Tokenization):** Lua source → token stream (handles strings, comments, keywords, operators)
2. **Phase 2 (Preprocessing):** Strip preamble (local functions), neutralize function bodies → `__FUNC__` placeholders
3. **Phase 3 (Lark Earley Parser):** Token stream → AST (nested table structure with support for arrays, booleans, nil, identifiers)
4. **Phase 4 (Semantic Analysis):** Validate AST against template-specific schemas (required fields, types, FSM, sensory)
5. **Phase 5 (Cross-File Analysis):** GUID uniqueness, material registry refs, template refs, room type_id resolution, exit targets, mutation targets, keyword collisions
6. **Phase 6 (Error Reporter):** Format violations with file, line, severity, rule ID, message, suggestion

### Key Technologies
- **Parser:** Lark + Earley (battle-tested on 83/83 objects, handles ambiguity gracefully)
- **Language:** Python 3 (no external runtime; ecosystem standard for CI)
- **Dependencies:** lark only (pip install lark)
- **Tokenizer:** Custom regex-based (handles Lua 5.1+ syntax: strings, escapes, block comments, long strings, hex/scientific numbers)

### Configuration System
- **Config File:** `.meta-check.json` (optional, project root)
- **Per-Rule Config:** Severity override, enable/disable
- **Category Config:** Disable entire categories (e.g., injury testing)
- **Environment Profiles:** Dev/prod/sandbox-specific rules (disable certain rules per env)
- **Orphan Allowlist:** Objects to exclude from GUID-02 (orphan detection) — mutation targets often orphaned
- **Keyword Allowlist:** Shared keywords across materials (match, key, door)
- **Cache File:** `.meta-lint-cache.json` (gitignored, SHA-256 file hashing)

### Cache Strategy
- **Incremental caching** per file (SHA-256 hash)
- **Single-file rules** only cached; cross-file rules (XF-*, XR-*, GUID-*, EXIT-*, LV-40) always re-run
- **Specific cross-file rules** also invalidated: EXIT-03, CREATURE-019, CREATURE-020
- **Cache invalidation:** Any file change forces full cross-file re-evaluation

### Mutation-Edge Extractor (`scripts/mutation-edge-check.lua`)
- **12 Extraction Mechanisms:**
  1. mutations[verb].becomes (file swap)
  2. mutations[verb].spawns[] (spawn on mutation)
  3. transitions[i].spawns[] (spawn on FSM transition)
  4. crafting[verb].becomes (crafting result)
  5. on_tool_use.when_depleted (depletion target)
  6. loot_table.always[] (always drop)
  7. loot_table.on_death[] (death loot)
  8. loot_table.variable[] (variable loot)
  9. loot_table.conditional.{key}[] (conditional loot)
  10. butchery_products.products[] (butchery yields)
  11. behavior.creates_object (creature spawning)
  12. death_state recursive variants (nesting)

- **CLI Modes:**
  - Default: Human-readable report (files scanned, edges found, broken edges, dynamic paths)
  - `--json`: JSON output for CI/tooling
  - `--targets`: Target file paths to stdout (for piping to lint.py)
  - Exit code 0: no broken edges; 1: broken edges found

- **Current Status:** 206 files scanned, 66 edges, 5 broken targets, 1 dynamic path

### Squad Routing
Maps rule IDs to squad members for auto-assignment:
- **Smithers** (S-*, D-*, T-*, XF-*, XR-*) — Structure, display, parser
- **Flanders** (SI-*, INJ-*, MD-*, MAT-*, CREATURE-*, LOOT-*) — Objects, injuries, creatures
- **Moe** (RM-*) — Rooms
- **Comic Book Guy** (LV-*) — Levels
- **Sideshow Bob** (EXIT-*) — Exit/portal definitions
- **Bart** (PARSE-*, G-*, FSM-*, TR-*, SN-*, TD-*, GUID-*) — Core engine, GUIDs, cross-cutting

### Output Formats
- **Text (human-readable):** Pretty-printed with ANSI colors (🔴 ERROR, 🟡 WARNING, 🟢 INFO), line numbers, suggestions
- **JSON:** Structured violations with file, line, column, severity, rule_id, message, suggestion, context
- **TAP (Test Anything Protocol):** For pre-commit hooks, per-file results

### Exit Codes
- **0:** All checks passed
- **1:** Errors found (must fix before merge)
- **2:** Warnings only (non-blocking)
- **64:** Invalid arguments or configuration
- **65:** File I/O error

### CLI Flags
- `--format {text|json|tap}` — Output format (default: text)
- `--severity {all|warning|error}` — Minimum severity to report
- `--output FILE` — Write to file instead of stdout
- `--verbose` — Print file/violation counts
- `--config FILE` — Load config from custom path
- `--list-rules` — Print all rules with metadata and exit
- `--init-config` — Generate default config
- `--fix` — Auto-fix low-risk issues (safe + unsafe that are idempotent)
- `--no-cache` — Full re-scan (skip cache)
- `--env {dev|prod|sandbox|level-01}` — Apply environment profile

### Performance Characteristics
- Tokenization: ~10 ms
- Preprocessing: ~5 ms
- Lark parse: ~20 ms
- Semantic analysis: ~50 ms
- Cross-file analysis: ~100 ms (O(n²) worst case for collisions)
- Reporting: ~10 ms
- **Total:** ~195 ms for full meta/ directory (pre-commit viable)
- **Optimization:** Can cache unchanged files, parallelize Phase 4, deduplicate keywords with hash table

### Integration Points
- **CI:** `squad-ci.yml` has mutation-edge-check step with `continue-on-error: true`
- **Pre-Deploy:** `run-before-deploy.ps1` runs edge check + lint (errors = exit 1)
- **Wrapper Scripts:**
  - `scripts/mutation-lint.ps1` — PowerShell; runs edge extraction → Python lint with parallel workers (PS7)
  - `scripts/mutation-lint.sh` — Bash; 4 workers by default (configurable)
  - Pattern: **Parallel execution per-file, sequential output display** (D-MUTATION-LINT-PARALLEL)

### Known Limitations & Design Gaps
- **Function bodies opaque:** Can't validate logic in `on_look()`, `on_feel()`, factory functions; Lua runtime handles this
- **Identifier references not traced:** wall-clock pattern (generate states in for-loop, reference by var) can't be statically validated
- **Dynamic mutations not followed:** `mutations[verb].dynamic = true` uses runtime functions; flagged but not resolved
- **Multi-hop chains deferred:** Phase 2 (D-MUTATION-CYCLES-V2) will add A→B→C validation + cycle detection
- **Behavioral/gameplay semantics:** Meta-lint validates structure/data layer; Lisa validates gameplay fun/balance

### Broken Edges (Known Issues)
- **poison-gas-vent-plugged** — 4 sources pointing to non-existent target (Issue #403)
- **wood-splinters** — (Issues #404, #405)
- Exit code 1 from edge extractor means runtime crashes when players trigger mutations

### Test Infrastructure
- **Python tests:** `test/linter/` (pytest)
- **Lua tests:**
  - `test/meta/test-edge-extractor.lua` — Mutation edge extraction
  - `test/meta/test-mutation-lint-integration.lua` — Full pipeline integration
- **Pre-deploy gate:** `test/run-before-deploy.ps1` (tests + linting + web build)

### Key Design Decisions (Active)
- **D-LINTER-AUDIT-BASELINE:** All meta file additions must pass lint with zero new findings before PR (active gate)
- **D-MUTATION-LINT-PIVOT:** Pivot from single-pass to expand-and-lint (Lua edge extraction → Python lint)
- **D-PARALLEL-EXPAND-LINT:** Run extraction + lint in parallel (mutation-lint.ps1/sh)
- **D-LINTER-IMPL-WAVES:** Phased implementation (waves 0-4, gates between)
- **D-MUTATION-LINT-PARALLEL:** Collect output per-file, display sequentially to avoid interleaving

### Linter Improvement Plan
- **Phase 1 (WAVE-0/1/2):** Core expansion (150 new rules) + creature/injury/level support + mutation edges ✓
- **Phase 2 (WAVE-3):** Multi-hop chains, parts[] extraction, cycle detection
- **Phase 3 (WAVE-4):** Advanced semantic checks (orphan reduction, loot validation)
- **Phase 4+ (future):** NPC routing, combat pipeline, behavior validation

### References
- **Docs:** `/docs/meta-lint/` — overview, architecture, rules, schemas, acceptance criteria, usage
- **Source:** `/scripts/meta-lint/` — lint.py (~1,900 LOC), rule_registry.py, config.py, cache.py, squad_routing.py, lua_grammar.py
- **Edge extraction:** `/scripts/mutation-edge-check.lua` (~450 LOC, zero Lua dependencies)
- **Wrapper scripts:** `/scripts/mutation-lint.ps1`, `/scripts/mutation-lint.sh`
- **Design docs:** `plans/linter/mutation-graph-linter-design.md`, `plans/linter/mutation-graph-linter-implementation-phase1.md`

### Mutation Graph Linter — Phase 1 Post-Mortem Findings (2026-08-31)

**What Phase 1 delivered:**
- Complete expand-and-lint pipeline: Lua edge extractor (437 LOC) + Python meta-lint (200+ rules) + wrapper scripts (PS/sh)
- 12 extraction mechanisms (5 core + 7 creature-specific), all tested
- 3 CLI modes: default report, --targets, --json
- 71 tests (58 edge extractor + 13 integration), 100% pass rate
- CI integration in squad-ci.yml, docs, skill file
- 3 GitHub issues filed (#403, #404, #405) for 5 broken edges (2 unique targets)
- All 3 waves (WAVE-0/1/2) completed, both gates (GATE-0/1) passed

**What the design doc specifies that wasn't built (deferred to Phase 2):**
1. Multi-hop chain validation (D-MUTATION-CYCLES-V2) — BFS/DFS traversal, cycle detection, unreachable node detection
2. parts[] extraction — composition edges (different from mutation edges)
3. Full Python lint pipeline in squad-ci.yml (only edge check present; Python step deferred)

**Bart's post-mortem:** 100% design coverage, zero gaps. Recommended filing issues (done), then Phase 2 for multi-hop + parts[] as nice-to-have.

**Nelson's post-mortem:** 71/71 tests pass, 12/12 mechanisms tested (including synthetic for on_tool_use.when_depleted). Identified 8 untested edge cases and 6 integration gaps for Phase 2. PowerShell wrapper e2e test still pending.

**Chalmers' post-mortem:** 100% plan adherence, zero gate failures, zero rework. Recommended "Option B — Lightweight Phase 2" (1-2 waves, 4-6 hours) for multi-hop chains + parts[] extraction. Not blocking production.

**Brockman's post-mortem:** Docs scored 9/10 completeness, 8/10 quality. No critical gaps. Minor suggestions: JSON example in user guide, creature pattern grouping, CI integration example. Phase 2 would need ~5 doc updates + 2 new docs.

**My analysis of current codebase state (live data):**
- 206 files scanned, 66 edges, 5 broken (2 unique targets), 1 dynamic
- 5 objects are both targets AND sources (multi-hop chains exist): matchbox↔matchbox-open, cloth→bandage/rag/terrible-jacket, wolf-meat→cooked-wolf-meat, poison-gas-vent→poison-gas-vent-plugged
- 3 objects use parts[]: candle-holder, nightstand, poison-bottle (inline definitions, not file references)
- Issues #403, #404, #405 still OPEN — broken edges not yet fixed
- Max chain depth observed: 2 hops (matchbox→matchbox-open→matchbox is a cycle; cloth has 3 outgoing but no confirmed 3-hop chain)

### Joined 2026-03-28
- Inheriting lint system from **Bart** (architecture, edge extractor), **Nelson** (tests), **Lisa** (validation specs), **Gil** (CI integration)
- System is live: WAVE-0/1/2 complete, WAVE-3+ planned
- No open technical debt in core (Phase 1 proven with 83/83 objects parsing successfully)
