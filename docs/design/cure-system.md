# Cure System Design

## Overview

The cure system provides a metadata-driven framework for healing injuries and diseases. Injuries declare their own cures via `healing_interactions` metadata, which define **when** (cure window), **what** (antidote object), and **how** (success/failure messaging) cures are applied. This follows Principle 8: Engine executes metadata — no disease-specific logic in code.

The system supports two healing modes:
1. **Interactive cure:** Player applies a healing object to an active injury
2. **Injury-driven cure:** Player uses a tool that triggers automatic healing matching injury definitions

## Healing Interactions Metadata Format

Each injury definition declares its cures in a `healing_interactions` table:

```lua
healing_interactions = {
    ["healing-poultice"] = {
        transitions_to = "healed",
        from_states = { "incubating", "prodromal" },
        success_message = "The poultice draws the infection. You feel the fever receding.",
        fail_message = "The disease has progressed too far. The poultice has no effect.",
    },
    ["antidote-vial"] = {
        transitions_to = "healed",
        from_states = { "active" },
        success_message = "The antidote courses through your veins. The poison fades.",
        fail_message = "It's too late. The venom has spread.",
    },
}
```

### Metadata Fields

| Field | Type | Purpose | Required |
|-------|------|---------|----------|
| `transitions_to` | string | Target FSM state after cure applied | Yes |
| `from_states` | array | States in which cure is effective | Yes |
| `success_message` | string | Narration when cure succeeds | Yes |
| `fail_message` | string | Narration when cure fails (state outside window) | No |

### Key Rules

- **Object ID is the key:** The healing object's `id` field must exactly match a `healing_interactions` key
- **State gating:** `from_states` array declares which FSM states are curable (cure window)
- **One cure per injury type:** Injury definitions can declare multiple cures (multiple keys)
- **No duplicate keys:** Each healing object ID maps to one interaction per injury definition

## Cure Window: Early → Late → Never

Cure effectiveness is controlled entirely by the `from_states` array. This gates healing to a specific disease phase.

### Cure Window Examples

#### Rabies — Early Window (Incubation & Prodromal Only)

```lua
healing_interactions = {
    ["healing-poultice"] = {
        transitions_to = "healed",
        from_states = { "incubating", "prodromal" },
        success_message = "The poultice draws the infection. You feel the fever receding.",
        fail_message = "The disease has progressed too far. The poultice has no effect.",
    },
}
```

Rabies states:
1. `incubating` (0–15 ticks) — **CURABLE** (hidden, no symptoms)
2. `prodromal` (15–25 ticks) — **CURABLE** (early symptoms appearing)
3. `furious` (25–33 ticks) — **INCURABLE** (too late; no cure declared)
4. `fatal` (33+ ticks) — **INCURABLE** (terminal)

**Player experience:** Player must discover cure before day 25 (in-game). Late discovery locks them into irreversible disease trajectory.

#### Food Poisoning — No Cure Window

```lua
healing_interactions = {},
```

Food poisoning has no cures. It must run its natural course:
1. `onset` → `nausea` → `recovery` → `cleared`

This creates **distinct survival challenges:** rabies is a resource puzzle (find poultice in time), food poisoning is an endurance challenge (survive 20 ticks).

## Antidote Pattern: Object ID Matching

### How It Works

When a player applies a healing object to an injury:

1. **Registry lookup:** Game finds the injury in `player.injuries` by type
2. **Metadata validation:** Loads the injury definition's `healing_interactions` table
3. **Key lookup:** Searches for a key matching the healing object's `id`
4. **State check:** Verifies injury's current `_state` is in `from_states` array
5. **Transition:** If valid, transitions injury to `transitions_to` state and prints success message
6. **Rejection:** If state is outside window, prints fail_message

### Example: Poultice → Rabies

**Object Definition** (`healing-poultice.lua`):
```lua
return {
    guid = "{...}",
    id = "healing-poultice",
    name = "a cloth poultice",
    on_apply = function(self, player, injury)
        -- Called by cure system if healing succeeds
        print("You apply the poultice to the bite wound.")
    end
}
```

**Injury Definition** (`rabies.lua`):
```lua
healing_interactions = {
    ["healing-poultice"] = {
        transitions_to = "healed",
        from_states = { "incubating", "prodromal" },
        success_message = "The poultice draws the infection. You feel the fever receding.",
        fail_message = "The disease has progressed too far. The poultice has no effect.",
    },
}
```

**Execution Flow:**
```
Player: "use poultice on bite"
  → Parser resolves "poultice" → healing-poultice object
  → Parser resolves "bite" → rabies injury
  → cure.apply_healing_interaction(player, healing_poultice)
  → Loads rabies.lua definition
  → Finds healing_interactions["healing-poultice"]
  → Checks if injury._state is in ["incubating", "prodromal"]
    ✓ If YES:  rabies FSM transitions to "healed"
              Print: "The poultice draws the infection. You feel the fever receding."
              Remove injury from player.injuries
    ✗ If NO:   Print: "The disease has progressed too far. The poultice has no effect."
              Injury unchanged
```

## Interactive Cure API

The `src/engine/injuries/cure.lua` module provides the core healing logic:

### `cure.try_heal(player, healing_object, verb)`

Direct healing with a cure object (e.g., "use poultice"):

```lua
local result = cure.try_heal(player, healing_poultice_obj, "use")
if result then
    print("Healing applied!")
else
    print("No effect.")
end
```

**Checks:**
1. Finds active injury matching object's `cures` declaration
2. Validates state is in injury definition's `curable_in` window
3. Validates state is in `healing_interactions[object.id].from_states`
4. Applies transition or removes injury
5. Prints success/fail message

### `cure.apply_healing_interaction(player, healing_object)`

Metadata-driven automatic cure (player applies object to self or injury):

```lua
local success, message = cure.apply_healing_interaction(player, healing_poultice_obj)
if success then
    print(message)
else
    print(message or "That doesn't help.")
end
```

**Scans:** All active injuries, finds first matching `healing_interactions[object.id]`, applies if state valid.

### `cure.resolve_target(player, target_str, cures_list)`

Injury resolution for multi-injury targeting:

```lua
local injury, err = cure.resolve_target(player, "left arm", {"bleeding", "poison"})
if injury then
    -- Apply cure to injury
else
    print(err)  -- "You don't have that injury"
end
```

**Priority order:**
1. Exact instance ID match
2. Display name substring ("severe nausea" matches "nausea")
3. Body location substring ("left arm" matches "arm")
4. Injury type exact match
5. Ordinal index ("first", "second", or "1", "2")

## Cure Eligibility: State-Based Gating

### Curable vs. Incurable States

Injury definitions control cure eligibility via two fields:

| Field | Purpose | Example |
|-------|---------|---------|
| `curable_in` | Global cure window (any antidote) | `["incubating", "prodromal"]` |
| `healing_interactions[x].from_states` | Per-antidote cure window | `["active"]` |

**How they interact:**
- If injury has `curable_in` declared, **all** healing checks respect it first
- Then, specific `healing_interactions[x].from_states` narrows further per antidote
- If both reject, injury is incurable

### Example: Multi-State Curable Window

```lua
-- Poison injury definition
curable_in = { "venom_active", "venom_spreading" }  -- Global window

healing_interactions = {
    ["antidote-vial"] = {
        transitions_to = "antidote_applied",
        from_states = { "venom_active" },
        success_message = "The venom retreats. The paralysis eases.",
    },
    ["healing-salts"] = {
        transitions_to = "healing_active",
        from_states = { "venom_active", "venom_spreading" },
        success_message = "The salts burn through the venom.",
    },
}
```

**Cure eligibility:**
- Venom in `venom_active` state:
  - `antidote-vial` → CURABLE (matches from_states)
  - `healing-salts` → CURABLE (matches from_states)
- Venom in `venom_spreading` state:
  - `antidote-vial` → INCURABLE (not in from_states)
  - `healing-salts` → CURABLE (matches from_states)
- Venom in `venom_fatal` state:
  - All antidotes → INCURABLE (not in global `curable_in`)

## Success/Fail Messaging

When a cure is attempted:

### Success Path

Injury state is in cure window; cure applied:
```lua
print(interaction.success_message)
-- Example: "The poultice draws the infection. You feel the fever receding."
```

### Failure Path

Injury state is **outside** cure window; cure rejected:
```lua
print(interaction.fail_message or interaction.reject_message)
-- Example: "The disease has progressed too far. The poultice has no effect."
```

Both fields are declared in injury definitions; fail_message can be customized per antidote.

## Implementation Files

| File | Role |
|------|------|
| `src/engine/injuries/cure.lua` | Core healing logic (try_heal, apply_healing_interaction, resolve_target) |
| `src/engine/injuries/init.lua` | Injury registry, FSM engine (calls cure module for healing) |
| `src/meta/injuries/food-poisoning.lua` | Example: no healing_interactions (incurable) |
| `src/meta/injuries/rabies.lua` | Example: poultice cure with state gating |

## Injury Definition Example: Rabies with Cure

**File:** `src/meta/injuries/rabies.lua`

```lua
return {
    guid = "{d41aae12-a8b8-481b-a8e7-6c3902130172}",
    id = "rabies",
    name = "Rabies",
    category = "disease",
    description = "A viral disease transmitted through animal bites.",
    
    -- ───────────────────────────────────────────────────────────
    -- DISEASE-SPECIFIC FIELDS
    -- ───────────────────────────────────────────────────────────
    hidden_until_state = "prodromal",
    curable_in = { "incubating", "prodromal" },
    
    initial_state = "incubating",
    
    on_inflict = {
        initial_damage = 0,
        damage_per_tick = 0,
        message = "The bite wound throbs once, then fades. You think nothing of it.",
    },
    
    -- ───────────────────────────────────────────────────────────
    -- FSM STATES
    -- ───────────────────────────────────────────────────────────
    states = {
        incubating = {
            name = "incubating rabies",
            description = "You feel fine. The bite wound has scabbed over.",
            damage_per_tick = 0,
            timed_events = {
                { event = "transition", delay = 5400, to_state = "prodromal" },
            },
        },
        prodromal = {
            name = "early rabies",
            description = "A tingling itch radiates from the old bite wound.",
            damage_per_tick = 1,
            restricts = { precise_actions = true },
            timed_events = {
                { event = "transition", delay = 3600, to_state = "furious" },
            },
        },
        furious = {
            name = "furious rabies",
            description = "Your throat constricts at the thought of water.",
            damage_per_tick = 3,
            restricts = { drink = true, precise_actions = true },
            timed_events = {
                { event = "transition", delay = 2880, to_state = "fatal" },
            },
        },
        fatal = {
            name = "terminal rabies",
            description = "Your body seizes. The virus has reached every nerve.",
            terminal = true,
            death_message = "The rabies has run its course. You collapse.",
        },
        healed = {
            name = "cured of rabies",
            description = "The treatment worked. The fever breaks.",
            terminal = true,
        },
    },
    
    -- ───────────────────────────────────────────────────────────
    -- HEALING INTERACTIONS — Only treatable early
    -- ───────────────────────────────────────────────────────────
    healing_interactions = {
        ["healing-poultice"] = {
            transitions_to = "healed",
            from_states = { "incubating", "prodromal" },
            success_message = "The poultice draws the infection. You feel the fever receding.",
            fail_message = "The disease has progressed too far. The poultice has no effect.",
        },
    },
}
```

## Testing Cure Window

### Test: Cure in Valid State

```lua
-- Rabies in prodromal state
injury._state = "prodromal"
poultice = load_object("healing-poultice")

local success = cure.apply_healing_interaction(player, poultice)
assert(success == true, "Cure should succeed in prodromal state")
assert(injury._state == "healed", "Injury should transition to healed")
```

### Test: Cure in Invalid State

```lua
-- Rabies in furious state
injury._state = "furious"
poultice = load_object("healing-poultice")

local success, msg = cure.apply_healing_interaction(player, poultice)
assert(success == false, "Cure should fail in furious state")
assert(msg:match("progressed too far"), "Should show late-stage rejection message")
assert(injury._state == "furious", "Injury state should unchanged")
```

## Related Documentation

- `docs/architecture/engine/fsm-object-lifecycle.md` — FSM state machine mechanics
- `docs/design/injuries-system.md` — Injury definitions, damage model, restriction system
- `src/meta/injuries/` — All injury definitions with healing_interactions
- `src/engine/injuries/` — Core injury engine (FSM, cure, restrictions)
