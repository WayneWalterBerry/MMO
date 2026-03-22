# Report Bug

> Report a bug or issue in the game.

## Synonyms
- `report bug` — Report a bug
- `report` — Report something (context: bug)

## Sensory Mode
- **Works anywhere?** ✅ Yes
- **Light requirement:** None

## Syntax
- `report bug` — Report a bug (opens issue reporting interface)
- `report [description]` — Report with description (if supported)

## Behavior
- **GitHub integration:** Opens GitHub issue in browser or creates issue
- **Template:** Pre-filled with game state info (if available)
- **State capture:** May include current room, inventory, game time
- **External action:** Opens browser or API call to GitHub

## Design Notes
- **Developer tool:** Meta-command for gameplay feedback
- **Integration:** Connects gameplay directly to issue tracking
- **Bug reporting:** Low-friction bug report creation from within game

## Related Documentation
- **[decisions.md](../../.squad/decisions.md)** — Squad decision log where bugs are tracked

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["report_bug"]`
- **Ownership:** Smithers (UI Engineer) — GitHub integration
