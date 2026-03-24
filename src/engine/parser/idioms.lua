-- engine/parser/idioms.lua
-- Tier 3: Idiom Library (Prime Directive #106)
-- Owned by Smithers (UI Engineer). Pure functions, no side effects.
--
-- Expands natural English phrases into canonical game commands.
-- Data-driven: each idiom is a { pattern, replacement, category } entry.
-- First match wins; patterns are anchored (^...$) to prevent partial matches.
--
-- API:
--   idioms.match(text) → result_text, matched_bool
--   idioms.IDIOM_TABLE — externally extensible pattern table

local M = {}

M.IDIOM_TABLE = {
    -- === FIRE / LIGHT ===
    { pattern = "^set%s+fire%s+to%s+(.+)$",    replacement = "light %1",       category = "fire" },
    { pattern = "^set%s+(.+)%s+on%s+fire$",     replacement = "light %1",       category = "fire" },
    { pattern = "^kindle%s+(.+)$",              replacement = "light %1",       category = "fire" },

    -- === EXTINGUISH ===
    { pattern = "^blow%s+out%s+(.+)$",          replacement = "extinguish %1",  category = "fire" },
    { pattern = "^snuff%s+out%s+(.+)$",         replacement = "extinguish %1",  category = "fire" },

    -- === DROP / DISCARD ===
    { pattern = "^put%s+down%s+(.+)$",          replacement = "drop %1",        category = "drop" },
    { pattern = "^put%s+(.+)%s+down$",          replacement = "drop %1",        category = "drop" },
    { pattern = "^set%s+down%s+(.+)$",          replacement = "drop %1",        category = "drop" },
    { pattern = "^set%s+(.+)%s+down$",          replacement = "drop %1",        category = "drop" },
    { pattern = "^get%s+rid%s+of%s+(.+)$",      replacement = "drop %1",        category = "drop" },
    { pattern = "^discard%s+(.+)$",             replacement = "drop %1",        category = "drop" },
    { pattern = "^ditch%s+(.+)$",               replacement = "drop %1",        category = "drop" },

    -- === GET / PICK UP ===
    { pattern = "^pick%s+up%s+(.+)$",           replacement = "get %1",         category = "get" },
    { pattern = "^pick%s+(.+)%s+up$",           replacement = "get %1",         category = "get" },

    -- === LOOK / EXAMINE ===
    { pattern = "^have%s+a%s+look%s+at%s+(.+)$",  replacement = "examine %1",  category = "look" },
    { pattern = "^take%s+a%s+look%s+at%s+(.+)$",  replacement = "examine %1",  category = "look" },
    { pattern = "^take%s+a%s+peek%s+at%s+(.+)$",  replacement = "examine %1",  category = "look" },
    { pattern = "^take%s+a%s+closer%s+look%s+at%s+(.+)$", replacement = "examine %1", category = "look" },
    { pattern = "^have%s+a%s+look%s+around$",    replacement = "look",          category = "look" },
    { pattern = "^take%s+a%s+look%s+around$",    replacement = "look",          category = "look" },
    { pattern = "^have%s+a%s+look$",             replacement = "look",          category = "look" },
    { pattern = "^take%s+a%s+look$",             replacement = "look",          category = "look" },
    { pattern = "^take%s+a%s+peek$",             replacement = "look",          category = "look" },
    { pattern = "^study%s+(.+)$",               replacement = "examine %1",     category = "look" },
    { pattern = "^check%s+out%s+(.+)$",         replacement = "examine %1",     category = "look" },
    { pattern = "^check%s+(.+)%s+out$",         replacement = "examine %1",     category = "look" },

    -- === SLEEP / REST ===
    { pattern = "^go%s+to%s+sleep$",            replacement = "sleep",          category = "rest" },
    { pattern = "^lay%s+down$",                 replacement = "sleep",          category = "rest" },
    { pattern = "^lie%s+down$",                 replacement = "sleep",          category = "rest" },
    { pattern = "^have%s+a%s+rest$",            replacement = "sleep",          category = "rest" },
    { pattern = "^have%s+a%s+seat$",            replacement = "sit",            category = "rest" },
    { pattern = "^sleep%s+to%s+(.+)$",          replacement = "sleep until %1", category = "rest" },
    { pattern = "^sleep%s+til%s+(.+)$",         replacement = "sleep until %1", category = "rest" },
    { pattern = "^sleep%s+till%s+(.+)$",        replacement = "sleep until %1", category = "rest" },

    -- === SENSORY ===
    { pattern = "^give%s+(.+)%s+a%s+sniff$",   replacement = "smell %1",       category = "sensory" },
    { pattern = "^take%s+a%s+whiff$",           replacement = "smell",          category = "sensory" },
    { pattern = "^give%s+(.+)%s+a%s+taste$",    replacement = "taste %1",       category = "sensory" },

    -- === MANIPULATION ===
    { pattern = "^toss%s+(.+)$",               replacement = "throw %1",       category = "manipulation" },
    { pattern = "^chuck%s+(.+)$",              replacement = "throw %1",       category = "manipulation" },
    { pattern = "^hurl%s+(.+)$",               replacement = "throw %1",       category = "manipulation" },
    { pattern = "^yank%s+(.+)$",               replacement = "pull %1",        category = "manipulation" },
    { pattern = "^shove%s+(.+)$",              replacement = "push %1",        category = "manipulation" },
    { pattern = "^slam%s+(.+)$",               replacement = "close %1",       category = "manipulation" },
    { pattern = "^flip%s+(.+)$",               replacement = "turn %1",        category = "manipulation" },
    { pattern = "^twist%s+(.+)$",              replacement = "turn %1",        category = "manipulation" },
    { pattern = "^rotate%s+(.+)$",             replacement = "turn %1",        category = "manipulation" },

    -- === SEARCH ===
    { pattern = "^rifle%s+through%s+(.+)$",     replacement = "search %1",     category = "search" },
    { pattern = "^dig%s+through%s+(.+)$",       replacement = "search %1",     category = "search" },
    { pattern = "^look%s+everywhere$",          replacement = "search",         category = "search" },
    { pattern = "^search%s+everywhere$",        replacement = "search",         category = "search" },

    -- === UTILITY ===
    { pattern = "^make%s+use%s+of%s+(.+)$",     replacement = "use %1",        category = "use" },

    -- === META ===
    { pattern = "^check%s+my%s+pockets$",       replacement = "inventory",      category = "meta" },
    { pattern = "^give%s+me%s+a%s+hint$",       replacement = "help",           category = "meta" },
}

--- match(text) -> result_text, matched_bool
--- Tries each idiom in order. Returns transformed text on first match.
function M.match(text)
    if not text or text == "" then return text or "", false end
    for _, idiom in ipairs(M.IDIOM_TABLE) do
        local new_text = text:gsub(idiom.pattern, idiom.replacement)
        if new_text ~= text then
            return new_text, true
        end
    end
    return text, false
end

return M
