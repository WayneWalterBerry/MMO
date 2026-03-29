# Options / Hint System — Architecture Proposal

**Author:** Bart (Architect)  
**Requested by:** Wayne "Effe" Berry  
**Date:** 2026-08-02  
**Status:** Approved — v2 (post-review, blockers resolved)  
**Wayne's Decisions:** Approach C (goal-driven hybrid), Option C context window (stable goals + rotating sensory), free hints, state-based goal detection

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

### 4.0 API Contracts

This section defines the interface contracts between the options system and the rest of the engine.

#### Option Table Structure

Each option entry returned by the system follows this structure:

```lua
---@class OptionEntry
---@field command string    -- executable command string (e.g., "feel", "open door north")
---@field display string    -- player-facing display text (e.g., "Feel around for objects in the darkness")
---@field source  string    -- "goal" | "sensory" | "dynamic" — which generation phase produced this
```

The `source` field enables debugging and metrics but is not shown to the player. It allows us to track whether players prefer goal-driven vs. exploratory suggestions.

#### Context Requirements

The options generator requires these fields from the context table:

- **`ctx.current_room`** — room table with optional `goal` (or `goals` array), `contents`, `exits`
- **`ctx.player`** — player table with `inventory`, `location`, `pending_options`
- **`ctx.light_level`** — current illumination state (dark/dim/lit)
- **`ctx.recent_commands`** — last N commands from context window (for rotation)
- **`ctx.options_request_count`** — number of times options requested in current room (for escalating specificity)

The `options_request_count` resets when the player changes rooms. It's used to detect repeated requests without action ("You ponder your situation... again").

#### Return Type

The `generate_options()` function returns:

```lua
---@class OptionsResult
---@field options OptionEntry[]  -- 1-4 entries, ordered by priority
---@field flavor_text string     -- narrator framing line ("You consider your situation...")
```

The `flavor_text` rotates or escalates based on `options_request_count`. After 3+ requests in the same room without state change, the narrator becomes more direct: "Perhaps you should try actually DOING something..."

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

#### Precedence Rule

**`pending_options` is ONLY active after the player calls the `options` verb.** When `pending_options` is `nil` (the default state), numeric input passes through to the normal parser unchanged. This means objects with numeric names (e.g., an object called "2") work normally — the options system never intercepts input unless the player explicitly requested options.

This precedence ensures that numeric object names don't collide with the numbered selection system. The engine only treats numeric input as option selection when the player has an active options window.

#### Collision Avoidance

Rooms with numbered exits (if any) are handled by the same precedence rule: when `pending_options` is active, numbers 1-4 are reserved for option selection. When inactive, numbers route normally. If a room genuinely uses "1", "2" etc. as exit names, the player must type something other than the bare number to use those exits while options are pending (e.g., "go 1" instead of just "1").

**Documentation note:** Numeric input is reserved for option selection ONLY during the active options window. Once the player types a number and the command executes (or types any non-numeric input), `pending_options` is cleared and numeric inputs return to normal parser behavior. This keeps the collision window minimal — only the brief period between calling `options` and acting on one of the suggestions.

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

#### 4.4.1 Performance Budget

Options generation (all three phases combined) MUST complete in **<50ms** on the reference hardware. This is the baseline for `test/options/test-performance.lua`. 

The 50ms budget breaks down roughly as:
- Phase 1 (GOAP planning): up to 30ms
- Phase 2 (sensory suggestions): up to 10ms
- Phase 3 (dynamic scan): up to 10ms

If GOAP planning for a room goal exceeds 30ms, the goal phase is skipped for that call and only sensory+dynamic suggestions are returned (graceful degradation, not failure). The system logs a warning but the player sees no error — they simply get exploratory suggestions instead of goal-directed ones.

This performance constraint ensures the `options` verb feels instant. Players invoking help systems expect immediate feedback; a laggy hint system breaks immersion. The 50ms threshold is based on human perception of instant response (typically <100ms).

**Implementation note:** Use `os.clock()` to measure phase durations. If Phase 1 times out, set a flag on the room object to skip GOAP for the next N requests (backoff pattern) rather than retrying every time.

#### 4.4.2 Edge Case: Empty Room / No Suggestions

When a room has:
- No `goal` defined
- No interesting objects (nothing with state transitions, no containers, no unexplored items)
- No scored candidates from the dynamic scan

The system returns generic exploration prompts:
1. "Look around" (if lit) / "Feel around" (if dark)  
2. "Listen carefully"
3. Available exits: "Head <direction>" for each open/unlocked exit

If even those aren't applicable (no exits, nothing to sense — shouldn't happen but defensive code), return a single option: 

```lua
{ command = "wait", display = "Wait and see what happens...", source = "fallback" }
```

with flavor text: 

```
"Nothing obvious comes to mind..."
```

This prevents the options system from ever returning an empty list. An empty list would be a UI failure — the player invoked help and got nothing. Even a trivial suggestion ("wait") is better than silence. It signals "the system is working, but there genuinely isn't much to do here."

**Design rationale:** Empty rooms are rare but possible (e.g., a cleared-out room post-puzzle, a pure narrative beat room). The fallback ensures the system never crashes or returns `nil`.

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

#### Goal Completion Detection

Goals use **state-based completion detection** (not action-based). A goal is "complete" when its postcondition state is true in the game world, NOT when the player attempts the action.

**Example:** Goal `{ verb = "go", noun = "north" }` is complete when `player.location` has changed to the room north of the current one. Merely typing "go north" while the door is locked does NOT complete the goal — the state didn't change.

This matters because:
- Failed actions (locked door, too dark, missing tool) don't count as goal completion
- The options system continues suggesting goal steps until the state actually changes
- Multi-priority goals (the `goals` array) fall through only when state confirms completion

**Implementation:** After each game tick, check `goal_complete(ctx, goal)` → returns true if the goal's postcondition holds. Use existing state-query infrastructure from the FSM tick.

For common goal types:
- `{ verb = "go", noun = "north" }` → complete when `ctx.player.location.id ~= starting_room_id`
- `{ verb = "light", noun = "candle" }` → complete when `candle._state == "lit"`
- `{ verb = "take", noun = "key" }` → complete when `find_in_inventory(ctx.player, "key") ~= nil`
- `{ verb = "unlock", noun = "door" }` → complete when `door.locked == false`

The `goal_complete()` function is generic — it queries the current game state and compares it to the goal's intent. This keeps goal definitions simple (just verb+noun) while the engine handles verification.

**Edge case:** If a goal cannot be verified via state query (e.g., a one-time narrative event), it can include an explicit `complete_when` function:

```lua
goal = {
    verb = "read",
    noun = "letter",
    label = "discover the secret",
    complete_when = function(ctx)
        return ctx.player.flags.read_secret_letter == true
    end
}
```

This is an escape hatch for goals that don't map cleanly to FSM state or inventory checks. Use sparingly — prefer state-based detection whenever possible.

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

The options system helps stuck players without destroying discovery. Seven rules govern what suggestions are exposed and when:

1. **One step ahead, never two.** Only show the immediate next GOAP step from the plan chain. Never reveal the full prerequisite sequence — the player should discover each step through play, not be handed the entire solution upfront.

2. **No hidden objects.** Don't suggest interacting with objects the player hasn't discovered yet. Check `obj.hidden` and whether the player has "seen" (in light) or "felt" (in darkness) the object. Undiscovered objects stay off the options list until the player finds them through exploration.

3. **Sensory before specific.** In darkness, suggest "feel around" before "take the key from under the rug." General sensory exploration comes first; object-specific actions emerge after discovery. This preserves the tactile exploration loop that defines the dark-room experience.

4. **Exits over solutions.** Suggest exploring exits before suggesting puzzle solutions. Movement options (doors, stairs, passages) take priority over manipulation verbs. The player should know they *can* leave before being nudged toward complex interactions. Exception: when the room goal is explicitly "escape this room" and exits are locked, puzzle hints take precedence.

5. **Escalating specificity.** Options responses escalate in directness based on `ctx.options_request_count` (number of times the player has requested options in the current room without making progress):

| Tier | Request Count | Behavior | Example |
|------|--------------|----------|---------|
| **Standard** | 1st–2nd | General sensory suggestions. No goal steps exposed. Encourage exploration. | "Feel around for objects in the darkness" |
| **Context Clues** | 3rd–4th | Include goal-directed hints with narrative framing. Indirect nudges toward the next step. | "Something about the padlock catches your attention..." |
| **Mercy Mode** | 5th+ | Direct, explicit guidance. No more cryptic hints — the player is genuinely stuck and deserves clear help. | "Try: unlock padlock with key" |

The escalation counter (`ctx.options_request_count`) resets when the player:
- Moves to a different room
- Successfully completes a goal step (detected via state change — e.g., object transitions from `locked` to `open`, or FSM state changes)
- Executes any command from the options list (even if it fails — they tried, so reset the counter and give them fresh context)

6. **Mercy mode is not a spoiler.** When a player has asked for options 5+ times in the same room without progress, they are stuck. Giving them the answer at that point respects their time and keeps the game moving. Mercy mode text should be helpful and direct, never condescending or sarcastic. Format: `"Try: <command>"` — clear, actionable, no ambiguity. The player shouldn't feel punished for asking; they should feel helped.

7. **Puzzle room overrides.** Rooms with `options_disabled`, `options_mode`, or `options_delay` flags (see section 4.8) override the default escalation behavior. A puzzle room set to `options_mode = "sensory_only"` never escalates past Standard tier, regardless of request count. A room with `options_disabled = true` returns a refusal message ("You need to figure this one out yourself.") at all tiers, blocking the system entirely. These flags let puzzle designers protect climactic moments while keeping the options system useful everywhere else.

### 4.8 Puzzle Room Exemptions

Some rooms — particularly climactic puzzle moments — should limit or disable the options system to preserve dramatic tension and protect "aha!" moments. Rooms can set exemption flags in their metadata alongside the `goal` field.

**Three Tiers of Exemption:**

| Flag | Value | Behavior | Use Case |
|------|-------|----------|----------|
| `options_disabled` | `true` | Options verb returns: "You need to figure this one out yourself." All tiers blocked, including Mercy Mode. No hints at any request count. | Climactic puzzle moments, boss encounters, dramatic reveals where struggle IS the intended experience |
| `options_mode` | `"sensory_only"` | Only sensory suggestions shown (feel, listen, smell, look). No goal steps, no dynamic object scan. Escalating specificity stays locked at Standard tier. | Exploration rooms, atmospheric set pieces, rooms where the journey IS the point — preserve mood without abandoning the player |
| `options_delay` | `N` (integer, turns) | Options verb unavailable for first N turns after entering room. Returns: "Give it a moment... look around first." After N turns, normal behavior (all tiers, full escalation). | Encourage initial exploration before hinting. Good for first entry into a new area — let the player get their bearings |

**Metadata example:**

```lua
-- A climactic puzzle room (final challenge before escape)
options_disabled = true,
goal = { verb = "solve", noun = "riddle", label = "unravel the mystery" },

-- An atmospheric exploration room (sensory immersion priority)
options_mode = "sensory_only",
goal = { verb = "go", noun = "east", label = "find the garden path" },

-- A room that rewards exploration first (delay before hints)
options_delay = 3,
goal = { verb = "light", noun = "torch", label = "illuminate the chamber" },
```

**Per-phase exemptions:** For multi-step puzzles, exemption flags can change dynamically as the puzzle progresses. The room's `on_state_change` hook can modify these flags in response to player actions. Example progression:

1. **Phase 1 (entry):** `options_delay = 5` — force exploration for 5 turns, no hints available
2. **Phase 2 (first clue found):** Switch to `options_mode = "sensory_only"` — guide with atmosphere, but don't reveal the solution
3. **Phase 3 (second clue found):** Remove all flags — full hints available, including Mercy Mode for the final step

This lets puzzle designers create escalating support: strict at first (preserve discovery), lenient at the end (prevent frustration).

**Design guideline (Sideshow Bob's recommendation):** Use `options_disabled` sparingly — reserve it for the 2-3 most dramatic puzzle moments per level. Players who are genuinely stuck with no hints at all will get frustrated and may quit. `options_mode = "sensory_only"` is the sweet spot for most puzzle rooms: it keeps the atmospheric nudges and exploration guidance flowing while protecting the puzzle's core "aha!" moment. Use `options_delay` liberally for new areas — 3-5 turn delays give players time to look around without feeling abandoned.

### 4.9 Clearing Pending Options

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

## Version History

- **v1.0** (2026-08-02): Initial draft proposing three approaches
- **v2.0** (2026-08-02): Blockers resolved post-review ceremony. Wayne approved Approach C (goal-driven hybrid), Option C context window (stable goals + rotating sensory), free hints, state-based goal detection. Added API contracts (B1), numeric precedence rules (B6/B7), performance budget <50ms (B9), empty room fallback (B11), state-based goal completion (B12).

---

*This architecture document is approved. Implementation proceeds per the phases defined in Section 8.*
