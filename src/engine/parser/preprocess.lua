-- engine/parser/preprocess.lua
-- Input preprocessing pipeline: natural language normalization and basic parsing.
-- Owned by Smithers (UI Engineer). Pure functions, no side effects.
--
-- Extracts:
--   preprocess.natural_language(input) -> verb, noun or nil, nil
--   preprocess.parse(input) -> verb, noun

local preprocess = {}

--- parse(input) -> verb, noun
--- Splits a raw input string into the first word (verb) and the rest (noun).
function preprocess.parse(input)
    input = input:match("^%s*(.-)%s*$") -- trim
    local verb, noun = input:match("^(%S+)%s*(.*)")
    return (verb or ""):lower(), (noun or ""):lower()
end

--- natural_language(input) -> verb, noun or nil, nil
--- Converts common question patterns and multi-word phrases into known verbs.
--- Returns nil, nil if no pattern matches (caller should fall through to parse).
function preprocess.natural_language(input)
    local lower = input:lower():match("^%s*(.-)%s*$")
    if not lower or lower == "" then return nil, nil end

    -- Question patterns → look
    if lower:match("^what%s+is%s+around")
        or lower:match("^what%s+do%s+i%s+see")
        or lower:match("^what%s+can%s+i%s+see")
        or lower:match("^where%s+am%s+i")
        or lower:match("^look%s+around$") then
        return "look", ""
    end

    -- Question patterns → time
    if lower:match("^what%s+time")
        or lower:match("^what%s+is%s+the%s+time") then
        return "time", ""
    end

    -- Question patterns → inventory
    if lower:match("^what%s+am%s+i%s+carry")
        or lower:match("^what%s+do%s+i%s+have") then
        return "inventory", ""
    end

    -- Question patterns → look in (container queries with noun)
    local container_noun = lower:match("^what'?s%s+in%s+(.+)")
        or lower:match("^what%s+is%s+in%s+(.+)")
        or lower:match("^what'?s%s+inside%s+(.+)")
        or lower:match("^what%s+is%s+inside%s+(.+)")
    if container_noun then
        return "look", "in " .. container_noun
    end

    -- Bare "what's inside" (no noun) → look
    if lower:match("^what'?s%s+inside$")
        or lower:match("^what%s+is%s+inside$") then
        return "look", ""
    end

    -- Question patterns → help
    if lower:match("^what%s+can%s+i%s+do")
        or lower:match("^how%s+do%s+i") then
        return "help", ""
    end

    -- Grope/feel compound phrases → feel (room sweep)
    if lower:match("^grope%s+around%s+")
        or lower:match("^feel%s+around%s+") then
        return "feel", ""
    end

    -- Composite part phrases: "take out X", "pull out X" → pull
    local pull_target = lower:match("^take%s+out%s+(.+)")
        or lower:match("^pull%s+out%s+(.+)")
        or lower:match("^yank%s+out%s+(.+)")
    if pull_target then
        return "pull", pull_target
    end

    -- Spatial movement phrases: "roll up X" → move X
    local roll_target = lower:match("^roll%s+up%s+(.+)")
        or lower:match("^roll%s+(.+)%s+up$")
    if roll_target then
        return "move", roll_target
    end

    -- "pull back X" → move X
    local pullback_target = lower:match("^pull%s+back%s+(.+)")
    if pullback_target then
        return "move", pullback_target
    end

    -- "uncork X", "pop cork" → uncork
    local uncork_target = lower:match("^pop%s+(.+)")
    if uncork_target and uncork_target:match("cork") then
        return "uncork", "bottle"
    end

    -- "use X on Y" → sew Y with X (crafting shorthand)
    local use_tool, use_target = lower:match("^use%s+(.+)%s+on%s+(.+)$")
    if use_tool and use_target then
        if use_tool:match("needle") or use_tool:match("thread") then
            return "sew", use_target .. " with " .. use_tool
        end
        if use_tool:match("key") then
            return "unlock", use_target .. " with " .. use_tool
        end
    end

    -- "push X back" / "put X back in Y" → put
    local push_back_target = lower:match("^push%s+(.+)%s+back")
    if push_back_target then
        return "put", push_back_target .. " in " .. push_back_target
    end

    -- "put X back" → put X in (context-dependent, let verb handler sort it)
    local put_back_item, put_back_target2 = lower:match("^put%s+(.+)%s+back%s+in%s+(.+)")
    if put_back_item then
        return "put", put_back_item .. " in " .. put_back_target2
    end

    -- Extinguish phrases: "put out X", "blow out X" → extinguish
    local extinguish_target = lower:match("^put%s+out%s+(.+)")
        or lower:match("^blow%s+out%s+(.+)")
    if extinguish_target then
        return "extinguish", extinguish_target
    end

    -- Wear/equip phrases: "put on X", "dress in X" → wear
    local wear_target = lower:match("^put%s+on%s+(.+)")
        or lower:match("^dress%s+in%s+(.+)")
    if wear_target then
        return "wear", wear_target
    end

    -- Remove/unequip phrases: "take off X" → remove
    local remove_target = lower:match("^take%s+off%s+(.+)")
    if remove_target then
        return "remove", remove_target
    end

    -- Wear query: "what am i wearing" → inventory
    if lower:match("^what%s+am%s+i%s+wear") then
        return "inventory", ""
    end

    -- Sleep phrases: "take a nap", "go to sleep", "lie down", "go to bed"
    if lower:match("^take%s+a%s+nap") then
        return "sleep", ""
    end
    local go_sleep_noun = lower:match("^go%s+to%s+sleep%s*(.*)")
    if go_sleep_noun then
        return "sleep", go_sleep_noun
    end
    if lower:match("^go%s+to%s+bed") then
        return "sleep", ""
    end
    if lower:match("^lie%s+down") then
        return "sleep", ""
    end

    -- Movement phrases: stairs, through, into
    if lower:match("^go%s+down%s+the%s+stair")
        or lower:match("^climb%s+down%s+the%s+stair")
        or lower:match("^descend%s+the%s+stair")
        or lower:match("^descend%s+stair") then
        return "down", ""
    end
    if lower:match("^go%s+up%s+the%s+stair")
        or lower:match("^climb%s+up%s+the%s+stair")
        or lower:match("^ascend%s+the%s+stair")
        or lower:match("^ascend%s+stair") then
        return "up", ""
    end

    -- Clock adjustment phrases: "turn hands", "set clock", "adjust clock"
    local clock_target = lower:match("^turn%s+hands%s*(.*)$")
        or lower:match("^turn%s+the%s+hands%s*(.*)$")
    if clock_target then
        local target = clock_target ~= "" and clock_target or "clock"
        return "set", target
    end
    if lower:match("^adjust%s+the%s+clock") or lower:match("^adjust%s+clock") then
        return "set", "clock"
    end
    if lower:match("^set%s+the%s+clock") or lower:match("^set%s+clock") then
        return "set", "clock"
    end

    return nil, nil
end

return preprocess
