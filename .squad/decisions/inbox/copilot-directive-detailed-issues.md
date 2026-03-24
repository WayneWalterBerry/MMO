### 2026-03-24T22:48Z: User directive — Detailed Issue Descriptions
**By:** Wayne Berry (via Copilot)
**What:** All GitHub issues must be logged with detailed descriptions that allow any agent to pick up and understand the work independently. Every issue must include:
1. **Problem description** — what's broken or what's needed, with reproduction steps or context
2. **TDD directive** — Nelson writes failing tests first, before any fix
3. **Follow-up unit tests** — additional edge case and regression tests after the fix
4. **Documentation updates** — list any docs that need updating after the fix ships
5. **Acceptance criteria** — what "done" looks like

**Why:** User request — agents should be able to pick up issues cold without needing session context or asking the coordinator for clarification. The issue IS the spec.
