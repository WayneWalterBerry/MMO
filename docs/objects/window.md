# Window — Object Design

## Description
A tall leaded glass window set deep in the stone wall. Diamond-paned, with an iron latch. Opens to let in outside air and sounds.

**Material:** `glass` (leaded panes)

## FSM States

```
closed ↔ open
```

- **closed** — Latched shut. Muffled outside sounds. Cold glass.
- **open** — Unlatched, swung open. Cool air, chimney smoke, distant city sounds.

## Sensory Descriptions

| State | Look | Feel | Smell | Listen |
|-------|------|------|-------|--------|
| closed | Tall diamond-paned leaded glass, warped view of rooftops | Cold glass, uneven, lead strips, iron latch | — | Faint muffled sounds from outside |
| open | Window stands open, iron latch thrown back | Cold glass swung open, damp stone sill | Rain and chimney smoke | Wind, cart wheels, dog barking, murmur of lives |

## Transitions

| From | To | Verb | Message |
|------|-----|------|---------|
| closed | open | open | Unlatch iron catch, push open. Cool air rushes in. |
| open | closed | close | Pull shut and latch. Outside sounds muffled. |

## Mutate Fields (Added 2026-07-20)

| Transition | Mutate |
|---|---|
| closed → open | `keywords = { add = "open" }`, `categories = { add = "ventilation" }` |
| open → closed | `keywords = { remove = "open" }`, `categories = { remove = "ventilation" }` |

**Design rationale:** "CLOSE THE OPEN WINDOW" resolves via keyword. "ventilation" category enables system queries for airflow (smell propagation, temperature).

## Properties

- **Size:** 5, **Weight:** 20, **Portable:** No
- **Categories:** fixture, glass, fragile
- **Keywords:** window, glass, pane, leaded glass

## What Changed (2026-07-20)

- Added `material = "glass"` metadata field
- Added `mutate` fields to both transitions (keywords ±open, categories ±ventilation)
