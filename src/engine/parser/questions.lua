-- engine/parser/questions.lua
-- Tier 1: Question Transforms (Prime Directive #106)
-- Owned by Smithers (UI Engineer). Pure functions, no side effects.
--
-- Converts natural-language questions into canonical imperative commands.
-- Data-driven: each entry is { pattern, verb, noun_capture, priority }.
-- Patterns tried in table order (sorted by priority).
--
-- API:
--   questions.match(text) → "verb noun" string | nil
--   questions.QUESTION_MAP — externally extensible pattern table

local M = {}

M.QUESTION_MAP = {
    -- Container queries (highest priority for specificity)
    { pattern = "^what'?s%s+in%s+my%s+hands",   verb = "inventory", noun_capture = 0, priority = 10 },
    { pattern = "^what%s+is%s+in%s+my%s+hands",  verb = "inventory", noun_capture = 0, priority = 10 },
    { pattern = "^what'?s%s+in%s+the%s+(.+)$",  verb = "examine",   noun_capture = 1, priority = 20 },
    { pattern = "^what'?s%s+in%s+(.+)$",         verb = "examine",   noun_capture = 1, priority = 21 },
    { pattern = "^what%s+is%s+in%s+the%s+(.+)$", verb = "examine",   noun_capture = 1, priority = 20 },
    { pattern = "^what%s+is%s+in%s+(.+)$",       verb = "examine",   noun_capture = 1, priority = 21 },

    -- Existence queries → search
    { pattern = "^is%s+there%s+anything%s+in%s+(.+)$", verb = "search", noun_capture = 1, priority = 30 },
    { pattern = "^is%s+there%s+an?%s+(.-)%s+in%s+the%s+room$", verb = "search", noun_capture = 1, priority = 31 },
    { pattern = "^is%s+there%s+an?%s+(.-)%s+here$", verb = "search", noun_capture = 1, priority = 31 },
    { pattern = "^is%s+there%s+an?%s+(.+)$",    verb = "search",    noun_capture = 1, priority = 32 },
    { pattern = "^do%s+you%s+see%s+an?%s+(.+)$", verb = "search",   noun_capture = 1, priority = 33 },
    { pattern = "^can%s+i%s+find%s+(.+)$",       verb = "search",   noun_capture = 1, priority = 34 },

    -- Health/injury queries (must precede "where am I" → look)
    { pattern = "^where%s+am%s+i%s+bleeding",    verb = "injuries",  noun_capture = 0, priority = 38 },
    { pattern = "^how%s+bad%s+is%s+it",           verb = "injuries",  noun_capture = 0, priority = 38 },
    { pattern = "^how%s+bad%s+are%s+",            verb = "injuries",  noun_capture = 0, priority = 38 },
    { pattern = "^how%s+am%s+i",                  verb = "health",    noun_capture = 0, priority = 39 },
    { pattern = "^am%s+i%s+hurt",                 verb = "health",    noun_capture = 0, priority = 39 },
    { pattern = "^am%s+i%s+injured",              verb = "health",    noun_capture = 0, priority = 39 },

    -- Identity queries
    { pattern = "^who%s+am%s+i",                  verb = "health",    noun_capture = 0, priority = 39 },

    -- Location queries → find
    { pattern = "^where%s+is%s+the%s+(.+)$",    verb = "find",      noun_capture = 1, priority = 40 },
    { pattern = "^where%s+is%s+(.+)$",           verb = "find",      noun_capture = 1, priority = 41 },
    { pattern = "^where'?s%s+the%s+(.+)$",       verb = "find",      noun_capture = 1, priority = 40 },
    { pattern = "^where'?s%s+(.+)$",             verb = "find",      noun_capture = 1, priority = 41 },

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

--- match(text) -> "verb noun" string | nil
--- Tries each question pattern in table order.
--- Returns transformed command string on match, or nil.
function M.match(text)
    if not text or text == "" then return nil end
    for _, entry in ipairs(M.QUESTION_MAP) do
        if entry.verb == "$1" then
            -- Dynamic verb extraction (e.g., "can I verb target")
            local v, n = text:match(entry.pattern)
            if v then
                local result = v
                if n and n ~= "" then result = result .. " " .. n end
                return result
            end
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
