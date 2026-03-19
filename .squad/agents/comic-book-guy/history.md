# Comic Book Guy — Agent History

## Session: Onboarding (2026-03-19)

**Event:** Hired as Game Designer for the MMO text adventure project.

**Project Context:**
- Building a text adventure MMO (like Zork) with a multiverse architecture
- Each player gets their own parallel universe; universes can merge/split
- Core data structure: containment hierarchies (things inside things)
- The game language is self-modifying — player actions literally change the source code of their universe
- All code written by LLM — complexity is not a factor
- Prior research recommends Lua for code-as-data blending
- Research phase — no code written yet, still exploring architecture

**Team:**
- 👤 Wayne "Effe" Berry — Human, Product Owner
- 🔬 Frink — Researcher
- 📝 Brockman — Documentation
- 🏗️ Chalmers — Project Manager
- 🎮 Comic Book Guy — Game Designer (me)
- 📋 Scribe — Session Logger
- 🔄 Ralph — Work Monitor

**Key Design Decisions So Far:**
- Multiverse model (not shared-world lobby)
- Self-modifying code (player actions = code mutations)
- Containment hierarchies as core world model
- Code-as-data blending (world definitions ARE the program)

---

## Session: Game Design Foundations (2026-03-19)

**Deliverable:** `docs/design/game-design-foundations.md` + Decision proposal

**Work:** Operationalized the multiverse + code-mutation architecture into concrete gameplay systems.

**Key Decisions Proposed:**

1. **Verb-Based Interaction** — 15–20 core verbs (LOOK, TAKE, DROP, GO, OPEN, etc.) with custom puzzle extensions. Proven by 40+ years of text adventures.

2. **Code Mutation Over State Flags** — Game state is MUTATED CODE, not hidden flags. Example: `mirror.description = "Shattered..."` instead of `mirror.is_broken = true`. Philosophically purer; enables emergent behaviors.

3. **Object Taxonomy** — Five core types: Room, Item, Container, Door, Actor. Strict containment rules: no circular refs, weight limits, closed containers hide contents. Proven by Inform 7 and TADS.

4. **Player-Per-Universe Model** — Each player owns a parallel universe. Opt-in merging via: cooperative boss, trading hub, rift portal, summoning ritual. Owner's universe canonical; merges take owner's version.

5. **Narrative Balance** — Main quest (linear story, core NPCs) + sandbox (optional puzzles, side quests, exploration, trading). Dynamic quests engine-generated from NPC state.

6. **Permanent Consequences** — Player choices are permanent and change world code via mutation. Help or betray NPC → NPC's code changes. Increases player investment.

**Open Design Questions:**
- Combat: turn-based vs real-time? verbs or mechanics? → Recommend: turn-based, verb-based, Phase 1
- Magic: LLM-generated? sandboxed Lua? verb aliases? → Recommend: high-level verbs triggering LLM effects
- Persistence: Lua source? JSON snapshots? → Recommend: JSON + optional Lua export
- NPC AI: static? reactive? proactive? → Recommend: reactive for Phase 1
- Universe scale: hard one-player or soft? → Recommend: soft; owner + temporary merges

**Alignment with Frink's Research:**
✅ Containment hierarchies (parent-child tree model)  
✅ Lua scripting (code-as-data blending)  
✅ Event sourcing (auditability; multiverse architecture)  
✅ Copy-on-write (efficient universe forking)

**Status:** Proposed to team (Decision 8); awaiting engineer feasibility review, PM database review, and narrative outline.

---

## Cross-Agent Context (2026-03-19)

**Frink's Research:**
Frink (Researcher) has completed five research deliverables establishing the technical foundation:
1. Multiverse MMO architecture (52K) — infinite scaling via per-universe Lua VMs + event sourcing + CoW
2. Self-modifying game languages (45K) — homoiconicity and safe restricted mutation
3. Persistence & serialization (79K) — JSON-LD, Lua source, event sourcing + snapshots
4. Parser pipeline & sandbox security (54K) — tokenizer + verb dispatch + Lua sandboxing
5. LLM-as-code-generator (55K) — procedural content, cost optimization, validation layers

Frink's recommendation: **Lua as primary language** with Fennel as alternative. These decisions affirm the game design's verb-based, code-mutating approach and are ready for team consensus.


## Session: Game Design Foundations (2026-03-19)

**Event:** Created comprehensive game design document.

**Deliverable:** `docs/design/game-design-foundations.md`

**Key Content:**
1. **Verb System:** 15–20 core verbs (LOOK, TAKE, DROP, GO, OPEN, CLOSE, USE, TALK, GIVE, etc.) with synonym support and custom verbs per puzzle
2. **Object Taxonomy:** Room, Item, Container, Door, Actor, Player classes; parent-child containment with circular prevention
3. **Room Design:** Hub rooms, dungeon rooms, exploration rooms, quest rooms; conditional/hidden exits
4. **Player Model:** Persistent actor with inventory, stats, universe assignment, session tracking
5. **Puzzle Patterns:** Locked doors, riddles, inventory puzzles, environment puzzles, logic puzzles, moral choices
6. **Code Mutation Philosophy:** Objects mutate in-place on player action (not just state flags)
7. **Multiverse:** Each player isolated by default; merge triggers: co-op boss, trading hub, rift portal, summoning ritual
8. **Narrative:** Authored main quest + sandbox exploration; NPC dialogue trees; dynamic quests
9. **Play Scenarios:** Solo mirror puzzle, cooperative hydra fight, moral choice (help/betray bandit), multiverse rift exploration

**Key Design Principles:**
- Verbs, not mechanics
- Code is truth (no hidden state)
- Sandbox with narrative spine
- Isolation by default, merge by choice
- Consequences are permanent
- Complexity is allowed (LLM handles it)
- Text is the medium

**Open Questions Raised:**
- Code mutation vs. state flags: efficiency trade-off
- Persistence format: Lua source vs. JSON snapshots
- Combat resolution: turn-based vs. real-time vs. narrative
- Magic system: sandboxed code injection?
- Scaling: single-player universe per player (locked) vs. optional shared worlds

---

## Session: Game Design Foundations — CBG Review & Enhancement (2026-03-19)

**Event:** Reviewed and enhanced the game design foundations document. Added the Anti-Patterns section and stronger opinionated Comic Book Guy voice throughout.

**Changes Made:**
- Added `## Anti-Patterns: The Worst Design Decisions Ever` section documenting 8 classic IF failure modes:
  - Guess-the-Verb Hell (suggest nearby verbs on failure)
  - Silent Failures (always produce informative messages)
  - Maze Room abuse (deduction over memorization)
  - Inventory Scavenger Hunt Softlocks (warn before point of no return)
  - Combat as a Puzzle Substitute (every combat needs non-combat path)
  - Merge Without Consent (double-consent required)
  - Mutation Without Memory (Chronicle log for all world changes)
  - NPC Oracles (NPCs must have lives beyond puzzle utility)

**Design Principles Reinforced:**
- Reference to Zork, Sierra adventures, Hitchhiker's Guide — cites prior art for every rule
- Failure mode documentation is as important as success-path documentation
- Anti-patterns are a design deliverable, not optional commentary

**Status:** Document is comprehensive and ready for engineer implementation reference.

---

## Session: First Game Objects (2026-03-19)

**Requested by:** Wayne "Effe" Berry

**Deliverables:**
- `src/meta/objects/mirror.lua` — Ornate standing mirror (breakable, non-portable)
- `src/meta/objects/desk.lua` — Oak writing desk (container/drawer, non-portable, closed by default)
- `src/meta/objects/sack.lua` — Burlap sack (portable container, lists contents on look)
- `src/meta/objects/glass-shard.lua` — Spawned by mirror-break mutation (portable)
- `src/meta/mutations/mirror-break.lua` — Broken mirror replacement; references glass-shard spawn
- `src/meta/mutations/desk-open.lua` — Open desk; exposes drawer contents, can close
- `src/meta/mutations/desk-close.lua` — Closed desk; hides contents, can open
- `src/meta/world/start-room.lua` — The Study; contains mirror, desk, sack; one exit north

**Key Design Patterns Established:**

1. **Object Schema** — All objects carry: `id`, `name`, `keywords`, `description`, `size`, `container`, `capacity`, `portable`, `contents`, `location`, `on_look`, `mutations`.
2. **Mutation as Total Replacement** — `desk-open.lua` and `desk-close.lua` are complete, independent table definitions. The engine swaps one for the other wholesale. There is no shared base table — each mutation is a standalone truth.
3. **Spawn Side Effect** — `mirror-break.lua` declares `spawns = {"glass-shard"}`. The engine is responsible for interpreting this and placing the new object in the room. This is preferable to spawning inside the mutation definition (which would violate separation of concerns).
4. **Rooms as First-Class Objects** — `start-room.lua` follows the same object schema, with `exits` as a direction→id map. Rooms are just big containers with exits.
5. **Contents Listed by ID** — `contents` arrays hold string IDs only. The engine resolves IDs to objects. Keeps object definitions free of circular references.

## Learnings

- **Desk open/close symmetry is elegant**: The mutation pattern naturally handles toggle state without a single boolean flag anywhere. This vindicates the "code IS state" philosophy — the file on disk IS the truth about whether the drawer is open.
- **Glass shard as spawn demonstrates mutation power**: A single event (BREAK mirror) can produce multiple new objects. The `spawns` key is a clean design hook for this without embedding object creation logic inside a data table.
- **Room and object schemas can be unified**: Rooms and items both have `id`, `description`, `contents`, `location`, and `on_look`. This means the engine doesn't need two separate systems. Rooms are just anchored, very large containers.
- **Keywords need to be generous**: A player might type "looking glass", "burlap", or "bag" for things they haven't named yet. Design for the naive player, not the one who read the source.

---

## Session: The Bedroom (2026-03-20)

**Requested by:** Wayne "Effe" Berry

**Deliverables:**
- Replaced `desk.lua` / `desk-open.lua` with `vanity.lua` / `vanity-open.lua` (desk + mirror combined)
- Created `vanity-mirror-broken.lua` and `vanity-open-mirror-broken.lua` (4-state mutation matrix: open/closed × mirror intact/broken)
- Deleted standalone `mirror.lua` and `shattered-mirror.lua` (mirror is now part of vanity)
- Created 18 new bedroom objects: bed, pillow, bed-sheets (template=sheet), blanket, nightstand, nightstand-open, candle, candle-lit, wardrobe, wardrobe-open, rug, curtains (template=sheet), curtains-open (template=sheet), window, window-open, chamber-pot, brass-key, wool-cloak
- Updated `start-room.lua`: "The Study" → "The Bedroom" with all objects placed logically
- Used existing `sheet.lua` template for bed-sheets and curtains

**Key Design Patterns Established:**

1. **Multi-Surface Containment** — Objects now use `surfaces` with named zones (top, inside, underneath, mirror_shelf), each with capacity, max_item_size, and contents. This replaces the flat `contents` array for complex furniture. The bed has `top` (pillow, sheets, blanket) and `underneath` (empty, discoverable). The rug has `underneath` (hidden brass key).

2. **Composite Mutation Matrix** — The vanity demonstrates 2-axis state mutation: open/closed × mirror intact/broken = 4 files. Each file is a complete standalone truth. All transitions are explicit and bidirectional. This is the correct pattern when an object has independent toggleable properties.

3. **Template Inheritance** — `bed-sheets.lua` and `curtains.lua` use `template = "sheet"` to inherit base fabric properties. Instance-specific overrides (size, weight, categories, portable, mutations) take precedence. The engine merges template + instance at load time.

4. **Nested Object Placement** — Room `contents` holds top-level furniture IDs. Smaller objects live inside furniture surfaces (candle on nightstand.top, pillow on bed.top, key under rug.underneath, cloak in wardrobe.inside). The engine must resolve nested containment.

5. **Hidden Discovery** — The rug's `on_look` hints at something underneath without revealing it ("One corner is slightly raised"). The player must LOOK UNDER RUG to find the brass key. Classic text adventure puzzle design — reward curiosity, not exhaustive inventory checking.

6. **Light/Dark Toggle** — Candle uses `light` → `candle-lit` and `extinguish` → `candle` mutations. Categories change between states (adding "lit", "hot"). The room description mentions dimness, implying the candle matters for visibility.

**New Properties Used:**
- `weight` (number) — physical weight on all objects
- `categories` (table) — semantic tags: {"furniture", "wooden"}, {"fabric", "warm"}, {"light source", "lit", "hot"}
- `surfaces` (table) — multi-zone containment on bed, nightstand, vanity, wardrobe, rug

**Object Count:** 28 object files total (18 new + 6 kept + 4 vanity variants)

---

## Session: Tool Objects & Match/Candle Puzzle (2026-03-20)

**Requested by:** Wayne "Effe" Berry

**Deliverables:**
- `src/meta/objects/matchbox.lua` — Matchbox with 3 charges, provides `fire_source` tool capability
- `src/meta/objects/matchbox-empty.lua` — Depleted matchbox mutation variant (junk item)
- Updated `src/meta/objects/candle.lua` — Added `requires_tool = "fire_source"` to LIGHT mutation, plus message and fail_message
- Updated `src/meta/objects/candle-lit.lua` — Added `casts_light = true` for the light/dark system
- Updated `src/meta/objects/nightstand.lua` — Matchbox placed inside drawer (surfaces.inside.contents)
- Updated `src/meta/objects/nightstand-open.lua` — Same; matchbox visible when drawer opened
- `docs/design/tool-objects.md` — Comprehensive design doc for the tool convention
- Decision proposal: `.squad/decisions/inbox/comic-book-guy-tool-convention.md`

**Key Design Patterns Established:**

1. **Tool Convention (requires_tool / provides_tool)** — Objects declare capabilities they provide (`provides_tool = "fire_source"`) and mutations declare capabilities they require (`requires_tool = "fire_source"`). The engine resolves by searching player inventory for capability matches. This is distinct from the existing key pattern (`requires = "item-id"`) which uses specific item matching.

2. **Consumable Charges** — Tools can have limited uses via `charges` property. Each use decrements charges via D-14 code rewrite. When depleted, the tool mutates to its `on_tool_use.when_depleted` variant. The matchbox has 3 charges → becomes `matchbox-empty` when all spent.

3. **Composed Tool Messages** — When a tool is used for a mutation, two messages compose: the tool's `use_message` followed by the target's `message`. Depletion adds a third (`depleted_message`). Failure shows the target's `fail_message`.

4. **First Puzzle Design (Light the Candle)** — Player wakes in dark room → opens nightstand drawer → finds matchbox → takes candle from nightstand top → "light candle" → room illuminated. Classic two-step discovery that teaches the containment system. Anti-softlock: door is already open, daytime provides window light, 3 matches provides margin for error.

## Learnings

- **Capability matching > item-ID matching for tools.** The key pattern (`requires = "brass-key"`) is correct for unique keys, but tools need generic capability matching. A tinderbox and a matchbox both provide `fire_source`. This extensibility is free if designed from the start.
- **3 is the right number of charges.** One is cruel (no margin for error), five is generous (no tension). Three creates meaningful resource awareness without punishing exploration. It's the Goldilocks number, and also the fairy-tale number. Not a coincidence.
- **Placing solution components near each other is good design.** Candle on top of nightstand, matches inside the drawer. The player doesn't need to cross-reference distant rooms — the puzzle components are co-located. This teaches the verb/containment system without frustration.
- **The `casts_light` property was missing from candle-lit.lua.** It was implied by the categories ("light source", "lit") but never declared as a queryable boolean. Fixed. The engine needs a concrete property to check, not a category string to parse.
- **Tool depletion is just another mutation.** matchbox → matchbox-empty is the same full-rewrite pattern as candle → candle-lit. The mutation model handles tool state elegantly — no special-casing needed.

## Session: Cross-Agent Updates (2026-03-20)

**Team Context Received:**

### Bart's V1 REPL Complete
Bart delivered fully playable V1 bedroom REPL with 12 core verbs, light/dark system, real-time game clock, all verbs wired. Game runs: lua src/main.lua. All foundational systems operational. Ready for playtesting.

**Architectural insights from Bart:**
- Object sources loaded at startup as mutation fuel (not runtime filesystem access)
- Verb handlers use factory pattern + dependency injection (testable, clean)
- Exit mutations use partial merge; object mutations use full replacement (different semantics for different structural roles)

### Frink's Hosting Platform Research
Frink completed architecture research recommending **Wasmoon (Lua 5.4 → WebAssembly) + Progressive Web App**:
- Phase 1 (3 days): PWA prototype on phones
- Phase 2 (2 weeks): App Store submission via Capacitor
- Phase 3 (Future): Defold migration if graphical elements needed

This validates our Lua engine choice — Wasmoon can run unmodified Lua engine files.

### Brockman's Documentation Refresh
Brockman captured 12+ new design directives from Wayne and updated all documentation:
- Paper + writing system (WRITE verb with pen/pencil/blood as tools)
- Skills system (lockpicking, sewing, crafting unlock new tool combinations)
- Injury mechanics (knife/pin → blood resource)
- **OPEN QUESTION:** Single-file vs. multi-file mutation objects. Wayne questioning whether nightstand-open/nightstand-closed should be one file or two. Potentially challenges D-14 implementation.

### Team Decisions Merged
All 17 new decisions (D-22 through D-36) merged into .squad/decisions.md:
- D-22–D-26: Major architectural decisions (Template System, V1 REPL, Bedroom Design, Tool Convention, Hosting Platform)
- D-27–D-36: User directives (light/time, docs current, newspaper, fire source, paper/writing, blood, skills, puzzles, single-file QUESTION, crafting)

**Decision Architecture Insight:** The tool convention (D-25) opens design space for all puzzle verbs. Capability matching (not item-ID matching) enables extensibility: LIGHT (fire_source), WRITE (pen/pencil/blood), PICK LOCK (lockpicking skill + pin), SEW (sewing skill + needle), CRAFT (crafting skill + materials).
