-- test/worlds/test-multi-world-boot.lua
-- Integration test: discovers both worlds from disk, selects each by ID,
-- content paths resolve correctly.

package.path = "src/?.lua;src/?/init.lua;" .. package.path
local t = require("test.parser.test-helpers")
local world_mod = require("engine.world")

local SEP = package.config:sub(1, 1)

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

local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

t.suite("multi-world boot — discover both worlds from disk")

t.test("discover finds manor and wyatt-world", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local worlds = world_mod.discover(worlds_dir, function() return {} end, read_file, mock_load_source)
    t.assert_truthy(#worlds >= 2, "should discover at least 2 worlds, got " .. #worlds)

    local ids = {}
    for _, w in ipairs(worlds) do ids[w.id] = true end
    t.assert_truthy(ids["world-1"], "should find manor (world-1)")
    t.assert_truthy(ids["wyatt-world"], "should find wyatt-world")
end)

t.suite("multi-world boot — select by ID")

t.test("select manor by ID from multiple worlds", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local worlds = world_mod.discover(worlds_dir, function() return {} end, read_file, mock_load_source)
    local world, err = world_mod.select(worlds, "world-1")
    t.assert_truthy(world, "should select manor: " .. tostring(err))
    t.assert_eq("world-1", world.id)
    t.assert_eq("The Manor", world.name)
end)

t.test("select wyatt-world by ID from multiple worlds", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local worlds = world_mod.discover(worlds_dir, function() return {} end, read_file, mock_load_source)
    local world, err = world_mod.select(worlds, "wyatt-world")
    t.assert_truthy(world, "should select wyatt-world: " .. tostring(err))
    t.assert_eq("wyatt-world", world.id)
    t.assert_eq("Wyatt's World", world.name)
    t.assert_eq("E", world.rating)
end)

t.test("select without ID fails with multiple worlds", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local worlds = world_mod.discover(worlds_dir, function() return {} end, read_file, mock_load_source)
    local world, err = world_mod.select(worlds)
    t.assert_nil(world, "should not auto-select with 2+ worlds")
    t.assert_truthy(err and err:find("multiple worlds"), "error should list available worlds")
end)

t.suite("multi-world boot — content paths")

t.test("manor content paths resolve to worlds/manor subdirs", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local worlds = world_mod.discover(worlds_dir, function() return {} end, read_file, mock_load_source)
    local manor, _ = world_mod.select(worlds, "world-1")
    t.assert_truthy(manor, "manor should be found")
    local paths = world_mod.get_content_paths(manor, "src" .. SEP .. "meta")
    t.assert_truthy(paths.rooms_dir:find("manor"), "rooms_dir should contain 'manor'")
    t.assert_truthy(paths.objects_dir:find("manor"), "objects_dir should contain 'manor'")
end)

t.test("wyatt-world content paths resolve to worlds/wyatt-world subdirs", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local worlds = world_mod.discover(worlds_dir, function() return {} end, read_file, mock_load_source)
    local wyatt, _ = world_mod.select(worlds, "wyatt-world")
    t.assert_truthy(wyatt, "wyatt-world should be found")
    local paths = world_mod.get_content_paths(wyatt, "src" .. SEP .. "meta")
    t.assert_truthy(paths.rooms_dir:find("wyatt%-world"), "rooms_dir should contain 'wyatt-world'")
    t.assert_truthy(paths.objects_dir:find("wyatt%-world"), "objects_dir should contain 'wyatt-world'")
end)

t.suite("multi-world boot — load() orchestrator with world_id")

t.test("load with world_id selects correct world", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local world, err = world_mod.load(worlds_dir, function() return {} end, read_file, mock_load_source, "world-1")
    t.assert_truthy(world, "should load manor: " .. tostring(err))
    t.assert_eq("world-1", world.id)
end)

t.test("load without world_id fails with 2+ worlds", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local world, err = world_mod.load(worlds_dir, function() return {} end, read_file, mock_load_source)
    t.assert_nil(world, "should fail without world_id")
    t.assert_truthy(err, "should return error")
end)

local exit_code = t.summary()
os.exit(exit_code > 0 and 1 or 0)
