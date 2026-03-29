# Sound Plan Review — Flanders (Object Engineer)

**Plan:** `projects/sound/sound-implementation-plan.md` + `sound-design-notes.md`  
**Date:** 2026-03-30  
**Verdict:** ⚠️ Concerns  

---

## Findings

### 1. ✅ Sound Metadata Spec Clear
Every object gets optional `sounds = { ... }` table with fields:
- `ambient_loop = "rat-idle.ogg"` (continuous while in room)
- `on_state_{state} = "sound-id.ogg"` (fired on FSM transition)
- `on_verb_{verb} = "sound-id.ogg"` (fired on verb action)
- `on_mutate = "sound-id.ogg"` (fired on mutation)

This is Principle 8 compliant (objects declare behavior, engine executes). Clean.

### 2. ✅ Creature Vocalization Chart Production-Ready
The design notes contain a detailed table:
| Creature | State | Sound | Priority |
| Rat | idle | rat-idle.ogg | T1 |
| ... | ... | ... | ... |

This IS the spec. I can implement creatures directly from this chart.

### 3. ⚠️ **BLOCKER: GUID Pre-Assignment Missing**
The implementation-plan SKILL (Pattern 15) says: **"GUID pre-assignment: Architect reserves all GUIDs before wave starts in a decision inbox file. Prevents collisions during parallel authoring."**

But I don't see this in the sound plan. Bart must pre-assign GUIDs for:
- 15+ objects getting `sounds` tables
- All new sound-related objects (if any)

**Current risk:** If Flanders and Moe both create objects in WAVE-1 and generate GUIDs independently, collision is possible (unlikely but violates safety protocol).

**Recommendation:** Before WAVE-1 starts, Bart writes `.squad/decisions/inbox/bart-sound-guids.md` with pre-assigned GUIDs for all objects Flanders/Moe will modify.

### 4. ⚠️ **BLOCKER: Field Naming Convention Unclear**
The plan uses mixed naming:
- `ambient_loop` — snake_case, clear
- `on_state_*` — underscore prefix + state name
- `on_verb_*` — underscore prefix + verb name
- `on_mutate` — no state suffix

But the existing object definitions use:
- `on_feel`, `on_listen`, `on_smell` — prefix only, no suffix

**Question:** Should sound fields follow the same `on_*` prefix pattern?
- Proposed: `on_ambient_loop` instead of `ambient_loop`?
- Or stick with `ambient_loop` for clarity?

**Current risk:** Inconsistent object definitions if not standardized before Flanders writes objects.

**Recommendation:** Bart documents the final naming convention in `src/meta/objects/SOUND-METADATA-SPEC.md`:
```markdown
## Field Naming Convention

### For sensory states (existing):
- on_feel, on_listen, on_smell, on_taste

### For sound events (new):
- ambient_loop = "..." -- continuous loop while object in room
- on_state_{state} = "..." -- FSM transition sound
- on_verb_{verb} = "..." -- verb action sound
- on_mutate = "..." -- mutation/destruction sound
```

### 5. ⚠️ **BLOCKER: on_feel Consistency**
The core principle (D-1) says every object MUST have `on_feel` — it's the primary sense in darkness.

Sound system adds optional `ambient_loop` (e.g., rat creature has ambient purr while alive). But if the creature dies, the ambient stops. The text says "Nothing. The purr is gone."

**Question:** When a creature dies:
1. Does `on_feel` update to describe the dead body? (E.g., "Cold, stiff fur.")
2. Or does the dead creature become a separate object (like mirror-broken)?
3. Or is the creature simply removed from the room?

The sound plan doesn't address creature death state. This affects whether sound manager calls `stop_by_owner()` or if the object is fully deleted.

**Recommendation:** Add to design doc: "Creature death state transition: (a) FSM → dead state, (b) on_listen text changes to silence, (c) ambient_loop stops, (d) on_feel remains (dead body texture), or (e) creature object deleted entirely? **Clarify before WAVE-2.**"

### 6. ⚠️ Concern: Object Size vs Sound Table
Some objects are TINY (pin, needle, thread, skull). Adding a `sounds` table adds ~30 bytes per object. Multiplied by 74+ objects, that's ~2.2 KB extra even if most `sounds` are nil.

**This is not a blocker** (Lua tables are efficient), but it's worth noting: every object definition gets slightly heavier. By design, but worth auditing.

### 7. ✅ Sensory Complement Smart
Objects with `on_listen = "..."` (e.g., "water dripping") now get `ambient_loop = "water-drip.ogg"`. The sound reinforces what `on_listen` already describes. Perfect.

### 8. ⚠️ Concern: Mutant Objects & Sound Tables
When a candle mutates from "intact" → "broken" and becomes a new object (`candle-broken.lua`), does it inherit the `sounds` table?

**Example:**
```lua
-- candle.lua
return {
  id = "candle",
  sounds = { on_state_lit = "candle-ignite.ogg" }
  mutations = { break = { becomes = "candle-broken" } }
}

-- candle-broken.lua
return {
  id = "candle-broken",
  sounds = { ??? }  -- What here?
}
```

If `candle-broken` has no `sounds` table, the `sound_manager.scan_object()` call on the new object is a no-op. Is that correct? Or should mutants inherit parent sounds (with exclusions)?

**Recommendation:** Bart specifies in mutation hook: "On mutation, sound_manager.stop_by_owner(old_obj_id), then scan_object(new_obj)."

### 9. ✅ Object Audit Thoroughness Excellent
Sound-design-notes.md categorizes every object:
- **Tier 1 (must-have):** 30+ objects
- **Tier 2 (high-value):** 20+ objects
- **Tier 3 (polish):** 15+ objects
- **Silent (no sound):** 25+ objects explicitly listed

This is NOT haphazard. I have a clear scope: add `sounds` tables to Tier 1 + Tier 2 only (~50 objects).

### 10. ⚠️ Concern: Event Verb Mapping
Some verbs trigger sounds on objects (e.g., `break` → glass-shatter). But the plan doesn't spec how Smithers maps verbs to sound events.

**Question:** When a player types `LISTEN`, does the engine:
- (a) Fire `sound_manager.trigger(obj, "on_verb_listen")`?
- (b) Fire `sound_manager.trigger(obj, "listen")` (verb name)?
- (c) Both?

**Recommendation:** Smithers documents verb-to-event mapping in WAVE-2. Flanders and Smithers coordinate on the exact field names (e.g., `on_verb_listen` vs `listen_sound`).

---

## Consolidated Verdict

**The object metadata spec is solid, but has 2 blockers and 3 concerns around GUID safety, naming conventions, and mutation handling.**

### Blockers (Must Fix Before WAVE-1)

1. **GUID pre-assignment:** Bart provides `.squad/decisions/inbox/bart-sound-guids.md` with reserved GUIDs for all objects Flanders/Moe will modify in WAVE-1.
2. **Field naming convention:** Bart documents final naming in `src/meta/objects/SOUND-METADATA-SPEC.md` (ambient_loop, on_state_*, on_verb_*, on_mutate).
3. **Creature death state:** Clarify whether dead creatures stay as objects with modified on_feel, or are deleted entirely. Affects sound_manager.stop_by_owner() behavior.

### Concerns (Strongly Recommended)

4. Mutation handling: Bart specifies sound_manager behavior on object mutation (stop old, scan new).
5. Verb-to-event mapping: Smithers/Flanders coordinate on exact field names in WAVE-2.

---

**Reviewed by:** Flanders (Object Engineer)  
**Confidence:** Medium (2 blockers, 1 critical clarification needed on creature death)  
**Signature:** ⚠️
