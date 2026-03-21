# Decision: Parser Unit Test Framework

**Author:** Bart (Architect)  
**Date:** 2026-03-21  
**Status:** Implemented  
**Affects:** test/, deployment pipeline

## Context

Wayne found a context retention bug during gameplay: after "search wardrobe", a bare "open" command should target the wardrobe, but instead the engine says "Open what?" — it doesn't consult the `ctx.last_object` context.

This exposed the need for a repeatable, automated test suite for the parser pipeline that runs before every deployment.

## Decision

### D-TEST001: Pure-Lua test framework, no external dependencies

Tests use a minimal homegrown framework (`test/parser/test-helpers.lua`) with `test()`, `assert_eq()`, and `pcall`-based error isolation. No luarocks, busted, or other external test libraries required.

**Rationale:** The engine is pure Lua with zero external dependencies. The test framework should match that constraint. Adding a test dependency would complicate the build pipeline.

### D-TEST002: Tests gate deployment

`test/run-before-deploy.ps1` runs the test suite before `build-engine.ps1`. If any test fails, the build is blocked.

**Rationale:** Prevents shipping regressions. The context retention bug and BUG-049 are now permanently guarded.

### D-TEST003: Test files are isolated subprocesses

Each `test-*.lua` file runs as its own Lua process. Failures in one file don't cascade to others.

**Rationale:** Verb handler tests load the full engine module graph (FSM, containment, presentation). Isolating them prevents state leaks between test files.

### D-TEST004: Known bugs are documented as passing tests

The context retention bug test passes today (confirming the bug exists) with a clear comment explaining the desired behavior and what to change when the bug is fixed.

**Rationale:** Tests should never be "expected to fail." Instead, test the current behavior and document the fix path inline.

## Test Inventory (26 tests)

- **Preprocess** (22): parse splitting, natural language patterns, preamble stripping, verb aliases, edge cases
- **Context** (4): pronoun resolution, bare-noun context bug, crash protection, BUG-049 alias verification
