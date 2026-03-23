-- test/rooms/test-level-intro.lua
-- Validates that level-01 contains intro text and that main.lua reads it.
-- Must be run from repository root: lua test/rooms/test-level-intro.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite
local assert_eq = h.assert_eq
local assert_truthy = h.assert_truthy

---------------------------------------------------------------------------
-- Load level data directly
---------------------------------------------------------------------------
local loader = require("engine.loader")

local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

local SEP = package.config:sub(1, 1)
local level_path = script_dir .. SEP .. ".." .. SEP .. ".." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "levels" .. SEP .. "level-01.lua"
local level_source = read_file(level_path)
local level = level_source and loader.load_source(level_source)

---------------------------------------------------------------------------
suite("Level 01 — Intro Text Structure")
---------------------------------------------------------------------------

test("level-01 loads successfully", function()
    assert_truthy(level, "level-01.lua should load")
end)

test("level-01 has intro table", function()
    assert_truthy(level.intro, "level should have an intro field")
    assert_eq("table", type(level.intro), "intro should be a table")
end)

test("intro has title", function()
    assert_truthy(level.intro.title, "intro should have a title")
    assert_eq("string", type(level.intro.title))
end)

test("intro has subtitle", function()
    assert_truthy(level.intro.subtitle, "intro should have a subtitle")
    assert_eq("string", type(level.intro.subtitle))
end)

test("intro has narrative table", function()
    assert_truthy(level.intro.narrative, "intro should have a narrative")
    assert_eq("table", type(level.intro.narrative))
    assert_truthy(#level.intro.narrative > 0, "narrative should have at least one line")
end)

test("narrative contains awakening text", function()
    local found = false
    for _, line in ipairs(level.intro.narrative) do
        if line:find("wake") then found = true; break end
    end
    assert_truthy(found, "narrative should contain awakening text")
end)

test("intro has help text", function()
    assert_truthy(level.intro.help, "intro should have a help field")
    assert_eq("string", type(level.intro.help))
    assert_truthy(level.intro.help:find("help"), "help text should mention 'help'")
end)

---------------------------------------------------------------------------
suite("Level 01 — Backward Compatibility")
---------------------------------------------------------------------------

test("level still has all room entries", function()
    assert_truthy(level.rooms, "level should have rooms")
    assert_eq(7, #level.rooms, "level should have 7 rooms")
end)

test("level still has start_room", function()
    assert_eq("start-room", level.start_room)
end)

test("level still has completion criteria", function()
    assert_truthy(level.completion, "level should have completion criteria")
    assert_truthy(#level.completion > 0, "completion should have at least one entry")
end)

---------------------------------------------------------------------------
-- Verify main.lua uses level intro by capturing output from headless mode
---------------------------------------------------------------------------
suite("main.lua — Reads Intro from Level Data")

-- Run main.lua in headless mode, pipe "quit" to stop the loop
local function run_headless()
    local SEP2 = package.config:sub(1, 1)
    local is_windows = SEP2 == "\\"
    local main_path = script_dir .. "/../../src/main.lua"
    local cmd
    if is_windows then
        cmd = 'echo quit | lua "' .. main_path .. '" --headless 2>&1'
    else
        cmd = 'echo quit | lua "' .. main_path .. '" --headless 2>&1'
    end
    local pipe = io.popen(cmd)
    if not pipe then return nil end
    local output = pipe:read("*a")
    pipe:close()
    return output
end

local headless_output = run_headless()

test("headless output contains narrative from level data", function()
    assert_truthy(headless_output, "headless output should not be nil")
    -- The narrative text should appear in headless output
    for _, line in ipairs(level.intro.narrative) do
        assert_truthy(headless_output:find(line, 1, true),
            "output should contain narrative line: " .. line)
    end
end)

---------------------------------------------------------------------------
h.summary()
