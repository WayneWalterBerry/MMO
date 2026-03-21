# Nelson — Deep Level 1 Puzzle Feedback (Pass 015)
**Date:** 2026-03-21  
**Source:** Deep exploration playtest of all 7 Level 1 rooms

---

## Overall Assessment

Level 1 is **excellent**. The writing is world-class. The puzzle design is sound. Five new bugs found, one HIGH severity (BUG-055: spent match stays in hand).

## Match Hand Slot Bug (BUG-055) — PRIORITY FIX

The spent match not being freed from the player's hand after burning out is the most impactful bug. It means:
1. After GOAP lights the candle, the player can't `take candle` (hand is blocked by spent match)
2. Player must manually `drop match` — but the game already said "You drop the blackened stub"
3. This makes the GOAP light chain feel broken even though it technically succeeds

**Recommendation:** When the match FSM transitions to `spent` state, the engine should remove it from the player's hand and place it in the room (or destroy it). The narrative already says "you drop it" — the game state should match.

## Plural Forms (BUG-056) — PARSER ENHANCEMENT

Room descriptions use plurals ("Torches burn...", "Portraits of stern-faced figures...") but the parser only matches singular object names. Players naturally type what they see. Consider:
- Adding a `plurals` keyword to object definitions
- Or auto-generating plural forms (append 's', handle 'es', etc.)
- Or matching "torches" to "torch" via fuzzy/stemming

## Candle Burn Time

The candle burns out after approximately 10 commands. This is VERY tight:
- Bedroom → Cellar → Storage Cellar takes ~8 commands minimum
- The candle dies in the storage cellar every time
- Player finishes deep cellar and reaches hallway in total darkness

This creates genuine tension but may frustrate new players. The oil lantern in the storage cellar is the intended second light source, but it needs oil (from the flask) to work. Consider:
- Extending candle burn to 15 commands (gives breathing room)
- OR making the lantern + oil flask puzzle more discoverable
- OR having a second candle somewhere (crypt has candle stubs but they may be too short)

## Courtyard Moonlight (BUG-051)

The courtyard should be outdoor-lit (moonlight). Currently treated as pitch dark. The feel/smell/listen systems work beautifully there, but `look` fails. This is a missed opportunity — the courtyard descriptions would be stunning if visible.

## Sarcophagus Targeting (BUG-052)

Five identical sarcophagi in the crypt. `push sarcophagus` opens the first one. But there's no way to specify "push second sarcophagus" or "push the one on the left." Consider:
- Numbering them ("first sarcophagus", "sarcophagus 1")
- Or giving each unique names/descriptions based on their effigies
- Or having only one be interactive (the rest are sealed/empty)

## Poison Bottle Death

Drinking the poison bottle produces a clean, dramatic death. The death system works. But:
- The skull-and-crossbones label is only visible when the candle is lit
- In the dark, a player who uncorks and drinks it has no warning
- Consider adding an on_smell warning ("Even through the cork, you detect something acrid and chemical. Dangerous.")
- **UPDATE:** on_smell DOES warn! "Something acrid and chemical. Dangerous." — excellent design.

## Storage Cellar Rat

The rat's feel description says "A heavy piece of furniture" (BUG-057). This is clearly a template fallback. The rat has good smell ("A rank, musky animal smell") and listen ("Scratching in the walls") but the feel text is broken.

---

## Summary of Recommendations

1. **FIX BUG-055 (HIGH):** Free hand slot when match burns out
2. **FIX BUG-057 (LOW):** Give rat a proper on_feel description
3. **FIX BUG-058 (MEDIUM):** Expose drawer `.inside` surface for feel verb
4. **CONSIDER BUG-056:** Plural form matching in parser
5. **CONSIDER:** Extend candle burn time or make lantern puzzle more discoverable
6. **CONSIDER:** Courtyard moonlight (BUG-051) for dramatic outdoor reveal
