-- test/objects/test-tear-cloak.lua
-- TDD tests for Issue #134: tear cloak produces no cloth, result not in hands.
--
-- Root cause: spawn_objects() places items in room.contents, not in player's
-- hands. The tear verb doesn't move spawned items to the hand that held
-- the torn object.
--
-- These tests validate:
--   1. Tearing a cloak produces cloth objects
--   2. Cloth ends up in the player's hands (not just on the floor)
--   3. The cloak itself is gone after tearing
--   4. Narration is produced
--
-- Usage: lua test/objects/test-tear-cloak.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

---------------------------------------------------------------------------
-- Load modules
---------------------------------------------------------------------------
local h    = require("test-helpers")
local test = h.test
local suite = h.suite

-- Load actual engine modules (no self-parameter mocks)
local verbs_mod = require("engine.verbs")
local loader    = require("engine.loader")

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function capture_print(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error(err, 2) end
    return table.concat(lines, "\n")
end

--- Load a .lua object definition from src/meta/objects/
local function load_object(filename)
    local path = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP .. filename
    return dofile(path)
end

--- Build a minimal mock registry
local function make_registry(initial_objects)
    local data = {}
    if initial_objects then
        for k, v in pairs(initial_objects) do data[k] = v end
    end
    return {
        get = function(self, id) return data[id] end,
        register = function(self, id, obj) data[id] = obj end,
        remove = function(self, id) data[id] = nil end,
        _data = data,  -- for test inspection
    }
end

--- Load templates from src/meta/templates/ (needed for resolve_template)
local function load_templates()
    local dir = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "templates" .. SEP
    local templates = {}
    local handle = io.popen('dir /b "' .. dir .. '*.lua" 2>nul')
    if handle then
        for line in handle:lines() do
            local path = dir .. line
            local f = io.open(path, "r")
            if f then
                local source = f:read("*a")
                f:close()
                local def = loader.load_source(source)
                if def and def.id then
                    templates[def.id] = def
                end
            end
        end
        handle:close()
    end
    return templates
end

--- Build object_sources map: object ID → source code string
--- (matches how main.lua builds ctx.object_sources)
local function build_object_sources(templates)
    local dir = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP
    local sources = {}
    local handle = io.popen('dir /b "' .. dir .. '*.lua" 2>nul')
    if handle then
        for line in handle:lines() do
            local path = dir .. line
            local f = io.open(path, "r")
            if f then
                local source = f:read("*a")
                f:close()
                local def = loader.load_source(source)
                if def and def.id then
                    sources[def.id] = source
                end
            end
        end
        handle:close()
    end
    return sources
end

--- Build a minimal game context with a cloak in the player's hand
local function make_ctx_with_cloak()
    local cloak = load_object("wool-cloak.lua")

    local reg = make_registry({ ["wool-cloak"] = cloak })
    local room = { id = "test-room", name = "Test Room", contents = {} }

    local templates = load_templates()
    local object_sources = build_object_sources(templates)

    local player = {
        hands = { "wool-cloak", nil },  -- cloak in left hand
        worn = {},
        max_health = 100,
        injuries = {},
        state = {},
        consciousness = { state = "conscious" },
    }

    local ctx = {
        registry = reg,
        current_room = room,
        player = player,
        object_sources = object_sources,
        loader = loader,  -- actual engine loader (no self parameter)
        templates = templates,
        headless = true,
        game_over = false,
        mutation = {
            mutate = function(reg, ldr, id, source, templates)
                return nil, "not needed for tear"
            end,
        },
    }

    return ctx, cloak
end

---------------------------------------------------------------------------
-- Suite 1: Tearing a cloak produces cloth
---------------------------------------------------------------------------
suite("#134 — Tear cloak produces cloth")

test("tear cloak produces cloth objects", function()
    local handlers = verbs_mod.create()
    local ctx, cloak = make_ctx_with_cloak()

    capture_print(function()
        handlers["tear"](ctx, "cloak")
    end)

    -- Check that cloth exists (either in hands or room)
    local cloth_found = false
    -- Check hands
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local id = type(hand) == "table" and hand.id or hand
            if id and id:match("^cloth") then cloth_found = true end
        end
    end
    -- Check room
    for _, id in ipairs(ctx.current_room.contents) do
        if id:match("^cloth") then cloth_found = true end
    end

    h.assert_truthy(cloth_found,
        "#134: tearing cloak must produce at least one cloth object")
end)

test("cloak is gone after tearing", function()
    local handlers = verbs_mod.create()
    local ctx, cloak = make_ctx_with_cloak()

    capture_print(function()
        handlers["tear"](ctx, "cloak")
    end)

    -- Cloak should not be in registry
    local still_exists = ctx.registry:get("wool-cloak")
    h.assert_nil(still_exists, "#134: cloak must be destroyed after tearing")
end)

---------------------------------------------------------------------------
-- Suite 2: Cloth ends up in player's hands
---------------------------------------------------------------------------
suite("#134 — Cloth goes to player's hands (not just floor)")

test("cloth is in player's hands after tearing cloak", function()
    local handlers = verbs_mod.create()
    local ctx, cloak = make_ctx_with_cloak()

    capture_print(function()
        handlers["tear"](ctx, "cloak")
    end)

    -- At least one hand should hold cloth
    local cloth_in_hands = false
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local id = type(hand) == "table" and hand.id or hand
            if id and id:match("^cloth") then cloth_in_hands = true end
        end
    end

    h.assert_truthy(cloth_in_hands,
        "#134: cloth must be in player's hands after tearing cloak")
end)

test("first cloth piece goes to the hand that held the cloak", function()
    local handlers = verbs_mod.create()
    local ctx, cloak = make_ctx_with_cloak()
    -- Cloak is in hand 1 (left)

    capture_print(function()
        handlers["tear"](ctx, "cloak")
    end)

    local hand1 = ctx.player.hands[1]
    local hand1_id = hand1 and (type(hand1) == "table" and hand1.id or hand1) or nil
    h.assert_truthy(hand1_id and hand1_id:match("^cloth"),
        "#134: first cloth piece should go to the hand that held the cloak (hand 1), got: " .. tostring(hand1_id))
end)

test("second cloth piece goes to other hand or room", function()
    local handlers = verbs_mod.create()
    local ctx, cloak = make_ctx_with_cloak()

    capture_print(function()
        handlers["tear"](ctx, "cloak")
    end)

    -- Second cloth piece should be in hand 2 or room
    local second_found = false
    local hand2 = ctx.player.hands[2]
    if hand2 then
        local id = type(hand2) == "table" and hand2.id or hand2
        if id and id:match("^cloth") then second_found = true end
    end
    for _, id in ipairs(ctx.current_room.contents) do
        if id:match("^cloth") then second_found = true end
    end

    h.assert_truthy(second_found,
        "#134: second cloth piece should be in hand 2 or room")
end)

---------------------------------------------------------------------------
-- Suite 3: Narration
---------------------------------------------------------------------------
suite("#134 — Tear produces narration")

test("tear cloak produces output text", function()
    local handlers = verbs_mod.create()
    local ctx, cloak = make_ctx_with_cloak()

    local output = capture_print(function()
        handlers["tear"](ctx, "cloak")
    end)

    h.assert_truthy(output and #output > 0,
        "#134: tearing cloak must produce narration output")
end)

---------------------------------------------------------------------------
-- Suite 4: rip is an alias for tear
---------------------------------------------------------------------------
suite("#134 — rip is an alias for tear")

test("rip cloak works same as tear cloak", function()
    local handlers = verbs_mod.create()
    local ctx, cloak = make_ctx_with_cloak()

    capture_print(function()
        handlers["rip"](ctx, "cloak")
    end)

    local cloak_gone = ctx.registry:get("wool-cloak") == nil
    h.assert_truthy(cloak_gone, "#134: rip should destroy cloak same as tear")
end)

---------------------------------------------------------------------------
-- Done
---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
