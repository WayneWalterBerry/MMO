# Prime Directive: Parser Tiers 1–5 Design Specification

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-25  
**Status:** 🔷 Design Complete  
**Issue:** #106  
**Audience:** Smithers (implementation), Nelson (testing), Wayne (approval)

> "The best parser is the one the player forgets exists." — Worst. Interface. Ever. (when they notice it.)

---

## Table of Contents

1. [What Is the Prime Directive?](#what-is-the-prime-directive)
2. [Architecture Overview: The Five Tiers](#architecture-overview-the-five-tiers)
3. [Tier 0: Input Normalization (DONE)](#tier-0-input-normalization-done)
4. [Tier 1: Question Transforms](#tier-1-question-transforms)
5. [Tier 2: Error Message Overhaul](#tier-2-error-message-overhaul)
6. [Tier 3: Idiom Library](#tier-3-idiom-library)
7. [Tier 4: Context Window Expansion](#tier-4-context-window-expansion)
8. [Tier 5: Fuzzy Noun Resolution](#tier-5-fuzzy-noun-resolution)
9. [Priority Order](#priority-order)
10. [Classic IF References](#classic-if-references)
11. [Implementation Notes for Smithers](#implementation-notes-for-smithers)
12. [Appendix: The Infocom Standard](#appendix-the-infocom-standard)

---

## What Is the Prime Directive?

The Prime Directive is this: **the player should never have to think about syntax.** They should be thinking about the world, the puzzles, the objects in their hands — not about how to phrase a command so the computer understands them.

Every time a player types something reasonable and gets "I don't understand that," we have failed. Every time a player has to rephrase the same intent three different ways, we have failed. The parser is not a gatekeeper. The parser is a translator. Its job is to understand human intent and route it to the correct game action, period.

Interactive fiction died commercially in the late 1980s for exactly one reason: parsers were too stupid. Infocom's games had brilliant writing, ingenious puzzles, and some of the best game design ever committed to code — and they still lost to point-and-click adventures because typing "PUT THE SMALL BRASS KEY IN THE LOCK ON THE OAK DOOR" and getting "I don't know the word 'lock'" made players want to throw their keyboards across the room.

We have sixty years of hindsight. We have Lua pattern matching. We have embedding indices. We do not have the excuse of 64KB memory constraints. Our parser should be *embarrassingly good.*

The five tiers below are a cascading system. Each tier catches what the previous tier missed, like a series of increasingly fine-mesh nets. Tier 0 handles the easy stuff (normalization). Tier 5 handles the weird stuff (typos, material references, partial names). Between them, we should resolve 99%+ of reasonable player input without the player ever noticing the machinery.

---

## Architecture Overview: The Five Tiers

```
Player Input: "where am I?"
     │
     ▼
┌─────────────────────────────────────────┐
│  TIER 0: Input Normalization            │  ← DONE (preprocess.lua)
│  Lowercase, trim, strip politeness,     │     224+ tests passing
│  strip preambles, strip adverbs,        │
│  strip gerunds, strip filler            │
│  "where am i"                           │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  TIER 1: Question Transforms            │  ← PARTIALLY DONE
│  "where am i" → "look"                  │     Expand coverage
│  "what do i have" → "inventory"         │
│  Conversational → imperative            │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  TIER 2: Error Message Overhaul         │  ← NEW
│  When action fails, respond in-world    │     Design required
│  with progressive hints                 │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  TIER 3: Idiom Library                  │  ← PARTIALLY DONE
│  "pick it up" → "get"                   │     Expand + systematize
│  "have a seat" → "sit"                  │
│  "toss it" → "throw"                    │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  TIER 4: Context Window Expansion       │  ← PARTIALLY DONE
│  "do it again" → repeat last command    │     (context.lua exists)
│  "go back" → return to prev room        │
│  "the other one" → disambiguation       │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  TIER 5: Fuzzy Noun Resolution          │  ← PARTIALLY DONE
│  "candel" → candle (typo)               │     (fuzzy.lua exists)
│  "the glass thing" → mirror             │
│  "the brass" → brass key                │
└─────────────────────────────────────────┘
```

**Key principle:** Tiers 0–1 and 3 run in `preprocess.lua` BEFORE verb dispatch. Tier 2 runs AFTER verb dispatch (on failure). Tiers 4–5 run during noun resolution (when the verb handler tries to find the target object). This ordering matters — we normalize input first, dispatch the verb, then resolve ambiguous nouns, and only if everything fails do we produce a good error message.

---

## Tier 0: Input Normalization (DONE)

**Status:** ✅ Complete — 224+ tests, 7 pipeline stages  
**Implementation:** `src/engine/parser/preprocess.lua`

Tier 0 is our foundation. It takes raw player input and normalizes it into a form the rest of the pipeline can work with. This is done. It handles:

- **Normalization:** Lowercase, trim whitespace, strip trailing `?`
- **Politeness stripping:** "please look" → "look", "could you open the door" → "open the door"
- **Preamble stripping:** "I want to look" → "look", "I'd like to open" → "open"
- **Adverb stripping:** "carefully examine" → "examine", "quickly take" → "take"
- **Gerund conversion:** "examining the candle" → "examine the candle"
- **Possessive stripping:** "hit your head" → "hit head"
- **Noun modifier stripping:** "search the whole room" → "search the room"

Tier 0 is the unsung hero. It turns freeform human language into something approaching canonical command syntax, and it does it invisibly. The player types however they want; Tier 0 quietly normalizes behind the scenes.

**What Tier 0 does NOT do:** It doesn't understand questions (Tier 1), doesn't know about idioms (Tier 3), doesn't remember context (Tier 4), and doesn't handle typos (Tier 5). It's purely syntactic, not semantic.

---

## Tier 1: Question Transforms

**Status:** 🟡 Partially implemented (in `preprocess.lua:transform_questions`)  
**Purpose:** Make the game feel conversational, not command-line  
**Player experience goal:** Players should be able to ask questions and get meaningful answers

### The Problem

Text adventures traditionally use imperative commands: LOOK, TAKE, OPEN. But real humans don't talk that way. They ask questions: "Where am I?" "What's that?" "How do I get out?" Every time a player phrases something as a question and the parser chokes, we remind them they're talking to a machine.

### What's Already Built

`transform_questions` in preprocess.lua already handles a solid set of patterns:

| Pattern | Maps To | Notes |
|---------|---------|-------|
| "where am I" | look | Orientation |
| "what do I see" / "what's around" | look | Scene query |
| "what do I have" / "what am I carrying" | inventory | Possession query |
| "what am I holding" | inventory | Hand query |
| "what time is it" | time | Game time |
| "what can I do" / "how do I..." | help | Meta-help |
| "where is the X" / "where's X" | find X | Object location |
| "is there a X in the room" | search X | Existence check |
| "what's in the X" | examine X | Container query |
| "am I hurt" / "how am I" | health | Status check |
| "where am I bleeding" | injuries | Injury detail |
| "what is this" / "what's this" | look | Deictic reference |

### What Needs to Be Added

#### 1. Causal / Why Questions

Players will ask WHY things happen. This is especially important after failed actions.

| Pattern | Maps To | Rationale |
|---------|---------|-----------|
| "why can't I see" | help (with light hint) | Darkness tutorial |
| "why can't I take X" | examine X (surface reason) | Constraint explanation |
| "why is it dark" | help (with light hint) | Common frustration point |
| "why won't X work" | examine X | State investigation |

**Implementation note:** "Why" questions should NOT just map to generic help. They should trigger context-aware responses. "Why can't I see?" when it's dark should produce "It's pitch black. You might need a light source." NOT "Try 'help' for commands." This is a Tier 2 (error messages) integration point.

#### 2. Capability Questions

| Pattern | Maps To | Rationale |
|---------|---------|-----------|
| "can I break X" | examine X | Object capability query |
| "can I eat X" | examine X | Safety check |
| "can I climb X" | examine X | Navigation query |
| "can I X" (generic) | verb X | Strip question wrapper (already exists) |

#### 3. Comparative / Which Questions

| Pattern | Maps To | Rationale |
|---------|---------|-----------|
| "which way is out" | exits / look | Navigation |
| "which door is locked" | examine doors | Multi-object comparison |
| "which key fits" | examine key | Tool matching |

#### 4. Counting Questions

| Pattern | Maps To | Rationale |
|---------|---------|-----------|
| "how many matches do I have" | inventory | Count query |
| "how many exits are there" | look | Room query |
| "how much does X weigh" | examine X | Property query |

### Edge Cases

#### Rhetorical Questions
- "What kind of game is this?" → Should NOT map to examine. Detect by absence of game-object reference. Fall through to Tier 2 with a witty narrator response.
- "Are you kidding me?" → Narrator responds with humor. See Tier 2 error messages.

#### Meta-Game Questions
- "How do I save?" → help (save)
- "How do I quit?" → help (quit)
- "What are the commands?" → help

#### Questions About Absent NPCs
- "Who's there?" → Currently no NPC system. Return atmospheric text: "Only silence answers." This is flavor, not error.
- "Is anyone here?" → Same treatment. When NPCs are implemented, these become meaningful queries.

### Design Philosophy

The game should feel like you're talking to a narrator who understands you, not typing commands into a terminal. Questions are the #1 indicator of a new player trying to learn the system. If we handle questions well, we teach players how to play *without* a tutorial.

**Infocom got this right** in *The Hitchhiker's Guide to the Galaxy*: you could type "what is the babel fish" and get a real answer. The parser understood you weren't trying to DO anything — you were trying to LEARN.

---

## Tier 2: Error Message Overhaul

**Status:** 🔴 Not implemented — this is a greenfield design  
**Purpose:** When the player tries something the game can't do, respond helpfully and in-character  
**Player experience goal:** Error messages should teach, not frustrate

### The Problem

Our current error responses are generic:

```
> frobulate the candle
"I'm not sure what you mean. Try 'help' to see what you can do."
```

This is the single worst thing a text adventure can do. It tells the player *nothing.* Is "frobulate" not a verb? Is "candle" not recognized? Is the action impossible? Is there a prerequisite missing? The player has zero information to work with.

Compare to Zork I:

```
> eat the sword
"I don't think that the platinum sword would agree with you."
```

That's an error message that (a) acknowledges the player's intent, (b) explains why it failed *in-world*, and (c) is actually entertaining to read. The player laughs instead of getting frustrated. THAT is what we need.

### Error Categories

Every failed action falls into exactly one of these categories. Each category needs its own response strategy.

#### Category 1: Unrecognized Verb ("What?")

The parser has no idea what verb the player intended. This should be rare if Tiers 0–1 and 3 do their jobs.

**Current:** "I'm not sure what you mean."  
**Desired voice:** The narrator, bemused but helpful.

| Attempt | Response |
|---------|----------|
| 1st | "That's not something you know how to do. Try examining things to learn what's possible." |
| 2nd (same verb) | "Still not a thing. You could try: look, take, open, examine, feel, smell, listen." |
| 3rd+ | "You keep trying to *{verb}* things. I admire the persistence, but that word means nothing here." |

**Progressive hints:** The game gets more explicit each time. First time: gentle redirect. Second time: shows available verbs. Third time: acknowledges the pattern with personality.

#### Category 2: Unrecognized Noun ("What's that?")

The verb is fine but the target object doesn't exist or isn't visible.

**Current:** "I don't see that here."  
**Desired:** Context-aware, specific.

| Context | Response |
|---------|----------|
| Object doesn't exist in game | "There's no *{noun}* here. Look around to see what's available." |
| Object exists but is in another room | "You don't see *{noun}* nearby." (No spoiler about other rooms) |
| Object is hidden (under rug, etc.) | "You don't notice anything like that." (True — they haven't found it) |
| Object is in closed container | "You don't see *{noun}* right now." (Hint: search more) |
| In darkness, object exists but can't be seen | "It's too dark to see. Try feeling around." |

**Key principle:** NEVER reveal hidden objects. "You don't see a brass key here" is fine when the key is under the rug. It's technically true — they DON'T see it. But don't say "There is no brass key" — that's a lie.

#### Category 3: Impossible Action ("You can't do that")

The verb and noun are both recognized, but the action is physically impossible or nonsensical.

**Current:** "You can't do that."  
**Desired:** Explain WHY, in world-appropriate terms.

| Impossible Action | Response |
|---|---|
| "eat nightstand" | "The nightstand is not something you could eat. Even if you were very hungry." |
| "open candle" | "The candle doesn't open. It's a solid column of wax." |
| "wear mirror" | "The mirror is far too large and fragile to wear." |
| "light door" | "The door is made of thick oak. It's not going to catch fire easily." |
| "drink rug" | "That's... not how rugs work." |

**Implementation:** Objects should declare what categories of verbs they respond to (via template inheritance). A `small-item` responds to `take/drop/examine/feel/smell/taste/listen`. Attempting an unsupported verb on an object → category 3 error. The response should reference the object's material properties when explaining impossibility.

**The narrator voice matters here.** Zork's genius was that impossible actions were often funnier than possible ones. "I don't think that the platinum sword would agree with you" is comedy gold. Our narrator should have personality — dry, slightly sardonic, but never mean.

#### Category 4: Missing Prerequisite ("You need something first")

The action WOULD work, but a precondition is unmet. This is the most important error category for game flow.

**Current:** Silent failure or generic "You can't do that."  
**Desired:** Hint at what's missing without solving the puzzle.

| Situation | Response |
|---|---|
| "light candle" (no fire source) | "You'll need something to light it with." |
| "open chest" (locked, no key) | "The chest is locked. You'll need to find the key." |
| "read note" (dark room) | "It's too dark to read anything." |
| "sew cloth" (no needle) | "You'd need a needle and thread for that." |
| "unlock door" (don't have key) | "You don't have anything that fits the lock." |

**Progressive hints for repeated attempts:**

| Attempt | Response for "light candle" without fire source |
|---|---|
| 1st | "You'll need something to light it with." |
| 2nd | "A flame would help. Matches? A lighter? Anything that makes fire?" |
| 3rd | "You really want this candle lit, don't you? Maybe search around for matches." |
| 4th+ | "The candle remains stubbornly unlit. There must be something in this room that makes fire." |

**This is the fine line:** We hint, we don't solve. The GOAP planner (Tier 3 in the architecture docs) can auto-resolve obvious prerequisites. But when the player genuinely hasn't found the required tool yet, we give clues, not answers. The progression should guide without spoiling.

#### Category 5: Ambiguous Command ("Which one?")

Multiple objects match the player's input. This is a noun resolution problem, but the ERROR response matters.

**Current:** fuzzy.lua produces "Which do you mean: X or Y?"  
**Desired:** More context-rich disambiguation.

| Ambiguity | Current Response | Better Response |
|---|---|---|
| "take candle" (2 candles visible) | "Which do you mean: candle or candle?" | "There are two candles here. Do you mean the one on the nightstand or the one on the shelf?" |
| "open door" (2 doors) | "Which do you mean: door or door?" | "There are doors to the north and east. Which one?" |
| "examine bottle" (3 bottles) | generic list | "You see a small glass bottle, a green wine bottle, and a corked flask. Which one interests you?" |

**Key insight:** Disambiguation should use LOCATION and DISTINGUISHING PROPERTIES, not just names. "Which candle?" is useless when both are called "candle." "The candle on the nightstand or the candle in your hand?" is helpful.

### The Narrator Voice

Our error messages should come from a consistent narrator persona. Think: the narrator from *Hitchhiker's Guide to the Galaxy* (Douglas Adams) crossed with the narrator from *Zork* (a slightly exasperated omniscient presence).

**Voice characteristics:**
- **Dry wit.** Never slapstick, always understated.
- **Acknowledges the player's intent.** "I see what you're trying to do" before explaining why it doesn't work.
- **In-world grounding.** References materials, physics, common sense — not game mechanics.
- **Brevity.** Error messages should be SHORT. One or two sentences max. The player wants to get back to playing, not read a novel about why they failed.
- **Never condescending.** The narrator is amused, not annoyed. The player is the hero; the narrator is the storyteller.

### Error Message Data Structure

Each error response should be defined as data, not hardcoded strings in verb handlers (Principle 8: objects declare behavior, engine executes):

```lua
-- On the object (or template):
error_responses = {
    unsupported_verb = "The {name} doesn't respond to that.",
    no_fire_source = "You'll need something to light {name} with.",
    locked = "The {name} is locked tight.",
    too_heavy = "The {name} is too heavy to pick up.",
    too_dark = "It's too dark to see {name} clearly.",
}
```

This keeps error messages in the object metadata (Principle 8) and allows per-object personality. A sarcastic magic mirror could have different error messages than a mundane nightstand.

---

## Tier 3: Idiom Library

**Status:** 🟡 Partially implemented (IDIOM_TABLE in preprocess.lua, ~25 entries)  
**Purpose:** Translate natural English phrases into canonical game commands  
**Player experience goal:** Players should be able to type naturally without learning "the commands"

### The Problem

There's a vast gap between how players naturally express intent and how the game expects commands to be formatted. Consider the action of picking something up:

- **Canonical command:** `take candle`
- **Player might type:** "pick up the candle," "grab the candle," "get the candle," "snag it," "pick it up," "take it," "I'll take the candle," "let me grab that," "I want to pick that up"

Every single one of those phrasings means the same thing. Tier 3 is the dictionary that maps all of them to `take candle`.

### What's Already Built

The IDIOM_TABLE in preprocess.lua handles:

| Idiom | Maps To | Category |
|-------|---------|----------|
| "set fire to X" | light X | Action synonym |
| "put down X" / "put X down" | drop X | Phrase variant |
| "set down X" / "set X down" | drop X | Phrase variant |
| "blow out X" | extinguish X | Action synonym |
| "have a look at X" | examine X | Compound phrase |
| "take a look at X" | examine X | Compound phrase |
| "take a peek at X" | examine X | Compound phrase |
| "have a look around" / "take a look around" | look | Sweep |
| "get rid of X" | drop X | Casual phrase |
| "make use of X" | use X | Formal phrase |
| "go to sleep" / "lay down" / "lie down" | sleep | Natural phrase |
| "sleep to/til/till dawn" | sleep until dawn | Temporal |

Additionally, `transform_compound_actions` handles a significant set of compound phrases (pry open, roll up, pull back, use X on Y, etc.) and `transform_search_phrases` handles search variants (rummage, hunt, feel around, etc.).

### What Needs to Be Added

The idiom library should be organized by **action category** so Smithers can maintain it systematically:

#### Movement Idioms

| Idiom | Maps To | Notes |
|-------|---------|-------|
| "go through the door" | go {direction of door} | Requires door→exit mapping |
| "walk to X" | go X | Movement synonym |
| "head north" | go north | Casual direction |
| "continue" / "keep going" | go {last direction} | Context-dependent (Tier 4) |
| "enter X" | go X | Room/passage entry |
| "leave" / "get out" | exits or go {only exit} | Auto-resolve if single exit |

#### Examination Idioms

| Idiom | Maps To | Notes |
|-------|---------|-------|
| "check it out" | examine it | Casual investigate |
| "what's this" | examine it | (already handled in Tier 1) |
| "give it a once-over" | examine it | Colloquial |
| "inspect X" | examine X | Formal synonym |
| "study X" | examine X | Thorough investigation |
| "investigate X" | examine X | Mystery-player language |
| "survey the room" | look | Sweep examination |

#### Manipulation Idioms

| Idiom | Maps To | Notes |
|-------|---------|-------|
| "toss X" / "chuck X" / "hurl X" | throw X | Throw synonyms |
| "yank X" | pull X | Forceful pull |
| "shove X" | push X | Forceful push |
| "budge X" | move X | Stuck-object attempt |
| "flip X" | turn X | Orientation change |
| "twist X" / "rotate X" | turn X | Rotational action |
| "slam X" | close X | Forceful close |

#### Sensory Idioms

| Idiom | Maps To | Notes |
|-------|---------|-------|
| "give X a sniff" | smell X | Casual smell |
| "take a whiff" | smell | Ambient smell |
| "poke X" | feel X | Casual touch |
| "run my fingers over X" | feel X | Detailed touch |
| "put my ear to X" | listen X | Targeted listen |
| "take a bite of X" | taste X | Eating attempt |
| "lick X" | taste X | (should already be alias) |
| "give X a taste" | taste X | Casual taste |

#### Inventory Idioms

| Idiom | Maps To | Notes |
|-------|---------|-------|
| "check my pockets" | inventory | Colloquial |
| "what've I got" | inventory | Casual |
| "show me my stuff" | inventory | Direct request |
| "empty my hands" | drop all | Two-hand dump |

### Library Size: The Diminishing Returns Threshold

How big should the idiom library be? This is a real design question.

**The Pareto distribution applies.** Analysis of IF player logs (from the Inform 7 community and IFComp submissions) consistently shows:

- **Top 20 phrases** cover ~60% of non-standard inputs
- **Top 50 phrases** cover ~80%
- **Top 100 phrases** cover ~90%
- **Beyond 200 phrases:** diminishing returns — you're catching edge cases that appear <0.1% of the time

**My recommendation:** Target **80–120 idiom entries** as the V1 library. This is large enough to handle the vast majority of natural phrasings but small enough to maintain by hand. Each entry should be justified by either (a) playtesting data showing real players typed it, or (b) inclusion in classic IF parser studies.

**Beyond 120:** Stop adding idioms and invest in Tier 2 (embedding matching) quality instead. The embedding matcher can handle novel phrasings that no fixed idiom list will catch. Idioms are for the *common* cases; embeddings are for the long tail.

### Regional and Colloquial Variants

This matters more than most designers realize. British English players type differently than American English players:

| British | American | Maps To |
|---------|----------|---------|
| "have a look" | "take a look" | examine |
| "bin it" | "trash it" | drop / destroy |
| "torch" (noun) | "flashlight" | Same object |
| "lift X" | "pick up X" | take |
| "carry on" | "keep going" | continue |
| "nick X" | "swipe X" | take (slang) |

**Decision:** Include British variants for common actions. Our game has a vaguely Anglo-European fantasy setting; British-isms feel natural. Don't go deep on Australian, South African, or Indian English variants for V1 — expand post-playtesting based on actual player demographics.

### Anti-Patterns: What NOT to Idiom-ify

Not everything should go in the idiom library:

1. **Single-word synonyms** belong in the verb alias dictionary (Tier 1), not idioms. "Grab" → "take" is an alias, not an idiom.
2. **Context-dependent phrases** belong in Tier 4. "Do it again" requires context history — no fixed idiom can resolve it.
3. **Noun-only phrases** belong in Tier 5. "The wooden thing" is fuzzy noun resolution, not an idiom.
4. **Compound multi-step goals** belong in GOAP (Tier 3 of the architecture). "Get a match and light the candle" is goal decomposition, not idiom expansion.

---

## Tier 4: Context Window Expansion

**Status:** 🟡 Partially implemented (`context.lua` exists with stack + discovery + room history)  
**Purpose:** The game remembers what the player was doing and uses that memory to resolve ambiguity  
**Player experience goal:** The game should understand implicit references and feel like a conversation, not isolated commands

### What's Already Built

`context.lua` currently provides:
- **Context stack** (5 items): Tracks recently interacted objects. "It" / "that" / "this" resolves to the most recent one.
- **Discovery list** (5 items): Tracks objects found via search. "The thing I found" resolves to the last discovery.
- **Previous room:** Stores the room ID before last movement. Powers "go back."
- **Basic pronoun resolution:** "it", "that", "this", "one" → top of context stack.

This is a good foundation. But it's barely scratching the surface of what context-aware parsing can do.

### Expansion Design

#### 1. Conversation Memory: Last N Commands

The context window should track the last 10 commands (verb + noun), not just last 5 objects. This enables:

| Player Types | What Context Resolves | How |
|---|---|---|
| "do it again" / "again" / "repeat" | Re-execute last command | command_history[1] |
| "do that to the other one" | Same verb, different noun | verb from history, "other" noun from visible objects |
| "try something else" | (Too vague — help prompt) | Recognize as help request |

**Command history structure:**
```lua
command_history = {
    { verb = "examine", noun = "candle", tick = 42, success = true },
    { verb = "take", noun = "match", tick = 41, success = true },
    { verb = "open", noun = "drawer", tick = 40, success = true },
    -- ...up to 10 entries
}
```

#### 2. Implicit References: Pronouns and Demonstratives

Beyond the current "it/that/this → last object," we need:

| Reference | Resolves To | Logic |
|---|---|---|
| "it" | Last object interacted with | Current behavior ✓ |
| "them" / "those" | Last PLURAL reference (e.g., "matches") | Track noun plurality |
| "the other one" | Second item in context stack | Stack[2] |
| "the first one" | First item in disambiguation list | After "which one?" prompt |
| "the second one" | Second item in disambiguation list | After "which one?" prompt |
| "both" | Top two objects in context | Only valid for take/drop |
| "here" | Current room | Always current_room |
| "there" | Last-mentioned location | If location was referenced |
| "everything" | All portable objects in scope | Special handling per verb |
| "all" | Same as everything | Alias |

**Critical new feature — disambiguation memory:** When the game asks "Which do you mean: the glass bottle or the wine bottle?", the player's NEXT command should resolve "it", "first", "second", "the glass one", etc. against that specific disambiguation list. Currently the game forgets the question the instant it's asked.

```lua
-- After disambiguation prompt:
disambiguation_context = {
    options = { glass_bottle_obj, wine_bottle_obj },
    tick = current_tick,
    -- Expires after 3 commands
}
```

#### 3. "Go Back" and Directional Context

Already partially built (previous_room tracking). Expand to:

| Command | Behavior | Implementation |
|---|---|---|
| "go back" | Return to previous room | Use stored previous_room_id |
| "retrace my steps" | Same as go back | Idiom alias → go back |
| "which way did I come from" | Tell the player | Narrate the return direction |
| "the way I came" | Resolve to return direction | As noun in go command |

#### 4. Scene Awareness: Proximity and Salience

"The door" should resolve to the most contextually relevant door, not just the first one in the object list. **Salience scoring:**

| Factor | Weight | Rationale |
|---|---|---|
| Was just mentioned by game text | +5 | The game literally just told them about it |
| Player just interacted with it | +4 | Top of context stack |
| Is the only one of its type | +3 | No ambiguity |
| Was recently examined | +2 | Player showed interest |
| Is in player's hands | +2 | Immediate access |
| Was mentioned in room description | +1 | Present but not highlighted |

**Example:** Player enters a room. The description mentions "a heavy oak door to the north" and "a small iron door to the east." Player types "open the door." Without salience, this is ambiguous. With salience: the oak door was mentioned first and described as "heavy" (implying it's the main obstacle) → lean toward the oak door. But if the player just examined the iron door, that one has higher salience.

When salience doesn't clearly resolve (scores within 1 point), fall through to disambiguation (Tier 2 Category 5).

#### 5. Implicit Object Inference

When a verb requires a tool and the tool is obvious from context, infer it:

| Command | Context | Inference |
|---|---|---|
| "unlock the door" | Player holding brass key | "unlock door with brass key" |
| "light the candle" | Player holding lit match | "light candle with match" |
| "sew the cloth" | Player holding needle + thread | "sew cloth with needle" |
| "write on paper" | Player holding pen | "write on paper with pen" |

**This already exists partially in the GOAP planner.** The context window expansion should feed INTO the GOAP planner's tool search, not replace it. Context provides the "most likely tool" signal; GOAP verifies the tool is actually valid.

### Aging and Decay

Context should fade. An object you examined 50 turns ago is less relevant than one you examined 2 turns ago. The current context window is a fixed stack of 5 — replace with a scored list that decays:

| Recency | Score | Label |
|---|---|---|
| 0–3 turns ago | 1.0 | Immediate |
| 4–10 turns ago | 0.7 | Recent |
| 11–25 turns ago | 0.4 | Fading |
| 26+ turns ago | 0.1 | Distant |

When resolving "it" or "that", multiply the object's base score by its recency multiplier. This prevents stale context from interfering with current intent.

---

## Tier 5: Fuzzy Noun Resolution

**Status:** 🟡 Partially implemented (`fuzzy.lua` exists with Levenshtein, material/property matching, disambiguation)  
**Purpose:** When the player's noun doesn't exactly match any keyword, figure out what they meant  
**Player experience goal:** Reasonable noun references should always resolve. Typos should be caught. Material/property descriptions should work.

### What's Already Built

`fuzzy.lua` is quite capable:
- **Levenshtein typo correction** with length-based thresholds (short words: exact only; medium: distance ≤2; long: distance ≤2)
- **Material matching:** "the wooden thing" → objects with material="wood"
- **Property matching:** "the heavy one" → highest-weight visible object
- **Partial name matching:** "bottle" → "small glass bottle" (substring, ≥3 chars)
- **Disambiguation prompts:** Multiple matches → "Which do you mean?"
- **Scoring system:** exact=10, material+name=5, partial=4, material=3, property=3, typo=2–3

### What Needs to Be Expanded

#### 1. Typo Tolerance Enhancement

Current thresholds are conservative (short words ≤4 chars: exact only). This is correct for avoiding false positives like "rug" → "mug." But we should add **phonetic similarity** as a secondary check:

| Player Types | Current Behavior | Desired Behavior |
|---|---|---|
| "candel" | ✅ Matches "candle" (Lev=2, len=6) | Already works |
| "mirrir" | ✅ Matches "mirror" (Lev=2, len=6) | Already works |
| "nighstand" | ✅ Matches "nightstand" (Lev=1, len=9) | Already works |
| "bottel" | ✅ Matches "bottle" (Lev=2, len=6) | Already works |
| "dor" | ❌ Exact only (len=3) | Should match "door" — add 3-char words with distance=1 |
| "tabel" | ✅ Matches "table" (Lev=2, len=5) | Already works |
| "bras" | ❌ Exact only (len=4) | Should match "brass" — distance 1, common dropped letter |
| "mach" | ❌ Exact only (len=4) | Should match "match" — distance 1, truncation |

**Proposed threshold adjustment:**
- Words ≤3 chars: exact only (unchanged — too short for fuzzy)
- Words = 4 chars: distance ≤1 (NEW — catches common truncations)
- Words 5–7 chars: distance ≤2 (unchanged)
- Words 8+ chars: distance ≤3 (RELAXED from 2 — long words have more typo surface area)

**The "Did you mean?" pattern:** When fuzzy matches with distance >1 but ≤ threshold, the game should confirm: "Did you mean the *candle*?" This lets the player correct a false positive without restarting.

#### 2. Material-Based References

Already working for single-material lookups. Expand to handle:

| Player Types | Resolution | Implementation |
|---|---|---|
| "the glass thing" | Mirror, glass bottle | Material match (exists) |
| "the wooden thing" | Door, nightstand | Material match (exists) |
| "the brass thing" | Brass key, brass spittoon | Material match (exists) |
| "something metal" | All metal objects | Material category match |
| "the breakable one" | Objects with high fragility | Property match on fragility |
| "the shiny thing" | Objects with reflective surface | New property: `reflective` |
| "the rusty one" | Objects with aged/degraded state | State-based matching |

**Material adjective expansion needed:**

| Adjective | Material | Currently in fuzzy.lua? |
|---|---|---|
| "wooden" / "wood" | wood | ✅ Yes |
| "brass" | brass | ✅ Yes |
| "glass" / "crystal" | glass/crystal | ✅ Yes |
| "wax" / "waxen" | wax | ✅ Yes |
| "cloth" / "fabric" | cloth | ✅ Yes |
| "rusty" | iron (degraded) | ❌ No — add |
| "shiny" / "gleaming" | (reflective property) | ❌ No — add as property |
| "old" / "ancient" | (age property) | ❌ No — add as property |
| "broken" / "cracked" | (state match) | ❌ No — match against _state |
| "soft" | cloth, wool, silk | ❌ No — add as material group |
| "sharp" | (property: edge/blade) | ❌ No — add as property |

#### 3. Color-Based References

Players WILL reference objects by color. "The red bottle" / "the green one" / "the dark thing."

**Implementation:** Objects need an optional `color` field (or derive it from material properties):

| Color Term | Matches | Derivation |
|---|---|---|
| "red" / "crimson" / "scarlet" | Objects with color="red" | Direct color field |
| "green" | Objects with color="green" | Direct color field |
| "dark" | Objects that are dark-colored OR unlit | Color or state |
| "bright" / "glowing" | Objects that cast light | casts_light=true |
| "tarnished" | Brass objects in degraded state | Material + state |
| "white" / "pale" | Objects with color="white" | Direct color field |

**Design decision:** Color should be a KEYWORD on the object, not a separate field. If the candle has `keywords = {"candle", "tallow candle", "white candle"}`, then "the white one" should match via partial keyword matching in fuzzy.lua. This requires no new fields — just good keyword authoring (Flanders' responsibility).

#### 4. Size-Based References

Already partially built (PROPERTY_ADJECTIVES in fuzzy.lua handles "big", "small", "heavy", "light"). Expand:

| Reference | Resolution Logic |
|---|---|
| "the big one" | Highest `size` among visible objects |
| "the small one" | Lowest `size` among visible objects |
| "the tiny thing" | Size < threshold (very small) |
| "the tall one" | Property match (need `height` or derive from size) |
| "the long one" | Property match (shape descriptor) |

**Note:** Size/property matching should ONLY engage when the adjective is genuinely discriminating. If all visible objects are the same size, "the big one" should trigger disambiguation, not randomly pick one.

#### 5. Confidence Threshold: When Is Fuzzy TOO Fuzzy?

This is the critical design question. A fuzzy match that's wrong is WORSE than no match at all — the player types "take mug" and the game picks up the rug. That's infuriating.

**Confidence tiers:**

| Score | Confidence | Action |
|---|---|---|
| 10 | Exact match | Execute immediately |
| 5+ | High confidence | Execute immediately |
| 3–4 | Medium confidence | Execute with narration: "(Taking the *candle*...)" |
| 2 | Low confidence | Confirm: "Did you mean the *candle*?" |
| 1 | Very low | Don't match — fall through to error |
| 0 | No match | Error message (Tier 2) |

**The "narration" pattern at medium confidence** is key. When the game is *pretty sure* but not certain, it should execute the action BUT TELL THE PLAYER what it resolved to. This serves two purposes: (a) the player gets their action done, and (b) if the game guessed wrong, the player immediately sees the mistake and can correct it.

```
> take bras
(Taking the brass key...)
You pick up the brass key.
```

vs.

```
> take bras
You pick up the brass key.     ← Player might not realize fuzzy matched
```

The parenthetical "(Taking the *brass key*...)" is a subtle signal that fuzzy resolution happened. Experienced players learn to watch for it; new players get their action done either way.

---

## Priority Order

Which tiers matter MOST for getting to playable? Here's my ranking, and I'll fight anyone who disagrees:

### 🥇 Priority 1: Tier 2 — Error Messages

**Why first:** Every single time the parser fails, the player sees an error message. If those messages are helpful, the player can self-correct. If they're generic ("I don't understand"), the player gives up. Error messages are the safety net under everything else. Even if Tiers 1, 3, 4, and 5 are perfect, players will still do things the game doesn't support — and the error message is ALL they have to learn from.

**Infocom knew this.** Steve Meretzky spent more time writing error messages for *Hitchhiker's Guide* than puzzle descriptions. The error messages were half the entertainment. Our error messages should be at minimum informative and at best delightful.

**Implementation scope:** Medium. Requires error category taxonomy, per-object error templates, progressive hint system, narrator voice guide.

### 🥈 Priority 2: Tier 5 — Fuzzy Noun Resolution

**Why second:** The single most common player frustration in IF is "the game won't recognize this object." When a player can SEE a candle in the room description but types "take candel" and gets "I don't see that here," they lose trust in the game immediately. Fuzzy matching is already partially built. Expanding it to handle material/color references and relaxing typo thresholds will catch the majority of noun resolution failures.

**Implementation scope:** Small-to-medium. `fuzzy.lua` already has the architecture. Needs threshold tuning, color/state matching, and "Did you mean?" confirmations.

### 🥉 Priority 3: Tier 4 — Context Window

**Why third:** Pronoun resolution ("it", "that") is already working. The big gaps are: "do it again" (repeat), disambiguation memory (remember what we just asked about), and salience scoring (pick the right door). These make the game feel intelligent and responsive.

**Implementation scope:** Medium. Requires command history tracking, disambiguation memory, salience scoring system.

### Priority 4: Tier 1 — Question Transforms

**Why fourth:** Already substantially implemented. The main gaps are "why" questions (which integrate with Tier 2 error messages) and counting/comparative questions. These are nice-to-have for the conversational feel but not blocking playability.

**Implementation scope:** Small. Mostly new patterns in `transform_questions`.

### Priority 5: Tier 3 — Idiom Library

**Why last:** The idiom library is already at ~25 entries and combined with verb aliases and Tier 2 embedding matching catches most natural phrasings. Expanding to 80–120 entries is a gradual, ongoing process driven by playtesting data. It's never "done" — you add idioms as players type unexpected things.

**Implementation scope:** Ongoing, small per-session. Table-driven, easy to extend.

---

## Classic IF References

### What Infocom Did Right

**The Zork series (1980–1987)** established the gold standard for parser design. Key lessons:

1. **Error messages were entertainment.** "It is pitch black. You are likely to be eaten by a grue." — This is an ERROR MESSAGE. It's also one of the most iconic lines in gaming history. The lesson: errors are content, not failures.

2. **The parser understood complex sentences.** "Put the small blue crystal sphere in the display case" worked in Zork I in 1980. Forty-five years later, we have no excuse for not matching this.

3. **Context carried forward.** "Open it" after examining a chest worked. "Go north" after being told there's a door to the north worked. The parser maintained a conversational thread.

4. **Disambiguation was friendly.** When the parser was confused, it asked politely: "Which crystal do you mean, the small blue one or the large red one?" — complete with the distinguishing adjectives.

### What Magnetic Scrolls Did Right

**The Pawn (1986)** and **The Guild of Thieves (1987)** had arguably the best parser in IF history:

1. **Adverb understanding.** "Carefully open the door" was recognized and could affect outcomes. We strip adverbs (Tier 0); Magnetic Scrolls used them.

2. **Conversation systems.** "Ask the wizard about the crystal" worked naturally. When we add NPCs, study their approach.

3. **Complex prepositions.** "Put the coin in the slot on the machine in the corner" — four nested prepositions, all resolved correctly.

### What Level 9 Did Right

**Snowball (1983)** and **Knight Orc (1987)** from Level 9 had an underrated parser:

1. **Pronoun chains.** Multiple pronouns in one command: "Give it to him" — resolved both "it" and "him" from context.

2. **Multiple commands per line.** "Open the door then go north then close the door" — the parser split on "then" and executed sequentially. Our `transform_compound_actions` in Tier 0 handles some of this.

3. **"OOPS" command.** Type "take tje candle" → "I don't see 'tje' here." → Type "OOPS candle" → The parser replaces the unrecognized word and retries. This is brilliant UX and costs almost nothing to implement.

### What Modern IF (Inform 7) Does Right

**Emily Short's work** (especially *Counterfeit Monkey*, 2012) and **Andrew Plotkin's work** (*Hadean Lands*, 2014):

1. **UNDO command.** Let the player reverse their last action. Mistakes shouldn't be permanent.

2. **Adaptive hints.** The game tracks what puzzles you've solved and offers contextually appropriate hints. Our progressive error messages (Tier 2) are inspired by this.

3. **Bulk actions.** "Take all" / "drop everything" / "examine all" — batch operations that save the player from tedious repetition.

4. **"GO TO" navigation.** *Hadean Lands* let you type "go to the lab" and the game auto-navigated through known rooms. For our V1 (7 rooms), this might be overkill, but for Level 2+ it's essential.

---

## Implementation Notes for Smithers

### Tier 2: Error Messages

1. **Create an error response module** (`src/engine/ui/errors.lua` or similar). Don't scatter error strings through verb handlers.
2. **Error category enum:** `UNKNOWN_VERB`, `UNKNOWN_NOUN`, `IMPOSSIBLE_ACTION`, `MISSING_PREREQUISITE`, `AMBIGUOUS_TARGET`.
3. **Per-object error overrides:** Objects can declare `error_responses` table. Templates provide defaults. Engine falls back through: object → template → category default.
4. **Progressive hint counter:** Track per-verb-noun pair how many times the player has tried this exact failing action. Increment counter; select response tier accordingly.
5. **Narrator voice:** All error text goes through a single formatter function that can be themed/styled later.

### Tier 5: Fuzzy Resolution

1. **Adjust typo thresholds:** 4-char words → distance ≤1. 8+ char words → distance ≤3.
2. **Add "Did you mean?" confirmation** for matches with score 2 (low confidence).
3. **Add state-based matching:** `_state` field should be searchable. "The broken mirror" → match objects where `_state == "broken"`.
4. **Narration on medium-confidence match:** When score is 3–4, prefix action output with "(Taking the *{resolved name}*...)".

### Tier 4: Context Expansion

1. **Add `command_history` ring buffer** (10 entries) alongside existing context stack.
2. **"again" / "repeat" command:** Pop last successful command from history, re-execute.
3. **Disambiguation memory:** After producing a disambiguation prompt, store the option list with a 3-command TTL. If next command is "first"/"second"/"the glass one", resolve against stored options.
4. **Salience scoring:** When noun resolution finds multiple matches, score by recency (context stack position), proximity (hands > room > container), and mention (was it in the last game-output text).

### Tier 1: Question Expansion

1. **"Why" questions** need integration with Tier 2. Route "why can't I X" to the appropriate error category handler and produce the same progressive hint text.
2. **Counting questions** need inventory/room introspection. "How many matches" → count objects matching keyword in scope.

### Tier 3: Idiom Expansion

1. **Keep the IDIOM_TABLE in preprocess.lua** — it's working well as a table-driven system.
2. **Add new entries as playtesting reveals them.** Don't speculate — add idioms when real players type them.
3. **Consider an external file** (`src/assets/parser/idiom-library.json`) if the table exceeds 100 entries, to keep preprocess.lua manageable.

### "OOPS" Command (Bonus — from Level 9)

Seriously, implement this. It's trivially simple and enormously helpful:

1. When parser fails on an unrecognized noun, store the failed input and the position of the unrecognized word.
2. If the player's next command is "oops {word}", replace the unrecognized word in the stored input and re-parse.
3. Example: "take teh candle" → fail → "oops the" → re-parse as "take the candle" → success.

This costs maybe 20 lines of Lua and saves enormous player frustration.

---

## Appendix: The Infocom Standard

For reference, here are the capabilities Infocom's Z-machine parser had in 1987 (Infocom's final parser, used in *Beyond Zork* and *Sherlock*):

| Capability | Infocom (1987) | Our Engine (2026) | Status |
|---|---|---|---|
| Verb aliases | ✅ | ✅ | Parity |
| Multi-word verbs ("pick up") | ✅ | ✅ | Parity |
| Prepositions (with/on/in/from) | ✅ | ✅ | Parity |
| Pronouns (it/them/him/her) | ✅ | 🟡 (it/that/this) | Need "them" |
| "all" / "everything" | ✅ | 🟡 (partial) | Need expansion |
| Multiple commands ("then") | ✅ | 🟡 (partial) | Compound actions exist |
| Disambiguation | ✅ | ✅ | Parity |
| OOPS correction | ✅ | ❌ | Implement |
| AGAIN / "g" | ✅ | ❌ | Implement (Tier 4) |
| UNDO | ✅ | ❌ | Future |
| Typo tolerance | ❌ (1987 limits) | ✅ | We're AHEAD |
| Material/property matching | ❌ | ✅ | We're AHEAD |
| Embedding similarity | ❌ | ✅ | We're AHEAD |
| Sensory verb dispatch | ❌ | ✅ | We're AHEAD |
| Progressive error hints | ❌ | 🔴 (Tier 2) | Implement |
| Context-aware tool inference | ❌ | 🟡 (GOAP partial) | Expand |

We're already ahead of Infocom in several areas (typo tolerance, material matching, embeddings, sensory system). But we're behind on OOPS, AGAIN, UNDO, and error message quality. The tiers in this document close those gaps.

---

**End of specification.**

*"I have no strong opinions on this matter. Except that it should be exactly like this."* — CBG
