# Bart — Phase 4 Plan v1.1: All Review Blockers Fixed

**Author:** Bart (Architecture Lead)  
**Date:** 2026-08-20  
**Scope:** `plans/npc-combat/npc-combat-implementation-phase4.md` v1.0 → v1.1  
**Triggered by:** 6 reviewer reports (Moe, Marge, Chalmers, CBG, Flanders, Smithers)

---

## Summary

19 blockers resolved across 6 reviews. Plan bumped to v1.1. Key architectural decisions made:

---

## Decisions Made

### D-PHASE4-STRESS-THRESHOLDS
**Decision:** Raise stress thresholds to 3/6/10 (was 1/3/5). Remove first-kill trigger. Reduce overwhelmed debuffs to -2 atk/+30% flee/20% move (was -4/+50%/50%).  
**Rationale:** CBG review showed single wolf kill would cripple player. Victory should reward, not punish. Stress accumulates gradually through repeated exposure.  
**Affects:** Flanders (stress.lua), Nelson (stress tests), CBG (balance validation).

### D-PHASE4-WEB-OBSTACLE
**Decision:** Spider webs are NPC movement obstacles, not size-based traps. No size system, escape difficulty, or trap state machine.  
**Rationale:** CBG review: size-based trap mechanics are premature for Level 1. Web-as-obstacle still enables emergent spider ecology (spider herds prey) without trap complexity.  
**Affects:** Flanders (spider-web.lua), Bart (create_object engine), Nelson (web tests).

### D-PHASE4-PACK-SIMPLIFIED
**Decision:** Pack tactics simplified to stagger attacks + individual wolf AI. Full alpha/beta/omega zone-targeting deferred to Phase 5.  
**Rationale:** CBG review: 2-wolf encounters are rare in Level 1. Zone-targeting requires combat engine changes. Individual wolf AI (defensive retreat, ambush, smart positioning) provides better per-encounter gameplay.  
**Affects:** Bart (pack.lua), Nelson (pack tests).

### D-PHASE4-CRAFT-TIER1
**Decision:** Phase 4 crafting uses Tier 1 recipe-ID dispatch (`craft silk-rope`). English syntax `craft X from Y` deferred to Phase 5.  
**Rationale:** Smithers review: compound noun syntax requires Tier 3 GOAP or Tier 2 phrase explosion. Recipe-ID is simplest, fits existing parser.  
**Affects:** Smithers (craft verb), parser/embedding index.

### D-PHASE4-SILK-ROPE-USE
**Decision:** Silk-rope must have immediate Level 1 use-case (courtyard well puzzle: `tie rope to hook`). Spider ecology becomes non-optional.  
**Rationale:** CBG review: without immediate use, players never craft silk again. Rope must have gameplay value in Level 1, not just Phase 5.  
**Affects:** Sideshow Bob (puzzle design), Flanders (silk-rope.lua), Moe (courtyard integration).

### D-PHASE4-SILK-BANDAGE-DUAL
**Decision:** Silk-bandage is dual-purpose: +5 HP instant AND stops active bleeding injury tick. Single-use, usable in combat.  
**Rationale:** Flanders review: clarifies injury system interaction. Bandage now differentiates from food (food = nutrition, bandage = healing + bleeding cure).  
**Affects:** Flanders (silk-bandage.lua), Nelson (bandage tests).

### D-PHASE4-NARRATION-PIPELINE
**Decision:** Smithers + Bart design narration pipeline in WAVE-0. Interface: `ctx.narrate(source, type, message)`. Document in `docs/architecture/ui/narration-pipeline.md`. Must be signed off before WAVE-3.  
**Rationale:** Smithers review: 5 narration sources in Phase 4 with no unified pipeline.  
**Affects:** Smithers (narration-pipeline.md), Bart (engine integration), Brockman (docs).

### D-PHASE4-TERRITORY-BFS
**Decision:** Territorial marking radius = exit-graph hops (BFS). territory-marker is invisible room object, not room metadata.  
**Rationale:** Flanders review: "radius" was undefined in graph-based topology. BFS on exit graph is deterministic and testable.  
**Affects:** Bart (territorial.lua), Flanders (territory-marker.lua), Moe (room topology verification).

### D-PHASE4-WEAPON-META-W4
**Decision:** Weapon combat metadata moved from WAVE-5 to WAVE-4 (Smithers parallel track).  
**Rationale:** Marge review: WAVE-5 had convergence bottleneck (3 agents blocked simultaneously). Moving weapon metadata to W4 reduces W5 load.  
**Affects:** Smithers (candlestick.lua, fire-poker.lua), conflict matrix.

### D-PHASE4-REGRESSION-BASELINE
**Decision:** Every gate includes Phase 3 regression check. PHASE-3-FINAL-COUNT baseline measured in GATE-0.  
**Rationale:** Marge/Chalmers review: no mechanism to detect Phase 3 regressions between waves.  
**Affects:** Nelson (test runner), all gate criteria.

---

## Files Changed

- `plans/npc-combat/npc-combat-implementation-phase4.md` — v1.0 → v1.1 (19 blockers fixed)

---

**Signed:** Bart (Architecture Lead)  
**Date:** 2026-08-20
