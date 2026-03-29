# Sound System — Formal Implementation Plan (Phases 1–8)

**Version:** 1.0  
**Date:** 2026-03-29  
**Status:** Ready for Team Review  
**Owner:** Kirk (Project Manager)  
**Architect:** Bart (Architecture Lead)  
**Scope:** Remaining sound work after MVP infrastructure (WAVES 0–5). Covers Phases 1–8 from North Star: real audio assets, object sounds, creature audio, combat audio, time-of-day variation, weather, music, and accessibility.

---

## Wave Status Tracker

```
WAVE-0 (Phase 1): ⏳ Pending (Asset Sourcing)  |  WAVE-1 (Phase 2): ⏳ Pending  |  WAVE-2 (Phase 3): ⏳ Pending  |  WAVE-3 (Phases 4–8): ⏳ Pending
```

---

## Executive Summary

**Context:** The sound system infrastructure is complete (sound manager, Web Audio driver, engine hooks, metadata system, 266 tests passing). The MVP implementation is production-ready. The engine waits for real audio assets and post-MVP expansion.

**What:** Execute Phases 1–8 from the North Star to transform the sound system from synthetic placeholders to production-grade audio immersion. Deliver real audio assets (Phase 1 MVP: 24 files), expand object/creature/combat sounds, implement time-of-day variation, integrate weather, explore music, and ensure accessibility.

**Why:** Sound is optional but irreplaceable — it transforms a text adventure from "reading a story" to "being in a place." A player navigating a 2 AM medieval manor by touch alone hears a rat skitter, a door creak, and a candle ignite. These moments create genuine tension and presence that text alone cannot.

**How:** 4 parallel waves structured by audio category and dependencies. Phase 1 assets unlock Phases 2–4. Phases 5–6 block on Level 2 weather engine (deferred). Phase 7 (music) pending design decision. Phase 8 (accessibility) runs in parallel.

**Execution Model:** Autonomous wave-based batching with team assignments, parallel tracks, gates, TDD, LLM walkthroughs, and documentation. Each gate is binary pass/fail. Wave failures escalate after 1x retry. Sound never breaks gameplay — all bridge calls wrapped in `pcall()`, nil-safe patterns throughout.

---

## Quick Reference Table

| Phase | Wave | Name | Agents | Tracks | Dependencies | Gate | Deliverables |
|-------|------|------|--------|--------|--------------|------|--------------|
| **1** | **WAVE-0** | Real Audio Assets (MVP) | CBG, Gil | 2 | None | GATE-0 | 24 `.opus` files sourced, compressed, deployed to `web/dist/sounds/` |
| **2** | **WAVE-1** | Object-Specific Sounds | Flanders, CBG, Nelson | 3 | Phase 1 assets | GATE-1 | Container, trap, puzzle, liquid sounds declared on 12+ objects; tests pass |
| **3** | **WAVE-2A** | Creature Audio Evolution | Flanders, Nelson | 2 | Phase 1 + Injury hook | GATE-2A | Per-state creature sounds; 5 creatures audio-complete; death silence design verified |
| **4** | **WAVE-2B** | Combat Immersion | Combat team, Flanders, Nelson | 3 | Phase 2A + Combat trace | GATE-2B | Weapon impact sounds, armor feedback, injury-specific sounds, death sounds (if applicable) |
| **5** | **WAVE-3** | Time-of-Day Ambient | Moe, Gil, Nelson | 2 | Phase 1 + Level 2 time system | GATE-3 | Ambient variation 2 AM → 6 AM → Day → Evening; crossfades smooth; L2 coupling complete |
| **6** | **WAVE-4** | Weather Audio | L2 team, Gil, Nelson | 2 | Level 2 weather engine | GATE-4 | Rain/wind/thunder/fog sound layers; integrated with L2 weather FSM |
| **7** | **WAVE-5** | Music & Score | CBG (decision), Composer (if approved), Nelson | 1 | Design decision | GATE-5 | (Conditional) Music design doc + composer timeline, or formal defer decision |
| **8** | **WAVE-6** | Accessibility & Volume | Smithers, Nelson | 2 | Phases 1–2 complete | GATE-6 | Volume controls UI, sound toggles, haptic layer research, screen reader test pass |

---

## Dependency Graph

```
┌─ WAVE-0 (Phase 1): Real Audio Assets (P0)
│   ├─ CBG: Finalize 24-file asset list, source CC0 + CC-BY sounds
│   ├─ Gil: Validate Opus format, compress @48 kbps, stage in web/dist/sounds/
│   └─ Nelson: Regression tests (full suite must pass)
│        │
│        ▼ GATE-0: 24 files deployed, <500 KB total, LLM walkthrough pass
│        │
│   ├─────────────────────────────────┬─────────────────────────────────┐
│   │                                 │                                 │
│   ▼                                 ▼                                 ▼
│ WAVE-1 (Phase 2):            WAVE-2A (Phase 3):            WAVE-3 (Phases 5–6):
│ Object Sounds                 Creature Audio                Time/Weather (blocked on L2)
│   │                             │                              │
│   ├─ Flanders: 12+ object       ├─ Flanders: 5 creatures       ├─ Moe: Room ambient variation
│   │ `on_verb_*` sounds          │ per-state sounds            ├─ Gil: Crossfade timing
│   ├─ CBG: Design review         ├─ Nelson: Integration        └─ L2 time system ready?
│   └─ Nelson: Tests              │  tests                           NO → BLOCKED
│        │                        │
│        ▼ GATE-1               ▼ GATE-2A
│        │                        │
│        └────────┬───────────────┴────────┐
│                 │                        │
│                 ▼                        ▼
│            WAVE-2B:           WAVE-2B (Phase 4):
│            (Phase 3 cont.)    Combat Sounds
│            Deferred           ├─ Combat trace: hit/miss/block chains
│            to WAVE-2B         ├─ Weapon impact sounds (4 types)
│                               ├─ Armor feedback sounds
│                               ├─ Creature vocalizations on injury
│                               └─ Nelson: Combat integration tests
│                                    │
│                                    ▼ GATE-2B
│                                    │
│                 ┌──────────────────┘
│                 │
│   WAVE-4 (Phase 6): Weather Audio (blocked on Level 2)
│   ├─ L2 weather engine outputs: rain/wind/thunder/fog FSM states
│   ├─ Gil: Dynamic sound layer mixing
│   └─ Nelson: L2 + sound integration tests
│        │
│        ▼ GATE-4
│        │
│   WAVE-5 (Phase 7): Music & Score (DESIGN-PENDING)
│   ├─ Wayne decision: Score? Diegetic? Non-diegetic?
│   ├─ If YES → Composer timeline + work
│   └─ If NO → Formal defer, archive decision
│        │
│        ▼ GATE-5
│        │
│   WAVE-6 (Phase 8): Accessibility (PARALLEL)
│   ├─ Smithers: Volume control UI + toggles
│   ├─ Nelson: Screen reader compatibility testing
│   └─ Accessibility audit checklist
│        │
│        ▼ GATE-6
│
└─ All phases: Zero regressions, TDD throughout, full test suite green
```

**Critical Path:**
- **P0 blocker:** Phase 1 assets must ship before Phases 2–4 can execute
- **L2 blocker:** Phases 5–6 (time-of-day + weather) blocked on Level 2 design
- **Design-pending:** Phase 7 (music) requires Wayne decision before wave start
- **Parallel:** Phase 8 (accessibility) runs with Phases 2–4 (non-blocking)

---

## Implementation Waves

### WAVE-0: Real Audio Assets (Phase 1 MVP)

**Goal:** Replace synthetic fallback tones with 24 real OGG Opus audio files. This is the minimum viable audio experience and unlocks all subsequent phases.

**Duration:** 2–3 weeks (asset sourcing, compression, validation, deploy)

#### Track 0A: Asset Sourcing & Curation (CBG)

**Responsibility:** CBG finalizes the 24-file MVP list and sources all audio.

**MVP Sound Categories (24 files total, ~230 KB compressed):**

| Category | Count | Examples | File Prefix |
|----------|-------|----------|------------|
| Creature vocalizations | 8 | Rat idle/skitter, wolf growl/snarl, bat wings/screech, cat purr/hiss | `creatures/` |
| Door/passage sounds | 5 | Door creak (heavy/light), lock click, gate clang, trapdoor thud | `objects/` |
| Fire/light ignition | 3 | Match strike, candle ignite, torch crackle | `objects/` |
| Combat impacts | 2 | Blunt hit, slash hit (pierce/crush deferred to Phase 4) | `combat/` |
| Ambient room loops | 6 | Bedroom silence, hallway torches, cellar drip, storage scratch, deep cellar void, crypt void, courtyard wind | `ambient/` |

**Sourcing Priority:**
1. CC0 (Zapsplat, Sonniss, Freesound CC0) — no attribution required
2. CC-BY (OpenGameArt, Freesound CC-BY) — require attribution in `assets/sounds/README.md`
3. CC-BY-SA (fallback) — reciprocal license acceptable for source
4. NO CC-BY-NC (BBC, etc.) — commercial flexibility required

**Files:**
- EDIT `.squad/decisions/inbox/cbg-sound-assets-phase1.md` — Final 24-file manifest with source URLs, licenses, and compression specs
- CREATE `assets/sounds/README.md` — Attribution table for all sourced/CC-BY sounds (required for compliance)

**Deliverables:**
- [ ] 24 audio files sourced (WAV or higher bitrate lossy)
- [ ] License verification (CC0 or CC-BY only)
- [ ] Attribution log created

#### Track 0B: Compression & Deployment (Gil)

**Responsibility:** Gil compresses all 24 files to OGG Opus @48 kbps mono and deploys to web build.

**Files:**
- EDIT `web/build-sounds.ps1` — Compress validated files via ffmpeg; validate format and size; copy to `web/dist/sounds/`
- EDIT `web/deploy.ps1` — Add sound directory copy to deployment target
- EDIT `.gitignore` — Ignore uncompressed source audio (WAV files in `assets/sounds-raw/`)

**Compression spec:**
```bash
ffmpeg -i input.wav -c:a libopus -b:a 48k -ac 1 output.opus
# Result: ~6 KB/sec; 24 files = ~230 KB total (~60% smaller than Vorbis)
```

**Deployment:**
- Flat namespace: `web/dist/sounds/{category}/{name}.opus`
- All 24 files in one directory (no subdirs on deploy)
- Cache-bust via `?v={CACHE_BUST}` query string (reuse existing constant)

**Validation:**
- [ ] Every `.opus` file < 100 KB (warn if exceeded)
- [ ] Valid OGG Opus format check (ffprobe)
- [ ] Total size < 500 KB (target: ~230 KB)
- [ ] Files deploy to correct path on staging server

**Deliverables:**
- [ ] 24 `.opus` files staged in `web/dist/sounds/`
- [ ] `build-sounds.ps1` validation passing
- [ ] Cache-busting deployed

#### Track 0C: Testing & Verification (Nelson)

**Responsibility:** Nelson runs LLM walkthroughs in headless mode to verify sound system is production-ready.

**Files:**
- CREATE `test/sound/scenarios/phase1-asset-verification.txt` — 5 headless LLM scenarios (scripted command sequences)

**LLM Scenarios (all with deterministic seed, `--headless` mode):**

1. **Room Ambient Load (no crash)**
   ```
   look
   listen
   ```
   Expected: Room description + on_listen text. No sound errors. Game continues.

2. **Creature Encounter (ambient queued)**
   ```
   take candle
   light candle
   look
   ```
   Expected: Game boots, candle lights, room description prints. If creature in room: ambient vocalization should queue (or no-op in headless). No crash.

3. **Door Traversal (crossfade ready)**
   ```
   open door north
   north
   look
   ```
   Expected: Door opens, ambient stops, new room ambient starts (or queued). Crossfade timing not checked in headless (web-only). No crash.

4. **Combat Encounter (impact sound ready)**
   ```
   attack rat
   ```
   Expected: Combat text appears. Impact sound would fire on web. No sound errors in headless. No crash.

5. **Full Level 1 Walkthrough (regression baseline)**
   ```
   {full command sequence through level completion}
   ```
   Expected: Zero crashes, zero sound-related errors, all text matches non-sound baseline.

**Test execution:**
```bash
lua src/main.lua --headless < test/sound/scenarios/phase1-asset-verification.txt
```

**Deliverables:**
- [ ] All 5 scenarios complete without errors
- [ ] Mock driver call log matches expected sound triggers
- [ ] Regression test suite passes (266+ tests)
- [ ] Zero sound-related crashes or exceptions

### GATE-0 Criteria (Phase 1 Complete)

- [ ] 24 `.opus` files sourced, compressed, staged in `web/dist/sounds/`
- [ ] Total compressed size < 500 KB (target: ~230 KB)
- [ ] `build-sounds.ps1` validation passes (format + size checks)
- [ ] Deployment tested on staging server
- [ ] Asset attribution log (`assets/sounds/README.md`) complete
- [ ] LLM headless walkthroughs pass (5 scenarios, deterministic seed)
- [ ] Regression baseline: all 266 tests pass
- [ ] Zero sound-related crashes or exceptions
- [ ] Checkpoint: Update `projects/sound/board.md` to `WAVE-0: ✅`

**Gate Review:** Bart (architecture), Marge (test sign-off), Nelson (LLM verification), Wayne (final approval)

---

### WAVE-1: Object-Specific Sounds (Phase 2)

**Goal:** Expand beyond creature + door sounds. Add container interactions, trap activations, puzzle sounds, and liquid effects. Objects now have rich, context-aware audio.

**Duration:** 3–4 weeks (audio production, object metadata, testing)

**Dependency:** GATE-0 passed; Phase 1 assets deployed

#### Track 1A: Sound Asset Production (CBG + Audio Production)

**Responsibility:** Produce 15–20 new audio files for Phase 2 categories.

**New Sound Categories:**

| Category | Count | Examples | Source |
|----------|-------|----------|--------|
| Container interactions | 4 | Chest open creak, drawer slide, crate creak, latch click | Sourced/created |
| Trap activation | 4 | Bear trap snap, falling club swing, rock fall thud, ceiling collapse | Sourced/created |
| Puzzle mechanics | 3 | Chain grinding, winch creaking, stone scraping | Sourced/created |
| Liquid interactions | 2 | Water slosh, pour splash | Sourced/created |
| Object destruction | 2 | Glass shatter detail, wood snap variation | May reuse from Phase 1 |

**Files:**
- EDIT `.squad/decisions/inbox/cbg-sound-assets-phase2.md` — 15–20 new files manifest with sources

**Deliverables:**
- [ ] 15–20 new `.opus` files sourced/produced
- [ ] Compressed to 48 kbps mono
- [ ] Staged in `assets/sounds/{category}/`

#### Track 1B: Object Metadata Expansion (Flanders)

**Responsibility:** Flanders adds `sounds` tables to 12+ objects (containers, traps, mechanical objects).

**Objects to Update:**

| Object | New Sound Fields | Category |
|--------|------------------|----------|
| Chest | `on_verb_open`, `on_verb_close` | Container |
| Drawer (nightstand) | `on_verb_open`, `on_verb_close` | Container |
| Crate (storage) | `on_verb_open` | Container |
| Bear Trap | `on_verb_trigger` (already has mutation hook) | Trap |
| Falling Club Trap | `on_state_sprung` | Trap |
| Falling Rock Trap | `on_state_sprung` | Trap |
| Unstable Ceiling | `on_state_collapsed` | Trap |
| Poison Gas Vent | `on_state_active` | Hazard |
| Chain (deep cellar) | `on_verb_disturb`, `on_verb_pull` | Mechanical |
| Well Winch | `on_verb_turn`, `on_verb_wind` | Mechanical |
| Wine Bottle | `on_verb_pour`, `on_verb_slosh` | Liquid |
| Rain Barrel | `on_verb_fill`, `on_verb_spill` | Liquid |

**Sound Field Pattern (same as Phase 1):**
- `on_verb_{verb}` — Triggered when verb acts on object
- `on_state_{state}` — Triggered on FSM transition
- `on_mutate` — Triggered on mutation (already defined for some)

**Files:**
- EDIT 12+ object `.lua` files in `src/meta/objects/`

**Spec Checklist (per object):**
- [ ] Every updated object has existing `on_feel` + `on_listen`
- [ ] Sound filenames reference files in Phase 2 asset list
- [ ] No orphan sound fields (all keys in resolution chain)
- [ ] GUID consistency (pre-assigned by Bart in `.squad/decisions/inbox/`)

**Deliverables:**
- [ ] 12+ objects updated with Phase 2 sound tables
- [ ] Metadata validation tests pass
- [ ] Design review (CBG) identifies any audio/gameplay conflicts

#### Track 1C: Testing & Validation (Nelson)

**Responsibility:** Nelson writes integration tests for object sound triggers.

**Files:**
- CREATE `test/sound/test-object-sounds-phase2.lua` — Trigger tests for containers, traps, mechanical objects
- CREATE `test/sound/test-sound-scenarios-phase2.lua` — LLM headless scenarios (open chest, trigger trap, pour liquid)

**Test Coverage:**
- [ ] Container open → sound triggers
- [ ] Trap trigger → sound fires (match FSM transition)
- [ ] Mechanical objects → sound on verb
- [ ] Liquid objects → sound on pour/spill verbs
- [ ] Headless mode: all triggers record in mock driver
- [ ] No ghost sounds; sounds stop when object state changes

**LLM Scenarios:**
1. Open chest → expect chest-open.opus
2. Trigger bear trap → expect trap-snap.opus
3. Pour wine → expect liquid-pour.opus
4. All scenarios pass without crash

**Deliverables:**
- [ ] Object sound integration tests written
- [ ] 3–4 LLM headless scenarios pass
- [ ] Regression baseline maintained

### GATE-1 Criteria (Phase 2 Complete)

- [ ] 15–20 Phase 2 audio files produced, compressed, staged
- [ ] 12+ objects updated with sound tables
- [ ] Metadata validation tests pass
- [ ] Object sound integration tests pass
- [ ] LLM headless walkthroughs pass (3–4 scenarios)
- [ ] Zero regressions
- [ ] Checkpoint: Update board to `WAVE-1: ✅`

---

### WAVE-2A: Creature Audio Evolution (Phase 3A)

**Goal:** Deepen creature audio identity. Per-state sounds, behavioral variation, injury vocalizations. Creatures are the primary threat; sound makes them emotionally present.

**Duration:** 4–5 weeks (creature behavior trace, audio production, integration)

**Dependency:** GATE-0 passed (Phase 1 assets available)

#### Track 2A.1: Creature Audio Expansion (Flanders + Audio Production)

**Responsibility:** Expand creature sound palette from 8 MVP sounds to 20+ state-specific sounds.

**Creature Per-State Audio Map:**

| Creature | State | Current MVP | New Phase 3 | Audio File |
|----------|-------|-------------|-------------|------------|
| **Rat** | idle | ✓ | ✓ (enhanced) | `rat-idle.opus` |
| | wander | ✓ | ✓ (add footsteps variant) | `rat-scurry.opus` (new) |
| | hunt | — | ✓ (predatory breathing) | `rat-hunt-breathe.opus` (new) |
| | injured | — | ✓ (pain squeak) | `rat-pain.opus` (new) |
| | dead | Silence | Silence | — |
| **Wolf** | idle | ✓ | ✓ | `wolf-breathe.opus` |
| | wander | ✓ | ✓ | `wolf-sniff.opus` |
| | patrol | ✓ (growl low) | ✓ | `wolf-growl-low.opus` |
| | aggressive | ✓ (snarl) | ✓ (more intense variant) | `wolf-snarl-intense.opus` (new) |
| | injured | — | ✓ (whimper/pain) | `wolf-whimper.opus` (new) |
| | dead | Silence | Silence | — |
| **Cat** | idle | ✓ (purr) | ✓ | `cat-purr.opus` |
| | hunt | Silence | Silence (intentional) | — |
| | injured | — | ✓ (hiss/growl on pain) | `cat-pain-hiss.opus` (new) |
| | dead | Silence | Silence | — |
| **Bat** | roosting | ✓ (echo) | ✓ | `bat-echo.opus` |
| | flying | ✓ (wings/squeak) | ✓ (add wing flutter variant) | `bat-flutter.opus` (new) |
| | injured | — | ✓ (wounded screech) | `bat-screech-pain.opus` (new) |
| | dead | Silence | Silence | — |
| **Spider** | idle | ✓ (scratch) | ✓ | `spider-scratch.opus` |
| | web-building | ✓ (silk ticking) | ✓ | `spider-silk.opus` |
| | injured | — | ✓ (frantic skitter) | `spider-panic-skitter.opus` (new) |
| | dead | Silence | Silence | — |

**Creature Death Silence Design (Principle D-SOUND-8):**
- When a creature dies: FSM transitions to `dead` state
- `on_listen` text updates: `"The [creature] is motionless. No breath, no sound."`
- No `on_state_dead` sound is produced — **silence IS the signal**
- Creature object remains in room as a dead body (not deleted)
- Engine calls `sound_manager:stop_by_owner(creature_id)` to halt ambient loops

**Files:**
- EDIT 5 creature `.lua` files in `src/meta/creatures/`

**Spec Checklist (per creature):**
- [ ] All existing per-state sounds assigned (Phase 1 MVP)
- [ ] New per-state sounds declared (injured, enhanced variants)
- [ ] Death state: `on_listen` explicitly describes silence; NO `on_state_dead` sound
- [ ] Creature GUID consistent with pre-assignment

**Audio Production:**
- [ ] 12+ new creature sound files produced (injury variants, enhanced states)
- [ ] Compressed to 48 kbps mono, staged in `assets/sounds/creatures/`

**Deliverables:**
- [ ] 12+ creature audio files (Phase 3 new sounds)
- [ ] 5 creatures updated with Phase 3 per-state sounds
- [ ] Death silence design verified (no sounds on `dead` state)

#### Track 2A.2: Injury System Audio Integration (Combat Team + Flanders)

**Responsibility:** Integrate creature audio with injury system. Creatures vocalize pain when injured.

**Injury-to-Audio Mapping:**

| Injury Type | Creature Response | Sound File |
|-------------|------------------|-----------|
| Gash (bleeding) | Creature vocalizes pain (severity-dependent) | Creature-specific pain sound |
| Numbness | Creature limps, quieter vocalization | Creature-specific struggle sound |
| Poison hiss | Creature chokes/gags (for poison source) | Generic poison-cough.opus |
| Fatal injury | Creature continues to `dead` state (silence) | — |

**Files:**
- EDIT `src/engine/injuries.lua` — Add sound trigger after FSM state change on injury
- Pattern: `if context.sound_manager then context.sound_manager:trigger(creature, "on_verb_injured") end` (nil-safe)

**Coordination:**
- Combat team provides injury event trace (which injury → which creature state)
- Flanders declares `on_verb_injured` on creature sound tables
- Engine hook in injuries.lua calls trigger

**Deliverables:**
- [ ] Injury system emits sound triggers
- [ ] Creature pain audio fires on injury
- [ ] Death silence (no sound on creature death) verified

#### Track 2A.3: Testing (Nelson)

**Files:**
- CREATE `test/sound/test-creature-sounds-phase3.lua` — Per-state sound triggers
- CREATE `test/sound/test-creature-injury-audio.lua` — Injury vocalizations
- CREATE `test/sound/scenarios/phase3-creature-audio.txt` — LLM headless scenarios

**Test Coverage:**
- [ ] Each creature state transition → correct sound
- [ ] Creature injured → pain vocalization fires
- [ ] Creature dead → silence (no sound)
- [ ] Ambient loop stops when creature dies (stop_by_owner works)

**LLM Scenarios:**
1. Encounter wolf (aggressive) → wolf-snarl.opus
2. Attack rat (injury) → rat-pain.opus
3. Kill wolf (death) → silence, then continued interaction

**Deliverables:**
- [ ] Creature audio integration tests pass
- [ ] LLM scenarios pass
- [ ] Zero regressions

### GATE-2A Criteria (Phase 3A Complete)

- [ ] 12+ creature audio files produced (Phase 3 new + enhanced)
- [ ] 5 creatures updated with per-state sounds
- [ ] Death silence verified (no on_state_dead sounds)
- [ ] Injury system integration complete
- [ ] Creature pain audio fires on injury
- [ ] Creature audio integration tests pass
- [ ] LLM headless scenarios pass
- [ ] Zero regressions
- [ ] Checkpoint: Update board to `WAVE-2A: ✅`

---

### WAVE-2B: Combat Immersion (Phase 4)

**Goal:** Make combat visceral through sound. Weapon impacts, armor feedback, creature vocalizations, death sequences. Combat becomes a multi-sensory experience.

**Duration:** 3–4 weeks (combat trace analysis, audio production, verb integration)

**Dependency:** GATE-2A passed; combat system understood; injury system audio integrated

#### Track 2B.1: Combat Audio Asset Production (CBG + Audio)

**Responsibility:** Produce weapon, armor, and impact sound files.

**Combat Audio Map:**

| Impact Type | Source | Sound File | Notes |
|-------------|--------|-----------|-------|
| **Blunt impact** | Mace, club, rock | `impact-blunt.opus` | Heavy, dull thud |
| **Slashing impact** | Sword, dagger | `impact-slash.opus` | Metallic swish + flesh contact |
| **Piercing impact** | Spear, arrow | `impact-pierce.opus` | Sharp penetration sound |
| **Crushing impact** | Bear trap, falling object | `impact-crush.opus` | Mechanical snap (trap), impact (object) |
| **Armor hit (leather)** | Hit on leather armor | `armor-leather-hit.opus` | Dull thump on hide |
| **Armor hit (plate)** | Hit on plate armor | `armor-plate-ricochet.opus` | Metallic ring (glancing) or clang (solid) |
| **Block/parry** | Successful block | `block-deflect.opus` | Weapon-to-weapon clash |
| **Dodge/roll** | Evaded attack | `dodge-roll.opus` | Fast movement sound (optional) |
| **Creature pain hiss** | Poisoned creature | `poison-cough.opus` | Choking/coughing sound |
| **Creature death** | Creature dies | — | Silence (per D-SOUND-8) |

**Audio Production:**
- [ ] 8–10 combat impact files produced
- [ ] Compressed to 48 kbps mono
- [ ] Staged in `assets/sounds/combat/`

**Deliverables:**
- [ ] Combat audio files ready for integration

#### Track 2B.2: Combat Verb Integration (Smithers + Combat Team)

**Responsibility:** Wire combat sounds into verb dispatch and effects pipeline.

**Combat Verbs with Sound:**
- `ATTACK` → impact sound based on weapon + target armor
- `DEFEND` → block/parry sound (if successful defense)
- `FLEE` → dodge/roll sound

**Verb-to-Sound Mapping:**

| Verb | Condition | Sound Trigger |
|------|-----------|---------------|
| ATTACK | Hit target | `on_verb_attack_{weapon_class}` (e.g., `on_verb_attack_blunt`) |
| ATTACK | Miss target | `on_verb_attack_miss` (swing-and-miss) |
| DEFEND | Block successful | `on_verb_defend_block` |
| DEFEND | Armor takes hit | `on_verb_defend_armor_{armor_type}` (e.g., `on_verb_defend_armor_plate`) |
| FLEE | Roll success | `on_verb_flee_dodge` |

**Files:**
- EDIT `src/engine/verbs/init.lua` — Add sound dispatch for combat verbs
- Pattern: `if context.sound_manager then context.sound_manager:trigger(target, "on_verb_attack_" .. weapon_type) end`

**Scope:**
- Weapon impact sounds fire AFTER combat text output
- Armor feedback fires immediately after weapon impact
- Creature pain vocalization (already integrated in WAVE-2A) plays concurrently
- **Combat sound budget: 3 simultaneous max** (ambient ducked, creature vocalization, impact sound)

**Deliverables:**
- [ ] Combat verbs integrated with sound dispatch
- [ ] Weapon impact sounds fire on successful attacks
- [ ] Armor feedback fires on blocked attacks
- [ ] Creature vocalizations play on injury (from WAVE-2A)

#### Track 2B.3: Testing (Nelson)

**Files:**
- CREATE `test/sound/test-combat-sounds.lua` — Combat trigger tests
- CREATE `test/sound/scenarios/phase4-combat.txt` — LLM headless scenarios

**Test Coverage:**
- [ ] Attack blunt target → `impact-blunt.opus`
- [ ] Attack plate-armored target → `armor-plate-ricochet.opus`
- [ ] Defend block → `block-deflect.opus`
- [ ] Creature injury vocalization fires concurrently
- [ ] Max 3 concurrent sounds (oldest evicted if exceeded)

**LLM Scenarios:**
1. Attack rat with weapon → impact sound + creature pain sound
2. Defend against creature attack → block sound + armor feedback
3. Kill creature in combat → death silence (no sound)

**Deliverables:**
- [ ] Combat sound integration tests pass
- [ ] LLM scenarios pass
- [ ] Zero regressions

### GATE-2B Criteria (Phase 4 Complete)

- [ ] 8–10 combat impact audio files produced
- [ ] Combat verbs integrated with sound dispatch
- [ ] Weapon impact sounds fire on attack
- [ ] Armor feedback fires on hit
- [ ] Creature pain vocalizations integrated
- [ ] Combat sound tests pass
- [ ] LLM headless scenarios pass
- [ ] Max 3 concurrent sounds budget verified
- [ ] Zero regressions
- [ ] Checkpoint: Update board to `WAVE-2B: ✅`

---

### WAVE-3: Time-of-Day Ambient Variation (Phase 5)

**Goal:** The world evolves sonically throughout the day. Day vs. night ambience. Smooth crossfades. Blocked on Level 2 time progression system.

**Duration:** 2–3 weeks (time system understanding, ambient swap, integration, testing)

**Dependency:** GATE-2B passed; Level 2 time system available; **Phase 5 is BLOCKED if L2 time system not ready**

**Status:** Deferred until Level 2 time design complete. If L2 timeline unclear, recommend standalone Phase 5 design (fixed time-of-day without L2 coupling).

#### Track 3.1: Time-Aware Ambient Design (Moe + CBG)

**Responsibility:** Define per-room ambient variation by time-of-day.

**Time-of-Day Bands:**

| Time | Atmosphere | Room Adjustments |
|------|-----------|------------------|
| **2 AM – 6 AM (deep night)** | Cold, oppressive, owl-heavy | Deep reverb, owls in courtyard, minimal other sounds |
| **6 AM – 12 PM (morning)** | Awakening, bird activity, cool light | Bird chirps emerge (courtyard), interior rooms warm slightly |
| **12 PM – 6 PM (afternoon)** | Active, warm, distant activity | Distant carts/activity (courtyard), lighter ambience in cellars |
| **6 PM – 9 PM (evening)** | Wind picks up, transition to night | Wind intensifies (courtyard), shadows in cellars, tension builds |
| **9 PM – 2 AM (night)** | Dark, oppressive, quiet | Full night ambience (back to 2 AM state) |

**Per-Room Ambient Variation:**

| Room | Current MVP | Night (2–6 AM) | Day (6 AM–6 PM) | Evening (6–9 PM) |
|------|-------------|----------------|-----------------|------------------|
| Bedroom | `amb-bedroom-silence.opus` | MVP (no change) | Slightly warmer tone | MVP |
| Hallway | `amb-hallway-torches.opus` | MVP + owl hoot (rare) | MVP + bird sounds (rare) | MVP + wind |
| Cellar | `amb-cellar-drip.opus` | MVP (deep reverb) | MVP (normal reverb) | MVP |
| Storage | `amb-storage-scratching.opus` | MVP (rat active) | Rat quieter | MVP |
| Deep Cellar | `amb-deep-cellar-silence.opus` | MVP | MVP | MVP |
| Crypt | `amb-crypt-void.opus` | MVP | MVP | MVP |
| Courtyard | `amb-courtyard-wind.opus` | MVP + owl hoots | Lighter, cart sounds | Wind intensifies |

**Crossfade Timing:**
- Time threshold crossing triggers ambient swap
- Fade out: 1.5 seconds (old ambient)
- Crossfade: 0.5 seconds (silence)
- Fade in: 1.5 seconds (new ambient)
- Total transition: ~3.5 seconds (imperceptible to player)

**Files:**
- EDIT 7 room `.lua` files in `src/meta/world/`
- Add: `ambient_loop_night`, `ambient_loop_day`, `ambient_loop_evening` (instead of single `ambient_loop`)

**OR** (if L2 time system not available):
- Use **static 2 AM ambience for all rooms** (MVP design)
- Defer per-time variation to Phase 5 polish cycle
- Simplify: keep single `ambient_loop` per room, remove time variation

**Deliverables:**
- [ ] Time-of-day ambient map defined (CBG + Moe)
- [ ] New ambient audio files produced (if time variation approved)
- [ ] Room ambient fields updated

#### Track 3.2: Time-of-Day Integration (Moe + Gil + Level 2 team)

**Responsibility:** Integrate L2 time system with sound manager ambient swaps.

**Integration Points:**
1. L2 time engine outputs: current time-of-day band (NIGHT, MORNING, DAY, EVENING)
2. Sound manager listens for time transitions
3. On time band change: crossfade from old ambient to new ambient

**Files:**
- EDIT `src/engine/sound/init.lua` — Add `set_time_of_day(band)` method
- EDIT Level 2 time module — Call `sound_manager:set_time_of_day(band)` on transition

**Crossfade Implementation:**
- Web driver: fade out (1.5s) → stop → fade in (1.5s) new ambient
- Terminal driver: stop old, play new (no fade)

**Deliverables:**
- [ ] Sound manager integrates with L2 time system
- [ ] Ambient crossfades on time transitions
- [ ] Crossfade timing verified (smooth 3.5s transition)

#### Track 3.3: Testing (Nelson)

**Files:**
- CREATE `test/sound/test-time-of-day-ambient.lua` — Time transition tests
- CREATE `test/sound/scenarios/phase5-time-variation.txt` — LLM headless scenarios

**Test Coverage:**
- [ ] Time transition → ambient swap
- [ ] Crossfade timing correct (1.5s out, 1.5s in)
- [ ] No ghost sounds during transition

**LLM Scenarios:**
1. Advance time from 2 AM to 6 AM → ambient shift
2. Full 24-hour loop → all time bands tested

**Deliverables:**
- [ ] Time-of-day integration tests pass
- [ ] LLM scenarios pass

### GATE-3 Criteria (Phase 5 Complete — If L2 Ready)

- [ ] Level 2 time system available (BLOCKER: if not ready, GATE-3 defers)
- [ ] Per-time ambient audio files produced (if variation approved)
- [ ] Room ambient fields updated with time variants
- [ ] Sound manager integrates with L2 time system
- [ ] Ambient crossfades smooth (3.5s total)
- [ ] Time-of-day integration tests pass
- [ ] LLM scenarios pass
- [ ] Zero regressions
- [ ] Checkpoint: Update board to `WAVE-3: ✅` (or mark BLOCKED)

**Escalation:** If L2 time system unavailable after 1 week, escalate to Wayne for defer decision.

---

### WAVE-4: Weather Audio Integration (Phase 6)

**Goal:** Dynamic sound layers driven by Level 2 weather system. Rain, wind, thunder, fog all affect the sonic environment.

**Duration:** 3–4 weeks (weather FSM understanding, audio production, integration, testing)

**Dependency:** GATE-3 passed; Level 2 weather engine available; **Phase 6 is BLOCKED if L2 weather not ready**

**Status:** Deferred until Level 2 weather design complete. Recommend similar defer strategy as Phase 5.

#### Track 4.1: Weather Audio Design (CBG + Moe + L2 Team)

**Responsibility:** Define weather-specific ambient layers.

**Weather Conditions & Sound Map:**

| Condition | Sound Layer | Rooms Affected | Notes |
|-----------|------------|---|---|
| **Clear** | None (use time-of-day ambient) | All | No weather overlay |
| **Rain** | `weather-rain-patter.opus` (loop) | All | Loud on courtyard, muffled in cellars |
| **Wind** | `weather-wind-howl.opus` (loop) | Courtyard, Hallway | Minimal in cellars |
| **Thunder** | `weather-thunder-distant.opus` (one-shot) | All | On random intervals during rain |
| **Fog/Mist** | None | Courtyard only | Visual effect; sound is echo reduction (future) |

**Weather Mixing (concurrent sounds):**
- Base ambient: ambient_loop (time-of-day adjusted)
- Weather layer: rain/wind/fog (max 2 concurrent)
- Max total: 4 concurrent (oldest evicted)

**Files:**
- Produces 4–6 weather audio files (rain, wind, thunder)

**Deliverables:**
- [ ] Weather audio files produced
- [ ] Weather-to-sound mapping defined

#### Track 4.2: L2 Weather Integration (Gil + L2 Team)

**Responsibility:** Integrate L2 weather FSM with sound manager.

**Integration Points:**
1. L2 weather engine outputs: current weather state (CLEAR, RAIN, WIND, THUNDER, FOG)
2. Sound manager listens for weather changes
3. On weather change: start/stop weather sound layers

**Files:**
- EDIT `src/engine/sound/init.lua` — Add `set_weather(condition)` method
- EDIT Level 2 weather module — Call `sound_manager:set_weather(condition)` on transition

**Mixing Rules:**
- Clear weather → only time-of-day ambient
- Rain → rain layer + time-of-day ambient (30% volume duck)
- Wind → wind layer + time-of-day ambient
- Thunder → one-shot (interrupts other sounds, priority)

**Deliverables:**
- [ ] Sound manager integrates with L2 weather system
- [ ] Weather layers mix correctly
- [ ] Thunder interrupts and re-establishes ambient

#### Track 4.3: Testing (Nelson)

**Files:**
- CREATE `test/sound/test-weather-sounds.lua` — Weather state tests
- CREATE `test/sound/scenarios/phase6-weather.txt` — LLM scenarios

**Test Coverage:**
- [ ] Weather change → sound layer starts/stops
- [ ] Rain + time-of-day ambient mix (correct volume)
- [ ] Thunder interrupts and re-establishes

**LLM Scenarios:**
1. Weather changes to RAIN → rain layer starts
2. Thunder during rain → thunder one-shot fires
3. Weather clears → rain stops, time-of-day ambient resumes

**Deliverables:**
- [ ] Weather integration tests pass
- [ ] LLM scenarios pass

### GATE-4 Criteria (Phase 6 Complete — If L2 Ready)

- [ ] Level 2 weather system available (BLOCKER)
- [ ] 4–6 weather audio files produced
- [ ] Sound manager integrates with L2 weather
- [ ] Weather layers mix correctly
- [ ] Thunder interrupts behavior verified
- [ ] Weather integration tests pass
- [ ] LLM scenarios pass
- [ ] Zero regressions
- [ ] Checkpoint: Update board to `WAVE-4: ✅` (or mark BLOCKED)

---

### WAVE-5: Music & Score (Phase 7)

**Goal:** Establish whether MMO wants a non-diegetic score. Design decision required. If approved, produce music and integrate. If not, formally defer.

**Duration:** 1 week (decision capture) + 4–6 weeks (if approved; composition is time-intensive)

**Dependency:** Design decision (Wayne)

**Status:** DESIGN-PENDING

#### Track 5.1: Music Design Decision (CBG + Wayne)

**Responsibility:** CBG presents options; Wayne decides.

**Design Questions:**

1. **Score type:** Non-diegetic (underscore) vs. diegetic (in-world instruments)?
   - **Non-diegetic:** Background music mood (exploration, danger, discovery) — typical for games
   - **Diegetic:** In-world music from bells, lutes, organs in specific locations — more immersive to text adventure
   - **Hybrid:** Both (non-diegetic underscore + diegetic instruments in locations)

2. **State reactivity:** Should music respond to game state?
   - **Static:** Single track per area (hallway theme, cellar theme)
   - **Dynamic:** Theme shifts on danger (combat mode), discovery (puzzle solved), mood (injured player)
   - **Silence:** Music optional; turn off for immersion

3. **Scope:** How many music pieces?
   - **MVP:** 3–5 area themes (bedroom, cellar, crypt, courtyard, etc.)
   - **Full:** 10+ pieces with state variations, leitmotifs, transitions

4. **Composition:** In-house or commission?
   - **Commission:** Composer hired (cost/timeline impact); produces professional score
   - **In-house:** CBG + GarageBand or similar; faster, acceptable for indie

**Files:**
- CREATE `.squad/decisions/inbox/cbg-music-design-phase7.md` — Music design options + recommendation
- Wayne responds: YES / NO / DEFER

**Outcome 1 (YES - Approved):**
- Move to Track 5.2 (composition timeline)
- Estimate: 4–6 weeks if commissioned, 2–3 weeks if in-house

**Outcome 2 (NO - Rejected):**
- Formal decision: "No music in Level 1; music deferred to future levels if approved"
- WAVE-5 complete; no implementation needed

**Outcome 3 (DEFER):**
- Explicit defer decision captured
- WAVE-5 blocks; note in project board

**Deliverable:**
- [ ] Music design decision captured to `.squad/decisions.md`

#### Track 5.2: Music Production & Integration (Composer + Gil + Nelson) — If Approved

**Responsibility:** Produce music files; integrate into game.

**Scope (if approved):**
- 3–5 area themes (estimated 30–60 minutes of composition)
- Compressed to MP3/OGG (~128 kbps)
- Integrated into sound manager as `music` category
- State-reactive triggers (optional)

**Files:**
- Produce `.opus` or `.mp3` music files
- EDIT sound manager: add `play_music()` method (different from SFX)
- EDIT verbs: trigger music state changes (optional)

**Deliverables (if approved):**
- [ ] Music files produced
- [ ] Sound manager music API exposed
- [ ] Integration tests pass

### GATE-5 Criteria (Phase 7 Complete or Deferred)

- [ ] Music design decision captured and approved
- [ ] (If approved) Music files produced and integrated
- [ ] (If approved) Music API tests pass
- [ ] Checkpoint: Update board to `WAVE-5: ✅` or `WAVE-5: DEFERRED`

---

### WAVE-6: Accessibility & Volume Controls (Phase 8)

**Goal:** Robust accessibility layer without making sound mandatory. Ensure deaf and hard-of-hearing players access 100% of information. Parallel work with Phases 2–4.

**Duration:** 2–3 weeks (UI implementation, testing, accessibility audit)

**Dependency:** Phases 1–2 complete; can run in parallel with Phases 3–4

#### Track 6.1: Volume Controls & UI (Smithers)

**Responsibility:** Smithers implements volume UI and toggles.

**Player Controls (MVP):**

| Control | Default | Type | Notes |
|---------|---------|------|-------|
| Master volume | 80% | Slider 0–100 | Single master gain |
| Sound effects | ON | Toggle | On/off for all SFX |
| Ambient loops | ON | Toggle | Separate from SFX (some players want action but not loops) |
| Creature sounds | ON | Toggle | Some players find anxiety-inducing; respect choice |
| Text-only mode | OFF | Toggle | When ON, suppresses all audio (explicit mute) |

**Files:**
- EDIT `src/engine/ui/init.lua` — Add volume slider + toggle buttons
- EDIT `src/engine/sound/init.lua` — Add methods: `set_master_volume(level)`, `set_category_enabled(category, bool)`

**UI Layout (web):**
```
┌─────────────────────────────┐
│ Sound Settings              │
├─────────────────────────────┤
│ Master Volume: [━━━━┳━━]80% │
├─────────────────────────────┤
│ ☑ Sound Effects             │
│ ☑ Ambient Loops             │
│ ☑ Creature Sounds           │
│ ☐ Text-Only Mode            │
└─────────────────────────────┘
```

**Persistence:**
- Store settings in `localStorage` (web) / player profile (future)
- Load on game boot

**Deliverables:**
- [ ] Volume slider UI implemented
- [ ] Category toggles implemented
- [ ] Settings persist across sessions
- [ ] UI tests pass

#### Track 6.2: Accessibility Audit & Documentation (Accessibility Lead + Nelson)

**Responsibility:** Verify deaf/hard-of-hearing access; test screen reader compatibility.

**Accessibility Checklist:**

| Item | Check | Status |
|------|-------|--------|
| All sound events have text equivalent | ✓ (by design: Principle 8) | — |
| `on_listen` descriptions complete for all creatures | ✓ (Phase 1–3) | — |
| Volume controls accessible via keyboard | Nelson test | — |
| Screen reader compatibility (ARIA labels) | Nelson test | — |
| Text-only mode suppresses all audio | Nelson test | — |
| No critical info exclusive to audio | CBG + Nelson review | — |
| Haptic feedback layer (future: Phase 8+) | Research only | N/A |

**Files:**
- CREATE `docs/accessibility/sound-accessibility.md` — Accessibility guidelines + checklist
- CREATE `test/sound/test-accessibility.lua` — Screen reader compatibility tests

**LLM Scenarios:**
1. Deaf player mode (text-only): Full level 1 playthrough without sound
2. Screen reader: Navigate UI + play game (verify no audio interference)

**Deliverables:**
- [ ] Accessibility checklist complete
- [ ] Screen reader tests pass
- [ ] Text-only mode verified
- [ ] Documentation shipped

### GATE-6 Criteria (Phase 8 Complete)

- [ ] Volume slider UI implemented and tested
- [ ] Category toggles (SFX, ambient, creature) working
- [ ] Settings persist across sessions
- [ ] Accessibility audit passed
- [ ] Screen reader compatibility verified
- [ ] Text-only mode suppresses audio
- [ ] Deaf/hard-of-hearing players access 100% of info
- [ ] LLM accessibility scenarios pass
- [ ] Documentation shipped
- [ ] Zero regressions
- [ ] Checkpoint: Update board to `WAVE-6: ✅`

---

## Testing Gates (Binary Pass/Fail Checkpoints)

| Gate | Phase | Triggers | Pass Criteria | Fail Escalation |
|------|-------|----------|---------------|-----------------|
| **GATE-0** | 1 (MVP Assets) | End of WAVE-0 | 24 files deployed, <500 KB, LLM scenarios pass, 0 regressions | File 1x issue, 2x escalate to Wayne |
| **GATE-1** | 2 (Objects) | End of WAVE-1 | 12+ objects updated, object tests pass, LLM scenarios pass, 0 regressions | Fix and re-gate (same session) |
| **GATE-2A** | 3 (Creatures) | End of WAVE-2A | 5 creatures updated, death silence verified, injury audio working, 0 regressions | Fix and re-gate |
| **GATE-2B** | 4 (Combat) | End of WAVE-2B | Combat verbs integrated, impact sounds fire, 3-concurrent budget verified, 0 regressions | Fix and re-gate |
| **GATE-3** | 5 (Time) | End of WAVE-3 | L2 time system ready (blocker), ambient crossfades work, 0 regressions | Escalate to Wayne if L2 unavailable |
| **GATE-4** | 6 (Weather) | End of WAVE-4 | L2 weather system ready (blocker), weather layers mix, 0 regressions | Escalate to Wayne if L2 unavailable |
| **GATE-5** | 7 (Music) | End of WAVE-5 | Design decision captured, (if approved) music integrated, 0 regressions | Defer if not approved |
| **GATE-6** | 8 (Accessibility) | End of WAVE-6 | Volume UI working, toggles working, accessibility audit passed, 0 regressions | Fix and re-gate |

**Gate Review Team:**
- **Bart** (architecture): Engine integration, API contracts, technical soundness
- **Marge** (QA): Test coverage, regression baseline, regressions present/absent
- **Nelson** (LLM testing): Headless walkthroughs, deterministic scenarios, no crashes
- **Wayne** (final): Design decisions, blocker escalation, overall go/no-go

**Regression Baseline:** Captured at start of each wave. Gate checks: baseline count ≤ gate test count (no regressions).

---

## Feature Breakdown (Per System)

### Asset Management System

**Scope:** Sourcing, compression, deployment of 24+ audio files across phases.

**Responsibilities:**
- **CBG:** Asset sourcing, licensing verification, design review
- **Gil:** Compression pipeline, deployment validation, cache-busting

**Integration Points:**
- `web/build-sounds.ps1` — Validate + compress all files
- `web/deploy.ps1` — Copy to GitHub Pages `play/sounds/`
- `assets/sounds/README.md` — Attribution tracking

**Deliverables:**
- [ ] `assets/sounds/` directory structured: `creatures/`, `objects/`, `combat/`, `ambient/`, `weather/`, `music/` (if used)
- [ ] Attribution log for CC-BY sounds
- [ ] Build pipeline validated

### Sound Manager API Extension

**Scope:** New methods for time-of-day and weather state management.

**New Methods:**
- `M:set_time_of_day(band)` — Update ambient based on time (NIGHT, MORNING, DAY, EVENING)
- `M:set_weather(condition)` — Update weather sound layers (CLEAR, RAIN, WIND, THUNDER, FOG)
- `M:set_master_volume(level)` — Master volume control (0–100)
- `M:set_category_enabled(category, bool)` — Toggle SFX, ambient, creature, music

**Files:**
- EDIT `src/engine/sound/init.lua` — Add 4 new methods

**Backward Compatibility:** All new methods are optional; existing API unchanged.

### Object Metadata Expansion

**Scope:** Add `sounds` tables to 20+ objects across phases.

**Phases:**
- Phase 1 (MVP): 5 creatures + 8 doors (COMPLETE, WAVE-0)
- Phase 2: 12+ containers, traps, mechanical objects (WAVE-1)
- Phase 3: 5 creatures expanded with per-state sounds (WAVE-2A)

**Sound Field Naming:** Consistent across all phases:
- `on_state_{state}` — FSM transition sound
- `on_verb_{verb}` — Verb action sound
- `on_mutate` — Mutation sound
- `ambient_loop` — Continuous ambient (object-specific)
- `ambient_{state}` — State-specific ambient

### Integration Hooks

**Scope:** Engine event points that trigger sounds.

**Phases:**
- Phase 1 (MVP): FSM transitions, room entry/exit, verb dispatch (COMPLETE, WAVE-2)
- Phase 2: Object-specific verb sounds (WAVE-1 testing)
- Phase 3–4: Creature injury vocalizations, combat sound dispatch (WAVE-2A/2B)
- Phase 5: Time-of-day ambient swaps (WAVE-3)
- Phase 6: Weather layer integration (WAVE-4)

**Hook Points (per Unified Plan v1.1):**
- FSM state transition → `trigger(obj, "on_state_{new_state}")`
- Verb execution → `trigger(obj, "on_verb_{verb}")`
- Object mutation → `trigger(obj, "on_mutate")`
- Room entry/exit → `enter_room(room)` / `exit_room(room)`
- Injury infliction → `trigger(creature, "on_verb_injured")`

### Web UI Controls

**Scope:** Volume slider and toggles in game UI.

**Phases:**
- Phase 1–2 (MVP): Master volume + 3 toggles (WAVE-6)
- Phase 3+ (future): Per-category sliders, visualization, EQ (deferred)

**Files:**
- EDIT `src/engine/ui/init.lua` — Add sound settings panel

### Testing & QA

**Scope:** Comprehensive test coverage across all phases.

**Test Files (Phase 1–8):**
- `test/sound/test-sound-manager.lua` (COMPLETE)
- `test/sound/test-sound-defaults.lua` (COMPLETE)
- `test/sound/test-sound-metadata.lua` (COMPLETE)
- `test/sound/test-sound-integration.lua` (COMPLETE)
- `test/sound/test-object-sounds-phase2.lua` (WAVE-1)
- `test/sound/test-creature-sounds-phase3.lua` (WAVE-2A)
- `test/sound/test-creature-injury-audio.lua` (WAVE-2A)
- `test/sound/test-combat-sounds.lua` (WAVE-2B)
- `test/sound/test-time-of-day-ambient.lua` (WAVE-3)
- `test/sound/test-weather-sounds.lua` (WAVE-4)
- `test/sound/test-accessibility.lua` (WAVE-6)

**LLM Scenarios (Phase 1–8):**
- Phase 1: 5 scenarios (asset verification, room ambient, creature encounter, door traversal, full walkthrough)
- Phase 2: 3–4 scenarios (container open, trap trigger, liquid pour)
- Phase 3: 2–3 scenarios (creature state, injury vocalization, death silence)
- Phase 4: 2–3 scenarios (weapon impact, armor feedback, combat death)
- Phase 5: 2 scenarios (time transition, 24-hour loop)
- Phase 6: 2–3 scenarios (weather change, thunder, fog)
- Phase 7: 1–2 scenarios (music state reactive, if approved)
- Phase 8: 2 scenarios (deaf player full playthrough, screen reader navigation)

**Regression Baseline:** Established at GATE-0 (Phase 1 complete). Each subsequent gate must match or exceed baseline test count.

---

## Cross-System Integration Points

### Sound Manager ↔ Effects Pipeline

**Pattern:** Objects declare sounds via metadata; effects pipeline dispatches `play_sound` type. Verb handlers do NOT call `sound_manager:trigger()` directly.

```lua
-- Verb handler (no direct sound call)
function verbs.break(context, noun)
    local obj = context.registry:find_by_keyword(noun)
    context.effects:process(obj, "play_sound", "on_verb_break")
    -- ... rest of verb logic
end

-- Effects handler
effects.register("play_sound", function(context, obj, event_key)
    if context.sound_manager then
        context.sound_manager:trigger(obj, event_key)
    end
end)
```

**Benefits:** No dual-path dispatch; effects pipeline is canonical; nil-safe at the effects layer.

### Sound Manager ↔ FSM

**Pattern:** FSM triggers sound on state transition.

```lua
-- In fsm.transition()
if context.sound_manager then
    context.sound_manager:trigger(obj, "on_state_" .. new_state)
end
```

### Sound Manager ↔ Injuries

**Pattern:** Injury infliction triggers creature pain vocalization.

```lua
-- In injuries.inflict()
if context.sound_manager then
    context.sound_manager:trigger(creature, "on_verb_injured")
end
```

### Sound Manager ↔ Level 2 Systems

**Pattern (Time-of-Day):** L2 time module notifies sound manager on time band change.

```lua
-- In level2/time.lua
function L2:tick()
    local new_band = self:get_time_band()
    if new_band ~= self._current_band then
        if context.sound_manager then
            context.sound_manager:set_time_of_day(new_band)
        end
        self._current_band = new_band
    end
end
```

**Pattern (Weather):** L2 weather module notifies sound manager on weather change.

```lua
-- In level2/weather.lua
function L2Weather:update()
    local new_condition = self:get_condition()
    if new_condition ~= self._current_condition then
        if context.sound_manager then
            context.sound_manager:set_weather(new_condition)
        end
        self._current_condition = new_condition
    end
end
```

### Web Audio Driver ↔ Fengari Bridge

**Pattern:** All JS calls wrapped in `pcall()` to prevent sound failures from crashing the game.

```lua
-- In web-driver.lua
local ok, result = pcall(function()
    return js.global._soundPlay(id, opts)
end)
if not ok then
    -- Log error (debug mode), continue silently
    if DEBUG then print("Sound play error: " .. tostring(result)) end
end
```

---

## Nelson LLM Test Scenarios

All scenarios use `--headless` mode with deterministic seed (`math.randomseed(42)`).

### Phase 1 Scenarios (Asset Verification)

**Scenario 1.1: Room Ambient Load (No Crash)**
```bash
echo "look" | lua src/main.lua --headless --seed=42
# Expected: Room description, on_listen text, no sound errors
# Mock driver: ambient_loop queued (or no-op in headless)
```

**Scenario 1.2: Creature Encounter (Ambient Queued)**
```bash
echo "take candle
light candle
look" | lua src/main.lua --headless --seed=42
# Expected: Candle lights, creature ambient queued, no crash
# Mock driver: on_state_lit + creature ambient recorded
```

**Scenario 1.3: Door Traversal (Crossfade Ready)**
```bash
echo "open door north
north
look" | lua src/main.lua --headless --seed=42
# Expected: Door opens, room changes, no sound errors
# Mock driver: on_traverse (door creak), exit room, enter room
```

**Scenario 1.4: Combat Encounter (Impact Sound Ready)**
```bash
echo "attack rat" | lua src/main.lua --headless --seed=42
# Expected: Combat text, mock driver records impact sound trigger
```

**Scenario 1.5: Full Level 1 Walkthrough (Regression Baseline)**
```bash
{full-command-sequence-through-level-completion}
# Expected: Zero crashes, all text unchanged from non-sound baseline
# Mock driver: All expected sound triggers recorded, no ghost sounds
```

### Phase 2 Scenarios (Object Sounds)

**Scenario 2.1: Container Open**
```bash
echo "take chest
open chest" | lua src/main.lua --headless --seed=42
# Expected: Chest-open.opus trigger recorded
```

**Scenario 2.2: Trap Trigger**
```bash
echo "trigger bear trap" | lua src/main.lua --headless --seed=42
# Expected: Trap-snap.opus trigger recorded
```

**Scenario 2.3: Liquid Pour**
```bash
echo "take wine
pour wine" | lua src/main.lua --headless --seed=42
# Expected: Liquid-pour.opus trigger recorded
```

### Phase 3 Scenarios (Creature Audio)

**Scenario 3.1: Creature State Transition**
```bash
echo "look" | lua src/main.lua --headless --seed=42
# Expected: Creature in initial state, on_state_idle recorded
```

**Scenario 3.2: Injury Vocalization**
```bash
echo "attack wolf" | lua src/main.lua --headless --seed=42
# Expected: Wolf-pain-vocalization recorded on injury
```

**Scenario 3.3: Death Silence**
```bash
{sequence to kill creature}
# Expected: No on_state_dead sound; stop_by_owner() called; subsequent interactions silent
```

### Phase 4 Scenarios (Combat Sounds)

**Scenario 4.1: Weapon Impact**
```bash
echo "attack rat" | lua src/main.lua --headless --seed=42
# Expected: Impact-blunt.opus (or impact-slash based on weapon)
```

**Scenario 4.2: Armor Feedback**
```bash
{sequence with armored opponent}
# Expected: Armor-plate-ricochet.opus on hit
```

**Scenario 4.3: Combat Death**
```bash
{sequence to kill opponent in combat}
# Expected: Death silence; no on_state_dead sound
```

### Phase 5 Scenarios (Time-of-Day)

**Scenario 5.1: Time Transition**
```bash
{advance time from 2 AM to 6 AM}
# Expected: Ambient crossfade trigger (fade out 1.5s, fade in 1.5s)
```

**Scenario 5.2: Full 24-Hour Loop**
```bash
{advance through all time bands}
# Expected: All ambient swaps smooth, no ghost sounds
```

### Phase 6 Scenarios (Weather)

**Scenario 6.1: Weather Change to Rain**
```bash
{weather changes to RAIN}
# Expected: Rain-patter.opus starts, ambient ducks 30%
```

**Scenario 6.2: Thunder During Rain**
```bash
{rain ongoing, thunder triggers}
# Expected: Thunder-distant.opus fires (interrupts), re-establishes ambient after
```

### Phase 7 Scenarios (Music — If Approved)

**Scenario 7.1: Music State Reactive**
```bash
{enter combat, exit combat}
# Expected: Music theme shifts (combat → exploration, if implemented)
```

### Phase 8 Scenarios (Accessibility)

**Scenario 8.1: Deaf Player Full Playthrough (Text-Only)**
```bash
echo "set text-only-mode on
{full-level-1-playthrough}" | lua src/main.lua --headless --seed=42
# Expected: All game text present, no sound calls, full level completable
```

**Scenario 8.2: Screen Reader Navigation**
```bash
{navigate to sound settings, adjust volume, toggle categories}
# Expected: ARIA labels present, no audio interference with TTS
```

---

## TDD Test File Map

| Test File | Coverage | Phase | Status |
|-----------|----------|-------|--------|
| `test/sound/test-sound-manager.lua` | Sound manager API (load, play, stop, room enter/exit) | 1 (MVP) | ✅ Complete |
| `test/sound/test-sound-defaults.lua` | Default verb-to-sound mappings | 1 (MVP) | ✅ Complete |
| `test/sound/mock-driver.lua` | Mock driver call recording | 1 (MVP) | ✅ Complete |
| `test/sound/test-sound-metadata.lua` | Object sound table validation | 1–2 (MVP + Phase 2) | ✅ Complete + WAVE-1 |
| `test/sound/test-room-ambients.lua` | Room ambient declarations | 1–5 (MVP + Phase 5) | ✅ Complete + WAVE-3 |
| `test/sound/test-sound-integration.lua` | FSM → sound, verb → sound, room entry/exit | 1–2 (MVP + Phase 2) | ✅ Complete + WAVE-1 |
| `test/sound/test-object-sounds-phase2.lua` | Container, trap, mechanical object sounds | 2 (Objects) | ⏳ WAVE-1 |
| `test/sound/test-creature-sounds-phase3.lua` | Per-state creature sounds, ambient loops | 3 (Creatures) | ⏳ WAVE-2A |
| `test/sound/test-creature-injury-audio.lua` | Injury vocalizations, death silence | 3–4 (Creatures + Combat) | ⏳ WAVE-2A/2B |
| `test/sound/test-combat-sounds.lua` | Weapon impacts, armor feedback, 3-concurrent budget | 4 (Combat) | ⏳ WAVE-2B |
| `test/sound/test-time-of-day-ambient.lua` | Time band transitions, ambient swaps | 5 (Time-of-Day) | ⏳ WAVE-3 |
| `test/sound/test-weather-sounds.lua` | Weather state changes, rain/wind/thunder mixing | 6 (Weather) | ⏳ WAVE-4 |
| `test/sound/test-accessibility.lua` | Volume controls, toggles, screen reader compatibility | 8 (Accessibility) | ⏳ WAVE-6 |

**Test Execution Command:**
```bash
lua test/run-tests.lua --test-pattern="sound"  # Run all sound tests
```

**Regression Baseline:** 
- **Start (WAVE-0 complete):** 266 tests passing
- **After each wave:** Baseline ≤ current count (no regressions)

---

## Risk Register

| Risk | Phase | Likelihood | Impact | Mitigation |
|------|-------|-----------|--------|-----------|
| Asset sourcing delays (no CC0 found) | 1 | Medium | Phase 1 slip | Pre-source backup library; use CC-BY fallback; consider commissioning bespoke audio |
| Opus codec not supported (very old browser) | 1 | Very Low | Silent fallback | Fengari PCM generation fallback; game unaffected (text-canonical) |
| Browser autoplay policy blocks AudioContext | 1 | Low | First room silent | First keypress unlocks; game requires typing anyway |
| Mobile audio context suspend (app backgrounded) | 1 | Low | Sounds cut off | Context resume on focus; document in release notes |
| Spatial audio API variance (panning) | 4 | Medium | Pan/reverb not portable | Fallback to stereo mixing; Phase 9 deferral acceptable |
| Creature audio overlaps (3+ wolves → cacophony) | 3 | Low | Bad UX | Max 3 concurrent per category; priority system (room > creature > object) |
| Level 2 delay blocks Phases 5–6 | 5–6 | Medium | Time/weather audio blocked | Standalone Phase 5 (static time); Phase 6 defers; escalate at week 1 if unclear |
| Music design decision indefinite (Wayne uncertain) | 7 | Low | Phase 7 blocks | Formal decision gate; if unclear after 1 week, recommend deferral |
| Screen reader interference (audio layer blocks TTS) | 8 | Low | Accessibility fail | pcall() wraps all audio; silent mode; TTS ducking research (Phase 9 future) |
| Performance regression (decode latency) | All | Low | Slow room transitions | Profile decode time; lazy load per room; async decode (already implemented) |
| File size budget exceeded (>500 KB) | 1–6 | Low | Mobile friction | Monitor phase-by-phase; defer Phase 4–6 if approaching limit |

---

## Autonomous Execution Protocol

**Coordinator Role:** Kirk (Project Manager) or delegate. Coordinates waves, gates, team, escalation.

### Wave Execution Loop

```
START WAVE-N
├─ 1. Coordinator announces wave: team assignments, files, TDD requirements
├─ 2. All agents start parallel tracks (no file conflicts)
├─ 3. Nelson runs mid-wave smoke tests (quick 5-command headless scenarios)
├─ 4. Agents commit work daily (test-driven: failing test → fix → commit)
├─ 5. Coordinator monitors progress (no blocking, report daily)
├─ 6. Wave complete: All agents report done
├─ 7. Coordinator runs full test suite + LLM gate scenarios
├─ 8. GATE-N pass? YES → proceed; NO → (see Gate Failure Protocol)
├─ 9. Checkpoint: Update `projects/sound/board.md` with wave status
├─ 10. Commit all wave work: `git add . && git commit -m "..."`
└─ END WAVE-N
```

### Per-Wave Coordination Tasks

| Task | Owner | When | Notes |
|------|-------|------|-------|
| Announce wave assignments | Kirk | Wave start | Tag all agents, link file ownership, post TDD requirements |
| Monitor progress (async) | Kirk | Daily | No blocking; report to Wayne if stuck >4 hours |
| Run smoke tests (mid-wave) | Nelson | Midway | Quick 5-command scenario; green = proceed, red = flag to assignee |
| Run full gate tests | Nelson | Wave end | All 3–5 gate scenarios, deterministic seed |
| Review test coverage | Marge | Wave end | Regression baseline met? Coverage acceptable? |
| Architect review | Bart | Wave end | API contracts frozen? Module size OK? |
| Checkpoint update | Kirk | Wave end | Mark wave complete in board, update status |
| Commit & push | Kirk | Wave end | One commit per wave; include all work |

### Gate Failure Protocol

1. **Gate fails (GATE-N: ❌)**
   - Nelson files GitHub issue: "GATE-N failed: {reason}"
   - Assignee tagged, severity high
   - Issue assigned to responsible agent(s)

2. **Fix cycle (same session)**
   - Agent fixes in same session (TDD: failing test → fix → test pass)
   - Request re-gate
   - Coordinator re-runs gate scenarios + full test suite

3. **Re-gate passes (GATE-N: ✅)**
   - Gate passes; proceed to next wave
   - Update board; checkpoint

4. **Re-gate fails (GATE-N: ❌ again)**
   - **Escalate to Wayne within 30 minutes**
   - Issue: "GATE-N failed 2x: {blocker details}"
   - Wayne decision: (a) more time, (b) defer wave, (c) reduce scope

5. **Flaky Test Protocol (non-deterministic)**
   - Tests marked `@skip-ci` with linked issue
   - Root cause: Bart (architecture) decides: fix immediately or quarantine
   - All LLM scenarios use fixed seed (no randomness)

### Blocker Escalation (L2 Dependency)

**Phases 5–6 are blocked on Level 2 readiness.**

- **1 week before WAVE-3:** Coordinator checks L2 time system status
- **Status unclear?** Escalate to Wayne: "L2 time system status? WAVE-3 depends."
- **L2 not ready?** Options: (a) defer WAVE-3, (b) standalone Phase 5 (static time), (c) continue while L2 work in parallel
- **Decision captured:** `.squad/decisions/inbox/kirk-wave3-l2-status.md`

---

## Wave Checkpoint Protocol

After each gate passes, update `projects/sound/board.md`:

**Checkpoint Template:**
```markdown
### WAVE-N: {Phase Name} ✅ Complete

**Completed By:** {Agent names}, {Date}
**Commit:** {git commit SHA}
**Files Modified:** {count} files
**Tests:** {count} new tests added, {count} total passing
**Scope Changes:** {any deviations from plan}
**Known Deferred:** {any P2 items captured for later}

**Verification:**
- [ ] GATE-N criteria met
- [ ] Regression baseline maintained
- [ ] LLM scenarios pass
- [ ] No outstanding GitHub issues from this wave
```

**Example (Phase 1 complete):**
```markdown
### WAVE-0: Real Audio Assets ✅ Complete

**Completed By:** CBG (sourcing), Gil (compression), Nelson (testing) — 2026-03-31
**Commit:** abc1234 (asset deployment)
**Files Modified:** 8 files (build-sounds.ps1, deploy.ps1, .gitignore, + 5 sound assets)
**Tests:** 5 LLM scenarios added; 266 total tests passing
**Scope Changes:** None
**Known Deferred:** Vorbis fallback (Phase 2 research)

**Verification:**
- [x] GATE-0 criteria met
- [x] Regression baseline: 266 tests (baseline from init)
- [x] LLM scenarios pass (5/5)
- [x] No outstanding issues
```

---

## Documentation Deliverables

| Document | Owner | Phase | Scope | Status |
|-----------|-------|-------|-------|--------|
| `docs/architecture/engine/sound-system.md` | Brockman | 1 (MVP) | Engine architecture, driver interface, hook points | ✅ Complete |
| `docs/design/sound-design-guide.md` | Brockman | 1 (MVP) | Sound philosophy, priority tiers, accessibility | ✅ Complete |
| `docs/design/object-design-patterns.md` (update) | Brockman | 2 (Objects) | Add `sounds` table pattern | ⏳ WAVE-1 |
| `docs/design/creature-design-patterns.md` (new) | Brockman | 3 (Creatures) | Creature per-state sounds, death silence design | ⏳ WAVE-2A |
| `docs/design/combat-audio-guide.md` (new) | Brockman | 4 (Combat) | Combat sound dispatch, weapon impacts, 3-concurrent budget | ⏳ WAVE-2B |
| `docs/architecture/time-of-day-ambient.md` (new) | Brockman | 5 (Time-of-Day) | Time band integration, ambient swaps, crossfade timing | ⏳ WAVE-3 |
| `docs/architecture/weather-audio.md` (new) | Brockman | 6 (Weather) | Weather FSM integration, sound layer mixing | ⏳ WAVE-4 |
| `docs/accessibility/sound-accessibility.md` (new) | Accessibility Lead | 8 (Accessibility) | Deaf/hard-of-hearing access, screen reader compat | ⏳ WAVE-6 |
| `assets/sounds/README.md` | CBG + Gil | 1+ (all) | Attribution log for CC-BY sounds | ⏳ WAVE-0 |
| `projects/sound/board.md` (live updates) | Kirk | All | Wave status, checkpoint summaries | Ongoing |

**Documentation Gate:** No wave ships without corresponding docs. Brockman runs in parallel with implementation teams (different files, no conflicts). Documentation completion is a GATE requirement, not optional.

---

## Lessons & Iteration (Post-Mortem Template)

After all waves complete, add to this section:

```markdown
## Post-Mortem (Captured After WAVE-6)

### Actual vs. Estimated

| Wave | Estimated | Actual | Variance | Notes |
|------|-----------|--------|----------|-------|
| WAVE-0 | 2–3 weeks | — | — | Pending execution |
| WAVE-1 | 3–4 weeks | — | — | Pending execution |
| WAVE-2A | 4–5 weeks | — | — | Pending execution |
| WAVE-2B | 3–4 weeks | — | — | Pending execution |
| WAVE-3 | 2–3 weeks | — | — | Blocked on L2; TBD |
| WAVE-4 | 3–4 weeks | — | — | Blocked on L2; TBD |
| WAVE-5 | 1 week (decision) + 4–6 weeks (if approved) | — | — | Design-pending; TBD |
| WAVE-6 | 2–3 weeks | — | — | Pending execution |

### Gate Failures & Resolutions

| Gate | Failures | Root Cause | Resolution | Time Added |
|------|----------|-----------|-----------|-----------|
| — | — | — | — | — |

### New Risks Discovered

| Risk | Phase | Mitigation Applied |
|------|-------|-------------------|
| — | — | — |

### Candidate Skills Earned

| Skill Topic | Description | Applied To |
|-------------|-------------|-----------|
| — | — | — |

### Team Feedback

| Agent | Feedback | Action Item |
|-------|----------|------------|
| — | — | — |
```

---

## Summary

This formal implementation plan structures **Phases 1–8 (Remaining Sound Work)** into 4 autonomous waves with clear team assignments, dependencies, gates, testing, documentation, and escalation protocols.

**Key Principles:**
1. **Wave-based batching** — Parallel work (4–5 agents per wave), no file conflicts
2. **Binary gates** — Pass/fail checkpoints; re-gate on failure (1x threshold for escalation)
3. **TDD throughout** — Failing test → fix → test pass → commit
4. **LLM walkthroughs** — Deterministic scenarios validate no regressions
5. **Nil-safe patterns** — Sound manager wraps all calls in `pcall()`; nil in headless mode
6. **Documentation as gate requirement** — No wave ships without docs
7. **Autonomous execution** — Coordinator (Kirk) manages waves; escalates to Wayne only on blockers

**Critical Path:**
- **GATE-0 (Phase 1)** is the gating item — real audio assets must ship before Phases 2–4
- **Level 2 dependency** — Phases 5–6 blocked until L2 time + weather systems ready
- **Design decision** — Phase 7 (music) requires Wayne approval before wave start
- **Accessibility parallel** — Phase 8 runs concurrently, non-blocking

**Estimated Total Duration:** 16–24 weeks (WAVE-0 through WAVE-6, accounting for L2 blockers and parallel execution).

---

**Last Updated:** 2026-03-29  
**Next Review:** After GATE-0 complete (Phase 1 assets shipped)  
**Escalation Contact:** Wayne "Effe" Berry (kirk@squad.local)
