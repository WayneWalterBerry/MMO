# NPC + Combat Phase 2 — Chunk 4: Feature Breakdown + Integration

**Author:** Bart (Architect)  
**Date:** 2026-07-28  
**Status:** Draft  
**Chunk:** 4 of N  
**Scope:** Detailed system specs + cross-system integration points  
**Governs:** Phase 2 new systems (Creature Generalization, NPC-vs-NPC Combat, Disease, Food PoC)

---

## Table of Contents

- [1. Feature Breakdown per System](#1-feature-breakdown-per-system)
  - [A. Creature Generalization System](#a-creature-generalization-system)
  - [B. NPC-vs-NPC Combat System](#b-npc-vs-npc-combat-system)
  - [C. Disease System](#c-disease-system)
  - [D. Food Proof-of-Concept](#d-food-proof-of-concept)
- [2. Cross-System Integration Points](#2-cross-system-integration-points)

---

## 1. Feature Breakdown per System

### A. Creature Generalization System

Phase 1 built the creature engine around one animal — the rat. Phase 2 proves the system generalizes to creatures with fundamentally different behavior profiles: predators, territorial defenders, ambush trappers. The engine changes are **zero creature-specific code** (Principle 8). Every new behavior emerges from metadata the existing `creature_tick()` already evaluates.

#### A.1 Creature-to-Creature Reactions

**Problem:** Phase 1 creatures only react to player stimuli (`player_enters`, `player_attacks`). Phase 2 creatures must react to each other — a cat must chase a rat, a dog must growl at a cat, a spider must ignore anything too large to trap.

**Solution: Creature-sourced stimuli.** Extend the existing stimulus system so creature actions (movement, vocalization, death) emit stimuli that other creatures can react to. The stimulus pipeline is already generic — `creatures.emit_stimulus(room_id, type, data)` accepts any stimulus type. We add creature-sourced types and creature-targeted reactions.

**New stimulus types:**

| Stimulus | Emitted When | Data Fields |
|----------|-------------|-------------|
| `creature_enters` | Creature moves into a room | `{ source = creature, from_room = id }` |
| `creature_exits` | Creature leaves a room | `{ source = creature, to_room = id }` |
| `creature_dies` | Creature health → 0 | `{ source = creature, killer = attacker_or_nil }` |
| `creature_vocalizes` | Creature performs vocalize action | `{ source = creature, sound = string }` |

**Reaction evaluation change:** `process_stimuli()` currently matches stimulus type against the creature's `reactions` table. No code change needed — a cat that has `creature_enters` in its reactions table already reacts. What changes is the **data**: reactions gain an optional `source_filter` to discriminate which creatures trigger them.

```lua
-- Cat reaction: only triggered by creatures matching its prey list
reactions = {
    creature_enters = {
        source_filter = "prey",   -- only fires if source.id is in behavior.prey
        action = "attack",
        message = "The cat's ears flatten. Its body tenses.",
        delay = 0,
    },
}
```

**`source_filter` resolution** (in `process_stimuli()`):

```lua
-- Pseudocode for source_filter evaluation
if reaction.source_filter == "prey" then
    if not table_contains(creature.behavior.prey, stimulus.data.source.id) then
        skip  -- stimulus source is not prey; ignore
    end
elseif reaction.source_filter == "predator" then
    if not table_contains(creature.behavior.predator, stimulus.data.source.id) then
        skip  -- not a predator; ignore
    end
elseif reaction.source_filter == nil then
    pass  -- no filter; react to all sources (existing behavior)
end
```

**Engine change:** ~15 lines added to `process_stimuli()` in `src/engine/creatures/init.lua`. No new modules.

#### A.2 Predator-Prey Metadata

**Format:** Two optional arrays on the `behavior` table:

```lua
behavior = {
    prey = { "rat", "mouse", "bird" },      -- creatures this one hunts
    predator = { "cat", "wolf", "hawk" },    -- creatures this one flees from
    -- existing fields unchanged
}
```

**Semantics:**

| Field | Effect on Behavior | Used By |
|-------|-------------------|---------|
| `prey` | When a prey creature is in the same room, this creature's `creature_enters` reaction fires with `source_filter = "prey"`. The reaction action is typically `attack` (enters combat). | `process_stimuli()`, `score_actions()` |
| `predator` | When a predator is in the same room, this creature's `creature_enters` reaction fires with `source_filter = "predator"`. The reaction action is typically `flee` with a high fear_delta. | `process_stimuli()`, `score_actions()` |

**Prey/predator is directional.** Cat has `prey = {"rat"}`. Rat has `predator = {"cat"}`. These are independent declarations — the engine doesn't infer one from the other. This is intentional: a wolf might consider a cat prey but a cat might not consider a wolf a predator (cats don't always flee wolves — they climb).

**No predator-prey registry.** Each creature declares its own relationships. The engine discovers them at stimulus time by checking the reacting creature's `prey`/`predator` arrays against the stimulus source's `id`. This follows Principle 8 — the engine reads metadata, not lookup tables.

#### A.3 Territorial Behavior

Phase 1 has `territorial = false` and `home_room = nil` on the creature template. Phase 2 activates these fields for creatures like the guard dog.

**Metadata format:**

```lua
behavior = {
    territorial = true,
    home_room = "hallway",              -- room ID this creature defends
    territory_aggression = "on_intrude", -- when to act aggressively
    territory = { "hallway", "foyer" }, -- optional: multiple rooms in territory
}
```

**`territory_aggression` values:**

| Value | Behavior |
|-------|----------|
| `"on_intrude"` | Attack any non-ally creature or player that enters territory rooms |
| `"on_provoke"` | Growl/vocalize warning on intrude; attack only if provoked |
| `"patrol"` | Wander between territory rooms; attack intruders on sight |

**Engine integration:** `score_actions()` gains a territory bonus. When a creature with `territorial = true` is in one of its `territory` rooms and a non-prey, non-predator entity enters, the `attack` action score gets a territory bonus (+30 by default). This makes territorial creatures strongly prefer attacking intruders in their home turf but still allows fear to override (flee_threshold still applies).

```lua
-- In score_actions(), after existing utility scoring:
if creature.behavior.territorial and
   table_contains(creature.behavior.territory or {creature.behavior.home_room}, current_room_id) and
   has_intruder(context, creature) then
    scores["attack"] = (scores["attack"] or 0) + 30
end
```

**Territory wander:** Creatures with `territory_aggression = "patrol"` get their `wander` action constrained to territory rooms only. The existing `wander` action picks a random valid exit — we add a filter that rejects exits leading outside the territory.

#### A.4 Attack Action: creature_tick() → Combat FSM

Phase 1 deferred the `attack` action — when `score_actions()` selected it, the creature fell back to `flee`. Phase 2 enables it.

**Attack action flow:**

```
creature_tick() evaluates behavior
  → score_actions() picks "attack" as highest utility
  → execute_action("attack", creature, context)
    → select target: find_attack_target(creature, context)
    → select weapon: select_natural_weapon(creature)
    → enter combat: combat.initiate_exchange(creature, target, weapon, context)
    → collect narration messages from combat result
    → return messages
```

**`find_attack_target(creature, context)`:**

1. Get all entities in the creature's room (player + other creatures)
2. Filter by `target_priority` from `combat.behavior`:
   - `"closest"` → first entity in room contents (insertion order)
   - `"weakest"` → lowest health fraction (`health / max_health`)
   - `"threatening"` → entity that last attacked this creature (tracked in `creature._last_attacker`)
   - `"random"` → random selection
   - `"prey_only"` → only target creatures in `behavior.prey` list
3. Return target or `nil` (if nil, fall back to `idle`)

**`select_natural_weapon(creature)`:**

Reads `combat.behavior.attack_pattern`:
- `"random"` → pick randomly from `combat.natural_weapons`
- `"strongest"` → pick weapon with highest `force`
- `"cycle"` → round-robin through weapons (track index in `creature._weapon_cycle_idx`)
- specific `id` → always use that weapon

**Integration point:** `execute_action()` in `src/engine/creatures/init.lua` gains an `"attack"` branch that calls into `src/engine/combat/init.lua`. The combat module's `resolve_exchange()` already handles NPC combatants — it reads `combat.behavior` metadata for NPC decisions. No combat module changes required for basic creature-initiated attacks.

#### A.5 Spider Web Creation: Creature-Created Objects

Spiders introduce a new pattern: creatures that create objects as part of their behavior. A web is a normal object — it has a template, sensory fields, FSM states — but it's spawned by the spider's tick, not placed by a room definition.

**Web object definition (`src/meta/objects/spider-web.lua`):**

```lua
return {
    guid = "{new-guid}",
    template = "small-item",
    id = "spider-web",
    name = "a thick spider web",
    keywords = { "web", "spider web", "cobweb", "silk" },
    description = "Sticky silk threads span the passage, glistening faintly.",
    
    on_feel = "Your fingers stick. Thin, incredibly strong threads coat your skin.",
    on_smell = "A faint musty sweetness.",
    on_listen = "Silent, unless something struggles in it.",
    
    material = "silk",
    size = "medium",
    weight = 0.1,
    portable = false,
    
    -- Trap behavior
    trap = {
        type = "ensnare",
        max_size = "small",         -- catches creatures size ≤ small
        on_trigger = {
            message_victim = "You walk into a web! Sticky threads cling to your arms and face.",
            message_room = "Something thrashes in the spider web.",
            effect = "restrained",  -- prevents movement for N turns
            duration = 3,           -- restrained for 3 turns
        },
    },
    
    -- FSM: webs can be destroyed
    initial_state = "intact",
    _state = "intact",
    states = {
        intact = {
            description = "A thick spider web blocks the passage.",
            room_presence = "A spider web stretches across the doorway.",
        },
        damaged = {
            description = "A torn spider web hangs in tatters.",
            room_presence = "Torn webbing hangs from the walls.",
        },
    },
    transitions = {
        { from = "intact", to = "damaged", verb = "cut" },
        { from = "intact", to = "damaged", verb = "break" },
        { from = "intact", to = "damaged", verb = "burn", requires_tool = "fire_source" },
    },
    mutations = {
        burn = { becomes = "spider-web-burned", message = "The web shrivels and blackens." },
    },
}
```

**Spider `create_web` action:**

New action type in the creature action system. When a spider's `score_actions()` selects `create_web`:

```lua
-- In spider behavior metadata:
behavior = {
    default = "idle",
    territorial = true,
    home_room = "cellar",
    territory = { "cellar" },
    territory_aggression = "on_intrude",
    create_web_chance = 30,     -- 30% chance per tick when idle in territory
    max_webs_per_room = 2,      -- don't fill a room with webs
}
```

**`execute_action("create_web")` flow:**

1. Check `creature.behavior.max_webs_per_room` against current web count in room
2. If under limit: instantiate `spider-web` via the loader (same path as room instance loading)
3. Register new object in context.registry
4. Add to current room's contents
5. Emit message: *"The spider works its spinnerets, stretching silk across the passage."*
6. Return messages

**Engine change:** Add `"create_web"` to the action dispatch table in `execute_action()`. The action is generic — it reads `creature.behavior.created_object` (defaults to `"spider-web"`) and instantiates it. Future creatures that create objects (bird nests, ant tunnels) use the same action with different `created_object` values.

```lua
-- Generic object-creation action metadata (on spider):
behavior = {
    created_object = "spider-web",   -- object ID to instantiate
    create_chance = 30,
    max_created_per_room = 2,
}
```

**Trap evaluation:** Traps fire during movement. When a creature or player enters a room, the movement handler checks room contents for objects with a `trap` field. If the moving entity's `size` ≤ `trap.max_size`, the trap triggers. This is a ~10-line check in `movement.lua`, not a creature-specific feature.

---

### B. NPC-vs-NPC Combat System

#### B.1 Unified Combatant Interface

Phase 1's combat FSM already accepts any entity with a `combat` table, `body_tree`, and `health`/`max_health` fields. The `resolve_exchange(attacker, defender, weapon, target_zone)` function makes no distinction between player and creature — the same math, narration, and injury pipeline handles all combatant types.

**What Phase 2 adds:** The initiation pathway. Phase 1 enters combat only through player verbs (`attack rat`). Phase 2 adds creature-initiated combat via the `attack` action in `creature_tick()` (see A.4 above) and automatic predator-prey triggering.

**Combatant interface contract** (any entity that fights must have):

```lua
{
    id = string,              -- creature/player ID
    name = string,            -- display name
    health = number,          -- current HP
    max_health = number,      -- max HP
    alive = true,             -- animate flag
    combat = {                -- combat metadata table
        size = string,        -- "tiny" | "small" | "medium" | "large" | "huge"
        speed = number,       -- initiative (1-10)
        natural_weapons = {}, -- array of weapon specs
        natural_armor = nil,  -- or armor spec
        behavior = {},        -- NPC decision-making (ignored for player)
    },
    body_tree = {},           -- zone specs for targeting
}
```

The player satisfies this via `ctx.player.combat` and `ctx.player.body_tree`. Creatures satisfy it via their `.lua` definition files. No adapter layer needed.

#### B.2 Multi-Combatant Turn Order

Phase 1 is strictly 1v1 — one attacker, one defender per exchange. Phase 2 supports N combatants in a single fight (cat vs. rat while player watches, or player + cat vs. wolf pack).

**Turn order algorithm:**

```
Given: combatants[] -- all entities in the fight

1. Sort combatants by combat.speed (descending)
2. On tie: smaller creature goes first (SIZE_ORDER["tiny"] > SIZE_ORDER["small"] > ...)
3. On tie: player goes first (home-field advantage)

Result: ordered turn list for this round
```

**Round execution:**

```
for each combatant in turn_order:
    if combatant.alive and combatant still in fight:
        target = select_target(combatant, other_combatants)
        if target is nil:
            combatant exits fight (no valid target)
        else:
            weapon = select_weapon(combatant)
            result = resolve_exchange(combatant, target, weapon, zone)
            narration += result.messages
            
            -- Post-exchange checks
            if target.health <= 0:
                handle_death(target)
                remove target from combatants
            if combatant morale check fails:
                combatant flees; remove from combatants
```

**Multi-combatant targeting:** Each NPC combatant uses `combat.behavior.target_priority` to select which opponent to attack. In a 3-way fight (player, cat, rat), the cat targets the rat (prey), the rat targets whoever attacked it (threatening), and the player targets whoever they chose.

**Fight tracking:** A new `combat_state` table tracks active fights:

```lua
-- Stored in context during active combat
context.active_fights = {
    [fight_id] = {
        combatants = { creature1, creature2, ... },
        turn_order = { ... },  -- recalculated each round
        round = 1,
        location = room_id,
    },
}
```

**Entry/exit conditions:**
- **Enter fight:** `attack` action (creature or player), predator-prey auto-trigger
- **Exit fight:** death, flee (successful), no valid targets remain, player intervention separates combatants
- **Fight ends:** ≤1 combatant remains, or all remaining combatants have no hostile relationship

#### B.3 Combat Witness Narration

When NPC-vs-NPC combat occurs, the player may or may not witness it. Narration adapts to perception context using the existing sensory system (Principle 6).

**Narration tiers:**

| Player Location | Light? | Narration Level | Example |
|----------------|--------|----------------|---------|
| Same room | Yes | Full visual detail | *"The cat springs from behind the barrel. Claws flash — the rat squeals — then silence."* |
| Same room | No | Audio-only | *"A sudden scrabbling. A shrill squeak — a wet crunch. Something killed something in the dark."* |
| Adjacent room | Any | Distant sound | *"From the cellar, you hear claws on stone, a high shriek, then silence."* |
| 2+ rooms away | Any | Nothing | (no output) |

**Implementation:** The existing `narration.lua` module in `src/engine/combat/` generates structured narration from combat results. Phase 2 adds a `witness_mode` parameter:

```lua
-- In narration.lua:
function M.narrate_exchange(result, witness_mode)
    if witness_mode == "full" then
        return full_visual_narration(result)
    elseif witness_mode == "audio" then
        return audio_only_narration(result)
    elseif witness_mode == "distant" then
        return distant_sound_narration(result)
    end
    return nil  -- too far, no narration
end
```

**`witness_mode` determination** (in the fight tick):

```lua
local function get_witness_mode(player, fight)
    if player.location == fight.location then
        local room = context.registry:find_room(fight.location)
        if room_has_light(room, context) then
            return "full"
        else
            return "audio"
        end
    elseif rooms_adjacent(player.location, fight.location) then
        return "distant"
    end
    return nil
end
```

**Audio narration templates:** Each natural weapon has a `sound` field (optional, defaults to weapon `message` verb):

```lua
-- On rat bite:
{ id = "bite", ..., sound = "a sharp squeak and the snap of tiny jaws" }
-- On cat claw:
{ id = "claw", ..., sound = "a hiss and the scrape of claws" }
```

Audio narration uses `sound` fields rather than visual descriptions. Death events always produce a sound: *"A final, high-pitched shriek — then nothing."*

#### B.4 Creature Morale: flee_threshold Mid-Combat

Phase 1 implements `flee_threshold` as a fear-driven behavior check. Phase 2 extends it to combat: creatures check morale after receiving damage.

**Morale check (in UPDATE phase of combat exchange FSM):**

```lua
-- After applying damage to defender:
if defender.animate then  -- only creatures have morale
    local health_fraction = defender.health / defender.max_health
    if health_fraction <= defender.combat.behavior.flee_threshold then
        -- Morale broken: creature attempts to flee
        local fled = attempt_flee(defender, context)
        if fled then
            messages[#messages + 1] = defender.name .. " breaks away and bolts!"
            remove_from_fight(defender, fight)
        else
            -- Blocked exit or cornered: fights desperately
            messages[#messages + 1] = defender.name .. " looks for escape but finds none."
            -- Switch defense to "flee" for next round (prioritizes dodging)
            defender._combat_override_defense = "flee"
        end
    end
end
```

**`attempt_flee()` reuses the existing `flee` action** from creature behavior — pick the exit farthest from threat, move creature. Flee can fail if:
- No valid exits (cornered)
- Exits blocked by webs/barriers
- Attacker speed > defender speed (optional: speed-chase check, Phase 3)

**Design note:** The player has no `flee_threshold` — player flee is always voluntary via the `flee` verb. This asymmetry is intentional: the player has agency, creatures have metadata.

---

### C. Disease System

#### C.1 Generic on_hit Disease Delivery

The `on_hit` field on natural weapons is the universal mechanism for combat-transmitted effects. It exists as a concept in the combat plan but Phase 2 implements it.

**`on_hit` field format:**

```lua
-- On a natural weapon:
{
    id = "bite",
    type = "pierce",
    material = "tooth_enamel",
    force = 2,
    on_hit = {
        type = "disease",             -- effect category
        disease = "rabies",           -- injury type ID (matches file in src/meta/injuries/)
        chance = 0.15,                -- probability per successful hit (0.0 – 1.0)
    },
}
```

**Alternate formats (same mechanism, different effects):**

```lua
-- Spider venom: 100% delivery, no chance roll
on_hit = { type = "disease", disease = "spider-venom", chance = 1.0 }

-- Poisoned weapon: limited uses
on_hit = { type = "disease", disease = "poisoned-nightshade", chance = 1.0, uses = 3 }
```

**Engine integration point:** In the RESOLVE phase of the combat exchange FSM (`src/engine/combat/init.lua`), after damage is calculated and a hit is confirmed:

```lua
-- In resolve_exchange(), after severity >= GRAZE:
if weapon.on_hit then
    local roll = math.random()
    if roll <= (weapon.on_hit.chance or 1.0) then
        local injury_type = weapon.on_hit.disease
        injuries.inflict(defender, injury_type, attacker.id, target_zone)
        -- on_hit message comes from the injury definition's on_inflict.message
    end
    -- Decrement uses if applicable
    if weapon.on_hit.uses then
        weapon.on_hit.uses = weapon.on_hit.uses - 1
        if weapon.on_hit.uses <= 0 then
            weapon.on_hit = nil  -- poison exhausted
        end
    end
end
```

**Key design:** `on_hit` is completely generic. The combat engine doesn't know what "rabies" or "spider-venom" means — it calls `injuries.inflict()` with whatever disease ID the weapon metadata specifies. The injury system handles the rest via its FSM progression. This is Principle 8 in action.

#### C.2 Disease as Injury Type with FSM Progression

Diseases use the existing injury system's FSM infrastructure. A disease is structurally identical to any other injury type — it has `states`, `transitions`, `on_inflict`, `healing_interactions`, and `damage_per_tick`. The difference is semantic: diseases have incubation periods, delayed symptoms, and progressive severity.

**Disease FSM pattern:**

```
incubating → symptomatic → critical → fatal
     │            │            │
     └─── cured ──┴─── cured ──┘   (healing only works in early states)
```

**How this maps to `injuries.lua`:**

The existing `injuries.tick()` function already:
1. Iterates `player.injuries` each turn
2. Advances FSM timers on each injury
3. Applies `damage_per_tick` from the current state
4. Checks `timed_events` for auto-transitions
5. Checks terminal states for death

Diseases slot into this pipeline with zero engine changes. The injury definitions declare the FSM states and timers; `injuries.tick()` advances them identically to physical injuries.

**New field for diseases:** `hidden_until_state` — suppresses injury display in `injuries.list()` until symptoms appear:

```lua
-- In a disease definition:
hidden_until_state = "symptomatic",  -- player doesn't see "rabies" during incubation
```

**Engine change:** ~5 lines in `injuries.list()` to check `hidden_until_state` against the injury's current state. If the injury hasn't reached the visible state yet, skip it in the listing. The player knows they were bitten (the bite wound is a separate minor-cut injury from combat) but doesn't know they're infected until symptoms appear.

#### C.3 Rabies Specification

**File:** `src/meta/injuries/rabies.lua`

```lua
return {
    guid = "{new-guid}",
    id = "rabies",
    name = "Rabies",
    category = "disease",
    damage_type = "degenerative",
    initial_state = "incubating",
    hidden_until_state = "prodromal",

    on_inflict = {
        initial_damage = 0,
        damage_per_tick = 0,
        message = "The bite wound throbs strangely.",
    },

    states = {
        incubating = {
            name = "animal bite",
            description = "A bite wound from a wild animal. It looks clean enough.",
            damage_per_tick = 0,
            timed_events = {
                { event = "transition", delay = 15, to_state = "prodromal" },
            },
        },
        prodromal = {
            name = "fever and malaise",
            description = "You feel feverish. The old bite wound itches terribly.",
            damage_per_tick = 2,
            restricts = { precise_actions = true },
            timed_events = {
                { event = "transition", delay = 10, to_state = "furious" },
            },
        },
        furious = {
            name = "hydrophobia",
            description = "You can't drink water. The thought of it makes you gag.",
            damage_per_tick = 5,
            restricts = { drink = true, precise_actions = true },
            timed_events = {
                { event = "transition", delay = 5, to_state = "fatal" },
            },
        },
        fatal = {
            name = "terminal rabies",
            description = "Seizures. Paralysis. The end approaches.",
            terminal = true,
            death_message = "The disease has run its course. You slip into darkness.",
        },
        cured = {
            name = "cured infection",
            description = "The infection has cleared.",
            terminal = true,
        },
    },

    transitions = {
        { from = "incubating", to = "prodromal", trigger = "auto", condition = "timer_expired" },
        { from = "prodromal", to = "furious", trigger = "auto", condition = "timer_expired" },
        { from = "furious", to = "fatal", trigger = "auto", condition = "timer_expired" },
    },

    healing_interactions = {
        ["healing-poultice"] = {
            transitions_to = "cured",
            from_states = { "incubating", "prodromal" },
            message = "The poultice draws out the infection. The fever breaks.",
        },
    },
}
```

**Timeline:** 15 turns incubation (silent) → 10 turns fever → 5 turns hydrophobia → death. Total: 30 turns from bite to death if untreated. Curable only in first 25 turns (incubating + prodromal) with a healing poultice.

**Delivery:** The rat's `bite` natural weapon gains `on_hit = { type = "disease", disease = "rabies", chance = 0.15 }`. Not every rat carries rabies — the 15% chance creates uncertainty. The player gets bitten, takes the minor-cut damage from the bite itself, and may or may not have contracted rabies. They won't know for 15 turns.

**Gameplay intent:** Rabies creates a ticking clock the player doesn't know about. By the time symptoms appear (turn 15), they have only 10 turns to find and apply a healing poultice before it becomes incurable. This rewards players who treat animal bites prophylactically — good real-world-consistent design.

#### C.4 Spider Venom Specification

**File:** `src/meta/injuries/spider-venom.lua`

```lua
return {
    guid = "{new-guid}",
    id = "spider-venom",
    name = "Spider Venom",
    category = "poison",
    damage_type = "degenerative",
    initial_state = "injected",
    hidden_until_state = nil,  -- immediate symptoms; no hidden phase

    on_inflict = {
        initial_damage = 3,
        damage_per_tick = 2,
        message = "Burning pain spreads from the bite. Your skin prickles.",
    },

    states = {
        injected = {
            name = "venom burning",
            description = "The bite site is swollen and hot. Numbness creeps outward.",
            damage_per_tick = 2,
            timed_events = {
                { event = "transition", delay = 5, to_state = "spreading" },
            },
        },
        spreading = {
            name = "spreading numbness",
            description = "Your fingers tingle. Your limbs feel heavy and slow.",
            damage_per_tick = 3,
            restricts = { precise_actions = true, attack_penalty = true },
            timed_events = {
                { event = "transition", delay = 5, to_state = "paralysis" },
            },
        },
        paralysis = {
            name = "partial paralysis",
            description = "You can barely move. Your breathing is shallow.",
            damage_per_tick = 4,
            restricts = {
                precise_actions = true,
                attack = true,
                movement = true,
            },
            timed_events = {
                { event = "transition", delay = 5, to_state = "fatal" },
            },
        },
        fatal = {
            name = "respiratory failure",
            description = "Your diaphragm seizes. You can't breathe.",
            terminal = true,
            death_message = "The venom stops your lungs. Darkness takes you.",
        },
        neutralized = {
            name = "neutralized venom",
            description = "The burning fades. Feeling returns to your limbs.",
            terminal = true,
        },
    },

    transitions = {
        { from = "injected", to = "spreading", trigger = "auto", condition = "timer_expired" },
        { from = "spreading", to = "paralysis", trigger = "auto", condition = "timer_expired" },
        { from = "paralysis", to = "fatal", trigger = "auto", condition = "timer_expired" },
    },

    healing_interactions = {
        ["antidote"] = {
            transitions_to = "neutralized",
            from_states = { "injected", "spreading", "paralysis" },
            message = "The antidote works fast. The numbness recedes.",
        },
        ["healing-poultice"] = {
            transitions_to = "neutralized",
            from_states = { "injected", "spreading" },
            message = "The poultice slows the venom. You can feel your fingers again.",
        },
    },
}
```

**Key differences from rabies:**

| Property | Rabies | Spider Venom |
|----------|--------|-------------|
| Onset | Delayed (15 turns) | Immediate |
| Hidden? | Yes (incubation) | No (instant symptoms) |
| Delivery chance | 15% per bite | 100% per bite |
| Cure window | Early stages only | All non-fatal stages |
| Progression speed | Slow (30 turns total) | Fast (15 turns total) |
| Movement restriction | No | Yes (paralysis) |

**Gameplay intent:** Spider venom is the opposite of rabies — immediate, obvious, fast. The player knows they're poisoned and has limited time to find an antidote or poultice. Venom creates urgency; rabies creates dread.

#### C.5 Integration with injuries.lua

**No structural changes to `injuries.lua` needed.** Diseases are injury types. The existing system already supports:

- ✅ FSM state progression (`states`, `transitions`, `timed_events`)
- ✅ Per-tick damage accumulation (`damage_per_tick`)
- ✅ Terminal state handling (`terminal = true`, `death_message`)
- ✅ Healing via treatment objects (`healing_interactions`)
- ✅ Activity restrictions (`restricts`)
- ✅ Degenerative damage type (`damage_type = "degenerative"`)

**Minor additions to `injuries.lua`:**

1. **`hidden_until_state` support** (~5 lines in `injuries.list()`):
   ```lua
   -- Skip hidden injuries in listing
   if injury.hidden_until_state and injury._state ~= injury.hidden_until_state
      and not has_passed_state(injury, injury.hidden_until_state) then
       goto continue
   end
   ```

2. **Disease category display** (~3 lines in injury status formatting):
   ```lua
   -- Show disease name differently from wound name
   if def.category == "disease" or def.category == "poison" then
       prefix = "Affliction: "
   end
   ```

**Total engine change:** ~10 lines in `injuries.lua`. Everything else is new `.lua` definition files in `src/meta/injuries/`.

---

### D. Food Proof-of-Concept

#### D.1 Food as Objects

Food items are standard objects with `template = "small-item"` plus food-specific metadata. No new template needed — food is a small item you can eat.

**Food metadata fields:**

```lua
-- Added to any object that is edible:
edible = true,
food = {
    nutrition = 20,               -- hunger reduction value
    effects = {},                 -- array of on-eat effects (heal, buff, poison risk)
    bait_value = 50,              -- attractiveness to hungry creatures (0-100)
    spoilage = true,              -- whether this food spoils over time
},
```

**Example: cheese (`src/meta/objects/cheese.lua`):**

```lua
return {
    guid = "{new-guid}",
    template = "small-item",
    id = "cheese",
    name = "a wedge of cheese",
    keywords = { "cheese", "wedge", "food" },
    description = "A wedge of hard yellow cheese, slightly crumbly at the edges.",

    on_feel = "Firm and waxy. Slightly oily surface.",
    on_smell = "Sharp, tangy. Undeniably cheese.",
    on_listen = "Silent.",
    on_taste = "Sharp, salty, rich. Satisfying.",

    material = "organic",
    size = "tiny",
    weight = 0.3,
    portable = true,

    edible = true,
    food = {
        nutrition = 20,
        effects = {
            { type = "heal", amount = 5 },
        },
        bait_value = 70,          -- rats love cheese
        spoilage = true,
    },

    -- Food spoilage FSM
    initial_state = "fresh",
    _state = "fresh",
    states = {
        fresh = {
            description = "A wedge of hard yellow cheese, slightly crumbly at the edges.",
            on_smell = "Sharp, tangy. Good cheese.",
            on_taste = "Sharp, salty, rich. Satisfying.",
            room_presence = "A wedge of cheese sits here.",
            timed_events = {
                { event = "transition", delay = 60, to_state = "stale" },
            },
        },
        stale = {
            description = "A wedge of cheese, going dry and hard at the edges.",
            on_smell = "Still cheesy, but fading.",
            on_taste = "Bland and rubbery. Edible, but barely.",
            room_presence = "A dried-out wedge of cheese sits here.",
            timed_events = {
                { event = "transition", delay = 60, to_state = "rotten" },
            },
        },
        rotten = {
            description = "A moldy, green-spotted lump that was once cheese.",
            on_smell = "An aggressive, sour stink. Definitely off.",
            on_taste = "You gag. That is NOT food anymore.",
            room_presence = "A moldy lump of something organic festers here.",
        },
    },
    transitions = {
        { from = "fresh", to = "stale", trigger = "auto", condition = "timer_expired" },
        { from = "stale", to = "rotten", trigger = "auto", condition = "timer_expired" },
    },
}
```

#### D.2 The `eat` Verb

**File:** `src/engine/verbs/init.lua` (new verb entry)

```lua
verbs.eat = function(context, noun)
    local obj = find_in_hands(context, noun)
    if not obj then
        obj = find_in_room(context, noun)
        if not obj then
            err_not_found(context, noun)
            return
        end
        -- Must be holding food to eat it
        print("You'd need to pick that up first.")
        return
    end

    if not obj.edible then
        print("You can't eat " .. (obj.name or "that") .. ".")
        return
    end

    -- State-dependent effects
    local state = obj._state
    local state_def = obj.states and obj.states[state]

    -- Rotten food: risk of sickness
    if state == "rotten" then
        print("You force down the rotten " .. obj.id .. ". Your stomach lurches.")
        injuries.inflict(context.player, "poisoned-nightshade", obj.id, nil, 3)
    else
        -- Normal consumption
        local taste = (state_def and state_def.on_taste) or obj.on_taste
        if taste then
            print(taste)
        end
        print("You eat " .. obj.name .. ".")
    end

    -- Apply food effects
    if obj.food and obj.food.effects then
        for _, effect in ipairs(obj.food.effects) do
            if effect.type == "heal" then
                -- Reduce total damage from injuries
                heal_player(context.player, effect.amount)
            end
        end
    end

    -- Consume the object (remove from game)
    remove_from_hands(context, obj)
    context.registry:remove(obj.guid)
end
```

**Verb aliases:** `eat`, `consume`, `devour` all map to the same handler. The preprocess pipeline normalizes these.

**Healing via food:** The `heal_player()` helper reduces `damage` on the player's least-severe active injury. It does NOT create new injuries or interact with the injury FSM — it just subtracts from accumulated damage. Simple and predictable for the PoC.

#### D.3 Bait Mechanic

Food creates emergent creature behavior: drop food in a room with a hungry creature, and the creature approaches.

**How it works:**

1. Food objects have `food.bait_value` (0–100)
2. Creatures have a `hunger` drive (already implemented in Phase 1)
3. During `creature_tick()`, in the `score_actions()` function, add a scan for food:

```lua
-- In score_actions(), new food-seeking branch:
if creature.drives.hunger and creature.drives.hunger.value > 40 then
    local food_items = find_food_in_room(context, creature.location)
    if #food_items > 0 then
        local best_food = max_by(food_items, function(f) return f.food.bait_value or 0 end)
        scores["approach_food"] = creature.drives.hunger.value
                                + (best_food.food.bait_value or 0) / 2
                                + random_jitter(-5, 5)
        creature._target_food = best_food
    end
end
```

4. New action `"approach_food"` in `execute_action()`:
   - Move toward food (if in same room: "eat" it — remove from room, reduce hunger)
   - If in adjacent room: move toward room with food (food smell as stimulus)
   - Emit message: *"The rat creeps toward the cheese, whiskers twitching."*

**`find_food_in_room()` helper:**

```lua
local function find_food_in_room(context, room_id)
    local room = context.registry:find_room(room_id)
    local food = {}
    for _, obj in ipairs(room.contents or {}) do
        if obj.edible and obj.food then
            food[#food + 1] = obj
        end
    end
    return food
end
```

**Gameplay loop:** Player finds cheese → drops cheese in hallway → rat smells cheese → rat enters hallway → rat approaches cheese → player can now `catch rat` while it's distracted (fear_delta reduced by food presence). This emerges from existing systems — no scripting.

**Food smell propagation:** Food with `food.bait_value > 0` emits a `food_smell` stimulus to adjacent rooms during the FSM tick (smells travel through exits). Creatures with `smell_range >= 1` detect it and may wander toward the source. This reuses the existing stimulus pipeline.

#### D.4 Food Spoilage FSM

Food spoilage uses the **existing FSM timer system** — no engine changes. Each food object declares its spoilage states inline (see cheese example in D.1).

**Spoilage progression:**

```
fresh → stale → rotten
```

| State | Effect on eat | Effect on bait | Timer |
|-------|-------------|---------------|-------|
| `fresh` | Full nutrition, positive effects | Full bait_value | 60 ticks |
| `stale` | Reduced nutrition (÷2), no heal | Reduced bait_value (÷2) | 60 ticks |
| `rotten` | Poison risk (poisoned-nightshade) | Increased bait_value for some creatures (rats eat anything) | Terminal |

**Design note:** Spoilage timers are intentionally long for the PoC (60 ticks each = 120 ticks total). This can be tuned during playtesting. The point is proving the FSM pattern works, not balancing the numbers.

**Minimal scope:** The PoC needs exactly 2 food objects (cheese and bread/meat) to validate the system. Object-specific variety (wines, berries, mushrooms) is future work.

#### D.5 Integration with Sensory System

Food objects already have `on_taste` and `on_smell` fields — these are standard object properties. Phase 2 adds food-state-aware sensory responses:

**State-dependent sensory text** (already supported by the FSM state system):

```lua
states = {
    fresh = {
        on_smell = "Sharp, tangy. Good cheese.",
        on_taste = "Sharp, salty, rich.",
    },
    rotten = {
        on_smell = "Sour, aggressive. Definitely off.",
        on_taste = "You gag. Not food anymore.",
    },
}
```

The existing look/smell/taste verb handlers already check `state_def.on_X` before falling back to `obj.on_X`. No engine change needed.

**Taste-as-identification:** A player can `taste cheese` to discover its state without eating it. Fresh cheese tastes good; rotten cheese makes them gag (but doesn't cause poisoning — you have to `eat` to get poisoned). This preserves the existing design where taste is a diagnostic tool (see poisoned-nightshade pattern).

---

## 2. Cross-System Integration Points

This section maps where the four systems connect to each other and to existing engine infrastructure.

### 2.1 Integration Matrix

| System A | System B | Integration Point | Direction |
|----------|----------|-------------------|-----------|
| Creature Generalization | NPC-vs-NPC Combat | `attack` action in creature_tick() calls combat FSM | A → B |
| Creature Generalization | Disease | Predator-prey combat delivers diseases via on_hit | A → B → C |
| Creature Generalization | Food PoC | Creature hunger drive responds to food bait | A ← D |
| NPC-vs-NPC Combat | Disease | on_hit field on natural weapons delivers diseases | B → C |
| NPC-vs-NPC Combat | Food PoC | Combat may occur near food (creature defending food) | Indirect |
| Disease | Food PoC | Rotten food causes poisoning (reuses injury system) | C ← D |
| Disease | Existing injuries.lua | Diseases ARE injuries with FSM progression | C → Existing |
| Food PoC | Existing FSM engine | Spoilage uses standard timed FSM transitions | D → Existing |
| All Systems | Existing sensory system | Light/darkness narration, on_feel/on_smell/on_taste | All → Existing |

### 2.2 Creature Generalization ↔ NPC-vs-NPC Combat

**Connection:** The `attack` action in `creature_tick()` is the bridge between creature behavior and the combat system.

**Data flow:**

```
creature_tick()
  → score_actions() picks "attack"
  → find_attack_target() selects target
  → select_natural_weapon() picks weapon
  → combat.resolve_exchange(creature, target, weapon, zone)  ← enters combat system
  → combat returns: { severity, damage, messages, defender_state }
  → creature_tick() applies results (injury, death, narration)
  → if multi-round: track in context.active_fights
```

**Shared state:** `context.active_fights` tracks ongoing multi-combatant fights. Both `creature_tick()` (to decide whether to continue attacking or flee) and the combat module (to track turn order and round progression) read and write this table.

**Conflict avoidance:** The combat module never modifies creature behavior metadata. The creature module never modifies combat resolution logic. They communicate through the fight state table and the `resolve_exchange()` function interface.

### 2.3 NPC-vs-NPC Combat ↔ Disease

**Connection:** The `on_hit` field on natural weapons triggers disease delivery during combat resolution.

**Data flow:**

```
combat.resolve_exchange()
  → severity >= GRAZE (hit lands)
  → check weapon.on_hit
  → if on_hit.type == "disease":
      → roll against on_hit.chance
      → if success: injuries.inflict(defender, on_hit.disease, attacker.id, zone)
  → disease now tracked in defender's injury list
  → injuries.tick() advances disease FSM each turn
```

**Principle 8 compliance:** The combat engine doesn't know what "rabies" or "spider-venom" is. It sees an `on_hit` table with a disease ID and a probability. It calls `injuries.inflict()` with that ID. The injury system loads the disease definition and handles everything from there.

**Cross-species disease:** The same mechanism works for any combatant type. A rat bites a cat → cat might get rabies. A spider bites a rat → rat gets venom. The engine doesn't care about species — it evaluates weapon metadata.

### 2.4 Creature Generalization ↔ Food PoC

**Connection:** The creature hunger drive creates demand for food objects. Food's `bait_value` creates supply for creature attraction.

**Data flow:**

```
creature_tick()
  → update_drives(): hunger increases each tick
  → score_actions(): if hunger > 40, scan room for edible objects
  → if food found: score "approach_food" high
  → execute_action("approach_food"):
      → creature moves toward food
      → creature "eats" food (removes from room, reduces hunger drive)
      → emit message about creature eating
```

**Food smell as stimulus:**

```
FSM tick on food object
  → food emits "food_smell" stimulus to current room + adjacent rooms
  → creature_tick() process_stimuli() checks for food_smell
  → creature with hunger drive scores "wander toward food source" higher
```

**Bait trap pattern:**

```
Player drops food in room
  → food_smell stimulus propagates
  → creature in adjacent room detects smell
  → creature wanders toward food room
  → creature approaches food
  → while creature is distracted: player can catch/attack with advantage
```

### 2.5 Disease ↔ Food PoC

**Connection:** Rotten food causes poisoning through the `eat` verb, using the existing injury system.

**Data flow:**

```
Player eats rotten food
  → eat verb checks obj._state == "rotten"
  → injuries.inflict(player, "poisoned-nightshade", obj.id, nil, 3)
  → existing poisoned-nightshade injury FSM handles symptoms
```

This is a one-way connection. Diseases don't affect food. Food in the `rotten` state becomes a hazard that feeds into the injury system. The `poisoned-nightshade` injury type already exists — no new disease definition needed for food poisoning.

### 2.6 All Systems ↔ Existing Engine Infrastructure

**Shared dependencies (existing, unchanged):**

| Engine Module | Used By | How |
|--------------|---------|-----|
| `injuries.lua` | Disease, Food (rotten), Combat | `inflict()`, `tick()`, `list()`, `try_heal()` |
| `creatures/init.lua` | Creature Gen, NPC Combat, Food | `tick()`, `emit_stimulus()`, `score_actions()` |
| `combat/init.lua` | NPC Combat, Disease (on_hit) | `resolve_exchange()` |
| `combat/narration.lua` | NPC Combat witness | `narrate_exchange()` with `witness_mode` |
| `fsm/init.lua` | Food spoilage, Disease progression | `timed_events`, auto-transitions |
| `registry/init.lua` | All systems | Object lookup, room contents, creature discovery |
| `loop/init.lua` | All systems | Tick ordering: verb → FSM → creature → injury |
| `verbs/init.lua` | Food (eat verb), Creature (attack) | Verb dispatch |

**Tick ordering (unchanged):**

```
Player input → Verb handler → FSM tick → Fire tick → Creature tick → Injury tick → Death check
                                 ↑                        ↑               ↑
                           Food spoilage         NPC combat        Disease progression
                           advances here         happens here      advances here
```

The existing tick order naturally places creature combat (in creature tick) before disease advancement (in injury tick), which means diseases inflicted during combat take effect the same turn. This is correct — a spider bite delivers venom that starts ticking immediately.

### 2.7 File Ownership Summary

| New/Modified File | Owner | Systems |
|-------------------|-------|---------|
| `src/engine/creatures/init.lua` (modified) | Bart | A, B, D |
| `src/engine/combat/init.lua` (modified) | Bart | B, C |
| `src/engine/combat/narration.lua` (modified) | Bart | B |
| `src/engine/injuries.lua` (modified) | Bart | C |
| `src/engine/verbs/init.lua` (modified) | Smithers | D |
| `src/meta/injuries/rabies.lua` (new) | Flanders | C |
| `src/meta/injuries/spider-venom.lua` (new) | Flanders | C |
| `src/meta/objects/spider-web.lua` (new) | Flanders | A |
| `src/meta/objects/cheese.lua` (new) | Flanders | D |
| `src/meta/creatures/cat.lua` (new) | Flanders | A, B |
| `src/meta/creatures/spider.lua` (new) | Flanders | A, C |
| `src/meta/creatures/guard-dog.lua` (new) | Flanders | A |
| `src/engine/verbs/movement.lua` (modified) | Bart | A (trap check) |

**No new engine modules.** All Phase 2 features are extensions of existing modules. This is by design — the architecture from Phase 1 was built to absorb this complexity.
