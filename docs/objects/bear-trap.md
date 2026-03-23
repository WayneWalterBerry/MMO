# Bear Trap — Object Reference

## Description
A rusted iron bear trap with powerful spring-loaded jaws. Touch-triggered injury object — armed and dangerous when first encountered. Teaches the "observe first" pattern.

**File:** `src/meta/objects/bear-trap.lua`
**Design:** `docs/design/objects/bear-trap.md`

## Location
Floor-level placement. Visible by default — appears in room description.

## Trap Metadata

```lua
is_trap = true
is_armed = true
is_dangerous = true
trap_type = "spring-jaw"
trap_injury_type = "crushing-wound"
trap_damage_amount = 15
```

These flags identify the object as a hazard. The engine uses `is_dangerous` and `is_armed` to determine contact behavior, and the structured `effect` table on transitions drives injury infliction through the generic effect processing pipeline.

## FSM States

```
set (armed) → triggered (snapped) → disarmed (safe)
```

- **set** — Armed and dangerous. Jaws slightly parted, springs coiled. Touching or taking triggers the trap. Safe to look, smell, and listen from a distance.
- **triggered** — Snapped shut. Jaws clamped, blood on metal. No longer dangerous. Can be taken (heavy) or disarmed.
- **disarmed** — Springs neutralized, jaws locked open. Completely safe. Portable. Can serve as trophy or tool.

## Contact → Injury Pipeline

**Take/Touch trigger (structured effect):**
```lua
effect = {
    type = "inflict_injury",
    injury_type = "crushing-wound",
    source = "bear-trap",
    location = "hand",
    damage = 15,
    message = "The trap's iron jaws crush your hand. The pain is blinding.",
}
```

**Feel trigger (sensory effect):**
The set state has `on_feel_effect` — touching while armed inflicts the same crushing wound.

**Injury template:** `src/meta/injuries/crushing-wound.lua`
- Damage type: over_time (crushing + bleeding combo)
- Initial: 15 damage, then 2/tick from bleeding
- Active → Treated → Healed (bandaged) or Active → Worsened → Critical → Fatal (untreated)
- Treatment: Bandage stops bleeding; crushing pain persists and self-heals

## Safety Hierarchy

Observation is safe. Interaction is risky:

| Action | Safe? | Result |
|--------|-------|--------|
| `look trap` | ✅ Yes | Detailed description — warns of danger |
| `smell trap` | ✅ Yes | "Rust and old blood." |
| `listen trap` | ✅ Yes | "Metallic creak. Springs straining." |
| `feel trap` | ❌ No | SNAP! Jaws crush hand. Injury inflicted. |
| `take trap` | ❌ No | SNAP! Same result. |
| `touch trap` | ❌ No | SNAP! Same result. |

## Interactions

| Action | State | Result |
|--------|-------|--------|
| `examine trap` (set) | set | Full description + "jaws open and waiting" |
| `take trap` (armed) | set → triggered | SNAP! Crushing injury. Trap transitions to triggered. |
| `touch trap` (armed) | set → triggered | SNAP! Same injury + transition. |
| `examine trap` (triggered) | triggered | "Jaws clamped shut, blood on metal, spring slack." |
| `take trap` (triggered) | triggered | Safe. "Heavy, blood-stained, but won't bite again." |
| `disarm trap` (no skill) | triggered | Fails: "You don't understand the mechanism." |
| `disarm trap` (with skill + tool) | triggered → disarmed | Success: springs neutralized, jaws locked open. |
| `take trap` (disarmed) | disarmed | Safe. "Just dead weight — rusted iron and slack springs." |

## Disarm Mechanics

Disarming requires:
1. **Trap must be triggered** (can't disarm while set — too dangerous)
2. **Lockpicking skill** (learned from Medical Scroll in cellar)
3. **Thin tool** (lockpick, knife, needle — `requires_tool = "thin_tool"`)

```lua
guard = function(obj, context)
    return context.player.has_skill("lockpicking")
end
```

Without skill: "You don't know what you're looking for."
With skill + tool: "You find the release pin... tension eases... trap is disarmed."

## Sensory Descriptions

| State | Look | Feel | Smell | Listen |
|-------|------|------|-------|--------|
| set | Rusted jaws, serrated teeth, coiled springs | SNAP! (injury) | Rust and old blood | Metallic creak, springs straining |
| triggered | Jaws clamped, blood stains, slack spring | Slack mechanism, no tension | Blood and rust | Silence |
| disarmed | Jaws locked open, springs neutralized | Inert, cold iron | Rust, fading blood | Silent, dead mechanism |

## Keywords / Aliases

- `trap`, `bear trap`, `bear-trap`, `jaws`, `metal trap`, `rusted trap`, `iron trap`

## Prerequisites (for GOAP planner)

```lua
prerequisites = {
    disarm = {
        requires_state = "triggered",
        requires_skill = "lockpicking",
        requires_tool = "thin_tool",
    },
}
```

## Mutate Fields

| Transition | Mutate |
|---|---|
| set → triggered (take/touch) | `is_armed = false`, `is_sprung = true`, `is_dangerous = false`, `keywords += "sprung"`, `categories -= "dangerous"`, `categories += "evidence"` |
| triggered → disarmed (disarm) | `is_disarmed = true`, `portable = true`, `keywords += "disarmed"`, `categories -= "hazard"`, `categories += "trophy"` |
| triggered → triggered (take) | `portable = true` |

## Principle 8 Compliance

The bear trap declares all behavior via metadata. The structured `effect` tables on transitions drive injury infliction through the generic effect processing pipeline. The `guard` function checks player skills generically. No `if obj.id == "bear-trap"` anywhere in engine code. The engine executes the declared FSM, effects, and guards — it has zero knowledge of "bear trap" as a type.

## Design Directives

1. Trap is visible by default — teaches observation before interaction
2. Contact triggers (take/touch) fire the trap; observation (look/smell/listen) is safe
3. Crushing wound is a combo injury: blunt force + bleeding component
4. Disarm requires skill + tool (skill gated, not arbitrary)
5. Triggered trap is safe to take (heavy but harmless)
6. Future work: hidden traps using `on_traverse` room-level hooks
