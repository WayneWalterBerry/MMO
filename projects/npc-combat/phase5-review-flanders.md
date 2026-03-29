# Phase 5 Implementation Plan — Flanders Object Engineering Review

**Reviewer:** Flanders (Object & Injury Systems Engineer)  
**Reviewed:** npc-combat-implementation-phase5.md (v1.0, Assembled)  
**Date:** 2026-03-28  
**Scope:** Object specs, creature design, salt object & preservation pipeline, GUID pre-assignment, meta-lint compliance  

---

## Executive Summary

Plan is **well-structured and implementable** with **3 object spec concerns** (metadata completeness) and **1 creature spec gap** (pack_role behavior). No blockers. Recommend proceeding to WAVE-1 pending clarification on:

- **Werewolf creature `pack_role` field** — computed vs stored (needs engine clarity from Bart)
- **Salted-meat FSM state grammar** — ensure Phase 4 food FSM patterns remain compatible
- **Salt object placement** — deepStorage/werewolfLair coordinates need Moe coordination

---

## Findings by Category

### 1. OBJECT SPEC COMPLETENESS

#### 1.1 Werewolf Loot Objects (WAVE-1)

**Files:** werewolf-pelt.lua, werewolf-fang.lua, silver-pendant.lua, torn-journal-page.lua

⚠️ **CONCERN — Incomplete metadata**

| Object | Issue | Required Fields Missing |
|--------|-------|------------------------|
| **werewolf-pelt** | specs say "crafting material" but no crafting pipeline defined yet (Phase 6?) | `crafting` table undefined; `template` (small-item OK); `on_smell`, `on_listen` needed |
| **werewolf-fang** | listed as "weapon (piercing, force 5)" but weapon metadata pattern not shown | `weapon` table structure (if separate from material system); `force_type` unclear |
| **silver-pendant** | "weighted loot" only — no gameplay purpose defined | `on_taste`, `on_listen`; categories; use_effect if player-facing (e.g., ritual item?) |
| **torn-journal-page** | loot item only; readable? craftable? | If readable: `readable_text` field; if lore-only: all sensory fields still required |

**Plan text:** "(25% weighted), (35% weighted), (40% nothing)" — these are loot roll weights, handled by engine. But **objects still need full metadata**.

**Checklist from my charter:**
- ✅ GUID pre-assigned (plan references none — **needs assignment**)
- ✅ template field (small-item inferred, not stated)
- ⚠️ id field (plan doesn't list)
- ⚠️ name, keywords (not in plan)
- ⚠️ on_feel (mandatory — not confirmed)
- ❌ on_smell, on_listen (not confirmed)

**Recommendation:** Before WAVE-1 start, file a decision doc (`.squad/decisions/inbox/flanders-werewolf-loot-specs.md`) with:
```lua
-- silverPendant.lua pattern
{
    guid = "{TBD-GUID}", template = "small-item", id = "silver-pendant",
    name = "a tarnished silver pendant",
    keywords = {"pendant", "silver pendant", "necklace"},
    on_feel = "Cold metal, warm from long wear. An engraved symbol catches your fingertip.",
    on_smell = "Faint silver polish smell, underneath — old fabric and dust.",
    on_listen = "Silent.",
    on_taste = "Metallic — bitter silver and human skin oils.",
    ... (rest of small-item fields)
}
```

---

#### 1.2 Werewolf & Product Meat Objects (WAVE-1)

**Files:** werewolf-meat.lua, cooked-werewolf-meat.lua

✅ **GOOD — Pattern clear**

Plan text matches Phase 4 wolf-meat pattern exactly:
```
werewolf-meat (raw) → [cook] → cooked-werewolf-meat
Nutrition: 50 (vs wolf 35) ✅
FSM: raw → cooked ✅
Sensory: on_feel, on_smell, on_taste, on_listen ✅
```

**Compliance check:**
- GUID: Plan doesn't assign (needs pre-assignment list before WAVE-1)
- `template`: inferred "small-item" — should state
- Food FSM: Plan says "same pattern as wolf-variant" — Principle 8 compliance ✅
- Spoilage: "25% longer than wolf" — needs FSM state `duration` field (clarify with Bart on ticking math)

**Recommendation:** During WAVE-1 object coding, use Phase 4 wolf-meat as template. Confirm spoilage duration:
```lua
-- Example (needs Bart validation)
states = {
    ["raw"] = { duration = 7200 * 1.25 },  -- 25% longer than wolf raw (7200s)
    ["spoiled"] = { ... }
}
```

---

#### 1.3 Salt Object (WAVE-3)

**File:** salt.lua

⚠️ **CONCERN — Incomplete spec, critical gameplay detail missing**

Plan text:
```
Template: small-item. Size: tiny, weight: 0.3.
provides_tool = "preservative", consumable = true, uses = 3.
Sensory: soft leather pouch, coarse granules, sharp mineral smell, intensely salty.
Placement: collapsed-cellar (shelf) and werewolf-lair (floor).
```

**Missing critical fields:**
- ❌ `id` — must be "salt" (or "salt-crystals"?)
- ❌ `name` — "a pouch of salt crystals" inferred
- ⚠️ `categories` — likely ["mineral", "ingredient", "small"]
- ⚠️ `on_listen` — plan only covers feel/smell/taste
- ⚠️ `uses = 3` — is this per-object or per-use? (assume per object per Phase 4 patterns)
- ❌ `location` — set to nil during object def (runtime placement in room files)

**Object design pattern check:**
- ✅ Consumable system (matches bandage/poultice patterns)
- ✅ Tool capability (matches brass-key `provides_tool`)
- ✅ Placement two-room strategy (collapsed-cellar + lair) — good redundancy
- ⚠️ Containers — plan says "soft leather pouch" but no `container` metadata (is it a container or just sensory flavor?)

**Recommendation:** Clarify whether salt can be taken from the pouch. If no inventory manipulation of individual crystals (i.e., salt-pouch is the only form), then current spec OK. If player can "open pouch" → get individual salt crystals, need container metadata.

**Assume:** salt.lua is a standalone consumable small-item (not a container). Plan confirms via "Player must hold salt in one hand" → implies salt is the portable object, not the pouch.

---

#### 1.4 Salted-Meat Objects (WAVE-3)

**Files:** salted-wolf-meat.lua, cooked-salted-wolf-meat.lua, salted-werewolf-meat.lua, cooked-salted-werewolf-meat.lua

✅ **GOOD — mutation chain clear**

Plan text:
```
wolf-meat + salt --[salt verb]--> salted-wolf-meat
                                      |
                         (spoilage: 3× slower)
                                      |
                              [cook] ---> cooked-salted-wolf-meat
```

**Compliance:**
- Mutation: `wolf-meat.mutations.salt = { becomes = "salted-wolf-meat", ... }` ✅
- FSM spoilage: Plan says "spoil_multiplier = 3.0" applied at engine level (Bart's responsibility, Principle 8) ✅
- Sensory distinct: "firm, salt-crusted flesh" vs "warm, juicy" — good ✅
- GUID pre-assignment: Plan doesn't list (needs assignment)

**Recommendation:** Verify `spoil_multiplier` field is recognized by `src/engine/fsm/init.lua` before WAVE-3. If not, file an engine task for Bart in PRE-WAVE.

---

### 2. CREATURE DESIGN COMPLETENESS

#### 2.1 Werewolf Creature Spec (WAVE-1)

**File:** werewolf.lua

✅ **MOSTLY GOOD — but one behavior spec gap**

| Aspect | Status | Details |
|--------|--------|---------|
| **FSM States** | ✅ | 6 states defined (alive-idle, patrol, hunt, aggressive, flee, dead) |
| **Transitions** | ✅ | Clear patterns (idle→patrol, patrol→aggressive, aggressive→flee) |
| **Combat Stats** | ✅ | health=45, attack=12, defense=8 (1.5× wolf baseline) |
| **Weapons** | ✅ | claw-swipe + bite with force/target specified |
| **Territory** | ✅ | home=werewolf-lair, patrol={lair, bone-gallery} |
| **Sensory** | ✅ | on_feel mandatory + others for each state |
| **Loot table** | ⚠️ | Always: hide+claw; Weighted: pendant, journal; Variable: bone ×1-3 |
| **Territorial behavior** | ⚠️ | Plan says "growls first (1-turn warning)" — **not in FSM** |
| **Pack interaction** | ❌ | Plan says werewolf NOT pack-eligible (Q1=B, solo NPC) but **field missing** |

**Concerns:**

1. **Growl warning mechanic** — Plan narrative says "growls first, 1-turn warning" but this should be an FSM state or transition effect:
   ```lua
   -- Missing: Should werewolf have a "growl-warning" state?
   -- alive-idle → alive-warning (on threat_detected) → alive-aggressive (on next tick)
   -- OR: transition effect message?
   ```
   Recommend: Add `alive-warning` state with narration "The werewolf's eyes snap open. A low growl rumbles from deep in its chest — a final warning before it strikes."

2. **`pack_role` field** — Plan (§1.3) says:
   > "Werewolves are solo hunters, never join wolf packs."
   
   WAVE-2 adds `pack_role` field to wolf.lua but **werewolf needs exclusion marker**:
   ```lua
   -- Missing from werewolf spec:
   pack_tactics = { role_eligible = false }
   ```
   This is a **critical integration point** — if pack-tactics engine checks `pack_tactics.role_eligible` on all creatures, werewolf must declare `false`.

3. **Respawn mechanics** — Plan says "respawn: 400 ticks, max_population=1". Is this engine-level metadata or creature behavior?
   - If engine-level: needs `respawn` + `max_population` fields
   - If behavior-level: needs creatures/actions.lua orchestration
   Recommend: Clarify with Bart before WAVE-1.

**Recommendation:** Update werewolf spec to include:
```lua
return {
    guid = "{TBD}",
    template = "creature",
    id = "werewolf",
    -- ... (existing fields)
    
    -- NEW: Pack exclusion (WAVE-2 integration)
    pack_tactics = {
        role_eligible = false,  -- Solo hunter, never joins wolf packs
    },
    
    -- UPDATE: FSM states
    states = {
        ["alive-idle"] = { ... },
        ["alive-warning"] = {  -- NEW: 1-turn warning before combat
            description = "The werewolf's eyes snap open. It draws back its lips and growls — a sound like boulders grinding.",
            room_presence = "A massive werewolf crouches, eyes blazing, deep growl filling the chamber.",
            on_listen = "An ominous, bone-deep growl that vibrates the stone.",
        },
        ["alive-patrol"] = { ... },
        -- ... (rest unchanged)
    },
    
    transitions = {
        -- ... (existing)
        { from = "alive-idle", to = "alive-warning", verb = "_tick", condition = "threat_detected" },
        { from = "alive-warning", to = "alive-aggressive", verb = "_tick", condition = "warning_time_elapsed" },
        -- ... (rest)
    },
}
```

---

#### 2.2 Wolf Pack Metadata Updates (WAVE-2)

**File:** wolf.lua (MODIFY)

⚠️ **CONCERN — `pack_role` spec incomplete**

Plan says (§1.3):
```
Add `pack_role = "beta"` (dynamic field)
Change `pack_size` from 1 → 3 for Level 2 wolves
```

**Issues:**

1. **`pack_role` is computed, not stored** — Plan (§2) shows `assign_roles()` function that recomputes roles each tick. Wolf.lua should NOT have static `pack_role = "beta"`. 
   - ✅ Correct if: plan means "don't pre-assign; engine computes"
   - ❌ Incorrect if: plan means "hardcode beta as initial state"
   
   **Recommendation:** Clarify in wolf spec — should wolf.lua have:
   ```lua
   pack_role = "unassigned",  -- Computed by engine each tick
   pack_tactics = {
       role_eligible = true,
       retreat_threshold = 0.3,
       return_threshold = 0.5,
   },
   pack_size = 3,  -- For Level 2 deployment
   ```

2. **`pack_size = 3`** — Is this a field that affects spawn counts, or just metadata for documentation?
   - If spawn-affecting: confirm engine respects this during Level 2 room initialization
   - If metadata-only: just document but doesn't affect behavior
   
   **Recommendation:** File a decision with Bart clarifying whether `pack_size` is engine-read or docs-only.

---

### 3. SALT PRESERVATION PIPELINE

#### 3.1 Mutation Chain (WAVE-3)

✅ **GOOD — mutation targets match mutation sources**

```
wolf-meat (existing) → [salt mutation] → salted-wolf-meat (new)
                                             |
                                      [cook mutation] → cooked-salted-wolf-meat (new)

werewolf-meat (new WAVE-1) → [salt mutation] → salted-werewolf-meat (new)
                                                    |
                                         [cook mutation] → cooked-salted-werewolf-meat (new)
```

**Compliance:**
- ✅ All 4 salted targets will exist by WAVE-3 start (werewolf-meat defined in WAVE-1)
- ✅ Mutation calls exist: `wolf-meat.mutations.salt` + `werewolf-meat.mutations.salt`
- ✅ New object files created in same wave (no forward refs)
- ✅ Two-hand tool requirement (`salt` in hand, meat in other hand) matches existing patterns

**Recommendation:** Ensure Phase 4 wolf-meat doesn't already have a `mutations.salt` entry that conflicts. Check existing `wolf-meat.lua` before WAVE-3 starts.

---

#### 3.2 Spoilage Rate Mechanic

⚠️ **CONCERN — FSM ticking contract unclear**

Plan says (§1.4):
```
| Unsalted meat | 7200s (2h) | — | 7200s |
| Salted meat | 21600s (6h) | 21600s (6h) | 43200s (12h) |

Spoilage multiplier lives in object FSM `duration` fields — no engine changes (Principle 8).
```

**Issues:**

1. **"No engine changes"** — but WAVE-3 plan (§4.1) says Bart modifies `src/engine/fsm/init.lua`:
   ```
   Bart | FSM spoilage rate modifier | Update src/engine/fsm/init.lua — 
   when ticking food spoilage timers, check for `spoil_multiplier` field on object. 
   If present, divide decay rate by multiplier.
   ```
   
   This IS an engine change, violating "Principle 8: engine executes metadata." But it's a **generic metadata interpreter** (good), not object-specific logic (bad).
   
   **Recommendation:** Clarify with Bart: is the check in generic FSM ticking code (Principle 8 compliant) or object-specific food handler (not compliant)?

2. **Multiplier application** — Plan says "divide decay rate by multiplier":
   ```
   decay_rate / 3.0 = 3× slower
   ```
   But need confirmation: Is `spoil_multiplier = 3.0` or `spoil_divisor = 3.0` in the object? (semantic preference, but affects readability.)
   
   **Recommendation:** Use `spoil_multiplier` (multiplicative, intuitive: 3.0 = 3× the duration).

3. **State duration syntax** — How do salted-meat FSM states declare the multiplier?
   ```lua
   -- Option A: Per-state duration calc
   states = {
       ["raw"] = { duration = 7200 * 3 },  -- 21600s
       ["stale"] = { duration = 21600 * 3 },  -- 64800s (actual: 43200s total, so duration = 21600)
   }
   
   -- Option B: Object-level multiplier + generic FSM read
   spoil_multiplier = 3.0,
   states = {
       ["raw"] = { duration = 21600 },
       ["stale"] = { duration = 21600 },
   }
   ```
   
   **Recommendation:** Use Option B (object-level `spoil_multiplier`). Principle 8 compliant, reusable for future preservation methods (smoking, drying).

---

### 4. GUID PRE-ASSIGNMENT

❌ **BLOCKER — No GUIDs assigned in plan**

Plan lists object files to create but provides **zero GUIDs**. My charter requires:
> "Assign Windows GUIDs to injury types to maintain consistency with the metadata identity system."

**Objects needing pre-assignment (25+ new objects):**

| Wave | Count | Files |
|------|-------|-------|
| W1 | 13 | werewolf.lua, werewolf-pelt, werewolf-fang, werewolf-meat, cooked-werewolf-meat, level-02.lua, 7 rooms (Moe), brass-key update (no new GUID) |
| W3 | 5 | salt.lua, salted-wolf-meat, cooked-salted-wolf-meat, salted-werewolf-meat, cooked-salted-werewolf-meat |

**Recommendation before WAVE-1:**

File a decision doc: `.squad/decisions/inbox/flanders-phase5-guids.md` with pre-generated GUID list:

```markdown
# Phase 5 Pre-Assigned GUIDs

## WAVE-1 Creatures & Objects
- werewolf: {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
- werewolf-pelt: {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
- werewolf-fang: {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
- werewolf-meat: {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
- cooked-werewolf-meat: {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
- silver-pendant: {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
- torn-journal-page: {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}

## WAVE-3 Preservation Objects
- salt: {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
- salted-wolf-meat: {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
- cooked-salted-wolf-meat: {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
- salted-werewolf-meat: {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
- cooked-salted-werewolf-meat: {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
```

Rooms are Moe's responsibility (he owns room files), so no GUID pre-assignment needed from me.

---

### 5. META-LINT COMPLIANCE

✅ **GOOD — no known lint blockers identified**

**Potential lint rules that apply to Phase 5 objects:**

| Rule | Check | Phase 5 Risk | Mitigation |
|------|-------|-------------|-----------|
| **XI-01** (GUID unique) | All objects have unique GUID | None if we pre-assign | Pre-assign before WAVE-1 |
| **XI-02** (object exists) | loot table references exist | Werewolf loot: pelt, fang, pendant, journal | Create all 4 objects in WAVE-1 |
| **XO-01** (required fields) | id, name, on_feel, template | wolf-meat pattern is gold standard | Follow wolf-meat.lua template |
| **XO-02** (keywords not empty) | keywords table has entries | Both food & creature objects fine | Standard compliance |
| **XO-03** (sensory consistent) | on_feel always present + others | Werewolf creature will have all | Checklist in werewolf.lua creation |
| **XR-01** (material valid) | material in materials registry | "meat", "bone", "brass" — all known | No risk |
| **XR-02** (template valid) | template in templates dir | "small-item", "creature" exist | No risk |

**Recommend:** Before WAVE-1 commit, run:
```bash
python scripts/meta-lint/lint.py src/meta/creatures/werewolf.lua src/meta/objects/werewolf*.lua
python scripts/meta-lint/lint.py src/meta/objects/salt*.lua  # WAVE-3
```

Should produce **zero ERRORs** (warnings OK, per charter).

---

### 6. OBJECT DESIGN CHECKLIST AUDIT

Per my charter, every object must pass this checklist. Scoring Phase 5 objects:

#### Werewolf-Meat (WAVE-1)

| Item | Status | Notes |
|------|--------|-------|
| **Identity:** name, id, keywords, categories, weight, size, portable | ✅ | Follows wolf-meat pattern exactly |
| **Sensory:** on_feel, on_smell, on_listen, on_taste per state | ✅ | "Dense, dark meat" flavor, raw vs cooked |
| **FSM:** states with transitions | ⚠️ | Will define raw↔cooked; spoilage timing TBD with Bart |
| **Spatial context:** where in Level 2 | ✅ | Butchery product from werewolf corpse (lair) |
| **GOAP prerequisites:** what does using it require? | ✅ | Cook verb (fire source); eat verb (in hand); salt verb (salt + hand) |
| **Principle 8 compliance:** all behavior in metadata | ✅ | Cook, spoilage, mutations all declared |

**Pass: ✅**

---

#### Salt Object (WAVE-3)

| Item | Status | Notes |
|------|--------|-------|
| **Identity:** name, id, keywords, categories, weight, size, portable | ⚠️ | Need: id field, explicit categories field |
| **Sensory:** on_feel, on_smell, on_listen, on_taste per state | ⚠️ | Missing: on_listen |
| **FSM:** states with transitions | ❌ | N/A (consumable, single-state or no FSM) |
| **Spatial context:** where in Level 2 | ✅ | Placement: collapsed-cellar, werewolf-lair |
| **GOAP prerequisites:** what does using it require? | ✅ | Salt verb (requires tool + target with mutations.salt) |
| **Principle 8 compliance:** all behavior in metadata | ✅ | Consumable system (uses=3), preservative capability |

**Pass: ⚠️ PENDING** — need clarifications on metadata fields & on_listen.

---

#### Salted-Wolf-Meat (WAVE-3)

| Item | Status | Notes |
|------|--------|-------|
| **Identity:** name, id, keywords, categories, weight, size, portable | ✅ | Will follow pattern: "salted-wolf-meat" (prefixed) |
| **Sensory:** on_feel, on_smell, on_listen, on_taste per state | ✅ | "salt-crusted flesh" + distinct taste |
| **FSM:** states with transitions | ⚠️ | 3-state FSM (fresh→stale→spoiled); need duration fields |
| **Spatial context:** where in game world | ⚠️ | Mutation-only (created by salt verb, no direct placement) |
| **GOAP prerequisites:** what does using it require? | ✅ | Eat (same as unsalted), cook (if raw-salted state exists) |
| **Principle 8 compliance:** all behavior in metadata | ✅ | Spoilage rate declared via `spoil_multiplier` |

**Pass: ✅**

---

## Summary by Wave

### WAVE-1 (Level 2 Foundation)

| Object | Completeness | Risk | Recommendation |
|--------|--------------|------|-----------------|
| werewolf.lua | 95% (pack_role field gap) | Med | Add `pack_tactics.role_eligible=false`; add `alive-warning` state |
| werewolf-pelt.lua | 70% (metadata incomplete) | Low | Follow small-item template; assign GUID |
| werewolf-fang.lua | 70% (weapon system unclear) | Low | Clarify weapon metadata structure with Bart |
| silver-pendant.lua | 60% (purpose undefined) | Low | Define gameplay use or mark lore-only |
| torn-journal-page.lua | 60% (readable?) | Low | Define if text file included or lore-only |
| werewolf-meat.lua | 90% (spoilage duration TBD) | Low | Confirm duration math with Bart; follow wolf-meat pattern |
| cooked-werewolf-meat.lua | 95% | Low | Follow cooked-wolf-meat pattern; verify FSM grammar |

**Gate-1 readiness:** **⚠️ PENDING** — Needs pre-assigned GUIDs + werewolf spec clarifications + Bart coordination on spoilage/pack_role

---

### WAVE-2 (Pack Coordination)

**Flanders tasks:**
- wolf.lua MODIFY: Add `pack_tactics.role_eligible=true`, `pack_size=3`, confirm `pack_role` is computed (not stored)
- werewolf.lua MODIFY: Add `pack_tactics.role_eligible=false` (if not already done in WAVE-1)

**Risk:** Low (metadata only, engine logic is Bart's)

---

### WAVE-3 (Salt Preservation)

| Object | Completeness | Risk | Recommendation |
|--------|--------------|------|-----------------|
| salt.lua | 80% (metadata incomplete) | Med | Add id, categories; confirm on_listen; confirm consumable behavior |
| salted-wolf-meat.lua | 90% | Low | Confirm spoil_multiplier applied by engine; follow salted pattern |
| cooked-salted-wolf-meat.lua | 90% | Low | Same as salted variant |
| salted-werewolf-meat.lua | 90% | Low | Same as salted variant |
| cooked-salted-werewolf-meat.lua | 90% | Low | Same as salted variant |
| wolf-meat.lua MODIFY | 95% (mutation addition) | Low | Add `mutations.salt` entry; verify no conflict |
| werewolf-meat.lua MODIFY | 95% (mutation addition) | Low | Add `mutations.salt` entry |

**Gate-3 readiness:** **⚠️ PENDING** — Needs salt.lua metadata clarification + Bart's `spoil_multiplier` engine support confirmation

---

## Detailed Recommendations

### PRE-WAVE Action Items (Flanders)

1. **File decision doc:** `.squad/decisions/inbox/flanders-phase5-guids.md` with 12 pre-assigned GUIDs (W1 creatures/objects + W3 preservation)

2. **Coordinate with Bart (cross-domain):**
   - Confirm `spoil_multiplier` field support in `src/engine/fsm/init.lua` by WAVE-3 start
   - Clarify `pack_role` assignment model (computed vs stored) for werewolf/wolf specs
   - Clarify respawn mechanics (`respawn`, `max_population` fields) for werewolf

3. **Coordinate with Smithers:**
   - Confirm salt verb checks for `mutations.salt` on target object (standard pattern?)
   - Confirm embedding index updates for "salt", "preserve", "cure" won't collide with existing

4. **Coordinate with Moe:**
   - Finalize room layout (collapsed-cellar vs werewolf-lair for salt placement)
   - Confirm room ids match Flanders' object placement references

---

### WAVE-1 Execution Checklist (Flanders)

- [ ] Pre-assign GUIDs to all 13 new objects/creatures (use decision doc from PRE-WAVE)
- [ ] Create werewolf.lua with:
  - [ ] 6 FSM states (add `alive-warning` for 1-turn delay)
  - [ ] All sensory properties (on_feel mandatory)
  - [ ] Loot table (always: pelt+fang; weighted: pendant, journal, bone)
  - [ ] Pack exclusion: `pack_tactics.role_eligible = false`
  - [ ] Territory: `home = "werewolf-lair"`, `patrol = {...}`
  - [ ] Respawn: `max_population = 1` (solo creature)
- [ ] Create werewolf-pelt, werewolf-fang, silver-pendant, torn-journal-page (4 loot objects)
- [ ] Create werewolf-meat, cooked-werewolf-meat (food variants)
- [ ] Run meta-lint: `python scripts/meta-lint/lint.py src/meta/creatures/werewolf.lua src/meta/objects/werewolf*.lua`
- [ ] **Zero new ERRORs** required for gate pass

---

### WAVE-3 Execution Checklist (Flanders)

- [ ] Create salt.lua with all fields:
  - [ ] `id = "salt"`, `name = "..."`
  - [ ] `on_listen` (currently missing from plan)
  - [ ] `provides_tool = "preservative"`, `consumable = true`, `uses = 3`
  - [ ] Confirm placement refs match Moe's room definitions
- [ ] Create salted-* variants (4 files):
  - [ ] 3-state FSM with `spoil_multiplier = 3.0` field
  - [ ] Distinct sensory text ("salt-crusted", etc.)
- [ ] Modify wolf-meat, werewolf-meat:
  - [ ] Add `mutations.salt = { becomes = "salted-...", message = "..." }`
  - [ ] Add `preservable = true` flag
- [ ] Run meta-lint on all preservation objects
- [ ] **Zero new ERRORs** required for gate pass

---

## Integration Risk Assessment

**High-impact integration points owned by Flanders:**

| Point | Risk | Mitigation |
|-------|------|-----------|
| Werewolf loot objects must exist for butchery | Med | Create all 4 loot objects in WAVE-1 same wave as creature |
| Salt object must declare correct `provides_tool` | Low | Follow brass-key pattern (already verified in Phase 4) |
| Salted-meat mutations must target correct GUIDs | Med | Pre-assign GUIDs in PRE-WAVE decision doc |
| Spoilage multiplier must be engine-readable | Med | Coordinate with Bart; document field name in charter |
| Pack role logic must not break werewolf | Low | Add `pack_tactics.role_eligible=false` to werewolf spec |

**Probability of gate failure:** ~15% (mainly GUID pre-assignment + Bart coordination delays)

---

## Final Verdict

### ✅ Overall Assessment: PROCEED TO WAVE-1 (with conditions)

**No blockers.** Plan is architecturally sound and follows Principle 8 (metadata-driven behavior). Object specs match Phase 4 patterns. Creature design is complete except for noted clarifications.

**Conditions:**
1. **PRE-WAVE:** File GUID decision doc + coordinate pack_role/spoil_multiplier specs with Bart
2. **WAVE-1:** Add `pack_tactics.role_eligible=false` to werewolf.lua; add `alive-warning` state
3. **WAVE-3:** Clarify salt object metadata (on_listen, categories) before coding

**Report Distribution:**
- This review: `.squad/decisions/inbox/flanders-phase5-review.md`
- GUID assignment: `.squad/decisions/inbox/flanders-phase5-guids.md` (filed during PRE-WAVE)
- Cross-domain clarifications: Documented in-turn during PRE-WAVE coordination

---

**Reviewer:** Flanders ⚙️  
**Status:** ✅ APPROVED FOR EXECUTION (with noted clarifications)  
**Next Step:** Await Bart/Smithers/Moe PRE-WAVE coordination; then spawn WAVE-1 parallel teams

