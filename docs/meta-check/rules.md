# Meta-Check: Validation Rules

**Date:** 2026-03-24  
**Version:** 1.0  
**Author:** Brockman (Documentation), rule catalog from Lisa  
**Total Rules:** 144 across 15 categories  

---

## Severity Levels

- 🔴 **ERROR** — Invalid object. Must fix before merge. Exit code 1.
- 🟡 **WARNING** — Probably wrong. Author should review. Exit code 2.
- 🟢 **INFO** — Style suggestion. Non-blocking. Exit code 0 unless errors exist.

---

## Quick Reference by Category

| Category | 🔴 Errors | 🟡 Warnings | 🟢 Infos | Total |
|----------|-----------|-------------|---------|-------|
| [Structural](#1-structural-checks--all-objects) | 11 | 2 | 5 | 18 |
| [Template-Specific](#2-template-specific-checks) | 13 | 3 | 0 | 16 |
| [GUID](#3-guid-checks) | 3 | 2 | — | 5 |
| [Sensory](#4-sensory-checks) | 5 | 5 | 2 | 12 |
| [FSM](#5-fsm-checks) | 5 | 5 | 2 | 12 |
| [Transitions](#6-transition-checks) | 7 | 3 | — | 10 |
| [Mutations](#7-mutation-checks) | 2 | 3 | — | 5 |
| [Materials](#8-material-reference-checks) | 2 | 2 | — | 4 |
| [Rooms](#9-room-checks) | 1 | 6 | 1 | 8 |
| [Nesting](#10-nesting--containment-checks) | — | 5 | 3 | 8 |
| [Cross-File](#11-cross-file-checks) | 3 | 6 | 2 | 11 |
| [Levels](#12-level-definition-checks) | 5 | 3 | — | 8 |
| [Composite Parts](#13-composite-parts-checks) | 3 | 4 | — | 7 |
| [Effects Pipeline](#14-effects-pipeline-checks) | 2 | 2 | 1 | 5 |
| [Lint Rules](#15-lint-rules) | — | 2 | 9 | 11 |
| **TOTAL** | **~65** | **~54** | **~25** | **~144** |

---

## 1. Structural Checks — All Objects

**Apply to:** Every `.lua` file in `src/meta/objects/`

| Rule | Severity | Description |
|------|----------|-------------|
| **S-01** | 🔴 | File must `return { ... }`. A file that returns nil, a string, or errors on load is invalid. |
| **S-02** | 🔴 | `guid` field MUST exist. Every object needs a unique identifier. |
| **S-03** | 🔴 | `guid` format valid: `{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}` (Windows GUID). Bare GUIDs in rooms are 🟡 WARNING. |
| **S-04** | 🔴 | `id` field MUST exist and be a non-empty string. |
| **S-05** | 🟡 | `id` should be lowercase-with-dashes `[a-z0-9-]+`. Underscores, spaces, or uppercase → warning. |
| **S-06** | 🔴 | `name` field MUST exist and be non-empty. (e.g., `"a tallow candle"`) |
| **S-07** | 🔴 | `template` field MUST exist. One of: `small-item`, `container`, `furniture`, `room`, `sheet`. |
| **S-08** | 🔴 | `template` value must correspond to a file in `src/meta/templates/`. |
| **S-09** | 🟡 | `keywords` field recommended. An empty table is acceptable but unusual. |
| **S-10** | 🔴 | If `keywords` present, must be `{string, string, ...}`. Non-strings are invalid. |
| **S-11** | 🔴 | `description` field MUST exist and be non-empty (string or function). |
| **S-12** | 🟢 | Objects should declare `location = nil` explicitly for clarity. |
| **S-13** | 🟢 | Objects should declare `mutations = {}` (even if empty) for consistency. |
| **S-14** | 🔴 | If `categories` present, must be `{string, ...}`. |
| **S-15** | 🔴 | If `portable` present, must be `true` or `false`. |
| **S-16** | 🔴 | If `size` present, must be a number > 0. |
| **S-17** | 🔴 | If `weight` present, must be a number > 0. |
| **S-18** | 🟢 | Flag any top-level field not a known type (string, number, boolean, table, function, nil). |

---

## 2. Template-Specific Checks

### 2.1 Small-Item Template

| Rule | Severity | Description |
|------|----------|-------------|
| **SI-01** | 🔴 | MUST declare `size` (number). |
| **SI-02** | 🔴 | MUST declare `weight` (number). |
| **SI-03** | 🟡 | Should be `portable = true`. If false, flag for review. |
| **SI-04** | 🔴 | MUST declare `material` string (Principle 9: Material Consistency). |

### 2.2 Container Template

| Rule | Severity | Description |
|------|----------|-------------|
| **CT-01** | 🔴 | MUST declare `container = true`. |
| **CT-02** | 🔴 | MUST declare `capacity` as a positive number. |
| **CT-03** | 🔴 | MUST declare `size`. |
| **CT-04** | 🔴 | MUST declare `weight`. |
| **CT-05** | 🔴 | MUST declare `material`. |

### 2.3 Furniture Template

| Rule | Severity | Description |
|------|----------|-------------|
| **FU-01** | 🔴 | MUST declare `size`. |
| **FU-02** | 🔴 | MUST declare `weight`. |
| **FU-03** | 🔴 | MUST declare `material`. |
| **FU-04** | 🟡 | If `portable = true` (rare for furniture), must also declare `hands_required`. |

### 2.4 Sheet Template

| Rule | Severity | Description |
|------|----------|-------------|
| **SH-01** | 🔴 | MUST declare `size`. |
| **SH-02** | 🔴 | MUST declare `weight`. |
| **SH-03** | 🔴 | MUST declare `material`. Should be fabric-class. |
| **SH-04** | 🟡 | Material should be fabric-class (fabric, wool, cotton, linen, velvet, burlap, hemp). Non-fabric → warning. |

### 2.5 Room Template

| Rule | Severity | Description |
|------|----------|-------------|
| **RM-01** | 🔴 | `description` MUST be non-empty. |
| **RM-02** | 🟡 | `exits` table recommended. A room with zero exits traps the player. |
| **RM-03** | 🟡 | `instances` table recommended (objects in the room). |
| **RM-04** | 🟡 | Rooms should declare `level = { number = N, name = "..." }`. |
| **RM-05** | 🔴 | Rooms MUST NOT have `size`, `weight`, `portable` (physical object properties). |
| **RM-06** | 🟢 | Rooms should have `short_description` for brief revisits. |

---

## 3. GUID Checks

| Rule | Severity | Description |
|------|----------|-------------|
| **G-01** | 🔴 | GUID must be well-formed: 8-4-4-4-12 hex pattern. Braces `{...}` preferred for objects. |
| **G-02** | 🔴 | GUID uniqueness across ALL objects in `src/meta/objects/`. No duplicates. |
| **G-03** | 🔴 | GUID uniqueness across ALL rooms in `src/meta/world/`. No duplicates. |
| **G-04** | 🟡 | GUIDs should be globally unique across entire `src/meta/` tree. |
| **G-05** | 🔴 | Reject placeholder GUIDs: `{00000000-0000-...}`, `{guid}`, `{guid-candle}`, or any non-hex characters. |
| **G-06** | 🟡 | All GUIDs in `src/meta/objects/` should use `{braced}` format. Mixed formats reduce readability. |

---

## 4. Sensory Checks

**🔴 CRITICAL: Every object MUST have `on_feel`. This is the primary sense in darkness.**

| Rule | Severity | Description |
|------|----------|-------------|
| **SN-01** | 🔴 | `on_feel` MUST exist on all non-room objects. This is Principle #1. Player navigates in darkness via touch. |
| **SN-02** | 🔴 | `on_feel` must be a string or function returning a string. No numbers, booleans, or tables. |
| **SN-03** | 🔴 | `on_feel` must be non-empty. Empty string `""` is equivalent to missing. |
| **SN-04** | 🟡 | `on_smell` recommended. Most physical objects have a scent. |
| **SN-05** | 🟡 | For FSM objects: `on_listen` recommended. State changes often produce sound. |
| **SN-06** | 🟡 | For consumables/liquids/poison: `on_taste` recommended. |
| **SN-07** | 🔴 | Sensory fields (`on_smell`, `on_listen`, `on_taste`) must be string or function if present. |
| **SN-08** | 🔴 | For FSM objects: every state definition MUST have its own `on_feel`. State determines perception. |
| **SN-09** | 🟡 | For FSM objects: if top-level has `on_smell`, each state should also have `on_smell`. |
| **SN-10** | 🟡 | Rooms should have `on_feel` for darkness navigation. |
| **SN-11** | 🟡 | Rooms should have `on_smell` for atmospheric immersion. |
| **SN-12** | 🟡 | Rooms should have `on_listen` for environmental audio. |

---

## 5. FSM Checks

**Apply to:** Objects with `states` and/or `transitions` tables

| Rule | Severity | Description |
|------|----------|-------------|
| **FSM-01** | 🔴 | If `states` defined, `initial_state` MUST also be defined. |
| **FSM-02** | 🔴 | If `states` defined, `_state` MUST also be defined. |
| **FSM-03** | 🔴 | `_state` must equal `initial_state` at definition time. They diverge only at runtime. |
| **FSM-04** | 🔴 | `initial_state` value must be a key in the `states` table. |
| **FSM-05** | 🟡 | Each state should have `name` field (string). |
| **FSM-06** | 🟡 | Each state should have `description` field (string or function). |
| **FSM-07** | 🔴 | Each state MUST have `on_feel` (see SN-08). |
| **FSM-08** | 🟡 | Every state should be reachable: either as `initial_state` or as a `to` target in transitions. Orphan states = likely bug. |
| **FSM-09** | 🟡 | If state declares `terminal = true`, no transitions should have it as `from`. |
| **FSM-10** | 🟢 | FSM should either have a terminal state (end condition) or form a cycle. FSM with states but no transitions is suspicious. |
| **FSM-11** | 🟡 | If multiple states exist, `transitions` should also be defined. Unreachable states are useless. |
| **FSM-12** | 🟡 | Top-level `name`, `description`, `on_feel` should match `states[initial_state]` values. Mismatches confuse presentation. |

---

## 6. Transition Checks

**Apply to:** Each entry in `transitions` array

| Rule | Severity | Description |
|------|----------|-------------|
| **TR-01** | 🔴 | `from` must reference a key in `states` table. |
| **TR-02** | 🔴 | `to` must reference a key in `states` table. |
| **TR-03** | 🔴 | `verb` MUST be a non-empty string (the player action that triggers it). |
| **TR-04** | 🟡 | `message` recommended: narrative text shown to player. |
| **TR-05** | 🟡 | If transition has `requires_tool` or `requires_property`, include `fail_message` for failure feedback. |
| **TR-06** | 🔴 | If `aliases` present, must be `{string, ...}`. |
| **TR-07** | 🔴 | If `requires_tool` present, must be a string (e.g., `"fire_source"`). |
| **TR-08** | 🔴 | If `requires_property` present, must be a string (e.g., `"has_striker"`). |
| **TR-09** | 🔴 | No duplicate (from + verb) pairs in transitions. Ambiguity = engine doesn't know which to fire. |
| **TR-10** | 🟡 | Auto-trigger transitions (`trigger = "auto"`) should have `condition` field. Auto with no condition is confusing. |
| **TR-11** | 🔴 | Transition `from` state must not be terminal. Terminal states have no outgoing transitions. |

---

## 7. Mutation Checks

| Rule | Severity | Description |
|------|----------|-------------|
| **MU-01** | 🔴 | If `mutate` present on transition, must be a table. |
| **MU-02** | 🟡 | Direct value mutations should match expected type of target field. `weight = "heavy"` is suspicious. |
| **MU-03** | 🔴 | Computed mutations (functions) must be callable. |
| **MU-04** | 🔴 | List ops (`add`, `remove`) must have string values. |
| **MU-05** | 🟡 | Mutation `becomes = "object-id"` should reference an existing object file. |
| **MU-06** | 🟡 | Mutation `spawns = {"obj1", "obj2"}` entries should reference existing object files. |
| **MU-07** | 🔴 | Top-level `mutations` table: each key should map to a table with valid mutation fields. |

---

## 8. Material Reference Checks

| Rule | Severity | Description |
|------|----------|-------------|
| **MAT-01** | 🔴 | `material` field MUST exist on all non-room objects (Principle 9). |
| **MAT-02** | 🔴 | `material` value must be in registry at `src/engine/materials/init.lua`. Valid: `wax, wood, fabric, wool, iron, steel, brass, glass, paper, leather, ceramic, tallow, cotton, oak, velvet, cardboard, linen, stone, silver, hemp, bone, burlap, plant`. |
| **MAT-03** | 🟡 | `material = "generic"` only for templates. Real objects should specify actual material. |
| **MAT-04** | 🟢 | Material-category consistency heuristic: `material = "glass"` + `categories = ["fragile"]` makes sense. But material choice is not enforced. |

---

## 9. Room Checks

### 9.1 Exit Checks

| Rule | Severity | Description |
|------|----------|-------------|
| **EX-01** | 🔴 | `exits` must be a table (if present). |
| **EX-02** | 🟡 | Each exit `target` should reference a valid room `id`. Unresolved targets like `"level-2"` → PENDING (future expansion). |
| **EX-03** | 🟡 | Exits should declare `type` (e.g., `"door"`, `"stairway"`, `"window"`, `"trap_door"`). |
| **EX-04** | 🟡 | Exits should have `name` for player-facing text. |
| **EX-05** | 🟡 | Exits should have `description`. |
| **EX-06** | 🟡 | Exits should have `keywords` for parser resolution. |
| **EX-07** | 🟡 | If `locked = true`, exit should have `key_id` or unlock mechanism. Locked with no unlock = player trap. |
| **EX-08** | 🟢 | If `max_carry_size`, `max_carry_weight`, `player_max_size` declared, should be positive numbers. |
| **EX-09** | 🟡 | For bidirectional exits: if room A → B, then B should have exit → A (unless `one_way = true`). |

### 9.2 Instance Checks

| Rule | Severity | Description |
|------|----------|-------------|
| **RI-01** | 🔴 | Every instance MUST have `id` (string). |
| **RI-02** | 🔴 | Every instance MUST have `type_id` referencing an object's GUID. |
| **RI-03** | 🟡 | `type_id` should match `guid` of an actual object in `src/meta/objects/`. Unresolved = missing objects. |
| **RI-04** | 🔴 | Instance `id` unique within room. No two instances with same `id`. |
| **RI-05** | 🔴 | Instance children may only use nesting keys: `on_top`, `contents`, `nested`, `underneath`. Others invalid. |

---

## 10. Nesting & Containment Checks

| Rule | Severity | Description |
|------|----------|-------------|
| **NC-01** | 🟡 | Nesting depth limit: practical max is 4 levels (room → nightstand → drawer → matchbox → match). Deeper than 5 = likely design error. |
| **NC-02** | 🟡 | `contents` children should only appear on objects with `container = true`. Non-containers with contents = suspicious. |
| **NC-03** | 🟢 | `nested` for slot relationships (drawer in nightstand), not generic containment. |
| **NC-04** | 🟡 | Objects with `on_top` children should have `surfaces.top` declared. |
| **NC-05** | 🟢 | Items in `underneath` typically hidden until parent moves. If parent immovable, items permanently inaccessible. |
| **NC-06** | 🟡 | If container has `capacity = N`, items in `contents` should not exceed N. |
| **NC-07** | 🟡 | If container has `max_item_size = M`, no contained item should have `size > M`. |
| **NC-08** | 🟡 | Nesting keys (`on_top`, `contents`, `nested`, `underneath`) are room-instance patterns. Object definitions should not use these as spatial keys. |

---

## 11. Cross-File Checks

**Require scanning multiple files:**

| Rule | Severity | Description |
|------|----------|-------------|
| **XF-01** | 🔴 | GUID global uniqueness: no duplicate GUIDs anywhere in `src/meta/`. Scan objects, rooms, levels, templates. |
| **XF-02** | 🟡 | `id` uniqueness within objects: two objects shouldn't share same `id` (unless intentional state variants). |
| **XF-03** | 🟢 | Keyword overlap audit: report keywords shared by multiple objects. Shared keywords aren't always wrong but cause parser ambiguity. |
| **XF-04** | 🟡 | Filename should match `id`. File `candle.lua` should have `id = "candle"`. Mismatches = confusing. |
| **XF-05** | 🔴 | All room instance `type_id` values must resolve to actual object GUIDs. Unresolved = engine load fails. |
| **XF-06** | 🟡 | Mutation `becomes` targets should reference existing objects. |
| **XF-07** | 🟡 | Mutation `spawns` targets should reference existing objects. |
| **XF-08** | 🟡 | Bidirectional exit completeness: if A → B, verify B → A (unless `one_way = true`). |
| **XF-09** | 🟡 | Level `rooms` table: all room IDs listed should correspond to actual room files. |
| **XF-10** | 🟢 | Orphan objects: objects not referenced by any room instance, mutation `becomes`/`spawns`, or composite `parts`. They exist but unreachable. |
| **XF-11** | 🟡 | `passage_id` uniqueness: if two rooms define exits with same `passage_id`, verify they're opposite sides of same passage. |

---

## 12. Level Definition Checks

**Apply to:** Files in `src/meta/levels/`

| Rule | Severity | Description |
|------|----------|-------------|
| **LV-01** | 🔴 | Level MUST have valid GUID. |
| **LV-02** | 🔴 | Level MUST declare `template = "level"`. |
| **LV-03** | 🔴 | Level MUST have `number` as positive integer. |
| **LV-04** | 🔴 | Level MUST have non-empty `name`. |
| **LV-05** | 🔴 | Level MUST have non-empty `rooms` table (at least one room). |
| **LV-06** | 🔴 | `start_room` must be one of the rooms listed in `rooms`. |
| **LV-07** | 🔴 | `start_room` must reference a valid room `id` in `src/meta/world/`. |
| **LV-08** | 🟡 | Levels should have `completion` criteria. |
| **LV-09** | 🟡 | Levels should have `intro` text for new players. |
| **LV-10** | 🟡 | Levels should declare `boundaries.entry` points. |

---

## 13. Composite Parts Checks

**Apply to:** Objects with `parts` table

| Rule | Severity | Description |
|------|----------|-------------|
| **CP-01** | 🔴 | Each part MUST have `id` (string). |
| **CP-02** | 🔴 | Each part MUST declare `detachable = true` or `detachable = false`. |
| **CP-03** | 🟡 | Detachable parts should have `factory` function that creates standalone object. |
| **CP-04** | 🟡 | Detachable parts should list `detach_verbs` (verbs that trigger detachment). |
| **CP-05** | 🟡 | Detachable parts should have `detach_message` (player-facing text). |
| **CP-06** | 🔴 | Part MUST have `on_feel`. Even non-detachable parts (like legs) need tactile description. |
| **CP-07** | 🟡 | Reversible parts (`reversible = true`) should have matching `reattach_part` transition in parent. |
| **CP-08** | 🟡 | Parts should have `keywords` for parser resolution. |
| **CP-09** | 🔴 | Objects returned by `factory()` MUST have `on_feel`. |

---

## 14. Effects Pipeline Checks

**Apply to:** Objects with `effects_pipeline = true` or effect tables

| Rule | Severity | Description |
|------|----------|-------------|
| **EF-01** | 🟢 | Objects using structured effect tables should declare `effects_pipeline = true`. |
| **EF-02** | 🔴 | Each effect MUST have `type` field (e.g., `"inflict_injury"`). |
| **EF-03** | 🔴 | Effects with `type = "inflict_injury"` MUST declare `injury_type`. |
| **EF-04** | 🔴 | Injury effects MUST declare `damage` as positive number. |
| **EF-05** | 🟡 | Effect `source` should match parent object's `id`. |
| **EF-06** | 🟡 | Dangerous effects (injury-causing) should have `prerequisites` with `warns` hints for GOAP planner. |

---

## 15. Lint Rules

**Style checks. Non-blocking.**

### 15.1 Naming Conventions

| Rule | Severity | Description |
|------|----------|-------------|
| **LN-01** | 🟢 | Filenames should be lowercase-with-dashes (no underscores, spaces, uppercase). |
| **LN-02** | 🟡 | `id` should match filename (without `.lua`). |
| **LN-03** | 🟢 | Keywords should be lowercase. |

### 15.2 Field Ordering

| Rule | Severity | Description |
|------|----------|-------------|
| **LN-04** | 🟢 | Recommended field order: `guid`, `template`, `id`, `material`, `name`, `keywords`, `description`, sensory fields, physical properties, FSM fields, `mutations`. |

### 15.3 Missing Recommended Fields

| Rule | Severity | Description |
|------|----------|-------------|
| **LN-05** | 🟢 | Most objects should have `on_smell`. |
| **LN-06** | 🟢 | Containers, liquids, mechanical objects should have `on_listen`. |
| **LN-07** | 🟢 | Visible objects should have `room_presence` text. |
| **LN-08** | 🟢 | FSM states that change appearance should have `room_presence`. |

### 15.4 Content Quality

| Rule | Severity | Description |
|------|----------|-------------|
| **LN-09** | 🟢 | Descriptions < 20 characters = placeholder. Flag for review. |
| **LN-10** | 🟡 | Identical descriptions across FSM states = FSM doesn't provide meaningful state feedback. |
| **LN-11** | 🟢 | Good `on_feel` describes what the player's hands discover, not visual appearance. |

---

## Top 10 Most Critical Rules

For developers: Focus on these first.

| # | Rule | Severity | Why |
|---|------|----------|-----|
| 1 | **SN-01** | 🔴 | Every object needs `on_feel` — the primary dark sense. Missing this breaks darkness gameplay. |
| 2 | **S-02** | 🔴 | Objects must have `guid` — required for room instantiation. |
| 3 | **S-04** | 🔴 | Objects must have `id` — required for parser. |
| 4 | **S-11** | 🔴 | Objects must have `description` — essential for gameplay. |
| 5 | **MAT-01** | 🔴 | Objects must have `material` — Principle 9 enforcement. |
| 6 | **G-02** | 🔴 | No duplicate GUIDs — breaks registry, causes collisions. |
| 7 | **FSM-04** | 🔴 | `initial_state` must reference valid state — prevents runtime crash. |
| 8 | **TR-01** | 🔴 | Transitions `from`/`to` must reference valid states — prevents state lookup failures. |
| 9 | **XF-05** | 🔴 | Room `type_id` must resolve to object GUID — engine load fails otherwise. |
| 10 | **CT-02** | 🔴 | Containers must have `capacity` — containment math depends on it. |

---

## Rule Organization by Developer Workflow

### When Creating a New Small-Item

Run checks: **S-01 to S-18, SI-01 to SI-04, SN-01 to SN-03, MAT-01, MAT-02, G-01, G-02, LN-01 to LN-04**

### When Creating a New Container

Run checks: **S-01 to S-18, CT-01 to CT-05, SN-01 to SN-03, MAT-01, MAT-02, G-01, G-02, NC-06, NC-07, LN-01 to LN-04**

### When Adding FSM to an Object

Run checks: **FSM-01 to FSM-12, TR-01 to TR-11, SN-08, SN-09**

### When Creating a New Room

Run checks: **S-01 to S-08, RM-01 to RM-06, EX-01 to EX-09, RI-01 to RI-05, G-01, G-02**

### Before Merging to Main

Run ALL checks. Exit code must be 0 (no errors).

---

## References

- **Acceptance Criteria (Full):** `docs/meta-check/acceptance-criteria.md` (Lisa's original specification, 144 rules detailed)
- **Architecture:** `docs/meta-check/architecture.md` (how meta-check validates)
- **Usage:** `docs/meta-check/usage.md` (how to run meta-check)
- **Schemas:** `docs/meta-check/schemas.md` (template field contracts)

