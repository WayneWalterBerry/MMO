# Matchbox — Object Design

## Description
A battered little cardboard matchbox with a sliding tray. One long side bears a rough brown striker strip, worn but functional. Contains 7 wooden matches at game start. Lives in the nightstand drawer.

**Material:** `cardboard`

## Location & Role
- **Initial location:** Inside nightstand drawer
- **Puzzle role:** Primary fire source in Level 1. Player must discover the matchbox, extract it, then extract individual matches to light candles or perform fire-based interactions.
- **Scarcity:** Limited supply (7 matches) makes fire a precious resource.

## Containment Structure

The matchbox is a **container** holding individual `match` objects:

```
matchbox (parent container)
  ├── match-1 (accessible only when matchbox is open)
  ├── match-2
  ├── match-3
  ├── match-4
  ├── match-5
  ├── match-6
  └── match-7
```

**Container properties:**
- **Accessible:** `false` (closed) — contents NOT accessible until opened
- **Capacity:** 10 matches
- **Max item size:** 1
- **Weight capacity:** 1 lb

## FSM States

```
closed ↔ open
```

- **closed** — Sliding tray shut. Contents inaccessible. Striker strip visible and functional.
- **open** — Tray pulled open. Contents visible and accessible. Matches can be taken.

## Sensory Descriptions

### Closed State
| Sense | Description |
|-------|-------------|
| Look | A battered little cardboard matchbox of thin cardboard. The sliding tray is closed. One long side bears a rough brown striker strip, worn but functional. Inside: [N] wooden matches. |
| Feel | A small cardboard box. One side is rough -- a striker strip. The box feels [light/normal/heavy] as it shifts when tilted. |
| Smell | Faintly sulfurous -- the promise of fire, dormant. |
| Listen | Something rattles inside -- small wooden sticks. |

**Dynamic feel:** Changes based on match count (empty, 1, 2, or several).

### Open State (matchbox-open)
| Sense | Description |
|-------|-------------|
| Look | A battered little cardboard matchbox, its sliding tray pulled open. Inside, wooden matches lie in a neat row. One long side bears a rough brown striker strip, worn but functional. Inside: [N] wooden matches. |
| Feel | A small cardboard box, tray slid open. You feel match heads inside -- bulbous and slightly rough. |
| Smell | Faintly sulfurous -- the promise of fire, now within easy reach. |
| Listen | Silence. The matches wait. |

## Transitions

| From | To | Verb | Mutate | Message |
|------|-----|------|--------|---------|
| closed | open | open | `becomes = "matchbox-open"` | You slide the matchbox tray open with your thumb. Inside, a clutch of wooden matches rests snugly in a row. |
| open | closed | close | `becomes = "matchbox"` | You slide the matchbox tray shut with a soft click. |

## Surfaces & Contained Objects

### Container (inside)
- **Capacity:** 10 matches
- **Accessible only when open**
- **Initial contents:** match-1 through match-7 (7 matches)

## Special Properties

- **has_striker:** `true` — The matchbox has a striker surface. Used in compound interactions like `STRIKE MATCH ON MATCHBOX`.
- **Portable:** `true` — Can be picked up and carried
- **Size:** 1, **Weight:** 0.3 lbs
- **Categories:** small, container

## Keywords & Aliases
- `matchbox`
- `match box`
- `box of matches`
- `tinderbox`
- `lucifers`
- `open matchbox` (when open)

## Integration with Match System

The matchbox is the **companion object** to the `match` resource:

1. **Discovery:** Player finds matchbox in nightstand drawer.
2. **Opening:** Player opens matchbox (mutation: closed → open).
3. **Extraction:** Player takes individual matches from inside.
4. **Striking:** Player strikes match on matchbox striker to light it.
5. **Depletion:** As matches are used (burned or consumed), matchbox emptiness increases puzzle urgency.

**Economy:** With 7 matches and a 3-tick burn time per match, player has roughly 21 ticks of light total. Must use wisely to solve Level 1 puzzles.

## Puzzle Dependencies

- **Nightstand:** Matchbox is discovered inside the closed drawer. Player must open drawer to find it.
- **Candle:** Match + matchbox striker can light candles (secondary light source with longer burn).
- **Fire-based interactions:** Certain puzzles (e.g., burning rope, thawing frozen objects) require fire from matches.
- **Resource scarcity:** Limited match supply creates tension and forces player to prioritize light usage.

## What Changed (2026-07-20)

- Added `material = "cardboard"` metadata field
- Clarified `has_striker = true` property for compound verb resolution
- Documented mutation pattern: closed → open → closed cycle

