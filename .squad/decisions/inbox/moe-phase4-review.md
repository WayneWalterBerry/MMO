# Moe Phase 4 NPC Combat Review
**Reviewer:** Moe (World Builder)  
**Date:** 2026-08-16  
**Plan:** plans/npc-combat/npc-combat-implementation-phase4.md  
**Status:** 🔴 REJECT (3 Blockers)

---

## Review Summary

Phase 4 plan contains **world/room design scope** for spider placement, territorial marking room effects, web mechanics, and safe room definitions. After thorough analysis against my charter and the current world architecture, I found **3 critical blockers** that must be resolved before execution can proceed.

---

## Blockers

### ❌ BLOCKER 1: Incorrect Room Directory Path
**Severity:** CRITICAL  
**Location:** Plan section WAVE-4 (Spider Ecology) and WAVE-5 (Advanced Behaviors)  
**Issue:** Plan repeatedly references `src/meta/world/cellar.lua`, but actual directory is `src/meta/rooms/cellar.lua`.

- Instances found:
  - "Moe | **cellar spider placement** | Place spider in cellar.lua with appropriate spawn_point"
  - Multiple file change entries: `src/meta/world/cellar.lua | Moe | MODIFY`

**Current Reality:** Room definitions live in `src/meta/rooms/`, not `src/meta/world/`. Registry:
- ✅ `src/meta/rooms/cellar.lua` (EXISTS)
- ✅ `src/meta/rooms/start-room.lua` (EXISTS)
- ✅ `src/meta/rooms/courtyard.lua` (EXISTS)
- ✅ `src/meta/rooms/hallway.lua` (EXISTS)
- ✅ `src/meta/rooms/storage-cellar.lua` (EXISTS)
- ✅ `src/meta/rooms/crypt.lua` (EXISTS)
- ✅ `src/meta/rooms/deep-cellar.lua` (EXISTS)
- ❌ `src/meta/world/` (DOES NOT EXIST)

**Impact:** Flanders and I cannot execute spider placement tasks until this path is corrected. Test assignments reference wrong paths. Build system may fail to locate files.

**Fix Required:** Update all references from `src/meta/world/{room}.lua` → `src/meta/rooms/{room}.lua` throughout the plan.

---

### ❌ BLOCKER 2: Safe Room Definition Unresolved — No Metadata Spec
**Severity:** HIGH  
**Location:** Plan section "Q2: Stress Cure — Safe Room Definition" and WAVE-3 (Stress Injury)  
**Issue:** Plan recommends "Option A: No creatures" but provides NO metadata specification for rooms to declare themselves as safe or unsafe.

**Current Problem:**
- Stress injury cure requires: "Rest 2 hours in safe room → stress cleared"
- Recommendation: "Option A (no creatures). Simple, consistent with current ecosystem."
- **BUT:** No guidance on HOW I (Moe) should mark rooms as safe or what metadata field to use
- Unclear: Should start-room, hallway, etc. be marked `safe_room = true`? What about rooms with peaceful creatures (future NPCs)?

**Architectural Confusion:**
- Current room template (`src/meta/templates/room.lua`) has no `safe_room` field
- No guidance whether "safe" means:
  - Engine-enforced (check at load time)
  - Stress-system-only (checked during rest verb)
  - Player-discoverable (sensory feedback)

**Design Gap:** If stress cure uses engine-level room checks, Bart must define the metadata spec BEFORE I can modify rooms. If it's verb-level, Smithers owns it (parser/verbs). Ambiguity creates risk of inconsistent implementation.

**Required Clarification:**
1. Which metadata field? (`safe_room`, `is_safe`, `sanctuary`, etc.)
2. Which rooms are designated safe in Level 1? (bedroom? hallway? crypt? storage?)
3. Can safe designation be dynamic (e.g., safe if no active creatures)?
4. Is sensory feedback required? (e.g., "You feel at ease here")

---

### ❌ BLOCKER 3: Spider Placement in Cellar — Web Spawn Points Underspecified
**Severity:** MEDIUM  
**Location:** Plan section WAVE-4 (Spider Ecology), "Moe | **cellar spider placement**"  
**Issue:** Task states "Place spider in cellar.lua with appropriate spawn_point for web creation" but provides NO spatial specification.

**Ambiguities:**
1. **Spawn point location:** Where exactly in cellar should spider be placed?
   - On floor?
   - In corner (mentioned in narration: "spider spins web in the corner")?
   - On a specific object (barrel, brazier)?
   - Multiple possible locations?

2. **Web spawn constraints:** Where can webs appear?
   - Anywhere in room?
   - Corner only (atmospheric)?
   - Near specific objects?
   - Blocked by furniture?

3. **Room capacity:** Plan says "max 2 webs per room" but no guidance on:
   - Should room have explicit `max_web_spawn_points`?
   - What prevents web spam during long play sessions?
   - Do old webs despawn?

4. **Spatial relationships:** Cellar contains:
   - Barrel (can spider climb on it? under it?)
   - Torch-bracket (wall-mounted — spider avoids?)
   - Brazier (heat source — spider avoids?)
   - Exits (stairs, door)
   - Rat creature (existing)

**Impact:** Without spatial clarity, Flanders and I may create conflicting placements. Spider behavior tests (Nelson) will lack testable coordinates.

**Required Specification:** Write spatial topology for spider/web interaction in cellar:
```
EXAMPLE (needs Moe input):
- Spider: floor near barrel, south wall
- Web spawn: corners (near barrel/torch-bracket)
- Blocked zones: near brazier (heat), near exits
- Max active webs: 2 in cellar, 1 in adjacent rooms
```

---

## Conditional Approvals (If Blockers Resolved)

### ✅ APPROVED: Safe Room Sensory Design
**Assuming** safe room metadata is defined, my sensory design is sound:
- Rooms marked safe should have descriptive cues (calm air, peace, shelter language)
- Start-room is appropriate candidate (defensive position at top of stairs)
- Hallway could be secondary safe zone (multiple exits = player choice)

### ✅ APPROVED: Spider Web Visibility in Darkness
Plan recommends "Option C: Both" — player feels sticky threads in darkness, sees web with light. This aligns with existing sensory architecture:
- ✅ `on_feel = "Sticky silk threads cling to you"`
- ✅ Visual description only if lit
- Consistent with Principle 6 (Sensory space)

### ✅ APPROVED: Territorial Marking Room Effects
Plan defers territorial marking visibility to engine (Bart), but room-level effects are sound:
- Marked rooms can have scent narration: "You smell wolf musk here"
- No permanent room mutations needed
- Spatial adjacency queries (mark_radius = 2 rooms) are engine-driven
- No room redesign required

### ✅ APPROVED: Pack Tactics Room Interactions
Plan recommends "alpha wolf uses highest aggression" (emergent behavior). Room-level implications are minimal:
- Multiple wolves in one room → coordinated (engine handles)
- No room-specific behavior needed
- Spatial constraints (2+ wolves per room) already supported
- Existing room capacity is sufficient

---

## Minor Concerns (Non-Blocking)

1. **Rat creature placement:** Current `cellar-rat` in cellar.lua could be web victim. Confirm with Flanders that trapped rat behavior is tested.

2. **Brazier as light source:** Cellar has brazier but it's not lit by default. Spider ecology tests should clarify whether darkness affects web visibility in tests.

3. **Deep-cellar.lua unused:** Plan only mentions "cellar" but Level 1 has `deep-cellar.lua` (storage-cellar.lua exists too). Should spider appear in multiple cellars or just main one?

---

## Recommendation

**🔴 REJECT** until blockers are resolved:

1. **Bart:** Fix all `src/meta/world/` → `src/meta/rooms/` path references in plan
2. **Bart:** Specify safe room metadata (field name, default values, which rooms are safe)
3. **Moe & Flanders:** Collaborate on spatial topology for spider/web placement in cellar.lua

Once addressed, resubmit plan for **CONDITIONAL APPROVE** validation.

---

## Moe Checklist (Pre-Execution)

After blockers clear, I will:
- [ ] Verify `src/meta/rooms/cellar.lua` structure supports spider instance
- [ ] Add spider placement with clear position metadata
- [ ] Define web spawn zones (corners, distances from heat/exits)
- [ ] Mark safe rooms (`start-room`, others) with metadata field
- [ ] Add sensory descriptions for marked-room feeling
- [ ] Document room topology in `docs/rooms/cellar.md`
- [ ] Test spider behavior on cellar geometry (Nelson)

---

**Co-authored-by:** Copilot (agent: moe-phase4-review)
