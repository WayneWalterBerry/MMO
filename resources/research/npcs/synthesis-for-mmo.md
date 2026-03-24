# Synthesis: NPC Architecture for MMO Engine (Recommendations)

**Final Synthesis** — Integrate research from DF, MUDs, patterns, and academics into a coherent architecture for MMO's Lua-based text adventure engine.

---

## Executive Summary

**Recommended Approach:** Implement NPCs as **stateful objects** with **component-based behavior**, driven by **needs and emotion**, updated via **tick-based simulation**, with optional **LLM dialogue layer**.

**Key Principle:** *Don't script individual NPC behaviors; design systems that generate behavior*. Simple rules composed together create complex, believable NPCs.

**Implementation Timeline:**
- **MVP (Phase 1):** Basic state machine + needs + memory (2-3 weeks, 100 lines Lua per NPC class)
- **Phase 1.5:** Emotion system + relationships (1-2 weeks)
- **Phase 2+:** LLM dialogue, procedural personality, multiplayer coordination (later)

---

## I. Core Architecture: Five Layers

### Layer 1: State & Identity

Each NPC is a Lua object with persistent state:

```lua
-- NPCs/dwarf.lua (example NPC definition)
local Dwarf = inherit(NPC)

function Dwarf:create()
    -- Identity
    self.name = "Borin"
    self.species = "dwarf"
    self.role = "blacksmith"
    
    -- Stats (fixed)
    self.stats = { strength = 14, intelligence = 10, dexterity = 12 }
    self.skills = { smithing = 60, mining = 40, combat = 35 }
    
    -- Personality (fixed, generates bias)
    self.personality = {
        friendliness = 0.7,
        anxiety = 0.3,
        pride = 0.8,
        patience = 0.4
    }
    
    -- Needs (dynamic, change over time)
    self.needs = { hunger = 0, thirst = 0, social = 0 }  -- 0-100 scale
    
    -- Relationships (persistent)
    self.relationships = {}  -- {npc_id => {type, strength, history}}
    
    -- State (current behavior)
    self.state = "idle"
    self.current_task = nil
    self.goal_queue = {}
    
    -- Memory (queryable history)
    self.memory = {
        events = {},  -- Circular buffer of last 50 events
        facts = {},   -- {key => {value, timestamp}}
    }
end

return Dwarf
```

**Rationale:**
- **Stateful:** NPCs persist across sessions (stored in database or serialized)
- **Typed attributes:** Clear contract for each NPC
- **Component-like:** Easy to add/remove features (e.g., new need, new skill)

---

### Layer 2: Needs & Mood System

**Needs drive behavior.**

```lua
function Dwarf:tick()
    -- Update needs (decay/accumulate)
    self:update_needs()
    
    -- Aggregate mood from needs
    self:calculate_mood()
    
    -- Choose action based on mood + needs
    self:decide_action()
    
    -- Execute action
    self:perform_action(self.current_task)
end

function Dwarf:update_needs()
    self.needs.hunger = math.min(100, self.needs.hunger + 1)  -- Hunger increases
    self.needs.thirst = math.min(100, self.needs.thirst + 2)  -- Thirst increases faster
    self.needs.social = math.max(0, self.needs.social - 1)   -- Social need decays if alone
    
    -- Apply personality modifier
    local social_personality = self.personality.friendliness
    self.needs.social = self.needs.social + (social_personality * 0.5)  -- Friendly dwarves need more social time
end

function Dwarf:calculate_mood()
    local mood_score = 0
    
    -- Needs below threshold are unhappy
    if self.needs.hunger > 50 then mood_score = mood_score - 20 end
    if self.needs.thirst > 60 then mood_score = mood_score - 25 end
    
    -- Recent happy/unhappy events
    for _, event in ipairs(self:get_recent_memory(86400)) do  -- Last 24h
        if event.type == "achievement" then mood_score = mood_score + 10 end
        if event.type == "insult" then mood_score = mood_score - 15 end
        if event.type == "friend_death" then mood_score = mood_score - 40 end
    end
    
    -- Map to mood state
    if mood_score > 30 then self.mood = "happy"
    elseif mood_score < -30 then self.mood = "sad"
    elseif mood_score < -60 then self.mood = "angry"
    else self.mood = "neutral"
    end
    
    -- Store for diagnostics
    self.mood_score = mood_score
end

function Dwarf:decide_action()
    local utility_scores = {}
    
    -- Evaluate each action (eat, sleep, work, socialize, flee)
    utility_scores.eat = (self.needs.hunger / 100) * 100  -- High utility if hungry
    utility_scores.sleep = math.max(0, (self.fatigue - 50) / 50 * 100)
    utility_scores.work = self:calculate_work_utility()  -- Based on task availability
    utility_scores.socialize = (self.needs.social / 100) * 100 * self.personality.friendliness
    
    -- Modulate by mood
    if self.mood == "sad" then utility_scores.work = 0 end  -- Depressed dwarves don't work
    if self.mood == "angry" and enemy_nearby then utility_scores.work = 0 end
    
    -- Choose highest utility action
    local best_action = self:get_max_utility_action(utility_scores)
    self.current_task = best_action
end

return Dwarf
```

**Why This Approach:**
- **Autonomous:** NPCs pursue their own needs, not just react to player
- **Personality-driven:** Personality biases need levels (friendly dwarves are more social)
- **Contextual:** Same event triggers different response depending on mood
- **Scalable:** Add new needs or emotions by extending `calculate_mood()`

---

### Layer 3: Relationships & Memory

NPCs build persistent relationships with each other and the player.

```lua
local Relationship = {}

function Relationship:new(with_npc)
    return {
        with = with_npc,
        type = "neutral",  -- friend, rival, lover, family, enemy
        strength = 0,      -- -100 to +100 (negative = hostile, positive = friendly)
        history = {},      -- Events involving this NPC
        grudges = {},      -- {reason => timestamp} (decay over time)
    }
end

function Dwarf:remember_event(event)
    -- Add to circular event buffer
    table.insert(self.memory.events, event)
    if #self.memory.events > 50 then
        table.remove(self.memory.events, 1)  -- Keep last 50 events
    end
    
    -- Update relevant relationships
    if event.type == "insult" and event.from then
        self:update_relationship(event.from, {
            type = "rival",
            strength = -10,
            grudge = event.type
        })
    elseif event.type == "helped_me" and event.from then
        self:update_relationship(event.from, {
            type = "friend",
            strength = 15
        })
    end
end

function Dwarf:get_relationship(with_npc)
    if not self.relationships[with_npc.id] then
        self.relationships[with_npc.id] = Relationship:new(with_npc)
    end
    return self.relationships[with_npc.id]
end

function Dwarf:should_help(other_npc)
    local rel = self:get_relationship(other_npc)
    
    -- Help friends, not enemies
    if rel.strength > 30 then return true end
    if rel.strength < -30 then return false end
    
    -- Base behavior on personality
    if self.personality.friendliness > 0.7 then return true end
    
    return false
end

return Dwarf
```

**Why This Approach:**
- **Persistent:** Relationships survive sessions
- **Complex:** Relationships have history (grudges, debt of gratitude)
- **Affect behavior:** NPC's decisions flow from relationships
- **Emergent conflict:** Grudges drive conflicts without scripting

---

### Layer 4: Dialogue & Interaction

NPCs respond to player and generate text based on state.

```lua
function Dwarf:hear_player(text)
    -- Parse player input to extract intent
    local intent = dialogue_engine:parse_intent(text)
    
    -- Query context: What do I know about this player?
    local known_facts = self:query_memory("about_player", 10)  -- Last 10 facts
    local relationship = self:get_relationship(player)
    
    -- Generate response based on state + context
    local response = self:generate_response(intent, known_facts, relationship)
    
    -- Record interaction in memory
    self:remember_event({
        type = "player_said",
        text = text,
        from = player,
        timestamp = os.time()
    })
    
    return response
end

function Dwarf:generate_response(intent, facts, relationship)
    -- Simple template-based response for MVP
    -- Later: Replace with LLM or dialogue tree
    
    if intent == "greeting" then
        if relationship.strength > 30 then
            return "Aye, " .. player.name .. "! Good to see ye."
        else
            return "What do ye want?"
        end
    elseif intent == "quest_offer" then
        if self.mood == "sad" or self.fatigue > 80 then
            return "Not now, I'm too tired."
        else
            return "Aye, I've got a task fer ye."
        end
    elseif intent == "insult" then
        self:remember_event({ type = "insult", from = player })
        self:update_relationship(player, { strength = -20 })
        return "How DARE ye! Get outta my sight!"
    end
    
    return "..."  -- Default response
end

return Dwarf
```

**For MVP:** Simple template-based responses. Later, integrate LLM for richer dialogue.

---

### Layer 5: Tick-Based Simulation

Update all NPCs efficiently.

```lua
-- main.lua or server loop
local NPC_TICK_INTERVAL = 100  -- ms between NPC updates

function game:tick()
    local now = os.time() * 1000  -- Current time in ms
    
    -- Update nearby NPCs frequently
    for _, npc in ipairs(world:get_nearby_npcs(player, 50)) do
        if not npc.last_tick or (now - npc.last_tick) > NPC_TICK_INTERVAL then
            npc:tick()
            npc.last_tick = now
        end
    end
    
    -- Update distant NPCs less frequently
    for _, npc in ipairs(world:get_distant_npcs(player, 50, 500)) do
        if not npc.last_tick or (now - npc.last_tick) > NPC_TICK_INTERVAL * 5 then  -- 5x slower
            npc:tick_background()  -- Lower-fidelity update
            npc.last_tick = now
        end
    end
end

function Dwarf:tick()
    self:update_needs()
    self:calculate_mood()
    self:decide_action()
    self:perform_action()
end

function Dwarf:tick_background()
    -- Lower-fidelity update for distant NPCs
    self:update_needs()
    self:calculate_mood()
    -- Don't perform action (might still be performing same action)
end

return game
```

**Performance:**
- **Nearby NPCs (50 units):** Full update every 100ms = 10 updates/sec (low CPU cost)
- **Distant NPCs:** Update every 500ms = 2 updates/sec (very low cost)
- **Estimated for 100 NPCs:** 50 nearby + 50 distant = (50×10 + 50×2) = 600 updates/sec ≈ 2-3% CPU (on modern hardware, assuming simple update logic)

---

## II. Integration with Existing Engine

### A. Object System

Our engine already uses Lua objects with FSM states and mutations. NPCs fit naturally:

```lua
-- Before: Static object (furniture)
local Mirror = inherit(Object)
function Mirror:interact()
    return "You see your reflection."
end

-- Now: NPC (subclass of Object)
local Dwarf = inherit(Object)  -- NPCs are objects!
function Dwarf:create()
    self.name = "Borin"
    self.stats = { strength = 10 }
    self.needs = { hunger = 0 }
    self.memory = {}
end
function Dwarf:interact()
    return self:hear_player("greeting")
end
function Dwarf:tick()
    -- Update state
end
```

**Advantage:** NPCs are *first-class objects* in containment hierarchy (dwarf can be in room, in tavern, etc.).

### B. Material Properties

Use existing material system to influence NPC properties:

```lua
-- Dwarf made of "dwarf_flesh" (material defines fatigue rate, hunger rate, etc.)
local Dwarf = inherit(Object)
function Dwarf:create()
    self:set_material("dwarf_flesh")  -- Defines biological properties
    self.stats = Material:get_stats("dwarf_flesh")  -- Inherits material properties
end
```

**Benefit:** Reuse material system for NPC composition.

### C. Effects & Sensory System

Use existing effects pipeline for NPC perception:

```lua
-- When player enters room, fire event to all NPCs
function Room:add_object(obj)
    if obj.type == "player" then
        self:emit_event("player_entered", obj)
    end
    -- ... existing code ...
end

-- Dwarf listens to "player_entered"
function Dwarf:register_events()
    self:on_event("player_entered", function(player)
        self:react_to_player(player)
    end)
end
```

**Benefit:** Reuse existing event system.

---

## III. Recommended Implementation: Phase Breakdown

### Phase 1: MVP (2-3 weeks)

**Goal:** Basic NPC system proving concept.

**Deliverables:**
1. **NPC Base Class** (200 lines)
   - State, needs, mood, relationships, memory
   - Tick function
   - Simple action selection (utility-based)

2. **Simple Dialogue** (150 lines)
   - Greeting responses based on relationship
   - Quest offer/acceptance
   - Basic insult response

3. **Test NPCs** (100 lines)
   - Shopkeeper (sells items, tracks sales)
   - Guard (patrols, reacts to player)
   - Quest-giver (tracks quests)

4. **Integration** (100 lines)
   - Add NPCs to world
   - Add tick system to main loop
   - Test persistence (save/load NPC state)

**Estimated Scope:** 550 lines Lua + documentation

### Phase 1.5: Emotion & Relationships (1-2 weeks)

**Goal:** Make NPCs feel alive through emotion and relationships.

**Deliverables:**
1. **Emotion System** (150 lines)
   - OCC model (joy, anger, sadness)
   - Emotion influences behavior
   - Events trigger emotions

2. **Relationship System** (100 lines)
   - Friendships between NPCs
   - Grudges and revenge
   - Loyalty and help-seeking

3. **Test Cases** (100 lines)
   - NPC befriends player
   - NPC holds grudge
   - NPC seeks revenge

**Estimated Scope:** 350 lines + tests

### Phase 2: Depth & Emergence (2-4 weeks)

**Goal:** NPC world feels alive and emergent.

**Deliverables:**
1. **Behavior Trees** (200 lines)
   - Action/condition/selector/sequence nodes
   - Modular behavior composition

2. **Skill Progression** (100 lines)
   - NPCs improve at skills
   - Skill affects success probability

3. **Emergent Events** (150 lines)
   - NPC-to-NPC conflicts
   - NPC achievements and failures
   - Rumor/reputation system

**Estimated Scope:** 450 lines + systems

### Phase 3: Polish (Later)

1. **Procedural Personality Generation**
   - Generate diverse NPCs from trait distributions

2. **LLM Dialogue** (Optional)
   - Integrate OpenAI/local models for rich conversation
   - Manage persona consistency and cost

3. **Multiplayer Coordination**
   - NPCs react to multiple players
   - Faction system
   - NPC-to-NPC alliance/conflict

---

## IV. Minimum Viable NPC (MVP Code Sketch)

```lua
-- NPCs/npc_base.lua
local NPC = inherit(Object)

function NPC:create()
    self.personality = { friendliness = 0.5, anxiety = 0.5 }
    self.needs = { hunger = 0, thirst = 0, social = 0 }
    self.mood = "neutral"
    self.relationships = {}
    self.memory = { events = {} }
    self.current_task = nil
end

function NPC:tick()
    self:update_needs()
    self:calculate_mood()
    self:decide_action()
end

function NPC:update_needs()
    self.needs.hunger = math.min(100, self.needs.hunger + 1)
    self.needs.thirst = math.min(100, self.needs.thirst + 1)
end

function NPC:calculate_mood()
    local score = 0
    if self.needs.hunger > 50 then score = score - 10 end
    if self.needs.thirst > 60 then score = score - 15 end
    
    if score < -20 then self.mood = "sad"
    elseif score > 20 then self.mood = "happy"
    else self.mood = "neutral"
    end
end

function NPC:decide_action()
    if self.needs.hunger > 70 then
        self.current_task = "eat"
    elseif self.needs.social > 60 and self.personality.friendliness > 0.6 then
        self.current_task = "socialize"
    else
        self.current_task = "work"
    end
end

function NPC:hear_player(text)
    if text:find("hello") then
        if self:get_relationship(player).strength > 30 then
            return "Hello, friend!"
        else
            return "What do ye want?"
        end
    end
    return "..."
end

return NPC
```

**~80 lines of core logic. Add specific NPC types (Shopkeeper, Guard) as subclasses.**

---

## V. Scale Considerations

### For 100 NPCs Across 50 Rooms

**Memory per NPC:**
- State: ~500 bytes (stats, needs, mood)
- Relationships: ~5 KB (10 relationships × 500 bytes)
- Memory (50 events): ~2 KB
- **Total: ~8 KB per NPC**
- **100 NPCs: 800 KB** (negligible)

**CPU per Update:**
- Nearby NPC (full update): ~0.5 ms (needs, mood, decision)
- Distant NPC (background update): ~0.1 ms
- Dialogue generation (simple template): ~1 ms
- **50 nearby NPCs @ 10 updates/sec:** 50 × 0.5ms × 10 = 250 ms / 1000 ms = 25% at peak
- **Optimized (stagger updates):** 50 × 0.5ms × 1 per 100ms = 5% CPU

**Acceptable:** 5-10% CPU for NPC simulation is reasonable, especially for MVP.

---

## VI. Top 2-3 Approaches Worth Prototyping

### Approach 1: Hierarchical FSM + Utility AI (Recommended for MVP)

**Rationale:**
- Fits existing Lua object model
- Proven pattern (used in industry)
- Scalable and tunable
- Easy to debug

**Prototype Time:** 1-2 weeks

**Pros:** Simple to implement, integrates well with existing code
**Cons:** Limited emergent behavior, less sophisticated

### Approach 2: Behavior Trees + Emotion System

**Rationale:**
- More modular and composable
- Scales better (hierarchical)
- Supports rich personality

**Prototype Time:** 2-3 weeks

**Pros:** More sophisticated, scalable, designer-friendly
**Cons:** More complex, requires tool support for visual editing

### Approach 3: Hybrid (HFSM + GOAP for Quests)

**Rationale:**
- Use HFSM for day-to-day behavior
- Use GOAP for quest goals (e.g., "find ingredient in dungeon")
- Best of both worlds

**Prototype Time:** 3-4 weeks

**Pros:** Flexible, handles complex quests elegantly
**Cons:** Most complex to implement, requires debugging GOAP planner

---

## VII. Decision Matrix: Minimal Violations of Principle 0

**Principle 0:** "Objects are inanimate (no NPC system yet)."

**Proposed Extension:** "NPCs are animated objects with autonomous goals, driven by rule-based simulation (no explicit consciousness required)."

**Key:** NPCs don't have *free will* or *consciousness*—just complex state machines responding to needs and events. This is a *quantitative*, not *qualitative* change from objects.

**Minimal Violation:**
- Add `needs` and `mood` attributes (extend object state)
- Add `tick()` method to update state (extend object behavior)
- Add `memory` table to store interactions (extend object data)
- Add `relationships` table (inter-object reference)

**Not Adding (Stays True to Principle 0):**
- No LLM (stays deterministic)
- No emergent consciousness (stay rule-based)
- No hidden knowledge (NPCs only know what they've experienced)
- NPCs are *objects*, not exceptions to object model

---

## VIII. Conclusion & Next Steps

**Recommendation:** Implement **Approach 1 (Hierarchical FSM + Utility AI)** for MVP, prove concept, then iterate.

**Next Steps:**
1. **Design Document:** Spec out NPC class, attributes, behavior
2. **Prototype:** Build minimal NPC (Shopkeeper test case)
3. **Integrate:** Add to world, test persistence
4. **Test:** Verify performance (100 NPCs over 50 rooms)
5. **Iterate:** Gather feedback, add emotion system (Phase 1.5), then behavior trees (Phase 2)

**Critical Success Factor:** **Personality & Autonomy**

Make NPCs feel alive by:
- Pursuing own goals (needs-based)
- Remembering interactions (persistent memory)
- Evolving relationships (dynamic relationships)
- Reacting emotionally (emotion system)

Don't rely on dialogue complexity; rely on authentic behavior.

---

## IX. References

- This research builds on: Dwarf Fortress, MUDs, Behavior Trees, GOAP, Utility AI
- See previous documents for detailed citations
- Academic foundation: Mateas & Stern, OCC model, Loyall & Bates
- Industry practice: Crusader Kings, RimWorld, Stardew Valley, Skyrim

---

**End of Research Package**

**Total Output:**
- 5 research documents (~65 KB total)
- Covers DF, MUDs, engineering patterns, academic research, and practical recommendations
- Provides clear path forward for MMO NPC architecture

**Handoff:** Ready for Bart (Architecture) and CBG (Design) to prototype Phase 1 MVP.
