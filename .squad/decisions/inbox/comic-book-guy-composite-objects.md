# Design Decision: Composite & Detachable Object System

**Date:** 2026-03-25  
**Author:** Comic Book Guy (Game Designer)  
**Approver:** Wayne Berry (Lead Designer)  
**Status:** Ready for Team Review  
**Impact:** Object architecture, puzzle design, player agency

---

## Summary

Objects in MMO are not always singular, indivisible things. A nightstand has a drawer. A poison bottle has a cork. A four-poster bed has curtains. These **sub-objects (parts) can sometimes be detached**, becoming independent objects in the game world.

**Core Insight (Wayne):** "An object might compose 0 or more objects, and that object can sometimes be taken apart. That single object might have Lua code for all the internal objects."

**Our Solution:** Single-file architecture where one `.lua` file defines parent + all parts. Parts detach via factory functions, becoming independent. Parent transitions to new FSM state reflecting missing parts.

---

## Design Decisions

### 1. Single-File Architecture (Approved)

**Decision:** All parts and parent logic live in **one Lua file**.

```lua
-- nightstand.lua defines:
-- 1. Nightstand object (parent)
-- 2. Drawer part (detachable)
-- 3. Legs part (non-detachable)
-- 4. FSM states for each configuration
```

**Rationale:**
- Keeps all object logic together (cohesion)
- Avoids file-per-state scattering (clarity)
- Enables Wayne's directive: "single object might have Lua code for all internal objects"
- Simpler for designers to understand full object at a glance

**Alternative Considered:** File-per-part (drawer.lua separate from nightstand.lua)
- **Rejected:** Scatters related logic, harder to understand parent-part relationship, file proliferation

### 2. Part Factory Pattern (Approved)

**Decision:** Each detachable part has a **factory function** that instantiates it as an independent object.

```lua
parts = {
    drawer = {
        factory = function(parent)
            return {
                id = "nightstand-drawer",
                keywords = {"drawer"},
                location = parent.location,
                -- full object properties
            }
        end
    }
}
```

**Rationale:**
- Clean separation: parent logic doesn't depend on part properties
- Enables composition: part factory defines all part-specific properties
- Reusable: same factory pattern works for all detachable parts
- State-aware: factory can access parent state to make decisions (e.g., carry contents)

**Alternative Considered:** Direct part instantiation (cloning parent's part table)
- **Rejected:** Doesn't handle property transformation, can't customize for independence

### 3. FSM State Naming for Part Presence (Approved)

**Decision:** Parent FSM states reflect which parts are currently attached.

**Naming convention:** `{base_state}_with_PART` and `{base_state}_without_PART`

```lua
states = {
    closed_with_drawer = { ... },
    open_with_drawer = { ... },
    closed_without_drawer = { ... },
    open_without_drawer = { ... },
}
```

**Rationale:**
- State name is self-documenting (tells you which parts are present)
- Enables different descriptions, surfaces, and accessibility per configuration
- Works with existing FSM system (no breaking changes)
- Scales: `missing_front_curtain`, `missing_left_and_right`, etc.

**Alternative Considered:** Bitflag state tracking (state = "closed", has_drawer = true/false)
- **Rejected:** Less clear, requires additional property lookups, harder to reason about

### 4. Verb Dispatch for Parts (Approved)

**Decision:** General verbs trigger detachment. Parts define their own verb aliases.

```lua
parts = {
    cork = {
        detachable_verbs = {"uncork", "remove cork", "pull cork", "pop cork"}
    }
}
```

**Canonical verbs:**
- **PULL:** Generic detachment
- **REMOVE:** Explicit separation
- **UNCORK:** Cork/stopper-specific

**Rationale:**
- No per-object special cases needed
- Player can use natural language variations (uncork, remove cork, pull cork)
- Engine adds these verbs to parent's verb dictionary when part is accessible
- Dispatch: parser recognizes part target → calls parent.detach_part(part_id)

**Alternative Considered:** Custom verbs per object (pull-drawer, uncork-bottle)
- **Rejected:** Clutters verb namespace, less flexible, harder to generalize

### 5. Contents Preservation Through Detachment (Approved)

**Decision:** Container parts carry their contents when detached (by default).

```lua
parts = {
    drawer = {
        carries_contents = true,  -- Default
        factory = function(parent)
            return {
                surfaces = {
                    inside = {
                        contents = parent.surfaces.inside.contents  -- PRESERVE
                    }
                }
            }
        end
    }
}
```

**Rationale:**
- Maintains logical integrity: drawer keeps its items
- Player can examine contents before/after detachment
- Supports puzzle scenarios: hide clue in drawer, player discovers by removing
- Non-container parts (cork) set `carries_contents = false` (no effect, cork has no container)

**Alternative Considered:** Contents drop to floor on detachment
- **Rejected:** Loses player's spatial understanding, breaks puzzle logic

### 6. Two-Handed Carry System (Approved)

**Decision:** Objects have `hands_required` property. Player has 2 hands.

```lua
objects = {
    match = { hands_required = 0 },        -- Pocket-able
    sword = { hands_required = 1 },        -- One-handed
    drawer = { hands_required = 2 },       -- Two-handed (bulky)
}
```

**Constraint:** Both hands must be free to carry `hands_required = 2` item.

**Rationale:**
- Reflects real-world physics (some things need both hands)
- Creates inventory puzzle (player must manage hand slots)
- Integrates with wearables: gloves worn on hands don't consume carrying capacity
- Teaches resource scarcity: full hands = can't pick up heavy objects

**Alternative Considered:** Arbitrary weight limits
- **Rejected:** Less intuitive, doesn't match gameplay metaphor

### 7. Reversibility as Design Choice (Approved)

**Decision:** Each part's reversibility is a **design-time choice**, not automatic.

**Reversible example:** Drawer (future verb: PUT DRAWER IN NIGHTSTAND)
- Drawer can be removed and replaced
- Requires drawer to be compatible, nightstand in matching state

**Irreversible example:** Cork (becomes independent object)
- Cork is permanent once detached
- Can be repurposed (fishing float, etc.) by game state

**Rationale:**
- Gives designers flexibility: some parts come back, some don't
- Supports puzzle design: permanent detachment = consequences, reversible = mistakes forgivable
- Reversibility requires separate verb (PUT) and reverse factory (installation logic)

**Alternative Considered:** All parts reversible by default
- **Rejected:** Limits design expressiveness, not all parts make sense reversible

### 8. Non-Detachable Parts Are Valid (Approved)

**Decision:** Parts can have `detachable = false` for descriptive structure without separation.

```lua
parts = {
    legs = {
        detachable = false,  -- Cannot be taken
        keywords = {"leg", "legs"},
        on_feel = "Solid wood, well-sanded.",
    }
}
```

**Purpose:** Enrich object description without creating detachable parts for everything.

**Rationale:**
- Nightstand legs are structure, not loot
- Adds sensory richness (player can FEEL the legs)
- Designer controls granularity (leg details vs. whole nightstand)
- No engine overhead: non-detachable parts are description-only

**Alternative Considered:** All parts must be detachable
- **Rejected:** Forces meaningless game objects into inventory

---

## Implementation Requirements

### For Bart (Architect)

1. **Part instantiation:**
   - Engine calls `part.factory(parent)` → returns complete object instance
   - Place instance in parent's room (`location = parent.location`)
   - Instance is now independent (not linked to parent)

2. **FSM state transitions:**
   - Support `_with_PART` and `_without_PART` naming
   - Auto-transition when `detach_part()` is called
   - Update description, surfaces, accessibility from new state

3. **Verb dispatch for parts:**
   - Parser recognizes target as part of container object
   - Dispatch to `parent:detach_part(part_id)`
   - Engine handles state transition + factory call

4. **Precondition system:**
   - Call `parent:can_detach_part(part_id)` before detachment
   - Allow parent to define state-dependent constraints (e.g., can't remove drawer from bottle)

5. **Two-handed carry:**
   - Track `hands_required` on objects
   - Enforce limits during TAKE action
   - Update player's hand slots on inventory changes

### For Comic Book Guy (Designer)

1. Create detachable versions of existing objects:
   - Nightstand drawer (detachable, carries contents)
   - Poison bottle cork (detachable, contents-less)
   - Four-poster bed curtains (4x detachable)
   - Wardrobe doors, mirror, shelves (future)

2. Test darkness playability:
   - Ensure parts are sensory-described (on_feel, on_smell, etc.)
   - Verify contents are discoverable by FEEL
   - Test that part detachment is sensory-clear

3. Document design patterns:
   - Provide examples for future designers
   - Document puzzle patterns (hidden compartments, resource repurposing)

---

## Edge Cases & Future Work

### Immediate (In Scope)

- ✅ Single-level composites (parent + parts, no nested)
- ✅ Detachable parts with contents
- ✅ Non-detachable parts (description-only)
- ✅ Partial detachment (some parts removed, some stay)
- ✅ State-dependent detachment (can_detach_part callbacks)

### Future (Out of Scope)

- 🔮 Nested composites (part contains sub-parts)
- 🔮 Reversible attachment (PUT DRAWER IN NIGHTSTAND)
- 🔮 Part mutations (cork → fishing float with new properties)
- 🔮 Weight redistribution (parent weight changes when parts removed)
- 🔮 Dynamic discovery (part visible only after state change)

---

## Success Criteria

1. **Nightstand + drawer detachment works end-to-end:**
   - PULL DRAWER creates independent drawer object
   - Nightstand transitions to `closed_without_drawer` state
   - Drawer carries its contents
   - Both are playable (can interact with both separately)

2. **Poison bottle + cork detachment works:**
   - UNCORK creates cork object
   - Bottle transitions from sealed → open state
   - Cork can be carried, examined, repurposed

3. **Two-handed carry enforced:**
   - Player cannot take 2-handed item if hands are full
   - Error message is clear and helpful
   - Wearables don't block hand carrying

4. **Dark playability maintained:**
   - Parts are sensory-described (FEEL, SMELL work)
   - Player can discover parts by touching
   - Player can understand what detaches via sensory feedback

5. **No existing content breakage:**
   - Existing objects (37 bedroom objects) still work
   - FSM system unchanged (composite objects extend it)
   - Verb dispatch unaffected

---

## Approval

**Approved By:**
- Wayne Berry (Lead Designer): ✅
- Comic Book Guy (Designer): ✅ (Author)

**Ready for Implementation:** Bart (Architect) — schedule implementation phase

**Ready for Design Team:** Brockman (Documentation) — update design docs with implementation updates

---

## References

- **Design Doc:** `docs/design/composite-objects.md` (comprehensive, 12 sections, implementation examples)
- **Example Files:** 
  - `src/meta/objects/nightstand.lua` (current)
  - `src/meta/objects/poison-bottle.lua` (current)
  - Future: nightstand with detachable drawer, poison-bottle with detachable cork
- **Related Systems:**
  - FSM: `docs/design/fsm-object-lifecycle.md`
  - Wearables: `docs/design/wearable-system.md`
  - Verb System: `docs/design/verb-system.md`
  - Sensory Convention: Decision D-28 (Multi-Sensory Object Convention)
