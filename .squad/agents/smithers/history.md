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

### 2026-07 — Parser/Verb Bug Fixes (#381, #374, #373, #383) — 10 assertions fixed

**Bug 5: Verb alias routing — carve→butcher, grab→take (#381, 3 assertions)** — `combat.lua` unconditionally set `handlers["carve"] = handlers["slash"]`, overriding butchery.lua's conditional alias. Removed the combat override. Also, `init.lua` wrapped `grab` with a creature-detection function, breaking identity with `take`. Restructured to wrap `take` instead and re-alias `grab = take`, preserving both creature-catch functionality and function identity. **Lesson:** When multiple verb modules alias the same word, order-dependent unconditional assignment creates hidden conflicts. Use conditional guards (`if not handlers[x]`) or single-source-of-truth ownership.

**Bug 6: Tier 2 benchmark edge cases — 3 misrouted inputs (#374, 3 assertions)** — C-97 "match match" → drop (should be ignite): tokenizer deduplicates repeated words, leaving only ["match"]; BM25 length normalization favored shorter "drop" phrases. Fixed by adding a dedicated index phrase. C-98 "the candle on the nightstand" → drop (should be ignite): all content words are nouns; "nightstand" had higher IDF than "candle". Fixed by adding multi-noun index phrase that matches both tokens. E-136 "fly north" → look (should be no match): "north" token matched "look at north" phrases with high IDF score. Added P6 unknown lead-word guard — rejects inputs where the first token is completely foreign to the game world (not in any phrase, verb table, or noun table). **Lesson:** BM25 doc-length normalization can cause counterintuitive results with very short docs; targeted index phrases are the cleanest fix. For impossible verbs, an early rejection gate prevents noun-only false positives.

**Bug 7: part_contents doesn't resolve part name (#373, 1 assertion)** — `resolve_part_display()` in `narrator.lua` only matched parts by surface mapping or exact key. When surface_name="inside" and the parent had `parts = { compartment = {...} }`, neither matched. Added a third fallback: use the first available part name, which is always more descriptive than a generic spatial term. **Lesson:** Narrator resolution should degrade gracefully through named parts before falling back to raw spatial terms.

**Bug 8: Burn "no flame" message (#383)** — Already fixed in a prior session (line 730 of fire.lua already reads "You have no flame..."). All 17 burn tests pass. No changes needed.

### 2026-07 — Search/Find Bugs (#385, #384, #377) — 9 assertions fixed

**Bug 5: Search/find doesn't discover room objects (#385, 4 assertions)** — `traverse.step()` suppressed all narration for objects with surfaces during undirected sweeps (room sweep and scoped search). Objects like the nightstand were invisible to "search around." Added `narrator.enumerate_room_object()` — a brief one-liner listing the object name without the "nothing there" suffix. Undirected sweeps of surfaced objects now emit this enumeration. **Lesson:** When suppressing parent narration to avoid contradicting surface contents (#40), ensure undirected sweeps still report object existence.

**Bug 6: Search opens closed containers (#384, 4 assertions)** — `containers.open()` in traverse.step permanently set `is_open=true`/`open=true`/`_state="open"` on every container the search peeked into. Added `peek_open()` helper that saves/restores open/closed/FSM state after calling `containers.open()`, preserving only the `accessible=true` flag. Replaced all 5 `containers.open()` calls in traverse.step. Updated 8 related tests across 4 test files to check `accessible` instead of `is_open`. **Lesson:** Search peek semantics: `accessible` tracks whether items are reachable (for take/get), while `is_open` tracks visual/narrative state. These are independent.

**Bug 7: Search pillow doesn't find hidden pin (#377, 1 assertion)** — Two issues: (1) `build_queue()` scope resolution only checked proximity_list and parts, not surface contents of room objects. The pillow (on the bed's top surface) wasn't findable. Extended scope resolution to search surface contents. (2) Non-container inaccessible surfaces were unconditionally blocked. Split the check: covering objects (rug) stay blocked (#26), non-covering objects (pillow) get a tactile peek that reports contents by feel. **Lesson:** Scope resolution must walk the full containment hierarchy (room → object → surfaces → children), not just top-level proximity list. Also, `covering` attribute distinguishes spatial hiding from mere inaccessibility.

### 2026-07 — 5 Parser/Verb Playtest Bugs (#318, #342, #306, #305, #310) — 12 assertions

**Bug 8: 'exits' command not recognized (#318, 5 assertions)** — No `exits` verb handler existed. Added `handlers["exits"]` to `movement.lua` that iterates `room.exits`, filters hidden exits, and displays direction + name + locked/closed state. Reuses the same rendering pattern as the look handler's room view. **Lesson:** Common text adventure commands like `exits`, `inventory`, `help` need explicit verb handlers even when the info is available elsewhere (e.g., `look` already shows exits).

**Bug 9: 'look the rat' article not stripped (#342, 2 assertions)** — The look handler's "look X" shorthand path passed the raw noun (including leading articles) to `find_visible()`. While `find_visible()` already strips articles internally, added explicit article stripping in the handler for consistency with the "look at X" code path. **Lesson:** Defense-in-depth — strip articles at the handler level AND in find_visible, so neither depends solely on the other.

**Bug 10: 'stomp spider' not recognized (#306, 2 assertions)** — `stomp` was not registered as a verb alias. Added `stomp`, `trample`, `stamp`, `squash`, `crush`, `squish` as aliases for the `hit` handler chain in `init.lua`. These route through the creature-combat check (hit→find_creature→attack) before falling through to self-infliction. **Lesson:** When adding creature combat aliases, they must go on the WAVE-4 extended `hit` handler (which has creature fallback), not on the original `combat.lua` hit handler (which is self-infliction only).

**Bug 11: 'use bandage' not recognized (#305, 1 assertion)** — The `use` handler in `meta.lua` checked for FSM "use" transitions and `on_use` callbacks, but bandage objects use the `apply` handler with the dual-binding treatment system. Added a `cures`-property check: if the object has `cures`, delegate to `handlers["apply"]`. The #329 no-injury guard fires first. **Lesson:** Generic verbs like "use" should check for domain-specific properties (cures → apply, flammable → light, etc.) before falling through to "don't know how to use."

**Bug 12: 'with' tool modifier ignored for unlock/lock (#310, 2 assertions)** — `find_visible(ctx, "padlock with brass key")` failed because "padlock with brass key" isn't a valid keyword. Added "with X" stripping at the top of both `unlock` and `lock` handlers in `containers.lua`, before `find_visible()`. The exit-door fallback already handled this, but only fired when `find_visible` returned nil. Now both paths share the pre-parsed `target_noun`. **Lesson:** Tool modifiers ("with X", "using X") should be stripped in the verb handler before any object resolution, not just in fallback paths.
