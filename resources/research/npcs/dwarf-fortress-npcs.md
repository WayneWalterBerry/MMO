# Dwarf Fortress NPC Architecture: Deep Research

**Primary Research Document** — Dwarf Fortress creature/NPC simulation is foundational to understanding how to build **believable, emergent NPCs at scale**.

---

## Executive Summary

Dwarf Fortress (DF) represents the gold standard for emergent NPC behavior in games. With 1000+ concurrent dwarves per fortress, each with unique needs, personality, skills, and memories, DF demonstrates that *simple, granular systems composed together create complex, organic behavior*. The engine doesn't script individual stories—it simulates a world where stories emerge naturally from the interaction of traits, needs, relationships, and world events.

**Key Insight for MMO:** DF's architecture is **systems-driven, not script-driven**. Apply this principle: *Don't author NPC behaviors; author the rules that generate them.*

---

## I. Creature Architecture: The Foundation

### A. Creature Definition (RAW Files)

In Dwarf Fortress, creatures are defined in `RAW` text files (procedurally generated data, not code). Each creature specifies:

- **Body structure:** Which body parts exist, their size, material, and connections
- **Material properties:** How the creature is constructed (bone, muscle, fat, etc.), each with physical properties
- **Tissues:** Intermediate layer that groups materials (e.g., skin, cartilage)
- **Attributes:** Base mental and physical stats (strength, agility, analytical ability, creativity, memory, etc.)

**Why This Matters:**
- Creature behavior emerges from **material composition**. A dwarf with stronger bones fights differently than one who doesn't. Tissue integrity directly affects combat capability.
- This mirrors our engine's principle: *objects' behavior flows from their material properties*.
- NPCs aren't monolithic; they're compositional—body parts can be damaged, replaced, or modified.

### B. Individual Differentiation

Each dwarf spawns with:
- **12 mental attributes** (analyzed ability, creativity, spatial sense, etc.), procedurally generated and weighted
- **30+ personality facets** (friendliness, anxiety, pride, chastity, patience, etc.) scored on a scale
- **Preferences** (food, drinks, materials, colors, animals)—unique, non-universal
- **Beliefs and values** (religious convictions, philosophy)
- **Dreams** (aspirations and fears)

**Impact:**
- Two dwarves react to the same event differently based on personality
- A dwarf with high anxiety becomes traumatized easier; one with high courage recovers faster
- Personality persists through the entire simulation

---

## II. Needs & Desires System: The Behavior Driver

### A. The Pyramid of Needs

Dwarves experience layered needs:

1. **Physiological (Immediate):**
   - Hunger (food)
   - Thirst (alcohol)
   - Sleep
   - Temperature regulation

2. **Social/Emotional (Short-term):**
   - Socializing/companionship (scales with personality: gregarious dwarves need more)
   - Prayer/religion
   - Recreation/alcohol
   - Combat/violence (for aggressive personalities)

3. **Psychological/Creative (Medium-term):**
   - Creative expression
   - Craftsmanship (satisfaction from quality work)
   - Achievement
   - Self-expression

### B. Need-Driven Behavior

**The Mechanism:**
- When a need goes unmet, a dwarf accumulates "unhappy thoughts" (e.g., "has not been meeting spouse recently," "no access to alcohol").
- Conversely, meeting needs generates "happy thoughts" (e.g., "saw a beautiful artifact," "ate at a legendary table").
- The **sum of happy and unhappy thoughts** determines overall mood/happiness.

**Emergent Result:**
- A depressed dwarf works slower, makes mistakes, and may spiral into tantrums.
- A satisfied dwarf works faster, is more creative, and can inspire others.
- NPCs have **agency in pursuing their own happiness**—they make decisions based on need fulfilment, not scripted paths.

### C. Strange Moods & Creative Inspiration

Occasionally, a dwarf enters a "strange mood":
- They become obsessed with a specific material or object
- They claim a workshop and require specific materials to craft an artifact
- If satisfied: They create a **legendary artifact** and gain legendary skill in a craft
- If denied: They potentially go insane, tantrum, or commit violence

**Why This Matters:**
- Moods are **emergent from need-state**, not hand-authored cutscenes
- They create risk/reward for the player and narrative tension
- They exemplify how *internal state drives external action*

---

## III. Personality & Social Model

### A. Personality as Behavioral Filter

Each personality facet biases decision-making:
- **High Friendliness** → actively seeks social interaction, gets unhappy faster when isolated
- **High Anxious** → more likely to flee danger, gets traumatized by combat
- **High Pride** → resents mistreatment, holds grudges longer
- **High Chastity** → doesn't tolerate certain behaviors, may get upset by crude jokes or exposure

**Key:** Personality doesn't *determine* behavior—it *biases* the tendency. A cowardly dwarf might still fight to protect a friend, but they're unhappy about it.

### B. Relationships & Social Bonds

Dwarves form relationships based on:
- **Shared experience:** Living together, working together, surviving danger together
- **Traits:** Similar personalities attract (or clash, depending on the trait)
- **Personality match:** A patient dwarf tolerates a lazy dwarf's quirks; an impatient one doesn't

**Relationship Types:**
- Friendships (mutual respect)
- Romantic bonds (marriages, lovers)
- Loyalty (to leaders, mentors, family)
- **Grudges** (lasting resentment from betrayal, injury, insult)

**Emergent Behaviors:**
- Friends defend each other in combat, becoming dualistically strong units
- A dwarf may commit violence in revenge for a fallen friend
- Morale boosts spread among friends
- Entire fortresses can collapse if a beloved dwarf dies (everyone gets "lost loved one" thought)

### C. Artifact & Legend Integration

Dwarves remember:
- Who killed their friends
- Who saved them
- Major historical events (fortress founding, wars, artifact creation)
- These memories persist across fortress resets

**This enables:**
- Grudges that drive narratives (a dwarf may pursue a personal vendetta for their entire life)
- Heroic stories (legendary figures inspire others)
- Complex social hierarchies based on earned respect

---

## IV. Job & Labor System: Autonomy Within Constraints

### A. Skill Progression

- Each dwarf has skills in 80+ possible labors (mining, crafting, combat, medicine, etc.)
- Skills improve through *practice and repetition*
- A legendary miner is faster, more accurate, and occasionally creates high-quality results
- **Expertise matters:** Assigning a novice to perform complex surgery kills the patient; assigning a legendary surgeon saves them

### B. Job Assignment Strategy

**Player-Driven:**
- Enable/disable labors on dwarves (labor toggle)
- Designate workshops and tasks
- The simulation auto-assigns idle dwarves to available tasks

**NPC-Driven (Autonomy):**
- A dwarf *chooses* which job to perform if multiple are available
- Dwarves may prioritize based on:
  - Current mood and need state (a hungry dwarf might cook before crafting)
  - Skill level (a skilled metalsmith might gravitate toward metalsmithing)
  - Personality (an artistic dwarf might prefer crafting over mining)

**Result:** NPCs are semi-autonomous agents, not puppets. The player *constrains* the space of options (by enabling/disabling labors and designating tasks), but the dwarf *decides* within that space.

---

## V. AI Decision-Making: Emotion, Thought, & Action

### A. The Thought System

Dwarf Fortress maintains a **log of thoughts** for each dwarf:
- Recent experiences ("lost spouse," "saw a beautiful artifact," "failed at trading")
- Relationships ("is best friends with X," "has grudge against Y")
- Occupational notes ("mastered mining," "failed at weapon training")
- Environmental state ("too crowded," "very scared")

**Thoughts decay over time**, with longer-lasting memories (years) for major events and shorter-term (days/weeks) for minor ones.

### B. Emotional State Machine

Dwarves operate in distinct emotional states:
- **Normal:** Executing assigned jobs, social interactions
- **Afraid/Fleeing:** When threatened, dwarves (based on personality) may panic and run
- **Combat:** Engaged with enemy, behavior switches to tactical (seek cover, attack)
- **Tantrum/Rampage:** Extreme unhappiness triggers violence; the dwarf attacks nearby entities
- **Melancholic:** Deep depression; the dwarf stops working, may refuse food/drink

**State Transition Logic:**
- Events trigger state changes (enemy sighted → Afraid or Combat depending on personality)
- Thoughts accumulate to shift state (enough unhappy thoughts → Tantrum threshold)
- Recovery is also gradual (as thoughts decay and new positive events occur)

### C. Decision Framework: Utility Calculation

When choosing between actions, a dwarf implicitly scores options:
- **Hunger + Food Available** → High utility for cooking/eating
- **Unhappy + Social Opportunity** → High utility for conversation
- **Tired + Bed Available** → High utility for sleeping
- **Job Available + Skilled in Labor** → Utility increases with skill level

**Result:** Dwarves don't follow explicit priority lists—they pursue the action with highest utility at the moment.

### D. Long-Term Goals & Ambitions

In newer versions, dwarves have **ambitions** (long-term goals):
- "Become a legendary smith"
- "Master a trade"
- "Achieve a personal dream/mood"
- "Raise a family"

These drive behavior over weeks/months, competing with immediate needs and creating narrative arcs within each dwarf's story.

---

## VI. Temporal Simulation & Scale

### A. Time Resolution

Dwarf Fortress runs at multiple time scales:
- **Tick:** Smallest unit (game time = real time at 100x acceleration) ~20-100ms real-time per tick
- **Season:** In-game year divided into 4 seasons; world events happen seasonally
- **Year:** Annual reckonings; civilizations rise/fall; trade caravans arrive
- **Historical Time:** Centuries of world history are generated before play begins

### B. Scaling to 1000+ Dwarves

**How DF manages scale:**
- Most dwarves are processed every tick (pathfinding, job assignment, thought updates)
- **Optimization:** Distant dwarves/creatures use lower-fidelity simulation
- **Spatial partitioning:** Only nearby entities fully simulate interactions
- **Skill caching:** Recent actions are cached to avoid re-evaluating every tick
- **Event queue:** Major events (injuries, moods, death) trigger updates; not all states change constantly

**Performance Strategy for MMO:**
- Not every NPC needs full simulation every frame
- Dwarves *outside player perception* can use lower-fidelity state machines
- When an NPC enters the player's sensory range, transition to full simulation
- Use event-driven updates for major state changes (wounds, mood shifts, relationships)

---

## VII. Social Contagion & Emergent Dynamics

### A. Morale & Emotional Spread

When one dwarf gets an unhappy thought, nearby dwarves can "catch" it:
- "Learned about the death of a friend" spreads sadness
- A rampage by one dwarf can trigger panic in others (if they're prone to fear)
- Conversely, legendary achievements inspire nearby dwarves

**Mechanism:**
- When NPC A experiences a significant event, nearby NPCs B, C, D get related thoughts
- The intensity decreases with social distance (friend gets a stronger thought than acquaintance)

### B. Emergent Violence & Conflict

- A dwarf insulted by another may start a brawl
- If one dwarf dies, their family/friends may pursue the killer
- Entire squads can be triggered to combat by leadership
- Civil conflicts can erupt if different value systems clash (religious zealots vs. pragmatists)

**All of this emerges from rule interaction, not scripted conflict.**

---

## VIII. Lessons for MMO NPC Architecture

### A. Principle 1: State ≠ Action

Dwarf Fortress separates *state* (needs, personality, thoughts, mood) from *action* (job, movement, interaction). This decoupling is critical:
- Change state → action naturally adapts
- No need to script every behavior combination
- Supports emergent NPC responses to player actions

**For MMO:** NPCs should have persistent *internal state* (emotion, need, relationship) that drives *transient actions* (current job, conversation, movement). Don't code "100 dialogue trees"; code a *state-action generator* that creates context-appropriate responses.

### B. Principle 2: Composition Over Inheritance

Each dwarf is a bundle of personality facets, needs, skills, and relationships. Rather than "Dwarf Class" → "Fighter Dwarf" → "Elite Fighter," DF uses **composition:** a dwarf with high combat skill, low anxiety, and a grudge against goblins naturally *behaves like* an elite fighter without explicit classification.

**For MMO:** Use component-based architecture (traits, needs, relationships) to compose NPC behavior rather than inheritance hierarchies.

### C. Principle 3: Time-Scaled Simulation

Not all simulation happens at the same granularity:
- *Player-relevant* NPCs simulate every tick
- *Distant* NPCs use lower-fidelity updates
- *Historical* world state updates seasonally/annually

**For MMO:** Stratify NPC simulation by player proximity. Distant NPCs can use summary states (mood, current task) rather than full behavior trees.

### D. Principle 4: Persistence & Continuity

Every thought, relationship, and skill persists. Dwarves remember:
- Who wronged them (grudges drive long-term behavior)
- Who helped them (friendships drive cooperation)
- What they've achieved (pride, confidence affect future behavior)

**For MMO:** Make NPC memory and relationship history *first-class data*. Don't erase NPC state between sessions. Let long-term consequences flow from player choices.

### E. Principle 5: Needs Drive Emergent Behavior

DF doesn't script "dwarf gets thirsty → finds tavern → drinks beer." Instead:
- Needs accumulate (thirst increases)
- A need state biases action selection (high thirst → drinking beverages high utility)
- NPCs autonomously pursue need satisfaction

**For MMO:** Use need hierarchies to drive NPC behavior. Rather than explicit schedules, let NPCs pursue needs based on current state and available resources.

### F. Principle 6: Personality as Behavioral Bias

DF doesn't use personality to *determine* action; it *biases* the choice distribution:
- A cowardly dwarf is *more likely* to flee, but not *guaranteed* to
- A proud dwarf *resents* insults more, but can tolerate them if sufficiently important

**For MMO:** Personality should affect *probability and intensity* of action, not make it deterministic. Enable surprises and variability.

---

## IX. Scale Considerations for MMO

### Simulation Complexity

Dwarf Fortress with 1000+ dwarves on a modern PC manages this by:
1. **Hierarchical updates:** Not all entities update every frame
2. **Event-driven architecture:** Major changes trigger updates; stable systems rest
3. **Spatial awareness:** Only nearby entities fully interact
4. **Skill/state caching:** Reduce redundant calculations

For **100 NPCs across 50 rooms**:
- Full simulation cost: ~O(N * M) where N = NPCs, M = decision points per NPC
- With hierarchical updates: ~O(N * log(M)) by batching distant NPCs
- **Estimated overhead:** 2-5% CPU at 60 FPS on modern hardware for 100 NPCs with moderate behavioral complexity

### Memory Footprint

Per NPC, store:
- Needs state: 5-10 values (hunger, thirst, social, etc.)
- Personality: 30+ facet scores (~120 bytes)
- Skill table: 80+ skills, 1 byte each (~80 bytes)
- Relationship map: Hash of (dwarf_id → relationship_type) (~200 bytes per 10 relationships)
- Thought queue: Recent 50 thoughts (~2 KB)
- **Total per NPC:** ~3-5 KB

For 100 NPCs: **300-500 KB base state**, well within reasonable memory budgets.

---

## X. What Makes DF NPCs Feel Alive

1. **Consistency:** NPCs remain true to personality over time; they're not random
2. **Consequence:** Actions have lasting effects (grudges last years, achievements are remembered)
3. **Variability:** Two dwarves never respond identically to the same event
4. **Agency:** NPCs pursue their own goals (needs, ambitions), not just react to player
5. **Narrative Emergence:** Complex stories arise from simple rule interactions; each playthrough is unique
6. **Scale & Depth:** With 1000+ unique dwarves, each feeling somewhat alive, the world feels populated

**Key Insight:** Aliveness comes from *persistent state* + *autonomous goal pursuit* + *personality-driven variation*, not from perfect dialogue or animation.

---

## XI. Shortcomings & What DF Doesn't Do Well

1. **Dialogue:** DF has no real NPC dialogue system (recent version added names/nicknames, but no conversation)
   - **Implication for MMO:** We need a separate dialogue layer; simulation alone won't suffice
2. **Spatial Reasoning:** DF's pathfinding is basic; NPCs sometimes make inefficient choices
   - **Implication:** Modern A* pathfinding should supplement needs-based behavior selection
3. **Learning:** Dwarves don't learn from experience beyond skill progression
   - **Implication:** Consider adding *strategy learning* for NPCs (e.g., "last time I walked into fire, I died; avoid that path")
4. **Multiplayer Dynamics:** DF is single-player; coordination between player and NPCs is limited
   - **Implication:** For MMO, we need explicit *cooperation frameworks* (shared goals, communication protocols)

---

## XII. Synthesis: How to Port DF Concepts to Text Adventure

1. **Needs System:** Implement 5-10 core needs (hunger, thirst, social, safety, meaning)
   - Each NPC has need state that changes over time
   - Needs bias action selection
   
2. **Personality:** Use DF's facet model (30+ traits, each 0-100 scale)
   - Store as compact bit-vector or table
   - Use for *probability weighting*, not determinism

3. **Relationships:** Explicit relationship graph
   - (NPC_A, NPC_B) → { type: friendship | rivalry | family, strength: 0-100, history: [...] }
   - Track grudges and achievements between NPCs

4. **Thoughts & Memory:** Event log per NPC
   - Recent events bubble up; old ones decay
   - Query: "What do I remember about X?" → filtered thought history
   - Support for evoking thoughts in dialogue

5. **Skills & Progression:** Track 10-30 relevant skills per NPC
   - Skill affects action success probability
   - Use in dialogue (skilled healer gives better medical advice)

6. **Simulation Tick:** Update NPC state (needs, skills, relationships) every in-game minute/hour
   - Not every interaction; sparse updates for distant NPCs

7. **Autonomy:** Each NPC has a *goal queue* (current task, next task, long-term ambition)
   - Update based on current need state, available tasks, personality bias
   - Player can *suggest* tasks, but NPC may prioritize differently

---

## References & Further Reading

- Dwarf Fortress Wiki: https://dwarffortresswiki.org/
- Academic: "SYSTEMS-BASED GAME DESIGN IN DWARF FORTRESS" (Lehner)
- Academic: "Interpreting Dwarf Fortress: Finitude, Absurdity, and Narrative"
- DFHack documentation: https://docs.dfhack.org/
- Community: "Dwarf Fortress as AI Research Platform" discussions

---

**Next:** Read `mud-npc-systems.md` for comparison with classic MUD architecture.
