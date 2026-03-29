# Decision: Sound WAVE-0 Bart Track Complete

**Author:** Bart (Architecture Lead)
**Date:** 2026-08-01
**Status:** Delivered
**Scope:** WAVE-0 Track 0A — Sound Manager Module

## What Was Delivered

1. **`src/engine/sound/init.lua`** — Sound manager with 21-method API, OOP metatables, driver injection, concurrency limits (4 oneshots / 3 ambients), pcall-wrapped driver calls.
2. **`src/engine/sound/defaults.lua`** — 15-entry verb-to-sound fallback table.
3. **`src/engine/sound/null-driver.lua`** — No-op driver implementing full interface contract (7 methods).
4. **`test/sound/test-sound-manager.lua`** — 47 tests across 12 suites. Registered in run-tests.lua.

## API Frozen at GATE-0

Per v1.1 contract, the following methods exist and are stable:
- `M.new()`, `M:init(driver, options)`, `M:shutdown()`
- `M:scan_object(obj)`, `M:flush_queue()`
- `M:play(filename, opts)`, `M:stop(play_id)`, `M:stop_by_owner(owner_id)`
- `M:enter_room(room)`, `M:exit_room(room)`, `M:unload_room(room_id)`
- `M:trigger(obj, event_key)` — resolution chain: obj.sounds → defaults → nil
- `M:set_volume(level)`, `M:mute()`, `M:unmute()`, `M:set_driver(driver)`

## Design Decisions

- **Volume range:** 0.0–1.0 (not 0–100). Matches Web Audio API convention. Clamped.
- **Driver interface:** Colon (method) syntax. 7 methods: `load`, `play`, `stop`, `stop_all`, `set_master_volume`, `unload`, `fade`.
- **Concurrency:** Enforced via eviction — oldest-first for oneshots, FIFO for ambients.
- **Null driver:** Returns the filename as a handle (supports identity checks in tests).

## Who This Affects

- **Gil:** Web driver must implement the 7-method driver interface contract.
- **Nelson:** Mock driver pattern established in test file — use `make_mock_driver()` pattern.
- **Flanders/Moe:** Object `sounds` table format validated via `scan_object()`.
- **Smithers:** `trigger(obj, event_key)` is the verb integration point.

## Test Baseline

- 259 test files, all passing. Zero regressions from 258-file baseline.
