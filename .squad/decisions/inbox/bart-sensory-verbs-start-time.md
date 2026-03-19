# Decision: Game Start Time + Sensory Verb System

**Author:** Bart (Architect)  
**Date:** 2026-03-21  
**Status:** IMPLEMENTED

## Game Start Time: 2 AM

Changed from 6 AM to 2 AM. The player now wakes in absolute darkness. Dawn at 6 AM arrives after ~10 real minutes (at 24x game speed). This forces the candle puzzle — players cannot simply LOOK around, they must FEEL, SMELL, LISTEN their way to the candle and matches.

## Sensory Verb Convention

All sensory verbs work in complete darkness. Objects support these optional fields:

| Field | Verb | Light required? |
|-------|------|----------------|
| `on_feel` | FEEL/TOUCH | No |
| `on_smell` | SMELL/SNIFF | No |
| `on_taste` | TASTE/LICK | No |
| `on_taste_effect` | (triggered by TASTE) | No |
| `on_listen` | LISTEN/HEAR | No |

Room-level ambient fields: `room.on_smell`, `room.on_listen`.

Objects without these fields get graceful defaults ("nothing distinctive", "makes no sound", etc.).

## Poison Mechanic (V1)

`on_taste_effect = "poison"` → immediate death. Future: antidote, timed effects, partial poisoning.

## Team Impact

- **Comic Book Guy:** Add `on_feel`, `on_smell`, `on_taste`, `on_listen` fields to objects. `on_taste_effect` on dangerous items. `on_smell` and `on_listen` on start-room.
- **All:** LOOK still requires light. All other senses do not.
