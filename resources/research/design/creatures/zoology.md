# Creature Research: Zoology & Animal Behavior

## Overview
Real-world animal behavior relevant to game creatures, with focus on animals that would exist in medieval dungeons/manor settings. Emphasizes ecology, predator-prey dynamics, and behavioral patterns that can inform creature design.

---

## 1. Rats in Medieval Dungeons

### Species: Black Rat (*Rattus rattus*)

#### Historical Context
- **Primary dungeon dweller:** Black rats (ship rats) colonized Europe in medieval period
- **Adaptation:** Highly adaptable; thrive in human structures (castles, dungeons, granaries)
- **Population:** Medieval people struggled to control infestations; saw them as plague bearers and pest

#### Behavioral Characteristics

| Behavior | Mechanism | Game Application |
|---|---|---|
| **Nocturnal** | Active at night; rest during day | Creatures act more in darkness; sleep/hide in daylight |
| **Omnivorous** | Eat seeds, insects, grains, sometimes meat | Scavenging drives behavior; attracted to food sources |
| **Communal nesting** | Form colonies in structures | Multiple rats coordinate movement; swarm behavior possible |
| **Rapid reproduction** | Litter every 20–30 days | Population grows quickly if unchecked; new young rats spawn |
| **Whisker sensitivity** | Use whiskers for navigation | Can navigate in complete darkness; tactile sense paramount |
| **Freezing response** | Freeze when startled; assess threat | Creatures enter "alert" state before fleeing/attacking |

#### Predator-Prey Dynamics
- **Natural predators:** Owls (nocturnal), hawks (diurnal), cats, ferrets, snakes
- **Escape tactics:** Flee to holes; climb walls; scatter when threatened
- **Survival strategy:** Speed + evasion; rarely fight (too fragile)
- **Dungeon advantage:** Few predators underground → rats dominate mid-level food chain

#### Ecological Niche in Dungeons
- **Food web position:** Scavenger of human waste; prey for predators
- **Resource competition:** With spiders, insects, other vermin for scraps
- **Habitat preference:** Dark, humid, undisturbed areas; near food sources
- **Territory size:** ~30–50 meters from nest; return to nest regularly

### Application to Game Design

```
Rat Drives (DF-inspired):
- Hunger (decay rate: high; satisfied by food scraps)
- Fear (reset on threat; moderate flee threshold)
- Curiosity (varies by individual; drives exploration)
- Nesting (maternal drive in females; return to burrow periodically)

FSM States:
- Foraging (default): Search for food; avoid light
- Alert (on danger): Freeze, assess, decide
- Fleeing (high threat): Run toward burrow/hole
- Aggressive (cornered): Bite in desperation (very rare)
```

---

## 2. Spiders in Medieval Ecology

### Characteristics

#### Hunting Strategies
- **Web builders:** Construct silken traps; wait for prey to land
- **Ambush predators:** Hide, pounce on passing insects
- **Active hunters:** Chase prey across surfaces (jumping spiders)

#### Prey
- **Primary:** Insects (flies, moths, gnats, mosquitoes)
- **Secondary:** Small arthropods (millipedes, woodlice)
- **Rare predation:** Juvenile rats or small birds (for large species only)

#### Habitat
- **Location:** Dark, undisturbed corners; crevices in stone; under eaves
- **Web placement:** Across pathways where insects fly; corners where wind currents trap prey
- **Dungeon advantage:** Spiders thrive in humid, dark, insect-rich environments

#### Size & Threat
- **Typical dungeons:** Small spiders (1–3cm); non-lethal to humans
- **Game spiders:** Giant spiders (house-cat sized) are fantasy; dungeon reality shows small spiders
- **Threat level:** Low to non-player characters; mostly ignored or feared out of superstition

### Spider-Rat Interaction
- **Direct predation:** Unlikely (adult rats too large; spiders too small)
- **Competition:** Both occupy dark niches; minimal direct conflict
- **Web interaction:** Rats avoid webs; spiders don't pursue rats
- **Ecological coexistence:** Live in same dungeon without major interaction

### Application to Game Design

```
Spider Behavior (simplified):
- Stationary (webs) vs. Roaming (hunters)
- Nocturnal tendencies (prefer darkness)
- Drawn to high-traffic insect areas
- Avoid disturbance (retreat into crevices if threatened)
- Sensory: Detect vibrations in webs; sensitive to air movement

FSM States:
- Waiting (web): Patience; detect prey vibration → attack
- Hunting (active): Prowl for insects; avoid large animals
- Threatened: Retreat to web/crevice

Danger to creatures:
- Web strands can slow movement (minor)
- Venom (real spiders) — can add immersion flavor but not lethal to adventurers
```

---

## 3. Other Dungeon Fauna: Bats, Snakes, Insects

### Bats

#### Characteristics
- **Nocturnal:** Roost during day; hunt at night
- **Echolocation:** Navigate and hunt using sound (don't rely on eyes)
- **Flight:** Extremely agile; hard to catch
- **Diet:** Insects (most species); some fruit/nectar

#### Dungeon Role
- **Behavior:** Roost in caves/attics; hunt insects that concentrate in dungeons
- **Player interaction:** Startle when disturbed; swarm behavior possible (avoid, don't attack)
- **Predator:** To insects; prey to birds if dungeon has openings

#### Game Application
- **Evasion example:** Bats can escape through high passages (flying)
- **Navigation sense:** Echolocation suggests creatures can "see" in darkness differently
- **Swarm mechanics:** Multiple bats → ambush or distraction possibility

### Snakes

#### Characteristics
- **Ambush hunters:** Wait for prey; strike when target passes
- **Sensory:** Heat pits (thermal vision); smell (track prey)
- **Constraints:** Limited speed on flat ground; climb poorly
- **Venom:** Variable (most European species non-venomous or weakly venomous)

#### Dungeon Role
- **Habitat:** Stone crevices, dark warm areas; moisture-loving
- **Behavior:** Solitary; territorial; avoid confrontation unless threatened
- **Diet:** Small mammals (mice, rats), insects, eggs

#### Game Application
- **Ambush predator mechanic:** Snakes surprise creatures from hidden locations
- **Venom as status effect:** Poisoned condition; slow damage over time
- **Thermal awareness:** Sense warm creatures through stone

### Insects & Vermin

| Species | Behavior | Game Role |
|---|---|---|
| **Beetles** | Decomposers; attracted to rot | Swarms in unsanitary areas; indicate filth |
| **Centipedes** | Fast, predatory; eat smaller insects | Dangerous if large; venomous (some species) |
| **Scorpions** | Ambush, venomous sting | High threat from single creature; rare |
| **Cockroaches** | Nocturnal, resilient, swarming | Harmless; indicate bad dungeon maintenance |
| **Flies** | Decomposers; attracted to death | Indicate corpses; swarm in large numbers; harmless |
| **Mosquitoes** | Blood-feeding; night activity | Irritant; disease vector potential |

---

## 4. Predator-Prey Relationships & Food Webs

### Simple Dungeon Food Web

```
    [Player]
       |
   [Predators]
    /  |  \
 [Rats] [Insects] [Small mammals]
    |   |       |
  [Rot] [Grain] [Plant matter]
    \   |       /
    [Detritus]
```

### Ecological Principles

#### Carrying Capacity
- **Definition:** Maximum population an area can sustain
- **Dungeon limit:** Few rats can thrive; overflow = starvation or migration
- **Game application:** If player kills predators, rat population explodes; imbalance creates challenges

#### Predator-Prey Cycles
- **Real ecology:** Predator population lags prey population; cycles occur
- **Game application:** Eliminate all rats → spiders/cats starve → disappear → rats return
- **Long-term gameplay:** Creates dynamic world; players can manipulate ecology

#### Territorial Behavior
- **Dominance hierarchies:** Strongest creature controls resource-rich area
- **Displacement:** Weak creatures forced to marginal areas
- **Game implication:** More dangerous areas have fewer total creatures (apex predators control them)

---

## 5. Nocturnal vs. Diurnal Patterns

### Dungeon Darkness = Permanent Night

In underground spaces, creatures adapt to darkness:

| Adaptation | Mechanism | Game Implication |
|---|---|---|
| **Enhanced hearing** | Larger ears; better sound detection | Creatures detect player by noise |
| **Scent tracking** | Olfactory system dominant | Creatures smell player before seeing |
| **Echolocation** | Sound wave reflection (bats) | Creatures navigate without light |
| **Heat sensing** | Thermal pits (snakes) | Creatures detect warm bodies |
| **Bioluminescence** | Some creatures glow | Provide light source; atmospheric |
| **Large eyes** | Pupils dilated; rod-dominated retina | Extreme sensitivity; low acuity |

### Behavioral Shifts
- **Nocturnal creatures** thrive in dungeon darkness (normal activity)
- **Diurnal creatures** in dungeons become lethargic (sleep during "night"/darkness)
- **Crepuscular creatures** (twilight-active) adapt to dim dungeon light

### Game Application (Time System)
Our game uses 1 real hour = 1 game day. Creatures can have **sleep cycles**:
```
2 AM (start of game): Nocturnal creatures ACTIVE
6 AM: Diurnal creatures wake; nocturnal creatures sleep
6 PM: Diurnal sleep; nocturnal creatures activate
```

---

## 6. Behavioral Ecology: Fight, Flight, Freeze

### The Three Responses

When threatened, animals follow predictable escalation:

#### 1. Freeze
- **Definition:** Become motionless; assess threat
- **Duration:** Seconds to minutes
- **Mechanism:** Predators detect movement; motionless = invisible
- **Application:** Creature enters "alert" state; player can act

#### 2. Flight
- **Definition:** Escape threat
- **Trigger:** Threat assessment determines fight/flight threshold
- **Factors:** Creature size, threat magnitude, available exits, encumbrance
- **Application:** Creature flees toward burrow/exit; disengage verb possible

#### 3. Fight
- **Definition:** Confront threat
- **Trigger:** Cornered, defending young, defending territory
- **Outcome:** Combat results based on **relative threat assessment**
- **Application:** Combat system; creature aggression based on situation

### Threat Assessment Math (Simplified)
```
Threat Level = (Creature Size / Player Size) × (Creature Armor / Player Weapon)
If Threat < threshold → Flee
If Threat > threshold → Fight
Otherwise → Freeze/Alert
```

---

## 7. Ecology of Medieval Dungeons

### Realistic Dungeon Ecosystem

Medieval dungeons were typically:
- **Damp:** Near water table; high humidity (spiders, insects thrive)
- **Dark:** No natural light beyond entrances
- **Cold:** Below surface temperature; metabolism slows
- **Filthy:** Accumulation of waste, decay, dead animals
- **Food-rich:** Stored grain, dead animals, organic matter

### Creature Populations
- **Insects:** Most abundant; multiple species
- **Rats:** Secondary scavengers; common
- **Spiders:** Predators of insects; established populations
- **Bats:** If cave entrances; roost sites
- **Snakes:** Solitary ambush predators; few individuals
- **Larger predators:** Rare; rely on rats/small mammals

### Environmental Zones
| Zone | Creatures | Conditions |
|---|---|---|
| **Entrance** | Mixed (light, fresh air) | Diurnal creatures; insects; occasional larger animals |
| **Mid-tunnel** | Nocturnal dominance | Darkness; cool; rats, spiders, bats |
| **Deep cavern** | Extremophiles | Perpetual darkness; cold; sparse but adapted creatures |
| **Storage areas** | Rat-dominated | Food source nearby; comfortable; high population |
| **Flooded areas** | Aquatic/amphibious | Water-dependent creatures (frogs, aquatic insects, eels) |

---

## 8. Behavioral Patterns for Game Creatures

### Pack Behavior (Rats, Wolves)
- **Coordination:** Individuals respond to group dynamics
- **Hierarchy:** Dominant individual leads; others follow
- **Mob confidence:** Larger pack → bolder behavior
- **Game mechanic:** 1 rat flees; 3 rats might attack together

### Territorial Behavior
- **Marking:** Creatures mark territory (scent); warn others away
- **Defense:** Will fight to defend territory against same species
- **Border patrol:** Creatures check territory boundaries regularly
- **Game mechanic:** Creatures respawn in same area; player disrupting territory = increased aggression

### Maternal/Protective Behavior
- **Vulnerability period:** Young animals + mother nearby = high danger
- **Mother aggression:** Normally docile mother extremely dangerous near young
- **Game implication:** Find rat nest → mother rat becomes aggressive threat

### Scavenging Behavior
- **Opportunistic:** Creatures eat whatever is available
- **Learning:** Some creatures learn player is food source (dangerous escalation)
- **Competence:** Competition over dead animals; fights break out

---

## 9. Applicability to MMO (Text Adventure)

### Creature Design Template (Zoologically Informed)

For each creature, use this framework:

```
SPECIES: Rat
HABITAT: Dungeon (dark, damp, underground)
SIZE: 15–25 cm
LIFESPAN: 2–3 years
REPRODUCTION: Rapid; litter every 30 days

SENSORY PROFILE:
- Vision: Poor in darkness; worse than human
- Hearing: Excellent; detect movement/vibrations
- Smell: Acute; track scents over distance
- Touch: Whiskers detect air movement; tactile navigation

BEHAVIORS:
1. Nocturnal Activity (night = active, day = sleepy)
2. Communal Nesting (return to burrow regularly)
3. Scavenging (search for food continuously)
4. Threat Response (freeze → flee → fight, in order)
5. Territorial (mark and defend nest area)

DIET: Omnivorous; prefer grains, seeds, insects, carrion

SOCIAL STRUCTURE: Loose hierarchy; cooperative nursing

PREDATORS: Owls, hawks, cats, snakes, ferrets, humans

FSM STATES:
- Foraging: Default; search for food
- Alert: Threat detected; freeze/assess
- Fleeing: High threat; run toward safety
- Defending: Cornered; bite (rare)
- Resting: Satisfied hunger; sleep in nest

DRIVES (DF-inspired):
- Hunger: Increases 2 points/turn; reset to 0 on eating
- Fear: Increases on threat detection; reset on safety
- Curiosity: Baseline 50; varies 30–70 by personality
- Nesting: Increases over time; satisfied by returning to burrow
```

### Phase 1 Rat Implementation Priorities
1. **Hunger drive:** Makes rat forage; search for player food
2. **Fear response:** Makes rat flee from threats; create evasion gameplay
3. **Nocturnal cycle:** Rat active/inactive based on time of day
4. **Stealing behavior:** Rat takes items from ground; theft as interaction
5. **Swarm emergence:** Multiple rats can coordinate if hungry

---

## 10. References & Sources

| Topic | Source | Relevance |
|---|---|---|
| Black rat ecology | Medieval historians, UK Museum studies | Historical accuracy for setting |
| Rat behavior | NIH, university animal behavior studies | Naturalistic creature behavior |
| Spider ecology | Entomology journals, university extensions | Dungeon ecosystem modeling |
| Predator-prey dynamics | Lotka-Volterra equations, ecology textbooks | Population cycling |
| Dungeon organisms | Historical archaeology, castle studies | Authentic dungeon fauna |
| Nocturnal adaptation | Comparative physiology | Sensory system design |
| Threat assessment | Animal behavior ethology | Behavioral FSM design |
