# Decision: Player Health & Injury Architecture

**Author:** Bart (Architect)  
**Date:** 2026-07-22  
**Status:** Design  
**Requested by:** Wayne Berry  
**Scope:** Player health system, injury FSM, damage/healing pipeline

---

## Summary

Designed the complete architecture for player health, damage application, injury state machines, and healing interactions. Three architecture docs created in `docs/architecture/player/`.

## Decisions

### D-HEALTH001: Damage Encoded on Objects, Not Engine
Object `.lua` files declare damage values (e.g., `on_drink = { damage = 100 }`). The engine reads and applies. No hardcoded damage tables. Object authors (Flanders) control damage.

### D-HEALTH002: Single Damage Pipeline for All Sources
All damage (verb-triggered, injury over-time, environmental) flows through one pipeline: declare → read → modify → apply → clamp → death check.

### D-HEALTH003: Health is Integer, Clamped 0–max_health
No floating-point. `health` clamped to `[0, max_health]`. Default max is 100.

### D-HEALTH004: Death at health ≤ 0
Clean threshold. Death triggers `on_death` engine hook.

### D-HEALTH005: Healing Items Declare Target Injury Type
Bandage targets "bleeding", antidote targets "poisoned". Generic engine, specific objects.

### D-INJURY001: Injuries are FSMs in `src/meta/injuries/`
Individual `.lua` files per injury type. Same FSM pattern as objects (states, transitions, timed_events). Content authors create new injuries without engine changes.

### D-INJURY002: Three Damage Types
- **One-time:** Single health decrease on infliction (bruise, cut)
- **Over-time:** Per-turn drain while active (bleeding, poison)
- **Degenerative:** Escalating per-turn drain (infection — damage increases each tick up to a cap)

### D-INJURY003: Healing Items Declare Target Injury Type
Specific matching prevents "heal everything" items. Forces resource management.

### D-INJURY004: Injury FSM Reuses Object FSM Engine
Same `fsm.tick()`, `fsm.transition()`, `fsm.start_timer()`, `fsm.tick_timers()`. No duplicate code.

### D-INJURY005: Multiple Simultaneous Injuries
Player can have multiple active injuries. Engine iterates all. Total damage is sum of all active injuries' `damage_per_tick`.

### D-INJURY006: Fatal Injury State Triggers Death
Even if health > 0, a fatal terminal state (e.g., sepsis) is game over.

## Files Created

- `docs/architecture/player/README.md`
- `docs/architecture/player/health.md`
- `docs/architecture/player/injuries.md`

## Impact

- Engine loop needs new phase: injury tick + death check (after object tick)
- New folder: `src/meta/injuries/` for injury type definitions
- Verb handlers need to check `on_<verb>.damage`, `on_<verb>.heal`, `on_<verb>.injury`, `on_<verb>.cures`
- Status bar should display health and active injuries
