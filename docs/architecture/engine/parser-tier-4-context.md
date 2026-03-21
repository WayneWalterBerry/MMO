# Parser Tier 4: Context Window (Designed, Not Yet Built)

**Status:** 🔷 Designed (not yet implemented)  
**Version:** 1.0  
**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-25  
**Purpose:** Enhanced context-aware parsing that remembers recent discoveries and infers missing information.

---

## Overview

This tier augments Tier 3 (GOAP) by maintaining a **short-term memory window** of recent player actions and discoveries. This enables:

- **Contextual Tool Inference:** "Light the candle" infers match from recently examined matchbox
- **Recent Discovery Bias:** Tools discovered 5 ticks ago rank higher than those discovered 50 ticks ago
- **Relationship Memory:** "Put it in there" resolves "it" and "there" from recent context

---

## Context Window Structure

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

---

## Context Aging & Confidence

Older discoveries fade in confidence to reflect player memory decay:

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

## Tool Inference from Context

### Example: "Light the candle"

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

---

## Implementation: Context Manager

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

## Integration with Tier 3 (GOAP)

When Tier 3 plans action chains, it consults the context window:

```
INPUT: "Light the candle"

TIER 3 (GOAP):
  1. Intent Recognition: verb=LIGHT, target=candle, goal_state=lit
  2. Action Chain Inference: Need fire_source
  3. [NEW] Context Lookup: Recently examined matchbox (confidence 0.85)
     → Inferred tool: match from matchbox
  4. Full chain: [TAKE matchbox, OPEN matchbox, TAKE match, STRIKE match, LIGHT candle]
```

---

## Example Scenarios

### Scenario: Contextual Tool Inference

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

## Design Notes

- **Window Size:** 100 ticks per session (tunable)
- **Max Recent Commands:** 20 commands (prevents memory bloat)
- **Confidence Decay:** Linear fade after 50 ticks (customizable curve)
- **Discovery Recording:** Triggered by EXAMINE, FEEL, and related sensory verbs
- **Integration Point:** Feeds into Tier 3 action planning

---

## Future Enhancements

- **Location Memory:** Track which rooms contain which objects
- **NPC Interaction History:** Remember what NPCs have told you
- **Failed Attempts:** Learn from player mistakes ("player tried to open locked door without key")
- **Player Preferences:** Personalize confidence thresholds per player

---

## See Also

- **Parser Tier 1 (Basic):** `parser-tier-1-basic.md`
- **Parser Tier 2 (Compound):** `parser-tier-2-compound.md`
- **Parser Tier 3 (GOAP):** `parser-tier-3-goap.md`
- **Parser Tier 5 (SLM):** `parser-tier-5-slm.md`
- **Architecture Overview:** `00-architecture-overview.md`
