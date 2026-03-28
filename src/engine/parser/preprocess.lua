-- engine/parser/preprocess.lua
-- Input preprocessing pipeline: natural language normalization and basic parsing.
-- Owned by Smithers (UI Engineer). Pure functions, no side effects.
--
-- Architecture: Table-driven pipeline of composable transform stages.
-- Each stage: string → string (pure transform). Pipeline controls execution order.
-- See docs/architecture/engine/parser/parser-strategy.md for rationale.
--
-- Extracts:
--   preprocess.natural_language(input) -> verb, noun or nil, nil
--   preprocess.parse(input) -> verb, noun
--   preprocess.pipeline -> ordered table of transform stages (externally accessible)

local preprocess = {}

local core = require("engine.parser.preprocess.core")
local phrases = require("engine.parser.preprocess.phrases")
local compound = require("engine.parser.preprocess.compound_actions")
local movement = require("engine.parser.preprocess.movement")
local split = require("engine.parser.preprocess.split")
local data = require("engine.parser.preprocess.data")

---------------------------------------------------------------------------
-- Pipeline Definition
-- Ordered table of transform stages. Externally accessible for extension.
-- Adding a new stage: table.insert(preprocess.pipeline, N, my_transform)
-- Disabling a stage: table.remove(preprocess.pipeline, N)
---------------------------------------------------------------------------

preprocess.pipeline = {
    core.normalize,                -- Trim, lowercase, strip question marks
    core.strip_filler,             -- Iterative: preambles + politeness + adverbs
    phrases.strip_noun_modifiers,     -- Issue #14: whole/entire/every/all-of-the
    phrases.strip_decorative_prepositions, -- #154: "on my head", "in the mirror", "as a hat"
    phrases.expand_idioms,            -- Tier 3: common English phrases → canonical commands
    phrases.transform_questions,      -- Question patterns → imperative commands
    phrases.transform_look_patterns,  -- look at/for/around, check → canonical verbs
    phrases.transform_search_phrases, -- search/hunt/rummage/find compounds
    compound.transform_compound_actions, -- pry, use X on Y, put/take, pull, wear
    movement.transform_movement,       -- sleep, stairs, clock, go back/return
    core.strip_possessives,        -- #67: your/my before noun phrases (AFTER phrase routing)
}

-- Expose individual stage functions for testing and reuse
preprocess.stages = {
    normalize = core.normalize,
    strip_politeness = core.strip_politeness,
    strip_adverbs = core.strip_adverbs,
    strip_preambles = core.strip_preambles,
    strip_gerunds = core.strip_gerunds,
    strip_filler = core.strip_filler,
    strip_possessives = core.strip_possessives,
    strip_noun_modifiers = phrases.strip_noun_modifiers,
    strip_decorative_prepositions = phrases.strip_decorative_prepositions,
    expand_idioms = phrases.expand_idioms,
    transform_questions = phrases.transform_questions,
    transform_look_patterns = phrases.transform_look_patterns,
    transform_search_phrases = phrases.transform_search_phrases,
    transform_compound_actions = compound.transform_compound_actions,
    transform_movement = movement.transform_movement,
}

--- natural_language(input) -> verb, noun or nil, nil
--- Runs the preprocessing pipeline, then parses the result.
--- Returns nil, nil if no transform matched (caller should fall through to parse).
function preprocess.natural_language(input, _depth)
    -- _depth accepted for backward compatibility but unused (pipeline is iterative)
    if not input then return nil, nil end

    local text = input
    local matched = false
    for i, transform in ipairs(preprocess.pipeline) do
        local before = text
        local result, stage_matched = transform(text)
        text = result
        if stage_matched or text ~= before then
            matched = true
        end
        if preprocess.debug and (stage_matched or text ~= before) then
            print(string.format("  [pipeline %d] %q → %q%s",
                i, before, text, stage_matched and " (claimed)" or ""))
        end
    end

    if text == "" then return nil, nil end

    -- If any stage transformed or recognized the text, parse the result
    local original = core.normalize(input)
    if matched or text ~= original then
        return core.parse(text)
    end

    return nil, nil
end


--- split_commands(input) -> list of command strings
--- Splits a raw input line on commas, semicolons, "then", "and then", and
--- ", and" to support multi-command input (Issue #168).
--- Trims whitespace from each segment and drops empty segments.
--- Strips leading "and " from segments left over after comma-and splitting.
--- Does NOT split on separators inside double-quoted text.
function preprocess.split_commands(input)
    return split.split_commands(input)
end

---------------------------------------------------------------------------
-- Issue #168: Verb-aware "and" splitting for compound commands.
-- Only splits "X and Y" when Y starts with a recognized verb.
-- "get candle and matchbox" → stays as one command (matchbox isn't a verb)
-- "take key and unlock door" → splits (unlock IS a verb)
---------------------------------------------------------------------------
function preprocess.split_compound(input)
    return split.split_compound(input)
end

function preprocess.strip_articles(noun)
    return core.strip_articles(noun)
end

function preprocess.parse(input)
    return core.parse(input)
end

function preprocess.singularize(noun)
    return core.singularize(noun)
end

preprocess.debug = false
preprocess.IDIOM_TABLE = data.IDIOM_TABLE

return preprocess
