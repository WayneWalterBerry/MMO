# Sound Plan Review — Moe (World Builder)

**Plan:** `projects/sound/sound-implementation-plan.md` + `sound-design-notes.md`  
**Date:** 2026-03-30  
**Verdict:** ✅ Approved  

---

## Findings

### 1. ✅ Room Ambient Design Excellent
Each of 7 rooms has a distinct ambient loop:
- **Bedroom:** `amb-bedroom-silence.ogg` — near-silence, settling stone
- **Hallway:** `amb-hallway-torches.ogg` — torch crackle dominant
- **Cellar:** `amb-cellar-drip.ogg` — water drips, deep echo
- **Storage Cellar:** `amb-storage-scratching.ogg` — rats + creaking wood
- **Deep Cellar:** `amb-deep-cellar-silence.ogg` — oppressive silence
- **Crypt:** `amb-crypt-void.ogg` — profound silence, rare stone settling
- **Courtyard:** `amb-courtyard-wind.ogg` — wind dominant, owl hoots, well winch

This is production-ready. Each loop complements the room's `description` field and creates atmosphere. ✅

### 2. ✅ Ambient Loop Per-Room Placement Clear
The plan says ambient loops load when a player enters a room and stop on exit. This maps cleanly to room instances:

```lua
-- bedroom.lua
return {
  id = "bedroom",
  name = "Master Bedroom",
  description = "...",
  ambient_loop = "amb-bedroom-silence.ogg",  -- NEW field
  instances = { ... }
}
```

(or as a property on the room object, details TBD with Bart).

**I can implement this.** ✅

### 3. ⚠️ **BLOCKER: Room Ambient Field Naming Undefined**
Similar to Flanders' concern: should the room ambient field be:
- `ambient_loop = "..."` (matches object naming)?
- `ambient_sound = "..."` (more intuitive)?
- `on_ambient = "..."` (follows on_* prefix)?

**Current risk:** If I use `ambient_loop` and Bart expects `on_ambient`, rooms won't load sounds.

**Recommendation:** Bart documents in `src/meta/rooms/SOUND-METADATA-SPEC.md`:
```markdown
## Room Sound Field

Every room may have optional ambient loop:
```lua
return {
  id = "bedroom",
  ambient_loop = "amb-bedroom-silence.ogg",  -- continuous while player in room
  ...
}
```

### 4. ⚠️ **BLOCKER: Room Exit Transition Sounds Undefined**
The design notes mention "Door/passage transitions" sounds (creak, clang, thud). But when a player moves between rooms, **who fires the transition sound?**

**Example:**
```
Player in Bedroom, types: north
Expected output (text): "You leave the bedroom and enter the hallway."
Expected output (sound): [door-creak-heavy.ogg plays]
```

**Question:** Does the exit object (e.g., the door between bedroom/hallway):
- (a) Have a `sounds = { on_verb_go = "door-creak.ogg" }`?
- (b) Have a `sounds = { on_traverse = "door-creak.ogg" }`?
- (c) Is the sound loaded from the room's exit definition?

**Current risk:** If Flanders adds sounds to door objects, and Bart hooks room traversal to fire door sounds, but they don't coordinate on which source is authoritative, I might get duplicate sounds or missed sounds.

**Recommendation:** Bart clarifies: "Room traversal fires door object's sound, not room's exit definition. Door object has `sounds = { on_traverse = "..." }`. Moe does NOT add sound fields to room exit definitions."

### 5. ✅ Ambient Loop Priority Clear
Ambient loops have priority: room > creature > object. So when a player enters a room:
1. Room ambient starts
2. If creature in room, creature ambient loops UNDER room ambient
3. If object has ambient (e.g., burning torch on table), it loops under creature

This prevents audio clutter. The plan specifies max 3 concurrent ambient loops. ✅ Understood.

### 6. ⚠️ Concern: Room Entry/Exit Hooks
The plan says sound_manager provides `enter_room(room)` and `exit_room(room)` methods. But:

**Question:** How does the game loop call these?

Is it:
- (a) Manually: game loop calls `sound_manager.enter_room(room)` after room text prints?
- (b) Automatic: loader hooks room transitions and fires sound_manager calls?
- (c) Part of effects pipeline?

**Current risk:** If the entry/exit hooks aren't wired, room ambients never start. Bart owns this integration, but I should understand it.

**Recommendation:** Bart documents in WAVE-2: "Game loop calls `sound_manager.enter_room()` after room text renders, and `exit_room()` before transitioning. This queues ambient load (async on web)."

### 7. ✅ Room Description Unchanged
Room descriptions describe **permanent features** (walls, floor, light, atmosphere). Sound fields are metadata, not part of description. This is correct Principle 0.5 architecture. ✅

### 8. ⚠️ Concern: Time-of-Day Room Variation
The design notes mention time-of-day affects ambient (e.g., courtyard sounds different at night vs. daytime). But WAVE-1 doesn't budget this.

**Question:** Does WAVE-1 create fixed ambients (always 2 AM atmosphere) or do I need to define time-variant fields like:
- `ambient_loop_night = "..."`
- `ambient_loop_day = "..."`

**CBG already flagged this as Phase 2.** So I assume MVP is fixed-ambient (permanent 2 AM). ✅

### 9. ✅ Courtyard as Unique Outdoor Space
The courtyard is the only outdoor room. Its ambient (`amb-courtyard-wind.ogg`) is distinct (wind, owl, well). This makes the courtyard feel different from cellars. ✅ Good design.

### 10. ⚠️ Concern: Per-Room Ambient Validation
The plan specifies Moe adds ambient declarations to 7 rooms, but doesn't define a validation test:
- Does test verify each room has `ambient_loop` field?
- Does test verify ambient filename matches a real file in `assets/sounds/`?

**Recommendation:** Nelson writes room-metadata validation test in WAVE-1 that checks every room either (a) has valid ambient_loop, or (b) explicitly sets `ambient_loop = nil`.

---

## Consolidated Verdict

**The room ambient design is excellent, but has 2 blockers around field naming and exit sound integration.**

### Blockers (Must Fix Before WAVE-1)

1. **Room ambient field naming:** Bart documents final naming in `src/meta/rooms/SOUND-METADATA-SPEC.md` (likely `ambient_loop`).
2. **Exit transition sounds:** Clarify that door objects (not room exits) fire transition sounds via `on_traverse` field. Moe does NOT add sound fields to room exit definitions.

### Concerns (Strongly Recommended)

3. Entry/exit hook integration: Bart documents how game loop calls `sound_manager.enter_room()` / `exit_room()`.
4. Per-room validation: Nelson writes test to verify all rooms have valid or nil `ambient_loop`.

---

**Reviewed by:** Moe (World Builder)  
**Confidence:** High (2 blockers are simple clarifications, overall design is solid)  
**Signature:** ✅ (pending blocker fixes)
