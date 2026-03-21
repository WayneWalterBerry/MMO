# Nelson — Puzzle Feedback for Bob (Pass 010)

**Date:** 2026-03-21
**Pass:** 010
**Focus:** Bug fix verification + full playthrough

## Puzzle Experience Rating: ★★★★½ (4.5/5)

## What Works Brilliantly

### GOAP Spent-Match Handling (BUG-035/101 Fix)
This is now the game's best moment. After your first match burns out and you type "light candle", the system auto-plans: drop spent → get fresh → strike → light candle. The "You'll need to prepare first..." message followed by the seamless chain is *incredibly* satisfying. It feels like the game reads your mind. Bart nailed this.

### Pour vs Drink (BUG-102 Fix)
"pour bottle" correctly triggers pour, not drink. This is critical for puzzle design — a player choosing to pour poison vs drink it is making a real decision. The verb_hint system works perfectly here.

### Candle Timer Urgency
The candle dying right as I pulled the rug was perfect dramatic timing. It forces real decisions about what to explore while light lasts. Brilliant emergent gameplay.

### Sensory Atmosphere
The smell system especially ("You'd rather not" for the chamber pot, "the honest smell of sheep and hearth" for the blanket) adds enormous personality. This is what separates a good text game from a great one.

## Suggestions for Future Puzzles

1. **Spent Match Display** — Room clutters with "There is a spent match here" ×3+. Suggest grouped display: "Three spent matches lie scattered on the floor."

2. **"light match" GOAP Awareness** — Currently "light match" while holding a spent match gives "You can't light a spent match" instead of auto-swapping. Only goal-level commands ("light candle") trigger GOAP. Players may find this inconsistent. Consider making "light match" GOAP-aware too.

3. **Cellar Light Source** — Torch bracket exists but can't be used yet. Room 3 will need this. Consider: player finds oil/cloth in cellar → makes torch → persistent light for deeper exploration.

4. **Multiple Spent Matches in Matchbox** — During GOAP chains, spent matches get dropped to the floor (good). But if a player manually puts a spent match back in the matchbox, it could confuse future "get match" commands. The `is_spent_or_terminal()` check should handle this, but worth monitoring.

## Bottom Line
The bedroom escape is polished and atmospheric. All 5 fixes land cleanly. GOAP spent-match handling is the standout — it transforms frustration into delight. Ready for Room 3 content.
