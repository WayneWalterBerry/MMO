# Sound System — Unified Implementation Plan

**Version:** 1.1  
**Date:** 2026-03-29  
**Status:** Wave-based execution plan, ready for team implementation  
**Owner:** Wayne "Effe" Berry  
**Architect:** Bart (Architecture Lead)  
**Contributors:** Comic Book Guy (Game Design), Gil (Web Pipeline), Flanders (Content)

---

## Executive Summary

**Context:** The sound system infrastructure is complete (sound manager, Web Audio driver, engine hooks, metadata system, 266 tests passing). The MVP implementation is production-ready. The engine waits for real audio assets and post-MVP expansion.

**What:** Execute Phases 1–8 from the North Star to transform the sound system from synthetic placeholders to production-grade audio immersion. Deliver real audio assets (Phase 1 MVP: 24 files), expand object/creature/combat sounds, implement time-of-day variation, integrate weather, explore music, and ensure accessibility.

**Why:** Sound is optional but irreplaceable — it transforms a text adventure from "reading a story" to "being in a place." A player navigating a 2 AM medieval manor by touch alone hears a rat skitter, a door creak, and a candle ignite. These moments create genuine tension and presence.

**How:** 4 parallel waves structured by audio category and dependencies. Phase 1 assets unlock Phases 2–4. Phases 5–6 block on Level 2 weather engine (deferred). Phase 7 (music) pending design decision. Phase 8 (accessibility) runs in parallel.

**Execution Model:** Autonomous wave-based batching with team assignments, parallel tracks, gates, TDD, LLM walkthroughs, and documentation. Each gate is binary pass/fail. Sound never breaks gameplay — all bridge calls wrapped in `pcall()`, nil-safe patterns throughout.

---

## Wave Status Tracker

```
WAVE-0 (Phase 1): ✅ COMPLETE — Sound infrastructure + drivers shipped
WAVE-1 (Phases 2–3): ⏳ Pending — Real assets unlock content expansion
WAVE-2 (Phases 4–5): ⏳ Pending — Combat + time variation
WAVE-3 (Phases 6–9): ⏳ Pending — Polish, accessibility, advanced features
```

---

## Quick Reference Table

| Phase | Wave | Name | Agents | Tracks | Dependencies | Gate | Deliverables |
|-------|------|------|--------|--------|--------------|------|--------------|
| **1** | **WAVE-0** | ✅ Infrastructure + Drivers | Bart, Gil, Nelson | 3 | None | ✅ GATE-0 | Sound manager (21 API), Web Audio driver, null driver, synthetic fallback |
| **2** | **WAVE-1** | Real Audio Assets (MVP) | CBG, Gil | 2 | None | GATE-1 | 24 `.opus` files sourced, compressed, deployed to `web/dist/sounds/` |
| **3** | **WAVE-2A** | Object-Specific Sounds | Flanders, CBG, Nelson | 3 | Phase 1 assets | GATE-2A | Container, trap, puzzle, liquid sounds declared on 12+ objects; tests pass |
| **4** | **WAVE-2B** | Creature Audio Evolution | Flanders, Nelson | 2 | Phase 1 + Injury hook | GATE-2B | Per-state creature sounds; 5 creatures audio-complete; death silence design verified |
| **5** | **WAVE-3** | Combat Immersion | Combat team, Flanders, Nelson | 3 | Phase 2B + Combat trace | GATE-3 | Weapon impact sounds, armor feedback, injury-specific sounds, death sounds (if applicable) |
| **6** | **WAVE-4** | Time-of-Day Ambient | Moe, Gil, Nelson | 2 | Phase 1 + Level 2 time system | GATE-4 | Ambient variation 2 AM → Day → Evening; crossfades smooth; L2 coupling complete |
| **7** | **WAVE-5** | Music & Score | CBG (decision), Composer (if approved), Nelson | 1 | Design decision | GATE-5 | (Conditional) Music design doc + composer timeline, or formal defer decision |
| **8** | **WAVE-6** | Accessibility & Volume | Smithers, Nelson | 2 | Phases 1–2 complete | GATE-6 | Volume controls UI, sound toggles, haptic layer research, screen reader test pass |

---

## Dependency Graph

```
┌─ WAVE-0 (Infrastructure): ✅ COMPLETE
│   ├─ Bart: src/engine/sound/init.lua + null-driver + defaults
│   ├─ Gil: web bridge, audio-driver.js
│   └─ Nelson: test scaffolding
│        │
│        ▼ GATE-0: ✅ PASSED
│        │
│   ├───────────────────────────────┬──────────────────────────────┐
│   │                               │                              │
│   ▼                               ▼                              ▼
│ WAVE-1: Real Assets         WAVE-2A: Object Sounds    WAVE-2B: Creature Audio
│ (Phase 1 MVP)              (Phase 2, parallel)       (Phase 3, parallel)
│   │                           │                          │
│   ├─ CBG: Source 24 files    ├─ Flanders: 12+ objs    ├─ Flanders: 5 creatures
│   ├─ Gil: Validate/deploy    ├─ CBG: Design review    ├─ Injuries hook ready?
│   └─ Nelson: Regression      └─ Nelson: Tests             NO → BLOCKED
│        │                           │                       │
│        ▼ GATE-1               ▼ GATE-2A                ▼ GATE-2B
│        │                           │                       │
│        └───────────┬───────────────┼───────────────────────┴────────┐
│                    │               │                                 │
│                    ▼               ▼                                 ▼
│              WAVE-3: Combat Audio + Time Variation
│              ├─ Combat team: Hit/miss chains, weapon sounds
│              ├─ Moe: Room ambient variation
│              ├─ Gil: Crossfade timing
│              └─ Nelson: Integration tests
│                   │
│                   ▼ GATE-3 & GATE-4
│                   │
│   ┌───────────────┼───────────────┬───────────────┐
│   │               │               │               │
│   ▼               ▼               ▼               ▼
│ WAVE-4:     WAVE-5:         WAVE-6:
│ Weather     Music           Accessibility
│ (blocked    (pending        (parallel)
│  on L2)     design)
│   │           │               │
│   ▼           ▼               ▼
│ GATE-4      GATE-5          GATE-6
```

---

## WAVE-0: Sound Infrastructure ✅ COMPLETE

### Status

✅ **COMPLETE** — Shipped 2026-03-29

Sound manager (21-method API), Web Audio driver with synthetic fallback, null driver, engine hooks integrated, 266-test suite passing. MVP infrastructure production-ready.

### Deliverables (Shipped)

- ✅ `src/engine/sound/init.lua` — Platform-agnostic sound manager (21 methods)
- ✅ `src/engine/sound/web-driver.lua` — Web Audio API bridge via Fengari
- ✅ `src/engine/sound/null-driver.lua` — Silent fallback (headless, tests)
- ✅ `web/audio-driver.js` — Web Audio implementation (~100 LOC)
- ✅ `web/game-adapter.lua` — Lua sound bridge to JS
- ✅ Engine hooks: FSM, verb, mutation, room, effects pipeline
- ✅ 266-test suite passing

### Gate-0: Infrastructure Ready (✅ PASSED)

Criteria:
- ✅ Sound manager loads without errors
- ✅ No-op mode runs silently during tests
- ✅ Web bridge (6 JS functions) exposed
- ✅ Lua bridge calls JS via pcall without crash
- ✅ Headless mode: ctx.sound_manager is nil (zero overhead)
- ✅ Mock driver tests pass
- ✅ Zero regressions

---

## WAVE-1: Real Audio Assets (Phase 1 MVP)

### Goal

Replace synthetic fallback tones with real audio files. Ship a cohesive first sound experience.

### Scope

**24 OGG Opus files (~230 KB total), sourced, compressed, deployed:**
- 8 creature sounds (rat, cat, wolf, bat, spider vocalizations)
- 5 door/passage sounds (creaks, locks, gates, trapdoors)
- 3 fire/light ignition sounds (match, candle, torch)
- 2 combat impacts (blunt hit, slash hit)
- 6 ambient loops (bedroom, hallway, cellar, storage, deep cellar, crypt, courtyard)

### Agents & Assignments

| Agent | Role | Tasks |
|-------|------|-------|
| **CBG (Game Design)** | Creative Director | Finalize sound asset list, source CC0 + CC-BY sounds, quality review |
| **Gil (Web Engineer)** | Build/Deploy Lead | Validate Opus format, compress @48 kbps, stage in web/dist/sounds/, cache-bust |
| **Nelson (QA)** | Test/Validation | Regression tests (full 266-suite must pass), LLM walkthroughs (5 scenarios) |

### Dependencies

None — can start immediately. Does not depend on object/room metadata being complete.

### Execution

1. **Asset Sourcing (CBG)** — 3–5 days
   - Audit 24 required sounds from design doc
   - Source royalty-free CC0 OR CC-BY files (freesound.org, zapsplat, epidemic sound)
   - OR commission custom recordings if budget approved
   - Store in `assets/sounds/{category}/{name}.wav` (studio quality)
   - Document source attribution in `assets/sounds/README.md`

2. **Compression & Staging (Gil)** — 1–2 days
   - Install ffmpeg (if not present)
   - For each `.wav`: `ffmpeg -i input.wav -c:a libopus -b:a 48k -ac 1 output.opus`
   - Validate each `.opus` file:
     - Is valid Opus format
     - < 100 KB per file (warn if larger)
     - Total size < 500 KB
   - Copy to `web/dist/sounds/{id}.opus` (flat namespace)
   - Generate `web/dist/sounds/manifest.json` (optional, for future preload)
   - Commit + push to main

3. **Validation & Testing (Nelson)** — 1 day
   - Run full test suite: `lua test/run-tests.lua` → **all 266 tests pass**
   - Run LLM headless walkthroughs (5 scenarios):
     ```
     echo "look\nfeel wolf\nlisten\nopen door\nlight candle" | lua src/main.lua --headless
     ```
   - Verify: sound manager loads, no crashes, correct fallback behavior
   - Document any issues in `.squad/decisions/inbox/nelson-sound-wave1-blockers.md`

### Gate-1: MVP Assets Ready

**Criteria (all must pass):**
- ✅ 24 OGG Opus files staged in `web/dist/sounds/`
- ✅ Each file valid Opus format, < 100 KB
- ✅ Total size < 500 KB
- ✅ Source attribution documented in `assets/sounds/README.md`
- ✅ Full 266-test suite passes
- ✅ LLM headless walkthroughs pass (5 scenarios)
- ✅ Zero regressions
- ✅ Manifest.json generated (if using preload strategy)

**If GATE-1 fails:** Retry asset sourcing or compression. If failed after 2 retries, escalate to Wayne.

### Timeline Estimate

**3–5 days total:**
- CBG: 2–3 days (asset sourcing)
- Gil: 1 day (compression + staging)
- Nelson: 1 day (validation + LLM walkthroughs)

---

## WAVE-2A: Object-Specific Sounds (Phase 2)

### Goal

Expand sound vocabulary beyond creatures and doors. Make every interactive object sing.

### Scope

Container interactions, trap activation, puzzle sounds, liquid interactions, environmental reactions.

### Agents & Assignments

| Agent | Role | Tasks |
|-------|------|-------|
| **Flanders (Content Lead)** | Metadata Lead | Add `sounds` tables to 12+ objects (containers, traps, puzzles, liquid) |
| **CBG (Game Design)** | Design Review | Validate sound choices align with design philosophy |
| **Nelson (QA)** | Test Lead | Write metadata validation tests, integration tests |

### Dependencies

✅ GATE-1 (Phase 1 assets) — object-specific sound files ready

### Execution

1. **Metadata Expansion (Flanders)** — 2–3 days
   - Select 12+ objects from `src/meta/objects/`:
     - 4 containers (chest, drawer, crate, barrel)
     - 3 traps (bear trap, falling club, falling rock)
     - 3 puzzles (chain, winch, stone scrape)
     - 2 liquids (wine bottle slosh, rain barrel splash)
   - For each, add `sounds` table:
     ```lua
     sounds = {
         on_state_open = "chest-open.opus",
         on_verb_push = "container-slide.opus",
         ambient_full = "bottles-clink.opus",
     }
     ```
   - Verify `on_listen` descriptions match sound choices
   - Commit + push

2. **Design Review (CBG)** — 1 day
   - Check: Sound choices follow Tier priority system (T1 critical, T2 immersion, T3 polish)
   - Verify: No redundant sounds (e.g., too many "click" sounds in same scene)
   - Approve or request revisions

3. **Test Coverage (Nelson)** — 1–2 days
   - Write metadata validation tests:
     ```lua
     t.test("chest has on_state_open sound", function()
         local obj = load_object("chest")
         t.assert_eq(obj.sounds.on_state_open, "chest-open.opus")
     end)
     ```
   - Write integration tests:
     ```lua
     t.test("opening chest plays sound", function()
         local ok, result = pcall(function()
             -- Simulate verb dispatch
             return verbs.open(context, "chest")
         end)
         t.assert(ok, "verb should not crash")
     end)
     ```
   - Run all tests: `lua test/run-tests.lua` → **all tests pass**

### Gate-2A: Object Sounds Complete

**Criteria (all must pass):**
- ✅ 12+ objects have `sounds` tables
- ✅ Sound keys match design spec (on_state_*, on_verb_*, ambient_*)
- ✅ All referenced sound files exist in Phase 1 assets
- ✅ `on_listen` descriptions updated/verified
- ✅ Metadata validation tests 100% pass
- ✅ Integration tests 100% pass
- ✅ Full 266-test suite passes
- ✅ Zero regressions
- ✅ CBG design review approved

**If GATE-2A fails:** Fix metadata or write missing tests. Retry. Escalate after 1 failure.

### Timeline Estimate

**3–4 days total:**
- Flanders: 2–3 days (metadata expansion)
- CBG: 1 day (design review, parallel)
- Nelson: 1–2 days (tests, parallel)

---

## WAVE-2B: Creature Audio Evolution (Phase 3)

### Goal

Deepen creature audio identity — per-state sounds, behavioral variation, pack dynamics.

### Scope

Per-state creature sounds (idle, hunting, fleeing, injured, dead). Creature interactions, creature death silence design (intentional absence).

### Agents & Assignments

| Agent | Role | Tasks |
|-------|------|-------|
| **Flanders (Content Lead)** | Creature Metadata | Add per-state sounds to 5 creatures (rat, cat, wolf, bat, spider) |
| **Combat Team** | Injuries Hook | Ensure injury system emits `on_injured` events for sound integration |
| **Nelson (QA)** | Test Lead | Integration tests, state transition verification |

### Dependencies

✅ GATE-1 (Phase 1 creature audio files)
✅ Injury system `on_injured` event hook (may need Bart to add if not present)

### Execution

1. **Creature Metadata (Flanders)** — 2–3 days
   - Open each creature in `src/meta/creatures/`:
     - rat.lua, cat.lua, wolf.lua, bat.lua, spider.lua
   - Add per-state `sounds` table:
     ```lua
     sounds = {
         on_state_idle = "rat-idle.opus",
         on_state_hunting = "rat-skitter.opus",
         on_state_fleeing = "rat-squeak-panic.opus",
         on_state_dead = nil,  -- intentional silence
     }
     ```
   - Key design: Dead creatures emit NO sound. Text says "Nothing." and sound confirms by silence.
   - Commit + push

2. **Injury Hook (Combat Team)** — 1 day
   - Verify `on_injured` event fires when creature takes damage
   - Event should include: creature GUID, damage type, injury severity
   - Sound system subscribes: `on_injured` → trigger creature vocalization sound
   - Example: Wolf injured (gash) → play `wolf-pain-growl.opus`

3. **Test Coverage (Nelson)** — 1–2 days
   - Write FSM state transition tests:
     ```lua
     t.test("rat transitions idle -> hunting triggers sound", function()
         local rat = load_creature("rat")
         local old_state = rat._state
         rat:transition_to("hunting")
         t.assert_eq(rat._state, "hunting")
         -- Verify sound was queued (mock sound manager)
     end)
     ```
   - Write death silence test:
     ```lua
     t.test("dead wolf produces no sound", function()
         local wolf = load_creature("wolf")
         wolf:transition_to("dead")
         -- Verify NO sound emitted (sound manager call NOT made)
     end)
     ```
   - Run all tests: `lua test/run-tests.lua` → **all tests pass**

### Gate-2B: Creature Sounds Complete

**Criteria (all must pass):**
- ✅ 5 creatures have per-state `sounds` tables
- ✅ Dead state produces NO sound (silence is intentional)
- ✅ All referenced sound files exist in Phase 1 assets
- ✅ `on_listen` descriptions match sound design
- ✅ Injury system `on_injured` hook verified
- ✅ FSM transition tests 100% pass
- ✅ Death silence tests 100% pass
- ✅ Full 266-test suite passes
- ✅ Zero regressions

**If GATE-2B fails:** Retry metadata or injury hook. Escalate after 1 failure.

### Timeline Estimate

**3–4 days total:**
- Flanders: 2–3 days (creature metadata)
- Combat team: 1 day (injury hook, parallel)
- Nelson: 1–2 days (tests, parallel)

---

## WAVE-3: Combat Audio Immersion (Phase 4)

### Goal

Make combat visceral through sound. Hit feedback, death sounds, weapon impacts, armor clangs.

### Scope

Weapon impact sounds (blunt, slash, pierce, range), armor feedback (leather, plate, ricochet), injury-specific sounds (gash, bleed, poison), combat miss sounds (swing-and-miss, dodge).

### Agents & Assignments

| Agent | Role | Tasks |
|-------|------|-------|
| **Combat Team Lead** | Combat Audio Lead | Trace combat event sequence, map sounds to each hit type |
| **Flanders (Content)** | Creature Audio | Add injury vocalization sounds to creatures |
| **Nelson (QA)** | Test Lead | Combat event trace tests, integration tests |

### Dependencies

✅ GATE-2A (object sounds, container interactions)
✅ GATE-2B (creature audio, injury vocalizations)
✅ Combat trace: Formal documentation of hit/miss/block chains

### Execution

1. **Combat Event Trace (Combat Team)** — 1–2 days
   - Document complete combat sequence:
     - Player attack: weapon type → hit chance roll → hit/miss result → damage calculation
     - Creature reaction: hit sound → damage type → injury sound → FSM state change
     - Miss: swing-and-miss sound → no creature reaction
     - Block: armor clang sound → reduced damage
   - Create decision matrix: weapon × damage type × injury severity → sound selection
   - Example: Wolf bite (claw) + gash (severe) → `wolf-pain-growl-loud.opus`

2. **Weapon Impact Sounds (Combat Team)** — 1 day
   - 4 weapon types × sound each:
     - Blunt (club): `hit-blunt.opus`
     - Slash (dagger): `hit-slash.opus`
     - Pierce (spear): `hit-pierce.opus`
     - Range (arrow): `hit-range.opus`
   - Armor feedback:
     - Hit on leather: soft thud
     - Hit on plate: metallic clang
     - Ricochet (block): sharp ring

3. **Injury Sounds (Flanders)** — 1 day
   - Map injury types to creature vocalizations:
     - Gash: `wolf-pain-growl.opus`, `rat-squeak-pain.opus`
     - Bleed: (creature continues, no unique sound, text describes bleeding)
     - Poison: `poison-hiss.opus` (creature-agnostic)
     - Numbness: (silence, movement impaired)
   - Add sounds to creature metadata:
     ```lua
     sounds = {
         on_injured_gash = "wolf-pain-growl.opus",
         on_injured_poison = "poison-hiss.opus",
     }
     ```

4. **Test Coverage (Nelson)** — 1–2 days
   - Combat event trace test:
     ```lua
     t.test("wolf attack -> hit -> gash injury -> wolf pain sound", function()
         local context = setup_combat_scenario()
         local wolf = get_creature("wolf")
         local hit_result = simulate_combat_attack(player_attack, wolf)
         t.assert_eq(hit_result.damage_type, "gash")
         t.assert_eq(hit_result.sound, "wolf-pain-growl.opus")
     end)
     ```
   - Miss sound test:
     ```lua
     t.test("swing-and-miss plays swing sound, no creature reaction", function()
         local miss_result = simulate_combat_attack(player_attack, wolf_dodges)
         t.assert_eq(miss_result.sound, "swing-and-miss.opus")
         -- Verify wolf does NOT emit injury sound
     end)
     ```
   - Run all tests: `lua test/run-tests.lua` → **all tests pass**

### Gate-3: Combat Sounds Complete

**Criteria (all must pass):**
- ✅ Combat event trace documented
- ✅ 4 weapon impact sounds sourced + deployed
- ✅ Armor feedback sounds (leather, plate, ricochet) deployed
- ✅ 4+ injury-specific creature sounds deployed
- ✅ Miss sounds (swing, dodge, block) deployed
- ✅ Combat event trace tests 100% pass
- ✅ Miss sound tests 100% pass
- ✅ Full 266-test suite passes
- ✅ Zero regressions

**If GATE-3 fails:** Retry event trace or sound mapping. Escalate after 1 failure.

### Timeline Estimate

**3–4 days total:**
- Combat team: 2–3 days (event trace, weapon sounds)
- Flanders: 1 day (creature injury sounds, parallel)
- Nelson: 1–2 days (tests, parallel)

---

## WAVE-4: Time-of-Day Ambient Variation (Phase 5)

### Goal

The world evolves sonically throughout the day. Day vs. night. Courtyard outdoors change.

### Agents & Assignments

| Agent | Role | Tasks |
|-------|------|-------|
| **Moe (Room Design)** | Ambient Design | Room-specific time variation descriptions |
| **Gil (Web Engineer)** | Audio Mixing | Crossfade implementation, smooth transitions |
| **Nelson (QA)** | Test Lead | Time progression tests, crossfade verification |

### Dependencies

✅ GATE-1 (Phase 1 ambient loops)
✅ Level 2 time system (if coupled)

**Note:** This wave is BLOCKED until Level 2 time system is ready. Can proceed in parallel as Phase 5 design-only if L2 is delayed.

### Execution

*(Placeholder — full details pending Level 2 specification)*

1. **Ambient Variation Design (Moe)** — 1–2 days
   - Define per-room ambient variation:
     - Night-time (2 AM – 6 AM): deeper reverb, longer drips, owls in courtyard
     - Daytime (6 AM – 6 PM): warmer tone, distant activity (carts, birds), wind shifts
     - Evening (6 PM – 9 PM): wind peaks, owl activity peaks

2. **Crossfade Implementation (Gil)** — 1–2 days
   - Smooth 5–10 second transitions when time thresholds cross
   - Implement dual-layer mixing: fade out old ambient, fade in new ambient
   - Test on mobile (low bandwidth scenarios)

3. **Integration Tests (Nelson)** — 1 day
   - Time progression test:
     ```lua
     t.test("courtyard ambient transitions 2am -> 6am (bird sounds appear)", function()
         set_game_time(2 * 60 * 60)  -- 2 AM
         local ambient_2am = get_active_ambient("courtyard")
         set_game_time(6 * 60 * 60)  -- 6 AM
         local ambient_6am = get_active_ambient("courtyard")
         t.assert_ne(ambient_2am, ambient_6am, "ambient should change")
     end)
     ```

### Gate-4: Time Variation Complete

**Criteria (all must pass):**
- ✅ Room ambient variation design documented
- ✅ Night/day/evening ambient files sourced + deployed
- ✅ Crossfade implementation tested on mobile
- ✅ Time progression tests 100% pass
- ✅ Full 266-test suite passes
- ✅ Zero regressions

### Timeline Estimate

**2–3 days total (deferred to Level 2 cycle)**

---

## WAVE-5: Music & Score (Phase 7 — DESIGN-PENDING)

### Goal

Establish whether MMO wants diegetic vs. non-diegetic music.

### Open Questions for Wayne

1. Should the game have a non-diegetic score (background orchestration)?
2. Should music respond to game state (danger theme, exploration theme)?
3. Should music be optional (toggle, like other audio)?
4. If yes: Composer/music production timeline and budget?

### Conditional Execution

**If Wayne approves music:**

1. **Music Design (CBG)** — 2–3 days
   - Define musical themes per game state
   - Diegetic music (in-world instruments): bell tower chimes, lute, orchestra
   - Non-diegetic underscore: ambient musical themes for rooms, moods, danger

2. **Composer Assignment** — TBD
   - Commission composer or use stock music library
   - Produce 3–5 musical themes (each 30–60 seconds)
   - Deliver in OGG Vorbis format (@128 kbps)

3. **Integration (Music team)** — 2–3 days
   - Wire music state machine to game state
   - Implement theme transitions with crossfades
   - Write integration tests

**If Wayne defers music:** Mark decision in `.squad/decisions.md` and close WAVE-5.

### Gate-5: Music Decision Made

**Criteria:**
- ✅ Wayne decision documented in `.squad/decisions/inbox/wayne-music-decision.md`
- ✅ If APPROVED: Music design doc + composer timeline provided
- ✅ If DEFERRED: Formal decision note with rationale

### Timeline Estimate

**4–6 weeks (if approved); 0 weeks (if deferred)**

---

## WAVE-6: Accessibility & Volume Controls (Phase 8)

### Goal

Ensure deaf and hard-of-hearing players lose nothing. Enhance audio descriptions, provide volume controls.

### Agents & Assignments

| Agent | Role | Tasks |
|-------|------|-------|
| **Smithers (Parser/UI)** | UI Lead | Volume slider UI, sound toggle UI, text-only mode |
| **Nelson (QA)** | Test Lead | Screen reader compatibility, accessibility audit |
| **TBD (Accessibility Specialist)** | A11y Lead | Haptic feedback research, enhanced `on_listen` guidelines |

### Dependencies

✅ GATE-1 (Phase 1 assets)
✅ GATE-2A (object sounds)
(Parallel work — does not block other phases)

### Execution

1. **Volume UI (Smithers)** — 1–2 days
   - Add to terminal header:
     - Master volume slider (0–100%)
     - Sound effects toggle (ON/OFF)
     - Ambient toggle (ON/OFF)
     - Creature sound toggle (ON/OFF)
     - Text-only mode toggle (ON/OFF)
   - Persist to `localStorage` so it survives page reload
   - Implement mute button (speaker icon with X)

2. **Enhanced `on_listen` Descriptions** — 1–2 days
   - Audit all object `on_listen` fields
   - Ensure descriptions are detailed enough for deaf players:
     ```lua
     on_listen = "A distant splash, then faint dripping water."
     -- (This will be accompanied by splash sound for hearing players)
     ```
   - Update `docs/design/object-design-patterns.md` with guidelines

3. **Screen Reader Testing (Nelson)** — 1 day
   - Test with NVDA (Windows), JAWS (Windows), VoiceOver (macOS)
   - Verify: Volume slider is announced, toggle states are clear
   - Verify: Sound layer doesn't interfere with screen reader output
   - Document any issues in accessibility audit

4. **Haptic Feedback Research** — 1 day
   - Research Vibration API (browser support, limitations)
   - Proposal: Haptic pulses for creature proximity, trap triggers, damage
   - Document as Phase 9+ feature (not MVP)

### Gate-6: Accessibility Complete

**Criteria (all must pass):**
- ✅ Volume UI implemented + functional
- ✅ Sound toggles persist to localStorage
- ✅ All `on_listen` descriptions enhanced (audit checklist signed off)
- ✅ Screen reader tests pass (NVDA, JAWS, VoiceOver)
- ✅ Text-only mode working (all audio suppressed)
- ✅ Haptic feedback research documented (proposal for Phase 9)
- ✅ Full 266-test suite passes
- ✅ Zero regressions

**If GATE-6 fails:** Fix UI or retry accessibility audit. Escalate after 1 failure.

### Timeline Estimate

**2–3 days total (parallel work)**

---

## Implementation Estimate (All Waves)

| Wave | Estimated Hours | Critical Path |
|------|-----------------|----------------|
| WAVE-0 | 8–10 (✅ COMPLETE) | Bart: 3, Gil: 5, Nelson: 2 |
| WAVE-1 | 6–8 | CBG: 3 (sourcing), Gil: 1, Nelson: 1 |
| WAVE-2A | 4–6 | Flanders: 3, CBG: 1, Nelson: 1 |
| WAVE-2B | 4–6 | Flanders: 2, Combat: 1, Nelson: 1 |
| WAVE-3 | 5–7 | Combat: 3, Flanders: 1, Nelson: 1 |
| WAVE-4 | 3–5 | Moe: 2, Gil: 2, Nelson: 1 (deferred to L2) |
| WAVE-5 | 0 (pending) | CBG: 2, Composer: TBD (if approved) |
| WAVE-6 | 4–5 | Smithers: 2, Nelson: 1, A11y: 1 |
| **Total** | **34–52 hours** | Parallel: 8–12 weeks with 4–5 agents |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|-----------|
| Asset sourcing delays (CBG) | Medium | Phase 1 slip 1–2w | Pre-source backup library, use royalty-free options, commission early |
| Browser autoplay policy | Low | Web audio fails to load | First keypress unlocks; document in release notes |
| Mobile audio context suspend | Low | Sounds cut off on lock | Test on mobile; implement context resume on focus |
| Spatial audio API variance | Medium | Pan/reverb not portable | Fallback to stereo mixing if panning unavailable |
| Audio memory pressure (50+ files) | Very Low | OOM on old devices | Phase 9 LRU cache; start aggressive at 1 MB decoded |
| Creature audio overlaps | Low | Wolf pack → cacophony | Max 3 concurrent creatures; priority system |
| Level 2 delay | Medium | Phases 5–6 blocked | Design Phase 5 as standalone; defer L2 coupling |

---

## Escalation Protocol

### When to Escalate

- **GATE failure after 1 retry:** Escalate to Wayne with root cause analysis
- **Asset sourcing blocked >1 week:** Escalate to Wayne with decision options (royalty-free, commission, defer)
- **Injury system hook not ready:** Escalate to Bart with timeline request
- **Level 2 delay >3 weeks:** Discuss Phase 5–6 deferral with Wayne

### Escalation Format

Write to `.squad/decisions/inbox/{agent}-{brief-slug}.md`:

```markdown
# Sound Wave-N Blocker: {Title}

**Date:** YYYY-MM-DD  
**Owner:** {Agent}  
**Blocker:** {Description}  
**Impact:** WAVE-N delayed {X days}  
**Options:**
1. {Option A}
2. {Option B}  
**Recommendation:** {Your call}  
**Next Steps:** {Waiting for Wayne decision}
```

---

## Success Criteria (All Waves)

| Criterion | Target | Measurement |
|-----------|--------|-----------|
| **Audio file adoption** | 24/24 MVP assets deployed | Commit references in board |
| **Creature audio immersion** | Players report tension | LLM walkthrough feedback |
| **Accessibility parity** | Deaf players lose 0% info | Accessibility audit checklist |
| **Audio performance** | <50 ms latency, <2 MB RAM | Profiler logs |
| **Cross-platform parity** | Web/terminal sound parity | Platform support matrix |
| **Zero audio regressions** | 266+ tests pass | CI/CD gate |
| **File size budget** | <500 KB total (compressed) | Asset size audit |

---

## Phase Roadmap & Timeline

```
NOW (2026-03-29):
├─ WAVE-0: ✅ COMPLETE

NEXT (2026-04-01 → 2026-04-12):
├─ WAVE-1: Real Audio Assets (P0)
│   ├─ CBG: Asset sourcing (2–3d)
│   ├─ Gil: Compression + deploy (1d)
│   └─ Nelson: Validation + LLM (1d)
├─ WAVE-2A: Object Sounds (P1, parallel)
│   ├─ Flanders: Metadata (2–3d)
│   ├─ CBG: Design review (1d, parallel)
│   └─ Nelson: Tests (1–2d, parallel)
├─ WAVE-2B: Creature Audio (P1, parallel)
│   ├─ Flanders: Creature metadata (2–3d)
│   ├─ Combat: Injury hook (1d, parallel)
│   └─ Nelson: Tests (1–2d, parallel)

AFTER GATE-1 (2026-04-12 → 2026-04-26):
├─ WAVE-3: Combat Audio (P2, parallel)
│   ├─ Combat: Event trace + sounds (2–3d)
│   ├─ Flanders: Creature vocalizations (1d, parallel)
│   └─ Nelson: Tests (1–2d, parallel)
├─ WAVE-4: Time-of-Day Variation (P3, BLOCKED on L2)
├─ WAVE-5: Music (P4, pending Wayne decision)
├─ WAVE-6: Accessibility (P2, parallel)
│   ├─ Smithers: Volume UI (1–2d)
│   ├─ Nelson: A11y audit (1d, parallel)
│   └─ A11y team: Haptic research (1d, parallel)

TOTAL: 8–12 weeks (with WAVE-4 blocked on Level 2)
```

---

## Next Steps

1. **Wayne:** Review this plan, approve wave sequence, confirm team assignments
2. **CBG:** Begin Phase 1 asset sourcing immediately (can start before other waves)
3. **Bart & Gil:** On standby for GATE-1 deployment (post-asset sourcing)
4. **All agents:** Reserve calendar time for wave execution (staggered, parallel tracks)
5. **Kirk (PM):** Track wave progress, escalate blockers, ensure gates are met

---

**Last Updated:** 2026-03-29  
**Plan Owner:** Kirk (Project Manager)  
**Execution Lead:** Bart (Architecture Lead)  
**Next Review:** When WAVE-1 assets are 50% sourced (2026-04-06)  
**Escalation Point:** If any GATE blocked >3 days, escalate to Wayne
