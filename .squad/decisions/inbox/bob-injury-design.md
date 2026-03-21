# Decision: Level 1 Injury Design Docs

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-25  
**Status:** PROPOSED  
**Scope:** 5 injury design documents for Level 1

---

## What Was Done

Designed 5 individual injury types for Level 1 as full design documents in `docs/design/injuries/`:

| Injury | File | Damage Type | Treatment | Lethal? |
|--------|------|-------------|-----------|---------|
| Minor Cut | `minor-cut.md` | One-time | Cloth bandage (optional) | No |
| Bleeding | `bleeding.md` | Over-time (DoT) | Cloth bandage → rest | Yes (if untreated) |
| Nightshade Poisoning | `poisoned-nightshade.md` | Over-time (rapid) | Nightshade antidote ONLY | Yes (8-10 turns) |
| Burn | `burn.md` | One-time | Cold water / cool cloth | No |
| Bruised | `bruised.md` | One-time | Rest (no item) | No |

Each doc includes: causes, FSM states, `injuries` verb output per state, correct treatment, wrong-treatment feedback, discovery clues, puzzle uses, stacking/system interactions, and implementation notes for Flanders.

---

## Decisions Requiring Approval

### 1. Nightshade Antidote in Level 1?

**Question:** Should a nightshade antidote object be placed in Level 1?

- **If YES:** The poison bottle becomes a survivable puzzle (drink → poisoned → find antidote). A new object (`nightshade-antidote`) must be placed somewhere in the level.
- **If NO:** The poison bottle remains instant death (current behavior). The nightshade poisoning injury type is deferred to Level 2+.

**Bob's recommendation:** Place the antidote in Level 1. The treatment-matching puzzle (specific cure for specific poison) is the most valuable teaching moment in the entire injury system. Having it in Level 1 means players learn this lesson early.

**Suggested location:** Locked medicine cabinet in the hallway, or hidden inside a crate in the storage cellar (Puzzle 009).

### 2. Severity Gradient Ordering

The 5 injuries form a designed severity gradient that calibrates player expectations:

```
Bruise (trivial) → Minor Cut (minor) → Burn (moderate) → Bleeding (serious) → Nightshade (lethal)
```

This is intentional. Player encounters should roughly follow this gradient, with bruises/cuts appearing earlier and nightshade later. CBG should consider this when sequencing encounters.

### 3. New Object: Nightshade Antidote

Full object spec is in `poisoned-nightshade.md` §11. Key properties:
- Small glass vial, "Contra Belladonna" label
- Dark green liquid, sharp herbal smell
- Consumable, single-use
- Only cures nightshade poisoning specifically

**Handoff to Flanders** for implementation if antidote placement is approved.

---

## Handoffs

| To | Task |
|----|------|
| **Flanders** | Build 5 injury templates in `src/meta/injuries/`. Plus nightshade antidote object if approved. Specs in each doc's implementation notes. |
| **Bart** | Injury infliction triggers — objects with `on_take_effect`/`on_feel_effect` must instantiate injury FSMs. |
| **CBG** | Approve antidote placement. Review severity gradient for encounter sequencing. |
| **Nelson** | Test each injury FSM, wrong treatments, death sequences, and stacking. |

---

## Files Created
- `docs/design/injuries/minor-cut.md`
- `docs/design/injuries/bleeding.md`
- `docs/design/injuries/poisoned-nightshade.md`
- `docs/design/injuries/burn.md`
- `docs/design/injuries/bruised.md`
