-- test/integration/test-room-override.lua
-- Integration tests for starting room override (#179).
-- Validates that --room flag changes the starting position,
-- invalid IDs fall back to default, and no effect when absent.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

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

local function assert_match(pattern, str, message)
    if not str or not str:match(pattern) then
        error(string.format(
            "%s\n  Pattern: %s\n  String:  %s",
            message or "Pattern not found",
            pattern,
            tostring(str)
        ))
    end
end

---------------------------------------------------------------------------
-- Helpers: Build a minimal set of fake rooms and a level for testing
---------------------------------------------------------------------------
local function make_rooms()
    return {
        ["start-room"] = {
            id = "start-room",
            name = "Bedroom",
            description = "A dark bedroom.",
            instances = {},
            contents = {},
            exits = { north = { target = "hallway" } },
        },
        ["hallway"] = {
            id = "hallway",
            name = "Hallway",
            description = "A long hallway.",
            instances = {},
            contents = {},
            exits = { south = { target = "start-room" } },
        },
        ["cellar"] = {
            id = "cellar",
            name = "Cellar",
            description = "A dank cellar.",
            instances = {},
            contents = {},
            exits = {},
        },
    }
end

local function make_level()
    return {
        start_room = "start-room",
        rooms = { "start-room", "hallway", "cellar" },
    }
end

---------------------------------------------------------------------------
-- select_start_room: mirrors the override logic from game-adapter.lua
-- and main.lua — extracted here so we can unit-test the decision.
---------------------------------------------------------------------------
local function select_start_room(rooms, level, override_id)
    local default_id = (level and level.start_room) or "start-room"
    local errors = {}

    if override_id and override_id ~= "" then
        local level_rooms = (level and level.rooms) or {}
        local valid = false
        for _, rid in ipairs(level_rooms) do
            if rid == override_id then valid = true; break end
        end
        if valid and rooms[override_id] then
            return override_id, rooms[override_id], errors
        else
            errors[#errors + 1] = "Room '" .. override_id .. "' not found in current level. Using default."
            -- list available rooms for debug
            local ids = {}
            for _, rid in ipairs(level_rooms) do ids[#ids + 1] = rid end
            table.sort(ids)
            errors[#errors + 1] = "Available rooms: " .. table.concat(ids, ", ")
        end
    end

    return default_id, rooms[default_id], errors
end

print("=== Room Override (#179) ===")

---------------------------------------------------------------------------
-- Core tests
---------------------------------------------------------------------------

test("override to hallway changes starting position", function()
    local rooms = make_rooms()
    local level = make_level()
    local id, room, errs = select_start_room(rooms, level, "hallway")
    assert_eq("hallway", id)
    assert_eq("Hallway", room.name)
    assert_eq(0, #errs, "no errors expected")
end)

test("override to cellar changes starting position", function()
    local rooms = make_rooms()
    local level = make_level()
    local id, room, errs = select_start_room(rooms, level, "cellar")
    assert_eq("cellar", id)
    assert_eq("Cellar", room.name)
    assert_eq(0, #errs)
end)

test("invalid room ID falls back to default with error", function()
    local rooms = make_rooms()
    local level = make_level()
    local id, room, errs = select_start_room(rooms, level, "nonexistent-room")
    assert_eq("start-room", id, "should fall back to default")
    assert_eq("Bedroom", room.name)
    assert_true(#errs > 0, "should report error")
    assert_match("not found", errs[1])
end)

test("invalid room lists available rooms in error", function()
    local rooms = make_rooms()
    local level = make_level()
    local _, _, errs = select_start_room(rooms, level, "bogus")
    assert_true(#errs >= 2, "should have available rooms list")
    assert_match("Available rooms:", errs[2])
    assert_match("hallway", errs[2])
    assert_match("start%-room", errs[2])
end)

test("nil override has no effect — uses default", function()
    local rooms = make_rooms()
    local level = make_level()
    local id, room, errs = select_start_room(rooms, level, nil)
    assert_eq("start-room", id)
    assert_eq("Bedroom", room.name)
    assert_eq(0, #errs)
end)

test("empty string override has no effect — uses default", function()
    local rooms = make_rooms()
    local level = make_level()
    local id, room, errs = select_start_room(rooms, level, "")
    assert_eq("start-room", id)
    assert_eq("Bedroom", room.name)
    assert_eq(0, #errs)
end)

test("override works without level data (fallback to start-room)", function()
    local rooms = make_rooms()
    local id, room, errs = select_start_room(rooms, nil, "hallway")
    -- No level.rooms to validate against, so hallway is invalid
    assert_eq("start-room", id, "no level means override can't validate")
    assert_true(#errs > 0)
end)

test("override to default room is a no-op", function()
    local rooms = make_rooms()
    local level = make_level()
    local id, room, errs = select_start_room(rooms, level, "start-room")
    assert_eq("start-room", id)
    assert_eq("Bedroom", room.name)
    assert_eq(0, #errs)
end)

---------------------------------------------------------------------------
-- CLI integration: run main.lua --headless --room to verify end-to-end
---------------------------------------------------------------------------

test("CLI --room hallway starts in hallway", function()
    local cmd = 'echo look | lua src/main.lua --headless --room hallway 2>&1'
    local handle = io.popen(cmd)
    if not handle then error("failed to run command") end
    local output = handle:read("*a")
    handle:close()
    assert_match("Starting in room", output, "should show room override message")
    assert_match("hallway", output:lower(), "output should reference hallway")
end)

test("CLI --room bogus falls back with error", function()
    local cmd = 'echo look | lua src/main.lua --headless --room bogus 2>&1'
    local handle = io.popen(cmd)
    if not handle then error("failed to run command") end
    local output = handle:read("*a")
    handle:close()
    assert_match("not found", output:lower(), "should report room not found")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------

print("--- Results ---")
print("  Passed: " .. tests_passed)
print("  Failed: " .. tests_failed)

if tests_failed > 0 then
    print("Failures:")
    os.exit(1)
end
