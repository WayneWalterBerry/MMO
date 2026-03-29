# Save Game Architecture

**Author:** Bart (Engine Architect)  
**Date:** 2026-08-04  
**Version:** 1.0 — Research & Recommendation  
**Status:** PROPOSAL — Awaiting Wayne approval

---

## 1. Problem Statement

Players want to save progress in the web version. The challenge is unique:

- **Code mutation IS state change** (D-14). When you break a mirror, `mirror.lua` is literally rewritten to `mirror-broken.lua` at runtime. There are no separate state flags.
- **Static site** — no server-side storage. GitHub Pages serves files. That's it.
- **Fengari runtime** — Lua runs in-browser via JavaScript. All state lives in JS/Lua memory.
- **JIT loading** — rooms and objects are fetched on-demand via HTTP. The server never knows what the player has done.
- **143 objects** across 7 rooms, plus player state, FSM timers, injuries, consciousness, skills, containment graph.

The question: how do you snapshot a self-modifying codebase into something persistable in a browser?

---

## 2. State Inventory

Before evaluating approaches, here's what constitutes a complete game state:

### 2.1 Player State (~2 KB)

| Field | Type | Notes |
|-------|------|-------|
| `hands[1], hands[2]` | string or nil | Object IDs held in each hand |
| `worn` | table | Body slot → object ID (`{head="hood", torso="jacket"}`) |
| `skills` | table | Binary flags (`{lockpicking=true, sewing=true}`) |
| `location` | string | Current room ID |
| `health` | number | Current HP (max 100) |
| `injuries` | array | Active injury objects with tick counters |
| `state.bloody` | boolean | Bleeding flag |
| `state.poisoned` | boolean | Poison flag |
| `state.has_flame` | number | Match/flame tick counter |
| `state.bleed_ticks` | number | Bleeding countdown |
| `visited_rooms` | table | `{[room_id] = true}` set |
| `consciousness` | table | State, wake_timer, cause |
| `body_tree` | table | Damage model per zone (head, torso, arms, etc.) |
| `combat` | table | Size, speed, natural weapons |

### 2.2 Object Runtime State (~50-200 bytes per mutated object)

For each object that has changed from its base definition:

| Field | Why It Changed |
|-------|---------------|
| `_state` | FSM transition (e.g., "unlit" → "lit") |
| `location` | Moved by player (picked up, dropped, placed) |
| `container` | Placed inside something |
| `remaining_burn` | Candle/match partial timer |
| `is_open` | Drawer, wardrobe, door opened |
| `contents` | Items added/removed from containers |
| `surfaces[zone].contents` | Items placed on surfaces |
| Mutation target fields | Object was mutated (broken mirror, lit candle, etc.) |

### 2.3 Room State (~100 bytes per visited room)

| Field | Notes |
|-------|-------|
| `contents` | Which objects are in the room (after player moves things) |
| `surfaces[].contents` | Surface contents of room-level fixtures |
| `exits[].open, .locked` | Door/exit state changes |

### 2.4 Engine State (~500 bytes)

| Field | Notes |
|-------|-------|
| `fsm.active_timers` | Object ID → `{state, remaining, event, to_state}` |
| `fsm.paused_timers` | Same structure, for objects in unloaded rooms |
| `game_start_time` | Epoch timestamp |
| `context.last_noun` | Last referenced object (pronoun resolution) |
| `context.last_tool` | Last tool used |

### 2.5 Total Estimate

| Scenario | Estimated Size |
|----------|---------------|
| Fresh game (1 room, no changes) | ~3 KB |
| Mid-game (3 rooms, 10 mutations) | ~8-15 KB |
| Full playthrough (7 rooms, 30+ mutations) | ~20-40 KB |

These are JSON-serialized sizes. Well within browser storage limits.

---

## 3. Approach Analysis

### 3.1 Full Snapshot — Serialize Entire Registry

**Concept:** Walk `registry._objects`, serialize every live object to JSON, store in localStorage.

**Implementation:**
```
save = {
    version: 1,
    player: { ...player state... },
    objects: { [id]: { ...full object table... }, ... },
    rooms: { [id]: { contents, surfaces, exits }, ... },
    timers: { active: {...}, paused: {...} },
    meta: { game_start_time, save_time, turn_count }
}
```

**Pros:**
- Conceptually simple — one big dump, one big restore
- Complete — nothing lost
- Load is fast — no replay, just deserialize and register

**Cons:**
- **Functions can't serialize.** Objects have `on_tick`, `guard`, `on_transition`, `mutations` with function values. These come from the `.lua` source and can't be stored as JSON.
- **Size:** 143 objects × ~500 bytes average runtime state = ~70 KB minimum, likely 100-200 KB with descriptions and metadata. Not huge, but wasteful since most objects are unchanged.
- **Staleness:** If we ship a game update that changes an object definition, the snapshot has the OLD definition baked in. Player loads stale state.

**Verdict:** ❌ Not viable as-is. Functions in object tables are a hard blocker. Could work if we serialize only data fields and reload functions from source, but that's basically the hybrid approach.

### 3.2 Delta/Replay — Track Mutations, Replay on Load

**Concept:** Record every player action as a command. On load, start from fresh and replay all commands.

**Implementation:**
```
save = {
    version: 1,
    commands: ["look", "take candle", "go north", "light candle with match", ...]
}
```

**Pros:**
- Tiny save file — just an array of strings
- Leverages existing command processing pipeline
- Automatically picks up game updates (replays against new code)

**Cons:**
- **Slow.** A 200-command game takes real time to replay. Each command goes through the full parser pipeline (5 tiers), verb dispatch, FSM ticks, mutation, sound hooks.
- **Non-deterministic.** Timed events (candle burndown, FSM timers) depend on real elapsed time between commands. Replay timing won't match.
- **Fragile.** If ANY game update changes verb behavior, the replay diverges. "light candle" might fail if we changed the match requirement.
- **Side effects.** Print output during replay must be suppressed. Sound hooks must be muted. Creature AI ticks are time-dependent.

**Verdict:** ❌ Too fragile, too slow. Replay-based saves are a known anti-pattern in games with time-dependent state.

### 3.3 Mutation Log — Record State Transitions, Not Commands

**Concept:** Track only the state-changing operations: mutations applied, FSM transitions, object movements. On load, start from fresh base objects and apply the log.

**Implementation:**
```
save = {
    version: 1,
    player: { ...player snapshot... },
    mutations: [
        { object: "candle", type: "fsm", from: "unlit", to: "lit", time: 123 },
        { object: "vanity", type: "mutation", becomes: "vanity-mirror-broken", time: 145 },
        { object: "knife", type: "move", to: "player.hands.0", time: 156 }
    ],
    timers: { ... }
}
```

**Pros:**
- Small save file (~5-15 KB for a full playthrough)
- Leverages the mutation system directly
- Game updates to non-mutated objects apply automatically

**Cons:**
- **Replay order matters.** Mutations must be applied in exact sequence — some depend on prior state (breaking a mirror requires it to exist first).
- **Partial rebuild latency.** Loading requires fetching every affected object from the server (HTTP requests), then applying mutations in order. Could take 2-5 seconds over HTTP.
- **Complex implementation.** Need to instrument every state-changing code path to emit log entries: FSM transitions, mutations, movements, containment changes, exit state changes.
- **Function reload problem persists.** After applying mutations, objects still need their functions reloaded from source.

**Verdict:** ⚠️ Feasible but complex. The instrumentation burden is high — every verb handler, every FSM transition, every containment change needs logging.

### 3.4 Hybrid Snapshot — Data Fields + Source Reload (RECOMMENDED)

**Concept:** Serialize only the **data fields** of changed objects (skip functions). On load, reload object source from server, then overlay the saved data fields.

**Implementation:**
```
save = {
    version: 2,
    format: "hybrid-v1",
    player: {
        hands: ["candle", null],
        worn: { torso: "terrible-jacket" },
        skills: { sewing: true },
        location: "hallway",
        health: 85,
        injuries: [{ type: "minor-cut", zone: "hands", ticks: 3 }],
        state: { bloody: true, has_flame: 0, bleed_ticks: 5 },
        visited_rooms: ["start-room", "hallway", "cellar"],
        consciousness: { state: "conscious" },
        body_tree: { ... }
    },
    objects: {
        "candle": { _state: "lit", remaining_burn: 42, location: "player" },
        "vanity": { _state: "mirror_broken", location: "room" },
        "nightstand": { _state: "open", location: "room" },
        "knife": { location: "player.hands.1" },
        "brass-key": { location: "hallway.floor" }
    },
    rooms: {
        "start-room": {
            contents: ["bed", "pillow", "nightstand", "vanity", "wardrobe"],
            exits: { north: { open: true, locked: false } }
        },
        "hallway": {
            contents: ["brass-key", "rug"]
        }
    },
    timers: {
        active: { "candle": { state: "lit", remaining: 42, event: "timer_expired", to_state: "extinguished" } },
        paused: {}
    },
    meta: {
        save_time: 1722729600,
        game_start_time: 1722726000,
        turn_count: 47,
        engine_version: "1.0",
        level: "level-01"
    }
}
```

**Load sequence:**
1. Parse save JSON from localStorage/IndexedDB
2. Boot engine normally (load templates, level definition)
3. For each room in `save.rooms`: JIT-load room + objects from server (same HTTP path as normal play)
4. For each object in `save.objects`: overlay saved data fields onto the freshly-loaded instance
5. For FSM objects: if `_state` differs from `initial_state`, apply the target state (which reloads functions from the state definition)
6. For mutated objects: if the mutation target differs from the base object, load the mutation target source and apply it
7. Restore player state
8. Restore FSM timers
9. Set current room, print room description

**Pros:**
- **No function serialization.** Functions come from source code, reloaded fresh.
- **Small saves.** Only changed data fields — typically 5-20 KB.
- **Game updates work.** Unchanged objects get new definitions. Changed objects keep their saved state.
- **Fast load.** Room/object sources are already HTTP-cached from prior play. Restoration is table-merge, not replay.
- **Mutation-compatible.** For mutated objects (mirror → mirror-broken), we store the mutation target ID. On load, we fetch the mutation target source and instantiate it.

**Cons:**
- **Mutation target tracking needed.** We need to know which objects were mutated and what they became. The mutation system already has `becomes` fields — we store the target.
- **Version migration.** If a game update changes an object's state machine (adds/removes states), saved `_state` values might not match. Need a version check.
- **Object diff logic.** Need a function to compare current object against base and extract only changed fields.

**Verdict:** ✅ **Recommended.** Best balance of correctness, size, and compatibility with the mutation architecture.

### 3.5 Export Code — Base64 Save String

**Concept:** Same as hybrid snapshot, but instead of localStorage, encode the save as a base64 string the player copies.

**Implementation:** Same JSON structure as §3.4, but `btoa(JSON.stringify(save))` → display in a text box.

**Pros:**
- Zero storage dependency — works on any browser, any device
- Player can share saves, back up manually
- Familiar pattern (Cookie Clicker, Candy Box, Universal Paperclips)

**Cons:**
- UX friction — copy/paste is clunky on mobile
- Base64 inflates size ~33% (20 KB → 27 KB encoded)
- No auto-save — player must remember to export

**Verdict:** ✅ **Include as secondary option.** Offer alongside localStorage for portability. Good fallback when localStorage is cleared.

### 3.6 Cloud Save — Backend Storage

**Concept:** Send save JSON to a backend (Azure Functions, Firebase, etc.), keyed by player ID.

**Pros:**
- Cross-device sync
- Automatic backups
- Could enable leaderboards, analytics

**Cons:**
- Requires authentication (player accounts)
- Requires backend infrastructure (cost, maintenance)
- Static site philosophy violation
- GDPR/privacy considerations for player data

**Verdict:** ⏳ **Future phase.** Not for V1. Mention as upgrade path.

---

## 4. Recommended Design: Hybrid Snapshot

### 4.1 Save Format

```json
{
    "version": 2,
    "format": "hybrid-v1",
    "level": "level-01",
    "player": { /* §2.1 fields */ },
    "changed_objects": {
        "<object_id>": {
            "mutation_target": "<target_id or null>",
            "state": "<fsm_state or null>",
            "fields": { /* only changed data fields */ }
        }
    },
    "room_state": {
        "<room_id>": {
            "contents": ["obj1", "obj2"],
            "exit_overrides": { "north": { "open": true, "locked": false } }
        }
    },
    "timers": {
        "active": { /* fsm.active_timers snapshot */ },
        "paused": { /* fsm.paused_timers snapshot */ }
    },
    "meta": {
        "save_time": 1722729600,
        "game_start_time": 1722726000,
        "turn_count": 47,
        "engine_version": "1.0"
    }
}
```

### 4.2 Identifying Changed Objects

An object is "changed" if any of these are true:

1. **FSM state differs** from `initial_state` (e.g., candle lit, nightstand open)
2. **Location differs** from original room placement (picked up, moved, dropped)
3. **Mutation applied** — the object was replaced via `mutation.mutate()` (mirror broken)
4. **Contents changed** — items added to or removed from a container/surface
5. **Custom runtime fields changed** — `remaining_burn`, injury state, etc.

### 4.3 Mutation Tracking

The mutation system already knows what an object "becomes" — it's declared in the object metadata:

```lua
mutations = {
    break = { becomes = "vanity-mirror-broken", message = "..." }
}
```

When `mutation.mutate()` fires, we record:
```lua
save_state.mutations[object_id] = {
    target = "vanity-mirror-broken",  -- the mutation target ID
    source_guid = "abc-123"           -- GUID of the mutation target definition
}
```

On load, instead of loading the original object, we load the mutation target source and instantiate it.

### 4.4 Storage Strategy

**Primary: localStorage** (5-10 MB limit per origin)
- `mmo_save_slot_1` through `mmo_save_slot_3` — three save slots
- `mmo_save_auto` — auto-save on room transitions
- Each key stores the JSON string

**Secondary: Export code**
- Base64-encoded JSON string
- Displayed in a modal dialog with copy button
- Import: paste into text area, decode, validate, load

**Future: IndexedDB**
- If saves exceed 5 MB (unlikely for Level 1, possible for multi-level games)
- Async API, but unlimited storage

### 4.5 Auto-Save Points

Trigger auto-save on:
- Room transitions (player moved to a new room)
- Major mutations (object broken, key item obtained)
- Every N commands (configurable, default 10)

### 4.6 Load Sequence (Detailed)

```
1. Read JSON from localStorage
2. Validate version + format
3. Initialize engine (templates, base modules)
4. Load level definition
5. For each room in save.room_state:
   a. JIT-load room from server (HTTP, cached)
   b. Override room.contents with saved contents
   c. Override exit states
6. For each object in save.changed_objects:
   a. If mutation_target set:
      - Load mutation target source from server
      - Instantiate as new object
   b. Else:
      - Load original object source from server
   c. Overlay saved fields (state, location, etc.)
   d. Register in registry
7. For unmodified objects in loaded rooms:
   - Normal JIT load (no overlay needed)
8. Restore player state
9. Restore FSM timers
10. Set context.current_room
11. Run room on_enter (but suppress "first visit" text)
12. Print room description
```

### 4.7 JSON Serialization

Lua tables with functions can't be directly serialized. The serializer must:

1. **Skip function values** — they come from source on reload
2. **Skip metatables** — engine sets these at runtime
3. **Handle nil array holes** — `hands = {nil, "knife"}` → `hands: [null, "knife"]`
4. **Circular reference detection** — containment can create cycles (object.location → room, room.contents → object). Serialize by ID reference, not nested objects.

We already have a minimal JSON module (`engine/parser/json.lua`) for the embedding index. Extend it with a `json.encode()` function, or use a small pure-Lua JSON encoder (~100 LOC).

### 4.8 Version Migration

```json
{
    "version": 2,
    "migrations": {
        "1_to_2": "Added consciousness field to player"
    }
}
```

On load, if `save.version < CURRENT_VERSION`, run migration functions:
```lua
migrations[1] = function(save)
    save.player.consciousness = save.player.consciousness or { state = "conscious" }
    save.version = 2
    return save
end
```

---

## 5. Example Save File

Scenario: Player has explored 3 rooms, lit the candle, broken the vanity mirror, picked up the knife and brass key, opened the nightstand drawer.

```json
{
    "version": 2,
    "format": "hybrid-v1",
    "level": "level-01",
    "player": {
        "hands": ["candle", "knife"],
        "worn": {},
        "skills": {},
        "location": "hallway",
        "health": 92,
        "max_health": 100,
        "injuries": [
            { "type": "minor-cut", "zone": "hands", "ticks_remaining": 3 }
        ],
        "state": {
            "bloody": true,
            "poisoned": false,
            "has_flame": 0,
            "bleed_ticks": 5
        },
        "visited_rooms": ["start-room", "hallway", "cellar"],
        "consciousness": { "state": "conscious" },
        "body_tree": {
            "hands": { "wounds": [{ "type": "cut", "severity": 1 }] }
        }
    },
    "changed_objects": {
        "candle": {
            "mutation_target": null,
            "state": "lit",
            "fields": {
                "remaining_burn": 42,
                "location": "player"
            }
        },
        "vanity": {
            "mutation_target": "vanity-mirror-broken",
            "state": null,
            "fields": {
                "location": "room"
            }
        },
        "nightstand": {
            "mutation_target": null,
            "state": "open",
            "fields": {}
        },
        "knife": {
            "mutation_target": null,
            "state": null,
            "fields": {
                "location": "player"
            }
        },
        "brass-key": {
            "mutation_target": null,
            "state": null,
            "fields": {
                "location": "hallway"
            }
        }
    },
    "room_state": {
        "start-room": {
            "contents": ["bed", "pillow", "nightstand", "vanity", "wardrobe", "window", "curtains", "rug"],
            "exit_overrides": {
                "north": { "open": true, "locked": false }
            }
        },
        "hallway": {
            "contents": ["brass-key"]
        }
    },
    "timers": {
        "active": {
            "candle": {
                "state": "lit",
                "remaining": 42,
                "event": "timer_expired",
                "to_state": "extinguished"
            }
        },
        "paused": {}
    },
    "meta": {
        "save_time": 1722729600,
        "game_start_time": 1722726000,
        "turn_count": 47,
        "engine_version": "1.0"
    }
}
```

**Size: ~1.8 KB** (minified JSON, no whitespace).

---

## 6. Size Estimates

| Scenario | Changed Objects | Rooms | Est. Save Size |
|----------|----------------|-------|----------------|
| Just started (1 room, 0 mutations) | 0 | 1 | ~1 KB |
| Early game (2 rooms, 5 mutations) | 5 | 2 | ~3 KB |
| Mid-game (4 rooms, 15 mutations) | 15 | 4 | ~8 KB |
| Full Level 1 (7 rooms, 30 mutations) | 30 | 7 | ~15 KB |
| Multi-level future (20 rooms, 80 mutations) | 80 | 20 | ~40 KB |

**localStorage budget:** 5 MB per origin. Three save slots + auto-save = 4 × 40 KB = 160 KB maximum. That's 3% of the budget. Plenty of headroom.

**Export code size:** Base64 inflates ~33%. A 15 KB save → 20 KB base64 string. Copy-pasteable on desktop; annoying but workable on mobile.

---

## 7. Implementation Scope

### 7.1 New Modules

| Module | Location | LOC Est. | Purpose |
|--------|----------|----------|---------|
| `save/init.lua` | `src/engine/save/init.lua` | ~200 | `save.capture(context)` → save table, `save.restore(context, data)` → rebuild state |
| `save/serialize.lua` | `src/engine/save/serialize.lua` | ~150 | Pure-data table → JSON serializer (skip functions, handle nils) |
| `save/migrate.lua` | `src/engine/save/migrate.lua` | ~50 | Version migration functions |
| Web save UI | `web/game-adapter.lua` (additions) | ~100 | localStorage read/write, export/import UI hooks |

### 7.2 Changes to Existing Modules

| Module | Change | Why |
|--------|--------|-----|
| `mutation/init.lua` | Record mutation target on object (`obj._mutation_from`) | So save knows what the object was mutated from |
| `loop/init.lua` | Auto-save trigger after N commands / room change | Fire save on natural breakpoints |
| `fsm/init.lua` | No changes | Timer data already accessible via `fsm.active_timers` |
| `registry/init.lua` | No changes | `registry:list()` already returns all objects |
| `web/game-adapter.lua` | Add save/load/export/import JS bridge calls | localStorage API, UI buttons |

### 7.3 New Verbs

| Verb | Action |
|------|--------|
| `save` | Trigger manual save (slot selection) |
| `load` | Trigger manual load (slot selection) |
| `export` | Display save code for copy |
| `import` | Accept pasted save code |

### 7.4 Estimated Total Effort

~500 LOC of new Lua code + ~100 LOC of JS/HTML changes. **2-3 focused sessions.**

---

## 8. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Object definition changes break saves | Player loses progress | Version field + migration functions; warn if incompatible |
| localStorage cleared by browser | Saves lost | Offer export code as backup; prompt player to export periodically |
| Mutation target source not available on server | Load fails | Validate all mutation target files exist at build time; fail gracefully with error message |
| Circular references in serialization | Crash or corrupt save | Serialize containment by ID reference, never nested objects; add cycle detection |
| FSM timer precision loss | Candle burns differently after load | Accept ±1 tick precision loss; document as known limitation |

---

## 9. Future Considerations

- **Cloud save** — When/if we add player accounts, the same JSON format uploads to a backend. No format change needed.
- **Save sharing** — Export codes are portable. Players could share saves to show off or help each other.
- **Replay viewer** — If we also log commands (separately from saves), we could build a "watch replay" feature. Distinct from save/load — don't conflate.
- **Multi-level saves** — As levels 2+ ship, saves grow but the delta model keeps them small. Only visited rooms and changed objects are stored.
- **Save compression** — If saves ever exceed 50 KB, apply LZ-string compression before localStorage write. Pure JS library, ~3 KB.

---

## 10. Decision

**Recommended: Hybrid Snapshot (§3.4) + Export Code (§3.5)**

The hybrid approach respects D-14 (code mutation IS state change) by recording WHAT mutated, not HOW it mutated. Functions reload from source. Data fields overlay onto fresh instances. It's small, fast, compatible with game updates, and works entirely client-side.

Export codes provide a no-infrastructure backup option that works on any browser, any device.

Cloud save is the natural upgrade path but requires backend work that's out of scope for V1.
