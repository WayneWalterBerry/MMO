# Poison Bottle — Object Reference

## Description
A small glass bottle with a skull and crossbones label, containing a sickly green liquid (nightshade extract). Sealed with a cork. Found on the nightstand in the bedroom.

**File:** `src/meta/objects/poison-bottle.lua`
**Design:** `docs/design/objects/poison-bottle.md`

## Location
Bedroom — on the nightstand surface

## Composite Object
The poison bottle is a **composite** — it contains the cork as a detachable part and the label as a readable non-detachable part.

```
poison-bottle (parent)
  ├── cork (detachable part)
  └── label (non-detachable, readable)
```

Single file: `poison-bottle.lua` defines all three objects.

## Consumable Metadata

```lua
is_consumable = true
consumable_type = "liquid"
poison_type = "nightshade"
poison_severity = "lethal"
```

These flags drive the consumption pipeline. The engine checks `is_consumable` to allow drink/consume verbs, and the effect system uses `poison_type` to select the correct injury template.

## FSM States

```
sealed → open → empty (terminal)
```

- **sealed** — Cork in place. Liquid inside. Can smell faintly through the seal. Label readable.
- **open** — Cork removed (cork becomes independent object). Sickly green vapor rises. Acrid fumes. Can drink, pour, smell strongly. Tasting causes minor poison effect.
- **empty** — Liquid consumed or poured out. Empty glass bottle remains. No longer dangerous.

## Cork as Detachable Part

When the player uncorks the bottle:
- Cork becomes its own independent object instance via factory function
- Cork has its own properties: small, round, watertight
- **Future use:** Cork can be used as a fishing float (Wayne's directive)
- Cork removal requires free hands (`requires_free_hands = true`)

## Label as Readable Part

The label is non-detachable and can be read in any state:
- `read label` → "POISON -- Belladonna extract. Lethal if ingested..."
- This is the **fair warning** mechanism — cautious players read before drinking
- Safety hierarchy: READ (safe) → SMELL (safe) → TASTE (warning) → DRINK (lethal)

## Injury Pipeline

**Consumption → Injury (structured effect):**
```lua
effect = {
    type = "inflict_injury",
    injury_type = "poisoned-nightshade",
    source = "poison-bottle",
    damage = 10,
    message = "A bitter, almost sweet taste burns down your throat...",
}
```

**Taste → Injury (sensory effect):**
The open state has `on_taste_effect` — tasting causes a weaker poison dose (damage = 5).

**Injury template:** `src/meta/injuries/poisoned-nightshade.lua`
- Damage type: over_time
- Active → Worsened → Fatal (untreated) or Active → Neutralized → Healed (antidote)
- Cure: nightshade-specific antidote only

## Interactions

| Action | State | Result |
|--------|-------|--------|
| `examine bottle` (sealed) | sealed | Full description + skull label warning |
| `read label` | any | "POISON -- Belladonna extract. Lethal if ingested..." |
| `open bottle` / `uncork bottle` | sealed → open | Cork pops free, becomes own object. Requires free hands. |
| `smell bottle` (sealed) | sealed | "Acrid and chemical through the cork." |
| `smell bottle` (open) | open | "Acrid fumes rise from the uncorked bottle." |
| `taste poison` (open) | open | "BITTER! Searing fire..." + minor poison injury |
| `drink poison` | open → empty | Full poison injury (poisoned-nightshade). Lethal if untreated. |
| `pour poison` | open → empty | Liquid pours out. No injury. Bottle becomes safe. |

## Sensory Descriptions

| State | Look | Feel | Smell | Taste |
|-------|------|------|-------|-------|
| sealed | Skull label, murky green liquid, cork wedged tight | Smooth glass, cold, cork on top | Acrid and chemical through cork | "Glass. Not helpful." |
| open | Cork removed, green vapor, skull label grins | Open mouth, fingers tingle from vapor | Acrid fumes, eyes water | BITTER! Searing fire (+ poison effect) |
| empty | Empty, green residue on walls | Slightly sticky inside | Faint chemical residue | — |

## Keywords / Aliases

- `bottle`, `poison bottle`, `poison-bottle`, `glass bottle`, `small bottle`
- `poison`, `vial`, `potion`, `flask`

## Prerequisites (for GOAP planner)

```lua
prerequisites = {
    drink = { requires_state = "open" },
    pour = { requires_state = "open" },
    open = { requires_state = "sealed", requires_free_hands = true },
    uncork = { requires_state = "sealed", requires_free_hands = true },
}
```

## Mutate Fields

| Transition | Mutate |
|---|---|
| sealed → open (uncork) | `weight -= 0.05`, `keywords += "uncorked"` |
| sealed → open (detach_part) | Same as uncork |
| open → empty (drink) | `weight = 0.1`, `is_consumable = false`, `categories -= "dangerous"`, `keywords += "empty"` |
| open → empty (pour) | Same as drink |

**Design rationale:** Sealed bottle (0.4) loses cork weight on open (-0.05). Empty bottle drops to 0.1 (just glass). `is_consumable` set to false when empty. "dangerous" category removed — engine stops flagging as hazard.

## Design Directives (from Wayne)

1. Poison bottle has a cork — when removed, cork becomes its own object
2. Cork is a detachable part (composite object pattern)
3. Cork can later be used as a fishing float
4. Drinking poison inflicts nightshade poisoning (injury system, not instant death)
5. Poison bottle should be examinable, smellable in all states
6. Label is readable without opening — fair warning design
7. Single .lua file defines bottle, cork, and label
8. "poison bottle" must work as a noun phrase (BUG-014, fixed)

## Material

**Material:** `glass` — references the material registry for fragility, opacity, etc.

## Principle 8 Compliance

The poison bottle declares all behavior via metadata — the engine has zero knowledge of "poison bottle" as a type. The structured `effect` table on transitions drives injury infliction through the generic effect processing pipeline. No `if obj.id == "poison-bottle"` anywhere in engine code.
