# Academic Research on Believable Agents & NPC AI (2023-2025)

**Current Research Review** — Cutting-edge academic and industry thinking on creating believable, lifelike NPCs. Focus on what's been proven, what's emerging, and practical implications.

---

## Executive Summary

Recent research (2023-2025) emphasizes:

1. **Believable agents** require *emotional modeling*, not just behavior scripting
2. **LLM-powered NPCs** are feasible but require careful tuning (persona consistency, hallucination mitigation)
3. **Emotion-driven architectures** (OCC model, appraisal theory) produce more believable characters
4. **Hybrid approaches** combine fixed-persona models with modular memory for scalability
5. **Emergent narrative** (from simulation, not scripting) is key to replayability

---

## I. Foundational Work: Believable Agents

### A. Mateas & Stern: Façade (2000s)

**Project:** Interactive drama where player interacts with AI characters (Grace and Trip) through dialogue and action in a real-time narrative.

**Key Contribution:**
- Demonstrated that **believable agents can drive interactive narrative**
- Introduced **ABL (A Behavior Language)**: reactive planning language for story-driven characters
- Characters coordinate with each other while responding to player input, maintaining narrative coherence

**Architecture:**
- **Perception:** Character observes player actions, dialogue, environment
- **Appraisal:** Processes observations through emotional filters (personality-influenced)
- **Planning:** Chooses actions/dialogue that advance character goals and maintain dramatic arc
- **Execution:** Performs actions while reacting believably to surprises

**Why It Mattered:**
- Proved that NPCs don't need "perfect" dialogue; they need *authentic emotional response*
- Showed that procedural behavior + scripted anchors = strong narrative
- Established **emotion as central to believability**

**Limitations:**
- Limited scalability (2 main characters + supporting cast)
- Dialogue options still limited (not truly open conversation)
- Requires hand-authored emotional arcs

### B. Loyall & Bates: Believability in Game Agents

**Research:** What makes game NPCs feel real?

**Key Findings:**
1. **Personality consistency:** NPCs who behave true-to-character feel alive, even if behavior is simple
2. **Internal motivation:** NPCs pursuing own goals (not just reacting to player) feel autonomous
3. **Emotional response:** NPCs who emote authentically are more engaging than stoic ones
4. **Memory & consequence:** NPCs who remember past events and hold grudges feel persistent
5. **Limitation of script trees:** Even complex dialogue trees feel scripted if responses aren't contextual

**Implication for MMO:** Focus on *authentic personality* and *goal pursuit* over dialogue breadth.

---

## II. Emotion Modeling & Affect Architecture (Recent)

### A. OCC Model (Ortony, Clore, Collins)

Psychological framework for structuring emotions:

**Emotion Types:**

1. **Goal-Based:** Events that impact character's goals
   - Joy/Sadness (goal achieved/failed)
   - Relief/Disappointment (goal likely to be achieved/failed)
   - Anger/Gratitude (someone helped/hindered goal)

2. **Standard-Based:** Violations of norms/beliefs
   - Pride/Shame (self conforms/violates standards)
   - Admiration/Reproach (others conform/violate)

3. **Attraction-Based:** Intrinsic preferences
   - Love/Hate (preferences toward people, objects)
   - Liking/Disliking (toward actions, situations)

**Application:**
- Character has *goals* (find food, protect friend, gain wealth)
- *Events* (player steals food, kills friend, offers treasure) trigger emotions based on goal impact
- **Emotions drive behavior:** Angry character is more aggressive; sad character withdraws

### B. Recent Affective Architectures (2023-2024)

**Appraisal-Based Chain-of-Emotion Architecture (2024 paper):**

```
Event → Appraisal (why did this happen?) → Emotion (joy, anger, fear) → Coping (action)
```

Example: Player kills NPC's friend
1. **Appraisal:** "The player killed my friend intentionally"
2. **Emotion:** Anger (goal blocked) + Sadness (loss) + Desire for revenge
3. **Coping:** Pursue player or report to authorities

**Implementation (conceptual):**

```lua
function npc:on_event(event)
    local appraisal = self:appraise_event(event)  -- Why did this happen?
    local emotion = self:emotion_from_appraisal(appraisal)  -- What do I feel?
    self:update_mood(emotion)
    local action = self:choose_coping_action(emotion)  -- What do I do?
    self:perform_action(action)
end

function npc:appraise_event(event)
    if event.type == "friend_death" and event.killer == event.actor then
        return { goal_impact = "negative", personal = true, agent = event.actor }
    end
end

function npc:emotion_from_appraisal(appraisal)
    if appraisal.goal_impact == "negative" then
        if appraisal.agent == "myself" then return "shame"
        elseif appraisal.personal then return "anger"  -- Against agent
        else return "sadness"
        end
    end
end
```

**Advantage:** Emotions feel *contextualized* and *justified*, not random.

### C. Modular Affective Architectures

Recent work emphasizes **composable emotion modules:**

- **Short-term emotion:** Immediate reaction (anger at insult)
- **Mood:** Sustained emotional state (depressed after loss)
- **Personality trait:** Long-term tendency (quick to anger, anxious)

Each layer influences the others:
- Personality biases which emotions arise
- Current mood amplifies/dampens emotional response
- Strong emotions can override mood

**Benefit:** Creates emotional complexity (same event triggers different responses depending on mood).

---

## III. LLM-Powered NPCs (2024-2025)

### A. State of the Art

Recent projects successfully integrate LLMs into game NPCs:

**Mantella (Skyrim Mod):**
- Replaces NPC dialogue trees with LLM conversation
- Backed by character stats (race, level, personality)
- Context includes NPC's relationships, current quest
- **Result:** Dialogue feels *far more varied* and *contextual*
- **Problems:** Latency (200-500ms per response), occasional hallucinations

**Echoes of Others (Unreal Engine 5):**
- Real-time LLM dialogue using cloud and local models
- Measures latency vs. dialogue quality
- Maintains 60 FPS with 30-50 concurrent NPC interactions
- **Findings:** Smaller models (7B-13B) tuned for persona perform nearly as well as GPT-4, with better latency

**Cross-Platform NPC Systems (2024):**
- Single NPC can interact via in-game chat AND Discord
- Persistent memory across platforms (NPC remembers you on Discord, greets you in-game)
- Modular memory: facts stored separately from personality prompt

### B. Hybrid Approach: Fixed-Persona SLMs with Modular Memory

**Architecture:**

```
┌─ Small Language Model (persona-tuned) ──┐
│  "You are a gruff dwarf blacksmith"     │
│  "Personality: impatient, proud"        │
└──────────────────────────────────────────┘
           │
           ↓
┌─ Modular Memory ──────────────────────┐
│  [Facts]: Player is human, name=John  │
│  [History]: John bought sword 3 days  │
│  [State]: Currently smithing iron     │
│  [Relationships]: Likes John (+0.6)   │
└───────────────────────────────────────┘
           │
           ↓
[Generate Response to John's greeting]
→ "Ah, John! Back for another sword?"
  (Small model generates; memory grounds facts)
```

**Advantages:**
- **Cost-effective:** Fine-tuned 7B model cheaper than GPT-4
- **Latency:** ~100-200ms inference on local hardware
- **Consistency:** Persona fixed; only memory updates per interaction
- **Scalability:** 100+ NPCs with separate models is feasible

**Challenges:**
- **Persona drift:** Over time, LLM may deviate from intended personality
- **Hallucination:** Invents facts (e.g., NPC claims player did something they didn't)
- **Context length:** Memory must be summarized to fit prompt (~4K tokens for GPT-3.5)

### C. Mitigation Strategies (2024-2025 Research)

**1. Retrieval-Augmented Generation (RAG):**
- Query memory database *before* generating response
- Only include relevant facts in prompt
- Reduces hallucination (LLM sees facts it should reference)

```lua
function npc:respond_to_greeting(player)
    -- Query memory: what do I know about this player?
    local relevant_facts = self.memory:query("player", player.id, max_results=5)
    
    -- Build prompt with facts
    local prompt = self:build_prompt(relevant_facts, player.text)
    
    -- Generate response (smaller model, constrained context)
    local response = llm:generate(prompt, max_tokens=50)
    
    -- Update memory
    self.memory:add_interaction(player, response)
    
    return response
end
```

**2. Constrained Vocabulary:**
- Limit LLM's output to known actions/emotions
- Prevents out-of-character responses

```lua
-- Instead of free-form: "Guard says: I'll report you to the authorities blah blah blah"
-- Constrain to actions:
local valid_actions = { "say", "emote", "attack", "flee", "quest_offer" }
local generated_text = llm:generate_with_constraints(prompt, valid_actions)
-- Returns: {action="emote", text="looks angry", target="player"}
```

**3. Persona Locking via Fine-Tuning:**
- Fine-tune model on character's dialogue samples
- Reinforces persona consistency
- Requires 10-50 training examples per character

**4. Memory Management:**
- Limit working memory to last N interactions
- Archive old memories (player won't notice)
- Summarize long conversations (e.g., "agreed to kill rats")

---

## IV. Emergent Narrative Through Simulation

### A. Crusader Kings III: Storytelling Through Systems

**Design Philosophy:** Don't author stories; simulate characters with goals/traits, let stories emerge.

**Architecture:**
- **Characters:** Each has traits, beliefs, ambitions, relationships
- **Events:** Storytelling vignettes (affairs, plots, betrayals) triggered by game state
- **Emergent:** Combination of traits + random events + character choices = unique narratives

**Example:**
- Character A (ambitious, treacherous) learns Character B (their liege) is weak
- Event triggers: "You could plot against them"
- Character A chooses conspiracy → other nobles join or refuse
- Result: Civil war, assassination, or false reconciliation

**Why It Works:**
- Every playthrough is different (traits and random events ensure variation)
- Characters feel *autonomous* (pursuing own goals, not following script)
- Stories feel *earned* (player's choices and character personalities drive plot)

**For MMO NPCs:** Use similar principle—define needs, traits, relationships, then let emergent interactions create stories.

### B. RimWorld: Emergent Stories from Need Simulation

**System:** Each colonist has needs (hunger, social, entertainment), traits (lazy, creative, bold), and relationships.

**Emergent Behaviors:**
- A colonist goes on a depressive rampage after losing their lover
- Two colonists fall in love based on compatible traits
- A legendary chef refuses to cook because of low mood
- Betrayal: A colonist sabotages colony due to low loyalty

**Why Players Care:**
- They remember *individual colonists* (not generic units)
- Colonists have persistent personalities and histories
- Meaningful choices flow from simulation (should I revive this colonist who betrayed me?)

**For MMO:**  Implement similar: needs → mood → behavior. Players remember NPCs who evolve and respond to their choices.

---

## V. The Uncanny Valley of NPC Behavior in Text

### A. What Makes Text NPCs Weird

**Text adventures lack:** Body language, facial expressions, tone of voice

**Result:** NPCs feel artificial if:
1. They're *too consistent* (never contradict themselves, never have bad days)
2. They're *too responsive* (instantly know everything player does)
3. They're *too verbose* (write novels; real people are terse)
4. They're *too accommodating* (never refuse, never misunderstand)

### B. Authenticity Through Constraint

**Make NPCs feel real by:**
1. **Limited knowledge:** NPCs only know what they'd plausibly know (not omniscient)
2. **Forgetfulness:** NPCs forget details after time; players re-explain
3. **Misunderstanding:** NPCs misinterpret player actions (comedic or dramatic)
4. **Stubbornness:** NPCs refuse requests that conflict with personality/goals
5. **Inconsistency:** Moody NPCs behave differently when happy vs. tired
6. **Brevity:** NPCs use short sentences, interruptions, incomplete thoughts

**Example:**
- Good NPC: "I remember you killed my brother. You pay with your life!" [attacks]
- Better NPC: "Wait, don't I know you? ... Oh god, you... [visibly struggles] I can't... I'm sorry, I just can't."
- Even better: *NPC walks away, shaking* / *NPC demands you leave, won't engage*

---

## VI. Procedural Personality Generation

### A. Trait-Based Synthesis

Recent research explores **generating** NPC personalities procedurally:

**Method:**
1. Sample personality traits from distributions (Big Five model, or simplified version)
2. Generate goals/dreams based on traits (ambitious → wants wealth; creative → wants recognition)
3. Sample skill set based on goals
4. Determine relationships with other NPCs based on trait compatibility

**Example:**
```
Traits: [Friendly: 0.8, Ambitious: 0.3, Creative: 0.7, Fearful: 0.2]
Generated Goals: "Make friends, create art, be admired"
Generated Skills: [art=75%, conversation=70%, business=40%]
Generated Relationships: Likes similar-personality NPCs, dislikes ambitious rivals
```

**Benefit:** Generate 1000s of unique NPCs without hand-authoring each.

### B. Limitations

- Traits alone don't create personality (need history, relationships, experiences)
- Random generation can produce inconsistent or boring NPCs
- Requires post-generation curation (delete unsuitable combinations)

---

## VII. Current Challenges & Open Problems

### A. Scaling Dialogue Quality

**Problem:** LLM dialogue quality drops significantly at scale.
- 1 NPC with 10K tokens context: Excellent dialogue
- 100 NPCs with 1K tokens each: Dialogue quality drops 30-40%

**Solutions Explored:**
- Tiered systems (main NPCs get full LLM, side NPCs get templates)
- Cached responses (common questions answered from template library)
- Distilled models (train small model on large model's outputs)

### B. Persona Consistency Over Long Play

**Problem:** LLMs drift from persona over 100+ interactions.

**Mitigations:**
- Refresh persona prompt every N interactions
- Fine-tune model regularly (daily)
- Use state machines to enforce consistency (emotion → action must be valid)

### C. Multiplayer Coordination

**Problem:** In multiplayer, NPCs must react consistently to multiple players.
- Player A: "Guard, help me!"
- Player B: "Guard, attack that player!"
- What does guard do?

**Solution:** Implement *allegiance/faction system* (guard helps faction members, not enemies).

---

## VIII. GDC & Industry Talks (Recent)

### A. Narrative Design with Simulation (GDC 2024)

**Takeaway:** Top narrative designers emphasize systems over scripting.
- Skyrim: Systems generated more storytelling than handcrafted quests
- Stardew Valley: Relationship systems enable player attachment (less dialogue, more impact)
- Hades: Minimal dialogue, *maximum personality* (each line carries weight)

### B. NPC Believability in Open-World Games (GDC 2023)

**Patterns:**
1. **Routine-based:** NPCs follow schedules (Stardew, Skyrim), appear in expected places, feel real
2. **Relationship-based:** Player interactions change NPC behavior (Hades, Persona)
3. **Need-based:** NPCs pursue goals autonomously (RimWorld, Dwarf Fortress)

**Lesson:** *Predictability paradoxically aids believability*—players form mental models of NPCs ("the guard is always at the gate"), and NPCs following patterns feel alive.

---

## IX. Synthesis: Recommended Approach for MMO

### Phase 1: Foundation (MVP)
1. **State machines:** Simple FSM per NPC (idle, combat, talking)
2. **Need system:** 3-5 basic needs (hunger, social, safety)
3. **Relationships:** Track friendships/grudges between NPCs
4. **Memory:** Recent events (last 20 interactions)
5. **Dialogue:** Trigger-based responses + simple templates

### Phase 2: Depth (Post-MVP)
1. **Emotion modeling:** OCC model (joy, anger, sadness driven by goals)
2. **Behavior trees:** Hierarchical decision-making
3. **Skill progression:** NPCs improve at tasks
4. **Emergent narrative:** Relationships evolve, rivalries form

### Phase 3: Polish (Later)
1. **Procedural personalities:** Generate diverse NPCs
2. **LLM dialogue:** Add natural conversation (optional)
3. **Multiplayer dynamics:** NPC reactions to multiple players
4. **Consequence persistence:** World changes based on NPC deaths, achievements

---

## X. References & Papers

### Landmark Papers
- Mateas & Stern: "A Behavior Language for Story-Based Believable Agents" (AAAI 2002)
- Loyall & Bates: "Believability Through Behavior" (CMU, 1997)
- OCC Model: Ortony, Clore, Collins (1988)

### Recent Work (2023-2025)
- "Fixed-Persona SLMs with Modular Memory: Scalable NPC Dialogue" (2024)
- "An Appraisal-Based Chain-of-Emotion Architecture for Affective Game Characters" (2024)
- "LLM-Driven NPCs: Cross-Platform Dialogue System" (2024)
- "Echoes of Others: Real-Time LLM Dialogue Generation" (2025)

### Industry Resources
- GDC Talks (gamedeveloper.com)
- Game AI Pro (gameaipro.com)
- Procedural Narrative workshops (ICCC, FDG)

---

**Next:** Read `synthesis-for-mmo.md` for final recommendations tailored to our engine.
