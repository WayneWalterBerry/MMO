# UI/Parser Code Ownership Map

**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-22  
**Based on:** Deep code review of all `src/engine/` source files

---

## Smithers Owns (UI Engineer)

| File | Purpose | Key Functions | Notes |
|------|---------|---------------|-------|
| `src/engine/parser/init.lua` (69 lines) | Tier 2 parser wrapper — loads embedding index, exposes `fallback()` for game loop | `parser.init(assets_root, debug)` L18, `parser.fallback(instance, input_text, context)` L35 | Clean, focused module. THRESHOLD=0.40 at L12. Diagnostic output goes to stderr (good). User-facing "I don't understand that." at L63 |
| `src/engine/parser/embedding_matcher.lua` (241 lines) | Tier 2 matching engine — tokenizes input, compares against phrase dictionary via Jaccard+bonus similarity | `matcher.new(index_path, debug)` L159, `matcher:match(input_text)` L210, `tokenize(text)` L90, `jaccard_with_bonus()` L111, `correct_typos()` L54, `levenshtein()` L27 | D-BUG018 implemented at L62-63 (short words skip fuzzy). STOP_WORDS at L15. Substring bonus at L131-147. Solid code quality |
| `src/engine/parser/json.lua` (119 lines) | Minimal JSON decoder for loading embedding-index.json | `json.decode(s)` L114, `decode_value()` L91, `decode_string()` L12, `decode_object()` L69, `decode_array()` L52 | Minimal but correct. Non-ASCII → "?" placeholder at L38 (acceptable for ASCII phrase data). No encoder needed |
| `src/engine/parser/goal_planner.lua` (442 lines) | Tier 3 GOAP backward-chaining planner — resolves tool prerequisites, builds multi-step plans | `goal_planner.plan(verb, noun, ctx)` L391, `goal_planner.execute(steps, ctx)` L427, `plan_for_tool(capability, ctx, visited, depth)` L280, `try_plan_match(entry, ctx, visited)` L191, `find_all(ctx, keyword)` L93, `resolve_target(ctx, noun)` L353 | MAX_DEPTH=5 at L8. VERB_SYNONYMS at L10. Handles nested containers, spent-match cleanup, spent-match hand drops. `is_spent_or_terminal()` at L35 is comprehensive |
| `src/engine/display.lua` (85 lines) | Word-wrap utility — replaces global `print()` with wrapping version, routes through UI when active | `display.word_wrap(text, width)` L21, `display.install()` L66 | WIDTH=78 default at L12. Preserves leading whitespace for indented lists. Handles UI routing at L76-78 |
| `src/engine/ui/init.lua` (370 lines) | Split-screen terminal UI — ANSI escape codes for status bar, scrollable output, input line | `ui.init()` L206, `ui.output(text)` L241, `ui.input()` L270, `ui.status(left, right)` L258, `ui.scroll_up/down(n)` L309/L321, `ui.handle_scroll(input)` L332, `ui.prompt(msg)` L297, `ui.cleanup()` L359, `ui.refresh()` L353 | Pure Lua ANSI (no C libs). Max 500-line scrollback. Windows VT processing enabled at L222. Falls back to plain I/O when terminal too small (<8 rows) |
| `src/assets/parser/embedding-index.json` | Phrase dictionary — maps natural language phrases to verb+noun pairs | N/A (data file) | ~50 phrases. Also has `.json.gz` compressed copy. Embedding vectors present but ignored by Lua runtime (for future browser ONNX) |

---

## Shared (Smithers + Bart)

| File | Smithers's Concern | Bart's Concern | Boundary |
|------|-------------------|----------------|----------|
| **`src/main.lua`** (483 lines) | Welcome banner (L457-467), `display.install()` (L48), `ui.init()` (L52-58), `parser_mod.init()` (L282-285), `update_status()` (L413-452), CLI flag parsing `--debug`, `--no-ui` (L18-32) | Loader pipeline (L97-170), registry creation (L213-261), containment tree building (L228-261), player state init (L266-276), context assembly (L287-302), FSM init (L307-310), `on_tick()` (L315-399) | **Smithers owns lines 1-58 (setup), 282-285 (parser), 410-467 (status+welcome). Bart owns 63-276 (load/build), 287-399 (context+tick). Line 302 (`ui = ui_active and ui or nil`) is the handshake.** |
| **`src/engine/loop/init.lua`** (489 lines) | `parse()` L78, `preprocess_natural_language()` L86-257, compound command splitting L319-349, GOAP compound optimization L338-349, Tier 1→2→3 cascade L354-403, scroll handling L306-308, input/output L292-313, quit handling L362-410, error messages L396-401 | FSM tick phase L414-471, timed events tick L464-471, `on_tick` callback L474-476, game-over check L479-484, `cmd_look()` L18-74 (initial version, superseded by verbs look) | **Smithers owns the READ→PARSE→DISPATCH pipeline. Bart owns the POST-COMMAND TICK phase. `cmd_look` at L18 is a built-in fallback, but `handlers["look"]` in verbs/init.lua is the real implementation.** |
| **`src/engine/verbs/init.lua`** (4604 lines) | `handlers["help"]` L4543-4599 (help text), `handlers["look"]` L1082-1299 (room presentation, dim light preamble, exit formatting), `handlers["examine"]` L1301-1351 (darkness fallback to feel), `handlers["feel"]` L1418-1601 (tactile output), `handlers["smell"]` L1606-1668, `handlers["taste"]` L1673-1715, `handlers["listen"]` L1720-1783, `find_visible()` L371-521 (pronoun resolution "it"/"one"/"that"), `handlers["inventory"]` L2664-2715 (inventory display), error message text across all handlers, `format_time()` L785, `time_of_day_desc()` L792, `get_light_level()` L810-851, `handlers["time"]` L4095 | `matches_keyword()` L21, hand helpers L42-105, `find_part()`/`detach_part()`/`reattach_part()` L111-364, `find_in_inventory()` L526-570, tool resolution L576-659, `consume_tool_charge()` L664-679, `remove_from_location()` L684-766, `move_spatial_object()` L975-1071, `find_mutation()`/`perform_mutation()` L876-957, `spawn_objects()` L906-928, all FSM transition calls, all containment logic, crafting (sew/cut/prick/write/burn), movement L4326-4460, sleep L4104-4324, clock puzzle L4465-4537 | **Smithers owns all text presentation, sensory verb output, help system, error message wording, pronoun resolution, light-level-aware display logic. Bart owns all game state mutations, FSM interactions, containment, tool resolution, and core verb logic. The boundary is: Smithers controls HOW things are shown, Bart controls WHAT happens.** |

---

## Bart Owns (Architect)

| File | Purpose | Why Not Smithers |
|------|---------|-----------------|
| `src/engine/fsm/init.lua` (425 lines) | Table-driven FSM engine — state transitions, auto-transitions, timed events, threshold checking, material integration | Core engine internals. UI never calls FSM directly; verbs/loop mediate. Smithers consumes FSM output (transition messages) but doesn't drive transitions |
| `src/engine/containment/init.lua` (146 lines) | 4-layer containment validator — container identity, physical size, capacity, category accept/reject | Pure game logic (physics, capacity). UI doesn't validate containment. Error strings from containment are player-facing (borderline shared) but logic is Bart's |
| `src/engine/loader/init.lua` (160 lines) | Sandboxed Lua loader — `load_source()`, `resolve_template()`, `resolve_instance()`, `deep_merge()` | Build-time concern. Loads object definitions into safe environment. No UI touch point |
| `src/engine/materials/init.lua` (254 lines) | Material property registry — 17 materials with numeric properties (density, melting point, hardness, etc.) | Data layer. `materials.get(name)` used by FSM threshold checks. UI never queries materials directly |
| `src/engine/mutation/init.lua` (57 lines) | Hot-swap rewrite engine — `mutation.mutate()` replaces live objects while preserving containment | Principle 1 (code-derived mutation). Pure engine plumbing. UI is unaware of mutations |
| `src/engine/registry/init.lua` (129 lines) | Object store — register, get, remove, find_by_keyword, find_by_category, weight queries | Data layer. Smithers calls `registry:get()` indirectly through `find_visible()` in verbs but doesn't own the registry |

---

## Key Observations

### Parser Pipeline — Actual Code Flow

```
Player Input
  │
  ├─ loop/init.lua L302-316: Read input (UI-aware or io.read), trim, strip "?"
  │
  ├─ loop/init.lua L319-349: Split compound commands on " and "
  │     └─ L338-349: GOAP optimization — if last sub-command has a plan, skip earlier parts
  │
  ├─ loop/init.lua L354-357: preprocess_natural_language() → verb, noun (deterministic)
  │     └─ 30+ pattern rules (L86-257): questions→look, "take out"→pull, "put on"→wear, etc.
  │
  ├─ loop/init.lua L358-359: parse() → verb, noun (simple split on first word)
  │
  ├─ loop/init.lua L368-372: Prepositional strip ("light X with Y" → "light X")
  │
  ├─ loop/init.lua L374-381: Tier 3 GOAP check — plan prerequisites if needed
  │     └─ goal_planner.plan() → steps list, then goal_planner.execute()
  │
  ├─ loop/init.lua L383-384: Tier 1 — exact verb dispatch: context.verbs[verb]
  │
  ├─ loop/init.lua L386-392: Tier 2 — parser_mod.fallback() if Tier 1 misses
  │     └─ embedding_matcher:match() → best Jaccard score
  │     └─ threshold check (0.40), then dispatch handler
  │
  └─ loop/init.lua L396-401: All tiers failed → error message
```

### Text Output Path

```
Any code calls print()
  │
  ├─ display.install() replaced _G.print (L66-83 in display.lua)
  │
  ├─ If display.ui active (ui.is_enabled()):
  │     └─ ui.output(text) → wrap_text() → append_to_buffer() → redraw_output()
  │
  └─ If no UI:
        └─ display.word_wrap(text) → original_print(wrapped_text)
```

### Pronoun Resolution

```
find_visible() wrapper (verbs/init.lua L500-521):
  - "it", "one", "that" → resolve to ctx.last_object
  - Every successful find_visible() updates ctx.last_object
  - Also populates ctx.known_objects (used by GOAP Tier 3)
```

---

## Discrepancies Between Docs and Code

1. **ui.lua EXISTS** — My history noted "src/engine/ui.lua does not exist" but it's actually at `src/engine/ui/init.lua`. Mystery solved — it's a directory module, not a file. The UI is fully implemented (370 lines of pure ANSI).

2. **`cmd_look` duplication** — `loop/init.lua` L18-74 defines a `cmd_look()` that is registered as the fallback `look` handler (L275-277), but `verbs/init.lua` L1082-1299 defines a much more comprehensive `handlers["look"]` that overrides it. The loop version is dead code once verbs are wired (L405: `context.verbs = verbs_mod.create()`).

3. **Tier 3 runs BEFORE Tier 1 dispatch, not after** — My docs implied Tier 1→2→3 cascade, but GOAP actually runs at L374-381 *before* the Tier 1 dispatch at L383. It's a prerequisite planner, not a fallback. Tier 2 is the only true fallback (L386-392).

4. **`preprocess_natural_language` is richer than documented** — My history listed 8 patterns. The actual code has 30+ patterns covering questions, spatial movement, clock adjustment, compound phrases, sleep, wear/remove, crafting shortcuts.

5. **Verb count** — History said "31 canonical verbs." Actual count of primary `handlers["X"]` entries (excluding aliases): ~40+ primary verbs. With aliases, total entries exceed 80.

---

## Improvement Opportunities (Do Not Implement Yet)

### Parser Improvements
- **Tier 2 phrase dictionary is static** — `embedding-index.json` is loaded once. Could support hot-reload or per-room phrase additions
- **No disambiguation prompt** — When Tier 2 has multiple close matches (score within 0.05 of each other), it picks the best silently. Should prompt: "Did you mean X or Y?"
- **preprocess_natural_language is a monolith** — 170-line function with 30+ patterns. Should be table-driven for maintainability
- **No input history** — Player can't arrow-up to repeat commands (readline-style)
- **Typo correction only applies to Tier 2 verbs** — If player types "opne box", Tier 1 misses and Tier 2's known_verbs set doesn't include all Tier 1 verbs

### Text Output Improvements
- **No color/emphasis** — All output is plain text. ANSI SGR codes could add bold for object names, dim for ambient descriptions, red for warnings
- **Room description doesn't vary by light level** — `dim` only adds a preamble ("Dim light seeps through..."). Objects should show reduced-detail descriptions in dim light
- **Sensory output inconsistency** — `feel` has rich surface enumeration (L1571+), but `smell` and `listen` don't enumerate room objects automatically

### REPL UX Improvements
- **Help is a wall of text** — 55 lines dumped at once. Should be paginated or categorized (`help movement`, `help senses`, `help crafting`)
- **No context-sensitive help** — "help" in darkness should emphasize feel/smell/listen. "help" while holding something should mention drop/put
- **Error messages are inconsistent** — Some say "You don't see that here." (L1191), others "You can't feel anything like that nearby." (L1555). Should standardize
- **No command abbreviation system** — "exam" doesn't work for "examine", only "x" alias exists

### Bugs Noticed
- **Dead `cmd_look` in loop** — L18-74 defines a simpler look handler that's always overridden. Should be removed to avoid confusion
- **Double `require` in loop** — L10 requires `goal_planner` via pcall, but L389 also does `require("engine.parser")` inside the loop body (should use the module-level import)
- **GOAP compound optimization can swallow valid commands** — L338-349: if last sub-command has a GOAP plan, ALL preceding sub-commands are dropped. But "open door and go north" would lose "open door" if "go north" somehow triggered GOAP
- **`push_back_target` self-referential** — L179: `return "put", push_back_target .. " in " .. push_back_target` puts item in itself. Should use context to determine original container
