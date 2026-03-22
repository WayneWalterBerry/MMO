# Taste

> Gustatory sensory verb — taste objects or consume by tasting.

## Synonyms
- `taste` — Taste an object
- `lick` — Taste by licking
- `consume` — Eat/taste by consuming

## Sensory Mode
- **Works in darkness?** ✅ Yes — taste works without vision
- **Primary sense:** Taste/Gustatory
- **Light requirement:** None
- **Warning:** Tasting unknown objects is risky

## Syntax
- `taste [object]` — Taste something
- `lick [object]` — Taste by licking
- `taste the [object]` — Taste with article

## Behavior
- **Object information:** Returns taste-based description
- **Flavor analysis:** May identify poisons, compositions, edibility
- **Search order:** Hands first (interaction verb — you taste what you have)
- **Risk:** Poisoned or unsafe objects may cause harm
- **Consumption:** Some objects are consumed (partially or fully) by tasting

## Design Notes
- **High risk:** Tasting unknown objects without identification may cause injury/sickness
- **Discovery sense:** Can taste to identify (e.g., taste water vs. salt water)
- **Works in darkness:** No light requirement
- **Less common:** Taste is a specialized sense, less used than sight/touch/hearing
- **Complementary:** Often paired with smell (odor + flavor)

## Related Verbs
- `eat` — Consume by eating (related action)
- `drink` — Consume liquid (different verb)
- `smell` — Often precedes taste
- `search` — May use taste as discovery sense (rare)
- `find` — May use taste to locate

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["taste"]`, `handlers["lick"]`
- **Consumption:** May consume part/all of object on taste
- **Ownership:** Smithers (UI Engineer) — gustatory descriptions
