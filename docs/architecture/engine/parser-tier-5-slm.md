# Parser Tier 5: SLM/LLM Fallback (Designed, Not Yet Implemented)

**Status:** 🔷 Designed (not yet implemented)  
**Version:** 1.0  
**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-25  
**Purpose:** Optional Small Language Model (SLM) fallback for novel command patterns beyond rule-based tiers.

---

## Overview

This tier is a **Phase 2+ optional enhancement** for inputs that deterministic Tier 3 (GOAP) rules cannot parse. It uses an on-device **Small Language Model (SLM)** to understand novel phrasings and decompose complex goals.

**Key Principle:** Deterministic rule-based parsing should handle ~95% of inputs. This tier exists only as a fallback for the remaining 5% and for learning data collection.

---

## Current Architecture: Tier 1-4 Parser Stack

```
Tier 1: Exact verb dispatch (70% of inputs)
  ↓ (miss)
Tier 2: Embedding phrase similarity (20% of inputs)
  ↓ (miss)
Tier 3: GOAP backward-chaining (8% of inputs)
  ↓ (miss)
Tier 4: Context-aware inference (1% of inputs)
  ↓ (miss)
Tier 5: SLM fallback (1% of inputs, OPTIONAL)
```

---

## Tier 5 Decision: Rule-Based vs. SLM

### Option A: Deterministic Rule-Based Decomposition (RECOMMENDED)

Use the five layers (intent recognition, action chaining, prerequisites, context, prepositions) entirely through hand-written rules.

**Pros:**
- Predictable, debuggable behavior
- Fast (no inference, just rule matching)
- Transparent (designer controls all logic)
- Suitable for mobile (no model download)

**Cons:**
- Brittle: New verb patterns require code changes
- Limited to known patterns
- Doesn't handle novel phrasings gracefully

### Option B: SLM-Based Goal Decomposition (PHASE 2+)

For inputs that deterministic rules can't parse, fall back to a **small language model (SLM)** running on-device to decompose goals into action chains.

#### SLM Candidate: Qwen2.5-0.5B

- **Size:** ~350MB (ONNX quantized, still large)
- **Latency:** 200–500ms per inference (slower than Tier 1-4)
- **Accuracy:** High-quality semantic understanding
- **Training:** Fine-tune on (goal_text, game_state) → action_chain pairs

#### Example: SLM-Powered Decomposition

```
INPUT: "I want to escape this room"
TIER 1: No exact match
TIER 2: Embedding similarity < 0.5 (no direct phrase match)
TIER 3+4: Rule-based decomposition fails (too novel)

TIER 5 (SLM):
  Input to SLM:
    {
      "goal": "I want to escape this room",
      "game_state": {
        "current_room": "bedroom",
        "inventory": ["key"],
        "room_objects": ["door", "window", "rug"],
        "room_exits": ["north_door (locked)"]
      }
    }
  
  SLM Output:
    {
      "goals": [
        { "type": "unlock", "target": "north_door", "tool": "key" },
        { "type": "go", "direction": "north" }
      ],
      "action_chain": ["OPEN door WITH key", "GO north"]
    }
```

---

## Trade-Offs: Deterministic vs. SLM

| Aspect | Rule-Based (MVP) | SLM (Phase 2+) |
|--------|-----------|-----|
| **Speed** | <50ms | 200–500ms |
| **Size** | 0MB | 350MB (download cost) |
| **Debuggability** | Excellent | Poor (black box) |
| **Flexibility** | Limited | High (generalizes) |
| **Coverage** | ~95% of common patterns | ~99% (including novel) |
| **Cost** | One-time design effort | Training cost, inference cost |
| **Mobile** | Yes (trivial) | Maybe (large model, slow) |
| **Transparency** | Full control | Limited visibility into decisions |

---

## Recommendation: Hybrid Approach

### Phase 1 (MVP): Rule-Based Deterministic Decomposition

- Covers 95%+ of gameplay patterns
- Fast, transparent, mobile-friendly
- Authors can understand and modify rules
- Tier 1-4 (exact, phrase similarity, GOAP, context) sufficient

### Phase 2 (Optional Enhancement): Add SLM as Tier 5 Fallback

- Only invoke if Tier 1-4 all fail AND confidence < threshold
- Use for learning: collect Tier 5 failures, fine-tune SLM training data
- Ship SLM optional (feature flag or Progressive Web App secondary tier)

### Key Decision: Optional & Downloadable, Not Mandatory

If SLM is shipped, make it **optional and downloadable**, not mandatory on first load. Progressive enhancement model:

**MVP:** Tier 1 + Tier 2 + deterministic Tier 3 + Tier 4  
**Enhanced (Optional):** + SLM Tier 5 for advanced parsing

---

## SLM Integration Architecture

### When SLM Engages

1. **Precondition:** All Tier 1-4 attempts failed
2. **Check:** `parse_confidence < FALLBACK_THRESHOLD` (e.g., 0.3)
3. **Input:** Goal text + current game state
4. **Output:** Structured action chain or confidence score
5. **Fallback:** If SLM confidence also low, escalate to error handling

### Input Format for SLM

```json
{
  "goal": "I want to escape this room",
  "current_tick": 42,
  "game_state": {
    "player": {
      "location": "bedroom",
      "inventory": ["key", "torch"],
      "health": 100,
      "light_level": 80
    },
    "room": {
      "name": "bedroom",
      "objects": ["door", "window", "rug", "bed"],
      "exits": ["north_door (locked, brass key required)"],
      "npcs": [],
      "light_sources": []
    },
    "recent_commands": [
      { "verb": "examine", "object": "door", "tick": 40 },
      { "verb": "examine", "object": "key", "tick": 38 }
    ]
  }
}
```

### Output Format from SLM

```json
{
  "confidence": 0.87,
  "goals": [
    {
      "type": "action",
      "verb": "OPEN",
      "target": "door",
      "tool": "key",
      "reason": "Door is locked and requires brass key (in inventory)"
    },
    {
      "type": "navigation",
      "direction": "north",
      "reason": "Door leads north out of room"
    }
  ],
  "action_chain": [
    "OPEN door WITH key",
    "GO north"
  ],
  "explanation": "To escape the bedroom, unlock the north door with your key and go north."
}
```

---

## Training Data for SLM

### Data Collection Strategy

1. **Phase 1 (Rule-Based):** Collect all Tier 5 fallback cases
2. **Phase 2 (Analysis):** Categorize failure patterns
3. **Phase 3 (Training):** Fine-tune SLM on (goal, state) → action_chain pairs

### Example Training Tuples

```
INPUT:
  goal: "I want to escape this room"
  state: { room: "bedroom", inventory: ["key"], exits: [north_door] }

OUTPUT:
  action_chain: ["OPEN door WITH key", "GO north"]

---

INPUT:
  goal: "Put on the armor"
  state: { room: "armory", inventory: [], objects: [locked_chest] }

OUTPUT:
  action_chain: ["OPEN chest WITH lockpick", "TAKE armor", "WEAR armor"]

---

INPUT:
  goal: "Make fire in the darkness"
  state: { 
    room: "cave",
    light_level: 0,
    inventory: ["wood", "match"]
  }

OUTPUT:
  action_chain: ["TAKE match", "STRIKE match", "LIGHT wood"]
```

---

## Failure Modes & Handling

### When SLM Parsing Fails

Even with SLM, some inputs will be ambiguous, impossible, or nonsensical.

#### Challenge: When All Tiers Fail

```
INPUT: "Create a new universe"
TIER 1-5: All fail

RESPONSE (with learning opportunity):
  "I don't recognize that action. Available verbs include: look, examine, take, drop, 
   open, close, light, wear, etc. Try 'help' for more."
```

#### SLM Uncertainty Handling

If SLM confidence score < 0.5, treat as Tier 5 failure:

```
TIER 5 OUTPUT: { confidence: 0.42, goals: [...] }

DECISION:
  - Reject SLM result
  - Escalate to error handling
  - Suggest disambiguation or help
```

---

## Progressive Verbosity

Players can set error reporting level:

```
--verbose: Explains every step of parsing and planning
  "Parsing goal: light candle.
   Found verb LIGHT, target candle.
   Inferred tool: match (from recent context).
   Planning action chain: [TAKE matchbox, OPEN matchbox, TAKE match, STRIKE match, LIGHT candle]
   Executing..."

--normal (default): Reports high-level steps
  "Getting a match from the matchbox..."
  "Striking the match..."
  "Lighting the candle..."
  
--silent: Only final state + consequences
  "The candle is now lit."
```

---

## Deployment Strategy

### MVP: Rule-Based Only

- **Timeline:** Phase 1 (Weeks 1-4)
- **Deliverable:** Tier 1-4 fully implemented
- **Coverage:** ~95% of typical gameplay
- **Performance:** Sub-100ms median parse time

### Phase 2: SLM Optional Enhancement

- **Timeline:** Phase 2 (Weeks 5+, optional)
- **Deliverable:** SLM fine-tuning infrastructure + integration
- **Deployment:** Progressive Web App feature flag
- **Decision Point:** Based on MVP coverage and player feedback

### Decision Criteria for SLM

Ship SLM only if:
1. **Coverage Gap:** Tier 1-4 misses >5% of typical inputs
2. **User Feedback:** Players report frustration with rule-based limitations
3. **Mobile Performance:** On-device inference <500ms acceptable
4. **Training Data:** Sufficient failure cases collected for SLM training

---

## References

- **GOAP Parser (Tier 3):** `parser-tier-3-goap.md`
- **Qwen Models:** https://github.com/QwenLM/Qwen2.5
- **ONNX Runtime:** https://onnxruntime.ai/ (on-device inference)
- **Parser Implementation Plan:** `../../plan/llm-slm-parser-plan.md`
- **Parser Decision (D-19):** Architecture overview notes

---

## See Also

- **Parser Tier 1 (Basic):** `parser-tier-1-basic.md`
- **Parser Tier 2 (Compound):** `parser-tier-2-compound.md`
- **Parser Tier 3 (GOAP):** `parser-tier-3-goap.md`
- **Parser Tier 4 (Context):** `parser-tier-4-context.md`
- **Architecture Overview:** `00-architecture-overview.md`

---

**Note:** Tier 5 is a Phase 2+ consideration. MVP focuses on rule-based Tier 1-4 completeness.
