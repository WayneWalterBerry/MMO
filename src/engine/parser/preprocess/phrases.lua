-- engine/parser/preprocess/phrases.lua
-- Phrase-level transforms for preprocessing.

local core = require("engine.parser.preprocess.core")
local data = require("engine.parser.preprocess.data")
local words = require("engine.parser.preprocess.words")

local phrases = {}

-- Stage: strip_noun_modifiers (Issue #14)
function phrases.strip_noun_modifiers(text)
    text = text:gsub("%f[%a]all%s+of%s+the%s+", "the ")
    text = text:gsub("%f[%a]all%s+of%s+", "")
    text = text:gsub("%f[%a]whole%s+", "")
    text = text:gsub("%f[%a]entire%s+", "")
    text = text:gsub("%f[%a]every%s+", "")
    text = text:gsub("%s%s+", " ")
    text = text:match("^%s*(.-)%s*$")
    return text
end

-- Stage: strip_decorative_prepositions (#154)
function phrases.strip_decorative_prepositions(text)
    local verb = text:match("^(%S+)")
    if not verb then return text end

    if verb == "put" or verb == "place" or verb == "set" then
        return text
    end

    text = text:gsub("%s+as%s+an?%s+%S+$", "")

    local in_prefix, in_part = text:match("^(.+)%s+in%s+the%s+(%S+)$")
    if in_prefix and data.BODY_PARTS[in_part] then return in_prefix end

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

    text = text:gsub("%s+on%s+the%s+floor$", "")
    text = text:gsub("%s+on%s+floor$", "")
    text = text:gsub("%s+on%s+the%s+ground$", "")
    text = text:gsub("%s+on%s+ground$", "")

    local prefix, part = text:match("^(.+)%s+on%s+my%s+(%S+)$")
    if prefix and data.BODY_PARTS[part] then return prefix end

    prefix, part = text:match("^(%S+%s+%S.-)%s+on%s+(%S+)$")
    if prefix and data.BODY_PARTS[part] then return prefix end

    prefix, part = text:match("^(.+)%s+from%s+my%s+(%S+)$")
    if prefix and data.BODY_PARTS[part] then return prefix end

    prefix, part = text:match("^(%S+%s+%S.-)%s+from%s+(%S+)$")
    if prefix and data.BODY_PARTS[part] then return prefix end

    return text
end

-- Stage: expand_idioms
function phrases.expand_idioms(text)
    for _, idiom in ipairs(data.IDIOM_TABLE) do
        local new_text = text:gsub(idiom.pattern, idiom.replacement)
        if new_text ~= text then
            return new_text, true
        end
    end
    return text
end

-- Stage: transform_questions
function phrases.transform_questions(text)
    -- Handle greetings before extracting directions
    if text:match("^what'?s%s+up%s*$") or text:match("^what%s+is%s+up%s*$")
        or text:match("^whats%s+up%s*$") or text:match("^wassup%s*$")
        or text:match("^sup%s*$") then
        return "look"
    end

    if text:match("^what'?s%s+in%s+my%s+hands")
        or text:match("^what%s+is%s+in%s+my%s+hands") then
        return "inventory"
    end

    local whats_in = text:match("^what'?s%s+in%s+the%s+(.+)$")
        or text:match("^what'?s%s+in%s+(.+)$")
    if whats_in then
        return "examine " .. whats_in
    end

    local is_anything_in = text:match("^is%s+there%s+anything%s+in%s+(.+)$")
    if is_anything_in then
        return "search " .. is_anything_in
    end

    local is_there_in = text:match("^is%s+there%s+an?%s+(.-)%s+in%s+the%s+room$")
        or text:match("^is%s+there%s+an?%s+(.-)%s+here$")
        or text:match("^is%s+there%s+an?%s+(.-)%s+nearby$")
        or text:match("^is%s+there%s+an?%s+(.-)%s+around$")
    if is_there_in then
        return "search " .. is_there_in
    end

    local is_there_bare = text:match("^is%s+there%s+an?%s+(.+)$")
    if is_there_bare then
        return "search " .. is_there_bare
    end

    local do_you_see = text:match("^do%s+you%s+see%s+an?%s+(.+)$")
    if do_you_see then
        return "search " .. do_you_see
    end

    local can_i_find = text:match("^can%s+i%s+find%s+an?%s+(.+)$")
        or text:match("^can%s+i%s+find%s+(.+)$")
    if can_i_find then
        return "search " .. can_i_find
    end

    local can_i_verb, can_i_target = text:match("^can%s+i%s+(%w+)%s+(.+)$")
    if can_i_verb and can_i_target then
        return can_i_verb .. " " .. can_i_target
    end

    if text:match("^what%s+is%s+this$") or text:match("^what'?s%s+this$") then
        return "look"
    end

    if text:match("^what%s+can%s+i%s+find") then
        return "search"
    end

    local where_is_target = text:match("^where%s+is%s+the%s+(.+)$")
        or text:match("^where%s+is%s+(.+)$")
        or text:match("^where'?s%s+the%s+(.+)$")
        or text:match("^where'?s%s+(.+)$")
    if where_is_target then
        return "find " .. where_is_target
    end

    if text:match("^where%s+am%s+i%s+bleeding")
        or text:match("^how%s+bad%s+is%s+it")
        or text:match("^how%s+bad%s+are%s+")
        or text:match("^why%s+don'?t%s+i%s+feel%s+well")
        or text:match("^why%s+don'?t%s+i%s+feel%s+good") then
        return "injuries"
    end

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

    -- Options / hint patterns (D-OPTIONS-B5: "help me" stays mapped to help)
    if text:match("^what%s+are%s+my%s+options")
        or text:match("^give%s+me%s+options")
        or text:match("^what%s+can%s+i%s+try")
        or text:match("^i'?m%s+stuck")
        or text == "hint"
        or text == "hints"
        or text == "nudge" then
        return "options"
    end

    if text:match("^what%s+is%s+around")
        or text:match("^what'?s%s+around")
        or text:match("^what%s+do%s+i%s+see")
        or text:match("^what%s+can%s+i%s+see")
        or text:match("^where%s+am%s+i") then
        return "look"
    end

    if text:match("^what%s+time")
        or text:match("^what%s+is%s+the%s+time") then
        return "time"
    end

    if text:match("^what%s+am%s+i%s+carry")
        or text:match("^what%s+am%s+i%s+hold")
        or text:match("^what%s+do%s+i%s+have")
        or text:match("^what'?s%s+in%s+my%s+hands")
        or text:match("^what%s+is%s+in%s+my%s+hands")
        or text:match("^am%s+i%s+holding%s+anything")
        or text:match("^am%s+i%s+holding%s+something") then
        return "inventory"
    end

    local container_noun = text:match("^what'?s%s+in%s+(.+)")
        or text:match("^what%s+is%s+in%s+(.+)")
        or text:match("^what'?s%s+inside%s+(.+)")
        or text:match("^what%s+is%s+inside%s+(.+)")
    if container_noun then
        return "examine " .. container_noun
    end

    if text:match("^what'?s%s+inside$")
        or text:match("^what%s+is%s+inside$") then
        return "examine it"
    end

    local what_noun = text:match("^what%s+is%s+the%s+(.+)$")
        or text:match("^what'?s%s+the%s+(.+)$")
        or text:match("^what%s+is%s+an?%s+(.+)$")
        or text:match("^what%s+is%s+(.+)$")
        or text:match("^what'?s%s+(.+)$")
    if what_noun then
        return "examine " .. what_noun
    end

    if text:match("^what%s+can%s+i%s+do")
        or text:match("^what%s+do%s+i%s+do")
        or text:match("^what%s+should%s+i%s+do")
        or text:match("^what%s+now$")
        or text:match("^now%s+what$")
        or text:match("^how%s+do%s+i") then
        return "help"
    end

    if text:match("^what%s+am%s+i%s+wear") then
        return "inventory"
    end

    return text
end

-- Stage: transform_look_patterns
function phrases.transform_look_patterns(text)
    if text:match("^look%s+around$") then
        return "look"
    end

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

    if text:match("^look%s+at%s+my%s+hands") then
        return "inventory"
    end

    local look_at_target = text:match("^look%s+at%s+(.+)")
    if look_at_target then
        return "examine " .. look_at_target
    end

    local check_target = text:match("^check%s+(.+)")
    if check_target then
        return "examine " .. check_target
    end

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

    local look_under_target = text:match("^look%s+under%s+(.+)")
        or text:match("^look%s+underneath%s+(.+)")
        or text:match("^look%s+beneath%s+(.+)")
    if look_under_target then
        return "examine " .. look_under_target
    end

    local look_for_target = text:match("^look%s+for%s+(.+)")
    if look_for_target then
        return "find " .. core.strip_articles(look_for_target)
    end

    return text
end

local function singularize_target(noun)
    local forms = words.singularize_word(noun)
    if #forms > 0 then return forms[1] end
    return noun
end

-- Stage: transform_search_phrases
function phrases.transform_search_phrases(text)
    if text:match("^grope%s+around%s+")
        or text:match("^feel%s+around%s+") then
        return "feel", true
    end

    if text:match("^search%s+around%s*") then
        return "search around", true
    end

    local search_scope_for = text:match("^search%s+(.+)%s+for%s+(.+)")
    if search_scope_for then
        local raw = text:match("^search%s+(.+)$")
        local scope_raw, target_raw = raw:match("^(.-)%s+for%s+(.+)$")
        if scope_raw and target_raw then
            return "search " .. core.strip_articles(scope_raw)
                .. " for " .. core.strip_articles(target_raw), true
        end
        return "search " .. raw, true
    end

    local search_target = text:match("^search%s+for%s+(.+)")
    if search_target then
        local stripped = core.strip_articles(search_target)
        if stripped == "everything" or stripped == "anything" or stripped == "all" then
            return "search", true
        end
        return "search " .. singularize_target(stripped), true
    end

    local hunt_target = text:match("^hunt%s+for%s+(.+)")
    if hunt_target then
        return "search " .. singularize_target(core.strip_articles(hunt_target)), true
    end
    if text:match("^hunt%s+around%s*") then
        return "search around", true
    end

    local rummage_target = text:match("^rummage%s+for%s+(.+)")
    if rummage_target then
        return "search " .. singularize_target(core.strip_articles(rummage_target)), true
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
        return "search " .. core.strip_articles(rummage_scope), true
    end

    local find_in = text:match("^find%s+(.+)%s+in%s+(.+)")
    if find_in then
        local raw = text:match("^find%s+(.+)$")
        local target_raw, scope_raw = raw:match("^(.-)%s+in%s+(.+)$")
        if target_raw and scope_raw then
            return "find " .. core.strip_articles(target_raw)
                .. " in " .. core.strip_articles(scope_raw), true
        end
        return "find " .. raw, true
    end

    local find_target = text:match("^find%s+(.+)")
    if find_target then
        local stripped = core.strip_articles(find_target)
        if stripped == "everything" or stripped == "anything" or stripped == "all" then
            return "search", true
        end
        return "find " .. singularize_target(stripped), true
    end

    return text
end

return phrases
