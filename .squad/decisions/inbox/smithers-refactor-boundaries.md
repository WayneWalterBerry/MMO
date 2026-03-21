# D-REFACTOR: UI/Parser/Engine Separation Boundaries

**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-23  
**Status:** Implemented (Partial)  

## Decision

Separated the engine into clean ownership zones so Smithers (UI/Parser) and Bart (Engine) can work on code simultaneously without merge conflicts.

### New Module Boundaries

1. **`engine/parser/preprocess.lua`** — Smithers owns exclusively. All NLP pattern matching and basic input parsing lives here. Bart should never need to touch this.

2. **`engine/ui/presentation.lua`** — Smithers owns exclusively. All presentation-facing queries (time formatting, light level calculation, vision checks) live here. This is the **single source of truth** for time constants (`GAME_SECONDS_PER_REAL_SECOND=24`, `GAME_START_HOUR=2`, `DAYTIME_START=6`, `DAYTIME_END=18`). Both `verbs/init.lua` and `ui/status.lua` import from here.

3. **`engine/ui/status.lua`** — Smithers owns exclusively. Status bar formatting.

### Rules Going Forward

- **Adding NLP patterns**: Edit `parser/preprocess.lua` only (Smithers)
- **Changing time constants**: Edit `ui/presentation.lua` only (affects all consumers)
- **Adding presentation helpers**: Add to `ui/presentation.lua` (Smithers)
- **Adding verb handlers**: Edit `verbs/init.lua` (Bart for logic, Smithers for text — coordinate)
- **Changing the game loop**: `loop/init.lua` top half is Smithers (parse pipeline), bottom half is Bart (tick phase)

### What's Still Shared

`verbs/init.lua` remains a shared file (~4500 lines). Individual verb handlers mix presentation and game logic. A future refactor could introduce a verb-result protocol, but the risk is too high for now.

### DRY Fixes

Eliminated 4 constant/function duplications between `main.lua`, `verbs/init.lua`, and the new modules.
