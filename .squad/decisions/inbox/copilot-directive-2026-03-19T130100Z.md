### 2026-03-19T130100Z: Architecture question — Verbs as Meta-Code
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Wayne wonders if verbs should be defined in src/meta/verbs/ (as Lua data files) rather than hardcoded in src/engine/verbs/init.lua. This would make verbs part of the world definition, not the engine. Each verb = a .lua file returning a table with handler, aliases, prerequisites. Engine just loads and dispatches. Verbs become mutable — a cursed room could change how LOOK works. New verbs = new files, no engine changes. Aligns with "code IS the world" philosophy.
**Status:** Open question — Wayne exploring, not directing yet. Needs Bart (Architect) analysis.
**Why:** Architectural consistency. If objects are meta-code, why aren't verbs? Could enable room-specific verbs, mutable actions, per-universe verb sets.
