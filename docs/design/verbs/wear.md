# Wear

> Put on a wearable item (clothing, armor, accessories).

## Synonyms
- `wear` — Put on a wearable item
- `don` — Put on (formal synonym)
- `put on` (context-dependent) — Can mean wear in clothing context

## Sensory Mode
- **Works in darkness?** ✅ Yes — can dress by touch
- **Primary sense:** Touch
- **Light requirement:** Not required

## Syntax
- `wear [object]` — Put on a wearable item
- `don [object]` — Put on (formal)
- `put on [object]` — Put on (casual, context-dependent)

## Behavior
- **Wearable check:** Object must have `wearable = true`
- **Search order:** Hands first (interaction verb)
- **Worn slot:** Item moves to "worn" inventory slot (separate from hands/bags)
- **Limited capacity:** Only one item per slot (hat, cloak, armor, etc.)
- **State change:** Item location changes from hands/inventory to "worn"
- **Message:** "You wear X."

## Design Notes
- **Interaction verb:** Hands-first search — you wear what you're holding
- **Separate inventory:** Worn items don't use hand slots; tracked separately
- **Removal:** Use `remove` to take off worn items
- **Equipment burden:** Worn items may affect carrying capacity or provide benefits

## Related Verbs
- `remove` — Take off a worn item (inverse)
- `inventory` — Check worn items
- `drop` — Drop something (different from removing)
- `don` — Formal synonym

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["wear"]` and `handlers["don"]`
- **Worn inventory:** `ctx.player.worn` or similar structure
- **Ownership:** Bart (Architect) — inventory state management
