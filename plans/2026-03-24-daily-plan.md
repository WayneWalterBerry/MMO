# Daily Plan — 2026-03-24

**Owner:** Wayne "Effe" Berry  
**Focus:** Flexible Armor System, Material-Derived Protection, Object-Material Audit, Brass Spittoon  
**Created:** 2026-03-23 evening  

---

## Carry-Over from 2026-03-23

### Still Open Issues (need fix + regression tests)
- [ ] #47: Dark search uses "find/see" instead of "feel" narration
- [ ] #48: Search results dump all at once — should stream with clock advance
- [ ] #49: "stab yourself" should infer weapon from hand contents
- [ ] #52: Mirror shows only hand contents, not full appearance
- [ ] #53: "get pot" outputs take message twice — duplicate response
- [ ] #56: on_drop engine event + material fragility system (ceramic pot shatters on drop)
- [ ] #3: Screen flicker (Bart, queued)
- [ ] #41: "search the drawer" not distinct from nightstand

### Verify Fixed (need Marge to close)
- [ ] #46: Match search P0 — Smithers found root cause (fuzzy resolver hijack), fix deployed
- [ ] #50: Stab no injury — Flanders migrated knife to pipeline
- [ ] #55: Hit head no effect — Flanders migrated weapons to pipeline
- [ ] #54: Chamber pot wearable as helmet — Flanders implemented

---

## 🎯 TODAY'S MAIN FEATURE: Flexible Armor System

### Design Philosophy (Wayne's Directive)

Armor protection MUST be **derived from material properties**, not hardcoded per-object. The Dwarf Fortress principle: the engine operates on property bags, not named object types. A ceramic pot on your head protects based on ceramic's `hardness: 7` and `fragility: 0.7` — NOT because we wrote `reduces_unconsciousness = 1` on the pot object.

**Key insight:** We already have the material registry (`src/engine/materials/init.lua`, 22 materials with numeric property bags) and the Effects Pipeline interceptor infrastructure. The armor system connects these two existing pieces.

### What Exists Today

| Component | Status | Location |
|-----------|--------|----------|
| Material registry | ✅ 22 materials, 11 numeric properties each | `src/engine/materials/init.lua` |
| Wearable system | ✅ 9 slots, 3 layers, conflict resolution | `src/engine/verbs/init.lua` |
| Effects Pipeline | ✅ before/after interceptors | `src/engine/effects.lua` |
| Injury system | ✅ 7 injury types, FSM-based | `src/engine/injuries.lua` |
| Chamber pot helmet | ✅ hardcoded `provides_armor = 1` | `src/meta/objects/chamber-pot.lua` |
| Appearance system | ✅ worn items rendered in mirror | `src/engine/player/appearance.lua` |

### What's Missing (The Gap)

1. **No armor interceptor** — the before-effect interceptor infrastructure exists but no armor reduction logic is registered
2. **`provides_armor` is a meaningless number** — it's not derived from material properties, just a hardcoded 1
3. **No location matching** — head armor doesn't specifically block head injuries
4. **No material degradation** — ceramic helmet should crack/shatter after absorbing hits
5. **No armor template** — each wearable object reinvents armor metadata

### Architecture: How Armor Should Work

```
ATTACK: knife stab → Effects Pipeline → before-interceptor
                                            ↓
                                    Query: what is player wearing on {injury.location}?
                                            ↓
                                    Found: chamber-pot on head (material: ceramic)
                                            ↓
                                    Lookup: materials.get("ceramic") → hardness: 7, fragility: 0.7
                                            ↓
                                    Calculate: protection = f(hardness, flexibility, density)
                                    Calculate: break_chance = f(fragility, impact_force)
                                            ↓
                                    Apply: effect.damage = max(1, damage - protection)
                                    Roll: if break_chance met → armor state transition (crack/shatter)
                                            ↓
                                    Continue to inflict_injury handler (reduced damage)
```

### Armor Formula Design Considerations

**Protection value** derived from material properties:
- `hardness` (primary) — higher = more damage absorbed
- `flexibility` (secondary) — absorbs impact energy, prevents cracking
- `density` (tertiary) — heavier = more mass to stop force

**Damage type interaction:**
- Slashing (knife, dagger): countered by hardness
- Blunt (hit head, fall): countered by hardness + flexibility
- Piercing (stab): partially countered by hardness, flexibility helps less

**Degradation:**
- After absorbing a hit, check `fragility` vs impact force
- High fragility materials (ceramic 0.7, glass 0.9) → crack → shatter (FSM transition)
- Low fragility materials (brass 0.1, steel 0.05) → dent (cosmetic, minor protection loss)
- Fabric/leather (fragility 0.0) → never breaks, but lower protection

**Armor template** for objects:
```lua
-- Proposed: objects declare wear metadata, engine derives protection from material
wear = {
    slot = "head",
    layer = "outer",
    -- NO hardcoded provides_armor — engine calculates from material
    -- NO hardcoded reduces_unconsciousness — engine derives from slot + material
    coverage = 0.8,     -- how much of the slot this covers (full helm = 1.0, pot = 0.8)
    fit = "makeshift",  -- makeshift | fitted | masterwork — multiplier on protection
}
-- material = "ceramic" already on the object → engine does the rest
```

---

## Implementation Phases

### Phase A1: Architecture Doc — Armor System ✅→ Bart
- [ ] Bart: Write `docs/architecture/engine/armor-system.md`
  - How protection is derived from material properties (formulas)
  - How the before-effect interceptor queries worn items by injury location
  - Slot-to-location mapping (head slot → head injuries, torso slot → torso injuries)
  - Degradation model (fragility → crack → shatter FSM states)
  - Armor template specification (what objects declare vs what engine derives)
  - Integration diagram: materials.lua ↔ effects.lua ↔ injuries.lua ↔ wear system
  - Reference: existing `docs/architecture/engine/material-properties.md`
  - Reference: existing `docs/design/material-properties-system.md`

### Phase A2: Design Doc — Armor Behaviors ✅→ CBG
- [ ] CBG: Write `docs/design/armor-system.md`
  - Designer-facing guide: how to make an object act as armor
  - Material → protection table (what each material provides)
  - Degradation narratives (ceramic cracks with satisfying description)
  - Damage type × material type interaction matrix
  - Examples: ceramic pot vs steel helm vs leather cap vs sack-on-head
  - Brass spittoon as case study (see Phase D1 below)

### Phase A3: Unit Tests — Armor Before Implementation ✅→ Nelson
- [ ] Nelson: Write armor interceptor regression tests BEFORE implementation
  - Wearing armor reduces injury damage
  - Different materials provide different protection levels
  - Head armor only protects against head injuries (not torso)
  - Torso armor only protects against torso injuries (not head)
  - Material degradation: ceramic armor cracks after absorbing hit
  - Shattered armor provides zero protection
  - Stacking: inner + outer layers both contribute
  - No armor = full damage (baseline)
  - Makeshift fit vs fitted vs masterwork multiplier

### Phase A3b: Marge Gate
- [ ] Marge: Verify test suite passes on CURRENT code (tests should FAIL for armor features)
- [ ] Marge: Approve test coverage before implementation begins

### Phase A4: Implement Armor Interceptor ✅→ Smithers
- [ ] Smithers: Register before-effect interceptor in effects.lua
  - Query `ctx.player.worn` for items covering `effect.location`
  - Look up each worn item's material via `materials.get(obj.material)`
  - Calculate protection from `hardness`, `flexibility`, `density`
  - Reduce `effect.damage` (minimum 1 — armor never fully negates)
  - Narrate armor interaction ("Your ceramic pot absorbs some of the blow.")
  - Check degradation: roll against `fragility` × `impact_force`
  - If degraded → fire object FSM transition (intact → cracked → shattered)

### Phase A5: Verify Tests Pass ✅→ Nelson + Marge
- [ ] Nelson: Run full suite — armor tests should now PASS
- [ ] Marge: Gate — zero regressions in existing tests

### Phase A6: Equipment Event Hooks ✅→ Bart + Smithers
- [ ] Bart: Add **equipment** category to `docs/architecture/engine/event-hooks.md`
  - `on_wear` — fires when item is put on (slot, layer context)
  - `on_remove_worn` — fires when item is taken off
  - `on_equip_tick` — fires each turn while worn (future: rust, warmth, curse)
  - Use cases: pot smell narration, cursed items that resist removal, armor stat application
  - Wayne's insight: wearing is NOT currently an engine event — it's just a verb handler moving items between arrays. This must change for armor to work properly.
- [ ] Smithers: Implement on_wear / on_remove_worn hooks in wear verb handler
  - When item is worn: check for `on_wear` callback on object, fire it
  - When item is removed: check for `on_remove_worn` callback, fire it
  - These hooks are where armor registration happens (not hardcoded interceptors)

### Phase A6b: Event Output System (Instance-Level Flavor Text) ✅→ Bart (arch) + Smithers (impl)

**Wayne's design:** Objects can declare per-event output text that fires once, then self-removes via mutation. The engine doesn't track "has this been shown" — the object does. First-time flavor text lives on the object instance; after it fires, the engine mutates the field to `nil`.

**Architecture:**
- [ ] Bart: Design the `event_output` table pattern in event-hooks architecture doc
  - Objects declare an `event_output` table keyed by event name:
    ```lua
    event_output = {
        on_wear = "I need to get better outfits. I look like a peasant.",
        on_take = "It's heavier than it looks.",
    }
    ```
  - When an engine event fires (on_wear, on_take, on_drop, etc.), the engine checks `obj.event_output[event_name]`
  - If text exists → print it → mutate `obj.event_output[event_name] = nil` (one-shot)
  - This is a DATA pattern, not a CODE pattern — no callbacks, just strings on the object
  - The mutation is a .lua state change on the object instance (persists across saves)
  - Designers add flavor text without writing any Lua functions
  - Multiple events can have output — each fires independently, each is one-shot independently
  - **Wayne's clarification:** Flavor text lives on the ROOM .lua (object instance), NOT the object template. The room already defines object instances — `event_output` is per-instance data alongside `location`, `underneath`, etc. This means the same object template (e.g., wool-cloak) can have different flavor text in different rooms, or no flavor text at all. The template stays clean; the room author adds personality.

**Implementation:**
- [ ] Smithers: Add event_output check to every engine event dispatch point
  - After firing on_wear/on_take/on_drop/on_consume/etc., check `obj.event_output`
  - If `obj.event_output[event_name]` exists and is a string → `print(text)` → set to `nil`
  - This is ~5 lines added to each event dispatch, not a new system — it piggybacks on existing hooks

**First objects to use it:**
- [ ] Flanders: Add `event_output.on_wear` to wool-cloak:
  `"I need to get better outfits. I look like a peasant."`
- [ ] Flanders: Add `event_output.on_wear` to chamber-pot (in start-room.lua instance):
  `"This is going to smell worse than I thought."`
- [ ] Flanders: Add `event_output.on_wear` to terrible-jacket:
  `"It fits... barely. The sleeves are too short and it smells of mildew."`

**Tests:**
- [ ] Nelson: event_output tests
  - Wear wool cloak → flavor text prints
  - Wear wool cloak AGAIN → no text (already consumed)
  - Take an object with event_output.on_take → text prints once
  - Object without event_output → no error, no output
  - Multiple events on same object → each fires independently

### Phase A7: Migrate Chamber Pot ✅→ Flanders
- [ ] Flanders: Remove hardcoded `provides_armor = 1` and `reduces_unconsciousness = 1`
  - Protection now derived from `material = "ceramic"` → engine calculates
  - Keep `is_helmet = true` as a semantic tag (engine hint, not protection source)
  - Add `coverage = 0.8` and `fit = "makeshift"` to wear table
  - Add `on_wear` callback for smell narration
  - Add degradation states: intact → cracked → shattered (FSM)
  - Update `docs/objects/chamber-pot.md` design doc

### Phase A8: Update Architecture Docs ✅→ Bart
- [ ] Bart: Update `effects-pipeline.md` to v3.0 — document armor interceptor
- [ ] Bart: Update `event-hooks.md` — add on_drop hook for #56 + equipment category

---

## Phase B: Object-Material Audit

### Current State
- **79 total objects** in `src/meta/objects/`
- **77 have `material =` assigned** ✅
- **2 missing:** `ivy.lua`, `rat.lua`

### Phase B1: Audit + Fix ✅→ Flanders
- [ ] Flanders: Add material to missing objects:
  - `ivy.lua` → research appropriate material (plant fiber? Use existing or add new)
  - `rat.lua` → research appropriate material (bone/fur? Organic creature material)
- [ ] Flanders: Spot-check all 77 existing material assignments:
  - Does each object's material exist in `src/engine/materials/init.lua` registry?
  - Are any material names misspelled or referencing non-existent materials?
  - Flag any objects where the material feels wrong (e.g., a wooden object marked as iron)
- [ ] If new materials needed (e.g., "plant", "organic"), add them to `materials/init.lua` with full property bags

### Phase B2: Validation Tests ✅→ Nelson
- [ ] Nelson: Write material audit test
  - For every .lua file in `src/meta/objects/`, verify `material` field exists
  - For every material referenced, verify it exists in `materials.registry`
  - This is a structural test — runs as part of CI to prevent future regressions

---

## Phase C: Helmet Conflict Unit Tests

Wayne's directive: test wearing/swapping two helmets (ceramic pot + brass spittoon).

### Phase C1: Helmet Swap Tests ✅→ Nelson
- [ ] Nelson: Write `test/wearables/test-helmet-swap.lua`
  - Wear ceramic pot → verify on head, provides protection
  - Try to wear brass spittoon WHILE pot is worn → verify rejection ("already wearing X, remove it first")
  - Remove pot → verify head is free
  - Wear spittoon → verify on head, provides protection
  - Try to wear pot WHILE spittoon is worn → verify rejection
  - Remove spittoon → wear pot again → verify works
  - Full swap cycle: pot on → pot off → spittoon on → spittoon off → pot on
  - Verify DIFFERENT protection values (brass > ceramic due to material properties)
  - Verify brass spittoon does NOT shatter on head hit (low fragility)
  - Verify ceramic pot DOES crack/shatter on strong head hit (high fragility)
  - Mirror shows correct helmet in each state
  - Appearance text changes when swapping helmets

---

## Phase D: Brass Spittoon — New Object

### Design Intent
The brass spittoon is a comedic counterpart to the ceramic chamber pot. Both are improvised helmets, but brass is **durable** (fragility 0.1, hardness 6) while ceramic is **fragile** (fragility 0.7, hardness 7). The material system should make this difference emergent — designers declare the material, engine handles the rest.

**Brass material properties (already in registry):**
- density: 8500 (heavy!)
- hardness: 6 (decent protection)
- fragility: 0.1 (won't shatter)
- flexibility: 0.1 (rigid)

**Contrast with ceramic:**
- ceramic hardness 7 > brass hardness 6 (ceramic blocks more raw damage)
- BUT ceramic fragility 0.7 >> brass fragility 0.1 (ceramic shatters, brass dents)
- brass density 8500 >> ceramic density 2300 (brass is much heavier)

**Gameplay tradeoff:** Ceramic pot is lighter and slightly harder, but shatters after a hit or two. Brass spittoon is heavier but nearly indestructible. Players choose: disposable-but-light vs durable-but-heavy.

### Phase D1: Design Doc ✅→ CBG
- [ ] CBG: Write `docs/objects/brass-spittoon.md`
  - Physical description: tarnished brass bowl with wide rim, tobacco stains inside
  - Container: holds small items + liquids (it's a spittoon)
  - Wearable: head/outer slot, `is_helmet = true`, makeshift fit
  - Material: brass → engine derives protection + durability
  - Comedy: "The inside still smells of old tobacco" when worn
  - Smell penalty when worn, appearance description for mirror
  - Keywords: spittoon, brass bowl, cuspidor, spit bowl
  - Degradation: dents (cosmetic) but doesn't shatter
  - Weight penalty: brass is heavy (density 8500), affects... future stamina system?

### Phase D2: Implementation ✅→ Flanders
- [ ] Flanders: Create `src/meta/objects/brass-spittoon.lua`
  - material = "brass"
  - wear = { slot = "head", layer = "outer", coverage = 0.7, fit = "makeshift" }
  - is_helmet = true
  - Container (capacity = 2, holds small items)
  - on_smell_worn narration
  - appearance.worn_description for mirror
  - Keywords and aliases
  - FSM states: clean → stained → dented (cosmetic degradation only)

### Phase D3: Spittoon Tests ✅→ Nelson
- [ ] Nelson: Write `test/objects/test-brass-spittoon.lua`
  - Data structure validation
  - Wear as helmet, remove helmet
  - Container behavior (put small item in spittoon)
  - Smell narration when worn
  - Mirror appearance when worn
  - Does NOT shatter when hit (brass fragility = 0.1)
  - Protection value differs from ceramic pot
  - Can be dropped without breaking

---

## Phase E: on_drop Event + Material Fragility (#56)

### Phase E1: Architecture ✅→ Bart
- [ ] Bart: Add `on_drop` to `docs/architecture/engine/event-hooks.md`
  - New contact-category hook: fires when player drops an object
  - Engine checks material fragility vs surface hardness
  - If fragility threshold met → object FSM transitions (intact → shattered)
  - Spawns debris objects (ceramic-shard, glass-shard, etc.)

### Phase E2: Implementation ✅→ Smithers
- [ ] Smithers: Add on_drop handler to verb system
  - When player drops object: check `materials.get(obj.material).fragility`
  - Compare against floor/surface hardness (default stone floor = hardness 7)
  - Threshold: if `fragility >= 0.5` AND `surface_hardness >= 5` → break
  - Fire object FSM transition, spawn shards, narrate

### Phase E3: Tests ✅→ Nelson
- [ ] Nelson: Drop tests
  - Drop ceramic pot on stone floor → shatters, spawns ceramic shards
  - Drop brass spittoon on stone floor → clangs, doesn't break (fragility 0.1)
  - Drop glass bottle → shatters (fragility 0.9)
  - Drop wooden object → doesn't break (fragility 0.2)

---

## Phase F: Carry-Over Bug Fixes

### Phase F1: Remaining P1/P2 Bugs ✅→ Smithers
- [ ] #47: Dark search narration — "feel" instead of "find/see"
- [ ] #49: Stab weapon inference from hand contents
- [ ] #52: Mirror full appearance (not just hands)
- [ ] #53: Duplicate "get pot" output

### Phase F2: Regression Tests ✅→ Nelson
- [ ] Tests for each fix above

### Phase F3: Marge Verify + Close
- [ ] Marge: Verify #46, #50, #54, #55 (fixed yesterday) + close
- [ ] Marge: Verify F1 fixes + close

---

## Phase G: Deploy + Newspaper

### Phase G1: Final Deploy ✅→ Gil
- [ ] Gil: Deploy after all armor system work ships

### Phase G2: Evening Newspaper ✅→ Brockman
- [ ] Brockman: March 24 evening edition — armor system, material-derived protection, brass spittoon

---

## Dependencies

```
A1 (arch doc) ──┐
A2 (design doc)─┤
                ├→ A3 (tests) → A3b (gate) → A4 (implement) → A5 (verify) → A6 (migrate pot)
                                                                              → A7 (update docs)

B1 (audit) → B2 (validation tests)     [independent of A]

C1 (helmet swap tests)                  [depends on A4 + D2]

D1 (spittoon design) → D2 (implement) → D3 (tests)   [D1 independent, D2 after A4]

E1 (on_drop arch) → E2 (implement) → E3 (tests)      [independent of A, can parallel]

F1-F3 (bug fixes)                       [independent, can start immediately]

G1-G2 (deploy + newspaper)             [after everything else]
```

**Parallel tracks:**
- Track 1: Armor system (A1→A7) — main feature
- Track 2: Object-material audit (B1→B2) — can start immediately
- Track 3: Bug fixes (F1→F3) — can start immediately  
- Track 4: on_drop + fragility (E1→E3) — can start immediately
- Track 5: Brass spittoon (D1→D2→D3) — D1 starts immediately, D2 after A4

---

## Design Decisions (to be made during implementation)

1. **Should armor EVER fully negate damage?** Wayne's instinct: minimum 1 damage always gets through. Even plate armor doesn't make you invincible.
2. **Weight penalty?** Brass spittoon is 3.7x heavier than ceramic pot. Do we have a weight/encumbrance system? If not, note for future.
3. **Armor fit quality multiplier?** Makeshift (0.5x), fitted (1.0x), masterwork (1.5x) applied to material-derived base protection? Or simpler?
4. **Degradation rate:** Does ceramic crack on first hit, or probabilistic? Suggested: `fragility * (damage / 10)` as probability per hit.
5. **Shattered armor drops?** When ceramic pot shatters on your head, do shards fall to the ground? Spawn `ceramic-shard` objects?

---

## Process Rules

1. Nelson tests BEFORE implementation (write tests first, watch them fail, then implement)
2. Commit+push between every phase
3. Marge gates every phase transition
4. Every bug fix includes regression test (Wayne directive)
5. Architecture docs must match shipped code — no aspirational content
6. When object behavior changes, update design docs
7. Material-derived behavior is the goal — minimize per-object hardcoding
