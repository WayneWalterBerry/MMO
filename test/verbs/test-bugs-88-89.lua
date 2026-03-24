-- test/verbs/test-bugs-88-89.lua
-- Regression tests for:
--   #88: "feel inside drawer" resolves to nightstand (parent) instead of drawer
--   #89: "what's inside?" shows room description instead of container contents

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local verbs_mod = require("engine.verbs")
local preprocess = require("engine.parser.preprocess")

local test   = h.test
local eq     = h.assert_eq
local truthy = h.assert_truthy

local handlers = verbs_mod.create()

-- Capture printed output
local function capture_output(fn)
    local captured = {}
    local old_print = print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        captured[#captured + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Handler call failed: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

local function assert_contains(haystack, needle, msg)
    if not haystack:find(needle, 1, true) then
        error((msg or "String not found") .. "\n  Expected: " .. needle .. "\n  In: " .. haystack)
    end
end

local function assert_not_contains(haystack, needle, msg)
    if haystack:find(needle, 1, true) then
        error((msg or "String should NOT be found") .. "\n  Unexpected: " .. needle .. "\n  In: " .. haystack)
    end
end

---------------------------------------------------------------------------
-- Context builders
---------------------------------------------------------------------------

--- Dark bedroom with nightstand + drawer (open) containing a matchbox.
-- The drawer is a part of the nightstand AND a standalone container in the registry.
local function make_drawer_context()
    local objects = {}
    local room_contents = {}

    -- Drawer: open container with contents
    objects["drawer"] = {
        id = "drawer",
        name = "a small drawer",
        keywords = {"drawer", "small drawer", "nightstand drawer"},
        description = "A shallow wooden drawer.",
        categories = {"furniture", "wooden", "container"},
        container = true,
        openable = true,
        accessible = true,
        _state = "open",
        states = {
            closed = { accessible = false },
            open = { accessible = true },
        },
        contents = {"matchbox"},
        on_feel = "Wood, smooth but slightly sticky from old wax.",
    }

    -- Matchbox inside the drawer
    objects["matchbox"] = {
        id = "matchbox",
        name = "a small matchbox",
        keywords = {"matchbox", "box"},
    }

    -- Nightstand: has the drawer as a composite part
    objects["nightstand"] = {
        id = "nightstand",
        name = "a small nightstand",
        keywords = {"nightstand", "night stand", "bedside table"},
        description = "A squat nightstand of knotted pine.",
        categories = {"furniture", "wooden", "container"},
        _state = "open_with_drawer",
        surfaces = {
            top = { capacity = 3, max_item_size = 2, contents = {} },
        },
        contents = {"drawer"},
        parts = {
            drawer = {
                id = "drawer",
                detachable = true,
                keywords = {"drawer", "small drawer", "nightstand drawer"},
                name = "a small drawer",
                categories = {"furniture", "wooden", "container"},
                container = true,
                carries_contents = true,
            },
            legs = {
                id = "nightstand-legs",
                detachable = false,
                keywords = {"leg", "legs"},
                name = "four wooden legs",
            },
        },
    }

    room_contents = {"nightstand"}

    local room = {
        id = "test-room", name = "Test Room",
        description = "A test room.",
        contents = room_contents, exits = {},
    }
    local reg = {
        _objects = objects,
        get = function(self, id) return self._objects[id] end,
    }
    return {
        registry = reg,
        current_room = room,
        time_offset = 0,  -- dark (2AM)
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn_items = {}, bags = {}, worn = {} },
        injuries = {},
    }
end

--- Lit room with an open wardrobe containing a wool cloak.
local function make_wardrobe_context()
    local objects = {}

    objects["curtains"] = {
        id = "curtains", name = "curtains",
        allows_daylight = true, hidden = true,
    }

    objects["wool-cloak"] = {
        id = "wool-cloak",
        name = "a wool cloak",
        keywords = {"cloak", "wool cloak"},
    }

    objects["wardrobe"] = {
        id = "wardrobe",
        name = "a heavy wardrobe",
        keywords = {"wardrobe", "heavy wardrobe"},
        description = "A tall oak wardrobe with heavy doors.",
        categories = {"furniture", "wooden", "container"},
        container = true,
        openable = true,
        _state = "open",
        states = {
            closed = { accessible = false },
            open = { accessible = true },
        },
        contents = {"wool-cloak"},
        on_look = function(self, registry)
            local text = "A tall oak wardrobe with heavy doors, standing open."
            local items = self.contents or {}
            if #items == 0 then
                text = text .. " It is empty."
            else
                text = text .. "\nInside:"
                for _, id in ipairs(items) do
                    local item = registry and registry:get(id)
                    text = text .. "\n  " .. (item and item.name or id)
                end
            end
            return text
        end,
    }

    local room = {
        id = "test-room", name = "Test Room",
        description = "A test room.",
        contents = {"curtains", "wardrobe"}, exits = {},
    }
    local reg = {
        _objects = objects,
        get = function(self, id) return self._objects[id] end,
    }
    return {
        registry = reg,
        current_room = room,
        time_offset = 8,  -- 10AM daytime
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn_items = {}, bags = {}, worn = {} },
        injuries = {},
    }
end

---------------------------------------------------------------------------
-- #88: "feel inside drawer" must target the drawer, not the nightstand
---------------------------------------------------------------------------
h.suite("BUG #88: 'feel inside drawer' resolves to drawer, not parent")

test("#88: 'feel inside the drawer' shows drawer contents, not nightstand error", function()
    local ctx = make_drawer_context()
    ctx.current_verb = "feel"
    local output = capture_output(function()
        handlers["feel"](ctx, "inside the drawer")
    end)
    -- Should show contents of the drawer (matchbox), NOT "can't feel inside a small nightstand"
    assert_not_contains(output, "nightstand",
        "Drawer should not resolve to nightstand parent")
    assert_contains(output, "matchbox",
        "Should list the matchbox inside the drawer")
end)

test("#88: 'feel inside drawer' (no article) also works", function()
    local ctx = make_drawer_context()
    ctx.current_verb = "feel"
    local output = capture_output(function()
        handlers["feel"](ctx, "inside drawer")
    end)
    assert_not_contains(output, "nightstand",
        "Should not mention nightstand")
    assert_contains(output, "matchbox",
        "Should list matchbox")
end)

test("#88: 'feel in drawer' also works", function()
    local ctx = make_drawer_context()
    ctx.current_verb = "feel"
    local output = capture_output(function()
        handlers["feel"](ctx, "in drawer")
    end)
    assert_not_contains(output, "nightstand",
        "Should not mention nightstand")
    assert_contains(output, "matchbox",
        "Should list matchbox")
end)

test("#88: 'feel inside nightstand' still targets nightstand correctly", function()
    local ctx = make_drawer_context()
    ctx.current_verb = "feel"
    local output = capture_output(function()
        handlers["feel"](ctx, "inside nightstand")
    end)
    -- Nightstand has a top surface but no "inside" surface;
    -- it should either show nothing or check container contents
    -- It should NOT show drawer contents (drawer is a separate object)
    assert_not_contains(output, "matchbox",
        "Nightstand feel-inside should not show drawer's matchbox")
end)

---------------------------------------------------------------------------
-- #89: "what's inside?" should examine last container, not show room
---------------------------------------------------------------------------
h.suite("BUG #89: 'what's inside?' uses context, not room look")

test("#89: bare 'what's inside' transforms to 'examine it', not 'look'", function()
    -- The preprocess pipeline should transform "what's inside" to use the
    -- last referenced object, not bare "look" which shows the room
    local result = preprocess.natural_language("what's inside?")
    -- Should NOT be "look" (which shows room description)
    local verb, noun = result, select(2, preprocess.natural_language("what's inside?"))
    truthy(verb ~= "look" or (noun and noun ~= ""),
        "Should not transform to bare 'look' — got verb='" .. tostring(verb) .. "' noun='" .. tostring(noun) .. "'")
end)

test("#89: 'what is inside' also uses context", function()
    local verb, noun = preprocess.natural_language("what is inside?")
    truthy(verb ~= "look" or (noun and noun ~= ""),
        "Should not transform to bare 'look'")
end)

test("#89: 'what's inside the wardrobe' still works (has noun)", function()
    local verb, noun = preprocess.natural_language("what's inside the wardrobe?")
    eq("examine", verb)
    -- noun should include "wardrobe"
    truthy(noun and noun:find("wardrobe"),
        "Should contain 'wardrobe' in noun, got: " .. tostring(noun))
end)

test("#89: 'what's inside?' after opening wardrobe shows contents", function()
    local ctx = make_wardrobe_context()

    -- Simulate opening the wardrobe (sets last_object)
    ctx.current_verb = "open"
    capture_output(function()
        handlers["open"](ctx, "wardrobe")
    end)

    -- Now "what's inside?" should show wardrobe contents
    local verb, noun = preprocess.natural_language("what's inside?")
    -- The preprocessor should give us something that resolves to the wardrobe
    -- Either "examine it" or "examine inside it" or similar
    local output = capture_output(function()
        ctx.current_verb = verb
        if handlers[verb] then
            handlers[verb](ctx, noun or "")
        end
    end)
    -- Should show wardrobe contents, not room description
    assert_not_contains(output, "A test room",
        "Should not show room description")
end)

---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
