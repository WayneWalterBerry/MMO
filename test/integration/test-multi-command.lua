-- test/integration/test-multi-command.lua
-- Integration test for multi-command execution (BUG-066 regression test)
-- Validates that comma-separated commands execute properly without hanging.

-- Set up package path
local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

-- Minimal test harness
local tests_run = 0
local tests_passed = 0
local tests_failed = 0

local function test(description, fn)
    tests_run = tests_run + 1
    local status, err = pcall(fn)
    if status then
        tests_passed = tests_passed + 1
        print("  PASS " .. description)
    else
        tests_failed = tests_failed + 1
        print("  FAIL " .. description)
        print("       " .. tostring(err))
    end
end

local function assert_eq(expected, actual, message)
    if expected ~= actual then
        error(string.format(
            "%s\n  Expected: %s\n  Got:      %s",
            message or "Values not equal",
            tostring(expected),
            tostring(actual)
        ))
    end
end

local function assert_true(value, message)
    if not value then
        error(message or "Expected true, got false")
    end
end

print("=== Multi-command execution (BUG-066 regression) ===")

-- Load the parser
local preprocess = require("engine.parser.preprocess")

test("split_commands handles complex multi-command input", function()
    local cmds = preprocess.split_commands("get match, light match, look")
    assert_eq(3, #cmds)
    assert_eq("get match", cmds[1])
    assert_eq("light match", cmds[2])
    assert_eq("look", cmds[3])
end)

test("split_commands handles semicolons and commas mixed", function()
    local cmds = preprocess.split_commands("feel around; open nightstand, get matchbox")
    assert_eq(3, #cmds)
    assert_eq("feel around", cmds[1])
    assert_eq("open nightstand", cmds[2])
    assert_eq("get matchbox", cmds[3])
end)

test("split_commands handles 'then' separator", function()
    local cmds = preprocess.split_commands("get match then light match then look")
    assert_eq(3, #cmds)
    assert_eq("get match", cmds[1])
    assert_eq("light match", cmds[2])
    assert_eq("look", cmds[3])
end)

test("split_commands with many commands completes quickly", function()
    -- Build a pathological case: 25 commands
    local parts = {}
    for i = 1, 25 do
        parts[i] = "look"
    end
    local input = table.concat(parts, ", ")
    
    local start_time = os.clock()
    local cmds = preprocess.split_commands(input)
    local elapsed = os.clock() - start_time
    
    assert_eq(25, #cmds, "Should split into 25 commands")
    assert_true(elapsed < 1.0, "Should complete in < 1 second, took " .. elapsed)
end)

test("'and' separator within command part doesn't cause infinite loop", function()
    -- This tests the "and" splitting logic in loop/init.lua
    -- We can't easily test that code without a full game context,
    -- but we can verify the preprocessor doesn't interfere
    local cmds = preprocess.split_commands("get match and light it")
    assert_eq(1, #cmds, "Should not split on 'and' in preprocessor")
    assert_eq("get match and light it", cmds[1])
end)

test("pathological edge case: many 'and' separators", function()
    -- Test that the loop's "and" splitter has safety limits
    local input = "a and b and c and d and e and f and g and h"
    local cmds = preprocess.split_commands(input)
    assert_eq(1, #cmds, "Preprocessor returns one command with 'and'")
    -- The loop/init.lua will split this further, and should have safety limits
end)

test("empty command after separator doesn't cause issues", function()
    local cmds = preprocess.split_commands("look, , feel")
    -- Empty segment should be dropped
    assert_eq(2, #cmds)
    assert_eq("look", cmds[1])
    assert_eq("feel", cmds[2])
end)

test("trailing separator doesn't cause issues", function()
    local cmds = preprocess.split_commands("look, feel,")
    assert_eq(2, #cmds)
    assert_eq("look", cmds[1])
    assert_eq("feel", cmds[2])
end)

-- Summary
print("--- Results ---")
print("  Passed: " .. tests_passed)
print("  Failed: " .. tests_failed)

os.exit(tests_failed > 0 and 1 or 0)
