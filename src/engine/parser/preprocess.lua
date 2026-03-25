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

--- Debug flag: when true, prints input→output at each pipeline stage.
preprocess.debug = false

--- strip_articles(noun) -> string
--- Strips leading articles ("the", "a", "an") from a noun phrase (BUG-081).
function preprocess.strip_articles(noun)
    if not noun then return "" end
    return noun:gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
end

--- parse(input) -> verb, noun
--- Splits a raw input string into the first word (verb) and the rest (noun).
--- Handles leading "I" pronoun: "i" is inventory only when typed alone.
function preprocess.parse(input)
    input = input:match("^%s*(.-)%s*$") -- trim
    local verb, noun = input:match("^(%S+)%s*(.*)")
    verb = (verb or ""):lower()
    noun = (noun or ""):lower()
    -- BUG-036: "I" as pronoun, not inventory shortcut. Re-parse the rest.
    if verb == "i" and noun ~= "" then
        return preprocess.parse(noun)
    end
    return verb, noun
end

---------------------------------------------------------------------------
-- BUG-056: Plural-to-singular mapping for noun resolution.
-- Room descriptions use plurals ("torches", "portraits") but objects have
-- singular keywords. Returns a list of candidate singular forms to try.
-- (Defined early so pipeline stages can use it.)
---------------------------------------------------------------------------
local function singularize_word(word)
    if not word or #word < 3 then return {} end
    local forms = {}
    -- -ies → -y (berries → berry, entries → entry)
    local ies_stem = word:match("^(.+)ies$")
    if ies_stem and #ies_stem >= 1 then forms[#forms+1] = ies_stem .. "y" end
    -- -es → strip, only after sibilants: ch, sh, s, x, z
    -- (torches → torch, boxes → box, matches → match)
    local es_stem = word:match("^(.+)es$")
    if es_stem and #es_stem >= 2
        and (es_stem:match("ch$") or es_stem:match("sh$")
             or es_stem:match("[sxz]$")) then
        forms[#forms+1] = es_stem
    end
    -- -s → strip, but not -ss (portraits → portrait, candles → candle)
    local s_stem = word:match("^(.+[^s])s$")
    if s_stem and #s_stem >= 2 then forms[#forms+1] = s_stem end
    return forms
end

---------------------------------------------------------------------------
-- #154: Body part lookup for prepositional suffix stripping.
-- Used by strip_decorative_prepositions and transform_compound_actions.
---------------------------------------------------------------------------
local BODY_PARTS = {
    head = true, face = true, neck = true,
    arm = true, arms = true, leg = true, legs = true,
    hand = true, hands = true, foot = true, feet = true,
    shoulder = true, shoulders = true, waist = true, torso = true,
    stomach = true, belly = true, gut = true, chest = true, side = true,
}

---------------------------------------------------------------------------
-- Pipeline Stage Functions
-- Each takes a string, returns a string (primary contract).
-- Convention: stages may return (text, true) as second value to signal
-- they recognized/claimed the input, even if the output text is identical.
-- This lets the pipeline runner distinguish "no match" from "matched but
-- text was already canonical." Pure transforms, no state mutation.
---------------------------------------------------------------------------

--- Stage: normalize
--- Trim whitespace, lowercase, strip trailing question marks.
local function normalize(text)
    if not text or text == "" then return "" end
    local result = text:lower():match("^%s*(.-)%s*$")
    if not result then return "" end
    result = result:gsub("%?+$", "")
    return result
end

--- Stage: strip_politeness
--- Remove politeness prefixes: "please", "kindly", "could you", etc.
local function strip_politeness(text)
    text = text:gsub("^please%s+", "")
    text = text:gsub("^kindly%s+", "")
    text = text:gsub("^could%s+you%s+", "")
    text = text:gsub("^can%s+you%s+", "")
    text = text:gsub("^would%s+you%s+mind%s+", "")
    text = text:gsub("^would%s+you%s+", "")
    text = text:gsub("^will%s+you%s+", "")
    text = text:gsub("^let%s+me%s+", "")
    text = text:gsub("^try%s+to%s+", "")
    text = text:gsub("^attempt%s+to%s+", "")
    text = text:gsub("^i%s+think%s+i'?ll%s+", "")
    text = text:gsub("^maybe%s+i%s+should%s+", "")
    text = text:gsub("^maybe%s+", "")
    text = text:gsub("^perhaps%s+", "")
    return text
end

--- Stage: strip_adverbs (BUG-085)
--- Remove leading and trailing adverbs/modifiers.
local function strip_adverbs(text)
    -- Leading adverbs
    text = text:gsub("^carefully%s+", "")
    text = text:gsub("^closely%s+", "")
    text = text:gsub("^quickly%s+", "")
    text = text:gsub("^slowly%s+", "")
    text = text:gsub("^gently%s+", "")
    text = text:gsub("^thoroughly%s+", "")
    text = text:gsub("^quietly%s+", "")
    text = text:gsub("^frantically%s+", "")
    text = text:gsub("^desperately%s+", "")
    text = text:gsub("^firmly%s+", "")
    text = text:gsub("^softly%s+", "")
    text = text:gsub("^briskly%s+", "")
    text = text:gsub("^hastily%s+", "")
    text = text:gsub("^nervously%s+", "")
    -- Trailing adverbs/modifiers
    text = text:gsub("%s+carefully$", "")
    text = text:gsub("%s+closely$", "")
    text = text:gsub("%s+quickly$", "")
    text = text:gsub("%s+slowly$", "")
    text = text:gsub("%s+gently$", "")
    text = text:gsub("%s+thoroughly$", "")
    text = text:gsub("%s+quietly$", "")
    text = text:gsub("%s+frantically$", "")
    text = text:gsub("%s+desperately$", "")
    text = text:gsub("%s+firmly$", "")
    text = text:gsub("%s+softly$", "")
    text = text:gsub("%s+briskly$", "")
    text = text:gsub("%s+hastily$", "")
    text = text:gsub("%s+nervously$", "")
    text = text:gsub("%s+again$", "")
    -- Guard: don't strip trailing "now" from question phrases ("what now", "where now")
    if not text:match("^wh%w*%s+now$") then
        text = text:gsub("%s+now$", "")
    end
    text = text:gsub("%s+here$", "")
    return text
end

--- Stage: strip_preambles (BUG-036)
--- Iteratively remove "I want to", "I need to", "I'd like to", etc.
--- Iterative (not recursive) — each pass strictly shortens input.
local function strip_preambles(text)
    for _ = 1, 10 do
        local rest = text:match("^i%s+want%s+to%s+know%s+(.+)")
            or text:match("^i%s+want%s+to%s+(.+)")
            or text:match("^i%s+need%s+to%s+know%s+(.+)")
            or text:match("^i%s+need%s+to%s+(.+)")
            or text:match("^i'?d%s+like%s+to%s+know%s+(.+)")
            or text:match("^i'?d%s+like%s+to%s+(.+)")
            or text:match("^i%s+would%s+like%s+to%s+know%s+(.+)")
            or text:match("^i%s+would%s+like%s+to%s+(.+)")
            or text:match("^i'?ll%s+(.+)")
            or text:match("^i%s+need%s+(.+)")
            or text:match("^i%s+want%s+(.+)")
        if not rest then break end
        text = rest
    end
    return text
end

--- Stage: strip_gerunds (BUG-107)
--- Convert a leading gerund verb to its base form after politeness stripping.
--- E.g., "would you mind examining X" → strips to "examining X" → "examine X".
local GERUND_MAP = {
    examining = "examine", looking = "look", searching = "search",
    opening = "open", closing = "close", taking = "take",
    checking = "check", feeling = "feel", reading = "read",
    smelling = "smell", listening = "listen", breaking = "break",
    tasting = "taste", lighting = "light", dropping = "drop",
    wearing = "wear", climbing = "climb", moving = "move",
    pulling = "pull", pushing = "push", finding = "find",
    lifting = "lift", sliding = "slide", shoving = "shove",
    heaving = "heave", dragging = "drag", nudging = "nudge",
    getting = "get", giving = "give", hiding = "hide",
    picking = "pick", drinking = "drink", eating = "eat",
    using = "use", pouring = "pour", filling = "fill",
    applying = "apply", rubbing = "rub",
    washing = "wash", cleaning = "clean", rinsing = "rinse", scrubbing = "scrub",
}
local function strip_gerunds(text)
    local first, rest = text:match("^(%S+)%s+(.+)$")
    if first and GERUND_MAP[first] then
        return GERUND_MAP[first] .. " " .. rest
    end
    -- Bare gerund with no target
    if GERUND_MAP[text] then
        return GERUND_MAP[text]
    end
    return text
end

--- Stage: strip_filler
--- Iteratively strips preambles, politeness, adverbs, and gerunds until stable.
--- Replaces the recursive natural_language re-entry pattern; single-pass,
--- always terminates (each iteration strictly shortens input or stops).
local function strip_filler(text)
    for _ = 1, 10 do
        local prev = text
        text = strip_preambles(text)
        text = strip_politeness(text)
        text = strip_adverbs(text)
        text = strip_gerunds(text)
        if text == prev then break end
    end
    return text
end

--- Stage: strip_possessives (#67)
--- Strip possessive pronouns ("your", "my") from noun phrases so that
--- "hit your head" → "hit head", "stab my leg" → "stab leg".
--- Only strips possessives that appear AFTER the first word (the verb),
--- to avoid mangling commands like "my inventory".
local function strip_possessives(text)
    -- Strip possessives after verb: "verb your X" → "verb X"
    text = text:gsub("^(%S+%s+)your%s+", "%1")
    text = text:gsub("^(%S+%s+)my%s+", "%1")
    -- Handle "pick up your X" (two-word verbs)
    text = text:gsub("^(%S+%s+%S+%s+)your%s+", "%1")
    text = text:gsub("^(%S+%s+%S+%s+)my%s+", "%1")
    return text
end

--- Stage: strip_noun_modifiers (Issue #14)
--- Remove quantifier/totality modifiers that players use for emphasis but that
--- confuse noun resolution: "whole", "entire", "every", "all of the", etc.
--- E.g., "search the whole room" → "search the room"
local function strip_noun_modifiers(text)
    -- "all of the X" → "the X"  (must come before single-word strips)
    text = text:gsub("%f[%a]all%s+of%s+the%s+", "the ")
    -- "all of X" → "X"
    text = text:gsub("%f[%a]all%s+of%s+", "")
    -- Single-word modifiers before a noun
    text = text:gsub("%f[%a]whole%s+", "")
    text = text:gsub("%f[%a]entire%s+", "")
    text = text:gsub("%f[%a]every%s+", "")
    -- Collapse any doubled spaces left behind
    text = text:gsub("%s%s+", " ")
    text = text:match("^%s*(.-)%s*$")
    return text
end

--- Stage: strip_decorative_prepositions (#154)
--- Strip trailing prepositional phrases that describe location/manner rather
--- than functional targets: "on my head", "from head", "in the mirror",
--- "as a hat", "on the floor". Skips "put"/"place"/"set" (compound targets
--- handled by transform_compound_actions).
local function strip_decorative_prepositions(text)
    local verb = text:match("^(%S+)")
    if not verb then return text end

    -- Compound-target verbs handle their own prepositions
    if verb == "put" or verb == "place" or verb == "set" then
        return text
    end

    -- "as a/an WORD" (manner descriptor: "as a hat", "as a mask")
    text = text:gsub("%s+as%s+an?%s+%S+$", "")

    -- #145: "in the BODYPART" (e.g., "in the face", "in the gut")
    local in_prefix, in_part = text:match("^(.+)%s+in%s+the%s+(%S+)$")
    if in_prefix and BODY_PARTS[in_part] then return in_prefix end

    -- "in the mirror/reflection" (reflective surface) — only strip when there's
    -- a noun between the verb and "in" (decorative: "examine yourself in the mirror").
    -- Bare "look in mirror" keeps "in mirror" as the functional target (#212).
    local pre_mirror = text:match("^(%S+%s+%S.-)%s+in%s+the%s+mirror$")
    if pre_mirror then text = pre_mirror end
    if not pre_mirror then
        pre_mirror = text:match("^(%S+%s+%S.-)%s+in%s+mirror$")
        if pre_mirror then text = pre_mirror end
    end
    local pre_refl = text:match("^(%S+%s+%S.-)%s+in%s+the%s+reflection$")
    if pre_refl then text = pre_refl end
    if not pre_refl then
        pre_refl = text:match("^(%S+%s+%S.-)%s+in%s+reflection$")
        if pre_refl then text = pre_refl end
    end

    -- "on the floor/ground" (drop location)
    text = text:gsub("%s+on%s+the%s+floor$", "")
    text = text:gsub("%s+on%s+floor$", "")
    text = text:gsub("%s+on%s+the%s+ground$", "")
    text = text:gsub("%s+on%s+ground$", "")

    -- "on my BODYPART" (possessive body placement)
    local prefix, part = text:match("^(.+)%s+on%s+my%s+(%S+)$")
    if prefix and BODY_PARTS[part] then return prefix end

    -- "on BODYPART" (bare body placement, requires verb+noun before)
    prefix, part = text:match("^(%S+%s+%S.-)%s+on%s+(%S+)$")
    if prefix and BODY_PARTS[part] then return prefix end

    -- "from my BODYPART" (possessive source)
    prefix, part = text:match("^(.+)%s+from%s+my%s+(%S+)$")
    if prefix and BODY_PARTS[part] then return prefix end

    -- "from BODYPART" (bare source, requires verb+noun before)
    prefix, part = text:match("^(%S+%s+%S.-)%s+from%s+(%S+)$")
    if prefix and BODY_PARTS[part] then return prefix end

    return text
end

---------------------------------------------------------------------------
-- Idiom Library (Tier 3)
-- Table-driven expansion of common English phrases into canonical commands.
-- Each entry: { pattern = Lua pattern, replacement = gsub replacement }.
-- Easy to extend: just append new entries to preprocess.IDIOM_TABLE.
---------------------------------------------------------------------------
local IDIOM_TABLE = {
    { pattern = "^set%s+fire%s+to%s+(.+)$",        replacement = "light %1" },
    { pattern = "^put%s+down%s+(.+)$",              replacement = "drop %1" },
    -- #138: "put X down" → "drop X" (word order variant)
    { pattern = "^put%s+(.+)%s+down$",              replacement = "drop %1" },
    -- #140: "set X down" / "set down X" → "drop X"
    { pattern = "^set%s+down%s+(.+)$",              replacement = "drop %1" },
    { pattern = "^set%s+(.+)%s+down$",              replacement = "drop %1" },
    { pattern = "^blow%s+out%s+(.+)$",              replacement = "extinguish %1" },
    { pattern = "^have%s+a%s+look%s+at%s+(.+)$",    replacement = "examine %1" },
    { pattern = "^take%s+a%s+look%s+at%s+(.+)$",    replacement = "examine %1" },
    { pattern = "^take%s+a%s+peek%s+at%s+(.+)$",    replacement = "examine %1" },
    { pattern = "^have%s+a%s+look%s+around$",        replacement = "look" },
    { pattern = "^take%s+a%s+look%s+around$",        replacement = "look" },
    { pattern = "^have%s+a%s+look$",                replacement = "look" },
    { pattern = "^take%s+a%s+look$",                replacement = "look" },
    { pattern = "^take%s+a%s+peek$",                replacement = "look" },
    { pattern = "^get%s+rid%s+of%s+(.+)$",          replacement = "drop %1" },
    { pattern = "^make%s+use%s+of%s+(.+)$",         replacement = "use %1" },
    { pattern = "^go%s+to%s+sleep$",                replacement = "sleep" },
    { pattern = "^lay%s+down$",                     replacement = "sleep" },
    { pattern = "^lie%s+down$",                     replacement = "sleep" },
    -- #42: "sleep to/til/till dawn" → "sleep until dawn"
    { pattern = "^sleep%s+to%s+(.+)$",             replacement = "sleep until %1" },
    { pattern = "^sleep%s+til%s+(.+)$",            replacement = "sleep until %1" },
    { pattern = "^sleep%s+till%s+(.+)$",           replacement = "sleep until %1" },
}

-- Expose for external extension
preprocess.IDIOM_TABLE = IDIOM_TABLE

--- Stage: expand_idioms
--- Expand common English idioms into canonical game commands.
local function expand_idioms(text)
    for _, idiom in ipairs(IDIOM_TABLE) do
        local new_text = text:gsub(idiom.pattern, idiom.replacement)
        if new_text ~= text then
            return new_text, true
        end
    end
    return text
end

--- Stage: transform_questions
--- Convert question patterns into imperative commands.
local function transform_questions(text)
    -- #38: Hand-specific "what's in my hands" → inventory (BUG-130)
    -- Must come before generic "what's in X" → "examine X" container query
    if text:match("^what'?s%s+in%s+my%s+hands")
        or text:match("^what%s+is%s+in%s+my%s+hands") then
        return "inventory"
    end

    -- "what's in the X" → "examine X"
    local whats_in = text:match("^what'?s%s+in%s+the%s+(.+)$")
        or text:match("^what'?s%s+in%s+(.+)$")
    if whats_in then
        return "examine " .. whats_in
    end

    -- "is there anything in X" → "search X"
    local is_anything_in = text:match("^is%s+there%s+anything%s+in%s+(.+)$")
    if is_anything_in then
        return "search " .. is_anything_in
    end

    -- Issue #23: Existence questions → search
    -- "is there a/an X in the room/here/nearby/around?" → "search X"
    local is_there_in = text:match("^is%s+there%s+an?%s+(.-)%s+in%s+the%s+room$")
        or text:match("^is%s+there%s+an?%s+(.-)%s+here$")
        or text:match("^is%s+there%s+an?%s+(.-)%s+nearby$")
        or text:match("^is%s+there%s+an?%s+(.-)%s+around$")
    if is_there_in then
        return "search " .. is_there_in
    end

    -- "is there a/an X?" → "search X" (bare existence question)
    local is_there_bare = text:match("^is%s+there%s+an?%s+(.+)$")
    if is_there_bare then
        return "search " .. is_there_bare
    end

    -- "do you see a/an X?" → "search X"
    local do_you_see = text:match("^do%s+you%s+see%s+an?%s+(.+)$")
    if do_you_see then
        return "search " .. do_you_see
    end

    -- "can I find a/an X?" → "search X" (specific override before generic "can I verb")
    local can_i_find = text:match("^can%s+i%s+find%s+an?%s+(.+)$")
        or text:match("^can%s+i%s+find%s+(.+)$")
    if can_i_find then
        return "search " .. can_i_find
    end

    -- "can I verb target" → "verb target" (strip question wrapper)
    local can_i_verb, can_i_target = text:match("^can%s+i%s+(%w+)%s+(.+)$")
    if can_i_verb and can_i_target then
        return can_i_verb .. " " .. can_i_target
    end

    -- "what is this" / "what's this" → "look" (BUG-104: "examine this" hung
    -- on unresolved pronoun; "look" is safe without context resolution)
    if text:match("^what%s+is%s+this$") or text:match("^what'?s%s+this$") then
        return "look"
    end

    -- "what can I find" → "search" (BUG-084)
    if text:match("^what%s+can%s+i%s+find") then
        return "search"
    end

    -- "where is the X" → "find X" (BUG-110: "search for X" was interpreted
    -- as scope search on the object rather than searching FOR the object)
    local where_is_target = text:match("^where%s+is%s+the%s+(.+)$")
        or text:match("^where%s+is%s+(.+)$")
        or text:match("^where'?s%s+the%s+(.+)$")
        or text:match("^where'?s%s+(.+)$")
    if where_is_target then
        return "find " .. where_is_target
    end

    -- #36: Bleeding/injury severity questions → injuries
    -- MUST come before "where am I" → look to avoid false match (BUG-128)
    if text:match("^where%s+am%s+i%s+bleeding")
        or text:match("^how%s+bad%s+is%s+it")
        or text:match("^how%s+bad%s+are%s+")
        or text:match("^why%s+don'?t%s+i%s+feel%s+well")
        or text:match("^why%s+don'?t%s+i%s+feel%s+good") then
        return "injuries"
    end

    -- #35: Health/status inquiry phrases → health (BUG-127)
    if text == "status"
        or text:match("^how%s+am%s+i")
        or text:match("^am%s+i%s+hurt")
        or text:match("^am%s+i%s+injured")
        or text:match("^am%s+i%s+ok")
        or text:match("^am%s+i%s+alright")
        or text:match("^what'?s%s+wrong%s+with%s+me")
        or text:match("^what%s+is%s+wrong%s+with%s+me")
        or text:match("^check%s+my%s+wounds")
        or text:match("^check%s+my%s+injuries")
        or text:match("^check%s+my%s+health") then
        return "health"
    end

    -- "what is around" / "what do I see" / "where am I" → "look"
    -- BUG-037: added "what's around me" pattern
    if text:match("^what%s+is%s+around")
        or text:match("^what'?s%s+around")
        or text:match("^what%s+do%s+i%s+see")
        or text:match("^what%s+can%s+i%s+see")
        or text:match("^where%s+am%s+i") then
        return "look"
    end

    -- Question patterns → time
    if text:match("^what%s+time")
        or text:match("^what%s+is%s+the%s+time") then
        return "time"
    end

    -- Question patterns → inventory (BUG-038)
    -- #38: Added hand/holding queries (BUG-130)
    if text:match("^what%s+am%s+i%s+carry")
        or text:match("^what%s+am%s+i%s+hold")
        or text:match("^what%s+do%s+i%s+have")
        or text:match("^what'?s%s+in%s+my%s+hands")
        or text:match("^what%s+is%s+in%s+my%s+hands")
        or text:match("^am%s+i%s+holding%s+anything")
        or text:match("^am%s+i%s+holding%s+something") then
        return "inventory"
    end

    -- Container queries with noun: "what's in X", "what is inside X"
    local container_noun = text:match("^what'?s%s+in%s+(.+)")
        or text:match("^what%s+is%s+in%s+(.+)")
        or text:match("^what'?s%s+inside%s+(.+)")
        or text:match("^what%s+is%s+inside%s+(.+)")
    if container_noun then
        return "examine " .. container_noun
    end

    -- Bare "what's inside" (no noun) → examine last-referenced container (#89)
    if text:match("^what'?s%s+inside$")
        or text:match("^what%s+is%s+inside$") then
        return "examine it"
    end

    -- "what is X" / "what's the X" → "examine X" (P3: prevents Tier 2 mismatch)
    local what_noun = text:match("^what%s+is%s+the%s+(.+)$")
        or text:match("^what'?s%s+the%s+(.+)$")
        or text:match("^what%s+is%s+an?%s+(.+)$")
        or text:match("^what%s+is%s+(.+)$")
        or text:match("^what'?s%s+(.+)$")
    if what_noun then
        return "examine " .. what_noun
    end

    -- Question patterns → help
    if text:match("^what%s+can%s+i%s+do")
        or text:match("^what%s+do%s+i%s+do")
        or text:match("^what%s+should%s+i%s+do")
        or text:match("^what%s+now$")
        or text:match("^now%s+what$")
        or text:match("^how%s+do%s+i") then
        return "help"
    end

    -- "what am I wearing" → "inventory"
    if text:match("^what%s+am%s+i%s+wear") then
        return "inventory"
    end

    return text
end

--- Stage: transform_look_patterns
--- Normalize look/check/look-for into canonical verbs.
local function transform_look_patterns(text)
    -- "look around" → "look" (BUG-037)
    if text:match("^look%s+around$") then
        return "look"
    end

    -- #37: Self-referential look/examine/check → appearance (BUG-129)
    -- Must come before generic "look at X" → "examine X"
    if text:match("^look%s+at%s+myself$")
        or text:match("^look%s+at%s+self$")
        or text:match("^look%s+at%s+me$")
        or text:match("^examine%s+myself$")
        or text:match("^examine%s+self$")
        or text:match("^examine%s+me$")
        or text:match("^check%s+myself$")
        or text:match("^check%s+self$") then
        return "appearance"
    end

    -- #38: "look at my hands" → inventory (BUG-130)
    if text:match("^look%s+at%s+my%s+hands") then
        return "inventory"
    end

    -- BUG-087: "look at X" → "examine X"
    local look_at_target = text:match("^look%s+at%s+(.+)")
    if look_at_target then
        return "examine " .. look_at_target
    end

    -- BUG-086: "check X" → "examine X"
    local check_target = text:match("^check%s+(.+)")
    if check_target then
        return "examine " .. check_target
    end

    -- BUG-118: "peek behind/at/through/in/into/around X" → "examine X"
    -- "peek" (bare) → "look"
    if text == "peek" then
        return "look"
    end
    local peek_target = text:match("^peek%s+behind%s+(.+)")
        or text:match("^peek%s+at%s+(.+)")
        or text:match("^peek%s+through%s+(.+)")
        or text:match("^peek%s+into%s+(.+)")
        or text:match("^peek%s+in%s+(.+)")
        or text:match("^peek%s+around%s+(.+)")
        or text:match("^peek%s+under%s+(.+)")
    if peek_target then
        return "examine " .. peek_target
    end

    -- BUG-112: "look under/underneath/beneath X" → "examine X"
    -- "look under" is not a recognized verb pattern in its own right; without
    -- this transform, the input falls through to Tier 2 search which can hang
    -- on unresolved pronouns. Route to "examine" which safely handles objects.
    local look_under_target = text:match("^look%s+under%s+(.+)")
        or text:match("^look%s+underneath%s+(.+)")
        or text:match("^look%s+beneath%s+(.+)")
    if look_under_target then
        return "examine " .. look_under_target
    end

    -- BUG-074: "look for X" → "find X" (BUG-081: strip articles)
    local look_for_target = text:match("^look%s+for%s+(.+)")
    if look_for_target then
        return "find " .. preprocess.strip_articles(look_for_target)
    end

    return text
end

--- Stage: transform_search_phrases
--- Normalize search/hunt/rummage/find/feel compound phrases.
--- Returns (text, true) on match — some patterns produce identical output
--- (e.g., "search around" is already canonical) but still count as recognized.
---
--- BUG-111: Singularize target nouns so "matches" → "match" for better
--- substring matching against game objects (e.g., "matchbox").
local function singularize_target(noun)
    local forms = singularize_word(noun)
    if #forms > 0 then return forms[1] end
    return noun
end

local function transform_search_phrases(text)
    -- Grope/feel compound phrases → "feel" (room sweep)
    if text:match("^grope%s+around%s+")
        or text:match("^feel%s+around%s+") then
        return "feel", true
    end

    -- "search around" → "search around"
    if text:match("^search%s+around%s*") then
        return "search around", true
    end

    -- "search [scope] for [target]" (BUG-081: strip articles)
    local search_scope_for = text:match("^search%s+(.+)%s+for%s+(.+)")
    if search_scope_for then
        local raw = text:match("^search%s+(.+)$")
        local scope_raw, target_raw = raw:match("^(.-)%s+for%s+(.+)$")
        if scope_raw and target_raw then
            return "search " .. preprocess.strip_articles(scope_raw)
                .. " for " .. preprocess.strip_articles(target_raw), true
        end
        return "search " .. raw, true
    end

    -- "search for [target]" (BUG-081, BUG-078: everything/anything/all → sweep)
    -- BUG-111: singularize target for better fuzzy matching
    local search_target = text:match("^search%s+for%s+(.+)")
    if search_target then
        local stripped = preprocess.strip_articles(search_target)
        if stripped == "everything" or stripped == "anything" or stripped == "all" then
            return "search", true
        end
        return "search " .. singularize_target(stripped), true
    end

    -- "hunt for [target]" / "hunt around" → search (BUG-081, BUG-111)
    local hunt_target = text:match("^hunt%s+for%s+(.+)")
    if hunt_target then
        return "search " .. singularize_target(preprocess.strip_articles(hunt_target)), true
    end
    if text:match("^hunt%s+around%s*") then
        return "search around", true
    end

    -- "rummage" and all forms → search (BUG-081, BUG-093, BUG-111)
    local rummage_target = text:match("^rummage%s+for%s+(.+)")
    if rummage_target then
        return "search " .. singularize_target(preprocess.strip_articles(rummage_target)), true
    end
    local rummage_through = text:match("^rummage%s+through%s+(.+)")
    if rummage_through then
        return "search " .. rummage_through, true
    end
    if text:match("^rummage%s+around%s*") then
        return "search around", true
    end
    if text:match("^rummage$") then
        return "search around", true
    end
    local rummage_scope = text:match("^rummage%s+(.+)")
    if rummage_scope then
        return "search " .. preprocess.strip_articles(rummage_scope), true
    end

    -- "find [target] in [scope]" (BUG-081: strip articles)
    local find_in = text:match("^find%s+(.+)%s+in%s+(.+)")
    if find_in then
        local raw = text:match("^find%s+(.+)$")
        local target_raw, scope_raw = raw:match("^(.-)%s+in%s+(.+)$")
        if target_raw and scope_raw then
            return "find " .. preprocess.strip_articles(target_raw)
                .. " in " .. preprocess.strip_articles(scope_raw), true
        end
        return "find " .. raw, true
    end

    -- "find [target]" (BUG-081, BUG-078: everything/anything/all → sweep, BUG-111)
    local find_target = text:match("^find%s+(.+)")
    if find_target then
        local stripped = preprocess.strip_articles(find_target)
        if stripped == "everything" or stripped == "anything" or stripped == "all" then
            return "search", true
        end
        return "find " .. singularize_target(stripped), true
    end

    return text
end

--- Stage: transform_compound_actions
--- Normalize compound verb phrases (pry open, use X on Y, put/take, etc.)
-- #142, #143, #146, #157: Hit/drop synonym verb sets
local HIT_SYNONYMS = { smack=true, bang=true, slap=true, whack=true }

local function transform_compound_actions(text)
    -- #142, #157: Simple hit synonyms (smack, bang, slap, whack) → hit
    local first_word = text:match("^(%S+)")
    if first_word and HIT_SYNONYMS[first_word] then
        return "hit" .. text:sub(#first_word + 1)
    end

    -- #144: "hurt X" → "hit X" (abstract pain phrases)
    local hurt_target = text:match("^hurt%s+(.+)$")
    if hurt_target then
        return "hit " .. hurt_target
    end

    -- #144: "beat X up" / "beat up X" → "hit X"
    local beat_up_target = text:match("^beat%s+(.+)%s+up$")
    if beat_up_target then
        return "hit " .. beat_up_target
    end
    local beat_up_target2 = text:match("^beat%s+up%s+(.+)$")
    if beat_up_target2 then
        return "hit " .. beat_up_target2
    end

    -- #143: headbutt always targets head
    if text:match("^headbutt") then
        return "hit head"
    end

    -- #146: bonk defaults to head when self-target or bare
    if text == "bonk" then return "hit head" end
    local bonk_noun = text:match("^bonk%s+(.+)$")
    if bonk_noun then
        local cleaned = bonk_noun:gsub("^my%s+", ""):gsub("^your%s+", "")
        if cleaned == "myself" or cleaned == "self" or cleaned == "me"
            or cleaned == "yourself" then
            return "hit head"
        end
        return "hit " .. bonk_noun
    end

    -- #112: wash synonyms: "clean X" / "rinse X" / "scrub X" → "wash X"
    -- Handle "with Y" and "in Y" prepositions for synonyms before bare conversion
    local WASH_SYNONYMS = { clean=true, rinse=true, scrub=true, wash=true }
    if first_word and WASH_SYNONYMS[first_word] then
        local rest = text:sub(#first_word + 1)
        -- "verb X in Y" → "wash X in Y"
        local item_in, target_in = rest:match("^%s+(.+)%s+in%s+(.+)$")
        if item_in then
            return "wash " .. item_in .. " in " .. target_in
        end
        -- "verb X with Y" → "wash X in Y"
        local item_w, target_w = rest:match("^%s+(.+)%s+with%s+(.+)$")
        if item_w then
            return "wash " .. item_w .. " in " .. target_w
        end
        -- bare synonym → "wash X"
        if first_word ~= "wash" then
            return "wash" .. rest
        end
    end

    -- #108: "pour X into Y" / "pour X in Y" → canonical "pour X into Y"
    local pour_item, pour_target = text:match("^pour%s+(.+)%s+into%s+(.+)$")
    if not pour_item then
        pour_item, pour_target = text:match("^pour%s+(.+)%s+in%s+(.+)$")
    end
    if pour_item then
        return "pour " .. pour_item .. " into " .. pour_target
    end

    -- #108: "fill Y with X" → "pour X into Y" (reverse syntax)
    local fill_target, fill_source = text:match("^fill%s+(.+)%s+with%s+(.+)$")
    if fill_target and fill_source then
        return "pour " .. fill_source .. " into " .. fill_target
    end

    -- #109: "apply X to Y" — canonical form passes through unchanged
    local apply_item, apply_target = text:match("^apply%s+(.+)%s+to%s+(.+)$")
    if apply_item then
        return "apply " .. apply_item .. " to " .. apply_target
    end

    -- #109: "rub X on/to Y" → "apply X to Y"
    local rub_item, rub_target = text:match("^rub%s+(.+)%s+on%s+(.+)$")
    if not rub_item then
        rub_item, rub_target = text:match("^rub%s+(.+)%s+to%s+(.+)$")
    end
    if not rub_item then
        rub_item, rub_target = text:match("^rub%s+(.+)%s+into%s+(.+)$")
    end
    if rub_item then
        return "apply " .. rub_item .. " to " .. rub_target
    end

    -- BUG-049: "pry open X" / "pry open X with Y" → "open X" / "open X with Y"
    local pry_target = text:match("^pry%s+open%s+(.+)")
    if pry_target then
        return "open " .. pry_target
    end

    -- BUG-049: "pry X with Y" → "open X with Y" (tool-assisted pry)
    local pry_noun, pry_tool = text:match("^pry%s+(.+)%s+with%s+(.+)$")
    if pry_noun and pry_tool then
        return "open " .. pry_noun .. " with " .. pry_tool
    end

    -- "force open X" → "open X"
    local force_target = text:match("^force%s+open%s+(.+)")
    if force_target then
        return "open " .. force_target
    end

    -- "use crowbar/bar on X" → "open X"
    local crowbar_target = text:match("^use%s+crowbar%s+on%s+(.+)")
        or text:match("^use%s+bar%s+on%s+(.+)")
        or text:match("^use%s+pry%s*bar%s+on%s+(.+)")
    if crowbar_target then
        return "open " .. crowbar_target
    end

    -- "report bug" / "report a bug" → "report_bug"
    if text:match("^report%s+a?%s*bug")
        or text:match("^bug%s+report")
        or text:match("^file%s+a?%s*bug") then
        return "report_bug"
    end

    -- "take out X", "pull out X", "yank out X" → "pull X"
    local pull_target = text:match("^take%s+out%s+(.+)")
        or text:match("^pull%s+out%s+(.+)")
        or text:match("^yank%s+out%s+(.+)")
    if pull_target then
        return "pull " .. pull_target
    end

    -- BUG-113: "pick up" (bare, no target) → "take" so loop context fallback kicks in
    if text == "pick up" then
        return "take"
    end

    -- "roll up X" → "move X"
    local roll_target = text:match("^roll%s+up%s+(.+)")
        or text:match("^roll%s+(.+)%s+up$")
    if roll_target then
        return "move " .. roll_target
    end

    -- "pull back X" → "move X"
    local pullback_target = text:match("^pull%s+back%s+(.+)")
    if pullback_target then
        return "move " .. pullback_target
    end

    -- "pop cork" → "uncork bottle"
    local uncork_target = text:match("^pop%s+(.+)")
    if uncork_target and uncork_target:match("cork") then
        return "uncork bottle"
    end

    -- "use X on Y" → dispatch by tool type (BUG-039)
    local use_tool, use_target = text:match("^use%s+(.+)%s+on%s+(.+)$")
    if use_tool and use_target then
        if use_tool:match("needle") or use_tool:match("thread") then
            return "sew " .. use_target .. " with " .. use_tool
        end
        if use_tool:match("key") then
            return "unlock " .. use_target .. " with " .. use_tool
        end
        if use_tool:match("match") or use_tool:match("lighter")
            or use_tool:match("flint") or use_tool:match("torch")
            or use_tool:match("fire") or use_tool:match("flame") then
            return "light " .. use_target .. " with " .. use_tool
        end
        -- #109: default "use X on Y" → apply (application semantics)
        return "apply " .. use_tool .. " to " .. use_target
    end

    -- #83: Placement verb aliases → put
    -- "set X in/on/under Y" → "put X in/on/under Y" (but NOT "set fire to" or "set clock")
    local set_item, set_prep, set_target = text:match("^set%s+(.+)%s+(in)%s+(.+)$")
    if not set_item then
        set_item, set_prep, set_target = text:match("^set%s+(.+)%s+(on)%s+(.+)$")
    end
    if not set_item then
        set_item, set_prep, set_target = text:match("^set%s+(.+)%s+(under)%s+(.+)$")
    end
    if not set_item then
        set_item, set_prep, set_target = text:match("^set%s+(.+)%s+(inside)%s+(.+)$")
    end
    if not set_item then
        set_item, set_prep, set_target = text:match("^set%s+(.+)%s+(underneath)%s+(.+)$")
    end
    if not set_item then
        set_item, set_prep, set_target = text:match("^set%s+(.+)%s+(beneath)%s+(.+)$")
    end
    if set_item then
        return "put " .. set_item .. " " .. set_prep .. " " .. set_target
    end

    -- "drop X on/in Y" → "put X on/in Y" (bare "drop X" stays as drop)
    local drop_item, drop_prep, drop_target = text:match("^drop%s+(.+)%s+(on)%s+(.+)$")
    if not drop_item then
        drop_item, drop_prep, drop_target = text:match("^drop%s+(.+)%s+(in)%s+(.+)$")
    end
    if not drop_item then
        drop_item, drop_prep, drop_target = text:match("^drop%s+(.+)%s+(under)%s+(.+)$")
    end
    if not drop_item then
        drop_item, drop_prep, drop_target = text:match("^drop%s+(.+)%s+(inside)%s+(.+)$")
    end
    if drop_item then
        return "put " .. drop_item .. " " .. drop_prep .. " " .. drop_target
    end

    -- "hide X under/in/inside Y" → "put X under/in/inside Y"
    local hide_item, hide_prep, hide_target = text:match("^hide%s+(.+)%s+(under)%s+(.+)$")
    if not hide_item then
        hide_item, hide_prep, hide_target = text:match("^hide%s+(.+)%s+(underneath)%s+(.+)$")
    end
    if not hide_item then
        hide_item, hide_prep, hide_target = text:match("^hide%s+(.+)%s+(beneath)%s+(.+)$")
    end
    if not hide_item then
        hide_item, hide_prep, hide_target = text:match("^hide%s+(.+)%s+(in)%s+(.+)$")
    end
    if not hide_item then
        hide_item, hide_prep, hide_target = text:match("^hide%s+(.+)%s+(inside)%s+(.+)$")
    end
    if hide_item then
        return "put " .. hide_item .. " " .. hide_prep .. " " .. hide_target
    end

    -- "stuff X in/inside/into Y" → "put X in Y"
    local stuff_item, stuff_target = text:match("^stuff%s+(.+)%s+in%s+(.+)$")
    if not stuff_item then
        stuff_item, stuff_target = text:match("^stuff%s+(.+)%s+inside%s+(.+)$")
    end
    if not stuff_item then
        stuff_item, stuff_target = text:match("^stuff%s+(.+)%s+into%s+(.+)$")
    end
    if stuff_item then
        return "put " .. stuff_item .. " in " .. stuff_target
    end

    -- #141: "toss/throw X on/onto/in/into Y" → "put X on/in Y" (placement)
    -- Bare "toss/throw X" (no preposition) → "drop X"
    for _, toss_verb in ipairs({"toss", "throw"}) do
        local toss_rest = text:match("^" .. toss_verb .. "%s+(.+)$")
        if toss_rest then
            -- Check for placement prepositions first
            local t_item, t_target
            t_item, t_target = toss_rest:match("^(.+)%s+onto%s+(.+)$")
            if t_item then return "put " .. t_item .. " on " .. t_target end
            t_item, t_target = toss_rest:match("^(.+)%s+into%s+(.+)$")
            if t_item then return "put " .. t_item .. " in " .. t_target end
            t_item, t_target = toss_rest:match("^(.+)%s+on%s+(.+)$")
            if t_item then return "put " .. t_item .. " on " .. t_target end
            t_item, t_target = toss_rest:match("^(.+)%s+in%s+(.+)$")
            if t_item then return "put " .. t_item .. " in " .. t_target end
            -- No preposition → drop
            return "drop " .. toss_rest
        end
    end

    -- "slide X under/into Y" → "put X under/in Y"
    local slide_item, slide_target = text:match("^slide%s+(.+)%s+under%s+(.+)$")
    if slide_item then
        return "put " .. slide_item .. " under " .. slide_target
    end
    slide_item, slide_target = text:match("^slide%s+(.+)%s+underneath%s+(.+)$")
    if slide_item then
        return "put " .. slide_item .. " under " .. slide_target
    end
    slide_item, slide_target = text:match("^slide%s+(.+)%s+into%s+(.+)$")
    if slide_item then
        return "put " .. slide_item .. " in " .. slide_target
    end

    -- "push X back" → "put X in X"
    local push_back_target = text:match("^push%s+(.+)%s+back")
    if push_back_target then
        return "put " .. push_back_target .. " in " .. push_back_target
    end

    -- #111: "heave X up" → "lift X"; "heave up X" → "lift X"
    local heave_target = text:match("^heave%s+(.+)%s+up$")
    if heave_target then return "lift " .. heave_target end
    heave_target = text:match("^heave%s+up%s+(.+)$")
    if heave_target then return "lift " .. heave_target end

    -- #111: "drag X across/along" → "move X"
    local drag_target = text:match("^drag%s+(.+)%s+across$")
    if drag_target then return "move " .. drag_target end
    drag_target = text:match("^drag%s+(.+)%s+along$")
    if drag_target then return "move " .. drag_target end

    -- #111: "shove X aside/away/over" → "push X" (strip suffix for push handler)
    local shove_target = text:match("^shove%s+(.+)%s+aside$")
        or text:match("^shove%s+(.+)%s+away$")
        or text:match("^shove%s+(.+)%s+over$")
    if shove_target then return "push " .. shove_target end

    -- #111: "nudge X aside/over" → "push X"
    local nudge_target = text:match("^nudge%s+(.+)%s+aside$")
        or text:match("^nudge%s+(.+)%s+over$")
    if nudge_target then return "push " .. nudge_target end

    -- "put X back in Y" → "put X in Y"
    local put_back_item, put_back_target2 = text:match("^put%s+(.+)%s+back%s+in%s+(.+)")
    if put_back_item then
        return "put " .. put_back_item .. " in " .. put_back_target2
    end

    -- "put out X", "blow out X" → "extinguish X"
    local extinguish_target = text:match("^put%s+out%s+(.+)")
        or text:match("^blow%s+out%s+(.+)")
    if extinguish_target then
        return "extinguish " .. extinguish_target
    end

    -- #154: "put X on (my) body_part" → "wear X" (body placement = wearing)
    local put_wear_item, put_wear_part
    put_wear_item, put_wear_part = text:match("^put%s+(.+)%s+on%s+my%s+(%S+)$")
    if not put_wear_item then
        put_wear_item, put_wear_part = text:match("^put%s+(.+)%s+on%s+(%S+)$")
    end
    if put_wear_item and put_wear_part and BODY_PARTS[put_wear_part] then
        return "wear " .. put_wear_item
    end

    -- "put on X", "dress in X" → "wear X"
    local wear_target = text:match("^put%s+on%s+(.+)")
        or text:match("^dress%s+in%s+(.+)")
    if wear_target then
        return "wear " .. wear_target
    end

    -- "take off X" → "remove X"
    local remove_target = text:match("^take%s+off%s+(.+)")
    if remove_target then
        return "remove " .. remove_target
    end

    return text
end

--- Stage: transform_movement
--- Normalize sleep, stair, clock, and return/go-back phrases.
local function transform_movement(text)
    -- Tier 4: "go back" / "return" → canonical "go back"
    if text == "go back" or text == "go back to where i was" then
        return "go back", true
    end
    if text:match("^go%s+back%s+to%s+") then
        return "go back", true
    end
    if text == "return" then
        return "go back", true
    end
    if text:match("^return%s+to%s+where%s+i%s+was")
        or text:match("^return%s+to%s+the%s+previous%s+room")
        or text:match("^return%s+to%s+previous%s+room") then
        return "go back", true
    end
    if text:match("^retrace%s+my%s+steps") or text:match("^retrace%s+steps") then
        return "go back", true
    end

    -- Sleep phrases
    if text:match("^take%s+a%s+nap") then
        return "sleep"
    end
    local go_sleep_noun = text:match("^go%s+to%s+sleep%s*(.*)")
    if go_sleep_noun then
        if go_sleep_noun == "" then return "sleep" end
        return "sleep " .. go_sleep_noun
    end
    if text:match("^go%s+to%s+bed") then
        return "sleep"
    end
    if text:match("^lie%s+down") then
        return "sleep"
    end

    -- Stair movement
    if text:match("^go%s+down%s+the%s+stair")
        or text:match("^climb%s+down%s+the%s+stair")
        or text:match("^descend%s+the%s+stair")
        or text:match("^descend%s+stair") then
        return "down"
    end
    if text:match("^go%s+up%s+the%s+stair")
        or text:match("^climb%s+up%s+the%s+stair")
        or text:match("^ascend%s+the%s+stair")
        or text:match("^ascend%s+stair") then
        return "up"
    end

    -- Clock adjustment: "turn hands", "adjust clock", "set clock"
    local clock_target = text:match("^turn%s+hands%s*(.*)$")
        or text:match("^turn%s+the%s+hands%s*(.*)$")
    if clock_target then
        local target = clock_target ~= "" and clock_target or "clock"
        return "set " .. target
    end
    if text:match("^adjust%s+the%s+clock") or text:match("^adjust%s+clock") then
        return "set clock"
    end
    if text:match("^set%s+the%s+clock") or text:match("^set%s+clock") then
        return "set clock"
    end

    return text
end

---------------------------------------------------------------------------
-- Pipeline Definition
-- Ordered table of transform stages. Externally accessible for extension.
-- Adding a new stage: table.insert(preprocess.pipeline, N, my_transform)
-- Disabling a stage: table.remove(preprocess.pipeline, N)
---------------------------------------------------------------------------

preprocess.pipeline = {
    normalize,                -- Trim, lowercase, strip question marks
    strip_filler,             -- Iterative: preambles + politeness + adverbs
    strip_noun_modifiers,     -- Issue #14: whole/entire/every/all-of-the
    strip_decorative_prepositions, -- #154: "on my head", "in the mirror", "as a hat"
    expand_idioms,            -- Tier 3: common English phrases → canonical commands
    transform_questions,      -- Question patterns → imperative commands
    transform_look_patterns,  -- look at/for/around, check → canonical verbs
    transform_search_phrases, -- search/hunt/rummage/find compounds
    transform_compound_actions, -- pry, use X on Y, put/take, pull, wear
    transform_movement,       -- sleep, stairs, clock, go back/return
    strip_possessives,        -- #67: your/my before noun phrases (AFTER phrase routing)
}

-- Expose individual stage functions for testing and reuse
preprocess.stages = {
    normalize = normalize,
    strip_politeness = strip_politeness,
    strip_adverbs = strip_adverbs,
    strip_preambles = strip_preambles,
    strip_gerunds = strip_gerunds,
    strip_filler = strip_filler,
    strip_possessives = strip_possessives,
    strip_noun_modifiers = strip_noun_modifiers,
    strip_decorative_prepositions = strip_decorative_prepositions,
    expand_idioms = expand_idioms,
    transform_questions = transform_questions,
    transform_look_patterns = transform_look_patterns,
    transform_search_phrases = transform_search_phrases,
    transform_compound_actions = transform_compound_actions,
    transform_movement = transform_movement,
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
    local original = normalize(input)
    if matched or text ~= original then
        return preprocess.parse(text)
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
    if not input then return {} end
    local trimmed = input:match("^%s*(.-)%s*$")
    if trimmed == "" then return {} end

    local lower = trimmed:lower()

    -- Fast path: no separators at all → single command
    if not trimmed:find("[,;]")
        and not lower:find("%f[%a]then%f[%A]")
        and not lower:find("%f[%a]and then%f[%A]") then
        return { trimmed }
    end

    -- Tokenise respecting double-quoted regions
    local segments = {}
    local current = {}
    local in_quote = false
    local i = 1
    local len = #trimmed

    while i <= len do
        local ch = trimmed:sub(i, i)

        -- Toggle quote state
        if ch == '"' then
            in_quote = not in_quote
            current[#current + 1] = ch
            i = i + 1

        -- " and then " compound separator (outside quotes, must check before "then")
        elseif not in_quote and lower:sub(i, i + 9) == " and then " then
            local seg = table.concat(current):match("^%s*(.-)%s*$")
            if seg ~= "" then segments[#segments + 1] = seg end
            current = {}
            i = i + 10  -- skip " and then "

        -- " then " word separator (outside quotes)
        elseif not in_quote and lower:sub(i, i + 5) == " then " then
            local seg = table.concat(current):match("^%s*(.-)%s*$")
            if seg ~= "" then segments[#segments + 1] = seg end
            current = {}
            i = i + 6  -- skip " then "

        -- Comma or semicolon separator (outside quotes)
        elseif not in_quote and (ch == ',' or ch == ';') then
            local seg = table.concat(current):match("^%s*(.-)%s*$")
            if seg ~= "" then segments[#segments + 1] = seg end
            current = {}
            i = i + 1

        else
            current[#current + 1] = ch
            i = i + 1
        end
    end

    -- Flush last segment
    local seg = table.concat(current):match("^%s*(.-)%s*$")
    if seg ~= "" then segments[#segments + 1] = seg end

    -- Strip leading "and " from segments (left over after comma-and splitting)
    for si = 1, #segments do
        local s = segments[si]
        local stripped = s:match("^[Aa][Nn][Dd]%s+(.+)$")
        if stripped then
            segments[si] = stripped:match("^%s*(.-)%s*$")
        end
    end

    -- Drop any segments that became empty after stripping
    local cleaned = {}
    for _, s in ipairs(segments) do
        if s ~= "" then cleaned[#cleaned + 1] = s end
    end

    -- If splitting produced nothing useful, return original as single command
    if #cleaned == 0 then return { trimmed } end
    return cleaned
end

---------------------------------------------------------------------------
-- Issue #168: Verb-aware "and" splitting for compound commands.
-- Only splits "X and Y" when Y starts with a recognized verb.
-- "get candle and matchbox" → stays as one command (matchbox isn't a verb)
-- "take key and unlock door" → splits (unlock IS a verb)
---------------------------------------------------------------------------
local KNOWN_VERBS = {
    -- sensory
    look = true, examine = true, x = true, inspect = true, check = true,
    feel = true, touch = true, grope = true, smell = true, sniff = true,
    taste = true, lick = true, listen = true, hear = true, read = true,
    search = true, find = true,
    -- acquisition
    take = true, get = true, pick = true, grab = true, drop = true,
    pull = true, yank = true, tug = true, extract = true,
    push = true, shove = true, nudge = true,
    move = true, shift = true, drag = true, slide = true,
    lift = true, heave = true, uncork = true, unstop = true, unseal = true,
    -- containers
    open = true, close = true, shut = true, pry = true,
    unlock = true, lock = true,
    -- equipment
    wear = true, don = true, remove = true, doff = true,
    -- crafting
    write = true, inscribe = true, sew = true, stitch = true, mend = true,
    put = true, place = true,
    -- combat
    stab = true, jab = true, pierce = true, stick = true,
    hit = true, punch = true, bash = true, bonk = true, thump = true,
    smack = true, bang = true, slap = true, whack = true, headbutt = true,
    toss = true, throw = true, cut = true, slice = true, nick = true,
    slash = true, carve = true, prick = true,
    -- destruction
    ["break"] = true, smash = true, shatter = true, tear = true, rip = true,
    -- fire
    light = true, ignite = true, relight = true,
    extinguish = true, snuff = true, strike = true, burn = true,
    -- survival
    eat = true, consume = true, devour = true,
    drink = true, quaff = true, sip = true,
    pour = true, spill = true, dump = true, fill = true,
    wash = true, clean = true, rinse = true, scrub = true,
    sleep = true, rest = true, nap = true,
    -- movement
    go = true, walk = true, run = true, head = true, travel = true,
    enter = true, climb = true, ascend = true, descend = true,
    back = true, ["return"] = true,
    north = true, south = true, east = true, west = true,
    up = true, down = true, n = true, s = true, e = true, w = true,
    -- meta
    inventory = true, i = true, time = true, set = true, adjust = true,
    help = true, wait = true, pass = true, use = true, utilize = true,
    apply = true, treat = true, appearance = true, quit = true,
}

--- split_compound(input) -> list of command strings
--- Verb-aware splitting on " and " — only splits when the word after "and"
--- is a recognized verb. Prevents breaking multi-object commands like
--- "get candle and matchbox" while splitting "take key and unlock door".
function preprocess.split_compound(input)
    if not input then return {} end
    local trimmed = input:match("^%s*(.-)%s*$")
    if trimmed == "" then return {} end

    local lower = trimmed:lower()
    if not lower:find("%s+and%s+") then
        return { trimmed }
    end

    local results = {}
    local remaining = trimmed
    local safety = 0

    while true do
        safety = safety + 1
        if safety > 50 then break end

        local lower_rem = remaining:lower()
        local best_pos = nil

        -- Find all " and " positions; pick the first one where the next word is a verb
        local search_start = 1
        while true do
            local and_start, and_end = lower_rem:find("%s+and%s+", search_start)
            if not and_start then break end

            local after = remaining:sub(and_end + 1)
            local next_word = after:match("^(%S+)")
            if next_word and KNOWN_VERBS[next_word:lower()] then
                best_pos = { start = and_start, finish = and_end }
                break
            end
            search_start = and_end + 1
        end

        if not best_pos then
            local r = remaining:match("^%s*(.-)%s*$")
            if r ~= "" then results[#results + 1] = r end
            break
        end

        local before = remaining:sub(1, best_pos.start - 1):match("^%s*(.-)%s*$")
        if before ~= "" then results[#results + 1] = before end
        remaining = remaining:sub(best_pos.finish + 1)
    end

    if #results == 0 then return { trimmed } end
    return results
end

--- singularize(noun) -> table of singular form candidates
--- For multi-word nouns, also tries singularizing the last word.
function preprocess.singularize(noun)
    if not noun or #noun < 3 then return {} end
    noun = noun:lower()
    local forms = singularize_word(noun)
    -- Multi-word: also try singularizing just the last word
    local prefix, last = noun:match("^(.+%s)(%S+)$")
    if prefix then
        for _, s in ipairs(singularize_word(last)) do
            forms[#forms+1] = prefix .. s
        end
    end
    return forms
end

return preprocess
