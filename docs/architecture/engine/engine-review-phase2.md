# Engine Code Review — Phase 2 Pre-Flight

**Reviewer:** Bart (Architect)  
**Date:** 2026-03-31  
**Scope:** All `src/engine/**/*.lua` files  
**Purpose:** Identify runaway files, recommend splits, map test gaps, and establish Phase 2 pre-flight checklist  
**Skill:** `engine-code-review` (Phase 1 of 5)

---

## Executive Summary

The engine has grown to **53 files / 19,292 LOC**. Of those, **14 files exceed 500 LOC** and **3 files exceed 1,000 LOC**. The verb subsystem alone accounts for 8,900+ LOC across 14 files.

Phase 2 (NPC combat, creature behavior, advanced crafting) will add an estimated **1,500–3,000 LOC** to files that are already at or above the split threshold. Without pre-emptive extraction, we'll have 5+ files over 1,000 LOC within two waves.

**Bottom line:** 6 files are **must-split** before Phase 2. 4 more are **nice-to-split**. The rest are healthy.

---

## 1. Size Audit — All Engine Files (LOC Descending)

| # | File | LOC | Status | Priority |
|---|------|-----|--------|----------|
| 1 | `verbs/helpers.lua` | 1,616 | 🔴 CRITICAL | **MUST-SPLIT** |
| 2 | `parser/preprocess.lua` | 1,282 | 🔴 CRITICAL | **MUST-SPLIT** |
| 3 | `verbs/sensory.lua` | 1,073 | 🔴 CRITICAL | **MUST-SPLIT** |
| 4 | `search/traverse.lua` | 871 | 🟠 HIGH | **MUST-SPLIT** |
| 5 | `verbs/acquisition.lua` | 792 | 🟠 HIGH | Nice-to-split |
| 6 | `parser/goal_planner.lua` | 790 | 🟠 HIGH | Nice-to-split |
| 7 | `verbs/survival.lua` | 664 | 🟡 ELEVATED | **MUST-SPLIT** |
| 8 | `verbs/fire.lua` | 640 | 🟡 ELEVATED | Nice-to-split |
| 9 | `verbs/crafting.lua` | 629 | 🟡 ELEVATED | **MUST-SPLIT** |
| 10 | `loop/init.lua` | 622 | 🟡 ELEVATED | Refactor-in-place |
| 11 | `verbs/meta.lua` | 536 | 🟡 ELEVATED | Nice-to-split |
| 12 | `parser/embedding_matcher.lua` | 516 | ⚪ OK | Monitor |
| 13 | `verbs/init.lua` | 508 | 🟡 ELEVATED | **MUST-SPLIT** (combat extraction) |
| 14 | `parser/fuzzy.lua` | 490 | ⚪ OK | Monitor |
| 15 | `verbs/equipment.lua` | 482 | ⚪ OK | Monitor |
| 16 | `search/narrator.lua` | 444 | ⚪ OK | OK |
| 17 | `combat/init.lua` | 435 | ⚪ OK (grows Phase 2) | Pre-split recommended |
| 18 | `injuries.lua` | 424 | ⚪ OK | OK |
| 19 | `creatures/init.lua` | 421 | ⚪ OK (grows Phase 2) | Pre-split recommended |
| 20 | `fsm/init.lua` | 420 | ⚪ OK | OK |
| 21 | `fire_propagation/init.lua` | 344 | ⚪ OK | OK |
| 22 | `ui/init.lua` | 329 | ⚪ OK | OK |
| 23 | `verbs/combat.lua` | 321 | ⚪ OK | OK |
| 24 | `verbs/movement.lua` | 316 | ⚪ OK | OK |
| 25 | `player/appearance.lua` | 299 | ⚪ OK | OK |
| 26–53 | *(28 files under 260 LOC)* | 60–257 | ⚪ OK | OK |

**Totals:** 53 files, 19,292 LOC  
**Files >500 LOC:** 14 (73% of total LOC)  
**Files >1000 LOC:** 3 (3,971 LOC combined — 21% of engine)

---

## 2. Must-Split Files — Detailed Analysis

### 2.1 `verbs/helpers.lua` — 1,616 LOC 🔴

**The Problem:** This is the engine's shared utility layer — 42 functions spanning 10 logical domains crammed into one file. Every verb module depends on it. Any edit risks merge conflicts with parallel agent work.

**Logical Domains Identified:**

| Domain | Functions | Est. LOC | Cohesion |
|--------|-----------|----------|----------|
| Object Search & Discovery | `find_visible`, `_fv_*` (7 sub-searches), `matches_keyword`, `_score_adjective_match`, `find_in_inventory`, `find_portal_by_keyword` | ~450 | HIGH — all about finding objects |
| Part Mechanics | `find_part`, `detach_part`, `reattach_part` | ~250 | HIGH — composite objects |
| Inventory Management | `_hid`, `_hobj`, `hands_full`, `first_empty_hand`, `which_hand`, `count_hands_used`, `remove_from_location`, `inventory_weight` | ~200 | HIGH — hand slot operations |
| Self-Harm System | `random_body_area`, `parse_self_infliction`, `handle_self_infliction` + body area constants | ~200 | HIGH — isolated subsystem |
| Mutations & Spawning | `find_mutation`, `spawn_objects`, `perform_mutation` | ~120 | MEDIUM |
| Tool Resolution | `find_tool_in_inventory`, `provides_capability`, `find_visible_tool`, `consume_tool_charge` | ~100 | HIGH — tool capability system |
| Spatial Movement | `move_spatial_object`, `container_contents_accessible` | ~180 | MEDIUM |
| FSM & Portals | `try_fsm_verb`, `sync_bidirectional_portal` | ~80 | MEDIUM |
| Errors & Hints | `err_not_found`, `err_cant_do_that`, `err_nothing_happens`, `show_hint` | ~40 | LOW — utility |
| Constants & Exports | Time constants, `interaction_verbs`, re-exports | ~60 | — |

**Split Recommendation (6 modules):**

```
src/engine/verbs/
  helpers.lua              → 120 LOC (thin re-export layer + constants + errors)
  helpers/
    search.lua             → 450 LOC (find_visible, _fv_*, scoring, portal search)
    parts.lua              → 250 LOC (find_part, detach_part, reattach_part)
    inventory.lua          → 200 LOC (hand slots, removal, weight)
    self_harm.lua          → 200 LOC (body areas, parse/handle self-infliction)
    tools.lua              → 100 LOC (capability resolution, charges)
    spatial.lua            → 180 LOC (move_spatial_object, container access)
```

**Why `helpers/search.lua` stays large (450 LOC):** The `find_visible` dispatcher and its 7 `_fv_*` sub-search functions are tightly coupled — they share adjective scoring, context window integration, and pronoun resolution. Splitting further would create circular dependencies. 450 LOC is acceptable for a single search subsystem.

**Phase 2 Growth:** +100–200 LOC (creature search in `find_visible`, NPC keyword matching, combat tool checks). Growth lands in search.lua and tools.lua — both manageable post-split.

**LLM Impact:** Massive improvement. Currently, any agent editing a verb handler must load 1,616 LOC of context. Post-split, editing self-harm logic requires only 200 LOC. **~75–88% context reduction per edit.**

**Test Gap Inventory:**
- ✅ `find_visible` — covered by `test/search/`, `test/verbs/test-search-find.lua`
- ✅ `detach_part` / `reattach_part` — covered by `test/objects/test-tear-cloak.lua`
- ✅ `remove_from_location` — covered by `test/inventory/`
- ⚠️ `move_spatial_object` — partial coverage (`test/verbs/test-spatial-verbs.lua`)
- ❌ `handle_self_infliction` — only `test/integration/test-stab-self-pipeline.lua` (integration, not unit)
- ❌ `consume_tool_charge` — no dedicated test
- ❌ `sync_bidirectional_portal` — covered by `test/rooms/test-portal-*.lua` (integration)

**Dependency Graph:**
```
helpers.lua (re-exports)
  ├── helpers/search.lua    ← requires: helpers/inventory, parser/context, parser/fuzzy
  ├── helpers/parts.lua     ← requires: helpers/inventory, helpers/search, fsm
  ├── helpers/inventory.lua ← requires: (standalone, leaf node)
  ├── helpers/self_harm.lua ← requires: helpers/search, helpers/inventory, effects
  ├── helpers/tools.lua     ← requires: helpers/inventory, helpers/search
  ├── helpers/spatial.lua   ← requires: helpers/search, fsm
  └── (errors, constants)   ← standalone
```
**Safe extraction order:** inventory → tools → search → spatial → self_harm → parts

---

### 2.2 `parser/preprocess.lua` — 1,282 LOC 🔴

**The Problem:** Largest parser file. 22+ transform functions in a single pipeline. Each function is a self-contained text transformation, but they're all in one file — making individual stage tuning expensive.

**Split Recommendation (5 modules + orchestrator):**

```
src/engine/parser/
  preprocess.lua             → 120 LOC (orchestrator: parse(), strip_articles(), natural_language(), split_*)
  preprocess/
    normalize.lua            → 140 LOC (normalize, strip_politeness, strip_adverbs, strip_preambles,
                                        strip_gerunds, strip_filler, strip_possessives)
    transforms.lua           → 200 LOC (transform_look_patterns, transform_search_phrases,
                                        transform_compound_actions, transform_movement)
    questions.lua            → 100 LOC (transform_questions — 50+ pattern matches)
    semantic.lua             → 80 LOC (strip_noun_modifiers, strip_decorative_prepositions, expand_idioms)
    singularize.lua          → 60 LOC (singularize_word, singularize_target)
```

**Phase 2 Growth:** +150–250 LOC (combat command parsing, NPC dialogue preprocessing, quantity prefixes). Growth distributed across transform and question modules — manageable post-split.

**LLM Impact:** Excellent. Tuning one preprocessing stage (e.g., question transforms) currently requires loading 1,282 LOC. Post-split: 100 LOC. **~92% context reduction.**

**Test Gap Inventory:**
- ✅ Pipeline stages — excellent coverage: 11 test files in `test/parser/pipeline/` (224+ tests)
- ✅ `natural_language` — `test/parser/test-preprocess.lua`, `test/parser/test-preprocess-phrases.lua`
- ✅ `split_commands` — `test/parser/test-compound-commands.lua`
- ✅ Questions — `test/parser/pipeline/test-transform-questions.lua`
- ⚠️ `singularize_word` — partial (tested indirectly via fuzzy noun tests)

**Safe extraction order:** singularize → normalize → semantic → questions → transforms

---

### 2.3 `verbs/sensory.lua` — 1,073 LOC 🔴

**The Problem:** 7 sensory systems (look, examine, read, feel, search, smell, taste, listen) in one file. Each sense is independent — they share helpers but never call each other. Natural 5-way split by sense modality.

**Split Recommendation (5 modules):**

```
src/engine/verbs/
  sensory.lua               → 65 LOC (thin register wrapper + M.register calls sub-modules)
  sensory/
    visual.lua              → 490 LOC (look, examine, read — light-dependent senses)
    tactile.lua             → 250 LOC (feel, touch, grope — darkness-independent)
    search.lua              → 130 LOC (search, find — delegates to engine.search)
    chemical.lua            → 100 LOC (smell, sniff, taste, lick)
    auditory.lua            → 65 LOC (listen, hear)
```

**Note:** `sensory/visual.lua` at 490 LOC is borderline but cohesive — look + examine + read are tightly coupled (examine delegates to look in light, read delegates to look for non-skill items). Don't split further.

**Phase 2 Growth:** +50–100 LOC (NPC descriptions in look, creature sounds in listen, NPC-specific search). Distributed across visual.lua and auditory.lua.

**LLM Impact:** Editing smell/taste currently loads 1,073 LOC. Post-split: 100 LOC. **~91% context reduction.**

**Test Gap Inventory:**
- ✅ look/examine — `test/sensory/test-senses-comprehensive.lua`, `test/verbs/test-verb-comprehensive.lua`
- ✅ feel — covered by `test/verbs/test-container-sensory-gating.lua`
- ✅ search — 17 test files in `test/search/`
- ⚠️ smell — no dedicated test (tested only in comprehensive suite)
- ⚠️ taste — partial (`test/verbs/test-consumption-verbs.lua`, `test/verbs/test-poison-bottle.lua`)
- ❌ listen — no dedicated test
- ❌ read (skill acquisition path) — no dedicated test

---

### 2.4 `search/traverse.lua` — 871 LOC 🟠

**The Problem:** The progressive search state machine. `traverse.step()` alone is 429 LOC (49% of file). Queue building and matching logic are independent concerns.

**Split Recommendation (2 extractions):**

```
src/engine/search/
  traverse.lua              → 450 LOC (build_queue, step — core traversal)
  matching.lua              → 180 LOC (matches_exact, matches_direct, matches_target, find_deeper_match)
  queue.lua                 → 240 LOC (get_proximity_list, expand_object — queue construction)
```

**Phase 2 Growth:** +150–300 LOC (NPC detection search, corpse looting, environment clue search). Growth lands in matching.lua (new match types) and step additions.

**LLM Impact:** Editing matching logic currently requires 871 LOC context. Post-split: 180 LOC. **~79% context reduction.**

**Test Gap Inventory:**
- ✅ Queue building — `test/search/test-search-traverse.lua`
- ✅ Matching — `test/search/test-search-scoped.lua`, `test/search/test-search-fuzzy-scope-bug146.lua`
- ✅ Progressive step — `test/search/test-search-streaming.lua`
- ⚠️ `find_deeper_match` (D-PEEK) — partial (integration tests only)
- ⚠️ Nested container depth limits — `test/search/test-search-container-depth.lua` (light)

---

### 2.5 `verbs/survival.lua` — 664 LOC 🟡

**The Problem:** 4 unrelated verb groups (consumption, liquids, hygiene, rest). The `do_sleep()` function alone is 250 LOC (37% of file) with time advancement, FSM ticking, injury processing, and flavor text.

**Split Recommendation (3 modules):**

```
src/engine/verbs/
  survival.lua              → 65 LOC (thin register wrapper)
  survival/
    consumption.lua         → 125 LOC (eat, drink + aliases)
    liquids.lua             → 175 LOC (pour, dump + aliases)
    rest.lua                → 300 LOC (sleep/rest/nap + wash)
```

**Why wash goes with rest:** Both are "body care" verbs; wash is only 90 LOC and doesn't justify its own module. If wash grows with NPC hygiene systems, extract then.

**Phase 2 Growth:** +100–150 LOC (food effects, NPC feeding, exhaustion system in sleep). Growth in consumption.lua and rest.lua.

**LLM Impact:** Editing sleep currently loads 664 LOC. Post-split: 300 LOC. **~55% context reduction.**

**Test Gap Inventory:**
- ✅ eat/drink — `test/verbs/test-consumption-verbs.lua`
- ✅ pour — `test/parser/pipeline/test-pour-patterns.lua` (parser), `test/verbs/test-wine-fsm.lua` (integration)
- ⚠️ dump — no dedicated test
- ⚠️ wash — `test/verbs/test-wash-verb.lua` exists but coverage is light
- ❌ sleep — no dedicated test (only tested via integration/multi-command)

---

### 2.6 `verbs/init.lua` — 508 LOC 🟡

**The Problem:** This should be a thin dispatcher (~60 LOC) but contains 400+ LOC of combat system logic (attack, fight, strike, swing, flee, combat encounter loop) that was bolted on during WAVE-3/WAVE-6. The `run_combat_encounter` function alone is 112 LOC.

**Split Recommendation (extract combat):**

```
src/engine/verbs/
  init.lua                  → 100 LOC (module loader, consciousness gate, creature catch/grab)
  combat_encounter.lua      → 400 LOC (attack, fight, hit, strike, swing, flee,
                                        run_combat_encounter, attempt_flee, all combat utilities)
```

**Phase 2 Growth:** +300–500 LOC (ranged combat, group combat, morale system, advanced stances). ALL growth lands in combat_encounter.lua. Without extraction, init.lua would exceed 1,000 LOC by WAVE-2.

**LLM Impact:** Editing module registration currently loads 508 LOC of mostly-combat code. Post-split, init.lua is 100 LOC. **~80% context reduction.**

**Test Gap Inventory:**
- ✅ Creature catch — `test/creatures/test-creature-verbs.lua`
- ✅ Attack/hit — `test/verbs/test-combat-verbs.lua`, `test/combat/test-combat-integration.lua`
- ⚠️ Flee — partial (tested in combat integration, no dedicated unit test)
- ❌ Consciousness gate — no dedicated test (tested indirectly via `test/verbs/test-hit-unconscious.lua`)
- ❌ `run_combat_encounter` loop — no dedicated test for multi-round encounter

---

### 2.7 `verbs/crafting.lua` — 629 LOC 🟡

**The Problem:** Three unrelated verb groups — writing (dynamic code generation), sewing (recipe crafting), and container placement (`put` verb at 295 LOC, 46% of file). The `put` handler is functionally an inventory verb, not a crafting verb.

**Split Recommendation (2 extractions):**

```
src/engine/verbs/
  crafting.lua              → 65 LOC (thin register wrapper)
  crafting/
    writing.lua             → 165 LOC (write, inscribe — dynamic mutation)
    recipes.lua             → 150 LOC (sew, stitch, mend — recipe crafting)
    placement.lua           → 295 LOC (put — container/surface placement)
```

**Phase 2 Growth:** +100–200 LOC (new recipes for cooking/smithing in recipes.lua, NPC trade via placement). The `put` handler is stable.

**LLM Impact:** Editing sewing recipes currently loads 629 LOC. Post-split: 150 LOC. **~76% context reduction.**

**Test Gap Inventory:**
- ✅ put — `test/inventory/test-put-container-scope-267.lua`, `test/inventory/test-put-regression.lua`
- ⚠️ write — no dedicated test (tested indirectly)
- ❌ sew — no dedicated test

---

## 3. Nice-to-Split Files

### 3.1 `verbs/acquisition.lua` — 792 LOC

**Assessment:** 20 verbs but only 4 core implementations (take, pull, push, drop) with 17 aliases. The `take` handler (313 LOC) and `drop` handler (207 LOC) are the complexity centers.

**Recommended split (if needed):**
- `acquisition/pickup.lua` — take, get, pick, grab (~320 LOC)
- `acquisition/movement.lua` — pull, push, move, slide, lift, uncork (~270 LOC)
- `acquisition/drop.lua` — drop with material fragility (~210 LOC)

**Phase 2 Growth:** +50–100 LOC (NPC loot, creature drop behavior). Low urgency.

**Test Coverage:** ✅ Good — `test/inventory/`, `test/verbs/test-fuzzy-drop.lua`, `test/verbs/test-on-drop.lua`

---

### 3.2 `parser/goal_planner.lua` — 790 LOC

**Assessment:** GOAP backward-chainer with fire-source specialization. Object finders (180 LOC) and generic tool planning (100 LOC) are extractable.

**Recommended split (if needed):**
- `goal_finders.lua` — 180 LOC (find_all, find_property, find_lightable, find_by_id)
- `goal_tools.lua` — 100 LOC (plan_retrieval, plan_for_light, plan_generic_tool)
- `goal_planner.lua` — 510 LOC (fire source + state queries + main API)

**Phase 2 Growth:** +200–350 LOC (NPC goal chains, advanced prerequisites). Extract finders before Phase 2.

**Test Coverage:** ✅ `test/parser/test-goap-tier6.lua` (integration)

---

### 3.3 `verbs/fire.lua` — 640 LOC

**Assessment:** 5 thematic groups (fire sources, light, extinguish, strike, burn). Fire source helpers are reusable.

**Recommended split (if needed):**
- Extract `fire_sources.lua` — 130 LOC (has_capable_state, auto_ignite, find_fire_source, find_unlit_source_name)
- Keep light/extinguish/strike/burn in `fire.lua` — 510 LOC

**Phase 2 Growth:** Low (+50 LOC). Fire system is mature.

**Test Coverage:** ✅ Good — `test/verbs/test-fire-verbs.lua`, `test/verbs/test-light-*.lua`, `test/verbs/test-burn-material.lua`, `test/verbs/test-fire-propagation.lua`

---

### 3.4 `verbs/meta.lua` — 536 LOC

**Assessment:** Kitchen-sink file: inventory display, time, bug reporting, help, injuries, healing, generic use, wait, appearance. 6+ unrelated domains.

**Recommended split:**
- `meta/display.lua` — 120 LOC (inventory, time, wait, appearance)
- `meta/help.lua` — 150 LOC (help, report_bug)
- `meta/health.lua` — 180 LOC (injuries, apply/treat, use)

**Phase 2 Growth:** +50–100 LOC (NPC injury inspection, party health). Low urgency.

**Test Coverage:**
- ✅ inventory — `test/verbs/test-meta-verbs.lua`
- ⚠️ help — no test
- ❌ apply/treat — no dedicated test
- ❌ report_bug — no test (meta/UI, acceptable)

---

## 4. Phase 2 Growth Watch — Pre-Split Critical

### Files That Will Exceed 500 LOC During Phase 2

| File | Current LOC | Phase 2 Growth Est. | Projected LOC | Action |
|------|-------------|---------------------|---------------|--------|
| `creatures/init.lua` | 421 | +200–400 | 620–820 | **Pre-split: extract behavior.lua** |
| `combat/init.lua` | 435 | +400–700 | 835–1,135 | **Pre-split: extract weapons.lua, aftermath.lua** |
| `verbs/init.lua` | 508 | +300–500 | 808–1,008 | **MUST-SPLIT NOW** (combat extraction) |
| `verbs/combat.lua` | 321 | +100–200 | 421–521 | Monitor |
| `loop/init.lua` | 622 | +80–150 | 702–772 | Refactor-in-place (extract helpers, don't split) |

### Recommended Pre-Splits for creatures/init.lua

```
src/engine/creatures/
  init.lua                → 250 LOC (tick orchestrator, stimulus queue, room queries)
  behavior.lua            → 170 LOC (score_actions, execute_action, creature_tick)
  navigation.lua          → 100 LOC (get_exit_target, get_room_distance, is_exit_passable, get_valid_exits)
```

### Recommended Pre-Splits for combat/init.lua

```
src/engine/combat/
  init.lua                → 250 LOC (initiate, declare, respond, resolve_exchange, resolve)
  weapons.lua             → 100 LOC (normalize_weapon, pick_weapon, ensure_material_defaults, get_material)
  zones.lua               → 50 LOC (zone_weights, weighted_zone, select_zone)
  aftermath.lua           → 100 LOC (update, map_severity_to_injury, run_combat, interrupt_check)
```

---

## 5. Files That Do NOT Need Splitting

| File | LOC | Assessment |
|------|-----|------------|
| `loop/init.lua` | 622 | Single monolithic function. **Refactor** into 6–8 private helper functions within the file. Splitting would fragment state management. |
| `parser/embedding_matcher.lua` | 516 | Well-organized with clear phases (P1–P5). 516 LOC is acceptable for a self-contained matching algorithm. |
| `parser/fuzzy.lua` | 490 | Under threshold. Monitor. |
| `verbs/equipment.lua` | 482 | Only 2 handlers (wear/remove), balanced ~250 LOC each. Inverse operations that share slot/layer logic. |
| `search/narrator.lua` | 444 | Pure narration templates. Under threshold. |
| `fsm/init.lua` | 420 | Core engine module. Under threshold. Stable. |
| `injuries.lua` | 424 | Under threshold. Phase 2 growth is moderate. |
| All 28 files < 260 LOC | 60–257 | Healthy. |

---

## 6. Test Gap Inventory — Summary

### Coverage by Module Area

| Area | Test Files | Status |
|------|-----------|--------|
| Verbs | 50 | ✅ Excellent |
| Parser | 31 | ✅ Excellent |
| Search | 17 | ✅ Good |
| Objects | 13 | ✅ Good |
| Integration | 10 | ✅ Good |
| Rooms | 9 | ✅ Good |
| Combat | 7 | ⚠️ Growing area, needs more |
| Creatures | 7 | ⚠️ Phase 2 growth area |
| Inventory | 7 | ✅ Good |
| Injuries | 6 | ✅ Adequate |
| Armor | 2 | ⚠️ Light |
| UI | 2 | ⚠️ Light |
| FSM | 1 | ⚠️ Under-tested for 420 LOC |
| Sensory | 1 | ❌ Needs dedicated per-sense tests |

### Critical Test Gaps (Must Fix Before Phase 2)

| Module | Gap | Risk |
|--------|-----|------|
| `verbs/helpers.lua` → `handle_self_infliction` | No unit test (only integration) | HIGH — Phase 2 combat depends on injury pipeline |
| `verbs/helpers.lua` → `consume_tool_charge` | No dedicated test | MEDIUM — tool depletion is core mechanic |
| `verbs/sensory.lua` → listen handler | No test at all | LOW — simple handler but gap |
| `verbs/sensory.lua` → read (skill acquisition) | No dedicated test | MEDIUM — skill system depends on this |
| `verbs/survival.lua` → sleep | No unit test | HIGH — time advancement affects FSM ticks globally |
| `verbs/init.lua` → run_combat_encounter | No dedicated test | HIGH — Phase 2 adds multi-round encounters |
| `verbs/crafting.lua` → sew/write | No dedicated tests | MEDIUM — crafting expansion in Phase 2 |
| `combat/init.lua` → resolve_damage | No unit test for tissue penetration math | HIGH — core combat math |
| `creatures/init.lua` → behavior scoring | No unit test for score_actions | HIGH — NPC AI depends on this |

---

## 7. Dependency Graph — Split Safety

### Verb Module Dependencies

```
verbs/init.lua (registry)
  ├── verbs/sensory.lua      ← requires: helpers, search, creatures (optional)
  ├── verbs/acquisition.lua  ← requires: helpers
  ├── verbs/containers.lua   ← requires: helpers
  ├── verbs/destruction.lua  ← requires: helpers
  ├── verbs/fire.lua         ← requires: helpers
  ├── verbs/combat.lua       ← requires: helpers, injuries
  ├── verbs/crafting.lua     ← requires: helpers
  ├── verbs/equipment.lua    ← requires: helpers
  ├── verbs/survival.lua     ← requires: helpers
  ├── verbs/movement.lua     ← requires: helpers
  ├── verbs/meta.lua         ← requires: helpers, fsm, injuries, appearance
  └── verbs/traps.lua        ← requires: helpers
```

**Key insight:** ALL verb modules depend on `helpers.lua`. Splitting helpers must preserve backward compatibility — the parent `helpers.lua` must re-export all sub-modules so existing `require("engine.verbs.helpers")` calls continue to work.

### Safe Split Order (No Dependency Cycles)

1. **helpers/inventory.lua** — leaf node, no internal deps
2. **helpers/tools.lua** — depends on inventory only
3. **helpers/search.lua** — depends on inventory + parser/context + parser/fuzzy
4. **helpers/spatial.lua** — depends on search + fsm
5. **helpers/self_harm.lua** — depends on search + inventory + effects
6. **helpers/parts.lua** — depends on inventory + search + fsm (split last)

### Parser Module Dependencies

```
parser/init.lua (Tier 2 wrapper)
  ├── parser/preprocess.lua      ← standalone (no internal deps)
  ├── parser/embedding_matcher.lua ← requires: json, bm25_data, synonym_table, context
  ├── parser/goal_planner.lua    ← requires: preprocess, presentation
  ├── parser/fuzzy.lua           ← requires: preprocess, bm25_data
  └── parser/context.lua         ← standalone
```

**Parser splits are safe:** Each parser module has minimal cross-dependencies. Preprocess sub-modules are pure text transforms — zero coupling risk.

---

## 8. Split Priority Matrix

### Must-Split Before Phase 2 WAVE-1 (6 files)

| Priority | File | Action | Estimated Effort | Risk |
|----------|------|--------|------------------|------|
| P0 | `verbs/init.lua` | Extract combat to `combat_encounter.lua` | 2 hours | LOW — clean cut |
| P0 | `verbs/helpers.lua` | Split into 6 sub-modules under `helpers/` | 4 hours | MEDIUM — many consumers |
| P1 | `parser/preprocess.lua` | Split into 5 sub-modules under `preprocess/` | 3 hours | LOW — pure functions |
| P1 | `verbs/sensory.lua` | Split into 5 sub-modules under `sensory/` | 3 hours | LOW — no cross-calls |
| P2 | `verbs/survival.lua` | Split into 3 sub-modules under `survival/` | 2 hours | LOW |
| P2 | `verbs/crafting.lua` | Split into 3 sub-modules under `crafting/` | 2 hours | LOW |

### Pre-Split for Phase 2 Growth (2 files)

| Priority | File | Action | Estimated Effort | Risk |
|----------|------|--------|------------------|------|
| P2 | `creatures/init.lua` | Extract behavior.lua + navigation.lua | 2 hours | LOW |
| P2 | `combat/init.lua` | Extract weapons.lua + aftermath.lua | 2 hours | LOW |

### Nice-to-Split (4 files, non-blocking)

| Priority | File | Action | Estimated Effort |
|----------|------|--------|------------------|
| P3 | `search/traverse.lua` | Extract matching.lua + queue.lua | 2 hours |
| P3 | `verbs/meta.lua` | Split into display/help/health | 2 hours |
| P3 | `parser/goal_planner.lua` | Extract finders.lua + tools.lua | 2 hours |
| P4 | `verbs/fire.lua` | Extract fire_sources.lua | 1 hour |

---

## 9. Phase 2 Pre-Flight Checklist

### ✅ MUST DO Before WAVE-1

- [ ] **P0: Extract combat from verbs/init.lua** — init.lua must be a thin dispatcher before combat expansion starts
- [ ] **P0: Split verbs/helpers.lua** — every verb module depends on it; splitting reduces blast radius for all Phase 2 work
- [ ] **P1: Split parser/preprocess.lua** — combat command parsing additions need clean module boundaries
- [ ] **P1: Split verbs/sensory.lua** — NPC descriptions (look) and creature sounds (listen) need isolated modules
- [ ] **Nelson: Write tests for critical gaps** — self-infliction unit tests, sleep unit tests, run_combat_encounter tests, resolve_damage tests, creature behavior scoring tests
- [ ] **Nelson: Establish Phase 2 test baseline** — full suite pass count recorded before any refactoring begins

### ⚠️ SHOULD DO Before WAVE-2

- [ ] **P2: Split verbs/survival.lua** — food systems (Phase 2) will add to consumption verbs
- [ ] **P2: Split verbs/crafting.lua** — recipe expansion (cooking, smithing) needs clean crafting module
- [ ] **P2: Pre-split creatures/init.lua** — NPC behavior expansion needs isolated behavior.lua
- [ ] **P2: Pre-split combat/init.lua** — ranged combat, armor system need clean module boundaries

### 📋 AFTER WAVE-3

- [ ] **P3: Split search/traverse.lua** — NPC detection search will add match types
- [ ] **P3: Split verbs/meta.lua** — NPC health inspection needs isolated health module
- [ ] **P3: Split parser/goal_planner.lua** — NPC goal chains need generic finders
- [ ] **Refactor loop/init.lua** — extract 6–8 internal helpers (don't split file)

---

## 10. Sequencing Notes

Per the `engine-code-review` skill (SKILL.md):

1. **This document = Phase 1 (Senior Code Review)** ✅
2. **Phase 2 = Pre-Refactor Test Baseline (Nelson)** — Nelson runs full suite, records counts, writes tests for gaps identified above
3. **Phase 3 = Execute Refactors (Bart)** — follow `register()` pattern proven in March 25 refactor; use `gpt-5.2-codex` for large multi-file splits
4. **Phase 4 = Post-Refactor Verification (Nelson)** — same test count, zero regressions
5. **Phase 5 = Sequencing with Phase 2 Features** — refactoring completes BEFORE NPC/combat features begin

**Critical rule from SKILL.md:** "No refactoring starts until the test baseline is established and new coverage tests pass."

---

*End of Phase 1 review. Filed by Bart, Architect.*
