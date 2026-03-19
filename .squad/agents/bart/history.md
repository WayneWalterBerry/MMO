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
