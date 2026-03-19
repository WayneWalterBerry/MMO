### 2026-03-19T125825Z: User directive — Two-Hand Inventory + Bags
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Players have TWO HANDS. That's their base inventory — they can carry/hold two items max. However:
- A BAG (held in one hand) expands capacity — bag contents don't count against hand slots, but the bag itself takes one hand
- A BACKPACK (worn on back) frees BOTH hands — backpack contents available without using hand slots
- TOOL USAGE REQUIRES HANDS. To strike a match on a matchbox, you need BOTH hands free (one for match, one for matchbox). If you're holding a bag, you must DROP BAG first.
- This creates real inventory management puzzles:
  - Carrying a bag + sword = no free hands = can't light match
  - Drop bag → strike match → light candle → pick up bag
  - Wearing a backpack = hands free for tool use
  - Backpack is a major upgrade item (not available in bedroom?)

**Implications:**
- Player state needs: hands[] (array of 2 slots) + worn[] (backpack slot) + bag contents
- Items need a `held_in` property: "hand", "bag", "backpack", "worn"
- Compound tool actions check: are both hands available?
- DROP becomes strategically important (not just discarding)
- Bags and backpacks are containers the player carries
- The sack in the bedroom could be the first bag!

**Puzzle depth this creates:**
- Dark room: you're holding the bed sheet. Drop sheet → open drawer → take match → take matchbox → strike match → light candle. That's 6 actions just to get light. Real gameplay.
- Trade-offs: carry the knife (protection) or the candle (light)? Can't hold both + a bag.

**Why:** User request — major inventory mechanic. Transforms inventory from "magic pocket" to physical constraint. Every item held is a choice. Every compound tool action requires hand management.
