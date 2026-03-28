### 2026-03-28T22:13: User directive
**By:** Wayne Berry (via Copilot)
**What:** Objects can be expanded and linted in parallel — the Lua edge extractor and Python meta-lint don't need to run serially. Each object's mutation targets can be expanded and linted concurrently, with outputs combined for the final report.
**Why:** User request — captured for team memory. Affects mutation-graph-linter design and implementation plan.
