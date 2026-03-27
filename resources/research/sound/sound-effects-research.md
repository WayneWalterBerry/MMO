# Sound Effects Research for MMO Text Adventure Engine

**Date:** 2026-03-27  
**Researcher:** Frink  
**Status:** Complete  
**Target:** Feasibility assessment for adding sound effects to terminal + web builds

---

## Executive Summary

**Can we add sound?** Yes, with platform-specific strategies:
- **Terminal CLI:** Sound support is **platform-dependent & degradable** — can use system sounds, but requires fallback for unsupported terminals
- **Web (Fengari):** Sound support is **excellent** — Web Audio API is fully accessible to JavaScript, and Fengari can bridge to it
- **Recommendation:** Build a **sound-optional architecture** that works without audio, but uses it when available

**Minimum viable sound set:** ~12-15 unique effects would have high impact (fire crackling, door/lock sounds, creature vocalizations, object impacts, combat hits)

---

## 1. Platform Feasibility

### 1.1 Terminal / CLI (Lua Standard Interpreter)

#### Can Terminal Play Sound?

**Direct Lua Audio:** No built-in support. Lua has no native audio libraries.

**Cross-Platform Sound via System Calls:**

| Platform | Method | Lua Approach | Notes |
|----------|--------|--------------|-------|
| **Windows** | WinMM or DirectSound | Call `os.execute()` to `powershell -c "[Console]::Beep()"` or play `.wav` via `mmsys.cpl` | Simple beep only; limited quality |
| **Windows** | PowerShell Audio | `powershell -c (New-Object System.Media.SoundPlayer).PlaySync('path.wav')`  | Full WAV support, blocks until done |
| **Windows** | `fplay.exe` (SFX Player) | `os.execute("fplay sound.wav")` | Third-party; requires external tool |
| **macOS** | `afplay` | `os.execute("afplay sound.wav")` | Built-in to macOS |
| **Linux** | `aplay`, `paplay` (PulseAudio), `speaker-test` | `os.execute("aplay sound.wav")` | Available if ALSA or PulseAudio installed |
| **Linux** | `espeak` (text-to-speech) | `os.execute("espeak 'door creaks'")` | Alternative for descriptive sounds |

**Reality Check:**
- Terminal emulators (Windows Terminal, iTerm2, etc.) pass sound commands to OS
- Some minimal/remote terminals (SSH over network, headless servers) won't play sound
- No standard terminal bell works for music; limited to beep/click sounds
- **File size:** WAV files are large (uncompressed PCM); OGG/MP3 would need decompression

#### Terminal Implementation Strategy

```lua
-- Conditional sound playback with graceful fallback
if can_play_sound() then
    play_sound("door-creak.wav")  -- triggers os.execute() on supported systems
else
    print("[A door creaks open.] ")  -- fallback to text description
end
```

**Pros:**
- Works on any OS with `os.execute()`
- WAV files are uncompressed and fast to play
- Minimal latency

**Cons:**
- Requires external audio files on disk
- Blocking (freezes game loop while playing)
- Not all terminals support it (SSH, CI/CD, headless)
- File size overhead (WAV is ~176 KB/sec at 16-bit 44 kHz)

---

### 1.2 Web Browser (Fengari + JavaScript)

#### Can Fengari Play Sound?

**Yes.** Fengari is a **Lua 5.3 VM compiled to JavaScript**. It has full access to the JavaScript runtime.

**Web Audio APIs Available:**

| API | Fengari Access | Use Case |
|-----|--------|----------|
| **Web Audio API** | ✅ Via `js.global.AudioContext` | Full playback control, synthesis, effects |
| **HTML5 `<audio>` element** | ✅ Via DOM manipulation | Simple playback, streaming |
| **MediaElementAudioSourceNode** | ✅ Via Web Audio | Combine HTML5 audio with effects |
| **OscillatorNode** | ✅ Via Web Audio | Procedural/synthesized sounds (beeps, tones) |

#### Web Audio API via Fengari Example

```lua
-- Access JavaScript globals from Fengari Lua
local js = require("js")
local window = js.global
local AudioContext = window.AudioContext or window.webkitAudioContext

-- Create audio context (once)
local audioCtx = AudioContext.new()

-- Play a pre-loaded sound (simple case)
local audio_el = window.document:createElement("audio")
audio_el.src = "assets/door-creak.ogg"
audio_el:play()

-- Or use Web Audio API for low-latency synthesis
local oscillator = audioCtx:createOscillator()
oscillator.frequency.value = 440  -- A4 note
oscillator:connect(audioCtx.destination)
oscillator:start(0)
oscillator:stop(audioCtx.currentTime + 0.5)
```

**Browser Compatibility:**
- Chrome/Edge: ✅ Full Web Audio API
- Firefox: ✅ Full Web Audio API
- Safari: ✅ Full Web Audio API (iOS 13+)
- IE11: ❌ No Web Audio API

#### Browser Implementation Strategy

**Preload strategy:**
- Build an audio manifest at bundle time listing all sounds
- Lazy-load sounds on first use (HTTP cache handles subsequent requests)
- Use `<audio>` tags with `preload="metadata"` for fast seek/play

**Format choice:**
- **OGG Vorbis:** ~50% smaller than WAV, supported on all modern browsers
- **MP3:** Better support on older browsers, ~40% smaller than WAV
- **WAV:** Large but simplest, no decompression latency

**File size budget:**
- Bundle is already 16 MB uncompressed (3 MB gzipped); adding 1-2 MB of audio is acceptable
- ~20 unique sounds @ ~50 KB each (OGG) = 1 MB; gzipped ~300 KB

---

### 1.3 Sound-Optional Architecture

**The ideal approach:** Make sound an optional subsystem.

```
Game Engine
    ├── Core (no sound deps)
    ├── Events (state changes, FSM transitions, combat)
    └── Sound Layer (conditional)
        ├── Terminal: Play via os.execute() if available
        ├── Web: Play via Web Audio API
        └── Fallback: No-op if platform unsupported
```

**Advantages:**
- Game works perfectly without sound
- No degradation on unsupported platforms (SSH, CI, headless)
- Easy to add; easy to disable
- Can be toggled at runtime

---

## 2. Free Sound Sources

### 2.1 Creative Commons / Public Domain Libraries

#### **Zapsplat** (https://www.zapsplat.com)
- **Library size:** 100,000+ SFX (mostly CC0)
- **Quality:** Professional
- **Relevant sounds:** Door creaks, glass breaking, metal clanks, creature sounds, fire crackle, water, wind, footsteps, chains
- **Format:** MP3, OGG (custom download options available)
- **License:** Creative Commons 0 (public domain equivalent) or CC-BY
- **Cost:** Free with account
- **Best for:** High-quality, curated, specific SFX

#### **Freesound.org** (https://freesound.org)
- **Library size:** 700,000+ samples
- **Quality:** Highly variable (user-contributed)
- **Relevant sounds:** Everything — creature sounds, object interactions, ambient
- **License:** CC-BY, CC0, other (check each)
- **Cost:** Free with account (premium for bulk download)
- **Best for:** Breadth of options; careful curation required

#### **BBC Sound Effects Library** (https://sound-effects.bbcrewind.co.uk)
- **Library size:** 16,000+ SFX
- **Quality:** Broadcast-grade
- **Relevant sounds:** Door creaks, locks, chains, wind, fire, creature vocalizations
- **License:** CC-BY-NC (non-commercial use)
- **Cost:** Free
- **Caveat:** NC license means **cannot be used if game is sold commercially**

#### **OpenGameArt.org** (https://opengameart.org)
- **Library size:** 1,000+ curated game SFX
- **Quality:** Game-specific (realistic + stylized)
- **License:** CC0, CC-BY, CC-BY-SA (check each)
- **Cost:** Free
- **Best for:** Ready-to-use game audio (less curation needed)

#### **Epidemic Sound** (https://www.epidemicsound.com)
- **Library size:** 30,000+ SFX
- **Quality:** Professional
- **License:** Royalty-free for licensed users
- **Cost:** Subscription ($9-15/mo) or one-time license
- **Pro:** Excellent for commercial use if budget allows

#### **Sonniss.com** (https://sonniss.com)
- **Library size:** 7,000+ free SFX
- **Quality:** Professional
- **License:** CC0 or CC-BY
- **Cost:** Free
- **Best for:** Quick, reliable sourcing

### 2.2 Sound Categories & Recommendations

| Category | Recommended Source | Count | Examples |
|----------|-------------------|-------|----------|
| **Ambient (loops)** | Zapsplat, Freesound, BBC | 3-4 | fire crackle, wind, dripping water, stone creaks |
| **Creature sounds** | Zapsplat, Freesound (filtered) | 5-7 | rat squeak, cat meow/purr, wolf growl, bat screech, spider skitter |
| **Door/lock** | BBC, Zapsplat | 2-3 | door creak (wood), lock click, door slam |
| **Object impacts** | Zapsplat, Freesound | 3-4 | glass breaking, ceramic shard, chains rattling, wood strike |
| **Combat** | Zapsplat, OpenGameArt | 2-3 | hit/slash impact, punch, flesh wound |
| **Fire/light** | Zapsplat, BBC | 1-2 | match strike, candle light, torch whoosh |
| **Water/liquid** | Zapsplat, Freesound | 1-2 | water splash, pour, sloshing |
| **UI (optional)** | Sonniss, OpenGameArt | 1-2 | blip/notification, hum |

**Total estimated unique sounds: 18-23** (accounting for overlap)

### 2.3 License Considerations for Commercial Use

| License | Commercial Use? | Modifications? | Attribution? |
|---------|-----------------|---|---|
| **CC0** | ✅ Yes | ✅ Yes | ❌ No |
| **CC-BY** | ✅ Yes | ✅ Yes (with conditions) | ✅ **Required** |
| **CC-BY-NC** | ❌ **No** | ❌ No | ✅ Required |
| **CC-BY-SA** | ✅ Yes | ✅ Yes | ✅ Required (derivative must be SA) |
| **All Rights Reserved** | ❌ Contact owner | — | — |

**Recommendation:** Prioritize CC0 and CC-BY sources to avoid commercial licensing complications.

---

## 3. Objects & Creatures with Sound Potential

### 3.1 Creatures (All Have `on_listen`)

**Extracted from `src/meta/creatures/`:**

| Creature | States | On-Listen Examples | Sound Priority |
|----------|--------|-------------------|---|
| **Rat** | idle, wander, flee, dead | "Skittering claws on stone", "frantic squeaking" | **HIGH** — Distinct, frequent |
| **Cat** | idle, wander, flee, hunt, dead | "Purr", "silence of predator", "claws scrabbling" | **HIGH** — Multiple states |
| **Wolf** | idle, wander, patrol, aggressive, flee, dead | "Growl", "snarl", "panting" | **HIGH** — Territorial; loud |
| **Bat** | (TBD — not yet examined) | (TBD) | **MEDIUM** (pending file review) |
| **Spider** | (TBD — not yet examined) | (TBD) | **LOW** (less vocal) |

**Total objects with on_listen:** ~63 in objects/, all 5 creatures in creatures/

### 3.2 High-Priority Objects (FSM State Changes)

**Extracted from grep scan of `on_listen` fields:**

| Object | States | Event Triggers | Sound Fit |
|--------|--------|---|---|
| **Candle** | unlit → lit → spent | Light transition (crackling) | **HIGH** — "crackling & hiss" |
| **Rain Barrel** | (multi-state water) | Interaction (sloshing) | **MEDIUM** — Ambient water |
| **Doors/Exits** | closed/locked → open | Transit (creaking) | **HIGH** — 8+ door objects |
| **Chest/Containers** | closed → open | State change (creak, click) | **HIGH** — 5+ containers |
| **Mirrors** | intact → broken | Destruction (shatter) | **HIGH** — One-time impact |
| **Traps** | inactive → sprung | Activation (whoosh, boom) | **HIGH** — 2 trap objects |
| **Fire/Torch** | unlit → lit | Ignition (whoosh) | **MEDIUM** |

### 3.3 Ambient Objects (Constant `on_listen`)

These objects have `on_listen` but no FSM; they could trigger ambient loop sounds in room presence:

- **Incense burner/stick:** "Thin smoke curls upward" → slight sizzle loop
- **Well/water features:** Dripping, echoes
- **Stone/architecture:** Wind, creaks, settling
- **Ivy/vines:** Rustling

---

## 4. Integration Architecture

### 4.1 Event-Driven Sound System

The game already has **FSM state transitions**, which are perfect hooks for sound:

```lua
-- In engine/fsm/init.lua (or new sound module)
-- When object transitions state:

function trigger_state_sound(obj, old_state, new_state)
    -- Lookup sound in object definition
    if obj.sounds and obj.sounds[new_state] then
        play_sound(obj.sounds[new_state])
    end
    
    -- Or: infer from on_listen field
    if obj.states[new_state].on_listen then
        -- Map description to sound (heuristic or explicit)
        infer_and_play(obj.states[new_state].on_listen)
    end
end
```

### 4.2 Object Definition Extension

Each object gains optional `sounds` field:

```lua
return {
    id = "candle",
    -- ... existing fields ...
    
    -- NEW: Sound association
    sounds = {
        lit = "candle-ignite.ogg",      -- triggered on transition to "lit"
        extinguished = "candle-snuff.ogg",
    },
    
    states = {
        lit = {
            on_listen = "A gentle crackling...",
            -- Engine hooks sound on state entry
        },
    },
}
```

### 4.3 Creature FSM Sounds

Creatures already have rich FSM:

```lua
return {
    id = "rat",
    sounds = {
        ["alive-idle"] = "rat-quiet-chittering.ogg",
        ["alive-wander"] = "rat-scurrying.ogg",
        ["alive-flee"] = "rat-panic-squeak.ogg",
        dead = "silence",  -- or optional "death-squeak.ogg"
    },
    states = { /* existing */ },
}
```

### 4.4 Combat Sound Hooks

When injuries are inflicted:

```lua
-- In src/engine/injuries.lua
function inflict(target, injury_type)
    -- ... existing logic ...
    
    -- Sound trigger
    if target.sounds and target.sounds.injured then
        play_sound(target.sounds.injured)
    end
end
```

### 4.5 Verb Handler Sound Hooks

Existing verbs can trigger sounds:

```lua
-- In src/engine/verbs/init.lua
verbs.open = function(context, noun)
    local obj = find_object(noun)
    if obj then
        if obj.sounds and obj.sounds.open then
            play_sound(obj.sounds.open)
        end
        obj._state = "open"
    end
end
```

### 4.6 Player Action Sounds

Combat/movement/inventory actions:

```lua
-- Explicit registry for verb-to-sound mappings
local action_sounds = {
    hit = "impact-blunt.ogg",
    slash = "impact-slash.ogg",
    take = "item-pickup.ogg",
    drop = "item-drop.ogg",
    drink = "swallow.ogg",
}
```

---

## 5. File Size & Performance

### 5.1 Audio Format Comparison

| Format | Bitrate | 1 sec @ 44 kHz | 10 sec | Compression | Browser | Notes |
|--------|---------|-------|-----|----|---------|-------|
| **WAV** (uncompressed PCM, 16-bit stereo) | 1.4 Mbps | ~176 KB | 1.76 MB | None | ✅ | Large; instant playback |
| **MP3** (320 kbps) | 320 kbps | 40 KB | 400 KB | Lossy | ✅ | Good quality; widely supported |
| **OGG Vorbis** (128 kbps quality) | ~128 kbps | 16 KB | 160 KB | Lossy | ✅ (except Safari pre-iOS 14) | Smaller; excellent quality |
| **AAC** (128 kbps) | ~128 kbps | 16 KB | 160 KB | Lossy | ✅ (Safari, iOS) | Mobile-friendly |
| **FLAC** (lossless compression) | ~600 kbps | 75 KB | 750 KB | Lossless | ⚠️ (poor support) | Not recommended |

### 5.2 Typical Sound Durations & Sizes

| Sound | Duration | WAV | MP3 | OGG | Packed |
|-------|----------|-----|-----|-----|--------|
| Door creak | 1.5 sec | 264 KB | 60 KB | 24 KB | 10 KB |
| Rat squeak | 0.5 sec | 88 KB | 20 KB | 8 KB | 3 KB |
| Wolf growl | 2 sec | 352 KB | 80 KB | 32 KB | 12 KB |
| Fire crackle (looped) | 8 sec | 1.4 MB | 320 KB | 128 KB | 40 KB |
| Combat hit | 0.3 sec | 53 KB | 12 KB | 5 KB | 2 KB |

**Estimate for 18-sound game:**
- **WAV:** ~5 MB uncompressed
- **OGG:** ~400 KB (50x smaller)
- **Gzipped:** ~100 KB (50x smaller than OGG)

**Web bundle impact:** Adding 18 OGG sounds = +100-200 KB gzipped (negligible vs 16 MB baseline)

### 5.3 Performance Implications

**Terminal:**
- `os.execute()` is **blocking** — game freezes while sound plays
- Typical sound: 0.5–2 sec freeze (acceptable for immersion)
- Keep max sound duration < 3 sec

**Web:**
- Web Audio API is **non-blocking** (asynchronous)
- Browser handles mixing multiple sounds
- No performance penalty to game loop

---

## 6. Accessibility & Player Control

### 6.1 Sound Is Enhancement, Not Required

- **Always provide text fallback** — `on_listen` descriptions must be complete
- **Mute toggle:** Accessible in settings/UI
- **Volume control:** Slider (0–100%)
- **No sound = zero gameplay impact** (design principle)

### 6.2 Visual Indicators

When a sound plays, optionally display:
- `[sounds like: door creaking]` — helps deaf/hard-of-hearing players
- Timer showing sound is still playing (for immersion)

---

## 7. Comparison: How Other Text Adventures Use Sound

| Game | Platform | Sound Strategy | Impact |
|------|----------|---|---|
| **Zork (original)** | Terminal (1980s) | None — text-only | Pure imagination |
| **Anchorhead** | Web (modern) | Ambient music + localized SFX | Atmospheric immersion |
| **Sunless Sea** | Desktop (indie) | Full audio design (music + SFX) | Signature experience |
| **Twine games** | Web (modern) | Often minimal; some include ambient | Variable |
| **MUD1 / LPC worlds** | Network (real-time) | Text descriptions + occasional server-side SFX | Rare; text dominates |
| **Interactive Fiction (Inform 7)** | Interpreter (standardized) | Sound support via interpreter; rarely used | Niche |

**Lesson:** Text adventures rarely used sound historically; modern web-based games increasingly add it for atmosphere, but text remains primary.

---

## 8. Recommendations

### 8.1 Minimum Viable Sound Set (MVP) — Phase 1

**Start with 12–15 high-impact sounds:**

1. **Creature vocalizations (4):**
   - Rat: squeak/chitter
   - Cat: purr/meow
   - Wolf: growl/snarl
   - Bat: screech (if implemented)

2. **Door/passage (3):**
   - Door creak (wood, interior)
   - Lock click
   - Metal gate clang

3. **Object interactions (3):**
   - Glass shatter
   - Chain rattle
   - Metal strike

4. **Ambiance (2):**
   - Fire/candle crackle (looped)
   - Water drip (looped)

5. **UI (optional, 1):**
   - Subtle notification blip

**Estimated effort:** 2–3 hours sourcing + 4–6 hours integration

### 8.2 Implementation Phases

**Phase 1 (MVP):**
- Build sound-optional architecture (no-op if unavailable)
- Add 12–15 core sounds
- Hook creature FSM + key object transitions
- Terminal + web working independently

**Phase 2 (Polish):**
- Expand to 30–40 sounds (all objects with `on_listen`)
- Spatial audio (left/right speaker; 3D positioning)
- Volume ducking (dim when multiple sounds overlap)
- User preferences (mute, volume)

**Phase 3 (Future):**
- Ambient music (separate from SFX)
- Dynamic audio synthesis (create sounds procedurally)
- Sound mixing/effects (echo, reverb)

### 8.3 Recommended Sound Source Priority

1. **Zapsplat** — High-quality, curated, game-ready (start here)
2. **BBC Sound Library** — Broadcast-grade creature/environment sounds (secondary)
3. **OpenGameArt** — Pre-tagged game sounds (fill gaps)
4. **Freesound** — Breadth; requires curation (last resort)

### 8.4 Technical Decisions

- **Format:** OGG Vorbis for web (128 kbps); consider WAV for terminal (instant playback)
- **Storage:** `resources/audio/` directory; organize by category (creatures/, objects/, ambience/)
- **Terminal fallback:** Sound optional; no `os.execute()` required on unsupported systems
- **Web delivery:** Lazy-load on first use; HTTP cache handles subsequent requests
- **Licensing:** Prioritize CC0 + CC-BY to avoid commercial use restrictions

---

## 9. Decision Points

### D1: Which Platform First?

- **Web first** (easier, more impact)
- Terminal second (if desired for CLI playtesting)

### D2: Upgrade Objects to Include `sounds` Field?

- Yes — Minimal migration (add optional field to object definition)
- Keep FSM state names as primary trigger

### D3: Ambient vs Event-Driven?

- **Event-driven primary** (on state change, verb action)
- **Ambient secondary** (room loops for fire, water, wind)

### D4: Creatures Before Objects?

- Yes — Creatures are most vocal; higher impact

### D5: Music Later?

- Yes — Keep SFX and music separate
- Music is **not** part of this phase

---

## 10. References & Resources

- **Web Audio API Spec:** https://www.w3.org/TR/webaudio/
- **Fengari Documentation:** https://fengari.io/
- **Zapsplat:** https://www.zapsplat.com
- **OpenGameArt SFX:** https://opengameart.org/?types=sfx
- **BBC Sound Effects:** https://sound-effects.bbcrewind.co.uk
- **OGG Vorbis Codec:** https://xiph.org/vorbis/
- **Game Audio Best Practices:** *Game Engine Architecture*, Jason Gregory (Ch. 12)

---

## Conclusion

**Sound is feasible & impactful.** The architecture is clean, the web path is smooth, the terminal path is optional, and the free resources are abundant. A minimum viable sound set (12–15 effects) would significantly enhance immersion without breaking the game or bloating the bundle.

**Recommended next step:** Curate the 12–15 MVP sounds from Zapsplat/BBC; create a sound manifest; propose Phase 1 implementation to Wayne.
