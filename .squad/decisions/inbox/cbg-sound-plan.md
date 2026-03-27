# Decision: Sound Design Plan — Game Design Section

**ID:** D-SOUND-GAME-DESIGN  
**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-07-28  
**Status:** 🟢 Active  
**Category:** Design  
**Deliverable:** `plans/sound-design-notes.md`

## Summary

Game design section for sound effects implementation completed. Covers sound priority tiers, per-object/creature sound audit, accessibility model, ambient design, combat sound layering, and MVP sound list.

## Decisions Made

### D-SOUND-TEXT-CANONICAL: Text Always Present
Sound enhances, never replaces. Every sound event has corresponding text output. A player with sound disabled misses zero gameplay information. This is non-negotiable (Wayne directive).

### D-SOUND-SILENCE-IS-VALID: Dead Creatures Produce Silence
No death sounds for creatures. The absence of the cat's purr or the wolf's growl IS the audio signal. Text handles death narration ("The rat goes still"). Silence is more powerful than a death squeal.

### D-SOUND-3-SLOT-MAX: 3 Simultaneous Sounds Maximum
Hard cap on concurrent audio: ambient (ducked) + creature vocalization + impact sound. Prevents audio mud. Text carries the narrative detail; sound sells the moment.

### D-SOUND-TYPE-BASED-IMPACTS: 4 Damage-Type Impact Sounds
Impact sounds map to damage type (pierce/slash/blunt/crush), not to specific weapons. Aligns with Principle 9 (material consistency) and the combat plan's material-based damage model.

### D-SOUND-SHARED-DOOR-SOUNDS: Doors Share Base Creak Sounds
2–3 base door sounds cover all 8+ door objects. Material variation (oak vs. iron vs. stone) is expressed through text, not unique sound files. Keeps MVP scope manageable.

### D-SOUND-AMBIENT-CROSSFADE: 1.5s Room Transition Crossfade
Ambient loops crossfade over 1.5 seconds on room transitions. Event sounds duck ambient by 30%. Abrupt cuts break immersion worse than no ambient at all.

### D-SOUND-TOD-PHASE2: Time-of-Day Ambient Deferred to Phase 2
The game starts at 2 AM. Night ambient is the MVP default for all rooms. Time-of-day variation (dawn birds, evening crickets) is Phase 2 polish.

### D-SOUND-MVP-24: 24 Sound Files for MVP
Concrete MVP: 8 creature, 4 door, 3 fire, 4 combat impact, 3 ambient loop, 2 destruction. ~100 KB gzipped. Every sound earns its place.

### D-SOUND-CONTROLS: Single Volume + 3 Toggles
Master volume (0–100%) plus three toggles: SFX, ambient, creatures. No full mixer UI in MVP. Full mixer is Phase 2+ if player demand warrants it.

## Affects

| Agent | Impact |
|-------|--------|
| **Bart** | Architecture plan needs to implement: 3-slot mixing, ambient crossfade, event ducking, lazy loading |
| **Flanders** | Objects gain optional `sounds` field — maps states/transitions to sound files |
| **Moe** | Rooms gain optional `ambient` field — specifies ambient loop file |
| **Smithers** | Verb handlers need sound trigger hooks; UI needs volume/toggle controls |
| **Gil** | Web build pipeline: pre-compress OGG files, lazy-load manifest, Web Audio API bridge |
| **Nelson** | Tests must verify text output unchanged; sound is additive only |

## Open Questions for Wayne

1. **Terminal sound support:** Is terminal sound in scope for MVP, or web-only first? (Research recommends web-first.)
2. **Sound sourcing:** Should we license from Zapsplat (CC0/CC-BY) or commission custom? Budget?
3. **Creature sound toggles:** Is per-category toggle (SFX/ambient/creature) sufficient, or do players need per-creature mute?
