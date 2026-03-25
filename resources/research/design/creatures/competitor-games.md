# Creature Research: Competitor Games

## Overview
Analysis of creature design patterns from classic text adventures and modern interactive fiction, with special focus on how emergent behavior and simple rules create compelling gameplay experiences.

---

## 1. Zork Series (Infocom Bestiary)

### The Grue
- **Archetype:** Invisible threat; fear/darkness incarnate
- **Mechanics:** Kills player instantly if encountered in complete darkness without light source
- **Behavior:** Lurks in dark locations; feared, never directly encountered in light
- **Design Pattern:** Creates dramatic tension through **absence and warnings** rather than complex AI
- **Sensory Design:** No visual description (intentionally); player learns through narrative ("You are likely to be eaten by a grue")
- **Application to our system:** Perfect model for environment-triggered dangers; use FSM states (danger-present vs. safe) tied to ambient light level

### The Troll
- **Archetype:** Brute obstacle guard
- **Mechanics:** Axe-wielding, blocks passage; requires combat confrontation or puzzle solution
- **Behavior:** Stationary guardian; predictable aggression
- **Design Pattern:** **Spatial gating** — blocks resources/areas until defeated
- **Application:** Creatures as location anchors; tied to room geography rather than wandering

### The Thief
- **Archetype:** Roaming antagonist with agency
- **Mechanics:** Steals valuables; appears unpredictably; combat optional (dangerous)
- **Behavior:** Autonomous movement; decision-making based on player items (attraction to treasure)
- **Design Pattern:** **Opportunistic AI** — acts on perceived advantage/value
- **Application:** First model for creature drives (hunger for valuable items); memory system (remembers what player carries)

### Other Notable Zork Creatures
- **Cyclops:** Puzzle guardian (susceptible to specific knowledge, e.g., word "ODYSSEUS")
- **Vampire Bat:** Mobile hazard; kidnaps and relocates player randomly
- **Dust Bunny, Bloodworm, Brogmoid, Cerberus, Dragon:** Environmental variety; different threat models (physical, magical, environmental)

### Key Insights
1. **Simplicity is strength:** Grue's effectiveness comes from *simplicity and narrative weight*, not complex AI
2. **Sensory design matters:** Objects described through player interaction, not visual dominance
3. **Creatures as verbs:** Creatures don't exist merely as loot — they *do things* (steal, guard, threaten)
4. **Opacity vs. clarity trade-off:** Zork embraced mystery; modern players might want clarity

---

## 2. Dwarf Fortress — The North Star

### Philosophical Foundation
Dwarf Fortress is the gold standard for emergent creature behavior in simulations. Rather than scripting specific NPC behaviors, DF defines simple rules that interact with thousands of agents, creating **emergent narratives**.

### Core Design Principles

#### 1. Needs-Driven Agency
- Creatures have **needs**: hunger, thirst, sleep, social interaction, purpose
- Each need has a **drive value** (0–100) that decays over time
- Creatures evaluate available actions and select highest-utility action based on current needs
- **Example:** A dwarf with 90+ hunger will interrupt socializing to eat, regardless of other priorities

#### 2. Personality & Relationships
- Creatures have **personality traits** (brave, cowardly, ambitious, cautious, etc.)
- Traits affect behavior selection and preference (cowardly dwarf will flee earlier than brave one)
- Creatures form **relationships** — grudges, friendships, rivalries — that alter interactions
- Relationships evolve based on shared experience (fought together, one stole from another, etc.)

#### 3. FSM + Emergent Reactions
- Creatures have simple **state machines** (idle → alert → fleeing → fighting)
- State transitions triggered by **stimuli**: injury, threat detection, need threshold
- Within a state, behavior is *contextual* — not scripted, but rule-based
- **Example:** Fleeing state chooses "run away from threat" but *which exit* depends on spatial awareness

#### 4. Ecology & Resource Competition
- Creatures are embedded in simulated **ecosystem**
- Predators and prey populations affect each other over time
- Territory control emerges from multiple creatures claiming same resources
- **Example:** Too many rats in a room → rats starve → predators leave → new rats invade

#### 5. Multi-Agent Interaction
- Creatures interact **directly with each other**, not just with player
- Two rats might fight over food; winner eats, loser flees
- Social creatures form groups; group dynamics affect individual behavior
- **Result:** Rich, unexpected interactions the designers didn't explicitly program

### DF Creature Definition Structure
In DF's RAW files, a creature is defined via metadata:
```
[CREATURE:RAT]
[BODY:BASIC_2PARTBODY]
[SIZE:5000]  # 50kg in DF units
[NATURAL_SKILL:DODGING:3]
[PREFSTRING:twitching whiskers]
[ATTACK:BITE:1d4]
[CASTE_NAME:rat:rats]
[MAXAGE:15:20]
```

The **engine** doesn't know "what a rat is." It knows how to:
- Apply skills to actions
- Track health and body parts
- Resolve hunger over time
- Select behaviors based on needs and traits
- Animate movement
- Simulate combat

### Key Insights for Our System
1. **Metadata is behavior:** Creatures declare their rules; engine executes them
2. **Simplicity scales:** 20 simple drives × thousands of creatures = emergent complexity
3. **Temporal decay drives autonomy:** Hunger increasing each tick forces creatures to *act*, not wait
4. **Ecology matters:** Creatures aren't isolated — they're part of a food web, resource competition system
5. **Personality bakes in variation:** Two identical-spec rats with different traits will behave differently

### Risks & Limitations of DF Approach
- **Complexity explosion:** Too many drives/traits can become unmaintainable; need careful subsetting for Phase 1 (rat)
- **Debugging difficulty:** Emergent behaviors are hard to trace to root cause (why did that rat flee?)
- **Performance:** Every creature on every tick evaluates every drive; scales linearly with creature count
- **Opacity:** Players may perceive "unfair" behavior if underlying rules are hidden

---

## 3. NetHack (Classic Roguelike)

### AI Philosophy
NetHack monsters use **rule-based, deterministic AI**. Most creatures follow simple scripts: pursue if hostile, flee if severely injured.

### Common Patterns
- **Pursuit:** Chase player if aware; use pathfinding to reach player
- **Fleeing:** If health drops below threshold (often 50%), flee toward exit or ally
- **Item Use:** Many monsters can drink potions, read scrolls, equip weapons — **mimicking the player's toolkit**
- **Special Quirks:** Coded behaviors for unique creatures (shopkeepers enforce commerce; nurses heal; unicorns provide lore)

### Interaction-Rich Design
- Nymphs steal items; leprechauns steal gold
- Shopkeepers get angry if you don't pay; they retaliate with combat
- Interactions often result in **emergent humor** (monster drinks poison by mistake, falls asleep, etc.)

### Key Insights
1. **Opacity as feature:** NetHack's mysterious AI encourages player experimentation and community knowledge-sharing
2. **Item interaction complexity:** Creatures using player-like tools (potions, wands) creates gameplay depth
3. **Special cases needed:** A few hardcoded quirks (shopkeeper, nurse) don't break maintainability; they add flavor
4. **Discovery learning:** Players enjoy "figuring out" creature behaviors through repeated play

### Limitations
- **Limited autonomy:** Most creatures are reactive, not proactive
- **No ecology:** Creatures don't interact with each other (except in fixed encounters)
- **Scalability issue:** Every special behavior requires custom code

---

## 4. Caves of Qud (Modern Roguelike)

### Modular AI System

Caves of Qud uses **component-based creature architecture** with XML configuration + C# scripting. Creatures are highly customizable and moddable.

#### The "Brain" Component
- Grants sentience and self-directed goals
- Can be configured to apply different **AI behaviors** to the same creature body
- Example: A mutant human might have "wandering brain" (wanders aimlessly) vs. "faction brain" (seeks faction objectives)

#### Modular Behavior Components
- `AIJuker` — creature moves erratically, hard to hit
- `AISelfPreservation` — creature flees when injured below threshold
- `AIWanderingJuggernaut` — creature charges through obstacles
- `AIWanderer` — creature explores, collects items, forms opinions
- **Custom goals via scripting** — C# allows complex logic

#### Opinion & Allegiance System
- Creatures form **opinions** of other creatures based on interactions
- Example: If creature A attacks creature B, all allies of B develop negative opinion of A
- Allegiances evolve dynamically, affecting who fights whom

#### Environmental Awareness
- Aquatic creatures stick to water; wall vines stick to walls
- Creatures optimize pathing for their **constraints** (not just shortest path to player)
- Sensory range varies by creature (keen eyes vs. blind but echolocating)

### Key Insights
1. **Modularity enables variety:** Same creature body can behave very differently based on AI component choice
2. **Faction complexity:** Allegiance systems create multi-sided conflicts, not just player vs. world
3. **Moddability is feature:** Community can tweak/extend creature behavior without forking codebase
4. **Emergent social networks:** Opinion systems create indirect relationships (enemy of my ally)

### Limitations
- **High complexity cost:** Caves of Qud's system is powerful but requires careful management
- **Performance:** Evaluating opinions for every creature pair is O(n²) in worst case
- **Learning curve:** Designers need to understand component interactions

---

## 5. Dungeon Crawl Stone Soup (Tactical Clarity)

### Philosophy
DCSS prioritizes **transparency and fairness**. Monster AI is straightforward; the game doesn't hide mechanics from the player.

### AI Patterns
- **Direct pursuit:** Most enemies head straight for player using ranged/melee
- **Tactical variants:** Different creature types have AI flavors (melee, ranged, caster, summoner)
- **Escape logic:** Creatures flee if badly hurt or if they determine player is stronger
- **Minimal surprises:** DCSS avoids "gotcha" hidden mechanics; players see what monsters see

### Transparency Benefits
- Players can **reason about encounters** without trial-and-error
- Frustration is reduced; players know they failed due to tactics, not hidden mechanics
- **Fairness:** Creature AI is constrained; creatures don't have abilities players can't access

### Key Insights
1. **Clarity over mystery:** DCSS trusts player skill; less "hidden AI" = more engaging tactical gameplay
2. **Predictability breeds mastery:** Expert players can anticipate creature moves and counter
3. **Fewer special cases:** Consistent AI rules scale better than per-creature hardcoding

---

## 6. Cross-Game Patterns & Synthesis

### Universal Patterns
1. **Threat scaling:** Easy creatures (low HP, weak attacks) appear in early game; threat increases gradually
2. **Creature roles:** Tank, glass cannon, healer, support — different creatures fill different niches
3. **Behavioral variety:** Creatures don't act identically; even "rats" vary (aggressive, cautious, cowardly)
4. **Sensory gating:** Creatures can only react to stimuli they can perceive

### Design Tension
| Game | Opacity | Simplicity | Emergent | Moddable |
|------|---------|-----------|----------|----------|
| Zork | High | Very High | Medium | No |
| DF | Medium | Medium | Very High | Medium |
| NetHack | High | High | Low | Low |
| Caves of Qud | Medium | Low | High | Very High |
| DCSS | Very Low | High | Low | Medium |

### For Our System (MMO)
**Best synthesis:** Combine DF's needs-based autonomy + Qud's modularity + DCSS's transparency

---

## 7. Applicability to MMO (Our Text Adventure)

### What We Should Steal from These Games

1. **From Zork:** Narrative weight and simplicity; a single mechanic (darkness) creates compelling threat
2. **From DF:** Needs-driven behavior; temporal decay on drives forces autonomy; ecology/food webs
3. **From NetHack:** Interaction-rich creature behavior; item use and theft add gameplay depth
4. **From Qud:** Modularity and component-based AI; allegiance/opinion systems for creatures working together
5. **From DCSS:** Transparency — players should be able to reason about creature behavior

### Phase 1 Priority: The Rat
Based on this research, a rat should:
- **Have drives:** hunger (decays), fear (resets on danger), curiosity (varies by personality)
- **Be autonomous:** moves around rooms; searches for food; flees from threats
- **Be interactive:** steals items from ground; eats player food; can be herded/trapped
- **Be predictable:** player should understand rat motivations; no hidden gotchas
- **Vary behaviorally:** some rats more curious (stay longer), others more cautious (flee quicker)

### Avoid (Anti-Patterns)
- ❌ Hardcoding rat-specific behavior in engine
- ❌ Making rat behavior opaque/mysterious
- ❌ Over-engineering Phase 1 rat; simple needs system sufficient
- ❌ Creature-creature interaction in Phase 1; focus on player-creature interaction first

---

## References & Sources

| Source | Relevance | URL |
|--------|-----------|-----|
| Zork Wiki | Bestiary patterns | https://zork.fandom.com/wiki/Grue |
| DF Systems Analysis | Emergent AI theory | https://www.theseus.fi/bitstream/handle/10024/814557/Lehner_Niilo.pdf |
| Caves of Qud Modding Wiki | Component-based AI | https://wiki.cavesofqud.com/wiki/Modding:Creature_AI |
| NetHack Wiki | Classic roguelike patterns | https://nethackwiki.com/wiki/Main_Page |
| DCSS AI Research | Tactical transparency | https://prl-theworkshop.github.io/prl2021/papers/PRL2021_paper_24.pdf |
