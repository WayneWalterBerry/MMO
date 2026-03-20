# Intelligent Parser: Goal-Oriented Natural Language Understanding

**Version:** 1.0  
**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-25  
**Status:** Design Complete  
**Related Decisions:** D-19 (Parser approach), LLM-SLM Parser Plan  

---

## EXECUTIVE SUMMARY

Players expect LLM-era natural language input: **"Get a match from the matchbox and light the candle"** should work end-to-end without the player spelling out each atomic step. Today's parser is verb+noun→single action. The next generation must infer action chains, resolve prerequisites, and handle contextual knowledge.

This design document lays out a **five-layer architecture** for goal-oriented parsing:

1. **Intent Recognition** — Extract the player's GOAL, not just the verb
2. **Action Chain Inference** — Decompose goals into atomic, ordered steps
3. **Prerequisite Resolution** — Auto-handle obvious prerequisites (open closed containers, etc.)
4. **Context Window** — Track player knowledge and inventory state
5. **Prepositional Intelligence** — Parse relationships as explicit declarations

We also evaluate **SLM Integration** as a Tier 3 fallback for decomposition that deterministic rules can't handle.

This design **assumes successful Tier 1 + Tier 2** embedding parser. The intelligent parser is Tier 3 opportunity.

---

## 1. INTENT RECOGNITION

### Problem

Current parser:
```
INPUT: "light the candle with a match"
PARSE: verb=light, object=candle, tool=match
ACTION: Execute LIGHT candle WITH match (single action)
```

But the player's **intent** is: "I want the candle to be lit." This requires prerequisites the engine must infer.

### Solution: Goal-State Decomposition

**Define intent as: (goal_state, required_tool, preconditions)**

#### Example 1: "Light the candle with a match"
```
INPUT: "light the candle with a match"

INTENT LAYER:
  goal_state: candle.lit == true
  verb: LIGHT
  target_object: candle
  tool_declared: match
  
PRECONDITIONS DISCOVERED:
  - Player must have match in inventory
  - Match must be lit (or be a fire_source)
  - If match is not lit, must be struckable
```

#### Example 2: "Get a match from the matchbox and light the candle"
```
INPUT: "Get a match from the matchbox and light the candle"

INTENT LAYER (Two goals detected):
  goal_1: player.inventory contains match
  goal_2: candle.lit == true
  
SEQUENCING:
  1. Take match from matchbox → goal_1 satisfied
  2. Strike match (if needed) → match becomes fire_source
  3. Light candle with match → goal_2 satisfied
```

#### Example 3: "Light the candle" (minimal input, maximum context)
```
INPUT: "light the candle"
CONTEXT: Player recently examined matchbox, knows it contains matches

INTENT LAYER:
  goal_state: candle.lit == true
  verb: LIGHT
  target_object: candle
  tool_declared: (none, but context suggests match)
  
INFERRED TOOL: match (from recent context)

PRECONDITIONS:
  - Player must have match (infer: GET from matchbox first)
  - Match must be fire_source (infer: STRIKE if needed)
```

### Implementation: Intent Classifier

```lua
-- Pseudocode
function classify_intent(player_input, context, game_state)
  -- 1. Parse primary verb
  verb, target, tool, source = parse_verb_noun_tool_source(player_input)
  
  -- 2. Look up goal state for this verb
  goal_template = VERB_GOAL_MAP[verb]
  -- e.g., VERB_GOAL_MAP["light"] = function(target) 
  --   return { property: "casts_light", value: true, object: target }
  -- end
  
  -- 3. Extract declared preconditions from input
  preconditions = parse_preconditions(player_input, verb, target, tool)
  -- e.g., "from matchbox" → { source_container: matchbox }
  -- e.g., "with match" → { tool: match }
  
  -- 4. Infer missing prerequisites from context
  inferred = infer_missing_prerequisites(
    verb, target, tool, context, game_state
  )
  
  return {
    verb = verb,
    target = target,
    tool = tool,
    goal_state = goal_template(target),
    declared_preconditions = preconditions,
    inferred_preconditions = inferred
  }
end
```

### Verb → Goal Mapping

Each verb maps to a goal state:

| Verb | Goal State | Example |
|------|-----------|---------|
| LIGHT | `target.casts_light == true` | Light the candle → candle casts light |
| OPEN | `target.is_open == true` | Open the door → door is open |
| CLOSE | `target.is_open == false` | Close the drawer → drawer is closed |
| TAKE | `target.location == player.inventory` | Take the match → match in inventory |
| DROP | `target.location == current_room` | Drop the candle → candle on floor |
| WEAR | `target in player.worn_slots` | Wear the cloak → cloak is worn |
| WRITE | `written_object exists with target.written_text` | Write on paper → paper has writing |

---

## 2. ACTION CHAIN INFERENCE

### Problem

**Goal:** Player holds a match from a closed matchbox.  
**Current State:** Player has no items, matchbox is closed.  
**Expected:** Get match from matchbox.

**What happens:**
1. Player types: "get match from matchbox"
2. Current parser: TAKE match (fails — matchbox is closed, match not visible)
3. Error: "I don't see that here."

**What should happen:**
1. Intent: Take match from matchbox
2. Engine infers: Matchbox is closed, so step 1 = "open matchbox"
3. Action chain: OPEN matchbox → TAKE match
4. Execute chain in order, report success/failure per step

### Solution: Goal-Oriented Planning

Given a goal and current game state, decompose into atomic actions.

#### Algorithm: Backward-Chaining Plan Search

```
GOAL: Take match from matchbox
STATE: matchbox.closed == true, match.location == matchbox

PLAN(goal, state):
  1. Check if goal already satisfied in state → RETURN [success]
  2. Find applicable verb that achieves goal
     e.g., TAKE match applies if match is in current_room or inventory
  3. Check preconditions for TAKE:
     - match must be in scope (visible, in container, in inventory)
     - if in closed container → precondition failed
  4. Add OPEN matchbox to plan
     - Recurse: PLAN(open matchbox, state)
  5. Return: [OPEN matchbox, TAKE match]
```

#### Example Trace: "Light the candle with a match"

```
GOAL: candle.casts_light == true
STATE: {
  player.inventory: [],
  matchbox.location: nightstand,
  matchbox.is_open: false,
  match.location: matchbox,
  candle.location: current_room,
  candle.casts_light: false
}

PLANNER OUTPUT:
  Step 1: TAKE matchbox (prerequisite for accessing match)
    - Precondition: matchbox must be in scope
    - Check: matchbox.location == nightstand, player is in same room ✓
    - Action: TAKE matchbox → player.inventory.add(matchbox)
    
  Step 2: OPEN matchbox
    - Precondition: matchbox must be in inventory/scope
    - Check: matchbox now in inventory ✓
    - Action: OPEN matchbox → matchbox.is_open = true
    
  Step 3: TAKE match
    - Precondition: match in accessible container
    - Check: match.location == matchbox, matchbox.is_open == true ✓
    - Action: TAKE match → player.inventory.add(match)
    
  Step 4: STRIKE match (inferred: match is not a fire_source yet)
    - Precondition: match in inventory, matchbox accessible for striking
    - Check: match in inventory ✓, matchbox in inventory ✓
    - Action: STRIKE match ON matchbox → match-lit object created
    
  Step 5: LIGHT candle WITH match-lit
    - Precondition: candle in scope, fire_source in inventory
    - Check: candle in room ✓, match-lit in inventory ✓
    - Action: LIGHT candle → candle.casts_light = true

PLAN: [TAKE matchbox, OPEN matchbox, TAKE match, STRIKE match, LIGHT candle]
```

### Implementation: Backward-Chaining Planner

```lua
-- Pseudocode
function plan_action_chain(goal, current_state, game_state, depth=0)
  MAX_DEPTH = 8  -- Prevent infinite loops
  
  if depth > MAX_DEPTH then
    return { error = "Plan too deep" }
  end
  
  -- Base case: Goal already satisfied
  if goal_satisfied(goal, current_state) then
    return { success = true, plan = [] }
  end
  
  -- Find verbs that could achieve this goal
  applicable_verbs = find_verbs_for_goal(goal)
  
  for each verb in applicable_verbs do
    -- Check preconditions
    preconditions = get_preconditions(verb, goal.target, current_state)
    
    if preconditions.all_satisfied then
      -- Direct path
      plan = [{ verb = verb, target = goal.target, tool = goal.tool }]
      return { success = true, plan = plan }
    else
      -- Recursively plan for failed preconditions
      sub_plans = {}
      for each precondition in preconditions.unsatisfied do
        sub_goal = precondition_to_goal(precondition, current_state)
        sub_result = plan_action_chain(sub_goal, current_state, game_state, depth + 1)
        
        if sub_result.error then
          -- This verb branch failed, try next verb
          continue
        end
        
        sub_plans.append(sub_result.plan)
        -- Apply sub-plan to state for next precondition
        current_state = apply_plan(current_state, sub_result.plan)
      end
      
      -- All preconditions satisfied via sub-plans
      if sub_plans.all_succeeded then
        full_plan = flatten(sub_plans) + [verb]
        return { success = true, plan = full_plan }
      end
    end
  end
  
  return { error = "No plan found" }
end
```

### Precondition Types

#### Physical Preconditions
- **Visibility:** Object in scope (in room, in open container, in inventory)
- **Accessibility:** Container is open, locked door is unlocked
- **Inventory space:** Hands available for two-handed objects

#### State Preconditions
- **Object state:** Match must be unlit before striking, container must be closed before opening
- **Capability:** Tool must provide required capability

#### Relational Preconditions
- **Containment:** Object A must contain object B for "put X in Y"
- **Proximity:** Player in same room as target

---

## 3. PREREQUISITE RESOLUTION

### Problem: The "Hidden" Prerequisites

Player: "I want to light the candle."  
Engine: "You don't see a match."  
Player: "Ugh, why didn't you tell me I need a match?"

### Solution: Anticipatory Precondition Analysis

Before failing, check: "Can the player obtain the missing prerequisites?" If yes, offer auto-resolution.

#### Example 1: Missing Tool Detection

```
GOAL: Light candle
CHECKING: Verb LIGHT requires tool = fire_source
FINDING: No fire_source in inventory

DISCOVERY:
  - Match is fire_source (when lit)
  - Match is in matchbox on nightstand
  - Matchbox is accessible
  - Player can execute: [TAKE matchbox, OPEN, TAKE match, STRIKE, LIGHT]

OPTIONS:
  A) Auto-execute the plan (if confidence > threshold)
  B) Prompt: "Do you want me to get a match and light the candle?"
  C) Fail with hint: "To light the candle, you'll need a fire source like a match."
```

#### Example 2: Locked Container

```
GOAL: Take scroll from chest
STATUS: Chest is locked, player has key in inventory

DISCOVERY:
  - Chest locked, needs key
  - Player has brass key in inventory
  - Brass key fits chest (from recent context/metadata)

RESOLUTION:
  - Auto-execute: OPEN chest WITH key (implied)
  - Then: TAKE scroll
```

#### Example 3: Closed But Unlocked

```
GOAL: Take match from matchbox
STATUS: Matchbox is closed

DISCOVERY:
  - Matchbox can be opened (not locked)
  - Opening has no cost/risk
  - Player has matchbox in inventory

RESOLUTION:
  - Auto-execute: OPEN matchbox
  - Then: TAKE match
```

### Implementation: Prerequisite Anticipation

```lua
function resolve_prerequisites(goal, current_state, game_state)
  unsatisfied = find_unsatisfied_preconditions(goal, current_state)
  
  for each precondition in unsatisfied do
    if is_auto_resolvable(precondition, current_state, game_state) then
      -- Cases:
      -- 1. Tool in inventory but not equipped → equip it
      -- 2. Container closed but unlocked → open it
      -- 3. Tool available in nearby container → take it
      
      resolution = get_auto_resolution(precondition, current_state, game_state)
      
      if resolution.confidence > AUTO_RESOLVE_THRESHOLD (0.8) then
        -- Execute resolution automatically
        execute_action(resolution.action, current_state, game_state)
      else
        -- Prompt player
        return {
          type = "confirm",
          message = resolution.prompt,
          action = resolution.action
        }
      end
    else
      -- Cannot auto-resolve (missing item, locked door without key, etc.)
      return {
        type = "fail",
        message = build_helpful_error(precondition, game_state)
      }
    end
  end
  
  return { success = true }
end
```

### Auto-Resolvable Preconditions

| Precondition | Auto-Resolvable? | Rationale |
|--------------|-----------------|-----------|
| Tool in inventory (not held) | ✓ Yes | Zero cost, obvious intent |
| Container closed (not locked) | ✓ Yes | Zero cost, reversible, obvious next step |
| Key in inventory for locked door | ✓ Yes (if recent context) | High confidence player intends to use it |
| Tool in nearby visible container | ~ Maybe | Depends on container access (open/closed), confidence > 0.6 prompts |
| Tool available but far away | ✗ No | Requires navigation, too speculative |
| Tool never seen before | ✗ No | Player doesn't know it exists |
| Locked container without key | ✗ No | Missing critical resource |
| Two-handed object with one hand free | ✗ No (but should prompt) | Inventory constraint, player choice |

---

## 4. CONTEXT WINDOW

### Problem: Commands Become Clearer With History

```
SEQUENCE 1:
  Player: "examine matchbox"
  Engine: "A wooden box with 7 matches inside."
  
  Player: "light the candle"
  Engine: "I don't see a match."  ← Missing context!
  
SEQUENCE 2 (WITH CONTEXT):
  Player: "examine matchbox"
  Engine: "A wooden box with 7 matches inside."
  [CONTEXT: Player knows matchbox contains matches]
  
  Player: "light the candle"
  Engine: "Getting a match from the matchbox first..."
  [Uses context to infer match source]
```

### Solution: Short-Term Memory Window

Maintain a **context window of recent player actions and discoveries**.

#### Context Categories

```lua
context = {
  recent_commands = [
    { verb = "examine", object = "matchbox", tick = 5 },
    { verb = "examine", object = "candle", tick = 4 }
  ],
  
  discovered_objects = {
    matchbox = {
      examined_at_tick = 5,
      contents = ["match", "match", "match"],
      properties = { is_container = true, is_open = false }
    }
  },
  
  player_knowledge = {
    "match is in matchbox",
    "matchbox is in bedroom",
    "candle is on desk"
  },
  
  recent_locations = [
    { room = "bedroom", tick = 10 },
    { room = "hallway", tick = 9 }
  ],
  
  inventory_at_tick = {
    10: ["torch", "key"],
    9: ["torch", "key"],
    8: ["key"]
  }
}
```

#### Usage: Infer Tool from Context

```lua
function find_tool_for_goal(goal, context, game_state)
  -- Goal: light candle (requires fire_source)
  
  -- Check 1: Player inventory has fire_source
  fire_sources_in_inventory = filter_by_capability(
    player.inventory, 
    "provides_tool", 
    "fire_source"
  )
  if fire_sources_in_inventory.count > 0 then
    return fire_sources_in_inventory[0]
  end
  
  -- Check 2: Recently discovered fire_sources
  recent_discoveries = get_recent_discoveries(context, max_ticks_ago = 20)
  fire_sources_discovered = filter_by_capability(
    recent_discoveries,
    "provides_tool",
    "fire_source"
  )
  if fire_sources_discovered.count > 0 then
    -- Assume player remembers where it is
    return fire_sources_discovered[0]
  end
  
  -- Check 3: Fire sources in nearby containers
  containers_in_room = get_containers_in_current_room(player, game_state)
  for each container in containers_in_room do
    fire_sources_in_container = filter_by_capability(
      get_container_contents(container),
      "provides_tool",
      "fire_source"
    )
    if fire_sources_in_container.count > 0 then
      -- Confidence depends on:
      -- - How recently was this container examined?
      -- - Is container open or closed?
      confidence = calculate_confidence(container, context)
      
      if confidence > 0.6 then
        return {
          object = fire_sources_in_container[0],
          source_container = container,
          confidence = confidence
        }
      end
    end
  end
  
  return { error = "No fire source found" }
end
```

#### Context Aging

Older discoveries fade in confidence:

```lua
function calculate_confidence(object, context)
  current_tick = game_state.tick
  last_seen_tick = get_last_seen_tick(object, context)
  ticks_ago = current_tick - last_seen_tick
  
  -- Recent (0-5 ticks ago): high confidence
  if ticks_ago <= 5 then return 0.95 end
  
  -- Recently (5-20 ticks ago): medium-high confidence
  if ticks_ago <= 20 then return 0.80 end
  
  -- Somewhat recent (20-50 ticks ago): medium confidence
  if ticks_ago <= 50 then return 0.60 end
  
  -- Old (50+ ticks ago): low confidence (fade)
  return max(0.30, 1.0 - (ticks_ago - 50) / 100.0)
end
```

### Implementation: Context Manager

```lua
ContextManager = {
  MAX_WINDOW_TICKS = 100,
  MAX_RECENT_COMMANDS = 20,
  
  update = function(self, action, game_state)
    -- Record command
    table.insert(self.recent_commands, {
      verb = action.verb,
      object = action.target,
      tick = game_state.tick
    })
    
    -- Keep window bounded
    if #self.recent_commands > self.MAX_RECENT_COMMANDS then
      table.remove(self.recent_commands, 1)
    end
    
    -- Record discovery if applicable
    if action.verb == "examine" or action.verb == "feel" then
      self:record_discovery(action.target, game_state)
    end
  end,
  
  record_discovery = function(self, object, game_state)
    self.discovered_objects[object.id] = {
      examined_at_tick = game_state.tick,
      properties = extract_properties(object),
      contents = object.contents or {}
    }
  end
}
```

---

## 5. PREPOSITIONAL INTELLIGENCE

### Problem: Relationships Hidden in Grammar

```
INPUT: "light the candle with a match"
PARSED: verb=light, object=candle
MISSING: Tool is in the preposition "with"!

INPUT: "take the match from the matchbox"
PARSED: verb=take, object=match
MISSING: Source container is in the preposition "from"!

INPUT: "put the candle on the desk"
PARSED: verb=put, object=candle
MISSING: Target location is in the preposition "on"!
```

### Solution: Relationship Extraction

Prepositions encode **relationships** that are essential to action execution.

#### Prepositional Roles

| Preposition | Role | Example | Semantic |
|-------------|------|---------|----------|
| **with** | Tool/instrument | "light with match" | `action.tool = match` |
| **from** | Source container/location | "take from matchbox" | `action.source = matchbox` |
| **on** | Target surface/body part | "put on desk" | `action.surface = desk` OR `action.worn_slot = head` |
| **in** | Target container | "put in chest" | `action.container = chest` |
| **to** | Destination/recipient | "give to player" | `action.recipient = player` |
| **at** | Direction/location | "look at object" | `action.target = object` |
| **into** | Destination container | "jump into pool" | `action.container = pool` |
| **over** | Obstacle/barrier | "jump over fence" | `action.obstacle = fence` |
| **under** | Hidden location | "put under bed" | `action.location = under_bed` |
| **before/after** | Ordering | "do this before that" | Sequencing constraint |

#### Parsing Strategy

```lua
function parse_relationships(input, verb, target)
  relationships = {}
  
  -- Pattern 1: "verb target with OBJECT"
  if input:match("with%s+(%w+)") then
    tool_noun = input:match("with%s+(%w+)")
    relationships.tool = resolve_noun(tool_noun)
  end
  
  -- Pattern 2: "verb OBJECT from CONTAINER"
  if input:match("from%s+(%w+)") then
    source_noun = input:match("from%s+(%w+)")
    relationships.source = resolve_noun(source_noun)
  end
  
  -- Pattern 3: "verb OBJECT on SURFACE"
  if input:match("on%s+(%w+)") then
    surface_noun = input:match("on%s+(%w+)")
    relationships.surface = resolve_noun(surface_noun)
  end
  
  -- Pattern 4: "verb OBJECT in CONTAINER"
  if input:match("in%s+(%w+)") then
    container_noun = input:match("in%s+(%w+)")
    relationships.container = resolve_noun(container_noun)
  end
  
  return relationships
end
```

#### Example Trace

```
INPUT: "Get a match from the matchbox and light the candle"

TOKENIZE: ["get", "a", "match", "from", "the", "matchbox", "and", "light", "the", "candle"]

GOAL 1: get match
  verb: GET
  target: match
  relationships: { source: matchbox }
  
GOAL 2: light candle
  verb: LIGHT
  target: candle
  relationships: {} (no tool specified, will infer from context)
  
PLANNING:
  Goal 1: Get match from matchbox
    - Check: matchbox.location == current_room ✓
    - Check: matchbox.is_open == false (precondition: open it)
    - Plan: [OPEN matchbox, TAKE match]
    
  Goal 2: Light candle
    - Check: candle.location == current_room ✓
    - Check: player has fire_source (will be true after Goal 1 → STRIKE match)
    - Plan: [LIGHT candle]
    
FINAL CHAIN: [OPEN matchbox, TAKE match, STRIKE match, LIGHT candle]
```

---

## 6. SLM INTEGRATION OPPORTUNITY

### Current Architecture: Three-Tier Parser

```
Tier 1: Exact verb dispatch (70% of inputs)
  ↓ (miss)
Tier 2: Embedding phrase similarity (20% of inputs)
  ↓ (miss)
Tier 3: ???
```

**Tier 3 decision: Rule-based decomposition vs. SLM?**

### Option A: Deterministic Rule-Based Decomposition

Use the five layers above (intent recognition, action chaining, prerequisites, context, prepositions) entirely through hand-written rules.

**Pros:**
- Predictable, debuggable behavior
- Fast (no inference, just rule matching)
- Transparent (designer controls all logic)
- Suitable for mobile (no model download)

**Cons:**
- Brittle: New verb patterns require code changes
- Limited to known patterns
- Doesn't handle novel phrasings gracefully

### Option B: SLM-Based Goal Decomposition

For inputs that deterministic rules can't parse, fall back to a **small language model (SLM)** running on-device to decompose goals into action chains.

#### SLM Candidate: Qwen2.5-0.5B

- **Size:** ~350MB (ONNX quantized, still large)
- **Latency:** 200–500ms per inference (slower than Tier 2)
- **Accuracy:** High-quality semantic understanding
- **Training:** Fine-tune on (goal_text, game_state) → action_chain pairs

#### Example: SLM-Powered Decomposition

```
INPUT: "I want to escape this room"
TIER 1: No exact match
TIER 2: Embedding similarity < 0.5 (no direct phrase match)

TIER 3 (SLM):
  Input to SLM:
    {
      "goal": "I want to escape this room",
      "game_state": {
        "current_room": "bedroom",
        "inventory": ["key"],
        "room_objects": ["door", "window", "rug"],
        "room_exits": ["north_door (locked)"]
      }
    }
  
  SLM Output:
    {
      "goals": [
        { "type": "unlock", "target": "north_door", "tool": "key" },
        { "type": "go", "direction": "north" }
      ],
      "action_chain": ["OPEN door WITH key", "GO north"]
    }
```

#### Trade-Offs

| Aspect | Rule-Based | SLM |
|--------|-----------|-----|
| **Speed** | <50ms | 200–500ms |
| **Size** | 0MB | 350MB (download cost) |
| **Debuggability** | Excellent | Poor (black box) |
| **Flexibility** | Limited | High (generalizes) |
| **Coverage** | ~95% of common patterns | ~99% (including novel) |
| **Cost** | One-time design effort | Training cost, inference cost |
| **Mobile** | Yes (trivial) | Maybe (large model, slow) |

### Recommendation: Hybrid Approach

**Phase 1 (Now):** Rule-based deterministic decomposition.
- Covers 95%+ of gameplay patterns
- Fast, transparent, mobile-friendly
- Authors can understand and modify

**Phase 2 (Optional):** Add SLM as Tier 3 fallback.
- Only invoke if deterministic rules fail AND confidence < threshold
- Use for learning: collect Tier 3 failures, fine-tune SLM training data
- Ship SLM optional (feature flag or Progressive Web App secondary tier)

**Key Decision:** If SLM is shipped, make it **optional and downloadable**, not mandatory on first load. Progressive enhancement model:
- MVP: Tier 1 + Tier 2 + deterministic Tier 3
- Enhanced (Progressive Web App, optional): + SLM Tier 3 for advanced parsing

---

## 7. EXAMPLE SCENARIOS

### Scenario 1: Basic Two-Step Goal

```
INPUT: "Get a match from the matchbox and light the candle"

PARSING:
  - Detect conjunction "and" → two goals
  - Goal 1: Get match from matchbox
  - Goal 2: Light the candle

INTENT RECOGNITION:
  Goal 1:
    verb: GET (TAKE)
    target: match
    source_container: matchbox
    goal_state: match in player.inventory
    
  Goal 2:
    verb: LIGHT
    target: candle
    goal_state: candle.casts_light == true

ACTION CHAIN INFERENCE:
  Goal 1 Chain:
    1. TAKE matchbox (matchbox must be in player possession)
    2. OPEN matchbox (matchbox must be open to access contents)
    3. TAKE match (prerequisite satisfied, match now in inventory)
    
  Goal 2 Chain:
    1. STRIKE match (match must be lit first)
       - Prerequisite: match in inventory ✓ (from Goal 1)
       - Prerequisite: matchbox accessible ✓ (in inventory from Goal 1)
    2. LIGHT candle (with match as fire_source)

EXECUTION:
  [TAKE matchbox, OPEN matchbox, TAKE match, STRIKE match, LIGHT candle]

OUTPUT MESSAGES:
  "You take the matchbox and set it on the nightstand. You open it carefully, revealing seven matches. You take one. You strike it against the box—bright light flares. You touch the flame to the candle wick. The wax catches fire, and warm light fills the room."
```

### Scenario 2: Contextual Tool Inference

```
INPUT: "Light the candle"

CONTEXT WINDOW:
  recent_commands: [
    { verb: "examine", object: "matchbox", tick: 3 }
  ]
  discovered_objects: {
    matchbox: { contents: ["match", "match", "match"], is_open: false }
  }

INTENT RECOGNITION:
  verb: LIGHT
  target: candle
  goal_state: candle.casts_light == true
  tool_declared: (none)

CONTEXT-BASED TOOL INFERENCE:
  - Player recently examined matchbox
  - Player knows matchbox contains matches
  - Match is a fire_source when lit
  - Confidence: 0.85 (recent, explicit discovery)
  → Inferred tool: match from matchbox

ACTION CHAIN INFERENCE:
  1. TAKE matchbox (prerequisite: in inventory)
  2. OPEN matchbox (prerequisite: open)
  3. TAKE match (prerequisite: in inventory)
  4. STRIKE match (prerequisite: fire_source)
  5. LIGHT candle

PREREQUISITE RESOLUTION:
  - Matchbox not in inventory → AUTO-RESOLVE: Take it
  - Matchbox closed → AUTO-RESOLVE: Open it
  - Match needs striking → AUTO-RESOLVE: Strike on matchbox (already has it)

EXECUTION: [TAKE matchbox, OPEN matchbox, TAKE match, STRIKE match, LIGHT candle]

OUTPUT: "You take the matchbox from the nightstand and open it. You take a match and strike it—it flares to life. You touch the flame to the candle. The wax catches fire."
```

### Scenario 3: Implicit Prerequisite (Locked Door)

```
INPUT: "Unlock the door"

GAME STATE:
  - Door is locked, requires brass key
  - Player has brass key in inventory (recently found)
  - Context: Player obtained brass key 15 ticks ago (confidence: 0.8)

INTENT RECOGNITION:
  verb: OPEN / UNLOCK
  target: door
  goal_state: door.is_locked == false

PREREQUISITE ANALYSIS:
  - Door is locked, requires key
  - Check inventory: brass key present ✓
  - Check recent discoveries: brass key recently found ✓
  - Confidence: 0.95 (recent, obvious intent)

AUTO-RESOLUTION:
  "You use the brass key to unlock the door. The lock clicks open."

EXECUTION: [OPEN door WITH brass_key]
```

### Scenario 4: Impossible Goal with Helpful Failure

```
INPUT: "Pick the lock on the door"

GAME STATE:
  - Door is locked
  - Player has no lockpicking skill
  - Player has no pin/tool that provides "lockpick" capability
  - Player has seen a lockpicking manual but hasn't read it

INTENT RECOGNITION:
  verb: OPEN / PICK
  target: door
  goal_state: door.is_locked == false
  tool_implied: lockpick (or similar)

PREREQUISITE ANALYSIS:
  - Door locked, requires unlock via PICK LOCK
  - Prerequisite: Player has lockpicking skill
    - Check: player.skills.lockpicking == false ✗
  - Prerequisite: Player has lockpick tool
    - Check: no "lockpick" capability in inventory ✗
  - Search: Is lockpick available anywhere?
    - Found: "pin" object in sewing kit (10 ticks ago, confidence 0.7)
  - Search: Can player learn lockpicking?
    - Found: Manual on shelf (discovered earlier)

HELPFUL FAILURE RESPONSE:
  "You don't have the skill to pick this lock. You've seen a lockpicking manual around—reading it might help. Or if you can find a suitable tool like a pin, you could try anyway."

SUGGESTIONS:
  1. Read the lockpicking manual to learn the skill
  2. Find a pin and attempt to pick the lock (with risk of bending it)
  3. Find the brass key (search the nightstand)
```

### Scenario 5: Compound Failure Analysis

```
INPUT: "Put on the armor and go upstairs"

GAME STATE:
  - Player has no armor
  - Armor is in a locked chest
  - Player has no key to chest
  - Upstairs door is locked, requires key player doesn't have
  - Light level is low (one candle left with 5 ticks)

INTENT RECOGNITION:
  Goal 1: Wear armor (goal_state: armor in player.worn_slots)
  Goal 2: Go upstairs (goal_state: player.location == upstairs)

ACTION CHAIN ATTEMPT:
  Goal 1:
    1. Find armor (not in inventory)
    2. Check: Is armor in current room? No
    3. Check: Is armor in discovered locations? Yes, in chest
    4. Check: Can player access chest? No, locked
    5. Check: Does player have key? No
    → FAIL: Armor inaccessible
    
  Goal 2:
    1. Navigate to upstairs
    2. Check: Player has light source? Yes (1 candle, 5 ticks)
    3. Check: Door is accessible? No, locked
    4. Check: Player has key? No
    → FAIL: Door locked

COMPREHENSIVE FAILURE RESPONSE:
  "I can't complete that chain. Here's what I found:
  
  1. You can't put on armor (it's in the locked chest and you don't have a key).
  2. You can't go upstairs (the door is locked and you don't have a key).
  
  Your light is running out (5 ticks left on the candle). Focus on finding keys or another light source first."

SUGGESTIONS:
  - Find a key to the chest
  - Find a key to the upstairs door
  - Get more light (find matches or another candle)
```

---

## 8. FAILURE MODES & ERROR HANDLING

### Challenge: When Intelligent Parsing Fails

Even with all five layers, some inputs will be ambiguous, impossible, or nonsensical.

### Failure Categories

#### 1. Unresolvable Goal (Impossible)

```
INPUT: "Create a new universe"
ACTION: Not mapped to any verb in game

RESPONSE (with learning opportunity):
  "I don't recognize that action. Available verbs include: look, examine, take, drop, 
   open, close, light, wear, etc. Try 'help' for more."
```

#### 2. Ambiguous Reference

```
INPUT: "Take it"
CONTEXT: Multiple objects recently mentioned (match, candle, nightstand)

RESPONSE (with clarification):
  "Take what? You recently mentioned: match, candle, nightstand. Which one?"

  [If player profile stores disambiguation preference, offer shorthand:
   "Take match / candle / nightstand?"]
```

#### 3. Impossible Due to Game State

```
INPUT: "Light the candle"
STATE: No fire source available, no way to obtain one

RESPONSE (with path analysis):
  "You can't light the candle—there's no fire source available.
   
   To get fire:
   - Find a match (exhausted all matchboxes)
   - Find a lit candle elsewhere (none available in this room)
   - Use oil lamp (none visible)
   
   You're in darkness. Explore other rooms to find fire sources."
```

#### 4. Contradiction or Paradox

```
INPUT: "Drop the candle and keep holding it"
PARSER: Detects contradiction in compound goals

RESPONSE:
  "Those actions contradict each other. Did you mean: 
   - 'Drop the candle' 
   - 'Keep holding the candle'?"
```

#### 5. Incomplete Instruction

```
INPUT: "Put the match"
MISSING: Target location (in what? on what?)

RESPONSE:
  "Put the match where? 
   Available: in matchbox, on desk, in inventory, on floor."
```

### Error Handling Strategy

```lua
function handle_parse_error(error_type, context, game_state)
  if error_type == "unresolved_goal" then
    return suggest_verbs(context.last_goal)
    
  elseif error_type == "ambiguous_reference" then
    return request_clarification(context.recent_objects)
    
  elseif error_type == "impossible_state" then
    return analyze_path_to_goal(context.goal, game_state)
    
  elseif error_type == "contradiction" then
    return offer_alternatives(context.goals)
    
  elseif error_type == "incomplete" then
    return request_missing_argument(context.last_verb, game_state)
  end
end
```

### Progressive Verbosity

Let players set error reporting level:

```
--verbose: Explains every step of parsing and planning
  "Parsing goal: light candle.
   Found verb LIGHT, target candle.
   Inferred tool: match (from recent context).
   Planning action chain: [TAKE matchbox, OPEN matchbox, TAKE match, STRIKE match, LIGHT candle]
   Executing..."

--normal (default): Reports high-level steps
  "Getting a match from the matchbox..."
  "Striking the match..."
  "Lighting the candle..."
  
--silent: Only final state + consequences
  "The candle is now lit."
```

---

## 9. IMPLEMENTATION ROADMAP

### Phase 1: Intent Recognition (Week 1)

**Deliverable:** `src/engine/parser/intent-classifier.lua`

- [ ] Verb → Goal state mapping (all 31 verbs)
- [ ] Precondition discovery for each verb
- [ ] Relationship extraction (from, with, on, in, to)
- [ ] Test: "light candle" → correct intent

### Phase 2: Action Chain Inference (Week 2)

**Deliverable:** `src/engine/parser/action-planner.lua`

- [ ] Backward-chaining planner algorithm
- [ ] Verb precondition system
- [ ] Goal satisfaction checker
- [ ] Test: "get match from matchbox" → [OPEN, TAKE]

### Phase 3: Prerequisite Resolution (Week 2-3)

**Deliverable:** `src/engine/parser/prerequisite-resolver.lua`

- [ ] Auto-resolvability classifier
- [ ] Tool-finding heuristics
- [ ] Confidence scoring
- [ ] Test: "light candle" → auto-resolve tool from context

### Phase 4: Context Window (Week 3)

**Deliverable:** `src/engine/parser/context-manager.lua`

- [ ] Recent command tracking
- [ ] Discovery recording
- [ ] Aging/confidence decay
- [ ] Integration with planner
- [ ] Test: Infer tool from recent EXAMINE

### Phase 5: Prepositional Intelligence (Week 3-4)

**Deliverable:** `src/engine/parser/relationship-extractor.lua`

- [ ] Regex-based relationship patterns
- [ ] Relationship-to-action mapping
- [ ] Integration with planner
- [ ] Test: "take match from matchbox" → correct source_container

### Phase 6: Integration & QA (Week 4)

**Deliverable:** Integrated Tier 3 in `src/engine/loop/init.lua`

- [ ] Wire all layers into game loop
- [ ] Fallback chain: Tier 1 → Tier 2 → Tier 3
- [ ] Error handling and suggestion system
- [ ] 50+ integration tests

### Phase 7: SLM Option Study (Optional, Week 5+)

**Deliverable:** `research/slm-tier3-study.md`

- [ ] Qwen2.5-0.5B ONNX integration research
- [ ] Training data generation (goal, state) → action_chain
- [ ] Latency profiling on target devices
- [ ] Decision: Proceed with SLM or remain rule-based?

---

## 10. SUCCESS CRITERIA

### Coverage Targets

- [ ] 95%+ of test commands parse correctly (intent recognized)
- [ ] 90%+ of test commands execute correct action chain
- [ ] 85%+ of test commands auto-resolve prerequisites correctly
- [ ] Context inference triggers on 30%+ of "minimal input" commands

### Performance Targets

- [ ] Intent classification: <10ms
- [ ] Action planning: <100ms (even for 5-step chains)
- [ ] Full parse-to-execution: <200ms median, <500ms p99
- [ ] No latency regression vs. Tier 1 + Tier 2

### Quality Targets

- [ ] Zero false-positive goal states (parser understands goal correctly)
- [ ] Zero deadlock plans (all chains executable from current state)
- [ ] User-friendly error messages for all failure modes
- [ ] Helpful suggestions for 80%+ of failed commands

---

## 11. OPEN QUESTIONS FOR WAYNE

1. **SLM Integration Urgency**
   - Is Tier 3 SLM critical for MVP, or Phase 2+?
   - Mobile latency sensitivity: Is 200–500ms acceptable for SLM inference?

2. **Confidence Thresholds**
   - Current defaults: AUTO_RESOLVE_THRESHOLD = 0.80, SLM fallback at <0.6
   - Should these be adjustable per player or per game difficulty?

3. **Error Messaging Tone**
   - Current: "You can't do that because X." (direct, diagnostic)
   - Alternative: "Hmm, that didn't work. Have you tried...?" (conversational)
   - Preference?

4. **Action Reporting**
   - Should the engine report all intermediate steps or only final state?
   - E.g., "You take the matchbox. You open it. You take a match. You strike it. You light the candle."
   - Or: "You prepare a match and light the candle."

5. **Compound Goal Handling**
   - Max goals per input: Currently assuming 2–3 (e.g., "and" conjunctions)
   - Should we support "Do X until Y" (looping)?
   - Should we support "Do X, then Y, then Z" (3+ step sequences)?

6. **Prerequisite Learning**
   - Should the parser "learn" from player actions?
   - E.g., if player manually executes [OPEN container, TAKE item] pattern, should parser remember this for future "take X from container" inputs?

---

## 12. REFERENCES

- **Architecture Overview:** `00-architecture-overview.md`
- **Parser Implementation Plan:** `plan/llm-slm-parser-plan.md`
- **Command Variations:** `../design/command-variation-matrix.md`
- **MUD Verb Systems:** `resources/research/competitors/mud-clients/verbs.md`
- **Decision D-19:** Parser approach (embedding vs. SLM)
- **Newspaper 2026-03-20:** Morning edition (verb scale research)

---

## APPENDIX A: Verb Goal Map

| Verb | Goal State | Preconditions | Tool? |
|------|-----------|---|---|
| LOOK | Player.can_see == true | Light available OR not blocked | No |
| EXAMINE | target.examined == true | Player in scope | No |
| TAKE | target.in_inventory == true | Target in scope, hands free | No |
| DROP | target.in_room == true | Target in inventory | No |
| OPEN | target.is_open == true | Target in scope, is_openable | Key? |
| CLOSE | target.is_open == false | Target in scope, is_closeable | No |
| LIGHT | target.casts_light == true | Target in scope, is_lightable | Yes (fire_source) |
| WEAR | target.worn_on_slot == true | Target in inventory, slot free | No |
| REMOVE | target.worn_on_slot == false | Target worn | No |
| WRITE | written_object exists | Target in inventory, has writing_tool | Yes (writing_tool) |
| PUT | target.in_container == true | Target & container in scope | No |
| STRIKE | target.state == lit | Target & matchbox in scope | Yes (striker) |
| FEEL | player.knows_texture == true | Any location (light not needed) | No |
| SMELL | player.knows_scent == true | Any location | No |
| TASTE | player.knows_flavor == true | Any location (dangerous) | No |
| LISTEN | player.knows_sound == true | Any location | No |
| BREAK | target.state == broken | Target in scope, is_breakable | Maybe (tool) |
| CUT | target.state == cut | Target in scope, is_cuttable | Yes (cutting_tool) |
| SEW | sewn_object exists | Objects in inventory | Yes (needle + thread) |
| PRICK | player.injured == true | Pin in inventory | Maybe (pin) |

---

**Document Complete**

*This design is ready for team review and implementation prioritization.*
