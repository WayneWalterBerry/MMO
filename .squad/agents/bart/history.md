# Bart — History (Summarized)

## Project Context

- **Project:** MMO — A text adventure MMO with multiverse architecture
- **Owner:** Wayne "Effe" Berry
- **Stack:** Lua (engine + meta-code), cloud persistence
- **Key Concepts:** Each player gets their own universe instance with self-modifying meta-code. Objects are rewritten (not flagged) when state changes. Code IS the state.

## Core Context

**Agent Role:** Architect responsible for engine design, verb systems, mutation mechanics, and tool resolution patterns.

**Work Summary (2026-03-18 to 2026-03-19):**
- Designed and built src/ tree structure (engine/, meta/, parser/, multiverse/, persistence/)
- Implemented four foundational engine modules: loader (sandboxed code execution), registry (object storage), mutation (object rewriting), loop (REPL)
- Established containment constraint architecture (4-layer validator: identity, size, capacity, categories)
- Designed template system + weight/categories + multi-surface containment for complex objects
- Implemented V2 verb system: sensory verbs (FEEL, SMELL, TASTE, LISTEN) all work in darkness
- Designed tool resolution pattern: verb-layer concern, supports virtual tools (blood), capability-based resolution
- Moved game start time from 6 AM → 2 AM for true darkness mechanic

**Architecture Decisions Established:**
- D-14: True code mutation (objects rewritten, not flagged)
- D-16: Lua for both engine and meta-code (loadstring enables self-modification)
- D-17: Universe templates (build-time LLM + procedural variation)
- D-37 to D-41: Sensory verb convention, tool resolution, blood as virtual tool, CUT vs PRICK capability split

**Latest Spawns (2026-03-19):**
1. Sensory verbs + start time fix (6 AM → 2 AM, FEEL/SMELL/TASTE/LISTEN implemented)
2. V2 tool pipeline (WRITE/CUT/PRICK/SEW/PICK LOCK verbs, tool resolution helpers, dynamic mutation via string.format)

**Key Patterns Established:**
- `engine/mutation/` is ONLY code that hot-swaps objects via loadstring()
- Mutation rules separate from object definitions (composable, clean)
- Registry uses instance pattern (not singleton) — enables simultaneous multiverse registries
- Tool resolution uses capabilities (not tool IDs) — supports complex interactions
- Blood is a virtual tool: generated on-demand when `player.state.bloody == true`, not an inventory item

## Recent Updates

### Session Update: V2 Verb System & Tool Pipeline (2026-03-19T13-22)
**Status:** ✅ COMPLETE  
**Parallel Spawns:** 2 successful background spawns

**Spawn 1: Sensory Verbs + Start Time Fix**
- Moved game start from 6 AM → 2 AM (true darkness)
- Implemented FEEL, SMELL, TASTE, LISTEN verbs for sensory navigation
- All sensory verbs work in complete darkness
- Poison mechanic: TASTE → death (immediate consequence)
- Decision D-37: Sensory verb convention established

**Spawn 2: V2 Tool Pipeline (WRITE/CUT/PRICK/SEW/PICK LOCK)**
- Decision D-38: Tool resolution as verb-layer concern
- Decision D-39: Blood as virtual tool
- Decision D-40: CUT vs PRICK capability split
- Decision D-41: Future verb stubs (SEW, PICK LOCK)
- Implemented: Dynamic mutation via string.format + %q (sanitizes player input)
- Tool resolver now supports:
  - find_tool_in_inventory()
  - provides_capability()
  - consume_tool_charge()

**Architecture Insight:** Tool resolution is tightly coupled to verb dispatch — stays in engine/verbs/init.lua, not separate module.

**Next:** Cross-agent impact on Comic Book Guy (sensory descriptions on 37 objects) and design verification.

### 2026-03-21 — Compound Tools, Two-Hand Inventory, Consumables

**Three major engine features implemented in one pass.**

**1. Two-Hand Inventory System:**
- Replaced `player.inventory = {}` with `player.hands = { nil, nil }` (two slots) + `player.worn = {}` + `player.skills = {}`
- Every inventory helper rewritten: `find_in_inventory`, `find_tool_in_inventory`, `find_visible`, `remove_from_location`, `get_light_level`, `inventory_weight`
- New helpers: `hands_full()`, `first_empty_hand()`, `which_hand()`, `get_all_carried_ids()`
- TAKE: checks for empty hand slot; "Your hands are full. Drop something first."
- DROP: removes from hand to room floor
- INVENTORY: shows Left hand / Right hand + bag contents + worn items
- GET X FROM Y: extracts items from held/worn containers
- PUT: now requires item in hand (not just in inventory)
- WEAR/DON: moves wearable item from hand to worn slot
- REMOVE: moves worn item back to hand (needs empty hand)

**2. Compound Tool System (STRIKE verb):**
- STRIKE match ON matchbox: finds matchbox (in hand or reachable surface), checks charges, consumes charge, sets `player.state.has_flame = 3`
- Design decision: you do NOT need to hold the matchbox — it just needs to be within reach. Avoids the "both hands occupied" deadlock.
- Match is ephemeral (`has_flame` state), not a persistent object
- LIGHT verb updated: checks `has_flame` first, then falls back to tool search
- New helper: `find_visible_tool()` — searches room/surfaces for tools (used by STRIKE to find matchbox on nightstand)

**3. Consumables System:**
- Tick system: `context.on_tick(ctx)` called after every command via loop hook
- Match flame: `has_flame` decrements each tick; "The match sputters and dies." when exhausted
- Candle burn: `burn_remaining = 60` on candle-lit.lua; ticks down per command; warning at 5; consumed at 0 with "The candle gutters and goes out, plunging the room into darkness."
- EAT verb (stub): checks `obj.edible`, removes from world
- BURN verb (stub): checks flame + flammable category, removes from world

**Files modified:**
- `src/engine/verbs/init.lua` — ~350 lines rewritten/added (all inventory helpers, TAKE, DROP, INVENTORY, PUT, LIGHT rewritten; STRIKE, WEAR, REMOVE, EAT, BURN, GET FROM added)
- `src/main.lua` — Player state restructured, on_tick handler for flame/candle burn
- `src/engine/loop/init.lua` — Post-command tick hook
- `src/meta/objects/candle-lit.lua` — Added `burn_remaining = 60`
- `src/meta/objects/wool-cloak.lua` — Added `wearable = true`

**Key architectural decisions:**
- Hand system is slot-based (2 items max), NOT weight-based — simpler, more physical
- Bags in hands extend capacity but cost a hand slot; worn bags (backpack) are free
- `get_all_carried_ids(ctx)` is the canonical function for "everything the player has access to"
- `find_visible` returns location type ("room"/"surface"/"container"/"hand"/"bag"/"worn") so verbs can make location-specific decisions
- Tick system is per-command, not real-time (V1 simplicity)
- Function ordering in verbs/init.lua matters for Lua upvalue capture — `provides_capability` must be defined before `find_visible_tool`

**Decision filed at:** `.squad/decisions/inbox/bart-compound-tools-hands-consumables.md`

### 2026 — GUID Assignment for Streaming Architecture Prep

**All 45 .lua files in src/meta/ now carry a unique UUID v4 `guid` field.**

**Changes:**
- 39 object files in `src/meta/objects/` — each has a `guid` field as first field in the returned table
- 1 room file in `src/meta/world/` — `start-room.lua` has its own guid
- 5 template files in `src/meta/templates/` — each has a guid (these are definition GUIDs, not instance GUIDs)
- `src/engine/registry/init.lua` — now maintains a `_guid_index` table (guid→id mapping), updated on register/remove; added `find_by_guid(guid)` method

**Key design rules:**
- GUIDs are STABLE — once assigned to a definition file, never changed
- Mutation variants (candle vs candle-lit) have DIFFERENT GUIDs because they are different definitions
- The guid is for the DEFINITION, not the live instance — when an object mutates, the registry entry keeps its original id
- No networking code — just the IDs and the registry index, preparing for future streaming/download architecture

**Decision filed at:** `.squad/decisions/inbox/bart-guid-definitions.md`
