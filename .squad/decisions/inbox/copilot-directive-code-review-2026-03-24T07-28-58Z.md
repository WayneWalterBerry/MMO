### 2026-03-24T07-28-58Z: User directive — Engine Code Review Before Everything
**By:** Wayne (via Copilot)
**What:** Tomorrow BEFORE everything else, do a senior engineering code review of the engine .lua files. Several files in subfolders are getting very large. Evaluate: should they be broken into separate files? Are there logical divides? Would splitting help or hurt LLMs writing them? Are there test opportunities for individual files? This is a standard refactoring review for long-running projects.
**Why:** Project maturity checkpoint — engine has grown significantly, need to assess technical debt before scaling further.
