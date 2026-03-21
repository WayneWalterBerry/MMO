### 2026-07-26: Bandage Lifecycle Design — Full FSM and Gameplay Flow
**By:** Sideshow Bob (Puzzle Designer)

**What:** Created `docs/design/injuries/bandage-lifecycle.md` — a comprehensive design doc for the bandage as a reusable treatment object with a full lifecycle (clean → applied → removable → soiled → clean).

**Key Design Decisions:**

1. **Four-state FSM:** Clean, Applied, Removable, Soiled. Each state has distinct description, sensory output, and mechanical effects. The cycle is: clean → applied (to injury) → removable (wound healed) → soiled (removed) → clean (washed). Soiled bandages CAN be reapplied without washing, but carry infection risk at Level 2+.

2. **Linked FSMs:** Bandage and injury track each other via `attached_to` / `treated_by` cross-references. The injury FSM reaching `healed` auto-triggers the bandage's `applied → removable` transition. This is event-driven, not verb-driven.

3. **Premature removal:** Players CAN remove a bandage from an unhealed wound — the wound re-opens and bleeds again. This enables the triage puzzle: strip bandage from a healing wound to save a newly bleeding one, at cost.

4. **Infection risk from dirty bandages:** Soiled bandages work but add infection risk. Washing in water resets to clean. This is a Level 2+ mechanic — Level 1 has no infection penalty to keep the learning curve smooth.

5. **The triage puzzle:** 2 bandages / 4 wounds (2 bleeding, 2 minor). Or worse: 1 bandage / 2 bleeds. The player must use `injuries` to assess severity and bandage the higher-drain wound first. The reuse loop (apply → wait → remove → reapply) turns one bandage into a time-shared resource.

6. **Crafting from cloth sources:** Bandages come from tearing blankets, cloaks, or curtains — each has an alternate use (warmth, cold protection, light control). Every bandage costs something else.

7. **Bandage vs. salve contrast:** Bandage = reusable, forgiving of wrong use (returned, not consumed), asks "which wound?" Salve = consumable, punishing of wrong use (wasted), asks "should I use this now?" Deliberately opposite lifecycles.

**Files Created:**
- `docs/design/injuries/bandage-lifecycle.md`

**Handoffs:**
- **Flanders:** Build bandage object with 4-state FSM (clean/applied/removable/soiled), `attached_to` runtime field, event-driven `injury_healed` transition. See §9 metadata sketch.
- **Bart:** Engine support for linked FSMs — injury `healed` event triggering bandage state change. Premature removal guard checking injury state. `portable = false` when applied.
- **Nelson:** Test full lifecycle loop (apply → heal → remove → wash → reapply). Test premature removal (wound re-opens). Test triage scenarios (multiple wounds, limited bandages). Test disambiguation when multiple bandages exist.
- **CBG:** Review triage puzzle balance — is the drain-rate math producing good gameplay tension?
