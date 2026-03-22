-- test/nightstand/test-container-gating-pass028.lua
-- Regression tests for Pass-028 container gating bugs:
--   BUG-095: Wardrobe shows contents while closed
--   BUG-096: Gating message says "nightstand" when player targets "drawer"
--   BUG-097: "look inside drawer" (closed, lit) shows description not "it's closed"

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

-- Build a room with a wardrobe (closed, has inside contents)
local function make_wardrobe_ctx(wardrobe_state)
    local reg = registry_mod.new()

    local room = {
        id = "room",
        name = "A bedroom",
        description = "A dark bedroom.",
        contents = {},
        exits = {},
    }

    local torch = {
        id = "torch",
        name = "a wall torch",
        keywords = {"torch"},
        casts_light = true,
    }

    local cloak = {
        id = "wool-cloak",
        name = "a moth-eaten wool cloak",
        keywords = {"cloak", "wool cloak"},
        description = "A moth-eaten wool cloak.",
        on_feel = "Rough wool, full of holes.",
    }

    local sack = {
        id = "sack",
        name = "a burlap sack",
        keywords = {"sack", "burlap sack"},
        description = "A coarse burlap sack.",
        on_feel = "Rough burlap.",
    }

    local is_closed = (wardrobe_state or "closed") == "closed"
    local wardrobe = {
        id = "wardrobe",
        name = "a heavy wardrobe",
        keywords = {"wardrobe", "armoire"},
        description = "A towering oak wardrobe. The doors are firmly closed.",
        on_feel = "A massive wooden frame, smooth and cold.",
        _state = wardrobe_state or "closed",
        initial_state = "closed",
        surfaces = {
            inside = {
                capacity = 8,
                max_item_size = 4,
                accessible = not is_closed,
                contents = {"wool-cloak", "sack"},
            },
        },
        states = {
            closed = {
                name = "a heavy wardrobe",
                description = "A towering oak wardrobe. The doors are firmly closed.",
                on_feel = "A massive wooden frame, smooth and cold.",
                surfaces = {
                    inside = { capacity = 8, max_item_size = 4, accessible = false, contents = {} },
                },
            },
            open = {
                name = "a heavy wardrobe (open)",
                description = "The massive wardrobe stands open.",
                on_feel = "A massive wooden frame. The doors swing wide.",
                surfaces = {
                    inside = { capacity = 8, max_item_size = 4, accessible = true, contents = {} },
                },
            },
        },
        transitions = {
            { from = "closed", to = "open", verb = "open" },
            { from = "open", to = "closed", verb = "close" },
        },
    }

    reg:register("room", room)
    reg:register("torch", torch)
    reg:register("wool-cloak", cloak)
    reg:register("sack", sack)
    reg:register("wardrobe", wardrobe)

    room.contents = {"torch", "wardrobe"}

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

-- Build a room with a nightstand that has a drawer part (for BUG-096, BUG-097)
local function make_nightstand_ctx(nightstand_state)
    local reg = registry_mod.new()

    local room = {
        id = "room",
        name = "A bedroom",
        description = "A dark bedroom.",
        contents = {},
        exits = {},
    }

    local torch = {
        id = "torch",
        name = "a wall torch",
        keywords = {"torch"},
        casts_light = true,
    }

    local matchbox = {
        id = "matchbox",
        name = "a small matchbox",
        keywords = {"matchbox"},
        description = "A small matchbox.",
        on_feel = "A small cardboard box.",
    }

    local is_open = (nightstand_state or "closed_with_drawer"):find("open") ~= nil
    local nightstand = {
        id = "nightstand",
        name = "a small nightstand",
        keywords = {"nightstand", "night stand"},
        description = "A squat nightstand.",
        on_feel = "Smooth wooden surface.",
        _state = nightstand_state or "closed_with_drawer",
        initial_state = "closed_with_drawer",
        surfaces = {
            top = { capacity = 3, max_item_size = 2, contents = {} },
            inside = {
                capacity = 2,
                max_item_size = 1,
                accessible = is_open,
                contents = {"matchbox"},
            },
        },
        states = {
            closed_with_drawer = {
                name = "a small nightstand",
                description = "A squat nightstand. A small drawer sits closed at the front.",
                on_feel = "Smooth wooden surface. A small drawer handle protrudes.",
                surfaces = {
                    top = { capacity = 3, max_item_size = 2, contents = {} },
                    inside = { capacity = 2, max_item_size = 1, accessible = false, contents = {} },
                },
            },
            open_with_drawer = {
                name = "a small nightstand",
                description = "A squat nightstand. The small drawer is pulled open.",
                on_feel = "Smooth wooden surface. The drawer slides open under your fingers.",
                surfaces = {
                    top = { capacity = 3, max_item_size = 2, contents = {} },
                    inside = { capacity = 2, max_item_size = 1, accessible = true, contents = {} },
                },
            },
        },
        transitions = {
            { from = "closed_with_drawer", to = "open_with_drawer", verb = "open" },
            { from = "open_with_drawer", to = "closed_with_drawer", verb = "close" },
        },
        parts = {
            drawer = {
                id = "nightstand-drawer",
                keywords = {"drawer", "small drawer", "nightstand drawer"},
                name = "a small drawer",
                description = "A shallow wooden drawer, about 12 inches wide and 6 inches deep.",
                on_feel = "Wood, smooth but slightly sticky from old wax.",
            },
        },
    }

    reg:register("room", room)
    reg:register("torch", torch)
    reg:register("matchbox", matchbox)
    reg:register("nightstand", nightstand)

    room.contents = {"torch", "nightstand"}

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
h.suite("BUG-095: Closed wardrobe hides contents")
-------------------------------------------------------------------------------

test("feel wardrobe (closed) → does NOT show inside contents", function()
    if skip_if_no_verbs("feel closed wardrobe") then return end
    local ctx = make_wardrobe_ctx("closed")

    local output = exec_verb(ctx, "feel", "wardrobe")

    truthy(not output:find("wool cloak"),
           "'feel' closed wardrobe should NOT reveal wool cloak, got: " .. output)
    truthy(not output:find("burlap sack"),
           "'feel' closed wardrobe should NOT reveal burlap sack, got: " .. output)
end)

test("look inside wardrobe (closed) → does NOT show contents", function()
    if skip_if_no_verbs("look inside closed wardrobe") then return end
    local ctx = make_wardrobe_ctx("closed")

    local output = exec_verb(ctx, "look", "inside wardrobe")

    truthy(not output:find("wool cloak"),
           "'look inside' closed wardrobe should NOT reveal wool cloak, got: " .. output)
    truthy(not output:find("burlap sack"),
           "'look inside' closed wardrobe should NOT reveal burlap sack, got: " .. output)
end)

test("feel inside wardrobe (closed) → blocked", function()
    if skip_if_no_verbs("feel inside closed wardrobe") then return end
    local ctx = make_wardrobe_ctx("closed")

    local output = exec_verb(ctx, "feel", "inside wardrobe")

    truthy(not output:find("wool cloak"),
           "'feel inside' closed wardrobe should NOT reveal wool cloak, got: " .. output)
end)

test("feel wardrobe (open) → DOES show inside contents", function()
    if skip_if_no_verbs("feel open wardrobe") then return end
    local ctx = make_wardrobe_ctx("open")

    local output = exec_verb(ctx, "feel", "wardrobe")

    truthy(output:find("wool cloak") or output:find("burlap sack"),
           "'feel' open wardrobe SHOULD reveal contents, got: " .. output)
end)

test("look inside wardrobe (open) → DOES show contents", function()
    if skip_if_no_verbs("look inside open wardrobe") then return end
    local ctx = make_wardrobe_ctx("open")

    local output = exec_verb(ctx, "look", "inside wardrobe")

    truthy(output:find("wool cloak") or output:find("burlap sack"),
           "'look inside' open wardrobe SHOULD reveal contents, got: " .. output)
end)

-------------------------------------------------------------------------------
h.suite("BUG-096: Gating message uses target name, not parent name")
-------------------------------------------------------------------------------

test("feel inside drawer (closed) → message references drawer not nightstand", function()
    if skip_if_no_verbs("feel inside drawer gating msg") then return end
    local ctx = make_nightstand_ctx("closed_with_drawer")

    local output = exec_verb(ctx, "feel", "inside drawer")

    truthy(output:find("drawer"),
           "Gating message should reference 'drawer', got: " .. output)
    -- Should NOT say "nightstand" in the gating message
    truthy(not output:find("nightstand"),
           "Gating message should NOT reference 'nightstand', got: " .. output)
end)

test("feel in drawer (closed) → message references drawer not nightstand", function()
    if skip_if_no_verbs("feel in drawer gating msg") then return end
    local ctx = make_nightstand_ctx("closed_with_drawer")

    local output = exec_verb(ctx, "feel", "in drawer")

    truthy(output:find("drawer"),
           "Gating message should reference 'drawer', got: " .. output)
    truthy(not output:find("nightstand"),
           "Gating message should NOT reference 'nightstand', got: " .. output)
end)

-------------------------------------------------------------------------------
h.suite("BUG-097: look inside closed drawer shows 'closed' message")
-------------------------------------------------------------------------------

test("look inside drawer (closed, lit) → says closed, not description", function()
    if skip_if_no_verbs("look inside closed drawer lit") then return end
    local ctx = make_nightstand_ctx("closed_with_drawer")

    local output = exec_verb(ctx, "look", "inside drawer")

    truthy(output:find("closed"),
           "'look inside' closed drawer with light should mention 'closed', got: " .. output)
    -- Should NOT show the physical description of the drawer
    truthy(not output:find("12 inches"),
           "Should NOT show drawer dimensions when closed, got: " .. output)
end)

test("look inside drawer (closed, lit) → does NOT show matchbox", function()
    if skip_if_no_verbs("look inside closed drawer contents") then return end
    local ctx = make_nightstand_ctx("closed_with_drawer")

    local output = exec_verb(ctx, "look", "inside drawer")

    truthy(not output:find("matchbox"),
           "'look inside' closed drawer should NOT reveal matchbox, got: " .. output)
end)

test("look inside drawer (open, lit) → DOES show contents", function()
    if skip_if_no_verbs("look inside open drawer") then return end
    local ctx = make_nightstand_ctx("open_with_drawer")

    local output = exec_verb(ctx, "look", "inside drawer")

    truthy(output:find("matchbox"),
           "'look inside' open drawer SHOULD reveal matchbox, got: " .. output)
end)

-------------------------------------------------------------------------------
-- Run
-------------------------------------------------------------------------------
h.summary()
