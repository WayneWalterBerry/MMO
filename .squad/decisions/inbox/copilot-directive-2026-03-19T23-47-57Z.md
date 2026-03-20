### 2026-03-19T23:47:57Z: User directive
**By:** Wayne "Effe" Berry (via Copilot)
**What:** The following objects all need FSM definitions embedded in their object files (per the FSM-inline directive): poison bottle, candle, nightstand, and vanity mirror. The vanity mirror also needs its separate state files collapsed into one file. Each object = one file with its FSM inline. Specifically:
- **Poison bottle** — needs states (sealed → open → empty? or poison effects?)
- **Candle** — needs states (unlit → lit → stub → spent, per CBG's design: 100 turns lit, 20 turns stub)
- **Nightstand** — already has FSM but in separate file; merge into object file, delete src/meta/fsms/nightstand.lua
- **Vanity mirror** — collapse all state files into one object file with inline FSM (intact → cracked → broken?)
- **Curtains** — needs inline FSM (closed → open, controls light from window)
**Why:** User request — these are the next objects to get the FSM treatment. Consistent with the "one file = one object = one FSM" architecture directive.
