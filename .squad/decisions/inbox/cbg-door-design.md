# Decision: Doors Should Be First-Class Objects (D-DOOR-OBJECTS)

**Author:** Comic Book Guy (Creative Director, Design Department Lead)  
**Date:** 2026-07-27  
**Status:** PROPOSED — Awaiting Wayne's review  
**Analysis:** `plans/door-design-analysis.md`

## Decision

Doors, windows, gates, portcullises, and all passage-gating constructs should be **first-class objects** (.lua files with templates, FSM, sensory properties, material inheritance) rather than inline exit-construct tables.

Room exit tables should become thin routing references:
```lua
exits = {
    north = { target = "hallway", door_id = "bedroom-door" }
}
```

All door behavior (state, transitions, mutations, sensory descriptions, material properties) lives in the door object file, not the exit table.

## Rationale

1. **Genre precedent:** Zork, Inform 6/7, Hugo all model doors as objects. TADS 3's exit-construct approach is its most criticized design.
2. **Principle alignment:** Door-objects align with Principles 1, 3, 4, 6, 7, 8, 9, and D-14. Exit-constructs violate all of them.
3. **Sensory system:** Game starts at 2 AM in darkness. Players FEEL doors. Exit-constructs don't participate in sensory space.
4. **Scenario coverage:** Door-objects handle all 10 tested scenarios. Exit-constructs fail on 3 (talking doors, remote mechanisms, timed drawbridges).
5. **Designer ergonomics:** Template inheritance + thin exits = less boilerplate than 150-line inline exit definitions.

## Migration Path

- **Phase 1 (Now):** Keep existing exits. Document door-object pattern.
- **Phase 2 (Post-playtest):** Create `door` template. Migrate bedroom-door to thin-exit pattern.
- **Phase 3:** Migrate remaining exits. Remove inline mutation code.
- **Phase 4:** All doors are objects. Exits are thin references.

## Affects

- **Bart:** Movement handler reads door object state; exit table schema change
- **Flanders:** Creates door template and door object definitions
- **Moe:** Room files simplified — thin exit references replace inline door logic
- **Smithers:** Verb dispatch routes to door objects
- **Nelson:** Regression tests for all door interactions during migration

## Risk

Primary risk is sync bugs between door object state and exit traversability. Mitigation: door object is SOLE source of truth — exit tables contain only `target` and `door_id`, zero state.
