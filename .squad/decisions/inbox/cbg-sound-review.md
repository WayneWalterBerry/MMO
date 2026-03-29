# Sound Plan Review — Comic Book Guy (Creative Director)

**Plan:** `projects/sound/sound-implementation-plan.md` + `sound-design-notes.md` + `sound-web-pipeline-notes.md`  
**Date:** 2026-03-30  
**Verdict:** ✅ Approved  

---

## Findings

### 1. ✅ Game Design Philosophy Solid
The three iron laws (text canonical, lazy loading, pre-compressed) are sound. Sound as "atmospheric seasoning" is the right framing for a text adventure. Every sound event has text equivalent — zero exclusive audio information. This preserves accessibility and player agency.

### 2. ✅ Sound Priority Tiers Well-Justified
The audit of every object is masterful:
- **Tier 1 (ship-blocking):** Creature vocalizations, doors, ignition, combat — these transform tension + discovery moments.
- **Tier 2 (immersion multipliers):** Ambient loops, containers, destruction, liquid — quality-of-life.
- **Tier 3 (polish):** UI sounds, clock, mechanical — Phase 2+.

This is not haphazard. Every Tier 1 sound addresses a specific game moment.

### 3. ⚠️ Concern: Silence Design Needs Player Education
"Dead creatures produce no sound" is a brilliant design choice — absence IS communication. But new players may not realize this is intentional. Recommendation: Add one line to `on_listen` for dead creatures:
```
"The [creature] is motionless. No breath, no sound."
```
The explicit mention of silence will cue players that it's information. This is a Smithers integration point (verb output).

### 4. ✅ Ambient Loop Choices Excellent
Per-room ambient design shows deep thought:
- **Bedroom:** Near-silence (contrasts with danger outside)
- **Hallway:** Torch crackle (warmth, safety)
- **Cellars:** Drips, scratching, oppressive void (dread escalation)
- **Courtyard:** Wind + outdoor openness (relief)

The progression from shallow to deep (Bedroom → Crypt) is intentional emotional pacing. Perfect.

### 5. ⚠️ Concern: Time-of-Day Variation Scope Creep?
Sound-design-notes.md mentions time-of-day variation (night birds, courtyard daytime activity). The implementation plan doesn't budget this. If it ships in WAVE-0 or WAVE-1, it needs explicit hours + test coverage. If deferred to Phase 2, document as deferred scope. **Recommendation:** Keep MVP as fixed-ambient (2 AM atmosphere always), move time variation to Phase 2. Simpler gate criteria, less integration risk.

### 6. ✅ Accessibility Dual-Channel Design Perfect
Every event produces text + optional sound. Mute toggle, master volume, creature-sounds toggle, ambient toggle = enough controls for MVP. The "no screen reader interference" note is smart (Phase 2: TTS ducking if needed).

### 7. ✅ Asset Sourcing Strategy Clear
24 MVP sounds, mostly reused across objects (rat-squeak → all rat states, door-creak → multiple doors). This reduces unique files from theoretical ~50 to ~18 actionable items. OGG Opus @ 48kbps is industry standard for SFX. ~230 KB total is mobile-friendly.

### 8. ⚠️ Concern: "Dead = Silence" Needs Combat Testing
When a wolf dies mid-combat, does an ambient loop (room + creature) *stop* cleanly? The plan doesn't detail how `on_object_death()` hooks into sound manager's `stop_by_owner()`. Test this in WAVE-2 integration — confirm no ghost sounds.

### 9. ✅ Fire-and-Forget Philosophy Strong
Sound wrapped in `pcall()` everywhere. Sound failure never crashes the game. Text output is unconditional. This is the right defensive design.

### 10. ✅ Creature Vocalization Chart Is Production-Ready
Every creature, every state, every corresponding sound file and `on_listen` text. This chart IS the design spec. Flanders can implement objects straight from this.

---

## Consolidated Verdict

**The game design is excellent.** This is not a generic "add sounds" plan — it's a carefully curated aesthetic that respects the text-first philosophy. The priority tiers will ship a game that FEELS atmospheric without bloat. The only missing piece is clarifying time-of-day as Phase 2.

**No blockers. Two concerns (silence education, time variation scope) are easy fixes.**

### Recommended Changes

1. In Smithers' verb output integration (WAVE-2), explicitly mention silence for dead creatures: `"The wolf is motionless. No breath, no sound."`
2. Mark time-of-day variation as **Phase 2 deferred** in the plan. Keep WAVE-1 ambient as fixed (permanent 2 AM atmosphere).
3. Add to WAVE-2 gate criteria: "Creature death stops all sounds owned by creature (no ghosts)."

---

**Reviewed by:** Comic Book Guy (Creative Director)  
**Confidence:** High  
**Signature:** ✅
