# Sound System — Unified Design Document

**Version:** 1.2  
**Status:** Production-ready (WAVE-5 complete, MVP infrastructure shipped)  
**Audience:** Content creators, object designers, room builders, web audio engineers, game designers  
**Owner:** Bart (Architecture Lead), Comic Book Guy (Game Design), Gil (Web Pipeline)  
**Last Updated:** 2026-03-29

---

## Executive Summary

The MMO sound system is a **platform-agnostic Lua sound manager** with pluggable drivers that transforms the text adventure from "reading a story" to "being in a place." 

**Current State:** Infrastructure complete. Engine supports 21-method sound API, Web Audio driver with synthetic fallback tones, room ambient declarations (all 7 rooms), 20+ object sound metadata, 266-test suite. MVP implementation production-ready. **Awaiting real audio assets (Phase 1).**

**Three Iron Laws:**
1. **Text is canonical, sound is additive.** Every sound event has a text equivalent. Deaf players miss zero gameplay information. Sound enhances emotional texture, never conveys data.
2. **Lazy loading.** Sounds load when objects/rooms load. No bulk preload. Mobile-friendly.
3. **Pre-compressed.** OGG Opus @ 48 kbps (not MP3, not WAV). Browser decodes natively.

---

## Vision Statement

The game starts at 2 AM in total darkness. The player navigates by **feel and hearing** before ever reaching light. Sound becomes the primary sense alongside touch.

**Core Promise:** Sound is optional but irreplaceable. It adds emotional depth to every interaction without replacing the text. The game is fully playable on mute; with sound, it becomes immersive.

---

## Design Philosophy

### Accessibility First

**Dual-Channel Principle:** Every game event produces TWO outputs:
1. **Text** (always present, always complete, always canonical)
2. **Sound** (optional enhancement, adds emotional texture)

The text is not a transcript of the sound. The text IS the game. The sound is the atmosphere.

```
Player types: OPEN DOOR

Game outputs:
  TEXT:  "The heavy oak door groans open on iron hinges."
  SOUND: [door-creak-heavy.ogg plays]

Player types: OPEN DOOR (with sound muted)

Game outputs:
  TEXT:  "The heavy oak door groans open on iron hinges."
  SOUND: (nothing — game is identical)
```

### What Sound Must NEVER Do

- **Never convey unique gameplay information.** If a sound tells you "a rat is in the next room," the text MUST also say it.
- **Never be required for a puzzle.** No "listen for the right number of clicks" puzzles.
- **Never replace `on_listen` text.** The `on_listen` field IS the canonical auditory description. Sound files are an *additional* parallel channel.
- **Never block the game loop.** Sound is wrapped in `pcall()` everywhere. Sound failure never crashes the game.

### When to Add Sounds to Objects

✅ **Add sounds:**
- Light sources (candle, torch, match) — ignition, burn, extinguishment
- Doors and passages — opening, closing, creaking
- Breakable objects (mirror, glass) — impact, shattering, cracking
- Creatures — vocalizations, movement, combat
- FSM state changes — any transition with physical consequence

❌ **Skip sounds:**
- Static objects (walls, furniture, decorative items)
- Objects that don't change (books, paintings)
- Objects with no physical action
- Objects where silence is intentional (dead creatures, spent candles)

**Design Rule on Silence:** Dead creatures and hunting cats produce NO sound. This is deliberate — the *absence* of the cat's purr tells the player something has changed. The text says "Nothing. The purr is gone." and the silence confirms it. Do not add a death sound for creatures. The silence IS the sound.

---

## Sound Priority Tiers (Game Design)

Every sound category ranked by player impact. The question: *does this sound make the player feel more present in the world?*

### Tier 1 — Must-Have (Ship Without These and You've Failed)

These sounds create the emotional foundation. A first-time player hearing a wolf growl while reading "A deep, rumbling snarl that vibrates the air" will remember that moment.

| Category | Why It's Tier 1 | Examples |
|----------|----------------|----------|
| **Creature vocalizations** | Creatures are the primary threat. Hearing a wolf growl before you see it (darkness!) creates genuine tension. | Wolf growl/snarl, rat squeak/skitter, cat hiss/purr, bat screech/wing-flutter, spider skitter |
| **Door/passage transitions** | The player opens doors constantly. This is the most frequent interaction that benefits from sound. | Wood door creak, lock click/unlock, iron gate clang, trapdoor thud |
| **Fire/light ignition** | Lighting a candle is the game's signature moment — going from darkness to sight. | Match strike, candle ignite, torch crackle, lantern light |
| **Combat impacts** | When a wolf bites or a bear trap snaps, the sound sells the danger. | Bite/claw impact, blunt impact, trap snap, flesh wound |

### Tier 2 — High-Value (Immersion Multipliers)

These sounds transform the experience from "reading a story" to "being in a place."

| Category | Why It's Tier 2 | Examples |
|----------|----------------|----------|
| **Ambient room loops** | Per-room atmosphere. The cellar drips. The courtyard has wind. | Water drip, wind, torch crackle, stone settling, silence |
| **Container interactions** | Opening chests, drawers, crates — the satisfying click and creak of discovery. | Chest open creak, drawer slide, crate lid scrape, latch click |
| **Object destruction** | One-time but memorable. Breaking a mirror, shattering a vase. | Glass shatter, wood snap, ceramic break |
| **Liquid/water sounds** | Water is everywhere — the well, rain barrel, poison bottle, wine. | Water slosh, pour, drip, splash |

### Tier 3 — Nice-to-Have (Polish)

These complete the picture but can wait for Phase 2+.

| Category | Why It's Tier 3 | Examples |
|----------|----------------|----------|
| **UI/system sounds** | Subtle feedback. A soft chime when you pick up an item. | Item pickup, item drop, inventory rustle |
| **Clock ticking** | A single room object. Atmospheric detail. | Clock tick loop |
| **Mechanical/chain sounds** | Specific interactions. | Chain clink/rattle, winch creak, spring release |
| **Weather/environmental** | Rain on cobblestones, wind through ivy. | Rain patter, owl hoot, ivy rustle |
| **Textile/soft sounds** | Subtle and barely perceptible. | Cloth rustle, curtain swish |

---

## Sound-Per-Object Audit

### Creatures (All Have Per-State Sounds)

Every creature has rich, state-specific audio descriptions. Each state transition triggers a distinct sound.

| Creature | State | on_listen Text | Sound File | Priority |
|----------|-------|---|---|---|
| **Rat** | idle | "Quiet chittering. The soft rasp of fur being groomed." | `rat-idle.ogg` | T1 |
| | wander | "The rapid click of tiny claws on stone." | `rat-skitter.ogg` | T1 |
| | flee | "Frantic squeaking and the scrabble of claws." | `rat-squeak-panic.ogg` | T1 |
| | dead | "Nothing. Absolutely nothing." | *(silence)* | — |
| **Cat** | idle | "A faint purr, barely audible." | `cat-purr.ogg` | T1 |
| | hunt | "Nothing. The silence of a predator." | *(silence — intentional)* | — |
| | flee | "Claws scrabbling, hiss of expelled air." | `cat-hiss.ogg` | T1 |
| **Wolf** | idle | "Slow breathing. Faint click of claws." | `wolf-breathe.ogg` | T2 |
| | patrol | "A low, rhythmic growl — a warning." | `wolf-growl-low.ogg` | T1 |
| | aggressive | "A deep, rumbling snarl that vibrates air." | `wolf-snarl.ogg` | T1 |
| | flee | "Rapid panting and claws on stone." | `wolf-pant.ogg` | T2 |
| **Bat** | flying | "The snap of leathery wings and squeaking." | `bat-wings.ogg` | T1 |
| | flee | "Frantic squeaking and frenzied wing beats." | `bat-screech.ogg` | T1 |
| **Spider** | idle | "Faint scratching, like tiny claws on stone." | `spider-scratch.ogg` | T2 |
| | flee | "A frantic skittering across stone." | `spider-skitter.ogg` | T2 |

### Objects with FSM State Changes

| Object | Transition | Sound File | Priority |
|--------|-----------|---|---|
| **Candle** | unlit → lit | `candle-ignite.ogg` | T1 |
| **Match** | unlit → lit | `match-strike.ogg` | T1 |
| **Torch** | unlit → lit | `torch-ignite.ogg` | T1 |
| **Oil Lantern** | unlit → lit | `lantern-ignite.ogg` | T1 |
| **Mirror** | cracked → shattered | `glass-shatter.ogg` | T1 |
| **Bear Trap** | set → sprung | `trap-snap.ogg` | T1 |
| **Falling Club Trap** | armed → sprung | `trap-club-swing.ogg` | T1 |
| **Falling Rock Trap** | armed → sprung | `trap-rock-fall.ogg` | T1 |
| **Unstable Ceiling** | stressed → collapsed | `ceiling-collapse.ogg` | T1 |

### Door/Passage Objects

8 distinct door objects. Doors share a small set of sound files. Material variation is expressed through text, not through 15 unique sounds.

| Object | Event | Sound File | Priority |
|--------|-------|---|---|
| **Heavy Doors** | open | `door-creak-heavy.ogg` | T1 |
| **Light Doors** | open | `door-creak-light.ogg` | T2 |
| **Locked Door** | unlock | `lock-click.ogg` | T1 |
| **Iron Gate** | open | `gate-clang.ogg` | T1 |
| **Trapdoor** | open | `trapdoor-thud.ogg` | T1 |
| **Window** | break | `glass-shatter.ogg` | T1 |

---

## Architecture Overview

### Platform-Agnostic Lua Sound Manager

The sound system is built in Lua (zero external dependencies) with pluggable platform drivers:

- **Lua Core** (`src/engine/sound/init.lua`): Sound manager with 21-method API
- **Web Audio Driver** (`src/engine/sound/web-driver.lua`): Bridges to Web Audio API (browser)
- **Terminal Driver** (`src/engine/sound/terminal-driver.lua`): Best-effort platform support (macOS/Linux/Windows)
- **Null Driver** (`src/engine/sound/null-driver.lua`): Silent fallback (headless mode, tests)

### Web Audio Driver

**File:** `web/audio-driver.js` (100 LOC)

When a sound plays:

```
1. Lua calls: sound_manager:play("door-creak.opus", opts)
2. web-driver.lua wraps this: window:_soundPlay("door-creak.opus", opts)
3. audio-driver.js checks: Does "sounds/door-creak.opus" exist?
   - YES → fetch + decodeAudioData() → play from buffer
   - NO  → generate synthetic tone (oscillator) + play
4. Result: Sound plays in-browser; game continues
```

### Synthetic Fallback Tones (TEMPORARY PLACEHOLDER ONLY)

⚠️ **IMPORTANT:** Synthetic tones are **temporary development placeholders ONLY**. For production, all sounds come from free libraries (Zapsplat, BBC Sound Effects, OpenGameArt) — no self-generated sounds.

**Development fallback (when real assets missing):**
- **One-shot sounds** (verb actions): Beep + envelope (attack/decay)
- **Ambient loops** (room atmosphere): Low-frequency drone (80 Hz sine wave)
- **Creature sounds** (vocalizations): Mid-frequency oscillator (440 Hz A note) with tremolo

**Production sourcing (Phase 1 MVP):** Real audio assets sourced from free CC0/CC-BY libraries using concrete shopping list (see `projects/sound/plan.md` WAVE-1 for details). No synthetic tones ship in production.

---

## Ambient Sound Design

### Per-Room Ambient Loops

Each room has a distinct sonic identity. Ambient loops play continuously while the player is in the room.

| Room | Ambient Loop | Source Text | Duration | Notes |
|------|-------------|---|---|---|
| **Bedroom** | `amb-bedroom-silence.ogg` | *(no on_listen — intentionally quiet)* | 30s loop | Near-silence with occasional settling stone. Very low volume. |
| **Hallway** | `amb-hallway-torches.ogg` | "The crackle and hiss of torches... footsteps on oak... creak of timbers" | 20s loop | Torch crackle dominant. Occasional timber creak. |
| **Cellar** | `amb-cellar-drip.ogg` | "Water dripping in darkness... cold, heavy air" | 30s loop | Irregular water drips echoing. The definitive dungeon sound. |
| **Storage Cellar** | `amb-storage-scratching.ogg` | "Scratching. Small, quick, furtive — rats in walls... wood creaking" | 25s loop | Rat scratching + old wood creaking. Unsettling. |
| **Deep Cellar** | `amb-deep-cellar-silence.ogg` | "Silence. A deeper silence... stone absorbs sound" | 40s loop | Almost nothing. Occasional faint echo. Oppressive. |
| **Crypt** | `amb-crypt-void.ogg` | "Nothing. Absolute silence... This silence has weight" | 60s loop | Quietest ambient. Single stone-settling sound every 45–60s. |
| **Courtyard** | `amb-courtyard-wind.ogg` | "Wind... breeze lifting ivy... well winch creak... owl hoot... water dripping" | 30s loop | Wind primary. Layered owl hoot, well winch creak, ivy rustle. |

### Time-of-Day Variation

The game runs on a 1-hour-per-day cycle. Time-of-day should affect ambient sound (Phase 5 feature):

| Time | Variation | Rooms Affected |
|------|-----------|---|
| **2 AM – 5 AM (deep night)** | Darkest. Wind coldest. Owl hoots in courtyard. Cellar drips echo more. Interior rooms quietest. | All |
| **5 AM – 6 AM (pre-dawn)** | Bird sounds begin faintly in courtyard. Wind shifts. Interior rooms unchanged. | Courtyard |
| **6 AM – 6 PM (daytime)** | Courtyard gets distant activity (cart wheels, wind through trees). Interior rooms slightly warmer in tone. | Courtyard, Hallway |
| **6 PM – 9 PM (evening)** | Courtyard wind peaks. Owl activity peaks. | Courtyard |

---

## Implementation: How to Add Sounds to Objects

### Step 1: Edit Your Object File

Open your object in `src/meta/objects/{name}.lua`. Add a `sounds` table at the root level:

```lua
return {
    guid = "{your-uuid}",
    id = "candle",
    name = "a tallow candle",
    -- ... other fields ...

    -- Sound events (new section)
    sounds = {
        on_state_lit = "candle-ignite.opus",
        on_verb_extinguish = "candle-blow.opus",
        ambient_lit = "candle-flame.opus",
    },

    -- ... rest of fields ...
}
```

### Step 2: Verify Sensory Descriptions

Every object with sounds **MUST** have `on_feel` and `on_listen`:

```lua
on_feel = "Waxy cylinder, cool to the touch.",
on_listen = "Faint tallow smell and the soft hiss of melting wax.",
```

### Step 3: Sound Key Resolution Chain

The engine resolves sounds in this priority order:

1. **Exact match:** `on_state_lit` for state "lit"
2. **Verb on object:** `on_verb_break` for "break" command
3. **Default verb:** `on_verb_default` for unhandled verbs
4. **Ambient:** `ambient_*` for continuous sounds

If a key doesn't exist, the sound doesn't play — no error.

### Step 4: Test

```bash
lua test/sound/test-sound-metadata.lua
```

Verify:
- Sound files exist in `assets/sounds/`
- Metadata keys are valid
- No typos in sound IDs

---

## Compression Strategy

### Format: OGG Opus

| Criterion | OGG Opus | OGG Vorbis | MP3 | WAV |
|-----------|----------|------------|-----|-----|
| File size (1s @ 48kHz) | ~6 KB | ~16 KB | ~40 KB | ~176 KB |
| Quality at low bitrate | Excellent | Good | Fair | Perfect |
| Browser decode native | ✓ | ✓ | ✓ | ✓ |
| Safari support | ✓ (iOS 15+) | ✓ (iOS 14+) | ✓ | ✓ |

**Decision: OGG Opus at 48 kbps mono.** Reasons:
- SFX are short (0.3–3s), mostly non-music — Opus excels here
- ~6 KB per second vs 16 KB (Vorbis) — 60% smaller
- Browser `decodeAudioData()` handles decompression natively
- Safari has supported Opus since iOS 15 / macOS Monterey (2021)

### File Size Budget

| Sound type | Typical duration | Size @ 48kbps Opus | Count | Subtotal |
|------------|------------------|--------------------|-------|----------|
| Short SFX (hit, click, squeak) | 0.3–1s | 2–6 KB | 10 | ~40 KB |
| Medium SFX (door creak, growl) | 1–3s | 6–18 KB | 6 | ~70 KB |
| Ambient loops (fire, water) | 5–8s | 30–48 KB | 3 | ~120 KB |
| **Total MVP (18 sounds)** | | | **~19** | **~230 KB** |

For context: the engine bundle is 232 KB compressed. Sound adds ~230 KB — roughly doubling static assets, but still under 500 KB total.

---

## Asset Sourcing Strategy

### Sources: Free Sound Libraries Only

Per Wayne's directive, **all sounds are sourced from free libraries — NO self-generated or synthesized sounds.**

**Primary sources:**
- **Zapsplat.com:** 100,000+ CC0 sound effects; high-quality, curated, game-ready. Start here for 80% of MVP sounds.
- **BBC Sound Effects Library:** 16,000+ broadcast-grade effects (creatures, environment, ambience); CC-BY-NC or CC0.
- **OpenGameArt.org:** 1,000+ game-ready SFX, CC0/CC-BY licensed, pre-optimized for games.

**Shopping List & Search Terms:** See `projects/sound/plan.md` WAVE-1 section for concrete asset list with Zapsplat search terms (water drip, wolf growl, door creak, etc.).

**Licensing:**
- ✅ **CC0** (preferred) — No attribution required, full commercial use
- ✅ **CC-BY** — Requires attribution, full commercial use
- ⚠️ **CC-BY-NC** — Non-commercial only; use only with Wayne's approval

**Attribution & Manifest:**
1. Capture source URL and artist name for each asset
2. Document in `assets/sounds/README.md` with full license text
3. Generate `assets/sounds/manifest.json` with source metadata (source, artist, license)
4. Ship manifest alongside compressed sounds to `web/dist/sounds/`

---

## Deployment Architecture

### Repository Structure

```
assets/
├── sounds/
│   ├── README.md              # License info, source attribution
│   ├── creatures/
│   │   ├── rat-squeak.opus
│   │   ├── cat-purr.opus
│   │   ├── wolf-growl.opus
│   │   ├── bat-screech.opus
│   ├── objects/
│   │   ├── glass-shatter.opus
│   │   ├── door-creak.opus
│   │   ├── lock-click.opus
│   │   ├── match-strike.opus
│   │   ├── candle-crackle.opus
│   ├── combat/
│   │   ├── hit-blunt.opus
│   │   ├── hit-slash.opus
│   ├── ambient/
│       ├── fire-loop.opus
│       ├── water-drip-loop.opus
```

### Build Pipeline

Sound files do NOT go through the engine bundle. They're static assets deployed alongside meta files.

**Build step** (`build-sounds.ps1`):
1. Read assets/sounds/**/*.opus
2. Validate: each file < 100 KB, is valid Opus
3. Copy to web/dist/sounds/ (flat namespace, no subdirectories)
4. Generate sounds/_manifest.json listing all available sound IDs

**Deploy step** (deploy.ps1 addition):
5. Copy web/dist/sounds/ => ../WayneWalterBerry.github.io/play/sounds/
6. Standard git add/commit/push

**Flat namespace for deployment.** Subdirectories in the source repo are organizational — deployment flattens to `sounds/{id}.opus`. This keeps Lua references simple: `sound.load("rat-squeak")` => fetches `sounds/rat-squeak.opus`.

---

## Web Integration

### Lazy Loading Pipeline

**Trigger:** Room Load

The existing room loader in `game-adapter.lua` already fetches room definitions and their objects on demand. Sound loading piggybacks on this flow.

```
Player enters room -> game-adapter.lua: load_room(room_id)
  -> For each object instance:
    -> load_object(guid)
    -> If obj.sounds exists:
      -> For each sound_id in obj.sounds:
        -> window:_soundLoad(sound_id, "sounds/" .. sound_id .. ".opus")
  -> (JS fetches async — doesn't block room loading)
  -> Room renders, player sees text immediately
  -> Sounds arrive in background, ready when needed
```

### JS Async Fetch + Decode

```javascript
window._soundLoad = function(id, url) {
    if (_audioBuffers[id]) return;  // already loaded
    if (!_ensureAudioContext()) return;  // no audio support
    
    fetch(url)
        .then(function(response) {
            return response.arrayBuffer();
        })
        .then(function(data) {
            return _audioCtx.decodeAudioData(data);
        })
        .then(function(buffer) {
            _audioBuffers[id] = buffer;
        })
        .catch(function(err) {
            // Silent failure — sound is optional
        });
};
```

**Key design choice:** Async fetch, non-blocking. The room text appears before sounds are ready. If a sound plays before its buffer arrives, it's a silent no-op.

### Cache Strategy

**In-memory buffer cache** (`_audioBuffers` object):
- Decoded `AudioBuffer` objects stay in memory after first load
- No eviction in MVP — 18 sounds ~50 KB decoded PCM = ~900 KB RAM. Negligible.
- Phase 2: LRU eviction if sound count grows past ~50

**HTTP caching:**
- Browser HTTP cache handles repeat fetches automatically
- Same `?v=CACHE_BUST` pattern as all other assets
- Cache-bust on deploy, cached between deploys

### Autoplay Policy

**The Problem:** Modern browsers block `AudioContext` playback until the user interacts with the page.

**The Solution:** First keypress unlocks audio. The player MUST type a command to play the game. Their first `Enter` keypress is the user interaction that unlocks `AudioContext`.

```javascript
inputEl.addEventListener('keydown', function (e) {
    // Unlock AudioContext on first interaction
    _ensureAudioContext();
    if (e.key === 'Enter') {
        // ... existing command processing ...
    }
});
```

**Timeline:**
```
Page loads => AudioContext created but suspended
  -> Player sees welcome text, room description (text only, no sound)
  -> Player types first command, presses Enter
  -> keydown handler calls _ensureAudioContext() => AudioContext.resume()
  -> AudioContext now running — sounds can play
```

No "click to enable sound" banner needed. The game's natural interaction model (typing commands) provides the user gesture.

### Fallback — When Audio Isn't Available

| Scenario | Detection | Behavior |
|----------|-----------|----------|
| Old browser (no Web Audio) | `window.AudioContext` is undefined | All `_soundXxx` calls are no-ops |
| User disabled audio | Mute toggle sets `_audioMuted = true` | `_soundPlay` returns immediately |
| Autoplay blocked | `AudioContext.state === 'suspended'` | Sounds queue silently; start after first interaction |
| Network error | `fetch()` rejects | Log warning; buffer stays empty; play is no-op |
| Memory pressure | `decodeAudioData` rejects | Same as network error — silent fallback |
| iOS low-power mode | AudioContext may be restricted | Same suspended-state handling |

**Design Principle:** The game is text-first. Sound is additive. Every sound-triggering event already produces text output. The text is ALWAYS emitted regardless of sound state.

---

## Player Controls (MVP)

| Control | Default | Notes |
|---------|---------|-------|
| Master volume | 80% | Single slider, 0–100% |
| Sound effects toggle | ON | On/off for all SFX |
| Ambient toggle | ON | Separate from SFX — some players want action sounds but not loops |
| Creature sound toggle | ON | Some players find creature sounds anxiety-inducing — respect that |
| Text-only mode | OFF | When ON, suppresses all audio (equivalent to muting, but explicit) |

**No separate volume sliders for SFX vs. ambient vs. creatures in MVP.** A single master volume + three toggles is sufficient. Full mixer UI is Phase 2+ if needed.

### Screen Reader Compatibility

Sound files MUST NOT interfere with screen reader output. The sound layer:
- Does not generate any text of its own
- Does not consume keyboard input
- Does not modify the DOM in ways that trigger aria-live announcements
- Plays at a volume that doesn't mask TTS output (duck to 50% if TTS detected — future consideration)

---

## Accessibility Design

### The Dual-Channel Principle

Every game event produces TWO outputs:
1. **Text** (always present, always complete, always canonical)
2. **Sound** (optional enhancement, adds emotional texture)

### What Sound Must NEVER Do

- **Never convey unique gameplay information.** If a sound tells you something, the text must too.
- **Never be required for a puzzle.** No "listen for the right number of clicks" puzzles.
- **Never replace `on_listen` text.** The `on_listen` field continues to be the canonical auditory description.
- **Never block the game loop.** Sound is wrapped in `pcall()` everywhere. Sound failure never crashes the game.
- **Never be required to unlock content.** Sound is opt-in everywhere.

### Enhanced `on_listen` Text for Deaf Players

For all sound effects, ensure the `on_listen` field is detailed enough that a deaf player can understand what's happening:

```lua
on_listen = "A distant splash, then the faint dripping of water."
-- (This text is accompanied by the splash sound in hearing players' experience)
```

---

## Key Design Decisions

1. **Text is canonical, sound is additive.** Every sound event has a text equivalent. Zero gameplay information exclusive to audio. Game fully playable on mute.

2. **Accessibility first.** Deaf players miss nothing. Screen reader compatible. Master volume + toggles for effects, ambients, creatures, text-only mode.

3. **Lazy loading.** Sounds load when their object/room loads — no bulk preload. Room transitions queue sounds in background (~30–80 KB per room).

4. **Pre-compressed.** OGG Opus @ 48 kbps (not MP3, not WAV). Browser's `decodeAudioData()` handles decompression natively. ~60% smaller than Vorbis.

5. **Platform abstraction.** Platform-agnostic Lua sound manager with swappable drivers: Web Audio (Fengari bridge), terminal (os.execute), no-op (headless).

6. **Autoplay policy:** First keypress unlocks AudioContext (browser policy). Game requires typing anyway — no "click to enable" banner needed.

7. **Fire-and-forget integration.** Sound is wrapped in `pcall()` everywhere. Sound failure never crashes the game.

8. **Dead = silence.** Creatures that die produce NO death sound. Absence of sound is the signal. Hunting cat in silence = intentional tension.

---

## Quick Reference: Object Sound Fields

```lua
sounds = {
    -- State change sounds (triggered on FSM transition)
    on_state_<state> = "sound-file.opus",
    
    -- Verb action sounds (triggered when verb is executed on object)
    on_verb_<verb> = "sound-file.opus",
    
    -- Default verb sound (fallback if specific verb sound not found)
    on_verb_default = "sound-file.opus",
    
    -- Ambient/continuous sounds (loops while object is active)
    ambient_<state> = "sound-file.opus",
}
```

Example:

```lua
sounds = {
    on_state_lit = "candle-ignite.opus",
    on_state_unlit = "candle-snuff.opus",
    on_verb_break = "candle-snap.opus",
    ambient_lit = "candle-crackle-loop.opus",
}
```

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Audio file adoption** | 24/24 MVP assets deployed | Commit references in board |
| **Creature audio immersion** | Players report tension from audio | LLM walkthrough feedback |
| **Accessibility parity** | Deaf players access 100% of info | Accessibility audit checklist |
| **Audio performance** | <50 ms latency, <2 MB RAM | Profiler logs, memory sampling |
| **Cross-platform consistency** | Web/terminal sound parity (best-effort) | Platform support matrix |
| **Zero audio regressions** | Full test suite passes (266+) | CI/CD gate |
| **File size budget** | <500 KB total (compressed) | Asset size audit |

---

## North Star Roadmap (Post-MVP Phases)

### Phase 1: Real Audio Assets (P0 — MVP)
**Goal:** Replace synthetic fallback tones with real audio files.
- 24 OGG Opus files (~230 KB total), sourced, compressed, deployed
- Owner: CBG (Creative Direction), Gil (Web Build)
- Timeline: 2–3 weeks

### Phase 2: Object-Specific Sounds (P1)
**Goal:** Expand sound vocabulary beyond creatures and doors.
- Container interactions, traps, puzzles, environmental reactions
- Owner: Flanders (Object Content), CBG (Sound Design)
- Timeline: 3–4 weeks

### Phase 3: Creature Sound Evolution (P1)
**Goal:** Deepen creature audio identity — per-state sounds, behavioral variation.
- Per-state creature sounds (idle, hunting, fleeing, injured, dead)
- Creature interactions, pack dynamics
- Owner: Flanders (Creatures), Combat team (Injuries)
- Timeline: 4–5 weeks

### Phase 4: Combat Audio Immersion (P2)
**Goal:** Make combat visceral through sound.
- Weapon impact sounds, armor feedback, injury-specific sounds
- Owner: Combat team (damage pipeline), Flanders (Creature audio)
- Timeline: 3–4 weeks

### Phase 5: Ambient Time-of-Day Variation (P3)
**Goal:** World evolves sonically throughout the day.
- Night-time vs. daytime ambient variation, crossfades
- Owner: Gil (Ambient loop library), Moe (Room ambient design), L2 team
- Timeline: 2–3 weeks (deferred to Level 2)

### Phase 6: Weather & Environmental Audio (P3)
**Goal:** Weather becomes sonically mechanical — rain, wind, fog.
- Rain soundscape, wind effects, thunder, fog audio
- Owner: Level 2 team (weather engine), Gil (Audio mixing)
- Timeline: 3–4 weeks (deferred to Level 2)

### Phase 7: Music & Score (Optional — Design Pending)
**Goal:** Establish whether MMO wants diegetic vs. non-diegetic music.
- Owner: CBG (Creative), TBD (Composer)
- Timeline: 4–6 weeks (if approved)

### Phase 8: Accessibility & Accessibility Modes (P2)
**Goal:** Ensure deaf and hard-of-hearing players lose nothing.
- Haptic feedback layer, enhanced `on_listen` text, sound toggle UI
- Owner: Accessibility team (TBD), Smithers (UI)
- Timeline: 2–3 weeks

### Phase 9: Advanced Audio Features (P3)
**Goal:** Mature audio engine with spatial awareness, dynamic mixing.
- Spatial audio, volume ducking, per-category volume controls, LRU cache
- Owner: Gil (Web Audio), Nelson (Testing)
- Timeline: 3–4 weeks

---

## Risk Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|-----------|
| Asset sourcing delays | Medium | Pre-source backup library, royalty-free options, or commission composer early |
| Browser autoplay policy | Low | First keypress unlocks; document in release notes |
| Mobile audio context suspend | Low | Test on mobile; implement context resume on focus |
| Spatial audio API variance | Medium | Fallback to stereo mixing if panning unavailable |
| Audio memory pressure (50+) | Very Low | Phase 2 LRU cache; start aggressive at 1 MB decoded |
| Creature audio overlaps | Low | Max 3 concurrent creatures; priority system |
| Level 2 delay | Medium | Design Phase 5 as standalone; defer L2 coupling |

---

## Quick Links

- **Current Board:** `projects/sound/board.md`
- **Implementation Plan:** `projects/sound/plan.md`
- **Sound Architecture:** `docs/architecture/engine/sound-system.md`

---

**Last Updated:** 2026-03-29  
**Next Review:** When Phase 1 assets are 50% sourced  
**Escalation:** If Phase 1 assets blocked >1 week, escalate to Wayne via `.squad/decisions/inbox/kirk-sound-phase1-blocked.md`


