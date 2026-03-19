# Source Tree Architecture

**Author:** Bart (Architect)  
**Date:** 2026-03-18  
**Status:** Approved — structure created

---

## Overview

The `src/` tree is organized around the five concerns of this engine:

1. **Engine** — loads, runs, and mutates live Lua code
2. **Meta** — canonical world templates (rooms, objects, mutations)
3. **Parser** — command interpretation (verb dispatch, synonym mapping)
4. **Multiverse** — universe lifecycle, ghost mechanics, fog of war
5. **Persistence** — cloud serialization of live universe state

Folder names follow the team convention: lowercase, dashes.

---

## Full Tree

```
src/
├── engine/
│   ├── loader/       — sandboxed loadstring() wrapper; turns Lua source into live objects
│   ├── registry/     — tracks every live object in a universe (by id)
│   ├── mutation/     — replaces a live object definition with a new one (the rewrite engine)
│   ├── containment/  — validates item placement against container constraints
│   └── loop/         — main game loop: read input → dispatch → tick → output
│
├── meta/
│   ├── world/        — room graph: canonical room definitions and exit topology
│   ├── objects/      — canonical object definitions with self-describing mutations
│   │                    (includes: paper, pen, pencil, knife, pin, needle, matchbox, match, match-lit, thread, poison-bottle)
│   ├── templates/    — base object templates for inheritance (sheet, furniture, container, small-item)
│   └── npcs/         — NPC definitions (behaviour, dialogue, state)
│
├── parser/
│   ├── verbs/        — verb handlers (~20 canonical verbs: look, take, drop, open, close, light, strike, write, cut, prick, feel, smell, taste, listen, break, examine, inventory, help, etc.)
│   └── synonyms/     — synonym tables mapping player input to canonical verbs/nouns
│
├── multiverse/
│   ├── instancing/   — fork a canonical template into a new player universe
│   ├── ghosts/       — project a player from universe A as a ghost into universe B
│   └── fog/          — fog-of-war: ghosts see only the room they currently occupy
│
├── persistence/
│   ├── serializer/   — dump/restore live registry state to/from a portable format
│   └── cloud/        — cloud provider adapter (read/write player universe snapshots)
│
├── utils/            — shared helpers (string, table, logging, uuid)
└── config/           — constants, feature flags, engine tunables
```

---

## Rationale

### `engine/`
The machine that makes code-IS-state possible. Five sub-concerns kept deliberately separate:

- **loader** — one job: accept a Lua string, return a sandboxed live table. No knowledge of the world.
- **registry** — the authoritative map of `id → live object` for a universe instance. Everything else looks up objects here.
- **mutation** — given an object id and a new Lua source string, call loader and hot-swap the entry in registry. This is the core differentiator of the whole engine. It must be simple, fast, and auditable.
- **containment** — validates whether an item can be placed in a container by checking five layers (container identity, physical size, capacity, category, weight). Runs before any mutation occurs.
- **loop** — thin orchestrator. Reads a command string, routes through parser, fires handlers, drives output. Composes room views dynamically: room description (permanent features) + object `room_presence` sentences + visible exits. See `docs/design/dynamic-room-descriptions.md`. Keeps everything else stateless.

### `meta/`
The canonical authored world — the source of truth before any player touches it. This is **not** runtime state; it is the template that gets cloned per-player universe.

- **world/** — room graph lives here. Each room is a Lua table with `name`, `description`, `exits`, and `on_enter` hooks. Room `description` must contain ONLY permanent features (walls, floor, ceiling, atmosphere, light, smell). Movable objects are NEVER referenced in room descriptions — the engine composes them dynamically from object `room_presence` fields at runtime. See `docs/design/dynamic-room-descriptions.md`.
- **objects/** — per-object `.lua` files containing the canonical definition plus self-describing mutations. Each object defines a `room_presence` field — a complete prose sentence describing how the object appears at a glance when standing in the room. Objects use `description` for detailed examine text. `room_presence` must NOT reference other movable objects (only walls, corners, floor — permanent features).
- **templates/** — base object templates for inheritance. Templates define shared properties that multiple objects can reference. Common templates: `sheet`, `furniture`, `container`, `small-item`. Objects reference a template via `template = "sheet"` and the engine merges the template properties with the object's own definition.
- **npcs/** — behavioural definitions, separated from static objects because they tick on every loop turn.

### `parser/`
Intentionally thin. The team decision is: **no per-interaction LLM tokens**. This is a fast, local lookup.

- **verbs/** — one file per canonical verb (~20 verbs implemented: LOOK, TAKE, DROP, OPEN, CLOSE, LIGHT, STRIKE, WRITE, CUT, PRICK, FEEL, SMELL, TASTE, LISTEN, BREAK, EXAMINE, INVENTORY, HELP, etc.). Each verb file knows how to resolve `verb <noun>` into an engine call.
- **synonyms/** — tables like `{ smash=break, shatter=break, destroy=break }`. Loaded once at startup.

### `multiverse/`
Inter-universe mechanics. Kept entirely separate from the engine because the engine operates on a single universe instance and has no concept of "other universes".

- **instancing/** — forks a canonical meta/ template into a fresh, isolated registry. Applies procedural variation seeds.
- **ghosts/** — reads a foreign universe's registry (read-only) and injects a ghost proxy object into the host universe.
- **fog/** — restricts what a ghost's player can observe to their current room only.

### `persistence/`
Cloud persistence is an adapter concern — the engine doesn't care where state goes.

- **serializer/** — converts a live registry (Lua tables, closures stripped) into a portable snapshot format and back.
- **cloud/** — provider-specific adapter. Swap S3 for Firebase without touching the rest of the engine.

### `utils/`
Cross-cutting helpers with no domain knowledge. String manipulation, UUID generation, structured logging, table deep-copy. No file in `utils/` imports from any other `src/` directory.

### `config/`
Single source of truth for engine-wide constants: tick rate, max universe size, cloud bucket names, feature flags.

---

## The Mirror Question

### 1. Where does the mirror's meta-code definition live?

```
src/meta/objects/mirror.lua
```

This file is the canonical intact-mirror definition — a Lua table with `name`, `description`, `keywords`, a `look` handler, and any initial state. It is loaded by the instancing system when a player's universe is forked from the template.

### 2. Where does the mutation logic live?

**All mutation definitions now live inside the object file itself.** Objects use a `mutations` table to self-describe what they become after events.

```lua
-- src/meta/objects/mirror.lua
return {
  id          = "mirror",
  name        = "ornate mirror",
  -- ... other fields ...
  mutations   = {
    break = {
      becomes = "mirror-broken",     -- this mirror becomes mirror-broken object
      spawns  = { shard = 3 },        -- and spawns 3 shards
    },
  }
}
```

The verb handler `src/parser/verbs/break.lua` is the glue: it resolves the noun (`mirror`), reads the mutation definition from the object (`mirror.mutations.break`), and calls `engine/mutation` with the new object definition (`mirror-broken`). The mutation engine calls `loader` with the new source, then updates `registry`. Done.

This means the engine itself knows nothing about mirrors. The mirror knows nothing about being broken. The object file is the only place that couples them — it's small, auditable, and LLM-generatable. Mutations are now **self-describing** and kept with their objects, not scattered in a separate mutations directory.

### 3. How far are we? Dependency chain.

We are **zero files written** in `src/` today. Here is the dependency chain from zero to "break mirror works":

```
[1] engine/loader        — sandboxed loadstring() wrapper
        ↓
[2] engine/registry      — object store for a universe
        ↓
[3] engine/mutation      — hot-swap using loader + registry
        ↓
[4] engine/containment   — validator for item placement
        ↓
[5] meta/objects/mirror.lua          — intact mirror definition with mutations table
    meta/objects/mirror-broken.lua   — broken mirror definition
        ↓
[6] parser/synonyms      — "smash", "shatter" → "break"
    parser/verbs/break.lua           — resolves noun, reads mutations, fires rewrite
        ↓
[7] engine/loop          — minimal read/eval/print loop
        ↓
[8] meta/world/start-room.lua        — one room containing the mirror
```

**Blockers before writing the mirror:**  
None. The mirror definition (`step 5`) can be written *today* without any engine code existing — it's just a Lua table. The engine pieces (steps 1–4) can also be written independently and in parallel with the meta content.

**Realistic sequencing for a minimal prototype:**  
Steps 1 → 2 → 3 → 4 can be written back-to-back in a single session (each is ~20–40 lines of Lua). Steps 5 and 6 follow immediately. Step 7 is a tiny REPL. Step 8 is one room table. A working "break mirror" prototype is **3–4 hours of writing** once the architecture is clear — which it now is.

### 4. Minimal Prototype

The smallest possible thing that works:

```
src/
├── engine/
│   ├── loader/init.lua      (~30 lines) — load(source, env) wrapper
│   ├── registry/init.lua    (~40 lines) — table keyed by id, get/set/list
│   └── mutation/init.lua    (~20 lines) — registry:set(id, loader.load(new_source))
├── meta/
│   ├── world/start-room.lua (~20 lines) — one room, one exit (nowhere), contains mirror
│   ├── objects/mirror.lua   (~15 lines) — intact mirror table
│   └── mutations/
│       └── mirror-break.lua (~15 lines) — broken mirror table
├── parser/
│   ├── synonyms/init.lua    (~10 lines) — { break={smash,shatter,destroy} }
│   └── verbs/break.lua      (~25 lines) — dispatch to mutation
└── engine/loop/init.lua     (~40 lines) — io.read() REPL, routes to verbs
```

Total: ~215 lines of Lua to reach a runnable "break mirror" demo.  
No cloud. No multiverse. No ghosts. Just the mutation engine proving itself.

---

## Documentation: Puzzle Architecture

A new folder `docs/puzzles/` contains design documentation for each puzzle in the game. Game designers document:

- Puzzle name and location
- Prerequisite knowledge / skills required
- Solution path(s)
- Objects involved
- Sensory / timing constraints
- Teach-value (what the player learns)
- Consequence if failed

**Purpose:** Makes puzzle design collaborative and auditable. New designers onboard by reading puzzle docs before implementation. Each puzzle's design is preserved and referenced alongside code.

---

## What Comes After the Prototype

Once the prototype validates the mutation model, the build-out order is:

1. Expand `meta/objects/` and `meta/mutations/` (content sprint)
2. `parser/` — full synonym tables and verb coverage
3. `persistence/serializer/` — snapshot the registry so a session can be resumed
4. `multiverse/instancing/` — fork universes per player
5. `persistence/cloud/` — connect serializer to cloud
6. `multiverse/ghosts/` + `multiverse/fog/` — inter-universe mechanics last

---

*Bart — Architect*
