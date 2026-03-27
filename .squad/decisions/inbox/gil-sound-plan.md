# Decision: Web Audio Pipeline Plan

**Agent:** Gil (Web Engineer)  
**Date:** 2026-03-27  
**Status:** 📋 Proposed  
**Scope:** Web layer only (`web/bootstrapper.js`, `web/game-adapter.lua`, `web/deploy.ps1`)

## Decision

Gil has written the web audio pipeline section of the sound implementation plan at `plans/sound-web-pipeline-notes.md`. Key technical decisions proposed:

### D-SOUND-FORMAT: OGG Opus at 48kbps Mono
- Opus is 60% smaller than Vorbis for short SFX, natively decoded by browsers via `decodeAudioData()`
- Safari supports Opus since iOS 15 / macOS Monterey (2021)
- Vorbis fallback deferred to Phase 2 if needed for legacy Safari users

### D-SOUND-BRIDGE: Six JS Bridge Functions on `window`
- `_soundLoad(id, url)` — async fetch + decode (non-blocking)
- `_soundPlay(id, opts)` — one-shot or loop with per-sound volume
- `_soundStop(id)`, `_soundUnload(id)`, `_soundIsLoaded(id)`
- `_soundSetMasterVolume(vol)`, `_soundSetMuted(muted)`
- Lua side: `_G._web_sound` table wrapping all calls in `pcall()` for silent fallback

### D-SOUND-LAZY: Piggyback on Room JIT Loader
- Sound loading triggers inside `load_room()` / `load_object()` when objects have `sounds = {...}`
- Async fetch — room text renders immediately, sounds arrive in background
- In-memory buffer cache, no eviction for MVP (~900 KB RAM for 18 sounds)

### D-SOUND-AUTOPLAY: First Keypress Unlocks AudioContext
- `_ensureAudioContext()` called in existing `keydown` handler
- No "click to enable sound" banner — game's natural interaction model provides the gesture
- Ambient sounds start after first command, not on page load

### D-SOUND-FALLBACK: Silent No-Op on All Failure Paths
- Text output is always unconditional — sound is additive overlay only
- Old browsers, muted state, network errors, autoplay blocks all result in silent no-ops
- No branching between "sound path" and "text path" — text always fires

## Affects
- **Bart:** Engine-side `sound` module needs to check `_G._web_sound` and use it when available
- **Flanders:** Objects gain optional `sounds = { state = "sound-id" }` field
- **Nelson:** Web integration tests should verify sound bridge doesn't break game loop
- **Gil:** Implements JS + Lua bridge code, build script, deploy pipeline changes

## Estimated Gil Work: 5.5 hours
