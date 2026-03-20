# Orchestration: Brockman — Sewing Manual + Burnability
**Date:** 2026-03-20T21:15Z
**Agent:** Brockman (Content Creator/Documentation)
**Status:** ✅ COMPLETED

## Spawn Summary
Brockman created comprehensive documentation for the sewing manual object and burnability system, establishing patterns for skill-granting objects and universal burnability across the game.

## Deliverables

### 1. Documentation: docs/objects/sewing-manual.md
- **Purpose:** Reference for sewing manual FSM, skill gating, burnability
- **Coverage:**
  - FSM states: `readable` → `burning` → `burned`
  - Skill acquisition only on READ, not on pickup
  - Burning consequences: permanent skill loss if unread
  - Integration with READ verb handler
  - Pattern for all skill-granting documents

### 2. Burnability System Documentation
- **Universal pattern:** Every object must answer "Is this burnable?"
- **Burnable objects:** Blanket, bed-sheet, rag, sack, paper, cloth, curtains, wool cloak
- **FSM states:** `normal` → `burning` → `burned` (destroyed)
- **Light emission:** Burning objects set `casts_light = true` in FSM `burning` state
- **One-shot timer:** Objects burn for N ticks then consumed
- **Chain reaction potential:** Burning object could ignite nearby flammable items

### 3. Pattern Established
- **Object ownership:** Objects declare burnability in FSM metadata
- **Engine role:** Reads and executes timer behavior, no special burning logic needed
- **Content creators:** Must consider burnability when designing ANY new object
- **Design implications:** Fire creates consequences and emergent gameplay

## User Directives Implemented
✅ READ verb for skill granting + burnable manuals (2026-03-20T21:13Z)
✅ Burnable objects as universal property (2026-03-20T21:08Z)

## Architecture Impact
- **Consistency:** Skill-granting is now read-based, not pickup-based (more immersive)
- **Consequences:** Burning valuable items before reading them creates meaningful choices
- **Extensibility:** Pattern applies to all knowledge objects (grimoires, maps, recipes, etc.)
- **Fire integration:** Completes the fire system (matches, candles, now any object can burn)

## Files/Artifacts Created
- `docs/objects/sewing-manual.md` — FSM reference, skill integration, burnability
- Pattern documentation for universal burnability system
- Reference for object authors on how to tag burnable objects

## Design Decisions Documented
1. **Skill on READ, not pickup:** More immersive, creates consequence if manual burns
2. **Burning emits light:** Any burning object becomes temporary light source
3. **Per-object FSM:** Burnability lives in object's .lua meta, engine just executes
4. **Consumed pattern:** Burned objects are destroyed, not replaced with ash
5. **Permanent loss:** Unread manual that burns = skill permanently lost for this run

## Next Steps
- Content creators integrate burnability to all flammable objects
- Implement READ verb handler (if not already done)
- Test burning manuals and skill loss scenarios
- Add chain-reaction fire system (optional, future)
