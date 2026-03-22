# Prime Directive Architecture Review

**Author:** Bart (Architect)  
**Date:** 2026-03-25  
**Requested by:** Wayne "Effe" Berry  
**Scope:** Full parser pipeline, search system, verb handlers, GOAP planner, context system  

---

## The Prime Directive (Restated)

> **The game should feel like talking to an AI — but cost nothing to run.**

No API calls. No runtime tokens. Pure local Lua parsing that creates the *illusion* of intelligence through engineering: robust NLP, GOAP goal resolution, helpful errors, progressive search narration, and context retention.

**The test:** If a player types something reasonable in English, the game understands it — or gracefully explains what it didn't understand.

---

## Executive Summary

**We're about 65% aligned with the Prime Directive.**

The foundation is solid — better than any classic IF parser I've seen. The preprocessor handles natural phrasing ("I want to light the candle"), the GOAP planner auto-resolves multi-step prerequisites, and the pronoun system chains compound commands. These are genuine innovations.

But there are real gaps. The parser still punishes players in ways that feel like Zork, not Copilot. Error messages are mechanical. Verb coverage has blind spots. The Tier 2 fallback (Jaccard matching) is clever but fragile. And the search narrator — our most ambitious Prime Directive feature — is stuck on template[1] and never rotates.

Below is the honest breakdown.

---

## 1. WHERE THE PARSER FEELS LIKE ZORK (Fighting the Parser)

These are inputs a real player would type that would **fail today**:

### Catastrophic Failures (No Handler, No Fallback)

| Player Types | What Happens | Why It Fails |
|---|---|---|
| `pick up the match` | Works (preprocess catches "pick up") | ✅ Actually works |
| `grab a match from the matchbox` | Falls to `grab` → `take`, but "a match from the matchbox" parse path depends on "from" detection in `take` handler | ⚠️ Works but fragile |
| `what's this?` | Stripped `?`, becomes "what's this" → no match | ❌ No natural_language pattern |
| `look at the bed carefully` | Tier 1: "look" verb found, noun = "at the bed carefully" → strips "at" → tries "the bed carefully" → fails keyword match | ❌ Adverbs poison noun |
| `examine everything` | `examine` handler gets "everything" → no object match | ❌ No "everything"/"all" support |
| `go to bed` | `preprocess.natural_language` catches this → sleep ✅ | ✅ Works |
| `can I open the drawer?` | `?` stripped, "can I open the drawer" → "can" verb → no handler | ❌ No "can I" pattern |
| `try opening the nightstand` | "try" verb → no handler | ❌ No "try to" pattern |
| `is there anything in the drawer?` | "is" verb → no handler | ❌ No "is there" question pattern |
| `maybe I should look around` | "maybe" verb → no handler | ❌ No hedging language |
| `please open the door` | "please" verb → no handler | ❌ No politeness stripping |
| `the matchbox, open it` | Splits on comma → "the matchbox" (no verb) + "open it" | ❌ Object-first phrasing |
| `light it up` | "light" verb, noun "it up" → pronoun resolves "it" but "up" confuses | ⚠️ Partial |
| `set fire to the candle` | No natural_language pattern for "set fire to" | ❌ Missing idiom |
| `put the match to the candle` | "put" handler, tries "match to the candle" → complex prep parsing | ❌ Missing prep pattern |

### The "Adverb Problem"

Our preprocessor strips articles (`the`, `a`, `an`) but **never strips adverbs or trailing qualifiers**. Players naturally type:

- `look at the bed more closely` → noun becomes "bed more closely" → fails
- `carefully examine the nightstand` → "carefully" becomes the verb → fails
- `quickly take the match` → "quickly" becomes the verb → fails
- `gently open the drawer` → "gently" becomes the verb → fails

This is a significant Prime Directive violation. Natural English uses adverbs constantly.

### The "Politeness Problem"

Players who are used to conversational AI will type politely:

- `please look around`
- `could you open the drawer?`
- `can I take the match?`
- `I think I'll examine the bed`

None of these work. Our `natural_language()` handles "I want to" and "I need to" preambles, but misses "please", "could you", "can I", "I think I'll", "let me", "maybe", "try to".

### The "Question Problem"

The game loop has a `question_words` check that catches `what/where/how/who/why` — but only when Tier 1 fails completely. Questions with embedded commands fail:

- `what happens if I light the candle?` → "what" → help text
- `can I look under the bed?` → "can" → no handler
- `is the drawer locked?` → "is" → no handler
- `do I have a key?` → "do" → no handler

These should map to actual game actions (examine candle, look under bed, examine drawer, inventory).

---

## 2. WHERE THE PARSER FEELS LIKE COPILOT (Magic Moments)

### GOAP Prerequisite Resolution ✨

This is our strongest Prime Directive alignment. When a player types `light the candle`:

1. GOAP detects no fire_source
2. Finds match in matchbox on nightstand
3. Plans: open matchbox → take match → strike match → light candle
4. Executes the entire chain automatically

**This is genuinely better than any classic IF parser.** Inform, TADS, and Hugo all require the player to manually perform each step. We infer intent and act on it. This alone justifies the architecture.

### Natural Language Preambles ✨

The preprocessor handles conversational preambles beautifully:

- `I want to take the match` → take match ✅
- `I need to light the candle` → light candle ✅
- `I'd like to open the drawer` → open drawer ✅
- `I'll examine the bed` → examine bed ✅

This is exactly Prime Directive behavior — forgiving, natural, zero-cost.

### Compound Commands ✨

Comma/semicolon/"then"/"and" splitting works well:

- `take match, strike it, light candle` → 3 commands executed in sequence ✅
- `move bed then move rug then open trapdoor` → 3 commands ✅
- `take match and light candle` → GOAP recognizes the intent and plans end-to-end ✅

### Pronoun Resolution ✨

Context chaining between commands works:

- `examine matchbox` then `open it` → opens the matchbox ✅
- `find match` then `take it` → takes the match ✅
- `look at candle` then `light that` → lights the candle ✅

### Plural-to-Singular Fallback ✨

BUG-056 fix means room descriptions can use "torches" and `take torch` still works. This is invisible to the player but prevents a classic IF frustration.

### Sensory Verb System ✨

Five senses work independently of light level. In darkness, `feel` works where `look` doesn't. This is both good game design and good Prime Directive alignment — the game explains WHY something doesn't work and what to do instead: `"(Try 'feel' to grope around in the darkness.)"`

---

## 3. THE BIGGEST GAP

### **Tier 2 (Embedding Matcher) is a False Promise**

The Tier 2 Jaccard-based matcher has 4,337 phrases across 48 verbs. That sounds impressive. But here's the problem: **it matches phrase text, not intent**.

When the Tier 1 verb lookup fails (no handler for the first word), Tier 2 tokenizes the entire input and compares it against pre-built phrases using Jaccard similarity. But because stop words are stripped (including `with`, `on`, `in`, `for`, `up`, `down`, `around`), the semantic meaning of prepositions is lost.

Example: `"put match on nightstand"` tokenizes to `{put, match, nightstand}`. But `"put match in nightstand"` also tokenizes to `{put, match, nightstand}`. Same score, different intent.

Worse: The matcher returns a pre-baked noun from the phrase entry, not the noun the player typed. So `"examine the strange looking bed"` might match phrase `"examine a large four-poster bed"` and return noun `"bed"` — which works, but only by coincidence. If the player typed `"examine the weird carving"`, it might match `"examine a lit tallow candle"` and return `"candle-lit"` — completely wrong.

**The fundamental issue:** Tier 2 maps input to a fixed set of known (verb, noun) pairs. It doesn't extract the player's actual noun and pair it with the best verb. This means Tier 2 can only handle inputs that closely resemble pre-built phrases.

**Impact on Prime Directive:** For the 10-20% of inputs that fall to Tier 2, many will silently match the wrong thing or fail with `"I don't understand that."` The player never knows why.

**Recommendation:** Restructure Tier 2 to do verb-only matching (find the best verb from the input) and use the existing noun extraction from the input text, not from the phrase dictionary. This would make Tier 2 dramatically more robust.

---

## 4. OUR STRONGEST ALIGNMENT

### **The GOAP + Preprocess Pipeline**

The combination of `preprocess.natural_language()` (strips preambles, maps questions to verbs, handles idioms) + `goal_planner.plan()` (backward-chains prerequisites) + compound command splitting ("and"/"then"/comma) creates a parser pipeline that is genuinely conversational.

When it works, the player types `"I want to light the candle"` and the game:
1. Strips "I want to" → `light the candle`
2. Recognizes `light` verb, `candle` noun
3. GOAP discovers no fire_source, plans match retrieval
4. Executes 5-step chain automatically
5. Outputs narrative prose for each step

**No classic IF engine does this.** This is Copilot-level inference at zero token cost.

---

## 5. WHAT TO BUILD NEXT (Prioritized Recommendations)

### Priority 1: Preamble/Politeness Stripping (1-2 hours)

**File:** `src/engine/parser/preprocess.lua`, function `natural_language()`

Add patterns to strip:
```lua
-- Politeness
lower:match("^please%s+(.+)")
lower:match("^could%s+you%s+(.+)")
lower:match("^can%s+you%s+(.+)")
lower:match("^would%s+you%s+(.+)")

-- Hedging
lower:match("^let%s+me%s+(.+)")
lower:match("^try%s+to%s+(.+)")
lower:match("^try%s+(.+)")
lower:match("^maybe%s+(.+)")
lower:match("^perhaps%s+(.+)")

-- Questions that are really commands
lower:match("^can%s+i%s+(.+)")
lower:match("^may%s+i%s+(.+)")
lower:match("^is%s+it%s+possible%s+to%s+(.+)")
```

Then recurse through `natural_language()` → `parse()` as the preamble patterns already do.

**Test cases:**
- `please open the drawer` → open drawer
- `can I take the match?` → take match
- `let me examine the bed` → examine bed
- `try to light the candle` → light candle

### Priority 2: Adverb Stripping (1 hour)

**File:** `src/engine/parser/preprocess.lua`

Add an adverb/qualifier strip pass in `parse()` or as a new function:
```lua
local ADVERBS = {
    "carefully", "quickly", "gently", "slowly", "quietly",
    "closely", "thoroughly", "softly", "firmly", "hard",
    "again", "once more",
}
-- Strip leading adverb
-- Strip trailing qualifier: "more closely", "very carefully"
```

**Test cases:**
- `carefully examine the nightstand` → examine nightstand
- `look at the bed more closely` → look at bed
- `quickly take the match` → take match

### Priority 3: Tier 2 Verb-Only Matching (2-3 hours)

**File:** `src/engine/parser/embedding_matcher.lua`

Restructure `match()` to:
1. Extract noun from the player's actual input (not the phrase entry)
2. Match only the verb component against known verbs
3. Return (matched_verb, player's_extracted_noun, score)

This would make Tier 2 a verb-recognition layer rather than a full-phrase lookup. The noun extraction already works well in Tier 1 — reuse it.

### Priority 4: Question-to-Action Mapping (1-2 hours)

**File:** `src/engine/parser/preprocess.lua`, function `natural_language()`

Add question patterns that map to actions:
```lua
-- "is the drawer locked?" → examine drawer
lower:match("^is%s+the%s+(.-)%s+locked") → "examine", target
lower:match("^is%s+the%s+(.-)%s+open") → "examine", target
lower:match("^is%s+there%s+(.-)%s+in%s+(.+)") → "look", "in " .. container

-- "do I have X?" → inventory
lower:match("^do%s+i%s+have%s+(.+)") → "inventory", ""

-- "what's this?" / "what is that?" → examine + context
lower:match("^what'?s%s+this") → "examine", (use last_noun)
lower:match("^what%s+is%s+that") → "examine", (use last_noun)
```

### Priority 5: Narrator Rotation Fix (30 minutes)

**File:** `src/engine/search/narrator.lua`

The narrator always picks `templates[1]`. This makes the search system feel mechanical ("Your eyes scan the X — nothing notable" every single time). Add simple rotation:

```lua
local _template_counter = 0
local function pick_template(templates)
    _template_counter = _template_counter + 1
    return templates[((_template_counter - 1) % #templates) + 1]
end
```

Also add more templates. The current set is minimal (3 per sense). Double or triple them for variety.

### Priority 6: "set fire to" Idiom (30 minutes)

**File:** `src/engine/parser/preprocess.lua`

Add missing fire idioms:
```lua
lower:match("^set%s+fire%s+to%s+(.+)") → "light", target
lower:match("^set%s+(.+)%s+on%s+fire") → "light", target
lower:match("^ignite%s+(.+)") → "light", target
lower:match("^kindle%s+(.+)") → "light", target
```

### Priority 7: Error Message Overhaul (2-3 hours)

See Section 7 below for specific examples.

### Priority 8: Context Window (Tier 4) — MVP Implementation (4-6 hours)

The Tier 4 design doc is solid but unimplemented. A minimal version would:
1. Track last 5 examined objects
2. Use discovered knowledge for GOAP tool inference
3. Enable `"light the candle"` to auto-find matches when player recently examined the matchbox

This would close the gap between "the parser understands my words" and "the parser understands my intent."

---

## 6. ARCHITECTURAL ISSUES

### 6A: The 4,813-Line Verb File

`src/engine/verbs/init.lua` is a monolith. Every verb handler — from `look` to `sew` to `sleep` to `report_bug` — lives in one file. This makes:
- **Finding code** hard (grep is necessary for any change)
- **Ownership** unclear (Smithers and Bart both own parts)
- **Testing** difficult (can't test one verb in isolation)
- **Error message consistency** impossible to enforce

**Recommendation:** Split into per-verb or per-category files:
```
src/engine/verbs/
├── init.lua          (registration + dispatch)
├── sensory.lua       (look, examine, feel, smell, taste, listen)
├── inventory.lua     (take, drop, put, wear, remove)
├── interaction.lua   (open, close, lock, unlock, break, light, extinguish)
├── crafting.lua      (sew, write, strike, cut, prick)
├── movement.lua      (go, climb, enter, directions)
├── meta.lua          (help, inventory, time, sleep, report_bug)
└── search.lua        (search, find — delegates to engine/search/)
```

This is not urgent, but it will become painful as we add verbs.

### 6B: Tier 2 Noun Leakage

As described in Section 3, the Tier 2 matcher returns pre-baked nouns from the phrase dictionary. If a player types `"examine strange object"` and it matches phrase `"examine a tallow candle"`, the handler receives `"candle"` as the noun — not `"strange object"`. The player's actual words are discarded.

This is an architectural mistake. The matcher should determine the verb, and the noun should be extracted from the player's input.

### 6C: Missing `"and"` Intelligence

The `" and "` compound splitting is naive — it splits on every occurrence of ` and `. This fails for:
- `"take the bread and butter"` → splits into `"take the bread"` + `"butter"` (loses verb)
- `"pick up the pen and paper"` → splits into `"pick up the pen"` + `"paper"`

Currently there's logic to detect if the second part is verb-less and prepend the verb, but I don't see that in the code. The `while` loop at line 114-131 of `loop/init.lua` just splits blindly.

**Fix:** After splitting on `"and"`, check if the second part starts with a known verb. If not, prepend the verb from the first part.

### 6D: Search Module Has No Memory

The search system's `has_been_searched()` and `mark_searched()` are stubs that always return false. This means every search re-visits every object. The README promises "remembers what's been searched, skips on re-search" but it's not implemented.

### 6E: The Tier 3/4/5 Gap

Tiers 3, 4, and 5 are documented but:
- **Tier 3 (GOAP):** Partially implemented — `goal_planner.lua` handles fire_source prerequisites only. The full backward-chaining planner from the design doc (arbitrary verb goals, container unlocking, key discovery) is NOT built.
- **Tier 4 (Context Window):** Not implemented at all. No context aging, no discovery tracking, no confidence scoring.
- **Tier 5 (SLM):** Not implemented (intentionally deferred).

The parser stack as documented suggests ~95% coverage. Reality is closer to 80% because Tier 3 only handles one capability (fire_source) and Tier 4 doesn't exist.

---

## 7. ERROR MESSAGES: Punishment vs. Guidance

### Current Error Messages (Examples from Code)

| Situation | Current Message | Prime Directive Grade |
|---|---|---|
| Object not found | `"You don't see that here."` | **D** — No help, no suggestion |
| Hands full | `"Your hands are full. Drop something first."` | **B** — Tells what to do |
| Can't carry | `"You can't carry that."` | **D** — Doesn't explain why |
| Can't light | `"You can't light that."` | **D** — No hint about fire source |
| Not openable | `"You can't open that."` | **D** — Doesn't say what IS openable |
| Wrong tool | `"You can't sew with that."` | **C** — Missing tool hint |
| Dark room | `"It is too dark to see... (Try 'feel')"` | **A** — Perfect! Explains AND suggests |
| Vision blocked | `"You can't see a thing -- the sack is covering your eyes."` | **A** — Specific, helpful |
| Total parse failure | `"I don't understand that."` | **F** — Worst possible response |
| Total parse fail (Tier 2 off) | `"I don't understand 'X'. Try 'look', 'examine', 'take', 'open', or type 'help'."` | **B** — At least suggests verbs |
| Question word | `"Try 'feel' to explore by touch, or 'look' if you have light."` | **B** — Helpful redirect |
| Search failed | `"You finish searching. No X found."` | **C** — Factual but not helpful |
| Sleep duration | `"Sleep how long? Try 'sleep for 2 hours' or 'sleep until dawn'."` | **A** — Perfect example |

### Recommended Improvements

**"You don't see that here."** → The #1 most frustrating message in IF. Replace with contextual hints:

```lua
-- Instead of: "You don't see that here."
-- Try:
"You don't see anything called '" .. noun .. "' nearby. Try 'look' to see what's around you."

-- If there's a close keyword match:
"Did you mean '" .. closest_match .. "'? Try 'examine " .. closest_match .. "'."

-- If in darkness:
"You can't see in the dark. Try 'feel " .. noun .. "' instead."
```

**"You can't light that."** → Should explain what's needed:

```lua
-- Instead of: "You can't light that."
-- Try:
"The " .. obj.name .. " doesn't seem flammable."
-- Or, if it IS flammable but missing fire_source:
"You'll need a fire source to light the " .. obj.name .. ". Maybe a match?"
```

**"I don't understand that."** → The Prime Directive's worst enemy:

```lua
-- Instead of: "I don't understand that."
-- Try:
"Hmm, I'm not sure what you mean. Try phrasing it as a verb + object, like 'open drawer' or 'take match'. Type 'help' for a full list of commands."

-- Or with fuzzy matching:
"I don't recognize '" .. verb .. "'. Did you mean '" .. closest_verb .. "'?"
```

**"You can't carry that."** → Should explain why:

```lua
-- If too heavy:
"The " .. obj.name .. " is too heavy to carry."
-- If fixed furniture:
"The " .. obj.name .. " is fixed in place. You can't pick it up."
-- If immovable:
"The " .. obj.name .. " won't budge."
```

---

## 8. 20+ PHRASES THAT SHOULD WORK BUT DON'T

These are inputs a reasonable player would try that our parser does not currently handle:

| # | Player Input | Expected Action | Current Result |
|---|---|---|---|
| 1 | `please open the drawer` | open drawer | ❌ "please" becomes verb |
| 2 | `can I look under the bed?` | look under bed | ❌ "can" becomes verb |
| 3 | `let me examine the nightstand` | examine nightstand | ❌ "let" becomes verb |
| 4 | `try opening the matchbox` | open matchbox | ❌ "try" becomes verb |
| 5 | `carefully look at the painting` | look at painting | ❌ "carefully" becomes verb |
| 6 | `what's this?` | examine (last object) | ❌ No pattern for "what's this" |
| 7 | `look at this more closely` | examine (last object) | ❌ "more closely" poisons noun |
| 8 | `is the door locked?` | examine door | ❌ "is" becomes verb |
| 9 | `do I have a key?` | inventory | ❌ "do" becomes verb |
| 10 | `set fire to the candle` | light candle | ❌ No pattern |
| 11 | `set the candle on fire` | light candle | ❌ No pattern |
| 12 | `put the match to the candle` | light candle | ❌ Misparses as "put" |
| 13 | `take a closer look at the painting` | examine painting | ❌ "take" verb, "closer look..." noun |
| 14 | `maybe I should look in the drawer` | look in drawer | ❌ "maybe" becomes verb |
| 15 | `I wonder what's behind the painting` | look behind painting | ❌ No pattern |
| 16 | `examine everything` | look (room survey) | ❌ No "everything" handling |
| 17 | `pick up everything` | take all | ❌ No "everything/all" handling |
| 18 | `look everywhere` | search | ❌ No "everywhere" mapping |
| 19 | `the matchbox — open it` | open matchbox | ❌ Object-first grammar |
| 20 | `where did I put the key?` | inventory | ❌ Complex question |
| 21 | `check my pockets` | inventory | ❌ No "pockets" mapping |
| 22 | `what does the inscription say?` | read inscription | ❌ Complex question form |
| 23 | `any matches around here?` | search for match | ❌ No "any X around" pattern |
| 24 | `rummage through the drawer` | search drawer | ❌ "rummage" not mapped |
| 25 | `give me a hint` | help | ❌ No "hint" mapping |
| 26 | `help me light the candle` | light candle (with GOAP) | ❌ "help" goes to help text |
| 27 | `blow on the match` | extinguish match | ❌ "blow" not mapped (only "blow out") |
| 28 | `knock on the door` | No action, but could be an affordance | ❌ "knock" not mapped |
| 29 | `look up` | look (upward) | ❌ "look" verb, "up" noun → confusing |
| 30 | `what time is it?` | time | ✅ This one actually works! |

---

## 9. SEARCH SYSTEM ASSESSMENT

### Strengths
- Progressive traversal is philosophically aligned with Prime Directive (narrative pacing)
- Sensory adaptation (vision vs touch) is elegant
- Goal-oriented search framework is in place
- Interruptible by design
- Context setting for follow-up commands

### Weaknesses
- **Narrator never rotates templates** — always picks `templates[1]`. Every step says the same thing.
- **No search memory** — stubs everywhere, re-searches everything
- **Container opening is state-only** — doesn't use FSM transitions consistently (`containers.open()` sets `is_open = true` as a side-channel, then attempts FSM, but the FSM path is fragile)
- **Goal matching is shallow** — `goals.parse_goal()` only catches "something that can [verb]" and "something [property]". Natural patterns like "find something to cut with" or "find a light" don't parse.
- **No partial matches** — if multiple items partially match a goal, player isn't offered choices

### Assessment
The search system is architecturally sound but needs polish. The progressive traverse *does* feel more natural than instant "search → found it!" — which is exactly the Prime Directive intent. But the mechanical narration undermines the illusion.

---

## 10. GOAP SYSTEM ASSESSMENT

### Strengths
- Backward chaining from goal to prerequisites is correct
- Handles nested containers (match inside matchbox inside nightstand drawer)
- Skips spent/terminal objects intelligently
- Clears spent matches before grabbing fresh ones (impressive detail)
- Plans are executed through existing verb handlers (no special-case code)

### Weaknesses
- **Only handles `fire_source` capability** — the full GOAP system from the design doc (arbitrary verbs, key resolution, container unlocking) is not implemented
- **No "unlock with key" resolution** — if chest is locked and player has key, GOAP doesn't auto-plan unlock → open → take
- **No "wear armor" resolution** — GOAP doesn't chain open container → take → wear
- **Hard-coded match-finding logic** — `try_plan_match()` is specific to matches, not generalized to any tool discovery

### Assessment
What's built works well for the candle-lighting puzzle, which is the core demo scenario. But it's a special case, not a general planner. To truly feel like Copilot, GOAP needs to handle any verb's tool requirements generically.

---

## 11. CONTEXT SYSTEM ASSESSMENT

### What Works
- `last_object` tracking for pronouns (it/that/one) ✅
- `last_noun` tracking for bare verb commands ✅
- Compound command chaining ("take match and light it") ✅
- Known objects tracking (`ctx.known_objects`) — populated but unused

### What's Missing
- **No discovery memory** — examining matchbox doesn't record that player knows about matches
- **No confidence decay** — context doesn't age; "it" from 50 commands ago is treated the same as "it" from 1 command ago
- **No spatial memory** — moving between rooms doesn't affect context
- **`known_objects` is unused** — populated in `find_visible` wrapper but never queried by GOAP or search

### Assessment
The pronoun system is functional and covers the most common case (immediate reference). But without Tier 4 (discovery memory + confidence), the context system can't enable the "light the candle" → "oh, you recently examined the matchbox, I'll use that" inference. This is the gap between "parser understands words" and "parser understands intent."

---

## 12. SUMMARY SCORECARD

| Area | Prime Directive Alignment | Grade |
|---|---|---|
| **Natural language preprocessing** | Preambles, questions, idioms — strong | **B+** |
| **GOAP prerequisite resolution** | Fire-source chain is magical | **A** (for what it covers) |
| **GOAP generalization** | Only covers one capability | **D** |
| **Pronoun resolution** | Works for immediate context | **B** |
| **Compound commands** | Comma/then/and splitting works | **B+** |
| **Error messages** | Mostly mechanical, some gems | **C-** |
| **Tier 2 fallback** | 4,337 phrases, but architectural flaw | **C** |
| **Search narration** | Good concept, mechanical execution | **C+** |
| **Adverb/politeness handling** | Missing entirely | **F** |
| **Question-to-action mapping** | Partial (some patterns, many missing) | **C** |
| **Context window (Tier 4)** | Not implemented | **F** |
| **Verb coverage breadth** | 48 verbs, good aliases | **B** |
| **Overall** | | **C+** |

---

## 13. FINAL RECOMMENDATION

The fastest path to Prime Directive alignment is:

1. **This week:** Politeness stripping + adverb stripping in `preprocess.lua` (2-3 hours). Massive bang for buck.
2. **This week:** Error message overhaul for the top 5 most common failures (2-3 hours). Replace "I don't understand" and "You don't see that here" with contextual help.
3. **Next sprint:** Tier 2 restructure to verb-only matching (3-4 hours). Eliminates the architectural noun leakage.
4. **Next sprint:** Generalize GOAP beyond fire_source (4-6 hours). The planner structure is there — extend `plan_for_tool()` to handle key, needle, cutting tools, etc.
5. **Future:** Tier 4 context window MVP (4-6 hours). Needed for "light the candle" to infer tool from recent examination.

The foundation is strong. We're not rebuilding — we're filling gaps in an already-clever system. The Prime Directive is achievable with engineering alone. We just need to close these specific holes.

---

*— Bart, Architect*  
*"The illusion of intelligence is engineering. The feeling of intelligence is attention to detail."*
