### 2026-03-19T123739Z: User directive
**By:** Wayne "Effe" Berry (via Copilot)
**What:** File-per-state is the chosen object model. Keep separate .lua files for each object state (nightstand.lua + nightstand-open.lua, candle.lua + candle-lit.lua, etc.). This resolves the open question from D-35. Wayne considered single-file-with-states but prefers the current pattern. Each state is a complete, self-contained object definition. Mutation = swap the entire file.
**Why:** User decision — resolves architecture question. File-per-state stays. No refactoring needed.
