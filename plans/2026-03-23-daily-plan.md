# Daily Plan — 2026-03-23

**Owner:** Wayne "Effe" Berry
**Focus:** Bug burndown from Wayne's play-test, search system improvements, web parity
**Updated:** 2026-03-23 9:39 AM PST (session in progress — plan synced with completed work)

---

## ✅ COMPLETED (pulled forward from 2026-03-22 afternoon)

### Carry-Over Items ✅
- [x] Deploy to live site (3 deploys today: Phase 7, parser fixes, Phase 3)
- [x] Bart: `--headless` testing mode implemented
- [x] LLM play testing skill updated to mandate `--headless`
- [x] Marge: closed Issues #1, #4, #7, #8 (already fixed), #2, #5, #6, #9, #10, #11 (hangs)
- [x] Gil hired as Web Engineer — owns deploys, web builds, browser fixes

### Phase 1: Design Docs ✅
- [x] `docs/design/injuries/unconsciousness.md` — FSM, severity-based duration, armor protection
- [x] `docs/design/injuries/self-hit.md` — Hit verb self-infliction, body areas
- [x] `docs/verbs/hit.md` — Verb reference: punch/strike/bash/bonk
- [x] `docs/design/objects/mirror.md` — `is_mirror` flag, appearance trigger
- [x] `docs/design/player/appearance.md` — Layer-based rendering, health tiers
- [x] `docs/design/objects/spatial-relationships.md` — hiding vs on-top-of (NEW)

### Phase 2: Architecture Docs ✅
- [x] `docs/architecture/player/appearance-subsystem.md` — Layered renderer, mirror integration
- [x] `docs/architecture/player/consciousness-state.md` — State machine, forced ticks, death handler
- [x] `docs/architecture/objects/spatial-relationships.md` — Hidden object visibility rules (NEW)

### Phase 3: Engine Implementation ✅
- [x] Hit verb: hit/punch/bash/bonk/thump — head→KO, limb→bruise, helmet reduces
- [x] Unconsciousness: state machine, game loop gate, bleed-out death, wake narration
- [x] Sleep injury fix: sleep now ticks injuries (was safe before)
- [x] Appearance subsystem: `appearance.lua` — layered body renderer
- [x] Mirror: vanity `is_mirror` flag → appearance.describe()
- [x] Tests: 1,117+ pass across 39 files
- [x] Nelson Pass 036: 29/37 pass, 4 presentation bugs (#28-31)

### Phase 3b: Spatial Relationships ✅ (Smithers — completed 2026-03-22 evening)
- [x] Fix traverse.lua: hidden objects skip search (#26)
- [x] Search peek mode: don't change container state (#24)
- [x] Search narration: report container contents (#27) — NOTE: #34 later found a reporting bug, now fixed
- [x] Tests for hiding, peek, narration

---

## 📋 Open Issues — 3 remaining (Marge triaged, ranked, assigned)

### Active Issues

| # | Title | Owner | Status |
|---|-------|-------|--------|
| #3 | Screen flicker | Bart | Queued |
| #18 | Safari cache (needs iPhone verify) | Wayne | Needs verify |
| #19 | Level intro text from level data | Moe | Deferred |

### ✅ Closed This Session (verified & closed by Marge)

**Critical & Essential (20 issues):** #14, #15, #16, #17, #20, #21, #22, #23, #24, #25, #26, #27, #28, #29, #30, #31, #33, #34

**Parser Phrase Routing (5 issues, fixed by Smithers):** #35, #36, #37, #38, #39

---

## Process Rules
1. Nelson play-tests between every phase
2. Commit+push between every step
3. Bugs tracked in GitHub Issues (WayneWalterBerry/MMO)
4. Engineers don't close Issues — Marge verifies and closes
5. Nelson uses `--headless` for all automated testing
6. Nelson gives Bart feedback on headless mode
7. Search = observation (no side effects), Open = action

---

## New Feature: Unconsciousness Injury System

**Wayne's design:** Expand the injury system to include injuries that cause unconsciousness — like a blow to the head. These are fundamentally different from bleeding/health-drain injuries.

### Design Principles

1. **Unconsciousness = temporary forced sleep.** Player can't act for N turns.
2. **Duration-based.** Each unconscious injury has a wake-up timer (e.g., "blow to the head" = 5-10 turns).
3. **Injury ticking continues while unconscious.** If you have a bleeding wound AND go unconscious, the bleeding ticks every turn. You can bleed out and die before waking up.
4. **Sleep + injuries = same risk.** If you go to sleep voluntarily with active bleeding injuries, you can bleed out and die during sleep. Sleep doesn't pause injury ticking.
5. **Wake-up narration.** When the timer expires: "You groan and open your eyes. Your head throbs. [time] has passed."
6. **Death during unconsciousness.** If health reaches 0 while unconscious: "You never wake up. The bleeding was too much."

### Injury Categories (after expansion)

| Category | Example | Mechanic | Ticks During Sleep/Unconscious? |
|----------|---------|----------|-------------------------------|
| **Bleeding** | Stab wound, cut | Loses health every turn | ✅ Yes — can bleed out |
| **Pain** | Bruise, sprain | Affects actions (slower, weaker) | No — dormant during sleep |
| **Unconsciousness** | Blow to head, knockout | Forced sleep for N turns | N/A — IS the sleep state |
| **Poison** | Nightshade | Ticks health + special effects | ✅ Yes — can die |

### Implementation Tasks

#### Phase 1: Design Docs (CBG + design team) ✅ PULLED FORWARD — completed 2026-03-22
- [x] `docs/design/injuries/unconsciousness.md` — Full FSM design, severity-based duration (3-25 turns), armor protection, wake-up narration
- [x] `docs/design/injuries/self-hit.md` — Hit verb self-infliction, body area targeting, armor interaction
- [x] `docs/verbs/hit.md` — Verb reference: synonyms (punch/strike/bash/bonk), body areas, injury types
- [x] `docs/design/objects/mirror.md` — `is_mirror` flag, appearance subsystem trigger, vanity placement
- [x] `docs/design/player/appearance.md` — Layer-based rendering, health tiers, multiplayer-ready
- [x] `git commit && git push`

#### Phase 2: Architecture Docs (Bart) ✅ PULLED FORWARD — completed 2026-03-22
- [x] `docs/architecture/player/appearance-subsystem.md` — Layered renderer pipeline, injury phrase composer, mirror integration, multiplayer-ready API
- [x] `docs/architecture/player/consciousness-state.md` — Full state machine, game loop gate, forced ticks, death handler
- [x] **Found bug:** Current sleep verb doesn't call `injury_mod.tick()` — sleeping with bleeding is currently safe (shouldn't be)
- [x] `git commit && git push`

#### Phase 3: Engine Implementation (Smithers + Bart) ✅ COMPLETED 2026-03-22
- [x] All items implemented — hit verb, unconsciousness, sleep fix, appearance, mirror
- [x] 1,117+ tests pass, Nelson Pass 036: 29/37 pass, 4 presentation bugs (#28-31)
- [x] `git commit && git push`

### 🧪 Nelson Sanity Check
- [x] Nelson tests: get injured → go unconscious → wake up (or die) — **PASS**
- [x] Nelson tests: get injured → sleep voluntarily → bleed out — **PASS**
- [x] Nelson tests: get injured → get knocked out → bleed out while unconscious — **PASS**
- [x] Nelson tests injury listing — natural phrasing: "health", "status", "how am I", "check my wounds", "am I hurt?", "what's wrong with me?", "injuries" — **PARTIAL: #35-36 found parser gaps, now fixed**
  - "Where am I bleeding from?" — should list bleeding injury locations
  - "Why don't I feel well?" — should describe all active injuries/effects
  - "Where is that blood coming from?" — should identify bleeding source
  - "Am I going to be ok?" — should give prognosis based on injury severity
  - "How bad is it?" — should describe injury severity
  - "What happened to my arm?" — should describe injuries to specific body part
- [x] Nelson tests inventory/hands — natural phrasing — **PARTIAL: #38 found parser gaps, now fixed**
  - "inventory" / "i" — does it show hands + worn + bags?
  - "what am I holding?" — should show hand slots
  - "what's in my hands?" — same
  - "what am I carrying?" — should show everything
  - "look at my hands" — should describe what's in them
  - "am I holding anything?" — yes/no + what
  - "what do I have?" — should show full inventory
  - "drop what I'm holding" — should work with context
- [x] Write results + file Issues for any bugs

**Pass 038: 22/38 pass. 5 bugs filed (#35-39), all fixed by Smithers in 351bfa3**

### Today's Session (2026-03-23 Morning) ✅

#### Bug Burndown
- [x] Marge: verified & closed 20 issues (#14-17, #20-31, #33-34, #35-39)
- [x] Smithers: fixed #22 (matchbox search) + #34 (container reporting) — 12 tests
- [x] Smithers: fixed #35-39 (parser phrase routing) — 30+ transforms, 2 new verbs
- [x] Nelson: Pass 038 sanity check — 22/38, filed #35-39

#### Design & Architecture  
- [x] CBG: poison bottle design doc (docs/design/objects/poison-bottle.md)
- [x] CBG: bear trap design doc (docs/design/objects/bear-trap.md)
- [x] CBG: injury hook taxonomy (4 categories: consumption, contact, proximity, duration)
- [x] Bart: engine hooks architecture (docs/architecture/engine/event-hooks.md)
- [x] Bart: proposed Effect Processing Pipeline (effects.lua)
- [x] Frink: classic IF research on poison/trap mechanics (docs/research/injury-objects-classic-if.md)

#### Object Implementation
- [x] Flanders: poison-bottle.lua (nested parts, consumable effects, FSM)
- [x] Flanders: bear-trap.lua (contact injury, 3-state FSM, disarm mechanics)
- [x] Flanders: crushing-wound.lua injury type (blunt + bleeding combo)
- [x] Flanders: object reference docs (docs/objects/poison-bottle.md, docs/objects/bear-trap.md)

#### Infrastructure
- [x] Gil: fixed squad-main-guard.yml CI workflow (removed main from push trigger)
- [x] Brockman: March 22 evening newspaper edition
- [x] Chalmers: plan audit — checkboxes synced with git history

---

#### Phase 3: Objects (Flanders)
- [ ] Create injury-causing objects that trigger unconsciousness
  - Falling rock trap? Ceiling collapse?
  - Enemy blow (combat precursor)?
  - Poison gas (cellar area)?
- [ ] Design narration for each unconsciousness trigger
- [x] `git commit && git push` (commit f102439)
---

## New Feature: Mirror / Player Appearance Subsystem

**Wayne's design:** A mirror is a special object with a metadata flag/hook that, when the player looks at it, shows what they look like — clothing, armor, injuries, bandages, blood, etc. This requires a whole engine subsystem for composing a player appearance description from their `player.lua` state.

**Key insight:** This subsystem is reusable. Today it powers mirrors. Tomorrow (multiplayer) it powers what one player sees when they look at another player. Design for that future, implement for single-player now.

### Design Principles

1. **Mirror = special object with `is_mirror` flag.** When you `look at mirror` or `examine mirror`, the engine intercepts and runs the player appearance subsystem instead of normal examine.
2. **Appearance is composed, not canned.** The subsystem reads the player's full state (worn items, held items, injuries, bandages, blood) and builds a dynamic description.
3. **Layered description.** Head-to-toe ordering:
   - Head: helmet, hat, hair, face injuries
   - Torso: armor, shirt, chest injuries, bandages
   - Arms/hands: gloves, held items, arm injuries
   - Legs: pants, leg armor, leg injuries
   - Feet: boots, shoes
   - Overall: blood stains, pallor (from health), general condition
4. **Smart injury rendering.** Not just "you have a cut" — it should compose: "a deep cut on your left arm, partially covered by a bloodied bandage" or "dried blood on your forehead from the gash above your eye"
5. **State-aware.** The description changes based on:
   - What you're wearing (armor, clothing, nothing)
   - Active injuries (bleeding, bruised, bandaged)
   - Health level (pale, flushed, fine)
   - What you're holding
6. **Engine subsystem, not object logic.** This lives in the engine (`src/engine/player/appearance.lua` or similar), not in object files. Objects just have the `is_mirror` flag.
7. **Future-proof for multiplayer.** Same subsystem answers "what does Player B look like?" — just swap whose state you're reading.

### Implementation Tasks

#### Phase M1: Design Docs ✅
- [x] `docs/design/objects/mirror.md` — Mirror object design:
  - `is_mirror` metadata flag on mirror objects
  - How `look at mirror` / `examine mirror` triggers appearance subsystem
  - Mirror placement (bedroom vanity, bathroom, hand mirror as inventory item?)
  - Narration framing: "In the mirror, you see..." vs "Your reflection shows..."
- [x] `docs/design/player/appearance.md` — Player appearance subsystem design:
  - How appearance is composed from player state
  - Head-to-toe layer ordering
  - Injury + clothing interaction (bandage over wound, blood on shirt)
  - Health-based overall descriptors (pale, flushed, strong)
  - Held item inclusion
  - Smart phrasing: composing natural English from state flags
  - Multiplayer hook: same subsystem, different player state input
- [x] `git commit && git push` (commit f102439)

#### Phase M2: Architecture Docs (Bart) ✅
- [x] `docs/architecture/player/appearance-subsystem.md` — Architecture:
  - Where it lives in the engine (`src/engine/player/appearance.lua`)
  - Input: player state table (worn items, injuries, health, held items)
  - Output: composed natural language description string
  - Layer system: ordered renderers (head, torso, arms, legs, feet, overall)
  - Each layer is a function: `render_head(player_state) → string or nil`
  - Nil layers are skipped (nothing notable to say)
  - Injury rendering pipeline: injury → location → severity → treatment → compose phrase
  - Integration point: mirror object `on_examine` hook calls appearance subsystem
  - Future integration point: `look at <player>` calls same subsystem with target's state
- [x] Review how player.lua currently stores worn items, injuries, held items
- [x] `git commit && git push` (commits dbe484e, 1cda161)

#### Phase M3: Engine Implementation (Smithers) ✅
- [x] `src/engine/player/appearance.lua` — Player appearance subsystem:
  - `appearance.describe(player_state)` → full description string
  - Layer renderers: head, torso, arms, hands, legs, feet, overall
  - Injury phrase composer: reads injury type, location, severity, treatment status
  - Health descriptor: maps HP percentage to adjectives (pale, gaunt, flushed, healthy)
  - Clothing/armor renderer: reads worn item slots, describes each
  - Held item renderer: describes what's in each hand
  - Smart composition: avoids repetition, uses natural English connectives
- [x] Mirror object hook: `is_mirror` flag → `on_examine` calls `appearance.describe()`
- [x] Parser integration: "look in mirror", "examine mirror", "look at my reflection" all trigger appearance
- [x] Create a mirror object in the bedroom (the oak vanity already exists — add mirror property)
- [x] **TEST GATE:** Unit tests covering:
  - Naked player → basic description
  - Fully armored player → all slots described
  - Injured player → injuries shown with locations
  - Bandaged injury → "covered by bandage" phrasing
  - Bleeding + bandage → "bloodied bandage" phrasing
  - Low health → pale/gaunt descriptors
  - Holding items → described in hand slots
  - Multiple injuries → all listed naturally
  - Empty slot → skipped gracefully (no "you are wearing nothing on your feet")
- [x] `git commit && git push` (commit 14b2ef4)

#### Phase M4: Nelson Review
- [ ] Nelson examines the mirror with various player configurations:
  - Fresh player (no injuries, basic clothing)
  - Injured player (stab wound, bleeding)
  - Bandaged player (treated wound)
  - Armored player (helmet, armor, boots)
  - Injured + armored (blood on armor, bandage under helmet)
  - Unconscious player can't look in mirror (verify error message)
- [ ] Nelson reviews the QUALITY of the mirror text — does it read naturally?
  - Not robotic: "You are wearing a helmet. You have a cut." ❌
  - Natural: "Your reflection shows a battered figure in dented iron armor, dried blood visible on the left pauldron where a deep gash runs beneath." ✅
- [ ] File Issues for any awkward/robotic phrasing
- [ ] `git commit && git push`

---

## Process Rules (same as 2026-03-22)

1. Nelson play-tests between every phase
2. Commit+push between every step
3. Keep this plan updated — mark items [x] as they complete
4. All tests must pass before advancing
5. Bugs tracked in GitHub Issues (WayneWalterBerry/MMO)
6. Engineers don't close Issues — Marge verifies and closes
7. Hang bugs require RCA before closure

---

## Design Decisions (answered 2026-03-22)

1. **Duration:** Severity-based — harder hit = longer unconscious. Each injury source defines a severity that maps to turn count.
2. **Early wake-up:** Single player for now — you always wait out the timer. Design the hook for future multiplayer but don't implement NPC wake-up yet.
3. **Dazed state:** No — binary conscious/unconscious, clean transition. No intermediate state.
4. **Armor protection:** Yes — helmets/armor reduce unconsciousness duration or prevent it entirely for weak blows. Design the `reduces_unconsciousness` property on wearable objects.
5. **Injury listing verb:** Three approaches, all should work:
   - `health` / `check health` — natural, covers injuries + overall state
   - `status` — covers everything (health, injuries, hunger, time)
   - `how am I` / `how do I feel` — Prime Directive natural English
   - Parser should handle all variants: "check my wounds", "am I hurt?", "what's wrong with me?", "injuries", "wounds"
   - **Nelson must test this area after implementation** — wide variety of natural phrasing




