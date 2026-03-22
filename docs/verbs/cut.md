# Cut

> Cut something with a tool, or self-harm by cutting.

## Synonyms
- `cut` — Cut something
- `slice` — Cut with a blade (synonym)
- `nick` — Cut superficially (synonym)

## Sensory Mode
- **Works in darkness?** ❌ No — requires light to cut world objects
- **Light requirement:** Yes (for cutting objects; self-harm works in dark)
- **Exception:** Self-infliction works in darkness (touch-based)

## Syntax
- `cut [object]` — Cut something (world object)
- `cut [object] with [tool]` — Cut using specific tool
- `cut self` — Self-inflict by cutting (self-injury)
- `cut self with [weapon]` — Cut self with specific blade
- `slice [object] with [tool]` — Cut with blade (synonym)

## Behavior
- **World object cutting:** Requires light, tool, and object to be visible
- **Self-cutting:** Works in darkness, requires blade in inventory
- **Mutation system:** World objects use mutation system for cutting results
- **Injury system:** Self-harm inflicts injury via injury module
- **Body area:** Random or specified body area affected
- **Message:** Mutation message or self-harm description

## Design Notes
- **Dual mode:** Both world object damage and self-harm via same verb
- **Light distinction:** World cutting needs light; self-harm doesn't
- **Weapon profiles:** Uses damage profiles (on_cut)
- **Precision:** Can target specific body areas for self-harm

## Related Verbs
- `stab` — Stabbing attack (similar)
- `slash` — Slashing attack (similar)
- `break`/`tear` — Other destruction verbs

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["cut"]`, `handlers["slice"]`, `handlers["nick"]`
- **Self-infliction:** `handle_self_infliction()` utility
- **World objects:** `find_mutation()` system
- **Ownership:** Bart (Architect)
