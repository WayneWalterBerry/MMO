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
