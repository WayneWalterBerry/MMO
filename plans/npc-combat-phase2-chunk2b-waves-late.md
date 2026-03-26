# NPC + Combat Phase 2 — Chunk 2b: Waves 3–5 (Late)

**Author:** Bart (Architect) · **Date:** 2026-07-30
**Chunk:** 2b of 5 — WAVE-3 (NPC Combat), WAVE-4 (Disease), WAVE-5 (Food PoC)
**Refs:** `plans/combat-system-plan.md` §10, `resources/research/food/food-integration-notes.md`

---

## WAVE-3: NPC Combat Integration

**Depends on:** GATE-2 passed

| Track | Agent | Scope |
|-------|-------|-------|
| 3A | **Bart** | NPC-vs-NPC combat resolution, multi-combatant turn order |
| 3B | **Bart** | Creature morale — `flee_threshold`, cornered fallback |
| 3C | **Smithers** | Combat witness narration (light-dependent) |
| 3D | **Nelson** | Tests + LLM scenario |
| 3E | **Brockman** | NPC combat architecture doc |

### 3A — NPC-vs-NPC Combat (Bart)

**MODIFY** `src/engine/combat/init.lua`

- Extend `resolve_exchange()` for NPC combatants — same `body_tree` → zone → tissue-layer pipeline.
- `context.active_fights` tracking: `{ id, combatants, room_id, round }`. Full FSM phases apply.
- **Turn order** (3+ participants): speed (highest first) → size tiebreak (smaller first) → player last among equals.
- Pairwise resolution: 3-way = 2 exchange cycles/round (priority queue, per R-2).
- NPC target: `prey` list from metadata; fallback to `aggression` threshold.

### 3B — Creature Morale (Bart)

**MODIFY** `src/engine/creatures/init.lua`

- `flee_threshold` check after every RESOLVE phase. `health/max_health < threshold` → flee via random valid exit. Combat entry updated, narration emitted.
- **Cornered fallback:** no valid exits → `cornered` stance, `attack × 1.5`, cannot flee.
- Per-creature thresholds: rat 0.3, cat 0.4, wolf 0.2, spider 0.1 (in creature `.lua` by Flanders).

### 3C — Witness Narration (Smithers)

**MODIFY** `src/engine/combat/narration.lua`

- **Same room + light:** full visual, third-person framing via `narration.describe_exchange()`.
- **Same room + dark:** audio-only keyed to severity (GRAZE→scuffle, HIT→yelps, CRITICAL→death).
- **Adjacent room:** distant audio, 1 line max.
- **Out of range:** nothing emitted.
- Cap per R-9: 2 lines/exchange (same room), 1 line (adjacent), ≤6 lines/round.

### 3D — Tests (Nelson)

**CREATE** `test/combat/test-npc-combat.lua` (~25 tests)
Cat-kills-rat resolution, turn order (speed/size/player tiebreak), `active_fights` lifecycle, NPC target selection (prey + aggression fallback), multi-combatant no-infinite-loop, player joins active fight, morale flee success/fail, cornered fallback bonus, dead creature mutation.

**CREATE** `test/combat/test-witness-narration.lua` (~15 tests)
Lit visual narration, dark audio-only, adjacent distant, out-of-range silence, line cap enforcement, severity scaling, third-person framing.

**LLM scenario:** Player watches cat kill rat — `look` → `wait` → witness narration → `wait` → rat dies → `look at dead rat` confirms mutation.

### 3E — Docs (Brockman)

**CREATE** `docs/architecture/combat/npc-combat.md` — NPC resolution flow, combatant interface, turn order algorithm, `active_fights`, morale/flee, witness narration tiers.

### File Ownership — WAVE-3

| File | Action | Owner |
|------|--------|-------|
| `src/engine/combat/init.lua` | MODIFY | Bart |
| `src/engine/creatures/init.lua` | MODIFY | Bart |
| `src/engine/combat/narration.lua` | MODIFY | Smithers |
| `test/combat/test-npc-combat.lua` | CREATE | Nelson |
| `test/combat/test-witness-narration.lua` | CREATE | Nelson |
| `docs/architecture/combat/npc-combat.md` | CREATE | Brockman |

### GATE-3

All ~40 new tests pass. `test/run-tests.lua` zero regressions. LLM cat-kills-rat passes. Doc exists. Multi-combatant order verified (3+ creatures, fixed seed). `git diff --stat` clean. **~50 tests total.**

---

## WAVE-4: Disease System

**Depends on:** GATE-3 passed

| Track | Agent | Scope |
|-------|-------|-------|
| 4A | **Flanders** | Rabies injury FSM definition |
| 4B | **Flanders** | Spider venom injury FSM definition |
| 4C | **Bart** | Generic `on_hit` disease delivery in combat |
| 4D | **Bart** | Disease progression FSM + `hidden_until_state` in injuries engine |
| 4E | **Nelson** | Disease test files |

### 4A — Rabies (Flanders)

**CREATE** `src/meta/injuries/rabies.lua`

`category = "disease"`, `hidden_until_state = "prodromal"` (silent incubation).
FSM: `incubating`(15t, 0 dmg) → `prodromal`(10t, 1 dmg, restricts `precise_actions`) → `furious`(8t, 3 dmg, restricts `drink`+`precise_actions`) → `fatal`(1t, lethal).
`curable_in = {"incubating", "prodromal"}`. `transmission.probability = 0.15`.

### 4B — Spider Venom (Flanders)

**CREATE** `src/meta/injuries/spider-venom.lua`

`category = "disease"`, no hidden state (immediate symptoms).
FSM: `injected`(3t, 2 dmg) → `spreading`(5t, 3 dmg, restricts `movement`) → `paralysis`(8t, 1 dmg, restricts `movement`+`attack`+`precise_actions`).
`curable_in = {"injected", "spreading"}`. `transmission.probability = 1.0`.

### 4C — on_hit Disease Delivery (Bart)

**MODIFY** `src/engine/combat/init.lua`

After `resolve_exchange()` at severity ≥ HIT: check attacker's `natural_weapon.on_hit = { inflict = "disease_id", probability = N }`. Roll `math.random()` → call `injuries.inflict(target, disease_id)`. Fully generic — no creature-specific engine code (Principle 8). Symmetric for player-vs-NPC and NPC-vs-NPC.

### 4D — Disease Progression FSM (Bart)

**MODIFY** `src/engine/injuries.lua`

- `injuries.tick()` handles `category = "disease"`: decrement `state_turns_remaining`, transition per `transitions` table, apply `damage_per_tick`, emit `message`.
- **`hidden_until_state`:** suppress messages/visibility until state reached.
- **Healing:** `injuries.heal()` checks `curable_in`. Outside list → *"The treatment has no effect."*
- **`restricts`:** `injuries.get_restrictions(player)` returns merged set. Verb dispatcher checks before execution.
- Budget: <10ms for 5 concurrent diseases.

### 4E — Tests (Nelson)

**CREATE** `test/injuries/test-disease-delivery.lua` (~15 tests)
Prob 1.0 always delivers, 0.15 rate verified (fixed seed ±5), DEFLECT/GRAZE don't deliver, NPC-vs-NPC delivery, no `on_hit` → no error, concurrent diseases tick independently.

**CREATE** `test/injuries/test-rabies.lua` (~15 tests)
Incubation hidden, transitions at 15/25/33 ticks, `drink` blocked in furious, fatal kills, early cure works (incubating/prodromal), late cure fails (furious), `compute_health()` reflects disease damage, rabies + wound coexist.

**CREATE** `test/injuries/test-spider-venom.lua` (~15 tests)
Immediate symptoms, transitions at 3/8 ticks, movement/attack restrictions, cure in/out of window, venom + rabies independent.

### File Ownership — WAVE-4

| File | Action | Owner |
|------|--------|-------|
| `src/meta/injuries/rabies.lua` | CREATE | Flanders |
| `src/meta/injuries/spider-venom.lua` | CREATE | Flanders |
| `src/engine/combat/init.lua` | MODIFY | Bart |
| `src/engine/injuries.lua` | MODIFY | Bart |
| `test/injuries/test-disease-delivery.lua` | CREATE | Nelson |
| `test/injuries/test-rabies.lua` | CREATE | Nelson |
| `test/injuries/test-spider-venom.lua` | CREATE | Nelson |

### GATE-4

All ~45 new tests pass. `test/run-tests.lua` zero regressions. Rabies full FSM verified. Venom full FSM verified. `hidden_until_state` confirmed. Healing early/late verified. Concurrent diseases work. `git diff --stat` clean. **~45 tests total.**

---

## WAVE-5: Food Proof-of-Concept + Polish

**Depends on:** GATE-4 passed. Also uses creature behavior from WAVE-2 (hunger drive, stimulus).

| Track | Agent | Scope |
|-------|-------|-------|
| 5A | **Flanders** | Food objects: cheese, bread |
| 5B | **Smithers** | Eat/drink verb extensions |
| 5C | **Bart** | Bait mechanic (hunger drive + food stimulus) |
| 5D | **Nelson** | Tests + LLM end-to-end walkthrough |
| 5E | **Brockman** | Food system PoC doc |

### 5A — Food Objects (Flanders)

**CREATE** `src/meta/objects/cheese.lua`
Template `small-item`. Keywords `{"cheese","wedge","food"}`. Material `cheese`. `food = { edible=true, nutrition=20, bait_value=3, bait_targets={"rat","bat"} }`. FSM: `fresh`(30t) → `stale`(20t) → `spoiled`. All sensory fields including `on_feel`.

**CREATE** `src/meta/objects/bread.lua`
Template `small-item`. Keywords `{"bread","crust","food"}`. Material `bread`. `food = { edible=true, nutrition=15, bait_value=2, bait_targets={"rat"} }`. FSM: `fresh`(20t) → `stale`. All sensory fields including `on_feel`.

### 5B — Eat/Drink Verbs (Smithers)

**MODIFY** `src/engine/verbs/survival.lua`

- `eat`: find by keyword → check `food.edible` → check `restricts` → consume (remove from inventory/registry) → apply `food.nutrition` → emit `on_taste`.
- `drink`: same pattern, check `restricts.drink` (rabies blocks).
- Non-food: *"You can't eat that."* Spoiled: warning message.
- Aliases: `eat`/`consume`/`devour`, `drink`/`sip`/`quaff`.

**MODIFY** `src/engine/verbs/init.lua` — ensure survival module registered with eat/drink aliases.

### 5C — Bait Mechanic (Bart)

**MODIFY** `src/engine/creatures/init.lua`

- Creature tick gains hunger drive: `hunger_level` increments per tick, checks `hunger_threshold`.
- When hungry + food with matching `bait_targets` in same/adjacent room: creature moves toward food → consumes it (object removed, hunger reset).
- Narration: *"The rat scurries toward the cheese and devours it."*
- Bait priority: higher `bait_value` first. In-combat suppresses hunger.
- **Hard boundary (R-5):** no cooking, recipes, or spoilage-driven creature behavior.

### 5D — Tests + LLM (Nelson)

**CREATE** `test/food/test-eat-drink.lua` (~15 tests)
Eat cheese/bread consumed + nutrition, eat non-food rejected, eat without holding, eat in dark works, drink blocked by rabies, spoiled food warning, consume removes from registry, keyword disambiguation.

**CREATE** `test/food/test-bait.lua` (~10 tests)
Drop food + rat approaches, rat consumes food, adjacent room movement, `bait_value` priority, in-combat suppression, non-matching targets ignored, narration emitted, multi-creature eval.

**LLM end-to-end:** bedroom → feel nightstand → take candle → light → navigate to cellar → see rat → attack rat → check rabies → find cheese → drop as bait → rat approaches → eat bread → nutrition applied. Validates full WAVE-1–5 chain.

### 5E — Docs (Brockman)

**CREATE** `docs/design/food-system.md` — food metadata, eat/drink verbs, bait mechanic, PoC scope, refs to food-integration-notes for future expansion.

### File Ownership — WAVE-5

| File | Action | Owner |
|------|--------|-------|
| `src/meta/objects/cheese.lua` | CREATE | Flanders |
| `src/meta/objects/bread.lua` | CREATE | Flanders |
| `src/engine/verbs/survival.lua` | MODIFY | Smithers |
| `src/engine/verbs/init.lua` | MODIFY | Smithers |
| `src/engine/creatures/init.lua` | MODIFY | Bart |
| `test/food/test-eat-drink.lua` | CREATE | Nelson |
| `test/food/test-bait.lua` | CREATE | Nelson |
| `docs/design/food-system.md` | CREATE | Brockman |

### GATE-5

All ~25 new tests pass. `test/run-tests.lua` zero regressions (full baseline). LLM end-to-end passes. Doc exists. Food objects load with all required fields (including `on_feel`). Eat/drink works. Bait triggers rat approach. Rabies blocks drink (cross-wave). `git diff --stat` clean. **~35 tests + LLM.**

---

## Cross-Wave File Map

| File | W-3 | W-4 | W-5 | Owner |
|------|-----|-----|-----|-------|
| `src/engine/combat/init.lua` | 3A | 4C | — | Bart |
| `src/engine/creatures/init.lua` | 3B | — | 5C | Bart |
| `src/engine/injuries.lua` | — | 4D | — | Bart |
| `src/engine/combat/narration.lua` | 3C | — | — | Smithers |
| `src/engine/verbs/survival.lua` | — | — | 5B | Smithers |

No file modified by two agents in same wave. Gates enforce sequential completion.

**Totals:** 13 new files · 5 modified · ~130 tests · 3 LLM scenarios
