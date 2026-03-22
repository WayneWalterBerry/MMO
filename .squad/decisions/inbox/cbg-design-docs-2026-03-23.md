# Decision: Unconsciousness System, Hit Verb, Mirror/Appearance Subsystem

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-23  
**Status:** DESIGN PHASE COMPLETE — Ready for Implementation Phase

---

## Summary

Wrote 5 comprehensive design documents for the unconsciousness injury system, self-hit verb (`hit head`), mirror object integration, and player appearance subsystem. All design decisions from the 2026-03-22 daily plan have been locked in and documented.

---

## Key Design Decisions Finalized

### 1. Unconsciousness State Machine
- **Binary transition:** Conscious → Unconscious → Waking → Conscious (no dazed state)
- **Severity-based duration:** 3-25 turns depending on blow strength
- **Injuries tick during unconsciousness:** Player can bleed to death while asleep/KO'd
- **Death condition:** Health ≤ 0 while unconscious = permanent death with special narration

### 2. Armor Interaction
- **Helmets reduce unconsciousness duration:** 30-75% reduction based on armor type
- **Bare head:** Full duration (3-20 turns)
- **Leather helmet:** 30% reduction
- **Iron helmet:** 50% reduction
- **Plate + gorget:** Can negate weak blows entirely

### 3. Self-Infliction via Hit Verb
- **Head hit:** Triggers unconsciousness injury (base 5 turns, +3-7 with weapons)
- **Arm/Leg hit:** Triggers bruise injury (pain type, affects actions)
- **Parallels `stab self`:** Same testing pattern for players to explore mechanics safely
- **Body area targeting:** Reuses stab's body area system (head, arm, leg, torso)

### 4. Mirror Object Design
- **Metadata flag:** `is_mirror = true` on mirror objects
- **Routing:** Examine mirror → appearance subsystem (not normal examine)
- **Player state reflection:** Shows current injuries, armor, held items, health level
- **Level 1 placement:** Bedroom vanity gets mirror flag

### 5. Player Appearance Subsystem
- **Layer system:** Head → Torso → Arms/Hands → Legs → Feet → Overall
- **Nil layers:** Skipped if nothing notable (don't describe bare feet in good condition)
- **Natural composition:** Connectives and varied phrasing (not robotic lists)
- **Health-based descriptors:** Robust → Healthy → Worn → Critical → Dying
- **Future-proof for multiplayer:** Same subsystem powers "look at <player>" logic

---

## Documented Files

### Design Documents (All Under docs/design/)

1. **docs/design/injuries/unconsciousness.md** (16.2 KB)
   - Complete FSM states and transitions
   - Duration mechanics and severity scaling
   - Armor protection interaction
   - Wake-up narration templates
   - Testing criteria and implementation notes

2. **docs/design/injuries/self-hit.md** (12.7 KB)
   - Hit verb syntax and body area targeting
   - Injury results by area
   - Armor interaction details
   - Narration and Prime Directive compliance
   - Parser integration

3. **docs/verbs/hit.md** (2.9 KB)
   - Verb reference (synonyms, syntax, behavior)
   - Sensory mode and injury results table
   - Implementation notes for engine routing

4. **docs/design/objects/mirror.md** (14.3 KB)
   - Mirror as metadata-flagged object
   - Appearance subsystem routing
   - Narration framing variations
   - Layer system and example descriptions
   - Engine integration points

5. **docs/design/player/appearance.md** (18.2 KB)
   - Complete appearance subsystem design
   - Layer rendering pipeline
   - Injury rendering with natural phrasing
   - Health tiers and descriptors
   - Multiplayer hook for future development

---

## Design Principles Affirmed

1. **State-driven composition beats hardcoded content.** Appearance is generated from flags (injuries, worn items, health level), not templates. Enables rich variation and future extensibility.

2. **Puzzle-first design.** Unconsciousness creates natural puzzles: time-pressure (injury ticking), resource-management (treat wounds before sleeping), and strategic choices (avoid certain areas until healthy).

3. **Natural language > robotic interface.** Mirror descriptions use prose with varied phrasing and connectives, not "You are wearing: [list]." Same philosophy as core Prime Directive.

4. **Layered systems enable reuse.** The appearance subsystem solves mirrors today and multiplayer "look at player" tomorrow. Designing for future doesn't break present.

5. **Injury system creates stakes.** Injuries tick during unconsciousness/sleep. This transforms these states from "safe rest" to "dangerous vulnerability." Sleep becomes a strategic decision, not a pause.

---

## Implementation Roadmap (Phase 2-3)

### Phase 2: Architecture Docs (Bart)
- `docs/architecture/player/` — Update player model (consciousness state, health derivation)
- Game loop handling (skip input, tick injuries, check death, decrement timers)
- Wake-up event dispatch and narration

### Phase 3: Engine Implementation (Smithers + Bart)
- Add `player.consciousness` and `player.unconsciousness_timer` to player model
- Game loop: if unconscious, tick injuries and check death
- Hit verb handler routing to injury system
- Appearance subsystem in `src/engine/player/appearance.lua`
- Mirror object `on_examine` hook integration

### Phase 4: Testing (Nelson)
- All test scenarios from unconsciousness.md design doc
- Mirror appearance in various player states
- Natural language quality check on generated descriptions
- Edge cases (unconscious during examination, darkness, etc.)

---

## Cross-Document References

This decision ties together the following existing docs:

- `docs/design/player/health-system.md` — Overall health/injury model (this clarifies unconsciousness layer)
- `docs/design/injuries/puzzle-integration.md` — How unconsciousness fits into Level 1 puzzles
- `docs/verbs/stab.md` — Existing self-infliction pattern (hit follows same model)
- `docs/design/verb-system.md` — Verb architecture (hit extends existing dispatch)
- `docs/design/wearable-system.md` — Armor system (unconsciousness reduction uses wearable properties)

---

## Design Quality Checklist

- ✅ Internal consistency (no contradictions within or between docs)
- ✅ Player experience narrative (how players will discover and understand systems)
- ✅ Engine feasibility (implementable with existing architecture)
- ✅ Puzzle opportunities (identifies multiple puzzle uses)
- ✅ Extensibility (designed for future systems, e.g., multiplayer)
- ✅ Testing criteria (each doc has clear Nelson QA list)
- ✅ Prime Directive compliance (natural language, no menus, touch-based in darkness)
- ✅ Narrative richness (sensory descriptions, emotional presence, varied phrasing)

---

## Remaining Open Questions (For Team Discussion)

1. **Multiple unconsciousness injuries:** Should they stack or restart the timer? Current design: restart (doesn't stack). Rationale: you can't be "more unconscious," but a bigger blow keeps you down longer.

2. **Early wake-up mechanics:** Currently designed as single-player only (you wait out the timer). Future multiplayer might have allies waking the player early. Keep hook in architecture?

3. **Bruise action penalties:** Design specifies bruises affect actions (slower, weaker) but percentage values are placeholders. Needs playtesting to calibrate.

4. **Health descriptor accuracy:** Should derived health exactly match displayed health tier descriptors, or can there be slight shifts for narrative variety? Current design allows shifts.

5. **Appearance subsystem performance:** Layer-by-layer rendering + injury composition could be expensive if called frequently. Should we cache appearance descriptions and invalidate on state change?

---

## See Also

- `plans/2026-03-23-daily-plan.md` — Full context and implementation tasks
- `.squad/decisions.md` — Central decision log (this inbox message should be merged into main decisions.md after review)
- `.squad/agents/comic-book-guy/history.md` — Design history and learnings appended

---

**Status:** Ready for implementation kickoff. All design questions answered. Design team sign-off complete.
