# Decision: Wyatt's World — MrBeast Challenge Arena

**ID:** D-WYATT-WORLD  
**Status:** 🟢 Active  
**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-08-22  
**Category:** Design / New World

## Summary

Wyatt's World is a standalone world built for Wyatt (age 10) themed around MrBeast's YouTube brand. 7 rooms, hub-and-spoke layout, single-room puzzles, 3rd grade reading level, 5th grade puzzle difficulty.

## Design Document

Full specification: `projects/wyatt-world/design.md`

## Key Decisions

1. **Hub-and-spoke layout.** MrBeast's Challenge Studio is the central hub. 6 challenge rooms branch off. Every room connects back to the hub. Player can't get lost.
2. **Single-room puzzles only.** No multi-room dependency chains. Every puzzle solvable with only items and clues in that room.
3. **3rd grade reading level.** 8–12 word sentences, simple vocabulary, active voice, present tense.
4. **No darkness, injury, poison, or danger.** All senses safe. TASTE never harms. No horror content.
5. **Reading IS the puzzle.** Every challenge's core mechanic is careful reading — signs, labels, recipes, letters, riddles.
6. **Failure is funny.** Wrong answers produce silly sounds and encouraging hints, never punishment.
7. **Same engine, different content.** Uses identical verb/FSM/mutation/containment systems. Only theme and tone differ from The Manor.
8. **~70 objects** across 5 categories: challenge props, prizes, brand items, reading/clue objects, set dressing.
9. **Modern era aesthetic.** Plastic, metal, glass, cardboard, bright colors. Forbidden: stone, bone, tallow, iron, gothic materials.

## Affects

- **Moe:** Build 7 room .lua files + world .lua. Hub room id = `beast-studio`.
- **Flanders:** ~70 object definitions with kid-friendly sensory descriptions.
- **Sideshow Bob:** 7 self-contained puzzles with hint escalation.
- **Smithers:** No parser changes. Simple keywords only.
- **Nelson:** Test zero-harm invariant (no injury, darkness, or poison). Test hub connectivity. Test puzzle isolation.

## Rationale

This world proves the engine can serve radically different audiences using the same mechanics. If the verb/object/FSM system works for both gothic horror AND a kids' MrBeast game show, the engine architecture is validated for multi-world expansion.
