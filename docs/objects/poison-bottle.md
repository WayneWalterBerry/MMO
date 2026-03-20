# Poison Bottle — Object Design

## Description
A small glass bottle with a skull and crossbones label, containing a sickly green liquid. Sealed with a cork. Found on the nightstand in the bedroom.

## Location
Bedroom — on the nightstand surface

## Composite Object
The poison bottle is a **composite** — it contains the cork as a detachable part.

```
poison-bottle (parent)
  └── cork (detachable part)
```

Single file: `poison-bottle.lua` defines both objects.

## FSM States

```
sealed → open → empty
```

- **sealed** — Cork in place. Liquid inside. Can smell faintly through the seal.
- **open** — Cork removed (cork becomes independent object). Sickly green vapor rises. Can drink, pour, smell strongly.
- **empty** — Liquid consumed or poured out. Empty glass bottle remains.

## Cork as Detachable Part

When the player uncorks the bottle:
- Cork becomes its own independent object instance
- Cork has its own properties: small, round, watertight
- **Future use:** Cork can be used as a fishing float (Wayne's directive)
- Cork can be put back in bottle (reversible detachment)

## Interactions

| Action | State | Result |
|--------|-------|--------|
| `examine bottle` (sealed) | sealed | "A small glass bottle with a skull and crossbones label. A dark green liquid sloshes inside. The cork is firmly in place." |
| `open bottle` / `uncork bottle` | sealed → open | Cork pops free, becomes own object. "Sickly green vapor rises from the open bottle." |
| `smell bottle` (sealed) | sealed | "Faint bitter almond scent through the seal." |
| `smell bottle` (open) | open | "An acrid, chemical smell burns your nostrils. Definitely poison." |
| `drink poison` | open → empty | **DEATH.** Game over. "You raise the bottle to your lips. The liquid burns like fire..." |
| `pour poison` | open → empty | Liquid pours out. "The green liquid hisses as it hits the floor." |
| `put cork in bottle` | open → sealed | Cork reattached. Bottle resealed. |

## Death Mechanic

Drinking the poison is **fatal and immediate**:
- Player dies
- Game over screen
- This is the only death condition in Room 1
- Message: "Your body crumples to the cold stone floor. The world fades to black."

## Timer Behavior

No timer — poison bottle is not a timed object. It's state-driven (sealed/open/empty), not time-driven.

## Sensory Descriptions (4 states × 3 senses)

| State | Look | Feel | Smell |
|-------|------|------|-------|
| sealed | Small glass bottle, skull label, dark green liquid, cork sealed | Cool glass, smooth, liquid sloshes | Faint bitter almond through cork |
| open | Open bottle, green vapor rising, liquid visible | Cool glass, open top, liquid weight | Acrid chemical burn, unmistakably poison |
| empty | Empty glass bottle, residue stains the inside | Light glass, hollow, slight residue | Stale chemical trace |

## Keywords / Aliases

- `bottle`, `poison bottle`, `poison-bottle`, `glass bottle`, `small bottle`
- `poison`, `liquid`, `green liquid`

## Prerequisites (for GOAP planner)

```lua
prerequisites = {
  drink = {
    requires_state = "open"  -- must be uncorked first
  },
  pour = {
    requires_state = "open"
  },
  smell = {
    -- works in any state, but output varies
  }
}
```

## Design Directives (from Wayne)

1. Poison bottle has a cork — when removed, cork becomes its own object
2. Cork is a detachable part (composite object pattern)
3. Cork can later be used as a fishing float
4. Drinking poison = death (game over, implemented)
5. Poison bottle should be examinable, smellable in all states
6. The bottle has 3 smell states matching its FSM (sealed/open/empty)
7. The bottle has 4 visual states matching its FSM
8. Single .lua file defines both bottle and cork
9. "poison bottle" must work as a noun phrase (BUG-014, fixed)
