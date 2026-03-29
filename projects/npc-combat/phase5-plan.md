# Phase 5 — Creature Intelligence Architecture Plan

**Author:** Bart (Architecture Lead)  
**Date:** 2026-08-17  
**Version:** v1.0  
**Status:** 🟢 READY — Architecture assessment complete  
**Requested By:** Wayne "Effe" Berry  
**Scope:** Engine changes for creature intelligence escalation  
**Baseline:** 266 test files passing, 5 creatures, 12 engine/creatures modules

---

## Section 1: Current State Assessment

### 1.1 Creature Engine Architecture (What Works Now)

The creature behavior engine (`src/engine/creatures/`) is a **12-module, metadata-driven system** that evaluates autonomous behavior for all `animate == true` objects. It already supports a rich behavior pipeline:

| Module | Status | Capability |
|--------|--------|------------|
| `init.lua` | ✅ Solid | Master tick, public API, module wiring |
| `actions.lua` | ✅ Solid | Utility scoring (6 action types) + execution |
| `stimulus.lua` | ✅ Solid | Global stimulus queue with distance-scaled reactions |
| `navigation.lua` | ✅ Solid | BFS distance, exit validation, NPC obstacle check |
| `territorial.lua` | ✅ Solid | Territory markers, BFS radius, marker response |
| `pack-tactics.lua` | ⚠️ Untestable at runtime | Alpha selection, attack stagger, retreat — but only 1 wolf exists |
| `predator-prey.lua` | ✅ Solid | Prey detection, priority-ordered target selection |
| `morale.lua` | ✅ Solid | Health-based morale checks, flee behavior |
| `death.lua` | ✅ Solid | D-14 reshape (creature → corpse metamorphosis) |
| `inventory.lua` | ✅ Solid | Creature inventory drop on death |
| `loot.lua` | ✅ Solid | 4-pattern probabilistic loot (always, weighted, variable, conditional) |
| `respawn.lua` | ✅ Solid | Timer-based respawn with population cap |

### 1.2 Creature Tick Pipeline (Current Flow)

```
creature_tick(context, creature)
  │
  ├─ 0.  Skip if dead or !animate
  ├─ 0a. Territorial: reduce fear in home territory
  ├─ 0b. Territory marking: place marker on room entry
  ├─ 0c. Foreign marker response: challenge or avoid
  ├─ 0d. Pack retreat: flee if health < 20%
  │
  ├─ 1.  Update drives (hunger grows, fear decays, curiosity rises)
  │
  ├─ 2.  Process stimuli → match reactions → apply drive deltas
  ├─ 2a. Bait check (food lure behavior)
  ├─ 2b. Ambush check (hide until trigger)
  ├─ 2c. Web ambush check (spider metadata — Principle 8)
  │
  ├─ 3.  Score actions (utility scoring + random jitter)
  │      ├─ idle (base 10)
  │      ├─ wander (curiosity × 0.3 + wander_chance × 0.2)
  │      ├─ flee (fear × 1.5, if fear ≥ threshold)
  │      ├─ vocalize (partial fear + curiosity)
  │      ├─ attack (aggression × 0.5 + hunger × 0.5, if prey present)
  │      └─ create_object (priority score, if creates_object declared)
  │
  └─ 4.  Execute highest-scoring action
         └─ Pack stagger: only alpha attacks this turn
```

### 1.3 Five Creatures — Inventory

| Creature | Size | HP | Aggression | Territorial | Prey | FSM States | Unique Behaviors |
|----------|------|----|-----------|-------------|------|------------|------------------|
| **Rat** | tiny | 5 | 5 | ✗ | — | idle, wander, flee, dead | Nocturnal, food scavenger |
| **Wolf** | medium | 22 | 70 | ✓ (hallway) | player, rat, cat, bat | idle, wander, patrol, aggressive, flee, dead | Territory marking, lingering scent, pack_size=1 ← **BUG** |
| **Spider** | tiny | 3 | 10 | ✗ | — | idle, web-building, flee, dead | Web creation, web ambush (conditional function) |
| **Cat** | small | 15 | 40 | ✗ | rat | idle, wander, hunt, flee, dead | Predator-prey (hunts rats) |
| **Bat** | tiny | 3 | 5 | ✗ | — | roosting, flying, flee, dead | Light-reactive, ceiling roosting |

### 1.4 Respawn System — Already Supports Multi-Instance

The respawn module (`respawn.lua`) already handles `max_population` per creature type per room. When a creature dies and respawns, it creates a fresh GUID instance. The wolf declares `max_population = 3` but only 1 wolf is placed in the hallway room definition. **The engine already supports multiple wolves — it's the world data that's limited.**

### 1.5 Pack Tactics — Already Implemented, Never Exercised

`pack-tactics.lua` has 4 functions ready:
- `select_alpha(pack)` — highest HP, tie-break by max_health
- `plan_attack(pack)` — alpha at delay 0, others stagger +1 each
- `should_retreat(creature)` — flee if health < 20%
- `get_pack_in_room(registry, room_id, creature)` — finds same-`id` creatures

The creature tick (`init.lua` lines 322-331) already checks for pack stagger on attack. **This code works — it just never fires because there's only 1 wolf.**

---

## Section 2: Gap Analysis

### 2.1 Issue #315 — Pack Tactics Untestable (Only 1 Wolf)

**Root cause:** `hallway.lua` places exactly 1 wolf instance. Wolf's `respawn.max_population = 3` would allow more, but respawn only fires after a wolf dies. The game starts with 1 wolf. Pack tactics code is dead code at runtime.

**Fix:** Place 2-3 wolf instances in the hallway room definition. This is a **Moe** change (room data, `src/meta/rooms/hallway.lua`) plus a **Flanders** review (creature metadata confirms combat.behavior.pack_size should match actual placement).

**Engine change needed:** None. The engine already handles multi-instance packs.

### 2.2 Pack Coordination Gaps

Current pack logic is minimal:
- ✅ Alpha selection (health-based)
- ✅ Attack stagger (alpha first, others wait 1 turn)
- ✅ Defensive retreat (health < 20%)
- ❌ No role differentiation (Alpha/Beta/Omega)
- ❌ No shared threat state (pack members don't communicate danger)
- ❌ No coordinated flee (one wolf flees, others don't know)
- ❌ No pack morale (alpha death doesn't demoralize pack)

### 2.3 Territorial Behavior Gaps

Current territorial system works but is limited:
- ✅ Territory marking (invisible scent markers)
- ✅ Foreign marker response (challenge/avoid based on aggression)
- ✅ BFS radius territory calculation
- ❌ No intrusion detection (creature doesn't know when player enters territory)
- ❌ No escalating response (first warning → growl → attack)
- ❌ No territory handoff (if alpha dies, pack doesn't inherit territory)

### 2.4 Ambush Mechanics Gaps

Current ambush system:
- ✅ `behavior.ambush` with proximity trigger
- ✅ `behavior.web_ambush` with conditional function (spider)
- ✅ `_ambush_sprung` flag prevents re-triggering
- ❌ No hide/reveal cycle (creature can't re-hide after combat)
- ❌ No surprise damage bonus
- ❌ No ambush narration escalation (setup → wait → spring)
- ❌ No group ambush (pack sets ambush together)

### 2.5 Action Scoring Gaps

Current scoring has 6 actions. Missing for intelligence escalation:
- ❌ No `guard` action (hold position, block exit)
- ❌ No `stalk` action (follow player at distance)
- ❌ No `call_pack` action (howl to summon nearby pack members)
- ❌ No `retreat_to_territory` action (fall back to home ground when losing)

---

## Section 3: Proposed Implementation Waves

### Design Constraints (Scope for TODAY)

Wayne wants to complete Phase 5 today. Given the existing engine infrastructure, this is feasible because:
1. Pack tactics engine already exists — it needs activation, not creation
2. Territorial system already exists — it needs escalation hooks
3. Ambush system already exists — it needs a damage multiplier
4. The respawn system already supports multi-instance creatures

**Total estimated scope:** ~300-400 LOC engine changes + ~100 LOC metadata changes + ~150 LOC tests

---

### WAVE-1: Multi-Instance Creatures (Fix #315)

**Goal:** Enable pack tactics to fire at runtime by placing multiple wolves.

**Engine changes (Bart):** None needed — engine already supports this.

**Metadata changes:**

| File | Owner | Change |
|------|-------|--------|
| `src/meta/rooms/hallway.lua` | Moe | Add 2nd wolf instance: `{ id = "hallway-wolf-2", type_id = "{e69fc5e8-...}" }` |
| `src/meta/creatures/wolf.lua` | Flanders | Update `combat.behavior.pack_size` from `1` to `2` (documentation field) |

**Tests (Nelson):**
- Verify `get_pack_in_room()` returns 2 wolves in hallway
- Verify `select_alpha()` picks the healthier wolf
- Verify `plan_attack()` produces staggered delays
- Integration: creature tick in hallway produces pack stagger behavior

**Gate:** Pack of 2 wolves functions in hallway. `get_pack_in_room()` returns 2. Alpha attacks first, beta waits 1 turn.

**Estimated LOC:** ~10 metadata, ~30 tests

---

### WAVE-2: Pack Behavior (Shared Threat + Pack Morale)

**Goal:** Wolves share threat state and react as a unit.

**Engine changes (Bart):**

1. **Shared threat state** — Add to `pack-tactics.lua`:
   ```
   M.share_threat(pack, stimulus_type, data)
   ```
   When one wolf reacts to a stimulus (e.g., `player_attacks`), all pack members in the same room receive the same `fear_delta`. This is a stimulus amplifier, not a new system.

2. **Pack morale** — Add to `pack-tactics.lua`:
   ```
   M.check_pack_morale(pack, context) -> "hold" | "scatter"
   ```
   If alpha dies or health drops below 20%, remaining pack members get a morale penalty (+40 fear). If majority of pack is dead/fled, survivors scatter (flee action forced).

3. **Call pack action** — Add to `actions.lua` score_actions:
   ```
   New action: "call_pack"
   Score: aggression × 0.4 (only when creature is aggressive and pack members are in adjacent rooms)
   ```
   Execution: Emit `pack_call` stimulus to adjacent rooms. Pack members hearing this move toward the caller's room next tick.

4. **Retreat to territory** — Add to `actions.lua` score_actions:
   ```
   New action: "retreat_to_territory"
   Score: fear × 1.0 (only when creature has territory and is NOT in territory room)
   ```
   Execution: Move toward territory room via random valid exit. Higher priority than random flee.

**Metadata changes:**
| File | Owner | Change |
|------|-------|--------|
| `src/meta/creatures/wolf.lua` | Flanders | Add `reactions.pack_call` reaction, add `reactions.pack_member_died` reaction |

**Tests (Nelson):**
- Shared threat: attack one wolf, verify other wolf's fear increases
- Pack morale: kill alpha, verify beta's fear spikes
- Pack scatter: kill 2 of 3 wolves, verify survivor flees
- Call pack: wolf in hallway calls, wolf in adjacent room moves to hallway
- Retreat to territory: wounded wolf outside territory flees toward territory

**Gate:** Pack members share threat state. Alpha death triggers morale penalty. Wolves can call reinforcements from adjacent rooms.

**Estimated LOC:** ~80 engine, ~20 metadata, ~60 tests

---

### WAVE-3: Territorial Behavior (Intrusion Detection + Escalation)

**Goal:** Creatures that own territory react to player intrusion with escalating aggression.

**Engine changes (Bart):**

1. **Intrusion detection** — Add to `territorial.lua`:
   ```
   M.detect_intrusion(creature, context) -> nil | "warning" | "threat" | "attack"
   ```
   Reads `creature.behavior.territorial` and checks if the player is in the creature's territory rooms (BFS from territory markers). Escalation levels:
   - Turn 1 in territory: `"warning"` (vocalize — growl)
   - Turn 2 in territory: `"threat"` (transition to alive-aggressive)
   - Turn 3+ in territory: `"attack"` (force attack action)

   Tracked via `creature._intrusion_turns` counter (incremented per tick when player is in territory, reset when player leaves).

2. **Territory claim on alpha death** — Add to `pack-tactics.lua`:
   ```
   M.transfer_territory(dead_alpha, pack, context)
   ```
   When alpha dies, the next-healthiest pack member inherits `behavior.territory`. Territory markers are not moved — the new "alpha" just claims the same territory.

3. **Hook intrusion detection into creature_tick** — In `init.lua`, after territorial evaluation (step 0c), call `detect_intrusion()`. If result is `"attack"`, override the action scoring to force the attack action.

**Metadata changes:**
| File | Owner | Change |
|------|-------|--------|
| `src/meta/creatures/wolf.lua` | Flanders | Add `behavior.intrusion_escalation = { warning = 1, threat = 2, attack = 3 }` |
| `src/meta/creatures/wolf.lua` | Flanders | Add `reactions.intrusion_warning` with growl message |

**Tests (Nelson):**
- Player enters wolf territory → wolf vocalizes warning on turn 1
- Player stays → wolf transitions to aggressive on turn 2
- Player stays further → wolf attacks on turn 3
- Player leaves territory → intrusion counter resets
- Alpha dies → beta inherits territory ownership

**Gate:** Wolves escalate from warning → threat → attack when player intrudes on territory. Territory transfers on alpha death.

**Estimated LOC:** ~60 engine, ~15 metadata, ~50 tests

---

### WAVE-4: Ambush Mechanics (Surprise + Group Ambush)

**Goal:** Creatures can set ambushes with a first-strike damage bonus.

**Engine changes (Bart):**

1. **Surprise damage multiplier** — In `actions.lua` attack execution:
   ```lua
   if creature._ambush_sprung and not creature._ambush_bonus_used then
       result.damage_multiplier = (creature.behavior.ambush and creature.behavior.ambush.damage_bonus) or 1.5
       creature._ambush_bonus_used = true
   end
   ```
   Pass `damage_multiplier` to `combat.run_combat()`. The combat module applies it to the first hit's force value. One-time bonus — `_ambush_bonus_used` prevents stacking.

2. **Re-hide after combat** — In `actions.lua`, add to `idle` action:
   ```lua
   if creature.behavior and creature.behavior.ambush and creature.behavior.ambush.can_rehide then
       if creature._ambush_sprung and not (player is in room) then
           creature._ambush_sprung = false
           creature._ambush_bonus_used = false
       end
   end
   ```
   Creatures with `can_rehide = true` can reset their ambush state when the player leaves the room.

3. **Group ambush** — In `pack-tactics.lua`:
   ```
   M.coordinate_ambush(pack, context) -> bool
   ```
   If alpha is in ambush state and pack members are present, all pack members enter ambush wait. When alpha springs, all spring simultaneously. This is a pack-level ambush — not individual.

**Metadata changes:**
| File | Owner | Change |
|------|-------|--------|
| `src/meta/creatures/wolf.lua` | Flanders | Add `behavior.ambush = { trigger_on_proximity = true, damage_bonus = 1.5, narration = "..." }` |
| `src/meta/creatures/spider.lua` | Flanders | Add `behavior.ambush.damage_bonus = 2.0` (venom ambush), `can_rehide = true` |

**Tests (Nelson):**
- Ambush spring applies 1.5× damage on first hit
- Ambush bonus only applies once per ambush cycle
- Spider re-hides when player leaves room
- Group ambush: 2 wolves both spring when alpha springs
- Group ambush damage: both wolves get first-strike bonus

**Gate:** Ambush creatures deal bonus damage on first strike. Spiders can re-hide. Pack ambush coordinates alpha + beta spring timing.

**Estimated LOC:** ~50 engine, ~10 metadata, ~40 tests

---

## Section 4: Agent Assignments

| Wave | Agent | Role | Files |
|------|-------|------|-------|
| **WAVE-1** | Moe | Add 2nd wolf to hallway.lua | `src/meta/rooms/hallway.lua` |
| **WAVE-1** | Flanders | Update wolf pack_size metadata | `src/meta/creatures/wolf.lua` |
| **WAVE-1** | Nelson | Pack activation tests | `test/creatures/` |
| **WAVE-2** | Bart | Shared threat, pack morale, call_pack, retreat_to_territory | `src/engine/creatures/pack-tactics.lua`, `actions.lua`, `init.lua` |
| **WAVE-2** | Flanders | Wolf reactions for pack_call, pack_member_died | `src/meta/creatures/wolf.lua` |
| **WAVE-2** | Nelson | Pack coordination tests | `test/creatures/` |
| **WAVE-3** | Bart | Intrusion detection, escalation, territory transfer | `src/engine/creatures/territorial.lua`, `init.lua` |
| **WAVE-3** | Flanders | Wolf intrusion escalation metadata | `src/meta/creatures/wolf.lua` |
| **WAVE-3** | Nelson | Territorial escalation tests | `test/creatures/` |
| **WAVE-4** | Bart | Surprise damage, re-hide, group ambush | `src/engine/creatures/actions.lua`, `pack-tactics.lua` |
| **WAVE-4** | Flanders | Ambush metadata for wolf + spider | `src/meta/creatures/wolf.lua`, `spider.lua` |
| **WAVE-4** | Nelson | Ambush mechanics tests | `test/creatures/` |
| **ALL** | Brockman | Architecture doc updates | `docs/architecture/meta/creature-behavior-engine.md` |

---

## Section 5: Gate Criteria

| Gate | Criteria | Pass Condition |
|------|----------|----------------|
| **GATE-1** | Pack activates | `get_pack_in_room("hallway")` returns ≥2 wolves; stagger fires; 266+ tests pass |
| **GATE-2** | Pack coordinates | Shared threat propagates; pack morale triggers scatter; call_pack summons; 270+ tests pass |
| **GATE-3** | Territory escalates | Intrusion detection fires warning→threat→attack; territory transfers; 275+ tests pass |
| **GATE-4** | Ambush works | Surprise damage applies 1.5×; re-hide cycles; group ambush coordinates; 280+ tests pass |

---

## Section 6: Principle 8 Compliance

**Every feature in this plan is metadata-driven.** No creature-specific engine code:

| Feature | Metadata Declaration | Engine Reads Generically |
|---------|---------------------|--------------------------|
| Pack size | `combat.behavior.pack_size` | `get_pack_in_room()` matches by `obj.id` |
| Shared threat | `reactions.pack_call` | Stimulus system delivers to all pack members |
| Pack morale | Derived from `health/max_health` | `check_pack_morale()` reads health ratios |
| Intrusion escalation | `behavior.intrusion_escalation` | `detect_intrusion()` reads escalation thresholds |
| Territory transfer | `behavior.territory` | Reassigned dynamically — no new engine field |
| Ambush damage | `behavior.ambush.damage_bonus` | `execute_action()` reads bonus from metadata |
| Re-hide | `behavior.ambush.can_rehide` | Boolean gate in idle action |
| Group ambush | Pack + `behavior.ambush` | `coordinate_ambush()` reads both pack and ambush metadata |

**Adding a new creature with pack/territorial/ambush behavior requires ONLY a new `.lua` file in `src/meta/creatures/`.** No engine changes.

---

## Section 7: Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Pack stagger creates unfair difficulty spike | Medium | Medium | Tune stagger delay; playtest after GATE-1 |
| Shared threat makes wolves too aggressive | Medium | Low | Fear delta is metadata-configurable; tune per-creature |
| Intrusion escalation too fast (3 turns) | Low | Medium | Escalation thresholds in metadata — tunable without engine changes |
| Ambush damage bonus too powerful | Medium | Medium | Multiplier in metadata; can reduce from 1.5× to 1.25× |
| Performance: pack queries scan all objects | Low | Low | Pack query is O(N) where N = objects in room; rooms have <20 objects |
| Test flakiness (noted in Phase 4 post-mortem) | Medium | Medium | Run test suite 2× before each gate; investigate global state leaks |

---

## Section 8: Files Modified Per Wave

### WAVE-1 (Multi-Instance)
```
MODIFIED: src/meta/rooms/hallway.lua          (Moe — add wolf instance)
MODIFIED: src/meta/creatures/wolf.lua         (Flanders — pack_size)
NEW:      test/creatures/test-pack-activation.lua  (Nelson)
```

### WAVE-2 (Pack Behavior)
```
MODIFIED: src/engine/creatures/pack-tactics.lua   (Bart — share_threat, check_pack_morale)
MODIFIED: src/engine/creatures/actions.lua        (Bart — call_pack + retreat_to_territory actions)
MODIFIED: src/engine/creatures/init.lua           (Bart — wire new actions into tick)
MODIFIED: src/meta/creatures/wolf.lua             (Flanders — new reactions)
NEW:      test/creatures/test-pack-coordination.lua  (Nelson)
```

### WAVE-3 (Territorial)
```
MODIFIED: src/engine/creatures/territorial.lua    (Bart — detect_intrusion, escalation)
MODIFIED: src/engine/creatures/init.lua           (Bart — intrusion hook in tick)
MODIFIED: src/engine/creatures/pack-tactics.lua   (Bart — transfer_territory)
MODIFIED: src/meta/creatures/wolf.lua             (Flanders — intrusion metadata)
NEW:      test/creatures/test-territorial-escalation.lua  (Nelson)
```

### WAVE-4 (Ambush)
```
MODIFIED: src/engine/creatures/actions.lua        (Bart — surprise damage, re-hide)
MODIFIED: src/engine/creatures/pack-tactics.lua   (Bart — coordinate_ambush)
MODIFIED: src/meta/creatures/wolf.lua             (Flanders — ambush metadata)
MODIFIED: src/meta/creatures/spider.lua           (Flanders — ambush damage_bonus, can_rehide)
NEW:      test/creatures/test-ambush-mechanics.lua  (Nelson)
```

---

## Section 9: Dependency Chain

```
WAVE-1: Multi-Instance (fix #315)
   │
   ├─── Required by WAVE-2 (pack needs ≥2 wolves)
   │
   ▼
WAVE-2: Pack Behavior (shared threat, morale, call_pack)
   │
   ├─── Required by WAVE-3 (territory transfer needs pack concept)
   │
   ▼
WAVE-3: Territorial Behavior (intrusion detection, escalation)
   │
   ├─── Independent from WAVE-4 (but WAVE-4 benefits from territory context)
   │
   ▼
WAVE-4: Ambush Mechanics (surprise damage, group ambush)
   │
   └─── Depends on WAVE-2 (group ambush uses pack coordination)
```

**Strict serial dependency:** WAVE-1 → WAVE-2 → WAVE-3 → WAVE-4.  
WAVE-3 and WAVE-4 could theoretically parallelize, but group ambush in WAVE-4 depends on pack functions from WAVE-2, which needs multi-instance from WAVE-1.

---

## Section 10: What This Does NOT Include

Explicitly deferred to Phase 6 or later:

| Feature | Reason for Deferral |
|---------|-------------------|
| A* pathfinding | Random-exit works for 7 rooms; defer until Level 2 geography exists |
| Zone-targeting (attack specific body parts) | Requires pack role system v2; Phase 6 |
| Alpha/Beta/Omega named roles | Simplified system (health-based) is sufficient for V1 |
| Environmental combat (push, throw, climb) | Belongs to combat system, not creature intelligence |
| Humanoid NPC dialogue | Phase 6 centerpiece |
| Creature-to-creature looting | Requires AI evaluation; expensive |
| Werewolf creature | Depends on Level 2 rooms (separate track) |
| Salt preservation | Separate track (WAVE-3 in the broader Phase 5 plan) |

---

*Plan authored by Bart (Architecture Lead). v1.0 — Ready for Wayne review.*
