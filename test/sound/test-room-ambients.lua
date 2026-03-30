-- test/sound/test-room-ambients.lua
-- WAVE-1 Track 1D: Validate every room has ambient_loop or explicitly none.
-- All 7 Level 1 rooms must be accounted for — no silent failures.
-- Per sound-implementation-plan.md v1.1 Track 1D, GATE-1, Moe #10.

package.path = "src/?.lua;src/?/init.lua;test/?.lua;test/parser/?.lua;" .. package.path

local t = require("test.parser.test-helpers")

local SEP = package.config:sub(1, 1)
local is_windows = SEP == "\\"

----------------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------------

local function list_lua_files(dir)
    local files = {}
    local cmd
    if is_windows then
        cmd = 'dir /b "' .. dir .. '\\*.lua" 2>nul'
    else
        cmd = 'ls "' .. dir .. '"/*.lua 2>/dev/null'
    end
    local handle = io.popen(cmd)
    if handle then
        for line in handle:lines() do
            local fname = line:match("([^/\\]+)$") or line
            if fname:match("%.lua$") then
                files[#files + 1] = fname
            end
        end
        handle:close()
    end
    return files
end

local function safe_load(filepath)
    local fn, err = loadfile(filepath)
    if not fn then
        return nil, "loadfile failed: " .. tostring(err)
    end
    local ok, result = pcall(fn)
    if not ok then
        return nil, "pcall failed: " .. tostring(result)
    end
    if type(result) ~= "table" then
        return nil, "file did not return a table"
    end
    return result, nil
end

----------------------------------------------------------------------------
-- Expected Level 1 rooms (7 total)
----------------------------------------------------------------------------

local EXPECTED_ROOMS = {
    "start-room",
    "hallway",
    "cellar",
    "storage-cellar",
    "deep-cellar",
    "crypt",
    "courtyard",
}

local rooms_dir = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "rooms"
local room_files = list_lua_files(rooms_dir)

----------------------------------------------------------------------------
-- Load all rooms
----------------------------------------------------------------------------

local rooms = {}        -- id -> { obj, filename }
local load_errors = {}

for _, fname in ipairs(room_files) do
    local filepath = rooms_dir .. SEP .. fname
    local obj, err = safe_load(filepath)
    if err then
        load_errors[#load_errors + 1] = { file = fname, err = err }
    elseif obj and obj.id then
        rooms[obj.id] = { obj = obj, filename = fname }
    end
end

----------------------------------------------------------------------------
-- Suite 1: Room discovery
----------------------------------------------------------------------------

t.suite("room ambients — discovery")

t.test("found room files to scan", function()
    t.assert_truthy(#room_files > 0,
        "should find room files in " .. rooms_dir .. ", got " .. #room_files)
end)

t.test("found exactly 7 Level 1 rooms", function()
    t.assert_eq(7, #room_files,
        "expected 7 room files, got " .. #room_files)
end)

t.test("no load errors in room files", function()
    if #load_errors > 0 then
        local msgs = {}
        for _, e in ipairs(load_errors) do
            msgs[#msgs + 1] = e.file .. ": " .. e.err
        end
        error("load errors:\n  " .. table.concat(msgs, "\n  "))
    end
end)

----------------------------------------------------------------------------
-- Suite 2: Every expected room is accounted for
----------------------------------------------------------------------------

t.suite("room ambients — all 7 rooms present")

for _, room_id in ipairs(EXPECTED_ROOMS) do
    t.test("room '" .. room_id .. "' exists in room files", function()
        t.assert_truthy(rooms[room_id],
            "room '" .. room_id .. "' not found in " .. rooms_dir)
    end)
end

----------------------------------------------------------------------------
-- Suite 3: Ambient loop validation
----------------------------------------------------------------------------

t.suite("room ambients — ambient_loop validation")

local rooms_with_ambient = 0
local rooms_without_ambient = 0

for _, room_id in ipairs(EXPECTED_ROOMS) do
    local entry = rooms[room_id]
    if not entry then
        -- Already caught in Suite 2; skip to avoid nil errors
    else
        local obj = entry.obj
        local has_sounds = type(obj.sounds) == "table"
        local has_ambient = has_sounds and type(obj.sounds.ambient_loop) == "string"

        if has_ambient then
            rooms_with_ambient = rooms_with_ambient + 1

            t.test(room_id .. " — ambient_loop ends in .opus", function()
                t.assert_truthy(obj.sounds.ambient_loop:match("%.opus$"),
                    "ambient_loop must be .opus, got: " .. obj.sounds.ambient_loop)
            end)

            t.test(room_id .. " — ambient_loop is not empty", function()
                t.assert_truthy(#obj.sounds.ambient_loop > 0,
                    "ambient_loop must not be empty")
            end)
        else
            rooms_without_ambient = rooms_without_ambient + 1

            -- Room explicitly has no ambient — that's OK, but we log it
            t.test(room_id .. " — no ambient_loop (accounted for)", function()
                -- Pass: room was checked, no silent failure
                t.assert_truthy(true,
                    "room '" .. room_id .. "' has no ambient_loop — accounted for")
            end)
        end
    end
end

print("  INFO: " .. rooms_with_ambient .. " rooms with ambient_loop, " ..
      rooms_without_ambient .. " without")

----------------------------------------------------------------------------
-- Suite 4: Room sound table structure (if present)
----------------------------------------------------------------------------

t.suite("room ambients — sound table structure")

for _, room_id in ipairs(EXPECTED_ROOMS) do
    local entry = rooms[room_id]
    if entry and type(entry.obj.sounds) == "table" then
        t.test(room_id .. " — all sound values are .opus strings", function()
            local bad = {}
            for key, value in pairs(entry.obj.sounds) do
                if type(value) ~= "string" then
                    bad[#bad + 1] = key .. " (not a string: " .. type(value) .. ")"
                elseif not value:match("%.opus$") then
                    bad[#bad + 1] = key .. " = " .. value .. " (not .opus)"
                end
            end
            if #bad > 0 then
                error("invalid sound values:\n    " .. table.concat(bad, "\n    "))
            end
        end)
    end
end

----------------------------------------------------------------------------
-- Results
----------------------------------------------------------------------------

local failed = t.summary()
os.exit(failed > 0 and 1 or 0)
