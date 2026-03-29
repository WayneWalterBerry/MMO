# Decision: Worlds WAVE-0 + WAVE-1 Loader Complete

**Author:** Bart (Architect)
**Date:** 2026-03-30
**Affects:** Moe, Nelson, Brockman

## What happened

Executed WAVE-0 (infrastructure) and WAVE-1 (world loader) from `projects/worlds/worlds-implementation-phase1.md`.

### Delivered:
- `src/engine/world/init.lua` — world loader module (discover, validate, select, get_starting_room, load)
- `test/worlds/test-world-loader.lua` — 16 tests, all passing
- `test/run-tests.lua` — registered `test/worlds/` in test_dirs and source_to_tests
- Board updated: `projects/worlds/board.md`

### Design decisions:
1. **Dependency injection** — zero `require()` calls in the world module. All dependencies (list_lua_files, read_file, load_source) passed as parameters.
2. **Validation requires non-empty `levels` array and non-empty `starting_room` string** — empty values fail validation, not just nil.
3. **Tests include real world-01.lua integration** — not just mocks. Discovers and validates the actual file on disk.

### What's next:
- **WAVE-1 remaining:** Nelson writes `test-world-definition.lua` (world template + world-01 field assertions)
- **WAVE-2:** Bart wires `main.lua` boot to use world loader, Nelson writes boot tests
- **WAVE-3:** Brockman writes docs, Nelson does LLM walkthrough

### Note for Moe/Flanders:
The plan references `the-manor.lua` but the actual file is `src/meta/worlds/world-01.lua` with `id = "world-1"`. The loader is generic — it discovers any `.lua` file in `src/meta/worlds/`. No rename needed unless the team decides otherwise.
