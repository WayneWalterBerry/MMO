### 2026-03-24T08-52-50Z: User directive — meta-check is compiler + linter
**By:** Wayne (via Copilot)
**What:** meta-check must be BOTH a semantic analyzer (compiler front-end: parse, tokenize, validate structure/references/FSM) AND a linter (style conventions, naming patterns, field ordering, documentation requirements). Not just "is this valid Lua" or "is this a valid object" — also "does it follow our conventions?"
**Why:** LLMs writing objects need both correctness checks AND style enforcement. Lisa uses it as a quality gate.

### Open questions resolved:
- **Name:** meta-check
- **Language:** Python + Lark
- **Location:** scripts/meta-check/
- **Refactor vs meta-check:** Independent — run in parallel
- **Deploy first:** Yes — Gil deploys March 24 work before tomorrow starts
- **Pre-existing test failures:** File as issues, fix in P1
