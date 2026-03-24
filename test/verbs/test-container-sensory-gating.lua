-- test/verbs/test-container-sensory-gating.lua
-- Issue #100: Container sensory gating — open/closed state gates look/feel/search.
-- Smell and listen pass through closed containers.
--
-- Usage: lua test/verbs/test-container-sensory-gating.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")
local registry_mod = require("engine.registry")

local test = h.test
local suite = h.suite
local eq = h.assert_eq

local handlers = verbs_mod.create()

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function capture_output(fn)
    local captured = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        captured[#captured + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Handler error: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

local function make_ctx(opts)
    opts = opts or {}
    local reg = registry_mod.new()
    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A plain test room.",
        contents = opts.room_contents or {},
        exits = opts.exits or {},
    }
    local player = {
        hands = opts.hands or { nil, nil },
        worn = {},
        injuries = {},
        bags = {},
        state = {},
        skills = {},
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = opts.time_offset or 6,  -- 8 AM (daytime) by default
        game_start_time = os.time(),
        current_verb = opts.verb or "",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

-- FSM chest: has _state and states table
local function make_fsm_chest(state, contents)
    return {
        id = "chest",
        name = "a wooden chest",
        keywords = {"chest", "wooden chest"},
        container = true,
        _state = state or "closed",
        initial_state = "closed",
        states = {
            closed = { name = "a closed chest" },
            open   = { name = "an open chest" },
        },
        transitions = {
            { from = "closed", to = "open", verb = "open", message = "You lift the lid." },
            { from = "open", to = "closed", verb = "close", message = "You close the chest." },
        },
        on_feel = "Rough wooden planks, iron-banded.",
        on_smell = "Old wood and iron.",
        on_listen = "A faint rattling from inside.",
        description = "A sturdy wooden chest with iron bands.",
        contents = contents or {},
    }
end

-- Simple flag-based container with FSM for open/closed gating
local function make_simple_box(state, contents)
    return {
        id = "box",
        name = "a cardboard box",
        keywords = {"box", "cardboard box"},
        container = true,
        _state = state or "closed",
        initial_state = "closed",
        states = {
            closed = { name = "a closed box" },
            open   = { name = "an open box" },
        },
        transitions = {
            { from = "closed", to = "open", verb = "open", message = "You open the box." },
            { from = "open", to = "closed", verb = "close", message = "You close the box." },
        },
        on_feel = "Thin, crinkly cardboard.",
        on_smell = "Musty cardboard.",
        description = "A battered cardboard box.",
        contents = contents or {},
    }
end

local function make_coin()
    return {
        id = "coin",
        name = "a gold coin",
        keywords = {"coin", "gold coin"},
        on_feel = "A small, cold metal disc.",
        on_smell = "Faint metallic tang.",
        description = "A shiny gold coin.",
    }
end

-- Light source so "look" tests work (room defaults to dark without one)
local function make_light()
    return {
        id = "lantern",
        name = "a lantern",
        keywords = {"lantern"},
        casts_light = true,
    }
end

---------------------------------------------------------------------------
-- LOOK INSIDE — gating tests
---------------------------------------------------------------------------
suite("Issue #100 — look inside: open container shows contents")

test("look inside open FSM chest shows contents", function()
    local coin = make_coin()
    local chest = make_fsm_chest("open", {"coin"})
    local light = make_light()
    local ctx = make_ctx({ room_contents = {"chest", "lantern"} })
    ctx.registry:register("chest", chest)
    ctx.registry:register("coin", coin)
    ctx.registry:register("lantern", light)
    local output = capture_output(function()
        handlers["look"](ctx, "in chest")
    end)
    h.assert_truthy(output:find("gold coin"), "Should list coin inside open chest")
end)

suite("Issue #100 — look inside: closed container blocked")

test("look inside closed FSM chest says closed", function()
    local coin = make_coin()
    local chest = make_fsm_chest("closed", {"coin"})
    local light = make_light()
    local ctx = make_ctx({ room_contents = {"chest", "lantern"} })
    ctx.registry:register("chest", chest)
    ctx.registry:register("coin", coin)
    ctx.registry:register("lantern", light)
    local output = capture_output(function()
        handlers["look"](ctx, "in chest")
    end)
    h.assert_truthy(output:lower():find("closed"),
        "Should say closed, got: " .. output)
    eq(nil, output:find("gold coin"),
        "Should NOT reveal contents when closed")
end)

test("look inside closed simple box says closed", function()
    local coin = make_coin()
    local box = make_simple_box("closed", {"coin"})
    local light = make_light()
    local ctx = make_ctx({ room_contents = {"box", "lantern"} })
    ctx.registry:register("box", box)
    ctx.registry:register("coin", coin)
    ctx.registry:register("lantern", light)
    local output = capture_output(function()
        handlers["look"](ctx, "in box")
    end)
    h.assert_truthy(output:lower():find("closed"),
        "Should say closed, got: " .. output)
    eq(nil, output:find("gold coin"),
        "Should NOT reveal contents when closed")
end)

test("look inside open simple box shows contents", function()
    local coin = make_coin()
    local box = make_simple_box("open", {"coin"})
    local light = make_light()
    local ctx = make_ctx({ room_contents = {"box", "lantern"} })
    ctx.registry:register("box", box)
    ctx.registry:register("coin", coin)
    ctx.registry:register("lantern", light)
    local output = capture_output(function()
        handlers["look"](ctx, "in box")
    end)
    h.assert_truthy(output:find("gold coin"), "Should list coin inside open box")
end)

test("look inside empty open container says nothing inside", function()
    local chest = make_fsm_chest("open", {})
    local light = make_light()
    local ctx = make_ctx({ room_contents = {"chest", "lantern"} })
    ctx.registry:register("chest", chest)
    ctx.registry:register("lantern", light)
    local output = capture_output(function()
        handlers["look"](ctx, "in chest")
    end)
    h.assert_truthy(output:lower():find("nothing inside"),
        "Should say nothing inside, got: " .. output)
end)

---------------------------------------------------------------------------
-- FEEL INSIDE — gating tests
---------------------------------------------------------------------------
suite("Issue #100 — feel inside: open container lets you feel contents")

test("feel inside open FSM chest reveals contents", function()
    local coin = make_coin()
    local chest = make_fsm_chest("open", {"coin"})
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["feel"](ctx, "inside chest")
    end)
    h.assert_truthy(output:find("gold coin"),
        "Should feel contents of open chest, got: " .. output)
end)

suite("Issue #100 — feel inside: closed container blocked")

test("feel inside closed FSM chest says closed", function()
    local coin = make_coin()
    local chest = make_fsm_chest("closed", {"coin"})
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["feel"](ctx, "inside chest")
    end)
    h.assert_truthy(output:lower():find("closed"),
        "Should say closed, got: " .. output)
    eq(nil, output:find("gold coin"),
        "Should NOT reveal contents by feel when closed")
end)

test("feel inside closed simple box says closed", function()
    local coin = make_coin()
    local box = make_simple_box("closed", {"coin"})
    local ctx = make_ctx({ room_contents = {"box"} })
    ctx.registry:register("box", box)
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["feel"](ctx, "inside box")
    end)
    h.assert_truthy(output:lower():find("closed"),
        "Should say closed, got: " .. output)
    eq(nil, output:find("gold coin"),
        "Should NOT reveal contents by feel when closed")
end)

suite("Issue #100 — feel outside: always works regardless of open/closed")

test("feel closed chest still gives exterior description", function()
    local chest = make_fsm_chest("closed", {"coin"})
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    local output = capture_output(function()
        handlers["feel"](ctx, "chest")
    end)
    h.assert_truthy(output:find("Rough wooden planks"),
        "Should feel outside of closed chest, got: " .. output)
    eq(nil, output:find("gold coin"),
        "Should NOT reveal contents when feeling outside")
end)

---------------------------------------------------------------------------
-- SEARCH — gating tests
---------------------------------------------------------------------------
suite("Issue #100 — search: open container can be searched")

test("search open FSM chest starts search", function()
    local coin = make_coin()
    local chest = make_fsm_chest("open", {"coin"})
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["search"](ctx, "chest")
    end)
    h.assert_truthy(output:lower():find("search"),
        "Should begin searching open chest, got: " .. output)
end)

suite("Issue #100 — search: closed container blocked")

test("search closed FSM chest says closed", function()
    local coin = make_coin()
    local chest = make_fsm_chest("closed", {"coin"})
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["search"](ctx, "chest")
    end)
    h.assert_truthy(output:lower():find("closed"),
        "Should say closed, got: " .. output)
end)

test("search closed simple box says closed", function()
    local coin = make_coin()
    local box = make_simple_box("closed", {"coin"})
    local ctx = make_ctx({ room_contents = {"box"} })
    ctx.registry:register("box", box)
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["search"](ctx, "box")
    end)
    h.assert_truthy(output:lower():find("closed"),
        "Should say closed, got: " .. output)
end)

test("search closed chest for specific item says closed", function()
    local coin = make_coin()
    local chest = make_fsm_chest("closed", {"coin"})
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["search"](ctx, "chest for coin")
    end)
    h.assert_truthy(output:lower():find("closed"),
        "Should say closed, got: " .. output)
end)

---------------------------------------------------------------------------
-- SMELL — passes through closed containers
---------------------------------------------------------------------------
suite("Issue #100 — smell: passes through closed containers")

test("smell closed chest still works", function()
    local chest = make_fsm_chest("closed", {})
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    local output = capture_output(function()
        handlers["smell"](ctx, "chest")
    end)
    h.assert_truthy(output:find("Old wood and iron"),
        "Smell should pass through closed container, got: " .. output)
end)

test("smell open chest still works", function()
    local chest = make_fsm_chest("open", {})
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    local output = capture_output(function()
        handlers["smell"](ctx, "chest")
    end)
    h.assert_truthy(output:find("Old wood and iron"),
        "Smell should work on open container too, got: " .. output)
end)

---------------------------------------------------------------------------
-- LISTEN — passes through closed containers
---------------------------------------------------------------------------
suite("Issue #100 — listen: passes through closed containers")

test("listen to closed chest still works", function()
    local chest = make_fsm_chest("closed", {})
    chest.on_listen = "A faint rattling from inside."
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    local output = capture_output(function()
        handlers["listen"](ctx, "chest")
    end)
    h.assert_truthy(output:find("rattling"),
        "Listen should pass through closed container, got: " .. output)
end)

---------------------------------------------------------------------------
-- Transparent container edge case
---------------------------------------------------------------------------
suite("Issue #100 — transparent container: look through closed")

test("look inside closed transparent container still shows contents", function()
    local coin = make_coin()
    local light = make_light()
    local jar = {
        id = "jar",
        name = "a glass jar",
        keywords = {"jar", "glass jar"},
        container = true,
        transparent = true,
        _state = "closed",
        initial_state = "closed",
        states = {
            closed = { name = "a closed jar" },
            open   = { name = "an open jar" },
        },
        transitions = {},
        description = "A clear glass jar with a lid.",
        contents = {"coin"},
    }
    local ctx = make_ctx({ room_contents = {"jar", "lantern"} })
    ctx.registry:register("jar", jar)
    ctx.registry:register("coin", coin)
    ctx.registry:register("lantern", light)
    local output = capture_output(function()
        handlers["look"](ctx, "in jar")
    end)
    h.assert_truthy(output:find("gold coin"),
        "Transparent closed container should show contents visually, got: " .. output)
end)

test("feel inside closed transparent container still blocked", function()
    local coin = make_coin()
    local jar = {
        id = "jar",
        name = "a glass jar",
        keywords = {"jar", "glass jar"},
        container = true,
        transparent = true,
        _state = "closed",
        initial_state = "closed",
        states = {
            closed = { name = "a closed jar" },
            open   = { name = "an open jar" },
        },
        transitions = {},
        on_feel = "Smooth cold glass.",
        description = "A clear glass jar.",
        contents = {"coin"},
    }
    local ctx = make_ctx({ room_contents = {"jar"} })
    ctx.registry:register("jar", jar)
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["feel"](ctx, "inside jar")
    end)
    h.assert_truthy(output:lower():find("closed"),
        "Transparent but closed jar should block feel, got: " .. output)
    eq(nil, output:find("gold coin"),
        "Should NOT feel inside closed transparent container")
end)

---------------------------------------------------------------------------
h.summary()
