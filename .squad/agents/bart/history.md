# Bart — History (Summarized)

## Project Context

- **Project:** MMO — A text adventure MMO with multiverse architecture
- **Owner:** Wayne "Effe" Berry
- **Stack:** Lua (engine + meta-code), cloud persistence
- **Key Concepts:** Each player gets their own universe instance with self-modifying meta-code. Objects are rewritten (not flagged) when state changes. Code IS the state.

## Core Context (Summarized)

**Role:** Architect — engine design, verb systems, FSM mechanics, mutation patterns, puzzle systems

**Major Systems Built:**
- **Engine Foundation:** Loader (sandboxed execution), Registry (object storage), Mutation (via loadstring), Loop (REPL)
- **Verb System:** 31 verbs across 4 categories (sensory, inventory, object interaction, meta); tool resolution (capabilities-based, supports virtual tools like blood)
- **FSM Architecture:** Inline state machines for all objects; timer tracking (two-phase tick), room pause/resume, cyclic states
- **Containment:** 4-layer validation (identity, size, capacity, categories)
- **Composite Objects:** Single-file pattern with detachable parts; two-hand carry system
- **Skill System:** Binary table lookup; skill gates; crafting recipes on materials
- **GOAP Planner:** Tier 3 backward-chaining; prerequisite resolution; in-place container handling
- **Terminal UI:** Split-screen (status bar + scrollable output + input); pure Lua; ANSI support
- **Multi-Room Engine:** All rooms loaded at startup; shared registry; per-room FSM ticking

**Architectural Patterns (Foundational):**
- Objects use FSM states with sensory text; mutation is code-level only
- `engine/mutation/` is ONLY code that hot-swaps objects
- Tool resolution: capabilities (not tool IDs)
- Sensory verbs work in darkness
- Skills: double-dispatch gating (skill gate + tool gate)

## Learnings

- **Brass Key/Padlock Fix (Phase 4 walkthrough bug):** The `unlock` and `lock` verb handlers in `engine/verbs/containers.lua` were stubs — they found the target object but always printed "You can't unlock that" without attempting FSM transitions. Fixed by implementing full FSM transition logic (matching the `open`/`close` pattern) with `requires_tool` capability checks. Additionally, all three key objects (brass-key, iron-key, silver-key) lacked `provides_tool` fields, so `find_tool_in_inventory()` could never match them. Added `provides_tool = "{key-id}"` to each. Two-bug fix: engine verb handler + object metadata. Bidirectional portal sync already handled by `fsm.transition()` calling `sync_bidirectional()`.

- **Engine Code Review (2026-03-28):** Full Phase 1 senior review of all 68 engine files (~26K LOC). Identified 6 files for splitting: `verbs/helpers.lua` (1634→5 modules), `parser/preprocess.lua` (1282→6 modules), `verbs/sensory.lua` (1113→3 modules), `loop/init.lua` (624→4 modules, highest contention at 52 commits), `search/traverse.lua` (871→3 modules), `injuries/init.lua` (540→3 modules). Critical finding: `loop/init.lua` has zero test coverage despite being most-edited file. LLM sweet spot confirmed at 150-400 lines per module. Review deliverable: `docs/architecture/engine/refactoring-review-2026-03-28.md`. Key dependency: `verbs/helpers.lua` is required by all 17 verb modules — splitting it gives biggest context reduction. Sequencing: Nelson must write test baselines before any splitting begins.

- **Linter Improvement Implementation Plan (2026-07-29):** Wrote 6-wave, 5-gate implementation plan for meta-lint improvement across 3 phases. Key architecture decisions: (1) Multi-module structure (lint.py, config.py, rule_registry.py, cache.py, squad_routing.py) enables parallel agent work — different agents edit different modules in the same wave. (2) lint.py is the bottleneck file (~2,538 lines) — only one agent per wave can touch it, which drives wave serialization for bug fixes. (3) EXIT-* rules already implemented and registered (7/7) — WAVE-4 is verification, not greenfield. (4) CREATURE-* rules are the largest new work (0/20 exist) — ~150 lines of new validator code. (5) Fix-safety schema already exists in rule_registry.py (fixable, fix_safety fields) but only 5 of 164 rules have explicit classifications — WAVE-2 audit + WAVE-3 integration completes this. (6) No test/linter/ directory exists — biggest quality gap, addressed in WAVE-0. (7) Environment variants are a config extension, not a new module. Plan written in one pass (~51KB) rather than chunked — at the upper limit of single-pass but successful.

- **Worlds Implementation Plan — Phase 1 (2026-08-21):** Wrote 4-wave, 3-gate implementation plan for World-driven engine boot. Key architecture decisions: (1) New module `engine/world/init.lua` rather than inlining in main.lua — testable, aligns with refactoring direction (D-ENGINE-REFACTORING-WAVE2). (2) Dependency injection pattern: world module has zero `require()` calls; loader, read_file, and templates all passed as parameters. Same isolation pattern as engine/loader. (3) No hardcoded fallback — zero worlds = FATAL error, not silent degradation. Fail fast. (4) World NOT registered in object registry — it's metadata on `context.world`, not a game entity. (5) One-directional relationship: World → Level (no `world_id` on levels). (6) `list_lua_files` duplicated in world module rather than extracting shared utility — acceptable for Phase 1 scope; D-ENGINE-REFACTORING-WAVE2 handles extraction later. (7) Level path resolution uses `level_dir` parameter, not raw `file` field from world definition — avoids cross-platform path issues. (8) Plan written in one pass (~39KB), under the 40KB chunking threshold. Wave structure: WAVE-0 pre-flight, WAVE-1 loader+tests parallel, WAVE-2 boot integration+tests parallel, WAVE-3 docs+LLM verification. Only main.lua is modified among existing files; world module is purely additive.

- **Phase 3 Helpers Split (2026-08-21):** Split `engine/verbs/helpers.lua` into modular helpers (`helpers/core.lua`, `inventory.lua`, `search.lua`, `tools.lua`, `mutation.lua`, `combat.lua`, `portal.lua`) with a thin re-export layer to preserve the API. Maintained verb behavior via shared helpers and dependency injection, resolved alias conflicts (`carve`) by guarding butchery alias registration, and added `core.hobj` to share hand-resolution across modules. Test suite re-run: remaining failures match pre-existing baseline (silk-bandage healing, predator-prey, spider-web, room override).
- **Phase 3 Preprocess Split (2026-08-21):** Split `engine/parser/preprocess.lua` into submodules (`preprocess/data.lua`, `words.lua`, `core.lua`, `phrases.lua`, `compound_actions.lua`, `movement.lua`, `split.lua`) with a thin orchestrator preserving pipeline order and exported API. Removed cross-module cycles by having phrase transforms call `core.strip_articles`. Tests re-run: preprocess tests pass; full suite shows the same pre-existing failures (silk-bandage healing, predator-prey, spider-web, room override).
- **Phase 3 Sensory Split (2026-08-21):** Split `engine/verbs/sensory.lua` into `verbs/sensory/` modules (look, touch, search, smell, taste, listen) with a wrapper that registers handlers in the original order. Sensory tests pass; full suite retains the same baseline failures (silk-bandage healing, predator-prey, spider-web, room override).
- **Phase 3 Traverse Effects Split (2026-08-21):** Split `engine/traverse_effects.lua` into `engine/traverse_effects/registry.lua` (registry/process) and `engine/traverse_effects/effects.lua` (built-in handlers), with a wrapper that loads built-ins and preserves the original API. Full suite retains the same baseline failures (silk-bandage healing, predator-prey, spider-web, room override).
