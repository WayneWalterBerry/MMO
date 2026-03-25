# meta-lint Acceptance Criteria

**Author:** Lisa (Object Testing Specialist)
**Version:** 1.0
**Date:** 2026-03-24
**Purpose:** Complete rules catalog for the meta-lint static validator. Every check Lisa wants performed against `.lua` object, room, and level files before they reach the engine.

**Severity Legend:**
- 🔴 **ERROR** — Invalid object. Must fix before merge.
- 🟡 **WARNING** — Probably wrong. Author should review.
- 🟢 **INFO** — Style suggestion. Non-blocking.

---

## Table of Contents

1. [Structural Checks — All Objects](#1-structural-checks--all-objects)
2. [Template-Specific Structural Checks](#2-template-specific-structural-checks)
3. [GUID Checks](#3-guid-checks)
4. [Sensory Checks](#4-sensory-checks)
5. [FSM Checks](#5-fsm-checks)
6. [Transition Checks](#6-transition-checks)
7. [Mutation Checks](#7-mutation-checks)
8. [Material Reference Checks](#8-material-reference-checks)
9. [Room Checks](#9-room-checks)
10. [Nesting & Containment Checks](#10-nesting--containment-checks)
11. [Cross-File Checks](#11-cross-file-checks)
12. [Level Definition Checks](#12-level-definition-checks)
13. [Composite Parts Checks](#13-composite-parts-checks)
14. [Effects Pipeline Checks](#14-effects-pipeline-checks)
15. [Lint Rules](#15-lint-rules)

---

## 1. Structural Checks — All Objects

These apply to every `.lua` file in `src/meta/objects/`.

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| S-01 | File returns a table | 🔴 ERROR | The `.lua` file must `return { ... }`. A file that returns nil, a string, or errors on load is invalid. |
| S-02 | `guid` field exists | 🔴 ERROR | Every object MUST have a `guid` field. |
| S-03 | `guid` format valid | 🔴 ERROR | GUID must match Windows GUID format: `{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}` where `x` is `[0-9a-fA-F]`. Bare GUIDs without braces (e.g., `44ea2c40-e898-...`) are also accepted for rooms — but should be flagged as 🟡 WARNING for inconsistency. |
| S-04 | `id` field exists | 🔴 ERROR | Every object must have a non-empty string `id`. |
| S-05 | `id` format valid | 🟡 WARNING | `id` should be lowercase-with-dashes (`[a-z0-9-]+`). Underscores, spaces, or uppercase trigger warning. |
| S-06 | `name` field exists | 🔴 ERROR | Every object must have a non-empty string `name`. |
| S-07 | `template` field exists | 🔴 ERROR | Every object (except templates themselves) must declare `template` referencing one of: `small-item`, `container`, `furniture`, `room`, `sheet`. |
| S-08 | `template` references valid template | 🔴 ERROR | The `template` value must correspond to a file in `src/meta/templates/`. |
| S-09 | `keywords` field exists | 🟡 WARNING | Every object should have a `keywords` table. An empty table is acceptable but unusual. |
| S-10 | `keywords` is a table of strings | 🔴 ERROR | If present, `keywords` must be `{string, string, ...}`. Non-string entries are invalid. |
| S-11 | `description` field exists | 🔴 ERROR | Every object must have a non-empty `description` (string or function). |
| S-12 | `location` field exists | 🟢 INFO | Objects should declare `location = nil` explicitly for clarity. |
| S-13 | `mutations` field exists | 🟢 INFO | Objects should declare `mutations = {}` even if empty, for structural consistency. |
| S-14 | `categories` is a table of strings | 🔴 ERROR | If present, `categories` must be `{string, ...}`. |
| S-15 | `portable` is boolean | 🔴 ERROR | If present, `portable` must be `true` or `false`. |
| S-16 | `size` is a positive number | 🔴 ERROR | If present, `size` must be a number > 0. |
| S-17 | `weight` is a positive number | 🔴 ERROR | If present, `weight` must be a number > 0. |
| S-18 | No unknown top-level field types | 🟢 INFO | Flag any top-level field that is not a known type (string, number, boolean, table, function, nil). |

---

## 2. Template-Specific Structural Checks

### 2.1 `small-item` Template

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| SI-01 | `size` defined | 🔴 ERROR | Must declare `size` (number). |
| SI-02 | `weight` defined | 🔴 ERROR | Must declare `weight` (number). |
| SI-03 | `portable` is true | 🟡 WARNING | Small items should be `portable = true`. If false, flag for review. |
| SI-04 | `material` defined | 🔴 ERROR | Must declare a `material` string (Principle 9). |

### 2.2 `container` Template

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| CT-01 | `container` is true | 🔴 ERROR | Must declare `container = true`. |
| CT-02 | `capacity` defined | 🔴 ERROR | Must declare `capacity` as a positive number. |
| CT-03 | `size` defined | 🔴 ERROR | Must declare `size`. |
| CT-04 | `weight` defined | 🔴 ERROR | Must declare `weight`. |
| CT-05 | `material` defined | 🔴 ERROR | Must declare `material`. |

### 2.3 `furniture` Template

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| FU-01 | `size` defined | 🔴 ERROR | Must declare `size`. |
| FU-02 | `weight` defined | 🔴 ERROR | Must declare `weight`. |
| FU-03 | `material` defined | 🔴 ERROR | Must declare `material`. |
| FU-04 | `portable` check | 🟡 WARNING | Furniture defaults to `portable = false`. If `portable = true`, must also declare `hands_required`. |

### 2.4 `sheet` Template

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| SH-01 | `size` defined | 🔴 ERROR | Must declare `size`. |
| SH-02 | `weight` defined | 🔴 ERROR | Must declare `weight`. |
| SH-03 | `material` defined | 🔴 ERROR | Must declare `material`. Material should be fabric-class (fabric, wool, cotton, linen, velvet, burlap, hemp). |
| SH-04 | `material` is fabric-class | 🟡 WARNING | A sheet with `material = "iron"` is suspicious. Flag non-fabric materials. |

### 2.5 `room` Template

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| RM-01 | `description` defined | 🔴 ERROR | Rooms must have a non-empty description. |
| RM-02 | `exits` defined | 🟡 WARNING | Rooms should have an `exits` table. A room with zero exits traps the player. |
| RM-03 | `instances` defined | 🟡 WARNING | Rooms should have an `instances` table (objects in the room). |
| RM-04 | `level` defined | 🟡 WARNING | Rooms should declare `level = { number = N, name = "..." }`. |
| RM-05 | No `size`/`weight`/`portable` on rooms | 🔴 ERROR | Rooms must not declare physical properties meant for objects. |
| RM-06 | `short_description` present | 🟢 INFO | Rooms should have a `short_description` for brief revisits. |

---

## 3. GUID Checks

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| G-01 | GUID is well-formed | 🔴 ERROR | Must be 8-4-4-4-12 hex pattern. Braces `{...}` optional but preferred for objects. |
| G-02 | GUID uniqueness across all objects | 🔴 ERROR | No two `.lua` files in `src/meta/objects/` may share the same `guid`. Scan ALL files. |
| G-03 | GUID uniqueness across all rooms | 🔴 ERROR | No two `.lua` files in `src/meta/rooms/` may share the same `guid`. |
| G-04 | GUID uniqueness across objects + rooms + levels | 🟡 WARNING | GUIDs should be globally unique across the entire `src/meta/` tree. |
| G-05 | No placeholder GUIDs | 🔴 ERROR | Reject GUIDs like `{00000000-0000-0000-0000-000000000000}`, `{guid}`, `{guid-candle}`, or any GUID containing non-hex characters. |
| G-06 | GUID format consistency | 🟡 WARNING | All GUIDs in `src/meta/objects/` should use the `{braced}` format. Mixed formats (some braced, some bare) reduce readability. |

---

## 4. Sensory Checks

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| SN-01 | `on_feel` exists (non-room objects) | 🔴 ERROR | **Every non-room object MUST have `on_feel`.** This is the #1 rule. `on_feel` is the primary sense in darkness — the entire game can start in pitch black. Missing `on_feel` means the player cannot perceive the object at all in the dark. |
| SN-02 | `on_feel` is string or function | 🔴 ERROR | `on_feel` must be a string or a function returning a string. A number, boolean, or table is invalid. |
| SN-03 | `on_feel` is non-empty | 🔴 ERROR | An empty string `""` for `on_feel` is equivalent to missing — the player gets nothing. |
| SN-04 | `on_smell` recommended | 🟡 WARNING | Objects should have `on_smell`. Almost every physical object has a scent. Missing this reduces immersion. |
| SN-05 | `on_listen` recommended for FSM objects | 🟡 WARNING | Objects with multiple states (FSM) should have `on_listen` — state changes often produce sound. |
| SN-06 | `on_taste` recommended for consumables | 🟡 WARNING | Objects with `is_consumable = true` or categories including `"consumable"`, `"liquid"`, `"food"`, or `"poison"` should have `on_taste`. |
| SN-07 | Sensory fields are string or function | 🔴 ERROR | `on_smell`, `on_listen`, `on_taste` must each be a string or function if present. |
| SN-08 | State-level `on_feel` exists for FSM objects | 🔴 ERROR | If an object has `states`, every state definition MUST have its own `on_feel` (string or function). State determines perception — a lit candle feels different from an unlit one. |
| SN-09 | State-level sensory consistency | 🟡 WARNING | If the top-level object has `on_smell`, each state should also have `on_smell` (or inherit clearly). State changes often alter smell (e.g., lit vs unlit). |
| SN-10 | Room `on_feel` exists | 🟡 WARNING | Rooms should have `on_feel` for darkness navigation. The hallway and cellar have it — all rooms should. |
| SN-11 | Room `on_smell` exists | 🟡 WARNING | Rooms should have `on_smell` for atmospheric immersion. |
| SN-12 | Room `on_listen` exists | 🟡 WARNING | Rooms should have `on_listen` for environmental audio. |

---

## 5. FSM Checks

These apply to any object that declares `states` and/or `transitions`.

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| FSM-01 | `initial_state` exists | 🔴 ERROR | If `states` is defined, `initial_state` MUST also be defined. |
| FSM-02 | `_state` exists | 🔴 ERROR | If `states` is defined, `_state` MUST also be defined. |
| FSM-03 | `_state` matches `initial_state` | 🔴 ERROR | At definition time, `_state` must equal `initial_state`. They diverge only at runtime. |
| FSM-04 | `initial_state` references a defined state | 🔴 ERROR | The value of `initial_state` must be a key in the `states` table. |
| FSM-05 | Every state has `name` | 🟡 WARNING | Each entry in `states` should have a `name` field (string). |
| FSM-06 | Every state has `description` | 🟡 WARNING | Each entry in `states` should have a `description` field (string or function). |
| FSM-07 | Every state has `on_feel` | 🔴 ERROR | Each state MUST have `on_feel` (string or function). See SN-08. |
| FSM-08 | No orphan states | 🟡 WARNING | Every state defined in `states` should be reachable — either as `initial_state` or as a `to` target in at least one transition. A state that can never be entered is likely a bug. Exception: `initial_state` is always reachable by definition. |
| FSM-09 | Terminal states have no outgoing transitions | 🟡 WARNING | If a state declares `terminal = true`, there should be no transitions with that state as `from`. |
| FSM-10 | At least one terminal state or cycle | 🟢 INFO | FSM objects should either have a terminal state (end condition) or form a cycle (e.g., open↔closed). An FSM with states but no transitions is suspicious. |
| FSM-11 | No `states` without `transitions` | 🟡 WARNING | If `states` is defined and has more than one state, `transitions` should also be defined. States without transitions are unreachable. |
| FSM-12 | Top-level properties match initial state | 🟡 WARNING | The object's top-level `name`, `description`, `on_feel` etc. should match the values in `states[initial_state]`. Mismatches cause confusing initial presentation. |

---

## 6. Transition Checks

These apply to each entry in the `transitions` array.

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| TR-01 | `from` references a defined state | 🔴 ERROR | `transition.from` must be a key in the `states` table. |
| TR-02 | `to` references a defined state | 🔴 ERROR | `transition.to` must be a key in the `states` table. |
| TR-03 | `verb` is a non-empty string | 🔴 ERROR | Every transition must declare a `verb` (the player action that triggers it). |
| TR-04 | `message` is a non-empty string | 🟡 WARNING | Every transition should have a `message` — the narrative text shown to the player. |
| TR-05 | `fail_message` for guarded transitions | 🟡 WARNING | If a transition has `requires_tool` or `requires_property`, it should also have `fail_message` so the player gets useful feedback on failure. |
| TR-06 | `aliases` is a table of strings | 🔴 ERROR | If present, `aliases` must be `{string, ...}`. |
| TR-07 | `requires_tool` is a string | 🔴 ERROR | If present, must be a string identifying the tool capability (e.g., `"fire_source"`). |
| TR-08 | `requires_property` is a string | 🔴 ERROR | If present, must be a string identifying the required property (e.g., `"has_striker"`). |
| TR-09 | No duplicate from+verb pairs | 🔴 ERROR | Two transitions with the same `from` state and same `verb` (ignoring auto-triggers) create ambiguity. The engine wouldn't know which to fire. |
| TR-10 | Auto-trigger transitions have `condition` | 🟡 WARNING | Transitions with `trigger = "auto"` should have a `condition` field (e.g., `"timer_expired"`). An auto-trigger with no condition is confusing. |
| TR-11 | Transition `from` is not a terminal state | 🔴 ERROR | If `states[transition.from].terminal == true`, this transition is unreachable. |

---

## 7. Mutation Checks

These apply to `mutate` fields on transitions and top-level `mutations`.

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| MU-01 | `mutate` is a table | 🔴 ERROR | If present on a transition, `mutate` must be a table. |
| MU-02 | Direct value type valid | 🟡 WARNING | Direct value mutations (e.g., `weight = 0.5`) should match the expected type of the target field. A `weight = "heavy"` is suspicious. |
| MU-03 | Function mutations are callable | 🔴 ERROR | Computed mutations (e.g., `weight = function(w) ... end`) must be functions. |
| MU-04 | List ops have valid structure | 🔴 ERROR | `keywords = { add = "x" }` or `keywords = { remove = "x" }` — the value of `add`/`remove` must be a string. |
| MU-05 | `becomes` references a valid object ID | 🟡 WARNING | If a mutation has `becomes = "candle-broken"`, there should be a corresponding `.lua` file for that object. |
| MU-06 | `spawns` entries reference valid object IDs | 🟡 WARNING | If `spawns = {"glass-shard", "cloth"}`, each entry should correspond to an existing object definition. |
| MU-07 | Top-level `mutations` table well-formed | 🔴 ERROR | Each key in `mutations` should map to a table with valid mutation fields (`becomes`, `spawns`, `message`, etc.). |

---

## 8. Material Reference Checks

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| MAT-01 | `material` field exists (non-room objects) | 🔴 ERROR | Every non-room object MUST declare `material` (Principle 9: Material Consistency). |
| MAT-02 | `material` references a valid registry entry | 🔴 ERROR | The `material` value must be a key in `materials.registry` from `src/engine/materials/init.lua`. Valid materials: `wax`, `wood`, `fabric`, `wool`, `iron`, `steel`, `brass`, `glass`, `paper`, `leather`, `ceramic`, `tallow`, `cotton`, `oak`, `velvet`, `cardboard`, `linen`, `stone`, `silver`, `hemp`, `bone`, `burlap`, `plant`. |
| MAT-03 | No `material = "generic"` in objects | 🟡 WARNING | Templates use `"generic"` as a placeholder. Real objects should specify an actual material. |
| MAT-04 | Material-category consistency | 🟢 INFO | An object with `material = "glass"` might reasonably have `"fragile"` in its categories. An object with `material = "iron"` probably shouldn't have `"fragile"`. This is a heuristic, not a hard rule. |

---

## 9. Room Checks

These apply to `.lua` files in `src/meta/rooms/`.

### 9.1 Exit Checks

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| EX-01 | `exits` is a table | 🔴 ERROR | If present, `exits` must be a table keyed by direction strings. |
| EX-02 | Exit `target` references a valid room | 🟡 WARNING | Each exit's `target` should match the `id` of a room in `src/meta/rooms/`. Targets like `"level-2"` or `"manor-west"` that don't yet exist should be flagged as warning (future room), not error. |
| EX-03 | Exit has `type` | 🟡 WARNING | Exits should declare `type` (e.g., `"door"`, `"stairway"`, `"window"`, `"trap_door"`). |
| EX-04 | Exit has `name` | 🟡 WARNING | Exits should have a `name` for player-facing text. |
| EX-05 | Exit has `description` | 🟡 WARNING | Exits should have a `description`. |
| EX-06 | Exit has `keywords` | 🟡 WARNING | Exits should have `keywords` for parser resolution. |
| EX-07 | Locked exits have `key_id` or unlock mechanism | 🟡 WARNING | If `locked = true`, the exit should declare `key_id` or have an unlock mutation. An exit that's locked with no way to unlock it traps the player. |
| EX-08 | Exit passage constraints valid | 🟢 INFO | If `max_carry_size`, `max_carry_weight`, `player_max_size` are declared, they should be positive numbers. |
| EX-09 | Bidirectional exit consistency | 🟡 WARNING | If room A has an exit to room B, room B should have a return exit to room A (unless `one_way = true`). |

### 9.2 Instance Checks

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| RI-01 | Each instance has `id` | 🔴 ERROR | Every entry in `instances` must have a string `id`. |
| RI-02 | Each instance has `type_id` | 🔴 ERROR | Every entry must have `type_id` referencing an object's GUID. |
| RI-03 | `type_id` references a valid object GUID | 🟡 WARNING | The `type_id` should match the `guid` of an existing object in `src/meta/objects/`. Unresolved references mean missing objects. |
| RI-04 | Instance `id` is unique within room | 🔴 ERROR | No two instances in the same room may share the same `id`. |
| RI-05 | Nesting keys are valid | 🔴 ERROR | Instance children may only use keys: `on_top`, `contents`, `nested`, `underneath`. Any other nesting key is invalid. |

---

## 10. Nesting & Containment Checks

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| NC-01 | Nesting depth limit | 🟡 WARNING | Nesting deeper than 4 levels (e.g., room → nightstand → drawer → matchbox → match) is the practical maximum. Deeper than 5 is likely a design error. |
| NC-02 | `contents` only on containers | 🟡 WARNING | In room instance nesting, `contents` children should only appear on objects that have `container = true` in their definition. A non-container with contents is suspicious. |
| NC-03 | `nested` for slot objects only | 🟢 INFO | `nested` should be used for physical slot relationships (drawer in nightstand), not generic containment. |
| NC-04 | `on_top` on surfaced objects | 🟡 WARNING | Objects with `on_top` children should have `surfaces.top` declared in their definition. |
| NC-05 | `underneath` implies hidden | 🟢 INFO | Items in `underneath` are typically hidden until the parent is moved. If the parent is not `movable`, the items may be permanently inaccessible. |
| NC-06 | Capacity not exceeded | 🟡 WARNING | If a container has `capacity = N`, the number of items in `contents` (at definition time) should not exceed N. |
| NC-07 | Max item size respected | 🟡 WARNING | If a container has `max_item_size = M`, no contained item should have `size > M`. |
| NC-08 | Nesting keys not on object definitions | 🟡 WARNING | `on_top`, `contents` (as nesting), `nested`, `underneath` are room-instance patterns. Object definitions in `src/meta/objects/` should not use these as spatial nesting keys (they may use `contents` as a list of contained item IDs, which is different). |

---

## 11. Cross-File Checks

These require scanning multiple files together.

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| XF-01 | GUID global uniqueness | 🔴 ERROR | No two files anywhere in `src/meta/` may share the same GUID. Scan objects, rooms, levels, and templates. |
| XF-02 | `id` uniqueness within objects | 🟡 WARNING | Two objects with the same `id` in `src/meta/objects/` cause ambiguity. If intentional (e.g., state variants like `matchbox` and `matchbox-open`), they should have different `id` values. |
| XF-03 | Keyword overlap audit | 🟢 INFO | Report any keywords shared by multiple objects. Shared keywords aren't always wrong (both `wine-bottle` and `poison-bottle` use `"bottle"`) but excessive overlap causes parser ambiguity. |
| XF-04 | File name matches `id` | 🟡 WARNING | The filename (without `.lua`) should match the object's `id` field. `candle.lua` should have `id = "candle"`. Mismatches are confusing. |
| XF-05 | All room instance `type_id` references resolve | 🔴 ERROR | Every `type_id` in every room's `instances` must match a `guid` in some object file. Unresolved type_ids mean the engine will fail to load. |
| XF-06 | All `becomes` targets exist | 🟡 WARNING | Any `becomes = "object-id"` in mutations should reference an existing object file. |
| XF-07 | All `spawns` targets exist | 🟡 WARNING | Any `spawns = {"object-id"}` entries should reference existing object files. |
| XF-08 | Bidirectional exit completeness | 🟡 WARNING | For every room A with exit to room B, verify room B has a reciprocal exit to room A (unless one_way). |
| XF-09 | Level room membership | 🟡 WARNING | Every room ID listed in a level's `rooms` table should correspond to an actual room file in `src/meta/rooms/`. |
| XF-10 | Orphan objects | 🟢 INFO | Objects in `src/meta/objects/` that are not referenced by any room instance, mutation `becomes`/`spawns`, or composite `parts` are orphans. They exist but are unreachable in-game. |
| XF-11 | `passage_id` uniqueness | 🟡 WARNING | If two rooms define exits with the same `passage_id`, they should be referring to opposite sides of the same passage. Verify the pair is consistent (same name/type). |

---

## 12. Level Definition Checks

These apply to files in `src/meta/levels/`.

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| LV-01 | `guid` exists and valid | 🔴 ERROR | Level must have a valid GUID. |
| LV-02 | `template` is `"level"` | 🔴 ERROR | Level files must declare `template = "level"`. |
| LV-03 | `number` is a positive integer | 🔴 ERROR | Level must have `number` as a positive integer. |
| LV-04 | `name` exists | 🔴 ERROR | Level must have a non-empty `name`. |
| LV-05 | `rooms` is a non-empty table | 🔴 ERROR | Level must list at least one room. |
| LV-06 | `start_room` is in `rooms` list | 🔴 ERROR | The `start_room` must be one of the rooms listed in `rooms`. |
| LV-07 | `start_room` references a valid room | 🔴 ERROR | `start_room` must match the `id` of a room file in `src/meta/rooms/`. |
| LV-08 | `completion` defined | 🟡 WARNING | Levels should have completion criteria. |
| LV-09 | `intro` defined | 🟡 WARNING | Levels should have intro text for new players. |
| LV-10 | `boundaries.entry` defined | 🟡 WARNING | Level should declare entry points. |

---

## 13. Composite Parts Checks

These apply to objects that declare a `parts` table.

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| CP-01 | Each part has `id` | 🔴 ERROR | Every part definition must have a string `id`. |
| CP-02 | Each part has `detachable` boolean | 🔴 ERROR | Must declare `detachable = true` or `detachable = false`. |
| CP-03 | Detachable parts have `factory` function | 🟡 WARNING | If `detachable = true`, the part should have a `factory` function that creates the standalone object. |
| CP-04 | Detachable parts have `detach_verbs` | 🟡 WARNING | Detachable parts should list verbs that trigger detachment. |
| CP-05 | Detachable parts have `detach_message` | 🟡 WARNING | Should have player-facing detachment text. |
| CP-06 | Part `on_feel` exists | 🔴 ERROR | Even non-detachable parts (like nightstand legs) need `on_feel` — the player can still touch them. |
| CP-07 | Reversible parts have matching transition | 🟡 WARNING | If `reversible = true`, there should be a `reattach_part` transition in the parent's `transitions` array. |
| CP-08 | Part `keywords` exist | 🟡 WARNING | Parts should have keywords for parser resolution. |
| CP-09 | Factory-produced objects have `on_feel` | 🔴 ERROR | The table returned by `factory()` must include `on_feel`. |

---

## 14. Effects Pipeline Checks

These apply to objects with `effects_pipeline = true`.

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| EF-01 | `effects_pipeline` flag present | 🟢 INFO | Objects using structured effect tables should declare `effects_pipeline = true`. |
| EF-02 | Effect tables have `type` field | 🔴 ERROR | Each effect in `pipeline_effects` or standalone effect tables must have a string `type` (e.g., `"inflict_injury"`). |
| EF-03 | Injury effects have `injury_type` | 🔴 ERROR | Effects with `type = "inflict_injury"` must declare `injury_type`. |
| EF-04 | Injury effects have `damage` | 🔴 ERROR | Injury effects must declare `damage` as a positive number. |
| EF-05 | Effect `source` matches object `id` | 🟡 WARNING | The `source` field in effects should match the parent object's `id`. |
| EF-06 | Prerequisites `warns` for dangerous effects | 🟡 WARNING | Objects with injury-causing effects should have `prerequisites` entries with `warns` hints so the GOAP planner can warn the player. |

---

## 15. Lint Rules

Style checks. Non-blocking. Improve consistency and readability.

### 15.1 Naming Conventions

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| LN-01 | Filename is lowercase-with-dashes | 🟢 INFO | Files should be `lowercase-with-dashes.lua`. No underscores, spaces, or uppercase. |
| LN-02 | `id` matches filename | 🟡 WARNING | The `id` field should match the filename (without `.lua`). |
| LN-03 | Keywords are lowercase | 🟢 INFO | All keyword strings should be lowercase. |

### 15.2 Field Ordering Conventions

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| LN-04 | Recommended field order | 🟢 INFO | Suggested top-level field order for readability: `guid`, `template`, `id`, `material`, `name`, `keywords`, `description`, sensory fields, physical properties (`size`, `weight`, `portable`, `categories`), FSM fields (`initial_state`, `_state`, `states`, `transitions`), `mutations`. |

### 15.3 Missing Recommended Fields

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| LN-05 | Missing `on_smell` | 🟢 INFO | Most physical objects have a scent. Flag missing `on_smell` as an informational note. |
| LN-06 | Missing `on_listen` | 🟢 INFO | Flag for objects that might make sound (containers, liquid holders, mechanical objects). |
| LN-07 | Missing `room_presence` on visible objects | 🟢 INFO | Objects placed in rooms should have `room_presence` text describing how they appear in room descriptions. |
| LN-08 | FSM states missing `room_presence` | 🟢 INFO | States that change an object's visible appearance (e.g., `lit` candle) should have `room_presence`. |

### 15.4 Content Quality

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| LN-09 | Description length | 🟢 INFO | Descriptions shorter than 20 characters are probably placeholder text. Flag for review. |
| LN-10 | Duplicate descriptions across states | 🟡 WARNING | If two different states have identical `description` text, the FSM isn't providing meaningful state feedback to the player. |
| LN-11 | `on_feel` mentions the object | 🟢 INFO | A good `on_feel` describes what the player's hands discover. Purely visual descriptions (e.g., "It looks blue") are wrong for a tactile sense. |

---

## Appendix A: Valid Material Names

Source: `src/engine/materials/init.lua`

```
wax, wood, fabric, wool, iron, steel, brass, glass, paper, leather,
ceramic, tallow, cotton, oak, velvet, cardboard, linen, stone, silver,
hemp, bone, burlap, plant
```

(23 materials as of 2026-03-24)

## Appendix B: Valid Template Names

Source: `src/meta/templates/`

```
small-item, container, furniture, room, sheet
```

(5 templates + `level` for level definitions)

## Appendix C: Nesting Relationship Keys

```
on_top      — Items sitting on a surface
contents    — Items inside a container
nested      — Objects in a physical slot
underneath  — Hidden items under parent
```

## Appendix D: Check Count Summary

| Category | 🔴 ERROR | 🟡 WARNING | 🟢 INFO | Total |
|----------|----------|------------|---------|-------|
| Structural (all objects) | 11 | 2 | 5 | 18 |
| Template-specific | 13 | 3 | 0 | 16 |
| GUID | 3 | 2 | 0 | 5 (+1 in S-03) |
| Sensory | 5 | 5 | 2 | 12 |
| FSM | 5 | 5 | 2 | 12 |
| Transitions | 7 | 3 | 0 | 10 (+1 combined) |
| Mutations | 2 | 3 | 0 | 5 (+2 in TR) |
| Materials | 2 | 2 | 0 | 4 |
| Room exits | 1 | 6 | 1 | 8 (+1 combined) |
| Room instances | 3 | 1 | 0 | 4 (+1 combined) |
| Nesting & containment | 0 | 5 | 3 | 8 |
| Cross-file | 3 | 6 | 2 | 11 |
| Level definitions | 5 | 3 | 0 | 8 (+2 combined) |
| Composite parts | 3 | 4 | 0 | 7 (+2 combined) |
| Effects pipeline | 2 | 2 | 1 | 5 (+1 combined) |
| Lint rules | 0 | 2 | 9 | 11 |
| **TOTAL** | **~65** | **~54** | **~25** | **~144** |

---

*This document is Lisa's wishlist. If meta-lint doesn't check it, nobody will.*
