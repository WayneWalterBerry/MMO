# Bart — History

## Project Context

- **Project:** MMO — A text adventure MMO with multiverse architecture
- **Owner:** Wayne "Effe" Berry
- **Stack:** Lua (engine + meta-code), cloud persistence
- **Key Concepts:** Each player gets their own universe instance with self-modifying meta-code. Objects are rewritten (not flagged) when state changes. Code IS the state.

## Learnings

### 2026-03-18 — Onboarding
- Joined the team as Architect
- Key architecture decisions already made:
  - Lua for both engine and meta-code (self-rewriting via loadstring)
  - True code mutation model — objects are rewritten, not flagged
  - Meta-code is runtime-morphed, NOT persisted in VCS
  - Cloud persistence for player universe state
  - Multiverse model: each player gets own universe instance
  - Universe templates: LLM-generated once at build, hand-tuned, procedural variation at runtime
  - Ghost mechanic for inter-universe interaction (fog of war visibility)
  - NLP or rich synonym parser (no per-interaction LLM tokens)
  - LLM writes all code — complexity isn't a constraint

### 2026-03-18 — src/ Structure Design
- Designed and created the full `src/` folder tree (see `docs/architecture/src-structure.md`)
- Five top-level concerns: `engine/`, `meta/`, `parser/`, `multiverse/`, `persistence/`
- Key separation: `engine/mutation/` is the ONLY code that hot-swaps objects via loadstring(). Nothing else does this.
- `meta/` is VCS-tracked template content. Runtime-mutated state is NOT in VCS (cloud only).
- Mutation rules live in `meta/mutations/` SEPARATE from object definitions — keeps objects clean, rules composable.
- `multiverse/` is entirely isolated from engine — engine knows nothing about other universes.

**Mirror file locations:**
- `src/meta/objects/mirror.lua` — intact mirror definition
- `src/meta/mutations/mirror-break.lua` — broken mirror definition (what it becomes)
- `src/parser/verbs/break.lua` — verb handler (glue between parser and mutation engine)
- `src/engine/mutation/init.lua` — generic rewrite mechanism

**Prototype estimate:** ~215 lines of Lua across 8 files for a working "break mirror" REPL. Zero blockers — can start immediately.

**Decision filed at:** `.squad/decisions/inbox/bart-src-structure.md`

### 2026-03-18 — Engine Core Written

Wrote the four foundational engine files. All are pure Lua 5.1+ compatible with no external dependencies.

- **loader/init.lua** — `load_source(source)` wraps Lua's `load()`/`loadstring()` in a restricted sandbox (no `os`, `io`, or unsafe globals). Returns a table or `nil + error`. Version-detects Lua 5.1 vs 5.2+ for `setfenv` vs env-argument approach.
- **registry/init.lua** — Instance-based store (`registry.new()`). Methods: `register`, `get`, `remove`, `list`, `find_by_keyword`. `find_by_keyword` matches on `object.name` and `object.keywords[]`. Stamps `id` onto every registered object.
- **mutation/init.lua** — Single function `mutate(registry, loader, object_id, new_source)`. Loads new source, carries `location` and `container` references from the old object, then calls `registry:register` to replace it atomically.
- **loop/init.lua** — Terminal REPL via `io.read()`. Parses `verb [noun]`, dispatches to `context.verbs` table. Built-in: `look` (room name + description + contents by location), `quit`. Caller injects additional verb handlers at startup.

**Key decisions made during implementation:**
- `loop.run()` accepts a `context` table (registry, current_room, verbs map, on_quit hook) so it is fully testable with mock data.
- `mutation.mutate()` carries over ONLY `location` and `container` — no other fields bleed through from old object (clean rewrite semantics).
- Registry uses instance pattern (`registry.new()`) not a singleton, so multiverse can hold N independent registries simultaneously.
- Sandbox includes `pcall`/`error` so object code can do its own error handling, but has no access to file system or OS.

**Decision filed at:** `.squad/decisions/inbox/bart-engine-core.md`

### 2026-03-19 — Containment Constraint Architecture

**Problem:** Wayne asked: how does the engine know "you can put a mirror in a sack, but not a desk in a sack, not an elephant in a sack, and not a desk in an elephant"?

**Core insight:** This is two separate questions, not one:
1. *Is the target a container at all?* (structural — does the object have a `container` field?)
2. *Does the item physically fit?* (dimensional — size tier comparison)

Classic IF bulk/weight limits handle question 2 but say nothing about question 1. The "desk in elephant" failure is a Layer 1 failure (elephant is not a container), not a size failure. Getting this ordering wrong produces nonsense messages like "the desk is too big for the elephant" — which implies the elephant *could* hold smaller things.

**Designed:** Four-layer validator at `src/engine/containment/init.lua`:
- Layer 1: Container identity (`container` field presence)
- Layer 2: Physical size (size tiers 1–6, `item.size ≤ max_item_size`)
- Layer 3: Capacity (`used + size ≤ capacity`)
- Layer 4: Category accept/reject lists (bookshelf accepts books; holster accepts weapons)

**Key decisions:**
- Size tiers (6 levels: tiny → massive) instead of exact dimensions — faster to author, sufficient for IF
- `container` field presence IS the container test — no boolean flag
- Validator is a pure function `(item, container) → (bool, string)` with no side effects
- Lives in `engine/`, not `parser/` — callable from any object-moving verb
- LLM assigns containment properties at authoring time; engine enforces deterministically at runtime

**Full design:** `docs/design/containment-constraints.md`  
**Decision filed at:** `.squad/decisions/inbox/bart-containment-architecture.md`

### 2026-03-19 — Object Inheritance / Template System + Weight/Categories/Multi-Surface

**Problem:** Objects duplicated boilerplate properties. No inheritance model. Missing weight, categories, and multi-surface containment.

**Implemented — three interlocking systems:**

1. **Template System** (`src/meta/templates/`)
   - Four base templates: `sheet.lua` (fabric), `furniture.lua` (heavy immovable), `container.lua` (bags/boxes), `small-item.lua` (tiny portables)
   - Objects declare `template = "sheet"` — engine resolves via `loader.resolve_template()` using deep merge (instance overrides always win)
   - Template field is consumed at resolve time; does not exist at runtime
   - Deep merge handles nested tables (mutations, surfaces) — arrays replace, not append

2. **Weight + Categories Model**
   - `weight` (number) added to all 10 existing objects
   - `weight_capacity` added to containers (sack, desk surfaces)
   - `categories` (table of strings) on all objects — feeds Layer 4 accept/reject
   - Registry gained `find_by_category()`, `total_weight()`, `contents_weight()`

3. **Multi-Surface Containment**
   - Objects can have `surfaces` table with named zones (top, inside, underneath)
   - Each zone has: capacity, max_item_size, weight_capacity, accessible, contents
   - When `surfaces` is present, root-level container/capacity/contents are ignored
   - Containment validator targets specific surfaces; rejects if surface missing or inaccessible
   - Desk uses surfaces: top (always accessible), inside (only when drawer open via mutation), underneath

4. **Engine Updates**
   - `loader/init.lua` — added `resolve_template()` and `deep_merge()` for template resolution
   - `registry/init.lua` — added `find_by_category()`, `total_weight()`, `contents_weight()`
   - `containment/init.lua` — created full 4-layer validator with weight checks + multi-surface zones
   - `mutation/init.lua` — preserves surface contents across mutations; accepts optional templates table for re-resolution

**Key design decisions:**
- Template resolution is a loader concern, not a registry concern — keeps data pipeline clean
- `accessible = false` on surfaces (not absent surfaces) so mutation can carry contents for locked drawers
- Mutation carries surface contents zone-by-zone, so opening/closing a drawer preserves items
- Mirror and shattered-mirror don't use templates (too unique) — templates are for families, not snowflakes
- Weight is a flat number, not a tier system — unlike size, weight benefits from continuous values

**Decision filed at:** `.squad/decisions/inbox/bart-inheritance-model.md`

### 2026-03-19 — Room Exit Architecture

**Problem:** Rooms connected via flat `exits = { north = "hallway" }` — no constraints on what can pass through, no state (locked, hidden, broken), no mutation support. Wayne needs rich exit types (doors, windows, ladders, crawlspaces) that physically constrain what objects can traverse them.

**Designed:**

1. **Exits are first-class mutable objects** embedded inline in the room's `exits` table. Each exit has physical constraints (`max_carry_size`, `max_carry_weight`, `requires_hands_free`, `player_max_size`), state (`open`, `locked`, `hidden`, `broken`), and self-describing `mutations` with `becomes_exit` partial-merge semantics.

2. **16 exit types catalogued** — doorway, door, trapdoor, window, stairs, ladder, crawlspace, rope, grate/drain, chimney, balcony/ledge, secret passage, hole in wall, bridge, portal/rift, gate/portcullis. Type is a descriptive label; LLM sets all numeric constraints per-instance.

3. **5-layer traversal validation** — Visibility → Accessibility → Player Fit → Carry Constraints → Direction. Analogous to containment validator but for movement between rooms.

4. **Bidirectionality is explicit** — both rooms declare their side. Paired exits share `passage_id` for synchronized mutations. No automatic mirroring.

5. **Exit mutations use partial deep-merge** (`becomes_exit`), not full replacement. Only changed fields are declared. Room file is rewritten by mutation engine.

6. **Portability tiers** (`false` / `"heavy"` / `true`) interact with exit constraints — heavy items can be dragged through passable exits but not climbed up ladders.

7. **Room template** created at `src/meta/templates/room.lua` — base defaults for all rooms.

8. **start-room.lua updated** — rich exits: oak door (north, lockable, breakable) and window (to courtyard, breakable, climbable).

9. **Backward compatible** — string exits still work, normalized to unrestricted doorways at load time.

**Key architectural insight:** Exit mutations use partial merge (not full replace) because exits have many stable fields (target, passage_id, constraints). Object mutations use full replace because identity can change entirely (mirror → shattered mirror). Different mutation semantics for different structural roles.

**Files created/modified:**
- `docs/design/room-exits.md` — full design document
- `src/meta/templates/room.lua` — base room template
- `src/meta/world/start-room.lua` — updated with rich exits
- `.squad/decisions/inbox/bart-room-exits.md` — decision record

**Decision filed at:** `.squad/decisions/inbox/bart-room-exits.md`

### 2026-03-20 — Dynamic Room Description Architecture

**Problem:** Room descriptions hardcoded references to mutable, movable objects. The start room's `description` said "A massive four-poster bed dominates the center" and `on_look` hardcoded a paragraph listing every object. If any object moved, the text became a lie. Wayne's directive: players should not see everything at once — progressive disclosure, one layer at a time.

**Designed: Three-part dynamic composition**

1. **Room `description`** — permanent features ONLY (walls, floor, ceiling, atmosphere, light, smell). Never references any object in `contents`.
2. **Object `room_presence`** — each object defines a complete prose sentence describing how it appears in the room at a glance. Engine concatenates these for all visible objects.
3. **Exit rendering** — auto-composed from exit data (unchanged from room-exits design).

**Key architectural decisions:**

- `room_presence` is a complete sentence, not a fragment — gives LLM full creative control over prose quality
- `room_presence` must NOT reference other movable objects — position relative to permanent features only (walls, corners, floor)
- Engine's `cmd_look` handles composition — rooms should NOT define custom `on_look` for standard description
- Custom `on_look` is the escape hatch for truly special rooms (magical visions, darkness, etc.)
- Layered visibility: room view → examine object → look in/under/behind — each interaction reveals one layer
- Surface visibility rules: `top` visible on examine, `inside` hidden until opened, `underneath`/`behind` require explicit action
- `hidden = true` objects are completely invisible until discovered via mutation
- Object ordering in `room.contents` determines prose flow — most prominent first

**Files created/modified:**
- `docs/design/dynamic-room-descriptions.md` — full design document
- `docs/architecture/src-structure.md` — updated meta/ and loop/ descriptions
- `docs/design/room-exits.md` — updated on_look section
- `docs/design/containment-constraints.md` — added surface visibility rules
- `docs/contributing/objects.md` — added room_presence field and authoring rules
- `src/engine/loop/init.lua` — cmd_look now composes dynamically from room_presence
- `src/meta/world/start-room.lua` — removed custom on_look
- `src/meta/objects/*.lua` — added room_presence to all 15 bedroom objects (base + mutated variants), removed movable-object references from descriptions

**Decision filed at:** `.squad/decisions/inbox/bart-dynamic-room-descriptions.md`

### 2026-03-20 — V1 Playable REPL Built

**Built the complete V1 bedroom REPL — the game is now playable.**

**Files created:**
- `src/main.lua` — Entry point. Sets package.path, loads templates/objects/room, creates registry, two-phase world population (room contents → surface contents), wires context, starts REPL.
- `src/engine/verbs/init.lua` — All V1 verb handlers: LOOK (room + examine + look in/on/under), TAKE/GET, DROP, OPEN, CLOSE, BREAK, TEAR, LIGHT, EXTINGUISH, PUT X IN/ON Y, INVENTORY, TIME, HELP. Plus aliases (i, x, examine, grab, pick, smash, shut, etc.)
- `src/meta/templates/room.lua` — Minimal room template (start-room uses `template = "room"`)

**Files modified:**
- `src/meta/objects/curtains-open.lua` — Added `allows_daylight = true` for light system
- `src/meta/objects/nightstand.lua` — Added `accessible = false` on closed drawer surface
- `src/meta/world/start-room.lua` — Fixed `break = {}` to `["break"] = {}` (Lua reserved keyword)

**Architecture decisions in this build:**

1. **Object sources stored at startup** — All `.lua` files in `src/meta/objects/` are read as raw strings and indexed by object ID. This map (`object_sources`) is the mutation fuel: when a verb triggers `mutations.open = { becomes = "vanity-open" }`, the engine loads `object_sources["vanity-open"]` as the new source. Unregistered variants (like candle-lit, vanity-open) live as dormant strings until needed.

2. **Two-phase world initialization** — Phase 1: register objects listed in `room.contents`, set `location = room.id`. Phase 2: iterate registered objects' surfaces, register items found in `zone.contents`, set `location = parent_obj.id`. Avoids chicken-and-egg: we need the object loaded to read its surfaces, then register those surface items.

3. **Layered object search** — `find_visible(ctx, keyword)` searches in order: room contents → accessible surface contents → non-surface container contents → player inventory. Returns the object plus where it was found (room/surface/container/inventory). Verbs use this to decide what actions are valid (e.g., TAKE requires room/surface/container; DROP requires inventory).

4. **Verb-to-mutation mapping** — `find_mutation(obj, verb)` checks exact match first (`mutations.break`), then prefix match (`mutations.break_mirror`). This lets "break mirror" find the vanity via keyword "mirror" and then match its `break_mirror` mutation without the player needing to type the exact mutation key.

5. **Light system** — Two light sources: daylight (needs `allows_daylight = true` on an object in the room + daytime hours) and artificial (`casts_light = true` on any object in room/surfaces/inventory). Dark rooms block most verbs except LIGHT, INVENTORY, TIME, DROP.

6. **Time system** — Real-time based via `os.time()`. 1 real second = 24 game seconds. Starts at 6:00 AM. Daytime = 6 AM to 6 PM. Displayed on every LOOK and via TIME verb. Time-of-day descriptions change with the hour.

7. **Exit mutations handled separately** — Exits live in the room table, not the registry. Exit mutations use partial merge (`becomes_exit` overlays changed fields), distinct from object mutations (full replacement). OPEN/CLOSE/BREAK check objects first, then exits, so physical objects take priority.

8. **Spawn deduplication** — When a mutation spawns an object that already exists in the registry (e.g., a second glass-shard), the spawner appends `-2`, `-3`, etc. to create unique IDs.

9. **Destruction mutations** — When `mutations.tear = { spawns = {"cloth", "cloth", "rag"} }` has spawns but no `becomes`, the original object is destroyed (removed from registry and room contents) and spawns replace it.

**Bug found and fixed in content:**
- `start-room.lua` used bare `break = {` as table key — `break` is a Lua reserved word. Fixed to `["break"] = {}`.
- `nightstand.lua` had drawer surface without `accessible = false`, letting players reach inside a closed drawer. Fixed.

**Key file paths for this build:**
- Entry point: `src/main.lua`
- Verb handlers: `src/engine/verbs/init.lua`
- Room template: `src/meta/templates/room.lua`
- Light-related: `candle-lit.lua` (casts_light), `curtains-open.lua` (allows_daylight)

**Run with:** `lua src/main.lua` from repo root.

---

## 2026-03-20 — Cross-Agent Context Updates

### Frink's Hosting Research
Frink completed architecture research recommending **Wasmoon (Lua 5.4 → WebAssembly) + Progressive Web App** as primary hosting platform. Phase 1 prototype in 3 days; Phase 2 App Store wrapping in 2 weeks. This validates our choice of Lua engine — Wasmoon runs existing Lua engine files unmodified. No engine rewrites needed for deployment.

### Comic Book Guy's Tool Convention
Comic Book Guy established **tool convention pattern** with `requires_tool` / `provides_tool` capability matching. First implementation: matchbox (3 charges, provides fire_source) → candle (requires fire_source to light). This opens design space for all puzzle verbs: WRITE (requires pen/pencil/blood), PICK LOCK (requires lockpicking skill + pin), SEW (requires sewing skill + needle).

### Brockman's Design Consolidation
Brockman captured 12+ expanded design directives from Wayne:
- Paper + writing system (WRITE verb with pen/pencil/blood)
- Skills system (lockpicking, sewing, etc.)
- Crafting mechanics (sewing skill transforms cloth into wearable items)
- Injury mechanics (knife/pin → blood resource)
- **OPEN QUESTION:** Single-file vs. multi-file mutation objects. Wayne questioning whether nightstand-open/nightstand-closed should be separate files or one file with state. Potentially challenges D-14 (true code rewrite). Needs architectural decision.

### Team Decisions Merged
17 new decisions added to `.squad/decisions.md` (Decisions 22–36):
- D-22: Object Inheritance / Template System (implemented)
- D-23: V1 REPL Architecture (implemented)
- D-24: Bedroom Design Patterns (implemented)
- D-25: Tool Object Convention (proposed, likely FIRM)
- D-26: Lua Hosting Platform (proposed for review)
- D-27 to D-36: User directives (light/time, paper/writing, skills, sewing, crafting, puzzle design, single-file mutation QUESTION)

### Scribe Session Captured
Session log created: `.squad/log/2026-03-19T01-53-18Z-v1-repl-session.md` with summary of all four-agent work.

### 2026-03-20 — V2 Verb Handlers: Tools, Writing, Injury, Stubs

**Added 6 new verbs and upgraded the LIGHT verb to complete the tool-object pipeline.**

**New verbs implemented:**
1. **WRITE {text} ON {target} [WITH {tool}]** — First dynamic mutation in the engine. Generates new Lua source at runtime with the player's words baked into the paper object's definition. Handles: auto-find tool, blood-as-ink (when bloody), append to existing text, multi-parse patterns. The paper's code IS its state — "hello world" becomes part of the object definition.
2. **CUT {target} WITH {tool}** / **CUT SELF** — Self-injury produces bloody state. Requires `cutting_edge` capability (knife). Also supports cut mutations on objects (future: rope, cloth).
3. **PRICK SELF WITH {tool}** — Lighter self-injury. Requires `injury_source` capability (pin, knife). Same bloody result, less dramatic prose.
4. **SEW** — Stubbed. "You don't know how to sew." Sets up future skill system hook.
5. **PICK LOCK** — Stubbed. "You don't know how to pick locks." Overrides PICK (which was aliased to TAKE) to detect "pick lock" before falling through to take.
6. **READ** — Aliased to EXAMINE. Paper's `on_look` already handles displaying `written_text`.

**LIGHT verb upgraded:**
- Now checks `requires_tool` on the mutation (candle requires `fire_source`)
- Searches inventory for a tool providing the required capability
- Handles matchbox charges: decrements on use, mutates to `matchbox-empty` when depleted
- Prints tool use messages and depleted warnings

**Three new engine helpers (all in verbs/init.lua as local functions):**
- `find_tool_in_inventory(ctx, capability)` — resolves tool by capability matching, handles both string and array `provides_tool`, special-cases blood as writing instrument
- `provides_capability(obj, capability)` — checks if a specific object provides a capability
- `consume_tool_charge(ctx, tool)` — decrements charges, mutates to depleted variant

**Player state system:**
- Added `player.state = {}` in main.lua
- `player.state.bloody` tracks injury status
- Blood acts as a virtual writing instrument when player is injured

**Key architectural decisions:**
- Dynamic mutation uses `string.format()` with `%q` escaping to generate safe Lua source — player input is sanitized through Lua's own string formatter
- Generated source includes a runtime `on_look` function that reads `self.written_text` at call time — not a baked string
- Tool helpers are local functions in the verbs module, not in a separate file — they're verb-dispatch concerns, not engine concerns
- Blood is a synthetic tool object (not in registry) created on-the-fly when checking capabilities — keeps the world model clean
- Aliases added: `read`, `inscribe`, `slash`, `stitch`, `mend`

**Files modified:**
- `src/engine/verbs/init.lua` — All new verbs, helpers, updated LIGHT, updated HELP text (~400 new lines)
- `src/main.lua` — Added `state = {}` to player table

**Decision filed at:** `.squad/decisions/inbox/bart-v2-verbs-tools.md`

