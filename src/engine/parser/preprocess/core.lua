-- engine/parser/preprocess/core.lua
-- Core parsing and basic cleanup helpers.

local data = require("engine.parser.preprocess.data")
local words = require("engine.parser.preprocess.words")

local core = {}

function core.strip_articles(noun)
    if not noun then return "" end
    return noun:gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
end

function core.parse(input)
    input = input:match("^%s*(.-)%s*$") -- trim
    local verb, noun = input:match("^(%S+)%s*(.*)")
    verb = (verb or ""):lower()
    noun = (noun or ""):lower()
    -- BUG-036: "I" as pronoun, not inventory shortcut. Re-parse the rest.
    if verb == "i" and noun ~= "" then
        return core.parse(noun)
    end
    return verb, noun
end

-- Stage: normalize
function core.normalize(text)
    if not text or text == "" then return "" end
    local result = text:lower():match("^%s*(.-)%s*$")
    if not result then return "" end
    result = result:gsub("%?+$", "")
    return result
end

-- Stage: strip_politeness
function core.strip_politeness(text)
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

-- Stage: strip_adverbs (BUG-085)
function core.strip_adverbs(text)
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

-- Stage: strip_preambles (BUG-036)
function core.strip_preambles(text)
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

-- Stage: strip_gerunds (BUG-107)
function core.strip_gerunds(text)
    local first, rest = text:match("^(%S+)%s+(.+)$")
    if first and data.GERUND_MAP[first] then
        return data.GERUND_MAP[first] .. " " .. rest
    end
    -- Bare gerund with no target
    if data.GERUND_MAP[text] then
        return data.GERUND_MAP[text]
    end
    return text
end

-- Stage: strip_filler
function core.strip_filler(text)
    for _ = 1, 10 do
        local prev = text
        text = core.strip_preambles(text)
        text = core.strip_politeness(text)
        text = core.strip_adverbs(text)
        text = core.strip_gerunds(text)
        if text == prev then break end
    end
    return text
end

-- Stage: strip_possessives (#67)
function core.strip_possessives(text)
    text = text:gsub("^(%S+%s+)your%s+", "%1")
    text = text:gsub("^(%S+%s+)my%s+", "%1")
    -- Handle "pick up your X" (two-word verbs)
    text = text:gsub("^(%S+%s+%S+%s+)your%s+", "%1")
    text = text:gsub("^(%S+%s+%S+%s+)my%s+", "%1")
    return text
end

function core.singularize(noun)
    if not noun or #noun < 3 then return {} end
    noun = noun:lower()
    local forms = words.singularize_word(noun)
    -- Multi-word: also try singularizing just the last word
    local prefix, last = noun:match("^(.+%s)(%S+)$")
    if prefix then
        for _, s in ipairs(words.singularize_word(last)) do
            forms[#forms+1] = prefix .. s
        end
    end
    return forms
end

return core
