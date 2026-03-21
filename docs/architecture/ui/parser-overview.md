# Parser Pipeline Overview

**Version:** 1.0  
**Author:** Smithers (UI Engineer)  
**Last Updated:** 2026-03-22  
**Purpose:** Complete specification of the 5-tier parser pipeline architecture.

---

## Overview

The MMO parser transforms natural language player commands into engine-level verb dispatch. It uses a **5-tier cascading pipeline** designed for:
1. **Speed** — 90%+ of commands resolve in <5ms (zero LLM tokens)
2. **Coverage** — Handles exact matches, synonyms, phrasings, multi-step goals
3. **Graceful degradation** — Each tier falls back to the next if it can't parse
4. **Transparency** — Diagnostic mode shows what each tier tried

**The Five Tiers:**
- **Tier 1: Exact Verb Dispatch** — Hash table lookup (`<1ms`, 70% coverage)
- **Tier 2: Phrase Similarity** — Jaccard token overlap (`~5ms`, +20% coverage → 90% total)
- **Tier 3: GOAP Planning** — Backward-chaining goal decomposition (`~50-100ms`, +8% coverage → 98% total)
- **Tier 4: Context Window** — Recent discoveries inform tool inference (Designed, not built)
- **Tier 5: SLM Fallback** — On-device small language model (Phase 2+)

---

## Design Philosophy

### Zero-Token Path for Common Commands

**From Wayne's Directive (2026-03-19):**
> Most commands should resolve instantly without LLM calls. LLMs are expensive and slow. Reserve them for the 1-2% of truly novel inputs.

**Trade-off:**
- **More engineering upfront** (phrase dictionary, GOAP rules, pattern matching)
- **Faster, cheaper at scale** (no API costs, <5ms latency)
- **Deterministic behavior** (same input → same output, always)

### Cascading Tiers (Fast → Slow)

Each tier attempts to parse. On failure, fall through to the next:

```
INPUT: "light the candle with a match"

TIER 1: Exact verb match?
  - Check: "light" in verb table? YES ✓
  - Dispatch: verbs["light"](ctx, "the candle with a match")
  - DONE (1ms)

(Tier 2, 3, 4, 5 never invoked — fast path)
```

```
INPUT: "get a match from the matchbox and light the candle"

TIER 1: Exact verb match?
  - Check: "get" in verb table? YES ✓
  - BUT: This is a compound command (split on "and")
  - Sub-command 1: "get a match from the matchbox"
  - Sub-command 2: "light the candle"
  
TIER 3: GOAP detects sub-command 2 needs planning
  - Goal: light candle
  - Prerequisites: need match (from sub-command 1) + need fire source
  - Plan: [OPEN matchbox, TAKE match, STRIKE match, LIGHT candle]
  - Execute plan (100ms)
  - DONE

(Tier 1 handled first command, Tier 3 planned second)
```

---

## Tier 1: Exact Verb Dispatch

**Status:** ✅ Implemented  
**Coverage:** ~70% of typical player input  
**Latency:** <1ms (hash table lookup)  
**Location:** `src/engine/loop/init.lua` (verb table dispatch)

### How It Works

1. **Normalize input:** Convert to lowercase, trim whitespace
2. **Split verb + noun:** First word = verb, rest = noun
3. **Lookup verb:** Check `context.verbs[verb]` table
4. **Dispatch:** Call handler function with `(context, noun)`

```lua
-- Verb table (partial)
verbs = {
  look = cmd_look,
  l = cmd_look,          -- Alias
  examine = cmd_examine,
  x = cmd_examine,       -- Alias
  take = cmd_take,
  get = cmd_take,        -- Synonym
  grab = cmd_take,       -- Synonym
  -- ... 31 total verbs + aliases
}

-- Parsing
local verb, noun = parse(input)
if verbs[verb] then
  verbs[verb](context, noun)
  return true
end
-- Fall through to Tier 2...
```

### Aliases & Synonyms

**Canonical Verb:** The primary verb name (e.g., `look`)  
**Aliases:** Shortcuts (e.g., `l` → `look`, `x` → `examine`)  
**Synonyms:** Alternative phrasings (e.g., `get` → `take`, `see` → `look`)

**Total Verb Coverage:**
- 31 canonical verbs
- ~50 total entries (verbs + aliases)

### Strengths

- **Instant:** O(1) hash table lookup
- **Deterministic:** Same input → same verb, always
- **Debuggable:** Easy to see what matched
- **Zero cost:** No tokens, no API calls

### Weaknesses

- **Brittle:** Exact match only (typos fail)
- **No context:** "it" or "that" won't resolve to last object
- **No multi-step:** "Get match and light candle" requires compound command handling

---

## Tier 2: Phrase Similarity Fallback

**Status:** ✅ Implemented  
**Coverage:** +20% (90% cumulative with Tier 1)  
**Latency:** ~5ms (phrase dictionary scan)  
**Location:** `src/engine/parser/init.lua`, `src/engine/parser/embedding_matcher.lua`

### How It Works

If Tier 1 misses (no exact verb match), compare input to a **phrase dictionary** using **Jaccard token overlap**:

```
INPUT: "examine the nightstand drawer"

TOKENIZE: ["examine", "the", "nightstand", "drawer"]

PHRASE DICTIONARY:
  "examine object"  → EXAMINE
  "look at object"  → LOOK
  "inspect object"  → EXAMINE
  "check object"    → EXAMINE

MATCH SCORES:
  "examine object" → Jaccard(["examine","the","nightstand","drawer"], ["examine","object"]) 
                   = |{examine}| / |{examine,the,nightstand,drawer,object}|
                   = 1 / 5 = 0.20
  
  (Continue for all phrases...)
  
  Best match: "examine object" (score: 0.45)

THRESHOLD: 0.40 (configurable)

RESULT: Score 0.45 > 0.40 → Dispatch to EXAMINE handler
```

### Jaccard Token Overlap Formula

```
J(A, B) = |A ∩ B| / |A ∪ B|

Where:
  A = tokenized input
  B = tokenized phrase from dictionary
  ∩ = intersection (common tokens)
  ∪ = union (all unique tokens)
```

**Example:**
```
A = ["light", "the", "candle"]
B = ["light", "candle"]

Intersection: {"light", "candle"} → count = 2
Union: {"light", "the", "candle"} → count = 3

Jaccard = 2 / 3 = 0.67 (strong match)
```

### Threshold Tuning

**Threshold:** Minimum score to accept match (default: `0.40`)

- **Too low (0.20):** False positives ("eat" matches "take")
- **Too high (0.70):** False negatives (only exact phrasings work)
- **Sweet spot (0.40):** Handles natural variations without over-matching

**Per D-6 (Parser Tier 2 Wiring):**
> Threshold is tunable. Start at 0.40, adjust based on playtest data.

### Phrase Dictionary

**Location:** `src/assets/parser/embedding-index.json`

The phrase dictionary maps natural language patterns to canonical verbs:

```json
{
  "phrases": [
    { "text": "look around", "verb": "look", "noun": "" },
    { "text": "examine object", "verb": "examine", "noun": "object" },
    { "text": "light candle with match", "verb": "light", "noun": "candle" },
    { "text": "get item from container", "verb": "take", "noun": "item" },
    ...
  ]
}
```

**Why JSON, not embeddings?**
The current implementation uses **token-based Jaccard** (no vector embeddings). The file is named `embedding-index.json` for future-proofing, but it's just a phrase list.

**Future:** May add true vector embeddings (sentence transformers) for semantic similarity, but this adds complexity (model weights, inference time).

### Strengths

- **Flexible:** Handles phrasings Tier 1 misses
- **Fast:** ~5ms for 50-phrase dictionary
- **Tunable:** Threshold adjusts sensitivity
- **Transparent:** Can see which phrase matched + score

### Weaknesses

- **Dictionary maintenance:** Need to add new phrasings manually
- **No context:** Still can't resolve "it" or "that"
- **No multi-step:** Can't chain prerequisites

---

## Tier 3: GOAP Planning (Goal-Oriented Action Planning)

**Status:** ✅ Implemented (per 2026-03-20 newspaper)  
**Coverage:** +8% (98% cumulative)  
**Latency:** ~50-100ms (backward-chaining search)  
**Location:** `src/engine/parser/goal_planner.lua`

### What Is GOAP?

**Goal-Oriented Action Planning** — A technique from game AI (F.E.A.R., 2005) for decomposing high-level goals into executable action sequences.

**Key Insight:** Players express *intent* ("light candle"), not steps. The engine should infer prerequisites and execute them automatically.

### How It Works

#### 1. Intent Recognition

Map verb + noun to a **goal state**:

```lua
-- Player types: "light candle"
goal = {
  verb = "light",
  target = "candle",
  goal_state = "candle.casts_light == true"
}
```

#### 2. Prerequisite Discovery

Check what must be true for the goal to succeed:

```lua
-- LIGHT verb requires:
prerequisites = {
  tool_capability = "fire_source",  -- Need something that provides fire
  target_in_scope = true,           -- Candle must be visible/accessible
  tool_in_inventory = true          -- Must hold the fire source
}
```

#### 3. Backward-Chaining Search

If prerequisites aren't met, recursively plan how to achieve them:

```lua
-- Prerequisite check: fire_source in inventory?
if not has_capability(player.inventory, "fire_source") then
  -- Sub-goal: Get a fire source
  fire_source = find_object_with_capability("fire_source", game_state)
  
  -- Match is a fire_source (when lit)
  -- Match is in matchbox
  -- Matchbox is closed
  
  -- Sub-plan: OPEN matchbox → TAKE match → STRIKE match
  sub_plan = [
    { verb = "open", target = "matchbox" },
    { verb = "take", target = "match" },
    { verb = "strike", target = "match" }
  ]
end

-- Final plan:
plan = sub_plan + [{ verb = "light", target = "candle" }]
```

#### 4. Plan Execution

Execute each action in sequence, printing feedback for each:

```lua
for _, action in ipairs(plan) do
  execute_action(action, context)
  print(action.message)
end
```

### Example: "Light Candle" in Darkness

**Input:** `light candle`  
**Game State:**
- Player in dark bedroom
- No matches in inventory
- Matchbox on nightstand (closed)
- Matchbox contains 7 matches

**GOAP Plan:**
1. **Open drawer** (to access nightstand contents)
2. **Take matchbox** (from nightstand)
3. **Open matchbox** (to access matches)
4. **Take match** (from matchbox)
5. **Strike match** (on matchbox striker surface)
6. **Light candle** (with lit match)

**Output:**
```
You'll need to prepare first...
You pull the small drawer open. It slides out with a soft wooden scrape.
You take the matchbox from the drawer.
You slide the matchbox tray open with your thumb.
You take a wooden match from an open matchbox.
You drag the match head across the striker strip. It sputters once, 
twice -- then catches...
The wick catches the flame and curls to life, throwing a warm amber glow 
across the room.
```

**Six actions auto-chained from one command.**

### Auto-Resolvable Prerequisites

Not all prerequisites trigger sub-plans. Some are auto-resolved:

| Prerequisite | Auto-Resolvable? | Rationale |
|--------------|-----------------|-----------|
| **Container closed (not locked)** | ✅ YES | Zero cost, obvious intent |
| **Tool in inventory (not held)** | ✅ YES | No hands needed, just access |
| **Key in inventory for locked door** | ✅ YES (with context) | High confidence player wants to use it |
| **Tool in nearby visible container** | ⚠️ MAYBE | Confidence threshold determines prompt vs auto |
| **Tool in distant room** | ❌ NO | Requires navigation, too speculative |
| **Locked container without key** | ❌ NO | Missing critical resource |

### Strengths

- **Powerful:** Handles complex multi-step goals
- **Intuitive:** Player types intent, engine figures out steps
- **Emergent:** New puzzles work automatically (no special-case code)
- **Fast:** 50-100ms for 5-step plans

### Weaknesses

- **Complexity:** Hard to debug when plans go wrong
- **Ambiguity:** Multiple paths to goal (which to choose?)
- **Context-blind:** Doesn't yet use recent discoveries (Tier 4 will fix)

---

## Tier 4: Context Window (Designed, Not Built)

**Status:** 🔷 Designed (not yet implemented)  
**Coverage:** +1% (99% cumulative)  
**Latency:** TBD (likely ~50ms)  
**Location:** N/A (future)

### What It Adds

Tier 4 augments Tier 3 (GOAP) with **short-term memory** of recent player actions:

- **Recent discoveries:** "Examined matchbox 5 ticks ago → knows it contains matches"
- **Tool inference:** "Light candle" infers match from recent context (no need to specify)
- **Pronoun resolution:** "Take it" resolves "it" to last examined object
- **Confidence decay:** Older discoveries fade (50 ticks ago = low confidence)

### Example: Contextual Tool Inference

```
> examine matchbox
A wooden box with a sliding tray. Inside, you see seven wooden matches.

(Context recorded: matchbox contains matches, examined at tick 5)

> light candle

(Tier 4 checks context: player recently saw matches in matchbox)
(Inference: match is required tool → auto-chain: TAKE match → LIGHT)

You take a match from the matchbox and strike it. The candle flares to 
life.
```

**Without Tier 4:**
```
> light candle
You need a fire source to light the candle.
```

**With Tier 4:**
```
> light candle
(Infers match from recent discovery, auto-chains)
```

### Context Structure

```lua
context_window = {
  recent_commands = [
    { verb = "examine", object = "matchbox", tick = 5 },
    { verb = "examine", object = "candle", tick = 4 }
  ],
  
  discovered_objects = {
    matchbox = {
      examined_at_tick = 5,
      contents = ["match", "match", "match", ...],
      properties = { is_container = true, is_open = false }
    }
  },
  
  last_examined_object = "matchbox",
  last_tool_used = "match"
}
```

### Confidence Scoring

```lua
function calculate_confidence(object, context)
  ticks_ago = current_tick - object.last_seen_tick
  
  if ticks_ago <= 5 then return 0.95 end      -- Very recent
  if ticks_ago <= 20 then return 0.80 end     -- Recent
  if ticks_ago <= 50 then return 0.60 end     -- Somewhat recent
  return max(0.30, 1.0 - (ticks_ago - 50) / 100.0)  -- Old
end
```

**Usage:** If confidence > 0.70, auto-resolve. If 0.40-0.70, prompt player. If < 0.40, fail.

### See Also

Full specification: [../engine/parser-tier-4-context.md](../engine/parser-tier-4-context.md)

---

## Tier 5: SLM Fallback (Phase 2+)

**Status:** 🔷 Designed (Phase 2+, optional)  
**Coverage:** +1% (100% cumulative)  
**Latency:** ~200-500ms (on-device inference)  
**Location:** N/A (future)

### What It Is

**Small Language Model (SLM)** — An on-device language model (e.g., Qwen2.5-0.5B, ~350MB) for parsing novel phrasings that rule-based tiers can't handle.

### When to Use

Only for inputs that Tier 1-4 cannot parse:
- Novel phrasings ("I want to escape this room")
- Complex multi-verb intent ("Make sure the room is secure")
- Ambiguous goals ("Prepare for the night")

**Key Principle:** Tier 5 should handle <1% of inputs. Most commands resolve in Tier 1-3.

### Example

```
INPUT: "I need to make this room brighter"

TIER 1: "make" not in verb table → MISS
TIER 2: No phrase match (score < 0.40) → MISS
TIER 3: No goal pattern recognized → MISS
TIER 4: No recent context helps → MISS

TIER 5 (SLM):
  Input to model:
    { goal: "I need to make this room brighter", game_state: {...} }
  
  Model output:
    { action: "light", target: "candle", inferred_intent: "increase light" }
  
  Execute: LIGHT candle (via Tier 3 GOAP)
```

### Trade-Offs

| Aspect | Rule-Based (Tier 1-4) | SLM (Tier 5) |
|--------|----------------------|--------------|
| Speed | <100ms | 200-500ms |
| Size | 0MB | 350MB |
| Coverage | ~99% | +1% → 100% |
| Determinism | Always same output | Probabilistic |
| Cost | Zero | On-device (no API cost) |

**Decision:** Phase 1 ships without Tier 5. Phase 2+ adds it if playtest data shows significant unhandled patterns.

### See Also

Full specification: [../engine/parser-tier-5-slm.md](../engine/parser-tier-5-slm.md)

---

## Natural Language Preprocessing

**Location:** `src/engine/loop/init.lua` (function `preprocess_natural_language`)

Before the parser tiers run, common phrasings are **hard-coded expanded**:

```lua
-- Question patterns → verbs
"what is around?"        → "look" ""
"what's in the box?"     → "look" "in box"
"what time is it?"       → "time" ""
"what am I carrying?"    → "inventory" ""

-- Composite part phrases → verbs
"take out match"         → "pull" "match"
"pull out drawer"        → "pull" "drawer"

-- Spatial movement → verbs
"roll up rug"            → "move" "rug"
"pull back curtain"      → "move" "curtain"

-- Tool usage → verbs
"use needle on cloth"    → "sew" "cloth with needle"
"use key on door"        → "unlock" "door with key"

-- Compound phrases → verbs
"put out candle"         → "extinguish" "candle"
"put on gloves"          → "wear" "gloves"
"take off gloves"        → "remove" "gloves"
"blow out match"         → "extinguish" "match"

-- Sleep phrases → verbs
"go to bed"              → "sleep" ""
"lie down"               → "sleep" ""
"take a nap"             → "sleep" ""
```

**Why Preprocessing?**
- **Faster than Tier 2:** Deterministic pattern matching (no dictionary scan)
- **Covers 90%+ of natural questions:** Players type "what's inside?" more than "examine contents"
- **Reduces Tier 2 dictionary size:** Fewer phrases to maintain

**Trade-off:**
- More code to maintain (hard-coded patterns)
- BUT: Covers common phrasings with zero token cost

---

## Compound Commands

**Location:** `src/engine/loop/init.lua` (REPL loop splits on " and ")

The parser handles **compound commands** (multiple verbs in one input):

```
INPUT: "get a match from the matchbox and light the candle"

SPLIT ON " and ":
  sub_command_1 = "get a match from the matchbox"
  sub_command_2 = "light the candle"

PARSE sub_command_1:
  verb = "get" (Tier 1)
  noun = "a match from the matchbox"
  Execute: GET match FROM matchbox

PARSE sub_command_2:
  verb = "light" (Tier 1)
  noun = "the candle"
  Tier 3 GOAP checks: Does player have fire source?
    (Yes, from sub_command_1)
  Execute: LIGHT candle
```

**GOAP Integration:**
If the **last sub-command** has a GOAP plan, it may subsume earlier sub-commands:

```
INPUT: "get match and light candle"

TIER 3 GOAP for "light candle":
  Goal: candle lit
  Prerequisites: need fire source (match)
  Plan: [OPEN matchbox, TAKE match, STRIKE match, LIGHT candle]

GOAP PLAN SUBSUMES "get match":
  The plan already includes TAKE match, so "get match" is redundant.
  Execute only the GOAP plan.
```

**Why subsume?**
Avoids duplicate actions ("get match" + GOAP's "take match" → same thing).

---

## Diagnostic Mode

**Flag:** `--debug` (command-line argument)

When debug mode is active, the parser shows what it tried:

```
> flibber the candle
[Parser] Tier 1 miss: "flibber" not in verb table
[Parser] Tier 2 match: "light candle" via "flibber candle" (score: 0.35)
[Parser] Below threshold (0.40). No match found.
I don't understand that. Try 'help' for a list of commands.
```

**Why Diagnostic Mode?**
From D-4 (Cross-Agent Directive: No Fallback Past Tier 2):
> Failed commands show diagnostic output so Wayne can see what the parser tried. This enables empirical QA: watch what players type, update phrase dictionary, improve coverage.

**Production Mode:**
```
> flibber the candle
I don't understand that. Try 'help' for a list of commands.
```

---

## Parser Performance Budget

**Target Latency:**
- Tier 1: <1ms (instant)
- Tier 2: <5ms (phrase scan)
- Tier 3: <100ms (GOAP planning)
- Tier 4: <50ms (context check)
- Tier 5: <500ms (SLM inference, optional)

**Coverage Goals:**
- Tier 1+2: 90% of inputs
- Tier 1+2+3: 98% of inputs
- Tier 1-4: 99% of inputs
- Tier 1-5: 100% of inputs (Phase 2+)

**Why These Numbers?**
- **Player perception:** <100ms feels instant
- **Token cost:** Avoiding LLM saves $0.01-0.10 per command
- **Scale:** At 1M commands/day, zero-token path saves $10K-100K/day

---

## Related Systems

- **Verb Handlers:** [../../design/verb-system.md](../../design/verb-system.md)
- **Text Presentation:** [text-presentation.md](text-presentation.md)
- **Tier 1 Details:** [../engine/parser-tier-1-basic.md](../engine/parser-tier-1-basic.md)
- **Tier 2 Details:** [../engine/parser-tier-2-compound.md](../engine/parser-tier-2-compound.md)
- **Tier 3 Details:** [../engine/parser-tier-3-goap.md](../engine/parser-tier-3-goap.md)
- **Tier 4 Details:** [../engine/parser-tier-4-context.md](../engine/parser-tier-4-context.md)
- **Tier 5 Details:** [../engine/parser-tier-5-slm.md](../engine/parser-tier-5-slm.md)
- **Command Variations:** [../../design/command-variation-matrix.md](../../design/command-variation-matrix.md)

---

## Examples from Newspapers

**From 2026-03-20 Evening Edition:**

Tier 3 GOAP shipped. Nelson (QA tester) tested in absolute darkness:

```
> light candle

You'll need to prepare first...
You pull the small drawer open. It slides out with a soft wooden scrape.
You slide the matchbox tray open with your thumb. Inside, a clutch of 
wooden matches rests snugly in a row.
You take a wooden match from an open matchbox.
You drag the match head across the striker strip. It sputters once, 
twice -- then catches...
The wick catches the flame and curls to life, throwing a warm amber glow 
across the room.
```

**Five auto-chained actions from one command:**
1. OPEN drawer (to access nightstand contents)
2. OPEN matchbox (to access matches)
3. TAKE match (from matchbox)
4. STRIKE match (on matchbox striker)
5. LIGHT candle (with lit match)

**Tier 3 worked in <100ms.** The parser "thought" through prerequisites and executed them automatically.

---

**END OF PARSER OVERVIEW**  
*Complete UI architecture documentation.*
