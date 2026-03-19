# Decision: Command Variation Matrix for Embedding Parser

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-22  
**Status:** Ready for Review  
**Related:** `docs/design/command-variation-matrix.md`

---

## The Decision

Define a canonical command variation matrix — all natural language variations players might type for the 31 verbs in the game — to serve as training data for the embedding-based parser (Tier 2).

---

## Context

The MMO engine has 31 verbs (23 canonical + 8 aliases). Players will not always use the canonical form:
- "grab" instead of "take"
- "pick up" instead of "pick"
- "examine" instead of "x"
- "go north" vs. "north" vs. "n"

An embedding-based parser needs examples of natural language variations to train accurately. This matrix provides ~400+ variations across all verbs, ensuring the embedding model understands player intent even when they don't use the exact canonical form.

---

## Key Design Decisions Embedded

### 1. Pronoun Resolution: Last-Examined Object
When a player types "it", "this", or "that", the parser resolves to the **last-examined object** (tracked via `ctx.last_object`).

**Rationale:**
- Simplest implementation (no discourse tracking or anaphora resolution)
- Fits the terse adventure game interface
- Avoids ambiguity in most cases

**Example:**
```
> examine candle
A tallow candle, half-burned.

> take it
You take the candle.
```

### 2. Darkness Verbs Are First-Class
FEEL, SMELL, TASTE, and LISTEN all have **darkness-aware variations** where feedback is sensory, not visual.

**Rationale:**
- Game is playable in pitch darkness
- These senses provide alternative information channels
- Sensory hierarchy: FEEL (primary), SMELL (safe ID), LISTEN (mechanics), TASTE (danger)

**Example (darkness variation):**
```
DARK: "You feel smooth wood and find a drawer handle."
LIGHT: "A wooden nightstand with an open drawer."
```

### 3. Tool Verbs Are Explicit About Requirements
WRITE, CUT, SEW, STRIKE, PRICK all have **tool-present** and **tool-absent** variations.

**Rationale:**
- Clear feedback guides player exploration (search for missing tool)
- Teaches the capability/requirement system
- Enables puzzles based on tool availability

**Example:**
```
With tool: "You write 'Hello' on the paper."
Without tool: "You need a writing instrument."
```

### 4. Bare Commands Prompt for Clarification
Verbs that require objects (TAKE, OPEN, LIGHT) should prompt when called bare.

**Rationale:**
- Teaches players the verb interface gradually
- Prevents silent failures
- Natural MUD/IF convention

**Example:**
```
> take
Take what?
```

### 5. Compound Actions Are Explicit
STRIKE, SEW, PRICK SELF have two-object or special-case variations.

**Rationale:**
- Compounds teach real-world logic (fire needs fuel + friction)
- Mutations are predictable (match → match-lit)
- Failure states are educational (bent pin, tangled thread)

**Example:**
```
> strike match on matchbox
The match ignites. You now hold a lit match.
```

### 6. Edge Cases Are Documented
The matrix includes edge cases like pronouns, ambiguous targets, non-standard phrasings.

**Rationale:**
- Parser needs to handle these gracefully
- Teaches QA team what to test
- Future embedding model will see these variations in training data

---

## Variations Documented

| Category | Verb Count | Variation Range | Example |
|----------|-----------|-----------------|---------|
| Navigation | 8 (LOOK, EXAMINE, READ, SEARCH, FEEL, SMELL, TASTE, LISTEN) | 12-18 per verb | FEEL: "feel around", "touch", "grope", "run fingers" |
| Inventory | 7 (TAKE, GET, PICK, GRAB, DROP, INVENTORY, PUT, OPEN, CLOSE) | 10-20 per verb | TAKE: "grab", "pick up", "snatch", "collect" |
| Interaction | 8 (LIGHT, STRIKE, EXTINGUISH, BREAK, TEAR, WRITE, CUT, SEW, PRICK) | 10-18 per verb | STRIKE: "strike match on matchbox", "rub against", "friction" |
| Movement | (GO + directions) | 8+ per direction | "go north", "north", "n", "head north", "walk north" |
| Meta | 2 (HELP, QUIT) | 5-8 per verb | QUIT: "quit", "exit", "goodbye", "bye" |

**Total: ~400+ variations**

---

## Training Pipeline Integration

### What Bart's Script Does
1. Reads all variations from this matrix
2. For each variation, generates an embedding vector
3. Groups vectors by canonical verb (training label)
4. Trains the embedding model to cluster variations by verb
5. Produces a lookup table: embedding → verb

### What QA Phase Does
1. Takes a subset of variations from this matrix
2. Passes them through the embedding matcher
3. Validates that the matcher returns the correct canonical verb
4. Catches any misclassifications or edge cases

---

## Darkness Design Note

A key insight: **darkness is not a wall, it's a different mode of play.** The variation matrix proves this:
- LOOK in darkness: "You can't see anything."
- FEEL in darkness: "You find a drawer handle." (FEEL is the primary sense)
- EXAMINE in darkness: "Too dark to see. You could feel it."

The sensory hierarchy enables dark-room gameplay:
1. **FEEL (primary):** Shape, texture, temperature, weight, contents
2. **SMELL (safe):** Chemical identity, materials, danger warnings
3. **LISTEN (mechanics):** Sounds, internal state of objects
4. **TASTE (learn-by-dying):** Flavor, poison detection via consequence

This is game design baked into the verb variations.

---

## Design Decisions for Future Consideration

### Not Yet Designed
- CLIMB (may be subsumed by GO + exit types)
- PUSH/PULL (for heavy objects)
- TALK (NPC interaction)
- CAST (magic)
- GIVE (trading)
- KILL (combat, if any)

### Parser Scope (Not Verb Scope)
- Preposition handling: "in", "on", "from", "with"
- Compound command queueing: "take and examine key"
- Disambiguation prompts: "Which match?"

These are parser-level concerns, not verb design. The verb variations assume the parser handles them.

---

## Acceptance Criteria

- [x] All 31 verbs documented with canonical forms and aliases
- [x] 10-20+ variations per verb
- [x] Darkness-aware variations documented
- [x] Tool-dependent variations documented
- [x] Edge cases and ambiguities covered
- [x] Context-sensitive variations (containers, tools, darkness) noted
- [x] Testing checklist for QA phase provided
- [x] ~400+ variations total
- [x] Design principles documented and justified

---

## Impact

**Parser Team (Bart):**
- Training data for embedding model now defined
- Clear specifications for what variations to expect
- Confidence that all major edge cases are covered

**QA Team:**
- Clear test plan: validate all variations map to correct verbs
- Context variations give testing depth (darkness, tools, containers)
- Pronoun resolution scope is defined

**Design Team:**
- Command variation matrix is canonical reference
- Future verbs should follow same pattern
- Sensory hierarchy is now documented

**Player Experience:**
- Game understands ~400 variations of natural player input
- Darkness gameplay is proven viable (sensory hierarchy)
- Tool verbs teach real-world logic through mechanics

---

## Questions for Review

1. **Pronoun scope:** Is "it" resolving to last-examined sufficient, or do we need broader discourse tracking?
2. **Bare command prompts:** Should meta verbs (HELP, QUIT) also prompt when bare? (Probably yes, but confirm.)
3. **Compound command queueing:** Should "take and examine key" queue two commands or parse first verb only? (Recommend: first verb only, for MVP. Queuing is future.)
4. **Edge case: "take all":** Should "take all" work, or should parser prompt "Take all what?" (Recommend: fail with prompt for MVP.)

---

## Approval

**Ready for:** Wayne "Effe" Berry (Project Owner), Bart (Parser/Architecture), QA Lead  
**Merged into:** `.squad/decisions.md` after review

