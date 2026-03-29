# NPC + Combat Unified Implementation Plan

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Status:** ✅ COMPLETE — Phase 1 shipped (creature engine 421 LOC, combat FSM 435 LOC, 14 test files)  
**Requested By:** Wayne "Effe" Berry  
**Governs:** NPC Phase 1 → Combat Phase 1 (sequential with internal parallelism)

---

## Quick Reference

| Wave | Name | Parallel Tracks | Gate | Key Deliverable |
|------|------|-----------------|------|-----------------|
| **WAVE-0** | Pre-Flight (Infrastructure) | 1 track | — | Register test/creatures/ and test/combat/ in test runner |
| **WAVE-1** | NPC Foundation (Data) | 3 tracks | GATE-1 | creature template, rat.lua, flesh.lua, test scaffolding |
| **WAVE-2** | NPC Engine (Behavior) | 3 tracks | GATE-2 | creature tick, stimulus system, game loop integration |
| **WAVE-3** | NPC Interaction (Verbs) | 3 tracks | GATE-3 | catch/chase verbs, room presence, attack-creature, Nelson LLM, Brockman NPC docs |
| **WAVE-4** | Combat Foundation (Data) | 3 tracks | GATE-4 | body_tree, tissue materials, weapon metadata, combat test scaffolding |
| **WAVE-5** | Combat Engine (Resolution) | 2 tracks | GATE-5 | combat exchange FSM, material damage resolution, narration (split: init.lua + narration.lua) |
| **WAVE-6** | Combat Integration (Verbs + Loop) | 3 tracks | GATE-6 | attack verb extension, stance-based combat, flee, darkness rules, Nelson LLM, Brockman combat docs |

**Total new files:** ~25 (code + tests) + 9 doc files  
**Total modified files:** ~9 (including test/run-tests.lua in WAVE-0)  
**Estimated scope:** 7 waves (WAVE-0 through WAVE-6), 6 gates, ~2,500 lines code + ~1,500 lines tests + ~9 architecture/design docs

---

## Section 1: Executive Summary

We're building two interlocking systems — NPC autonomy and physical combat — in a strict sequence that maximizes parallel agent work while preventing file conflicts.

**NPC Phase 1** (WAVE-1 through WAVE-3) establishes creature autonomy: a rat that exists in rooms, moves between them, reacts to stimuli, and bites when grabbed. It uses the existing `injuries.inflict()` for damage — no combat FSM, no body_tree, no combat metadata. This is Wayne's approved decision (D-COMBAT-NPC-PHASE-SEQUENCING).

**Combat Phase 1** (WAVE-4 through WAVE-6) retrofits physical combat onto the working NPC foundation: body_tree zones on player and rat, tissue materials, a 6-phase combat exchange FSM, material-based damage resolution, and combat narration. It consumes the creature infrastructure NPC Phase 1 built.

**Why this sequence:** NPC Phase 1 proves that creatures work as autonomous agents before we complicate them with combat. If the rat doesn't feel alive without combat, combat won't fix it. If it does feel alive, combat adds tactical depth to an already-working system.

**Walk-away capability:** Each wave is a batch of parallel work assignments. The coordinator spawns agents, collects results, runs Nelson's gate tests. Pass → next wave. Fail → file issue, assign fix, re-gate. Wayne doesn't need to be in the loop unless a gate fails twice.

---

## Section 2: Dependency Graph

```
WAVE-0: Pre-Flight (Infrastructure)
└── [Bart]     Register test/creatures/ and test/combat/ in test/run-tests.lua
        │
        ▼  ── (no gate — 2-line change, verified by run-tests.lua dry run) ──
        │
WAVE-1: NPC Foundation (Data Layer)
├── [Flanders] creature.lua template ─────────────┐
├── [Flanders] rat.lua object definition ──────────┤ (parallel, no file overlap)
├── [Flanders] flesh.lua material ─────────────────┤
└── [Nelson]   test scaffolding (test/creatures/)──┘
        │
        ▼  ── GATE-1 (template loads, rat validates, flesh resolves) ──
        │
WAVE-2: NPC Engine (Behavior Layer)
├── [Bart]     engine/creatures/init.lua ──────────┐
│              (tick, drives, stimulus, actions)    │
├── [Bart]     loop/init.lua integration (~6 lines)│ (parallel, Bart owns both)
└── [Nelson]   test/creatures/test-creature-tick.lua
        │
        ▼  ── GATE-2 (creature tick works, drives decay, actions execute) ──
        │
WAVE-3: NPC Interaction (Verb + Presence Layer)
├── [Smithers] catch/chase verbs + room presence ──┐
│              attack creature extension            │ (parallel, no file overlap)
├── [Bart]     stimulus emission points ────────────┤
│              (verbs/init.lua, movement.lua,       │
│               fsm/init.lua, effects.lua)          │
├── [Brockman] NPC architecture docs ──────────────┤
│              (creature-system.md, stimulus-       │
│               system.md, creature-template.md,    │
│               npc-system.md)                      │
└── [Nelson]   LLM walkthrough + integration tests ┘
        │
        ▼  ── GATE-3 (NPC Phase 1 COMPLETE — full Nelson LLM walkthrough + Brockman docs) ──
        │
        │  ═══ NPC PHASE 1 SHIPS HERE ═══
        │
WAVE-4: Combat Foundation (Data Layer)
├── [Flanders] body_tree on rat.lua (retrofit) ────┐
├── [Flanders] body_tree on player model ──────────┤
├── [Flanders] 6 tissue materials ─────────────────┤ (parallel, no file overlap)
├── [Flanders] weapon combat metadata ─────────────┤
└── [Nelson]   test/combat/ scaffolding ───────────┘
        │
        ▼  ── GATE-4 (body_tree validates, materials resolve, weapons have combat table) ──
        │
WAVE-5: Combat Engine (Resolution Layer)
├── [Bart]     engine/combat/init.lua ─────────────┐
│              (exchange FSM, resolve_exchange,     │
│               material damage, narration)         │ (parallel, no file overlap)
└── [Nelson]   test/combat/test-exchange-fsm.lua ──┤
               test/combat/test-material-damage.lua┘
        │
        ▼  ── GATE-5 (FSM transitions correctly, damage resolves, narration generates) ──
        │
WAVE-6: Combat Integration (Verb + Loop Layer)
├── [Smithers] attack verb → combat FSM trigger ───┐
│              stance prompt + interrupt detection  │
│              flee mechanic                        │ (parallel, no file overlap)
├── [Bart]     combat → injury integration ─────────┤
│              creature death mutation              │
│              combat in darkness rules             │
│              loop integration for combat FSM      │
├── [Brockman] Combat architecture docs ───────────┤
│              (body-zone-system.md, combat-fsm.md, │
│               damage-resolution.md, combat-       │
│               narration.md, combat-system.md)     │
└── [Nelson]   LLM walkthrough + integration tests ┘
        │
        ▼  ── GATE-6 (Combat Phase 1 COMPLETE — full Nelson LLM walkthrough + Brockman docs) ──
```

**Key constraint:** No two agents in any wave touch the same file. File ownership is explicit in Section 3.

---

## Section 3: Implementation Waves

### WAVE-0: Pre-Flight (Infrastructure)

**Goal:** Register new test directories in `test/run-tests.lua` before any test files are created.

| Task | Agent | Files Modified | Scope |
|------|-------|---------------|-------|
| Register test/creatures/ and test/combat/ | Bart | **MODIFY** `test/run-tests.lua` | Tiny (2 lines) |

**Bart instructions:**

Add two entries to the `test_dirs` table in `test/run-tests.lua` (after the existing `test/fsm` entry):
```lua
repo_root .. SEP .. "test" .. SEP .. "creatures",
repo_root .. SEP .. "test" .. SEP .. "combat",
```

**Verification:** Run `lua test/run-tests.lua` — must pass with zero regressions. The new directories don't exist yet, so the runner will simply find no test files in them (no error).

---

### WAVE-1: NPC Foundation (Data Layer)

**Goal:** All creature data definitions exist, load cleanly, and pass static validation.

| Task | Agent | Files Created/Modified | TDD Test File | Scope |
|------|-------|----------------------|---------------|-------|
| Creature template | Flanders | **CREATE** `src/meta/templates/creature.lua` | `test/creatures/test-creature-template.lua` (Nelson) | Small |
| Rat object definition | Flanders | **CREATE** `src/meta/creatures/rat.lua` | `test/creatures/test-rat-definition.lua` (Nelson) | Medium |
| Flesh material | Flanders | **CREATE** `src/meta/materials/flesh.lua` | `test/creatures/test-flesh-material.lua` (Nelson) | Small |
| Test directory + helpers | Nelson | **CREATE** `test/creatures/test-creature-template.lua`, `test/creatures/test-rat-definition.lua`, `test/creatures/test-flesh-material.lua` | — | Medium |

**File ownership (no overlap):**
- Flanders: `src/meta/templates/creature.lua`, `src/meta/creatures/rat.lua`, `src/meta/materials/flesh.lua`
- Nelson: `test/creatures/test-creature-template.lua`, `test/creatures/test-rat-definition.lua`, `test/creatures/test-flesh-material.lua`

**Flanders instructions — creature.lua template:**
- Use the spec from `plans/npc-system-plan.md` Section 3
- `animate = true`, FSM states (`alive-idle`, `alive-wander`, `alive-flee`, `dead`)
- Behavior, drives, reactions, movement, awareness tables as defaults
- Health/max_health, alive flag
- **NO body_tree, NO combat table** — those come in WAVE-4 (D-COMBAT-NPC-PHASE-SEQUENCING)
- Size field is string enum: `"small"` (not number)
- Must have `on_feel` (mandatory sensory property)
- Generate a fresh Windows GUID

**Flanders instructions — rat.lua:**
- Use the spec from `plans/npc-system-plan.md` Section 6.1
- Complete behavior metadata: `default = "idle"`, `aggression = 5`, `flee_threshold = 30`, `wander_chance = 40`
- Three drives: hunger, fear, curiosity (with decay rates)
- Four reactions: `player_enters`, `player_attacks`, `loud_noise`, `light_change`
- Movement: `speed = 1`, `can_open_doors = false`, `can_climb = true`
- FSM states: `alive-idle`, `alive-wander`, `alive-flee`, `dead`
- `dead` state sets `portable = true`, `animate = false`
- `size = "tiny"`, `weight = 0.3`, `material = "flesh"`
- **NO body_tree, NO combat table** in this wave
- Generate a fresh Windows GUID

**Flanders instructions — flesh.lua:**
- Use the spec from `plans/npc-system-plan.md` Section 7.3
- Standard material properties: `density = 1050`, `hardness = 1`, `flexibility = 0.8`, `fragility = 0.7`, etc.
- This is muscle/fat tissue — distinct from skin/hide (those come in WAVE-4)

**Nelson instructions — test scaffolding:**
- Create `test/creatures/` directory
- `test-creature-template.lua`: Template loads via dofile, required fields exist (`animate`, `behavior`, `drives`, `reactions`, `on_feel`, `states`, `initial_state`), field types validate
- `test-rat-definition.lua`: Rat loads, inherits from creature template, all keywords present, all FSM states defined, all drives have required fields, all reactions have required fields, size is string enum
- `test-flesh-material.lua`: flesh.lua loads via dofile, `density` is number, `hardness` is number, material resolves through `engine/materials` if possible

---

### WAVE-2: NPC Engine (Behavior Layer)

**Goal:** The creature tick engine exists and correctly evaluates behavior metadata. Creatures update drives, match stimuli, select actions, and move between rooms.

**Depends on:** GATE-1 pass (creature template and rat definition load cleanly)

| Task | Agent | Files Created/Modified | TDD Test File | Scope |
|------|-------|----------------------|---------------|-------|
| Creature engine module | Bart | **CREATE** `src/engine/creatures/init.lua` | `test/creatures/test-creature-tick.lua` (Nelson) | Large |
| Game loop integration | Bart | **MODIFY** `src/engine/loop/init.lua` (~8 lines) | (covered by tick tests) | Small |
| Creature tick tests | Nelson | **CREATE** `test/creatures/test-creature-tick.lua` | — | Large |

**File ownership (no overlap):**
- Bart: `src/engine/creatures/init.lua`, `src/engine/loop/init.lua`
- Nelson: `test/creatures/test-creature-tick.lua`

**Bart instructions — engine/creatures/init.lua (~250–300 lines):**

The module must be generic (Principle 8). It does NOT know about rats. It knows about:
- Tables with `animate == true`
- Drive decay/growth via `drives` table
- Stimulus queue matching against `reactions` tables
- Utility-scored action selection from `behavior` metadata
- Generic action execution: `idle`, `wander`, `flee`, `hide`, `approach`, `vocalize`
- Room movement via registry location tracking
- Perception range optimization (full tick for same room, partial for adjacent, minimal for distant)

API surface:
```lua
local M = {}
local stimulus_queue = {}

function M.emit_stimulus(room_id, stimulus_type, data)
function M.tick(context) -> messages[]
function M.get_creatures_in_room(registry, room_id) -> creature[]
```

Core algorithm per `plans/npc-system-plan.md` Section 5.2:
1. For each creature where `animate == true`:
2. Update drives (decay hunger up, decay fear down per `decay_rate`)
3. Check stimulus_queue for matching entries in creature's `reactions` table
4. Apply reaction drive deltas
5. Score available actions via utility calculation (drive weights + jitter)
6. Execute highest-scoring action
7. If creature moved rooms: update registry location, emit arrival/departure messages
8. If creature is in player's room: collect narration messages
9. Return all messages for the loop to print

**Wander action:** Pick random valid exit from current room. Validate against `movement.can_open_doors` and `movement.size_limit`. Move creature's location in registry. Emit departure message in old room, arrival message in new room.

**Flee action:** Pick exit farthest from threat (or random if no directional data). Move immediately. Emit flee narration.

**Game loop integration:** Insert creature tick after fire propagation and before injury tick in `loop/init.lua`:
```lua
-- Creature tick: evaluate behavior for all animate objects
local creature_ok, creature_mod = pcall(require, "engine.creatures")
if creature_ok and creature_mod then
    local creature_msgs = creature_mod.tick(context)
    for _, msg in ipairs(creature_msgs or {}) do
        print(msg)
    end
end
```
This slots in at approximately line 633 of the current `loop/init.lua`, after fire propagation and before injury tick.

**Nelson instructions — test-creature-tick.lua (~150 lines):**

Test with mock creatures (pure tables, no file I/O). Must cover:
1. Drive decay: hunger increases by `decay_rate` per tick
2. Drive clamping: drives don't exceed `max` or go below `min`
3. Fear spike: emitting `player_enters` stimulus increases fear by `fear_delta`
4. Fear decay: fear decreases by `decay_rate` over multiple ticks
5. Wander action: creature with high `wander_chance` eventually moves rooms
6. Flee action: creature with fear above `flee_threshold` flees
7. Idle action: creature with no urgent drives stays idle
8. Room boundary: creature can't move through doors if `can_open_doors = false` and door is closed
9. Dead creatures: `animate = false` creatures are skipped
10. Perception range: creatures in distant rooms only get drive decay (no movement)
11. Message collection: tick returns messages array for player's room only
12. Multiple creatures: tick handles N creatures without interference
13. Distant-room stimulus boundary: creature 3+ rooms away receives NO stimulus when `player_enters` fires locally. Validates `perception_range` boundary — only same-room and adjacent-room creatures react.

---

### WAVE-3: NPC Interaction (Verb + Presence Layer)

**Goal:** Player can see, hear, feel, catch, chase, and attack the rat. Stimuli fire on player actions. Full NPC Phase 1 integration.

**Depends on:** GATE-2 pass (creature tick works correctly)

| Task | Agent | Files Created/Modified | TDD Test File | Scope |
|------|-------|----------------------|---------------|-------|
| catch verb handler | Smithers | **MODIFY** `src/engine/verbs/init.lua` | `test/creatures/test-creature-verbs.lua` (Nelson) | Medium |
| chase verb handler | Smithers | **MODIFY** `src/engine/verbs/init.lua` | (same test file) | Small |
| Attack creature extension | Smithers | **MODIFY** `src/engine/verbs/init.lua` | (same test file) | Medium |
| Room presence for creatures | Smithers | **MODIFY** `src/engine/verbs/init.lua` (look handler) | (same test file) | Small |
| Stimulus emission: room transition | Bart | **MODIFY** `src/engine/verbs/movement.lua` | `test/creatures/test-stimulus.lua` (Nelson) | Small |
| Stimulus emission: attack | Bart | **MODIFY** `src/engine/verbs/combat.lua` | (same test file) | Small |
| Stimulus emission: loud noise | Bart | **MODIFY** `src/engine/effects.lua` | (same test file) | Small |
| Stimulus emission: light change | Bart | **MODIFY** `src/engine/fsm/init.lua` | (same test file) | Small |
| Rat room placement | Moe | **MODIFY** `src/meta/world/cellar.lua` (or appropriate room) | `test/creatures/test-rat-room.lua` (Nelson) | Small |
| Integration + LLM tests | Nelson | **CREATE** `test/creatures/test-creature-verbs.lua`, `test/creatures/test-stimulus.lua`, `test/creatures/test-rat-room.lua`, `test/integration/test-npc-integration.lua` | — | Large |
| NPC architecture docs | Brockman | **CREATE** `docs/architecture/engine/creature-system.md`, `docs/architecture/engine/stimulus-system.md`, `docs/architecture/engine/creature-template.md`, `docs/design/npc-system.md` | — | Medium |

**File ownership (no overlap):**
- Smithers: `src/engine/verbs/init.lua`
- Bart: `src/engine/verbs/movement.lua`, `src/engine/verbs/combat.lua`, `src/engine/effects.lua`, `src/engine/fsm/init.lua`
- Moe: `src/meta/world/cellar.lua` (or chosen room file)
- Brockman: `docs/architecture/engine/creature-system.md`, `docs/architecture/engine/stimulus-system.md`, `docs/architecture/engine/creature-template.md`, `docs/design/npc-system.md`
- Nelson: all test files in `test/creatures/` and `test/integration/test-npc-integration.lua`

**Smithers instructions — verb handlers:**

*catch verb:*
- Resolve creature by keyword via `context.registry:find_by_keyword(noun)`
- Check `animate == true` and `alive == true`; if dead, suggest "take" instead
- Check size: creatures larger than "small" can't be caught bare-handed
- Check free hand: player needs an empty hand slot
- Success roll: `math.random(100) > (creature.behavior.flee_threshold + 20)`
- On success: print catch message, call `injuries.inflict(player, "minor-cut", creature.id, "arms", 2)` for rat bite (Wayne's approved simple injury on grab)
- On failure: print escape message, emit `player_attacks` stimulus via `creatures.emit_stimulus()`
- Register aliases: `catch`, `grab`, `snatch`

*chase verb:*
- Resolve creature in current room or recently departed
- If creature is in `alive-flee` state and has `_last_exit`, move player through that exit
- If creature is not fleeing: "Nothing to chase."
- Register aliases: `chase`, `pursue`, `follow`

*Attack creature extension:*
- In the existing attack/hit/kick handler, add creature detection
- If target is a creature with `animate == true`:
  - Apply damage directly: reduce `creature.health` by weapon force or bare-hand force (3)
  - If health ≤ 0: transition FSM to `dead` state, print death message
  - Emit `player_attacks` stimulus
  - Emit `loud_noise` stimulus (for other creatures in the room)
- **NO combat FSM in this wave** — direct damage only

*Room presence:*
- In the `look` verb handler, after rendering object presences, iterate `creatures.get_creatures_in_room()` and print each creature's `room_presence` from their current FSM state
- In darkness: use `on_listen` description instead of visual presence

**Bart instructions — stimulus emission (~4-5 small edits):**

In `verbs/movement.lua` after player moves to new room:
```lua
local creature_ok, creatures = pcall(require, "engine.creatures")
if creature_ok and creatures then
    creatures.emit_stimulus(new_room.id, "player_enters", { player = true })
    if old_room then
        creatures.emit_stimulus(old_room.id, "player_leaves", { player = true })
    end
end
```

In `verbs/combat.lua` (the attack handler file) after player attacks a creature:
```lua
creatures.emit_stimulus(context.current_room.id, "player_attacks", { target = creature.id })
```

In `effects.lua` after loud effects (break, slam):
```lua
creatures.emit_stimulus(room_id, "loud_noise", {})
```

In `fsm/init.lua` after light-source transitions (lit/extinguished):
```lua
creatures.emit_stimulus(room_id, "light_change", {})
```

All of these are optional pcall-guarded — if `engine.creatures` isn't loaded, they silently no-op.

**Moe instructions — rat placement:**
- Place rat in cellar.lua (or start-room.lua if Wayne prefers the rat accessible from game start)
- Rat is placed as a **top-level instance** in the room (NOT on/in/under furniture): `instances = { ..., { id = "cellar-rat", type_id = "{rat-guid}" } }`
- This means the rat is on the floor/ground of the room, free to move
- No other changes to the room file

**Nelson instructions — integration + LLM tests:**

*test-creature-verbs.lua (~100 lines):*
- Mock creature in registry, mock player with hands
- Test catch on live creature: success path (message + injury), failure path (escape + stimulus)
- Test catch on dead creature: redirects to take
- Test catch on non-creature: error message
- Test chase fleeing creature: player moves rooms
- Test chase non-fleeing creature: error message
- Test attack creature: damage applied, death transition when health ≤ 0
- Test look room with creature: presence text appears
- Test sensory verbs on creature: feel/smell/listen return creature descriptions

*test-stimulus.lua (~80 lines):*
- Emit `player_enters` stimulus: creature in room receives fear_delta
- Emit `player_attacks` stimulus: creature receives fear spike, enters flee state
- Emit `loud_noise` stimulus: creature receives fear delta
- Emit `light_change` stimulus: creature receives evaluation trigger
- Stimulus in empty room: no errors

*test-rat-room.lua (~30 lines):*
- Room loads with rat instance
- Rat is in room's contents after loader processes it
- Rat resolves by keyword in registry

*test-npc-integration.lua (~80 lines, using `--headless`):*
- Full game loop scenario: enter room → hear rat → feel rat → light candle → see rat → grab rat → get bitten → rat flees → rat wanders back

**Brockman instructions — NPC architecture docs (4 files, all in `docs/`):**

Brockman runs in parallel with Nelson's LLM testing — no file conflicts (docs/ vs test/).

- `docs/architecture/engine/creature-system.md`: Document the creature tick engine (`src/engine/creatures/init.lua`). Cover: drive system, stimulus queue, action selection, perception ranges, room movement, game loop integration point. Reference Principle 8 (engine executes metadata).
- `docs/architecture/engine/stimulus-system.md`: Document stimulus emission and reception. Cover: `emit_stimulus()` API, stimulus types (`player_enters`, `player_attacks`, `loud_noise`, `light_change`), pcall-guarded optional coupling, reaction matching in creature tick.
- `docs/architecture/engine/creature-template.md`: Document the creature template format (`src/meta/templates/creature.lua`). Cover: required fields, behavior/drives/reactions structure, FSM states, size enum, sensory properties, how instances override template defaults.
- `docs/design/npc-system.md`: Design-level overview of the NPC system. Cover: creature autonomy model, rat as first creature, interaction verbs (catch/chase/attack), room presence rendering, Phase 1 scope and Phase 2 roadmap.

**Rule: No phase ships without its docs.** GATE-3 requires all 4 NPC docs to exist and accurately describe the implemented system.

---

### WAVE-4: Combat Foundation (Data Layer)

**Goal:** Body zones, tissue materials, and weapon combat metadata exist and validate. The data layer for combat is complete before we build the engine.

**Depends on:** GATE-3 pass (NPC Phase 1 complete)

| Task | Agent | Files Created/Modified | TDD Test File | Scope |
|------|-------|----------------------|---------------|-------|
| body_tree on rat | Flanders | **MODIFY** `src/meta/creatures/rat.lua` | `test/combat/test-body-tree.lua` (Nelson) | Small |
| body_tree on player | Flanders | **MODIFY** `src/main.lua` (player table, lines ~305-324) | `test/combat/test-player-body.lua` (Nelson) | Small |
| skin.lua material | Flanders | **CREATE** `src/meta/materials/skin.lua` | `test/combat/test-tissue-materials.lua` (Nelson) | Small |
| hide.lua material | Flanders | **CREATE** `src/meta/materials/hide.lua` | (same test file) | Small |
| bone.lua material | Flanders | **CREATE** `src/meta/materials/bone.lua` | (same test file) | Small |
| organ.lua material | Flanders | **CREATE** `src/meta/materials/organ.lua` | (same test file) | Small |
| tooth_enamel.lua material | Flanders | **CREATE** `src/meta/materials/tooth_enamel.lua` | (same test file) | Small |
| keratin.lua material | Flanders | **CREATE** `src/meta/materials/keratin.lua` | (same test file) | Small |
| Weapon combat metadata | Flanders | **MODIFY** `src/meta/objects/silver-dagger.lua`, `src/meta/objects/knife.lua` | `test/combat/test-weapon-metadata.lua` (Nelson) | Small |
| Combat test scaffolding | Nelson | **CREATE** `test/combat/test-body-tree.lua`, `test/combat/test-player-body.lua`, `test/combat/test-tissue-materials.lua`, `test/combat/test-weapon-metadata.lua` | — | Medium |

**File ownership (no overlap):**
- Flanders: `src/meta/creatures/rat.lua`, `src/main.lua` (player table only), 6 material files, weapon object files
- Nelson: all files in `test/combat/`

**Flanders instructions — body_tree on rat.lua:**

Add to the existing rat.lua (WAVE-1 created it without body_tree):
```lua
body_tree = {
    head = { size = 1, vital = true, tissue = { "hide", "flesh", "bone" } },
    body = { size = 3, vital = true, tissue = { "hide", "flesh", "bone", "organ" } },
    legs = { size = 2, vital = false, tissue = { "hide", "flesh", "bone" }, on_damage = { "reduced_movement" } },
    tail = { size = 1, vital = false, tissue = { "hide", "flesh" }, on_damage = { "balance_loss" } },
},
```

Also add the `combat` table per `plans/combat-system-plan.md` Section 7.2:
```lua
combat = {
    size = "tiny",
    speed = 6,
    natural_weapons = {
        { id = "bite", type = "pierce", material = "tooth_enamel", zone = "head", force = 2, target_pref = "arms", message = "sinks its teeth into" },
        { id = "claw", type = "slash", material = "keratin", zone = "legs", force = 1, message = "rakes its claws across" },
    },
    natural_armor = nil,
    behavior = {
        aggression = "on_provoke",
        flee_threshold = 0.3,
        attack_pattern = "random",
        defense = "dodge",
        target_priority = "threatening",
        pack_size = 1,
    },
},
```

**Flanders instructions — body_tree on player:**

Add to the player table in **`src/main.lua`** (lines ~305-324, where the `local player = { ... }` table is defined):
```lua
body_tree = {
    head  = { size = 1, vital = true,  tissue = { "skin", "flesh", "bone" } },
    torso = { size = 4, vital = true,  tissue = { "skin", "flesh", "bone", "organ" } },
    arms  = { size = 2, vital = false, tissue = { "skin", "flesh", "bone" }, on_damage = { "weapon_drop", "reduced_attack" } },
    legs  = { size = 2, vital = false, tissue = { "skin", "flesh", "bone" }, on_damage = { "reduced_movement", "prone" } },
},
combat = {
    size = "medium",
    speed = 4,
    natural_weapons = {
        { id = "punch", type = "blunt", material = "bone", zone = "arms", force = 2, message = "punches" },
        { id = "kick", type = "blunt", material = "bone", zone = "legs", force = 3, message = "kicks" },
    },
    natural_armor = nil,
},
```

**Flanders instructions — tissue materials (6 files):**

Each file in `src/meta/materials/`:
- `skin.lua`: `density = 1050, hardness = 1, flexibility = 0.7, fragility = 0.6, absorbency = 0.3, opacity = 1.0, flammability = 0.3, conductivity = 0.1, value = 0`
- `hide.lua`: `density = 1100, hardness = 2, flexibility = 0.6, fragility = 0.5, absorbency = 0.2, opacity = 1.0, flammability = 0.2, conductivity = 0.1, value = 0`
- `bone.lua`: `density = 1900, hardness = 6, flexibility = 0.05, fragility = 0.3, absorbency = 0.0, opacity = 1.0, flammability = 0.05, conductivity = 0.1, value = 0`
- `organ.lua`: `density = 1050, hardness = 0.5, flexibility = 0.9, fragility = 0.8, absorbency = 0.7, opacity = 1.0, flammability = 0.3, conductivity = 0.1, value = 0`
- `tooth_enamel.lua`: `density = 2900, hardness = 5, flexibility = 0.0, fragility = 0.4, absorbency = 0.0, opacity = 1.0, flammability = 0.0, conductivity = 0.1, max_edge = 4, value = 0`
- `keratin.lua`: `density = 1300, hardness = 3, flexibility = 0.2, fragility = 0.3, absorbency = 0.0, opacity = 1.0, flammability = 0.3, conductivity = 0.1, max_edge = 3, value = 0`

Add `max_edge` property to tooth_enamel and keratin (combat-specific; other materials may not have it — the combat engine defaults to 0 for materials without `max_edge`).

**Flanders instructions — weapon combat metadata:**

Add `combat` table to `silver-dagger.lua`:
```lua
combat = {
    type = "edged",
    force = 5,
    message = "slashes",
    two_handed = false,
},
```

Add `combat` table to `knife.lua`:
```lua
combat = {
    type = "edged",
    force = 4,
    message = "cuts",
    two_handed = false,
},
```

The weapon's `material` field already exists — the combat engine reads material properties from the material registry.

**Nelson instructions — combat test scaffolding:**

*test-tissue-materials.lua:*
- For each tissue material (`skin`, `hide`, `bone`, `organ`, `tooth_enamel`, `keratin`): test that `engine.materials.get('flesh')` (and each material name) returns a non-nil table.
- **Explicit registry integration test:** Call `require("engine.materials").get("flesh")` — if it returns `nil`, the test must fail with a clear message: `"Material 'flesh' not found in registry — check src/meta/materials/flesh.lua exists and materials/init.lua auto-discovers it"`. This is NOT a load error — it's a registry resolution failure.
- Validate `density` and `hardness` are numbers for each material.
- Validate `max_edge` exists on `tooth_enamel` and `keratin`.

---

### WAVE-5: Combat Engine (Resolution Layer)

**Goal:** The combat exchange FSM exists and correctly resolves material-based damage. Narration templates generate varied text.

**Depends on:** GATE-4 pass (body_tree and tissue materials validate)

| Task | Agent | Files Created/Modified | TDD Test File | Scope |
|------|-------|----------------------|---------------|-------|
| Combat exchange FSM | Bart | **CREATE** `src/engine/combat/init.lua` | `test/combat/test-exchange-fsm.lua` (Nelson) | Large |
| Material damage resolution | Bart | (inside `combat/init.lua`) | `test/combat/test-material-damage.lua` (Nelson) | Large |
| Combat narration | Bart | **CREATE** `src/engine/combat/narration.lua` | `test/combat/test-combat-narration.lua` (Nelson) | Medium |
| Combat FSM tests | Nelson | **CREATE** `test/combat/test-exchange-fsm.lua`, `test/combat/test-material-damage.lua`, `test/combat/test-combat-narration.lua` | — | Large |

**File ownership (no overlap):**
- Bart: `src/engine/combat/init.lua`, `src/engine/combat/narration.lua` (REQUIRED split — init.lua is FSM + damage, narration.lua is text generation)
- Nelson: all test files in `test/combat/`

**Bart instructions — engine/combat/init.lua + engine/combat/narration.lua (~350–400 lines total):**

This is the core combat engine, split into two files:
- `combat/init.lua`: FSM phases, damage resolution, initiative, main entry points
- `combat/narration.lua`: Template-based narration generation, severity vocabulary, darkness variants

Both must be generic (Principle 8). `init.lua` requires `narration.lua` internally.

Module structure:
```lua
local M = {}

-- Severity levels
M.SEVERITY = { DEFLECT = 0, GRAZE = 1, HIT = 2, SEVERE = 3, CRITICAL = 4 }

-- Combat FSM states
M.PHASE = { INITIATE = 1, DECLARE = 2, RESPOND = 3, RESOLVE = 4, NARRATE = 5, UPDATE = 6 }

function M.initiate(attacker, defender) -> turn_order
function M.declare(attacker, combat_metadata) -> action
function M.respond(defender, combat_metadata, attack) -> response
function M.resolve(attacker, defender, weapon, target_zone, response) -> result
function M.narrate(result, light_level) -> text
function M.update(result, context) -> messages, combat_over

-- Main entry point
function M.resolve_exchange(attacker, defender, weapon, target_zone, response, context) -> result
function M.run_combat(attacker, defender, context) -> outcome
```

**resolve_exchange() — the core function:**
Per `plans/combat-system-plan.md` Section 5.3:

1. **Zone selection:** If player targeted specific zone: 60% hit probability (miss → random adjacent zone). If random: weight by `body_tree` zone sizes.
2. **Layer penetration:** For each layer from outer to inner in `body_tree[zone].tissue`:
   - Look up material from material registry
   - Edged/pierce: `penetration = (force × weapon.max_edge) - (layer.hardness × thickness_factor)`. If positive: penetrate, reduce force. If not: stop.
   - Blunt: `transfer = force × (1.0 - layer.flexibility)`. Force continues at 80% through each layer.
3. **Severity mapping:** Based on deepest layer penetrated: no penetration = DEFLECT, skin only = GRAZE, flesh = HIT, bone = SEVERE, organ = CRITICAL.
4. **Defense modifier:** block (0.3×), dodge success (0×), dodge fail (1×), counter (1× + attacker takes hit), flee success (0.5×), flee fail (1.2×).

**Force calculation:**
```
FORCE = weapon_density × size_modifier × quality_modifier
size_modifiers = { tiny = 0.5, small = 1.0, medium = 2.0, large = 4.0, huge = 8.0 }
```
For natural weapons: use the weapon's `force` field directly × size_modifier.

**Narration generation (in `combat/narration.lua`):**
- Template: `"{attacker_name} {action_verb} {target_name}'s {body_zone}, {result_description}"`
- Severity scales vocabulary (see combat plan Section 4.5)
- Darkness mode: switch to auditory/tactile descriptions
- Must not repeat exact same text — use severity + material + zone to vary output

**Initiative:**
- Compare `combat.speed` values. Faster acts first. Ties: smaller creature first. Still tied: player first.

**Nelson instructions — WAVE-5 narration variety test (C7):**
- In `test/combat/test-combat-narration.lua`: Run 3 combat exchanges with fixed seed (`math.randomseed(42)`). Assert ≥3 unique narration templates across exchanges. Templates must vary by severity + material + zone combination. If fewer than 3 unique strings are produced, fail with message showing actual outputs.

---

### WAVE-5.5: Hybrid Stance Combat Model (B1)

**Context:** Wayne decided combat uses auto-resolve by stance, NOT per-exchange player input. This replaces the RESPOND phase's per-exchange prompts for MOST rounds.

**Hybrid stance model (implemented in WAVE-6 by Smithers, engine support in WAVE-5 by Bart):**

1. **Player sets stance before combat round:** `aggressive`, `defensive`, or `balanced`
   - Aggressive: +30% attack force, -30% defense modifier, counter on natural 20
   - Defensive: -30% attack force, +30% defense modifier, auto-dodge on natural 1
   - Balanced: no modifiers (default)

2. **Rounds auto-resolve using stance + creature behavior:**
   - Each round: attacker declares (from stance/behavior), defender responds (from stance/behavior), engine resolves
   - No player input between rounds — combat flows automatically
   - Creature behavior (`attack_pattern`, `defense`, `flee_threshold`) drives creature side

3. **System INTERRUPTS and re-prompts when any of these occur:**
   - Weapon breaks (material failure during resolve)
   - Armor fails (tissue layer fully penetrated for first time)
   - Stance ineffective for 2+ consecutive rounds (DEFLECT results twice = stance isn't working)
   - Creature enters flee state (morale break)
   - Player or creature health drops below 30%
   - Any significant state change (light change, new creature enters)

4. **At interrupt points, player chooses:**
   - New stance (aggressive/defensive/balanced)
   - Flee (triggers flee mechanic)
   - Target specific zone (next round only, then reverts to stance-based)
   - Use item (drink potion, switch weapon)

**Bart (WAVE-5):** Add stance modifiers to `resolve_exchange()`. Add `interrupt_check(result, combat_state) -> interrupt_reason|nil` function that evaluates whether to break auto-resolve.

**Smithers (WAVE-6):** Implement stance prompt before combat round. Implement auto-resolve loop that calls `combat.resolve_exchange()` repeatedly until `interrupt_check()` returns non-nil. Print round-by-round narration. On interrupt: print interrupt reason, re-prompt for stance/action. In `--headless` mode: auto-select `balanced` stance, never interrupt (run combat to completion).

---

### WAVE-6: Combat Integration (Verb + Loop Layer)

**Goal:** Player can fight the rat with held weapons. Full combat encounter from attack through resolution to death/flee.

**Depends on:** GATE-5 pass (combat FSM and damage resolution work)

| Task | Agent | Files Created/Modified | TDD Test File | Scope |
|------|-------|----------------------|---------------|-------|
| Attack verb → combat FSM | Smithers | **MODIFY** `src/engine/verbs/init.lua` | `test/combat/test-combat-verbs.lua` (Nelson) | Medium |
| Stance prompt + interrupt detection | Smithers | **MODIFY** `src/engine/verbs/init.lua` | (same test file) | Medium |
| Flee mechanic | Smithers | **MODIFY** `src/engine/verbs/init.lua` | (same test file) | Medium |
| Combat → injury integration | Bart | **MODIFY** `src/engine/combat/init.lua` | `test/combat/test-combat-injury.lua` (Nelson) | Medium |
| Creature death mutation | Bart | **MODIFY** `src/engine/combat/init.lua` | (same test file) | Medium |
| Combat in darkness rules | Bart | **MODIFY** `src/engine/combat/init.lua` | `test/combat/test-combat-darkness.lua` (Nelson) | Small |
| Combat loop integration | Bart | **MODIFY** `src/engine/loop/init.lua` | (covered by integration tests) | Small |
| Combat integration tests | Nelson | **CREATE** `test/combat/test-combat-verbs.lua`, `test/combat/test-combat-injury.lua`, `test/combat/test-combat-darkness.lua`, `test/integration/test-combat-integration.lua` | — | Large |
| Combat architecture docs | Brockman | **CREATE** `docs/architecture/combat/body-zone-system.md`, `docs/architecture/combat/combat-fsm.md`, `docs/architecture/combat/damage-resolution.md`, `docs/architecture/combat/combat-narration.md`, `docs/design/combat-system.md` | — | Medium |

**File ownership (no overlap):**
- Smithers: `src/engine/verbs/init.lua` (ALL verb-level entry points live here; calls `combat.run_combat()` from Bart's module)
- Bart: `src/engine/combat/init.lua`, `src/engine/combat/narration.lua`, `src/engine/loop/init.lua`
- Brockman: `docs/architecture/combat/body-zone-system.md`, `docs/architecture/combat/combat-fsm.md`, `docs/architecture/combat/damage-resolution.md`, `docs/architecture/combat/combat-narration.md`, `docs/design/combat-system.md`
- Nelson: all test files

**Ownership clarification (C4):** Bart creates `src/engine/combat/init.lua` (combat FSM engine) and `src/engine/combat/narration.lua` (combat narration). Smithers owns ALL verb handlers in `src/engine/verbs/`. The combat verb-level entry point goes in `verbs/init.lua` (Smithers), which calls `combat.run_combat()` (Bart's module). `src/engine/verbs/combat.lua` is Bart's stimulus emission file (small edits in WAVE-3), NOT a verb handler.

**Smithers instructions — verb extensions:**

*Attack verb refactor:*
- Replace WAVE-3's direct-damage attack with combat FSM entry:
- `attack rat` → `combat.run_combat(player, creature, context)` which runs the 6-phase FSM
- `attack rat head` → pass `target_zone = "head"` to combat FSM
- Detect held weapon: check `player.hands[1]` and `player.hands[2]` for objects with `combat` table
- If no weapon: use player's natural weapons (punch/kick)
- Register attack aliases: `attack`, `hit`, `strike`, `swing`, `fight`

*Stance prompt + auto-resolve loop (replaces per-exchange defensive prompts):*
- Before combat round, prompt player for stance:
  ```
  Combat stance? > aggressive | defensive | balanced
  ```
- Read stance choice via `io.read()` (same pattern as main game input)
- In `--headless` mode: auto-select `balanced` stance
- Run auto-resolve loop: call `combat.resolve_exchange()` repeatedly, printing round-by-round narration
- After each exchange, call `combat.interrupt_check()` — if non-nil, break auto-resolve and re-prompt:
  ```
  [INTERRUPT: Your weapon cracks!]
  Combat stance? > aggressive | defensive | balanced | flee | use [item]
  ```
- Interrupt options include: new stance, flee, target specific zone (next round only), use item

*Combat sub-loop integration (C3):*
- Combat sub-loop runs INSIDE the main game loop. `combat.run_combat()` returns control to the game loop after combat ends (all rounds resolved or player flees).
- Stance prompt uses same `io.read()` pattern as main input.
- In `--headless` mode: auto-select `balanced` stance, never interrupt (run combat to completion).
- Combat does NOT create a separate input loop — it's a verb handler that happens to call `io.read()` for stance selection.

*Flee mechanic:*
- At any stance prompt or interrupt point, player can type `flee` or `flee [direction]`
- Success check: player speed vs creature speed, modified by leg injuries
- On success: partial damage (50%), player moves rooms, combat ends
- On failure: full damage (120% modifier), player stays, loses defensive action

**Bart instructions — combat integration:**

*Combat → injury:*
- In `combat/init.lua` UPDATE phase, call `injuries.inflict()`:
  ```lua
  local injury_type = map_severity_to_injury(severity, weapon_type)
  local damage = calculate_injury_damage(severity, force_remaining)
  injuries.inflict(target, injury_type, weapon_id, zone_id, damage)
  ```
- Severity mapping: GRAZE → "minor-cut", HIT → "bleeding", SEVERE → "bleeding" (high damage), CRITICAL+vital → fatal

*Creature death mutation:*
- When creature health ≤ 0 after combat: transition FSM to `dead` state
- The `dead` state already sets `animate = false`, `portable = true` (defined in WAVE-1)
- Emit `creature_died` stimulus for other creatures
- Print death narration from creature's `dead` state description

*Combat in darkness:*
- Check `context.current_room.light_level` (or equivalent)
- If dark: no targeted attacks (all random zone selection), narration uses sound/feel templates
- If light: normal combat with targeting

*Loop integration:*
- If `context.combat_active` is set during verb dispatch, skip normal post-command ticks until combat resolves
- Combat runs as a sub-loop within the verb handler (not a separate game loop)

**Brockman instructions — combat architecture docs (5 files, all in `docs/`):**

Brockman runs in parallel with Nelson's LLM testing — no file conflicts (docs/ vs test/).

- `docs/architecture/combat/body-zone-system.md`: Document body_tree structure, zone selection weighted by size, vital flag meaning, tissue layer ordering from outer to inner.
- `docs/architecture/combat/combat-fsm.md`: Document the 6-phase combat FSM (INITIATE → DECLARE → RESPOND → RESOLVE → NARRATE → UPDATE). Cover: stance modifiers, interrupt detection, auto-resolve loop, initiative calculation.
- `docs/architecture/combat/damage-resolution.md`: Document layer penetration algorithm, force calculation, severity mapping (DEFLECT through CRITICAL), defense modifiers, material interaction math.
- `docs/architecture/combat/combat-narration.md`: Document template system in `combat/narration.lua`. Cover: severity-scaled vocabulary, darkness variants, variety guarantees, template selection by severity + material + zone.
- `docs/design/combat-system.md`: Design-level overview of the combat system. Cover: hybrid stance model, auto-resolve with interrupts, creature combat behavior, weapon/armor interaction, injury integration, darkness combat, Phase 1 scope.

**Rule: No phase ships without its docs.** GATE-6 requires all 5 combat docs to exist and accurately describe the implemented system.

---

## Section 4: Testing Gates

### GATE-1: NPC Data Validation

**After:** WAVE-1 completes  
**Tests that must pass:**
- `lua test/creatures/test-creature-template.lua` — all assertions green
- `lua test/creatures/test-rat-definition.lua` — all assertions green
- `lua test/creatures/test-flesh-material.lua` — all assertions green
- `lua test/run-tests.lua` — zero regressions in existing 113+ test files

**Pass/fail:** ALL tests pass, zero regressions. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)  
**Action on fail:** File issue, assign to Flanders (data fix) or Nelson (test fix), re-gate.

**On pass:** `git add -A && git commit -m "GATE-1: NPC Foundation data layer passed" && git push`

---

### GATE-2: NPC Engine Validation

**After:** WAVE-2 completes  
**Tests that must pass:**
- `lua test/creatures/test-creature-tick.lua` — all 12+ test cases green
- `lua test/run-tests.lua` — zero regressions

**Specific assertions:**
- Creature drives decay correctly over 5 ticks
- Fear spikes on stimulus, then decays back to 0
- Creature wanders to adjacent room within 10 ticks (probabilistic — run 50 trials)
- Creature flees when fear exceeds threshold
- Dead creature is skipped by tick
- Creature tick returns messages for player's room only
- **Performance budget (B5):** Creature tick completes in <50ms per cycle with 5 mock creatures. Nelson adds a perf assertion to `test-creature-tick.lua`: measure `os.clock()` before and after `creatures.tick(context)` with 5 creatures in registry, assert elapsed < 0.05 seconds.

**Pass/fail:** ALL tests pass, zero regressions, perf budget met. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)

**On pass:** `git add -A && git commit -m "GATE-2: NPC Engine behavior layer passed" && git push`

---

### GATE-3: NPC Phase 1 Complete (Full LLM Walkthrough)

**After:** WAVE-3 completes  
**Tests that must pass:**
- `lua test/creatures/test-creature-verbs.lua` — all assertions green
- `lua test/creatures/test-stimulus.lua` — all assertions green
- `lua test/creatures/test-rat-room.lua` — all assertions green
- `lua test/integration/test-npc-integration.lua` — all assertions green
- `lua test/run-tests.lua` — zero regressions

**Documentation deliverables that must exist:**
- `docs/architecture/engine/creature-system.md`
- `docs/architecture/engine/stimulus-system.md`
- `docs/architecture/engine/creature-template.md`
- `docs/design/npc-system.md`

**Nelson LLM walkthrough scenario (headless):**
```
Scenario: "Discover and interact with the rat"
1. Start game → look (darkness, can't see rat)
2. listen → hear "skittering claws" (rat's on_listen presence)
3. feel rat → "Coarse, greasy fur... It bites." (injury inflicted)
4. [light candle via existing gameplay]
5. look → see "A rat crouches in the shadows" (room presence)
6. examine rat → full description
7. smell rat → musty rodent description
8. grab rat → catch attempt → injury from bite OR rat escapes
9. wait 3 turns → rat wanders to adjacent room (behavior system)
10. [move to adjacent room] → rat is present
11. attack rat → rat takes damage, flees
12. chase rat → player follows rat to next room
```

**Pass/fail:** ALL unit tests pass. LLM walkthrough completes all 12 steps without errors. All 4 NPC docs exist. Zero regressions. Binary.  
**Reviewer:** Bart (architecture), Nelson (LLM execution + gate signer), Marge (test sign-off)

**On pass:** `git add -A && git commit -m "GATE-3: NPC Phase 1 complete — LLM walkthrough + docs" && git push`

---

### GATE-4: Combat Data Validation

**After:** WAVE-4 completes  
**Tests that must pass:**
- `lua test/combat/test-body-tree.lua` — body_tree validates on rat and player
- `lua test/combat/test-player-body.lua` — player has correct zones
- `lua test/combat/test-tissue-materials.lua` — all 6 tissue materials resolve through material registry
- `lua test/combat/test-weapon-metadata.lua` — dagger and knife have combat tables
- `lua test/run-tests.lua` — zero regressions (NPC Phase 1 tests still pass)

**Pass/fail:** ALL tests pass, zero regressions. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)

**On pass:** `git add -A && git commit -m "GATE-4: Combat Foundation data layer passed" && git push`

---

### GATE-5: Combat Engine Validation

**After:** WAVE-5 completes  
**Tests that must pass:**
- `lua test/combat/test-exchange-fsm.lua` — FSM transitions through all 6 phases
- `lua test/combat/test-material-damage.lua` — damage resolution produces correct severities
- `lua test/combat/test-combat-narration.lua` — narration varies by severity/material/zone, ≥3 unique templates across 3 fixed-seed exchanges
- `lua test/run-tests.lua` — zero regressions

**Specific assertions:**
- Steel dagger vs. unarmored rat = CRITICAL (instant kill per combat plan Section 5.4)
- Rat bite vs. bare hand = HIT (pierces skin and flesh, stopped at bone)
- Wooden club vs. ceramic pot = pot cracks, blunt force transfers
- DEFLECT severity generates "glances off" vocabulary
- CRITICAL severity generates "severs"/"eviscerates" vocabulary
- Darkness narration uses sound/feel instead of visual
- Narration variety: 3 exchanges with `math.randomseed(42)` produce ≥3 unique narration strings (C7)

**Pass/fail:** ALL tests pass, zero regressions. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)

**On pass:** `git add -A && git commit -m "GATE-5: Combat Engine resolution layer passed" && git push`

---

### GATE-6: Combat Phase 1 Complete (Full LLM Walkthrough)

**After:** WAVE-6 completes  
**Tests that must pass:**
- `lua test/combat/test-combat-verbs.lua` — all assertions green
- `lua test/combat/test-combat-injury.lua` — all assertions green
- `lua test/combat/test-combat-darkness.lua` — all assertions green
- `lua test/integration/test-combat-integration.lua` — all assertions green
- `lua test/run-tests.lua` — zero regressions (ALL prior tests still pass)

**Documentation deliverables that must exist:**
- `docs/architecture/combat/body-zone-system.md`
- `docs/architecture/combat/combat-fsm.md`
- `docs/architecture/combat/damage-resolution.md`
- `docs/architecture/combat/combat-narration.md`
- `docs/design/combat-system.md`

**Nelson LLM walkthrough scenario (headless):**
```
Scenario: "Full combat encounter with the rat"
1. [Find and equip silver dagger via existing gameplay]
2. Enter room with rat → rat reacts (fear spike)
3. attack rat → stance prompt appears → select aggressive
4. Rounds auto-resolve → material resolution → damage narration per round
5. Rat retaliates → rat bites player → injury inflicted
6. [Interrupt if weapon breaks / stance ineffective 2+ rounds]
7. Player stance + dagger vs rat body → CRITICAL → rat dies
8. look → dead rat on floor
9. take rat → dead rat is portable

Scenario: "Combat in darkness"
10. [No light source]
11. attack rat → all attacks random zone, sound-only narration
12. "You hear scrabbling claws and swing blindly"

Scenario: "Flee from combat"
13. attack rat → combat starts → stance prompt
14. [At interrupt or initial stance prompt] flee north → success check → player escapes with glancing blow
```

**Pass/fail:** ALL unit tests pass. ALL LLM scenarios complete. All 5 combat docs exist. Zero regressions. Binary.  
**Reviewer:** Bart (architecture), Nelson (LLM execution + gate signer), Marge (test sign-off)

**On pass:** `git add -A && git commit -m "GATE-6: Combat Phase 1 complete — LLM walkthrough + docs" && git push`

---

## Section 5: NPC Phase 1 Breakdown

| # | Task | Owner | Files | Depends On | Wave |
|---|------|-------|-------|-----------|------|
| N1 | Creature template | Flanders | `src/meta/templates/creature.lua` | — | WAVE-1 |
| N2 | Rat object definition | Flanders | `src/meta/creatures/rat.lua` | — | WAVE-1 |
| N3 | Flesh material | Flanders | `src/meta/materials/flesh.lua` | — | WAVE-1 |
| N4 | Creature tick engine | Bart | `src/engine/creatures/init.lua` | N1 (template defines API) | WAVE-2 |
| N5 | Game loop integration | Bart | `src/engine/loop/init.lua` (modify) | N4 | WAVE-2 |
| N6 | Stimulus system | Bart | `movement.lua`, `combat.lua`, `effects.lua`, `fsm/init.lua` (modify) | N4 | WAVE-3 |
| N7 | catch verb | Smithers | `src/engine/verbs/init.lua` (modify) | N4 | WAVE-3 |
| N8 | chase verb | Smithers | `src/engine/verbs/init.lua` (modify) | N4, N7 | WAVE-3 |
| N9 | Attack creature (simple) | Smithers | `src/engine/verbs/init.lua` (modify) | N4 | WAVE-3 |
| N10 | Room presence for creatures | Smithers | `src/engine/verbs/init.lua` (modify) | N4 | WAVE-3 |
| N11 | Rat room placement | Moe | `src/meta/world/cellar.lua` (modify) | N2 | WAVE-3 |
| N12 | NPC test suite | Nelson | `test/creatures/*.lua`, `test/integration/test-npc-integration.lua` | N1-N11 | WAVE-1,2,3 |
| N13 | NPC architecture docs | Brockman | `docs/architecture/engine/creature-system.md`, `docs/architecture/engine/stimulus-system.md`, `docs/architecture/engine/creature-template.md`, `docs/design/npc-system.md` | N1-N11 | WAVE-3 |

---

## Section 6: Combat Phase 1 Breakdown

| # | Task | Owner | Files | Depends On | Wave |
|---|------|-------|-------|-----------|------|
| C1 | body_tree on rat | Flanders | `src/meta/creatures/rat.lua` (modify) | GATE-3 (NPC complete) | WAVE-4 |
| C2 | body_tree on player | Flanders | `src/main.lua` (player table, lines ~305-324) (modify) | — | WAVE-4 |
| C3 | Tissue materials (6) | Flanders | `src/meta/materials/{skin,hide,bone,organ,tooth_enamel,keratin}.lua` | — | WAVE-4 |
| C4 | Weapon combat metadata | Flanders | `src/meta/objects/{silver-dagger,knife}.lua` (modify) | — | WAVE-4 |
| C5 | Combat exchange FSM | Bart | `src/engine/combat/init.lua` | C1-C4 (data layer) | WAVE-5 |
| C6 | Material damage resolution | Bart | `src/engine/combat/init.lua` | C3 (materials) | WAVE-5 |
| C7 | Combat narration | Bart | `src/engine/combat/narration.lua` (REQUIRED separate file) | C5, C6 | WAVE-5 |
| C8 | Attack verb → combat FSM | Smithers | `src/engine/verbs/init.lua` (modify) | C5 | WAVE-6 |
| C9 | Stance prompt + interrupt detection | Smithers | `src/engine/verbs/init.lua` (modify) | C5 | WAVE-6 |
| C10 | Flee mechanic | Smithers | `src/engine/verbs/init.lua` (modify) | C5 | WAVE-6 |
| C11 | Combat → injury integration | Bart | `src/engine/combat/init.lua` (modify) | C5 | WAVE-6 |
| C12 | Creature death mutation | Bart | `src/engine/combat/init.lua` (modify) | C5, N4 | WAVE-6 |
| C13 | Combat in darkness | Bart | `src/engine/combat/init.lua` (modify) | C5 | WAVE-6 |
| C14 | Combat loop integration | Bart | `src/engine/loop/init.lua` (modify) | C5 | WAVE-6 |
| C15 | Combat test suite | Nelson | `test/combat/*.lua`, `test/integration/test-combat-integration.lua` | C1-C14 | WAVE-4,5,6 |
| C16 | Combat architecture docs | Brockman | `docs/architecture/combat/body-zone-system.md`, `docs/architecture/combat/combat-fsm.md`, `docs/architecture/combat/damage-resolution.md`, `docs/architecture/combat/combat-narration.md`, `docs/design/combat-system.md` | C1-C14 | WAVE-6 |

---

## Section 7: Cross-Plan Integration Points

### Interfaces NPC Phase 1 Must Expose for Combat Phase 1

| Interface | Module | Used By |
|-----------|--------|---------|
| `creatures.get_creatures_in_room(registry, room_id)` | `engine/creatures/init.lua` | Combat FSM (find attacker/defender) |
| `creatures.emit_stimulus(room_id, type, data)` | `engine/creatures/init.lua` | Combat UPDATE phase (emit `creature_attacked`, `creature_died`) |
| `creature.health` / `creature.max_health` | rat.lua, creature template | Combat damage application |
| `creature.alive` / `creature.animate` | rat.lua, creature template | Combat entry validation |
| `creature._state` | rat.lua FSM | Combat checks creature state (already fleeing?) |
| `creature.behavior.flee_threshold` | rat.lua | Combat morale check (flee when health low) |

### Interfaces Combat Phase 1 Consumes

| Consumer | Interface | Provider |
|----------|-----------|----------|
| Combat FSM | `injuries.inflict(target, type, source, location, damage)` | `engine/injuries.lua` (existing) |
| Combat FSM | `injuries.compute_health(target)` | `engine/injuries.lua` (existing) |
| Damage resolution | `materials.get(name)` | `engine/materials/init.lua` (existing) |
| Zone selection | `creature.body_tree[zone]` | rat.lua / player model (WAVE-4) |
| Weapon properties | `weapon.combat.type`, `weapon.material` | weapon object files (WAVE-4) |
| Death mutation | `creature.states.dead` | rat.lua FSM states (WAVE-1) |

### Registry Query Patterns for Combat

```lua
-- Find creature by keyword (existing)
local creature = context.registry:find_by_keyword("rat")

-- Check if target is a creature
if creature and creature.animate then ... end

-- Get all creatures in current room (new function from WAVE-2)
local creatures_here = creatures.get_creatures_in_room(context.registry, context.current_room.id)

-- Get weapon from player's hand
local weapon = context.player.hands[1]
local weapon_combat = weapon and weapon.combat or nil
```

---

## Section 8: Nelson LLM Test Scenarios

**Determinism rule (C6):** All LLM walkthroughs seed `math.randomseed(42)` via `--headless` mode. Wander behavior must trigger within 5 ticks. If a probabilistic test fails, re-run with seed 43, then 44, before declaring failure. Three consecutive failures across different seeds = genuine bug.

### GATE-1 Scenario: Data Validation
```
# No LLM walkthrough — unit tests only.
# Validate: template loads, rat loads, flesh resolves.
```

### GATE-2 Scenario: Creature Tick
```
# No LLM walkthrough — unit tests only.
# Validate: drives decay, stimuli fire, actions execute.
```

### GATE-3 Scenario: NPC Phase 1 Complete

**Scenario A: "Rat Discovery in Darkness"**
```bash
echo "listen\nfeel rat\nlook\nsmell rat" | lua src/main.lua --headless
```
Expected: hear skittering, feel fur + get bitten, can't see (dark), smell musty rodent.

**Scenario B: "Rat Interaction with Light"**
```bash
echo "take matchbox\nopen matchbox\ntake match\nlight match\nlight candle\nlook\nexamine rat\ngrab rat" | lua src/main.lua --headless
```
Expected: light candle → see rat in room → examine shows full description → grab attempt → bite injury OR escape.

**Scenario C: "Rat Behavior Over Time"**
```bash
echo "look\nwait\nwait\nwait\nwait\nwait\nlook" | lua src/main.lua --headless
```
Expected: rat may wander away between waits (probabilistic). Room presence changes.

**Scenario D: "Attack and Chase"**
```bash
echo "attack rat\nlook\nchase rat\nlook" | lua src/main.lua --headless
```
Expected: rat takes damage → rat flees → player follows → rat is in new room.

### GATE-4 Scenario: Combat Data
```
# No LLM walkthrough — unit tests only.
# Validate: body_tree on rat and player, materials resolve, weapons have combat table.
```

### GATE-5 Scenario: Combat Engine
```
# No LLM walkthrough — unit tests only.
# Validate: FSM transitions, damage calculation, narration generation.
```

### GATE-6 Scenario: Combat Phase 1 Complete

**Scenario E: "Full Rat Combat with Weapon"**
```bash
echo "take silver dagger\nattack rat\ndodge\nattack rat\nlook\ntake rat" | lua src/main.lua --headless
```
Expected: combat FSM runs → rat bites → player dodges → player kills rat → dead rat on floor → pick up dead rat.

**Scenario F: "Combat in Darkness"**
```bash
echo "attack rat\ndodge" | lua src/main.lua --headless
```
Expected: no zone targeting, sound-based narration ("You swing blindly...").

**Scenario G: "Flee from Combat"**
```bash
echo "attack rat\nflee north" | lua src/main.lua --headless
```
Expected: combat starts → player flees → glancing blow → player in adjacent room.

**Scenario H: "Unarmed Combat"**
```bash
echo "attack rat\ndodge\nattack rat" | lua src/main.lua --headless
```
Expected: player uses punch/kick natural weapons → low damage → multiple exchanges needed.

---

## Section 9: TDD Test File Map

Every new engine module has its test file written FIRST (or alongside). Tests use the existing pure-Lua test framework (`test/parser/test-helpers.lua`).

### NPC Phase 1 Tests

| Engine Module | Test File | Written In | Key Assertions |
|---------------|-----------|-----------|----------------|
| `src/meta/templates/creature.lua` | `test/creatures/test-creature-template.lua` | WAVE-1 | Fields exist, types correct, `animate == true` |
| `src/meta/creatures/rat.lua` | `test/creatures/test-rat-definition.lua` | WAVE-1 | All drives, reactions, states defined; size is string |
| `src/meta/materials/flesh.lua` | `test/creatures/test-flesh-material.lua` | WAVE-1 | Material resolves, density/hardness are numbers |
| `src/engine/creatures/init.lua` | `test/creatures/test-creature-tick.lua` | WAVE-2 | 12+ test cases: drives, stimuli, actions, movement |
| Stimulus emission points | `test/creatures/test-stimulus.lua` | WAVE-3 | 5+ test cases: each stimulus type fires correctly |
| Verb handlers (catch/chase/attack) | `test/creatures/test-creature-verbs.lua` | WAVE-3 | 10+ test cases: catch, chase, attack, look, sensory |
| Rat room placement | `test/creatures/test-rat-room.lua` | WAVE-3 | Room loads with rat, rat resolves by keyword |
| Full NPC integration | `test/integration/test-npc-integration.lua` | WAVE-3 | Multi-command headless scenario |

### Combat Phase 1 Tests

| Engine Module | Test File | Written In | Key Assertions |
|---------------|-----------|-----------|----------------|
| body_tree (rat + player) | `test/combat/test-body-tree.lua` | WAVE-4 | Zones exist, sizes sum correctly, vital flags set |
| Player body_tree | `test/combat/test-player-body.lua` | WAVE-4 | Player has head/torso/arms/legs, correct tissue layers |
| Tissue materials (6) | `test/combat/test-tissue-materials.lua` | WAVE-4 | All 6 materials resolve, hardness/density are numbers |
| Weapon combat metadata | `test/combat/test-weapon-metadata.lua` | WAVE-4 | Dagger/knife have combat.type, combat.force |
| Combat exchange FSM | `test/combat/test-exchange-fsm.lua` | WAVE-5 | 6-phase transitions, initiative, declare, respond, resolve |
| Material damage resolution | `test/combat/test-material-damage.lua` | WAVE-5 | Steel vs flesh = CRITICAL, rat bite vs hand = HIT |
| Combat narration | `test/combat/test-combat-narration.lua` | WAVE-5 | Severity-scaled text, darkness variant, ≥3 unique templates across 3 fixed-seed exchanges (C7) |
| Attack verb + combat | `test/combat/test-combat-verbs.lua` | WAVE-6 | Attack triggers FSM, weapon detected from hands |
| Combat → injury | `test/combat/test-combat-injury.lua` | WAVE-6 | Severity maps to injury type, damage applied |
| Combat in darkness | `test/combat/test-combat-darkness.lua` | WAVE-6 | No targeting, sound narration |
| Full combat integration | `test/integration/test-combat-integration.lua` | WAVE-6 | Full rat fight headless scenario |

### Test Runner Integration

**WAVE-0 (pre-flight):** Bart adds BOTH directories to `test/run-tests.lua` before any test files exist:
```lua
repo_root .. SEP .. "test" .. SEP .. "creatures",
repo_root .. SEP .. "test" .. SEP .. "combat",
```

This is a 2-line change that must happen BEFORE WAVE-1 so that all subsequent test files are automatically discovered by the test runner.

---

## Section 10: Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| **File conflict between agents** | Medium | High | Explicit file ownership per wave. No two agents touch the same file in any wave. Coordinator enforces. |
| **Creature tick slows game loop** | Low | Medium | Spatial optimization: only full-tick creatures in player's room. Profile after GATE-2. |
| **NPC behavior feels robotic** | Medium | High | Random jitter on utility scores. Fear decay creates variation. Tune after GATE-3 LLM walkthrough. |
| **Combat damage balance is off** | Medium | Medium | Unit tests with known material pairs (steel vs flesh, rat bite vs hand). Tune constants after GATE-5. |
| **Existing tests regress** | Low | High | Run `lua test/run-tests.lua` at every gate. Zero-regression policy. |
| **Creature movement breaks room state** | Medium | Medium | Use existing registry location tracking. Test movement extensively in WAVE-2. |
| **Combat narration is repetitive** | Medium | Medium | Narration tests assert variety. Multiple templates per severity level. Tune after GATE-6. |
| **Stimulus emission misses an edge case** | Medium | Low | Test each stimulus type individually in WAVE-3. LLM walkthrough catches integration gaps. |
| **body_tree retrofit breaks existing rat behavior** | Low | Medium | WAVE-4 is additive (adds fields to existing rat.lua). NPC Phase 1 tests must still pass at GATE-4. |
| **WAVE-3 Smithers/Bart both modify verbs/init.lua** | PREVENTED | — | Smithers owns `verbs/init.lua`. Bart modifies `verbs/movement.lua`, `verbs/combat.lua`, `effects.lua`, `fsm/init.lua`. No overlap. |
| **Combat FSM complexity exceeds estimate** | Medium | Medium | Start with simplified 6-phase loop (not full FSM state machine). Phase transitions are function calls, not FSM metadata in WAVE-5. |
| **LLM walkthrough tests are flaky** | Medium | Low | Use deterministic seed for `math.random()` in headless mode. Repeat flaky tests 3x. |

---

## Section 11: Autonomous Execution Protocol

### Coordinator Execution Loop

```
FOR each WAVE in [WAVE-0, WAVE-1, WAVE-2, ..., WAVE-6]:

  1. SPAWN parallel agents per wave assignment table
     - Each agent gets: task description, exact files, TDD requirements
     - No two agents touch the same file
  
  2. COLLECT results from all agents
     - Check: all files created/modified as specified
     - Check: no unintended file changes (git diff --stat)
  
  3. RUN gate tests:
     lua test/run-tests.lua
     + wave-specific test files
     + LLM walkthrough (GATE-3 and GATE-6 only)
     + doc existence check (GATE-3 and GATE-6 only)
  
  4. EVALUATE gate:
     IF all tests pass AND zero regressions AND docs exist (where required):
       COMMIT: git add -A && git commit -m "GATE-N: {description}" && git push
       → PROCEED to next wave
     
     IF any test fails:
       FILE issue with failure details
       ASSIGN fix to the agent who owns the failing file
       RE-RUN gate after fix (re-gate tests ONLY the failed items, not the entire wave)
       IF gate fails 1x: ESCALATE to Wayne with diagnostic summary
       (Phase 1 policy — first implementation, diagnosis is harder with parallel work.
        Can relax to 2x-failure threshold once the pattern is proven.)
  
  5. NOTIFY Ralph (pipeline monitor) of wave completion
```

### Commit Pattern

One commit per wave, message format:
```
WAVE-N: {NPC/Combat} {layer name}

- {summary of what was created/modified}
- Tests: {count} new, 0 regressions

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

### Parallel Agent Constraints

- Maximum 4 agents per wave (practical limit)
- All agents in a wave start simultaneously
- No agent starts until the previous GATE passes
- If an agent finishes early, it DOES NOT start the next wave's work
- Inter-wave dependency is enforced by the coordinator, not by agents

### Escalation Protocol

| Condition | Action |
|-----------|--------|
| Gate fails once | File issue, assign fix agent (not original author if lockout applies), re-gate failed items only. **Escalate to Wayne with diagnostic summary.** |
| Agent produces unexpected file changes | Reject, re-run with stricter prompt |
| Regression in existing test | STOP all work. Fix regression first. |
| LLM walkthrough fails but unit tests pass | Integration gap. Bart diagnoses, assigns fix. |
| Missing documentation at GATE-3 or GATE-6 | Block gate. Assign Brockman to write missing docs. |

> **Phase 1 policy (C8):** Escalate to Wayne after 1x gate failure (not 2x) since this is the first NPC+Combat implementation and diagnosis is harder with parallel agent work. Can relax to 2x-failure threshold once the wave/gate pattern is proven.

### Wayne Check-In Points

Wayne only needs to be involved at:
1. **GATE-3** (NPC Phase 1 complete) — play-test the rat interaction
2. **GATE-6** (Combat Phase 1 complete) — play-test combat
3. **Any escalation** from the 1x-failure rule (Phase 1 policy)

Everything else runs autonomously.

---

## Section 12: Gate Failure Protocol

### Failure Handling Procedure

**Step 1: First failure**
- Coordinator files a GitHub issue with:
  - Which gate failed
  - Which specific test(s) failed
  - Full error output
  - Which agent's file is implicated
- Assign fix to the appropriate agent. If lockout applies (original author can't see the bug), assign to a different agent.
- Re-gate: run ONLY the failed test items, not the entire wave's test suite.
- **Escalate to Wayne** with a diagnostic summary (Phase 1 policy — 1x threshold).

**Step 2: Second failure (same test)**
- Escalate immediately to Wayne with full diagnostic:
  - Original failure details
  - Fix attempt details
  - Second failure output
  - Agent's analysis of root cause
- Wayne decides: retry with different agent, redesign approach, or skip/defer.

### Re-gating Rules

- Re-gating tests ONLY the failed items from the original gate run.
- All previously-passing tests are NOT re-run during re-gate (they already passed).
- After fix is applied, the specific failing test file(s) are run in isolation first.
- Then `lua test/run-tests.lua` is run once to confirm zero regressions from the fix.
- If re-gate passes: proceed to next wave. If re-gate fails: Step 2 above.

### Lockout Policy

- If an agent's code failed a gate, and the agent's second attempt also fails, that agent is locked out of fixing that specific issue.
- A fresh agent (or Bart for architecture issues) takes over the fix.
- This prevents "thrashing" where the same agent makes the same mistake repeatedly.
