-- test/worlds/test-world-discovery.lua
-- TDD tests for world discovery system (WAVE-0).
-- Spec: projects/wyatt-world/plan.md §4.0.1, §4.0.2, §5.1
-- Written from spec — Bart implements in parallel.

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

local function real_read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

-----------------------------------------------------------------------
-- Suite 1: discover() finds world.lua in subdirectories
-----------------------------------------------------------------------
t.suite("world discovery — subdirectory scanning")

t.test("discover finds at least one world from src/meta/worlds", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local worlds = world_mod.discover(worlds_dir, function() return {} end, real_read_file, mock_load_source)
    t.assert_truthy(#worlds >= 1, "should discover at least 1 world")
end)

t.test("manor world discovered with id 'world-1'", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local worlds = world_mod.discover(worlds_dir, function() return {} end, real_read_file, mock_load_source)
    local found = false
    for _, w in ipairs(worlds) do
        if w.id == "world-1" then found = true end
    end
    t.assert_truthy(found, "manor world (id='world-1') should be discovered")
end)

t.test("manor world has correct name 'The Manor'", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local worlds = world_mod.discover(worlds_dir, function() return {} end, real_read_file, mock_load_source)
    local manor = nil
    for _, w in ipairs(worlds) do
        if w.id == "world-1" then manor = w end
    end
    t.assert_truthy(manor, "manor should exist")
    t.assert_eq("The Manor", manor.name, "manor name")
end)

t.test("manor world has rating 'M'", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local worlds = world_mod.discover(worlds_dir, function() return {} end, real_read_file, mock_load_source)
    local manor = nil
    for _, w in ipairs(worlds) do
        if w.id == "world-1" then manor = w end
    end
    t.assert_truthy(manor, "manor should exist")
    t.assert_eq("M", manor.rating, "manor rating should be 'M' (Mature)")
end)

t.test("discovered world gets content_root set", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local worlds = world_mod.discover(worlds_dir, function() return {} end, real_read_file, mock_load_source)
    local manor = nil
    for _, w in ipairs(worlds) do
        if w.id == "world-1" then manor = w end
    end
    t.assert_truthy(manor, "manor should exist")
    t.assert_truthy(manor.content_root, "content_root should be set by discover")
    t.assert_truthy(manor.content_root:find("manor"), "content_root should reference manor")
end)

-----------------------------------------------------------------------
-- Suite 2: multiple worlds discovered
-----------------------------------------------------------------------
t.suite("world discovery — multiple worlds")

t.test("discover returns 2 worlds from legacy file list", function()
    local src1 = [[return {
        guid = "a", id = "world-1", name = "The Manor",
        starting_room = "start-room", levels = {1}, theme = {}, rating = "M"
    }]]
    local src2 = [[return {
        guid = "b", id = "wyatt-world", name = "Wyatt's World",
        starting_room = "beast-studio", levels = {1}, theme = {}, rating = "E"
    }]]
    local files_map = {}
    files_map["no-subdirs" .. SEP .. "world-01.lua"] = src1
    files_map["no-subdirs" .. SEP .. "wyatt-world.lua"] = src2

    local function list_files(dir) return { "world-01.lua", "wyatt-world.lua" } end
    local function mock_read(path) return files_map[path] end

    -- "no-subdirs" won't have real subdirs, so Phase 1 finds nothing → Phase 2 runs
    local worlds = world_mod.discover("no-subdirs", list_files, mock_read, mock_load_source)
    t.assert_eq(2, #worlds, "should discover 2 worlds via legacy fallback")
end)

t.test("discovered worlds have distinct ids", function()
    local src1 = [[return { guid="a", id="world-1", name="M", starting_room="sr", levels={1}, theme={} }]]
    local src2 = [[return { guid="b", id="wyatt-world", name="W", starting_room="sr2", levels={1}, theme={} }]]
    local files_map = {}
    files_map["mock" .. SEP .. "w1.lua"] = src1
    files_map["mock" .. SEP .. "w2.lua"] = src2

    local function list_files(dir) return { "w1.lua", "w2.lua" } end
    local function mock_read(path) return files_map[path] end

    local worlds = world_mod.discover("mock", list_files, mock_read, mock_load_source)
    t.assert_eq(2, #worlds)
    local ids = {}
    for _, w in ipairs(worlds) do ids[w.id] = true end
    t.assert_truthy(ids["world-1"], "should have world-1")
    t.assert_truthy(ids["wyatt-world"], "should have wyatt-world")
end)

-----------------------------------------------------------------------
-- Suite 3: graceful handling of missing/broken world files
-----------------------------------------------------------------------
t.suite("world discovery — graceful skip")

t.test("missing world.lua in subfolder is skipped", function()
    local worlds_dir = "src" .. SEP .. "meta" .. SEP .. "worlds"
    local function selective_read(path)
        if path:find("manor") then return real_read_file(path) end
        return nil  -- simulate missing world.lua for other subdirs
    end
    local worlds = world_mod.discover(worlds_dir, function() return {} end, selective_read, mock_load_source)
    t.assert_truthy(#worlds >= 1, "should skip missing world.lua and still find valid worlds")
end)

t.test("malformed world.lua is skipped", function()
    local good = [[return { guid="a", id="world-1", name="M", starting_room="sr", levels={1}, theme={} }]]
    local bad = [[this is not valid lua!!!!]]
    local files_map = {}
    files_map["mock" .. SEP .. "good.lua"] = good
    files_map["mock" .. SEP .. "bad.lua"] = bad

    local function list_files(dir) return { "good.lua", "bad.lua" } end
    local function mock_read(path) return files_map[path] end

    local worlds = world_mod.discover("mock", list_files, mock_read, mock_load_source)
    t.assert_eq(1, #worlds, "should skip malformed world and keep valid one")
    t.assert_eq("world-1", worlds[1].id)
end)

t.test("empty directory returns empty array", function()
    local function list_files(dir) return {} end
    local function no_read(path) return nil end
    local worlds = world_mod.discover("nonexistent", list_files, no_read, mock_load_source)
    t.assert_eq(0, #worlds, "empty directory returns 0 worlds")
end)

local exit_code = t.summary()
os.exit(exit_code > 0 and 1 or 0)
