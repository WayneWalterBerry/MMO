# Object Template Inheritance Audit — Pass 004

**Tester:** Lisa (Object Testing Specialist)
**Date:** 2026-03-21
**Requested by:** Wayne "Effe" Berry
**Scope:** All 74 object .lua files, 5 template files, 7 room files

---

## Executive Summary

I read every object file, every template, and every room definition. The bedroom (original) objects are rock-solid — correct templates, matching GUIDs, consistent patterns. But the Level 1 expansion objects have **serious structural problems**: invalid GUIDs, zero template usage, and type_id mismatches in every room file outside the bedroom. Four objects referenced from rooms don't even have .lua files yet.

**Verdict: The bedroom is production-quality. Everything else needs a wiring pass.**

---

## Templates Available

| Template | GUID | Key Defaults |
|----------|------|-------------|
| **container** | `f1596a51...` | portable=true, size=2, weight=0.5, container=true, capacity=4 |
| **furniture** | `45a12525...` | portable=false, size=5, weight=30, material=wood, container=false |
| **room** | `071e1b6a...` | Minimal room defaults (name, exits, contents) |
| **sheet** | `ada88382...` | portable=true, size=1, weight=0.2, material=fabric, tear→cloth |
| **small-item** | `c2960f69...` | portable=true, size=1, weight=0.1, container=false |

---

## Section 1: Template Reference Audit — All 74 Objects

### Objects WITH template references (17 objects) — All Correct ✅

| Object | Template | Correct? | Notes |
|--------|----------|----------|-------|
| bandage | small-item | ✅ | size=1, weight=0.1, portable — textbook small-item |
| bed-sheets | sheet | ✅ | fabric, portable, overrides size/weight |
| cloth | sheet | ✅ | fabric base material, has tear→cloth and crafting mutations |
| glass-shard | small-item | ✅ | size=1, weight=0.1, portable |
| knife | small-item | ✅ | Overrides weight=0.3 and categories for tool |
| matchbox | small-item | ⚠️ | See Finding #1 — it's a container masquerading as small-item |
| matchbox-open | small-item | ⚠️ | Same issue as matchbox |
| needle | small-item | ✅ | size=1, weight=0.05, tool |
| paper | small-item | ✅ | size=1, writable surface |
| pen | small-item | ✅ | size=1, writing_instrument tool |
| pencil | small-item | ✅ | size=1, writing_instrument tool |
| pin | small-item | ✅ | size=1, weight=0.05, skill-gated tool |
| rag | sheet | ✅ | fabric, size=1, weight=0.1 |
| sack | container | ✅ | container=true, capacity=4, wearable override |
| sewing-manual | small-item | ✅ | size=1, skill-granting readable |
| terrible-jacket | sheet | ✅ | fabric, wearable, tear→cloth×3 |
| thread | small-item | ✅ | size=1, weight=0.05, crafting material |

### Objects WITHOUT template references (57 objects)

#### 🔴 CRITICAL: Should have templates but don't

These are simple, static objects that match an existing template perfectly and would benefit from inheriting defaults:

| Object | Should Be | Why |
|--------|-----------|-----|
| **brass-key** | small-item | size=1, weight=1, portable=true, no FSM, no surfaces — classic small-item |
| **burial-coins** | small-item | size=1, weight=0.3, portable=true, static treasure |
| **burial-jewelry** | small-item | size=1, weight=0.05, portable=true, static treasure |
| **iron-key** | small-item | size=1, weight=0.5, portable=true — same pattern as brass-key |
| **silver-key** | small-item | size=1, weight=0.3, portable=true — same pattern as brass-key |
| **skull** | small-item | size=2 (slight override), weight=0.5, portable=true, static |
| **cobblestone** | small-item | size=2 (slight override), weight=2, portable tool |
| **silver-dagger** | small-item | size=2 (slight override), weight=0.5, portable tool/weapon |
| **blanket** | sheet | material=wool, portable, has `tear→{cloth, cloth}` mutation — exactly what sheet provides |
| **pillow** | sheet | material=linen, portable, has `tear→{cloth}` mutation |
| **wool-cloak** | sheet | material=wool, portable, has `tear→{cloth, cloth}` mutation |
| **chamber-pot** | container | container=true, capacity=2, portable=true — fits container template |

**Total: 12 objects should have templates but don't.**

#### 🟡 ADVISORY: FSM/Complex objects — Template not required

These objects are FSM-managed or have complex structure (surfaces, states, composites). They override virtually every template field, so a template reference would be purely documentary. The pattern across original AND expansion objects is consistent: **FSM objects don't use templates**. This is acceptable.

| Object | Type | Why No Template is OK |
|--------|------|----------------------|
| bed | furniture+surfaces+spatial | Overrides everything; has custom surfaces, spatial mechanics |
| candle | FSM (4 states) | Complex state machine with burn timers |
| candle-holder | FSM composite | Detachable candle part system |
| candle-stub | FSM (3 states) | Simplified candle variant |
| chain | FSM (2 states) | Puzzle mechanic |
| curtains | FSM (2 states) + sheet-like | Has tear mutation but also FSM; hybrid |
| grain-sack | FSM (3 states) + container | Nested container puzzle |
| ivy | FSM (3 states) | Environmental/climbable |
| large-crate | FSM (3 states) + container | Puzzle container |
| locked-door | FSM (1 state) | Boundary object |
| match | FSM (3 states) | Consumable fire source |
| nightstand | FSM composite (4 states) | Detachable drawer system |
| offering-bowl | FSM (2 states) | Puzzle trigger |
| oil-lantern | FSM (5 states) | Complex light source |
| poison-bottle | FSM composite (3 states) | Detachable cork system |
| rain-barrel | FSM (3 states) | Water source |
| rat | FSM (4 states) | Ambient creature |
| sarcophagus | FSM (2 states) | Openable container |
| small-crate | FSM (3 states) | Breakable container |
| stone-sarcophagus | FSM (2 states) | Deep cellar variant |
| tattered-scroll | FSM (2 states) | Readable lore |
| tome | FSM (2 states) | Critical lore object |
| torch | FSM (3 states) | Starts lit, consumable |
| trap-door | FSM (3 states) | Hidden discovery object |
| vanity | FSM (4 states) | Mirror+drawer system |
| vase | FSM (2 states) | Breakable decorative |
| wall-clock | FSM (24 states) | Cyclic time tracker |
| wall-sconce | FSM (2 states) | Light source holder |
| wardrobe | FSM (2 states) | Openable container |
| well-bucket | FSM (3 states) | Water retrieval tool |
| window | FSM (2 states) | Openable fixture |
| wine-bottle | FSM (4 states) | Multi-path consumable |
| wooden-door | FSM (3 states) | Unlockable door |

#### 🟡 ADVISORY: Static objects without clear template fit

| Object | Why No Template |
|--------|----------------|
| barrel | Non-portable container without container=true (see Finding #2) |
| bed (already listed above) | Complex furniture with surfaces |
| incense-burner | Portable container with surfaces — hybrid |
| portrait | Non-portable decorative — no "decorative" template exists |
| rope-coil | size=3, weight=3 — too large for small-item, not furniture |
| crowbar | size=3, weight=3 — too large for small-item, not furniture |
| rug | Non-portable fabric with spatial mechanics — hybrid |
| side-table | Static furniture with surface — could be furniture but overrides most fields |
| stone-altar | Static furniture with surfaces — could be furniture but stone, not wood |
| stone-well | Static structure with surfaces — no fitting template |
| torch-bracket | Static architecture fixture — no fitting template |
| wall-inscription | Static readable architecture — no fitting template |
| wine-rack | Static furniture with surfaces — could be furniture but has surfaces |

---

## Section 2: Field Conflicts with Templates

### 🔴 Finding #1: Matchbox objects declare small-item but are containers

**Objects:** `matchbox.lua`, `matchbox-open.lua`
**Template:** small-item (container=false, capacity=0)
**Actual fields:** container=true, capacity=10, contents=7 matches

The small-item template says `container = false, capacity = 0`. Both matchbox variants override these to become containers. This works at runtime because instance fields override template fields, but it's semantically misleading — a reader looking at `template = "small-item"` would not expect a container with 10-slot capacity.

**Recommendation:** Either create a "small-container" template, or switch matchbox/matchbox-open to `template = "container"` and override size/weight. Or accept the override pattern as intentional (small item that happens to hold things).

### 🔴 Finding #2: Barrel declares "container" category but lacks container fields

**Object:** `barrel.lua`
**Categories:** `{"wooden", "container"}`
**Missing fields:** No `container = true`, no `capacity`, no `contents = {}`

The barrel says it's a container by category but has none of the actual container mechanics. Either it needs `container = true` + `capacity` + `contents`, or the "container" category should be removed. A player trying to PUT something IN the barrel would get confusing results.

---

## Section 3: Room Instance type_id Audit

### 🟢 Bedroom (start-room.lua) — ALL 25 instances match ✅

Every `type_id` in start-room.lua exactly matches the `guid` in the corresponding .lua file. This is the gold standard.

### 🔴 CRITICAL: ALL other rooms have type_id mismatches

**Every single room instance outside the bedroom has a type_id that does NOT match the guid in the corresponding .lua file.** This affects 5 rooms and approximately 40+ object instances.

The root cause: **Level 1 expansion objects have invalid GUIDs.** Their .lua file guids contain non-hexadecimal characters (letters like h, k, n, s, t, x, z) that are not valid in UUID format.

**Examples of invalid GUIDs in .lua files:**

| Object | GUID in .lua file | Invalid chars |
|--------|-------------------|---------------|
| candle-stub | `91hsx61e-2c39-...` | h, s, x |
| chain | `c84fkt8r-5f66-...` | k, t, r |
| ivy | `46cns16z-d7e4-...` | n, s, z |
| cobblestone | `57dot27a-e8f5-...` | o, t |
| rain-barrel | `79fqv49c-0a17-...` | q, v |
| crowbar | `3f5bk9i0-c6d7-...` | k, i (ambiguous) |

Meanwhile, room instances reference properly-formed GUIDs (e.g., `b825e6ed-0ce7-4166-82a1-57d97ea51cee` for stone-well). The .lua files and the room files have **different** GUIDs and neither set is correct in both places.

**Room-by-room mismatch count:**

| Room | Instance Count | Mismatches |
|------|---------------|------------|
| cellar | 2 | 0 (barrel and torch-bracket have VALID guids that match) ✅ |
| courtyard | 5 | 5 ❌ |
| crypt | 11 | 11 ❌ |
| deep-cellar | 9 | 9 ❌ |
| hallway | 7 | 7 ❌ |
| storage-cellar | 13 | 13 ❌ |

Wait — cellar is actually fine! barrel.lua and torch-bracket.lua have valid hex GUIDs that match their room type_ids. So the problem is specifically the expansion objects added AFTER the cellar.

### 🔴 CRITICAL: Missing .lua files — 4 objects referenced from rooms don't exist

| Room | Instance ID | Type | type_id | Status |
|------|-------------|------|---------|--------|
| storage-cellar | oil-flask | Oil Flask | `1afa6416-...` | ❌ **NO .lua FILE** |
| storage-cellar | cloth-scraps | Cloth Scraps | `5bd1e52c-...` | ❌ **NO .lua FILE** |
| crypt | bronze-ring | Bronze Ring | `f9e5b47b-...` | ❌ **NO .lua FILE** (burial-jewelry exists but has different id) |
| crypt | burial-necklace | Burial Necklace | `099be501-...` | ❌ **NO .lua FILE** |

These objects will cause runtime errors when the engine tries to load these rooms.

---

## Section 4: Pattern Consistency — Bedroom vs Level 1 Expansion

| Aspect | Bedroom (Original) | Level 1 Expansion |
|--------|--------------------|--------------------|
| GUIDs in .lua files | Valid UUID format (hex only) | Invalid — contain non-hex chars |
| Room type_ids match .lua guids | ✅ Perfect match | ❌ Zero matches |
| Template usage on simple objects | Consistent (cloth→sheet, knife→small-item, etc.) | None — no expansion object uses templates |
| Missing object files | None | 4 files missing |
| Container field consistency | Consistent (container=true + capacity + contents) | Barrel has "container" category but no container fields |

**The bedroom was built with care. The expansion rooms were wired up with placeholder GUIDs that were never reconciled.**

---

## Section 5: Room Template Usage

All 7 room files correctly declare `template = "room"` ✅

| Room | template | Correct? |
|------|----------|----------|
| cellar | room | ✅ |
| courtyard | room | ✅ |
| crypt | room | ✅ |
| deep-cellar | room | ✅ |
| hallway | room | ✅ |
| start-room | room | ✅ |
| storage-cellar | room | ✅ |

---

## Bug Report Summary

### 🔴 BUG-004-A: Room instance type_ids don't match .lua GUIDs (CRITICAL)

- **Severity:** 🔴 CRITICAL — engine cannot resolve base classes for ~35 expansion object instances
- **Affected:** courtyard, crypt, deep-cellar, hallway, storage-cellar (all rooms except bedroom and cellar)
- **Root cause:** Expansion .lua files have invalid non-hex GUIDs; room files have different (valid) GUIDs
- **Fix:** Either update .lua GUIDs to match room type_ids, or update room type_ids to match .lua GUIDs. I recommend replacing all invalid .lua GUIDs with the valid GUIDs from the room files, since room instance data appears to have the correct (properly generated) values.

### 🔴 BUG-004-B: Missing object .lua files (CRITICAL)

- **Severity:** 🔴 CRITICAL — runtime errors on room load
- **Missing files:** oil-flask.lua, cloth-scraps.lua, bronze-ring.lua, burial-necklace.lua
- **Fix:** Create these 4 files, or remove the references from room instance lists

### 🟡 BUG-004-C: 12 static objects missing template references (MEDIUM)

- **Severity:** 🟡 MEDIUM — no runtime impact, but violates template inheritance pattern
- **Objects:** brass-key, burial-coins, burial-jewelry, iron-key, silver-key, skull, cobblestone, silver-dagger, blanket, pillow, wool-cloak, chamber-pot
- **Fix:** Add `template = "small-item"`, `template = "sheet"`, or `template = "container"` as appropriate

### 🟡 BUG-004-D: Matchbox template mismatch (LOW)

- **Severity:** 🟡 LOW — works at runtime due to field overrides
- **Objects:** matchbox.lua, matchbox-open.lua
- **Issue:** Declares template="small-item" but is actually a container (container=true, capacity=10)
- **Fix:** Either change to template="container" or accept as intentional override

### 🟡 BUG-004-E: Barrel missing container mechanics (MEDIUM)

- **Severity:** 🟡 MEDIUM — misleading category
- **Object:** barrel.lua
- **Issue:** Has "container" in categories but no container=true, no capacity, no contents
- **Fix:** Either add container fields or remove "container" from categories

---

## Recommendations

1. **Immediate:** Fix BUG-004-A and BUG-004-B before any gameplay testing of Level 1 expansion rooms. Nothing outside the bedroom will load correctly without GUID reconciliation and missing files.
2. **Short-term:** Add template references to the 12 static objects identified in BUG-004-C for consistency.
3. **Process:** Establish a GUID generation step when creating new objects — use proper UUIDs from the start, and wire room type_ids at the same time.

---

*Audit complete. 74 objects examined, 7 rooms examined, 5 templates examined.*
*Lisa out. 🎯*
