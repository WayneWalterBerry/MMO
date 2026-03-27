# Research Complete: Sound Effects Integration for MMO

**Date:** 2026-03-27  
**Agent:** Frink  
**Category:** Design + Architecture  
**Status:** Exploratory (no commitments; presents options)

---

## Summary

Sound effects are **feasible and recommended**. Both terminal and web platforms support audio with clean optional architectures. The team can ship sound in Phase 1 (12–15 MVP effects) with minimal risk and no engine refactoring.

---

## Key Decision Points for Wayne

### D-SOUND-1: Platform Priority

**Option A (Recommended):** Web first; terminal second (if desired)
- Web = higher player impact; easier implementation
- Terminal = platform-dependent; add later if needed

**Option B:** Both simultaneously
- More effort; unclear if terminal sound worth the cost

**Recommendation:** Go with **Option A** for Phase 1.

### D-SOUND-2: Sound-Optional Architecture

**Decision:** YES — Build sound as optional subsystem

- Game works perfectly without audio (fallback to text descriptions)
- No performance penalty on unsupported platforms
- Graceful degradation (SSH, headless servers, etc.)
- Easy to toggle at runtime

### D-SOUND-3: Source Priority

**Recommendation:** Zapsplat (primary) → BBC (secondary) → OpenGameArt (gaps)

- All are free with acceptable licenses (CC0/CC-BY)
- Zapsplat is highest quality and most curated
- BBC for creature vocalizations + mechanical sounds
- OpenGameArt for game-ready fallbacks

### D-SOUND-4: MVP Sound Set Size

**Recommendation:** 12–15 unique effects (estimated effort: 2–3 hours sourcing + 4–6 hours integration)

1. Creature vocalizations: 4 (rat, cat, wolf, bat)
2. Door/lock: 3 (creak, click, clang)
3. Object impacts: 3 (glass, chain, metal)
4. Ambiance: 2 (fire crackle loop, water drip loop)
5. UI (optional): 1

**Why this size?** Covers all 5 creatures + key object interactions + immersive ambiance. Larger sets show diminishing returns for effort.

### D-SOUND-5: Audio Format

**Recommendation:** OGG Vorbis (128 kbps quality) for web; WAV optional for terminal

- OGG: ~50% smaller than WAV, excellent quality, universal browser support
- File size impact: ~100 KB gzipped for 18-sound bundle (negligible)
- Terminal: WAV preferred for instant playback (no decompression latency)

### D-SOUND-6: Integration Hook

**Recommendation:** FSM state transitions + optional verb handlers

- When object transitions state → play sound (no engine refactoring)
- Extend object definitions with optional `sounds` field (backward-compatible)
- Event-driven primary; ambient loops secondary

### D-SOUND-7: File Organization

**Recommendation:** `resources/audio/` with subdirectories

```
resources/audio/
  creatures/       (rat-squeak, cat-purr, wolf-growl, bat-screech)
  objects/         (door-creak, glass-shatter, chain-rattle, candle-ignite)
  ambience/        (fire-crackle-loop, water-drip-loop)
  ui/              (optional notification blip)
```

---

## Architecture (Clean Integration)

**No engine changes needed.** Hook into existing infrastructure:

```lua
-- Object definition (optional extension)
return {
    id = "candle",
    sounds = {
        lit = "candle-ignite.ogg",
        extinguished = "candle-snuff.ogg",
    },
    states = { /* existing */ },
}

-- FSM engine (on state transition)
if obj.sounds and obj.sounds[new_state] then
    play_sound(obj.sounds[new_state])
end

-- Verb handler (optional)
if obj.sounds and obj.sounds.open then
    play_sound(obj.sounds.open)
end
```

---

## Implementation Phases

### Phase 1 (MVP): 2–3 days
- Curate 12–15 effects from Zapsplat/BBC
- Build `engine.sound` module (optional, platform-aware)
- Hook FSM + verb handlers
- Test terminal + web

### Phase 2 (Polish): 1–2 weeks
- Expand to 30–40 sounds (all creatures + key objects)
- Spatial audio (left/right speaker positioning)
- Volume ducking (mix overlapping sounds)
- User preferences (mute, volume slider)

### Phase 3 (Future): Post-beta
- Ambient music (separate subsystem)
- Procedural sound synthesis
- Effects/reverb

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Audio files too large | LOW | OGG codec keeps bundle impact <1% |
| Terminal sound unreliable | LOW | Optional; graceful fallback to text |
| Browser compatibility | LOW | Web Audio API supported in all modern browsers |
| Accessibility concern | MEDIUM | Always provide text fallback; mute toggle required |
| Player distraction | LOW | Text-first; sound is enhancement only |

**Overall risk:** Very low. Sound is optional, non-blocking, and fully backward-compatible.

---

## Success Criteria

- Phase 1: 12–15 MVP sounds sourced and integrated
- Terminal build works (with or without sound)
- Web build plays sounds reliably (no Web Audio errors)
- Test suite includes audio scenarios (where feasible)
- Documentation updated (how to add new sounds)

---

## No Blocking Decisions

This research is exploratory. **No team commitments required** until Wayne decides to greenlight Phase 1.

**If approved:** Recommend assigning to **Smithers** (UI/presentation domain) or **Bart** (engine architecture), depending on integration depth desired.

---

## Next Steps

1. **Wayne reviews** and confirms: Phase 1 greenlight? (y/n)
2. **If yes:** Choose primary sound-sourcer (Zapsplat vs BBC vs OpenGameArt)
3. **If yes:** Assign implementation (Smithers likely candidate)
4. **If yes:** Create GitHub issue with Phase 1 acceptance criteria

---

## Deliverable

Full research report: `resources/research/sound/sound-effects-research.md` (21 KB, 10 sections)

Covers: feasibility, free sources, object candidates, integration architecture, file size, accessibility, comparison with other games, phases, and recommendations.
