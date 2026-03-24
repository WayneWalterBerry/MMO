### 2026-03-24T07-34-02Z: User directive — TDD Before Refactoring
**By:** Wayne (via Copilot)
**What:** Before refactoring ANY engine code (splitting files, moving functions), we must follow TDD: write tests for the existing behavior FIRST, verify they pass, THEN refactor. The tests prove the refactor didn't break anything. No refactoring without a green test suite covering the code being moved.
**Why:** Refactoring without tests is how you introduce silent regressions. Tests are the safety net.
