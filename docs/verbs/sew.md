# Sew

> Sew materials together — requires sewing skill and tools.

## Synonyms
- `sew` — Sew something
- `stitch` — Stitch with needle (synonym)

## Sensory Mode
- **Works in darkness?** ❌ No — requires light
- **Light requirement:** Yes ("too dark to sew, you'd stab yourself")

## Syntax
- `sew [material]` — Sew material
- `sew [material] with [tool]` — Sew using specific needle
- `stitch [material] with [tool]` — Stitch (synonym)

## Behavior
- **Skill requirement:** Player must know sewing skill
- **Light requirement:** Must have light ("too dark to sew")
- **Material search:** Object must be visible or in inventory
- **Tool requirement:** Must have sewing tool (needle)
- **Thread requirement:** Must have sewing material (thread)
- **Crafting recipe:** Uses material's `crafting.sew` recipe
- **Consumption:** Consumes material items as per recipe
- **Message:** "You sew X."

## Design Notes
- **Skill gate:** Requires sewing skill to execute
- **Tool assembly:** Uses tool resolution system (needle detection)
- **Recipe system:** Follows crafting recipe pattern
- **Light critical:** Cannot sew in darkness (safety mechanic — injury risk)
- **Thread requirement:** Must have thread in inventory

## Related Verbs
- `tear` — Tear fabric (opposite)
- `read` — Teach sewing skill via instruction

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["sew"]`, `handlers["stitch"]`
- **Skill check:** `ctx.player.skills.sewing`
- **Recipe system:** Uses crafting recipe with tool requirements
- **Ownership:** Bart (Architect) — crafting mechanics
