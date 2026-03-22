### 2026-03-22T12:31: User directive — Search engine as separate module
**By:** Wayne (Effe) Berry (via Copilot)
**What:** The search/find traverse system should be a separate engine module (`src/engine/search/`), not inline in verbs/init.lua. Same pattern as injuries.lua and traverse_effects.lua — standalone, clean, testable. Verb handlers stay thin and delegate to the search module.
**Why:** Engineering discipline — search traverse is complex enough to warrant its own module with sub-components (traverse, containers, narration, goals)
