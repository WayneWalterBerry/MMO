# Existing Validation Audit: What the Engine Loader Checks

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Source:** `src/engine/loader/init.lua` (226 lines)  
**Purpose:** Identify what validation exists at load time, and what gaps meta-lint must fill.

---

## Executive Summary

The loader is a **sandboxed executor**, not a validator. It ensures Lua source compiles and runs in a sandbox, resolves template inheritance, and flattens instance trees — but performs **zero field-level validation**. Any syntactically valid Lua table passes through, regardless of missing fields, wrong types, or broken cross-references.

**Meta-check must catch everything the loader doesn't.**

---

## 1. What the Loader DOES Check

### 1.1 Syntax & Execution Safety (load_source, line 66-92)

| Check | How | Error Message |
|-------|-----|---------------|
| Lua compile error | `loadstring()` / `load()` | `"compile error: ..."` |
| Runtime error | `pcall(chunk)` | `"runtime error: ..."` |
| Return type is table | `type(result) ~= "table"` | `"object source must return a table, got ..."` |

**Sandbox:** Objects execute inside a restricted environment (`make_sandbox()`, line 17-33). Only safe globals are exposed: `ipairs`, `pairs`, `next`, `math`, `string`, `table`, `pcall`, `error`, `type`, `tonumber`, `tostring`. No `os`, `io`, `require`, `dofile`, `loadfile`.

### 1.2 Template Resolution (resolve_template, line 98-112)

| Check | How | Error Message |
|-------|-----|---------------|
| Template exists | Lookup in templates table | `"template 'X' not found"` |

After resolution, the `template` field is removed (`resolved.template = nil`). Base properties are deep-merged with instance overrides.

### 1.3 Instance Resolution (resolve_instance, line 122-167)

| Check | How | Error Message |
|-------|-----|---------------|
| Instance has `type_id` | `not instance.type_id` | `"instance 'X' missing type_id"` |
| Base class exists for GUID | Lookup in base_classes | `"base class not found for guid 'X'"` |

Also performs:
- GUID normalization (strips braces: `{abc}` → `abc`)
- Template re-resolution if base wasn't pre-resolved
- Clears `contents` arrays (rebuilt from instance tree)
- Clears surface zone contents

### 1.4 Instance Tree Flattening (flatten_instances, line 182-223)

Walks the deep-nested instance tree and produces a flat array with `.location` fields:
- `"room"` — room-level object
- `"parent_id.surface"` — placed on a parent's named surface
- `"parent_id"` — simple containment

Handles 4 relationship keys: `on_top`, `underneath`, `nested`, `contents`.

**No validation here** — just structural transformation.

---

## 2. What the Loader Does NOT Check (Silent Pass-Through)

These are the validation gaps. Objects with any of these problems load without error.

### 2.1 Missing Required Fields

| Field | Impact | Example |
|-------|--------|---------|
| `guid` | Object can't be referenced by rooms | Object without identity |
| `id` | Parser can't resolve nouns | `look candle` finds nothing |
| `name` | Display shows `nil` | "You see nil" |
| `keywords` | Parser can't match user input | Object is unreachable |
| `description` | LOOK shows nothing | Blank output on examine |
| `on_feel` | FEEL in darkness fails | Primary dark sense broken |
| `template` | No base properties inherited | Missing defaults |
| `material` | Material system can't derive properties | No hardness, density, etc. |
| `size` | Containment math breaks | Can't check if object fits |
| `weight` | Inventory weight unchecked | Infinite carry capacity |

**The loader checks NONE of these.** An object with only `{ guid = "x" }` loads fine.

### 2.2 Type Correctness

No type checking at all. These all load silently:

```lua
size = "big"           -- should be number
keywords = "candle"    -- should be array of strings
portable = "yes"       -- should be boolean
weight = true          -- should be number
categories = 42        -- should be array of strings
```

### 2.3 FSM Consistency

No validation of state machine integrity:

| Gap | Example |
|-----|---------|
| `initial_state` references non-existent state | `initial_state = "magic"` with no `states.magic` |
| Transition `from`/`to` references missing state | `from = "open"` but no `states.open` |
| Orphan states (unreachable) | State defined but no transition leads to it |
| Dead-end states without `terminal = true` | Non-terminal state with no outgoing transitions |
| `_state` doesn't match `initial_state` | Inconsistent initial state |

### 2.4 Sensory Completeness

The design requires every object to have `on_feel` (primary dark sense). The loader doesn't check this. An object without `on_feel` is invisible in darkness — a game-breaking gap.

### 2.5 Material Validity

`material = "adamantium"` loads fine even though the material registry (`src/engine/materials/init.lua`) has no such material. The engine silently returns `nil` from `materials.get()`.

### 2.6 Cross-Reference Integrity

| Reference | What Should Be Checked |
|-----------|----------------------|
| `type_id` in room instances | Must match an existing object's `guid` |
| Exit `target` | Must match an existing room's `id` |
| `requires_tool` | Should reference a valid tool capability |
| Mutation `becomes` | Must reference an existing object file |
| Mutation `spawns` | Each spawned id must reference an existing object |
| `provides_tool` | Should be a recognized capability string |

The loader checks `type_id` → base class lookup (§1.3) but does NOT validate exit targets, mutation targets, tool capabilities, or spawn references.

### 2.7 Template Conformance

No validation that objects provide the fields their template expects. A `small-item` with `capacity = 100` (a container field) loads without warning.

### 2.8 Keyword Quality

- No minimum keyword count check
- No duplicate keyword detection
- No validation that `id` appears in `keywords`

### 2.9 Numeric Range Validation

- `size = -5` loads fine
- `weight = 99999` loads fine
- `capacity = 0` for a container — loads fine
- `burn_duration = 0` for a timed object — loads fine

### 2.10 Composite Object Consistency

Objects with `parts` table:
- No check that `part_id` in transitions matches a defined part
- No check that `factory` function exists for detachable parts
- No check that `requires_state_match` references a valid state

---

## 3. What Meta-Check Should Catch

### Tier 1: Critical (would crash or break gameplay)

1. **Missing `guid`** — object can't be placed in rooms
2. **Missing `id`** — parser can't resolve nouns
3. **Missing `keywords`** — object unreachable by player
4. **Missing `on_feel`** — darkness gameplay broken
5. **FSM `initial_state` not in `states`** — runtime crash on state lookup
6. **Transition references non-existent state** — runtime crash
7. **`type_id` in room doesn't match any object `guid`** — room load fails
8. **Duplicate `guid` across objects** — registry collision

### Tier 2: High (degraded experience)

9. **Missing `description`** — LOOK shows nothing
10. **Missing `name`** — display shows nil
11. **`material` not in registry** — material system returns nil
12. **Exit `target` references non-existent room** — movement fails
13. **Mutation `becomes` references non-existent object** — mutation fails
14. **Type mismatches** — `size` as string, `weight` as boolean, etc.
15. **Empty `keywords` array** — object exists but can't be interacted with

### Tier 3: Quality (correctness and consistency)

16. **Orphan states** — states with no transitions leading to them
17. **Dead-end non-terminal states** — states with no outgoing transitions
18. **Container without capacity** — `container = true` but no `capacity`
19. **Numeric range violations** — negative size, zero burn_duration
20. **Template conformance** — fields that don't belong to the template
21. **Keyword quality** — `id` not in keywords, duplicate keywords
22. **Orphan objects** — defined but not placed in any room

---

## 4. Architectural Observation

The loader's minimalism is deliberate — it's a **sandbox executor**, not a linter. This is the right design for the engine: fast, permissive, forward-compatible. But it means the entire validation burden falls on either:

1. **Pre-deploy tooling** (meta-lint) — catch errors before they reach the engine
2. **Runtime errors** — discover problems when a player triggers them

Meta-check is the right layer for validation. It can be strict, exhaustive, and catch cross-file consistency issues that no single-file loader could detect.

---

## References

- `src/engine/loader/init.lua` — 226 lines, 5 public functions
- `src/engine/registry/init.lua` — object storage (not audited here)
- `src/engine/materials/init.lua` — material registry
- `resources/research/meta-compiler/schema-catalog.md` — Frink's field type catalog
- `resources/research/meta-compiler/lua-subset-parsing.md` — Frink's parsing analysis
