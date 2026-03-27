# WEB AUDIO PIPELINE — Sound Implementation Plan

**Author:** Gil (Web Engineer)  
**Date:** 2026-03-27  
**Status:** Plan (not yet implemented)  
**Depends on:** Frink's sound research (`resources/research/sound/sound-effects-research.md`)

---

## 1. Web Audio API Integration

### How Lua Calls Web Audio

The game runs Lua in Fengari (Lua 5.3 compiled to JavaScript). Fengari has full access to the JS runtime via `require("js")`. Sound calls originate in Lua (the engine emits `sound.play("glass-shatter")` on a state transition or verb handler) and cross into JavaScript through bridge functions exposed on `window`.

**The bridge pattern already exists.** Today `game-adapter.lua` calls JS via `window:_appendOutput()`, `window:_updateStatusBar()`, `window:_openUrl()`, etc. Sound follows the exact same pattern — JS functions on `window`, called from Lua.

### Architecture Layers

```
┌──────────────────────────────────────────┐
│  Lua Engine (Fengari)                    │
│  ┌────────────────────────────────────┐  │
│  │  sound module (engine/sound.lua)   │  │
│  │  sound.play("glass-shatter")       │  │
│  │  sound.load("rat-squeak", url)     │  │
│  └──────────┬─────────────────────────┘  │
│             │ calls window:_soundXxx()   │
├─────────────┼────────────────────────────┤
│  JS Bridge  │ (bootstrapper.js)          │
│  ┌──────────▼─────────────────────────┐  │
│  │  window._soundPlay(id, opts)       │  │
│  │  window._soundLoad(id, url)        │  │
│  │  window._soundStop(id)             │  │
│  │  window._soundUnload(id)           │  │
│  │  window._soundIsLoaded(id) → bool  │  │
│  └──────────┬─────────────────────────┘  │
│             │ Web Audio API              │
│  ┌──────────▼─────────────────────────┐  │
│  │  AudioContext                      │  │
│  │  ├── GainNode (master volume)      │  │
│  │  └── AudioBufferSourceNode(s)      │  │
│  │      (one per concurrent sound)    │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

### JS Functions to Expose (in bootstrapper.js)

```javascript
// --- Audio subsystem (added to bootstrapper.js) ---

var _audioCtx = null;        // Created on first user interaction
var _masterGain = null;      // Master volume node
var _audioBuffers = {};      // { id: AudioBuffer } — decoded, ready to play
var _activeSources = {};     // { id: AudioBufferSourceNode } — currently playing
var _audioMuted = false;

// Resume/create AudioContext (called on first keydown)
function _ensureAudioContext() {
    if (_audioCtx && _audioCtx.state === 'running') return true;
    if (!_audioCtx) {
        var AC = window.AudioContext || window.webkitAudioContext;
        if (!AC) return false;  // browser doesn't support Web Audio
        _audioCtx = new AC();
        _masterGain = _audioCtx.createGain();
        _masterGain.connect(_audioCtx.destination);
    }
    if (_audioCtx.state === 'suspended') {
        _audioCtx.resume();
    }
    return _audioCtx.state === 'running';
}
```

---

## 2. Compression Strategy

### Format: OGG Opus

| Criterion | OGG Opus | OGG Vorbis | MP3 | WAV |
|-----------|----------|------------|-----|-----|
| File size (1s @ 48kHz) | ~6 KB | ~16 KB | ~40 KB | ~176 KB |
| Quality at low bitrate | Excellent | Good | Fair | Perfect |
| Browser decode native | ✅ | ✅ | ✅ | ✅ |
| Safari support | ✅ (iOS 15+) | ⚠️ (iOS 14+) | ✅ | ✅ |
| Designed for | Speech + SFX | Music | Music | Raw PCM |

**Decision: OGG Opus at 48 kbps mono.** Reasons:
- SFX are short (0.3–3s), mostly non-music — Opus excels here
- ~6 KB per second vs 16 KB (Vorbis) — 60% smaller
- Browser `decodeAudioData()` handles decompression natively — zero manual work
- Safari has supported Opus since iOS 15 / macOS Monterey (2021). Our target audience is modern mobile browsers.

**Fallback: OGG Vorbis.** For the ~2% of users on iOS 14 or older Safari, we can dual-encode critical sounds as `.ogg` (Vorbis). The JS bridge checks `AudioContext` codec support and fetches the right file. This is a Phase 2 concern — not MVP.

### Pre-Compression Pipeline

Sound files are compressed **at build time**, not runtime:

```
Source WAV (studio quality)
    ↓  ffmpeg -i input.wav -c:a libopus -b:a 48k -ac 1 output.opus
Compressed .opus file (stored in repo + deployed to server)
    ↓  Browser fetches .opus via HTTP
    ↓  AudioContext.decodeAudioData() → PCM AudioBuffer (in memory)
Ready to play
```

The browser does ALL decompression. No JS decompression libraries needed. No gzip wrapper needed either — Opus is already compressed, so gzipping gains <5%.

### File Size Budget

| Sound type | Typical duration | Size @ 48kbps Opus | Count | Subtotal |
|------------|------------------|--------------------|-------|----------|
| Short SFX (hit, click, squeak) | 0.3–1s | 2–6 KB | 10 | ~40 KB |
| Medium SFX (door creak, growl) | 1–3s | 6–18 KB | 6 | ~70 KB |
| Ambient loops (fire, water) | 5–8s | 30–48 KB | 3 | ~120 KB |
| **Total MVP (18 sounds)** | | | **~19** | **~230 KB** |

For context: the engine bundle is 232 KB compressed. Sound adds ~230 KB — roughly doubling static assets, but still under 500 KB total. Acceptable for mobile.

---

## 3. Lazy Loading Pipeline

### Trigger: Room Load

The JIT loader in `game-adapter.lua` already fetches room definitions and their objects on demand (when the player enters a room). Sound loading piggybacks on this existing flow.

```
Player enters room
    ↓ game-adapter.lua: load_room(room_id)
    ↓ For each object instance:
    ↓   load_object(guid)
    ↓   If obj.sounds exists:
    ↓     For each sound_id in obj.sounds:
    ↓       window:_soundLoad(sound_id, "sounds/" .. sound_id .. ".opus")
    ↓ (JS fetches async — doesn't block room loading)
    ↓ Room renders, player sees text immediately
    ↓ Sounds arrive in background, ready when needed
```

### JS Async Fetch + Decode

```javascript
// Called from Lua: window:_soundLoad("glass-shatter", "sounds/glass-shatter.opus")
window._soundLoad = function(id, url) {
    if (_audioBuffers[id]) return;  // already loaded
    if (!_ensureAudioContext()) return;  // no audio support

    // Cache-bust with same timestamp as other assets
    var bustUrl = url + '?v=' + CACHE_BUST;

    fetch(bustUrl)
        .then(function(response) {
            if (!response.ok) throw new Error('HTTP ' + response.status);
            return response.arrayBuffer();
        })
        .then(function(data) {
            return _audioCtx.decodeAudioData(data);
        })
        .then(function(buffer) {
            _audioBuffers[id] = buffer;
            if (window._debugMode) {
                showStatus('Sound loaded: ' + id + ' (' + formatSize(buffer.length) + ')');
            }
        })
        .catch(function(err) {
            // Silent failure — sound is optional
            if (window._debugMode) {
                console.warn('Sound load failed: ' + id, err);
            }
        });
};
```

**Key design choice: async fetch, non-blocking.** The `fetch()` runs in the background. The Lua call to `window:_soundLoad()` returns immediately. The room text appears before sounds are ready. If a sound plays before its buffer arrives, it's a silent no-op — the player sees the text description regardless.

### Cache Strategy

**In-memory buffer cache** (`_audioBuffers` object):
- Decoded `AudioBuffer` objects stay in memory after first load
- No eviction in MVP — 18 sounds × ~50 KB decoded PCM ≈ 900 KB RAM. Negligible.
- Phase 2: LRU eviction if sound count grows past ~50. Use a simple counter-based approach — evict least-recently-played buffer when cache exceeds a configurable limit (e.g., 5 MB decoded).

**HTTP caching:**
- Browser HTTP cache handles repeat fetches automatically
- Same `?v=CACHE_BUST` pattern as all other assets — cache-bust on deploy, cached between deploys
- `fetch()` respects standard HTTP cache headers (GitHub Pages sends `Cache-Control: max-age=600`)

---

## 4. Asset Hosting

### Repository Structure

```
assets/
└── sounds/
    ├── README.md              # License info, source attribution
    ├── creatures/
    │   ├── rat-squeak.opus
    │   ├── cat-purr.opus
    │   ├── wolf-growl.opus
    │   └── bat-screech.opus
    ├── objects/
    │   ├── glass-shatter.opus
    │   ├── door-creak.opus
    │   ├── lock-click.opus
    │   ├── chain-rattle.opus
    │   ├── match-strike.opus
    │   └── candle-crackle.opus
    ├── combat/
    │   ├── hit-blunt.opus
    │   └── hit-slash.opus
    └── ambient/
        ├── fire-loop.opus
        └── water-drip-loop.opus
```

### Build Pipeline

Sound files do NOT go through the engine bundle (`build-engine.ps1`). They're static assets deployed alongside meta files.

```
Build step (new: build-sounds.ps1):
  1. Read assets/sounds/**/*.opus
  2. Validate: each file < 100 KB, is valid Opus
  3. Copy to web/dist/sounds/ (flat namespace, no subdirectories)
     - rat-squeak.opus → web/dist/sounds/rat-squeak.opus
     - door-creak.opus → web/dist/sounds/door-creak.opus
  4. Generate sounds/_manifest.json listing all available sound IDs
     (optional — engine can also just try to fetch and handle 404)

Deploy step (deploy.ps1 addition):
  5. Copy web/dist/sounds/ → ../WayneWalterBerry.github.io/play/sounds/
  6. Standard git add/commit/push
```

**Flat namespace for deployment.** Subdirectories in the source repo are organizational — deployment flattens to `sounds/{id}.opus`. This keeps Lua references simple: `sound.load("rat-squeak")` → fetches `sounds/rat-squeak.opus`.

**No manifest required for MVP.** The Lua engine knows which sounds to load because objects declare `sounds = { ... }` in their definitions. The engine doesn't need a master list — it loads what objects reference.

---

## 5. Fengari Bridge — Complete API

### JS Side (bootstrapper.js additions)

```javascript
// --- Sound Bridge API ---

window._soundLoad = function(id, url) { /* see §3 above */ };

window._soundPlay = function(id, opts) {
    if (_audioMuted || !_audioCtx || !_audioBuffers[id]) return;
    _ensureAudioContext();

    var source = _audioCtx.createBufferSource();
    source.buffer = _audioBuffers[id];
    source.loop = !!(opts && opts.loop);

    // Per-sound volume (0.0–1.0), default 1.0
    var gainNode = _audioCtx.createGain();
    gainNode.gain.value = (opts && opts.volume != null) ? opts.volume : 1.0;
    source.connect(gainNode);
    gainNode.connect(_masterGain);

    source.start(0);

    // Track for stop/cleanup
    _activeSources[id] = { source: source, gain: gainNode };
    source.onended = function() { delete _activeSources[id]; };
};

window._soundStop = function(id) {
    var entry = _activeSources[id];
    if (entry) {
        try { entry.source.stop(); } catch(e) {}
        delete _activeSources[id];
    }
};

window._soundUnload = function(id) {
    window._soundStop(id);
    delete _audioBuffers[id];
};

window._soundIsLoaded = function(id) {
    return !!_audioBuffers[id];
};

window._soundSetMasterVolume = function(vol) {
    if (_masterGain) _masterGain.gain.value = Math.max(0, Math.min(1, vol));
};

window._soundSetMuted = function(muted) {
    _audioMuted = !!muted;
    if (_audioMuted) {
        // Stop all active sounds
        for (var sid in _activeSources) {
            try { _activeSources[sid].source.stop(); } catch(e) {}
        }
        _activeSources = {};
    }
};
```

### Lua Side (game-adapter.lua additions)

```lua
---------------------------------------------------------------------------
-- Sound bridge — Lua API wrapping JS Web Audio functions
---------------------------------------------------------------------------
local sound = {}

function sound.load(id, url)
    url = url or ("sounds/" .. id .. ".opus")
    pcall(function() window:_soundLoad(id, url) end)
end

function sound.play(id, options)
    pcall(function() window:_soundPlay(id, options or {}) end)
end

function sound.stop(id)
    pcall(function() window:_soundStop(id) end)
end

function sound.unload(id)
    pcall(function() window:_soundUnload(id) end)
end

function sound.is_loaded(id)
    local ok, result = pcall(function() return window:_soundIsLoaded(id) end)
    return ok and result
end

function sound.set_volume(vol)
    pcall(function() window:_soundSetMasterVolume(vol) end)
end

function sound.mute(muted)
    pcall(function() window:_soundSetMuted(muted) end)
end

-- Expose to engine via context
_G._web_sound = sound
```

The engine's platform-agnostic `sound` module (`src/engine/sound.lua` — Bart's domain) checks `_G._web_sound` and uses it when available. On CLI, `_G._web_sound` is nil, so the engine falls back to `os.execute()` or no-op.

### Why pcall() Everywhere

Fengari's JS interop can throw on edge cases (AudioContext not created yet, browser restrictions, memory pressure). Every bridge call is wrapped in `pcall()` so a sound failure never crashes the game. Sound is enhancement — a thrown error must be swallowed silently.

---

## 6. Fallback — When Audio Isn't Available

### Scenarios

| Scenario | Detection | Behavior |
|----------|-----------|----------|
| Old browser (no Web Audio) | `window.AudioContext` is undefined | `_ensureAudioContext()` returns false; all `_soundXxx` calls are no-ops |
| User disabled audio | Mute toggle sets `_audioMuted = true` | `_soundPlay` returns immediately; no fetch/decode |
| Autoplay blocked | `AudioContext.state === 'suspended'` | Sounds queue silently; start after first interaction |
| Network error | `fetch()` rejects | `_soundLoad` catch logs warning; buffer stays empty; play is no-op |
| Memory pressure | `decodeAudioData` rejects | Same as network error — silent fallback |
| iOS low-power mode | AudioContext may be restricted | Same suspended-state handling |

### Design Principle

**The game is text-first. Sound is additive.** Every sound-triggering event already produces text output (`on_listen` descriptions, state change messages, verb output). The text is ALWAYS emitted regardless of sound state. There is no codepath where sound replaces text.

```lua
-- Engine verb handler (Bart's domain) — illustrative pattern:
verbs.break = function(context, noun)
    local obj = find_object(noun)
    -- Text ALWAYS fires
    print(obj.mutations.break.message)  -- "The mirror shatters!"
    -- Sound is optional overlay
    if _G._web_sound and obj.sounds and obj.sounds.break then
        _G._web_sound.play(obj.sounds.break)
    end
end
```

No `if sound then ... else print() end` branching. Text is unconditional. Sound is fire-and-forget.

---

## 7. Autoplay Policy

### The Problem

All modern browsers block `AudioContext` playback until the user has interacted with the page (click, tap, or keypress). This is a hard browser policy — there is no workaround.

### The Solution

**First keypress unlocks audio.** The player MUST type a command to play the game. Their first `Enter` keypress in the input box is the user interaction that unlocks `AudioContext`.

```javascript
// In the existing keydown handler (bootstrapper.js, line ~250):
inputEl.addEventListener('keydown', function (e) {
    // Unlock AudioContext on first interaction
    _ensureAudioContext();

    if (e.key === 'Enter') {
        // ... existing command processing ...
    }
});
```

### Timeline

```
Page loads → AudioContext created but suspended
   ↓
Player sees welcome text, room description (text only, no sound)
   ↓
Player types first command, presses Enter
   ↓
keydown handler calls _ensureAudioContext() → AudioContext.resume()
   ↓
AudioContext now running — all queued/future sounds will play
   ↓
Room's ambient sounds can start (if object sounds were pre-loaded during room load)
```

**No "click to enable sound" banner needed.** The game's natural interaction model (typing commands) provides the user gesture. The first keypress is always before any sound would meaningfully play.

### Ambient Sounds After Unlock

Room ambient loops (fire crackle, water drip) start when the player enters a room AND AudioContext is running. If the player enters the first room before typing (impossible — they see the welcome text and must type to proceed), ambient would silently wait.

```javascript
window._soundPlay = function(id, opts) {
    if (_audioMuted || !_audioBuffers[id]) return;
    if (!_ensureAudioContext()) return;  // still suspended = silent skip
    // ... play sound ...
};
```

---

## 8. Integration with Existing Web Architecture

### What Changes in Each File

| File | Changes | Risk |
|------|---------|------|
| `web/bootstrapper.js` | Add audio subsystem (~80 lines): AudioContext setup, 6 bridge functions, autoplay unlock in keydown handler | Low — additive, no existing code modified except one line in keydown |
| `web/game-adapter.lua` | Add sound bridge module (~40 lines): Lua wrapper functions, expose `_G._web_sound` | Low — additive, no existing code modified |
| `web/build-engine.ps1` | No changes — sounds are static assets, not engine code | None |
| `web/build-meta.ps1` | No changes — sounds are not meta files | None |
| `web/deploy.ps1` | Add `sounds/` directory copy step (~5 lines) | Low |
| `web/index.html` | Optional: mute button in terminal header | Low |
| **New: `web/build-sounds.ps1`** | Validate + copy sound files to `web/dist/sounds/` | New file |

### Build Script Integration

Sound build runs as part of the deploy pipeline, after engine and meta builds:

```powershell
# deploy.ps1 addition (after existing build steps):
& "$PSScriptRoot\build-sounds.ps1"  # validate + copy to dist/sounds/
```

### Cache-Busting

Sound files use the same `?v=CACHE_BUST` pattern as all other fetched assets. The existing `CACHE_BUST` constant in `bootstrapper.js` is reused. No new stamping mechanism needed.

---

## 9. Open Questions for Wayne / Team

1. **Opus vs Vorbis?** I recommend Opus (smaller, better for SFX). Vorbis has slightly broader Safari legacy support. Wayne's call — Opus is my default unless overridden.

2. **Mute UI?** Small speaker icon in terminal header? Or a `mute`/`unmute` command in-game? Both? Either is ~15 min of work.

3. **Volume persistence?** Save master volume to `localStorage` so it survives page reload? Easy to add.

4. **Sound during search trickle?** When search results trickle in (Issue #72), should we play a subtle tick per line? Or only play sounds on verb actions / state transitions? I lean toward state transitions only.

5. **Build pipeline: separate script or fold into existing?** I propose a new `build-sounds.ps1` for clarity, called from `deploy.ps1`. Alternative: add sound copying directly to `deploy.ps1`.

---

## 10. Implementation Estimate

| Task | Hours | Depends On |
|------|-------|------------|
| JS audio subsystem in bootstrapper.js | 2 | Nothing |
| Lua sound bridge in game-adapter.lua | 1 | JS subsystem |
| build-sounds.ps1 + deploy.ps1 update | 1 | Sound files exist |
| Mute button UI (if requested) | 0.5 | JS subsystem |
| Integration testing (manual) | 1 | All above |
| **Gil total** | **5.5** | |

Engine-side work (Bart's domain): hooking `sound.play()` into FSM transitions, verb handlers, and the object `sounds` field. That's Bart's estimate to give, not mine.

---

*Gil — Gets it out the door.*
