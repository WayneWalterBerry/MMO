# Creature Ecology Design

**Version:** 1.0  
**Last Updated:** 2026-08-21  
**Author:** Brockman (Documentation)  
**Related:** `../../architecture/engine/creatures.md`, `combat-system.md`, `spatial-system.md`

---

## Overview

The creature ecology system defines how NPCs behave as a collective — coordinating attacks, marking territory, and creating environmental obstacles. Implemented in Phase 4 **WAVE-5**, it introduces three subsystems:

1. **Pack awareness** — Multiple creatures coordinate attacks (simplified stagger model, not full zone-targeting)
2. **Territorial marking** — Creatures mark rooms with invisible markers; other creatures respond to territorial claims
3. **Web obstacles** — Spider-created webs block NPC movement while remaining player-passable

These systems add depth to Level 1 encounters without requiring complex state machines. Each system is independently toggleable per creature type via behavior metadata.

---

## 1. Pack Awareness: Coordinated Creature Attacks

### Design: Simplified Stagger Model

**Scope decision (v1.1):** Full alpha/beta/omega role system with zone-targeting is **deferred to Phase 5**. Phase 4 implements **simplified pack awareness** instead.

When multiple wolves are in the same room:

- Creatures are **aware** of each other (can see in same room)
- Attacks are **staggered** — one leads, others wait 1 game-turn
- Alpha is **highest health** (simplest observable metric)
- Individual wolf AI improves (defensive retreat, ambush positioning, smart positioning)

### What's NOT Implemented (Phase 5+)

- ❌ Zone targeting (torso, legs, arms)
- ❌ Combat engine changes for coordinated zone selection
- ❌ Omega reserve conditions (complex state)
- ❌ Full role hierarchies with communication

### Pack Behavior Implementation

#### 1. Alpha Selection

In `src/engine/creatures/pack.lua`:

```lua
function select_pack_alpha(creatures_in_room)
    -- Alpha = creature with highest current health
    local alpha = nil
    local max_health = 0
    
    for _, creature in ipairs(creatures_in_room) do
        if creature.template == "wolf" and (not alpha or creature.health > max_health) then
            alpha = creature
            max_health = creature.health
        end
    end
    
    return alpha  -- may be nil if no wolves
end
```

**Rationale:** Health is observable, easily tracked, and already updated during combat. No new state required.

#### 2. Stagger Attack Logic

When combat resolves for wolf #2 in a pack:

```lua
-- In src/engine/combat/init.lua
function resolve_wolf_attack(attacker, defender, ctx)
    -- Check if wolf is in pack
    local wolves = ctx.room:find_by_template("wolf")
    if #wolves > 1 then
        local alpha = select_pack_alpha(wolves)
        
        -- Non-alpha wolves wait one turn
        if attacker ~= alpha and attacker._pack_stagger_cooldown then
            if ctx.game_time - attacker._pack_stagger_cooldown < 1 then
                return  -- Skip this turn; staggered
            end
        end
        
        -- After attacking, apply cooldown to next non-alpha
        for _, wolf in ipairs(wolves) do
            if wolf ~= alpha and wolf ~= attacker then
                wolf._pack_stagger_cooldown = ctx.game_time
            end
        end
    end
    
    -- Normal combat resolution proceeds
    perform_combat_resolution(attacker, defender, ctx)
end
```

**Effect:** 2 wolves vs player: alpha attacks immediately, second wolf waits 1 turn, then attacks on turn 2. Pattern repeats. Creates rhythm without full combat engine restructuring.

### Individual Wolf AI Improvements

Beyond pack tactics, individual wolves demonstrate:

#### A. Defensive Retreat

When wolf health drops below 20%:

```lua
function wolf_defensive_retreat(wolf, ctx)
    if wolf.health < (wolf.max_health * 0.2) then
        -- Try to move behind furniture
        local furniture = ctx.room:find_by_template("furniture")
        if #furniture > 0 then
            wolf:move_behind(furniture[1])  -- Positional hint
            return true
        end
        
        -- Otherwise flee room
        local exit = wolf:find_random_exit()
        wolf:move_to_room(exit)
        return true
    end
    return false
end
```

**Effect:** Wounded wolves don't stupidly charge to death. They reposition, creating dynamic combat.

#### B. Ambush Positioning (Near Web)

If spider web is in room:

```lua
function wolf_web_ambush(wolf, ctx)
    local webs = ctx.room:find_by_template("spider-web")
    if #webs > 0 then
        -- Wolf positions near web, waits for prey
        wolf._ambush_position = webs[1]
        wolf._ambush_active = true
        return true
    end
    return false
end
```

**Effect:** Wolves leverage environmental objects (spider webs) for advantage. Creates hybrid pack/environmental tactics.

#### C. Smart Positioning

Wolves prefer attacking from doorway (blocks player escape):

```lua
function wolf_smart_positioning(wolf, room, ctx)
    -- If room has exits and player is inside, position at exit
    local exits = room:get_exits()
    if #exits > 0 and ctx.player.room == room then
        for _, exit_info in ipairs(exits) do
            wolf._preferred_position = exit_info  -- Doorway hint
        end
    end
end
```

**Effect:** Wolves naturally block escape routes, making combat feel coordinated and threatening.

### Pack Behavior Metadata

In `src/meta/creatures/wolf.lua`:

```lua
behavior = {
    -- ... existing drives, states, reactions ...
    
    pack_tactics = {
        enabled = true,
        stagger_attacks = true,
        alpha_selection = "highest_health",
    },
    
    individual_ai = {
        defensive_retreat = true,
        retreat_threshold = 0.2,  -- 20% health
        ambush_positioning = true,
        smart_positioning = true,
    },
}
```

### Testing Pack Tactics

Example scenario:

```
Room: Cellar
Creatures: Wolf A (50 HP), Wolf B (40 HP), Player (60 HP)

Turn 1: Alpha (Wolf A, 50 HP) attacks player
        Wolf B on cooldown
Turn 2: Wolf B attacks player
        Wolf A can attack again next turn
Turn 3: Pattern repeats

Result: 2 wolves dealing ~20 damage per coordinated round
        vs single wolf: ~10 damage per round
        
Challenge: Doubled damage output, but predictable rhythm
           allows player to plan (heal, flee, focus fire)
```

---

## 2. Territorial Marking System

### Design: Invisible Room Markers with BFS Radius

Wolves mark rooms with invisible territorial markers. Other creatures detect markers and respond based on aggression:

- **Aggressive wolf** (aggression > 0.7) → Challenge intruder, fight for territory
- **Submissive wolf** (aggression ≤ 0.7) → Avoid territory, flee
- **Non-wolf creature** → Ignore marking

### Territory Marker Object

In `src/meta/objects/territory-marker.lua`:

```lua
return {
    guid = "{windows-guid}",
    template = "invisible",  -- not visible to player
    id = "territory-marker",
    name = "wolf territory mark",
    
    -- Marker metadata
    owner = "{wolf-guid}",        -- creature GUID who placed it
    timestamp = 0,                 -- game time placed
    radius = 2,                    -- exit-graph hops
    duration = "1 day",            -- game time before expiring
    
    -- Sensory: player can smell it
    on_feel = "Nothing detectable.",
    on_smell = "You catch a musky animal scent. Territorial.",
    on_listen = "Silent.",
    on_taste = "Bitter and rank.",
    
    -- Player interaction
    detectable = false,  -- can't find via look/examine
    smell_only = true,   -- only smell reveals presence
}
```

### Marking Process

When wolf enters new room:

```lua
-- In src/engine/creatures/territorial.lua
function mark_territory(wolf, room, ctx)
    local mark_config = wolf.behavior.territorial
    if not mark_config or not mark_config.marks_territory then
        return
    end
    
    -- Check if already marked by this wolf
    local existing = room:find_by_owner(wolf.guid)
    if existing then
        return  -- Already marked; update timestamp
    end
    
    -- Create invisible marker
    local marker = ctx.registry:instantiate("territory-marker")
    marker.owner = wolf.guid
    marker.timestamp = ctx.game_time
    marker.radius = mark_config.mark_radius or 2
    
    room:add_object(marker)  -- Added to room but invisible to player
end
```

### Territory Detection: BFS Radius

Territory is detected via **exit-graph BFS** (breadth-first search from marked room).

Definition: **radius = N** means marker affects marked room + all rooms reachable within N exits.

Example (Level 1 cellar, 7 rooms):

```
Marked room: Cellar
Radius: 2 exits away

         Start-Room
             |
         Hallway (1 hop) ← affected
             |
         Courtyard (2 hops) ← affected
         
         Cellar (origin) ← affected
             |
         Storage (1 hop) ← affected
             |
         Crypt (2 hops) ← affected
```

Implementation:

```lua
function is_in_territory(creature, room, ctx)
    local markers = ctx.game:find_all_markers()
    
    for _, marker in ipairs(markers) do
        if not is_owner(creature, marker) then
            -- Check if room is within BFS radius of marker room
            local marker_room = ctx.registry:get(marker.location_guid)
            if is_within_bfs_radius(room, marker_room, marker.radius) then
                return true, marker
            end
        end
    end
    
    return false, nil
end

function is_within_bfs_radius(target_room, source_room, radius)
    local queue = { { room = source_room, distance = 0 } }
    local visited = {}
    
    while #queue > 0 do
        local current = table.remove(queue, 1)
        
        if visited[current.room.guid] then
            goto continue
        end
        visited[current.room.guid] = true
        
        if current.room == target_room then
            return current.distance <= radius
        end
        
        if current.distance < radius then
            for _, exit in ipairs(current.room:get_exits()) do
                table.insert(queue, { room = exit.target, distance = current.distance + 1 })
            end
        end
        
        ::continue::
    end
    
    return false
end
```

### Response to Territorial Claim

When creature enters territory:

```lua
function on_creature_enter_territory(creature, marker, ctx)
    local response = creature.behavior.territorial.response_to_mark
    if not response then return end
    
    if marker.owner == creature.guid then
        return "patrol"  -- Own territory; patrol
    end
    
    if creature.behavior.aggression > 0.7 then
        return "challenge"  -- Aggressive; fight intruder
    else
        return "avoid"  -- Submissive; leave territory
    end
end
```

**Effects:**

| Response | Behavior |
|----------|----------|
| **Patrol** | Wolf stays alert, increased attack bias |
| **Challenge** | Wolf hunts intruder aggressively |
| **Avoid** | Wolf flees, seeks other territory |

### Player Interaction with Territory

**Player perception:**

```
> smell
You catch a musky animal scent here. This is claimed territory.
```

**Design rationale:** Player senses territorial markers via smell but cannot see them. Rewards sensory exploration. Encourages repeated `smell` commands.

### Marker Expiration

Markers expire after "1 day" (implementation-dependent game time). Expired markers are removed.

```lua
function cleanup_expired_markers(ctx)
    local markers = ctx.game:find_all_markers()
    
    for _, marker in ipairs(markers) do
        if ctx.game_time - marker.timestamp > 86400 then  -- 1 game day in ticks
            ctx.registry:deregister(marker.guid)
        end
    end
end
```

---

## 3. Web Obstacles: Spider Environmental Control

### Design: Movement Obstacle (Not Trap)

Spider-created webs are **movement obstacles** for NPCs, not player-targeting traps.

**v1.1 scope decision:** Simplified from size-based trap system (v1.0) to binary obstacle.

- **NPCs (any creature, size-agnostic):** Cannot pass through web; blocked
- **Player:** Can walk through (sticky but passable)

No escape difficulty, no size scaling, no FSM state machine. Webs are simple, solid obstacles.

### Spider-Web Object

In `src/meta/objects/spider-web.lua`:

```lua
return {
    guid = "{windows-guid}",
    template = "small-item",
    id = "spider-web",
    name = "a sticky spider web",
    keywords = {"web", "spider web", "cobweb", "silk"},
    description = "Glistening threads span the corner, sticky to the touch.",
    
    on_feel = "Tacky, clinging strands. They stick to your fingers.",
    on_smell = "Faint earthy smell.",
    on_listen = "Silent.",
    on_taste = "Bitter, inedible.",
    
    material = "silk",
    
    -- Web as movement obstacle
    obstacle = {
        blocks_npc_movement = true,      -- NPCs cannot pass
        player_passable = true,          -- Player can walk through
        message_blocked = "Something skitters into the web and struggles.",
        message_destroyed = "The web tears apart.",
    },
    
    -- Player sensory entry feedback
    on_enter = "You brush through the sticky web. Threads cling to your clothes.",
}
```

### Obstacle Mechanics

When NPC moves toward room with web:

```lua
-- In src/engine/creatures/init.lua
function attempt_npc_move(creature, exit_direction, ctx)
    local target_room = ctx.room:get_exit(exit_direction).target
    
    -- Check for webs blocking
    local webs = target_room:find_by_template("spider-web")
    if #webs > 0 and not can_pass_web(creature) then
        -- NPC cannot enter; blocked
        ctx.print(webs[1].obstacle.message_blocked)
        creature:stay_in_room()  -- No movement
        return false
    end
    
    creature:move_to_room(target_room)
    return true
end

function can_pass_web(creature)
    -- Spiders can pass; all other creatures blocked
    if creature.template == "spider" then return true end
    return false
end
```

**Effect:** Small creatures (rat) trapped by web in room with spider. Cannot escape; becomes prey.

### Player Movement Through Web

Player walks through normally:

```lua
> go north
You brush through the sticky web. Threads cling to your clothes.

[Player enters room with web; no mechanical penalty]
```

**Design rationale:** Web is cosmetic obstacle for player. Reinforces sensory immersion without game-breaking hindrance.

### Web Creation Cooldown

Spiders create webs on a cooldown:

```lua
-- In src/meta/creatures/spider.lua
behavior = {
    creates_object = {
        template = "spider-web",
        cooldown = "30 minutes",      -- game time
        max_per_room = 2,              -- cap at 2 active webs
        condition = function(spider, ctx)
            -- Only create if room has fewer than max webs
            local webs = ctx.room:find_by_template("spider-web")
            return #webs < 2
        end,
        narration = "The spider spins a web in the corner.",
    },
}
```

**Effect:** Spider gradually fills room with 1-2 webs over time. Web density increases if player doesn't clear them. Adds environmental pressure.

### Ambush Behavior Near Web

Spider prioritizes attacking creatures trapped in web:

```lua
-- In src/engine/creatures/init.lua
function spider_ambush_priority(spider, ctx)
    -- High priority if prey in web
    local webs = ctx.room:find_by_template("spider-web")
    for _, web in ipairs(webs) do
        if web.trapped_creature then
            return 0.9  -- High priority
        end
    end
    
    -- Normal priority otherwise
    return 0.5
end
```

**Gameplay loop:**
1. Spider creates web
2. Rat enters room, blocked by web
3. Spider detects trapped rat
4. Spider attacks trapped rat (easy kill)
5. Player must decide: help rat or leave?

---

## 4. Pack Awareness + Territory + Web: Integrated Example

### Scenario: Multi-Wolf Cellar

```
Room: Cellar
Creatures: Wolf A (50 HP), Wolf B (40 HP), Spider (30 HP)
Environment: 2 spider webs, territory marker from Wolf A

Turn 1:
- Player enters cellar
- Senses territorial marker: "Musky animal scent; claimed territory"
- Sees 2 webs
- Wolf A (alpha, highest HP) attacks first

Turn 2:
- Wolf B staggered; waits (pack tactic)
- Spider in web, blocked by player presence
- Rat caught in web, spider circles

Turn 3:
- Wolf B attacks (stagger ends)
- Player deals 15 damage to Wolf A

Turn 4:
- Wolf A health 35 HP (below 50), still alpha
- Wolf B 40 HP, attacks again
- Wolf A health < 20% → defensive retreat triggered
- Wolf A moves behind barrel

Result: Coordinated threat, environmental pressure, strategic depth
```

---

## 5. Player Interactions with Creature Ecology

### Direct Interactions

| Behavior | Player Action | Outcome |
|----------|---------------|---------|
| **Pack stagger** | Fight 2 wolves | Predictable rhythm; focus on alpha |
| **Territorial mark** | Smell room | Discover wolf presence before encounter |
| **Ambush near web** | Enter web room | Spider attacks from advantage; high threat |

### Strategic Implications

**Territorial intelligence:**

```
Player: smell
Output: "Musky wolf scent. This territory is claimed."

Implication: Wolf pack nearby. Prepare for multi-wolf encounter.
```

**Web navigation:**

```
Player: examine web
Output: "Sticky threads. Something small is trapped inside."

Implication: Web blocks small creatures. Avoids rat ambush puzzle.
```

**Pack positioning:**

```
Turn 1: 2 wolves enter
Turn 2: Alpha attacks; beta waits
Turn 3: Beta attacks

Player learns: Attack strongest first (alpha). Beta will follow.
Expect coordinated but staggered damage.
```

---

## 6. Design Rationale (v1.1)

### Pack Tactics Simplification

**v1.0:** Full alpha/beta/omega roles, zone-targeting, 200+ LOC  
**v1.1:** Stagger attacks + alpha selection by health, ~80 LOC

**Rationale:** Phase 4 focuses on crafting and stress. Combat AI complexity deferred to Phase 5. Stagger model is 80% of gameplay impact with 20% of code cost.

### Territory Marking Scope

**v1.0:** Undefined "rooms" concept  
**v1.1:** Precise BFS exit-graph hop definition

**Rationale:** Exit graph is already implemented (room traversal). BFS is standard algorithm. Enables spatial reasoning without new systems.

### Web Obstacle Simplification

**v1.0:** Size-based trap, creature speed scaling, escape difficulty FSM  
**v1.1:** Binary NPC block, player passable, no FSM

**Rationale:** Simpler design, fewer edge cases. NPC obstruction is sufficient for Level 1. Trap state machine deferred to Phase 5+ (escape artists, item use).

---

## 7. Testing Strategy

### Test Coverage (WAVE-5 deliverables)

**File:** `test/creatures/test-pack-tactics.lua`

- ✅ 2 wolves in room → alpha (highest health) attacks first
- ✅ Non-alpha wolf staggered (waits 1 turn)
- ✅ Stagger pattern repeats (turn 3: alpha again)
- ✅ Alpha priority updates if health changes
- ✅ Single wolf ignores stagger logic

**File:** `test/creatures/test-territorial.lua`

- ✅ Wolf marks room on entry
- ✅ Marker invisible to player (look fails)
- ✅ `smell` reveals territorial marker presence
- ✅ Other wolf in territory: aggression > 0.7 → challenge
- ✅ Other wolf in territory: aggression ≤ 0.7 → avoid
- ✅ BFS radius calculation: 2 hops from source room
- ✅ Marker expires after 1 day (game time)

**File:** `test/creatures/test-spider-web.lua` (from WAVE-4)

- ✅ Spider creates web on cooldown (30 min)
- ✅ Max 2 webs per room
- ✅ Web blocks NPC movement (rat cannot pass)
- ✅ Player can walk through web
- ✅ Spider attacks trapped creature (high priority)

### Integration Tests

- ✅ Full scenario: 2 wolves + territorial mark + web room
- ✅ Player senses all 3 systems (territory, stagger rhythm, web)
- ✅ Ecosystem feels coordinated and threatening

---

## 8. Known Limitations & Future Extensions

| Limitation | Status | Phase |
|-----------|--------|-------|
| Pack limited to 3 wolves per room | By design | P4 (Level 1 scope) |
| No zone-targeting in combat | Deferred | P5+ (combat engine upgrade) |
| Marker visible only via smell | By design | P4 |
| Web not destructible by NPC | Deferred | P5+ (NPC tool use) |
| No omega reserve condition | Deferred | P5+ (complex state) |
| Territory not visible on map | Deferred | P5+ (map UI) |

---

## 9. Glossary

| Term | Definition |
|------|-----------|
| **Pack awareness** | Simplified multi-creature coordination via staggered attacks and alpha selection |
| **Alpha** | Lead wolf in pack; selected by highest current health; attacks first |
| **Stagger** | Non-alpha attacks delayed 1 turn; creates predictable rhythm |
| **Territorial marking** | Invisible marker placed in room; detected via creature response or player smell |
| **Territory** | Set of rooms within BFS radius of marked room |
| **BFS radius** | Exit-graph hops; 2 = marked room + 2 exits away |
| **Territory marker** | Invisible object tracking owner, timestamp, radius; placed by wolf on room entry |
| **Web obstacle** | Spider-created object blocking NPC movement; player passable |
| **Ambush behavior** | Spider prioritizes attacking prey trapped in web |

---

## 10. Related Systems

- **Combat System** (`combat-system.md`) — Stagger attacks affect combat resolution
- **Creatures** (`../../architecture/engine/creatures.md`) — Base behavior framework
- **Spatial System** (`spatial-system.md`) — Room graph, exit traversal, BFS navigation
- **Spider Ecology** (`crafting-system.md` WAVE-4) — Web creation and silk crafting
- **Creature Death** (`../../architecture/engine/creature-death-reshape.md`) — Corpse states and loot
