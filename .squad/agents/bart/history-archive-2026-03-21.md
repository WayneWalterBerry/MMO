# Bart — History Archive (Early Sessions, 2026-03-19 to 2026-03-21)

## Archived Session Summaries

### Session: V2 Verb System & Tool Pipeline (2026-03-19T13-22)
**Status:** ✅ COMPLETE  
**Spawns:** 2 parallel background spawns

**Spawn 1:** Sensory Verbs (FEEL, SMELL, TASTE, LISTEN) + start time fix (6 AM → 2 AM for true darkness)
**Spawn 2:** Tool Pipeline (WRITE/CUT/PRICK verbs), tool resolution pattern, blood as virtual tool

**Decisions:** D-37 (sensory verbs), D-38 (tool resolution), D-39 (blood), D-40 (CUT/PRICK), D-41 (future stubs)

---

### Session: Compound Tools, Two-Hand Inventory, Consumables (2026-03-21)
**Status:** ✅ COMPLETE

**1. Two-Hand Inventory:** `player.hands = {nil, nil}` + `player.worn` + `player.skills`  
**2. Compound Tools:** STRIKE verb (match ON matchbox) + ephemeral state  
**3. Consumables:** Tick system, flame decay, candle burn, EAT/BURN verbs

**Files:** `src/engine/verbs/init.lua` (~350 lines), `src/main.lua` (player state), loop/init.lua (tick hook)

---

### Session: GUID Assignment (2026-03-21)
**Status:** ✅ COMPLETE

All 45 Lua files in src/meta/ assigned UUID v4 GUIDs. Added `_guid_index` to registry. Prepared for streaming architecture.

---

### Session: Instance/Base-Class Architecture (2026-03-21)
**Status:** ✅ COMPLETE

Implemented clean separation: immutable base classes (src/meta/objects/) vs. mutable instances (defined in rooms with `base_guid` + `location`).

**Key Pattern:** Instance `location` uses dot notation for surfaces (`"nightstand.top"`) and bare IDs for containers.

---

### Session: Feel Verb Fix (2026-03-21)
**Status:** ✅ COMPLETE

Fixed FEEL verb to enumerate container/surface contents (critical for darkness gameplay). Added surface-enumeration blocks to `src/engine/verbs/init.lua`.

---

## Archived Learnings (Core Principles)

1. **Deep-merge strategy:** When merging base classes with instance overrides, contents must be explicitly cleared and rebuilt — otherwise base contents leak
2. **Location notation:** Dot notation (`"parent.surface"` vs bare `"parent"`) is clean for parsing containment
3. **Registry pattern:** Pre-resolve templates into base classes before instance resolution
4. **Containment models:** Verbs must check both `obj.surfaces` (multi-zone) and `obj.container`/`obj.contents` (simple)
5. **Training data:** 54 verbs × 39 objects → ~30k training pairs via synonym/article/noun variations
6. **Extraction:** Python regex extraction of Lua metadata (no parser needed)

---

## Current Status

All early engine work complete. Ready for:
1. Play testing (new directives: empirical testing, visible misses)
2. Parser integration (Phase 3)
3. Cross-agent coordination (Comic Book Guy sensory descriptions, Frink browser port)
