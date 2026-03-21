# Trap Door — Object Design

## Description
A heavy wooden trap door set flush with the flagstones. Hidden under the rug at game start. Discovered when rug is moved. Opens to reveal a spiral stone stairway descending into darkness.

## FSM States

```
hidden → revealed → open
```

- **hidden** — Under the rug. Invisible to player. No description, no room_presence.
- **revealed** — Rug moved. Iron ring handle visible. Closed.
- **open** — Opened. Stairway descends into darkness. Reveals "down" exit.

## Sensory Descriptions

| State | Look | Feel | Smell |
|-------|------|------|-------|
| hidden | — (invisible) | — | — |
| revealed | Heavy wooden door in floor, iron ring handle | Edges of wooden door, cold iron ring with rust | Damp earth through cracks |
| open | Trap door yawns open, spiral stone stairway down | Open door edge, stone stairway into cool damp air | Earth and old stone |

## Transitions

| From | To | Verb | Mutate |
|------|-----|------|--------|
| hidden | revealed | reveal (trigger) | — |
| revealed | open | open | `keywords = { add = "open" }` |

## Properties

- **Size:** 6, **Weight:** 100, **Portable:** No, **Hidden:** true (initially)
- **Categories:** architecture, wooden
- **Keywords:** trap door, trapdoor, trap, hatch, door in floor, floor door
- **Special:** `reveals_exit = "down"` when opened

## What Changed (2026-07-20)

- Added `mutate` field to revealed→open transition (keywords +open)
