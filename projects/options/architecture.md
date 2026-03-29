# Options / Hint System — Architecture Proposal

**Author:** Bart (Architect)  
**Requested by:** Wayne "Effe" Berry  
**Date:** 2026-08-02  
**Status:** Draft — awaiting review

---

## 1. Problem Statement

Players get stuck. Especially new players in the dark at 2 AM with no context. The
game is deliberately opaque — sensory exploration IS the gameplay — but there's a
gap between "I'm exploring" and "I have no idea what to do." We need a system that
nudges without spoiling, adapts to player state, and doesn't break immersion.

The player types "what are my options" or "give me options" and gets a numbered
list of 1–4 actionable things. They can type a number to execute that command
directly.

---

## 2. Analysis of Three Approaches

### A. Engine-Determined (Fully Dynamic)

The engine scans the current game state — objects in the room, exits, inventory,
FSM states, light level, containment hierarchy — and assembles a list of viable
actions.

**How it works:**
- Walk `current_room.contents`, check each object for available verbs, transitions,
  unopened containers, surfaces with items
- Check exits (locked doors → suggest unlock, closed → suggest open, open → suggest go)
- Check inventory for unused tools, consumables, unread items
- Filter by light level (dark → only non-visual verbs: feel, listen, smell)
- Rank by "interestingness" heuristic (unexplored > state-changeable > ordinary)

**Pros:**
- Always accurate — reflects actual game state
- Zero maintenance — no metadata to author or keep in sync
- Adapts automatically as player progresses (won't suggest "open door" when it's open)
- Scales to any number of rooms and objects without additional work

**Cons:**
- Combinatorial explosion — a room with 10 objects and 31 verbs produces hundreds of
  valid verb+noun pairs. Most are uninteresting ("feel the wall", "smell the floor")
- Hard to prioritize. The engine knows what's *possible* but not what's *interesting*.
  "Take the key" and "smell the barrel" are equally valid; only one advances the game
- No narrative voice — suggestions would be mechanical ("open barrel", "go north")
  unless we layer presentation on top
- Risk of suggesting spoiler actions (listing a hidden object the player hasn't found yet)

**Verdict:** Necessary machinery, but insufficient alone. This is an ingredient, not a meal.

---

### B. Room-Baked (Static Hints)

Each `room.lua` includes an `options` or `hints` field with hand-written suggestions.

```lua
-- Example: cellar.lua
hints = {
    { text = "Feel around in the darkness", command = "feel" },
    { text = "Try the door to the north",   command = "open door north" },
    { text = "Listen for sounds",           command = "listen" },
}
```

**Pros:**
- Hand-crafted quality — designers control exactly what players see
- Narrative voice built in ("Feel around in the darkness" vs "feel room")
- Can guide the player toward the intended experience path
- Simple to implement — just read a table and print it

**Cons:**
- Stale hints. If the player already opened the door, "try the door" is useless.
  Worse, if they already have the key, suggesting "find the key" is confusing
- Combinatorial state problem. A room with 3 binary states (door open/closed, light
  on/off, barrel searched/not) needs 8 hint variations. Real rooms have dozens of
  states. This doesn't scale
- Maintenance burden — every room needs hints authored and updated when objects change
- Violates Principle 8 (objects declare behavior, engine executes) by embedding
  gameplay logic in static room data
- Doesn't account for inventory — player might have the key but the hint says "search
  for a key"

**Verdict:** Good for narrative framing, terrible for accuracy. Static hints will lie.

---

### C. Goal-Driven Hybrid (Room Declares Goal, Engine Plans Path)

Rooms declare a high-level `goal`. The engine uses the existing GOAP planner to work
backward from that goal, identifies unmet prerequisites, and presents the first
actionable steps as options.

**How it works:**
- Room defines: `goal = { verb = "go", noun = "north", label = "escape this room" }`
- Engine calls GOAP planner with goal verb+noun against current state
- GOAP returns a plan: `[open drawer → take key → unlock door → open door → go north]`
- Engine checks which steps are already done (door already unlocked? skip that)
- Presents the FIRST 1–2 unmet steps as options
- Fills remaining slots (up to 4) with dynamic sensory suggestions from Approach A

**Pros:**
- Adapts to player state — GOAP replans from current conditions every time
- Narratively guided — the goal gives direction without giving away the answer
- Leverages existing infrastructure (`goal_planner.lua` already does backward chaining)
- Scales naturally — GOAP handles combinatorial state, not the hint author
- Respects Principle 8 — room declares the goal (metadata), engine figures out the path

**Cons:**
- GOAP plans can be non-obvious or suboptimal (player might not think to "open
  nightstand" before "take matchbox")
- Goal definition is new metadata, but it's a single field per room — minimal burden
- GOAP might expose puzzle solutions if we show too many steps ahead
- Some rooms may not have a clear single goal (exploration rooms vs puzzle rooms)

**Verdict:** Right architecture. Combines the accuracy of dynamic analysis with the
narrative direction of authored content.

---

## 3. Recommendation

**Approach C (Goal-Driven Hybrid)** with a layered strategy:

```
┌──────────────────────────────────────────────────┐
│ Layer 3: Narrative Framing (room.hints_flavor)   │  ← Optional per-room flavor text
│ Layer 2: Goal-Directed Steps (GOAP planner)      │  ← 1–2 progression-relevant actions
│ Layer 1: Sensory Exploration (dynamic scan)      │  ← 2–3 senses/exploration actions
│ Layer 0: State Assessment (engine query)         │  ← Light? Exits? Inventory? Objects?
└──────────────────────────────────────────────────┘
```

### Why This Combination

1. **We already have GOAP.** The `goal_planner.lua` module does backward chaining for
   tool prerequisites. Extending it to room-level goals is natural — same algorithm,
   wider scope. We're not building new infrastructure; we're pointing existing
   infrastructure at a new problem.

2. **Principle 8 alignment.** Rooms declare a `goal` (metadata). The engine plans the
   path (behavior). No room-specific logic in the engine. No engine-specific logic in
   rooms.

3. **Sensory exploration IS the gameplay.** The options list should encourage sensory
   verbs (feel, listen, smell) alongside goal-directed actions. Layer 1 always suggests
   at least one sensory verb appropriate to the current state (in darkness: feel > smell
   > listen; in light: look > search > examine).

4. **Anti-spoiler by design.** We show only the NEXT step, not the whole plan. Player
   sees "feel around for objects" not "find key, unlock door, escape." The system nudges;
   it doesn't solve.

5. **Optional narrative framing.** Rooms CAN provide `hints_flavor` — a short intro
   line like "You consider what you know..." — but the actual options are always
   engine-generated. This gives Moe/Bob a creative hook without the maintenance burden
   of static hints.

### Should Options Cost Something?

**No.** Reasoning:

- The options list presents actions the player could figure out themselves. It's
  accessibility, not a cheat code
- Adding a cost (time, resource, sanity) punishes players who are already struggling
- The game's natural difficulty (darkness, limited matches, two-hand inventory) already
  gates progression — the hint system helps players engage with those mechanics, not
  bypass them
- If we want to discourage over-reliance, we can make repeated `options` in the same
  room return the same list (no new information), and have the narrator sound
  increasingly bored: "You ponder your situation... again."

---

## 4. Technical Design

### 4.1 Verb Handler

New verb: `options` — registered in `meta.lua` alongside `help`, `inventory`, `time`.

The handler lives in a new module: `src/engine/verbs/options.lua`. This keeps the
growing `meta.lua` from becoming another monolith. The module exports a single
`register(handlers)` function following the existing pattern.

```
src/engine/verbs/options.lua    ← NEW: options verb handler + state scanner
```

`verbs/init.lua` adds one line:

```lua
local options = require("engine.verbs.options")
options.register(handlers)
```

### 4.2 Parser Integration

Add aliases so the player can trigger `options` naturally. Three touch points:

**a) `preprocess/data.lua` — verb table:**
```lua
options = true,
```

**b) `preprocess/phrases.lua` — question patterns (extend the existing block):**
```lua
if text:match("^what%s+are%s+my%s+options")
    or text:match("^give%s+me%s+options")
    or text:match("^what%s+can%s+i%s+try")
    or text:match("^i'?m%s+stuck")
    or text:match("^hint$")
    or text:match("^hints$")
    or text:match("^nudge$") then
    return "options"
end
```

This is distinct from the existing `help` patterns ("what can I do", "how do I..."),
which remain mapped to `help`. The `help` verb shows the command reference; `options`
shows contextual suggestions. Different intents, different verbs.

**c) `preprocess/idioms.lua` — idiom table:**
```lua
["give me a nudge"]  = "options",
["give me a hint"]   = "options",   -- re-route from help → options
["suggest something"] = "options",
```

### 4.3 Numbered Selection System

When the player gets an options list, the engine stores the mapping in
`ctx.player.pending_options`:

```lua
ctx.player.pending_options = {
    { command = "feel",           display = "Feel around for objects in the darkness" },
    { command = "open door north", display = "Try the door to the north" },
    { command = "look up",         display = "Look up toward the trapdoor" },
    { command = "listen",          display = "Listen carefully for sounds" },
}
```

The main loop (`loop/init.lua`) checks for numeric input BEFORE passing to the parser:

```lua
local num = tonumber(input)
if num and ctx.player.pending_options and ctx.player.pending_options[num] then
    input = ctx.player.pending_options[num].command
    ctx.player.pending_options = nil  -- clear after use
end
```

This is clean because:
- It intercepts at the top of the loop, before preprocessing
- The substituted command flows through the normal parser pipeline
- `pending_options` is cleared on any non-numeric input (player types something else →
  options expire)
- No special state machine needed — it's a one-shot lookup table

### 4.4 Options Generation Algorithm

The `options` handler assembles a list of up to 4 suggestions using three sources,
in priority order:

```
function generate_options(ctx)
    local opts = {}

    -- Phase 1: Goal-directed steps (0–2 items)
    if ctx.current_room.goal then
        local plan = goal_planner.plan_for_goal(ctx, ctx.current_room.goal)
        if plan and #plan > 0 then
            -- Take only the first unmet step (anti-spoiler)
            opts[#opts + 1] = wrap_goal_step(plan[1])
            -- If first step is trivial (movement), show step 2 as well
            if #plan > 1 and plan[1].verb == "go" then
                opts[#opts + 1] = wrap_goal_step(plan[2])
            end
        end
    end

    -- Phase 2: Sensory exploration (1–2 items)
    local sensory = pick_sensory_suggestions(ctx)
    for _, s in ipairs(sensory) do
        if #opts < 4 then opts[#opts + 1] = s end
    end

    -- Phase 3: Dynamic object scan (fill remaining slots)
    local dynamic = scan_interesting_actions(ctx)
    for _, d in ipairs(dynamic) do
        if #opts < 4 then opts[#opts + 1] = d end
    end

    return opts
end
```

#### Phase 1: Goal-Directed Steps

New function in `goal_planner.lua`:

```lua
function goal_planner.plan_for_goal(ctx, goal)
```

Takes a goal table `{ verb = "go", noun = "north" }` and runs the existing backward
chaining logic. Returns a list of `{ verb, noun }` steps, filtered to only unmet
prerequisites. This is a thin wrapper around the existing `plan()` function — the
planner already knows how to resolve tool requirements, locked doors, dark rooms, etc.

#### Phase 2: Sensory Suggestions

Picks 1–2 sensory verbs based on state:

| Condition | Suggestions |
|-----------|-------------|
| Dark, no light source | `feel`, `listen`, `smell` (rotate based on what player has tried recently) |
| Dark, has unlit candle | `feel`, then goal step for lighting it |
| Lit room, unexplored objects | `look at <object>`, `search <container>` |
| Any state | Avoid suggesting senses the player used in the last 2 turns (use context window) |

The context window (`parser/context.lua`) already tracks recent commands. We query it
to avoid repeating suggestions.

#### Phase 3: Dynamic Object Scan

Scans the room for "interesting" actions — things with state changes available:

- Closed containers → "open <container>"
- Locked exits → "try the door" / "examine the lock"
- Objects with FSM transitions available → "light the <thing>" / "strike the match"
- Unexplored surfaces → "look on <furniture>"
- Objects not yet examined → "examine <object>" (if lit)

Each candidate is scored by a simple heuristic:

```
score = 0
if obj.has_unexplored_transition  then score = score + 3 end
if obj.container and not obj.open then score = score + 2 end
if obj.is_exit and obj.locked     then score = score + 2 end
if not obj._examined              then score = score + 1 end
```

Top-scored candidates fill remaining slots.

### 4.5 Room Goal Metadata

Rooms MAY declare a `goal` field. It's optional — rooms without goals still get
sensory + dynamic suggestions.

```lua
-- In room.lua:
goal = {
    verb = "go",
    noun = "north",
    label = "find a way through",  -- optional flavor for the narrator
},
```

The `label` field is used in the narrator's framing text, not shown directly as an
option. It gives the system thematic context without revealing the solution.

Rooms can also declare multiple goals for different phases:

```lua
goals = {
    { verb = "light", noun = "candle", label = "find light", priority = 1 },
    { verb = "go",    noun = "down",   label = "explore deeper", priority = 2 },
},
```

The engine picks the highest-priority unmet goal. Once a goal's verb+noun succeeds
(the candle is lit), it falls through to the next. This handles multi-objective rooms
like the bedroom (light → explore → exit).

### 4.6 Presentation

The options verb handler wraps output in narrative framing:

```lua
local FLAVOR_LINES = {
    "You consider your situation...",
    "You take a moment to think...",
    "You pause and assess what you know...",
    "You weigh your choices...",
}
-- Pick one randomly (or cycle)
```

Then prints numbered options:

```
You consider your situation...
  1. Feel around for objects in the darkness
  2. Try the door to the north
  3. Look up toward the trapdoor
  4. Listen carefully for sounds
```

Display text is authored in `wrap_goal_step()` and `pick_sensory_suggestions()` using
templates that read naturally:

| Command | Display template |
|---------|-----------------|
| `feel` | "Feel around for objects in the darkness" / "Run your hands over nearby surfaces" |
| `listen` | "Listen carefully for sounds" |
| `smell` | "Sniff the air for clues" |
| `look` | "Look around the room" |
| `open <x>` | "Try to open the <x.name>" |
| `go <dir>` | "Head <direction>" / "Try the door to the <direction>" |
| `take <x>` | "Pick up the <x.name>" |
| `examine <x>` | "Take a closer look at the <x.name>" |
| `unlock <x>` | "Try to unlock the <x.name>" |

### 4.7 Anti-Spoiler Rules

1. **One step ahead, never two.** Only show the immediate next action, not the full
   GOAP plan chain
2. **No hidden objects.** Don't suggest interacting with objects the player hasn't
   discovered (check `obj.hidden` and whether player has "seen" or "felt" the object)
3. **Sensory before specific.** In darkness, suggest "feel around" before "take the
   key from under the rug" — let the player discover objects through play
4. **Exits over solutions.** Suggest exploring exits before suggesting puzzle solutions
5. **Diminishing novelty.** If player asks `options` 3+ times in the same room without
   acting, the narrator hints more directly: "Perhaps you should try actually DOING
   something..." — gentle push toward action, not more information

### 4.8 Clearing Pending Options

`pending_options` is cleared when:
- Player types a number and the command executes
- Player types any non-numeric input (they chose to do something else)
- Player moves to a different room
- Player types `options` again (refreshes the list)

---

## 5. Example: The Cellar

The cellar at game start. Player has just arrived, it's 2 AM, pitch dark. No items
in hand.

### Room goal definition (cellar.lua — Moe adds this field):

```lua
goal = {
    verb = "go",
    noun = "north",
    label = "find a way forward",
},
```

### Interaction:

```
The Cellar
You stand at the foot of a narrow stone stairway...

> what are my options
You consider your situation...
  1. Feel around for objects in the darkness
  2. Listen carefully for sounds
  3. Try the door to the north
  4. Sniff the air for clues

> 1
(feel)
Your hands find rough stone walls, slick with moisture. A large wooden
barrel sits against one wall. Nearby, an iron bracket juts from the stone.
A metal brazier squats against the far wall, cold and empty.

> what are my options
You take a moment to think...
  1. Feel the barrel more closely
  2. Feel the iron bracket on the wall
  3. Try the door to the north
  4. Listen carefully for sounds

> 3
(open door north)
The door is locked. A heavy padlock secures it shut.

> options
You weigh your choices...
  1. Feel the padlock on the door
  2. Search the barrel
  3. Feel the iron bracket on the wall
  4. Listen carefully for sounds
```

### What's happening under the hood:

**First `options` call:**
- Phase 1 (Goal): GOAP plans `go north` → prerequisite: `open door north` → prerequisite:
  `unlock padlock` → prerequisite: find key. First exposed step: `open door north`, but
  it's dark and player hasn't discovered the door yet. Anti-spoiler Rule 3 kicks in:
  suggest sensory exploration instead. Door is still shown as "try the door" because
  exits are always known (the room description mentions directions)
- Phase 2 (Sensory): Dark room → suggest `feel`, `listen`, `smell`. Player hasn't used
  any senses yet, so `feel` gets top priority (primary dark sense)
- Phase 3 (Dynamic): No scored candidates beat the sensory suggestions
- Result: 4 options, mostly exploratory

**Second `options` call (after `feel`):**
- Player has now discovered the barrel, bracket, and brazier via touch
- Phase 2 (Sensory): `feel` was just used → suggest feel-specific-object instead of
  generic feel. Rotate to new targets
- Phase 1 (Goal): Still suggests trying the door (exit-priority rule)
- Phase 3 (Dynamic): Barrel is a container → "search the barrel" surfaces

**Third `options` call (after trying the locked door):**
- Player now knows the door is locked
- Phase 1 (Goal): GOAP knows door needs unlocking → padlock is the blocker → suggest
  "feel the padlock" (examine the obstacle, anti-spoiler: don't say "find the key")
- Phase 2: Rotate to objects not yet explored individually

---

## 6. Example: The Bedroom (Lit Room)

Player has lit the candle. Room is illuminated. Bedroom has many objects.

```
> options
You consider your situation...
  1. Look under the bed
  2. Open the nightstand drawer
  3. Search the wardrobe
  4. Examine the rug on the floor

> 2
(open drawer)
You pull open the nightstand drawer. Inside you find a matchbox and a
small poultice wrapped in cloth.
```

Here the system prioritizes containers and unexplored surfaces because the room is lit
(visual verbs available) and there's lots of undiscovered content.

---

## 7. File Changes Summary

| File | Change | Owner |
|------|--------|-------|
| `src/engine/verbs/options.lua` | NEW — options verb handler, state scanner, presentation | Bart |
| `src/engine/verbs/init.lua` | Add `require + register` for options module | Bart |
| `src/engine/parser/preprocess/data.lua` | Add `options = true` to verb table | Bart |
| `src/engine/parser/preprocess/phrases.lua` | Add alias patterns for options/hint/stuck | Bart |
| `src/engine/parser/preprocess/idioms.lua` | Add idiom mappings | Bart |
| `src/engine/parser/goal_planner.lua` | Add `plan_for_goal(ctx, goal)` wrapper | Bart |
| `src/engine/loop/init.lua` | Add numeric input interception for pending_options | Bart |
| `src/meta/rooms/*.lua` | Add optional `goal` field to room definitions | Moe |
| `test/verbs/test-options.lua` | NEW — unit tests for options generation | Nelson |
| `test/integration/test-options-flow.lua` | NEW — end-to-end options + number selection | Nelson |

---

## 8. Implementation Phases

### Phase 1: Core Verb + Number Selection (Bart)
- `options.lua` verb handler with Phase 2 (sensory) + Phase 3 (dynamic scan) only
- Numeric input interception in `loop/init.lua`
- Parser aliases
- No GOAP integration yet — purely dynamic suggestions
- **Tests:** Handler returns options, number selection executes correct command

### Phase 2: GOAP Goal Integration (Bart)
- Add `plan_for_goal()` to `goal_planner.lua`
- Wire Phase 1 (goal-directed) into options generation
- Anti-spoiler filtering
- **Tests:** Goal-driven options adapt to state changes

### Phase 3: Room Goals (Moe)
- Add `goal` field to room definitions
- Author goals for all 7 Level 1 rooms
- **Tests:** Integration tests verify options in each room

### Phase 4: Polish (Smithers + Bob)
- Narrative framing text
- Display text templates for natural language
- Diminishing-returns messaging for repeated requests
- **Tests:** Presentation quality, edge cases

---

## 9. Open Questions

1. **Should `options` replace `help` for "give me a hint"?** Currently "give me a hint"
   maps to `help` (command reference). I think it should map to `options` (contextual
   nudge). The player asking for a hint wants guidance, not a verb list. Recommend
   re-routing.

2. **Multi-level goals.** Should goals be per-level as well as per-room? E.g., Level 1
   goal = "escape the manor." Room goals contribute steps toward the level goal. This
   adds complexity but enables long-range hints ("You feel like you need to go deeper
   into the manor..."). Defer to Phase 2.

3. **Creature interactions.** When creatures are present, should options suggest
   combat/evasion actions? Probably yes, but creature AI is Phase 5 territory. Flag for
   future integration.

4. **Context window integration.** The context window tracks recent commands. Should
   repeated `options` calls in the same room show the SAME list (stable) or rotate
   suggestions (varied)? I lean toward stable-with-rotation: same goal steps, rotated
   sensory suggestions.

---

*This proposal is an architecture document. Implementation requires Wayne's approval
on the approach before code is written.*
