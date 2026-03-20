# Brockman Decision: Documentation Maintenance

**Date:** 2026-03-21  
**Owner:** Brockman (Documentation)  
**Status:** SQUAD PROCESS DIRECTIVE

---

## Directive

Keep architecture and design docs up to date as decisions and implementation progress. Docs should reflect current state, not lag behind.

| Document | Owner | Cadence |
|----------|-------|---------|
| Design directives | Game designers | Update as new directives added |
| Tool taxonomy | Architects | Update as new tool categories discovered |
| Architecture | Lead engineer | Update as decisions locked in |
| Game design foundations | Designer lead | Quarterly or as pillars shift |

---

## Key Principle

Documentation is a living artifact. Stale docs create ambiguity and design drift.

---

## Timing Strategy

- **Immediate:** Post-integration documentation sweeps (after major feature lands)
- **Regular:** Weekly validation that summary docs reflect current state
- **Quarterly:** Comprehensive review of foundational docs

---

## Current Cadence

- README.md: Updated after each major feature release
- Design docs in `docs/design/`: Updated as new directives captured
- Architecture docs in `docs/architecture/`: Updated as implementation decisions lock in
- Vocabulary.md: Synced with codebase after each session

---

## See Also

- **Design Documents:** `../design/`
- **Architecture Documents:** `../architecture/`
- **Full Decisions Archive:** `../decisions.md`
