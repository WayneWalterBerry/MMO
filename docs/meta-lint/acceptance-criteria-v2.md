# meta-lint Acceptance Criteria — V2 (Full Meta Type Coverage)

**Author:** Lisa (Object Testing Specialist)
**Version:** 2.0
**Date:** 2026-03-24
**Builds On:** `acceptance-criteria.md` (V1 — 144 rules for objects + rooms)
**Purpose:** Extends meta-lint to validate the 4 remaining meta types: **Levels**, **Injuries**, **Templates** (as definitions, not as instance contracts), and **Materials**. Smithers codes from this spec.

**Severity Legend:**
- 🔴 **ERROR** — Invalid definition. Must fix before merge.
- 🟡 **WARNING** — Probably wrong. Author should review.
- 🟢 **INFO** — Style suggestion. Non-blocking.

---

## Table of Contents

1. [Template Definition Checks](#1-template-definition-checks)
2. [Injury Definition Checks](#2-injury-definition-checks)
3. [Material Definition Checks](#3-material-definition-checks)
4. [Level Definition Checks (Extended)](#4-level-definition-checks-extended)
5. [Cross-Reference Checks (New)](#5-cross-reference-checks-new)
6. [Edge Cases & Gotchas](#6-edge-cases--gotchas)
7. [Appendix A: Injury Category Values](#appendix-a-injury-category-values)
8. [Appendix B: Material Property Ranges](#appendix-b-material-property-ranges)
9. [Appendix C: Template Contracts](#appendix-c-template-contracts)
10. [Appendix D: Rule Count Summary](#appendix-d-rule-count-summary)

---

## 1. Template Definition Checks

These apply to `.lua` files in `src/meta/templates/`. Templates are the base contracts that instances inherit from. V1 checks what *instances* must have per template; V2 checks the *template definitions themselves*.

**Source files (5):** `container.lua`, `furniture.lua`, `room.lua`, `sheet.lua`, `small-item.lua`

### 1.1 Structural — All Templates

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| TD-01 | File returns a table | 🔴 ERROR | Template `.lua` file must `return { ... }`. |
| TD-02 | `guid` exists and valid | 🔴 ERROR | Template must have a valid GUID (8-4-4-4-12 hex). Templates use bare GUIDs (no braces) — consistent with current files. |
| TD-03 | `id` exists | 🔴 ERROR | Template must have a non-empty string `id`. |
| TD-04 | `id` matches filename | 🔴 ERROR | The `id` field must exactly match the filename without `.lua` extension. E.g., `container.lua` → `id = "container"`. |
| TD-05 | `name` exists | 🔴 ERROR | Template must have a non-empty string `name`. |
| TD-06 | `keywords` is a table | 🔴 ERROR | Must declare `keywords` as a table (empty is valid for templates — instances override). |
| TD-07 | `description` exists | 🔴 ERROR | Must have a `description` string. May be placeholder for templates. |
| TD-08 | `mutations` is a table | 🟡 WARNING | Templates should declare `mutations` (even if `{}`). This establishes the structural contract for instances. |
| TD-09 | No `template` field on templates | 🔴 ERROR | Templates must NOT declare a `template` field — they ARE templates. A template referencing another template is a structural error (no template inheritance chain exists). |
| TD-10 | GUID uniqueness across templates | 🔴 ERROR | No two template files may share the same `guid`. |

### 1.2 Physical Templates (container, furniture, small-item, sheet)

These 4 templates define the physical-object contract. The `room` template is different (see §1.3).

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| TD-11 | `size` is a positive number | 🔴 ERROR | Physical templates must declare `size > 0`. This is the default inherited by instances. |
| TD-12 | `weight` is a positive number | 🔴 ERROR | Physical templates must declare `weight > 0`. |
| TD-13 | `portable` is boolean | 🔴 ERROR | Must declare `portable` as `true` or `false`. |
| TD-14 | `material` is a string | 🔴 ERROR | Must declare `material`. Value `"generic"` is acceptable for templates (instances override). |
| TD-15 | `container` is boolean | 🔴 ERROR | Must explicitly declare `container = true` or `container = false`. |
| TD-16 | `capacity` is a non-negative number | 🔴 ERROR | Must declare `capacity`. `0` is valid for non-containers. |
| TD-17 | `contents` is a table | 🔴 ERROR | Must declare `contents` (should be `{}` — templates never have pre-loaded contents). |
| TD-18 | `contents` is empty | 🟡 WARNING | Template `contents` should be `{}`. A template with pre-populated contents is suspicious — instances should define contents. |
| TD-19 | `location` declared | 🟢 INFO | Physical templates should declare `location = nil` for structural clarity. |
| TD-20 | `categories` is a table of strings | 🟡 WARNING | If present, `categories` must be `{string, ...}`. Templates may define default categories. |

### 1.3 Container Template Specifics

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| TD-21 | `container` is `true` | 🔴 ERROR | The `container` template MUST have `container = true`. |
| TD-22 | `capacity` is positive | 🔴 ERROR | Container template must have `capacity > 0`. A container with zero capacity cannot hold anything. |
| TD-23 | `weight_capacity` is a positive number | 🟡 WARNING | Container template should declare `weight_capacity > 0`. If missing, instances must override. |

### 1.4 Room Template Specifics

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| TD-24 | No physical properties | 🔴 ERROR | Room template must NOT declare `size`, `weight`, `portable`, `material`, `capacity`, or `container`. Rooms are spatial containers, not physical objects. |
| TD-25 | `contents` is a table | 🔴 ERROR | Room template must declare `contents` (empty `{}`). |
| TD-26 | `exits` is a table | 🔴 ERROR | Room template must declare `exits` (empty `{}`). |

### 1.5 Sheet Template Specifics

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| TD-27 | `material` is fabric-class | 🟡 WARNING | Sheet template `material` should be a fabric-class material: `fabric`, `wool`, `cotton`, `linen`, `velvet`, `burlap`, `hemp`. Current value is `"fabric"`. |

---

## 2. Injury Definition Checks

These apply to `.lua` files in `src/meta/injuries/`. Injuries are FSM-driven definitions loaded by `src/engine/injuries.lua` via `injuries.load_definition(injury_type)`. The engine accesses fields by exact name — typos mean silent nil.

**Source files (7):** `bleeding.lua`, `bruised.lua`, `burn.lua`, `concussion.lua`, `crushing-wound.lua`, `minor-cut.lua`, `poisoned-nightshade.lua`

### 2.1 Identity & Structural

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| INJ-01 | File returns a table | 🔴 ERROR | Injury `.lua` file must `return { ... }`. |
| INJ-02 | `guid` exists and valid | 🔴 ERROR | Injury must have a valid GUID. Injuries use braced format `{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}`. |
| INJ-03 | `id` exists | 🔴 ERROR | Must have a non-empty string `id`. |
| INJ-04 | `id` matches filename | 🔴 ERROR | `id` must match the filename without `.lua`. E.g., `bleeding.lua` → `id = "bleeding"`. The engine loads via `require("meta.injuries." .. injury_type)` — the `injury_type` string IS the filename. If `id` doesn't match, healing lookups break. |
| INJ-05 | `name` exists | 🔴 ERROR | Must have a non-empty string `name` (display name, e.g., "Bleeding Wound"). |
| INJ-06 | `category` exists | 🔴 ERROR | Must have a non-empty string `category`. Valid values: `"physical"`, `"environmental"`, `"toxin"`, `"unconsciousness"`. |
| INJ-07 | `category` is a known value | 🟡 WARNING | `category` should be one of the established values. New categories aren't wrong but should be flagged for review. |
| INJ-08 | `description` exists | 🔴 ERROR | Must have a non-empty string `description`. |
| INJ-09 | GUID uniqueness across injuries | 🔴 ERROR | No two injury files may share the same `guid`. |
| INJ-10 | No `template` field | 🟢 INFO | Injuries do not use the template system. If a `template` field is present, it's likely a copy-paste error from an object file. |

### 2.2 Damage Model

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| INJ-11 | `damage_type` exists | 🔴 ERROR | Must declare `damage_type` as a string. Valid values: `"over_time"`, `"one_time"`. |
| INJ-12 | `damage_type` is a known value | 🔴 ERROR | Must be one of: `"over_time"`, `"one_time"`. The engine branches on this (`"degenerative"` also referenced in engine code as future type). |
| INJ-13 | `initial_state` exists | 🔴 ERROR | Must declare `initial_state` as a string. |
| INJ-14 | `initial_state` references a defined state | 🔴 ERROR | `initial_state` must be a key in the `states` table. |
| INJ-15 | `on_inflict` exists | 🔴 ERROR | Must declare `on_inflict` as a table. The engine reads `on_inflict.initial_damage`, `on_inflict.damage_per_tick`, and `on_inflict.message`. |
| INJ-16 | `on_inflict.initial_damage` is a non-negative number | 🔴 ERROR | Must be present. `0` is valid (injuries that don't deal immediate damage). |
| INJ-17 | `on_inflict.damage_per_tick` is a non-negative number | 🔴 ERROR | Must be present. `0` is valid for one-time injuries. Must be `> 0` for `damage_type = "over_time"`. |
| INJ-18 | `on_inflict.message` is a non-empty string | 🔴 ERROR | The engine prints this message when the injury is inflicted. Missing means silent injury — confusing to the player. |
| INJ-19 | `damage_type` / `on_inflict.damage_per_tick` consistency | 🟡 WARNING | If `damage_type = "over_time"`, then `on_inflict.damage_per_tick` should be `> 0`. If `damage_type = "one_time"`, then `on_inflict.damage_per_tick` should be `0`. Mismatches indicate a classification error. |

### 2.3 FSM States

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| INJ-20 | `states` exists and is a table | 🔴 ERROR | Must declare `states` as a table keyed by state name strings. |
| INJ-21 | At least 2 states defined | 🔴 ERROR | Injuries must have at least `initial_state` + one terminal state (usually `"healed"` and/or `"fatal"`). |
| INJ-22 | Every state has `name` | 🔴 ERROR | Each state definition must have a `name` string. The engine reads `state_def.name` for injury listing output. |
| INJ-23 | Every state has `description` | 🔴 ERROR | Each state definition must have a `description` string. The engine reads `state_def.description` for injury listing. |
| INJ-24 | Non-terminal states have `on_feel` | 🔴 ERROR | Non-terminal states represent active injuries the player can perceive. `on_feel` is the primary sense — required for consistency with object sensory rules. |
| INJ-25 | Non-terminal states have `damage_per_tick` | 🔴 ERROR | Non-terminal states must declare `damage_per_tick` as a number (≥ 0). The engine reads this directly: `state_def.damage_per_tick`. |
| INJ-26 | Terminal states have `terminal = true` | 🔴 ERROR | States that end the injury lifecycle (`"healed"`, `"fatal"`) must declare `terminal = true`. The engine checks `state_def.terminal` to remove resolved injuries. |
| INJ-27 | At least one terminal state exists | 🔴 ERROR | Every injury must have at least one terminal state. Without one, the injury can never resolve — the player is permanently injured. |
| INJ-28 | A `healed` or equivalent positive terminal exists | 🟡 WARNING | Most injuries should have a `"healed"` state. If all terminals are `"fatal"`, the injury is always lethal — which should be intentional and flagged. |
| INJ-29 | Terminal states have no `damage_per_tick > 0` | 🟡 WARNING | Terminal states should not deal damage — the injury is resolved. `damage_per_tick > 0` on a terminal state is illogical. |
| INJ-30 | Terminal states have no `timed_events` | 🟡 WARNING | Terminal states should not have timed transitions — there's nowhere to go. |
| INJ-31 | Terminal states have no `restricts` | 🟡 WARNING | Terminal states (especially `"healed"`) should not restrict player actions. A healed injury that still blocks climbing is a bug. |
| INJ-32 | `on_look` recommended for non-terminal states | 🟢 INFO | Most visible injuries should have `on_look` for lit environments. |
| INJ-33 | `on_smell` for bleeding/infected states | 🟢 INFO | States involving blood or infection should have `on_smell` for immersion. |

### 2.4 Timed Events

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| INJ-34 | `timed_events` is an array of tables | 🔴 ERROR | If present, must be `{ {table}, {table}, ... }`. |
| INJ-35 | Each timed event has `event` field | 🔴 ERROR | Must declare `event` (string). Known value: `"transition"`. |
| INJ-36 | Each timed event has `delay` field | 🔴 ERROR | Must declare `delay` as a positive number (seconds). Represents real-time delay before event fires. |
| INJ-37 | Each timed event has `to_state` field | 🔴 ERROR | For `event = "transition"`, must declare `to_state` as a string referencing a defined state. |
| INJ-38 | `to_state` references a defined state | 🔴 ERROR | The `to_state` value must be a key in the `states` table. |
| INJ-39 | `delay` is reasonable | 🟡 WARNING | Delay values should be within 360–10800 seconds (1–30 turns at 360s/turn). Values outside this range should be flagged: too short means instant cascade, too long means the timer is effectively irrelevant. |
| INJ-40 | No conflicting timed events | 🟡 WARNING | A single state should have at most one `timed_event` with `event = "transition"`. Two competing timers to different states from the same state is ambiguous. **Exception:** Burn's `active` state has two potential auto-paths (healed vs blistered) — resolved by source-specific timer overrides. Flag for review. |

### 2.5 Restricts

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| INJ-41 | `restricts` is a table | 🔴 ERROR | If present, `restricts` must be a table mapping action strings to `true`. |
| INJ-42 | `restricts` values are boolean `true` | 🔴 ERROR | Each value in `restricts` must be `true`. Other values (numbers, strings) are type errors. |
| INJ-43 | `restricts` keys are known actions | 🟡 WARNING | Keys should be recognized player actions: `"climb"`, `"run"`, `"jump"`, `"fight"`, `"grip"`, `"focus"`. Unknown actions won't be checked by the engine. |

### 2.6 Transitions

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| INJ-44 | `transitions` is an array of tables | 🔴 ERROR | Must be `{ {table}, {table}, ... }`. |
| INJ-45 | Each transition has `from` | 🔴 ERROR | `from` must be a string referencing a defined state. |
| INJ-46 | Each transition has `to` | 🔴 ERROR | `to` must be a string referencing a defined state. |
| INJ-47 | `from` references a defined state | 🔴 ERROR | Must be a key in `states`. |
| INJ-48 | `to` references a defined state | 🔴 ERROR | Must be a key in `states`. |
| INJ-49 | Verb-triggered transitions have `verb` | 🔴 ERROR | Non-auto transitions must declare `verb` as a non-empty string (e.g., `"use"`, `"drink"`, `"rest"`, `"sleep"`). |
| INJ-50 | Auto-triggered transitions have `trigger = "auto"` | 🔴 ERROR | Timer-driven transitions must declare `trigger = "auto"`. |
| INJ-51 | Auto-triggered transitions have `condition` | 🟡 WARNING | Auto transitions should declare `condition` (e.g., `"timer_expired"`). An auto-trigger with no condition is ambiguous. |
| INJ-52 | `message` exists on every transition | 🔴 ERROR | Every transition must have a `message` string. Injury state changes without narrative feedback are confusing. |
| INJ-53 | `from` is not a terminal state | 🔴 ERROR | Transitions from terminal states are unreachable. |
| INJ-54 | No duplicate `from` + `verb` pairs | 🟡 WARNING | Two verb-triggered transitions with the same `from` state and `verb` create ambiguity (same rule as object FSM TR-09). Exception: different `requires_item_cures` values disambiguate. |
| INJ-55 | `requires_item_cures` is a string | 🔴 ERROR | If present, must be a non-empty string identifying the injury type the healing item cures. |
| INJ-56 | `mutate` is a table | 🔴 ERROR | If present, `mutate` must be a table of property changes. Injury transitions commonly mutate `damage_per_tick` and `_timer_delay`. |
| INJ-57 | `mutate.damage_per_tick` is a non-negative number | 🟡 WARNING | If mutate changes `damage_per_tick`, the new value should be ≥ 0. Negative damage-per-tick doesn't make sense. |

### 2.7 Healing Interactions

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| INJ-58 | `healing_interactions` exists | 🔴 ERROR | Must be present (even if `{}`). The engine reads this directly: `def.healing_interactions`. Missing field means `nil`, which causes a different code path than empty table. |
| INJ-59 | `healing_interactions` is a table | 🔴 ERROR | Must be a table keyed by healing item ID strings. |
| INJ-60 | Each interaction has `transitions_to` | 🔴 ERROR | Must be a string referencing a defined state. This is the state the injury transitions to when the healing item is used. |
| INJ-61 | `transitions_to` references a defined state | 🔴 ERROR | Must be a key in the `states` table. |
| INJ-62 | Each interaction has `from_states` | 🔴 ERROR | Must be a table of strings. These are the states from which the healing item is effective. |
| INJ-63 | `from_states` entries reference defined states | 🔴 ERROR | Every entry in `from_states` must be a key in the `states` table. |
| INJ-64 | `from_states` entries are non-terminal | 🟡 WARNING | Healing items should only work from non-terminal states. A healing item that works from `"healed"` or `"fatal"` is illogical. |
| INJ-65 | Healing item IDs should reference existing objects | 🟡 WARNING | The keys in `healing_interactions` (e.g., `"bandage"`, `"healing-poultice"`, `"antidote-nightshade"`) should correspond to object `id` values in `src/meta/objects/`. Unresolvable item IDs mean the healing path is broken. |

### 2.8 Special Injury Fields

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| INJ-66 | `causes_unconsciousness` is boolean | 🔴 ERROR | If present, must be `true` or `false`. Currently only used by `concussion`. |
| INJ-67 | `unconscious_duration` has valid structure | 🔴 ERROR | If present, must be a table mapping severity strings to positive numbers (turn counts). Known severities: `"minor"`, `"moderate"`, `"severe"`, `"critical"`. |
| INJ-68 | `unconscious_duration` requires `causes_unconsciousness` | 🔴 ERROR | If `unconscious_duration` is defined, `causes_unconsciousness` must be `true`. |
| INJ-69 | No unknown top-level fields | 🟢 INFO | Flag any top-level field not in the known set: `guid`, `id`, `name`, `category`, `description`, `damage_type`, `initial_state`, `on_inflict`, `states`, `transitions`, `healing_interactions`, `causes_unconsciousness`, `unconscious_duration`. |

---

## 3. Material Definition Checks

These apply to `.lua` files in `src/meta/materials/`. Materials are property tables loaded by `src/engine/materials/init.lua` via `dofile()`. The engine strips the `name` field and indexes by it — every other field becomes the property bag.

**Source files (23):** `bone.lua`, `brass.lua`, `burlap.lua`, `cardboard.lua`, `ceramic.lua`, `cotton.lua`, `fabric.lua`, `glass.lua`, `hemp.lua`, `iron.lua`, `leather.lua`, `linen.lua`, `oak.lua`, `paper.lua`, `plant.lua`, `silver.lua`, `steel.lua`, `stone.lua`, `tallow.lua`, `velvet.lua`, `wax.lua`, `wood.lua`, `wool.lua`

### 3.1 Structural

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| MD-01 | File returns a table | 🔴 ERROR | Material `.lua` file must `return { ... }`. |
| MD-02 | `name` exists | 🔴 ERROR | Must have a non-empty string `name`. The engine uses this as the registry key. |
| MD-03 | `name` matches filename | 🔴 ERROR | `name` must exactly match the filename without `.lua`. E.g., `glass.lua` → `name = "glass"`. The engine indexes by `name`, and objects reference by filename convention. |
| MD-04 | No `guid` field | 🟢 INFO | Materials don't use GUIDs — they're keyed by name. If a `guid` is present, it's likely a copy-paste error. |
| MD-05 | No `id` field | 🟢 INFO | Materials use `name` as their identifier, not `id`. Presence of `id` suggests confusion with objects. |

### 3.2 Required Physical Properties

These 11 properties form the core material contract. The engine and objects query them via `materials.get_property(name, property)`.

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| MD-06 | `density` exists and is a positive number | 🔴 ERROR | Material density in kg/m³. All 23 existing materials define this. Range: 300 (fabric) to 10490 (silver). Must be > 0. |
| MD-07 | `hardness` exists and is a number 0–10 | 🔴 ERROR | Mohs-scale-inspired hardness. Range: 1 (fabrics, paper) to 9 (steel). Must be in [0, 10]. |
| MD-08 | `flexibility` exists and is a number 0.0–1.0 | 🔴 ERROR | How much the material bends. 0.0 = rigid (glass, stone), 1.0 = fully flexible (fabric, cotton). |
| MD-09 | `absorbency` exists and is a number 0.0–1.0 | 🔴 ERROR | How much liquid the material absorbs. 0.0 = none (metals, glass), 0.9 = highly absorbent (cotton, paper). |
| MD-10 | `opacity` exists and is a number 0.0–1.0 | 🔴 ERROR | Light transmission. 0.0 = transparent, 1.0 = fully opaque. Note: glass is 0.1 (translucent), not 0.0. |
| MD-11 | `flammability` exists and is a number 0.0–1.0 | 🔴 ERROR | How easily the material catches fire. 0.0 = non-flammable (metals, glass, stone, ceramic), up to 0.8 (tallow, paper, cardboard). |
| MD-12 | `conductivity` exists and is a number 0.0–1.0 | 🔴 ERROR | Thermal/electrical conductivity. 0.0 = insulator (most organics), 0.95 = highly conductive (silver). |
| MD-13 | `fragility` exists and is a number 0.0–1.0 | 🔴 ERROR | How easily the material shatters/breaks. 0.0 = unbreakable (fabric, leather), 0.9 = very fragile (glass). |
| MD-14 | `value` exists and is a positive number | 🔴 ERROR | Relative economic value. Integer. Range: 1 (wax, tallow, paper, bone, burlap, plant, cardboard) to 40 (silver). |
| MD-15 | `melting_point` is a positive number or nil | 🔴 ERROR | Temperature in °C where the material melts. `nil` is valid for organic/fibrous materials that burn before melting (wood, fabric, wool, cotton, paper, leather, velvet, linen, hemp, plant, burlap, bone, cardboard). |
| MD-16 | `ignition_point` is a positive number or nil | 🔴 ERROR | Temperature in °C where the material catches fire. `nil` is valid for non-combustible materials (glass, iron, steel, brass, ceramic, silver, stone). |

### 3.3 Physical Property Consistency

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| MD-17 | `flammability` > 0 requires `ignition_point` | 🟡 WARNING | If a material has `flammability > 0`, it should also have a defined `ignition_point`. A material that burns but has no ignition temperature is inconsistent. |
| MD-18 | `flammability` = 0 implies `ignition_point` = nil | 🟡 WARNING | Non-flammable materials should not have an ignition point. |
| MD-19 | `melting_point` and `ignition_point` exclusivity | 🟢 INFO | Most materials have one or the other. Materials with BOTH (e.g., wax: melts at 60°C, ignites at 230°C) are valid but unusual — flag for review. |
| MD-20 | `flexibility` + `fragility` sanity | 🟡 WARNING | Highly flexible materials (flexibility ≥ 0.7) should have low fragility (fragility ≤ 0.1). A material that bends easily shouldn't shatter easily. Current data: all flexible materials (fabric, cotton, wool, velvet, linen, hemp, burlap, plant) have fragility ≤ 0.3. |
| MD-21 | `conductivity` > 0 implies metallic/mineral | 🟢 INFO | Only metals and minerals should have `conductivity > 0`. Organic materials (fabric, wood, leather) should be `0.0`. Current exception: stone at 0.1 — valid. |

### 3.4 Optional Properties

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| MD-22 | `rust_susceptibility` is a number 0.0–1.0 | 🔴 ERROR | If present, must be a valid range. Currently only on `iron` (0.9) and `steel` (0.4). |
| MD-23 | `rust_susceptibility` only on ferrous materials | 🟡 WARNING | Only iron-based materials should have `rust_susceptibility`. A material like `"glass"` with `rust_susceptibility` is a data error. |
| MD-24 | No unknown fields | 🟢 INFO | Flag any field not in the known set: `name`, `density`, `melting_point`, `ignition_point`, `hardness`, `flexibility`, `absorbency`, `opacity`, `flammability`, `conductivity`, `fragility`, `value`, `rust_susceptibility`. New properties aren't wrong but should be documented. |

---

## 4. Level Definition Checks (Extended)

V1 covers LV-01 through LV-10 (basic structure). V2 adds deep validation of sub-structures: `intro`, `completion`, `boundaries`, and `restricted_objects`.

**Source files (1):** `level-01.lua` (more expected as game grows)

### 4.1 Intro Structure

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| LV-11 | `intro` is a table | 🔴 ERROR | If present (and it should be — LV-09), `intro` must be a table. |
| LV-12 | `intro.title` is a non-empty string | 🔴 ERROR | Displayed at game start. Missing title means blank header. |
| LV-13 | `intro.narrative` is a table of strings | 🔴 ERROR | Must be `{string, string, ...}`. The engine prints each entry as a separate line. Non-string entries cause runtime errors. |
| LV-14 | `intro.narrative` is non-empty | 🟡 WARNING | A level with no narrative text starts silently — almost certainly unintentional. |
| LV-15 | `intro.help` is a non-empty string | 🟡 WARNING | Should provide initial help text. Missing means the player has no guidance. |
| LV-16 | `intro.subtitle` is a string | 🟢 INFO | Optional subtitle. If present, must be a string. |

### 4.2 Completion Criteria

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| LV-17 | `completion` is a table of tables | 🔴 ERROR | Must be `{ {table}, {table}, ... }`. Each entry is one completion condition. |
| LV-18 | Each completion entry has `type` | 🔴 ERROR | Must be a non-empty string. Known type: `"reach_room"`. |
| LV-19 | `type = "reach_room"` requires `room` | 🔴 ERROR | Must declare `room` as a string — the target room that triggers completion. |
| LV-20 | `completion[].room` is in `rooms` list | 🔴 ERROR | The completion target room must be a member of the level's `rooms` array. Completing by reaching a room outside the level is a logic error. |
| LV-21 | `completion[].message` is a non-empty string | 🟡 WARNING | Completion events should have a narrative message. Missing means the level ends silently. |
| LV-22 | `completion[].from` references a valid room | 🟡 WARNING | If present, `from` should be in the level's `rooms` array. It identifies the specific approach that triggers this completion variant. |

### 4.3 Boundaries

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| LV-23 | `boundaries` is a table | 🟡 WARNING | Levels should declare boundaries. Missing boundaries means no defined entry/exit points. |
| LV-24 | `boundaries.entry` is a non-empty table of strings | 🔴 ERROR | Must list at least one entry point. Each entry must be a room ID string. |
| LV-25 | `boundaries.entry` rooms are in `rooms` list | 🔴 ERROR | Every entry point must be a room that belongs to this level. |
| LV-26 | `boundaries.entry` includes `start_room` | 🟡 WARNING | The level's `start_room` should appear in `boundaries.entry`. A start room that isn't an entry point is contradictory. |
| LV-27 | `boundaries.exit` is a table of tables | 🟡 WARNING | Should list exit points (may be empty for the final level). |
| LV-28 | Each exit has `room` | 🔴 ERROR | Exit must declare which room contains the exit. |
| LV-29 | Each exit has `exit_direction` | 🔴 ERROR | Exit must declare direction string (e.g., `"north"`, `"south"`). |
| LV-30 | Each exit has `target_level` | 🔴 ERROR | Exit must declare which level number the exit leads to. Must be a positive integer. |
| LV-31 | Exit `room` is in `rooms` list | 🔴 ERROR | The exit room must belong to this level. |
| LV-32 | Exit `exit_direction` exists on the room | 🟡 WARNING | The declared direction should correspond to an actual exit in that room's `exits` table. Mismatch means the boundary points to a non-existent doorway. |
| LV-33 | Exit `target_level` > current `number` | 🟡 WARNING | Exit levels should progress forward. An exit to a lower-numbered level is unusual (backtracking). |

### 4.4 Restricted Objects

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| LV-34 | `restricted_objects` is a table of strings | 🔴 ERROR | If present, must be `{string, string, ...}`. Each entry is an object ID. |
| LV-35 | Restricted object IDs reference existing objects | 🟡 WARNING | Each ID should correspond to an object in `src/meta/objects/`. |

### 4.5 Description & Rooms Detail

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| LV-36 | `description` is a non-empty string | 🔴 ERROR | Levels must have a description documenting the level's narrative arc. |
| LV-37 | `rooms` entries are unique | 🔴 ERROR | No duplicate room IDs in the `rooms` array. |
| LV-38 | `rooms` entries reference valid rooms | 🔴 ERROR | Every room ID must match a room file in `src/meta/world/`. (Strengthens V1's XF-09 from WARNING to ERROR for level membership.) |
| LV-39 | `start_room` is in `rooms` list | 🔴 ERROR | The start room must be a member of this level. (Restates LV-06 for completeness in extended section.) |
| LV-40 | `number` uniqueness across levels | 🔴 ERROR | No two level files may share the same `number`. Level numbers define progression order. |
| LV-41 | `guid` uniqueness across levels | 🔴 ERROR | No two level files may share the same `guid`. |

---

## 5. Cross-Reference Checks (New)

These checks validate references BETWEEN the new meta types and the rest of the system.

### 5.1 Injury ↔ Object Cross-References

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| XR-01 | Healing item IDs in `healing_interactions` resolve to objects | 🟡 WARNING | Every key in every injury's `healing_interactions` (e.g., `"bandage"`, `"healing-poultice"`, `"cold-water"`, `"damp-cloth"`, `"salve"`, `"antidote-nightshade"`) should match an object `id` in `src/meta/objects/`. Unresolvable means the healing path is dead. |
| XR-02 | Objects with `cures` reference valid injury IDs | 🟡 WARNING | If an object declares `on_use.cures = "bleeding"`, the injury type `"bleeding"` must exist in `src/meta/injuries/`. |
| XR-03 | `requires_item_cures` on transitions references valid injury IDs | 🟡 WARNING | The `requires_item_cures` value on injury transitions (e.g., `"bleeding"`, `"burn"`, `"crushing-wound"`, `"minor-cut"`, `"poisoned-nightshade"`) must match the `id` of an injury definition. Usually it's the same injury's own `id`. |

### 5.2 Material ↔ Object Cross-References

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| XR-04 | Object `material` values reference material files | 🔴 ERROR | Every object's `material` field must correspond to a `.lua` file in `src/meta/materials/`. Supersedes V1 MAT-02 (which referenced the old hardcoded registry). |
| XR-05 | Template `material = "generic"` not in materials | 🟢 INFO | Templates use `"generic"` as a placeholder. There is no `generic.lua` in materials — this is intentional. Objects inheriting `"generic"` must override it. |

### 5.3 Template ↔ Object Cross-References

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| XR-06 | Every `template` value on objects resolves to a template file | 🔴 ERROR | Object `template` field must match a template `id` in `src/meta/templates/`. (Reinforces V1 S-08.) |
| XR-07 | Template default values are valid | 🟡 WARNING | If a template declares default property values (e.g., `size = 2`), those values should satisfy the same type checks as objects. A template with `size = "big"` would poison every instance. |

### 5.4 Level ↔ Room ↔ Object Cross-References

| # | Check | Severity | Description |
|---|-------|----------|-------------|
| XR-08 | Level `completion[].room` exists as a room file | 🔴 ERROR | Completion target rooms must exist in `src/meta/world/`. |
| XR-09 | Level `boundaries.exit[].room` has matching exit direction | 🟡 WARNING | The boundary exit direction must correspond to an actual exit key on the room. |
| XR-10 | Every room file belongs to at least one level | 🟡 WARNING | Rooms in `src/meta/world/` not listed in any level's `rooms` array are orphaned — exist but unreachable in normal play. |
| XR-11 | GUID global uniqueness across ALL meta types | 🔴 ERROR | No two files in the entire `src/meta/` tree (objects, rooms, levels, templates, injuries) may share the same GUID. Extends V1 XF-01 to include all meta types. |

---

## 6. Edge Cases & Gotchas

### 6.1 Injury Gotchas

1. **Burn has conflicting auto-transitions from `active`.** The `active` state has a timed event to `"healed"` (self-heal for minor burns) AND a transition `active → blistered` with `trigger = "auto"`. The resolution is that severe burn sources override the timer at infliction time. Meta-Lint should flag multiple auto-transitions from the same state as 🟡 WARNING, not 🔴 ERROR — Burn is the known exception (see INJ-40).

2. **`healing_interactions` keys are object IDs, not injury types.** A common confusion: the keys are the *healing item's* `id` (e.g., `"bandage"`), not the injury type. The `requires_item_cures` field on transitions contains the injury type. Don't cross-validate them against each other — they reference different namespaces.

3. **`_timer_delay` in mutate.** Some transitions mutate `_timer_delay` (e.g., crushing-wound worsened→treated sets `_timer_delay = 7200`). This overrides the target state's timed event delay. Meta-Lint should allow `_timer_delay` as a known mutate key without flagging it as suspicious.

4. **Empty `healing_interactions = {}` is valid.** Bruised and Concussion have no item-based healing — they self-heal with time/rest. An empty table is correct, not missing.

5. **Injury `id` must match filename exactly.** The engine loads via `require("meta.injuries." .. injury_type)` where `injury_type` is a string like `"bleeding"`. If the file is `bleeding.lua` but `id = "bleed"`, the `healing_interactions` lookup will fail because the engine resolves by filename, but healing interactions reference by `id`.

### 6.2 Material Gotchas

1. **Engine strips `name` from the loaded table.** After `dofile()`, the engine sets `mat.name = nil` and stores the rest under `materials.registry[name]`. So `materials.get("glass").name` returns `nil` at runtime. Meta-Lint validates the raw file, not the runtime table — `name` IS present in the file and must match the filename.

2. **`"generic"` is not a material file.** Templates use `material = "generic"` but no `generic.lua` exists. This is intentional — objects must override. Meta-Lint should NOT flag `"generic"` as a missing material when scanning template files, but SHOULD flag it on object files.

3. **Optional properties are material-specific.** `rust_susceptibility` only appears on iron and steel. Future materials may add properties like `toxicity` (for poisons) or `transparency` (distinct from opacity). Meta-Lint should flag unknown properties as 🟢 INFO, not ERROR.

4. **`nil` values are meaningful.** `melting_point = nil` means "does not melt" (burns or decomposes instead). `ignition_point = nil` means "does not ignite." These are not missing values — they encode physical truth. Meta-Lint must NOT flag `nil` as missing for these two fields.

### 6.3 Template Gotchas

1. **Templates have no `template` field.** Objects declare `template = "container"` to inherit from the container template. But templates themselves must NOT have a `template` field — there's no meta-template chain.

2. **Template GUIDs are bare (no braces).** All 5 template files use GUIDs without `{...}` braces: `guid = "f1596a51-4e1f-4f9a-a6d0-93b279066910"`. Objects use braced GUIDs. This inconsistency is established convention — don't ERROR on it, but note it.

3. **Room template is minimal.** The room template has no physical properties (`size`, `weight`, `portable`, `material`). This is correct — rooms are spatial containers. But meta-lint should verify that any new template follows the same pattern: room-type templates must NOT have physical properties.

4. **Sheet template has default mutations.** The sheet template declares `mutations = { tear = { becomes = nil, spawns = {"cloth"} } }`. This is the only template with non-empty mutations. Instances that don't want this mutation must explicitly override it.

### 6.4 Level Gotchas

1. **Level GUIDs are bare (no braces).** Like templates, levels use bare GUIDs: `guid = "c4a71e20-8f3d-4b61-a9c5-2d7e1f03b8a6"`. Consistent with the non-object convention.

2. **`restricted_objects` can be empty.** Level 1 has an empty `restricted_objects` array. This is valid — no objects are restricted for this level.

3. **`completion` conditions are OR'd.** Multiple completion entries mean "any one of these triggers completion." Meta-Lint should not require a single entry.

4. **`rooms` ordering is narrative, not mechanical.** The rooms array is ordered by story arc (Act I, II, III, IV) but the engine doesn't depend on order. Duplicate detection should still check for repeated entries.

---

## Appendix A: Injury Category Values

| Category | Description | Injuries |
|----------|-------------|----------|
| `physical` | Wounds from physical force | bleeding, bruised, crushing-wound, minor-cut |
| `environmental` | Damage from environmental hazards | burn |
| `toxin` | Poison/chemical damage | poisoned-nightshade |
| `unconsciousness` | Loss of consciousness | concussion |

## Appendix B: Material Property Ranges

Observed ranges across all 23 materials:

| Property | Type | Min | Max | Nullable | Notes |
|----------|------|-----|-----|----------|-------|
| `density` | number | 300 (fabric) | 10490 (silver) | No | kg/m³ |
| `melting_point` | number/nil | 45 (tallow) | 1600 (ceramic) | Yes | °C. `nil` for organics that burn. |
| `ignition_point` | number/nil | 200 (tallow) | 600 (bone) | Yes | °C. `nil` for non-combustibles. |
| `hardness` | number | 1 (fabrics) | 9 (steel) | No | 0–10 scale |
| `flexibility` | number | 0.0 (glass/stone/ceramic) | 1.0 (fabric/cotton) | No | 0.0–1.0 |
| `absorbency` | number | 0.0 (metals/glass) | 0.9 (cotton/paper) | No | 0.0–1.0 |
| `opacity` | number | 0.1 (glass) | 1.0 (most solids) | No | 0.0–1.0 |
| `flammability` | number | 0.0 (metals/glass/stone/ceramic) | 0.8 (tallow/paper/cardboard) | No | 0.0–1.0 |
| `conductivity` | number | 0.0 (most organics) | 0.95 (silver) | No | 0.0–1.0 |
| `fragility` | number | 0.0 (fabrics/leather) | 0.9 (glass) | No | 0.0–1.0 |
| `value` | number | 1 (common materials) | 40 (silver) | No | Relative economic value |
| `rust_susceptibility` | number | 0.4 (steel) | 0.9 (iron) | Optional | 0.0–1.0. Only ferrous metals. |

## Appendix C: Template Contracts

What each template provides as defaults, and what instances MUST override:

### container
| Field | Default | Instance Override? |
|-------|---------|-------------------|
| `guid` | template GUID | Instance gets own GUID via `type_id` |
| `id` | `"container"` | MUST override |
| `name` | `"a container"` | MUST override |
| `keywords` | `{}` | MUST override |
| `description` | `"A basic container."` | MUST override |
| `size` | `2` | Usually override |
| `weight` | `0.5` | Usually override |
| `portable` | `true` | May override |
| `material` | `"generic"` | MUST override (MAT-03) |
| `container` | `true` | Inherited |
| `capacity` | `4` | Usually override |
| `weight_capacity` | `10` | Usually override |
| `categories` | `{"container"}` | Usually extend |

### furniture
| Field | Default | Instance Override? |
|-------|---------|-------------------|
| `size` | `5` | Usually override |
| `weight` | `30` | Usually override |
| `portable` | `false` | Rarely override |
| `material` | `"wood"` | May override |
| `container` | `false` | May override |
| `categories` | `{"furniture", "wooden"}` | Usually extend |

### small-item
| Field | Default | Instance Override? |
|-------|---------|-------------------|
| `size` | `1` | Usually override |
| `weight` | `0.1` | Usually override |
| `portable` | `true` | Rarely override |
| `material` | `"generic"` | MUST override |
| `container` | `false` | Rarely override |
| `categories` | `{}` | Usually override |

### sheet
| Field | Default | Instance Override? |
|-------|---------|-------------------|
| `size` | `1` | Usually override |
| `weight` | `0.2` | Usually override |
| `portable` | `true` | Rarely override |
| `material` | `"fabric"` | May override |
| `categories` | `{"fabric"}` | May extend |
| `mutations.tear` | `{becomes=nil, spawns={"cloth"}}` | May override |

### room
| Field | Default | Instance Override? |
|-------|---------|-------------------|
| `name` | `"A room"` | MUST override |
| `description` | `""` | MUST override |
| `contents` | `{}` | Rebuilt from `instances` |
| `exits` | `{}` | MUST override |

---

## Appendix D: Rule Count Summary

### V2 New Rules

| Category | 🔴 ERROR | 🟡 WARNING | 🟢 INFO | Total |
|----------|----------|------------|---------|-------|
| Template definitions (TD) | 18 | 5 | 4 | 27 |
| Injury identity/structural (INJ 01–10) | 8 | 1 | 1 | 10 |
| Injury damage model (INJ 11–19) | 7 | 2 | 0 | 9 |
| Injury FSM states (INJ 20–33) | 7 | 5 | 2 | 14 |
| Injury timed events (INJ 34–40) | 5 | 2 | 0 | 7 |
| Injury restricts (INJ 41–43) | 2 | 1 | 0 | 3 |
| Injury transitions (INJ 44–57) | 9 | 3 | 0 | 12 (+2 combined) |
| Injury healing interactions (INJ 58–65) | 6 | 2 | 0 | 8 |
| Injury special fields (INJ 66–69) | 3 | 0 | 1 | 4 |
| Material structural (MD 01–05) | 3 | 0 | 2 | 5 |
| Material required properties (MD 06–16) | 11 | 0 | 0 | 11 |
| Material consistency (MD 17–21) | 0 | 3 | 2 | 5 |
| Material optional (MD 22–24) | 1 | 1 | 1 | 3 |
| Level extended (LV 11–41) | 20 | 7 | 4 | 31 |
| Cross-references (XR 01–11) | 4 | 6 | 1 | 11 |
| **V2 Subtotal** | **~104** | **~38** | **~18** | **~160** |

### Combined V1 + V2

| Scope | Rules |
|-------|-------|
| V1 (objects + rooms) | ~144 |
| V2 (templates + injuries + materials + levels ext. + cross-refs) | ~160 |
| **Grand Total** | **~304** |

---

*V2 completes the meta-lint coverage. Every `.lua` file under `src/meta/` is now covered by at least one validation section. If meta-lint doesn't check it, nobody will.*
