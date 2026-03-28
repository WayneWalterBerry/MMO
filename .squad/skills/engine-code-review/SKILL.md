---
name: "engine-code-review"
description: "Senior engineer code review of engine .lua files — identify runaway files, recommend splits, find test gaps, then TDD-first refactor"
domain: "engineering, refactoring, code quality"
confidence: "high"
source: "earned — March 25 P0-A engine code review (verbs/init.lua 5,884→12 modules, zero regressions)"
---

## Context

When engine code has been growing organically across many sessions and multiple agents contributing, .lua files can become runaways — monoliths that are too large for efficient LLM editing, hard to test in isolation, and risky to modify. This skill defines the pattern Wayne established: periodic senior engineer code review → TDD safety net → refactor → verify.

**Primary goal: LLM editability.** The reason we split files is so LLM agents can modify them most easily. The Coordinator decides which files to split based on Bart's review — no human approval needed for the split list. The guiding question is always: "Will this split make it easier for an LLM agent to read, understand, and edit this code?" If yes, split. If the file is already manageable for an LLM context window, leave it alone.

Applies when:
- Any engine file exceeds ~500 lines
- Multiple agents are frequently editing the same file (contention signal)
- Wayne asks to "review the engine code" or "check for runaway files"
- Before a major new feature that will add significant code to existing modules
- After a sprint of bug fixes that may have bloated files

## Patterns

### 1. Senior Code Review Phase (Bart)

Bart reviews ALL engine files, focusing on:
- **Size audit:** List every file >500 lines with line counts, sorted descending
- **Logical divides:** Identify natural split points (verb categories, subsystem boundaries, data vs logic)
- **LLM impact analysis:** Would splitting help or hurt LLM agents? (30 small files vs 5 medium ones)
- **Test gap inventory:** Which sections have zero test coverage?
- **Dependency graph:** What requires what? Which splits are safe vs risky?

**Deliverable:** `docs/architecture/engine/refactoring-review.md` — the full analysis with recommendations

### 2. Pre-Refactor Test Baseline (Nelson)

BEFORE any refactoring begins:
- Nelson runs the full test suite and records exact pass/fail counts
- Nelson identifies HIGH-RISK verb handlers or modules with LOW or NO test coverage
- Nelson writes NEW tests for the at-risk areas (TDD-first — tests before refactor)
- This creates the safety net that guarantees refactoring is behavior-preserving

**Critical rule:** No refactoring starts until the test baseline is established and new coverage tests pass.

### 3. Execute Refactor (Bart)

The actual split uses a **register pattern** (proven on verbs/init.lua):
- Parent file becomes a thin loader that requires category modules
- Each module exports a table of handlers via `return { handler1 = fn, handler2 = fn }`
- Parent calls `register(require("path.to.module"))` to wire them in
- No behavior changes — only file organization changes

**Key decisions from the verbs/init.lua refactor:**
- Split by category (movement, examination, inventory, combat, etc.) not per-verb
- Keep helpers in a shared `helpers.lua` that all modules can require
- Use `gpt-5.2-codex` model for large multi-file refactors (500+ lines)

### 4. Post-Refactor Verification (Nelson)

After refactoring:
- Run the EXACT same test suite from step 2
- Assert: same pass count, same fail count, zero new failures
- Any new failure = the refactor broke behavior → revert and investigate
- Report: "{N} assertions, {M} files, zero regressions"

### 5. Sequencing with Other Work

The March 25 session established this sequencing:
- Code review runs FIRST (before meta-compiler or new features)
- Refactoring changes file paths → any tool that validates paths must run AFTER
- TDD approach: Nelson writes tests FIRST, then refactoring proceeds safely
- New features (NPC, combat) should be built on the REFACTORED structure

## Examples

**Reference implementation:** March 25, 2026 — P0-A Engine Code Review

| Phase | Agent | Deliverable | Result |
|-------|-------|-------------|--------|
| Review | Bart | `docs/architecture/engine/refactoring-review.md` (414 lines) | verbs/init.lua flagged at 5,884 lines |
| Baseline | Nelson | 172 pre-refactor tests | Safety net established |
| Refactor | Bart (gpt-5.2-codex) | 5,884 lines → 12 modules + registry | `register(handlers)` pattern |
| Verify | Nelson | 2,670 assertions | Zero regressions |

**Result:** 74-84% LLM context reduction per verb handler edit. Every agent now only loads the specific verb category file they're editing.

**Orchestration log:** `.squad/orchestration-log/2026-03-24T16-25-00Z-bart-p0a.md`

## Anti-Patterns

- **Don't refactor without tests first** — the March 25 refactor succeeded because Nelson wrote 172 tests BEFORE Bart touched a line of code
- **Don't split per-function** — split by category/subsystem. Too many tiny files hurts LLM context switching more than one medium file
- **Don't change behavior during a refactor** — a refactor is ONLY file reorganization. If you need to fix bugs, do that in a separate commit
- **Don't skip the verification step** — even if "nothing changed," run the full suite. The March 25 refactor passed 2,670 assertions — that confidence was earned, not assumed
- **Don't refactor files that are actively being written** — wait for the feature to land, then review. Refactoring mid-implementation causes merge conflicts
- **Don't let the original author verify their own refactor** — Nelson (independent QA) verified Bart's refactor, not Bart himself
