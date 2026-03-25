# Deep Architecture Analysis: Doors, Portals & Exits

**Author:** Bart (Architecture Lead)  
**Date:** 2026-07-28  
**Status:** Analysis — pending Wayne's decision  
**Scope:** Should doors/portals be special-cased room constructs or first-class objects?

---

## 1. Executive Summary

The current exit system is a **parallel object system** hiding inside room definitions. Exits have their own mutation mechanism (`becomes_exit`), their own keyword resolution (`exit_matches`), their own state model (boolean flags instead of FSM), and their own effect pipeline (`on_traverse`) — all separate from the engine's established object infrastructure. This violates Core Principles P1, P2, P3, P5, P6, P8, and P9. The hybrid approach — where some doors exist as *both* exit tables and object .lua files linked by `passage_id` — is the worst of both worlds: double maintenance, split state, and synchronization bugs waiting to happen.

**My recommendation is Option B: Exits become first-class objects with a thin routing layer.** This unifies doors under the existing object system (FSM, mutation, sensory, materials, templates) while keeping a lightweight `exits` map on rooms for directional routing. The engine gains simplicity (remove ~200 lines of exit-specific code), designers gain full creative freedom (doors that talk, dissolve, teleport, contain hidden compartments), and every Core Principle is satisfied. The migration is incremental and backward-compatible.

---

## 2. Current State Analysis: The Hybrid Problem

### 2.1 What Exists Today

The engine has **two parallel systems** for modeling passages between rooms:

#### System A: Exit Tables (room-level)
Inline tables in `room.exits[direction]` with:
- Boolean state flags: `open`, `locked`, `hidden`, `broken`, `breakable`
- Own mutation pattern: `becomes_exit` (property merge, not code rewrite)
- Own keyword matching: `exit_matches()` function in helpers.lua
- Own effect system: `on_traverse` table processed by traverse_effects.lua
- Own sensory properties (optional, inconsistent): `on_feel`, `on_listen` sometimes present
- No GUID, no template, no material, no FSM states/transitions

#### System B: Door Objects (.lua files)
Standard object definitions (bedroom-door.lua, wooden-door.lua, locked-door.lua, trap-door.lua) with:
- Full FSM: states, transitions, sensory text per state
- Template inheritance (furniture template)
- Material property (oak)
- `linked_exit` / `linked_passage_id` to synchronize with exit table
- Sensory properties per state: on_examine, on_feel, on_smell, on_listen, on_knock, on_push, on_pull

#### The Synchronization Problem
When both exist for the same door:
- **State lives in TWO places**: exit.open/locked flags AND object._state
- **Mutations happen in TWO systems**: exit uses `becomes_exit` merge; object uses FSM transitions
- **The engine must sync them**: destruction.lua lines 138-150 manually copy name/description/keywords from exit mutation to room object
- **Sensory queries split**: "look at door" might hit the object OR the exit depending on search order
- **No guarantee of consistency**: nothing enforces that exit.locked=true corresponds to object._state="locked"

### 2.2 Exit-Specific Engine Code Inventory

| File | Lines | Exit-Specific Logic |
|------|-------|-------------------|
| `helpers.lua` | ~12 | `exit_matches()` — parallel to `matches_keyword()` |
| `movement.lua` | ~80 | Direction resolution, exit state validation, traversal flow |
| `destruction.lua` | ~40 | `becomes_exit` merge, exit breakability, exit-object sync |
| `containers.lua` | ~60 | Exit open/close/lock/unlock via `becomes_exit` (4 verb paths) |
| `sensory.lua` | ~30 | Exit-targeted look/examine/feel/listen |
| `traverse_effects.lua` | ~90 | Full standalone module for pre-movement effects |
| `equipment.lua` | ~5 | Exit reference for edge cases |
| `acquisition.lua` | ~5 | Exit reference for edge cases |
| **Total** | **~322** | **Lines of exit-specific engine code** |

This is a **parallel object system** implemented across 8 engine files. Every capability the object system already provides (FSM, mutation, sensory, keyword matching) has a simpler, less-capable duplicate for exits.

### 2.3 How Verbs Currently Handle Exits

The `open` verb in containers.lua follows this dispatch:

1. Search visible objects for FSM match → if found, run FSM transition
2. Search visible objects for mutation match → if found, run object mutation
3. **Fall through to exits** → iterate room.exits, run `exit_matches()`, apply `becomes_exit`

This means exits are ALWAYS the fallback. The verb handler has two completely different code paths: one for objects (FSM-aware, mutation-aware, sensory-aware) and one for exits (flag-based, merge-based, sensory-limited).

---

## 3. Option A: Exits Stay as Room Constructs (Status Quo + Cleanup)

### What This Means
Keep the current `room.exits[direction]` inline table approach. Clean up the hybrid by removing door .lua objects — exits become the SOLE representation of passages. No more dual state.

### What Gets Improved
- Remove bedroom-door.lua, wooden-door.lua, locked-door.lua, trap-door.lua as separate objects
- Remove `linked_exit` / `linked_passage_id` synchronization logic
- All door state lives in one place (the exit table)
- Simpler mental model: "exits are exits, objects are objects"

### What Stays the Same
- `becomes_exit` mutation system (parallel to object mutation)
- `exit_matches()` keyword resolution (parallel to object keyword matching)
- Boolean flag state model (no FSM for exits)
- `on_traverse` effect system (separate from effects pipeline)
- Exits lack templates, GUIDs, materials, full sensory space

### Principle Alignment

| Principle | Satisfied? | Notes |
|-----------|-----------|-------|
| P0: Objects are inanimate | N/A | Doors are inanimate, but exits aren't objects |
| P0.5: Deep nesting | ❌ | Exits can't contain inner objects (no lock mechanism as sub-object, no peephole) |
| P1: Code-derived mutable | ⚠️ Partial | Exits mutate via `becomes_exit` merge, not code mutation (D-14 Prime Directive violated) |
| P2: Base → instance | ❌ | No template system for exits — every exit is bespoke |
| P3: FSM + state tracking | ❌ | Boolean flags (open/locked/hidden), not FSM states with transitions |
| P4: Composite encapsulation | ❌ | Exits can't encapsulate inner objects |
| P5: Multiple instances per base | ❌ | Every exit is unique; no shared base |
| P6: Sensory space | ⚠️ Partial | Some exits have on_feel/on_listen, but inconsistent; no per-state sensory text |
| P7: Spatial relationships | ⚠️ Partial | Exits ARE spatial but use direction-keyed topology (not nesting) |
| P8: Engine executes metadata | ❌ | Exit mutations are a PARALLEL metadata system with dedicated engine code |
| P9: Material consistency | ❌ | Exits have no material properties |

**Alignment Score: 0 full / 3 partial / 8 missed out of 11 principles**

### Engine Code Impact
- **Kept**: ~322 lines of exit-specific code across 8 files
- **Removed**: ~30 lines of sync logic in destruction.lua
- **Net**: Still maintaining a parallel object system

### Game Design Flexibility

| Scenario | Supported? | How |
|----------|-----------|-----|
| Locked door with key | ✅ | `key_id` + `becomes_exit` unlock mutation |
| Breakable door | ✅ | `breakable` + break mutation |
| Hidden passage | ✅ | `hidden = true`, revealed by trigger |
| Window as exit | ✅ | Already exists (bedroom-courtyard) |
| One-way door | ✅ | Define exit on one side only |
| Trap door | ✅ | Already exists with `reveals_exit` |
| Door that requires puzzle | ⚠️ | Would need custom condition function |
| Portcullis (raise/lower) | ⚠️ | Would need new mutation states |
| Drawbridge (multi-step) | ❌ | Boolean flags can't model multi-step sequences |
| Teleportation circle | ❌ | No material/magical properties |
| Door that talks | ❌ | Exits have no NPC/dialogue hooks |
| Door with peephole | ❌ | Exits can't contain sub-objects |
| Collapsing tunnel | ❌ | No material degradation, no FSM for progressive collapse |
| Door that appears/disappears | ⚠️ | `hidden` toggle works but no timed FSM |
| Secret door with mechanism | ❌ | No composite parts (handle, lock, mechanism) |
| Magical ward on door | ❌ | No effect system, no material magic properties |

---

## 4. Option B: Doors Become First-Class Objects (Full Unification)

### Core Idea
Exits become **references to objects**, not inline definitions. The room file keeps a thin `exits` routing table that maps directions to door/passage object GUIDs. All door state, behavior, sensory properties, and mutations live in the object system.

### How Exits Would Be Defined

**Room file (thin routing only):**
```lua
-- start-room.lua
return {
    id = "start-room",
    name = "Bedroom",
    description = "Permanent features only...",
    
    exits = {
        north = { passage = "bedroom-hallway-door" },   -- object ID
        window = { passage = "bedroom-window" },         -- non-cardinal direction
        down = { passage = "bedroom-trapdoor" },
    },
    
    instances = {
        -- doors are just objects in the room
        { id = "bedroom-hallway-door", type_id = "{guid}" },
        { id = "bedroom-window", type_id = "{guid}" },
        { id = "bedroom-trapdoor", type_id = "{guid}" },
        -- ... other furniture ...
    },
}
```

**Door object (full object system):**
```lua
-- bedroom-hallway-door.lua
return {
    guid = "{guid}",
    template = "passage",             -- NEW template for traversable objects
    id = "bedroom-hallway-door",
    name = "a heavy oak door",
    material = "oak",
    keywords = {"door", "oak door", "heavy door", "barred door"},
    
    -- Passage-specific metadata (declared, engine-executed per P8)
    passage = {
        target = "hallway",           -- destination room
        bidirectional_id = "bedroom-hallway-passage",  -- sync both sides
        direction_hint = "north",     -- for "which way?" queries
        max_carry_size = 3,           -- size limit for passing through
        max_carry_weight = 50,        -- weight limit
    },
    
    -- Standard sensory (works in darkness via P6)
    on_feel = "Rough oak planks, iron-banded. An iron bar sits in heavy brackets across the frame.",
    on_smell = "Old oak and iron. Faint draft from the other side.",
    on_listen = "Silence beyond the door. The iron bar doesn't rattle — it's seated firm.",
    on_taste = "You lick a door. It tastes like regret and splinters.",
    
    -- Standard FSM (P3)
    initial_state = "barred",
    _state = "barred",
    states = {
        barred = {
            description = "A heavy oak door sealed by an iron bar in brackets.",
            room_presence = "A heavy oak door bars the way north, an iron crossbar seated in brackets.",
            traversable = false,
            on_examine = "The door is solid oak with iron hinges. A thick iron bar...",
            on_knock = "Your knuckles meet solid oak. No response from beyond.",
            on_push = "The door doesn't budge. The iron bar holds it fast.",
        },
        unbarred = {
            description = "A heavy oak door, closed but no longer barred.",
            room_presence = "A heavy oak door to the north stands unbarred.",
            traversable = false,
            on_examine = "The iron bar has been removed. The door is closed but free.",
            on_push = "The door shifts slightly in its frame. You could push it open.",
        },
        open = {
            description = "The oak door stands open, revealing a dim hallway beyond.",
            room_presence = "The oak door to the north stands open.",
            traversable = true,
            on_examine = "The door is swung inward on heavy iron hinges. A hallway stretches north.",
        },
        broken = {
            description = "A splintered doorframe with twisted iron hinges.",
            room_presence = "A shattered doorframe opens north, splinters littering the floor.",
            traversable = true,
            on_examine = "The door has been smashed apart. Jagged oak splinters cling to the frame.",
        },
    },
    transitions = {
        { from = "barred", to = "unbarred", verb = "unbar" },
        { from = "unbarred", to = "open", verb = "open", aliases = {"push"} },
        { from = "open", to = "unbarred", verb = "close", aliases = {"shut"} },
        { from = "barred", to = "broken", verb = "break", requires_capability = "blunt_force",
          requires_strength = 3 },
        { from = "unbarred", to = "broken", verb = "break", requires_capability = "blunt_force" },
    },
    
    -- Standard mutations (P1, D-14 Prime Directive)
    mutations = {
        break = {
            becomes = "bedroom-hallway-door-broken",  -- standard code mutation!
            message = "You smash through the oak door! Splinters fly everywhere.",
            spawns = { "wood-splinters" },
        },
    },
    
    -- Traverse effects (now on the OBJECT, not a separate system)
    on_traverse = {
        wind_effect = {
            extinguishes = { "candle" },
            message_extinguish = "A draft through the doorway gutters your candle flame.",
        },
    },
}
```

### How the Engine Would Process Them

**Movement verb (simplified):**
```lua
-- movement.lua — drastically simplified
function handle_movement(ctx, direction)
    local room = ctx.current_room
    local exit_ref = room.exits[direction]
    if not exit_ref then
        -- fallback: search all passage objects by keyword
        exit_ref = find_passage_by_keyword(ctx, direction)
    end
    if not exit_ref then
        print("You can't go that way.")
        return
    end
    
    -- Resolve the passage OBJECT from registry
    local passage = ctx.registry:find_by_id(exit_ref.passage)
    if not passage then
        print("You can't go that way.")
        return
    end
    
    -- Check traversability via FSM state (not boolean flags!)
    local state = passage.states and passage.states[passage._state]
    if not state or not state.traversable then
        -- State-specific messaging (per D-DOOR-FSM-ERROR-ROUTING)
        local msg = state and state.blocked_message
        if passage._state == "locked" then
            print((passage.name or "The way") .. " is locked.")
        elseif not state or not state.traversable then
            print((passage.name or "The exit") .. " is closed.")
        end
        return
    end
    
    -- Process traverse effects (reuses effects pipeline!)
    if passage.on_traverse then
        traverse_effects.process(passage, ctx)
    end
    
    -- Standard movement flow (unchanged)
    fire_hook("on_exit_room", ctx.current_room, ctx)
    ctx.player.location = passage.passage.target
    fire_hook("on_enter_room", ctx.rooms[passage.passage.target], ctx)
    -- ... arrival text ...
end
```

**Key insight:** The `open`, `close`, `lock`, `unlock`, `break` verbs need ZERO exit-specific code. They already handle FSM objects and mutations. The door is just another object.

### Principle Alignment

| Principle | Satisfied? | Notes |
|-----------|-----------|-------|
| P0: Objects are inanimate | ✅ | Doors are inanimate objects |
| P0.5: Deep nesting | ✅ | Doors can use `contents`, `nested` for sub-objects (lock mechanism, peephole, mail slot) |
| P1: Code-derived mutable | ✅ | Door mutations use standard `becomes` (code rewrite), obeying D-14 |
| P2: Base → instance | ✅ | `passage` template defines base shape; rooms instantiate |
| P3: FSM + state tracking | ✅ | Full FSM with states/transitions; `traversable` flag per state |
| P4: Composite encapsulation | ✅ | Doors can contain inner objects (lock, handle, hinges, peephole lens) |
| P5: Multiple instances per base | ✅ | Can reuse "standard-oak-door" template across rooms |
| P6: Sensory space | ✅ | Full per-state sensory text; works in darkness (on_feel always) |
| P7: Spatial relationships | ✅ | Direction-keyed routing + nesting for door parts |
| P8: Engine executes metadata | ✅ | Engine reads `traversable`, `passage.target`; no exit-specific logic |
| P9: Material consistency | ✅ | `material = "oak"` → engine derives breakability, fire behavior, sound |

**Alignment Score: 11/11 principles fully satisfied**

### Engine Code Impact

| Change | Lines Removed | Lines Added | Net |
|--------|--------------|------------|-----|
| Remove `exit_matches()` from helpers.lua | -12 | 0 | -12 |
| Remove exit-specific paths from containers.lua (open/close/lock/unlock) | -60 | 0 | -60 |
| Remove exit-specific paths from destruction.lua | -40 | 0 | -40 |
| Remove exit-specific paths from sensory.lua | -30 | 0 | -30 |
| Simplify movement.lua (resolve passage object, check `traversable`) | -80 | +30 | -50 |
| Remove exit-object sync in destruction.lua | -20 | 0 | -20 |
| Add `passage` template | 0 | +25 | +25 |
| Add `find_passage_by_keyword()` helper (uses existing `matches_keyword`) | 0 | +15 | +15 |
| Update `traverse_effects.lua` to read from object | -10 | +5 | -5 |
| **Total** | **-252** | **+75** | **-177 net lines removed** |

### Game Design Scenarios This Enables

| Scenario | How It Works |
|----------|-------------|
| Locked door with key | FSM: locked → unlocked → open (standard transition + key tool) |
| Breakable door | FSM transition + mutation `becomes` (standard code rewrite) |
| Hidden passage | FSM: hidden → revealed → open (standard states) |
| Window as exit | Passage template with `max_carry_size` constraint |
| One-way door | Passage on one side only; or `traversable` only in one state direction |
| Trap door | FSM: hidden → closed → open; `hidden` state has no room_presence |
| **Portcullis** | FSM: lowered → raising → raised → lowering (timed states!) |
| **Drawbridge** | FSM: raised → lowering → lowered → raising (chain mechanism as sub-object) |
| **Teleportation circle** | Passage with `material = "arcane"`, `requires_capability = "magic"` |
| **Door that talks** | `on_knock` / `on_push` hooks return dialogue; future NPC hooks ready |
| **Door with peephole** | Composite: door contains peephole lens (nested object). "look through peephole" works |
| **Collapsing tunnel** | FSM: stable → cracking → collapsed; timed transition; material = "stone" |
| **Door appears/disappears** | FSM with timed states: visible → fading → hidden → materializing → visible |
| **Secret door with mechanism** | Composite: wall panel with hidden lever (nested). Lever triggers FSM transition |
| **Magical ward** | Effect on examine/touch; requires specific tool/spell to dispel (FSM gate) |
| **Door with lock as sub-object** | Composite: door contains lock (nested). Pick lock = interact with sub-object |
| **Size-gated passage** | `max_carry_size` / `max_carry_weight` on passage metadata |

### Migration Path

**Phase 1: Create passage template + engine support** (1 session)
- Create `src/meta/templates/passage.lua` with base shape
- Add `find_passage_by_keyword()` to helpers.lua
- Update movement.lua to resolve passage objects
- Add `traversable` check to movement flow

**Phase 2: Migrate one door as proof of concept** (1 session)
- Convert bedroom-hallway-door to full passage object
- Update start-room.lua exits.north to thin reference
- Update hallway.lua exits.south to thin reference
- Verify all verbs work: go north, open door, break door, look door, feel door

**Phase 3: Migrate remaining exits** (2-3 sessions)
- Convert all exit definitions to passage objects
- Remove exit-specific code paths from containers.lua, destruction.lua, sensory.lua
- Remove `becomes_exit` mutation system
- Remove `exit_matches()` (replace with standard `matches_keyword`)

**Phase 4: Cleanup** (1 session)
- Remove `linked_exit` / `linked_passage_id` fields
- Simplify traverse_effects.lua to read from object
- Update all tests
- Update documentation

**Backward compatibility:** Phase 1-2 can coexist with old exit system. Movement.lua checks for passage object first, falls back to inline exit table. This allows incremental migration with zero big-bang risk.

---

## 5. Option C: Lightweight Passage References with Shared State (Hybrid Done Right)

### Core Idea
Keep exits as direction-keyed maps on rooms, but make them **references to a shared passage registry** instead of inline tables. Passages are defined once (not as full objects, but as typed records) and rooms point to them by ID.

### How It Would Look

**Passage definitions (new file: `src/meta/passages/bedroom-hallway-door.lua`):**
```lua
return {
    id = "bedroom-hallway-door",
    type = "door",
    name = "a heavy oak door",
    material = "oak",
    keywords = {"door", "oak door"},
    
    rooms = { "start-room", "hallway" },  -- bidirectional
    
    open = false,
    locked = true,
    breakable = true,
    
    -- Still flag-based, but centralized
    mutations = {
        open = { open = true, description = "..." },
        close = { open = false },
        break = { open = true, broken = true, spawns = {"wood-splinters"} },
    },
}
```

**Room file:**
```lua
exits = {
    north = { passage = "bedroom-hallway-door" },
}
```

### Why I Don't Recommend This

Option C solves the **dual state problem** (one source of truth) but still maintains a parallel system:
- Still needs `becomes_exit`-style mutations (not standard object mutation)
- Still no FSM (boolean flags only)
- Still no templates, sensory per-state, composite encapsulation
- Still requires separate engine code for passage resolution
- Creates a NEW registry (passages) alongside the object registry
- Doesn't leverage ANY existing engine infrastructure

**It's a better hybrid, but still a hybrid.** The architectural debt is reduced but not eliminated. You'd still need passage-specific code in every verb handler.

### Principle Alignment Score: 2/11 (P0, P7 partial)

---

## 6. Principle-by-Principle Alignment Matrix

| Principle | Option A (Status Quo) | Option B (Objects) | Option C (Passage Registry) |
|-----------|----------------------|-------------------|---------------------------|
| P0: Inanimate | N/A (not objects) | ✅ | N/A (not objects) |
| P0.5: Deep nesting | ❌ | ✅ | ❌ |
| P1: Code-derived mutable | ⚠️ Flag merge | ✅ Standard mutation | ⚠️ Flag merge |
| P2: Base → instance | ❌ No templates | ✅ Passage template | ❌ No templates |
| P3: FSM + state | ❌ Boolean flags | ✅ Full FSM | ❌ Boolean flags |
| P4: Composite | ❌ No sub-objects | ✅ Nestable | ❌ No sub-objects |
| P5: Multiple instances | ❌ All unique | ✅ Reusable bases | ❌ All unique |
| P6: Sensory space | ⚠️ Inconsistent | ✅ Full per-state | ⚠️ Possible but no FSM |
| P7: Spatial | ⚠️ Direction only | ✅ Direction + nesting | ⚠️ Direction only |
| P8: Engine executes metadata | ❌ Parallel system | ✅ Unified system | ❌ Still parallel |
| P9: Material | ❌ None | ✅ Full materials | ⚠️ Declared but unused |
| **Score** | **0/11** | **11/11** | **0/11** |

---

## 7. Engine Code Impact Assessment

### Files That Change Under Option B

| File | Current Exit Code | After Option B | Change Type |
|------|------------------|---------------|-------------|
| `verbs/movement.lua` | 80 lines exit logic | 30 lines passage lookup | **Simplify** |
| `verbs/containers.lua` | 60 lines exit open/close/lock/unlock | 0 lines (standard FSM handles it) | **Remove** |
| `verbs/destruction.lua` | 40 lines exit break + sync | 0 lines (standard mutation handles it) | **Remove** |
| `verbs/sensory.lua` | 30 lines exit look/feel/listen | 0 lines (standard sensory handles it) | **Remove** |
| `verbs/helpers.lua` | 12 lines `exit_matches()` | 15 lines `find_passage_by_keyword()` | **Replace** |
| `traverse_effects.lua` | 90 lines standalone module | ~60 lines (reads from object) | **Simplify** |
| `verbs/equipment.lua` | 5 lines exit ref | 0 | **Remove** |
| `verbs/acquisition.lua` | 5 lines exit ref | 0 | **Remove** |
| **New: `templates/passage.lua`** | — | 25 lines | **Add** |
| **All 7 room files** | Inline exit tables | Thin passage references | **Simplify** |
| **4 door object files** | Hybrid linked objects | Full passage objects | **Upgrade** |

### Test Impact
- `test/rooms/test-bedroom-door.lua` — update to test passage object
- `test/objects/test-bedroom-door-object.lua` — merge into door test
- `test/verbs/test-movement-verbs.lua` — update mock exits to passage references
- `test/verbs/test-door-resolution.lua` — update for passage resolution
- `test/parser/test-on-traverse.lua` — update for object-based traverse
- `test/search/test-search-traverse.lua` — update traverse search tests
- Estimated: ~15-20 test files touched, mostly mock context updates

---

## 8. Game Design Flexibility Comparison

### Complexity Spectrum

```
Simple ←————————————————————————————————→ Complex

Option A handles:          Option B handles:
├─ Open door               ├─ Everything in A, plus:
├─ Locked door + key       ├─ Multi-step mechanisms (portcullis, drawbridge)
├─ Break door              ├─ Timed doors (appear/disappear, collapse)
├─ Hidden passage          ├─ Composite doors (peephole, mail slot, lock)
├─ Window exit             ├─ Material-derived behavior (burn oak door, freeze iron gate)
├─ Trap door               ├─ Size/weight gating per passage
└─ One-way door            ├─ Reusable door templates (all Level 2 doors from 1 base)
                           ├─ Magical wards, teleportation circles
                           ├─ Doors with hooks (on_open, on_close, on_traverse)
                           ├─ Progressive degradation (tunnel cracking over time)
                           └─ Puzzle mechanisms as composite sub-objects
```

### Level Design Efficiency

**Option A:** Every exit is hand-authored inline. 7 rooms × ~3 exits = 21 bespoke exit definitions. Adding Level 2 means authoring ~30+ more inline exit tables, each with full mutation definitions.

**Option B:** Create 3-4 passage templates (door, window, archway, stairway). Level 2's 30 exits might use 5 templates with instance overrides. Designers (Flanders/Moe) work with the same patterns they already know for objects.

---

## 9. Recommendation

**I recommend Option B: Full unification of doors as first-class objects.**

### Rationale

1. **Principle alignment is decisive.** 11/11 vs 0/11 isn't a close call. The exit system violates every principle that makes the object system elegant. This isn't an aesthetic concern — it's a debt multiplier. Every new feature (timed events, materials, hooks, effects pipeline) must be separately ported to exits.

2. **The engine shrinks, not grows.** We REMOVE ~250 lines of exit-specific code. The engine already has FSM, mutation, sensory, keyword matching, materials, effects, hooks — exits just need to use them. Zero new engine systems required.

3. **D-14 (Prime Directive) compliance.** `becomes_exit` property merging is NOT code mutation. When a door breaks, the system should rewrite the .lua file (or in-memory table equivalent), not merge a property dict. This is the foundational principle of the engine and exits currently violate it.

4. **Designer velocity.** Flanders and Moe already know how to author objects with FSM and sensory properties. Teaching them a second syntax for exits is overhead. Under Option B, a door is just another object file — same patterns, same templates, same tooling (meta-lint validates it).

5. **Migration is safe.** The backward-compatible migration path means we can convert one door at a time, test it, and move to the next. No big-bang rewrite. The existing tests catch regressions.

6. **Future-proofing.** Level 2+ will have drawbridges, portcullises, magical wards, collapsing tunnels, secret mechanisms. Every one of these is trivial under Option B (just another FSM object) and painful/impossible under Option A (new exit-specific features for each).

### What I Would NOT Do
- Don't try to make exits "smarter" (Option A+). That's putting a bandaid on a parallel system.
- Don't create a passage registry (Option C). That's a third system alongside objects and exits.
- Don't migrate everything at once. Incremental phase approach is critical.

---

## 10. Decision Points for Wayne

### Must Decide

1. **Go / No-Go on unification.** Do we commit to making doors first-class objects? This is a multi-session migration. The payoff is architectural cleanliness and design flexibility; the cost is ~4-6 sessions of incremental work.

2. **Template name: `passage` vs `portal` vs `exit`.** I recommend `passage` — it's the most general term covering doors, windows, archways, trap doors, and magical circles. "Exit" implies one direction; "portal" implies magic.

3. **`traversable` flag: per-state or computed?** My proposal puts `traversable = true/false` on each FSM state. Alternative: compute it from state name or material (e.g., "open" states are always traversable). I recommend explicit per-state — it's clearer and handles edge cases (a door can be "open" but "blocked" by debris).

4. **Bidirectional sync strategy.** Currently `passage_id` loosely links two exit tables. Under Option B, options are:
   - **(a) Single passage object referenced by both rooms** — true single source of truth, but need to handle "which side am I on?" for asymmetric descriptions
   - **(b) Paired passage objects** — each room has its own door object, linked by `bidirectional_id`. More authoring, but simpler asymmetric descriptions (bedroom side vs hallway side of same door)
   
   I lean toward **(b)** — it's how the game currently works (each room has its own exit description) and avoids complex "which side?" logic. The `bidirectional_id` field lets the engine sync state changes.

5. **Migration priority.** Which door first? I recommend the bedroom-hallway door — it's the most complex (barred/unbarred/open/broken FSM, linked object, traverse effects, break mutation with spawns) and already has a companion object file. If it works, everything else is easier.

### Nice to Have (Decide Later)

6. **Should traverse_effects.lua merge into effects.lua?** The traverse effect system (`wind_effect`) could become just another effect type in the unified effects pipeline. This is a natural follow-on but not required for Phase 1.

7. **Should `on_knock` become a standard verb?** The bedroom-door.lua defines per-state `on_knock` text. Under Option B, this could become a first-class verb (like `on_feel`). Low priority but clean.

8. **Meta-lint rules for passages.** Should meta-lint enforce passage-specific rules (must have `passage.target`, must have at least one `traversable` state)? Yes, but this is Phase 4 cleanup.

---

*— Bart, Architecture Lead*  
*"The best architecture is the one you already have. Exits should use it."*
