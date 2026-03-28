-- engine/parser/preprocess/movement.lua
-- Movement-related transforms.

local movement = {}

function movement.transform_movement(text)
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

return movement
