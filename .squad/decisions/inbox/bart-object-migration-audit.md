# Effects Pipeline Compatibility Audit
## Objects Inventory & Migration Plan

**Audit Date:** 2026-03-24  
**Auditor:** Bart (Architect)  
**Scope:** All 79 objects in `src/meta/objects/`  
**Issue:** Wayne's play-test revealed knife stab verb doesn't create injuries (#50)

---

## Executive Summary

Of 79 total objects:
- **✅ Pipeline-routed:** 2 objects (poison-bottle, bear-trap)
- **🔴 Broken (migration needed):** 3 objects (knife, glass-shard, silver-dagger)
- **🟡 Legacy-working:** 0 objects (none found mid-transition)
- **⚪ No effects:** 74 objects (passive furniture, tools, decorations)

**Critical finding:** The knife, silver-dagger, and glass-shard have `on_stab`, `on_cut`, `on_slash` verb definitions with `damage` and `injury_type` fields, but **none are routed through `effects_pipeline = true`**. This breaks injury creation when players interact with these weapons.

---

## Full Inventory

### ✅ PIPELINE-ROUTED (2/5 objects migrated)

These objects correctly use the Effects Pipeline. They define `effects_pipeline = true` and route all effects through `effects.process()`.

| Object | Filename | Verbs | Features | Status |
|--------|----------|-------|----------|--------|
| bear-trap | bear-trap.lua | take, touch, feel, disarm | FSM (set→triggered→disarmed), injury routing, skill gate | ✅ Complete |
| poison-bottle | poison-bottle.lua | drink, pour, taste | FSM (sealed→open→empty), liquid effects, cork part | ✅ Complete |

**Pattern (bear-trap.lua, lines 25-27):**
```lua
-- Effects pipeline flag (D-EFFECTS-PIPELINE)
effects_pipeline = true,
```

Transitions define `effect` + `pipeline_effects` arrays. Engine processes via `effects.process()`.

---

### 🔴 BROKEN (3/5 objects need urgent migration)

These objects have `on_stab`, `on_cut`, or similar injury verbs with `damage` and `injury_type` fields, but **do not declare `effects_pipeline = true`**. When players interact with these weapons, the injury system never receives the effect—no wound creation, no damage tracking.

#### **knife** (knife.lua)
- **Problem:** Defines `on_stab` (damage=5, injury_type="bleeding") and `on_cut` (damage=3, injury_type="minor-cut"), but no `effects_pipeline = true`
- **Current code (lines 30-41):**
  ```lua
  on_stab = {
      damage = 5,
      injury_type = "bleeding",
      description = "You stab the knife into your %s. It hurts more than you expected.",
      pain_description = "A blunt, throbbing pain. The blade is not as sharp as a dagger.",
  },
  ```
- **Why it fails:** The engine sees `on_stab` but doesn't know to route it through the effects pipeline. No `effects.process()` call means `inflict_injury()` is never triggered.
- **Migration approach:** Add `effects_pipeline = true` and restructure on_stab/on_cut as pipeline effects.
- **Complexity:** Low — simple weapon with two injury types. No FSM needed.

#### **silver-dagger** (silver-dagger.lua)
- **Problem:** Defines `on_stab` (damage=8), `on_cut` (damage=4), and `on_slash` (damage=6), each with injury_type, but no `effects_pipeline = true`
- **Current code (lines 24-41):**
  ```lua
  on_stab = { damage = 8, injury_type = "bleeding", ... },
  on_cut = { damage = 4, injury_type = "minor-cut", ... },
  on_slash = { damage = 6, injury_type = "bleeding", ... },
  ```
- **Why it fails:** Same as knife—no pipeline routing.
- **Migration approach:** Add `effects_pipeline = true` and define pipeline effects for all three verbs.
- **Complexity:** Low — three injury types, no state changes. Treat as a multi-verb weapon.

#### **glass-shard** (glass-shard.lua)
- **Problem:** Defines `on_cut` (damage=3, injury_type="minor-cut") and `on_feel_effect = "cut"` (a legacy string reference), but no `effects_pipeline = true`
- **Current code (lines 9-10, 27-33):**
  ```lua
  on_feel_effect = "cut",  -- Legacy string, unclear meaning
  
  on_cut = {
      damage = 3,
      injury_type = "minor-cut",
      description = "You press the glass edge against your %s. The shard bites into skin.",
  },
  ```
- **Why it fails:** `on_feel_effect = "cut"` is a legacy field that doesn't route through the pipeline. The `on_cut` verb is similarly orphaned.
- **Migration approach:** Remove legacy `on_feel_effect` string. Add `effects_pipeline = true` and restructure `on_cut` as pipeline effect.
- **Complexity:** Low — single injury type, legacy cleanup needed.

---

### ⚪ NO EFFECTS (74/79 objects)

Pure passive objects with no effect metadata. These require **no migration** as they are not intended to create injuries or trigger effects. Includes:

- **Furniture:** bed, nightstand, wardrobe, side-table, vanity, torch-bracket, wall-sconce, wall-clock, stone-altar, etc.
- **Decorations:** portrait, curtains, rug, vase, skull, tattered-scroll, wall-inscription, pillow, blanket, etc.
- **Containers:** barrel, sack, crate (large/small), grain-sack, chamber-pot, offering-bowl, wine-rack, etc.
- **Light sources (FSM but no injury):** candle, torch, match, matchbox — these use FSM for state transitions (lit→unlit) but don't inflict injuries
- **Tools (no injury):** crowbar, rope-coil, chain, pen, pencil, paper, needle, thread, etc.
- **Consumables (no injury):** wine-bottle, oil-flask, bandage (treatment, not creation), tome, sewing-manual, etc.
- **Keys & trinkets:** brass-key, iron-key, silver-key, bronze-ring, burial-coins, burial-jewelry, burial-necklace, etc.
- **Flora:** ivy, rat, cobblestone, glass (as broken part), cloth/cloth-scraps, rag, cloth-scraps, etc.
- **Doors & structures:** wooden-door, locked-door, trap-door, stone-well, stone-sarcophagus, well-bucket, rain-barrel, window, etc.

**Example (crowbar.lua):** Provides tool to other objects (prying_tool, blunt_weapon, leverage) but has no `on_stab`, `on_cut`, or injury metadata. No migration needed.

---

## Migration Priority & Complexity Estimate

### **Priority 1 — CRITICAL (Week 1)**

| Object | Verbs | Estimate | Rationale |
|--------|-------|----------|-----------|
| **knife** | stab, cut | 1–2 hours | Player-facing weapon, explicitly mentioned in #50. Blocking play-test. |
| **glass-shard** | cut, feel | 45 min | Same severity, simpler (1 verb). Clean up legacy field. |

**Total P1 effort:** ~2.5 hours

### **Priority 2 — HIGH (Week 1-2)**

| Object | Verbs | Estimate | Rationale |
|--------|-------|----------|-----------|
| **silver-dagger** | stab, cut, slash | 2 hours | Ceremonial weapon, 3 verbs = more testing. Lower priority than knife but same pattern. |

**Total P2 effort:** ~2 hours

### **Priority 3 — FUTURE (After knife/glass-shard work)**

No additional objects queued for migration based on current codebase.

---

## Migration Checklist

For each broken object, apply this pattern (derived from bear-trap.lua, poison-bottle.lua):

### Step 1: Add pipeline flag
```lua
effects_pipeline = true,
```

### Step 2: Restructure verb handlers as pipeline effects

**From (current broken state):**
```lua
on_stab = {
    damage = 5,
    injury_type = "bleeding",
    description = "...",
    pain_description = "...",
},
```

**To (pipeline-routed):**
```lua
on_stab = {
    damage = 5,
    injury_type = "bleeding",
    description = "...",
    pain_description = "...",
    -- This entire table is now routed through effects.process()
    -- which normalizes it to an inflict_injury effect
},
```

Or if using full pipeline_effects (optional but explicit):
```lua
-- For verb-triggered transitions (FSM)
transitions = {
    {
        from = "ready", to = "used", verb = "stab",
        effect = {
            type = "inflict_injury",
            injury_type = "bleeding",
            damage = 5,
            message = "...",
        },
    },
},
```

### Step 3: Test with the effects system

Ensure the injury is created via `inflict_injury()` and the injury system receives it:
```
game/entities/injuries/bleeding.lua
game/entities/injuries/minor-cut.lua
```

### Step 4: Verify in play-test
- STAB SELF WITH knife → wound created ✓
- CUT SELF WITH glass-shard → wound created ✓
- STAB SELF WITH silver-dagger → wound created ✓

---

## Recommended Order

1. **knife** — Highest visibility, #50 blocker
2. **glass-shard** — Quick win, clears legacy field
3. **silver-dagger** — Last, lower priority but same pattern

This unblocks play-testing and establishes the pattern for any future weapon-like objects.

---

## Implementation Notes

### For Bart (Architect):

- **Decision:** Knife, glass-shard, and silver-dagger are weapon/tool objects with injury intent. They must declare `effects_pipeline = true`.
- **Pattern:** Injury verbs (`on_stab`, `on_cut`, etc.) with `damage` + `injury_type` are not passive metadata—they are **effect declarations** that trigger game mechanics. They require pipeline routing.
- **Implication:** Any future weapon-like object (e.g., club, sword, poison dart) must follow this pattern.

### For the implementation (later):

- Check if `effects.process()` already normalizes `on_stab`, `on_cut` tables, or if we need to add normalization logic.
- Verify injury system imports are in place (bleeding, minor-cut, crushing-wound, poisoned-nightshade).
- Consider adding a warning to the object validator: "Injury verb defined but `effects_pipeline != true`".

---

## Testing Scenarios

Once migrated, verify:

```
# Knife
> stab self with knife
← Wound (bleeding, damage 5)

> cut self with knife  
← Wound (minor-cut, damage 3)

# Glass-shard
> cut self with glass-shard
← Wound (minor-cut, damage 3)

# Silver-dagger
> stab self with silver-dagger
← Wound (bleeding, damage 8)

> slash self with silver-dagger
← Wound (bleeding, damage 6)

> cut self with silver-dagger
← Wound (minor-cut, damage 4)
```

All wounds should appear in `player.injuries` and persist until treated/healed.

---

## Appendix: Object Breakdown by Category

### FSM-Managed (State Transitions)

These are correctly using FSM. No injury issues.

| Object | States | Pipeline | Notes |
|--------|--------|----------|-------|
| candle | unlit, lit, extinguished, spent | No | Light source, timer-based, no injury |
| torch | lit, extinguished, spent | No | Same pattern as candle |
| match | unlit, lit, spent | No | Single-use light, FSM correct |
| bandage | clean, applied, soiled | No | **Treatment object, not injury creation** |
| bear-trap | set, triggered, disarmed | **Yes** | ✅ **Correctly uses pipeline** |
| poison-bottle | sealed, open, empty | **Yes** | ✅ **Correctly uses pipeline** |

### Consumable/Effect Objects (No Injury)

| Object | Purpose | Pipeline | Notes |
|--------|---------|----------|-------|
| wine-bottle | Beverage | No | No injury metadata |
| oil-flask | Fuel source | No | Non-consumable in player sense; refuel other objects |

### Tool Objects (No Injury)

| Object | Purpose | Pipeline | Notes |
|--------|---------|----------|-------|
| crowbar | Prying tool | No | Provides capability to other objects; no direct injury |
| rope-coil | Climbing/binding | No | Tool, not weapon |
| chain | Binding | No | Decoration/prop, not weapon |

---

## Related Issues & Decisions

- **#50:** "Wound doesn't take hold" — knife stab verb not creating injuries
- **D-EFFECTS-PIPELINE:** Decision record on effects routing architecture
- **D-INJURY001:** Injury system integration patterns
- **D-INJURY002:** Disarm mechanics for traps (bear-trap pattern)

---

## Sign-Off

Audit completed by Bart (Architect). Report ready for Wayne to prioritize migration.

All findings in human terms:
- **5 objects total have injury/effect intent**
- **2 are correctly on the pipeline** (poison-bottle, bear-trap)
- **3 are broken and need migration** (knife, glass-shard, silver-dagger)
- **74 are passive and need nothing**

Migration of the 3 broken objects is estimated at **~4.5 hours total work** and will unblock play-testing.
