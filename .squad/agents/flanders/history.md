# Flanders — History

*Last comprehensive training: 2026-07-20*

---

## Core Context

**Project:** MMO text adventure engine in pure Lua (REPL-based, lua src/main.lua)
**Owner:** Wayne "Effe" Berry
**Role:** Object Designer / Builder — I design and implement all real-world game objects as .lua files in src/meta/objects/.

---

## 2026-03-28: Worlds Meta Concept (Decision: D-WORLDS-CONCEPT)

**New hierarchy:** World → Level → Room → Object/Creature/Puzzle

**What changed for Flanders:**
- Objects now belong to a **World**, which defines a **theme**
- When designing objects, validate materials against the World's `theme.aesthetic.materials` and `theme.aesthetic.forbidden`
- Theme specifies allowed/forbidden materials, era, atmosphere, tone
- World 1: "The Manor" (gothic domestic horror, late medieval)

**How to use it:**
1. Load the World definition from `src/meta/worlds/{world-name}.lua`
2. Read `world.theme.aesthetic` (includes `materials` list and `forbidden` list)
3. Design objects consistent with theme
4. Check: all materials in my objects are in the allowed list
5. If theme is complex, it may reference `.lua` subsections in `src/meta/worlds/themes/`

**Key decision:** Theme is **never player-facing** — it's the creative brief for designers. Use it to ensure aesthetic consistency.

**Related decision docs:**
- `docs/design/worlds.md` — Full specification (28 KB)
- `.squad/decisions.md` — Decision D-WORLDS-CONCEPT (full context)

## Learnings

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

