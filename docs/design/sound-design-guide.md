# Sound Design Guide — ARCHIVED

**This document has been consolidated into `projects/sound/design.md`.**

All sound design content, principles, object audit, architecture, deployment, and accessibility guidelines have been merged into the unified design reference.

**New Location:** [projects/sound/design.md](../../projects/sound/design.md)

---

## Why This Change?

The sound project had multiple overlapping design documents:
- `projects/sound/north-star.md` — Vision + roadmap
- `projects/sound/sound-design-notes.md` — Game design perspective
- `docs/design/sound-design-guide.md` — Comprehensive guide (this file)
- Plus: implementation plans, web pipeline notes, etc.

**Kirk consolidated to 3 files per Wayne's request:**
1. **design.md** — One unified design reference (all design, philosophy, audits, architecture)
2. **plan.md** — One unified execution plan (waves, timeline, assignments)
3. **board.md** — Project board (updated with references)

This ensures there's **one source of truth** for sound system design and avoids content duplication.

---

## Quick Navigation

If you're looking for:
- **Sound philosophy + accessibility** → See [design.md § Philosophy](../../projects/sound/design.md#design-philosophy)
- **Object/creature sound audit** → See [design.md § Sound-Per-Object Audit](../../projects/sound/design.md#sound-per-object-audit)
- **Web Audio architecture** → See [design.md § Deployment Architecture](../../projects/sound/design.md#deployment-architecture)
- **Implementation timeline** → See [plan.md § Wave Roadmap](../../projects/sound/plan.md#phase-roadmap--timeline)
- **Object sound implementation** → See [design.md § Implementation](../../projects/sound/design.md#implementation-how-to-add-sounds-to-objects)

---

**Consolidated:** 2026-03-29  
**Redirect valid as of:** 2026-03-29


---

## Web Audio Driver (NEW — WAVE-4)

The Web Audio driver enables in-browser sound playback via the Web Audio API. It implements:

- **Async audio loading:** Fetch + decode OGG Opus files
- **Concurrent playback:** Max 4 one-shots, max 3 ambient loops
- **Volume control:** Master gain node with per-sound ducking
- **Synthetic fallback:** If a real audio file is missing (404), generates a procedural tone (oscillator-based) so sounds work immediately during dev
- **Fengari bridge:** Calls JavaScript functions via `js` global (Fengari compatibility)

### How It Works

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

### Synthetic Fallback Tones

When real assets are missing, the engine generates synthetic tones to prevent silent failures:

- **One-shot sounds** (verb actions): Beep + envelope (attack/decay)
- **Ambient loops** (room atmosphere): Low-frequency drone (80 Hz sine wave)
- **Creature sounds** (vocalizations): Mid-frequency oscillator (440 Hz A note) with tremolo

**Why:** Developers can test the sound system without waiting for audio production. The synthetic fallback makes it immediately obvious that a sound *should* play at that point, even if it sounds like a placeholder.

### Deployment

Real audio files go to `web/sounds/`:

```
web/
├── audio-driver.js           ← Web Audio API engine
├── sounds/                   ← OGG Opus files (MVP 24 files)
│   ├── ambient/
│   │   ├── bedroom-night.opus
│   │   ├── hallway-wind.opus
│   │   └── ...
│   ├── creatures/
│   │   ├── rat-idle.opus
│   │   ├── wolf-growl.opus
│   │   └── ...
│   ├── combat/
│   │   ├── hit-blunt.opus
│   │   ├── hit-slash.opus
│   │   └── ...
│   └── objects/
│       ├── door-creak.opus
│       ├── candle-ignite.opus
│       └── ...
└── build-sounds.ps1         ← Build pipeline (validates + deploys)
```

**Build Pipeline:** `web/build-sounds.ps1`
- Validates OGG Opus format (@48 kbps mono)
- Checks file sizes (warn if >50 KB per file)
- Copies to `web/dist/sounds/` with cache-busting
- Generates manifest (optional, for future asset preload)

---

## Philosophy

Sound transforms a text adventure from "reading a story" to "being in a place." The game starts at **2 AM in total darkness**. As the player navigates by touch alone, hearing a rat skitter, a door creak, or a candle ignite creates genuine tension and presence.

**Three Iron Laws:**
1. **Sound enhances; text is truth.** Every sound event has a text description. Sound is optional; text is required.
2. **Lazy loading.** Sounds load when objects load. No bulk preload. Mobile-friendly.
3. **Accessibility first.** Never convey critical gameplay information via sound alone.

---

## When to Add Sounds to Objects

Add sounds to objects that **move, change state, or interact with the player.** Examples:

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

---

## How to Add Sounds to Objects

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
-- Required with sounds
on_feel = "A smooth wax cylinder, warm from the flame.",
on_listen = "A gentle crackling as the wax burns.",

-- Optional but recommended
on_smell = "Burning tallow.",
on_taste = "Bitter wax.",
```

**Why:** Players navigate in darkness. `on_feel` is the primary sense. When a candle ignites (sound), the player must also feel it (`on_feel`). When something cracks (sound), the player must hear it (text) even without audio.

### Step 3: Use Correct Field Names

Sound fields use a specific naming convention (separate from sensory `on_*` fields):

| Field | Use Case | Example |
|-------|----------|---------|
| `ambient_loop` | Continuous loop (object/creature always sounds this way) | `"rat-idle.opus"` |
| `ambient_{state}` | Loop while in specific FSM state | `ambient_lit = "candle-flame.opus"` |
| `on_state_{state}` | Fires on transition TO state | `on_state_lit = "candle-ignite.opus"` |
| `on_verb_{verb}` | Fires when verb acts on object | `on_verb_break = "glass-shatter.opus"` |
| `on_mutate` | Fires when mutation applies | `"mirror-crack.opus"` |
| `on_traverse` | Fires on door/passage traversal | `"door-creak.opus"` |

### Step 4: Test Your Sounds Table

Run the test suite:

```bash
lua test/run-tests.lua
```

Look for errors like:
- `Error: sound file not found: candle-ignite.opus`
- `Error: object has sounds but no on_listen`
- `Error: invalid sound key: on_vbr_break` (typo)

---

## Field Naming Convention Deep Dive

### State-Based Events

When an object transitions to a new FSM state:

```lua
states = {
    unlit = { ... },
    lit = {
        ...
        -- Option 1: One-shot on entry to "lit" state
        -- (fires once, immediately)
        on_look = "The candle flickers to life.",
    },
},

sounds = {
    -- Fires when FSM enters "lit" state
    on_state_lit = "candle-ignite.opus",
    
    -- (Optional) Loops while in "lit" state
    ambient_lit = "candle-flame.opus",
},
```

**Difference:**
- `on_state_lit` → **one-shot** when state changes (ignition sound)
- `ambient_lit` → **loop** while in that state (ongoing flame sound)

Both can coexist. The one-shot fires first; the loop starts after.

### Verb Events

When a verb acts on an object:

```lua
sounds = {
    -- Fires when "break" verb targets this object
    on_verb_break = "glass-shatter.opus",
    
    -- Fires when "hit" verb targets this object
    on_verb_hit = "glass-crack.opus",
    
    -- Fires on any other "open" verb
    on_verb_open = "generic-creak.opus",  -- Fallback to default if not here
},
```

**Verb names match handler names exactly:** `on_verb_break`, `on_verb_hit`, `on_verb_open`, `on_verb_light`, `on_verb_listen`, etc.

### Mutation Events

When an object mutates (transforms):

```lua
mutations = {
    break = {
        becomes = "mirror-broken",
        message = "The mirror shatters.",
        sound = {
            -- This fires when mutation applies
            on_mutate = "mirror-shatter-crunch.opus",
        },
    },
},
```

Or as a field in the `sounds` table:

```lua
sounds = {
    on_mutate = "mirror-shatter-crunch.opus",
},
```

When a candle mutates from `candle` → `candle-spent`:
1. Old object: `on_mutate` sound fires
2. Old object's ambients are stopped
3. New object (`candle-spent.lua`) is scanned
4. New object's `ambient_loop` (if any) starts

**Design rule:** Mutated objects don't inherit parent sounds. Each variant declares its own `sounds` table.

Example:
- `candle.lua`: `{ ambient_lit = "candle-flame.opus" }`
- `candle-spent.lua`: `{}` (no sounds — it's dead)

### Creature Ambient + Vocalization

Creatures have a special pattern:

```lua
-- creature-rat.lua
sounds = {
    -- Continuous idle loop (while rat is alive and in room)
    ambient_loop = "rat-idle.opus",
    
    -- One-shot when rat dies (rarely used; silence is preferred)
    on_state_dead = nil,  -- NO SOUND. Silence IS the death.
    
    -- One-shot when rat attacks (part of combat flow)
    on_verb_attack = "rat-squeak.opus",
},

states = {
    alive = {
        on_listen = "A rat chittering and scratching.",
    },
    dead = {
        on_listen = "The rat is motionless. No breath, no sound.",
        -- Silence = death. Engine calls stop_by_owner(rat_id).
        -- on_state_dead sound does NOT fire.
    },
},
```

**Dead Creature Convention:** When a creature dies, its `ambient_loop` is stopped by the engine. The creature remains in the room as a dead body, but **silent**. Absence of sound IS the sound of death. Do NOT add an `on_state_dead` sound.

---

## Room Ambients

### How to Add Room Ambients

Open your room in `src/meta/world/{room_name}.lua`. Add a `sounds` table:

```lua
return {
    guid = "{your-uuid}",
    id = "bedroom",
    name = "Bedroom",
    description = "...",

    -- NEW: Room ambient
    sounds = {
        ambient_loop = "amb-bedroom-silence.opus",
    },

    instances = { ... },
    exits = { ... },
}
```

### Room Ambient Lifecycle

1. **Player enters room** → Engine calls `sound_manager:enter_room(room)`
2. **Ambient starts** → `room.sounds.ambient_loop` plays with `loop=true`
3. **Player interacts in room** → Object/verb sounds play over ambient
4. **Player leaves room** → Engine calls `sound_manager:exit_room(room)`
5. **Ambient stops** → Room sound crossfades out (1.5s on web)
6. **New room ambient starts** → Crossfade in (1.5s on web)

### Room Ambient Characteristics

**Bedroom:**
```lua
sounds = { ambient_loop = "amb-bedroom-silence.opus" },
```
Near-silence; faint settling stone, occasional creak. Conveys isolation and safety.

**Hallway:**
```lua
sounds = { ambient_loop = "amb-hallway-torches.opus" },
```
Torch crackle, timber groaning. Conveys old wood, firelight, atmosphere.

**Cellar:**
```lua
sounds = { ambient_loop = "amb-cellar-drip.opus" },
```
Irregular water drips, stone echo, air movement. Oppressive, damp.

**Storage Cellar:**
```lua
sounds = { ambient_loop = "amb-storage-scratching.opus" },
```
Rat scratching, old wood creak. Danger, decay.

**Deep Cellar:**
```lua
sounds = { ambient_loop = "amb-deep-cellar-silence.opus" },
```
Oppressive near-silence. Conveys depth and isolation.

**Crypt:**
```lua
sounds = { ambient_loop = "amb-crypt-void.opus" },
```
Borderline inaudible; rare stone settle. Conveys death, emptiness.

**Courtyard:**
```lua
sounds = { ambient_loop = "amb-courtyard-wind.opus" },
```
Wind, rare owl hoot, ivy rustle. Conveys open air, night, nature.

---

## Audio Format Specifications

### Codec & Bitrate

**Codec:** OGG Opus  
**Bitrate:** 48 kbps mono (not stereo)  
**Sample rate:** 48 kHz  
**Extension:** `.opus` (not `.ogg`)  

### Why Opus?

- **Efficient:** 48 kbps is high-quality mono speech/effects
- **Mobile-friendly:** ~6 KB/sec; Level 1 total ~230 KB
- **Web support:** Browser `decodeAudioData()` handles decompression natively
- **License:** Royalty-free (Xiph.Org Foundation)

### Compression Example

```bash
# Convert WAV to Opus
ffmpeg -i input.wav -c:a libopus -b:a 48k -ac 1 output.opus

# Verify format
ffprobe output.opus
# Should show: Audio: opus, 48000 Hz, mono, ~48 kbps
```

### File Organization

```
assets/sounds/
├── creatures/
│   ├── rat-squeak.opus
│   ├── rat-idle.opus
│   └── ...
├── objects/
│   ├── candle-ignite.opus
│   ├── candle-blow.opus
│   ├── mirror-crack.opus
│   └── ...
├── combat/
│   ├── generic-blunt-hit.opus
│   ├── generic-slash-hit.opus
│   └── ...
├── ambient/
│   ├── amb-bedroom-silence.opus
│   ├── amb-cellar-drip.opus
│   └── ...
└── README.md  # Attribution for CC-BY files
```

### Size Limits

- **Per file:** < 100 KB (enforced by `build-sounds.ps1`)
- **Per room:** 30–80 KB (room ambients + object ambients)
- **Total MVP:** ~230 KB (all 24 files)
- **Mobile:** Lazy-loaded per room; no bulk preload

---

## Asset Sourcing Guidelines

### Licensing

Sounds must be **freely usable in commercial products**. Priority order:

1. **CC0 (Public Domain)** ✅ Best — no attribution needed
   - Zapsplat (zapsplat.com)
   - Sonniss (sonniss.com)

2. **CC-BY (Attribute author)** ✅ Good — require attribution
   - OpenGameArt (opengameart.org)
   - Freesound subset (freesound.org, CC-BY licensed)

3. **CC-BY-SA (Copyleft)** ⚠️ Risky — requires derivative works be CC-BY-SA
   - Freesound (some files)

4. **CC-BY-NC (Non-commercial)** ❌ Not allowed
   - BBC Sound Effects Library
   - Not usable in commercial product

### Attribution

CC-BY sounds require attribution. Create `assets/sounds/README.md`:

```markdown
# Sound Assets Attribution

## CC-BY Licensed

- **rat-squeak.opus** — [Author Name] (freesound.org, CC-BY)
  License: https://creativecommons.org/licenses/by/4.0/
  
- **mirror-crack.opus** — [Author Name] (freesound.org, CC-BY)
  License: https://creativecommons.org/licenses/by/4.0/

## CC0 Licensed (Public Domain)

- All other files are CC0 (public domain) or original work.
```

Include this in game credits or help menu.

---

## Design Rules & Best Practices

### Rule 1: Sensory Consistency

Every sound must have a text equivalent. If the candle ignites:

```lua
-- sound fires: on_state_lit → "candle-ignite.opus"

states = {
    lit = {
        on_look = "A tallow candle burns with a steady yellow flame.",
        on_feel = "Warm wax, softening near the flame. Careful — it's hot.",
        on_listen = "A gentle crackling, and the soft hiss of melting wax.",
    },
}
```

Text is printed first (always). Sound fires asynchronously. Player perceives both.

### Rule 2: No Information in Sound Alone

Critical game information must be in text. Examples of sound-only info (❌ WRONG):

```lua
-- WRONG: Sound is the only way to know something happened
on_verb_break = "glass-shatter.opus",  -- But no text message!

-- RIGHT: Text + sound together
-- (Verb handler prints text; sound fires asynchronously)
```

Sound is **confirmatory**, never **primary**.

### Rule 3: Creature Death is Silent

When a creature dies:

```lua
states = {
    dead = {
        on_listen = "The rat is motionless. No breath, no sound.",
        -- Explicit silence in text
    },
},

sounds = {
    -- NO on_state_dead sound
    -- Engine calls stop_by_owner(creature_id)
    -- Absence of sound = death notification
},
```

Why? Death is profound. Silence is more powerful than a death-scream.

### Rule 4: State-Based Ambients

Use `ambient_{state}` for loops specific to FSM states:

```lua
sounds = {
    -- Loops while in lit state
    ambient_lit = "candle-flame.opus",
    
    -- Loops while in unlit state (if needed)
    ambient_unlit = nil,  -- nil = no ambient for this state
},

states = {
    lit = { ... },
    unlit = { ... },
},
```

If a candle transitions from `lit` → `extinguished`:
1. `ambient_lit` stops
2. `on_state_extinguished` fires (one-shot)
3. `ambient_extinguished` starts (if defined)

### Rule 5: Reuse Defaults; Override When Needed

Don't create redundant sounds. Use defaults for generic verbs:

```lua
sounds = {
    -- Use default generic-break.opus unless you need custom
    on_verb_break = "glass-shatter.opus",  -- Custom: glass sounds different
    
    -- No on_verb_open entry = falls back to generic-creak.opus
},
```

If your object sounds like every other object when opened, don't declare `on_verb_open` at all.

### Rule 6: Creature Vocalizations Parallel on_listen

Creature ambients should match their `on_listen` text:

```lua
creatures = {
    rat = {
        sounds = {
            ambient_loop = "rat-chittering.opus",
        },
        on_listen = "A rat chittering softly in the darkness.",
    },
},
```

Rat makes chittering sound (audio). Player hears rats (text). Both reinforce each other.

---

## Common Patterns

### Pattern 1: Light Source (Candle, Torch, Match)

```lua
-- candle.lua
return {
    id = "candle",
    
    sounds = {
        -- Fires when state → lit
        on_state_lit = "candle-ignite.opus",
        
        -- Loops while in lit state
        ambient_lit = "candle-flame.opus",
        
        -- Fires when player blows it out
        on_verb_extinguish = "candle-blow.opus",
    },
    
    states = {
        unlit = {
            on_listen = "Silent. Wax and wick.",
        },
        lit = {
            on_listen = "A gentle crackling as the candle burns.",
        },
    },
}
```

### Pattern 2: Door / Passage

```lua
-- bedroom-hallway-door-north.lua
return {
    id = "bedroom-hallway-door-north",
    
    sounds = {
        -- Fires when door opens
        on_verb_open = "door-creak-wood.opus",
        
        -- Fires when player walks through
        on_traverse = "footsteps-stone.opus",
    },
    
    on_listen = "Silence behind the wooden door.",
}
```

### Pattern 3: Breakable Object

```lua
-- mirror.lua
return {
    id = "mirror",
    
    sounds = {
        -- Impact before break
        on_verb_hit = "glass-crack.opus",
        
        -- Final break
        on_verb_break = "glass-shatter.opus",
        
        -- Mutation sound (transition from intact → broken)
        on_mutate = "mirror-tinkle.opus",
    },
    
    states = {
        intact = { ... },
        cracked = { ... },
        broken = {
            on_listen = "Silence. Broken glass has no voice.",
        },
    },
}
```

### Pattern 4: Creature (Living)

```lua
-- creature-rat.lua
return {
    id = "rat",
    
    sounds = {
        -- Ambient loop while rat is in room
        ambient_loop = "rat-idle.opus",
        
        -- Combat vocalization
        on_verb_attack = "rat-squeak-panic.opus",
        
        -- (No on_state_dead — silence is death)
    },
    
    states = {
        alive = {
            on_listen = "A rat chittering nervously in the shadows.",
        },
        dead = {
            on_listen = "The rat is motionless. No breath, no sound.",
        },
    },
}
```

### Pattern 5: Room Ambient

```lua
-- cellar.lua
return {
    id = "cellar",
    
    sounds = {
        -- Ambient loop for room
        ambient_loop = "amb-cellar-drip.opus",
    },
    
    description = "Underground stone chamber...",
    
    instances = { ... },
}
```

---

## Adding Real Audio Assets (Phase 1+)

Current status: **MVP implementation complete. Web Audio driver ready. Synthetic fallback tones work. Awaiting real audio files (Phase 1).**

### Asset Production Pipeline

**Step 1: Audio Source**
- **Option A:** Commission royalty-free audio library (Freesound, Zapsplat, BBC Sound Effects Library)
- **Option B:** Create procedurally (synthesize via Web Audio API — post-Phase 1)
- **Option C:** Record foley (if budget allows — high-fidelity option)

**Target Spec:**
- Format: OGG Opus @ 48 kbps mono
- Duration: 1–5 seconds per file (one-shots), 10–60 seconds (ambient loops)
- Total budget: ~230 KB (24 MVP files)
- Compression: Handled by browser `decodeAudioData()`

### Asset Directory Structure

```
web/sounds/
├── ambient/           ← Room atmosphere loops
│   ├── bedroom-night.opus
│   ├── hallway-wind.opus
│   ├── cellar-drip.opus
│   ├── storage-scratching.opus
│   ├── deep-cellar-void.opus
│   ├── crypt-void.opus
│   └── courtyard-wind.opus
├── creatures/         ← Creature vocalizations
│   ├── rat-idle.opus
│   ├── rat-skitter.opus
│   ├── wolf-growl.opus
│   ├── wolf-snarl.opus
│   ├── cat-purr.opus
│   ├── cat-hiss.opus
│   ├── bat-screech.opus
│   └── spider-skitter.opus
├── objects/           ← Object interactions
│   ├── door-creak.opus
│   ├── door-lock-click.opus
│   ├── gate-clang.opus
│   ├── trapdoor-thud.opus
│   ├── candle-ignite.opus
│   ├── match-strike.opus
│   ├── glass-shatter.opus
│   └── trap-snap.opus
└── effects/           ← Fallback SFX
    ├── generic-break.opus
    ├── generic-creak.opus
    └── generic-close.opus
```

### Integration Workflow

**When a new asset is ready:**

1. **Add to web/sounds/{category}/{name}.opus**
2. **Update object/room metadata** in `src/meta/`:
   ```lua
   sounds = {
       on_verb_open = "door-creak.opus",  ← now references real file
   }
   ```
3. **Deploy via build pipeline:**
   ```powershell
   .\web\build-sounds.ps1
   ```
4. **Test in browser:**
   - Open game
   - Trigger the action (e.g., open a door)
   - Real audio should play; synthetic fallback silenced
5. **Verify file size** — Run `build-sounds.ps1` check, warn if >50 KB per file
6. **Commit:**
   ```
   git add web/sounds/{category}/
   git commit -m "feat(audio): add {name} asset ({category})"
   ```

### Fallback Behavior

If a real audio file is missing (404 or network error):
- Browser still plays a synthetic tone (placeholder)
- Game continues; no hang or error
- Dev is alerted via console (`[audio-driver] fallback tone played for...`)
- Metadata validation test warns if file missing at commit time

### Performance Considerations

| Metric | Target | Check |
|--------|--------|-------|
| File size per asset | <50 KB | `build-sounds.ps1` warning |
| Total audio RAM (decoded) | <1 MB | Profile in DevTools |
| Concurrent playback | 4 one-shots + 3 ambients | Enforced by sound manager |
| Load latency | <200 ms per file | Network tab in DevTools |
| Audio latency (play delay) | <50 ms | Test in console |

**Mobile optimization:** Lazy load — sounds decode only when needed (room entry, object interaction). No preload of all 24 files at startup.

---

## Room Ambient Loops (WAVE-5 Complete)

All 7 rooms have `ambient_loop` declarations:

| Room | Ambient File | Status |
|------|--------------|--------|
| Bedroom | `ambient/bedroom-night.opus` | ✅ Declared (WAVE-5) |
| Hallway | `ambient/hallway-wind.opus` | ✅ Declared (WAVE-5) |
| Cellar | `ambient/cellar-drip.opus` | ✅ Declared (WAVE-5) |
| Storage Cellar | `ambient/storage-scratching.opus` | ✅ Declared (WAVE-5) |
| Deep Cellar | `ambient/deep-cellar-void.opus` | ✅ Declared (WAVE-5) |
| Crypt | `ambient/crypt-void.opus` | ✅ Declared (WAVE-5) |
| Courtyard | `ambient/courtyard-wind.opus` | ✅ Declared (WAVE-5) |

Ambient loops start when player enters room, stop on exit. See `src/meta/rooms/*.lua` for declarations.

---

## Checklist: Before Committing

- [ ] Object has `sounds` table? → Verify `on_feel` and `on_listen` exist
- [ ] Sound field names correct? → Check `on_state_*`, `ambient_*`, `on_verb_*`, etc.
- [ ] All referenced files exist? → `assets/sounds/{category}/{name}.opus`
- [ ] Dead creatures silent? → `on_state_dead` not declared; text says "no sound"
- [ ] Text consistent with sound? → `on_listen` matches audio atmosphere
- [ ] File format correct? → `.opus` extension, 48 kbps, mono
- [ ] File size < 100 KB? → Checked with `ls -lh` or file properties
- [ ] Tests pass? → `lua test/run-tests.lua` includes sound metadata tests

---

## Example Workflow: Adding a Torch

### Step 1: Find torch.lua

```bash
cd src/meta/objects
cat torch.lua
```

Current content:

```lua
return {
    guid = "{torch-guid}",
    id = "torch",
    name = "a wooden torch",
    description = "A torch wrapped in oil-soaked cloth.",
    on_feel = "Rough wood, greasy cloth, and cold iron ferrule.",
    on_listen = "Silent.",
    -- ... states, FSM, etc ...
}
```

### Step 2: Add Sounds Table

```lua
return {
    guid = "{torch-guid}",
    id = "torch",
    name = "a wooden torch",
    
    sounds = {
        on_state_lit = "torch-ignite.opus",
        ambient_lit = "torch-flame.opus",
        on_verb_extinguish = "torch-blow.opus",
    },
    
    -- ... rest of file ...
}
```

### Step 3: Update Sensory Descriptions

```lua
states = {
    lit = {
        on_listen = "A steady crackling as the torch flame dances.",
        on_feel = "Intense heat radiating from the cloth and wood.",
        on_smell = "Burning oil and char.",
    },
    unlit = {
        on_listen = "Silence. Dead cloth.",
    },
},
```

### Step 4: Verify Sound Files Exist

```bash
ls -lh assets/sounds/objects/
# Should list:
# torch-ignite.opus (< 100 KB)
# torch-flame.opus (< 100 KB)
# torch-blow.opus (< 100 KB)
```

### Step 5: Run Tests

```bash
lua test/run-tests.lua
# Look for sound-metadata tests
# Should pass: "torch.lua: sounds table valid" ✓
```

### Step 6: Commit

```bash
git add src/meta/objects/torch.lua
git commit -m "Add sound metadata to torch (on_state_lit, ambient_lit, on_verb_extinguish)"
```

Done! When a player lights the torch, they hear an ignition sound followed by ongoing flame crackle.

---

## Troubleshooting

### Sound Not Playing on Web

1. **Check browser console** (F12 → Console tab)
   - Look for 404 errors: `sounds/torch-ignite.opus: 404 Not Found`
   - Look for CORS errors: `Cross-Origin Request Blocked`

2. **Verify file exists:**
   ```bash
   ls -l assets/sounds/objects/torch-ignite.opus
   ```

3. **Check cache:**
   - Hard-refresh browser: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
   - Check `CACHE_BUST` constant in `web/bootstrapper.js`

4. **Check format:**
   ```bash
   ffprobe assets/sounds/objects/torch-ignite.opus
   # Must show: Audio: opus, 48000 Hz, mono
   ```

### Sound Not Playing in Terminal

1. **Check platform support:**
   - macOS: Verify `afplay` is available (`which afplay`)
   - Linux: Verify `paplay` or `aplay` available
   - Windows: Verify PowerShell audio available

2. **Check file permissions:**
   ```bash
   chmod +r assets/sounds/objects/torch-ignite.opus
   ```

3. **Manual test:**
   ```bash
   # macOS
   afplay assets/sounds/objects/torch-ignite.opus
   
   # Linux
   paplay assets/sounds/objects/torch-ignite.opus
   
   # Windows (PowerShell)
   (New-Object Media.SoundPlayer "assets/sounds/objects/torch-ignite.opus").PlaySync()
   ```

### Metadata Test Failures

```bash
lua test/sound/test-sound-metadata.lua
# Example error:
# ✗ torch.lua: sound field on_vbr_light is invalid (typo?)
```

Fix: Correct field name from `on_vbr_light` to `on_verb_light`.

### Concurrency Issues

If only 4 one-shots play max:

```lua
-- This is correct behavior (enforced concurrency limit)
for i = 1, 5 do
    sound_manager:play("sound.opus")
    -- Only 4 will play; 5th is silent (oldest evicted)
end
```

To allow all 5: space them out or use loops instead of one-shots.

---

## Accessibility Notes

Sound is **never required**. Every sound event has a text equivalent:

- **Creature vocalization** → `on_listen` text describes the sound
- **Door creak** → `on_listen` describes the sound (or lack thereof)
- **Impact sound** → Verb text describes what happened (damage, etc.)
- **Ambient loop** → Room `description` conveys atmosphere

Players on mute, with hearing loss, or using screen readers can play the full game with text alone. Sound enhances but never restricts.

---

## Final Thoughts

Sound design is about **creating presence**. When the player hears a rat skitter in the darkness, they are no longer reading a story—they are *in* the story. Every sound should reinforce the text, deepen the atmosphere, and make the world feel alive.

Add sounds thoughtfully. Quality over quantity. Let silence be powerful too.

---

**Last Updated:** WAVE-3 (v1.1)  
**Questions?** See `docs/architecture/engine/sound-system.md` for technical details.
