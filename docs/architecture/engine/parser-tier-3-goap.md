# Parser Tier 3: GOAP (Goal-Oriented Action Planning)

**Status:** 🔷 Designed (not yet implemented)  
**Version:** 1.0  
**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-25  
**Related Decisions:** D-19 (Parser approach), LLM-SLM Parser Plan  
**Purpose:** Backward-chaining decomposition of complex goals into executable action chains.

---

## Overview

If Tier 1 + Tier 2 both fail, this layer engages. It uses **Goal-Oriented Action Planning (GOAP)** to infer prerequisites, decompose multi-step goals, and auto-resolve obvious intermediate steps.

**Key Use Cases:**
- "Get a match from the matchbox and light the candle" → [OPEN matchbox, TAKE match, STRIKE match, LIGHT candle]
- "Light the candle" (when match is hidden) → infers missing tools and their prerequisites
- "Unlock the door" → auto-opens door WITH key (if player has it)

---

## 1. Intent Recognition

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

## 2. Action Chain Inference

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

## 3. Prerequisite Resolution

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

## 4. Context Window

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

---

## 5. Prepositional Intelligence

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

## Example Scenarios

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

---

## Implementation Roadmap

### Phase 1: Intent Recognition
- Verb → Goal state mapping (all 31 verbs)
- Precondition discovery for each verb
- Relationship extraction (from, with, on, in, to)

### Phase 2: Action Chain Inference
- Backward-chaining planner algorithm
- Verb precondition system
- Goal satisfaction checker

### Phase 3: Prerequisite Resolution
- Auto-resolvability classifier
- Tool-finding heuristics
- Confidence scoring

### Phase 4: Context Window
- Recent command tracking
- Discovery recording
- Aging/confidence decay
- Integration with planner

### Phase 5: Prepositional Intelligence
- Regex-based relationship patterns
- Relationship-to-action mapping
- Integration with planner

### Phase 6: Integration & QA
- Wire all layers into game loop
- Fallback chain: Tier 1 → Tier 2 → Tier 3
- Error handling and suggestion system
- 50+ integration tests

---

## See Also

- **Parser Tier 1 (Basic):** `parser-tier-1-basic.md`
- **Parser Tier 2 (Compound):** `parser-tier-2-compound.md`
- **Parser Tier 4 (Context Window):** `parser-tier-4-context.md`
- **Parser Tier 5 (SLM):** `parser-tier-5-slm.md`
- **Architecture Overview:** `00-architecture-overview.md`
- **Verb System:** `verb-system.md`
- **Parser Implementation Plan:** `../../plan/llm-slm-parser-plan.md`
