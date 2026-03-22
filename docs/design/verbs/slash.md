# Slash

> Slashing attack with a weapon or self-harm by slashing.

## Synonyms
- `slash` — Slash with a weapon
- `carve` — Carve/slash (synonym)

## Sensory Mode
- **Works in darkness?** ❌ No — requires light for world objects
- **Light requirement:** Yes (world objects); No (self-harm)

## Syntax
- `slash [target]` — Slash target (world object or self)
- `slash self` — Self-harm by slashing
- `slash self with [weapon]` — Slash self with specific blade
- `carve [object]` — Carve/slash (synonym)

## Behavior
- **Self-infliction first:** Checks for "self" target or body area keywords first
- **World object fallback:** Falls through to cut logic if not self-infliction
- **Injury system:** Self-harm inflicts injury
- **Body area:** Random or specified
- **Message:** Weapon's description or self-harm message

## Design Notes
- **Self-harm priority:** Slash defaults to self-infliction
- **Fallback to cut:** Non-self targets use cut logic
- **Weapon profiles:** Uses on_slash damage profile

## Related Verbs
- `stab` — Stabbing attack
- `cut` — Cutting attack
- `carve` — Synonym/formal

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["slash"]`, `handlers["carve"]`
- **Self-infliction:** `handle_self_infliction()` utility
- **Ownership:** Bart (Architect)
