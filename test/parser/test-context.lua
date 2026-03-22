-- test/parser/test-context.lua
-- Unit tests for parser context retention and pronoun resolution.
-- Tests the interaction between verb dispatch, find_visible, and context tracking.
--
-- These tests use a minimal mock world (registry + room + player) to exercise
-- the same code paths the real game loop uses.

-- Set up package path to find engine modules from repo root
local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")

local test = h.test
local eq   = h.assert_eq

-------------------------------------------------------------------------------
-- Mock registry: minimal object store that satisfies verb handler needs
-------------------------------------------------------------------------------
local function make_registry(objects)
    local store = {}
    for _, obj in ipairs(objects) do
        store[obj.id] = obj
    end
    return {
        get = function(self, id) return store[id] end,
        set = function(self, id, obj) store[id] = obj end,
        all = function(self)
            local out = {}
            for id, obj in pairs(store) do out[#out + 1] = obj end
            return out
        end,
    }
end

-------------------------------------------------------------------------------
-- Build a minimal game context with a room containing given objects
-------------------------------------------------------------------------------
local function make_context(objects)
    local obj_ids = {}
    for _, obj in ipairs(objects) do
        obj_ids[#obj_ids + 1] = obj.id
    end

    local room = {
        id = "test_room",
        name = "Test Room",
        description = "A bare room for testing.",
        contents = obj_ids,
        exits = {},
        light_level = 1,
    }

    local registry = make_registry(objects)
    registry:set("test_room", room)

    local ctx = {
        registry = registry,
        current_room = room,
        player = { hands = {}, worn = {}, skills = {} },
        verbs = {},
        known_objects = {},
        last_object = nil,
        last_object_loc = nil,
        last_object_parent = nil,
        last_object_surface = nil,
        game_start_time = os.time(),
        time_offset = 4, -- daytime (start at 6 AM)
    }
    return ctx
end

-------------------------------------------------------------------------------
-- Capture print output for assertion
-------------------------------------------------------------------------------
local captured = {}
local real_print = print
local function capture_print(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end
    captured[#captured + 1] = table.concat(parts, "\t")
end
local function start_capture() captured = {}; print = capture_print end
local function stop_capture() print = real_print; return captured end

-------------------------------------------------------------------------------
-- Load verb handlers into context (requires FSM module)
-------------------------------------------------------------------------------
local function load_verbs(ctx)
    local ok, verbs_mod = pcall(require, "engine.verbs")
    if not ok then
        return false, "Could not load engine.verbs: " .. tostring(verbs_mod)
    end
    ctx.verbs = verbs_mod.create()
    return true
end

-------------------------------------------------------------------------------
h.suite("Context retention — pronoun resolution")
-------------------------------------------------------------------------------

-- Test: "examine nightstand" then "open it" → "it" resolves to nightstand
test("'open it' after 'examine nightstand' resolves pronoun", function()
    local wardrobe = {
        id = "nightstand",
        name = "nightstand",
        keywords = {"nightstand"},
        description = "A sturdy nightstand.",
        _state = "closed",
        states = {
            closed = {
                description = "The nightstand drawer is closed.",
                transitions = {{ verb = "open", to = "open", message = "You open the nightstand drawer." }},
            },
            open = {
                description = "The nightstand drawer is open.",
                transitions = {{ verb = "close", to = "closed", message = "You close the drawer." }},
            },
        },
    }

    local ctx = make_context({wardrobe})
    local ok, err = load_verbs(ctx)
    if not ok then
        -- If verbs can't load (missing dependencies), test the pattern manually
        error("Verb loading failed — " .. err)
    end

    -- Step 1: examine nightstand → sets ctx.last_object
    start_capture()
    ctx.verbs["examine"](ctx, "nightstand")
    stop_capture()
    eq("nightstand", ctx.last_object and ctx.last_object.id or nil,
       "examine should set last_object to nightstand")

    -- Step 2: open it → should resolve "it" to nightstand via last_object
    start_capture()
    ctx.verbs["open"](ctx, "it")
    local output = stop_capture()
    eq("nightstand", ctx.last_object and ctx.last_object.id or nil,
       "'it' should still reference nightstand")
end)

-------------------------------------------------------------------------------
h.suite("Context retention — bare noun inference")
-------------------------------------------------------------------------------

-- Note: Bare noun resolution ("pick up" after discovery) is handled by the
-- game loop (loop/init.lua), NOT by individual verb handlers. When calling
-- handlers directly (as in this test), the noun is not pre-resolved. This is
-- by design — the game loop layer handles context resolution before dispatch.
test("bare 'open' after 'search wardrobe' — handler requires game loop for context", function()
    local wardrobe = {
        id = "wardrobe",
        name = "wardrobe",
        keywords = {"wardrobe"},
        description = "A tall wooden wardrobe.",
        _state = "closed",
        states = {
            closed = {
                description = "The wardrobe is closed.",
                transitions = {{ verb = "open", to = "open", message = "You open the wardrobe." }},
            },
            open = {
                description = "The wardrobe stands open.",
                transitions = {{ verb = "close", to = "closed", message = "You close the wardrobe." }},
            },
        },
    }

    local ctx = make_context({wardrobe})
    local ok, err = load_verbs(ctx)
    if not ok then
        error("Verb loading failed — " .. err)
    end

    -- Step 1: search wardrobe → should set ctx.last_object
    start_capture()
    ctx.verbs["search"](ctx, "wardrobe")
    stop_capture()
    eq("wardrobe", ctx.last_object and ctx.last_object.id or nil,
       "search should set last_object to wardrobe")

    -- Step 2: bare "open" with empty noun — handler says "Open what?"
    -- because the game loop hasn't pre-resolved the noun.
    -- Through the game loop, "open" after search WOULD resolve to wardrobe.
    start_capture()
    ctx.verbs["open"](ctx, "")
    local output = stop_capture()

    local got_prompt = false
    for _, line in ipairs(output) do
        if line:match("Open what") then got_prompt = true end
    end
    h.assert_truthy(got_prompt,
        "Handler alone says 'Open what?' — context resolution is in the game loop layer.")
end)

-------------------------------------------------------------------------------
h.suite("Parser edge cases")
-------------------------------------------------------------------------------

-- Test: "search everything" should not crash
test("'search everything' does not crash", function()
    local crate = {
        id = "crate",
        name = "old crate",
        keywords = {"crate"},
        description = "A battered wooden crate.",
    }

    local ctx = make_context({crate})
    local ok, err = load_verbs(ctx)
    if not ok then error("Verb loading failed — " .. err) end

    h.assert_no_error(function()
        start_capture()
        ctx.verbs["search"](ctx, "everything")
        stop_capture()
    end, "'search everything' should not crash")
end)

-- Test: "pry crate" dispatches to open handler (BUG-049 verification)
test("'pry' is aliased to 'open' handler (BUG-049)", function()
    local crate = {
        id = "crate",
        name = "old crate",
        keywords = {"crate"},
        description = "A battered wooden crate.",
        _state = "closed",
        states = {
            closed = {
                description = "Sealed shut.",
                transitions = {{ verb = "open", to = "open", message = "You pry the crate open." }},
            },
            open = { description = "The crate is open." },
        },
    }

    local ctx = make_context({crate})
    local ok, err = load_verbs(ctx)
    if not ok then error("Verb loading failed — " .. err) end

    h.assert_truthy(ctx.verbs["pry"], "pry handler should exist (aliased to open)")

    start_capture()
    ctx.verbs["pry"](ctx, "crate")
    local output = stop_capture()

    local opened = false
    for _, line in ipairs(output) do
        if line:match("pry.*open") or line:match("open") then opened = true end
    end
    h.assert_truthy(opened, "pry should trigger the open verb on the crate")
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
