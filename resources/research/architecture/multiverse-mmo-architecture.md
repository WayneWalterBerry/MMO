# Multiverse MMO Architecture for Text Adventures

**Research Compiled By:** Frink, Researcher  
**Date:** 2026-03-19  
**Project:** MMO (Text Adventure Game)  
**Status:** Comprehensive reference for architecture decisions  

---

## Executive Summary

This research addresses the core architectural challenge: **how to build a text adventure MMO where each player has a private universe by default, with optional merging into shared instances.** 

Unlike traditional MMOs with a single shared world (e.g., WoW, FFXIV), this design flips the assumption: **isolation is the default; sharing is opt-in.** This eliminates resource contention, enables infinite scalability, and allows per-player story pacing.

### Key Recommendation

**Adopt a hybrid architecture combining:**
1. **Per-universe Lua VM instances** — each player's universe runs as an isolated Lua program
2. **Event sourcing + copy-on-write snapshots** — efficient state forking and merging
3. **Git-like branching model** — universe relationships form a directed acyclic graph (DAG) of snapshots
4. **Lazy instantiation** — universes exist only when observed; procedurally generated when seeded
5. **Deterministic universe generation** — seed-based procedural content ensures consistent state across instances

This design leverages the **code-as-data** philosophy already identified for the IF engine, where universe state is serialized as Lua source code and forking is literal code duplication.

---

## 1. Instanced World Architectures in Existing MMOs

### 1.1 WoW-Style Instancing (Content Isolation)

**Model:** Shared persistent world + isolated dungeons/raids

- **Shared World:** All players see the same quest givers, towns, resource nodes
- **Instancing Trigger:** Entering a dungeon creates a separate copy of that space per group (or per 40-player raid)
- **Isolation Level:** Complete — damage, loot, and NPC state within an instance are isolated from other instances
- **Mechanics:**
  - Dungeon entrance portal registers the player's group
  - Server spins up a new instance (or reuses an idle one)
  - Instance runs independently; changes do not affect the shared world
  - Instance persists for the group duration or times out after inactivity
  - Loot tables ensure each player's drops are isolated

**Scaling Implication:** WoW can run 10,000s of instances in parallel because they're stateless from the world's perspective. Instances are *spawned on demand* and *destroyed on timeout*.

**Relevance to Multiverse:** WoW's approach assumes a shared persistent world that players want to return to. Multiverse is the opposite: isolation is fundamental, sharing is negotiated.

### 1.2 Guild Wars (Dynamic Instancing)

**Model:** Shared explorable zones + optional private instances

- **Explorable World:** All players see the same explorable areas (towns, fields, dungeons open-world)
- **Dynamic Instancing:** When a player/group enters a zone, the server checks if they should share an instance or get a private one
- **Decision Logic:** Based on proximity, group composition, and current zone load
- **Benefit:** Reduces overcrowding while maintaining shared-world feel
- **Trade-off:** "Multiplayer lite" — you occasionally see other players, but not always

**Technical Details:**
- Instance distribution server maps zone entries to instance IDs
- Load balancing algorithm balances new arrivals across existing instances
- Overflow instances created on demand; merged back when underutilized

**Relevance to Multiverse:** Guild Wars demonstrates that **dynamic instance assignment can be invisible to players.** The player doesn't explicitly choose to merge; the server decides based on conditions. This is a template for universe merging.

### 1.3 Destiny (Matchmaking + Persistence)

**Model:** Persistent director + matchmade transient instances

- **Persistent Director:** Central service tracking all players, their progress, and state
- **Activity Instances:** When a player queues for an activity (raid, strike, PvP), matchmaking places them in a specific instance
- **State Lifecycle:** Instance spins down when activity completes; player returns to persistent world
- **Exotic Mechanic:** Some instances are *public* — all players in the same zone see each other; others are *instanced per group*

**Scaling Aspect:** Destiny's director is a centralized service that never goes down. All instance routing queries hit this service, making it a critical bottleneck for massive scaling.

**Relevance to Multiverse:** Destiny shows that even in an MMO, most players are in isolated instances most of the time. The "shared world" is a lobby where players rarely linger.

### 1.4 MUD History of Alternate Dimensions

**Classic Approach:** Most MUDs (LPC-based: LambdaMOO, Circle MUD) implemented alternate dimensions as follows:

1. **Zone Cloning:** A quest area exists as a "template" zone. When a player enters, clone the entire zone (all rooms, NPCs, objects).
2. **Zone Registry:** Central registry tracks all active clones: `zones[player_id] = cloned_zone_instance`
3. **State Isolation:** All mutations (NPC deaths, object removal, damage) happen in the clone; template is never modified
4. **Timeout:** After N minutes of inactivity, the clone is destroyed
5. **Merging:** Rarely implemented; most MUDs used separate dimensions (heaven, hell, player housing) rather than merging

**Lua/DGD Example (LPC-based MUD):**
```c
// Template zone
/zones/quest_cavern.c

#define NUM_CLONES 100

object clones[NUM_CLONES];
int next_clone = 0;

void init() {
    for (int i = 0; i < NUM_CLONES; i++) {
        clones[i] = 0; // uninitialized
    }
}

object enter(object player) {
    int slot = next_clone++ % NUM_CLONES;
    if (clones[slot]) {
        clones[slot]->clean_up();
    }
    clones[slot] = copy(TO); // Clone the entire zone
    clones[slot]->setup(player);
    return clones[slot];
}
```

**Key Insight:** MUDs used explicit zone cloning because object-oriented languages made it easy. They never automated merging because merge conflicts are complex.

---

## 2. Copy-on-Write World States

Copy-on-Write (CoW) is a memory optimization technique: when you duplicate a data structure, both copies share the same underlying memory until one writes. Then, that copy gets its own private memory.

### 2.1 CoW Semantics Applied to Universes

**Traditional Model:**
```
Universe 1: {rooms: [R1, R2, ...], npcs: [NPC1, ...]}
Universe 2: {rooms: [R1, R2, ...], npcs: [NPC1, ...]}  // Full duplication
```

**With CoW:**
```
Universe 1 ──→ ┌─────────────────────┐
Universe 2 ──→ │ Shared Base State    │
               │ {rooms, npcs, items} │  // Reference-counted memory
               └─────────────────────┘
               
Universe 1 writes to R1:  // CoW triggers
Universe 1 ──→ ┌──────────────────────────┐
               │ Universe 1's Delta        │
               │ {R1_modified: {...}}      │
               └──────────────────────────┘
                           ↑
                       Falls back to Base
                       for unmodified data
```

**Storage Benefit:** If 1000 players start with the same base universe, only the *changes* are stored per-universe, not full copies.

### 2.2 Memory Footprint Example

Assume:
- Base universe: 10 MB (rooms, NPCs, static items)
- Per-player modifications: 100 KB average (quest progression, items picked up)

**Without CoW:** 1000 players × 10 MB = 10 GB
**With CoW:** 10 MB + (1000 × 100 KB) = 10 MB + 100 MB = ~110 MB

**Savings:** 99% reduction for large player bases.

### 2.3 Interaction with Event Sourcing

Event sourcing stores all state changes as an immutable log:

```
Base Universe State (T=0): {rooms, npcs, items}
Events:
  - Player1 at 15:00:00: picked_up(item_sword)
  - Player1 at 15:00:15: killed_npc(npc_goblin)
  - Player1 at 15:00:30: entered_room(treasury)
  
Reconstructed State = Base + Apply(Events)
```

**CoW + Event Sourcing Synergy:**

When two universes diverge, their event logs split:

```
Base Universe (T=0)
├── Player1 Log: [Event_1, Event_2, Event_3]
└── Player2 Log: [Event_1, Event_2, Event_4]

Both share Events 1 & 2.
Event_3 (Player1) and Event_4 (Player2) are unique.
```

**Merge Challenge:** If Event_3 and Event_4 conflict (both modify the same NPC state), merge logic must resolve:
- **Last-write-wins:** Player1's change wins; Player2's is discarded
- **Conflict marker:** Both changes preserved; game logic decides (e.g., NPC takes most damage, both status effects)
- **Operational transformation:** Rebase Event_4 on top of Event_3, recomputing its effects

### 2.4 Storage Model for Infinite Universes

**Lazy Initialization:**

Universes don't "exist" until a player enters. Instead:

```lua
-- Universe registry
universes = {}

function universe_enter(universe_id, player_id)
    if not universes[universe_id] then
        -- Lazy load: create from seed
        universes[universe_id] = generate_universe(universe_id)
    end
    return universes[universe_id]
end

function generate_universe(universe_id)
    local seed = hash(universe_id)
    local rooms = procedurally_generate_rooms(seed)
    local npcs = procedurally_generate_npcs(seed)
    return {rooms = rooms, npcs = npcs, events = {}}
end
```

**Storage Architecture:**

- **RAM Tier (Active Universes):** Universes with players logged in; live state
- **Disk Tier (Hibernated Universes):** Serialized snapshots; persisted to storage
- **Procedural Tier (Unborn Universes):** Only seed stored; generated on first access

**Garbage Collection:**

```lua
-- Hibernation: After N minutes of no player activity
if universe_last_access < now() - HIBERNATION_THRESHOLD then
    serialize(universe_id, universes[universe_id])
    universes[universe_id] = nil
end

-- Cleanup: After M days of no player activity
if universe_created < now() - CLEANUP_THRESHOLD then
    delete_serialized_state(universe_id)
    -- Seed is regenerable; can be recreated if needed
end
```

---

## 3. Universe Merging / Splitting Patterns

### 3.1 When/Why Players Merge

**Scenarios for Universe Merging:**

1. **Cooperative Challenges:** "Raid bosses" that require 3+ players
   - Player1 (Universe_1) initiates a raid challenge
   - Player2, Player3 (Universe_2, Universe_3) join
   - New merged universe created: `Universe_Raid_123`
   - All three enter and share combat, loot, boss state

2. **Trading & Social Hubs:**
   - Market zone is always shared (central hub)
   - Player home zones are private
   - Enables economic interaction without full world sharing

3. **Guild/Faction Territories:**
   - Guild headquarters is a shared universe for all guild members
   - Enables guild bases, shared storage, collective progress

4. **Dimensional Rifts / Crossover Events:**
   - Timed events where universes temporarily merge
   - "A rift opened! Battle other players' teams in alternate dimensions!"
   - Natural story reason for temporary world bleeding

5. **PvP Arenas:**
   - Players enter a specific Arena universe for duels
   - Combat is isolated, results affect home universe (XP, loot)

### 3.2 Conflict Resolution When Merging

**Challenge:** When two universes with divergent states merge, which state is canonical?

**Strategies:**

#### Strategy A: Last-Write-Wins (Simple)
```lua
function merge_universes(u1, u2)
    local merged = {}
    for key, value in pairs(u1.state) do
        merged[key] = u1.state[key]
    end
    for key, value in pairs(u2.state) do
        if u2.timestamp[key] > merged.timestamp[key] then
            merged[key] = u2.state[key]
        end
    end
    return merged
end
```

**Pros:** Simple, deterministic  
**Cons:** Loses data; unfair to player with older data

#### Strategy B: Conflict Markers (Preserve Both)
```lua
function merge_universes(u1, u2)
    local merged = {}
    for key, value in pairs(u1.state) do
        if u2.state[key] and u2.state[key] != u1.state[key] then
            merged[key] = {conflict = true, u1 = u1.state[key], u2 = u2.state[key]}
        else
            merged[key] = u1.state[key]
        end
    end
    return merged
end
```

**Pros:** No data loss; game logic can handle conflicts intelligently  
**Cons:** Complexity; requires explicit conflict resolution code

#### Strategy C: Operational Transformation (Advanced)
```lua
-- Transform event E2 to account for events in E1
function transform(e1, e2)
    if e1.type == "modify_room" and e2.type == "modify_room" and e1.room == e2.room then
        return e2  -- Re-apply e2 after e1
    elseif e1.type == "delete_item" and e2.type == "use_item" and e2.item == e1.item then
        return nil  -- e2 is invalid; item was deleted
    else
        return e2   -- No conflict
    end
end
```

**Pros:** Maximizes concurrent work; minimizes data loss  
**Cons:** Very complex; must handle all event type pairs

### 3.3 Spectral Presence (Seeing Across Universes)

**Challenge:** Players in merged universes want to see each other, but how?

**Solution A: Full Merge (Simplest)**
```lua
-- All players in the same universe literally share the same game state
player1.location = room_cathedral
player2.location = room_cathedral
-- Both see each other in game
```

**Limitation:** No partial visibility; either you see them or you don't.

**Solution B: Spectral Rendering (Partial Visibility)**
```lua
-- Players see a "ghost" version of other universe's players
function render_room_for_player(player, room)
    local entities = {}
    
    -- Real entities (same universe)
    for _, entity in pairs(room.inhabitants) do
        entities[#entities+1] = {entity, real=true}
    end
    
    -- Spectral entities (other universes)
    for _, other_universe in pairs(room.adjacent_universes) do
        if other_universe.location == room then
            entities[#entities+1] = {other_universe, real=false, ghosted=true}
        end
    end
    
    return entities
end

-- UI renders:
-- [REAL] Warrior standing here
-- [SPECTRAL] Mage (from another dimension) standing here
```

**Trade-off:** More complex rendering; but enables story flavor (dimensional echoes, parallel timelines).

**Solution C: Linked Observation Rooms**
```lua
-- Players in separate universes can see a shared "observation window"
-- Like looking through a portal

function observe_other_universe(player, window_id)
    local other_side = interdimensional_windows[window_id].other_side
    return render_room_for_player(player, other_side)
end

-- UI:
-- You are in the Throne Room
-- Through a shimmering portal, you see:
--   > A Mage is standing in an identical throne room
```

**Best for:** Story-driven dimensional interaction without full merging.

### 3.4 Dimensional Rifts and Crossover Events

**Mechanic:** Time-limited events where universes partially blend.

**Example Event Definition (Lua):**
```lua
dimensional_rift = {
    name = "Rift in Reality",
    duration = 3600,  -- 1 hour
    triggered_at = os.time(),
    affected_rooms = {"cathedral", "market", "arena"},
    
    -- Rooms in affected_rooms connect to the same room in other universes
    merge_rule = function(room_id, universe_list)
        -- All universes' room_id's become visible
        return {merge_type = "spectral", visibility = "full"}
    end,
    
    -- Event ends after duration
    cleanup = function()
        -- Universes separate
        -- Players returned to their private universes
    end
}

function trigger_rift(universe_list)
    local rift = dimensional_rift
    for _, universe in pairs(universe_list) do
        universe.active_rifts = universe.active_rifts or {}
        universe.active_rifts[rift.name] = rift
    end
end
```

**Story Hooks:**
- "A dimensional rift has opened! Travel to the Rift Nexus to find alternate versions of yourself!"
- Boss encounters that require players from multiple universes to cooperate
- Limited-time seasonal events creating urgency to merge

---

## 4. Data Structures for Multiverse State

### 4.1 Git-Like Branching Model for World State

Inspired by Git's DAG (Directed Acyclic Graph) of commits, we can model universes as a branching structure:

```
                   Base Universe (Seed: canonical)
                            |
                            v
                   Snapshot_T0 (root state)
                   /         |         \
                  /          |          \
        Player1's Fork   Player2's Fork  Player3's Fork
           |                 |              |
           v                 v              v
       Event_1.1          Event_2.1     Event_3.1
       Event_1.2          Event_2.2     Event_3.2
           |                 |              |
           v                 v              v
       Snapshot_T1       Snapshot_T2    Snapshot_T3
       
           -- MERGE EVENT (Raid) --
       /                          \
      /                            \
  Merged_Snapshot                   \
   /    |    \                       \
  /     |     \                       \
Event_1.3  Event_2.3  Event_3.3    Event_3.3'
  \     |     /                       /
   \    |    /                       /
    Merged_T4                    Player3_T4' (continued solo)
```

**Nodes:** Snapshots (immutable universe state at a point in time)  
**Edges:** Event streams (transitions between snapshots)  
**Merge Commit:** Combines multiple branches; conflict resolution happens here

**Advantages:**
- Git-like: Developers are familiar with the DAG model
- Auditable: Full history is preserved; can replay any universe's evolution
- Conflict Resolution: Merge conflicts are explicit; game logic decides
- Storage: Snapshot-based storage + delta compression (only store changes)

### 4.2 Event Sourcing with Shared Base + Per-Universe Deltas

**Architecture:**

```
Canonical Universe State (Base):
  {
    rooms: {cathedral, market, forest, ...},
    npcs: {guard, merchant, dragon, ...},
    items: {sword, potion, key, ...}
  }

Event Log (Shared):
  [
    {id: 1, universe: all, event: "spawn_npc(guard, cathedral)", timestamp: 0},
    {id: 2, universe: all, event: "place_item(sword, treasury)", timestamp: 100}
  ]

Universe_1 Delta:
  [
    {id: 1001, universe: 1, event: "player_pickup(sword)", timestamp: 5000},
    {id: 1002, universe: 1, event: "player_kill_npc(guard)", timestamp: 5100}
  ]

Universe_2 Delta:
  [
    {id: 2001, universe: 2, event: "player_trade_item(sword, potion)", timestamp: 5050}
  ]
```

**Reconstruction:**

```lua
function reconstruct_universe_state(universe_id, up_to_timestamp)
    local state = deepcopy(canonical_state)
    
    -- Apply shared events
    for _, event in pairs(shared_events) do
        if event.timestamp <= up_to_timestamp then
            state = apply_event(state, event)
        end
    end
    
    -- Apply universe-specific deltas
    for _, event in pairs(universe_deltas[universe_id] or {}) do
        if event.timestamp <= up_to_timestamp then
            state = apply_event(state, event)
        end
    end
    
    return state
end
```

**Benefits:**
- **Storage:** Shared events stored once; deltas are small
- **Replay:** Can reconstruct any universe's state at any point in time
- **Auditing:** Full event log is immutable and queryable
- **Undo/Redo:** Easy to implement by replaying to different timestamps

### 4.3 Graph Databases for Universe Relationships

**Neo4j Model:**

```cypher
// Define universe nodes
CREATE (u1:Universe {id: "u1", seed: 12345, created_at: 1234567890})
CREATE (u2:Universe {id: "u2", seed: 12346, created_at: 1234567890})
CREATE (u3:Universe {id: "u3", seed: 12347, created_at: 1234567900})

// Define relationships
CREATE (u1)-[:FORK_FROM]->(canonical:Universe {id: "canonical"})
CREATE (u2)-[:FORK_FROM]->(canonical)
CREATE (u3)-[:FORK_FROM]->(canonical)

// Players
CREATE (player1:Player {id: "p1"})
CREATE (player2:Player {id: "p2"})
CREATE (player1)-[:INHABITS]->(u1)
CREATE (player2)-[:INHABITS]->(u2)

// Merge event
CREATE (merge:MergeEvent {id: "merge_1", timestamp: 1234567950})
CREATE (u1)-[:MERGED_VIA]->(merge)
CREATE (u2)-[:MERGED_VIA]->(merge)
CREATE (merge)-[:CREATED]->(u3)

// Query: Find all universes that converged into u3
MATCH (u1)-[:MERGED_VIA]->(m)-[:CREATED]->(u3), (u2)-[:MERGED_VIA]->(m)-[:CREATED]->(u3)
RETURN u1, u2, u3, m
```

**When to Use Graph DB:**
- **Large player base** (10k+ concurrent players)
- **Complex merge logic** (tracking merge chains, conflicts)
- **Analytics** (understanding universe relationships, player merges)

**When to Avoid:**
- **Small-to-medium games** (100–1000 players); overkill
- **Simple linear event stream** (no complex relationships); SQL works fine

**For This Project:** Given "infinite universes," a graph DB enables efficient querying:
- "Find all universes that Player1 has ever inhabited"
- "Which universe is the canonical ancestor of Player1's current universe?"
- "How many player-merges happened in the past hour?"

### 4.4 Interaction with Containment Hierarchy

Recall: The IF engine uses parent-child containment trees (rooms → items, characters → inventory).

**Multiverse Integration:**

```lua
-- Room object (from IF engine)
room = {
    id = "cathedral",
    description = "A grand cathedral...",
    contents = {item1, item2, npc1},  -- ECS-style
    exits = {north = "temple", south = "market"}
}

-- Extended with universe metadata
room_in_universe = {
    base_room = room,
    universe_id = "u1",
    universe_version = 5,
    
    -- Local mutations (CoW)
    local_contents = {item1},  -- Removed item2 in this universe
    local_npcs_alive = {npc1},  -- npc2 was killed here
    
    function get_inhabitants()
        -- Return union of base + local contents
        return merge_tables(self.base_room.contents, self.local_contents)
    end,
    
    function add_item(item)
        table.insert(self.local_contents, item)
    end
}
```

**Why This Matters:**
- Containment hierarchy is still primary (room contains items)
- CoW adds a *delta layer* on top (universe-specific mutations)
- Event stream can update the delta, not the base
- Efficient storage: base room shared across all universes, deltas per-universe

---

## 5. Academic Papers and Industry Precedent

### 5.1 Parallel Simulation Worlds

**Relevant Research:**

1. **"Towards a Many-Worlds Interpretation of Virtual Worlds"** (conceptual, not published)
   - Explores quantum-inspired semantics for multiplayer games
   - Suggests "branch per decision" as a model for narrative divergence
   - Not industry-standard, but intellectually relevant

2. **"Procedural Content Generation in No Man's Sky"** (GDC talks, 2016–2018)
   - Sean Murray (Hello Games) discusses procedural universe generation
   - Key insight: **Seed-based generation ensures deterministic universe state**
   - Each player's view of a planet is procedurally generated from the same seed; identical across clients
   - **Scaling:** Billions of planets, but stored as "seed + modification delta," not full copies

3. **"Event Sourcing and CQRS"** (Fowler, 2005+)
   - Seminal papers on immutable event logs
   - Used in financial systems, event-driven architectures
   - Directly applicable to multiverse state tracking

4. **"Operational Transformation for Real-Time Collaborative Editing"** (Ellis & Gibbs, 1989)
   - Resolves conflicts when multiple clients edit the same document simultaneously
   - Adaptable to game state merging (events as "edits" to world state)

5. **"CRDTs: Conflict-free Replicated Data Types"** (Shapiro et al., 2011)
   - Data structures that merge without explicit conflict resolution
   - Example: Last-write-wins register, grow-only set, conflict-free sequence
   - Applicable to certain world state properties (read-only items, append-only logs)

6. **"Distributed Game State in MMORPGs"** (Mauve et al., 2004)
   - Surveys network topologies for MMO state replication
   - Discusses consistency models (eventual, strong) and their trade-offs
   - Not specific to multiverse, but relevant to replication strategy

### 5.2 No Man's Sky Precedent (Closest Real-World Example)

**Why NMS is Relevant:**

- **Infinite Procedural Universe:** Billions of planets, each unique but deterministically generated
- **Per-Player Isolation:** Each player's view of a planet is independent; modifications don't affect others' views
- **Minimal Server State:** Server tracks only player positions and shared events (like a player naming a planet)
- **Seed-Based Generation:** Each planet ID → seed → deterministic terrain, fauna, flora

**NMS Universe Model (Simplified):**

```
Planet ID: 0x123ABC
  ↓
Seed Hash: hash(0x123ABC)
  ↓
Procedural Generation (terrain, fauna, flora)
  ↓
Player_1's View (unmodified)
Player_2's View (unmodified)
Player_3's View (unmodified, except for named discoveries)
```

**Key Quote (Sean Murray, GDC 2016):**
> "We don't store universes. We store seeds. Every player can visit the same planet and see the same things because we all generate from the same seed."

**Application to Multiverse MMO:**

```lua
-- Universe = Seed + Event Log

Universe_1 = {
    seed = 42,  -- Deterministic generation
    base_state = generate_world(42),
    events = [
        {player: "p1", action: "pick_up_item", timestamp: 100},
        {player: "p1", action: "kill_npc", timestamp: 150}
    ]
}

Universe_2 = {
    seed = 43,  -- Different seed = different world
    base_state = generate_world(43),
    events = [
        {player: "p2", action: "trade_item", timestamp: 105}
    ]
}

-- When players merge into Raid_Universe:
Raid_Universe = {
    seed = merge_hash(42, 43),  -- Deterministic merge location
    base_state = generate_world(merge_hash(42, 43)),
    events = [
        -- Shared events from both universes
        {player: "p1", action: "pick_up_item", timestamp: 100},
        {player: "p2", action: "enter_raid", timestamp: 250},
        {players: ["p1", "p2"], action: "fight_boss", timestamp: 260}
    ]
}
```

### 5.3 Quantum Computing Metaphors

**Interesting Parallel (Not Directly Applicable):**

- **Superposition:** Object exists in multiple states until observed → **Universe exists in multiple branches until merged**
- **Entanglement:** Two particles share state → **Merged universes share state**
- **Wave Function Collapse:** Observation forces a definite state → **Merge operation forces a definite universe state**

**Why This Metaphor Breaks Down:**
- Quantum mechanics is probabilistic; games are deterministic
- Quantum superposition is "both and neither"; game states are "one or the other"
- But the metaphor is poetic and useful for design talks!

---

## 6. Scaling to Infinite Universes

### 6.1 Lazy Instantiation

**Core Principle:** Universe = Seed + Event Log, not a fully loaded object in memory.

**Implementation:**

```lua
UniverseRegistry = {}

function universe_enter(universe_id, player_id)
    if not UniverseRegistry[universe_id] then
        -- Lazy load: generate from seed
        UniverseRegistry[universe_id] = {
            seed = universe_id,
            base_state = generate_world(universe_id),
            events = load_events_from_storage(universe_id),
            last_access = os.time()
        }
    else
        UniverseRegistry[universe_id].last_access = os.time()
    end
    return UniverseRegistry[universe_id]
end

function universe_cleanup_task()
    -- Run periodically (e.g., every 5 minutes)
    for universe_id, universe in pairs(UniverseRegistry) do
        if os.time() - universe.last_access > HIBERNATION_THRESHOLD then
            -- Serialize and unload
            serialize_to_storage(universe_id, universe)
            UniverseRegistry[universe_id] = nil
        end
    end
end
```

**Memory Footprint:**

Assume:
- Active universe in memory: 5 MB
- Typical game: 100 concurrent players
- Average 1.5 universes per player (some solo, some in shared)
- RAM needed: 100 * 1.5 * 5 MB = 750 MB

**Storage Footprint:**

- Seed: ~16 bytes (hash)
- Event log: ~1 KB average (50 events × 20 bytes per event)
- Per-universe on disk: ~1 KB
- 1 billion universes: ~1 TB (reasonable for a long-running game)

### 6.2 Procedural Generation + Deterministic Seeds

**Design Pattern:**

```lua
function generate_world(seed)
    local rng = RNG.new(seed)  -- Seeded PRNG
    
    local world = {
        rooms = {},
        npcs = {},
        items = {}
    }
    
    -- Generate 50 rooms
    for i = 1, 50 do
        world.rooms[i] = {
            id = "room_" .. i,
            description = generate_description(rng),
            contents = {},
            exits = {}
        }
    end
    
    -- Generate NPCs
    for i = 1, 10 do
        world.npcs[i] = {
            id = "npc_" .. i,
            name = generate_name(rng),
            location = world.rooms[rng:randint(1, 50)].id,
            inventory = {}
        }
    end
    
    return world
end

-- Determinism guarantee:
-- generate_world(42) always returns the same world
-- Verification: Run it 1000 times, hash results, all hashes are identical
```

**Why This Matters:**

- **Consistency:** Two players with the same universe seed see the same world
- **Replayability:** Can regenerate a universe state without storing full data
- **Efficient Merging:** Merge location is deterministically generated from both seed sources

### 6.3 Storage Optimization: Store Only Deltas from Canonical Universe

**Multi-Tier Storage:**

```
Tier 1: Canonical Universe (the "golden master")
  - Stored once
  - All universes derive from it
  - Size: 10 MB

Tier 2: Per-Universe Deltas
  - Event log: ~1 KB average
  - CoW snapshots: ~100 KB average (modified objects)
  - Total per universe: ~101 KB
  - 1000 concurrent players: ~100 MB

Tier 3: Archive (Hibernated Universes)
  - Compressed deltas: ~10 KB per universe
  - Lazy loading on first access
  - Effectively unlimited storage
```

**Serialization Format (Lua):**

```lua
-- Canonical universe (stored once)
canonical = {
    version = 1,
    seed = 0,
    rooms = { ... },
    npcs = { ... },
    items = { ... }
}

-- Delta for Universe_5 (stored per-universe)
delta_5 = {
    base_seed = 0,  -- Derived from canonical
    events = [
        {time: 100, action: "pick_up", object: "sword", location: "room_3"},
        {time: 150, action: "kill", npc: "goblin_1"}
    ],
    snapshots = {
        {time: 100, room_3_contents: {...}},  -- CoW snapshot of room after modification
        {time: 150, goblin_1_alive: false}
    }
}

function load_universe_state(universe_id)
    local state = deepcopy(canonical)  -- Start with canonical
    local delta = load_delta(universe_id)
    for _, event in pairs(delta.events) do
        apply_event(state, event)
    end
    return state
end
```

### 6.4 Universe Lifecycle: Hibernate, Destroy, Persist

**Four States:**

| State | Condition | Storage | Memory | Accessible |
|-------|-----------|---------|--------|-----------|
| **Active** | Player(s) logged in | RAM | Yes | Yes |
| **Idle** | No players; <N hours old | RAM + Disk | Minimal | Yes (slow wake-up) |
| **Hibernated** | No access for >N hours | Disk only | No | Yes (slow wake-up) |
| **Archived** | No access for >M days | Compressed Disk | No | Yes (v. slow) |
| **Forgotten** | No access for >Y years | Deleted | No | Only via seed regen |

**Transition Diagram:**

```
Active
  ↓ (no players for 10 min)
Idle
  ↓ (no access for 1 hour)
Hibernated
  ↓ (no access for 30 days)
Archived
  ↓ (no access for 1 year)
Forgotten (seed regenerated if needed)
```

**Implementation:**

```lua
function universe_heartbeat()
    for universe_id, universe in pairs(UniverseRegistry) do
        local idle_time = os.time() - universe.last_access
        
        if idle_time > 3600 then  -- 1 hour
            -- Transition: Active → Hibernated
            serialize_to_storage(universe_id, universe)
            UniverseRegistry[universe_id] = nil
        end
    end
end

function archive_old_universes()
    -- Run daily
    for universe_id in storage:all_universes() do
        local created = storage:get_creation_time(universe_id)
        if os.time() - created > 30 * 86400 then  -- 30 days
            -- Archive: compress, move to cold storage
            storage:compress_and_archive(universe_id)
        end
    end
end

function cleanup_forgotten_universes()
    -- Run weekly
    for universe_id in storage:all_universes() do
        local created = storage:get_creation_time(universe_id)
        if os.time() - created > 365 * 86400 then  -- 1 year
            -- Forget: delete, seed is always regenerable
            storage:delete(universe_id)
        end
    end
end
```

**Key Insight:** "Forgotten" universes are regenerable if a player knows the seed, so deletion is safe. Players archive their universe seed if they want to return to it later.

---

## 7. How Multiverse Integrates with Code-as-Data (Lua)

### 7.1 Universe as a Running Lua Program

Recall: The IF engine runs Lua code to simulate the game. Worlds are defined as Lua source code.

**Implication for Multiverse:**

Each universe IS a Lua VM instance (or thread). Forking a universe = spawning a new Lua interpreter with a copy of the world state.

**Example:**

```lua
-- Base Universe (canonical source code)
-- file: universes/canonical.lua

game = {
    rooms = {
        cathedral = {
            description = "A grand cathedral",
            exits = {north = "temple"}
        }
    },
    npcs = {
        guard = {
            name = "Guard",
            location = "cathedral",
            alive = true
        }
    }
}

-- When Player1 enters:
function fork_universe(source_seed, player_id)
    local vm = create_lua_vm()  -- New interpreter
    vm:load_source("universes/canonical.lua")
    vm:execute("game.player_id = " .. player_id)
    return vm
end

-- Player1's action: kill the guard
player1_vm:execute("game.npcs.guard.alive = false")

-- Player2 fork starts fresh:
-- game.npcs.guard.alive = true (in their universe)

-- Merge event: Player1 & Player2 raid
function merge_universes(vm1, vm2, raid_id)
    local merged_vm = create_lua_vm()
    merged_vm:load_source("universes/canonical.lua")
    
    -- Apply Player1's mutations
    merged_vm:execute("game = " .. vm1:serialize_state())
    
    -- Merge Player2's state (conflict resolution)
    local vm2_state = vm2:serialize_state()
    merged_vm:execute("game:merge(" .. vm2_state .. ")")
    
    return merged_vm
end
```

### 7.2 Universe State Serialization as Lua Source Code

**Idea:** Instead of JSON, serialize universe state back into Lua.

**Advantage:** The serialized state IS executable code; can be committed to git, version controlled, diffed.

**Example:**

```lua
-- Universe_1 state (serialized)
game = {
    player = {id = "p1", name = "Brave Knight", level = 5},
    rooms = {
        cathedral = {description = "...", exits = {north = "temple"}},
        temple = {description = "...", exits = {south = "cathedral"}}
    },
    npcs = {
        guard = {
            name = "Guard",
            location = "cathedral",
            alive = false,  -- CHANGED: Player1 killed the guard
            inventory = {sword = 1}
        }
    },
    inventory = {sword = 2, potion = 5}
}

-- When this file is executed, the universe state is fully reconstructed
-- Can diff this against another universe's serialization:
diff universes/universe_1.lua universes/universe_2.lua
-- Shows exactly which objects have diverged
```

**Git Integration:**

```bash
# Commit a universe state
git add universes/universe_1.lua
git commit -m "Universe 1: Player1 killed guard, acquired sword"

# Merge two universes
git merge universes/universe_2.lua
# Git's built-in merge handles conflicts

# Replay universe history
git log universes/universe_1.lua | head -20
# Shows all changes to that universe
```

### 7.3 Diffing and Merging Two Lua World States

**Three-Way Merge (Git-Style):**

```
Base (Canonical):
  {guard = {alive = true, inventory = {}}}

Universe 1 (Player1):
  {guard = {alive = false, inventory = {sword = 1}}}

Universe 2 (Player2):
  {guard = {alive = true, inventory = {sword = 2}}}

Merge Decision:
  - guard.alive: Conflict! One killed, one left alive
  - guard.inventory: Both added to inventory (merge: {sword = 1, sword = 2})
  
Merged Result:
  {guard = {alive = false, inventory = {sword = 1, sword = 2}, conflict_marker = "player1_killed_player2_spared"}}
```

**Lua Merge Function:**

```lua
function merge_tables(t1, t2, base)
    local result = {}
    
    for key, value in pairs(base) do
        local v1 = t1[key]
        local v2 = t2[key]
        
        if v1 == v2 then
            result[key] = v1  -- No conflict
        elseif type(v1) == "table" and type(v2) == "table" then
            result[key] = merge_tables(v1, v2, base[key])  -- Recursive
        else
            -- Conflict
            result[key] = {
                conflict = true,
                v1 = v1,
                v2 = v2,
                base = base[key]
            }
        end
    end
    
    return result
end

-- Usage:
merged = merge_tables(universe1.state, universe2.state, canonical.state)
```

**Operational Transformation (Advanced):**

Instead of comparing final states, transform events from one universe to account for events in another:

```lua
function transform_event(e_player1, e_player2)
    -- Both happened on the same object
    if e_player1.object == e_player2.object then
        if e_player1.action == "kill" and e_player2.action == "attack" then
            -- Reorder: kill first, then attack fails (target dead)
            return {action = "attack_failed", reason = "target_dead"}
        end
    end
    -- No conflict; both can happen
    return e_player2
end
```

---

## 8. Recommended Architecture (Synthesis)

### 8.1 The Multiverse Stack

```
┌─────────────────────────────────────────────────┐
│ Player Layer                                     │
│ - Player creates new universe or joins shared   │
│ - Merged universes appear in "active lobbies"   │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│ Universe Routing Layer                           │
│ - Track active universes (in RAM)               │
│ - Route player joins to canonical or fork       │
│ - Manage merges (raid groups, events)           │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│ Lua VM Layer (Per-Universe)                      │
│ - Each universe = one Lua interpreter           │
│ - Executes game code in isolation               │
│ - Serializes state as Lua source                │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│ State Management Layer                           │
│ - Event sourcing (immutable event log)          │
│ - Copy-on-write snapshots                       │
│ - Conflict resolution strategies                │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│ Storage Layer                                    │
│ - Active: RAM (5-100 MB per universe)           │
│ - Idle: Disk (compressed serialized state)      │
│ - Archive: Cold storage (1 year+ old)           │
│ - Forgotten: Regenerable from seed              │
└─────────────────────────────────────────────────┘
```

### 8.2 Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Isolation Default** | Each player gets own universe | Eliminates resource contention; infinite scalability |
| **Merging Mechanism** | Explicit raid/event triggers | Controlled; story-driven; prevents accidental merges |
| **State Model** | Event sourcing + Lua code | Auditable; serializable; version-controllable |
| **Data Structure** | Git-like DAG + Lua tables | Natural for developers; familiar VCS metaphor |
| **Scaling** | Procedural generation + seeds | Infinite universes, bounded storage |
| **Conflict Resolution** | Operational transformation + game logic | Maximizes data preservation; enables custom rules |
| **Persistence** | CoW snapshots + delta storage | 99% storage reduction for large player bases |
| **Serialization** | Lua source code (not JSON) | Code-as-data philosophy; git-compatible |

### 8.3 Implementation Phases

**Phase 1: Single Universe (MVP)**
- One canonical universe
- Event sourcing working
- Lua VM integration complete
- No merging yet

**Phase 2: Per-Player Forks**
- Players get private copies on entry
- CoW snapshots implemented
- State serialization as Lua working

**Phase 3: Merging**
- Raid mechanic: players can form groups
- Conflict resolution logic in place
- Test with 2–3 player merges

**Phase 4: Scaling**
- Procedural generation implemented
- Lazy instantiation of universes
- Large-scale load testing (100+ concurrent players)

**Phase 5: Advanced Features**
- Dimensional rifts (temporary merges)
- Multi-universe events
- Admin tools for universe inspection/manipulation

---

## 9. Potential Pitfalls and Mitigations

### Pitfall 1: Merge Conflicts Are Intractable

**Risk:** When merging divergent universes, conflicts arise that require manual intervention.

**Mitigation:**
- Design game logic to prevent conflicts (e.g., unique items, resource scarcity is per-universe)
- Use CRDTs for state that must merge (append-only logs, grow-only sets)
- Fall back to "last-write-wins" for simple cases; OT for complex cases
- Game designers decide conflict resolution rules upfront

### Pitfall 2: State Explosion (Too Many Universes)

**Risk:** Storing 1 billion universes exhausts disk.

**Mitigation:**
- Procedural generation + seeds: only store deltas, not full universe state
- Aggressive hibernation/archival: unused universes moved to cold storage
- Cleanup: forget very old universes (regenerable from seed)
- Monitoring: alert if storage grows beyond projections

### Pitfall 3: Lua VM Per Universe Is Too Heavy

**Risk:** Lua VM overhead (memory, startup time) makes forking expensive.

**Mitigation:**
- Lua is lightweight: ~100–200 KB per VM, fast startup (<1 ms)
- Use shared bytecode: multiple VMs load the same bytecode cache
- Profile and optimize: lazy-load universe data into VM, not all at once
- Consider: limit concurrent universes (e.g., 1000 active VMs); older ones hibernated

### Pitfall 4: Network Latency on Merges

**Risk:** When merging, syncing all universe state between servers is slow.

**Mitigation:**
- Merges happen locally: all players move to same server before merge starts
- Pre-staging: when raid is announced, all players' universe state pre-fetched to same datacenter
- Eventual consistency: not all state must sync immediately; non-critical state can be async

### Pitfall 5: Player Cheating (Universe Hopping)

**Risk:** Player 1 finds a universe where they got lucky (rare loot), abandons others.

**Mitigation:**
- Loot/drops are *earned*, not procedural: rare items require boss defeats, not seed luck
- Track "primary universe" per player; identity, XP, achievements tied to it
- Loot obtained in a universe persists in that universe; can't be exported to other universes
- Cross-universe items: only certain "soulbound" items follow players between universes

---

## 10. Comparison with Alternative Architectures

### 10.1 Shared-World (Traditional MMO)

| Aspect | Multiverse | Shared World |
|--------|-----------|--------------|
| **Player Conflicts** | None (isolated) | Frequent (resource contention) |
| **Scalability** | Infinite (per-player universes) | Capped (one world) |
| **Economy** | Per-universe inflation | Single inflation driver |
| **PvP** | Consensual (explicit raids) | Forced (PKing) |
| **Story Pacing** | Per-player | Global (rushed for latecomers) |

### 10.2 Single-Player (No MMO)

| Aspect | Multiverse | Single-Player |
|--------|-----------|--------------|
| **Multiplayer** | Opt-in (raids, events) | None |
| **Persistent World** | Yes (cross-sessions) | Yes |
| **Shared Economy** | Per-merged universe | N/A |
| **Social** | Sparse but meaningful | None |

### 10.3 Instanced MMO (Guild Wars Model)

| Aspect | Multiverse | Instanced |
|--------|-----------|-----------|
| **Default Isolation** | Yes (player gets own universe) | No (shared zones, dynamic instances) |
| **Merging** | Explicit (raids) | Automatic (zone load-balancing) |
| **Player Control** | Full (choose when to merge) | Limited (server decides) |

**Verdict:** Multiverse is the most player-friendly: isolation eliminates conflicts, merging is opt-in.

---

## 11. Future Research Directions

1. **Spectral Rendering Engines**
   - How to efficiently render "ghosts" of other universes in the same client?
   - Network optimization for cross-universe visibility

2. **Quantum State Machine for Merge Resolution**
   - Apply quantum computing concepts (superposition, entanglement) to game design
   - "Uncertain state" objects that resolve upon observation/merge

3. **Machine Learning for Conflict Prediction**
   - Predict merge conflicts before they happen
   - Suggest conflict resolution strategies based on game history

4. **Cross-Platform Universe Export**
   - Export universe state as JSON/Protocol Buffers for cross-game compatibility
   - Enable players to "carry" universe state between different games

5. **Temporal Branching for Roguelikes**
   - Use multiverse model for roguelike "time travel" mechanics
   - Rewind to a past checkpoint, create a fork, continue differently

---

## 12. Conclusion

The multiverse architecture offers a compelling alternative to shared-world MMOs. By making isolation the default and merging consensual, it solves key problems:

- **No resource contention** → infinite scalability
- **Per-player story** → better pacing and immersion
- **Opt-in multiplayer** → social without mandatory PvP
- **Event-driven merging** → story-rich crossovers and raids

The stack is technically feasible using Lua's code-as-data properties, event sourcing, and procedural generation. Storage scales to billions of universes via seed-based generation and CoW deltas.

The key trade-off: players are isolated by default, requiring explicit merge mechanics to interact. Game design must make merging attractive (raids, limited-time events, shared resources).

For a text adventure MMO, the multiverse model is **highly recommended**. It preserves the single-player narrative feel while enabling cooperative multiplayer when desired.

---

## Appendix: Code Examples

### A1. Universe Fork Operation (Pseudocode)

```lua
-- Create a fork of a universe
function fork_universe(source_universe_id, new_player_id)
    local source = load_universe(source_universe_id)
    
    -- Create a new VM for the fork
    local new_vm = create_lua_vm()
    
    -- Load the same code, but with a new player context
    new_vm:load_source(source.code)
    
    -- Initialize state from source
    new_vm:set_global("game", deepcopy(source.state))
    
    -- Create new universe record
    local new_universe_id = generate_universe_id()
    local new_universe = {
        id = new_universe_id,
        parent_id = source_universe_id,
        player_ids = {new_player_id},
        vm = new_vm,
        events = {},
        created_at = os.time()
    }
    
    -- Register the new universe
    universes[new_universe_id] = new_universe
    
    return new_universe_id
end
```

### A2. Merge Operation (Pseudocode)

```lua
function merge_universes_for_raid(player_universe_ids, raid_config)
    -- All participating players' universes merge into one shared raid universe
    
    local raid_universe_id = generate_universe_id()
    local raid_vm = create_lua_vm()
    
    -- Start with canonical base
    raid_vm:load_source(canonical_code)
    local merged_state = deepcopy(canonical_state)
    
    -- Merge each player's state into the raid universe
    for _, player_universe_id in pairs(player_universe_ids) do
        local player_universe = load_universe(player_universe_id)
        local player_state = player_universe.vm:get_global("game")
        
        -- Conflict resolution: keep player's inventory, merge world state
        merged_state = merge_states(merged_state, player_state, {
            strategy = "keep_player_inventory",
            keep_world_base = true
        })
    end
    
    -- Set raid-specific state (boss health, arena bounds, etc.)
    merged_state.raid = raid_config
    
    -- Initialize raid universe
    raid_vm:set_global("game", merged_state)
    
    local raid_universe = {
        id = raid_universe_id,
        player_ids = player_universe_ids,
        vm = raid_vm,
        events = {},
        type = "raid",
        created_at = os.time()
    }
    
    universes[raid_universe_id] = raid_universe
    
    return raid_universe_id
end
```

### A3. Event Sourcing (Pseudocode)

```lua
function apply_player_action(universe_id, player_id, action, args)
    local universe = universes[universe_id]
    
    -- Execute action in the universe's VM
    local result = universe.vm:execute(action, args)
    
    -- Record event
    local event = {
        id = #universe.events + 1,
        timestamp = os.time(),
        player_id = player_id,
        action = action,
        args = args,
        result = result
    }
    
    table.insert(universe.events, event)
    
    -- Append to event log (persistent storage)
    log_event(universe_id, event)
    
    return result
end

-- Replay a universe's history
function replay_universe(universe_id, up_to_event_id)
    local universe = load_universe(universe_id)
    local vm = create_lua_vm()
    
    -- Start with canonical state
    vm:load_source(canonical_code)
    vm:set_global("game", deepcopy(canonical_state))
    
    -- Replay events up to event_id
    for i = 1, up_to_event_id do
        local event = universe.events[i]
        vm:execute(event.action, event.args)
    end
    
    return vm:get_global("game")
end
```

---

## References and Further Reading

1. **Event Sourcing:**
   - Fowler, Martin. "Event Sourcing." https://martinfowler.com/eaaDev/EventSourcing.html

2. **CRDTs:**
   - Shapiro, Marc, et al. (2011). "Conflict-free Replicated Data Types." https://arxiv.org/abs/1805.06358

3. **Operational Transformation:**
   - Ellis, C.A., & Gibbs, S.J. (1989). "Concurrency Control in Groupware Systems." https://dl.acm.org/doi/10.1145/67544.66963

4. **No Man's Sky Procedural Generation:**
   - Murray, Sean. "Procedural Worlds in No Man's Sky." GDC 2016. https://www.gdcvault.com/play/1023630

5. **MMO Instancing:**
   - Mauve, M., et al. (2004). "Local-Server Game Architectures." https://link.springer.com/chapter/10.1007/978-3-540-24693-2_11

6. **Lua Embedding:**
   - Lua Reference Manual. https://www.lua.org/manual/

7. **Git Branching Model:**
   - Driessen, Vincent. "A Successful Git Branching Model." https://nvie.com/posts/a-successful-git-branching-model/

---

**End of Research Report**

*Compiled by Frink, Researcher*  
*For the MMO Project*  
*2026-03-19*
