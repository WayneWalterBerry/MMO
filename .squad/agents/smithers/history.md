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

### 2026-07 — Phase 4 Silk Wiring Bugs (2 fixes)

**Bug 1: Identical-item disambiguation bypass** — `_try_room_scored()` in helpers.lua fired disambiguation when multiple objects with the same `id` tied on adjective score (e.g., 3 silk-bundles on the floor from killed spiders). Added an `all_same_id` check after tie detection: if every top-scoring match shares the same base `id`, return the first one. Fungible items don't need disambiguation.

**Bug 2: Lua pattern dash in crafting ingredient match** — `obj.id:match("^" .. ingredient.id)` silently failed for any hyphenated id like "silk-bundle" because `-` is a lazy quantifier in Lua patterns. Replaced all 6 occurrences in crafting.lua (craft handler + sew handler) with `string.find(obj.id, ingredient.id, 1, true) == 1` for plain-string prefix matching. **Lesson:** Never use raw Lua `match()` with user-facing object IDs that contain dashes — always use `string.find` with `plain=true`.

### 2026-07 — Movement + Exit Door Resolution (#388, #387) — 43 assertions fixed

**Bug 3: Movement handler missing legacy exit support (#388, 31 assertions)** — `handle_movement()` in `movement.lua` only resolved portal-based exits (D-PORTAL-ARCHITECTURE). After the portal code block, it fell through to "You can't go that way" for ALL legacy `room.exits` entries. Two fixes: (1) Added legacy exit handling after portal resolution — checks hidden/locked/closed state, then navigates with full room hooks (on_exit_room, on_enter_room, visit tracking, emit_player_enters). (2) Added exit keyword search so `go wooden door` / `enter closet` resolves exits by keyword, name, or target room id when DIRECTION_ALIASES doesn't match. **Lesson:** When a new system (portals) is added alongside a legacy system (room.exits), the handler must fall through to legacy when the new system doesn't match — not short-circuit to failure.

**Bug 4: Exit doors invisible to open/close/unlock/lock (#387, 12 assertions)** — Container verb handlers only searched registry objects via `find_visible()`. Exit doors live in `room.exits` as plain tables, not registered objects, so they were invisible. Added `find_exit_by_keyword()` helper to `search.lua` — searches exits by direction name, keyword array, name substring, and target room id. All four handlers now fall through to exit door resolution when `find_visible` returns nil. Supports: key matching (auto-find in hands), "with Y" syntax parsing for unlock, wrong-key rejection, already-open/closed messages, and lock (auto-closes + locks). **Lesson:** Exit doors are NOT registry objects — any verb that acts on doors must explicitly search `room.exits` as a fallback after `find_visible`.
