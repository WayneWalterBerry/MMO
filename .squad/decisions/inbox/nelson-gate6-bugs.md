# Nelson — Gate6 Combat Bugs (2026-03-26)

## CRITICAL: Duplicate Trapdoor Blocks All Cellar Access

**Affects:** Bart (engine), Moe (room definitions), Flanders (trapdoor object)
**Severity:** CRITICAL — blocks ALL combat testing and cellar access

### Bug Description

When the player executes `pull rug` in the bedroom, the engine spawns a NEW trapdoor object but does NOT remove or update the original hidden trapdoor. This creates two trapdoor objects in the room:

1. Original trapdoor (state: hidden, won't budge)
2. Newly revealed trapdoor (state: openable via "pull iron ring")

Even after "pull iron ring" opens the revealed trapdoor, the `down` exit remains blocked because the exit check resolves to the OLD hidden trapdoor.

### Reproduction
```
move bed → pull rug → pull iron ring → down
```
Result: "a trap door blocks your path" (despite trapdoor visibly open in room description)

### Impact
- ALL 4 gate6 combat scenarios FAIL
- Player is permanently trapped in bedroom
- Combat system is completely untestable
- Freeform playthroughs cannot reach the cellar

### Recommendation
The `pull rug` mutation should either:
- Update the existing trapdoor's state from hidden→closed (instead of spawning a new one), OR
- Remove the old trapdoor and replace with the revealed one, OR
- The exit check should look for ANY open trapdoor, not just the first one found

### Secondary Issues
- Gate6 scenario scripts use `take candle holder` (should be `take candle`)
- Gate6 scenario scripts are missing the `move bed → pull rug → pull iron ring` sequence
- "punch rat" when rat not in scope says "You can only hit yourself right now" — should say target not found
