# Decision: Material Data Migration (Issue #123)

**Author:** Smithers (Parser/UI Engineer)
**Date:** 2026-07-18
**Status:** Implemented

## Decision

Material definitions now live in `src/meta/materials/` as individual `.lua` files, following the same pattern as objects, templates, and rooms. The engine registry (`src/engine/materials/init.lua`) is now a thin loader that discovers files at require-time.

## Rationale

- **Principle 1 (Code-derived mutable objects):** Materials are metadata, not engine logic. They belong in `src/meta/` alongside objects and rooms.
- **Extensibility:** Adding a new material now requires only dropping a `.lua` file into `src/meta/materials/` — zero engine changes.
- **Consistency:** Objects, templates, rooms, and levels all live in `src/meta/`. Materials were the only holdout.

## Impact

| Who | What |
|-----|------|
| **Flanders** (Objects) | New materials: just create `src/meta/materials/{name}.lua`. No engine coordination needed. |
| **Moe** (Rooms) | No change — rooms don't reference materials directly. |
| **Bart** (Engine) | `engine/materials/init.lua` is now a loader, not a data store. Future engine changes won't touch material data. |
| **Nelson** (QA) | Material audit test (#163) and material properties test (#123) both pass unchanged. |
| **Gil** (Web) | Material files will need to be included in the web build's meta bundle. Coordinate with Gil on the Fengari loader. |

## File Format

Each material file returns:
```lua
return {
    name = "ceramic",
    density = 2300,
    melting_point = 1600,
    ignition_point = nil,
    hardness = 7,
    flexibility = 0.0,
    absorbency = 0.1,
    opacity = 1.0,
    flammability = 0.0,
    conductivity = 0.0,
    fragility = 0.7,
    value = 3,
}
```

The `name` field is used as the registry key and stripped from the property table at load time.

## Files Changed

- `src/engine/materials/init.lua` — rewritten from 333-line data store to 54-line loader
- `src/meta/materials/*.lua` — 23 new files (one per material)
