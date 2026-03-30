-- test/objects/test-sack-capacity.lua
-- Bug #171: Sack capacity too small
-- TDD-FIRST: These tests MUST FAIL on current code to prove the bug exists.
--
-- The sack (container, capacity 8, max_item_size 2) should hold at least 5
-- small items. Narration for containers should use "in" (not "on") based on
-- the container_preposition field.
--
-- Usage: lua test/objects/test-sack-capacity.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")
local registry_mod = require("engine.registry")
local containment_mod = require("engine.containment")

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
        exits = {},
    }
    local player = {
        hands = opts.hands or { nil, nil },
        worn = {},
        injuries = {},
        bags = {},
        state = opts.state or {},
        max_health = 100,
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = opts.verb or "put",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
        containment = containment_mod,
    }
end

-- Realistic sack matching src/meta/worlds/manor/objects/sack.lua
local function make_sack(existing_contents)
    return {
        id = "sack",
        name = "a burlap sack",
        keywords = {"sack", "bag", "burlap sack"},
        material = "fabric",
        size = 1,
        weight = 0.3,
        portable = true,
        on_feel = "Rough burlap.",
        container = true,
        container_preposition = "in",
        capacity = 8,
        max_item_size = 2,
        weight_capacity = 10,
        contents = existing_contents or {},
    }
end

local function make_small_item(id, name, keywords)
    return {
        id = id,
        name = name or ("a " .. id),
        keywords = keywords or {id},
        size = 1,
        weight = 0.1,
        portable = true,
        on_feel = "Small and solid.",
    }
end

---------------------------------------------------------------------------
-- Bug #171: Put key in sack succeeds
---------------------------------------------------------------------------
suite("#171 — sack capacity: basic put")

test("put key in sack succeeds", function()
    local sack = make_sack({})
    local key = make_small_item("key", "a brass key", {"key", "brass key"})

    local ctx = make_ctx()
    ctx.registry:register("sack", sack)
    ctx.registry:register("key", key)
    ctx.player.hands[1] = key
    ctx.player.hands[2] = sack

    local output = capture_output(function()
        handlers["put"](ctx, "key in sack")
    end)

    -- Key should be inside the sack
    local found = false
    for _, id in ipairs(sack.contents) do
        if id == "key" then found = true; break end
    end
    h.assert_truthy(found, "Key should be in sack contents; got output: " .. output)
    h.assert_nil(ctx.player.hands[1], "Key should be removed from hand")
end)

---------------------------------------------------------------------------
-- Bug #171: Put second item in sack (with key already inside)
---------------------------------------------------------------------------
suite("#171 — sack capacity: second item")

test("put candle in sack with key already inside succeeds", function()
    -- Sack has key inside (size 1). Candle is size 1. Capacity is 8.
    -- Total would be 2/8 — should succeed. Bug #171 says this currently fails.
    local key = make_small_item("key", "a brass key", {"key", "brass key"})
    local sack = make_sack({"key"})
    local candle = make_small_item("candle", "a tallow candle", {"candle", "tallow candle"})

    local ctx = make_ctx()
    ctx.registry:register("sack", sack)
    ctx.registry:register("key", key)
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    ctx.player.hands[2] = sack

    local output = capture_output(function()
        handlers["put"](ctx, "candle in sack")
    end)

    -- Candle should be inside the sack alongside the key
    local found_candle = false
    for _, id in ipairs(sack.contents) do
        if id == "candle" then found_candle = true; break end
    end
    h.assert_truthy(found_candle,
        "Candle should be in sack (capacity 8, used 1); got output: " .. output)
end)

---------------------------------------------------------------------------
-- Bug #171: Sack should hold at least 5 small items
---------------------------------------------------------------------------
suite("#171 — sack capacity: 5 small items")

test("sack holds 5 small items", function()
    -- 5 items × size 1 = 5 total. Capacity 8. Should fit.
    local items = {}
    for i = 1, 5 do
        items[i] = make_small_item("item-" .. i, "item " .. i, {"item" .. i})
    end

    local existing_ids = {}
    for i = 1, 4 do
        existing_ids[i] = items[i].id
    end
    local sack = make_sack(existing_ids)

    local ctx = make_ctx()
    ctx.registry:register("sack", sack)
    for _, item in ipairs(items) do
        ctx.registry:register(item.id, item)
    end

    -- Put the 5th item in
    local fifth = items[5]
    ctx.player.hands[1] = fifth
    ctx.player.hands[2] = sack

    local output = capture_output(function()
        handlers["put"](ctx, fifth.id .. " in sack")
    end)

    local found = false
    for _, id in ipairs(sack.contents) do
        if id == fifth.id then found = true; break end
    end
    h.assert_truthy(found,
        "5th item should fit in sack (capacity 8); got output: " .. output)
end)

---------------------------------------------------------------------------
-- Bug #171: Narration uses "in" not "on" for containers
---------------------------------------------------------------------------
suite("#171 — sack narration: preposition 'in'")

test("put key on sack narrates 'in' (not 'on') because sack is a container", function()
    -- Player says "put key on sack". The sack has container_preposition = "in".
    -- BUG: the put handler uses the input preposition "on" verbatim instead of
    -- the container's container_preposition "in". Output says "on a burlap sack"
    -- but should say "in a burlap sack".
    local sack = make_sack({})
    local key = make_small_item("key", "a brass key", {"key", "brass key"})

    local ctx = make_ctx()
    ctx.registry:register("sack", sack)
    ctx.registry:register("key", key)
    ctx.player.hands[1] = key
    ctx.player.hands[2] = sack

    local output = capture_output(function()
        handlers["put"](ctx, "key on sack")
    end)

    -- Should say "in", not "on" — the sack's container_preposition overrides
    h.assert_truthy(output:find("in a burlap sack"),
        "Narration should use container_preposition 'in', not input 'on'; got: " .. output)
end)

test("put key in sack narration uses 'in'", function()
    -- When player says "in" explicitly, it should stay "in".
    local sack = make_sack({})
    local key = make_small_item("key", "a brass key", {"key", "brass key"})

    local ctx = make_ctx()
    ctx.registry:register("sack", sack)
    ctx.registry:register("key", key)
    ctx.player.hands[1] = key
    ctx.player.hands[2] = sack

    local output = capture_output(function()
        handlers["put"](ctx, "key in sack")
    end)

    h.assert_truthy(output:find(" in "),
        "Narration should use 'in' for containers; got: " .. output)
end)

test("containment error uses container_preposition 'in'", function()
    -- When sack is full, the error message should say "in" not "on"
    local sack = make_sack({})
    sack.capacity = 1 -- tiny capacity for test
    local item1 = make_small_item("item-1", "item one", {"item1"})
    local item2 = make_small_item("item-2", "item two", {"item2"})
    sack.contents = {"item-1"} -- already full (1/1)

    local ctx = make_ctx()
    ctx.registry:register("sack", sack)
    ctx.registry:register("item-1", item1)
    ctx.registry:register("item-2", item2)
    ctx.player.hands[1] = item2
    ctx.player.hands[2] = sack

    local output = capture_output(function()
        handlers["put"](ctx, "item2 in sack")
    end)

    -- Error should say "not enough room in" (using container_preposition)
    h.assert_truthy(output:find("not enough room in") or output:find("full"),
        "Capacity error should use 'in' for sack; got: " .. output)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
os.exit(h.summary() > 0 and 1 or 0)
