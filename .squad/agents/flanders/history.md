# Flanders — History

*Last comprehensive training: 2026-07-20*

---

## Core Context

**Project:** MMO text adventure engine in pure Lua (REPL-based, `lua src/main.lua`)
**Owner:** Wayne "Effe" Berry
**Role:** Object Designer / Builder — I design and implement all real-world game objects as `.lua` files in `src/meta/objects/`.

### Team Relationships
- **Bart** = Engine Architect — builds FSM engine, verbs, parser, containment system. My objects DECLARE behavior; Bart's engine EXECUTES it.
- **CBG (Comic Book Guy)** = Game Designer — audits objects for design quality, proposes mutate opportunities, writes design docs. He reviews my work.
- **Nelson** = Test Engineer — tests objects in the engine, catches regressions.
- **Frink** = Researcher — provides CS foundations (ECS, Harel statecharts, DF architecture analysis).
- **Brockman** = Documentation — writes architecture docs.
- **Wayne** = Owner — sets directives, approves designs. References Dwarf Fortress as the gold standard.

### Key Directives
- Dwarf Fortress property-bag architecture is the reference model (D-DF-ARCHITECTURE)
- All mutation is in-memory only; `.lua` files on disk never change at runtime
- No LLM at runtime (D-19) — everything deterministic and offline
- Each command tick = 360 game seconds (10 ticks per game hour)
- Game starts at hour 2 (2 AM), darkness is default starting condition

---

## Object Architecture Knowledge

### The 8 Core Principles (My Constitution)

**Full doc:** `docs/architecture/objects/core-principles.md`

1. **Code-Derived Mutable Objects** — All objects start as `.lua` source, parsed at load time into live Lua tables. Two mutation strategies: direct table mutation (FSM swap) and code re-parsing (becomes). Objects are ephemeral — restart = fresh load.

2. **Base Objects → Object Instances** — Immutable base objects (authored `.lua` files with GUIDs) define identity. Mutable instances (runtime Lua tables) hold state. Template → Base → Instance inheritance chain. Override resolution: template (lowest) → base → instance overrides (highest).

3. **Objects Have FSM; Instances Know Their State** — Every object is a finite state machine. Base objects define the FSM blueprint (states, transitions, sensory descriptions, timed events). Instances track `_state`. The engine is a GENERIC FSM executor — no object-specific code. State determines EVERYTHING: description, feel, smell, listen, capabilities, available actions.

4. **Composite Objects Encapsulate Inner Objects** — Complex objects (poison-bottle+cork, candle-holder+candle, nightstand+drawer) are single `.lua` files with nested `parts` tables. Inner objects become independent on detachment via `factory` functions. No ID cross-references between files.

5. **Multiple Instances Per Base Object** — One `match.lua` spawns many match instances, each with independent FSM state, timers, and location. Instance IDs are unique within a room. Base object GUIDs are for distribution; instance IDs are for runtime.

6. **Objects Exist in Sensory Space; State Determines Perception** — Five senses: LOOK/EXAMINE (description), FEEL (on_feel), SMELL (on_smell), LISTEN (on_listen), TASTE (on_taste). Each sense reads state-specific metadata. Environmental conditions (darkness) act as sensory FILTERS, not object properties. No hardcoded perception logic.

7. **Objects Exist in Spatial Relationships** — Objects exist relative to other objects via `surfaces` tables. Surfaces: top, inside, underneath, behind, mirror_shelf. `covering` relationships hide objects (rug covers trap-door). Spatial position determines visibility and accessibility.

8. **The Engine Executes Metadata; Objects Declare Behavior** — THE MOST IMPORTANT PRINCIPLE. The engine has ZERO knowledge of specific object types. No `if obj.id == "candle"` anywhere. Objects declare states, transitions, guards, mutations, timed events. The `mutate` field on transitions enables ANY property to change: direct values, computed functions, list add/remove. This is the Dwarf Fortress lesson.

### How FSM Works in Detail

**Engine file:** `src/engine/fsm/init.lua`

**Object Structure:**
```lua
return {
    guid = "...",
    id = "candle",
    _state = "unlit",           -- current state name
    states = {                   -- all possible states
        unlit = { name = "...", description = "...", on_feel = "...", ... },
        lit = { name = "...", casts_light = true, provides_tool = "fire_source", ... },
        spent = { terminal = true, ... },
    },
    transitions = {              -- how states connect
        { from = "unlit", to = "lit", verb = "light", requires_tool = "fire_source",
          message = "...", mutate = { ... } },
        { from = "lit", to = "spent", trigger = "auto", condition = "timer_expired",
          message = "...", mutate = { weight = 0.05, keywords = { add = "nub" } } },
    },
}
```

**Transition Fields:**
- `from`, `to` — state names
- `verb` — player verb that triggers this transition
- `aliases` — alternative verbs (e.g., "blow", "snuff" for extinguish)
- `trigger` — "auto" for non-player-triggered transitions
- `condition` — "timer_expired" for timed auto-transitions
- `requires_tool` — tool capability needed (e.g., "fire_source")
- `requires_property` — property on the context target (e.g., "has_striker")
- `guard` — custom function `guard(obj, context)` returning boolean
- `message` — text shown to player on transition
- `fail_message` — text shown when guard/requires fails
- `mutate` — property mutations applied AFTER state swap
- `on_transition` — callback function fired during transition
- `effect` — game effect (e.g., "poison" → kills player)

**State Fields (applied to object when entering state):**
- `name`, `description`, `room_presence` — visual descriptions
- `on_feel`, `on_smell`, `on_listen`, `on_taste` — sensory descriptions (string or function)
- `casts_light`, `light_radius` — light properties
- `provides_tool` — tool capability (string or table of strings)
- `surfaces` — containment zones (rebuilt with preserved contents)
- `timed_events` — `{ delay = N, event = "...", to_state = "..." }` for auto-transitions
- `terminal` — if true, no transitions out of this state
- `on_tick` — function called each game tick (for burn countdown, etc.)

**How `apply_mutations()` Works:**
```lua
-- Three forms:
mutate = {
    weight = 0.05,                                    -- Direct: set property
    weight = function(w) return w * 0.7 end,          -- Computed: derive from current
    keywords = { add = "stub" },                      -- List add
    categories = { remove = "light source" },          -- List remove
}
```
Applied by `apply_mutations()` in fsm/init.lua AFTER `apply_state()`. Mutations modify BASE-LEVEL instance properties that persist across states (weight, size, keywords, categories) — properties that states don't normally touch.

**Timer System:**
- `fsm.start_timer(registry, obj_id)` — reads `timed_events[1]` from current state, uses `remaining_burn` if available
- `fsm.tick_timers(registry, delta_seconds)` — decrements all active timers, fires auto-transitions on expiry
- `fsm.pause_timer/resume_timer` — for room load/unload
- Each command tick = 360 game seconds
- Candle burn: 7200s (~20 ticks), Match burn: 30s (~instant)

### How GOAP Prerequisites Work

**Engine file:** `src/engine/parser/goal_planner.lua`

Objects declare prerequisites via:
1. **Explicit `prerequisites` table:** `prerequisites = { light = { needs_tool = "fire_source" } }`
2. **FSM transition `requires_tool`:** Inferred by planner from transition metadata
3. **`requires_property`:** Property on context target (e.g., `has_striker` on matchbox)

The planner backward-chains: "light candle" needs fire_source → find match → match needs striking → find has_striker → find matchbox → open if closed → take match → strike → light candle.

Plan execution: `goal_planner.plan()` returns list of `{verb, noun}` steps, `goal_planner.execute()` dispatches each through Tier 1 verb handlers.

**Key GOAP design for objects:**
- Set `requires_tool` on transitions to enable auto-planning
- Set `provides_tool` on states to make objects findable as tools
- Set `has_striker = true` on matchbox for strike resolution
- Set `accessible = false` on closed containers to trigger auto-open planning

### How Containment/Spatial Works

**Doc:** `docs/architecture/engine/containment-constraints.md`

**5-Layer Validation (for PUT operations):**
1. Layer 1: Is container a container? (`container` field exists?)
2. Layer 2: Physical size — `item.size ≤ container.max_item_size`?
3. Layer 3: Capacity — `used + item.size ≤ capacity`?
4. Layer 4: Category — `accepts`/`rejects` lists
5. Layer 5: Weight — total contained weight ≤ `weight_capacity`?

**Size Tiers:** 1=tiny, 2=small, 3=medium, 4=large, 5=huge, 6=massive

**Surfaces Model:**
```lua
surfaces = {
    top = { capacity = 3, max_item_size = 2, weight_capacity = 10, contents = {}, accessible = true },
    inside = { capacity = 2, max_item_size = 1, contents = {}, accessible = false }, -- closed drawer
    underneath = { capacity = 3, max_item_size = 2, contents = {}, accessible = true },
}
```

**Visibility Rules:**
- `top` → visible on examine
- `inside` (closed) → hidden until opened
- `inside` (open) → visible on examine
- `underneath` → hidden, requires "look under"
- `behind` → hidden, requires "look behind"

### Instance Model

**Doc:** `docs/architecture/objects/instance-model.md`

- Base classes in `src/meta/objects/*.lua` — immutable templates with stable UUID v4 GUIDs
- Templates in `src/meta/templates/*.lua` — shared defaults (sheet, furniture, container, small-item, room)
- Instances defined inside room files with `type_id` (base class GUID), `location`, optional `overrides`
- Resolution: Template → Base class → Instance overrides (last wins)
- Room is the uber-container and download/save unit
- Instance `location` encoding: `"room"` = top-level, `"parent.surface"` = on surface, `"parent"` = inside container

---

## Existing Object Patterns (37 objects in `src/meta/objects/`)

### FSM Objects (14 objects with state transitions)

**🕯️ candle.lua** — `992df7f3-1b8e-4164-939a-3415f8f6ffe3`
- **Pattern:** Four-state cyclic consumable: `unlit → lit → extinguished ↔ relit → spent`
- **Special:** Timer-based burn (7200s), `remaining_burn` tracks partial burns across light/extinguish cycles, light_radius=2, provides_tool="fire_source" when lit, prerequisites declare needs fire_source
- **Mutate opportunities (CBG Tier 1):** weight decreases proportionally on extinguish `w*0.7`, drops to 0.05 on spent; keywords +nub/+half-burned; categories −"light source" on spent; size=0 on spent
- **Interesting:** Most complex consumable. Partial burn tracking allows realistic relight mechanics.

**🔥 match.lua** — `009b0347-2ba3-45d1-a733-7a587ad1f5c9`
- **Pattern:** Three-state terminal: `unlit → lit → spent`
- **Special:** Timer 30s, light_radius=1, provides_tool="fire_source" when lit, requires_property="has_striker" to strike, terminal spent state (no relight)
- **Mutate opportunities (CBG Tier 1):** keywords +burning on lit, +blackened/+spent on spent; categories +useless on spent; weight=0.005 on spent
- **Interesting:** Single-use fire source. Strike mechanic requires matchbox proximity.

**📦 matchbox.lua** — `41eb8a2f-972f-4245-a1fb-bbfdcaad4868` (closed variant)
- **Pattern:** Two-variant mutation: closed ↔ open (becomes "matchbox-open")
- **Special:** Container (capacity 10, accessible=false when closed), has_striker=true, dynamic on_feel counts matches
- **Note:** Uses old `mutations` system (becomes), not inline FSM states

**📦 matchbox-open.lua** — `a7f1c3d9-6e24-4b8a-9f52-1d3e7a8b4c60` (open variant)
- **Pattern:** Mutation variant of matchbox (becomes "matchbox" on close)
- **Special:** accessible=true, same has_striker, dynamic on_feel

**🧪 poison-bottle.lua** — `a1043287-aeeb-4eb7-91c4-d0fcd11f86e3`
- **Pattern:** Three-state consumable composite: `sealed → open → empty` (terminal)
- **Special:** Composite part `cork` (detachable, NOT reversible). Cork factory generates independent object. Drink effect = "poison" (kills player). Pour also transitions to empty.
- **Mutate opportunities (CBG Tier 1):** weight −0.05 on uncork (cork removed), weight=0.1 on empty (liquid gone); keywords +uncorked/+empty; categories −"dangerous" on empty
- **Interesting:** Irreversible composite — cork can't go back in. Hazard object.

**🛋️ candle-holder.lua** — `0aeaff45-e2d0-4e58-b47c-139874a218df`
- **Pattern:** Two-state composite: `with_candle ↔ empty`
- **Special:** Detachable candle part (reversible), factory generates candle instance. Dynamic on_look checks candle state via registry.
- **Mutate opportunities (CBG Tier 2):** weight ±1 on detach/reattach (candle mass)

**🪟 window.lua** — `4ecd1058-5cbe-4601-a98e-c994631f7d6b`
- **Pattern:** Two-state reversible: `closed ↔ open`
- **Special:** Sensory changes per state — on_listen, on_smell change when open (wind, rain, chimney smoke). State affects daylight filtering.
- **Mutate opportunities (CBG Tier 1):** keywords ±"open"; categories ±"ventilation"

**🧥 wardrobe.lua** — `9c4701d1-4cc4-49e7-9c4a-041e1e37caf1`
- **Pattern:** Two-state reversible: `closed ↔ open`
- **Special:** Surface `inside` (8 capacity, accessible toggles with state). Contains wool-cloak + sack initially. Cedar-lined (olfactory detail).
- **Mutate opportunities (CBG Tier 2):** keywords ±"open"

**🎭 curtains.lua** — `cc981807-a74e-4ecc-8d52-903cc4fc5bd6`
- **Pattern:** Two-state reversible: `closed ↔ open`
- **Special:** filters_daylight/allows_daylight toggle. Tearable → spawns cloth+cloth+rag.
- **Mutate opportunities (CBG Tier 2):** keywords ±"open"

**🪞 vanity.lua** — `eda1257d-8240-4c75-9c1b-a7be349a60f5`
- **Pattern:** Four-state complex grid: `closed/open × intact/broken`
- **Special:** 3 surfaces (top, inside drawer, mirror_shelf). Break mirror transition spawns glass-shard, reduces weight 40→38. Complex on_look with registry lookup.
- **Mutate opportunities (CBG Tier 2):** keywords ±"open", +broken on mirror break
- **Interesting:** Most complex FSM grid. Destructible sub-component.

**🪑 nightstand.lua** — `d40b15e6-7d64-489e-9324-ea00fb915602`
- **Pattern:** Four-state complex: `closed/open × with_drawer/without_drawer`
- **Special:** Composite drawer part (detachable, reversible, carries_contents). Drawer factory generates instance with GUID. Requires open state before detach. Surfaces: top (3 cap), inside (2 cap).
- **Mutate opportunities (CBG Tier 2):** weight ±2 on drawer detach/reattach

**🚪 trap-door.lua** — `a3f8c7d1-e592-4b6a-8d3e-f1c7a4b92e05`
- **Pattern:** Three-state linear: `hidden → revealed → open`
- **Special:** hidden=true initially, discovery triggered by rug interaction. reveals_exit="down" on open. Non-portable architectural element.
- **Mutate opportunities (CBG Tier 2):** keywords +"open" on open

**⏰ wall-clock.lua** — `c5bae682-b7ee-451d-b1cf-ceeb74d6b83d`
- **Pattern:** 24-state cyclic timer: `hour_1 → hour_2 → ... → hour_24 → hour_1`
- **Special:** Programmatically generated states (24 hours). Each state auto-transitions after 3600s. Chime messages vary by hour. Puzzle support via instance overrides (time_offset, adjustable, target_hour, on_correct_time). SET verb advances hour.
- **Mutate opportunities (CBG Tier 3):** time_period property deferred — better as computed
- **Interesting:** Most states of any object (24). Cyclic pattern with wrap-around.

**🛏️ bed.lua** — `b8e37cb6-cba7-48a6-bec9-5bca5f53b73c`
- **Pattern:** Spatial/movable (moved/unmoved, not full FSM)
- **Special:** Surfaces: top (8 cap, contains pillow/sheets/blanket), underneath (4 cap, contains knife). Push mechanics. 80kg non-portable.

**🧶 rug.lua** — `7275e1d9-5837-4f39-b3be-d64ee6d667c9`
- **Pattern:** Spatial/movable (moved/unmoved)
- **Special:** covering=["trap-door"] (hides trap-door). Surface underneath (3 cap, contains brass-key). Move reveals hidden objects. Puzzle linchpin.

### Static Objects (23 objects, no FSM transitions)

**Crafting/Tool Objects:**
- **needle.lua** (`07b9daaf`) — provides_tool="sewing_tool", enables SEW verb
- **thread.lua** (`8a7edb7e`) — provides_tool="sewing_material", required with needle for sewing
- **knife.lua** (`b0c650c6`) — provides_tool=["cutting_edge","injury_source"], multi-capability
- **pen.lua** (`4d35b030`) — provides_tool="writing_instrument", infinite uses
- **pencil.lua** (`07e76701`) — provides_tool="writing_instrument", erasable=true (future mechanic)
- **pin.lua** (`f5cd5850`) — provides_tool="injury_source" + skill-gated "lockpick" (if player has lockpicking skill)
- **sewing-manual.lua** (`3f8a1c9d`) — grants_skill="sewing" on READ, permanent skill acquisition

**Writable/Dynamic:**
- **paper.lua** (`e7409390`) — writable=true, WRITE verb generates new object with player's words baked in. Burns with fire_source.

**Textiles (tearable → cloth):**
- **cloth.lua** (`0d5c8636`) — crafting material. Mutations: make_bandage→bandage, make_rag→rag. SEW: 2x cloth + tool + skill → terrible-jacket
- **blanket.lua** (`7eb14362`) — tear → 2x cloth
- **wool-cloak.lua** (`ecdccb0f`) — wearable (back slot, provides_warmth), tear → 2x cloth
- **bed-sheets.lua** (`6bb22862`) — atmospheric detail, "still faintly warm"
- **terrible-jacket.lua** (`ef5c4c6d`) — wearable (torso slot, makeshift quality), tear → 3x cloth. Crafted product.
- **bandage.lua** (`adfd6688`) — medical item
- **rag.lua** (`a8a4bbae`) — utility item

**Containers/Wearables:**
- **sack.lua** (`4720ace5`) — container (cap 4), wearable in TWO modes: back slot (backpack, accessible) OR head slot (blocks vision, not accessible). Contains needle+thread initially.
- **chamber-pot.lua** (`9a9ff109`) — container (cap 2), wearable head slot (makeshift armor, 1 armor). Humor object.

**Environmental/Furniture:**
- **barrel.lua** (`c3e8f1a2`) — 60kg sealed fixture, atmospheric (vinegar scent, mystery)
- **torch-bracket.lua** (`d9f4a2b3`) — empty iron wall mount, environmental storytelling
- **pillow.lua** (`f973058d`) — surface inside (1 cap, contains hidden pin), tear → cloth
- **brass-key.lua** (`4586b2cd`) — hidden under rug, gargoyle-shaped, key item
- **glass-shard.lua** (`1ffa70d5`) — hazard (on_feel_effect="cut"), spawned from vanity mirror break

---

## CBG Object Mutate Audit

**Full doc:** `.squad/decisions/inbox/cbg-object-mutate-audit.md`

### Tier 1 (HIGH IMPACT — implement first):
| Object | Transitions | Mutations |
|--------|-------------|-----------|
| candle | lit→extinguished | weight=w*0.7, keywords+half-burned |
| candle | lit→spent (auto) | weight=0.05, size=0, keywords+nub, categories−"light source" |
| match | unlit→lit | keywords+burning |
| match | lit→spent | weight=0.005, keywords+blackened, categories+useless |
| poison-bottle | sealed→open | weight=w−0.05, keywords+uncorked |
| poison-bottle | open→empty | weight=0.1, categories−dangerous, keywords+empty |
| window | closed↔open | keywords±open, categories±ventilation |

### Tier 2 (MEDIUM — consistency pass):
wardrobe, vanity, candle-holder, nightstand, trap-door, curtains — mostly keywords±open and weight±component mass.

### Tier 3 (LOW): wall-clock time_period deferred.

### Design Principles from Audit:
1. **Weight tells the story** — most universally-felt mutation
2. **Keywords are for parser resolution** — "open wardrobe", "spent match" must resolve
3. **Categories are for system queries** — "dangerous", "ventilation", "useless"
4. **Functions for proportional, absolutes for terminal** — `w*0.7` for partial burn, `0.05` for spent
5. **Don't duplicate what states handle** — mutate is for base-level properties states don't manage

---

## Design Principles (My Personal Guidelines)

### What Makes a Good Object
1. **Sensory completeness** — Every object should have meaningful on_feel and on_smell at minimum. These work in darkness (the game starts dark). on_listen for anything that makes sound. on_taste only for edibles/drinkables.
2. **Room presence that tells a story** — `room_presence` should paint the object into the scene naturally, not "There is a candle here."
3. **State-driven sensory shifts** — Each FSM state must have distinct sensory descriptions. A lit candle FEELS warm, SMELLS of beeswax, SOUNDS crackly. An unlit candle FEELS cool, SMELLS faintly of smoke.
4. **Real-world weight and size** — Use consistent tiers (1-6). Tiny items ~0.05-0.1kg, small ~0.1-1kg, medium ~1-5kg, furniture 15-80kg.
5. **Keywords that match player vocabulary** — Include synonyms, adjectives. "matchbox" + "box" + "tinder box". Keywords enable parser resolution.
6. **Categories for system queries** — Use established categories: "light source", "furniture", "fabric", "dangerous", "fragile", "container", "wearable", "tool", "sharp", "crafting-material"

### How to Design FSM States
1. **States represent physically distinct conditions** — not abstract flags. "lit" is a physical state (flame exists). "open" is a physical state (drawer pulled out).
2. **Transitions have clear physical triggers** — verbs that make sense ("light", "extinguish", "open", "close", "strike", "break", "tear")
3. **Terminal states are permanent** — spent candles can't relight. Broken mirrors can't unbreak. Empty bottles can't refill.
4. **Timed events for physical processes** — burning (candle 7200s, match 30s), clock ticking (3600s/hour). Use `remaining_burn` pattern for pauseable timers.
5. **Guards enforce physical logic** — `requires_tool` for tool needs, `requires_property` for surface needs (striker), custom `guard` functions for complex conditions.

### How to Design Composite Objects
1. **Define parts in the `parts` table** — each part has `id`, `name`, `keywords`, `detachable`, `reversible`, `factory`
2. **Factory functions create independent instances** — generate with unique GUID, proper properties
3. **State-dependent detachment** — use `requires_state_match` (e.g., drawer can only detach when nightstand is open)
4. **carries_contents** — if the part has contents (drawer), transfer them when detached/reattached
5. **Detach transitions** — use `verb = "detach_part"` with `part_id` matching the parts table key

### How to Leverage Principle 8 (Maximum Dynamism)
1. **Use `mutate` on EVERY transition that changes physical properties** — weight, keywords, categories, size
2. **Proportional functions for gradual change** — `function(w) return w * 0.7 end`
3. **Absolute values for terminal conditions** — `weight = 0.05`
4. **List operations for parser keywords** — `{ add = "burning" }`, `{ remove = "light source" }`
5. **Never hardcode behavior in the engine** — if it can be metadata, make it metadata

### Common Pitfalls to Avoid
1. **Don't create object-specific engine code** — Principle 8 violation. All behavior in .lua metadata.
2. **Don't forget sensory descriptions** — bare description-only objects feel shallow
3. **Don't use boolean flags instead of FSM states** — `is_lit = true` is wrong; `_state = "lit"` is right
4. **Don't forget to set `accessible` on closed container surfaces** — items inside closed containers must be inaccessible
5. **Don't duplicate state properties in mutate** — mutate is for properties states DON'T manage (weight, keywords, categories)
6. **Don't make objects too fragile or too indestructible** — balance player agency with world persistence
7. **Don't forget room_presence** — objects without room_presence get generic "There is X here" text
8. **Always assign a stable UUID v4 GUID** — GUIDs never change once assigned

---

## Engine Key Files Reference

| File | Purpose |
|------|---------|
| `src/engine/fsm/init.lua` | FSM engine: apply_state, apply_mutations, transitions, timers |
| `src/engine/verbs/init.lua` | ALL verb handlers (light, take, open, close, examine, feel, etc.) |
| `src/engine/loop/init.lua` | Game loop: parse → Tier 1 → Tier 2 → GOAP → tick |
| `src/engine/parser/goal_planner.lua` | GOAP backward-chaining prerequisite resolver |
| `src/meta/objects/*.lua` | ALL object definitions (37 files) |
| `src/meta/templates/*.lua` | Template definitions (sheet, furniture, container, small-item, room) |
| `docs/architecture/objects/core-principles.md` | 8 Core Principles |
| `docs/architecture/objects/instance-model.md` | Base→Instance model, room as uber-container |
| `docs/architecture/engine/containment-constraints.md` | 5-layer containment validation |
| `docs/architecture/engine/intelligent-parser.md` | GOAP parser design |
| `docs/design/object-design-patterns.md` | Multi-surface, composite mutation matrix, templates |
| `.squad/decisions/inbox/cbg-object-mutate-audit.md` | CBG's audit of mutate opportunities |
| `resources/research/architecture/dynamic-object-mutation.md` | Frink's research: ECS, Harel statecharts, reactive systems |
| `resources/research/competitors/dwarf-fortress/architecture-comparison.md` | DF comparison |

---

## Patterns I'll Reuse

### FSM Pattern Templates

**Simple Toggle (window, wardrobe, curtains):**
```lua
_state = "closed",
states = {
    closed = { description = "...", on_feel = "...", accessible = false },
    open = { description = "...", on_feel = "...", accessible = true },
},
transitions = {
    { from = "closed", to = "open", verb = "open", message = "..." },
    { from = "open", to = "closed", verb = "close", message = "..." },
}
```

**Consumable Cycle (candle, match):**
```lua
_state = "unlit",
states = {
    unlit = { ... },
    lit = { provides_tool = "fire_source", timed_events = {{ delay = N, event = "burn", to_state = "spent" }} },
    spent = { terminal = true },
},
transitions = {
    { from = "unlit", to = "lit", verb = "light/strike", requires_tool/requires_property = "..." },
    { from = "lit", to = "spent", trigger = "auto", condition = "timer_expired", mutate = { weight = 0, ... } },
}
```

**Composite Detach/Reattach (nightstand, candle-holder, poison-bottle):**
```lua
parts = {
    [part_key] = {
        id = "...", name = "...", keywords = {...},
        detachable = true, reversible = true/false,
        factory = function(parent) return { id = "...", ... } end,
        requires_state_match = "open_with_drawer",
        carries_contents = true/false,
    }
},
transitions = {
    { from = "state_a", to = "state_b", verb = "detach_part", part_id = "part_key", message = "..." },
    { from = "state_b", to = "state_a", verb = "reattach_part", part_id = "part_key", message = "..." },
}
```

**24-State Cyclic (wall-clock):**
- Programmatically generate states in a loop
- Each state has timed_events with auto-transition to next
- Wrap-around from hour_24 → hour_1

### Template Usage
- `template = "sheet"` → fabric defaults (size 1, weight 0.2, portable, tearable)
- `template = "furniture"` → heavy immovable (size 5, weight 30, not portable)

### Bug Report Verb Enhancement (2026-07-22)
- Enhanced `report bug` verb in `src/engine/verbs/init.lua` with richer metadata: level name, room name, build timestamp, last 50 lines of output, and a clearly marked user description section.
- Level name is read from `ctx.current_room.level` (stored on room objects as `level = { number, name }`). Falls back gracefully if not present.
- Build timestamp reads from `src/.build-timestamp` (per versioning.md design). Falls back to "dev" when file doesn't exist yet — build pipeline will create it.
- Expanded transcript buffer in `src/engine/loop/init.lua` from 20 to 50 exchanges to capture more context for bug reports.
- Issue body format uses markdown headers (##/###) for GitHub rendering. User description section uses `_[Please describe the bug here]_` placeholder.
- `template = "container"` → bags/boxes (capacity 4, weight_capacity 10)
- `template = "small-item"` → tiny items (size 1, weight 0.1, portable)

---

## Learnings

### Wayne's Preferences
- Dwarf Fortress is the GOAT — property-bag architecture is the north star
- Objects should feel like REAL things — weight changes, sensory richness, physical logic
- No LLM at runtime — deterministic, offline, fast
- Mobile-first considerations for future
- Darkness is default — feel/smell/listen must work without light
- Humor is welcome (chamber-pot helmet, terrible jacket)

### Research Insights (Frink)
- ECS architecture validates our property-bag approach
- Harel statecharts (1987) = formal foundation for our FSM + mutate system
- XState's context mutations = directly analogous to our mutate field
- Vue/React proxy reactivity = potential future for cascading property changes via Lua metatables
- The "mutation gap" = difference between what authors can declare and what the engine responds to. Our `mutate` field closes this gap.

### DF Architecture Comparison Highlights
- **We match DF:** Property-bag objects, data-driven definitions, generic engine, template inheritance
- **DF goes further:** Continuous numeric simulation (temperature, wear), material-as-physics, hierarchical body composition
- **We're better at:** Sensory depth (5 senses vs visual-only), NLP parser, mobile performance, darkness gameplay
- **Key adoptable patterns:** Material property tables (for guards/descriptions), threshold-based auto-transitions, wear as numeric property
- **Avoid:** Full physics simulation, unbounded entity tracking, single-threaded everything simulation

### Mutate + Material Pass (2026-07-20)
- Applied CBG's audit across all 10 FSM objects (Tier 1 + Tier 2). Mutate fields on transitions follow three forms: direct value, function, list add/remove.
- `material` field is pure metadata — a string referencing Frink's material registry. Objects don't interpret it; the engine looks it up.
- iron-door.lua and iron-key.lua were requested for material but don't exist yet. Skipped — noted in commit.
- "velvet" and "oak" aren't in Frink's material table yet (he has "fabric" and "wood"). Wayne's task specified these names, so they'll need registry entries.
- Composite objects (poison-bottle, candle-holder, nightstand) need mutate on BOTH the verb-triggered AND the detach_part transitions — same mutation, two paths to the same state change.
- When adding keywords ±open to open/close patterns, it's a project-wide convention now: window, wardrobe, nightstand, vanity, curtains, trap-door all follow it.
- Documentation charter: every object gets a .md in docs/objects/. Created 9 new docs, updated 4 existing.

### Level 1 Object Specification Pass (2026-07-21)
- Created 5 comprehensive room-based object specification docs in `docs/objects/level-01-*.md` covering all ~38 new objects needed for Level 1's 5 new rooms.
- **Storage Cellar (10 objects):** large-crate, small-crate, grain-sack, wine-rack, wine-bottle, rope-coil, iron-key, oil-lantern, crowbar, rat. Most complex room — nested container puzzle (crate→sack→key) and optional light upgrade puzzle (lantern+oil).
- **Deep Cellar (8 objects):** stone-altar, wall-sconce, incense-burner, tattered-scroll, silver-key, stone-sarcophagus, offering-bowl, chain. Narrative-focused room — altar puzzle with offering mechanic.
- **Hallway (5 objects):** torch, portrait, side-table, vase, locked-door. Reward/transition room — no puzzles, lore delivery via portraits.
- **Courtyard (6 objects):** stone-well, well-bucket, ivy, cobblestone, wooden-door, rain-barrel. Optional room — climbing, water mechanics.
- **Crypt (9 base objects, 5 sarcophagus instances):** sarcophagus, candle-stub, skull, burial-jewelry, burial-coins, tome, silver-dagger, wall-inscription. Lore-heavy — Blackwood family history, tome as critical narrative prize.

#### New Materials Needed (4 total)
Flagged materials NOT in `src/engine/materials/init.lua`:
1. **stone** — altar, sarcophagus, well, cobblestone, wall-inscription. Critical — used by 8+ objects across 3 rooms.
2. **silver** — silver-key, silver-dagger, burial-jewelry, burial-coins. Important for value system.
3. **hemp** — rope-coil. Single object but unique material.
4. **bone** — skull. Single object, niche material.
- `burlap` was also flagged (grain-sack) but `fabric` works as fallback.
- These should be added to the registry before building .lua files. Coordinate with Frink/Bart.

#### Design Patterns Established for New Objects
- **Nested Container Puzzle pattern:** sealed crate (requires prying_tool) → tied sack (requires cutting_edge or untie by hand) → hidden key. Three-layer accessibility gate.
- **Fuel-then-light pattern (oil-lantern):** empty → fueled (requires lamp-oil) → lit (requires fire_source). Two-step activation extends the candle "light" pattern.
- **Instance Override for Content Variants:** wine-bottle base object with instance overrides for oil variant. Sensory clues (smell, viscosity, no label) distinguish oil from wine. One base, multiple behaviors.
- **Ambient Creature pattern (rat):** 4-state FSM (hidden→visible→fleeing→gone) driven by auto-transitions and player proximity triggers. Not portable, not interactive — pure atmosphere. Proves Principle 8: creatures are just objects with states.
- **Effigy-as-description (not separate object):** Sarcophagus effigies are part of the sarcophagus's closed state description, not independent objects. Avoids object fragmentation.
- **Lore Cross-referencing pattern:** wall-inscription names ↔ portrait names ↔ sarcophagus contents ↔ tome text. The same family narrative is told from multiple angles across rooms, rewarding exploration.

#### Coordination Notes
- **For Bob (Puzzle Master):** Puzzle 012 (Altar Puzzle) has a placeholder offering mechanism — the offering-bowl guard needs the specific acceptable offering item defined. Puzzle 013 (Courtyard Entry) has multiple possible paths — wooden-door unlock, ivy climb, or both.
- **For Bart (Engine):** Oil-lantern's fueling step requires `requires_tool = "lamp-oil"` — need to confirm the engine can resolve a tool capability from a container's contents_type (wine-bottle-oil instance).
- **For Moe (World Builder):** Object placement coordinates included in each spec. Spatial relationships (large-crate against east wall, rope on peg, etc.) should be honored in room files.
- **For Wayne:** Several design decisions flagged as TBD — altar offering item, courtyard door key, crypt lore text, buried-alive sarcophagus significance. See CBG's decision points in level-01-intro.md §Wayne's Decision Points.

### Level 1 Object Build Pass (2026-07-21)
- Built all 37 new .lua object files in `src/meta/objects/` from Level 1 specifications.
- **Storage Cellar (10 files):** large-crate, small-crate, grain-sack, wine-rack, wine-bottle, rope-coil, iron-key, oil-lantern, crowbar, rat.
- **Deep Cellar (7 files):** stone-altar, wall-sconce, incense-burner, tattered-scroll, silver-key, stone-sarcophagus, offering-bowl, chain.
- **Hallway (5 files):** torch, portrait, side-table, vase, locked-door.
- **Courtyard (6 files):** stone-well, well-bucket, ivy, cobblestone, wooden-door, rain-barrel.
- **Crypt (8 files):** sarcophagus (base for 5 instances), candle-stub, skull, burial-jewelry, burial-coins, tome, silver-dagger, wall-inscription.
- All 37 files pass Lua syntax validation (`loadfile()` check).

#### Build Patterns Applied
- Every FSM object follows candle.lua/poison-bottle.lua structure: guid, id, material, keywords, states table, transitions table, mutations table.
- Static objects (keys, tools, furniture) follow brass-key.lua pattern: flat metadata, no FSM.
- All objects include sensory properties (description, on_feel, on_smell minimum) per Principle 6.
- `provides_tool` used for: crowbar (prying_tool, blunt_weapon, leverage), rope-coil (rope, binding), cobblestone (blunt_weapon, weight, hammer), silver-dagger (cutting_edge, injury_source, ritual_blade), torch (fire_source).
- `surfaces` used for containers: crates (inside), wine-rack (inside), altar (top, behind), sarcophagus (inside, top), well (top, inside), offering-bowl (inside), wall-sconce (inside with accepts filter).
- Timer metadata (burn_duration, remaining_burn) on: oil-lantern (14400s), torch (10800s), candle-stub (1800s).
- `room_presence` strings on all objects that appear independently in rooms.
- `prerequisites` (GOAP) on: large-crate, grain-sack, oil-lantern, torch, candle-stub, sarcophagus, tattered-scroll, tome.

#### Materials Referenced (not yet in registry)
- `stone` — 7 objects (stone-altar, stone-sarcophagus, sarcophagus, stone-well, cobblestone, wall-inscription, offering-bowl uses ceramic)
- `silver` — 4 objects (silver-key, silver-dagger, burial-jewelry, burial-coins)
- `hemp` — 1 object (rope-coil)
- `bone` — 1 object (skull)
- `burlap` — 1 object (grain-sack)
- `tallow` — 1 object (candle-stub) — may or may not exist in registry
- These need Frink/Bart to add to `src/engine/materials/init.lua`.

### Template Assignment Audit (2026-07-20)
- Lisa's audit found 61 objects (not 12) missing template declarations in src/meta/objects/
- Assigned templates to all 61: 23 small-item, 25 furniture, 7 container, 6 sheet
- Convention: template field goes after guid, before id (matches bandage.lua etc.)
- Ambiguous cases resolved: rat→furniture (no creature template), curtains/rug→sheet (fabric nature overrides non-portability), candle-holder→small-item (portable despite 'furniture' category), poison-bottle→small-item (has 'small-item' in categories), barrel/rain-barrel→furniture (heavy immovable despite container categories)
- All 78 object files pass Lua syntax check after changes

## Learnings

### Wine Bottle FSM — Puzzle 016 (2026-07-22)
- Added DRINK transition (`open → empty`) to `wine-bottle.lua` with aliases: quaff, sip, swig
- Added `on_taste` sensory properties to all three interactive states (sealed, open, empty) — TASTE investigates without consuming; DRINK consumes and transitions state
- Changed template from `container` to `small-item` — wine bottle is holdable/drinkable, not a storage container; matches poison-bottle pattern
- Updated categories from `{"container", ...}` to `{"small-item", ...}` for consistency
- Added `drink` prerequisite requiring `open` state — prevents drinking a sealed bottle
- Updated OPEN message to match puzzle doc spec ("peel away crumbling wax seal")
- Added `contains = nil` to both drink and pour mutate blocks — empties the bottle content reference
- Updated empty state descriptions for more sensory detail (dry inside, dark stain)
- Added `on_drink_reject` to `oil-flask.lua` for when player tries to drink lamp oil
- Followed puzzle-016 design doc: NO mechanical effect from drinking (no liquid_courage flag, no buff). The design explicitly says "flavor text only" — the teaching is the DRINK verb itself, not a reward system
- Per-bottle flavor variations (3 different drink messages) are handled via instance overrides in room placement, not in the base object — that's Moe's domain
- The wine rack already has the 3 bottles in `surfaces.inside.contents` — no room changes needed

### BUG-061 & BUG-062 Fixes — Nelson Pass 016 (2026-07-22)
- **BUG-061 (HIGH):** Wine rack `surfaces.inside.contents` referenced `{"wine-bottle-1", "wine-bottle-2", "wine-bottle-3"}` but the room instance in `storage-cellar.lua` only places one bottle with `id = "wine-bottle"`. Fixed by updating wine-rack contents to `{"wine-bottle"}` to match the actual instance ID. Lesson: always cross-check rack/container content IDs against room instance IDs — they must match exactly.
- **BUG-062 (LOW):** Oil flask's `on_drink_reject` field was never checked by the drink verb handler. The handler fell through to the generic "You can't drink..." message. Fixed by adding a check for `obj.on_drink_reject` in `src/engine/verbs/init.lua` before the generic fallback. Lesson: when adding custom rejection fields to objects, always verify the engine verb handler actually reads them — object data is inert without engine support.

### Injury Lua Templates — First 5 Implementations (2026-07-25)
- Created `src/meta/injuries/` directory and implemented 5 injury `.lua` files from Bob's design docs
- All files follow the canonical template format from `docs/architecture/player/injury-template-example.md`
- Each file returns a single Lua table with GUID, FSM states, transitions, timers, and healing interactions
- **minor-cut.lua** `{fc7f4ea7-c569-4f6d-bc80-64f918ccfb42}` — One-time (3 dmg), physical. States: active/treated/healed. Self-heals in 5 turns; bandage accelerates to 2 turns. No capability restrictions.
- **bleeding.lua** `{f6c20c23-a8e3-402e-afc7-1f0857481b4c}` — Over-time (5 dmg/tick), physical. States: active/treated/worsened/critical/fatal/healed. 15-turn worsen timer. Bandage stops drain; poultice works even in critical. Restricts climb (active), run (worsened), fight (critical).
- **poisoned-nightshade.lua** `{62874f58-bcee-4f39-9f63-c3953d532aea}` — Over-time (8 dmg/tick), toxin. States: active/worsened/neutralized/fatal/healed. 4-turn escalation windows. ONLY antidote-nightshade works. Generic cures rejected by empty healing_interactions. Recovery from worsened takes 6 turns via `_timer_delay` mutate.
- **burn.lua** `{d182984e-b424-47d9-91fc-2796d993228c}` — One-time (5 dmg), environmental. States: active/blistered/treated/healed. Minor burns self-heal in 10 turns; severe burns blister at 8 turns (source overrides timer). Cold-water, damp-cloth treat active; salve treats active AND blistered.
- **bruised.lua** `{4deab41d-f062-4f05-89fd-8fc2cbc2d073}` — One-time (4 dmg), physical. States: active/recovering/healed. Self-heals in 8 turns; rest/sleep accelerates to 4 turns. No item required. Restricts climb/run/jump. Empty healing_interactions (verb-only treatment).
- Replaced older prototype `poisoned-nightshade.lua` (had no GUID, no transitions table, no worsened state, used non-canonical `symptom` and `auto_heal_turns` fields) with full canonical format
- Key design decisions: used "neutralized" state name for nightshade (matches Bob's design, distinct from physical "treated"); burn blistered-path timer is set by inflicting object override; bruised healing_interactions is empty because rest is a verb, not an item
- All 5 files validated: Lua syntax clean, return tables with guid/id/states/transitions confirmed