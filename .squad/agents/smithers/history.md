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

### 2026-07 — 6 Parser/Verb Playtest Bugs (#335, #313, #309, #320, #321, #307) — 13 assertions

**Bug 13: Fuzzy matches 'meat' to 'rug' (#335, 3 assertions)** — Fuzzy typo tolerance length ratio threshold (75%) was too permissive. "meat"(4 chars) vs "mat"(3 chars) had ratio 3/4=0.75, exactly meeting the threshold, producing a score-3 typo match against the rug. Raised the length ratio from 0.75 to 0.80 in `fuzzy.score_object()`. Now "meat" vs "mat" (ratio 0.75 < 0.80) is rejected, while same-length typos like "candel"→"candle" (ratio 1.0) still pass. **Lesson:** Cross-length typo matching needs tighter ratio checks. Short words (3-4 chars) are especially vulnerable to false positives because one character difference represents 25-33% of the word.

**Bug 14: 'light candle' targets holder instead of candle (#313, 2 assertions)** — The existing #313 fix in fire.lua only checked `obj.parts` for nested lightable items. The candle-holder also stores the candle in `obj.contents` (state-defined `contents = {"candle"}`). Extended the light handler to also search `obj.contents` for nested lightable items. Also added "with X" stripping from keyword before parts/contents search. **Lesson:** Composite objects may store children in `parts` (structural) AND `contents` (state-defined). Both must be checked when searching for nested items.

**Bug 15: Door disambiguation shows identical names (#309, 1 assertion)** — `_try_room_scored()` built disambiguation prompts using raw `obj.name`, producing "Which do you mean: an open iron-bound door or an open iron-bound door?". Two fixes: (1) Detect duplicate names in the prompt and add direction qualifiers from `room.exits` — now shows "the south iron-bound door or the north iron-bound door". (2) Skip fuzzy fallback when `disambiguation_prompt` is already set by scored search, preventing the direction-qualified prompt from being overwritten. **Lesson:** Disambiguation prompts must differentiate objects visually. When names collide, use spatial context (direction, location) as qualifiers.

**Bug 16: 'insert key into lock' misrouted to close (#320, 3 assertions)** — No "insert" pattern existed in the compound action preprocessor. The unmodified input fell through to Tier 2 semantic matching which misrouted to "close". Added "insert X into Y" pattern to `compound_actions.lua` — routes to "unlock Y with X" for lock/keyhole targets, "put X in Y" for general containers. **Lesson:** Every natural-language verb players might use needs explicit compound action routing. Unhandled verbs fall through to semantic matching which can produce absurd results.

**Bug 17: 'use key on padlock' not recognized (#321, 2 assertions)** — The compound_actions preprocessor correctly converts "use key on padlock" → "unlock padlock with brass key". But the unlock handler's exit-door fallback couldn't find "padlock" because exit doors use keywords like "door"/"iron-bound door". Added fallback: when `find_exit_by_keyword()` fails for a noun containing "lock"/"padlock", search all room exits for any locked exit. **Lesson:** Players refer to door components (padlock, lock, keyhole) independently. The unlock handler must resolve these component nouns to the parent exit door.

**Bug 18: 'craft' with no noun (#307, 2 assertions)** — Already fixed. The handler returns "Craft what? (Try: craft silk-rope)" for empty noun input. Added regression tests for craft and make aliases to prevent future breakage.

### 2026-07 — 3 Disambiguation/Verb Bugs (#344, #322, #299) — 11 assertions

**Bug 19: Attack creature disambiguation uses non-standard prompt (#344, 3 assertions)** — `find_creature()` in `init.lua` used `"Which one? X, Y?"` format and set `ctx.disambiguation_prompt` as a table (array of names) instead of a string. Changed to standard `"Which do you mean: X or Y?"` format matching `_try_room_scored()` in search.lua. Now `ctx.disambiguation_prompt` is always a string, consistent across creature and object disambiguation. **Lesson:** All disambiguation prompts must use the same string format — downstream code (e.g., `err_not_found()` in helpers.lua) expects `ctx.disambiguation_prompt` to be a printable string, not a table.

**Bug 20: 'unbar door' says 'You aren't holding that' (#322, 5 assertions)** — `unbar` was not registered as a verb handler. Player input fell through to Tier 2 semantic matching which misrouted to the `drop` handler, producing the misleading "You aren't holding that" error. Added `handlers["unbar"]`, `handlers["bar"]`, and aliases `"lift bar"`, `"remove bar"` to `traps.lua` using the existing `fsm_interact()` pattern (same as breathe/trigger/step). FSM transitions on portal objects (e.g., `bedroom-hallway-door-south.lua`) already declared `verb = "unbar"` — the new handler correctly routes to `try_fsm_verb()`. **Lesson:** Every verb that appears in FSM `transitions.verb` fields must have a registered handler, or Tier 2 semantic matching will misroute it. The `fsm_interact` pattern in traps.lua is the correct generic handler for FSM-only verbs.

**Bug 21: Disambiguation for identical items gives no way to differentiate (#299, 3 assertions)** — `_try_room_scored()` in search.lua only added direction qualifiers for doors with identical names (#309 fix). Non-door objects with the same display name showed identical strings: "Which do you mean: a tallow candle or a tallow candle?". Added ordinal fallback: when `has_dupes` is true and `_door_direction()` returns nil, prepend ordinals ("the first", "the second", etc.) to produce "Which do you mean: the first tallow candle or the second tallow candle?". The existing fungible-item bypass (all_same_id from #362) still auto-selects the first item for truly identical objects like silk-bundles. **Lesson:** Disambiguation prompts must always provide visually distinct options. Direction qualifiers work for doors; ordinals are the universal fallback for any objects sharing a name.

### 2026-07 — 4 Playtest Bug Fixes (#402, #399, #398, #401) — 12 assertions

**Bug 22: Unbar prints success but door stays barred (#402, 3 assertions, HIGH)** — `fsm_interact()` in `traps.lua` called `try_fsm_verb()` which only processed effects without changing state (the comment explicitly says "Does NOT mutate obj._state directly"). Rewrote `fsm_interact` to call `fsm_mod.transition()` first (like containers.lua's open/close handlers), which properly applies `_state` change, keyword mutations via `apply_mutations()`, and bidirectional portal sync. Falls through to `try_fsm_verb` for effect-only transitions. Also fixed `apply_mutations()` in `fsm/init.lua` to handle table values for `add`/`remove` (e.g., `remove = {"barred", "iron bar"}`). Updated gas vent test to reset shared `_state` since `fsm_interact` now correctly changes state. **Lesson:** Every FSM verb handler that should change state must call `fsm.transition()`, not just `try_fsm_verb()`. The latter is effects-only — it processes `pipeline_effects` without state mutation.

**Bug 23: 'strike match' resolves to trap door (#399, 2 assertions)** — When the match object isn't directly visible (inside matchbox/drawer), `find_visible(ctx, "match")` falls through to fuzzy noun resolution which matches "match" to the trap door. Added compound action rule in `compound_actions.lua`: `"strike match"` and `"strike a match"` transform to `"light match"`, routing through the light handler with proper match-finding logic. The `"strike X on Y"` pattern is NOT transformed — the strike handler already handles two-object resolution. **Lesson:** Common natural-language phrases that collide with fuzzy matching should be intercepted in the compound_actions preprocessor before they reach noun resolution.

**Bug 24: 'fuel lantern' routes to medical treatment (#398, 3 assertions)** — `"fuel"` was not registered as a verb handler. The lantern FSM correctly listed `"fuel"` as an alias for `"pour"`, but the verb dispatch table in `survival.lua` only had `"spill"` and `"fill"` as aliases. Without `handlers["fuel"]`, input fell through to Tier 2 embedding matching which misrouted to the medical `apply` handler. Added `handlers["fuel"] = handlers["pour"]` and `handlers["refuel"] = handlers["pour"]`. **Lesson:** Every verb alias in FSM transition definitions must also be registered as a handler — FSM aliases only work AFTER the verb handler dispatches, not before.

**Bug 25: Courtyard dark despite moonlight + cat grammar (#401, 4 assertions, LOW)** — Two issues: (1) `get_light_level()` only checked artificial sources and daylight, ignoring `room.light_level`. Added ambient light check in `presentation.lua`: `light_level >= 2` → "lit", `>= 1` → "dim" (moonlight), `nil`/`0` → unchanged. (2) `actions.lua` concatenated exit direction name directly (`"scurries " .. direction`), producing "scurries window" for non-cardinal exits. Added cardinal direction check — non-cardinal exits get "through the" prefix: "A grey cat scurries through the window." **Lesson:** Room ambient light must be checked as a separate layer after artificial sources and daylight. Creature movement messages need preposition logic for named exits vs cardinal directions.

### 2026-07 — Tier 2 Benchmark Expansion: 147 → 200 Tests (31 new failures)

**Task:** Wayne directive — benchmark at 100% means "we can never get better." Expanded from 147 to 200 test cases across 5 new aspirational categories designed to find the parser's real limits.

**Result:** 169/200 (84.5%) — 31 failing cases identify concrete parser improvement opportunities.

**New categories added (53 cases total):**

- **G: Complex multi-object interactions (11 cases, 7 fail)** — Prepositional phrases with multiple game nouns. Key failures: BM25 picks wrong noun in "put X on Y" (nightstand wins over key), "cut X with Y" (knife wins over cloth), and "take X from Y" (matchbox wins over match). Non-indexed verbs like "hide", "wrap", "stuff" either misroute ("stuff" → "snuff" via typo match) or fail to score.

- **H: Ambiguous pronouns/references (11 cases, 8 fail)** — Pronouns stripped as stop words leave bare verbs below threshold. "put it there", "open the first one", "examine the other one" all score 0.0. "give me the key" also fails (0.0) — "give" has no index presence. Surprise: "use this on that" incorrectly matches "ignite portrait" (score 5.4) via residual "use" token matching. "yes the candle" incorrectly matches "drop candle" (score 4.1) via "let go of" phrase.

- **I: Natural language variations (11 cases, 11 fail)** — Hardest category. Slang ("lemme", "gonna", "yo", "im"), txtspeak ("u"), question forms ("where is", "how do I"), and heavy typos ("breka", "srch", "exmne") all produce 0.0 scores. Even mild variation "whats in the nightstand" misroutes to "examine" instead of "search". The P6 unknown-lead-word guard rejects all inputs where the first token is foreign to the index.

- **J: Context-dependent commands (10 cases, 1 fail)** — Most pass correctly as no-match (the parser correctly rejects "again", "undo", "wait", "go back"). One fail: "what about the candle" routes to "help" (via "what can i do" phrase) instead of expected "examine".

- **K: Adversarial/tricky inputs (10 cases, 4 fail)** — Negation is the critical weakness: "don't open the door" → "don trap-door" (score 8.3), "don't drop the knife" → "don knife" (score 10.3) — the parser matches "don't" to the "don" (clothing) verb. "what if I eat the key" → "help" via "what can i do". "is it possible to open the wardrobe" → "open wardrobe" (score 7.0) — correct action but wrong intent.

**Improvement roadmap from failures:**
1. **Multi-noun disambiguation** (G): Need first-noun-is-target heuristic for "V X prep Y" patterns
2. **Verb synonym expansion** (G/H): "hide"→"put", "give"→"get", "stuff"→"put", "show"→"look"
3. **Slang/contraction preprocessing** (I): "lemme"→"let me", "gonna"→"going to", "im"→"I'm", "u"→"you", "whats"→"what is"
4. **Question-form routing** (I/J): "where is X"→"look X", "how do I X"→X
5. **Negation detection** (K): Must detect "don't"/"stop"/"not" before stripping and reject or flag
6. **Heavy typo tolerance** (I): Current typo correction requires >4 char words; short mangled tokens fail
7. **P6 guard too aggressive** (I): Rejects valid inputs when lead word is unknown slang/contraction
