# Nelson — Pass-003 Bug Report
**Date:** 2026-03-20
**Build:** Current HEAD
**Pass:** test-pass/2026-03-20-pass-003.md

## Bugs Found

### BUG-015: Wardrobe container shows internal IDs instead of display names
- **Severity:** Minor
- **Input:** `look at wardrobe` (when open)
- **Expected:** "Hanging inside: a moth-eaten wool cloak, a burlap sack"
- **Actual:** "Hanging inside: wool-cloak, sack"
- **Note:** Same class of bug as BUG-010 (fixed for nightstand) but persists in wardrobe container. Needs `on_look(self, registry)` pattern applied to wardrobe.

### BUG-016: "put X on head" not recognized for wear slot
- **Severity:** Minor
- **Input:** `put sack on head`
- **Expected:** Equivalent to `wear sack`
- **Actual:** "You don't see head here."
- **Note:** Parser treats "head" as a room object. `wear sack` works fine.

### BUG-017: Replacing drawer DESTROYS nightstand surface objects
- **Severity:** Critical
- **Input:** `pull drawer` → `put drawer in nightstand`
- **Expected:** Objects on nightstand surface (candle, bottle) survive reattachment
- **Actual:** Lit candle and poison bottle are DELETED. Room goes dark. Objects unrecoverable.
- **Root Cause:** Nightstand FSM state transition likely wipes `on_surface` children when returning to "has drawer" state. The new composite object needs to preserve surface contents through part reattachment.

### BUG-018: "kick" parsed as "lick"
- **Severity:** Minor
- **Input:** `kick wardrobe`
- **Expected:** "I don't understand that" or kick response
- **Actual:** "You give a heavy wardrobe a cautious lick."
- **Root Cause:** Tier 2 fuzzy matching — 1-char edit distance between "kick" and "lick". Threshold too low for short words.

### BUG-019: Internal FSM state label leaks into player text
- **Severity:** Cosmetic
- **Input:** `move nightstand` / `put key on nightstand`
- **Expected:** Clean object name without state suffix
- **Actual:** Object name includes "(drawer open)" state label
- **Fix:** Strip FSM state suffix from display name in player-facing messages.

### BUG-020: Lowercase/inconsistent "no room" message
- **Severity:** Cosmetic
- **Input:** `put matchbox on bed`
- **Actual:** "there is not enough room" (lowercase, generic)
- **Fix:** Capitalize and make specific: "There is not enough room on the bed."

### BUG-021: Parser startup debug line without --debug flag
- **Severity:** Cosmetic
- **Input:** Start game with `lua src/main.lua`
- **Actual:** `[Parser] Tier 2 loaded: 4337 phrases from index` shown on startup
- **Fix:** Guard startup message behind `--debug` flag like per-command diagnostics.

### BUG-022: "Play again?" doesn't restart
- **Severity:** Minor
- **Input:** Die from poison → "Play again?" → `y`
- **Actual:** "Restart the game to play again." then exits
- **Fix:** Either implement restart or change prompt to "Press any key to exit."

## Priority Ranking
1. **BUG-017** — Critical. Game-breaking data loss. Fix before next playtest.
2. **BUG-018** — Minor but embarrassing. "kick" → "lick" will confuse players.
3. **BUG-015** — Minor. Same fix pattern as BUG-010, just needs applying to wardrobe.
4. **BUG-019** — Cosmetic. State labels in player text.
5. Others — Low priority cosmetic/polish.
