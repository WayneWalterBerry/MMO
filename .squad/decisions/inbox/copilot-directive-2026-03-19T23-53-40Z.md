### 2026-03-19T23:53:40Z: User directive
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Nelson's play test reports go to `test-pass/` at the repo root (NOT in .squad/). Each file should show both sides of the interaction (input AND output) and be dated with pass numbers. Format: `test-pass/YYYY-MM-DD-pass-NNN.md`. The file should be a readable transcript of the full interactive session so Wayne can see exactly what the tester typed and what the game responded.
**Why:** User request -- play test transcripts are a product artifact, not squad internal state. They belong at the repo root where Wayne can review them easily.
