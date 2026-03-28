# Pass-045: Kill Spider — Silk-Bundle Byproduct Drop

**Date:** 2026-03-27
**Tester:** Nelson
**Build:** `lua src/main.lua --headless`
**Scope:** Verify spider death drops silk-bundle byproduct, silk is takeable, has sensory text

## Executive Summary

| Metric | Value |
|--------|-------|
| **Total tests** | 7 |
| **Passed** | 3 |
| **Failed** | 4 |
| **Bugs found** | 1 (HIGH severity) |

Spider combat and death work correctly — the creature dies after sufficient attacks and the reshape narration fires ("The spider's abdomen splits, spilling a tangle of silk."). However, the silk-bundle byproduct **never actually spawns** into the room. The root cause is that `silk-bundle` is defined as an object file (`src/meta/objects/silk-bundle.lua`) but is never loaded into the registry because no room instance references it. The death byproduct code in `src/engine/creatures/death.lua` silently skips unregistered byproducts.

## Bug List

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-173 | HIGH | Silk-bundle byproduct never spawns — object not registered in registry |

## Methodology

Headless pipe-based testing per SKILL.md Pattern 1:

```
echo "goto deep-cellar\nlook\nattack spider\nattack spider\nattack spider\nlook\ntake silk\nfeel silk\ninventory" | lua src/main.lua --headless
```

Second run with expanded discovery commands:

```
echo "goto deep-cellar\nattack spider\nsearch around\nfeel around\nsearch silk\nsearch bundle\nfeel silk bundle\ntake silk bundle\nfeel dead spider" | lua src/main.lua --headless --debug
```

## Individual Tests

### T-001: `goto deep-cellar`
**Input:** `goto deep-cellar`
**Response:**
```
You materialize in The Deep Cellar.
**The Deep Cellar**
It is too dark to see. You need a light source. Try 'feel' to grope around
in the darkness.It is 2:00 AM.
The spider tenses, front legs raised. The web trembles.
Faint scratching, like tiny claws on stone.
A wolf paces the room, sniffing the air.
```
**Verdict:** ✅ PASS — Room loads correctly, spider and wolf react to player entry.

### T-002: `attack spider`
**Input:** `attack spider` (repeated until dead — took 1 command in run 1, multiple hits in run 2)
**Response (run 1):**
```
You can't see well — attacks will be less accurate.
You engage a large brown spider with bare fists!
A wet thud and sharp pain in a large brown spider's abdomen; the bone
bites into flesh.
The spider's abdomen splits, spilling a tangle of silk.
a large brown spider is dead!
```
**Verdict:** ✅ PASS — Spider dies, reshape narration fires correctly, death_state applied. Combat in darkness applies accuracy penalty as expected.

### T-003: `look` (after spider death)
**Input:** `look`
**Response:**
```
**The Deep Cellar**
It is too dark to see. You need a light source. Try 'feel' to grope around
in the darkness.It is 2:00 AM.
```
**Verdict:** ✅ PASS — Room displays correctly in darkness. No silk-bundle visible (expected in dark), but also not discoverable by any means (see T-004 through T-007).

### T-004: `take silk`
**Input:** `take silk`
**Response:**
```
You don't notice anything called that nearby. Try 'search around' to
discover what's here.
```
**Verdict:** ❌ FAIL — Silk-bundle should be on the room floor after spider death but is not discoverable.
**Bug:** BUG-173

### T-005: `feel silk`
**Input:** `feel silk`
**Response:**
```
You can't feel anything like that nearby. Try 'feel' to explore what's
around you.
```
**Verdict:** ❌ FAIL — Silk-bundle should be feelable in darkness. Object does not exist in room.
**Bug:** BUG-173

### T-006: `search around` / `feel around` (after spider death)
**Input:** `search around`, `feel around`
**Response (search):**
```
You begin searching...
On top of the stone altar, you feel: a brass incense burner, a tattered
scroll, a stone offering bowl.
You feel an open sarcophagus. You pull it open.
Inside the open sarcophagus, you feel: a small silver key.
You feel an iron chain — nothing there.
You feel the iron door — nothing there.
You feel a wide stone stairway — nothing there.
You feel a stone archway with an iron gate — nothing there.
You feel a dead spider — nothing there.
You feel a dead spider — nothing there.
You feel a grey wolf — nothing there.
You finish searching the area. Nothing interesting.
```
**Response (feel around):**
```
You reach out in the darkness, feeling around you...
  a stone altar
  an iron wall sconce
  an iron wall sconce
  an open sarcophagus
  an iron chain
  the iron door
  a wide stone stairway
  a stone archway with an iron gate
  a dead spider
  a dead spider
```
**Verdict:** ❌ FAIL — Silk-bundle does not appear in room proximity list. Dead spider is present and searchable, but no byproduct dropped alongside it.
**Bug:** BUG-173

### T-007: `inventory` (after attempting take)
**Input:** `inventory`
**Response:**
```
  Left hand: (empty)
  Right hand: (empty)
```
**Verdict:** ❌ FAIL — Confirms silk was never picked up (expected given T-004 failure).
**Bug:** BUG-173

## Bug Details

### BUG-173: Silk-bundle byproduct never spawns after spider death (HIGH)

**Severity:** HIGH — Blocks intended gameplay mechanic (byproduct crafting material)

**Reproduction:**
1. `goto deep-cellar`
2. `attack spider` (until dead)
3. `search around` or `feel around` or `take silk`
4. **Expected:** Silk-bundle appears on room floor, discoverable and takeable
5. **Actual:** Silk-bundle does not exist in room. No error or warning.

**Root Cause Analysis:**

The byproduct code in `src/engine/creatures/death.lua` lines 85–87:
```lua
if reg and type(reg.get) == "function" and reg:get(bp_id) then
    room.contents[#room.contents + 1] = bp_id
end
```

This checks `reg:get("silk-bundle")` before adding the ID to `room.contents`. However, `silk-bundle` is **never registered** in the registry because:

1. The object definition exists at `src/meta/objects/silk-bundle.lua` (GUID `{203f252d-61f6-4533-a379-f5ecb3880de4}`)
2. But no room's `instances` array references it — it's not placed in any room at world load
3. The loader only registers objects that are instantiated as room instances during Phase 1 of `main.lua`
4. So `reg:get("silk-bundle")` returns `nil`, the check fails, and the byproduct is silently skipped

The `reshape_narration` text ("The spider's abdomen splits, spilling a tangle of silk.") still fires because it's printed unconditionally at line 98 — giving the player the impression that silk dropped when it didn't.

**Suggested Fix:** The death byproduct system needs to **instantiate** the byproduct from its object definition file and register it in the registry before adding it to `room.contents`. The current code assumes byproducts are pre-registered, which conflicts with the design intent (byproducts are created on-demand at death time).

---

*Nelson — finds every crack.*
