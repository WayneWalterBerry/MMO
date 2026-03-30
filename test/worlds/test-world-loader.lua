-- test/worlds/test-world-loader.lua
-- Tests for src/engine/world/init.lua: discover, validate, select, load, get_starting_room.

package.path = "src/?.lua;src/?/init.lua;" .. package.path
local t = require("test.parser.test-helpers")
local world_mod = require("engine.world")

t.suite("world loader — module load")

t.test("module loads without error", function()
    t.assert_truthy(world_mod, "world module should load")
    t.assert_truthy(world_mod.discover, "discover function exists")
    t.assert_truthy(world_mod.validate, "validate function exists")
    t.assert_truthy(world_mod.select, "select function exists")
    t.assert_truthy(world_mod.load, "load function exists")
    t.assert_truthy(world_mod.get_starting_room, "get_starting_room function exists")
end)

-- Mock world table matching world-01.lua shape
local mock_world_source = [[
return {
    guid = "fbfaf0de-c263-4c05-b827-209fac43bb20",
    template = "world",
    id = "world-1",
    name = "The Manor",
    description = "A crumbling gothic estate.",
    starting_room = "start-room",
    levels = { 1 },
    theme = {
        pitch = "Gothic domestic horror.",
        era = "Medieval",
        atmosphere = "Oppressive darkness.",
        aesthetic = { materials = {"stone"}, forbidden = {"plastic"} },
        mood = "Dread.",
        tone = "Serious.",
        constraints = {},
        design_notes = "",
    },
    mutations = {},
}
]]

-- Simple mock loader that uses loadstring/load
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

t.suite("world loader — discover()")

t.test("discover finds 1 world from mock", function()
    local function list_files(dir) return { "world-01.lua" } end
    local function read_file(path) return mock_world_source end
    local worlds = world_mod.discover("fake/dir", list_files, read_file, mock_load_source)
    t.assert_eq(1, #worlds, "should find 1 world")
    t.assert_eq("world-1", worlds[1].id, "world id should be world-1")
end)

t.test("discover returns empty array when no files", function()
    local function list_files(dir) return {} end
    local function read_file(path) return nil end
    local worlds = world_mod.discover("fake/dir", list_files, read_file, mock_load_source)
    t.assert_eq(0, #worlds, "should find 0 worlds")
end)

t.suite("world loader — validate()")

t.test("validate accepts valid world", function()
    local world = mock_load_source(mock_world_source)
    local ok, err = world_mod.validate(world)
    t.assert_truthy(ok, "valid world should pass")
    t.assert_nil(err, "no error expected")
end)

t.test("validate rejects missing starting_room", function()
    local world = mock_load_source(mock_world_source)
    world.starting_room = nil
    local ok, err = world_mod.validate(world)
    t.assert_eq(false, ok, "should fail validation")
    t.assert_truthy(err and err:find("starting_room"), "error mentions starting_room")
end)

t.test("validate rejects missing levels", function()
    local world = mock_load_source(mock_world_source)
    world.levels = nil
    local ok, err = world_mod.validate(world)
    t.assert_eq(false, ok, "should fail validation")
    t.assert_truthy(err and err:find("levels"), "error mentions levels")
end)

t.test("validate rejects empty levels", function()
    local world = mock_load_source(mock_world_source)
    world.levels = {}
    local ok, err = world_mod.validate(world)
    t.assert_eq(false, ok, "should fail validation")
    t.assert_truthy(err and err:find("levels"), "error mentions levels")
end)

t.test("validate rejects empty starting_room string", function()
    local world = mock_load_source(mock_world_source)
    world.starting_room = ""
    local ok, err = world_mod.validate(world)
    t.assert_eq(false, ok, "should fail validation")
    t.assert_truthy(err and err:find("starting_room"), "error mentions starting_room")
end)

t.suite("world loader — select()")

t.test("select returns single world", function()
    local world = mock_load_source(mock_world_source)
    local result, err = world_mod.select({ world })
    t.assert_eq("world-1", result.id, "should return the world")
    t.assert_nil(err, "no error expected")
end)

t.test("select returns FATAL for zero worlds", function()
    local result, err = world_mod.select({})
    t.assert_nil(result, "no world expected")
    t.assert_truthy(err and err:find("FATAL"), "error should be FATAL")
end)

t.test("select returns not-implemented for multiple worlds", function()
    local w1 = mock_load_source(mock_world_source)
    local w2 = mock_load_source(mock_world_source)
    local result, err = world_mod.select({ w1, w2 })
    t.assert_nil(result, "no world expected")
    t.assert_truthy(err and err:find("not implemented"), "error should say not implemented")
end)

t.suite("world loader — get_starting_room()")

t.test("get_starting_room returns start-room", function()
    local world = mock_load_source(mock_world_source)
    local room = world_mod.get_starting_room(world)
    t.assert_eq("start-room", room, "starting room should be start-room")
end)

t.suite("world loader — load() orchestrator")

t.test("load discovers, validates, and selects world", function()
    local function list_files(dir) return { "world-01.lua" } end
    local function read_file(path) return mock_world_source end
    local world, err = world_mod.load("fake/dir", list_files, read_file, mock_load_source)
    t.assert_truthy(world, "should return a world")
    t.assert_nil(err, "no error expected")
    t.assert_eq("world-1", world.id, "world id should be world-1")
    t.assert_eq("start-room", world_mod.get_starting_room(world), "starting room via get_starting_room")
end)

t.test("load returns FATAL when no valid worlds", function()
    local function list_files(dir) return {} end
    local function read_file(path) return nil end
    local world, err = world_mod.load("fake/dir", list_files, read_file, mock_load_source)
    t.assert_nil(world, "no world expected")
    t.assert_truthy(err and err:find("FATAL"), "error should be FATAL")
end)

-- Also test against the real world.lua file on disk
t.suite("world loader — real manor/world.lua integration")

t.test("discover finds real manor world", function()
    local SEP = package.config:sub(1, 1)
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"

    local function read_file(path)
        local f = io.open(path, "r")
        if not f then return nil end
        local content = f:read("*a")
        f:close()
        return content
    end

    local worlds = world_mod.discover(worlds_dir, function() return {} end, read_file, mock_load_source)
    t.assert_truthy(#worlds >= 1, "should discover at least 1 world")
    t.assert_eq("world-1", worlds[1].id, "first world should be world-1")
    t.assert_truthy(worlds[1].content_root, "world should have content_root set by discover")
end)

t.test("load real manor/world.lua has required fields", function()
    local SEP = package.config:sub(1, 1)
    local path = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "world.lua"
    local f = io.open(path, "r")
    t.assert_truthy(f, "manor/world.lua file should exist")
    local source = f:read("*a")
    f:close()
    local world = mock_load_source(source)
    t.assert_truthy(world, "manor world should load")
    local ok, err = world_mod.validate(world)
    t.assert_truthy(ok, "manor world should validate: " .. tostring(err))
    t.assert_eq("start-room", world_mod.get_starting_room(world), "starting room should be start-room")
    t.assert_truthy(world.theme, "world should have theme")
    t.assert_truthy(world.name, "world should have name")
end)

local exit_code = t.summary()
os.exit(exit_code > 0 and 1 or 0)
