# Flanders — History

*Last comprehensive training: 2026-07-20*

---

## Core Context

**Project:** MMO text adventure engine in pure Lua (REPL-based, lua src/main.lua)
**Owner:** Wayne "Effe" Berry
**Role:** Object Designer / Builder — I design and implement all real-world game objects as .lua files in src/meta/objects/.

---

## Essential Patterns & Learnings

### Object Design Principles
1. **Every object MUST have `on_feel`** — it's the primary dark sense
2. **Food system has two pathways:** Small creatures (rat/bat/cat) use corpse-as-raw-meat; large creatures (wolf/spider) use butcher→separate raw products
3. **Creature metadata must be pure data** — no inline functions (Principle 8)
4. **Unique registration IDs critical** — `registry.get()` uses id field, not guid
5. **Territory markers need both fields:** `territorial` (config) AND `territory` (room-id string)
6. **Healing metadata requires top-level `use_effect` field** — not just design properties

### Creature Zone Names & Narration
- Combat narration uses creature-specific body zone names from `body_tree[zone].names`
- All creatures (spider, rat, wolf, cat, bat) have `names` arrays per zone
- Engine `zone_text()` checks creature zones first before falling back
- Different creatures need different vocabulary (spider has "fangs", human has "teeth")

### Territory & Sensory System
- Territory markers use unique IDs (`territory-marker-{uid}`)
- Room contents reference markers by registration id, not guid
- Narration cleanup required for mid-sentence capitalization and prepositions
- Deduplication needed when creatures appear in both room.contents and get_creatures_in_room()
- State-aware sensory text must be checked for animate objects

---

## Recent Major Work (2026-08-23)

### WAVE-1b — Wyatt's World Objects (68 files)
- Built all ~70 objects for Wyatt's World (MrBeast challenge arena for Wyatt, age 10)
- 68 unique GUIDs, all 68 have `on_feel` (engine requirement)
- All sensory text at 3rd-grade reading level
- Zero Lua syntax errors, zero test regressions (273 pass, 4 pre-existing failures unchanged)
- **Key design decision:** Foam material for burger ingredients (TV set props, not real food)

## Learnings

### 2026-08-17: Food Board Audit

**Task:** Audit food implementation, verify Kirk's "90% done, 4 raw-meat objects missing" claim.

**Finding:** The claim was wrong. Phase 1 food system is functionally complete with 0 blocking gaps:
- `wolf-meat.lua` already existed (raw wolf meat from butchery). Not missing.
- `raw-rat-meat.lua`, `raw-bat-meat.lua`, `raw-cat-meat.lua` are NOT NEEDED. Small creatures (rat, bat, cat) use the corpse-as-raw-meat pattern: their `death_state` includes `food = { raw = true, cookable = true }` and `crafting.cook = { becomes = "cooked-{type}-meat" }`. The cook verb reads these directly from the reshaped corpse. This matches CBG's Option A recommendation.
- Board also undercounted: 14 food objects (not 10), 11 test files (not 9).

**Lesson:** Two distinct creature→food pathways exist and both are implemented:
1. **Small creatures (rat/bat/cat):** kill → dead corpse (IS the raw meat) → cook → cooked meat. No separate raw-meat .lua file.
2. **Large creatures (wolf/spider):** kill → dead corpse → butcher with tool → raw products (wolf-meat.lua, spider-meat.lua) → cook → cooked meat.

The `death_state.crafting.cook` field on creature definitions is the key mechanism for pathway 1. Always check creature death_state before assuming a standalone raw-meat object is needed.

### 2025-07-21: Bug Fix Batch — Issues #380, #378, #379

**Wolf territory (#380):** The wolf had `behavior.territorial` (a table with marking config) but was missing `behavior.territory = "hallway"` — the string field the engine uses for home-room comparison. Lesson: `territorial` (config) and `territory` (room-id) are separate fields.

**Silk-bandage use_effect (#378):** Healing metadata was spread across `healing_boost`, `cures`, and FSM transition effects, but the engine contract requires a top-level `use_effect` table with `{ heal, stops_bleeding, consumed }`. Lesson: always provide the engine-facing contract field, not just design-facing properties.

**Spider creates_object (#379):** The spider had `cooldown = "30 minutes"` (string, should be numeric 30) and a `condition` function (violates Principle 8). Replaced with `cooldown = 30` and `max_per_room = 2`. Also required a companion engine fix in `actions.lua` to use `registry:instantiate(template)` and enforce `max_per_room` natively. Lesson: creature metadata must be pure data — no inline functions.

**Cross-domain note:** #379 required touching `src/engine/creatures/actions.lua` (Bart's domain) because the engine lacked `template`-based instantiation and `max_per_room` enforcement. Decision filed to `.squad/decisions/inbox/`.

### 2026-07-20: Bug Fix Batch — Issues #369, #337, #370, #345, #331

**Spider body zones (#369/#337):** Combat narration was using human anatomy words ("knee", "thigh", "shin", "haunch") for spider's `legs` zone because `narration.lua::zone_text()` had a hardcoded `zone_words` table with no creature awareness. Fix: added `names` arrays to all creature body_tree zones (spider, rat, wolf, cat, bat) and modified `zone_text()` to check `body_tree[zone].names` first. Principle 8 in action — objects declare their narration words, engine executes.

**Death message formatting (#345/#370):** Verified death messages now use `"The " + creature.id + " is dead!"` (capitalized definite article). The fix was already in verbs/init.lua (line 427). Wrote proper TDD test to validate end-to-end.

**Dead creature verb aliases (#331):** All combat verb aliases (stab, hit, kick, punch, strike, swing) now check for dead creatures in room contents before falling through to non-combat handlers. Uses the `check_dead_creature()` helper already in verbs/init.lua.

**Cross-domain note:** Touched `src/engine/combat/narration.lua` (Bart's domain) — added `body_tree` parameter to `zone_text()` and threaded it through `generate()` and `witness_visual()`. Minimal change, no behavioral change to fallback path. Decision filed to `.squad/decisions/inbox/flanders-creature-zone-names.md`.

**Lesson:** When creature zones share names with human zones (e.g., "legs"), the narration system needs creature-specific overrides. The `names` field pattern works well — objects provide their vocabulary, engine picks from it.

### 2026-07-20: Bug Fix Batch — Issues #296, #312, #323, #338, #346

**Spider web ghost (#296):** The cellar room had the spider creature but no spider-web object instance. The spider's `room_presence` described a web, but players couldn't interact with it. Fix: added `cellar-spider-web` instance to `src/meta/rooms/cellar.lua` referencing the existing `spider-web.lua` definition. Lesson: room_presence text must always have a corresponding interactable object — narrative flavor without game objects breaks immersion.

**Territory markers never created (#312):** Two bugs: (1) `mark_territory()` registered all markers under the shared id `"territory-marker"`, so the real registry (which keys by id) overwrote previous markers. Room contents referenced markers by guid, but `reg:get(guid)` returns nil. (2) `creature_tick()` set `_last_marked_room` even when marking failed, preventing retry. Fix: unique ids per marker (`"territory-marker-{uid}"`), room contents use registration id, `_last_marked_room` only set on success. Lesson: always use unique registration ids in the registry. The real registry's `get()` only checks `_objects[id]`, not the guid index.

**Wolf scent vanishes (#323):** Related to #312 — territory markers provide persistent scent. Added `behavior.lingering_scent` metadata to wolf.lua for future non-territorial scent trail support. With #312 fixed, the wolf now leaves detectable scent markers in rooms it visits.

**Garbled spider bite narration (#338):** Three issues in `narration.lua`: (1) `material_text("tooth-enamel")` returned raw material names ("enamel", "tooth-enamel") — fixed to only return weapon names ("tooth", "fang"). (2) `render()` didn't clean dangling prepositions before punctuation — added cleanup patterns. (3) Mid-sentence capitalization ("as A large") — added fixup. Lesson: natural weapon `message` fields that end with prepositions (e.g., "sinks its fangs into") need render-level fixups because some templates place `{verb}` at sentence boundaries.

**Ambient scan excludes rat (#346):** Two issues in smell.lua/listen.lua: (1) No deduplication — creatures in both `room.contents` and `get_creatures_in_room()` appeared twice. (2) Object loop didn't check FSM state-specific sensory text for animate objects. Fix: added `seen_ids` dedup set and state-aware sensory text in the object loop.

**Cross-domain note:** Touched `territorial.lua`, `creatures/init.lua` (Bart), `narration.lua` (Bart), `smell.lua`/`listen.lua` (Smithers). Decision filed to `.squad/decisions/inbox/flanders-territory-narration-sensory-fixes.md`.

### 2026-07-20: Test Fix Batch — Issues #393, #392, #394

**Flaky dagger damage (#393):** Test "silver dagger stab creates bleeding with higher damage" expected damage=8 but got 12 when `random_body_area()` rolled torso (1.5x). Fix: changed test input from `"self with silver dagger"` to `"left arm with silver dagger"` — explicit 1.0x body area makes damage deterministically 8. Lesson: tests asserting exact damage values must pin the body area to avoid multiplier variance.

**Search auto-open vs peek (#392):** Test "Search auto-opens unlocked containers" checked `containers.is_open()` but the engine uses `peek_open` (#384) — contents become accessible without visually opening. Many tests validate peek behavior. Fix: changed assertion to check `nightstand.accessible` instead of `containers.is_open(nightstand)`, renamed test to "Search makes unlocked container contents accessible". Lesson: `peek_open` sets `accessible=true` but restores `is_open` — always test the right property.

**Surface object narration (#394):** Test "traverse.step: object with surfaces returns empty narrative (undirected)" failed because #385 added `narrator.enumerate_room_object()` for surfaced objects during undirected sweep, conflicting with bug #40 fix. Fix: return empty narrative for surfaced objects — surface entries in the queue handle their own narration.

**Cross-domain note:** Touched `src/engine/search/traverse.lua` (Bart's domain) for #394 — minimal change, removed contradictory narration path. Decision filed to `.squad/decisions/inbox/flanders-surface-object-narration.md`.

### 2026-08-23: WAVE-1b — Wyatt's World Objects (68 files)

**Task:** Build all ~70 objects for Wyatt's World (MrBeast challenge arena for Wyatt, age 10). WAVE-1b of the implementation plan.

**Files created:** 68 object .lua files in `src/meta/worlds/wyatt-world/objects/`

**Room breakdown:**
- **Beast Studio (hub):** 10 objects — welcome-sign, big-red-button (FSM: unpressed→pressed), scoreboard, confetti-cannon (FSM: loaded→fired), giant-screen, camera, speaker, golden-podium, mrbeast-banner, studio-confetti
- **Feastables Factory:** 12 objects — 5 chocolate bars (purple/gold/red/blue/green with flavor_category metadata), 4 sorting bins (FSM: empty→has_correct/has_wrong), conveyor-belt (surface), factory-sign
- **Money Vault:** 10 objects — 3 counting tables (surfaces), 3 money cards (readable: $50/$60/$100), vault-safe (FSM: locked→unlocked, combination=210), vault-golden-trophy, gold-coins, vault-sign
- **Beast Burger Kitchen:** 12 objects — 6 ingredients (bottom-bun through top-bun with burger_order 1-6), recipe-card (full step-by-step), assembly-plate (ordered container), big-grill, kitchen-sign, beast-burger-coupon, ingredient-shelf
- **Last to Leave Room:** 10 objects — couch, tv-screen, bookshelf, normal-rug (all is_fake=false), weird-clock (15 numbers), backwards-book (reversed title), cold-lamp (on but cold) (all is_fake=true), found-it-box (container), challenge-rules-sign, completion-medal
- **Riddle Arena:** 9 objects — 3 riddle boards (FSM: unsolved→solved), arena-clock (answers riddle 1), arena-piano (answers riddle 2), stage-hole (answers riddle 3), riddle-podium, spotlight, riddle-prize-trophy
- **Grand Prize Vault:** 6 objects — mrbeast-letter (hidden_numbers={13,50,7}), letter-pedestal, prize-chest (FSM: locked→unlocked, combination={13,50,7}), golden-mrbeast-trophy, victory-confetti-cannon (FSM: loaded→fired), vault-streamers

**Validation:**
- 68 unique GUIDs (generated fresh — bart-wyatt-guids.md not found)
- All 68 objects have `on_feel` (engine requirement)
- All 68 have `on_taste` — always safe and fun per CBG design
- All sensory text at 3rd-grade reading level
- Zero Lua syntax errors
- Zero test regressions (273 pass, 4 pre-existing failures unchanged)

**Design decisions:**
1. **GUID generation:** Bart's pre-assigned GUID file (`bart-wyatt-guids.md`) wasn't found. Generated 68 fresh Windows-format GUIDs via PowerShell. All unique. Filed mental note — if Bart publishes GUIDs later, may need reconciliation.
2. **Foam material for burger ingredients:** Used `material = "foam"` for all burger parts since they're game-show props, not real food. Consistent with the "everything is a TV set prop" aesthetic.
3. **Puzzle metadata on objects:** Added domain-specific fields for puzzle logic: `flavor_category` on chocolate bars, `accepts_category` on bins, `burger_order` on ingredients, `is_fake`/`fake_reason` on Last to Leave objects, `riddle_answer`/`answers_riddle` on riddle objects, `hidden_numbers`/`combination` on vault items. Engine doesn't read these yet — they're metadata for WAVE-2 puzzle wiring.
4. **Chocolate material:** Added `material = "chocolate"` to bars even though it's not in the material registry. This is a Wyatt-world-specific material — may need Bart to add it to materials/init.lua.
5. **No inline functions:** All objects are pure data tables. No `on_look` functions, no `on_feel` functions. Principle 8 compliance — objects declare, engine executes.

**Lesson:** Building for a kid audience changes EVERYTHING about sensory writing. Manor objects describe texture, weight, temperature — physical realism. Wyatt objects describe fun, silliness, excitement — emotional engagement. Same engine, radically different voice. The `on_taste` field went from "dangerous poison mechanic" to "comedy opportunity." Both are valid uses of the same system.
