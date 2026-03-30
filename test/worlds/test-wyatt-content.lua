-- test/worlds/test-wyatt-content.lua
-- WAVE-2b: Wyatt's World content loading tests.
-- Verifies world boots, all rooms/objects load, level is valid,
-- player spawns in beast-studio, and hub connects bidirectionally.

package.path = "src/?.lua;src/?/init.lua;" .. package.path
local t = require("test.parser.test-helpers")

local SEP = package.config:sub(1, 1)
local is_windows = SEP == "\\"

local WYATT_ROOT = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "wyatt-world"
local ROOMS_DIR  = WYATT_ROOT .. SEP .. "rooms"
local OBJECTS_DIR = WYATT_ROOT .. SEP .. "objects"
local LEVELS_DIR  = WYATT_ROOT .. SEP .. "levels"

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------

local function load_lua_file(path)
    local f = io.open(path, "r")
    if not f then return nil, "file not found: " .. path end
    local source = f:read("*a")
    f:close()
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
            local fname = line:match("^%s*(.-)%s*$")
            if fname and fname ~= "" and fname ~= ".gitkeep" then
                files[#files + 1] = fname
            end
        end
        handle:close()
    end
    return files
end

-----------------------------------------------------------------------
-- Suite 1: world.lua loads and is valid
-----------------------------------------------------------------------
t.suite("content — world.lua")

local world, world_err = load_lua_file(WYATT_ROOT .. SEP .. "world.lua")

t.test("world.lua loads without error", function()
    t.assert_truthy(world, "world.lua should load: " .. tostring(world_err))
end)

t.test("world.id is wyatt-world", function()
    t.assert_eq("wyatt-world", world.id)
end)

t.test("world.rating is E", function()
    t.assert_eq("E", world.rating)
end)

t.test("world.name is Wyatt's World", function()
    t.assert_eq("Wyatt's World", world.name)
end)

t.test("world.starting_room is beast-studio", function()
    t.assert_eq("beast-studio", world.starting_room)
end)

t.test("world has content_root", function()
    t.assert_truthy(world.content_root, "content_root should be set")
end)

-----------------------------------------------------------------------
-- Suite 2: level definition
-----------------------------------------------------------------------
t.suite("content — level definition")

local level, level_err = load_lua_file(LEVELS_DIR .. SEP .. "level-01.lua")

t.test("level-01.lua loads", function()
    t.assert_truthy(level, "level-01.lua should load: " .. tostring(level_err))
end)

t.test("level has 7 rooms", function()
    t.assert_truthy(level.rooms, "level should have rooms table")
    t.assert_eq(7, #level.rooms, "level should list 7 rooms")
end)

t.test("level start_room is beast-studio", function()
    t.assert_eq("beast-studio", level.start_room)
end)

t.test("level has intro text", function()
    t.assert_truthy(level.intro, "level should have intro")
    t.assert_truthy(level.intro.title, "level intro should have title")
end)

-----------------------------------------------------------------------
-- Suite 3: all 7 rooms load
-----------------------------------------------------------------------
t.suite("content — rooms load")

local room_files = list_lua_files(ROOMS_DIR)

t.test("7 room files found", function()
    t.assert_eq(7, #room_files, "should find 7 room .lua files (got " .. #room_files .. ")")
end)

local expected_room_ids = {
    "beast-studio", "feastables-factory", "money-vault",
    "beast-burger-kitchen", "last-to-leave", "riddle-arena",
    "grand-prize-vault",
}

local loaded_rooms = {}
for _, fname in ipairs(room_files) do
    local path = ROOMS_DIR .. SEP .. fname
    local room, err = load_lua_file(path)
    if room then
        loaded_rooms[room.id] = room
    end

    t.test("room file " .. fname .. " loads", function()
        t.assert_truthy(room, fname .. " should load: " .. tostring(err))
    end)
end

for _, room_id in ipairs(expected_room_ids) do
    t.test("room " .. room_id .. " exists", function()
        t.assert_truthy(loaded_rooms[room_id],
            room_id .. " should be among loaded rooms")
    end)
end

-----------------------------------------------------------------------
-- Suite 4: all 68 objects load
-----------------------------------------------------------------------
t.suite("content — objects load")

local object_files = list_lua_files(OBJECTS_DIR)

t.test("68 object files found", function()
    t.assert_eq(68, #object_files,
        "should find 68 object .lua files (got " .. #object_files .. ")")
end)

local all_objects_parse = true
local bad_object = nil
for _, fname in ipairs(object_files) do
    local path = OBJECTS_DIR .. SEP .. fname
    local obj, err = load_lua_file(path)
    if not obj then
        all_objects_parse = false
        bad_object = fname .. ": " .. tostring(err)
        break
    end
end

t.test("all object files parse without error", function()
    t.assert_truthy(all_objects_parse,
        "all objects should parse: " .. tostring(bad_object))
end)

-----------------------------------------------------------------------
-- Suite 5: player spawns in beast-studio
-----------------------------------------------------------------------
t.suite("content — player spawn")

t.test("world starting_room matches level start_room", function()
    t.assert_eq(world.starting_room, level.start_room,
        "world and level should agree on start room")
end)

t.test("beast-studio room file exists on disk", function()
    local path = ROOMS_DIR .. SEP .. "beast-studio.lua"
    local f = io.open(path, "r")
    t.assert_truthy(f, "beast-studio.lua should exist")
    if f then f:close() end
end)

-----------------------------------------------------------------------
-- Suite 6: hub connects bidirectionally to all 6 challenge rooms
-----------------------------------------------------------------------
t.suite("content — hub bidirectional exits")

local hub = loaded_rooms["beast-studio"]

t.test("beast-studio has 6 exits", function()
    t.assert_truthy(hub, "hub must be loaded")
    local count = 0
    if hub and hub.exits then
        for _ in pairs(hub.exits) do count = count + 1 end
    end
    t.assert_eq(6, count, "hub should have 6 exits (got " .. count .. ")")
end)

local hub_targets = {
    { dir = "north", target = "feastables-factory" },
    { dir = "south", target = "money-vault" },
    { dir = "east",  target = "beast-burger-kitchen" },
    { dir = "west",  target = "last-to-leave" },
    { dir = "up",    target = "riddle-arena" },
    { dir = "down",  target = "grand-prize-vault" },
}

for _, ht in ipairs(hub_targets) do
    t.test("hub " .. ht.dir .. " exit → " .. ht.target, function()
        t.assert_truthy(hub and hub.exits, "hub should have exits")
        local exit = hub.exits[ht.dir]
        t.assert_truthy(exit, "hub should have " .. ht.dir .. " exit")
        t.assert_eq(ht.target, exit.target)
    end)
end

-- Reverse direction map
local reverse = {
    north = "south", south = "north",
    east = "west",   west = "east",
    up = "down",     down = "up",
}

for _, ht in ipairs(hub_targets) do
    t.test(ht.target .. " has return exit to beast-studio", function()
        local room = loaded_rooms[ht.target]
        t.assert_truthy(room, ht.target .. " must be loaded")
        t.assert_truthy(room.exits, ht.target .. " should have exits")
        -- Find any exit pointing back to beast-studio
        local found = false
        for _, exit in pairs(room.exits) do
            if exit.target == "beast-studio" or exit == "beast-studio" then
                found = true
                break
            end
        end
        t.assert_truthy(found,
            ht.target .. " should have an exit back to beast-studio")
    end)
end

local exit_code = t.summary()
os.exit(exit_code > 0 and 1 or 0)
