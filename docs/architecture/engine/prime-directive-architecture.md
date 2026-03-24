# Prime Directive Architecture: Parser Tiers 1–5

**Author:** Smithers (UI Engineer)  
**Date:** 2026-07-19  
**Issue:** #106  
**Status:** Technical specification — ready for Nelson (TDD) and implementation  
**Companion doc:** `docs/architecture/engine/parser/prime-directive-roadmap.md` (design intent, by Bart)

---

## Pipeline Overview

Player input flows through a well-defined sequence. The existing `preprocess.lua` pipeline is table-driven (11 stages), feeding into verb dispatch (`loop/init.lua`), with Tier 2 embedding fallback and Tier 3 GOAP planning as post-dispatch layers. The five new tiers slot into this pipeline at specific points.

### Current Flow (As-Built)

```
Raw Input
    │
    ├─ split_commands()          Multi-command splitting (commas, semicolons, "then")
    ├─ split_compound()          Verb-aware "and" splitting
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  preprocess.pipeline (11 stages, table-driven)      │
│                                                     │
│  1. normalize           — trim, lowercase, strip ?  │
│  2. strip_filler        — preambles, politeness,    │
│                           adverbs, gerunds          │
│  3. strip_noun_modifiers — whole/entire/every        │
│  4. strip_decorative_prepositions — body parts, etc. │
│  5. expand_idioms       — "set fire to X" → light X │
│  6. transform_questions — questions → commands       │
│  7. transform_look_patterns — look at/for/around     │
│  8. transform_search_phrases — search/hunt/rummage   │
│  9. transform_compound_actions — pry, use X on Y    │
│ 10. transform_movement  — sleep, stairs, go back    │
│ 11. strip_possessives   — your/my after routing     │
└─────────────────────────────────────────────────────┘
    │
    ▼
preprocess.parse()  →  verb, noun
    │
    ├─ Context resolution (pronouns, bare nouns, Tier 4)
    ├─ Tool extraction ("with Y", "into Y")
    │
    ▼
Tier 3: GOAP goal_planner.plan(verb, noun, ctx)
    │
    ▼
Verb handler dispatch (ctx.verbs[verb])
    │
    ├─ [on miss] → Tier 2: parser.fallback() → embedding matcher
    │
    ▼
Narration / Error output
```

### Proposed Flow (With All 5 Tiers)

```
Raw Input
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  TIER 3: Idiom Library (expand_idioms — ENHANCED)   │
│  Position: pipeline slot 5 (existing)               │
│  + external data table in idioms.lua                │
└─────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  TIER 1: Question Transforms (transform_questions   │
│          — ENHANCED with questions.lua backing)     │
│  Position: pipeline slot 6 (existing)               │
└─────────────────────────────────────────────────────┘
    │
    ▼
  [...remaining pipeline stages...]
    │
    ▼
  preprocess.parse()  →  verb, noun
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  TIER 4: Context Window (ENHANCED context.lua)      │
│  Position: loop/init.lua pronoun resolution block   │
│  + "again" / "go back" support                      │
└─────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  TIER 5: Fuzzy Noun Resolution (ENHANCED fuzzy.lua) │
│  Position: loop/init.lua, after keyword match fails │
│  + Levenshtein typo correction, confidence scoring  │
└─────────────────────────────────────────────────────┘
    │
    ▼
  Verb handler dispatch
    │
    ├─ [on miss] → Tier 2 embedding fallback
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  TIER 2: Error Message Overhaul                     │
│  Position: verb handlers + fallback paths           │
│  Structured error context replaces bare strings     │
└─────────────────────────────────────────────────────┘
    │
    ▼
  Player sees output
```

---

## Tier 1: Question Transforms

### Module

**Existing file:** `src/engine/parser/preprocess.lua` → `transform_questions()` (pipeline slot 6)  
**New backing module:** `src/engine/parser/questions.lua`

### Current State

`transform_questions()` in preprocess.lua already handles ~25 question patterns inline via Lua `text:match()` chains. It covers `what's in X`, `where is X`, `what am I carrying`, `can I verb X`, health/injury queries, and several `what time` / `what now` patterns. This is working — but the patterns are interleaved, hard to extend, and co-mingled with non-question transforms.

### Architecture

#### Pipeline Position

Stays at slot 6 — **after** `expand_idioms` (slot 5) and `strip_filler` (slot 2). This is correct because:
- Politeness/filler must be stripped first (`can you please tell me what's in the drawer?` → `what's in the drawer?`)
- Idiom expansion can produce questions that need transforming
- Questions should be resolved before look/search/compound transforms

#### Data-Driven Pattern Table

Extract the 25+ inline patterns into a structured table in `questions.lua`:

```lua
-- src/engine/parser/questions.lua
local M = {}

-- Each entry: { pattern, verb, noun_capture, priority }
-- pattern: Lua pattern matched against normalized input
-- verb: canonical verb to emit
-- noun_capture: which capture group is the noun (0 = no noun)
-- priority: lower = matched first (for ordering ambiguous patterns)

M.QUESTION_MAP = {
    -- Container queries
    { pattern = "^what'?s%s+in%s+my%s+hands",   verb = "inventory", noun_capture = 0, priority = 10 },
    { pattern = "^what'?s%s+in%s+the%s+(.+)$",  verb = "examine",   noun_capture = 1, priority = 20 },
    { pattern = "^what'?s%s+in%s+(.+)$",         verb = "examine",   noun_capture = 1, priority = 21 },
    { pattern = "^what%s+is%s+in%s+my%s+hands",  verb = "inventory", noun_capture = 0, priority = 10 },
    { pattern = "^what%s+is%s+in%s+(.+)$",       verb = "examine",   noun_capture = 1, priority = 20 },

    -- Existence queries → search
    { pattern = "^is%s+there%s+anything%s+in%s+(.+)$", verb = "search", noun_capture = 1, priority = 30 },
    { pattern = "^is%s+there%s+an?%s+(.-)%s+in%s+the%s+room$", verb = "search", noun_capture = 1, priority = 31 },
    { pattern = "^is%s+there%s+an?%s+(.-)%s+here$", verb = "search", noun_capture = 1, priority = 31 },
    { pattern = "^is%s+there%s+an?%s+(.+)$",    verb = "search",    noun_capture = 1, priority = 32 },
    { pattern = "^do%s+you%s+see%s+an?%s+(.+)$", verb = "search",   noun_capture = 1, priority = 33 },
    { pattern = "^can%s+i%s+find%s+(.+)$",       verb = "search",   noun_capture = 1, priority = 34 },

    -- Location queries → find
    { pattern = "^where%s+is%s+the%s+(.+)$",    verb = "find",      noun_capture = 1, priority = 40 },
    { pattern = "^where%s+is%s+(.+)$",           verb = "find",      noun_capture = 1, priority = 41 },
    { pattern = "^where'?s%s+the%s+(.+)$",       verb = "find",      noun_capture = 1, priority = 40 },
    { pattern = "^where'?s%s+(.+)$",             verb = "find",      noun_capture = 1, priority = 41 },

    -- Health/injury queries (must precede "where am I" → look)
    { pattern = "^where%s+am%s+i%s+bleeding",    verb = "injuries",  noun_capture = 0, priority = 38 },
    { pattern = "^how%s+bad%s+is%s+it",           verb = "injuries",  noun_capture = 0, priority = 38 },
    { pattern = "^how%s+bad%s+are%s+",            verb = "injuries",  noun_capture = 0, priority = 38 },
    { pattern = "^how%s+am%s+i",                  verb = "health",    noun_capture = 0, priority = 39 },
    { pattern = "^am%s+i%s+hurt",                 verb = "health",    noun_capture = 0, priority = 39 },
    { pattern = "^am%s+i%s+injured",              verb = "health",    noun_capture = 0, priority = 39 },

    -- Environment queries → look
    { pattern = "^what%s+is%s+around",            verb = "look",      noun_capture = 0, priority = 50 },
    { pattern = "^what'?s%s+around",              verb = "look",      noun_capture = 0, priority = 50 },
    { pattern = "^what%s+do%s+i%s+see",           verb = "look",      noun_capture = 0, priority = 50 },
    { pattern = "^where%s+am%s+i",                verb = "look",      noun_capture = 0, priority = 51 },

    -- Possibility questions → strip wrapper
    { pattern = "^can%s+i%s+(%w+)%s+(.+)$",      verb = "$1",        noun_capture = 2, priority = 60 },

    -- Identity questions
    { pattern = "^what%s+is%s+this$",             verb = "look",      noun_capture = 0, priority = 70 },
    { pattern = "^what'?s%s+this$",               verb = "look",      noun_capture = 0, priority = 70 },

    -- Inventory queries
    { pattern = "^what%s+am%s+i%s+carry",         verb = "inventory", noun_capture = 0, priority = 80 },
    { pattern = "^what%s+am%s+i%s+hold",          verb = "inventory", noun_capture = 0, priority = 80 },
    { pattern = "^what%s+do%s+i%s+have",          verb = "inventory", noun_capture = 0, priority = 80 },

    -- Help/confusion
    { pattern = "^what%s+can%s+i%s+do",           verb = "help",      noun_capture = 0, priority = 90 },
    { pattern = "^what%s+do%s+i%s+do",            verb = "help",      noun_capture = 0, priority = 90 },
    { pattern = "^how%s+do%s+i",                  verb = "help",      noun_capture = 0, priority = 90 },

    -- Time queries
    { pattern = "^what%s+time",                   verb = "time",      noun_capture = 0, priority = 95 },
}

--- match(text) -> verb, noun or nil
--- Tries each question pattern in priority order.
--- Returns transformed "verb noun" string on match, or nil.
function M.match(text)
    for _, entry in ipairs(M.QUESTION_MAP) do
        if entry.verb == "$1" then
            -- Dynamic verb extraction (e.g., "can I verb target")
            local v, n = text:match(entry.pattern)
            if v then return v .. " " .. (n or "") end
        elseif entry.noun_capture == 0 then
            if text:match(entry.pattern) then
                return entry.verb
            end
        else
            local noun = text:match(entry.pattern)
            if noun then
                return entry.verb .. " " .. noun
            end
        end
    end
    return nil
end

return M
```

#### Integration

`transform_questions()` in preprocess.lua calls `questions.match(text)` as its primary path, with remaining inline patterns as overflow:

```lua
local questions = require("engine.parser.questions")

local function transform_questions(text)
    local result = questions.match(text)
    if result then return result end
    -- ... remaining inline patterns that don't fit table structure ...
    return text
end
```

#### Handling Different Question Types

| Question Pattern | Verb | Rationale |
|---|---|---|
| `what is X?` / `what's X?` | `examine X` | Identification = examination |
| `where is X?` | `find X` | Location query = spatial search |
| `is there X?` | `search X` | Existence query = room sweep |
| `can I verb X?` | `verb X` | Possibility = attempt (strip wrapper) |
| `how do I...?` | `help` | Confusion = guidance needed |
| `what time...?` | `time` | Temporal query = clock check |

#### API Contract

```lua
-- questions.lua exports:
M.QUESTION_MAP  -- table: the pattern table (externally extensible)
M.match(text)   -- string → string|nil: returns "verb noun" or nil
```

#### Test Strategy

- Unit test `questions.match()` with every pattern in the table
- Regression: all 25+ existing question patterns must still resolve
- Edge cases: questions that contain keywords of other patterns (e.g., "where am I bleeding" vs "where am I")
- Priority ordering: test that higher-priority patterns win over lower ones

#### Estimated Complexity

- **New file:** `src/engine/parser/questions.lua` (~80 lines)
- **Modified file:** `src/engine/parser/preprocess.lua` (replace `transform_questions` body, ~-60 / +10 lines net reduction)
- **Test file:** `test/parser/test-questions.lua` (~100 lines)

---

## Tier 2: Error Message Overhaul

### Module

**No new module.** Enhances existing error paths across:
- `src/engine/loop/init.lua` (Tier 2 fallback, unknown verb fallback)
- `src/engine/parser/init.lua` (embedding matcher failure messages)
- `src/engine/verbs/*.lua` (per-verb error messages)

**New support file:** `src/engine/errors.lua` (error context builder + message templates)

### Current State

Error messages are scattered across verb handlers as bare strings:
- `"You don't see that here."` — no hint what IS here
- `"You can't light that."` — no hint about missing tool
- `"I don't understand that."` — most harmful message in the game
- `"That's not something you can do here."` — generic, unhelpful

The Tier 2 fallback in `parser/init.lua` (line 68) produces the generic `"I'm not sure what you mean."` for unmatched input.

### Architecture

#### Error Context System

Define a structured error object that verb handlers populate:

```lua
-- src/engine/errors.lua
local M = {}

-- Error categories
M.CATEGORY = {
    NOT_FOUND    = "not_found",     -- Object doesn't exist in scope
    WRONG_TARGET = "wrong_target",  -- Object exists but verb is invalid
    MISSING_TOOL = "missing_tool",  -- Action valid but tool absent
    IMPOSSIBLE   = "impossible",    -- Physically impossible action
    DARK         = "dark",          -- Can't see (light required)
    NO_VERB      = "no_verb",       -- Verb not recognized
    AMBIGUOUS    = "ambiguous",     -- Multiple matching objects
}

-- Build an error context table
function M.context(category, fields)
    return {
        category = category,
        verb = fields.verb or nil,
        noun = fields.noun or nil,
        object = fields.object or nil,
        reason = fields.reason or nil,
        suggestions = fields.suggestions or {},
        close_match = fields.close_match or nil,
    }
end

-- Message templates keyed by category
-- Each template is a function(err_ctx) → string
M.TEMPLATES = {
    [M.CATEGORY.NOT_FOUND] = function(e)
        if e.close_match then
            return string.format(
                "You don't see '%s' nearby. Did you mean '%s'? Type 'look' to see what's around.",
                e.noun or "that", e.close_match)
        end
        return string.format(
            "You don't see anything called '%s' here. Try 'look' to see what's in the room.",
            e.noun or "that")
    end,

    [M.CATEGORY.WRONG_TARGET] = function(e)
        local obj_name = e.object and (e.object.name or e.object.id) or e.noun or "that"
        if e.suggestions and #e.suggestions > 0 then
            return string.format(
                "You can't %s %s. Try: %s",
                e.verb or "do that to", obj_name,
                table.concat(e.suggestions, ", "))
        end
        return string.format(
            "You can't %s %s. Try 'examine %s' to learn more about it.",
            e.verb or "do that to", obj_name, e.noun or "it")
    end,

    [M.CATEGORY.MISSING_TOOL] = function(e)
        return string.format(
            "You need %s to %s %s.%s",
            e.reason or "the right tool",
            e.verb or "do that to",
            e.object and (e.object.name or e.object.id) or e.noun or "that",
            e.close_match and (" Maybe " .. e.close_match .. "?") or "")
    end,

    [M.CATEGORY.DARK] = function(e)
        return string.format(
            "It's too dark to %s. Try 'feel %s' to explore by touch, or find a light source.",
            e.verb or "do that", e.noun or "around")
    end,

    [M.CATEGORY.NO_VERB] = function(e)
        if e.close_match then
            return string.format(
                "I don't recognize '%s'. Did you mean '%s'? Type 'help' for commands.",
                e.verb or "that", e.close_match)
        end
        return string.format(
            "I'm not sure what '%s' means. Try phrasing as verb + object (e.g., 'open drawer'). Type 'help' for commands.",
            e.verb or "that")
    end,

    [M.CATEGORY.IMPOSSIBLE] = function(e)
        return string.format(
            "The %s %s%s",
            e.object and (e.object.name or e.object.id) or e.noun or "that",
            e.reason or "won't budge.",
            #(e.suggestions or {}) > 0 and (" Try: " .. table.concat(e.suggestions, ", ")) or "")
    end,

    [M.CATEGORY.AMBIGUOUS] = function(e)
        if e.suggestions and #e.suggestions > 0 then
            if #e.suggestions == 2 then
                return string.format(
                    "Which do you mean: %s or %s?",
                    e.suggestions[1], e.suggestions[2])
            end
            return "Which do you mean: " .. table.concat(e.suggestions, ", ") .. "?"
        end
        return "Could you be more specific?"
    end,
}

--- Format an error context into a player-facing message.
function M.format(err_ctx)
    local template = M.TEMPLATES[err_ctx.category]
    if template then
        return template(err_ctx)
    end
    return "Something went wrong. Type 'help' for guidance."
end

return M
```

#### Integration Points

**1. Verb handlers** — Replace bare error strings with structured calls:

```lua
-- BEFORE (in a verb handler):
print("You don't see that here.")

-- AFTER:
local errors = require("engine.errors")
local err = errors.context(errors.CATEGORY.NOT_FOUND, {
    verb = "examine", noun = noun, close_match = fuzzy_suggestion
})
print(errors.format(err))
```

**2. Loop fallback** (loop/init.lua line 506–511) — Replace generic messages:

```lua
-- BEFORE:
print("That's not something you can do here.")

-- AFTER:
local errors = require("engine.errors")
local suggestion = fuzzy.correct_typo(verb, visible_verbs)
local err = errors.context(errors.CATEGORY.NO_VERB, {
    verb = verb, close_match = suggestion
})
print(errors.format(err))
```

**3. Tier 2 failure** (parser/init.lua line 68) — Contextual failure message:

```lua
-- BEFORE:
print("I'm not sure what you mean. Try 'help'...")

-- AFTER:
local errors = require("engine.errors")
-- Attempt fuzzy verb correction on the first word
local first_word = input_text:match("^(%S+)")
local err = errors.context(errors.CATEGORY.NO_VERB, {
    verb = first_word,
    close_match = find_closest_verb(first_word)
})
print(errors.format(err))
```

#### Error Flow Trace

Current path for `"You can't do that"` messages:

```
loop/init.lua:462  →  handler = context.verbs[verb]
                  →  handler(context, noun)
                       ↓
engine/verbs/sensory.lua → find_visible() returns nil
                         → print("You don't see that here.")
```

New path:

```
loop/init.lua:462  →  handler(context, noun)
                       ↓
engine/verbs/sensory.lua → find_visible() returns nil
                         → fuzzy.correct_typo(noun, visible) → suggestion
                         → errors.context(NOT_FOUND, {noun, close_match=suggestion})
                         → print(errors.format(err))
```

#### Where Error Messages Live

- **Template system:** `src/engine/errors.lua` — category → message function mapping
- **Not per-verb:** Templates are shared across all verbs by category
- **Not constants file:** Functions, not strings, so messages can incorporate context
- **Verb handlers** call `errors.context()` + `errors.format()` — one line replaces each error

#### API Contract

```lua
-- errors.lua exports:
M.CATEGORY            -- table of string constants
M.context(cat, fields) -- builds error context table
M.format(err_ctx)     -- renders error context to string
M.TEMPLATES           -- table: externally extensible template registry
```

#### Test Strategy

- Unit test each template function with all field combinations
- Integration: feed known-failing inputs, assert error messages contain suggestions
- Regression: existing error messages still produce output (no silent failures)
- Quality check: no message should contain `"I don't understand"` or `"You can't do that"` without context

#### Estimated Complexity

- **New file:** `src/engine/errors.lua` (~120 lines)
- **Modified files:** `src/engine/verbs/*.lua` (scattered, ~50 error sites across all verb files)
- **Modified:** `src/engine/loop/init.lua` (~10 lines)
- **Modified:** `src/engine/parser/init.lua` (~5 lines)
- **Test file:** `test/parser/test-errors.lua` (~80 lines)

---

## Tier 3: Idiom Library

### Module

**Existing implementation:** `src/engine/parser/preprocess.lua` → `IDIOM_TABLE` + `expand_idioms()` (pipeline slot 5)  
**New backing module:** `src/engine/parser/idioms.lua`

### Current State

`IDIOM_TABLE` in preprocess.lua already has 16 entries using `{ pattern, replacement }` pairs matched via `text:gsub()`. The table covers fire idioms (`set fire to`), drop idioms (`put down`, `set down`, `get rid of`), look idioms (`have a look`, `take a look`), sleep idioms, and a few others. It is exposed via `preprocess.IDIOM_TABLE` for external extension.

### Architecture

#### Pipeline Position

Stays at slot 5 — **before** `transform_questions` (slot 6). This is critical because:
- Idioms must be expanded before question detection (`"is it possible to set fire to X?"` → strip filler → `"set fire to X"` → expand idiom → `"light X"`)
- The expand_idioms stage fires before look/search/compound transforms so that canonical verbs reach those stages

#### Data Structure

Extract the idiom table to a dedicated data module:

```lua
-- src/engine/parser/idioms.lua
local M = {}

-- Each idiom: { pattern = Lua pattern, replacement = gsub replacement, category = string }
-- Category is for documentation/debugging only, not matching logic.
-- Patterns are tried in order; first match wins.
-- replacement uses %1, %2 etc. for captures (standard gsub).

M.IDIOM_TABLE = {
    -- === FIRE / LIGHT ===
    { pattern = "^set%s+fire%s+to%s+(.+)$",    replacement = "light %1",   category = "fire" },
    { pattern = "^set%s+(.+)%s+on%s+fire$",     replacement = "light %1",   category = "fire" },
    { pattern = "^kindle%s+(.+)$",              replacement = "light %1",   category = "fire" },

    -- === DROP / DISCARD ===
    { pattern = "^put%s+down%s+(.+)$",          replacement = "drop %1",    category = "drop" },
    { pattern = "^put%s+(.+)%s+down$",          replacement = "drop %1",    category = "drop" },
    { pattern = "^set%s+down%s+(.+)$",          replacement = "drop %1",    category = "drop" },
    { pattern = "^set%s+(.+)%s+down$",          replacement = "drop %1",    category = "drop" },
    { pattern = "^get%s+rid%s+of%s+(.+)$",      replacement = "drop %1",    category = "drop" },
    { pattern = "^discard%s+(.+)$",             replacement = "drop %1",    category = "drop" },
    { pattern = "^ditch%s+(.+)$",               replacement = "drop %1",    category = "drop" },

    -- === EXTINGUISH ===
    { pattern = "^blow%s+out%s+(.+)$",          replacement = "extinguish %1", category = "fire" },
    { pattern = "^snuff%s+out%s+(.+)$",         replacement = "extinguish %1", category = "fire" },

    -- === LOOK / EXAMINE ===
    { pattern = "^have%s+a%s+look%s+at%s+(.+)$",  replacement = "examine %1", category = "look" },
    { pattern = "^take%s+a%s+look%s+at%s+(.+)$",  replacement = "examine %1", category = "look" },
    { pattern = "^take%s+a%s+peek%s+at%s+(.+)$",  replacement = "examine %1", category = "look" },
    { pattern = "^take%s+a%s+closer%s+look%s+at%s+(.+)$", replacement = "examine %1", category = "look" },
    { pattern = "^have%s+a%s+look%s+around$",    replacement = "look",       category = "look" },
    { pattern = "^take%s+a%s+look%s+around$",    replacement = "look",       category = "look" },
    { pattern = "^have%s+a%s+look$",             replacement = "look",       category = "look" },
    { pattern = "^take%s+a%s+look$",             replacement = "look",       category = "look" },
    { pattern = "^take%s+a%s+peek$",             replacement = "look",       category = "look" },
    { pattern = "^study%s+(.+)$",               replacement = "examine %1", category = "look" },
    { pattern = "^check%s+out%s+(.+)$",         replacement = "examine %1", category = "look" },

    -- === UTILITY ===
    { pattern = "^make%s+use%s+of%s+(.+)$",     replacement = "use %1",     category = "use" },

    -- === SLEEP / REST ===
    { pattern = "^go%s+to%s+sleep$",            replacement = "sleep",      category = "rest" },
    { pattern = "^lay%s+down$",                 replacement = "sleep",      category = "rest" },
    { pattern = "^lie%s+down$",                 replacement = "sleep",      category = "rest" },
    { pattern = "^have%s+a%s+rest$",            replacement = "sleep",      category = "rest" },
    { pattern = "^sleep%s+to%s+(.+)$",          replacement = "sleep until %1", category = "rest" },
    { pattern = "^sleep%s+til%s+(.+)$",         replacement = "sleep until %1", category = "rest" },
    { pattern = "^sleep%s+till%s+(.+)$",        replacement = "sleep until %1", category = "rest" },

    -- === SEARCH ===
    { pattern = "^rifle%s+through%s+(.+)$",     replacement = "search %1",  category = "search" },
    { pattern = "^dig%s+through%s+(.+)$",       replacement = "search %1",  category = "search" },
    { pattern = "^look%s+everywhere$",          replacement = "search",     category = "search" },
    { pattern = "^search%s+everywhere$",        replacement = "search",     category = "search" },

    -- === META ===
    { pattern = "^check%s+my%s+pockets$",       replacement = "inventory",  category = "meta" },
    { pattern = "^give%s+me%s+a%s+hint$",       replacement = "help",       category = "meta" },
}

--- match(text) -> result_text, matched_bool
--- Tries each idiom in order. Returns transformed text on first match.
function M.match(text)
    for _, idiom in ipairs(M.IDIOM_TABLE) do
        local new_text = text:gsub(idiom.pattern, idiom.replacement)
        if new_text ~= text then
            return new_text, true
        end
    end
    return text, false
end

return M
```

#### Matching Algorithm

**Word-boundary aware via Lua anchors.** Every pattern uses `^` (start anchor) and `$` (end anchor) to match the full input, not substrings. This prevents false positives:

- `"pick up the pace"` — does NOT match `"^pick%s+up%s+(.+)$"` because "pick up" is handled in `transform_compound_actions`, not idioms. Idioms only fire for full-phrase matches.
- `"set fire to X"` — matches `"^set%s+fire%s+to%s+(.+)$"` exactly.
- `"put down X"` — matches `"^put%s+down%s+(.+)$"` exactly.

**False positive prevention:**
1. Full-line anchoring (`^...$`) ensures partial matches don't fire
2. Priority ordering: more specific patterns listed before general ones
3. Categories allow selective testing of idiom groups
4. Idioms transform to canonical verbs that are always valid — no risk of producing unrecognized output

#### Extensibility

The idiom table is **data-driven**: adding a new idiom is one table entry, no code changes. The `M.IDIOM_TABLE` is exposed for external extension (same pattern as current `preprocess.IDIOM_TABLE`).

Future: idioms could be loaded from a separate `.lua` data file (e.g., `src/meta/parser/idioms-data.lua`) if the table grows beyond ~100 entries. For now, a single module is simpler.

#### Integration

```lua
-- In preprocess.lua expand_idioms():
local idioms = require("engine.parser.idioms")

local function expand_idioms(text)
    return idioms.match(text)
end
```

#### API Contract

```lua
-- idioms.lua exports:
M.IDIOM_TABLE       -- table: externally extensible idiom list
M.match(text)       -- string → string, bool: transformed text + matched flag
```

#### Test Strategy

- Unit test every idiom entry with exact input → expected output
- False positive tests: inputs that look similar but should NOT match
- Regression: all existing 16 IDIOM_TABLE entries must still work
- Edge cases: idioms interacting with filler stripping (chained transforms)

#### Estimated Complexity

- **New file:** `src/engine/parser/idioms.lua` (~100 lines)
- **Modified file:** `src/engine/parser/preprocess.lua` (replace inline IDIOM_TABLE with require, ~-20 / +5 lines)
- **Test file:** `test/parser/test-idioms.lua` (~80 lines)

---

## Tier 4: Context Window Expansion

### Module

**Existing file:** `src/engine/parser/context.lua`  
**Integration:** `src/engine/loop/init.lua` (pronoun resolution block, lines 359–385)

### Current State

`context.lua` already provides:
- **Object stack** (`_stack`): last 5 interacted objects, deduplicated, most-recent-first
- **Discovery list** (`_discoveries`): last 5 search discoveries
- **Previous room** (`_previous_room_id`): for "go back" support
- **Pronoun resolution** (`resolve()`): handles `it`, `that`, `this`, `one`, and `thing I found` patterns
- **Push/peek API**: `push(obj)`, `push_discovery(obj)`, `peek()`, `last_discovery()`

`loop/init.lua` resolves pronouns via a separate PRONOUNS table (14 entries) and falls back to `context.last_noun` or `context_window.peek()` for bare nouns.

### What Needs Enhancement

| Feature | Current | Target |
|---|---|---|
| Verb history | None | Track last N verbs for "again" |
| Direction history | `_previous_room_id` only | Track last direction for "go back" |
| Pronoun "them"/"those" | Listed but resolves to single object | Resolve to last multi-object context |
| "again" / repeat | Not supported | Replay last command |
| "go back" | Works (via movement verb) | Already functional, extend to multi-hop |
| Disambiguation signal | Not used | Context recency as tiebreaker in fuzzy |

#### Data Model Extensions

```lua
-- New state fields in context.lua:
local _last_command = nil       -- { verb = "examine", noun = "matchbox", raw = "examine the matchbox" }
local _last_direction = nil     -- "north", "south", etc.
local _verb_stack = {}          -- Last 5 verbs (for pattern detection)
local _max_verb_stack = 5
```

#### "Again" / Repeat Last Command

```lua
--- New resolve function for "again" and repeat phrases.
--- Returns the raw command string to replay, or nil.
function context_window.resolve_repeat(noun)
    if not noun then return nil end
    local kw = noun:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if kw == "again" or kw == "do it again" or kw == "repeat"
        or kw == "do that again" or kw == "same thing"
        or kw == "one more time" then
        return _last_command
    end
    return nil
end

--- Record the last executed command (called after successful dispatch).
function context_window.set_last_command(verb, noun, raw)
    _last_command = { verb = verb, noun = noun, raw = raw }
end
```

**Integration in loop/init.lua:**

```lua
-- After parse, before verb dispatch:
if verb == "again" or (noun and noun:match("again")) then
    local repeat_cmd = context_window.resolve_repeat(verb == "again" and "again" or noun)
    if repeat_cmd then
        verb = repeat_cmd.verb
        noun = repeat_cmd.noun
    else
        print("There's nothing to repeat.")
        goto next_sub
    end
end
-- ... after successful dispatch:
context_window.set_last_command(verb, noun, sub_input)
```

#### Enhanced Pronoun Resolution

Extend `resolve()` to handle `them`/`those` by keeping a multi-object context:

```lua
local _last_multi = {}  -- Objects from last multi-object interaction

function context_window.push_multi(objects)
    _last_multi = {}
    for _, obj in ipairs(objects) do
        if obj and obj.id then
            _last_multi[#_last_multi + 1] = obj
        end
    end
end

-- In resolve():
if kw == "them" or kw == "those" then
    if #_last_multi > 0 then return _last_multi end
    return _stack[1]  -- fallback to single
end
```

#### Context as Disambiguation Signal

When fuzzy.lua produces multiple matches, context recency can break ties:

```lua
--- Score a fuzzy match candidate by recency in context.
function context_window.recency_score(obj_id)
    for i, obj in ipairs(_stack) do
        if obj.id == obj_id then
            return _max_stack - i + 1  -- Higher = more recent
        end
    end
    return 0
end
```

This score is added to fuzzy match scores as a tiebreaker (see Tier 5 integration).

#### API Contract

```lua
-- context.lua exports (additions to existing API):
context_window.resolve_repeat(text)    -- string → table|nil (last command)
context_window.set_last_command(v,n,r) -- record last successful command
context_window.push_multi(objects)     -- record multi-object context
context_window.recency_score(obj_id)   -- string → number (0-5 recency)
context_window.get_last_direction()    -- string|nil
context_window.set_last_direction(dir) -- record last movement direction
```

#### Test Strategy

- Unit test `resolve_repeat()` with all repeat phrases
- Unit test `recency_score()` with push sequences
- Integration: "examine matchbox" → "open it" → "take them" chain
- Integration: "again" replays last command
- Regression: all existing pronoun resolution still works
- Edge: "again" with no prior command → helpful message

#### Estimated Complexity

- **Modified file:** `src/engine/parser/context.lua` (~+60 lines)
- **Modified file:** `src/engine/loop/init.lua` (~+25 lines for repeat/direction tracking)
- **Test file:** `test/parser/test-context-expansion.lua` (~90 lines)

---

## Tier 5: Fuzzy Noun Resolution Enhancement

### Module

**Existing file:** `src/engine/parser/fuzzy.lua`

### Current State

`fuzzy.lua` already provides:
- **Levenshtein distance** for typo detection
- **Material matching**: "the wooden thing" → objects with `material="wood"` (30 material adjectives)
- **Property matching**: "the heavy one" → match by weight/size (7 property adjectives)
- **Partial name matching**: "bottle" → "small glass bottle" (substring, ≥3 chars)
- **Typo tolerance**: max edit distance 2 for words ≥5 chars, 0 for ≤4 chars
- **Disambiguation prompt**: multiple matches → `"Which do you mean: X or Y?"`
- **Scoring system**: exact=10, material+name=5, partial=4, material=3, typo=2-3
- **`gather_visible()`**: collects all objects from room, surfaces, hands, bags, worn items
- **Length ratio check**: shorter/longer ≥ 0.75 prevents "cloak" → "oak" false positives

### What Needs Enhancement

| Feature | Current | Target |
|---|---|---|
| Levenshtein threshold | distance 0 for ≤4 chars | distance 1 for exactly 4 chars (configurable) |
| Confidence scoring | Score only (3-10 scale) | Normalized 0.0-1.0 confidence with threshold |
| Context integration | None | Recency bonus from context_window |
| Rejection threshold | Implicit (score > 0) | Explicit minimum confidence (≥ 0.3) |
| "Did you mean?" | Only for disambiguation | Also for typo correction suggestion |

#### Confidence Scoring

Normalize the existing score system to 0.0–1.0:

```lua
-- Confidence normalization
local MAX_SCORE = 10  -- exact match score

function fuzzy.confidence(raw_score)
    return math.min(raw_score / MAX_SCORE, 1.0)
end

-- Minimum confidence to accept a fuzzy match (below = reject)
fuzzy.MIN_CONFIDENCE = 0.3  -- score 3/10

-- Minimum confidence to auto-accept without disambiguation
fuzzy.AUTO_ACCEPT = 0.7     -- score 7/10
```

#### Enhanced Scoring with Context

Integrate context recency as a tiebreaker:

```lua
function fuzzy.score_with_context(obj, parsed, context_window)
    local base_score, reason = fuzzy.score_object(obj, parsed)
    if base_score == 0 then return 0, nil end

    local recency = 0
    if context_window and obj.id then
        recency = context_window.recency_score(obj.id)
    end

    -- Recency adds up to 1.0 bonus (tiebreaker, never overrides a better match)
    return base_score + (recency * 0.1), reason
end
```

#### Levenshtein Threshold Tuning

Current thresholds from `max_typo_distance()`:

| Word Length | Current Max Distance | Proposed Max Distance |
|---|---|---|
| ≤3 chars | 0 (exact only) | 0 (unchanged) |
| 4 chars | 0 (exact only) | 1 (allow single typo: `dor` → `door`) |
| 5-7 chars | 2 | 2 (unchanged) |
| 8+ chars | 2 | 2 (unchanged, conservative) |

```lua
function fuzzy.max_typo_distance(word_len)
    if word_len <= 3 then return 0 end
    if word_len == 4 then return 1 end
    if word_len <= 7 then return 2 end
    return 2
end
```

The 4-char change is gated by the 0.75 length ratio check, which prevents `"door"` from matching `"do"` (2/4 = 0.50 < 0.75).

#### "Did You Mean?" Integration

When fuzzy matching fails entirely but `correct_typo()` finds a close match, suggest it:

```lua
-- In the verb handler noun-resolution path (loop/init.lua):
local obj = find_visible(ctx, noun)
if not obj then
    -- Try fuzzy resolution
    local fobj, floc, fparent, fsurface, prompt = fuzzy.resolve(ctx, noun)
    if fobj then
        obj = fobj  -- fuzzy match succeeded
    elseif prompt then
        print(prompt)  -- disambiguation needed
        goto next_sub
    else
        -- No fuzzy match — try typo suggestion
        local suggestion = fuzzy.correct_typo(noun, fuzzy.gather_visible(ctx))
        if suggestion then
            print("You don't see '" .. noun .. "' here. Did you mean '" .. suggestion .. "'?")
        else
            print(errors.format(errors.context(errors.CATEGORY.NOT_FOUND, { noun = noun })))
        end
        goto next_sub
    end
end
```

#### False Positive Prevention

Existing safeguards (retained and enforced):
1. **Minimum word length**: partial match requires ≥3 chars
2. **Length ratio**: shorter/longer ≥ 0.75 for Levenshtein
3. **No typo on ≤3-char words**: prevents `"a"` → `"bed"` etc.
4. **Score threshold**: matches below `MIN_CONFIDENCE` (0.3) are rejected entirely
5. **Disambiguation**: multiple matches at same score → prompt player instead of guessing

New safeguard:
6. **Reject common English words**: add a small blocklist of words that should never fuzzy-match to object names (e.g., `"the"`, `"here"`, `"room"`, `"there"`).

```lua
local FUZZY_BLOCKLIST = {
    the = true, here = true, there = true, room = true,
    this = true, that = true, it = true, them = true,
    all = true, everything = true, nothing = true,
}
```

#### API Contract

```lua
-- fuzzy.lua exports (additions to existing API):
fuzzy.confidence(raw_score)              -- number → 0.0-1.0
fuzzy.MIN_CONFIDENCE                     -- number: rejection threshold
fuzzy.AUTO_ACCEPT                        -- number: auto-accept threshold
fuzzy.score_with_context(obj, parsed, cw) -- obj, parsed, context_window → score, reason
fuzzy.FUZZY_BLOCKLIST                    -- table: words that never fuzzy-match
-- Existing exports unchanged:
fuzzy.resolve(ctx, keyword)              -- ctx, string → obj, loc, parent, surface, prompt
fuzzy.correct_typo(keyword, visible)     -- string, list → string|nil
fuzzy.score_object(obj, parsed)          -- obj, parsed → score, reason
fuzzy.gather_visible(ctx)                -- ctx → list
fuzzy.levenshtein(a, b)                  -- string, string → number
fuzzy.parse_noun_phrase(noun)            -- string → table
```

#### Test Strategy

- Unit test confidence normalization: `score_object()` output → `confidence()` output
- Unit test typo threshold at 4-char boundary: `"dor"` → `"door"` should match
- Unit test blocklist: `"room"` should not fuzzy-match anything
- Unit test context integration: recently interacted objects score higher
- Regression: all existing fuzzy tests must pass (material, property, partial, typo)
- False positive suite: known problematic inputs that should NOT match

#### Estimated Complexity

- **Modified file:** `src/engine/parser/fuzzy.lua` (~+40 lines)
- **Modified file:** `src/engine/loop/init.lua` (~+15 lines for "did you mean" integration)
- **Test file:** `test/parser/test-fuzzy-enhanced.lua` (~100 lines)

---

## Implementation Order

Recommended sequence based on dependency, risk, and impact:

| Order | Tier | Reason | Dependencies | Risk |
|---|---|---|---|---|
| 1 | **Tier 3: Idiom Library** | Zero risk, additive only, immediate coverage boost | None | ZERO |
| 2 | **Tier 1: Question Transforms** | Low risk, data-driven refactor of existing code | None | LOW |
| 3 | **Tier 2: Error Messages** | High impact on player experience, no parser logic change | None | LOW |
| 4 | **Tier 4: Context Window** | Medium risk, requires careful pronoun integration | None | MEDIUM |
| 5 | **Tier 5: Fuzzy Enhancement** | Highest risk (false positives), but highest reward | Tier 4 (for context scoring) | MEDIUM |

**Rationale:** Tiers 1 and 3 are pure data additions — they can't break anything. Tier 2 is presentation only (error messages), isolated from parsing logic. Tier 4 requires state management but builds on existing working infrastructure. Tier 5 depends on Tier 4 for context scoring and has the highest false-positive risk, so it goes last.

---

## Summary: New and Modified Files

| File | Action | Tier | Lines (est.) |
|---|---|---|---|
| `src/engine/parser/questions.lua` | NEW | 1 | ~80 |
| `src/engine/errors.lua` | NEW | 2 | ~120 |
| `src/engine/parser/idioms.lua` | NEW | 3 | ~100 |
| `src/engine/parser/preprocess.lua` | MODIFY | 1, 3 | ~-80 / +15 net |
| `src/engine/parser/context.lua` | MODIFY | 4 | ~+60 |
| `src/engine/parser/fuzzy.lua` | MODIFY | 5 | ~+40 |
| `src/engine/loop/init.lua` | MODIFY | 2, 4, 5 | ~+50 |
| `src/engine/parser/init.lua` | MODIFY | 2 | ~+5 |
| `src/engine/verbs/*.lua` | MODIFY | 2 | ~50 error sites |
| `test/parser/test-questions.lua` | NEW | 1 | ~100 |
| `test/parser/test-errors.lua` | NEW | 2 | ~80 |
| `test/parser/test-idioms.lua` | NEW | 3 | ~80 |
| `test/parser/test-context-expansion.lua` | NEW | 4 | ~90 |
| `test/parser/test-fuzzy-enhanced.lua` | NEW | 5 | ~100 |

**Total new code:** ~300 lines (3 new modules)  
**Total modified code:** ~170 lines across existing modules  
**Total new tests:** ~450 lines (5 test files)

---

## Cross-Cutting Concerns

### Principle 8 Compliance

No tier introduces object-specific logic in the engine. All transforms are generic:
- Questions map by structure, not by object name
- Idioms map by phrase pattern, not by object identity
- Error templates use object metadata (name, material), not hardcoded object checks
- Context tracks objects generically by id/stack position
- Fuzzy matches by keyword/material/property — never by specific object

### Zero External Dependencies

All tiers use pure Lua pattern matching, table lookups, and string operations. No new dependencies. Fengari-compatible.

### Performance Budget

| Tier | Expected Overhead | Justification |
|---|---|---|
| Tier 1 (Questions) | <0.1ms | Table scan of ~35 patterns |
| Tier 2 (Errors) | <0.1ms | Template lookup + string format |
| Tier 3 (Idioms) | <0.1ms | Table scan of ~40 patterns |
| Tier 4 (Context) | <0.1ms | Stack push/peek, array scan |
| Tier 5 (Fuzzy) | ~1-5ms | Levenshtein on visible objects (already benchmarked) |

All tiers stay within the "feels instant" threshold (<10ms total pipeline).

---

*"The illusion of intelligence is engineering. Each tier brings us closer to Copilot without spending a single token."*
