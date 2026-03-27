### 2026-08-16: D-DEATH-RESHAPE-ARCHITECTURE — In-place creature death reshape
**By:** Bart (Architect)
**Requested By:** Wayne Berry (directive 2026-03-27)
**Supersedes:** D-FOOD-ARCHITECTURE `mutations.kill`, Phase 3 v1.2 `mutations.die` file-swap approach

**What:** Creature death no longer file-swaps to separate dead-creature `.lua` files. Instead:
1. Each creature file declares a `death_state` metadata block containing ALL dead-state data (template, name, description, sensory text, food properties, container properties, spoilage FSM, crafting recipes).
2. On death, the engine calls `reshape_instance()` (NOT `mutation.mutate()`) to transform the creature instance in-place.
3. `reshape_instance()` switches template (creature→small-item/furniture), overwrites properties from death_state, deregisters from creature tick, registers as room object, preserves GUID.
4. No separate dead-creature files exist. 5 object files eliminated: dead-rat.lua, dead-cat.lua, dead-wolf.lua, dead-spider.lua, dead-bat.lua.

**Why:**
- Wayne directive: "I really want the instance of creature/rat.lua to reshape itself into an object."
- Stronger D-14 alignment: the creature code literally transforms. No file swap — the instance reshapes.
- Eliminates 5 object files and 5 GUIDs of overhead.
- Keeps all creature lifecycle data in one place (living + dead states in same file).

**Key distinction — `reshape_instance()` vs `mutation.mutate()`:**
- `mutation.mutate()` loads a **different .lua file** and replaces the instance's backing code. Used for genuine type changes (dead-rat → cooked-rat-meat).
- `reshape_instance()` transforms the **same instance** via metadata overlay. No new file loaded. Used for in-place state transformation (living rat → dead rat).

**Impact:**
- Phase 3 plan bumped to v1.3.
- WAVE-1 completely rewritten: engine builds `reshape_instance()`, Flanders adds death_state blocks to creature files.
- WAVE-2: inventory drops scatter alongside reshaped corpse (not separate object).
- WAVE-3: cook verb targets reshaped instances. Cooked meat .lua files still exist as separate objects.
- WAVE-0: 5 fewer GUIDs to pre-assign.
- All gates, TDD map, file ownership tables updated.

**Backward compatibility:** Creatures WITHOUT `death_state` keep existing FSM dead state behavior. Opt-in only.
