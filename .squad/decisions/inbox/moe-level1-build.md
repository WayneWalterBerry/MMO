# Decision: Level 1 Room Build — Moe

**Author:** Moe (World Builder)
**Date:** 2026-07-21
**Status:** Implemented

## Summary

Built 5 new room .lua files for Level 1 and updated cellar.lua exit routing. All rooms follow the established format from start-room.lua and cellar.lua.

## Decisions Made

### D-MOE-001: Storage Cellar Inserted Between Cellar and Deep Cellar
Updated `cellar.lua` north exit from targeting `deep-cellar` to targeting `storage-cellar`. Passage ID changed from `cellar-deep-door` to `cellar-storage-door`. The storage cellar contains the critical-path crowbar + iron-key crate puzzle.

### D-MOE-002: Placeholder Object GUIDs for Parallel Build
All new object instances reference placeholder GUIDs that Flanders will match when building object .lua files. The engine gracefully warns "base class not found" for unbuilt objects — rooms are functional shells awaiting object definitions.

### D-MOE-003: Crypt Exit Direction Is West
The crypt's exit back to deep-cellar uses direction `west` (matching the task specification). The deep cellar's exit to the crypt also uses `west`. This creates a non-Euclidean winding passage connection, which is common in underground text adventure spaces.

### D-MOE-004: Hallway Self-Lit at light_level 3
The hallway is the only room in Level 1 with its own persistent light source (lit torches in brackets). `light_level = 3` means the player does NOT need a carried light source to see. This is the reward contrast — warm, lit, safe after cold dark cellars.

### D-MOE-005: Environmental Properties Set Per Design Docs
All rooms declare `temperature`, `moisture`, and `light_level` as top-level fields. The engine reads these with defaults (20°C, 0.0, 0). The gradient from cellar (cold/wet/dark) through deep cellar (cold/dry/dark) to hallway (warm/dry/lit) is preserved exactly as designed.

### D-MOE-006: Sensory Callbacks Added to All New Rooms
All 5 rooms include `on_feel`, `on_smell`, and `on_listen` as top-level strings. These enable sensory exploration in darkness (FEEL, SMELL, LISTEN work without light per D-37).

## Dependencies

- **Flanders:** ~40 new object .lua files needed. Priority order: storage cellar (critical path) → deep cellar → hallway → courtyard → crypt.
- **Bob:** Puzzles 009 (crate), 010 (lantern), 011 (ascent), 012 (altar), 013 (courtyard entry), 014 (sarcophagus) need implementation.
- **Nelson:** All new rooms need gameplay testing once objects are built.
