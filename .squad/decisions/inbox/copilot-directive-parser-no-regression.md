### 2026-03-25T18:38Z: User directive
**By:** Wayne Berry (via Copilot)
**What:** "Let's not go backwards with the parser." All parser/embedding changes MUST pass the 70-case Tier 2 benchmark at 100% accuracy. No regressions allowed. Run `lua test/parser/test-tier2-benchmark.lua` before and after any parser changes.
**Why:** User request — the parser was painstakingly brought from 78% to 100% over 3 phases. Protecting that investment is non-negotiable.