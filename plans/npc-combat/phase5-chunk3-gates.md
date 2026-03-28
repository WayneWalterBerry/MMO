# Phase 5 — Chunk 3: Testing Gates + Nelson LLM Scenarios + TDD Test File Map

**Author:** Bart (Architecture Lead)  
**Date:** 2026-03-28  
**Chunk:** 3 of 5  
**Parent:** `plans/npc-combat/npc-combat-implementation-phase5.md` (Chunk 1 Skeleton)

---

## Section 1: Testing Gates

### Regression Baseline Protocol

Run `lua test/run-tests.lua` on Phase 4 HEAD before Phase 5 work. Record as PHASE-4-FINAL-COUNT (current: ~258 files, 223 tracked tests). Each gate adds incrementally: GATE-1 +15, GATE-2 +10, GATE-3 +10, GATE-4 +15. Final target: **270+ passing tests, ZERO regressions.**

---

### GATE-1 — Level 2 Foundation

**After:** WAVE-1 | **Reviewers:** Bart + Nelson

#### Pass/Fail Criteria

- [ ] All 7 L2 rooms instantiate — `lua test/rooms/test-level2-rooms.lua`
- [ ] Exits route correctly (bidirectional, no orphans) — `lua test/rooms/test-level2-exits.lua`
- [ ] Brass key unlocks L1→L2 door — `lua test/rooms/test-brass-key-transition.lua`
- [ ] Werewolf creature loads (stats, patrol, territorial) — `lua test/creatures/test-werewolf.lua`
- [ ] L2 creatures spawn in correct rooms — `lua test/creatures/test-level2-placement.lua`
- [ ] Room presence text correct — Manual review
- [ ] Zero regressions + ~238 tests pass — `lua test/run-tests.lua`

**Perf:** L2 instantiation < 200ms | **LLM:** Scenario 2.1 | **Commit:** `feat: Level 2 foundation (WAVE-1)`

---

### GATE-2 — Pack Role System

**After:** WAVE-2 | **Reviewers:** Bart + Nelson

#### Pass/Fail Criteria

- [ ] Stagger attacks (alpha first, others delay 1 turn) — `lua test/creatures/test-pack-stagger.lua`
- [ ] Alpha = highest HP; re-evaluates on damage — `lua test/creatures/test-pack-alpha.lua`
- [ ] Omega (< 25% HP) retreats — `lua test/creatures/test-pack-omega.lua`
- [ ] `pack_role` field on wolf instances — `lua test/creatures/test-wolf-pack-metadata.lua`
- [ ] Territory zones map to L2 topology — `lua test/creatures/test-level2-territory.lua`
- [ ] Coordinated attack narration correct — Manual review
- [ ] Zero regressions + ~248 tests pass — `lua test/run-tests.lua`

**Perf:** Pack scoring < 50ms/tick | **LLM:** Scenario 2.4 | **Commit:** `feat: pack roles (WAVE-2)`

---

### GATE-3 — Salt Preservation System

**After:** WAVE-3 | **Reviewers:** Bart + Nelson

#### Pass/Fail Criteria

- [ ] Salt verb resolves (aliases: salt, preserve, cure) — `lua test/verbs/test-salt-verb.lua`
- [ ] Salt object loads (small-item, preservative) — `lua test/objects/test-salt-object.lua`
- [ ] `salt wolf-meat` → salted-wolf-meat mutation — `lua test/preservation/test-salt-mutation.lua`
- [ ] Spoilage = 3× slower (deterministic) — `lua test/preservation/test-spoilage-rate.lua`
- [ ] Fails without salt in hand — `lua test/preservation/test-salt-requirement.lua`
- [ ] Salted meat distinct sensory fields — `lua test/preservation/test-salted-sensory.lua`
- [ ] Zero regressions + ~258 tests pass — `lua test/run-tests.lua`

**Perf:** Salt mutation < 20ms | **LLM:** Scenario 2.3 | **Commit:** `feat: salt preservation (WAVE-3)`

---

### GATE-4 — Phase 5 Complete

**After:** WAVE-4 | **Reviewers:** Bart + Nelson + Brockman

#### Pass/Fail Criteria

- [ ] Full LLM walkthrough passes (Scenarios 2.1-2.5) — headless
- [ ] 3 design docs meet acceptance criteria (below)
- [ ] Zero regressions + 270+ tests pass — `lua test/run-tests.lua`
- [ ] No flaky tests (3 consecutive runs, 100%) — `lua test/run-tests.lua` × 3
- [ ] No engine module > 500 LOC — manual audit
- [ ] Meta-lint passes (0 errors) — `lua scripts/meta-lint.lua`
- [ ] Embedding index updated (L2 nouns, salt, werewolf) — `lua test/parser/test-embedding-index.lua`

#### Docs Acceptance

| Doc | Min Content | Sign-Off |
|-----|-------------|----------|
| `docs/design/level2-ecology.md` | 7-room map, habitats, biomes, treasure, difficulty | Bart |
| `docs/architecture/creatures/pack-tactics-v2.md` | Stagger algo, alpha, omega reserve, Phase 6 preview | Bart |
| `docs/design/preservation-system.md` | Salt pipeline, mutation spec, spoilage math, future hooks | Bart |

**Commit:** `feat: Phase 5 complete (WAVE-4)` | **Tag:** `phase-5-complete`

---

## Section 2: Nelson LLM Test Scenarios

All scenarios use `--headless` mode with deterministic seeds (`math.randomseed(42)`). Navigation paths are approximate — adjust after WAVE-1 room wiring.

### 2.1 Scenario: Level 2 Exploration (GATE-1 + GATE-4)

**Goal:** Navigate from Level 1 → unlock brass key door → enter Level 2 → explore all 7 rooms.

```bash
echo "look
take brass key
go north
go north
go north
unlock door with brass key
open door
go north
look
go east
look
go south
look
go west
look
go north
look
go east
look
go south
look" | lua src/main.lua --headless
```

**Expected patterns:** `brass key` (pickup), `unlock` (door), `catacombs` (L2 entry), ≥4 distinct L2 room names, no `error`/`nil`, no `You can't go that way` after valid exits.

**Pass:** Player reaches L2, visits ≥5 of 7 rooms, all descriptions render cleanly.

---

### 2.2 Scenario: Werewolf Encounter (GATE-1 + GATE-4)

**Goal:** Find werewolf in Level 2, engage combat, defeat it, loot remains.

```bash
echo "look
take brass key
go north
go north
go north
unlock door with brass key
open door
go north
go east
go east
look
feel
smell
attack werewolf
attack werewolf
attack werewolf
attack werewolf
attack werewolf
look
examine corpse
butcher werewolf
look" | lua src/main.lua --headless
```

**Expected patterns:** `werewolf` (present), `attack`/`hit`/`strike` (combat), `dead`/`corpse`/`collapses` (death), `meat`/`hide`/`bone` (loot). No `You can't` for valid combat.

**Pass:** Werewolf found in L2, combat resolves, butchery yields products.

---

### 2.3 Scenario: Salt Preservation (GATE-3 + GATE-4)

**Goal:** Find salt, salt meat, verify salted meat has different properties from fresh.

```bash
echo "look
take knife
take salt
go south
go south
look
attack wolf
attack wolf
attack wolf
attack wolf
butcher wolf
take wolf-meat
salt wolf-meat
examine salted-wolf-meat
feel salted-wolf-meat
taste salted-wolf-meat
smell salted-wolf-meat" | lua src/main.lua --headless
```

**Expected patterns:** `salt` (pickup/verb), `salted` (mutation confirmation), `crusted`/`dry` (on_feel), `salty` (on_taste). No `You don't have`, no mutation errors.

**Pass:** Salt verb transforms fresh meat into salted variant with distinct sensory properties. Mutation pipeline clean.

---

### 2.4 Scenario: Pack Tactics (GATE-2 + GATE-4)

**Goal:** Encounter wolf pack, verify stagger attacks, observe alpha/omega behavior.

```bash
echo "look
take knife
go north
go north
go north
unlock door with brass key
open door
go north
go west
look
wait
wait
wait
wait
wait
look
feel" | lua src/main.lua --headless
```

**Expected patterns:** `wolf` (multiple mentions — pack present), `alpha`/`lunges first`/`leads the attack` (alpha first), `staggers`/`follows` (beta delayed), `retreats`/`flees` (omega if wounded). Sequential attack text, no simultaneous. No creature tick errors.

**Pass:** Alpha attacks first, beta staggers 1 turn, omega retreats if wounded. Pack does not attack simultaneously.

**Note:** `wait` advances game time to trigger creature ticks. Adjust count based on tick frequency.

---

### 2.5 Scenario: Full Phase 5 Loop (GATE-4 — integration)

**Goal:** End-to-end: L1 → brass key → L2 → wolf combat → butcher → salt → werewolf → rest.

```bash
echo "look
take brass key
take knife
go north
go north
go north
unlock door with brass key
open door
go north
go east
attack wolf
attack wolf
attack wolf
attack wolf
butcher wolf
take wolf-meat
take salt
salt wolf-meat
go west
go east
go east
attack werewolf
attack werewolf
attack werewolf
attack werewolf
attack werewolf
butcher werewolf
go west
go south
rest" | lua src/main.lua --headless
```

**Expected patterns:** Combines Scenarios 1-4 patterns + `rest`/`calm`/`safe` + `---END---`. No `nil`, no stack traces.

**Pass:** Full Phase 5 arc completes in one session — L1→L2, combat, butcher, salt, rest.

---

## Section 3: TDD Test File Map

### New Test Files for Phase 5

| File | Wave | Coverage | Agent | Tests |
|------|------|----------|-------|-------|
| `test/rooms/test-level2-rooms.lua` | W1 | 7 L2 rooms load, fields present, descriptions non-empty | Nelson | 7 |
| `test/rooms/test-level2-exits.lua` | W1 | L2 exits route to valid targets, bidirectional, no orphans | Nelson | 8 |
| `test/rooms/test-brass-key-transition.lua` | W1 | Brass key unlocks L1→L2 door, FSM state | Nelson | 4 |
| `test/creatures/test-werewolf.lua` | W1 | Werewolf instantiation, stats, patrol, territorial, sensory | Nelson | 6 |
| `test/creatures/test-level2-placement.lua` | W1 | Creatures in correct L2 rooms per geography | Nelson | 5 |
| `test/creatures/test-pack-stagger.lua` | W2 | Alpha first, beta delayed 1 turn, sequence correct | Nelson | 4 |
| `test/creatures/test-pack-alpha.lua` | W2 | Highest HP = alpha; re-evaluates; deterministic tie-break | Nelson | 4 |
| `test/creatures/test-pack-omega.lua` | W2 | Omega retreat at < 25% HP, path selection | Nelson | 3 |
| `test/creatures/test-wolf-pack-metadata.lua` | W2 | `pack_role` field present, updates dynamically | Nelson | 3 |
| `test/creatures/test-level2-territory.lua` | W2 | BFS radius in L2 room graph, zone boundaries | Nelson | 4 |
| `test/verbs/test-salt-verb.lua` | W3 | Aliases resolve, requires salt in hand | Nelson | 4 |
| `test/objects/test-salt-object.lua` | W3 | Salt loads, preservative capability, keywords | Nelson | 3 |
| `test/preservation/test-salt-mutation.lua` | W3 | wolf-meat → salted-wolf-meat, GUID + metadata | Nelson | 3 |
| `test/preservation/test-spoilage-rate.lua` | W3 | Salted = 3× fresh decay (deterministic time test) | Nelson | 2 |
| `test/preservation/test-salt-requirement.lua` | W3 | Fails without salt, fails on non-food, salt consumed | Nelson | 3 |
| `test/preservation/test-salted-sensory.lua` | W3 | on_feel, on_taste, on_smell differ from fresh | Nelson | 3 |
| `test/integration/test-level2-full-flow.lua` | W4 | L1→L2 → combat → butcher → salt → rest | Nelson | 5 |
| `test/integration/test-phase5-regression.lua` | W4 | Phase 4 scenarios unchanged (candle, cook, craft, stress) | Nelson | 8 |

### New Directory: `test/preservation/` — register in `test/run-tests.lua` during PRE-WAVE or WAVE-3.

### Summary

| Wave | Files | Tests | Cumulative |
|------|-------|-------|------------|
| W1 | 5 | ~30 | ~253 |
| W2 | 5 | ~18 | ~271 |
| W3 | 6 | ~18 | ~289 |
| W4 | 2 | ~13 | ~302 |
| **Total** | **18** | **~79** | **~302** |

**Target:** 270+ (conservative), 300+ (stretch). **Baseline:** Phase 4 = 223 tracked. **Zero regression tolerance.**

---

*Chunk 3 authored by Bart (Architecture Lead). Testing gates, LLM scenarios, and TDD file map for Phase 5.*
