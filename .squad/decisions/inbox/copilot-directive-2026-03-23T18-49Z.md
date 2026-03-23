### 2026-03-23T18:49Z: User directive
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Every bug fix MUST include a regression test that locks down the exact scenario. The nightstand search has broken 3+ times because fixes weren't locked with tests. From now on: no fix ships without a test that reproduces the original bug. If a bug comes back, that means the test was missing or insufficient — file a process bug alongside the code bug.
**Why:** Wayne keeps hitting the same nightstand search bug repeatedly. Regression tests are the only way to prevent this.
