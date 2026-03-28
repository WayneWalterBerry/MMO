# Orchestration Log: smithers-review

**Timestamp:** 2026-03-28T22:25:46Z  
**Agent:** Smithers (UI Engineer / Parser Pipeline)  
**Task:** Review output formatting + CLI UX for mutation-graph-linter  
**Mode:** background (claude-opus-4.6)

## Outcome

🔴 **Blockers Found (2) + Recommendations (14)**

### Critical Blockers

**Blocker 1: JSON Schema Undefined**
- Plan lists `--json` flag but provides no schema specification
- Without schema, implementation will invent format and tests will reverse-engineer it
- **Fix:** Define JSON schema explicitly in CLI spec before Bart implements

**Blocker 2: Parallel Output Interleaving**
- Wrapper script runs edge check + Python lint in parallel
- Parallel lint workers (4+ threads) write to stdout simultaneously
- Output will be unreadable jumble (edges interleaved with file lint results)
- **Fix:** Collect per-file output, then print sequentially; add phase headers

### Recommendations (14)

**Output Format (4):**
1. Replace `⚡` symbol with `⚠` or `[DYNAMIC]` (symbol vocabulary consistency)
2. Drop 2-space indent on stat block (matches linter style)
3. Define exact stderr format for `--targets-only` mode (use `WARNING:` prefix)
4. Add "✓ All mutation edges resolve" success line (positive confirmation)

**CLI Consistency (3):**
5. Consider `--targets` vs `--targets-only` (shorter, Lua convention)
6. Document `--json` vs `--targets-only` mutual exclusivity
7. Consider `--format {text,json,targets}` unified flag (match lint.py)

**Error Messaging (3):**
8. Include source file path in broken edge output (developer UX)
9. Verb name as locator is good — no change needed
10. Issue template is excellent — approved as-is

**UX Improvements (3):**
11. Add `--quiet` flag for CI/pre-deploy (exit code only, no report)
12. Collect parallel output before printing (readability fix)
13. Add section headers separating phases (Phase 1: Edge Check, Phase 2: Lint)

**Remaining (1):**
14. test/meta/ directory safe from parser conflict — no change needed

### Deliverables

- UI review written to inbox (2 blockers, 14 recommendations, severity table)
- Recommendations ranged: High (2), Medium (4), Low (8)
- Smithers verdict: Plan is architecturally sound but needs 2 blockers fixed before implementation

---

*— Scribe, 2026-03-28T22:25:46Z*
