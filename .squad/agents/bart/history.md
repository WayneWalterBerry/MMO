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
