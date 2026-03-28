# Brockman — Documentation Specialist

**Role:** Maintain design docs, architecture documentation, decision logs, team communications.

## Core Context (Essential)

**Owner:** Wayne "Effe" Berry  
**Project:** MMO (Lua text adventure, 14-agent Squad)  

**Responsibilities:**
- Design documentation (gameplay mechanics, player systems)
- Architecture documentation (engine internals, technical patterns)
- Decision logging (squad process, architecture choices)
- Team communications (Newspaper, announcements)

**Current Status:** Phase 4 WAVE-5 design docs complete (crafting, stress, ecology). Testing docs created. Documentation-first culture established.

## Key Decisions Authored

- **D-BROCKMAN001:** Design vs. Architecture separation (gameplay in docs/design/, engine in docs/architecture/)
- **D-BROCKMAN002:** Documentation-first directive (docs source of truth before code review)
- **D-HEADLESS:** Headless testing mode documentation (--headless for CI/LLM automation)
- **D-TESTFIRST:** Test-first directive (every bug fix includes regression tests)

## Documentation Systems Maintained

| System | Status | Coverage |
|--------|--------|----------|
| Design Docs | ✅ Active | 11 files: food, cure, crafting, stress, ecology, creature death, loot tables, butchery |
| Architecture Docs | ✅ Active | 6 files: engine subsystems, FSM, effects pipeline, creature systems |
| Vocabulary | ✅ Active | 200+ terms across 6 categories; v1.3 synchronized with codebase |
| Decision Log | ✅ Active | decisions.md (canonical source); inbox workflow established |
| Newspaper | 🟡 On Hold | Per D-NO-NEWSPAPER-PENDING directive (resume Phase 5) |
| Testing Docs | ✅ Complete | Framework, patterns, directory structure, pre-deploy gates |
| Mutation-Graph Linting Docs | ✅ Complete | docs/testing/mutation-graph-linting.md + motivation section (WAVE-2) |

## Key Deliverables

### WAVE-2 Mutation Graph Linter Documentation (2026-08-23)

- **Deliverable 1:** `docs/testing/mutation-graph-linting.md` — comprehensive user guide (85+ lines)
  - Motivation section (why expand-and-lint instead of custom Lua graph library)
  - Installation + setup (Python 3.9+, verify PATH)
  - Quick start (run mutation-lint.ps1 / mutation-lint.sh)
  - JSON output mode (--json flag reference)
  - Understanding broken edges (5 types, edge list format)
  - GitHub issues workflow (broken edge triage)
  - CI integration (squad-ci.yml, pre-deploy gate)

- **Deliverable 2:** `.squad/skills/mutation-graph-lint/SKILL.md` — skill file for squad registry
  - Skill name: `mutation-graph-lint`
  - Invocation: `--json` output mode specification
  - Use case: scripted tooling integration + CI gates

- **Deliverable 3:** Updated `plans/linter/mutation-graph-linter-implementation-phase1.md` status tracker
  - All 3 waves marked ✅ Complete
  - Both gates marked ✅ Pass

- **Session commit:** c69bc65 (docs: WAVE-2 mutation-graph linting documentation)

## Archives

**history-archive-2026-03-20T22-40Z-brockman.md** — Full archive (2026-03-18 to 2026-03-20T22:40Z)

---

**For detailed session history, see history-archive.md**
