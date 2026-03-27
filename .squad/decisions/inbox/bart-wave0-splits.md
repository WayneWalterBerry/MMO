# D-WAVE0-SPLITS — Phase 2 WAVE-0 Module Split Decisions

**Author:** Bart (Architecture Lead)
**Date:** 2026-08
**Branch:** squad/phase2-wave0-splits

## D-STIMULUS-MODULE

**Decision:** Stimulus queue management extracted to `src/engine/creatures/stimulus.lua`. The module owns the queue state and exposes `emit`, `clear`, `process`. Helper functions (get_location, get_room_distance) are injected via a helpers table — not duplicated.

**Affects:** Anyone calling `creatures.emit_stimulus()` or `creatures.clear_stimuli()` — public API unchanged. Internal consumers of stimulus processing should now go through `stimulus.process()`.

## D-PREDATOR-PREY-STUB

**Decision:** `src/engine/creatures/predator-prey.lua` created as a stub. No predator-prey code existed in Phase 1. WAVE-2 will populate `detect_prey`, `evaluate_source_filter`, `predator_reaction`.

**Affects:** Flanders (creature definitions needing diet/prey_tags), Comic Book Guy (game design for predator-prey mechanics).

## D-NPC-BEHAVIOR-STUB

**Decision:** `src/engine/combat/npc-behavior.lua` created as a stub. No NPC-specific combat decision code existed in Phase 1. WAVE-2 will populate `select_response`, `select_stance`, `select_target_zone`.

**Affects:** Anyone extending NPC combat AI. The stubs return safe defaults (nil/balanced) so existing code paths are unaffected.

## D-TEST-FOOD-DIR

**Decision:** `test/food/` registered in test runner (`test/run-tests.lua`). Directory exists with .gitkeep. Ready for WAVE-1 food/consumption tests.

**Affects:** Nelson (QA), anyone writing food system tests.

## D-TISSUE-MATERIALS-AUDIT

**Decision:** All 5 tissue materials needed for WAVE-1 body_tree exist: hide, flesh, bone, tooth-enamel, keratin. No creation needed. The material name is "tooth-enamel" (hyphenated, matching filename).

**Affects:** Flanders (creature body_tree tissue layer definitions in WAVE-1).
