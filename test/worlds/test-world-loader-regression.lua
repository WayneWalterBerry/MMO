-- test/worlds/test-world-loader-regression.lua
-- Regression tests: manor continues working with the new world loader (WAVE-0).
-- Spec: projects/wyatt-world/plan.md §7.1 (Smoke Tests), §4.0.9
-- Ensures existing game is not broken by multi-world engine changes.

package.path = "src/?.lua;src/?/init.lua;" .. package.path
local t = require("test.parser.test-helpers")
local world_mod = require("engine.world")

local SEP = package.config:sub(1, 1)
local is_windows = SEP == "\\"

local function mock_load_source(source)
    local chunk, err
    if _VERSION == "Lua 5.1" then
        chunk, err = loadstring(source)
    else
        chunk, err = load(source)
    end
    if not chunk then return nil, err end
    local ok, result = pcall(chunk)
    if not ok then return nil, result end
    return result, nil
end

local function real_read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

-- Count .lua files in a directory
local function count_lua_files(dir)
    local cmd
    if is_windows then
        cmd = 'dir /b "' .. dir .. '\\*.lua" 2>nul'
    else
        cmd = 'ls "' .. dir .. '"/*.lua 2>/dev/null'
    end
    local handle = io.popen(cmd)
    local count = 0
    if handle then
        for _ in handle:lines() do count = count + 1 end
        handle:close()
    end
    return count
end

-----------------------------------------------------------------------
-- Suite 1: manor boots with world loader
-----------------------------------------------------------------------
t.suite("regression — manor world loads")

t.test("manor boots successfully via discover + select", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local worlds = world_mod.discover(
        worlds_dir,
        function() return {} end,
        real_read_file,
        mock_load_source
    )
    t.assert_truthy(#worlds >= 1, "should discover worlds")
    local world, err = world_mod.select(worlds, "world-1")
    t.assert_truthy(world, "manor should select by id: " .. tostring(err))
    t.assert_eq("world-1", world.id, "selected world should be manor")
end)

t.test("load() forwards world_id (WAVE-0 new signature)", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    -- §5.1: load(worlds_dir, list_lua_files, read_file, load_source, world_id)
    local world, err = world_mod.load(
        worlds_dir,
        function() return {} end,
        real_read_file,
        mock_load_source,
        "world-1"
    )
    t.assert_truthy(world, "load() should forward world_id to select: " .. tostring(err))
    t.assert_eq("world-1", world.id, "loaded world should be manor")
end)

t.test("manor passes validation", function()
    local path = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "world.lua"
    local source = real_read_file(path)
    t.assert_truthy(source, "manor world.lua should be readable")
    local world = mock_load_source(source)
    t.assert_truthy(world, "manor world.lua should parse")
    local ok, err = world_mod.validate(world)
    t.assert_truthy(ok, "manor should pass validation: " .. tostring(err))
end)

-----------------------------------------------------------------------
-- Suite 2: all 7 manor rooms present
-----------------------------------------------------------------------
t.suite("regression — manor rooms")

t.test("manor has 7 room files", function()
    local rooms_dir = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "rooms"
    local count = count_lua_files(rooms_dir)
    t.assert_eq(7, count, "manor should have 7 room .lua files")
end)

t.test("start-room.lua exists", function()
    local path = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP
               .. "rooms" .. SEP .. "start-room.lua"
    local f = io.open(path, "r")
    t.assert_truthy(f, "start-room.lua should exist")
    if f then f:close() end
end)

t.test("each room file parses without error", function()
    local rooms_dir = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "rooms"
    local cmd
    if is_windows then
        cmd = 'dir /b "' .. rooms_dir .. '\\*.lua" 2>nul'
    else
        cmd = 'ls "' .. rooms_dir .. '"/*.lua 2>/dev/null'
    end
    local handle = io.popen(cmd)
    local all_ok = true
    local bad_file = nil
    if handle then
        for fname in handle:lines() do
            fname = fname:match("^%s*(.-)%s*$")
            local path = rooms_dir .. SEP .. fname
            local source = real_read_file(path)
            if source then
                local tbl, err = mock_load_source(source)
                if not tbl then
                    all_ok = false
                    bad_file = fname .. ": " .. tostring(err)
                end
            end
        end
        handle:close()
    end
    t.assert_truthy(all_ok, "all room files should parse: " .. tostring(bad_file))
end)

-----------------------------------------------------------------------
-- Suite 3: manor objects present
-----------------------------------------------------------------------
t.suite("regression — manor objects")

t.test("manor has object files", function()
    local objects_dir = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "objects"
    local count = count_lua_files(objects_dir)
    t.assert_truthy(count > 0, "manor should have object .lua files (got " .. count .. ")")
end)

t.test("manor has 70+ objects", function()
    local objects_dir = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "objects"
    local count = count_lua_files(objects_dir)
    t.assert_truthy(count >= 70, "manor should have 70+ objects (got " .. count .. ")")
end)

-----------------------------------------------------------------------
-- Suite 4: player spawns in start-room
-----------------------------------------------------------------------
t.suite("regression — player start position")

t.test("player spawns in start-room", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local worlds = world_mod.discover(
        worlds_dir,
        function() return {} end,
        real_read_file,
        mock_load_source
    )
    local world, err = world_mod.select(worlds, "world-1")
    t.assert_truthy(world, "world should load: " .. tostring(err))
    local room = world_mod.get_starting_room(world)
    t.assert_eq("start-room", room, "player should spawn in start-room")
end)

-----------------------------------------------------------------------
-- Suite 5: headless boot (integration — existing commands)
-----------------------------------------------------------------------
t.suite("regression — headless boot integration")

t.test("manor boots in headless mode without FATAL errors", function()
    local cmd
    if is_windows then
        cmd = 'echo quit | lua src/main.lua --headless 2>&1'
    else
        cmd = 'echo "quit" | lua src/main.lua --headless 2>&1'
    end
    local handle = io.popen(cmd)
    local output = ""
    if handle then
        output = handle:read("*a") or ""
        handle:close()
    end
    t.assert_truthy(output ~= "", "headless boot should produce output")
    t.assert_truthy(not output:find("FATAL"), "no FATAL errors in output")
end)

t.test("headless 'look' command produces output", function()
    local cmd
    if is_windows then
        -- Use a temp approach: pipe "look" then "quit"
        cmd = '(echo look & echo quit) | lua src/main.lua --headless 2>&1'
    else
        cmd = 'printf "look\\nquit\\n" | lua src/main.lua --headless 2>&1'
    end
    local handle = io.popen(cmd)
    local output = ""
    if handle then
        output = handle:read("*a") or ""
        handle:close()
    end
    -- "look" in the dark bedroom should produce tactile/darkness response
    t.assert_truthy(#output > 50, "look should produce meaningful output (got "
        .. #output .. " chars)")
end)

t.test("headless 'feel' command works", function()
    local cmd
    if is_windows then
        cmd = '(echo feel & echo quit) | lua src/main.lua --headless 2>&1'
    else
        cmd = 'printf "feel\\nquit\\n" | lua src/main.lua --headless 2>&1'
    end
    local handle = io.popen(cmd)
    local output = ""
    if handle then
        output = handle:read("*a") or ""
        handle:close()
    end
    t.assert_truthy(#output > 50, "feel should produce meaningful output (got "
        .. #output .. " chars)")
end)

local exit_code = t.summary()
os.exit(exit_code > 0 and 1 or 0)
