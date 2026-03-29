# Sound System — North Star Vision

**Version:** 1.0  
**Date:** 2026-03-29  
**Owner:** Kirk (Project Manager), Bart (Architecture Lead)  
**Status:** Strategic roadmap for post-V1.1 sound evolution

---

## Vision Statement

The MMO sound system transforms a text adventure from "reading a story" to "being in a place." Starting from a dark medieval manor at 2 AM, sound becomes the primary sense alongside touch — the player navigates by feel and hearing before ever reaching light.

**Core Promise:** Sound is optional but irreplaceable — it adds emotional depth to every interaction without replacing the text. The game is fully playable on mute; with sound, it becomes immersive.

---

## Current State (WAVE-4/5 Complete)

✅ **Shipped:** Sound manager (21-method API), null driver, Web Audio driver with synthetic fallback tones, room ambient declarations (all 7 rooms), 20+ object sound metadata declarations, 141 metadata validation tests, full engine hook integration (FSM, verbs, mutations, room transitions, effects pipeline).

✅ **What Works:**
- Platform-agnostic Lua sound manager (zero external dependencies)
- Web Audio API bridge with synthetic tone fallback (no server audio files yet)
- Ambient room loops queued on entry (all 7 rooms declared)
- Object/creature sound metadata (ready for asset integration)
- Engine integration complete (sound fires on FSM transitions, verb dispatch, room transitions, mutations)
- 266-test suite passing (includes sound validation)

⏳ **MVP Gaps (Phase 1 → now complete implementation, awaiting assets):**
- Real audio assets (24 MVP sounds in OGG Opus) — implementation ready, awaiting audio sourcing
- Per-object sound effects (doors, light sources, traps, containers) — metadata declared, awaiting audio assets
- Creature vocalizations (wolf growl, rat skitter, bat screech) — metadata declared, awaiting audio assets
- Combat sounds (hit, miss, block, death) — infrastructure ready, awaiting audio design

---

## North Star Phases (Prioritized by Impact)

### Phase 1: Real Audio Assets + MVP Sound Completion
**Goal:** Replace synthetic fallback tones with real audio files. Ship a cohesive first sound experience.

**What:** 24 OGG Opus files (~230 KB total), sourced, compressed, deployed.

**Deliverables:**
- ✅ Asset catalog (sound design guide + design notes complete)
- ⏳ Audio files sourced or created (23/24 files — awaiting final asset pipeline decision)
- ⏳ Deployed to `web/sounds/` with cache-busting
- ⏳ LLM walkthrough validation (5 headless scenarios)

**Owner:** CBG (Creative Direction), Gil (Web Build)  
**Dependencies:** Asset sourcing decision, web build pipeline (`build-sounds.ps1`)  
**Priority:** **P0** — This is the minimum viable audio experience. Without this, the sound system is an empty skeleton.

**Timeline Estimate:** 2–3 weeks (asset sourcing + QA)

---

### Phase 2: Object-Specific Sounds (Beyond MVP)
**Goal:** Expand sound vocabulary beyond creatures and doors. Make every interactive object sing.

**What:** Sound metadata expansion — container interactions, traps, puzzles, environmental reactions.

**Deliverables:**
- Container interactions: chest open/close, drawer slide, crate creaks
- Trap activation: bear trap snap, falling club thud, rock collapse, ceiling crush
- Environmental puzzles: chain grinding, winch creaking, stone scraping
- Liquid interactions: pouring, sloshing, splashing
- Textile sounds: cloth rustling, curtain swishing (nice-to-have from T3 audit)

**Owner:** Flanders (Object Content), CBG (Sound Design)  
**Dependencies:** Phase 1 assets + audio production pipeline established  
**Priority:** **P1** — High immersion value but not critical for playability  
**Timeline Estimate:** 3–4 weeks (audio production, object metadata updates)

---

### Phase 3: Creature Sound Evolution
**Goal:** Deepen creature audio identity — per-state sounds, behavioral variation, pack dynamics.

**What:** Expand from single-state vocalizations to nuanced creature soundscapes.

**Deliverables:**
- Per-state creature sounds (idle, hunting, fleeing, injured, dead)
- Creature interactions: wolf pack coordination, rat swarm, bat colony communication
- Creature death silence design (intentional absence, not a sound)
- Spatial audio: creature sounds come from different directions (future: Web Audio panning)
- Creature stress state audio: injury vocalizations, pain sounds (tightly coupled to injury system)

**Owner:** Flanders (Creatures), Combat team (Injuries)  
**Dependencies:** Injury system audio hook, Phase 1 assets  
**Priority:** **P1** — Creatures are the primary antagonist; sound is emotional payoff  
**Timeline Estimate:** 4–5 weeks (creature behavior expansion, audio production)

---

### Phase 4: Combat Audio Immersion
**Goal:** Make combat visceral through sound. Hit feedback, death sounds, weapon impacts, armor clangs.

**What:** Sound integration with the combat system (hit/miss/block chains, injury types, weapon classes).

**Deliverables:**
- Weapon impact sounds: blunt impact, slashing swipe, piercing thrust, range impact
- Armor feedback: hit on leather, hit on plate, ricochet (on blocked attack)
- Injury-specific sounds: gash, bleed, poison hiss, poison cough, numbness silence
- Combat miss sounds: swing-and-miss, dodge/roll
- Death sounds (optional, per creature design — many creatures die in silence)
- Creature pain responses: whimper, growl, screech (coupled to injury severity)

**Owner:** Combat team (damage pipeline), Flanders (Creature audio)  
**Dependencies:** Injuries system audio hook (D-SOUND-MUTATION-CTX complete), combat event trace  
**Priority:** **P2** — High impact but deferred until Phase 1 solid  
**Timeline Estimate:** 3–4 weeks (combat trace analysis, audio production)

---

### Phase 5: Ambient Time-of-Day Variation
**Goal:** The world evolves sonically throughout the day. Day vs. night. Courtyard outdoors change.

**What:** Time-aware ambient sound swaps and layering (tied to Level 2 time progression).

**Deliverables:**
- Night-time ambient variation (2 AM – 6 AM): deeper reverb, longer drips, owls in courtyard
- Day-time ambient variation (6 AM – 6 PM): warmer tone, distant activity (carts, birds), wind shifts
- Evening transition (6 PM – 9 PM): wind picks up, owl activity peaks in courtyard
- Seasonal/weather layers (Level 2): rain effects (water amplifies), wind changes (howling in courtyard)
- Crossfade timing: smooth 5–10 second transitions when time thresholds cross

**Owner:** Gil (Ambient loop library), Moe (Room ambient design), Level 2 team  
**Dependencies:** Level 2 weather engine, time progression system  
**Priority:** **P3** — Post-Level 1. Blocked on Level 2 design  
**Timeline Estimate:** 2–3 weeks (implementation), deferred to L2 cycle

---

### Phase 6: Weather & Environmental Audio (Level 2+)
**Goal:** Weather becomes sonically mechanical — rain extinguishes fire, wind carries distant sounds, fog muffles audio.

**What:** Dynamic sound layers driven by Level 2 weather system.

**Deliverables:**
- Rain soundscape: patter on stone, gutters dripping, puddles splashing
- Wind effects: howling through passages, rattling loose objects, direction-aware panning
- Thunder: distant rumbles, close cracks (ties to player damage?)
- Lightning flash (visual, but sound effect for dramatic timing)
- Fog audio: muffled distant sounds, echo reduction
- Fog/mist interactions: vapor hiss, moisture drips

**Owner:** Level 2 team (weather engine), Gil (Audio mixing)  
**Dependencies:** Level 2 weather system (mechanical integration)  
**Priority:** **P3** — Post-Level 1, blocked on L2  
**Timeline Estimate:** 3–4 weeks (audio production, integration)

---

### Phase 7: Music & Score (Optional — Design Decision Pending)
**Goal:** Establish whether MMO wants diegetic vs. non-diegetic music.

**Questions for Wayne:**
- Should the game have a non-diegetic score (background orchestration)?
- Should music respond to game state (danger theme, exploration theme)?
- Should music be optional (toggle, like other audio)?
- If yes: Composer/music production timeline and budget?

**If Approved — Deliverables:**
- Diegetic music: in-world instruments (bell tower chimes, lute, orchestra)
- Non-diegetic underscore: ambient musical themes for rooms, moods, danger
- State-reactive composition: theme shifts on combat, injury, discovery
- Musical leitmotifs: creatures, NPCs (if added), locations

**Owner:** CBG (Creative), TBD (Composer)  
**Dependencies:** Wayne design decision  
**Priority:** **DESIGN-PENDING** — Not approved yet  
**Timeline Estimate:** 4–6 weeks (if approved; composition is time-intensive)

---

### Phase 8: Accessibility & Accessibility Modes
**Goal:** Ensure deaf and hard-of-hearing players lose nothing. Enhance audio descriptions for deaf players who use visual/haptic feedback.

**What:** Robust accessibility layer without making sound mandatory.

**Deliverables:**
- Haptic feedback layer: pulse patterns for creature proximity, trap triggers, damage
- Enhanced `on_listen` text for deaf players: detailed auditory descriptions written as text
- Sound toggle UI: explicit sound mute + per-category toggles (effects, ambients, creatures, music)
- Audio descriptions: for all sound effects (hover tooltip: "wolf growl (aggressive)")
- Screen reader testing: ensure audio layer doesn't interfere with accessibility APIs
- High-contrast sound visualization (optional): on-screen glyph feedback for sound events

**Owner:** Accessibility team (TBD), Smithers (UI)  
**Dependencies:** Haptic API research (future), accessibility audit  
**Priority:** **P2** — Accessibility is principle, not afterthought  
**Timeline Estimate:** 2–3 weeks (implementation + testing)

---

### Phase 9: Advanced Audio Features (Post-MVP)
**Goal:** Mature audio engine with spatial awareness, dynamic mixing, and player agency.

**What:** Sophisticated audio features that make the game world feel alive.

**Deliverables:**
- Spatial audio: Web Audio panning (creature sounds from direction, reverb field)
- Volume ducking: ambient lowers when SFX plays, SFX lowers when music plays
- Per-category volume controls: adjust effects, ambients, creatures, music independently
- LRU buffer cache: manage decoded audio if library grows >50 files
- Audio visualization: waveform display, equalizer UI (optional)
- Dynamic creature orchestration: wolf pack harmonic calls (multiple instances)

**Owner:** Gil (Web Audio), Nelson (Testing)  
**Dependencies:** Phase 1–3 complete, advanced Web Audio API use  
**Priority:** **P3** — Post-MVP polish  
**Timeline Estimate:** 3–4 weeks (implementation, testing)

---

## Dependency Map

```
┌─ Phase 1: Real Assets (P0)
│    ├─ Sourcing/Creation
│    ├─ Deployment (build-sounds.ps1)
│    └─ LLM Validation
│
├─ Phase 2: Object-Specific Sounds (P1)
│    ├─ Depends: Phase 1 assets
│    └─ Triggers: Flanders content expansion
│
├─ Phase 3: Creature Audio (P1)
│    ├─ Depends: Phase 1 assets + Injuries system
│    └─ Triggers: Combat team, creature behavior
│
├─ Phase 4: Combat Audio (P2)
│    ├─ Depends: Phase 1 + Phase 3 + Injuries hook
│    └─ Triggers: Combat event trace
│
├─ Phase 5: Time-of-Day Variation (P3)
│    ├─ Depends: Phase 1 assets + Level 2 time system
│    └─ Blocks: Level 2 progression
│
├─ Phase 6: Weather Audio (P3)
│    ├─ Depends: Level 2 weather engine
│    └─ Blocks: Level 2 progression
│
├─ Phase 7: Music/Score (DESIGN-PENDING)
│    ├─ Depends: Wayne design decision
│    └─ Triggers: Composer (if approved)
│
├─ Phase 8: Accessibility (P2, parallel)
│    ├─ Depends: Phases 1–2 (non-blocking)
│    └─ Enhances: All phases
│
└─ Phase 9: Advanced Features (P3, post-MVP)
     ├─ Depends: Phases 1–3 stable
     └─ Triggers: Audio polish cycle
```

---

## Priority Matrix (What Matters Most for Immersion?)

| Phase | Impact | Effort | Owner | Current Gate |
|-------|--------|--------|-------|--------------|
| **1: Real Assets** | 🟥🟥🟥 Critical | 2–3w | CBG, Gil | ⏳ Asset sourcing |
| **2: Object Sounds** | 🟩🟩 High | 3–4w | Flanders, CBG | ⏳ P1 assets ready |
| **3: Creature Audio** | 🟩🟩🟩 Very High | 4–5w | Flanders, Combat | ⏳ P1 assets ready |
| **4: Combat Audio** | 🟩🟩 High | 3–4w | Combat, Flanders | ⏳ P3 assets ready |
| **5: Time Variation** | 🟨 Medium | 2–3w | Gil, Moe, L2 | 🚫 Blocked on L2 |
| **6: Weather Audio** | 🟨 Medium | 3–4w | L2, Gil | 🚫 Blocked on L2 |
| **7: Music** | 🟩🟩 High | 4–6w | CBG, Composer | ❓ Design pending |
| **8: Accessibility** | 🟩 Important | 2–3w | A11y, Smithers | ⏳ Phase 1–2 ready |
| **9: Advanced Features** | 🟨 Nice-to-Have | 3–4w | Gil, Nelson | ⏳ Post-MVP |

**Top 3 Priorities (Next 8 Weeks):**
1. **Phase 1: Real Assets** — Get authentic audio files shipped. This unlocks everything else.
2. **Phase 3: Creature Audio** — Creatures are the emotional core. Rich creature sounds = immersive threat.
3. **Phase 8: Accessibility** — Parallel work; don't block. Ensures no player left behind.

---

## Success Metrics (How Do We Know We're Winning?)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Audio file adoption** | 24/24 MVP assets deployed | Commit references in board |
| **Creature audio immersion** | Players report tension from audio | LLM walkthrough feedback, player testing notes |
| **Accessibility parity** | Deaf players access 100% of info | Accessibility audit checklist |
| **Audio performance** | <50 ms latency, <2 MB RAM | Profiler logs, memory sampling |
| **Cross-platform consistency** | Web/terminal sound parity (best-effort) | Platform support matrix |
| **Zero audio regressions** | Full test suite passes (266+) | CI/CD gate |
| **File size budget** | <500 KB total (compressed) | Asset size audit |

---

## Key Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|-----------|
| Asset sourcing delays | Medium | Phase 1 slip | Pre-source backup library, royalty-free options, or commission composer early |
| Browser autoplay policy | Low | Web audio fails to load | First keypress unlocks; document in release notes |
| Mobile audio context suspend | Low | Sounds cut off on lock | Test on mobile; implement context resume on focus |
| Spatial audio API variance | Medium | Pan/reverb not portable | Fallback to stereo mixing if panning unavailable |
| Audio memory pressure (50+) | Very Low | OOM on old devices | Phase 2 LRU cache; start aggressive at 1 MB decoded |
| Creature audio overlaps | Low | Wolf pack → cacophony | Max 3 concurrent creatures; priority system |
| Level 2 delay | Medium | Time/weather audio blocked | Design Phase 5 as standalone; defer L2 coupling |

---

## Quick Links

- **Current Board:** `projects/sound/board.md`
- **Implementation Plan:** `projects/sound/sound-implementation-plan.md`
- **Design Notes (CBG):** `projects/sound/sound-design-notes.md`
- **Web Pipeline (Gil):** `projects/sound/sound-web-pipeline-notes.md`
- **Sound Architecture:** `docs/architecture/engine/sound-system.md`
- **Sound Design Guide:** `docs/design/sound-design-guide.md`

---

**Last Updated:** 2026-03-29  
**Next Review:** When Phase 1 assets are 50% sourced  
**Escalation:** If Phase 1 assets blocked >1 week, escalate to Wayne via `.squad/decisions/inbox/kirk-sound-phase1-blocked.md`
