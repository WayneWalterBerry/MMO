# NPC + Combat Phase 2 — Chunk 3: Gates + Testing

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Chunk:** 3 of 5 — Testing Gates, Nelson LLM Scenarios, TDD Test File Map  
**Scope:** Phase 2 = Creature Variety + Disease + Food/Bait  
**Reference:** `plans/npc-combat-implementation-phase1.md` (Phase 1), `plans/combat-system-plan.md` (design), `plans/npc-system-plan.md` (NPC design)

---

## Section 1: Testing Gates

### GATE-0: Pre-Flight (Infrastructure)

**After:** WAVE-0 completes  
**Tests that must pass:**

- `lua test/run-tests.lua` — zero regressions across all existing test files
- New directories registered: `test/creatures/`, `test/combat/`, `test/food/`, `test/scenarios/`
- No engine file exceeds 500 LOC (checked via `wc -l` or Lua line-count script)

**Specific checks:**

| Check | Method | Pass Criteria |
|-------|--------|---------------|
| Test dirs registered | `test/run-tests.lua` discovers new dirs without error | Runner finds 0 files in new dirs (no crash) |
| LOC guard | `wc -l src/engine/**/*.lua` | Every file < 500 lines |
| No regressions | `lua test/run-tests.lua` | All existing tests pass |

**Pass/fail:** ALL checks pass. Binary.  
**Reviewer:** Bart (architecture)  
**Action on fail:** Fix before proceeding — pre-flight is blocking.

**On pass:** No separate commit — WAVE-0 is a 5-minute setup folded into WAVE-1 commit.

---

### GATE-1: Creature Definitions (4 Creatures Load + Validate)

**After:** WAVE-1 completes  
**Tests that must pass:**

- `lua test/creatures/test-cat.lua` — all assertions green
- `lua test/creatures/test-wolf.lua` — all assertions green
- `lua test/creatures/test-spider.lua` — all assertions green
- `lua test/creatures/test-rat-phase2.lua` — rat updates validate (body_tree, combat metadata additions)
- `lua test/creatures/test-creature-materials.lua` — chitin, hide, tooth_enamel, keratin resolve through material registry
- `lua test/run-tests.lua` — zero regressions in ALL existing tests (Phase 1 creature/combat tests still pass)

**Specific assertions:**

| Creature | Required Fields | Key Validations |
|----------|----------------|-----------------|
| Cat | `animate=true`, `template="creature"`, `behavior.prey={"rat"}`, `body_tree` with head/body/legs/tail | Keywords include "cat", "feline"; size is string `"small"`; `on_feel` present |
| Wolf | `animate=true`, `behavior.aggression >= 70`, `body_tree` with head/body/legs | Keywords include "wolf"; size `"medium"`; `combat.natural_weapons` includes bite; `can_open_doors=false` |
| Spider | `animate=true`, `behavior.ambush=true`, `body_tree` with body/legs | Keywords include "spider"; size `"tiny"`; `combat.natural_weapons` bite has `on_hit.inflict="spider-venom"` |
| Rat (updated) | `combat` table added, `body_tree` present | `combat.natural_weapons` bite has `on_hit.inflict="rabies"` with `probability=0.15` |

**Material resolution checks:**

- `chitin` — spider exoskeleton, hardness > flesh, `natural_armor` use
- `hide` — animal outer layer, shear_resistance > skin
- `tooth_enamel` — natural weapon material for bites
- `keratin` — claws/nails material

**Pass/fail:** ALL creature files load via `dofile()`. ALL fields validate against creature template. ALL materials resolve. Zero regressions. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)  
**Action on fail:** File issue, assign to Flanders (creature data) or Nelson (test fix), re-gate.

**On pass:** `git add -A && git commit -m "GATE-1: Phase 2 creature definitions — 4 creatures + materials validated" && git push`

---

### GATE-2: Creature Attack + Predator-Prey + Stimulus

**After:** WAVE-2 completes  
**Tests that must pass:**

- `lua test/creatures/test-creature-combat.lua` — creature attack action works
- `lua test/creatures/test-predator-prey.lua` — predator-prey trigger fires when cat and rat share a room
- `lua test/creatures/test-creature-stimulus.lua` — creature-to-creature stimulus emission + reception
- `lua test/run-tests.lua` — zero regressions

**Specific assertions:**

| Test Case | Input | Expected |
|-----------|-------|----------|
| Cat sees rat → chase | Cat + rat in same room, creature tick | Cat's fear_delta doesn't spike; cat selects "chase" action targeting rat |
| Rat detects cat → flee | Rat has `predator={"cat"}`, cat enters room | Rat's fear spikes above `flee_threshold`; rat selects "flee" action |
| Wolf sees player → attack | Wolf in room, player enters, wolf aggression ≥ 70 | Wolf selects "attack" action targeting player |
| Spider in web → wait | Spider in room with web, player enters | Spider does NOT attack; web triggers trap check |
| Stimulus propagation | Cat kills rat in room A; player in room A | Player receives `creature_died` stimulus message |
| Cross-room stimulus | Loud creature event in room B; player in room A (adjacent) | Player receives sound-range stimulus (if sound_range ≥ 1) |

**Performance budget:** Creature tick completes in <50ms for 10 mock creatures (all 4 types × 2 + 2 rats). Nelson measures via `os.clock()` before/after `creatures.tick(context)`.

**Pass/fail:** ALL tests pass, zero regressions, perf budget met. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)

**On pass:** `git add -A && git commit -m "GATE-2: Phase 2 creature combat + predator-prey validated" && git push`

---

### GATE-3: NPC-vs-NPC Combat + Witness Narration

**After:** WAVE-3 completes  
**Tests that must pass:**

- `lua test/combat/test-npc-combat.lua` — NPC-vs-NPC combat resolves through unified `resolve_exchange()`
- `lua test/combat/test-witness-narration.lua` — player witness narration generates correct output
- `lua test/combat/test-multi-combatant.lua` — turn order with 3+ participants
- `lua test/run-tests.lua` — zero regressions

**Specific assertions:**

| Test Case | Input | Expected |
|-----------|-------|----------|
| Cat kills rat | Cat (attack) vs rat (flee), `math.randomseed(42)` | Combat resolves: cat wins, rat mutates to dead-rat, narration generated |
| Turn order: speed-based | Wolf (speed=2), rat (speed=3), cat (speed=2) | Rat acts first (fastest), then wolf/cat by size tiebreak (smaller first) |
| Multi-combatant: 3 creatures | Cat + rat + wolf in same room | Each creature selects target based on prey/aggression metadata; no infinite loops |
| Witness narration: lit room | Player in room, cat kills rat, light present | Player sees: visual combat narration ("The cat pounces on the rat...") |
| Witness narration: dark room | Same combat, no light | Player hears: audio-only narration ("You hear hissing, then a shriek cut short.") |
| Witness narration: adjacent room | Combat in next room, player sound_range covers it | Player hears: distant sound ("From the next room, you hear scrabbling and a sharp squeal.") |
| NPC morale/flee | Rat at low health vs cat | Rat attempts flee; if successful, exits room; combat ends |
| Player intervention | Player types "attack cat" during cat-vs-rat combat | Player joins as third combatant; turn order recalculated |

**Documentation deliverables that must exist:**

- `docs/architecture/combat/npc-combat.md` — NPC-vs-NPC resolution, witness system
- `docs/architecture/engine/predator-prey.md` — predator-prey metadata and trigger logic
- `docs/design/creature-combat-profiles.md` — wolf, cat, spider, rat combat behavior specs

**Pass/fail:** ALL unit tests pass. All 3 docs exist. Zero regressions. Binary.  
**Reviewer:** Bart (architecture), Nelson (gate signer), Marge (test sign-off)

**On pass:** `git add -A && git commit -m "GATE-3: Phase 2 NPC-vs-NPC combat + witness narration" && git push`

---

### GATE-4: Disease Delivery + Rabies + Venom + Injury Integration

**After:** WAVE-4 completes  
**Tests that must pass:**

- `lua test/injuries/test-disease-delivery.lua` — `on_hit` disease mechanism works generically
- `lua test/injuries/test-rabies.lua` — rabies incubation → prodromal → furious → fatal progression
- `lua test/injuries/test-spider-venom.lua` — spider venom infliction and effect progression
- `lua test/injuries/test-disease-healing.lua` — poultice cures rabies in early stages only
- `lua test/run-tests.lua` — zero regressions

**Specific assertions:**

| Test Case | Input | Expected |
|-----------|-------|----------|
| Rabies delivery: 15% chance | Rat bites player 100 times with `math.randomseed(42)` | ~15 infections (±5 tolerance); `injuries.inflict("rabies")` called |
| Rabies incubation | Player infected, 15 ticks pass | State transitions: `incubating` → `prodromal`; message "You feel feverish..." |
| Rabies hydrophobia | Rabies reaches `furious` state | `restricts.drink = true`; player cannot use `drink` verb |
| Rabies terminal | Rabies reaches `fatal` state | Death message emitted; player dies |
| Rabies early cure | Apply healing-poultice during `incubating` | Rabies cured; injury removed |
| Rabies late cure fails | Apply healing-poultice during `furious` | No effect; rabies continues |
| Venom delivery: 100% | Spider bites player once | `injuries.inflict("spider-venom")` called; always fires (no probability) |
| Venom progression | Spider venom ticks | Damage per tick applied; movement restriction after threshold |
| Disease via NPC combat | Cat bites rat (rat carries rabies) | Disease check runs for NPC targets too (not player-only) |
| Injury system integration | Rabies damage ticks | `injuries.compute_health()` reflects accumulated damage; health decreases |

**Performance budget:** Disease tick (all active injuries) resolves in <10ms for 5 concurrent diseases.

**Pass/fail:** ALL tests pass, zero regressions, perf budget met. Binary.  
**Reviewer:** Bart (architecture), Marge (test sign-off)  
**Action on fail:** File issue, assign to Flanders (injury definitions) or Bart (engine integration), re-gate.

**On pass:** `git add -A && git commit -m "GATE-4: Phase 2 disease delivery — rabies + venom + healing" && git push`

---

### GATE-5: Food + Eat/Drink + Bait + Full LLM Walkthrough

**After:** WAVE-5 completes  
**Tests that must pass:**

- `lua test/food/test-eat-drink.lua` — eat and drink verbs work on food objects
- `lua test/food/test-bait.lua` — bait mechanic triggers creature approach
- `lua test/food/test-food-objects.lua` — all food items load and validate
- `lua test/integration/test-phase2-integration.lua` — multi-command end-to-end scenario
- `lua test/run-tests.lua` — zero regressions (ALL Phase 1 + Phase 2 tests pass)

**Specific assertions:**

| Test Case | Input | Expected |
|-----------|-------|----------|
| Eat cheese | Player holds cheese, types `eat cheese` | Cheese consumed (removed from inventory); hunger drive reduced; message printed |
| Eat non-food | Player tries `eat candle` | Rejection message: "You can't eat that." |
| Drink water | Player holds waterskin, types `drink water` | Water consumed (waterskin state changes); thirst satisfied |
| Drink blocked by rabies | Player has furious rabies, types `drink water` | "You gag at the thought of water." — action blocked by `restricts.drink` |
| Bait placement | Player drops cheese in room with rat | Rat's hunger drive detects food stimulus; rat approaches cheese |
| Bait consumption | Rat reaches cheese, hunger high | Rat "eats" cheese (cheese removed); rat hunger satisfied |
| Bait trap combo | Player drops cheese, hides, rat approaches | Rat moves to cheese; player can then attack distracted rat |
| Food spoilage FSM | Cheese ticks through `fresh → stale → spoiled` | States transition correctly; spoiled food has negative eat effect |

**Documentation deliverables that must exist:**

- `docs/architecture/engine/food-system.md` — eat/drink verbs, food FSM, bait stimulus
- `docs/design/food-mechanics.md` — food objects, spoilage, hunger interaction
- `docs/design/creature-disease-system.md` — rabies, venom, disease delivery overview

**Nelson LLM walkthrough scenarios:** See Section 2 — all 7 scenarios must complete.

**Performance budget:**

- Creature tick <50ms for 10 creatures (maintained from GATE-2)
- Combat resolution <100ms for a 3-creature fight
- Disease tick <10ms for 5 concurrent diseases (maintained from GATE-4)

**Pass/fail:** ALL unit tests pass. ALL 7 LLM scenarios complete without errors. All 3 docs exist. Zero regressions. Binary.  
**Reviewer:** Bart (architecture), Nelson (LLM execution + gate signer), Marge (test sign-off), CBG (player experience check)

**CBG player experience check (GATE-5 only):**

- Does cat-kills-rat feel natural and discoverable? (<3 turns after entering room)
- Does rabies create a meaningful "oh no" moment when symptoms appear?
- Does bait mechanic feel like a puzzle the player would try without hints?
- Design debt captured to `.squad/decisions/inbox/cbg-design-debt-GATE-5.md`

**On pass:** `git add -A && git commit -m "GATE-5: Phase 2 complete — food/bait + full LLM walkthrough + docs" && git push`

---

## Section 2: Nelson LLM Test Scenarios

**Determinism rule:** All LLM walkthroughs seed `math.randomseed(42)` via `--headless` mode. Probabilistic behavior (wander, disease transmission) must trigger within defined tick counts. If a probabilistic test fails, re-run with seed 43, then 44. Three consecutive failures across different seeds = genuine bug.

**Mode:** All scenarios use `--headless`. Input via pipe or `echo`. Output validated against expected substrings.

---

### GATE-1 Scenarios: Creature Data Validation

```
# No LLM walkthrough — unit tests only.
# Validate: 4 creatures load, body_tree validates, materials resolve.
# Static checks in test files, not headless game session.
```

---

### GATE-2 Scenarios: Creature Combat + Predator-Prey

**Scenario P2-A: "Cat Chases Rat Across Rooms"**

```bash
# Setup: Cat and rat both placed in cellar. Player in adjacent room.
# Cat has prey={"rat"}. Rat has predator={"cat"}.
echo "go cellar\nlook\nwait\nwait\nwait\nlook" | lua src/main.lua --headless
```

**Expected output contains:**
- First `look`: see both cat and rat in cellar (lit) OR hear both (dark)
- After waits: cat chases rat; rat flees to adjacent room
- Second `look`: cat has pursued rat OR rat is gone from cellar
- Key validation: creature-to-creature stimulus → action pipeline fires

**Scenario P2-B: "Wolf Attacks Player in Hallway"**

```bash
# Setup: Wolf placed in hallway. Player starts in bedroom.
echo "go north\nlook\nwait" | lua src/main.lua --headless
```

**Expected output contains:**
- Player enters hallway → wolf `player_enters` reaction fires
- Wolf aggression ≥ 70 → wolf attacks player
- Combat narration appears (wolf bite attempt)
- Player receives damage OR gets prompted for response
- Key validation: aggressive creature initiates combat on sight

**Scenario P2-C: "Spider Web Trap"**

```bash
# Setup: Spider in cellar with web object already created.
echo "go cellar\nlook" | lua src/main.lua --headless
```

**Expected output contains:**
- Player enters cellar → web trap check fires
- If web exists in exit path: "You walk into a sticky web..." (trap triggered)
- Spider detects trapped player → may approach
- Key validation: creature-created objects interact with player movement

---

### GATE-3 Scenarios: NPC-vs-NPC Combat + Witness Narration

**Scenario P2-D: "Player Watches Cat Kill Rat"**

```bash
# Setup: Cat and rat in cellar. Player enters with light.
echo "take matchbox\nopen matchbox\ntake match\nlight match\nlight candle\ngo cellar\nlook\nwait\nwait\nwait\nlook" | lua src/main.lua --headless
```

**Expected output contains:**
- Player sees cat and rat in cellar
- Cat-vs-rat combat initiates (predator-prey)
- Witness narration: "The cat pounces on the rat..." or similar visual combat text
- After combat resolves: dead rat on floor OR rat fled
- If rat died: `look` shows dead rat, cat present
- Key validation: witness narration generates for lit-room observer

**Scenario P2-D2: "Witness Combat in Darkness"**

```bash
# Setup: Same as P2-D but no light.
echo "go cellar\nlisten\nwait\nwait\nlisten" | lua src/main.lua --headless
```

**Expected output contains:**
- Player hears combat: "hissing," "shriek," "scrabbling" (audio-only narration)
- No visual descriptions of the fight
- Key validation: dark-room witness narration uses sound only

**Scenario P2-E: "Multi-Combatant Turn Order"**

```bash
# Setup: Wolf, cat, and rat in same room. Player enters.
echo "go cellar\nwait\nwait\nwait" | lua src/main.lua --headless
```

**Expected output contains:**
- Multiple creatures act in speed order
- Rat (fastest) acts first, then cat, then wolf (or by size tiebreak)
- No infinite combat loops — combat resolves or creatures flee
- Key validation: turn order with 3+ participants is correct and terminates

---

### GATE-4 Scenarios: Disease Delivery

**Scenario P2-F: "Rat Bites Player — Rabies Progression"**

```bash
# Setup: Player provokes rat. Rat bites. Seed chosen for rabies transmission.
# Use math.randomseed that triggers the 15% chance.
echo "go cellar\ngrab rat\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nlook" | lua src/main.lua --headless
```

**Expected output contains:**
- `grab rat` → rat bites → "The rat sinks its teeth into your hand."
- If rabies transmitted (seed-dependent): "The bite wound throbs strangely."
- After 15 waits (incubation): "You feel feverish. The old bite wound itches terribly."
- Key validation: `on_hit` disease delivery fires; rabies FSM progresses on tick

**Scenario P2-F2: "Spider Venom Delivery"**

```bash
# Setup: Spider bites player (100% venom delivery).
echo "go cellar\ngrab spider\nwait\nwait\nwait" | lua src/main.lua --headless
```

**Expected output contains:**
- Spider bites → "The spider's fangs pierce your skin. A burning sensation spreads."
- Venom injury inflicted immediately (100% delivery, no probability)
- After waits: venom progression messages; movement may be restricted
- Key validation: `on_hit.inflict="spider-venom"` fires on spider bite

---

### GATE-5 Scenarios: Food + Bait + Full End-to-End

**Scenario P2-G: "Bait Mechanic — Cheese Lures Rat"**

```bash
# Setup: Player has cheese. Rat is in adjacent room.
echo "take cheese\ngo cellar\ndrop cheese\ngo north\nwait\nwait\nwait\ngo cellar\nlook" | lua src/main.lua --headless
```

**Expected output contains:**
- Player drops cheese in cellar
- After waits: rat detects food stimulus; rat moves toward cheese
- Player returns to cellar: rat is near/eating cheese
- Key validation: food stimulus triggers creature movement; bait mechanic works

**Scenario P2-H: "Eat and Drink Verbs"**

```bash
# Setup: Player has food and waterskin.
echo "take cheese\neat cheese\ntake waterskin\ndrink water" | lua src/main.lua --headless
```

**Expected output contains:**
- `eat cheese`: "You eat the cheese." (or similar); cheese removed from inventory
- `drink water`: "You drink from the waterskin." (or similar); thirst effect
- Key validation: eat/drink verbs consume items, affect player state

**Scenario P2-I: "Rabies Blocks Drinking"**

```bash
# Setup: Player has rabies in furious stage. Tries to drink.
# This may need a save-state or extended wait sequence to reach furious.
echo "go cellar\ngrab rat\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\nwait\ntake waterskin\ndrink water" | lua src/main.lua --headless
```

**Expected output contains:**
- Rabies has progressed to `furious` state (hydrophobia)
- `drink water` → "You gag at the thought of water." (action blocked)
- Key validation: `restricts.drink` on disease state blocks the drink verb

**Scenario P2-J: "Full End-to-End Walkthrough"**

```bash
# The complete Phase 2 experience: explore, fight, get diseased, use food, bait creature.
echo "look\n\
take matchbox\n\
open matchbox\n\
take match\n\
light match\n\
light candle\n\
look\n\
take cheese\n\
take silver dagger\n\
go cellar\n\
look\n\
drop cheese\n\
wait\n\
wait\n\
wait\n\
look\n\
attack rat\n\
dodge\n\
attack rat\n\
look\n\
take rat\n\
inventory\n\
go north\n\
look\n\
eat cheese\n\
go hallway\n\
look" | lua src/main.lua --headless
```

**Expected output validation (ordered):**

| Step | Command | Expected Substring or Behavior |
|------|---------|-------------------------------|
| 1 | `look` | Darkness description (game starts 2 AM) |
| 2–6 | Light sequence | Candle lights; room illuminated |
| 7 | `look` | See room contents including cheese and dagger |
| 8–9 | Take items | Cheese and dagger in hands |
| 10 | `go cellar` | Player enters cellar; rat present |
| 11 | `look` | See rat in cellar |
| 12 | `drop cheese` | Cheese on cellar floor |
| 13–15 | `wait` × 3 | Rat may approach cheese (bait stimulus) |
| 16 | `look` | Rat near cheese OR eating cheese |
| 17 | `attack rat` | Combat initiates; dagger vs rat |
| 18 | `dodge` | Player dodges rat counterattack |
| 19 | `attack rat` | Rat takes critical damage (steel dagger vs flesh) |
| 20 | `look` | Dead rat on floor |
| 21 | `take rat` | Dead rat picked up (portable) |
| 22 | `inventory` | Shows: candle (lit), dead rat |
| 23–24 | `go north`, `look` | Player in new room |

**Key validations for P2-J:**
- Bait mechanic (cheese draws rat)
- Combat resolution (dagger kills rat)
- Dead creature pickup (mutation to portable)
- No crashes across 24+ commands
- All Phase 1 mechanics still work (lighting, movement, inventory)

---

### Scenario Log Format

Nelson logs every LLM scenario run to `test/scenarios/gate{N}/`:

```
test/scenarios/gate0/   — (empty, unit tests only)
test/scenarios/gate1/   — (empty, unit tests only)
test/scenarios/gate2/
  ├── p2-a-cat-chases-rat.txt
  ├── p2-b-wolf-attacks-player.txt
  └── p2-c-spider-web-trap.txt
test/scenarios/gate3/
  ├── p2-d-witness-cat-kills-rat.txt
  ├── p2-d2-witness-dark.txt
  └── p2-e-multi-combatant.txt
test/scenarios/gate4/
  ├── p2-f-rabies-progression.txt
  └── p2-f2-spider-venom.txt
test/scenarios/gate5/
  ├── p2-g-bait-cheese-rat.txt
  ├── p2-h-eat-drink.txt
  ├── p2-i-rabies-blocks-drink.txt
  └── p2-j-full-end-to-end.txt
```

Each log file records:
- Seed used (`math.randomseed(N)`)
- Exact input pipe
- Full stdout capture
- PASS/FAIL per expected substring
- Timestamp

---

## Section 3: TDD Test File Map

Every test file listed below is created by Nelson. Tests are written to the **spec** (design plan), not to the implementation. Tests use the existing pure-Lua test framework (`test/parser/test-helpers.lua`).

### Creature Definition Tests (WAVE-1)

| Test File | Module Under Test | Wave | Key Assertions |
|-----------|-------------------|------|----------------|
| `test/creatures/test-cat.lua` | `src/meta/creatures/cat.lua` | WAVE-1 | Loads via `dofile()`; `animate=true`; `template="creature"`; `behavior.prey={"rat"}`; `body_tree` has head/body/legs/tail; `on_feel` present; keywords include "cat"; size is string `"small"` |
| `test/creatures/test-wolf.lua` | `src/meta/creatures/wolf.lua` | WAVE-1 | Loads via `dofile()`; `animate=true`; `behavior.aggression >= 70`; `body_tree` has head/body/legs (no tail); `combat.natural_weapons` includes bite with force ≥ 6; size `"medium"` |
| `test/creatures/test-spider.lua` | `src/meta/creatures/spider.lua` | WAVE-1 | Loads via `dofile()`; `animate=true`; `behavior.ambush=true`; `body_tree` has body/legs only; `combat.natural_weapons` bite has `on_hit.inflict="spider-venom"`; size `"tiny"`; material includes `"chitin"` |
| `test/creatures/test-rat-phase2.lua` | `src/meta/creatures/rat.lua` (modified) | WAVE-1 | `combat` table added; `combat.natural_weapons` bite has `on_hit.inflict="rabies"` with `probability=0.15`; `body_tree` present (head/body/legs/tail); Phase 1 fields still intact |
| `test/creatures/test-creature-materials.lua` | `src/meta/materials/chitin.lua`, `hide.lua`, `tooth_enamel.lua`, `keratin.lua` | WAVE-1 | Each material loads; `density` is number; `hardness` is number; resolves through `engine/materials` registry |

### Creature Combat + Behavior Tests (WAVE-2)

| Test File | Module Under Test | Wave | Key Assertions |
|-----------|-------------------|------|----------------|
| `test/creatures/test-creature-combat.lua` | `src/engine/creatures/init.lua` (attack action) | WAVE-2 | Creature with `aggression >= 70` selects attack action; attack action calls `resolve_exchange()`; attack produces narration; creature with `aggression=0` never attacks unprovoked |
| `test/creatures/test-predator-prey.lua` | `src/engine/creatures/init.lua` (prey detection) | WAVE-2 | Cat in room with rat → cat detects prey → cat selects chase/attack; rat detects predator → flee; prey detection only triggers for alive creatures; dead rat does not trigger cat chase |
| `test/creatures/test-creature-stimulus.lua` | `src/engine/creatures/init.lua` (stimulus) | WAVE-2 | `creature_attacks` stimulus emitted when creature attacks; `creature_died` emitted on death; `creature_fled` emitted on flee; stimuli reach creatures within `awareness.sound_range`; stimuli respect room boundaries |
| `test/creatures/test-creature-perf.lua` | `src/engine/creatures/init.lua` | WAVE-2 | 10 creatures in registry; `creatures.tick(context)` completes in <50ms (measured via `os.clock()`); no memory leak over 100 ticks (collectgarbage + check) |

### NPC-vs-NPC Combat Tests (WAVE-3)

| Test File | Module Under Test | Wave | Key Assertions |
|-----------|-------------------|------|----------------|
| `test/combat/test-npc-combat.lua` | `src/engine/combat/init.lua` (NPC path) | WAVE-3 | `resolve_exchange(cat, rat, cat_bite, "body")` produces result; NPC defense selection reads `combat.behavior.defense`; cat-vs-rat resolves to rat injury or death; both combatants use same `resolve_exchange()` as player combat |
| `test/combat/test-witness-narration.lua` | `src/engine/combat/narration.lua` | WAVE-3 | Lit room: visual narration string contains action verbs ("pounces", "bites"); dark room: audio narration ("you hear"); adjacent room: distant sound; no narration if player not in range; narration varies by severity (≥3 unique strings with seed 42) |
| `test/combat/test-multi-combatant.lua` | `src/engine/combat/init.lua` (turn order) | WAVE-3 | 3 creatures: turn order by speed (descending), size tiebreak (smaller first); player in fight: player acts at correct position in order; combat terminates when all opponents dead or fled; no infinite loops (max 20 rounds safety) |
| `test/combat/test-npc-morale.lua` | `src/engine/creatures/init.lua` (morale) | WAVE-3 | Creature at health < 30% → flee_threshold check fires; morale break mid-combat → creature exits fight; fled creature moves to adjacent room; morale does not trigger on dead creatures |

### Disease + Injury Tests (WAVE-4)

| Test File | Module Under Test | Wave | Key Assertions |
|-----------|-------------------|------|----------------|
| `test/injuries/test-disease-delivery.lua` | `src/engine/injuries.lua` (on_hit extension) | WAVE-4 | `on_hit = { inflict = "X" }` calls `injuries.inflict("X")`; probability field respected (100 trials, ±tolerance); `uses` field decrements and stops delivery at 0; works for both player and NPC targets |
| `test/injuries/test-rabies.lua` | `src/meta/injuries/rabies.lua` | WAVE-4 | Loads via `dofile()`; 4 states defined (incubating/prodromal/furious/fatal); transitions trigger on timer; `restricts.drink` in furious state; `healing_interactions` works for incubating and prodromal only; terminal state has `death_message`; damage_per_tick values correct per state |
| `test/injuries/test-spider-venom.lua` | `src/meta/injuries/spider-venom.lua` | WAVE-4 | Loads via `dofile()`; venom progression states defined; 100% delivery (no probability); damage_per_tick applies; movement restriction after threshold; cure mechanics (if any for Phase 2) |
| `test/injuries/test-disease-healing.lua` | `src/engine/injuries.lua` (healing path) | WAVE-4 | Poultice applied to `incubating` rabies → cured; poultice applied to `furious` rabies → no effect; healing checks `from_states` allowlist; injury removed from player on successful cure |

### Food + Bait Tests (WAVE-5)

| Test File | Module Under Test | Wave | Key Assertions |
|-----------|-------------------|------|----------------|
| `test/food/test-eat-drink.lua` | `src/engine/verbs/init.lua` (eat/drink handlers) | WAVE-5 | `eat` verb on food item → item consumed (removed from inventory); `eat` on non-food → rejection message; `drink` verb on liquid container → liquid consumed; `drink` blocked when `restricts.drink` active (rabies); eating spoiled food inflicts negative effect; uneaten food still in inventory |
| `test/food/test-bait.lua` | `src/engine/creatures/init.lua` (food stimulus) | WAVE-5 | Food item on ground emits `food_stimulus`; creature with hunger drive detects food in same room; creature moves toward food (priority over wander); creature consumes food (item removed); bait works cross-tick (not instant); no stimulus from food in closed containers |
| `test/food/test-food-objects.lua` | `src/meta/objects/cheese.lua`, etc. | WAVE-5 | Food items load; `edible=true` flag present; `nutrition` value defined; FSM states: `fresh → stale → spoiled`; `on_feel`, `on_smell`, `on_taste` present; keywords correct; material is food-appropriate |
| `test/food/test-food-spoilage.lua` | FSM on food objects | WAVE-5 | Fresh food transitions to stale after N ticks; stale transitions to spoiled after M ticks; spoiled food has modified `on_smell` (rotten); spoiled food `eat` effect is negative; spoilage timer pauses in closed containers (optional) |

### Integration + Scenario Tests (WAVE-5)

| Test File | Module Under Test | Wave | Key Assertions |
|-----------|-------------------|------|----------------|
| `test/integration/test-phase2-integration.lua` | Full Phase 2 system | WAVE-5 | Multi-command headless scenario: light → move → encounter creature → combat → disease check → eat food → bait → verify all subsystems integrate; zero crashes across 30+ commands; all Phase 1 features still work |

### Scenario Log Files (Created During Gate Runs)

| Directory | Gate | Contents |
|-----------|------|----------|
| `test/scenarios/gate0/` | GATE-0 | Empty (pre-flight, no scenarios) |
| `test/scenarios/gate1/` | GATE-1 | Empty (unit tests only) |
| `test/scenarios/gate2/` | GATE-2 | `p2-a-cat-chases-rat.txt`, `p2-b-wolf-attacks-player.txt`, `p2-c-spider-web-trap.txt` |
| `test/scenarios/gate3/` | GATE-3 | `p2-d-witness-cat-kills-rat.txt`, `p2-d2-witness-dark.txt`, `p2-e-multi-combatant.txt` |
| `test/scenarios/gate4/` | GATE-4 | `p2-f-rabies-progression.txt`, `p2-f2-spider-venom.txt` |
| `test/scenarios/gate5/` | GATE-5 | `p2-g-bait-cheese-rat.txt`, `p2-h-eat-drink.txt`, `p2-i-rabies-blocks-drink.txt`, `p2-j-full-end-to-end.txt` |

### Test Runner Registration (WAVE-0, Pre-Flight)

Bart adds these directories to `test/run-tests.lua` before any test files are created:

```lua
repo_root .. SEP .. "test" .. SEP .. "creatures",   -- already registered in Phase 1
repo_root .. SEP .. "test" .. SEP .. "combat",      -- already registered in Phase 1
repo_root .. SEP .. "test" .. SEP .. "food",         -- NEW for Phase 2
repo_root .. SEP .. "test" .. SEP .. "scenarios",    -- NEW for Phase 2
```

Phase 1 already registered `test/creatures/` and `test/combat/`. Phase 2 adds `test/food/` and `test/scenarios/`.

### Test Count Summary

| Category | New Test Files | Est. Test Cases | Wave |
|----------|---------------|-----------------|------|
| Creature definitions (4) | 5 files | ~60 | WAVE-1 |
| Creature combat + behavior | 4 files | ~40 | WAVE-2 |
| NPC-vs-NPC combat | 4 files | ~35 | WAVE-3 |
| Disease + injuries | 4 files | ~30 | WAVE-4 |
| Food + bait | 4 files | ~25 | WAVE-5 |
| Integration | 1 file | ~15 | WAVE-5 |
| **Total** | **22 files** | **~205 tests** | |

### Performance Budget Summary

| Metric | Budget | Measured At | Test File |
|--------|--------|-------------|-----------|
| Creature tick (10 creatures) | <50ms | GATE-2, GATE-5 | `test/creatures/test-creature-perf.lua` |
| Combat resolution (3 creatures) | <100ms | GATE-3, GATE-5 | `test/combat/test-multi-combatant.lua` |
| Disease tick (5 concurrent) | <10ms | GATE-4, GATE-5 | `test/injuries/test-disease-delivery.lua` |
| Full game tick (10 creatures + 5 diseases) | <150ms | GATE-5 | `test/integration/test-phase2-integration.lua` |
