# Decision: Phase 3 Plan v1.4 — All 6-Reviewer Blocker Fixes

**Author:** Bart (Architect)
**Date:** 2026-08-17
**Affects:** Brockman, Moe, Smithers, Flanders, Nelson, Marge
**Plan:** `plans/npc-combat/npc-combat-implementation-phase3.md`
**Version:** v1.3 → v1.4

---

## Context

All 6 reviewers (CBG, Chalmers, Flanders, Smithers, Moe, Marge) conditionally approved Phase 3 v1.3 with blockers. Wayne directed Bart to fix all blockers and bump to v1.4.

## Decisions Made

### D-PHASE3-WAVE0-DOCS (Critical — All 6 reviewers)

**Decision:** Architecture docs moved from WAVE-5 to WAVE-0. Brockman writes `creature-death-reshape.md` and `creature-inventory.md` as GATE-0 deliverables. Bart reviews for accuracy before sign-off.

**Rationale:** Wayne directive: "All affected architecture docs in `docs/architecture/` must be updated in WAVE-0 before proceeding to WAVE-1." Code implements against documented architecture, not the other way around.

**Impact:**
- Brockman: New WAVE-0 assignment (~2-3 hours)
- Bart: 30-min doc review added to WAVE-0
- GATE-0: 3 new checkboxes (2 docs + review sign-off)
- WAVE-5: Brockman scope narrowed to design docs only (food-system.md, cure-system.md)

### D-PHASE3-RESHAPE-NARRATION (Smithers blocker)

**Decision:** Added optional `reshape_narration` field to `death_state` spec. Silent by default (player discovers on next `look`). Flanders decides per-creature whether to include dramatic narration.

**Rationale:** Reduces combat narration spam while allowing dramatic moments for interesting creatures.

### D-PHASE3-COMBAT-SOUND-API (Smithers blocker)

**Decision:** Specified `emit_combat_sound(room, intensity, witness_text)` API in `combat/narration.lua`. Three distance tiers: same room (covered by combat narration), adjacent (direction-resolved text), 2+ exits (no propagation). Smithers owns narration templates, Bart owns engine emission.

### D-PHASE3-BRAZIER-TIMING (Moe blocker)

**Decision:** Cellar brazier assigned — Flanders creates `cellar-brazier.lua` object in WAVE-3, Moe updates `cellar.lua` room with brazier instance in WAVE-3. Fire source available for cook verb testing.

### D-PHASE3-HOME-ROOM-VERIFY (Moe recommendation)

**Decision:** Moe pre-flight verification added before WAVE-5: verify all 5 home_room IDs (cellar, courtyard, hallway, deep-cellar, crypt) exist. Create missing rooms if needed.

### D-PHASE3-STRESS-CLEANUP (Consistency)

**Decision:** Removed stale stress.lua references from dependency graph and conflict matrix. Stress was deferred to Phase 4 per Q5 but references persisted in v1.3.

---

## Status

**Plan v1.4:** ✅ APPROVED — Ready for implementation
**All 6 reviewer conditions:** Resolved
**Next step:** Begin WAVE-0 execution
