# Engine Refactoring Review — Files >500 Lines

**Author:** Bart (Architect)  
**Date:** 2026-03-28  
**Status:** Review (no code changes)  
**Requested by:** Wayne "Effe" Berry (P0-A)

---

## Executive Summary

Five engine files exceed 500 lines. One is critical: `verbs/init.lua` at **5,884 lines** — nearly 6× larger than the next-largest file. It is the single highest-risk module for LLM editing errors, merge conflicts, and cognitive overload. I recommend splitting it into 8 files plus a shared helpers module.

The other four files (1,059 / 871 / 848 / 585 lines) are moderate. Two are split candidates; two should stay intact.

**Key finding:** Three utility functions (`strip_articles`, `matches_keyword`/`kw_match`, singularization) are duplicated across 3+ files. Centralizing them is a zero-risk prerequisite for any split.

---

## File Inventory (Sorted by Size)

| File | Lines | Verdict | Risk |
|------|------:|---------|------|
| `src/engine/verbs/init.lua` | 5,884 | 🔴 **SPLIT** (8 modules + helpers) | Critical |
| `src/engine/parser/preprocess.lua` | 1,059 | 🟡 **SPLIT** (3 modules) | Low |
| `src/engine/search/traverse.lua` | 871 | 🟢 **KEEP** as-is | None |
| `src/engine/parser/goal_planner.lua` | 848 | 🟡 **SPLIT** (2-3 modules) | Low |
| `src/engine/loop/init.lua` | 585 | 🟢 **KEEP** as-is | None |

No other engine file exceeds 500 lines. Next largest: `parser/fuzzy.lua` at 461 lines.

---

## 1. `verbs/init.lua` — 5,884 Lines (🔴 CRITICAL)

### Problem Statement

This file contains **every verb handler** (70+ handlers), **all shared helpers** (35+ functions), the **find_visible family** (7 search functions), **part detachment/reattachment** logic, **spatial movement**, **tool resolution**, **self-infliction combat**, and **mutation execution**. An LLM asked to modify the `wear` verb must load 5,884 lines of context, of which only ~300 are relevant.

### Current Structure

```
Lines 1-28:      Module requires (6 core + 4 optional)
Lines 29-126:    Instance helpers, error helpers, keyword matching
Lines 127-170:   Hand slot accessors (hands_full, first_empty_hand, etc.)
Lines 172-425:   Part system (find_part, detach_part, reattach_part)
Lines 426-770:   find_visible family (_fv_room/surfaces/parts/hands/bags/worn)
                 + pronoun wrapper + fuzzy fallback
Lines 771-930:   Inventory search, tool resolution, capability checks
Lines 931-1040:  remove_from_location (82 lines)
Lines 1041-1255: Container access, mutation, exits, spawning, spatial movement
Lines 1258-1593: verbs.create() + look handler (330 lines!)
Lines 1594-2130: Sensory verbs (examine, read, search, find, feel)
Lines 2131-2300: Sensory verbs (smell, taste, listen)
Lines 2301-2828: Acquisition verbs (take, pull, push, move, lift, uncork)
Lines 2829-3000: drop handler (166 lines — fragility, shattering)
Lines 3000-3286: Container interaction (open, close, unlock)
Lines 3287-3495: Destruction (break, tear)
Lines 3495-3880: Fire/Light + write/inscribe + inventory display
Lines 3880-4090: Combat constants + self-infliction helpers
Lines 4090-4500: Combat verbs (stab, hit, cut, slash, prick, sew)
Lines 4498-4878: put/place handler (228 lines) + strike handler (138 lines)
Lines 4878-5316: Equipment (wear=302 lines, remove=124 lines)
Lines 5317-5528: Consumption (eat, drink, pour, burn)
Lines 5529-5790: sleep handler (246 lines — ticks FSM during sleep)
Lines 5791-6088: Movement/navigation (go, directions, back, enter, climb)
Lines 6089-6393: Meta verbs (report_bug, help, injuries, apply, wait, appearance)
Lines 6396:      return verbs
```

### Proposed Split: 9 Files

#### `verbs/helpers.lua` — ~650 lines (EXTRACT FIRST)

The shared foundation. Every other verb file requires this.

**Contents:**
- Instance helpers: `_hid()`, `_hobj()`, `next_instance_id()`
- Error helpers: `err_not_found()`, `err_cant_do_that()`, `err_nothing_happens()`
- Keyword matching: `matches_keyword()` (with singularization)
- Hand accessors: `hands_full()`, `first_empty_hand()`, `which_hand()`, `count_hands_used()`
- find_visible family: `_fv_room()`, `_fv_surfaces()`, `_fv_parts()`, `_fv_hands()`, `_fv_bags()`, `_fv_worn()`, `find_visible()` + pronoun/fuzzy wrapper
- Inventory search: `find_in_inventory()`, `find_tool_in_inventory()`, `find_visible_tool()`
- Tool/capability: `provides_capability()`, `consume_tool_charge()`
- Location management: `remove_from_location()` (82 lines)
- Container helpers: `container_contents_accessible()`
- Mutation helpers: `find_mutation()`, `perform_mutation()`, `spawn_objects()`
- Exit matching: `exit_matches()`
- Weight: `inventory_weight()`
- Constants: `interaction_verbs`, `DIRECTION_ALIASES`, time constants
- Module requires: all 6 core + 4 optional dependencies

**Pattern:**
```lua
-- verbs/helpers.lua
local H = {}
H.find_visible = function(ctx, noun) ... end
H.matches_keyword = function(obj, kw) ... end
H.remove_from_location = function(ctx, player, obj) ... end
-- ... etc
return H
```

#### `verbs/sensory.lua` — ~860 lines

| Handler | Est. Lines | Notes |
|---------|-----------|-------|
| look | 330 | Room view, light checks, presences, exits |
| examine | 90 | Detail examination, container peek |
| read | 54 | Readable objects, skill granting |
| search | 76 | Progressive traverse (two separate blocks) |
| find | 34 | Targeted search |
| feel | 249 | Tactile exploration (darkness-safe) |
| smell | 61 | Olfactory sweep |
| taste | 27 | Gustatory + effects pipeline |
| listen | 63 | Audio sweep |

**Dependencies:** helpers.lua, fsm_mod, presentation, search module, appearance module

#### `verbs/acquisition.lua` — ~530 lines

| Handler | Est. Lines | Notes |
|---------|-----------|-------|
| take/get/pick/grab | 289 | From room/containers/surfaces |
| pull/yank/tug/extract | 77 | Part detachment |
| push/shove | 13 | Spatial movement |
| move/shift/slide | 16 | Spatial movement |
| lift | 26 | Pick up or reveal underneath |
| uncork/unstop/unseal | 53 | Cork-type detachment |
| drop/toss/throw | 166 | Fragility, shattering |

**Dependencies:** helpers.lua, part system (find_part, detach_part), move_spatial_object

Note: `find_part()`, `detach_part()`, `reattach_part()`, and `move_spatial_object()` (total ~340 lines) belong in helpers.lua since they're used by both acquisition and containment verbs.

#### `verbs/containers.lua` — ~270 lines

| Handler | Est. Lines | Notes |
|---------|-----------|-------|
| open | 114 | FSM + mutation paths, hooks |
| close/shut | 97 | FSM + mutation paths, hooks |
| unlock | 57 | Key resolution |

**Dependencies:** helpers.lua, fsm_mod

#### `verbs/destruction.lua` — ~140 lines

| Handler | Est. Lines | Notes |
|---------|-----------|-------|
| break/smash/shatter | 95 | FSM or mutation path |
| tear/rip | 42 | Spawn-in-hand support |

**Dependencies:** helpers.lua, fsm_mod, materials

#### `verbs/fire.lua` — ~390 lines

| Handler | Est. Lines | Notes |
|---------|-----------|-------|
| light/ignite/relight | 137 | Tool-based, compound tools |
| extinguish/snuff | 64 | Flame state transitions |
| burn | 50 | Burn flammable items |
| strike | 138 | Match+matchbox compound interaction |

**Dependencies:** helpers.lua, fsm_mod, materials

#### `verbs/combat.lua` — ~400 lines

| Handler | Est. Lines | Notes |
|---------|-----------|-------|
| stab/jab/pierce/stick | 7 | → handle_self_infliction |
| hit/punch/bash/... | 109 | Head→unconscious, body→bruise |
| cut/slice/nick | 54 | Cut objects or self |
| slash/carve | 12 | → cut redirect |
| prick | 42 | Blood for writing |
| BODY_AREA_* constants | ~40 | Weights, damage mods, aliases |
| parse_self_infliction | 20 | Body area parsing |
| handle_self_infliction | 125 | Injury system routing |

**Dependencies:** helpers.lua, injuries module, effects module, armor module

#### `verbs/crafting.lua` — ~390 lines

| Handler | Est. Lines | Notes |
|---------|-----------|-------|
| write/inscribe | 163 | Dynamic mutation, light check |
| sew/stitch/mend | 149 | Skill-gated, tool+material |
| put/place | 228 | Containment, surfaces, reattach |

**Dependencies:** helpers.lua, fsm_mod, containment module

Note: `put` is placed here because it shares the `reattach_part()` codepath with crafting and is a creation/placement verb, not pure acquisition.

#### `verbs/equipment.lua` — ~430 lines

| Handler | Est. Lines | Notes |
|---------|-----------|-------|
| wear/don | 302 | Slot conflicts, vision blocking |
| remove/doff | 124 | Unequip or detach parts |

**Dependencies:** helpers.lua, fsm_mod

#### `verbs/survival.lua` — ~380 lines

| Handler | Est. Lines | Notes |
|---------|-----------|-------|
| eat/consume/devour | 30 | Food consumption |
| drink/quaff/sip | 68 | Liquid FSM or generic |
| pour/spill/dump | 36 | Pour out liquids |
| sleep/rest/nap | 246 | Time advancement, FSM ticking |

**Dependencies:** helpers.lua, fsm_mod, injuries module

#### `verbs/movement.lua` — ~300 lines

| Handler | Est. Lines | Notes |
|---------|-----------|-------|
| n/s/e/w/u/d + full names | ~12 | Direction aliases |
| go/walk/run/head/travel | 7 | General navigation |
| move (disambiguation) | 13 | Navigation vs object move |
| back/return | 9 | Context window return |
| enter | 6 | Enter through exit |
| descend/ascend/climb | 12 | Vertical movement |
| _navigate() internal | ~240 | Room transitions, exit checks, traverse effects |

**Dependencies:** helpers.lua, traverse_effects, context_window

#### `verbs/meta.lua` — ~270 lines

| Handler | Est. Lines | Notes |
|---------|-----------|-------|
| inventory/i | 50 | Hands, worn, bags display |
| time | 4 | Game time display |
| report_bug | 72 | GitHub issue filing |
| help | 71 | Help screen |
| injuries/wounds/health | 16 | Injury display |
| apply/treat | 107 | Healing item application |
| wait/pass | 3 | Pass turn |
| appearance | 7 | Player appearance |
| set/adjust | 73 | Clock puzzle |

**Dependencies:** helpers.lua, injuries module, presentation, appearance module

### `verbs/init.lua` — ~80 lines (REGISTRY ONLY)

After split, `init.lua` becomes a thin registry:

```lua
local verbs = {}

function verbs.create()
    local handlers = {}
    
    -- Load verb modules
    local sensory = require("engine.verbs.sensory")
    local acquisition = require("engine.verbs.acquisition")
    local containers = require("engine.verbs.containers")
    -- ... etc
    
    -- Register all handlers
    sensory.register(handlers)
    acquisition.register(handlers)
    containers.register(handlers)
    -- ... etc
    
    return handlers
end

return verbs
```

Each verb module exports a `register(handlers)` function:

```lua
-- verbs/sensory.lua
local H = require("engine.verbs.helpers")
local sensory = {}

function sensory.register(handlers)
    handlers["look"] = function(ctx, noun)
        -- ... look implementation using H.find_visible(), etc.
    end
    -- ... other sensory verbs
end

return sensory
```

### Estimated LOC After Split

| File | Est. Lines | % of Original |
|------|-----------|--------------|
| helpers.lua | ~650 | 11% |
| sensory.lua | ~860 | 15% |
| acquisition.lua | ~530 | 9% |
| containers.lua | ~270 | 5% |
| destruction.lua | ~140 | 2% |
| fire.lua | ~390 | 7% |
| combat.lua | ~400 | 7% |
| crafting.lua | ~390 | 7% |
| equipment.lua | ~430 | 7% |
| survival.lua | ~380 | 6% |
| movement.lua | ~300 | 5% |
| meta.lua | ~270 | 5% |
| init.lua (registry) | ~80 | 1% |
| **Total** | **~5,090** | 87% |

~800 lines saved through deduplication (shared `require` blocks, redundant comments, blank lines between verb groups).

### Shared Helper Dependency Map

Functions in `helpers.lua` and which verb modules use them:

| Helper | Used By |
|--------|---------|
| `find_visible()` | sensory, acquisition, containers, destruction, fire, crafting, equipment, survival |
| `matches_keyword()` | ALL (via find_visible) |
| `find_in_inventory()` | acquisition, fire, crafting, equipment, combat |
| `find_tool_in_inventory()` | fire, crafting, combat |
| `remove_from_location()` | acquisition, destruction, crafting, survival |
| `perform_mutation()` | containers, destruction, fire |
| `find_part()` / `detach_part()` | acquisition, equipment |
| `reattach_part()` | crafting (put handler) |
| `move_spatial_object()` | acquisition |
| `consume_tool_charge()` | fire, crafting |
| `handle_self_infliction()` | combat |
| `err_not_found()` | ALL |
| `err_cant_do_that()` | sensory, acquisition, containers, crafting, equipment |

### LLM Impact Analysis

| Scenario | Before (monolith) | After (split) |
|----------|-------------------|--------------|
| "Fix the wear verb" | Load 5,884 lines | Load helpers (650) + equipment (430) = **1,080 lines** (82% reduction) |
| "Add a new sensory verb" | Load 5,884 lines | Load helpers (650) + sensory (860) = **1,510 lines** (74% reduction) |
| "Fix navigation bug" | Load 5,884 lines | Load helpers (650) + movement (300) = **950 lines** (84% reduction) |
| "Modify drop fragility" | Load 5,884 lines | Load helpers (650) + acquisition (530) = **1,180 lines** (80% reduction) |

**Sweet spot analysis:** 8-12 files is optimal. Fewer than 5 means files are still >1,000 lines. More than 15 means too much cross-file coordination. The proposed 12-file split (init + helpers + 10 verb modules) keeps each module between 140-860 lines.

---

## 2. `parser/preprocess.lua` — 1,059 Lines (🟡 SPLIT)

### Structure

The file is a table-driven pipeline of 14 composable transform stages, each a pure `string → string` function. They share no mutable state. The file also exports `parse()`, `strip_articles()`, `singularize()`, `split_commands()`, and `natural_language()`.

### Logical Seams

Three natural divisions:

| Module | Contents | Est. Lines |
|--------|----------|-----------|
| `preprocess/core.lua` | `parse()`, `strip_articles()`, `singularize()`, `split_commands()`, `natural_language()`, pipeline execution, `BODY_PARTS` | ~150 |
| `preprocess/transforms.lua` | Small stages: `normalize`, `strip_politeness`, `strip_adverbs`, `strip_preambles`, `strip_gerunds`, `strip_filler`, `strip_noun_modifiers`, `strip_decorative_prepositions`, `expand_idioms` | ~350 |
| `preprocess/patterns.lua` | Large pattern matchers: `transform_questions` (166 lines), `transform_look_patterns`, `transform_search_phrases`, `transform_compound_actions`, `transform_movement` | ~450 |

### Recommendation: **SPLIT — but low priority**

The stages are already independently testable (Nelson has `test/parser/pipeline/` with 224 tests exercising `preprocess.stages.*`). The main benefit of splitting is LLM context reduction: editing `transform_questions` doesn't require loading `strip_filler`. But this file isn't causing active pain — it's well-organized internally with clear section headers.

**Priority:** P2. Split after verbs/init.lua is done.

---

## 3. `search/traverse.lua` — 871 Lines (🟢 KEEP)

### Structure

The file has a clear architecture: `expand_object()` (123 lines) recursively expands objects into searchable entries, `build_queue()` (63 lines) constructs the search queue, and `traverse.step()` (430 lines) is the search FSM that advances one step per player "search" command.

### Why Keep

`traverse.step()` is large (430 lines) but represents a **single state machine**. Splitting it would mean splitting FSM states across files, which breaks the mental model. The helper functions (`matches_exact`, `matches_direct`, `matches_target`, `find_deeper_match`) are already well-extracted. The file has strong internal cohesion — every function participates in the same traversal algorithm.

**No mutable module-level state.** Only `CATEGORY_SYNONYMS` (a static lookup table). This file is architecturally clean.

### Recommendation: **KEEP as-is.** 

Consider extracting `CATEGORY_SYNONYMS` and `matches_exact`/`matches_direct`/`matches_target` into a shared keywords module only if other modules need them in the future.

---

## 4. `parser/goal_planner.lua` — 848 Lines (🟡 SPLIT)

### Structure

Three tiers:
1. **Queries** (~200 lines): `find_all()`, `find_property()`, `find_lightable()`, `find_by_id()`, `find_locked_exit()`, `resolve_target()` — read-only world queries
2. **Planners** (~350 lines): `plan_fire_source()`, `plan_retrieval()`, `plan_for_light()`, `plan_for_key()`, `plan_generic_tool()`, `plan_for_tool()`, `try_plan_match()` — backward-chaining GOAP
3. **Core** (~150 lines): Helpers (`kw_match`, `strip_articles`, `is_spent_or_terminal`, hand accessors), public API (`plan()`, `execute()`), constants

### Recommendation: **SPLIT into 2 files — low priority**

| Module | Contents | Est. Lines |
|--------|----------|-----------|
| `goal_planner/queries.lua` | All `find_*` functions, `resolve_target()` | ~250 |
| `goal_planner/init.lua` | Helpers, planners, public API | ~600 |

The queries are independently useful (and could serve future Tier 2 NLP fallback). But the planners and core are tightly coupled — planners call queries, and the public API orchestrates planners. Don't over-split.

### Duplicated Utilities

- `strip_articles()` at line 54 duplicates `preprocess.strip_articles()`. Replace with `require("engine.parser.preprocess").strip_articles()`.
- `kw_match()` at line 34 duplicates logic from `verbs/init.lua:matches_keyword()`. Centralize.

**Priority:** P3. Split only if the file keeps growing.

---

## 5. `loop/init.lua` — 585 Lines (🟢 KEEP)

### Structure

The game loop is a single `loop.run(context)` function with clear phases:
1. Consciousness gate (ticks injuries while unconscious)
2. Search tick (advances pending searches)
3. Input reading (headless/TUI/raw)
4. Command parsing (preprocess → verb+noun)
5. Pronoun resolution
6. GOAP planning (optional Tier 3)
7. Verb dispatch
8. FSM post-tick

### Why Keep

585 lines is reasonable for a game loop that orchestrates 5 parser tiers, consciousness, and FSM ticking. The phases are sequential and tightly ordered — splitting into `input.lua`, `dispatch.lua`, `postprocess.lua` would fragment a critical execution contract. The consciousness gate, search tick, and FSM post-tick are **safety barriers** that must execute in exact sequence. Splitting risks someone inserting code between barriers.

### Recommendation: **KEEP as-is.**

The file is at the threshold (585 lines) but its size reflects genuine complexity, not poor structure. It has no duplicated utilities and clean internal organization.

---

## Cross-Cutting Issues

### Utility Duplication (Fix Before Any Split)

| Function | Defined In | Also In | Action |
|----------|-----------|---------|--------|
| `strip_articles()` | preprocess.lua:21 | goal_planner.lua:54, traverse.lua (inline ×3) | Centralize to preprocess |
| `kw_match()` / `matches_keyword()` | verbs/init.lua:82 | goal_planner.lua:34 | Extract to `verbs/helpers.lua` or shared module |
| `singularize()` | preprocess.lua:47 | Used via `preprocess.singularize()` ✅ | Already centralized |
| `_hid()` / `_hobj()` | verbs/init.lua:39 | goal_planner.lua:77 (`_gp_hid`) | Extract to helpers |

**Recommendation:** Before any file split, create a shared keyword matching module or ensure all consumers `require` the canonical implementations. This is a 30-minute task with zero behavioral risk.

### Test Coverage Gaps (Nelson: Read This)

**Verb handlers with NO dedicated unit tests:**

| Category | Untested Verbs | Priority |
|----------|---------------|----------|
| Movement | go, back, enter, ascend, descend, climb, all directions | High (movement is core) |
| Consumption | eat, drink, pour | Medium |
| Crafting | write, sew, put | High (complex logic) |
| Fire | light, extinguish, burn, strike | High (compound tool logic) |
| Equipment | (partial — wear tested, remove less so) | Medium |
| Meta | help, report_bug, time, wait, set/adjust | Low |
| Container | open, close (hooks tested, core logic less so) | Medium |

**Before splitting verbs/init.lua**, Nelson should write tests for every helper function that will move to `helpers.lua`. The helpers are the highest-risk extraction — if `find_visible()` breaks, every verb breaks.

**Critical test targets for helpers.lua:**
1. `find_visible()` — all 7 search paths × interaction vs acquisition order
2. `remove_from_location()` — from hands, bags, worn, room, surfaces
3. `matches_keyword()` — singular/plural, word boundary, id vs keyword vs name
4. `perform_mutation()` — becomes path + spawns path
5. `move_spatial_object()` — reveal hidden, dump contents

---

## Risk Assessment

### What Could Break During Refactoring

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Upvalue capture breaks** | 🔴 High | Lua closures capture locals by reference. Verb handlers inside `verbs.create()` close over local helpers. When helpers move to a separate module, every closure must change from direct local access to `H.function_name()`. One missed reference = silent nil call. | **Run full test suite after every file extraction.** |
| **Require path changes** | 🟡 Medium | `require("engine.verbs")` currently loads `verbs/init.lua` which returns the `verbs` table. After split, `init.lua` must still return the same public API. Internal `require("engine.verbs.helpers")` must resolve correctly. | **Verify require paths with a smoke test.** |
| **Module-level state isolation** | 🟡 Medium | `_next_instance_id` is a module-level counter in verbs/init.lua. After split, it must live in exactly ONE module (helpers.lua) to avoid duplicate counters. | **Audit all module-level `local` vars for split ownership.** |
| **Load order dependencies** | 🟡 Medium | `pcall(require, ...)` for optional modules (fuzzy, context_window) currently lives in verbs/init.lua. After split, these must load in helpers.lua so all verb modules can use them. | **Centralize optional requires in helpers.lua.** |
| **Handler registration order** | 🟢 Low | Handler assignment order doesn't matter (it's a hash table). No risk from splitting handlers across files. | None needed. |
| **Alias chains** | 🟢 Low | Some verbs are aliases (`handlers["shut"] = handlers["close"]`). After split, aliases must reference handlers from the same module. | **Keep aliases adjacent to their primary handler.** |

### Estimated Effort

| Task | Hours | Owner |
|------|-------|-------|
| Centralize duplicated utilities | 0.5 | Bart |
| Write pre-refactoring tests for helpers | 4-6 | Nelson |
| Extract helpers.lua | 2 | Bart |
| Extract 10 verb modules | 6-8 | Bart |
| Verify full test suite after each extraction | 2 | Nelson |
| Split preprocess.lua (P2) | 2 | Smithers |
| Split goal_planner.lua (P3) | 1.5 | Bart |
| **Total** | **18-22** | — |

---

## Sequencing: Refactor Before or After Meta-Compiler (P0-B)?

### Recommendation: **Refactor BEFORE meta-compiler.**

**Arguments for refactoring first:**

1. **Meta-compiler validates file paths.** If we build meta-lint against `verbs/init.lua` (5,884 lines), then refactor into 12 files, every validation rule referencing the file path breaks. Refactoring first means meta-lint is built against the final structure.

2. **Smaller files are easier to validate.** A 650-line helpers file has clearer invariants than a 5,884-line monolith. Meta-check rules will be simpler and more precise.

3. **LLM productivity compounds.** Every squad member touching engine code benefits immediately from smaller files. The meta-compiler work itself involves editing engine code — Bart benefits from the split while building meta-lint.

4. **Test safety net already exists.** We have 97+ test files with 500+ assertions. The refactoring is mechanical (move code, update requires). With TDD discipline, the risk is manageable.

**Arguments for meta-compiler first (rejected):**

- "Refactoring changes file paths" — true, but meta-lint is a new tool. There are no existing paths to break.
- "Safety net for refactoring" — meta-lint validates object .lua files, not engine .lua files. It wouldn't catch refactoring bugs in `verbs/helpers.lua`.

**Proposed sequence:**

```
Week 1:  Nelson writes pre-refactoring tests (P0-A prep)
Week 1:  Bart centralizes duplicated utilities (zero-risk)
Week 2:  Bart extracts helpers.lua + sensory.lua (highest-value split)
Week 2:  Nelson verifies, runs full suite
Week 2+: Bart extracts remaining verb modules (1-2 per session)
Week 3:  Begin P0-B meta-compiler (against clean file structure)
```

---

## Appendix: Verb Handler Catalog by Proposed File

### sensory.lua
`look`, `examine` (x, find, check, inspect), `read`, `search`, `find`, `feel` (touch, grope), `smell` (sniff), `taste` (lick), `listen` (hear)

### acquisition.lua
`take` (get, pick, grab), `pull` (yank, tug, extract), `push` (shove), `move` (shift, slide — object variant), `lift`, `uncork` (unstop, unseal), `drop` (toss, throw)

### containers.lua
`open`, `close` (shut), `unlock`

### destruction.lua
`break` (smash, shatter), `tear` (rip)

### fire.lua
`light` (ignite, relight), `extinguish` (snuff), `burn`, `strike`

### combat.lua
`stab` (jab, pierce, stick), `hit` (punch, bash, bonk, thump, smack, bang, slap, whack, headbutt), `cut` (slice, nick), `slash` (carve), `prick`

### crafting.lua
`write` (inscribe), `sew` (stitch, mend), `put` (place)

### equipment.lua
`wear` (don), `remove` (doff)

### survival.lua
`eat` (consume, devour), `drink` (quaff, sip), `pour` (spill, dump), `sleep` (rest, nap)

### movement.lua
`north`/`south`/`east`/`west`/`up`/`down` (n/s/e/w/u/d), `go` (walk, run, head, travel), `move` (navigation variant), `back` (return), `enter`, `descend`, `ascend`, `climb`

### meta.lua
`inventory` (i), `time`, `report_bug`, `help`, `injuries` (injury, wounds, health), `apply` (treat), `wait` (pass), `appearance`, `set` (adjust)
