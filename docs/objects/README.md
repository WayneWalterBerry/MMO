# Object Design Directives

This directory contains one markdown file per game object, documenting design directives, FSM states, timer behavior, and special mechanics.

## Naming Convention

Files use the object's internal ID: `{object-id}.md` (e.g., `candle.md`, `wall-clock.md`, `matchbox.md`).

## Format

Each file should include:
- **Description** — what the object is, how the player encounters it
- **FSM States** — all states and transitions
- **Timer Behavior** — if the object has timed events (burn, chime, tick)
- **Composite Parts** — if the object has detachable parts
- **Prerequisites** — what's needed to interact with it (for GOAP planner)
- **Sensory Descriptions** — what the player sees, feels, smells, hears in each state
- **Design Directives** — Wayne's specific instructions about this object

## Object Index

| Object | File | Key Mechanic |
|--------|------|-------------|
| Candle | [candle.md](candle.md) | Consumable, extinguishable, partial burn, timer |
| Candle Holder | [candle-holder.md](candle-holder.md) | Composite, holds candle, enables portable light |
| Match | [match.md](match.md) | One-shot consumable, no relight, 3-tick burn |
| Poison Bottle | [poison-bottle.md](poison-bottle.md) | Composite (cork), 3 FSM states, death on drink |
| Sewing Manual | [sewing-manual.md](sewing-manual.md) | Skill-granting document, burnable, READ verb, permanent loss if burned |
| Wall Clock | [wall-clock.md](wall-clock.md) | Recurring timed event, hourly chime |
