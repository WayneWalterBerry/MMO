# Decision: GUID Normalization Pattern (BUG-063)

**Date:** 2025-03-21  
**Author:** Bart (Architect)  
**Status:** Implemented  
**Commit:** 0ddd673

## Context

Flanders added `{braces}` to all object GUIDs in `src/meta/objects/*.lua`, but room files in `src/meta/world/*.lua` reference GUIDs WITHOUT braces. The loader does exact string matching, causing a complete mismatch.

- Object files: `guid = "{d40b15e6-7d64-489e-9324-ea00fb915602}"`
- Room files: `type_id = "d40b15e6-7d64-489e-9324-ea00fb915602"`
- Result: `base_classes[instance.type_id]` → NO MATCH → game unplayable

## Decision

**Normalize GUIDs at the loader level** by stripping braces before any comparison or indexing operation. This is Option B from the original issue — a one-fix-forever approach that handles both formats transparently.

### Implementation

Added `normalize_guid()` helper function in **four places**:

1. **`src/main.lua`** — normalize when indexing `base_classes` after loading objects
2. **`src/engine/loader/init.lua`** — normalize `instance.type_id` before lookup
3. **`src/engine/registry/init.lua`** — normalize when indexing/finding by GUID
4. **`web/game-adapter.lua`** — normalize in JIT loader for web version

```lua
local function normalize_guid(guid)
  if type(guid) ~= "string" then return guid end
  return guid:gsub("^%{(.-)%}$", "%1")
end
```

Applied at **both registration and lookup points** to ensure consistency.

## Rationale

**Why not just fix the room files?** (Option A)

- Requires mass edits to ~100 instances across 7 room files
- Fragile — any future inconsistency breaks the game again
- Doesn't solve the root problem: we have two valid formats in the wild

**Why normalization wins:**

- Single fix in 4 engine files vs. mass content edits
- Future-proof — both formats work forever
- Defensive coding — loader handles variation gracefully
- No performance cost (regex runs once per object at load time)

## Pattern for Future Use

**GUID Normalization as a Standard Pattern:**

When GUIDs flow between different parts of the system (files, loader, registry), always normalize at **system boundaries**:

- File → Loader: normalize on load
- Loader → Registry: normalize on registration
- Lookup operations: normalize query GUID

This prevents format mismatches from causing silent failures.

## Testing

- ✅ Manual test: `feel around` → nightstand appears, `open drawer` → `get matchbox` works
- ✅ All 280 unit tests pass (test suite: `lua test/run-tests.lua`)
- ✅ No regressions in inventory, parser, or injury systems

## Impact

- **Fixed:** BUG-063 — game now playable again
- **Benefit:** Both `{abc-123}` and `abc-123` formats work anywhere
- **Risk:** None — normalization is idempotent and backward-compatible
