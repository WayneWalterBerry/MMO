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
│   └── loop/         — main game loop: read input → dispatch → tick → output
│
├── meta/
│   ├── world/        — room graph: canonical room definitions and exit topology
│   ├── objects/      — canonical object definitions (e.g. mirror.lua, chest.lua)
│   ├── npcs/         — NPC definitions (behaviour, dialogue, state)
│   └── mutations/    — named mutation rules: what an object becomes after an event
│
├── parser/
│   ├── verbs/        — verb handlers: each verb (break, open, take, look…) as a module
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
The machine that makes code-IS-state possible. Four sub-concerns kept deliberately separate:

- **loader** — one job: accept a Lua string, return a sandboxed live table. No knowledge of the world.
- **registry** — the authoritative map of `id → live object` for a universe instance. Everything else looks up objects here.
- **mutation** — given an object id and a new Lua source string, call loader and hot-swap the entry in registry. This is the core differentiator of the whole engine. It must be simple, fast, and auditable.
- **loop** — thin orchestrator. Reads a command string, routes through parser, fires handlers, drives output. Keeps everything else stateless.

### `meta/`
The canonical authored world — the source of truth before any player touches it. This is **not** runtime state; it is the template that gets cloned per-player universe.

- **world/** — room graph lives here. Each room is a Lua table with `name`, `description`, `exits`, and `on_enter` hooks.
- **objects/** — per-object `.lua` files. `mirror.lua` is a prime example (see below).
- **mutations/** — named transformation rules. `mirror-break.lua` describes what the mirror *becomes* after the `break` verb fires. Keeping mutations separate from object definitions means the object file stays clean and mutation rules can be reused, composed, or versioned independently.
- **npcs/** — behavioural definitions, separated from static objects because they tick on every loop turn.

### `parser/`
Intentionally thin. The team decision is: **no per-interaction LLM tokens**. This is a fast, local lookup.

- **verbs/** — one file per canonical verb. `break.lua` knows how to resolve `break <noun>` into an engine call.
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

Two places, deliberately split:

| What | Where |
|------|-------|
| The broken-mirror *definition* (what the object IS after mutation) | `src/meta/mutations/mirror-break.lua` |
| The generic *rewrite mechanism* (how any object gets swapped) | `src/engine/mutation/` |

The verb handler `src/parser/verbs/break.lua` is the glue: it resolves the noun (`mirror`), looks up the mutation rule (`mirror-break`), and calls `engine/mutation` with both. The mutation engine calls `loader` with the new source, then updates `registry`. Done.

This means the engine itself knows nothing about mirrors. The mirror knows nothing about being broken. The mutation rule file is the only place that couples them — and it's small, auditable, and LLM-generatable.

### 3. How far are we? Dependency chain.

We are **zero files written** in `src/` today. Here is the dependency chain from zero to "break mirror works":

```
[1] engine/loader        — sandboxed loadstring() wrapper
        ↓
[2] engine/registry      — object store for a universe
        ↓
[3] engine/mutation      — hot-swap using loader + registry
        ↓
[4] meta/objects/mirror.lua          — intact mirror definition
    meta/mutations/mirror-break.lua  — broken mirror definition
        ↓
[5] parser/synonyms      — "smash", "shatter" → "break"
    parser/verbs/break.lua           — resolves noun, fires mutation
        ↓
[6] engine/loop          — minimal read/eval/print loop
        ↓
[7] meta/world/start-room.lua        — one room containing the mirror
```

**Blockers before writing the mirror:**  
None. The mirror definition (`step 4`) can be written *today* without any engine code existing — it's just a Lua table. The engine pieces (steps 1–3) can also be written independently and in parallel with the meta content.

**Realistic sequencing for a minimal prototype:**  
Steps 1 → 2 → 3 can be written back-to-back in a single session (each is ~30–60 lines of Lua). Steps 4 and 5 follow immediately. Step 6 is a tiny REPL. Step 7 is one room table. A working "break mirror" prototype is **3–4 hours of writing** once the architecture is clear — which it now is.

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
