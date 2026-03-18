# Persistence, Serialization, and State Management for Self-Modifying Code Worlds

**Research Compiled By:** Frink, Researcher  
**Date:** 2026-03-20  
**Project:** MMO (Text Adventure Game Engine)  
**Status:** Comprehensive research report  
**Audience:** Architecture team, engineering leads  

---

## Executive Summary

In a text adventure MMO where **each universe is a living, mutable program that players reshape through gameplay**, persistence is not a traditional "database schema" problem. Instead, it's a **code versioning, serialization, and time-travel problem.**

### The Core Challenge

- **Every player action mutates the world's source code** (Lua, Fennel, or equivalent)
- **The code IS the world state** — no separate data layer
- **Universes fork and merge** — creating a directed acyclic graph (DAG) of code states
- **Scale:** Millions of possible universes, but only a subset are "active" at any moment
- **Durability:** Player progress must survive crashes, server restarts, and multi-session gameplay

### Key Recommendation

**Adopt a hybrid persistence strategy:**

1. **Event Sourcing as the Primary Model** — All player actions are immutable events that describe code mutations. Replay events to reconstruct any universe state.
2. **Snapshot-Based Copy-on-Write** — Periodically save full universe snapshots to avoid replaying from genesis; share common subtrees across related universes.
3. **Git-Inspired Branching** — Universe relationships modeled as branches in a content-addressable store. Merges use structural diff + strategic conflict resolution (CRDTs for gameplay state).
4. **Lazy Code Serialization** — Serialize universe code to readable Lua source (not bytecode) to enable diffs, version control, and human inspection. Use tables + AST reconstruction instead of `string.dump()`.
5. **Tiered Storage** — Active universes in memory (with frequent snapshots); inactive universes hibernated on disk; rarely-accessed universes reconstructed on-demand from events.

This approach scales from single-player persistence to billions of universe branches while keeping the mental model simple: **each universe is a versioned Lua program in a git-like store.**

---

## 1. Image-Based Persistence (Smalltalk Model)

### 1.1 How Smalltalk Images Work

Smalltalk and Pharo use **live object environments** where the entire running system—memory, open editors, execution state—is saved as a binary snapshot called an "image." Resuming an image restarts execution exactly where it left off.

**Example workflow:**
```smalltalk
"Day 1: Writing code"
MyObject >> greet [ ^'Hello' ]
"... hours of development, editing, testing ..."
"Save the image (snapshot the entire VM state)"
SystemImage save.

"Day 2: Restart from exactly where you left off"
"VM loads the image; all objects, state, uncommitted changes preserved"
vm load: 'my-image.image'
```

### 1.2 Why This Matters for Self-Modifying Worlds

In a Smalltalk image, **the live state and the serialized state are isomorphic.** There is no impedance mismatch between "what's running" and "what's saved."

For our MMO:
- Each universe could be a **Lua VM snapshot**
- Player action → mutate running code → save new snapshot
- Universe fork → copy the snapshot + start a new VM
- Universe merge → integrate code mutations back into a common ancestor

### 1.3 Technical Challenges: Building a Lua Image Store

**Problem:** Lua doesn't have native image serialization like Smalltalk.

**Possible Solutions:**

#### Option A: Full Memory Dump (libmemcached approach)
```lua
-- Save the entire Lua state to a binary blob
function saveUniverse(universe_id)
  local L = getVMforUniverse(universe_id)
  local dump = lua_dump(L)  -- hypothetical C API call
  store:put("universe:" .. universe_id, dump)
end

function loadUniverse(universe_id)
  local dump = store:get("universe:" .. universe_id)
  local L = lua_create()
  lua_restore(L, dump)  -- restore VM state from dump
  return L
end
```

**Pros:** Complete fidelity; includes closures, metatables, running state.  
**Cons:** Binary format (hard to diff, inspect, or version-control); platform-dependent; closure serialization is complex.

#### Option B: Serialize to Lua Table Representation
```lua
-- Better: Serialize the game world as Lua tables, then dump to source
function serializeUniverse(universe_id)
  local world = getWorldTable(universe_id)
  -- Recursively convert world to a Lua string representation
  local source = tableToLuaSource(world)
  return source
end

function tableToLuaSource(tbl, indent)
  -- Reconstruct readable Lua source from nested tables
  if type(tbl) == 'table' then
    local lines = {'{\n'}
    for k, v in pairs(tbl) do
      table.insert(lines, indent .. '[' .. quote(k) .. '] = ')
      table.insert(lines, tableToLuaSource(v, indent .. '  '))
      table.insert(lines, ',\n')
    end
    table.insert(lines, indent .. '}')
    return table.concat(lines)
  else
    -- Handle primitives, strings, etc.
    return repr(tbl)
  end
end
```

**Pros:** Readable source code; diff-friendly; version-control compatible.  
**Cons:** Loses some runtime state (active coroutines, C callbacks); closures with external state are lossy.

#### Option C: AST-Based Serialization (for homoiconic languages like Fennel)
```fennel
; Fennel (Lisp on Lua) makes this natural
(defn serialize-universe [universe-id]
  (let [world (get-world universe-id)]
    ; In Fennel, code and data are the same; just dump the tables as S-expressions
    (to-string world)))

; Reconstructing:
(defn load-universe [universe-id]
  (let [source (read-file (.. "universe-" universe-id ".fnl"))]
    (eval (read source))))
```

**Pros:** True homoiconicity; code and data serialize identically; very elegant for procedural content.  
**Cons:** Requires adopting Lisp/Fennel; different mental model than Lua.

### 1.4 Recommendation: Hybrid Approach

**Use Smalltalk-inspired snapshots for active universes, but serialize to readable Lua source for storage:**

```lua
-- Runtime: In-memory Lua VM for each universe (fast access, closure support)
-- Persistence: Serialize to source code for storage (readable, diff-able)

function snapshotUniverse(universe_id)
  local world = getWorldState(universe_id)
  local source = tableToReadableLua(world)
  storage.put("universe:snapshot:" .. universe_id, source, compression="zstd")
  storage.putMeta("universe:" .. universe_id, {
    snapshot_at = os.time(),
    size_bytes = #source
  })
end

function resumeUniverse(universe_id)
  local source = storage.get("universe:snapshot:" .. universe_id)
  local L = lua.createVM()
  lua.dostring(L, source)
  return L
end
```

**Trade-offs:**
- ✅ Fast resume (Lua execution is quick)
- ✅ Readable, diff-able code
- ✅ Version-control friendly
- ⚠️ Lost state for ephemeral runtime closures (events, callbacks not tied to objects)
- ⚠️ Serialization time proportional to universe size

---

## 2. Source-Code-as-Save-File

### 2.1 The Philosophy

Rather than thinking of "saving state" as a database operation, think of it as **writing a Lua program.** The program IS the state.

```lua
-- World definition for Player1's universe (saved as Player1.lua)

WORLD = {
  rooms = {
    dungeon_1 = {
      name = "Dark Dungeon",
      description = "A mysterious passage...",
      exits = { north = "surface_1" },
      items = { 
        { name = "gold_coin", id = "coin_1" }
      }
    },
    surface_1 = {
      name = "Grassy Field",
      description = "Open plains stretch before you.",
      exits = { south = "dungeon_1" }
    }
  },
  player = {
    location = "dungeon_1",
    inventory = { "coin_1" },
    hp = 95,
    max_hp = 100
  },
  events = {
    -- Previous mutations recorded as code
    { at_turn = 10, action = "picked_up_coin", item_id = "coin_1" },
    { at_turn = 15, action = "damaged", amount = 5 }
  }
}

-- Player action: "take coin"
-- This modifies the world...
table.insert(WORLD.player.inventory, "coin_1")
table.remove(WORLD.rooms.dungeon_1.items, 1)
table.insert(WORLD.events, { at_turn = 20, action = "took_coin" })

-- Then save the modified world back to disk as a Lua program
```

### 2.2 Serializing Lua Tables to Source Code

**Challenge:** Lua functions (closures, methods, event handlers) don't have a built-in string representation.

**`string.dump()` Approach (Bytecode):**
```lua
function serializeFunction(fn)
  local bytecode = string.dump(fn)
  return "loadstring(" .. quote(bytecode) .. ")"
end
```
**Pros:** Preserves compiled bytecode; relatively compact.  
**Cons:** Binary representation; not human-readable; endianness issues; can't inspect or modify the function logic.

**Source Reconstruction Approach:**
```lua
function functionToSource(fn, name)
  -- For named functions in the WORLD table:
  -- Option 1: Store the source code as a string, not compiled function
  
  -- Instead of:
  -- on_enter = function(player) player.seen_dungeon = true end
  
  -- Do:
  -- on_enter_src = [[
  --   function(player) 
  --     player.seen_dungeon = true 
  --   end
  -- ]]
  
  -- Then at load time:
  -- obj.on_enter = loadstring(obj.on_enter_src)()
end
```

**Pros:** Human-readable; modifiable; great for player scripting (players can edit behavior).  
**Cons:** Requires storing source, not compiled bytecode; loses performance (need to recompile); closures with captured state are problematic.

**Best Practice for Self-Modifying Worlds:**

```lua
-- When a player modifies code, record it as an AST or source patch, not a binary

WORLD.mutations = {
  {
    timestamp = 1000,
    type = "modify_room",
    room_id = "dungeon_1",
    change = [[
      description = "A new, friendlier room. Butterflies flutter here."
    ]]
  },
  {
    timestamp = 1050,
    type = "add_item",
    room_id = "dungeon_1",
    item = {
      name = "magic_wand",
      id = "wand_1"
    }
  }
}

-- Reconstruct by applying mutations in order (like event sourcing)
function applyMutations(world, mutations)
  for _, mut in ipairs(mutations) do
    if mut.type == "modify_room" then
      world.rooms[mut.room_id].description = mut.change
    elseif mut.type == "add_item" then
      table.insert(world.rooms[mut.room_id].items, mut.item)
    end
  end
  return world
end
```

### 2.3 Round-Tripping Lua Tables to Readable Source

**The Challenge:** Not all values in a Lua table are serializable to readable code.

```lua
function serializeTable(tbl, seen)
  seen = seen or {}
  if seen[tbl] then
    error("Circular reference detected")
  end
  seen[tbl] = true
  
  local parts = {}
  for k, v in pairs(tbl) do
    local key_str
    if type(k) == "string" then
      key_str = k  -- assume valid identifier
    else
      key_str = "[" .. tostring(k) .. "]"
    end
    
    local value_str
    if type(v) == "table" then
      value_str = serializeTable(v, seen)
    elseif type(v) == "string" then
      value_str = string.format("%q", v)  -- quote string
    elseif type(v) == "function" then
      -- For named functions: placeholder
      value_str = "-- [function at " .. tostring(v) .. "]"
    elseif type(v) == "boolean" or type(v) == "number" or v == nil then
      value_str = tostring(v)
    else
      error("Unsupported type: " .. type(v))
    end
    
    table.insert(parts, key_str .. " = " .. value_str)
  end
  
  return "{\n  " .. table.concat(parts, ",\n  ") .. "\n}"
end

-- Usage:
local world = {
  name = "My Universe",
  level = 42,
  visited_rooms = { "dungeon", "tower" },
  metadata = { created = "2026-03-20" }
}

print(serializeTable(world))
-- Output:
-- {
--   name = "My Universe",
--   level = 42,
--   visited_rooms = {
--     "dungeon",
--     "tower"
--   },
--   metadata = {
--     created = "2026-03-20"
--   }
-- }
```

### 2.4 Handling Closures with Captured State

**Problem:** A closure captures variables from its lexical scope, which can't be serialized as source.

```lua
-- This closure captures 'magic_number'
local magic_number = 42
local function spell()
  return magic_number * 2  -- refers to outer scope
end
```

**Solution Approaches:**

1. **Store closures as source + captured state separately:**
   ```lua
   -- Instead of storing the closure, store its definition and captured values
   SPELL = {
     source = [[local function spell(magic_number) return magic_number * 2 end]],
     captured = { magic_number = 42 }
   }
   
   -- To recreate:
   local captured = SPELL.captured
   local fn = loadstring(SPELL.source .. "; return spell")()
   -- Bind captured variables via upvalues or pass as arguments
   ```

2. **Redesign to avoid closures:** Store captured state in the object, not in a closure.
   ```lua
   CREATURE = {
     name = "Dragon",
     max_hp = 100,
     damage_multiplier = 1.5,
     
     takeDamage = function(self, amount)
       local modified = amount * self.damage_multiplier
       self.hp = self.hp - modified
     end
   }
   ```

3. **For homoiconic languages (Fennel/Lisp), this is natural:**
   ```fennel
   ; In Fennel, all data is code; closures serialize like any other data structure
   (local magic-number 42)
   (fn spell [] (* magic-number 2))
   
   ; Serialize the whole thing:
   (setlocal world-snapshot
     {:name "My Fennel World"
      :spell `(fn [] (* magic-number 2))  ; quoted code
      :magic-number magic-number})
   
   ; The quote means: don't evaluate yet; treat as data
   ```

### 2.5 Fennel/Lisp Advantage

Homoiconic languages (Fennel, a Lisp on Lua) make this trivial:

```fennel
; Code as data: everything is an S-expression

; Define a room:
(def kitchen
  {:name "Kitchen"
   :description "A cozy kitchen."
   :on_enter (fn [player] (say "You enter the kitchen"))})

; Serialize it (it's already data!):
(print (tostring kitchen))
; Output: {:name "Kitchen", ...}

; Modify it at runtime:
(set kitchen.description "A large, grand kitchen.")

; Save back to disk:
(with-open [f (io.open "kitchen.fnl" :w)]
  (f:write (tostring kitchen)))
```

**Advantage:** Code and data are the same; serialization is trivial. Perfect for self-modifying worlds.

---

## 3. Event Sourcing + Self-Modifying Code

### 3.1 Core Concept

Instead of saving the final state, save the **sequence of mutations.** Each player action is an immutable event describing how the code changed.

```
TIME 0: Base universe created
  Event 1: "dungeon_1 room spawned"
  Event 2: "gold_coin added to dungeon_1"

TIME 1: Player enters dungeon
  Event 3: "player entered dungeon_1"

TIME 2: Player takes coin
  Event 4: "player took gold_coin"
  Event 5: "dungeon_1 description updated" (by a trap trigger)

TIME 3: Player casts spell
  Event 6: "spell_mana consumed"
  Event 7: "dungeon_1 flooded" (spell effect)
```

**Reconstruction:** Replay events from the base state to reach any point in time.

### 3.2 Event Schema for Self-Modifying Code

```lua
-- Event: A mutation to the world state
Event = {
  timestamp = 1000,           -- when this happened
  actor = "player_1",         -- who caused it
  type = "code_mutation",    -- one of: code_mutation, object_state_change, etc.
  mutation = {
    target = "room:dungeon_1",  -- what changed
    operation = "set_property",  -- what operation
    property = "description",    -- which property
    old_value = "A dark room",
    new_value = "A dark, flooded room",
    change_source = "spell_cast:fireball"  -- why did this code change
  }
}

-- Another event: Adding a new object (code addition)
Event = {
  timestamp = 1050,
  actor = "game_system",
  type = "code_mutation",
  mutation = {
    target = "room:dungeon_1",
    operation = "add_item",
    item_def = {
      id = "magical_staff_1",
      name = "Magical Staff",
      properties = { damage = 50, requires_level = 20 }
    }
  }
}
```

### 3.3 Event Replay and Reconstruction

```lua
local BASE_UNIVERSE = loadUniverse("base")  -- start from known state

function replayEventsToTime(events, target_time)
  local universe = deepcopy(BASE_UNIVERSE)
  
  for _, event in ipairs(events) do
    if event.timestamp > target_time then
      break  -- stop before we reach target time
    end
    
    applyEvent(universe, event)
  end
  
  return universe
end

function applyEvent(universe, event)
  if event.type == "code_mutation" then
    local target = resolveTarget(universe, event.mutation.target)
    
    if event.mutation.operation == "set_property" then
      target[event.mutation.property] = event.mutation.new_value
    elseif event.mutation.operation == "add_item" then
      table.insert(target.items or {}, event.mutation.item_def)
    elseif event.mutation.operation == "remove_item" then
      -- Remove item by id
      local items = target.items or {}
      for i = #items, 1, -1 do
        if items[i].id == event.mutation.item_id then
          table.remove(items, i)
        end
      end
    end
  end
end

-- Usage: Get the state of the universe at turn 100
local past_state = replayEventsToTime(all_events, 100)
```

### 3.4 Snapshotting to Avoid Replaying from Genesis

Without snapshots, recovering the current state requires replaying from the very first event, which becomes prohibitively slow.

**Strategy: Periodic Full Snapshots**

```lua
-- Every 1000 events or every 1 hour, create a snapshot
function snapshotUniverse(universe_id, after_event_index)
  local universe = replayEventsToTime(getEvents(universe_id), math.huge)
  local snapshot = {
    universe_id = universe_id,
    snapshot_at_event = after_event_index,
    timestamp = os.time(),
    data = serializeToLua(universe),
    data_hash = sha256(data)
  }
  storage.put("snapshot:" .. universe_id .. ":" .. after_event_index, snapshot)
  
  -- Delete old events that are now superseded
  -- (keep the last N for debugging, or keep all for audit trail)
end

-- Recovery: Use the latest snapshot, then replay only subsequent events
function loadUniverseAtTime(universe_id, target_time)
  local latest_snapshot = getLatestSnapshot(universe_id)
  local universe = loadSnapshotData(latest_snapshot)
  
  -- Replay only events after the snapshot
  local subsequent_events = getEventsSince(universe_id, latest_snapshot.snapshot_at_event)
  for _, event in ipairs(subsequent_events) do
    if event.timestamp > target_time then break end
    applyEvent(universe, event)
  end
  
  return universe
end
```

### 3.5 Multiverse Implications: Shared Event Log + Private Suffixes

When universes fork or merge, event sourcing makes it elegant:

```
Base Universe (shared by all):
  Event 1, Event 2, Event 3, ... Event 100
  [These are common ancestors; shared across all universes]

Player 1's Universe:
  [Inherits Event 1-100]
  Event 101, Event 102, Event 103, ... Event 150
  [Private modifications]

Player 2's Universe:
  [Inherits Event 1-100]
  Event 101', Event 102', Event 103', ... Event 160'
  [Different sequence of actions from Player 1]

Merged Universe (if Player 1 and 2 negotiate a merge):
  [Inherits Event 1-100]
  [Conflict resolution for Event 101 vs Event 101']
  Event 101-merged, Event 102-merged, ...
```

**Conflict Resolution in Merges:**

```lua
-- When merging, if both universes modified the same object:
Event_1_mod = "Set dungeon_1.description = 'Bright'"
Event_2_mod = "Set dungeon_1.description = 'Dark'"

-- Resolution strategies:
-- 1. Last-write-wins: Take Event 2 (timestamp is later)
-- 2. Player 1 wins: Explicit priority rule
-- 3. Merge descriptions: description = "A bright and dark room"
-- 4. Conflict marker: description = "!CONFLICT! Bright vs Dark"

-- For complex merges, use CRDT (see Section 7)
```

### 3.6 Implementation Example: Simple Event Log

```lua
-- File: universe_event_log.lua

EventLog = {}

function EventLog.create(universe_id)
  return {
    id = universe_id,
    events = {},
    snapshots = {},
    current_index = 0
  }
end

function EventLog:record(event)
  table.insert(self.events, event)
  self.current_index = #self.events
end

function EventLog:getEventRange(start_idx, end_idx)
  return {table.unpack(self.events, start_idx, end_idx)}
end

function EventLog:snapshot()
  local snap = {
    at_index = self.current_index,
    data = serializeCurrentState(self),
    timestamp = os.time()
  }
  table.insert(self.snapshots, snap)
  return snap
end

-- Serialize to JSON for storage
function EventLog:toJSON()
  return json.encode(self)
end

function EventLog.fromJSON(json_str)
  return json.decode(json_str)
end
```

### 3.7 Pros and Cons

**Pros:**
- ✅ Perfect audit trail (every change is recorded)
- ✅ Time travel (replay to any point)
- ✅ Multiverse friendly (fork = create new event suffix)
- ✅ Efficient merging (replay conflicts, apply resolution)
- ✅ Debugging (understand exactly how state evolved)

**Cons:**
- ⚠️ Replay can be slow if events are numerous
- ⚠️ Need to snapshot periodically to stay performant
- ⚠️ Conflicts in merges need explicit resolution logic
- ⚠️ Long-term storage (events never deleted unless archived)

---

## 4. Git-as-State-Store

### 4.1 Core Idea: Universes as Branches

Treat each universe as a **git branch** where the branch contains the source code that defines that universe.

```
main (canonical universe)
├── player_1/alice (fork: Player 1's private universe)
│   └── player_1/alice/dungeon-extensions (fork within fork)
├── player_2/bob (fork: Player 2's private universe)
└── shared/realm-3 (shared universe, merges welcome)

Each branch tip = the current source code state for that universe
Each commit = a player action
```

### 4.2 Workflow: Player Action → Commit

```bash
# Player action: "take gold coin"
1. Read current universe state (git read-tree)
2. Apply mutation to source code
3. Commit the change
   git add .
   git commit -m "player took gold_coin (turn 100)"

# Player action: "cast fireball"
4. Read current state again
5. Apply mutation
6. Commit
   git commit -m "cast fireball; dungeon flooded (turn 101)"
```

### 4.3 Universe Fork: `git branch`

```bash
# Create Player 1's universe as a fork of main
git branch player_1/alice main

# Player 1 and Player 2 diverge independently
player_1/alice: [commit A, commit B, commit C]
player_2/bob:   [commit A, commit B', commit C']
```

### 4.4 Universe Merge: `git merge`

When two players negotiate a merge of their universes:

```bash
# Player 1 wants to merge their changes into player_2's universe
git checkout player_2/bob
git merge player_1/alice

# Git auto-resolves changes that don't conflict
# Manual conflict resolution for changes to the same object
```

### 4.5 Diffing: `git diff`

Compare two universes easily:

```bash
# What changed between Player 1 and Player 2?
git diff player_1/alice player_2/bob

# Shows:
# - player_1/alice added a "magic wand" to dungeon_1
# - player_2/bob modified dungeon_1's description
# - etc.
```

### 4.6 Time Travel: `git log` + `git checkout`

```bash
# See all player actions (commits) for this universe
git log player_1/alice

# Revert to an earlier state if something broke
git checkout player_1/alice~10  # 10 commits ago

# Or use git reflog for even more history
```

### 4.7 Implementation: libgit2 or isomorphic-git

**Option A: Direct git repository on disk**

```lua
local git = require("libgit2")  -- Lua bindings for libgit2

function playerAction(universe_id, action_desc)
  local repo = git.Repository.open("/data/universes/" .. universe_id)
  local index = repo:index()
  
  -- Modify world state (Lua source)
  modifyUniverse(universe_id, action_desc)
  
  -- Stage changes
  index:add_all()
  
  -- Commit
  local author = git.Signature.now("player", "player@localhost")
  local tree = index:write_tree()
  local parent = repo:head():target()
  repo:create_commit("HEAD", author, author, action_desc, tree, {parent})
  
  print("Committed: " .. action_desc)
end

function universeStatus(universe_id)
  local repo = git.Repository.open("/data/universes/" .. universe_id)
  local head = repo:head():shorthand()
  local log = repo:history()
  
  print("Branch: " .. head)
  print("Recent commits:")
  for i, commit in ipairs(log) do
    if i > 5 then break end
    print("  " .. commit:summary())
  end
end
```

**Option B: Isomorphic-git (JavaScript/Node.js)**

For web-based or distributed scenarios:

```javascript
// isomorphic-git works in-browser or Node, no git binary needed
const fs = require('fs');
const path = require('path');
const git = require('isomorphic-git');

async function playerAction(universeId, actionDesc) {
  const universeDir = `/data/universes/${universeId}`;
  
  // Modify universe state
  modifyUniverse(universeId, actionDesc);
  
  // Add and commit
  await git.add({ fs, dir: universeDir, filepath: '.' });
  await git.commit({
    fs,
    dir: universeDir,
    message: actionDesc,
    author: { name: 'player', email: 'player@localhost' }
  });
}

async function universeHistory(universeId) {
  const universeDir = `/data/universes/${universeId}`;
  const log = await git.log({
    fs,
    dir: universeDir,
    ref: 'HEAD',
    depth: 10
  });
  
  log.forEach(commit => console.log(commit.commit.message));
}
```

**Option C: Custom Content-Addressable Store (Inspired by Git)**

If you want git-like semantics without the git overhead:

```lua
-- Simplified git-inspired store
ContentAddressableStore = {}

function ContentAddressableStore:hash(content)
  return sha256(content)
end

function ContentAddressableStore:store(content)
  local hash = self:hash(content)
  local path = "store/" .. hash:sub(1, 2) .. "/" .. hash:sub(3)
  fs.write(path, content)
  return hash
end

function ContentAddressableStore:retrieve(hash)
  local path = "store/" .. hash:sub(1, 2) .. "/" .. hash:sub(3)
  return fs.read(path)
end

-- A "ref" (branch pointer) just points to a commit hash
Refs = {}

function Refs:create_branch(name, commit_hash)
  self[name] = commit_hash
end

function Refs:update_branch(name, commit_hash)
  self[name] = commit_hash
end

-- Usage:
local store = ContentAddressableStore.new()
local universe_code = readFile("universe_1.lua")
local code_hash = store:store(universe_code)
Refs:create_branch("player_1/alice", code_hash)
```

### 4.8 Git Performance at Scale

**Challenge:** Can git handle millions of branches?

**Pessimistic view:**
- ❌ Git stores branch references in a flat directory; millions of refs could be slow
- ❌ Packing refs helps, but not ideal for highly dynamic scenarios
- ❌ Each universe = separate working tree? Disk space overhead

**Optimistic view (with proper setup):**
- ✅ Packed refs can efficiently store millions of branches
- ✅ libgit2 + mmap is optimized for large repos
- ✅ Distributed git (e.g., GitHub) handles millions of repos; why not branches?
- ✅ Use a custom ref store backed by a database (SQLite) instead of filesystem

**Hybrid Approach: Git + Database**

```lua
-- Store refs (branch pointers) in SQLite instead of .git/refs/
-- Commit objects and content still in git's object store

GitRefStore = {}

function GitRefStore:init()
  self.db = sqlite.open(":memory:")
  self.db:exec([[
    CREATE TABLE refs (
      name TEXT PRIMARY KEY,
      commit_hash TEXT NOT NULL,
      updated_at INTEGER
    )
  ]])
end

function GitRefStore:set_ref(name, hash)
  self.db:execute(
    "INSERT OR REPLACE INTO refs (name, commit_hash, updated_at) VALUES (?, ?, ?)",
    {name, hash, os.time()}
  )
end

function GitRefStore:get_ref(name)
  local row = self.db:query("SELECT commit_hash FROM refs WHERE name = ?", {name})
  return row and row[1].commit_hash or nil
end

function GitRefStore:all_branches()
  return self.db:query("SELECT name FROM refs ORDER BY updated_at DESC")
end
```

### 4.9 Pros and Cons

**Pros:**
- ✅ Battle-tested technology (git is proven at massive scale)
- ✅ Natural branching/merging semantics
- ✅ Built-in diffing and history
- ✅ Human-friendly (can inspect with `git log`, `git diff`, etc.)
- ✅ Integrates with existing developer tools
- ✅ Copy-on-write semantics (branches are cheap)

**Cons:**
- ⚠️ Disk space (each universe has a full copy of the source code)
- ⚠️ Merge conflicts need explicit resolution
- ⚠️ Performance: micro-commits per player action could create huge object stores
- ⚠️ Not ideal for "shared mutable state" (git is designed for disconnected collaboration)

---

## 5. Copy-on-Write State

### 5.1 Core Idea: Structural Sharing

Instead of each universe having a full copy of the world state, use **structural sharing:** all universes start by referencing the same base state, and only diverging changes are stored separately.

```
Base Universe State:
  {
    rooms: { dungeon, tower, plaza, ... },
    player: { ... },
    time: 1000
  }

Player 1's Universe:
  [Reference Base]
  Overrides: {
    rooms.dungeon.description = "A bright dungeon",
    rooms.dungeon.items = [...new items...]
  }

Player 2's Universe:
  [Reference Base]
  Overrides: {
    rooms.tower.description = "A crumbling tower",
    player.hp = 50
  }

Shared Merged Universe:
  [Reference Base]
  Overrides: {
    rooms.dungeon.description = "A bright dungeon",
    rooms.tower.description = "A crumbling tower",
    player.hp = 50
  }
```

### 5.2 Implementation: Lua Proxy Tables

```lua
-- Copy-on-Write table wrapper

CoWTable = {}
CoWTable.__index = CoWTable

function CoWTable.new(base_tbl)
  local self = setmetatable({}, CoWTable)
  self.base = base_tbl
  self.overrides = {}
  self.children = {}  -- Track derived tables
  return self
end

function CoWTable:__index(key)
  -- Check overrides first
  if self.overrides[key] ~= nil then
    return self.overrides[key]
  end
  -- Fall back to base
  return self.base[key]
end

function CoWTable:__newindex(key, value)
  -- Mutation triggers CoW
  self.overrides[key] = value
  
  -- Invalidate children that inherit from this
  for _, child in ipairs(self.children) do
    child:invalidate_cache()
  end
end

function CoWTable:fork()
  -- Create a new CoWTable that shares the base but has its own overrides
  local forked = CoWTable.new(self)  -- self becomes the new base
  table.insert(self.children, forked)
  return forked
end

function CoWTable:serialize()
  -- Collect all data (base + overrides)
  local result = {}
  for k, v in pairs(self.base) do
    result[k] = v
  end
  for k, v in pairs(self.overrides) do
    result[k] = v
  end
  return result
end

-- Usage:
local base_world = {
  name = "Dungeon",
  level = 1,
  items = { "sword", "shield" }
}

local player1_world = CoWTable.new(base_world)
local player2_world = CoWTable.new(base_world)

-- Player 1 modifies:
player1_world:__newindex("level", 5)
player1_world:__newindex("name", "Bright Dungeon")

-- Player 2 modifies:
player2_world:__newindex("items", { "potion", "staff" })

-- Check values:
print(player1_world.name)    -- "Bright Dungeon" (overridden)
print(player1_world.items)   -- { "sword", "shield" } (from base)

print(player2_world.name)    -- "Dungeon" (from base)
print(player2_world.items)   -- { "potion", "staff" } (overridden)
```

### 5.3 Nested Copy-on-Write

For hierarchical structures (rooms containing items):

```lua
-- Extend CoWTable to handle nested structures

function CoWTable:deep_fork()
  local forked = CoWTable.new(self)
  
  -- Recursively wrap nested tables
  for k, v in pairs(self.base) do
    if type(v) == "table" and not getmetatable(v) then
      local nested_cow = CoWTable.new(v)
      forked.overrides[k] = nested_cow
    end
  end
  
  return forked
end

-- Usage:
local base_world = {
  rooms = {
    dungeon = {
      name = "Dungeon",
      items = { "coin", "key" }
    }
  }
}

local player1_world = CoWTable.new(base_world):deep_fork()
player1_world.rooms.dungeon.items = { "coin", "key", "amulet" }

-- Only the items list is copied; rooms.dungeon is shared
```

### 5.4 Serialization with Copy-on-Write

When saving a CoW universe, you can save just the overrides (delta) or the full materialized state:

```lua
function CoWTable:save_delta()
  -- Save only the differences from base
  return {
    base_id = self.base_id,  -- reference to base state
    overrides = self.overrides
  }
end

function CoWTable:save_full()
  -- Save fully materialized state
  return self:serialize()
end

-- Recovery from delta:
function CoWTable.from_delta(delta, base_store)
  local base = base_store:get(delta.base_id)
  local cow = CoWTable.new(base)
  cow.overrides = delta.overrides
  return cow
end
```

**Disk savings example:**
- Base state: 10 MB
- Player 1 delta: 100 KB (modified 10 rooms)
- Player 2 delta: 80 KB (modified 8 rooms)
- Total: 10.18 MB instead of 20 MB (full copies)

### 5.5 Pros and Cons

**Pros:**
- ✅ Memory efficient (shared base state)
- ✅ Disk efficient (only deltas stored)
- ✅ Fast forking (no need to copy everything)
- ✅ Elegant for universes with common ancestry

**Cons:**
- ⚠️ Lookup performance: checking overrides + base on every access
- ⚠️ Garbage collection: when is the base no longer needed?
- ⚠️ Merge complexity: combining overrides from multiple branches
- ⚠️ Mutable base problem: if base is mutated, all CoW tables see the change

---

## 6. Snapshot Strategies

### 6.1 Snapshot Frequency and Triggers

**Options:**

| Strategy | When | Pros | Cons |
|----------|------|------|------|
| **Every N actions** | After player takes 100 actions | Predictable replay cost | Arbitrary; might miss critical moments |
| **Every N seconds** | Every 60 seconds of real time | Prevents large time gaps | May snapshot idle universes |
| **On player disconnect** | When player logs out | Captures final safe state | Long sessions without snapshots |
| **On critical event** | After boss defeated, quest completed | Important moments preserved | Requires game logic to recognize events |
| **Every N mutations to code** | After 50 code mutations detected | Focused on significant changes | Ignores player action velocity |
| **Adaptive (dynamic)** | Snapshot when action rate > threshold | Responsive to activity | Complex logic; hard to predict cost |

**Recommendation:** Hybrid approach
- Snapshot every 100 actions (ensure bounded replay cost)
- Also snapshot on player disconnect (safety)
- Also snapshot on critical events (user experience; minimize loss on crash)

```lua
function snapshotTrigger(universe_id, event_type)
  local stats = getUniverseStats(universe_id)
  
  if event_type == "action_count" and stats.actions_since_snapshot >= 100 then
    return true
  elseif event_type == "disconnect" then
    return true
  elseif event_type == "critical" then
    return true
  end
  
  return false
end
```

### 6.2 Full vs Incremental Snapshots

**Full Snapshot:**
```lua
function fullSnapshot(universe_id)
  local state = getUniverseState(universe_id)
  local blob = serializeToLua(state)
  storage.put("snapshot:full:" .. universe_id, blob)
end
```
- Pros: Complete, no dependencies
- Cons: Large size, redundant data

**Incremental Snapshot:**
```lua
function incrementalSnapshot(universe_id)
  local state = getUniverseState(universe_id)
  local prev_snapshot = getLatestSnapshot(universe_id)
  local prev_state = deserializeFromLua(prev_snapshot)
  
  local delta = computeDelta(prev_state, state)
  storage.put("snapshot:delta:" .. universe_id, delta)
end

function reconstructFromIncremental(universe_id)
  local full = getFullSnapshot(universe_id)
  local state = deserializeFromLua(full)
  
  local deltas = getIncrementalSnapshots(universe_id)
  for _, delta in ipairs(deltas) do
    applyDelta(state, delta)
  end
  
  return state
end
```
- Pros: Smaller storage, efficient for slow-changing universes
- Cons: Requires replay of all deltas; fragile if a delta is corrupted

**Recommendation:** Full snapshots every 100 actions, but use **compression** (zstd, gzip) to keep size manageable.

### 6.3 Compression: Redundancy Between Universes

Snapshots for related universes (forks) have massive redundancy. Exploit it:

```
Base Universe Snapshot: 10 MB (uncompressed)
Player 1 Fork Snapshot: 10.1 MB (mostly same, + 1 room changed)
Player 2 Fork Snapshot: 10.05 MB (mostly same, + 5 items changed)

With zstd compression:
  Base: 1.2 MB
  Player 1: 1.3 MB (zstd finds similarity to base!)
  Player 2: 1.4 MB
  Total: 3.9 MB instead of 30.15 MB!
```

**Why:** Compression algorithms (zstd, LZMA) excel at finding patterns across related data.

**Implementation:**
```lua
function compressSnapshot(universe_id, data)
  local compressed = zstd.compress(data, 10)  -- level 10 = high compression
  return compressed
end

function storeSnapshot(universe_id, data)
  local compressed = compressSnapshot(universe_id, data)
  storage.put("snapshot:" .. universe_id, compressed)
end
```

### 6.4 Hot vs Cold Snapshots

**Hot Snapshot (while universe is running):**
```lua
function hotSnapshot(universe_id)
  local state = getUniverseState(universe_id)  -- read while running
  -- Risk: state might change during serialization
  
  -- Mitigation: use read-only copies or versioned access
  local snapshot_time = os.time()
  local frozen_state = freezeState(state)  -- atomic snapshot
  
  return frozen_state
end
```

**Cold Snapshot (pause universe):**
```lua
function coldSnapshot(universe_id)
  pauseUniverse(universe_id)  -- stop accepting new actions
  local state = getUniverseState(universe_id)
  local blob = serialize(state)
  resumeUniverse(universe_id)
  return blob
end
```

**Trade-offs:**
- Hot: Faster, but requires careful synchronization
- Cold: Safer, but causes player-visible pause

**Recommendation:** Use hot snapshots with atomic state access (versioned snapshots or copy-on-write locks).

### 6.5 Snapshot Storage Tiers

**Tier 1 (Hot): Last 5 snapshots**
- Storage: SSD or memory
- Latency: <100ms
- Used for: Quick recovery, undo operations

**Tier 2 (Warm): Last 50 snapshots**
- Storage: SSD
- Latency: <1s
- Used for: Recent history, debugging

**Tier 3 (Cold): All snapshots**
- Storage: S3, Glacier, or archive disk
- Latency: 1s-1min
- Used for: Long-term backup, compliance

```lua
function storeSnapshot(universe_id, data)
  local tier1_count = countSnapshots("tier1:" .. universe_id)
  
  -- Store to Tier 1
  storage.put_fast("snapshot:" .. universe_id, data)
  
  -- If Tier 1 is full, move oldest to Tier 2
  if tier1_count > 5 then
    local oldest = getOldestSnapshot("tier1:" .. universe_id)
    storage.move("tier1:" .. oldest, "tier2:" .. oldest)
  end
  
  -- Archive to cold storage every day
  if shouldArchive(universe_id) then
    archiveToS3(universe_id)
  end
end
```

---

## 7. Diffing and Merging World States

### 7.1 Structural Diff (AST-Level)

Instead of textual diffs, compare the semantic structure of the world.

```lua
function structuralDiff(state_a, state_b, path)
  path = path or {}
  local diffs = {}
  
  local all_keys = {}
  for k in pairs(state_a) do all_keys[k] = true end
  for k in pairs(state_b) do all_keys[k] = true end
  
  for key in pairs(all_keys) do
    local val_a = state_a[key]
    local val_b = state_b[key]
    
    if val_a == nil then
      table.insert(diffs, {
        type = "added",
        path = table.concat(path, ".") .. "." .. key,
        value = val_b
      })
    elseif val_b == nil then
      table.insert(diffs, {
        type = "removed",
        path = table.concat(path, ".") .. "." .. key,
        value = val_a
      })
    elseif type(val_a) == "table" and type(val_b) == "table" then
      local nested_diffs = structuralDiff(val_a, val_b, 
                                          table.insert(path, key) and path or path)
      for _, d in ipairs(nested_diffs) do
        table.insert(diffs, d)
      end
    elseif val_a ~= val_b then
      table.insert(diffs, {
        type = "changed",
        path = table.concat(path, ".") .. "." .. key,
        from = val_a,
        to = val_b
      })
    end
  end
  
  return diffs
end

-- Usage:
local base = { rooms = { dungeon = { level = 1 } } }
local player1 = { rooms = { dungeon = { level = 5 } } }

local diffs = structuralDiff(base, player1)
-- Output:
-- { type = "changed", path = "rooms.dungeon.level", from = 1, to = 5 }
```

### 7.2 Semantic Merge

When two universes diverge and need to merge, use semantic rules specific to your game.

```lua
function semanticMerge(base, branch1, branch2)
  local result = deepcopy(base)
  
  local diffs1 = structuralDiff(base, branch1)
  local diffs2 = structuralDiff(base, branch2)
  
  -- Apply non-conflicting changes from both branches
  for _, diff in ipairs(diffs1) do
    if not conflictsWithAny(diff, diffs2) then
      applyDiff(result, diff)
    end
  end
  
  for _, diff in ipairs(diffs2) do
    if not conflictsWithAny(diff, diffs1) then
      applyDiff(result, diff)
    end
  end
  
  -- For conflicting changes, apply game-specific resolution
  for _, diff1 in ipairs(diffs1) do
    for _, diff2 in ipairs(diffs2) do
      if diff1.path == diff2.path then
        local resolved = resolveConflict(diff1, diff2)
        applyDiff(result, resolved)
      end
    end
  end
  
  return result
end

function resolveConflict(diff1, diff2)
  -- Example: Stat merges (take the max)
  if diff1.path:match("\.level$") then
    return {
      type = "changed",
      path = diff1.path,
      from = diff1.from,
      to = math.max(diff1.to, diff2.to)
    }
  end
  
  -- Example: Inventory merges (combine items)
  if diff1.path:match("\.inventory$") then
    local merged = {}
    for _, item in ipairs(diff1.to) do
      table.insert(merged, item)
    end
    for _, item in ipairs(diff2.to) do
      if not listContains(merged, item) then
        table.insert(merged, item)
      end
    end
    return {
      type = "changed",
      path = diff1.path,
      to = merged
    }
  end
  
  -- Default: Last-write-wins (prefer diff2 as it's more recent)
  return diff2
end
```

### 7.3 CRDTs for Conflict-Free Replicated Data Types

For distributed worlds with concurrent edits, use **CRDTs** — data structures that automatically resolve conflicts without coordination.

**Example: LWW (Last-Write-Wins) Register**

```lua
-- A CRDT value that always resolves conflicts by keeping the latest timestamp
LWWRegister = {}
LWWRegister.__index = LWWRegister

function LWWRegister.new(value, timestamp)
  return setmetatable({
    value = value,
    timestamp = timestamp or os.time()
  }, LWWRegister)
end

function LWWRegister:update(new_value)
  self.value = new_value
  self.timestamp = os.time()
end

function LWWRegister:merge(other)
  -- Conflict resolution: keep the value with the later timestamp
  if other.timestamp > self.timestamp then
    self.value = other.value
    self.timestamp = other.timestamp
  end
  -- If self.timestamp >= other.timestamp, keep self unchanged
end

-- Usage:
local player1_hp = LWWRegister.new(100, 1000)
local player2_hp = LWWRegister.new(95, 1010)

player1_hp:merge(player2_hp)  -- player1_hp now has value 95 (later timestamp)
```

**Example: G-Counter (Grow-Only Counter)**

```lua
GCounter = {}
GCounter.__index = GCounter

function GCounter.new()
  return setmetatable({
    counts = {}  -- replica_id -> count
  }, GCounter)
end

function GCounter:increment(replica_id, amount)
  self.counts[replica_id] = (self.counts[replica_id] or 0) + amount
end

function GCounter:value()
  local sum = 0
  for _, count in pairs(self.counts) do
    sum = sum + count
  end
  return sum
end

function GCounter:merge(other)
  for replica_id, count in pairs(other.counts) do
    self.counts[replica_id] = math.max(
      self.counts[replica_id] or 0,
      count
    )
  end
end

-- Usage: Track total gold across all players
local gold = GCounter.new()
gold:increment("player_1", 10)
gold:increment("player_2", 5)
print(gold:value())  -- 15

-- In another universe:
local other_gold = GCounter.new()
other_gold:increment("player_1", 8)
other_gold:increment("player_3", 3)

-- Merge:
gold:merge(other_gold)
print(gold:value())  -- 10 + 8 + 5 + 3 = 26 (conflict-free!)
```

**Pros:**
- ✅ No coordination needed
- ✅ Automatic conflict resolution
- ✅ Commutative (order of merges doesn't matter)

**Cons:**
- ⚠️ Limited expressiveness (CRDTs are tailored to specific data types)
- ⚠️ Some operations (like deletion from sets) are tricky
- ⚠️ Overkill for most game scenarios

### 7.4 Operational Transforms (OT)

Like Google Docs for game state: track transformations and replay them.

```lua
-- Simplified OT model
Op = {}
Op.__index = Op

function Op.new(op_type, path, value)
  return setmetatable({
    type = op_type,  -- "set", "insert", "delete"
    path = path,
    value = value,
    timestamp = os.time()
  }, Op)
end

-- Transform two concurrent operations to preserve intent
function transform(op_a, op_b)
  if op_a.path == op_b.path then
    -- Same path: operations conflict
    if op_a.timestamp < op_b.timestamp then
      -- op_b wins (later timestamp)
      return nil, op_b  -- op_a is invalidated, op_b stands
    else
      return op_a, nil  -- op_a wins, op_b is invalidated
    end
  else
    -- Different paths: no conflict
    return op_a, op_b
  end
end

-- Replay operations in causal order
function applyOps(state, ops)
  table.sort(ops, function(a, b) return a.timestamp < b.timestamp end)
  
  for _, op in ipairs(ops) do
    if op.type == "set" then
      setValueAt(state, op.path, op.value)
    elseif op.type == "insert" then
      insertAt(state, op.path, op.value)
    end
  end
  
  return state
end
```

---

## 8. Hibernation and Lazy Loading

### 8.1 The Problem: Memory Budget

If a server has 1 million active universes, each 1 MB in size, that's 1 TB of RAM. Not realistic.

**Solution:** Only keep "hot" universes in memory; hibernate the rest.

### 8.2 Hibernation Strategy

```lua
-- Track universe activity
UniverseManager = {}

function UniverseManager:init()
  self.active = {}       -- currently loaded universes
  self.hibernating = {}  -- universes on disk
  self.max_active = 1000 -- configurable threshold
end

function UniverseManager:access(universe_id)
  if self.active[universe_id] then
    -- Already loaded
    self.active[universe_id].last_access = os.time()
    return self.active[universe_id]
  else
    -- Load from disk
    self:wake(universe_id)
    return self.active[universe_id]
  end
end

function UniverseManager:wake(universe_id)
  -- Load universe from hibernation
  local data = storage.get("hibernated:" .. universe_id)
  local universe = deserialize(data)
  self.active[universe_id] = {
    state = universe,
    last_access = os.time()
  }
  
  -- If we exceed capacity, hibernate the LRU universe
  if utils.table_size(self.active) > self.max_active then
    local victim = self:findLRUUniverse()
    self:hibernate(victim)
  end
end

function UniverseManager:hibernate(universe_id)
  local universe = self.active[universe_id]
  local data = serialize(universe.state)
  storage.put("hibernated:" .. universe_id, data)
  self.active[universe_id] = nil
end

function UniverseManager:findLRUUniverse()
  local oldest_time = math.huge
  local oldest_id = nil
  
  for id, info in pairs(self.active) do
    if info.last_access < oldest_time then
      oldest_time = info.last_access
      oldest_id = id
    end
  end
  
  return oldest_id
end
```

### 8.3 Lazy Loading Within a Universe

Even within a single universe, not all rooms/objects need to be materialized immediately.

```lua
Room = {}
Room.__index = Room

function Room.new(id)
  return setmetatable({
    id = id,
    _loaded = false,
    name = nil,
    description = nil,
    items = {}
  }, Room)
end

function Room:load()
  if self._loaded then return end
  
  local data = storage.get("room:" .. self.id)
  local room_def = deserialize(data)
  
  self.name = room_def.name
  self.description = room_def.description
  self.items = room_def.items
  
  self._loaded = true
end

function Room:getName()
  self:load()  -- Lazy load on first access
  return self.name
end

function Room:__tostring()
  self:load()
  return "Room: " .. self.name
end

-- Usage:
local dungeon = Room.new("dungeon_1")
-- dungeon is not loaded yet (no I/O)

print(dungeon:getName())
-- Now dungeon_1 is loaded from disk on demand
```

### 8.4 Partial Materialization

Only materialize the parts of the universe the player can interact with:

```lua
function getPlayerViewport(universe_id, player_location)
  -- Load current room + adjacent rooms
  local rooms_to_load = {
    player_location,
    getAdjacentRooms(universe_id, player_location)
  }
  
  local viewport = {}
  for _, room_id in ipairs(rooms_to_load) do
    local room = lazy_load_room(room_id)
    viewport[room_id] = room
  end
  
  return viewport
end

function processPlayerAction(universe_id, action)
  local player_room = getPlayerCurrentRoom(universe_id)
  local viewport = getPlayerViewport(universe_id, player_room)
  
  -- Process action only with loaded rooms
  local result = applyAction(action, viewport)
  
  -- Update persisted state
  saveViewport(universe_id, viewport)
end
```

### 8.5 Reconstruction on Demand

Instead of hibernating to disk, can we just **delete the universe and re-derive it from events**?

```lua
-- Option 1: Store full snapshot (takes space, but fast recovery)
function hibernateSnapshot(universe_id)
  local state = getUniverseState(universe_id)
  storage.put("universe:snapshot:" .. universe_id, serialize(state))
end

function resumeSnapshot(universe_id)
  return deserialize(storage.get("universe:snapshot:" .. universe_id))
end

-- Option 2: Store only events (takes less space, slow recovery)
function hibernateEvents(universe_id)
  local events = getEventLog(universe_id)
  storage.put("universe:events:" .. universe_id, serialize(events))
end

function resumeFromEvents(universe_id)
  local events = deserialize(storage.get("universe:events:" .. universe_id))
  return replayEventsToFinal(events)
end

-- Hybrid: Snapshots for fast recovery, events for space efficiency
function hibernateHybrid(universe_id)
  local last_snapshot_idx = getLatestSnapshotIndex(universe_id)
  local subsequent_events = getEventsSince(universe_id, last_snapshot_idx)
  
  -- Store only the events after the snapshot (delta)
  storage.put("universe:delta:" .. universe_id, serialize(subsequent_events))
end

function resumeHybrid(universe_id)
  local snapshot = storage.get("universe:snapshot:" .. universe_id)
  local state = deserialize(snapshot)
  
  local delta = storage.get("universe:delta:" .. universe_id)
  if delta then
    local events = deserialize(delta)
    state = replayEvents(state, events)
  end
  
  return state
end
```

### 8.6 Garbage Collection

When can a hibernated universe be deleted?

```lua
function maybeGarbageCollect(universe_id)
  local meta = storage.getMeta("universe:" .. universe_id)
  
  local last_accessed = meta.last_accessed
  local now = os.time()
  local stale_after_days = 30
  
  if (now - last_accessed) > (stale_after_days * 86400) then
    -- Optionally: archive to cold storage before deleting
    archiveToGlacier("universe:" .. universe_id)
    storage.delete("universe:" .. universe_id)
  end
end
```

---

## 9. Academic and Industry Precedent

### 9.1 Persistent Programming Languages

**Orthogonal Persistence (1976)**
- Object-oriented databases store objects on disk without a separate schema
- A pointer to an object works whether the object is in RAM or disk (transparent)
- Examples: ObjectStore, Gemstone, Versant

**Relevance:** Our multiverse could use orthogonal persistence — treat universes as first-class persistent objects.

### 9.2 Prevayler (Java)

**Model:** Keep ALL state in memory; durability via transaction log.

```
1. Player action arrives
2. Create Transaction object describing the action
3. Write Transaction to a Write-Ahead Log (WAL) on disk
4. Apply Transaction to in-memory state
5. Acknowledge to player
6. (periodically: save full snapshot to disk)
```

**Advantages:** Simple, fast (no parsing), all operations are in-memory
**Disadvantages:** Limited to state that fits in RAM; startup requires replaying all transactions

**Relevance:** Event Sourcing (Section 3) is inspired by this pattern.

### 9.3 Mnesia (Erlang)

**Model:** Distributed, fault-tolerant database with replicated tables.

```
Local replica of table A (in RAM)
Local replica of table B (on disk)
Replication to other nodes
Two-phase commit for distributed transactions
```

**Advantages:** Automatic replication, fault tolerance, hot standby
**Disadvantages:** Complex distributed logic; not designed for millions of distinct entities

**Relevance:** Could use Mnesia for a central multiverse registry, but probably overkill for per-universe state.

### 9.4 Datomic (Clojure)

**Model:** Immutable database with time-travel querying.

```
Add fact: [:player/1 :inventory :sword] at T1
Add fact: [:player/1 :inventory :shield] at T2
Update fact: [:player/1 :hp 50] at T3

Query at T2: What was the player's inventory?
Answer: [:sword]

Query at T3: What is the player's HP now?
Answer: 50
```

**Advantages:**
- Rich time-travel capabilities
- Functional updates (no mutations, only adds)
- Great for replaying history

**Disadvantages:** Not open-source (proprietary); overkill for text adventure

**Relevance:** Conceptually similar to Event Sourcing + snapshots. Could use similar ideas with Lua.

### 9.5 Redis Persistence

**RDB (Redis Database):** Periodic snapshots of entire dataset
```
Every 1 hour or N writes: save entire dataset to disk
Fast: copying is fast (often using fork)
Compact: binary format
Risky: recent updates between snapshots can be lost
```

**AOF (Append-Only File):** Log every write command
```
Every write: append command to a log file
Durable: every update is on disk
Slow: I/O for every operation
Large: log file can grow unbounded
Hybrid: AOF + RDB combine benefits
```

**Relevance:** Our multiverse persistence could use RDB-style snapshots + AOF-style event logs.

### 9.6 Git (Distributed Version Control)

**Model:** Content-addressable storage + immutable commits + branching

Already covered in Section 4 in detail, but key academic influences:
- **Merkle trees:** Content-based addressing ensures integrity
- **DAG (Directed Acyclic Graph):** Branch relationships form a DAG
- **Causal ordering:** Commits reference their parents

**Relevance:** Git is a proven model for what we're building. Adopting it (Section 4) is a strong recommendation.

### 9.7 CockroachDB and Distributed Transactions

**Relevance:** If multiplayer actions happen across multiple universes, how do you ensure consistency?

- Multi-version concurrency control (MVCC)
- Serializable isolation level (stronger than typical databases)
- Distributed consensus (Raft)

For our use case: **Not necessary if universes are isolated.** ACID becomes important only when players interact across boundaries.

### 9.8 How Existing MMOs Handle Per-Player State at Scale

**World of Warcraft:**
- Separate character databases per realm
- Each character is a row in a table
- State: location, inventory, quest progress, achievements
- Serialization: Binary database format (MySQL)
- Scaling: Horizontal sharding by realm

**Approach NOT suitable for us:** Assumes shared world with centralized state.

**EVE Online:**
- Single shared universe (intentional design choice, unlike Multiverse)
- Massive database cluster (Cassandra-like)
- State: ship positions, structures, contracts
- Persistence: Eventually-consistent replicated database
- Scaling: Accepts temporary inconsistency for availability

**Approach NOT suitable for us:** Needs strong consistency for per-player universes.

**Runescape (Old School):**
- Per-player activity logging
- Event-sourced gameplay (every action is an event)
- Serialization: Custom binary format
- Scaling: Horizontal by world servers

**Approach SUITABLE for us:** Event sourcing is proven in production MMO.

---

## 10. Recommendation: Hybrid Multiverse Persistence Architecture

### 10.1 Overall Strategy

Combine the best practices from all approaches:

```
┌─────────────────────────────────────────────────────────────┐
│ Player Action (e.g., "take coin")                           │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Apply to In-Memory Universe (Lua VM)                        │
│ + Record as Event in append-only event log                  │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Every 100 actions:                                          │
│ - Serialize universe to Lua source code                     │
│ - Compress with zstd                                        │
│ - Store as snapshot                                         │
│ - Clear event log (or archive it)                           │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ When Active Universes > Capacity:                           │
│ - Hibernate LRU universe (copy snapshot to hibernation)    │
│ - Keep in-memory cache of recently-accessed universes      │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Universe Forking (Player creates alt):                      │
│ - Branch the event log + latest snapshot                    │
│ - Copy-on-Write: share base snapshot, deltas only           │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Universe Merging (Negotiate shared world):                  │
│ - Structural diff between forks                             │
│ - Apply non-conflicting changes                             │
│ - CRDT or LWW for conflicts                                 │
│ - Create new merged universe branch                         │
└─────────────────────────────────────────────────────────────┘
```

### 10.2 Storage Tiers

**Tier 1 (Hot Memory):**
- Currently active universes (player online)
- ~1000 universes max
- Latency: <10ms
- Medium: RAM (or Redis)

**Tier 2 (Warm Disk):**
- Recently used universes (last accessed < 1 day)
- ~10,000 universes
- Latency: <1s
- Medium: SSD

**Tier 3 (Cold Archive):**
- All historical universes (last accessed > 7 days)
- Unlimited
- Latency: 1s-1min (S3, Glacier)
- Medium: Cloud object storage

**Tier 4 (Reconstruction):**
- Ancient universes (last accessed > 30 days)
- Reconstruct on-demand from event log
- Latency: 10s-100s (replay time depends on action count)
- Medium: Append-only event log in cold storage

### 10.3 Persistence Model

```lua
-- Core abstraction

Universe = {}

function Universe.new(universe_id)
  return {
    id = universe_id,
    state = {},          -- the Lua world table
    events = {},         -- event log since last snapshot
    last_snapshot_time = os.time(),
    last_snapshot_hash = nil
  }
end

function Universe:recordAction(action)
  local event = {
    timestamp = os.time(),
    action = action,
    sequence_number = #self.events + 1
  }
  
  -- Apply to state
  applyActionToState(self.state, action)
  
  -- Record in event log
  table.insert(self.events, event)
  
  -- Trigger snapshot if needed
  if #self.events >= 100 then
    self:snapshot()
  end
end

function Universe:snapshot()
  -- Serialize current state to Lua source
  local source = serializeStateToLua(self.state)
  local compressed = zstd.compress(source, 10)
  
  -- Store
  local snapshot_meta = {
    universe_id = self.id,
    timestamp = os.time(),
    action_count = #self.events,
    hash = sha256(compressed),
    size_bytes = #compressed
  }
  
  storage.put("universe:snapshot:" .. self.id, compressed, snapshot_meta)
  
  -- Clear event log (keep a small buffer for debugging)
  self.events = {}
  self.last_snapshot_time = os.time()
end

function Universe:serialize()
  return {
    state = serializeStateToLua(self.state),
    events = self.events,
    meta = {
      snapshot_time = self.last_snapshot_time
    }
  }
end

function Universe:fork(new_id)
  -- Create a child universe
  local forked = Universe.new(new_id)
  forked.state = deepcopy(self.state)
  forked.events = {}  -- Fresh event log for the fork
  return forked
end

function Universe:mergeWith(other)
  -- Merge another universe's changes
  local base = self.state
  local branch1 = self.state
  local branch2 = other.state
  
  local merged_state = semanticMerge(base, branch1, branch2)
  self.state = merged_state
  
  -- Record merge as a special event
  table.insert(self.events, {
    timestamp = os.time(),
    action = "merged_with_universe_" .. other.id,
    sequence_number = #self.events + 1
  })
end
```

### 10.4 Operational Policies

**Policy: Snapshot Frequency**
- Snapshot every 100 player actions
- Also snapshot on disconnect
- Also snapshot on critical events (boss defeated, quest completed)

**Policy: Event Retention**
- Keep events in memory until snapshot (then clear)
- Archive old events to cold storage for audit trail
- Retention: 1 year minimum, configurable

**Policy: Hibernation Triggers**
- Hibernate universe when no player online for 10 minutes
- LRU (least-recently-used) eviction when active count > 1000
- Restore on player reconnect (wakens from hibernation)

**Policy: Conflict Resolution**
- Player 1 forks a universe → gets a fresh private copy
- Player 1 can merge back into shared universe by:
  - Initiating a negotiation with players in shared universe
  - Diffs are computed + presented to all players
  - Non-conflicting changes auto-merge
  - Conflicting changes require vote or admin override

**Policy: Storage Budgets**
- Tier 1: 1 GB (active universes in memory)
- Tier 2: 100 GB (recent universes on SSD)
- Tier 3: Unlimited (cold storage)
- Cleanup: Move Tier 2 → Tier 3 after 7 days of inactivity

### 10.5 Implementation Roadmap

**Phase 1: Event Sourcing Foundation (Week 1-2)**
- [ ] Design event schema for mutations
- [ ] Implement event recording + replay
- [ ] Test: record 100 actions, replay to verify state matches

**Phase 2: Snapshot + Serialization (Week 2-3)**
- [ ] Implement Lua state → source code serialization
- [ ] Add compression + decompression
- [ ] Test: snapshot → hibernation → resume

**Phase 3: Multiverse Forking (Week 3-4)**
- [ ] Implement universe fork (CoW)
- [ ] Test: fork universe, diverge, verify independence

**Phase 4: Merging + Conflict Resolution (Week 4-5)**
- [ ] Implement structural diff
- [ ] Implement semantic merge (non-conflicting changes)
- [ ] Add CRDT for complex state (optional)
- [ ] Test: merge two diverged universes

**Phase 5: Hibernation + Lazy Loading (Week 5-6)**
- [ ] Implement universe hibernation (LRU eviction)
- [ ] Implement lazy loading (on-demand materialization)
- [ ] Test: handle >1000 universes with limited RAM

**Phase 6: Storage Tiers + Archival (Week 6-7)**
- [ ] Implement tiered storage (hot/warm/cold)
- [ ] Implement archive to S3/Glacier
- [ ] Test: lifecycle of data through tiers

**Phase 7: Testing + Optimization (Week 7-8)**
- [ ] Performance testing under load
- [ ] Corruption recovery tests
- [ ] Multiverse stress test

---

## 11. Code Example: Complete Persistence System

Here's a self-contained Lua example tying everything together:

```lua
-- File: universe_persistence.lua
-- Complete persistence system for self-modifying code multiverse

require "json"
require "zstd"
require "lfs"

-- ============================================================================
-- CORE DATA STRUCTURES
-- ============================================================================

Universe = {}
Universe.__index = Universe

function Universe.new(id, initial_state)
  return setmetatable({
    id = id,
    state = initial_state or {},
    events = {},
    event_index = 0,
    last_snapshot_time = os.time(),
    snapshot_count = 0
  }, Universe)
end

-- ============================================================================
-- ACTION RECORDING
-- ============================================================================

function Universe:recordAction(actor, action_type, action_data)
  local event = {
    timestamp = os.time(),
    sequence = self.event_index + 1,
    actor = actor,
    type = action_type,
    data = action_data
  }
  
  table.insert(self.events, event)
  self.event_index = self.event_index + 1
  
  -- Apply mutation to state
  self:applyEvent(event)
  
  -- Snapshot if needed
  if self.event_index % 100 == 0 then
    self:snapshot()
  end
  
  return event
end

function Universe:applyEvent(event)
  -- Generic event application logic
  if event.type == "object_mutation" then
    local target = self.state
    for _, key in ipairs(event.data.path) do
      target = target[key]
    end
    target[event.data.property] = event.data.value
  end
end

-- ============================================================================
-- SERIALIZATION
-- ============================================================================

function Universe:serializeState()
  -- Convert Lua table to readable source code
  return tableToLua(self.state, 0)
end

function tableToLua(tbl, indent)
  if type(tbl) ~= "table" then
    if type(tbl) == "string" then
      return string.format("%q", tbl)
    elseif type(tbl) == "nil" then
      return "nil"
    else
      return tostring(tbl)
    end
  end
  
  local parts = {}
  local indent_str = string.rep("  ", indent)
  local next_indent_str = string.rep("  ", indent + 1)
  
  for k, v in pairs(tbl) do
    local key = type(k) == "string" and k or "[" .. tostring(k) .. "]"
    local value = tableToLua(v, indent + 1)
    
    if type(v) == "table" then
      table.insert(parts, next_indent_str .. key .. " = " .. value)
    else
      table.insert(parts, next_indent_str .. key .. " = " .. value)
    end
  end
  
  return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent_str .. "}"
end

function Universe:snapshot()
  local serialized = self:serializeState()
  local compressed = zstd.compress(serialized, 10)
  
  local snapshot_file = "snapshots/universe_" .. self.id .. "_" .. self.snapshot_count .. ".lua.zst"
  
  lfs.mkdir("snapshots")
  local f = io.open(snapshot_file, "wb")
  f:write(compressed)
  f:close()
  
  self.snapshot_count = self.snapshot_count + 1
  self.last_snapshot_time = os.time()
  self.events = {}  -- Clear event log after snapshot
  
  print(string.format("[SNAPSHOT] %s: size=%d bytes (compressed)", self.id, #compressed))
end

-- ============================================================================
-- DESERIALIZATION & RESUME
-- ============================================================================

function Universe.resume(id, snapshot_id)
  -- Load a snapshot and resume
  local snapshot_file = "snapshots/universe_" .. id .. "_" .. snapshot_id .. ".lua.zst"
  
  local f = io.open(snapshot_file, "rb")
  if not f then
    print("[ERROR] Snapshot not found: " .. snapshot_file)
    return nil
  end
  
  local compressed = f:read("*a")
  f:close()
  
  local serialized = zstd.decompress(compressed)
  
  -- Parse Lua source and execute to reconstruct state
  local chunk = load("return " .. serialized)
  local state = chunk()
  
  return Universe.new(id, state)
end

-- ============================================================================
-- FORKING (Copy-on-Write)
-- ============================================================================

function Universe:fork(new_id)
  -- Create a new universe as a fork (CoW)
  local forked = Universe.new(new_id, deepcopy(self.state))
  print(string.format("[FORK] %s -> %s", self.id, new_id))
  return forked
end

function deepcopy(tbl)
  if type(tbl) ~= "table" then return tbl end
  local copy = {}
  for k, v in pairs(tbl) do
    copy[k] = deepcopy(v)
  end
  return copy
end

-- ============================================================================
-- DIFFING & MERGING
-- ============================================================================

function Universe:diff(other)
  -- Compute structural diff
  return structuralDiff(self.state, other.state, {})
end

function structuralDiff(a, b, path)
  local diffs = {}
  
  if type(a) ~= "table" or type(b) ~= "table" then
    if a ~= b then
      table.insert(diffs, {
        path = table.concat(path, "."),
        from = a,
        to = b
      })
    end
    return diffs
  end
  
  local all_keys = {}
  for k in pairs(a) do all_keys[k] = true end
  for k in pairs(b) do all_keys[k] = true end
  
  for k in pairs(all_keys) do
    local new_path = {}
    for _, p in ipairs(path) do table.insert(new_path, p) end
    table.insert(new_path, k)
    
    local diffs_nested = structuralDiff(a[k], b[k], new_path)
    for _, d in ipairs(diffs_nested) do
      table.insert(diffs, d)
    end
  end
  
  return diffs
end

function Universe:mergeWith(other, base)
  -- Merge another universe's changes
  base = base or {}
  local diffs_self = structuralDiff(base, self.state, {})
  local diffs_other = structuralDiff(base, other.state, {})
  
  -- Apply non-conflicting changes
  for _, diff in ipairs(diffs_self) do
    setValueByPath(self.state, diff.path, diff.to)
  end
  
  for _, diff in ipairs(diffs_other) do
    if not hasConflictingDiff(diffs_self, diff) then
      setValueByPath(self.state, diff.path, diff.to)
    end
  end
  
  print(string.format("[MERGE] %s merged with %s", self.id, other.id))
  self:recordAction("system", "merge", { merged_from = other.id })
end

function setValueByPath(tbl, path, value)
  local keys = {}
  for k in string.gmatch(path, "[^.]+") do
    table.insert(keys, k)
  end
  
  local current = tbl
  for i = 1, #keys - 1 do
    current = current[keys[i]]
  end
  
  current[keys[#keys]] = value
end

function hasConflictingDiff(diffs, diff)
  for _, d in ipairs(diffs) do
    if d.path == diff.path then
      return true
    end
  end
  return false
end

-- ============================================================================
-- HIBERNATION
-- ============================================================================

function Universe:hibernateToFile(filename)
  -- Save to disk for later resume
  local data = {
    id = self.id,
    state = self.state,
    events = self.events,
    event_index = self.event_index,
    last_snapshot_time = self.last_snapshot_time
  }
  
  local json_data = json.encode(data)
  local compressed = zstd.compress(json_data, 10)
  
  local f = io.open(filename or ("hibernated/" .. self.id .. ".bin"), "wb")
  f:write(compressed)
  f:close()
end

function Universe.wakeFromFile(filename)
  local f = io.open(filename, "rb")
  local compressed = f:read("*a")
  f:close()
  
  local json_data = zstd.decompress(compressed)
  local data = json.decode(json_data)
  
  local u = Universe.new(data.id, data.state)
  u.events = data.events
  u.event_index = data.event_index
  u.last_snapshot_time = data.last_snapshot_time
  
  return u
end

-- ============================================================================
-- EXAMPLE USAGE
-- ============================================================================

if __main__ == "universe_persistence.lua" then
  print("=== Multiverse Persistence Example ===\n")
  
  -- Create base universe
  local base = Universe.new("base", {
    name = "Mystical Realm",
    level = 1,
    rooms = {
      dungeon = { name = "Dark Dungeon", items = { "coin", "key" } },
      tower = { name = "Tower", items = { "staff" } }
    }
  })
  
  -- Player 1 takes coin
  base:recordAction("player_1", "object_mutation", {
    path = { "rooms", "dungeon", "items" },
    property = "items",
    value = { "key" }
  })
  print("Player 1 took a coin")
  
  -- Fork for Player 2
  local player2 = base:fork("player_2")
  player2:recordAction("player_2", "object_mutation", {
    path = { "level" },
    property = "level",
    value = 2
  })
  print("Player 2 leveled up")
  
  -- Show diffs
  print("\n=== Diff: base vs player_2 ===")
  local diffs = base:diff(player2)
  for _, diff in ipairs(diffs) do
    print(string.format("  %s: %s -> %s", diff.path, diff.from, diff.to))
  end
  
  -- Snapshot
  print("\n=== Snapshotting ===")
  for i = 1, 100 do
    base:recordAction("system", "tick", { tick = i })
  end
  
  print("\n=== Done ===")
end
```

---

## 12. Final Recommendation & Conclusion

### 12.1 Choose This Stack

For the MMO's persistence and serialization needs:

1. **Primary:** Event Sourcing + Snapshots
   - Record every player action as an immutable event
   - Periodic full-state snapshots (every 100 actions)
   - Enables time-travel and audit trails

2. **Secondary:** Readable Lua Source Serialization
   - Serialize snapshots to readable Lua source (not bytecode)
   - Enables diffs, version control, human inspection
   - Use compression (zstd) for storage efficiency

3. **Tertiary:** Git-Inspired Branching
   - Use git or a git-like content-addressable store
   - Universe forks = branches; merges = git merges
   - Build on proven technology with good tooling

4. **Optimization:** Copy-on-Write for Related Universes
   - Forks share common base state + deltas only
   - Reduces memory and disk overhead

5. **Scale:** Tiered Storage + Hibernation
   - Hot (memory): active universes
   - Warm (SSD): recent universes
   - Cold (S3): archived universes
   - Reconstruct on-demand from event log if needed

### 12.2 Why This Works

- ✅ **Conceptually simple:** Universes are versioned programs; players are programmers
- ✅ **Scales to millions of universes:** Hibernation + lazy loading manage memory
- ✅ **Self-modifying code support:** Every mutation is recorded; can inspect + replay
- ✅ **Multiverse support:** Forking/merging as natural operations (like git)
- ✅ **Debugging:** Full audit trail; time-travel to any moment
- ✅ **Extensible:** Easy to add CRDTs, conflict resolution, etc. later

### 12.3 Pitfalls to Avoid

- ❌ Don't use binary snapshots (string.dump). Use readable Lua source.
- ❌ Don't skip snapshotting. Event replay will become too slow.
- ❌ Don't ignore conflicts in merges. Define clear resolution rules.
- ❌ Don't keep all universes in RAM. Use hibernation + tiered storage.
- ❌ Don't forget compression. Snapshots compress extremely well.

---

## References & Further Reading

1. **Smalltalk/Pharo Images:** *Pharo by Example* — https://pharobyexample.org/
2. **Event Sourcing:** *Event Sourcing* (Martin Fowler) — https://martinfowler.com/eaaDev/EventSourcing.html
3. **CRDTs:** *A comprehensive study of CRDT* — https://arxiv.org/abs/1805.06358
4. **Operational Transforms:** *OT Editing* — https://en.wikipedia.org/wiki/Operational_transformation
5. **Git Internals:** *Pro Git* — https://git-scm.com/book/en/v2/Git-Internals
6. **Redis Persistence:** Redis Documentation — https://redis.io/topics/persistence
7. **Datomic:** Database as a Value — https://www.datomic.com/
8. **Orthogonal Persistence:** *The Case for Orthogonal Persistence* — Atkinson et al.
9. **Distributed Transactions:** *Google Spanner* — https://research.google/pubs/pub39966/

---

**Report Status:** Complete  
**Next Steps:** Review with architecture team; begin Phase 1 implementation (event sourcing foundation)
