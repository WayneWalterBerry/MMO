-- test/nightstand/test-container-gating.lua
-- Tests for container sensory gating: engine checks open/closed state
-- before revealing container contents to player senses.
--
-- Scenarios:
--   1. Closed container hides contents from look/examine/feel
--   2. Open container reveals contents
--   3. Transparent container allows vision when closed but blocks touch

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local eq   = h.assert_eq
local truthy = h.assert_truthy

local registry_mod = require("engine.registry")

local verbs_ok, verbs_mod = pcall(require, "engine.verbs")
local handlers = verbs_ok and verbs_mod.create() or nil

local function capture_print(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error(err) end
    return table.concat(lines, "\n")
end

local function exec_verb(ctx, verb, noun)
    if not handlers or not handlers[verb] then
        error("Verb handler '" .. verb .. "' not available")
    end
    return capture_print(function()
        handlers[verb](ctx, noun or "")
    end)
end

local function skip_if_no_verbs(test_name)
    if not handlers then
        print("  SKIP " .. test_name .. " (verb handlers not loadable in isolation)")
        return true
    end
    return false
end

-- Build a simple room with a closed container (a chest)
local function make_chest_ctx(state, transparent)
    local reg = registry_mod.new()

    local room = {
        id = "room",
        name = "A room",
        description = "A plain room.",
        contents = {},
        exits = {},
    }

    local torch = {
        id = "torch",
        name = "a wall torch",
        keywords = {"torch"},
        casts_light = true,
    }

    local coin = {
        id = "coin",
        name = "a gold coin",
        keywords = {"coin", "gold coin"},
        description = "A shiny gold coin.",
        on_feel = "A small, cold metal disc.",
    }

    local chest = {
        id = "chest",
        name = "a wooden chest",
        keywords = {"chest", "wooden chest"},
        description = "A sturdy wooden chest with iron bands.",
        on_feel = "Rough wooden planks bound with cold iron bands.",
        container = true,
        contents = {"coin"},
        _state = state or "closed",
        transparent = transparent or false,
        states = {
            closed = {
                name = "a wooden chest",
                description = "A sturdy wooden chest with iron bands. It is closed.",
            },
            open = {
                name = "a wooden chest",
                description = "A sturdy wooden chest with iron bands. It is open.",
            },
        },
        transitions = {
            { from = "closed", to = "open", verb = "open" },
            { from = "open", to = "closed", verb = "close" },
        },
    }

    reg:register("room", room)
    reg:register("torch", torch)
    reg:register("coin", coin)
    reg:register("chest", chest)

    room.contents = {"torch", "chest"}

    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = {nil, nil},
            state = {},
            worn_items = {},
            bags = {},
            worn = {},
        },
        injuries = {},
        last_noun = nil,
        last_object = nil,
        time_offset = 12,
        game_start_time = os.time(),
    }

    return ctx, reg
end

-- Build a transparent container (glass bottle)
local function make_glass_bottle_ctx(state)
    local reg = registry_mod.new()

    local room = {
        id = "room",
        name = "A room",
        description = "A plain room.",
        contents = {},
        exits = {},
    }

    local torch = {
        id = "torch",
        name = "a wall torch",
        keywords = {"torch"},
        casts_light = true,
    }

    local marble = {
        id = "marble",
        name = "a glass marble",
        keywords = {"marble"},
        description = "A small glass marble.",
        on_feel = "A smooth glass sphere.",
    }

    local bottle = {
        id = "bottle",
        name = "a glass bottle",
        keywords = {"bottle", "glass bottle"},
        description = "A clear glass bottle.",
        on_feel = "Smooth, cool glass.",
        container = true,
        contents = {"marble"},
        transparent = true,
        _state = state or "closed",
        states = {
            closed = { description = "A clear glass bottle. It is corked." },
            open = { description = "A clear glass bottle. The cork has been removed." },
        },
    }

    reg:register("room", room)
    reg:register("torch", torch)
    reg:register("marble", marble)
    reg:register("bottle", bottle)

    room.contents = {"torch", "bottle"}

    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = {nil, nil},
            state = {},
            worn_items = {},
            bags = {},
            worn = {},
        },
        injuries = {},
        last_noun = nil,
        last_object = nil,
        time_offset = 12,
        game_start_time = os.time(),
    }

    return ctx, reg
end

-------------------------------------------------------------------------------
h.suite("1. CLOSED CONTAINER — Contents hidden")
-------------------------------------------------------------------------------

test("examine closed chest → does NOT list contents", function()
    if skip_if_no_verbs("examine closed chest") then return end
    local ctx = make_chest_ctx("closed")

    local output = exec_verb(ctx, "examine", "chest")

    truthy(not output:find("gold coin"),
           "'examine' closed chest should NOT reveal gold coin, got: " .. output)
    truthy(not output:find("Inside you see"),
           "Should NOT show 'Inside you see' for closed chest, got: " .. output)
end)

test("look at closed chest → does NOT list contents", function()
    if skip_if_no_verbs("look at closed chest") then return end
    local ctx = make_chest_ctx("closed")

    local output = exec_verb(ctx, "look", "at chest")

    truthy(not output:find("gold coin"),
           "'look at' closed chest should NOT reveal gold coin, got: " .. output)
end)

test("look closed chest → does NOT list contents", function()
    if skip_if_no_verbs("look closed chest") then return end
    local ctx = make_chest_ctx("closed")

    local output = exec_verb(ctx, "look", "chest")

    truthy(not output:find("gold coin"),
           "'look' closed chest should NOT reveal gold coin, got: " .. output)
end)

test("feel closed chest → does NOT list contents", function()
    if skip_if_no_verbs("feel closed chest") then return end
    local ctx = make_chest_ctx("closed")

    local output = exec_verb(ctx, "feel", "chest")

    truthy(not output:find("gold coin"),
           "'feel' closed chest should NOT reveal gold coin, got: " .. output)
    truthy(not output:find("Inside you feel"),
           "Should NOT show 'Inside you feel' for closed chest, got: " .. output)
end)

test("feel inside closed chest → does NOT list contents", function()
    if skip_if_no_verbs("feel inside closed chest") then return end
    local ctx = make_chest_ctx("closed")

    local output = exec_verb(ctx, "feel", "inside chest")

    truthy(not output:find("gold coin"),
           "'feel inside' closed chest should NOT reveal gold coin, got: " .. output)
end)

test("examine closed chest in dark → does NOT list contents", function()
    if skip_if_no_verbs("examine closed chest dark") then return end
    local ctx = make_chest_ctx("closed")
    -- Remove light source for darkness
    ctx.current_room.contents = {"chest"}

    local output = exec_verb(ctx, "examine", "chest")

    truthy(not output:find("gold coin"),
           "'examine' closed chest in dark should NOT reveal gold coin, got: " .. output)
end)

-------------------------------------------------------------------------------
h.suite("2. OPEN CONTAINER — Contents visible")
-------------------------------------------------------------------------------

test("examine open chest → lists contents", function()
    if skip_if_no_verbs("examine open chest") then return end
    local ctx = make_chest_ctx("open")

    local output = exec_verb(ctx, "examine", "chest")

    truthy(output:find("gold coin"),
           "'examine' open chest should show gold coin, got: " .. output)
end)

test("look at open chest → lists contents", function()
    if skip_if_no_verbs("look at open chest") then return end
    local ctx = make_chest_ctx("open")

    local output = exec_verb(ctx, "look", "at chest")

    truthy(output:find("gold coin"),
           "'look at' open chest should show gold coin, got: " .. output)
end)

test("feel open chest → lists contents", function()
    if skip_if_no_verbs("feel open chest") then return end
    local ctx = make_chest_ctx("open")

    local output = exec_verb(ctx, "feel", "chest")

    truthy(output:find("gold coin"),
           "'feel' open chest should show gold coin, got: " .. output)
end)

test("feel inside open chest → lists contents", function()
    if skip_if_no_verbs("feel inside open chest") then return end
    local ctx = make_chest_ctx("open")

    local output = exec_verb(ctx, "feel", "inside chest")

    truthy(output:find("gold coin"),
           "'feel inside' open chest should show gold coin, got: " .. output)
end)

test("examine open chest in dark → lists contents by touch", function()
    if skip_if_no_verbs("examine open chest dark") then return end
    local ctx = make_chest_ctx("open")
    -- Remove light source for darkness
    ctx.current_room.contents = {"chest"}

    local output = exec_verb(ctx, "examine", "chest")

    truthy(output:find("gold coin"),
           "'examine' open chest in dark should show gold coin by touch, got: " .. output)
end)

-------------------------------------------------------------------------------
h.suite("3. TRANSPARENT CONTAINER — Vision when closed, no touch")
-------------------------------------------------------------------------------

test("examine closed transparent bottle → shows contents visually", function()
    if skip_if_no_verbs("examine closed transparent") then return end
    local ctx = make_glass_bottle_ctx("closed")

    local output = exec_verb(ctx, "examine", "bottle")

    truthy(output:find("marble"),
           "'examine' closed transparent bottle should show marble, got: " .. output)
end)

test("look at closed transparent bottle → shows contents visually", function()
    if skip_if_no_verbs("look at closed transparent") then return end
    local ctx = make_glass_bottle_ctx("closed")

    local output = exec_verb(ctx, "look", "at bottle")

    truthy(output:find("marble"),
           "'look at' closed transparent bottle should show marble, got: " .. output)
end)

test("feel closed transparent bottle → does NOT show contents", function()
    if skip_if_no_verbs("feel closed transparent") then return end
    local ctx = make_glass_bottle_ctx("closed")

    local output = exec_verb(ctx, "feel", "bottle")

    truthy(not output:find("marble"),
           "'feel' closed transparent bottle should NOT reveal marble, got: " .. output)
end)

test("feel inside closed transparent bottle → does NOT show contents", function()
    if skip_if_no_verbs("feel inside closed transparent") then return end
    local ctx = make_glass_bottle_ctx("closed")

    local output = exec_verb(ctx, "feel", "inside bottle")

    truthy(not output:find("marble"),
           "'feel inside' closed transparent bottle should NOT reveal marble, got: " .. output)
end)

test("examine open transparent bottle → shows contents", function()
    if skip_if_no_verbs("examine open transparent") then return end
    local ctx = make_glass_bottle_ctx("open")

    local output = exec_verb(ctx, "examine", "bottle")

    truthy(output:find("marble"),
           "'examine' open transparent bottle should show marble, got: " .. output)
end)

test("feel open transparent bottle → shows contents", function()
    if skip_if_no_verbs("feel open transparent") then return end
    local ctx = make_glass_bottle_ctx("open")

    local output = exec_verb(ctx, "feel", "bottle")

    truthy(output:find("marble"),
           "'feel' open transparent bottle should show marble by touch, got: " .. output)
end)

-------------------------------------------------------------------------------
h.suite("4. NO STATE CONTAINER — Backward compatibility")
-------------------------------------------------------------------------------

test("container without _state still shows contents", function()
    if skip_if_no_verbs("no state container") then return end
    local ctx = make_chest_ctx("closed")
    local chest = ctx.registry:get("chest")
    chest._state = nil  -- remove state tracking

    local output = exec_verb(ctx, "examine", "chest")

    truthy(output:find("gold coin"),
           "Container without _state should still show contents (backward compat), got: " .. output)
end)

-------------------------------------------------------------------------------
-- Run
-------------------------------------------------------------------------------
h.summary()
