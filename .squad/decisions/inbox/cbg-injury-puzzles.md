# Decision: Injury ↔ Puzzle Integration Analysis

**Author:** Comic Book Guy (Design Lead)  
**Date:** 2026-07-25  
**Type:** Design Analysis  
**Status:** For Review  
**Deliverable:** `docs/design/injuries/puzzle-integration.md`

---

## What Was Done

Wrote a comprehensive design analysis (~35 KB) examining how Bob's five Level 1 injury types integrate with the puzzle system. The document identifies five distinct roles injuries play in puzzle design and maps each injury to specific Level 1 rooms, objects, and gameplay moments.

## Key Findings

### Five Roles of Injury in Puzzle Design

1. **Injuries AS Puzzles** — Bleeding and nightshade poisoning create ticking-clock puzzles. Treatment matching (nightshade needs "Contra Belladonna," not generic antidote) is a three-layer puzzle: identify → locate → apply. Resource scarcity (limited cloth, multiple wounds) creates triage decisions.

2. **Puzzles CAUSING Injuries** — Every physical puzzle should have a failure-state injury. Severity matches recklessness: grab candle = minor burn, drink poison = potentially lethal. Environmental hazards (dark stairs, glass on floor) create the "darkness tax" — light isn't just for seeing, it's for safety.

3. **Injuries BLOCKING Puzzles** — Capability gates (bruised legs → can't climb, burned hand → can't grip) create heal-to-progress points. These gates redirect players toward content they'd otherwise skip (courtyard exploration while resting, reading scrolls while recovering).

4. **Treatment AS Puzzles** — No healing item is found ready-to-use in Level 1. Every treatment is a crafting chain: find material → transform → apply. The tattered scroll in the deep cellar serves as a pre-loadable medical reference that rewards early exploration.

5. **Engine Hooks** — Proposed `injury_effect` handler following the existing `wind_effect` pattern. `on_traverse` for hazard injuries, `on_pickup` for object injuries, `on_timer` for injury worsening. Prevention conditions (`has_light`, `wrapped_in_cloth`) make avoidance itself a puzzle.

### Level 1 Room Integration Map

- **Bedroom:** 5 possible injuries (all avoidable, all educational). Minor cut is first-ever injury — calibrates expectations.
- **Cellar:** Darkness injuries. Treatment is in the bedroom above — creates "hurt underground, medicine upstairs" micro-puzzle.
- **Storage Cellar:** Both injury source and treatment source (grain sack → bandage cloth). Teaches environment-as-pharmacy.
- **Deep Cellar:** Knowledge chamber. Tattered scroll provides treatment knowledge. No direct injuries — prevention focus.
- **Courtyard:** Treatment hub (rain barrel = burn treatment, rest space = bruise recovery). Ironic: hardest room to reach safely, most useful for healing.
- **Crypt:** Danger room. Full injury complexity. Demands preparation. Final exam for bedroom lessons.

### Anti-Patterns Identified

- Never injure for observation (EXAMINE/SMELL/LISTEN are safe)
- Never create unwinnable injury stacks
- Critical path completable without ANY injuries
- Darkness injuries must be rare enough to teach, not tedious enough to annoy

## Decisions Needed from Wayne

1. **Nightshade antidote placement:** Should the antidote exist in Level 1 (making poison survivable) or stay deferred to Level 2+? Bob's design leaves this open.
2. **Medical scroll content:** Proposed tattered scroll text included in §4.4. Should this be part of the deep cellar altar content?
3. **Engine priority:** `injury_effect` handler and `on_timer` system are P1 for full integration. Does Bart have bandwidth?

## Dependencies

- Bob's injury designs (all five in `docs/design/injuries/`)
- Engine event handler system (`puzzle-designer-guide.md`)
- Healing items catalog (`healing-items.md`)
- Level 1 room/puzzle architecture (`level-01-intro.md`)
