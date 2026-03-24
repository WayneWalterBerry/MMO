# NPC Engineering Patterns: Decision-Making & Architecture

**Technical Deep Dive** — Compare and contrast FSMs, Behavior Trees, GOAP, Utility AI, and architectural styles (event-driven, tick-based, actor model). Match patterns to our engine's philosophy.

---

## Executive Summary

NPC decision-making can be architected via multiple patterns, each with trade-offs:

| Pattern | Pros | Cons | Best For |
|---------|------|------|----------|
| **FSM** | Simple, efficient, debuggable | Scales poorly, rigid | Simple NPCs, state-locked behaviors |
| **Hierarchical FSM** | Reduces duplication, clearer structure | More complex debugging | Moderate complexity (10-20 states) |
| **Pushdown Automaton (Stack Machine)** | Handles nested/interrupt semantics | Complex to implement and debug | NPCs with resumable tasks (do X, interrupted by Y, resume X) |
| **Behavior Tree** | Modular, composable, visual | Requires tool support to shine | Moderately complex behaviors, team design |
| **GOAP** | Reactive, emergent, planful | Computational cost, debugging hard | NPCs with dynamic goals (solve puzzle, find resource) |
| **Utility AI** | Responsive, scalable, intuitive | Tuning curves is an art | NPCs with competing priorities (danger vs. task) |
| **ECS (Entity Component System)** | Scalable, cache-efficient, composable | Data-driven (steeper learning curve) | 100+ NPCs, need high performance |

**For MMO with Lua FSM objects:** Recommend **Hierarchical FSM + Utility AI** for core behavior, with **GOAP** for goal-driven planning. Use **tick-based updates** for efficiency.

---

## I. Finite State Machines (FSMs)

### A. Classic FSM

An FSM is a set of discrete states with explicit transitions:

```lua
-- Simple guard FSM
local GUARD_FSM = {
    state = "idle",
    states = {
        idle = {
            update = function(self) end,
            on_event = { player_detected = "alert" }
        },
        alert = {
            update = function(self)
                self:move_toward_player()
            end,
            on_event = {
                player_lost = "idle",
                player_attacked = "combat"
            }
        },
        combat = {
            update = function(self)
                self:attack_player()
            end,
            on_event = { player_dead = "idle", enemy_defeated = "idle" }
        }
    }
}

function GUARD_FSM:transition(event)
    local next_state = self.states[self.state].on_event[event]
    if next_state then
        self.state = next_state
    end
end
```

**Pros:**
- Easy to visualize and debug (print current state)
- Efficient (single state active at once)
- Clear transitions (explicit events)

**Cons:**
- **Scalability:** With 20 states, transition matrix explodes to 400+ combinations
- **Rigidity:** Changing behavior requires refactoring entire FSM
- **No memory:** NPC forgets previous state upon transition (context loss)

### B. State Explosion Problem

Example: Guard with `idle`, `patrol`, `alert`, `combat`, `flee`, `investigate`, `rest`, `eat`:

- Direct transitions: 8² = 64 possible transitions
- Not all valid (can't eat while in combat)
- Adding one state: 9² = 81 transitions
- **Scaling:** 30 states → 900 transitions (becomes unmaintainable)

---

## II. Hierarchical FSM (HFSM)

### A. Layered State Machine

HFSM adds hierarchy: states can contain sub-FSMs.

```lua
local GUARD_HFSM = {
    state = "awake",
    substates = {
        awake = {
            idle = { update = function(self) end },
            patrol = { update = function(self) self:patrol() end }
        },
        combat = {
            attacking = { update = function(self) self:attack() end },
            defending = { update = function(self) self:block() end },
            fleeing = { update = function(self) self:flee() end }
        },
        sleep = { update = function(self) end }
    }
}

function GUARD_HFSM:transition(superstate, substate)
    self.state = superstate
    self.substate = substate
end
```

**Structure:**
- **Top level:** awake, combat, sleep (3 states)
- **Awake → sub-FSM:** idle, patrol (2 sub-states)
- **Combat → sub-FSM:** attacking, defending, fleeing (3 sub-states)
- **Total transitions:** 3 + (2×2) + (3×3) = 3 + 4 + 9 = 16 (vs. 30 direct states = 900 transitions)

**Benefits:**
- Reduces duplication (common "awake" behaviors grouped)
- Clearer hierarchy (behaviors organized by context)
- Easier to add variants (e.g., "combat" → "melee combat", "ranged combat")

**Limitations:**
- Still rigid within hierarchy
- Transitions between unrelated sub-FSMs are awkward
- Debugging requires tracking multiple state levels

---

## III. Pushdown Automaton (Stack-Based State Machine)

### A. Concept

A pushdown automaton adds a **stack** to FSM, enabling:
- Save current state
- Transition to new state
- Pop stack to resume previous state

```lua
local NPC = {
    state_stack = { "idle" },
}

function NPC:push_state(new_state)
    table.insert(self.state_stack, new_state)
end

function NPC:pop_state()
    if #self.state_stack > 1 then
        table.remove(self.state_stack)
    end
end

function NPC:current_state()
    return self.state_stack[#self.state_stack]
end

-- Example: NPC patrolling, notices danger, investigates, then resumes patrol
function NPC:on_danger_detected()
    self:push_state("investigating")  -- Stack: ["idle", "investigating"]
end

function NPC:investigation_complete()
    self:pop_state()  -- Stack: ["idle"], resumes patrol
end
```

**Use Case:**
- Guard patrols → hears noise → investigates → returns to patrol
- Shopkeeper working → player arrives → conversation → resumes work

**Pros:**
- Enables resumable tasks (pause/resume semantics)
- Natural interrupt handling
- Supports nested behaviors

**Cons:**
- **Stack mismanagement:** Can end up with deeply nested states (hard to debug)
- **Memory overhead:** Stack per NPC
- **Complexity:** More conceptually advanced than FSM

---

## IV. Behavior Trees (BT)

### A. Structure

A Behavior Tree is a tree of nodes representing actions and decisions:

```
Root
├─ Selector (try actions until one succeeds)
│  ├─ Sequence (all must succeed)
│  │  ├─ Check: PlayerVisible?
│  │  └─ Action: Attack
│  ├─ Sequence
│  │  ├─ Check: HealthLow?
│  │  └─ Action: Flee
│  └─ Action: Patrol
```

**Node Types:**
- **Action:** Do something (attack, move, say)
- **Condition:** Check state (player visible? health low?)
- **Selector:** Try children until one succeeds (OR)
- **Sequence:** All children must succeed (AND)
- **Parallel:** Run children concurrently

### B. Lua Implementation

```lua
local BT = {}

-- Node types
local Action = {}
function Action.new(name, func) return { type="action", name=name, func=func } end
function Action:execute(npc) return self.func(npc) end

local Condition = {}
function Condition.new(name, func) return { type="condition", name=name, func=func } end
function Condition:execute(npc) return self.func(npc) and "success" or "failure" end

local Selector = {}
function Selector.new(children) return { type="selector", children=children } end
function Selector:execute(npc)
    for _, child in ipairs(self.children) do
        if child:execute(npc) == "success" then
            return "success"
        end
    end
    return "failure"
end

local Sequence = {}
function Sequence.new(children) return { type="sequence", children=children } end
function Sequence:execute(npc)
    for _, child in ipairs(self.children) do
        if child:execute(npc) ~= "success" then
            return "failure"
        end
    end
    return "success"
end

-- Example: Guard behavior tree
local guard_bt = Selector.new({
    Sequence.new({
        Condition.new("PlayerVisible", function(npc) return npc:can_see_player() end),
        Action.new("Attack", function(npc) npc:attack_player() return "success" end)
    }),
    Sequence.new({
        Condition.new("HealthLow", function(npc) return npc.health < npc.max_health / 3 end),
        Action.new("Flee", function(npc) npc:flee() return "success" end)
    }),
    Action.new("Patrol", function(npc) npc:patrol() return "success" end)
})

function npc:tick()
    guard_bt:execute(self)
end
```

**Pros:**
- **Modular:** Trees can be visually edited and reused
- **Composable:** Subtrees are building blocks
- **Scalable:** Handles 30+ conditions/actions gracefully
- **Designer-friendly:** Non-programmers can tweak trees in visual editors (Unreal Blueprints, Unity visual BT tools)

**Cons:**
- **Overhead:** More complex than FSM for simple behaviors
- **Lack of memory:** Tree executes fresh each frame; limited state persistence
- **Debugging:** Tree execution can be hard to trace (what path did it take?)

---

## V. GOAP (Goal-Oriented Action Planning)

### A. Concept

GOAP is a **planning algorithm** that:
1. Defines *world state* (has_weapon, enemy_visible, low_health)
2. Defines *actions* with preconditions and effects
3. Takes a *goal* (eliminate_enemy, escape)
4. **Plans** a sequence of actions to reach goal

```lua
local GOAP = {}

-- World state
local world_state = {
    has_weapon = false,
    has_ammo = false,
    enemy_visible = false,
    low_health = false
}

-- Actions with preconditions and effects
local actions = {
    {
        name = "pickup_weapon",
        preconditions = { has_weapon = false },
        effects = { has_weapon = true },
        cost = 1
    },
    {
        name = "reload",
        preconditions = { has_weapon = true, has_ammo = false },
        effects = { has_ammo = true },
        cost = 1
    },
    {
        name = "shoot_enemy",
        preconditions = { has_weapon = true, has_ammo = true, enemy_visible = true },
        effects = { enemy_visible = false },
        cost = 1
    },
    {
        name = "hide",
        preconditions = {},
        effects = { low_health = false },  -- Hiding restores perspective
        cost = 2
    }
}

-- Goal: Defeat enemy
local goal = { enemy_visible = false }

-- Plan: Find lowest-cost action sequence from current state to goal
-- Result might be: [pickup_weapon, reload, shoot_enemy]
```

**Algorithm (simplified A*):**
1. Start with current world state
2. For each action whose preconditions match:
   - Apply action effects, creating new state
   - Recursively plan from new state toward goal
   - Track cost (sum of action costs)
3. Return lowest-cost path

### B. Advantages

- **Reactive:** Plan adapts as world state changes (if weapon drops, replans)
- **Goal-driven:** NPCs pursue meaningful objectives, not just react to triggers
- **Emergent:** Multiple valid plans exist; NPC can choose different paths

**Example:** If weapon unavailable, NPC might flee instead of shoot.

### C. Disadvantages

- **Computational cost:** Planning on every update is expensive (mitigate via caching, limiting plan depth)
- **Debugging:** Hard to understand why NPC chose a suboptimal plan
- **State representation:** Defining world state and action preconditions requires careful design

---

## VI. Utility AI

### A. Concept

Utility AI scores each possible action based on utility functions:

```lua
local UtilityAI = {}

function UtilityAI:evaluate_action(action, npc)
    local utility = 0
    
    -- Base utility
    if action == "attack" then
        utility = 50 + (npc.aggression * 10)
        -- Increase if enemy is close
        if npc:distance_to_player() < 5 then utility = utility + 30 end
    elseif action == "flee" then
        utility = 10 + (npc.fear * 20)
        -- Increase if health is low
        if npc.health < npc.max_health / 2 then utility = utility + 40 end
    elseif action == "heal" then
        utility = (1 - npc.health / npc.max_health) * 100  -- Higher utility when damaged
    elseif action == "idle" then
        utility = 20  -- Default fallback
    end
    
    return utility
end

function npc:decide_action()
    local best_action = nil
    local best_utility = -math.huge
    
    for _, action in ipairs(self.available_actions) do
        local utility = self:evaluate_action(action, self)
        if utility > best_utility then
            best_utility = utility
            best_action = action
        end
    end
    
    self:perform_action(best_action)
end
```

**Why It's Intuitive:**
- Each action has a *numeric score*
- NPC picks highest-scoring action
- Easy to tune by adjusting coefficients

**Advantages:**
- Responsive (recalculates every frame based on current state)
- Scalable (add new actions by adding score functions)
- Intuitive tuning (adjust weights until behavior feels right)

**Disadvantages:**
- **Curve tuning is art, not science:** Balancing utility functions requires playtesting
- **Can feel random:** Two actions with similar utility → unpredictable choice (mitigate with randomization)
- **Short-term:** Doesn't plan ahead; only considers immediate best action

---

## VII. Comparison & Synthesis

| Aspect | FSM | BT | GOAP | Utility |
|--------|-----|----|----|---------|
| **Learning Curve** | Easy | Medium | Hard | Medium |
| **Scalability** | Poor | Good | Fair | Good |
| **Reactivity** | Slow (state-locked) | Medium | High (replans) | High (recalculates) |
| **Predictability** | High (deterministic) | Medium | Low (emergent) | Medium |
| **Planning Depth** | None | None | Deep (A* search) | None (immediate) |
| **Composability** | Low | High | Low | Low |
| **Debugging** | Easy | Medium | Hard | Medium |

**Recommendation for MMO:**
1. **Core FSM:** Use HFSM for broad state (in_combat, peaceful, fleeing)
2. **Sub-behaviors:** Use Behavior Trees or Utility AI for decisions within state
3. **Goal Planning:** Optional GOAP layer for quests/objectives (e.g., "fetch ingredient from dungeon")
4. **Fallback:** Simple rule-based actions (wander, rest, eat)

---

## VIII. Architectural Patterns: Tick-Based, Event-Driven, Actor Model

### A. Tick-Based Updates

**Model:** Global game loop calls `npc:tick()` for all NPCs each frame.

```lua
-- main.lua
function game_loop()
    for frame = 1, 1000000 do
        for _, npc in ipairs(world.npcs) do
            npc:tick()  -- Update NPC behavior
        end
        game:render()
    end
end
```

**Pros:**
- Deterministic (same input → same output)
- Efficient (batch updates)
- Debuggable (step through ticks)

**Cons:**
- All NPCs update every tick, even if far away
- Hard to handle variable-rate events

### B. Event-Driven Updates

**Model:** NPCs register for events; update only when events occur.

```lua
-- NPC registers interest in "player_enter_room"
npc:on_event("player_enter_room", function(player)
    npc:alert(player)
end)

-- When player enters room:
room:emit_event("player_enter_room", player)
```

**Pros:**
- Efficient (no wasted updates)
- Natural for reactive behavior (event triggers action)

**Cons:**
- Non-deterministic (event order matters)
- Complex debugging (hard to trace causal chain)
- Potential event storms (one event triggers many others)

### C. Actor Model

**Model:** Each NPC is an autonomous agent; communication via message passing.

```lua
-- NPC receives messages (mailbox)
function npc:receive_message(from, msg)
    if msg.type == "attack" then
        self:defend()
        self:send_message(from, { type = "counterattack" })
    end
end

function npc:send_message(to, msg)
    to:receive_message(self, msg)
end
```

**Pros:**
- Scalable (message-based concurrency)
- Safe (no shared mutable state)
- Natural for multiplayer

**Cons:**
- Complexity (message buffering, ordering)
- Latency (messages travel through queue)

### D. Hybrid Approach (Recommended)

Combine **tick-based + event-driven + actor model**:

1. **Tick-based:** Global frame updates NPC state (every 100ms for distant NPCs, every 10ms for nearby)
2. **Event-driven:** Significant events (player entered, NPC died) trigger immediate updates
3. **Actor model:** NPCs send messages to each other (e.g., "help me, I'm in danger")

```lua
function game:tick(dt)
    -- Batch update nearby NPCs every tick
    for _, npc in ipairs(world:get_nearby_npcs(player, 50)) do
        npc:update(dt)
    end
    
    -- Event-driven: handle queued events
    while #world.event_queue > 0 do
        local event = table.remove(world.event_queue, 1)
        world:dispatch_event(event)
    end
end

-- When player kills enemy, fire event
function player:kill(enemy)
    local allies = world:get_allies(enemy)
    for _, ally in ipairs(allies) do
        world:emit_event("ally_died", { victim = enemy, killer = player })
        -- Ally receives event and might seek revenge
        ally:receive_message("revenge_target", player)
    end
end
```

---

## IX. Memory & Knowledge Representation

### A. What NPCs Know

NPCs should track:

1. **Spatial awareness:**
   - Which rooms/areas they've been to
   - Where allies/enemies were last seen
   - Safe vs. dangerous areas

2. **Relational knowledge:**
   - Who is friendly/hostile
   - Kin, friends, rivals
   - Faction allegiances

3. **Factual knowledge:**
   - Skills/professions (Smithy is a blacksmith)
   - Objects/items locations (where to find food, weapons)
   - Quest facts (kill 10 rats, retrieve artifact)

4. **Procedural knowledge:**
   - How to complete tasks (recipe for healing potion)
   - How to reach locations (path to dungeon)
   - Combat tactics (when to flee, when to attack)

### B. Memory Implementation

```lua
local NPC_Memory = {}

function NPC_Memory:new()
    return {
        spatial = {},  -- {location_name => last_visited_time}
        relationships = {},  -- {npc_id => {type, strength, history}}
        facts = {},  -- {fact_key => value, timestamp}
        procedures = {},  -- {task => steps}
        events = {}  -- Circular buffer of recent events
    }
end

function NPC_Memory:remember(fact_key, value)
    self.facts[fact_key] = { value = value, timestamp = os.time() }
end

function NPC_Memory:recall(fact_key, max_age)
    local fact = self.facts[fact_key]
    if fact and (os.time() - fact.timestamp) < max_age then
        return fact.value
    end
    return nil
end

-- Use in dialogue:
function npc:respond_to_greeting(player)
    if self.memory:recall("player_name", 86400) then  -- Remember for 24h
        return "Hello, " .. player.name .. "!"
    else
        return "Hello, stranger."
    end
end
```

---

## X. Stack-Based Behavior: Interrupt Handling

### A. Priority System

Some behaviors should interrupt others:

```lua
local NPC_Priority = {}

function npc:update()
    local top_priority = self:get_top_priority()
    
    if top_priority == "flee" then
        self:flee()
    elseif top_priority == "combat" then
        self:fight()
    elseif top_priority == "task" then
        self:work()
    elseif top_priority == "idle" then
        self:idle()
    end
end

function npc:get_top_priority()
    if self:is_dying() then return "flee" end
    if self:is_in_combat() then return "combat" end
    if self:has_task() then return "task" end
    return "idle"
end

function npc:interrupt(new_priority)
    -- Save current task
    self.interrupted_task = self.current_task
    -- Switch to interrupt
    self.current_priority = new_priority
end

function npc:resume()
    -- Restore previous task
    if self.interrupted_task then
        self.current_task = self.interrupted_task
        self.interrupted_task = nil
    end
end
```

---

## XI. Blackboard Architecture: Shared State

Multiple NPCs coordinate via shared **blackboard**:

```lua
local Blackboard = {}

function Blackboard:new()
    return {
        tasks = {},  -- {task_id => {assignee, status, priority}}
        observations = {},  -- {observer => [events]}
        squad_state = {}  -- {squad_id => {objective, members}}
    }
end

function Blackboard:claim_task(npc, task_id)
    if not self.tasks[task_id].assignee then
        self.tasks[task_id].assignee = npc.id
        return true
    end
    return false
end

function Blackboard:post_observation(observer, event)
    table.insert(self.observations[observer], event)
    -- Other NPCs can query observations
end

-- Guards coordinate via blackboard
function guards:coordinate()
    for _, guard in ipairs(squad.members) do
        if blackboard:claim_task(guard, "guard_north_gate") then
            guard:move_to("north_gate")
            break
        end
    end
end
```

---

## XII. Recommendations for MMO

### Given Lua FSM Object System

1. **Use Hierarchical FSM** for state (most compatible with existing object model)
2. **Add Utility AI layer** for action selection within states
3. **Optional GOAP** for quests (e.g., "find ingredient" → A* plan through dungeon)
4. **Tick-based updates** (NPC:tick() every 100ms for distant, 10ms for nearby)
5. **Event-driven augmentation** for significant changes (combat, death, meeting player)
6. **Blackboard** for squad coordination (if multiplayer emergent combat)

### Example: Guard NPC

```lua
local Guard = inherit(NPC)

-- States
Guard.fsm = {
    awake = { idle = {}, patrol = {} },
    combat = { attacking = {}, defending = {}, fleeing = {} },
    sleep = {}
}

function Guard:tick()
    -- Update state machine
    self:update_fsm()
    
    -- Within state, use utility AI for action selection
    local action_utilities = {
        attack = self:calculate_attack_utility(),
        defend = self:calculate_defend_utility(),
        flee = self:calculate_flee_utility()
    }
    
    local best_action = self:get_best_action(action_utilities)
    best_action()
end

function Guard:calculate_attack_utility()
    local utility = 50
    utility = utility + (self.aggression * 10)
    if self:distance_to_player() < 5 then utility = utility + 30 end
    return utility
end

function Guard:hear_player(text)
    local response = dialogue_engine:generate_response(text, self:get_context())
    return response
end
```

---

## References

- Game Programming Patterns: https://gameprogrammingpatterns.com/
- Behavior Trees: https://www.gamedeveloper.com/programming/behavior-trees-for-ai-decision-making
- GOAP: https://www.gamedeveloper.com/design/building-the-ai-of-f-e-a-r-with-goal-oriented-action-planning
- Utility AI: https://tonogameconsultants.com/game-ai-planning/

---

**Next:** Read `academic-research.md` for current research and LLM approaches.
