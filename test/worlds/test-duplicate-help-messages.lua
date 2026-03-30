-- test/worlds/test-duplicate-help-messages.lua
-- TDD test for Issue #474: Duplicate world debug lines
-- Verifies that only ONE help message appears when loading a world

local t = require("test.parser.test-helpers")

-- Helper to capture output from main.lua execution
local function capture_game_output(world_id)
    local sep = package.config:sub(1, 1)
    local cmd
    if sep == "\\" then
        -- Windows
        cmd = 'echo quit | lua src' .. sep .. 'main.lua --world ' .. world_id .. ' --no-ui 2>&1'
    else
        -- Unix
        cmd = 'echo "quit" | lua src/main.lua --world ' .. world_id .. ' --no-ui 2>&1'
    end
    
    local handle = io.popen(cmd)
    if not handle then return nil end
    
    local output = handle:read("*a")
    handle:close()
    return output
end

-- Helper to count occurrences of a pattern in text
local function count_occurrences(text, pattern)
    local count = 0
    for _ in text:gmatch(pattern) do
        count = count + 1
    end
    return count
end

t.test("world load shows only ONE help message", function()
    local output = capture_game_output("wyatt-world")
    t.assert_truthy(output, "should capture output")
    
    -- Count how many times "Type" appears (each help message starts with "Type")
    -- Should be exactly 1 help message, not 2
    local type_count = count_occurrences(output, "Type '[^']+' ")
    
    -- Debug: show what we found
    if type_count > 1 then
        print("\n=== DUPLICATE HELP MESSAGES FOUND ===")
        for line in output:gmatch("[^\r\n]+") do
            if line:match("Type") then
                print("  " .. line)
            end
        end
        print("=====================================\n")
    end
    
    t.assert_eq(1, type_count, "should show exactly ONE help message, not " .. type_count)
end)

t.test("help message mentions core commands", function()
    local output = capture_game_output("wyatt-world")
    t.assert_truthy(output, "should capture output")
    
    -- The ONE help message should mention key commands
    -- It should mention either 'help', 'look', or 'quit'
    local has_help_cmd = output:match("Type 'help'") or 
                         output:match("Type 'look'") or 
                         output:match("Type 'quit'")
    
    t.assert_truthy(has_help_cmd, "help message should mention key commands")
end)

t.test("world-1 also shows only ONE help message", function()
    local output = capture_game_output("world-1")
    t.assert_truthy(output, "should capture output")
    
    local type_count = count_occurrences(output, "Type '[^']+' ")
    t.assert_eq(1, type_count, "world-1 should also show exactly ONE help message, not " .. type_count)
end)

t.summary()
