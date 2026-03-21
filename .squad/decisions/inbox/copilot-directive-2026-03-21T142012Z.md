### 2026-03-21T14:20:12Z: Object and puzzle reuse across levels

**By:** Wayne "Effe" Berry (via Copilot)
**What:** Objects can be reused across levels (they're shared). Puzzles should NOT be reused across levels — unless they are refactored to "look" different. Each level's docs are organized in zero-padded subfolders (docs/levels/01/, docs/levels/02/) with rooms/ and puzzles/ subfolders per level. Objects stay in docs/objects/ since they're cross-level.
**Why:** User request — captured for team memory. Establishes the level documentation hierarchy.
