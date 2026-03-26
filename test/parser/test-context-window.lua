-- test/parser/test-context-window.lua
-- Tier 4 — Context Window unit tests.
-- Tests the context stack, discovery integration, pronoun resolution,
-- "go back" support, and preprocess pipeline transforms.
--
-- Usage: lua test/parser/test-context-window.lua
-- Must be run from the repository root.

-- Set up package path to find engine modules from repo root
local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")
local context_window = require("engine.parser.context")

local test = h.test
local eq   = h.assert_eq

-- Reset context before each test
local function fresh()
    context_window.reset()
end

-------------------------------------------------------------------------------
h.suite("Context Window — Stack operations")
-------------------------------------------------------------------------------

test("push adds object to stack", function()
    fresh()
    context_window.push({ id = "lamp", name = "brass lamp" })
    local top = context_window.peek()
    eq("lamp", top and top.id or nil, "peek should return pushed object")
end)

test("push maintains order (most recent first)", function()
    fresh()
    context_window.push({ id = "lamp", name = "brass lamp" })
    context_window.push({ id = "key", name = "rusty key" })
    context_window.push({ id = "book", name = "old book" })
    local top = context_window.peek()
    eq("book", top.id, "most recent push should be on top")
end)

test("stack limited to 5 objects", function()
    fresh()
    for i = 1, 7 do
        context_window.push({ id = "obj" .. i, name = "Object " .. i })
    end
    local stack = context_window.get_stack()
    eq(5, #stack, "stack should cap at 5")
    eq("obj7", stack[1].id, "newest should be first")
    eq("obj3", stack[5].id, "oldest surviving should be obj3")
end)

test("push deduplicates — moves existing object to top", function()
    fresh()
    context_window.push({ id = "lamp", name = "brass lamp" })
    context_window.push({ id = "key", name = "rusty key" })
    context_window.push({ id = "lamp", name = "brass lamp" })
    local stack = context_window.get_stack()
    eq(2, #stack, "duplicate should be removed, not added")
    eq("lamp", stack[1].id, "duplicate should move to top")
    eq("key", stack[2].id, "other object should shift down")
end)

test("push ignores nil and objects without id", function()
    fresh()
    context_window.push(nil)
    context_window.push({})
    context_window.push({ name = "no id" })
    local stack = context_window.get_stack()
    eq(0, #stack, "invalid pushes should be ignored")
end)

test("push ignores duplicate at top (no-op)", function()
    fresh()
    context_window.push({ id = "lamp", name = "brass lamp" })
    context_window.push({ id = "lamp", name = "brass lamp" })
    local stack = context_window.get_stack()
    eq(1, #stack, "same object pushed twice should only appear once")
end)

-------------------------------------------------------------------------------
h.suite("Context Window — Search discovery tracking")
-------------------------------------------------------------------------------

test("push_discovery adds to both discovery list and context stack", function()
    fresh()
    context_window.push_discovery({ id = "matchbox", name = "small matchbox" })
    local disc = context_window.last_discovery()
    local top = context_window.peek()
    eq("matchbox", disc and disc.id or nil, "last_discovery should return matchbox")
    eq("matchbox", top and top.id or nil, "peek should also return matchbox")
end)

test("push_discovery tracks multiple discoveries", function()
    fresh()
    context_window.push_discovery({ id = "matchbox", name = "small matchbox" })
    context_window.push_discovery({ id = "candle", name = "wax candle" })
    local disc = context_window.last_discovery()
    eq("candle", disc.id, "last_discovery should return most recent")
    local discs = context_window.get_discoveries()
    eq(2, #discs, "should track both discoveries")
end)

test("push_discovery limited to 5", function()
    fresh()
    for i = 1, 7 do
        context_window.push_discovery({ id = "disc" .. i, name = "Disc " .. i })
    end
    local discs = context_window.get_discoveries()
    eq(5, #discs, "discovery list should cap at 5")
end)

test("regular push does not affect discovery list", function()
    fresh()
    context_window.push({ id = "lamp", name = "brass lamp" })
    local disc = context_window.last_discovery()
    eq(nil, disc, "regular push should not add to discoveries")
end)

-------------------------------------------------------------------------------
h.suite("Context Window — Pronoun resolution")
-------------------------------------------------------------------------------

test("resolve 'it' returns top of context stack", function()
    fresh()
    context_window.push({ id = "nightstand", name = "nightstand" })
    local obj = context_window.resolve("it")
    eq("nightstand", obj and obj.id or nil, "'it' should resolve to top of stack")
end)

test("resolve 'that' returns top of context stack", function()
    fresh()
    context_window.push({ id = "nightstand", name = "nightstand" })
    local obj = context_window.resolve("that")
    eq("nightstand", obj and obj.id or nil, "'that' should resolve")
end)

test("resolve 'this' returns top of context stack", function()
    fresh()
    context_window.push({ id = "nightstand", name = "nightstand" })
    local obj = context_window.resolve("this")
    eq("nightstand", obj and obj.id or nil, "'this' should resolve")
end)

test("resolve 'one' returns top of context stack", function()
    fresh()
    context_window.push({ id = "nightstand", name = "nightstand" })
    local obj = context_window.resolve("one")
    eq("nightstand", obj and obj.id or nil, "'one' should resolve")
end)

test("resolve 'the thing I found' returns last discovery", function()
    fresh()
    context_window.push_discovery({ id = "matchbox", name = "small matchbox" })
    local obj = context_window.resolve("the thing I found")
    eq("matchbox", obj and obj.id or nil, "'the thing I found' should resolve from discoveries")
end)

test("resolve 'what I found' returns last discovery", function()
    fresh()
    context_window.push_discovery({ id = "candle", name = "wax candle" })
    local obj = context_window.resolve("what I found")
    eq("candle", obj and obj.id or nil, "'what I found' should resolve from discoveries")
end)

test("resolve 'thing I discovered' returns last discovery", function()
    fresh()
    context_window.push_discovery({ id = "key", name = "rusty key" })
    local obj = context_window.resolve("thing I discovered")
    eq("key", obj and obj.id or nil, "'thing I discovered' should resolve")
end)

test("resolve 'item I found' returns last discovery", function()
    fresh()
    context_window.push_discovery({ id = "gem", name = "red gem" })
    local obj = context_window.resolve("item I found")
    eq("gem", obj and obj.id or nil, "'item I found' should resolve")
end)

test("resolve pronoun returns nil when stack is empty", function()
    fresh()
    local obj = context_window.resolve("it")
    eq(nil, obj, "'it' with empty stack should return nil")
end)

test("resolve discovery reference returns nil when no discoveries", function()
    fresh()
    context_window.push({ id = "lamp", name = "brass lamp" })
    local obj = context_window.resolve("the thing I found")
    eq(nil, obj, "'the thing I found' with no discoveries should return nil")
end)

test("resolve unrecognized noun returns nil", function()
    fresh()
    context_window.push({ id = "lamp", name = "brass lamp" })
    local obj = context_window.resolve("nightstand")
    eq(nil, obj, "specific noun should not resolve from context")
end)

test("pronoun resolves to most recent, not discovery", function()
    fresh()
    context_window.push_discovery({ id = "matchbox", name = "small matchbox" })
    context_window.push({ id = "nightstand", name = "nightstand" })
    local obj = context_window.resolve("it")
    eq("nightstand", obj.id, "'it' should resolve to most recent interaction, not discovery")
end)

-------------------------------------------------------------------------------
h.suite("Context Window — Room history (go back)")
-------------------------------------------------------------------------------

test("previous room is nil initially", function()
    fresh()
    eq(nil, context_window.get_previous_room(), "initial previous room should be nil")
end)

test("set_previous_room stores room ID", function()
    fresh()
    context_window.set_previous_room("bedroom")
    eq("bedroom", context_window.get_previous_room(), "should return stored room ID")
end)

test("set_previous_room overwrites previous value", function()
    fresh()
    context_window.set_previous_room("bedroom")
    context_window.set_previous_room("hallway")
    eq("hallway", context_window.get_previous_room(), "should return most recent room")
end)

test("reset clears previous room", function()
    fresh()
    context_window.set_previous_room("bedroom")
    context_window.reset()
    eq(nil, context_window.get_previous_room(), "reset should clear previous room")
end)

test("reset clears all state", function()
    fresh()
    context_window.push({ id = "lamp", name = "brass lamp" })
    context_window.push_discovery({ id = "key", name = "rusty key" })
    context_window.set_previous_room("cellar")
    context_window.reset()
    eq(nil, context_window.peek(), "reset should clear stack")
    eq(nil, context_window.last_discovery(), "reset should clear discoveries")
    eq(nil, context_window.get_previous_room(), "reset should clear room history")
end)

-------------------------------------------------------------------------------
h.suite("Context Window — Preprocess pipeline: go back / return")
-------------------------------------------------------------------------------

test("'go back' passes through pipeline", function()
    local v, n = preprocess.natural_language("go back")
    eq("go", v, "'go back' verb should be 'go'")
    eq("back", n, "'go back' noun should be 'back'")
end)

test("'return' transforms to 'go back'", function()
    local v, n = preprocess.natural_language("return")
    eq("go", v, "'return' should become verb 'go'")
    eq("back", n, "'return' should become noun 'back'")
end)

test("'retrace my steps' transforms to 'go back'", function()
    local v, n = preprocess.natural_language("retrace my steps")
    eq("go", v, "'retrace my steps' should become verb 'go'")
    eq("back", n, "'retrace my steps' should become noun 'back'")
end)

test("'return to the previous room' transforms to 'go back'", function()
    local v, n = preprocess.natural_language("return to the previous room")
    eq("go", v, "should become verb 'go'")
    eq("back", n, "should become noun 'back'")
end)

test("'go back to where I was' transforms to 'go back'", function()
    local v, n = preprocess.natural_language("Go back to where I was")
    eq("go", v, "should become verb 'go'")
    eq("back", n, "should become noun 'back'")
end)

test("'return the key' does NOT transform to 'go back'", function()
    -- "return X" should be treated as "give back X", not "go back"
    -- natural_language may return nil (no pipeline match), so fallback to parse
    local v, n = preprocess.natural_language("return the key")
    if not v then
        v, n = preprocess.parse("return the key")
    end
    h.assert_truthy(v ~= nil, "'return the key' should parse")
    -- The important thing is it does NOT become "go back"
    if v == "go" then
        h.assert_truthy(n ~= "back", "'return the key' must not become 'go back'")
    end
end)

-------------------------------------------------------------------------------
h.suite("Context Window — Pronoun resolution with verb handlers")
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
            for _, obj in pairs(store) do out[#out + 1] = obj end
            return out
        end,
    }
end

local function make_context(objects)
    local obj_ids = {}
    for _, obj in ipairs(objects) do
        obj_ids[#obj_ids + 1] = obj.id
    end
    local room = {
        id = "test_room", name = "Test Room",
        description = "A bare room for testing.",
        contents = obj_ids, exits = {}, light_level = 1,
    }
    local registry = make_registry(objects)
    registry:set("test_room", room)
    return {
        registry = registry, current_room = room,
        player = { hands = {}, worn = {}, skills = {} },
        verbs = {}, known_objects = {},
        last_object = nil, last_object_loc = nil,
        last_object_parent = nil, last_object_surface = nil,
        game_start_time = os.time(), time_offset = 4,
    }
end

local captured = {}
local real_print = print
local function capture_print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    captured[#captured + 1] = table.concat(parts, "\t")
end
local function start_capture() captured = {}; print = capture_print end
local function stop_capture() print = real_print; return captured end

local function load_verbs(ctx)
    local ok, verbs_mod = pcall(require, "engine.verbs")
    if not ok then return false, tostring(verbs_mod) end
    ctx.verbs = verbs_mod.create()
    return true
end

test("examine sets context — 'examine it' after 'examine lamp' works", function()
    fresh()
    local lamp = {
        id = "lamp", name = "brass lamp",
        keywords = {"lamp", "brass lamp"},
        description = "A dull brass lamp.",
    }
    local ctx = make_context({lamp})
    local ok, err = load_verbs(ctx)
    if not ok then error("Verb loading failed — " .. err) end

    -- Examine lamp → sets context
    start_capture()
    ctx.verbs["examine"](ctx, "lamp")
    stop_capture()
    eq("lamp", ctx.last_object and ctx.last_object.id or nil,
       "examine should set last_object")

    -- "examine it" → should resolve to lamp via context
    start_capture()
    ctx.verbs["examine"](ctx, "it")
    stop_capture()
    -- Verify context still points to lamp (pronoun resolved correctly)
    eq("lamp", ctx.last_object and ctx.last_object.id or nil,
       "'examine it' should resolve 'it' to lamp and keep last_object as lamp")
end)

test("'examine this' resolves to last context object", function()
    fresh()
    local crate = {
        id = "crate", name = "old crate",
        keywords = {"crate"},
        description = "A battered wooden crate.",
    }
    local ctx = make_context({crate})
    local ok, err = load_verbs(ctx)
    if not ok then error("Verb loading failed — " .. err) end

    start_capture()
    ctx.verbs["examine"](ctx, "crate")
    stop_capture()

    start_capture()
    ctx.verbs["examine"](ctx, "this")
    stop_capture()
    eq("crate", ctx.last_object and ctx.last_object.id or nil,
       "'examine this' should resolve to crate via context")
end)

test("context stack tracks multiple objects — pronoun resolves to most recent", function()
    fresh()
    local lamp = {
        id = "lamp", name = "brass lamp",
        keywords = {"lamp"}, description = "A lamp.",
    }
    local crate = {
        id = "crate", name = "old crate",
        keywords = {"crate"}, description = "A crate.",
    }
    local ctx = make_context({lamp, crate})
    local ok, err = load_verbs(ctx)
    if not ok then error("Verb loading failed — " .. err) end

    -- Examine lamp, then crate
    start_capture()
    ctx.verbs["examine"](ctx, "lamp")
    ctx.verbs["examine"](ctx, "crate")
    stop_capture()

    -- Context stack should have crate on top
    local top = context_window.peek()
    eq("crate", top and top.id or nil, "context stack top should be crate")

    -- "examine it" should resolve to crate (most recent)
    start_capture()
    ctx.verbs["examine"](ctx, "it")
    stop_capture()
    eq("crate", ctx.last_object and ctx.last_object.id or nil,
       "'it' should resolve to most recent object (crate)")
end)

test("discovery reference: 'the thing I found' resolves via find_visible", function()
    fresh()
    local matchbox = {
        id = "matchbox", name = "small matchbox",
        keywords = {"matchbox", "matchbox"},
        description = "A small box of matches.",
    }
    local ctx = make_context({matchbox})
    local ok, err = load_verbs(ctx)
    if not ok then error("Verb loading failed — " .. err) end

    -- Simulate search finding the matchbox
    context_window.push_discovery(matchbox)

    -- "examine the thing I found" should resolve to matchbox
    start_capture()
    ctx.verbs["examine"](ctx, "thing i found")
    stop_capture()
    eq("matchbox", ctx.last_object and ctx.last_object.id or nil,
       "'thing I found' should resolve to the discovered matchbox")
end)

-------------------------------------------------------------------------------
h.suite("Context Window — Go back verb handler")
-------------------------------------------------------------------------------

test("'back' handler exists in verb table", function()
    fresh()
    local ctx = make_context({})
    local ok, err = load_verbs(ctx)
    if not ok then error("Verb loading failed — " .. err) end
    h.assert_truthy(ctx.verbs["back"], "'back' handler should be registered")
end)

test("'return' handler exists in verb table", function()
    fresh()
    local ctx = make_context({})
    local ok, err = load_verbs(ctx)
    if not ok then error("Verb loading failed — " .. err) end
    h.assert_truthy(ctx.verbs["return"], "'return' handler should be registered")
end)

test("'go back' with no previous room gives message", function()
    fresh()
    local ctx = make_context({})
    local ok, err = load_verbs(ctx)
    if not ok then error("Verb loading failed — " .. err) end

    start_capture()
    ctx.verbs["go"](ctx, "back")
    local output = stop_capture()
    local got_msg = false
    for _, line in ipairs(output) do
        if line:match("can't go back") or line:match("haven't been") then
            got_msg = true
        end
    end
    h.assert_truthy(got_msg, "'go back' with no history should say you can't go back")
end)

test("'go back' after room transition returns to previous room", function()
    fresh()
    -- Portal object for north exit in Room A → Room B
    local portal_north = {
        id = "portal-a-north",
        template = "portal",
        name = "a doorway",
        keywords = {"door"},
        categories = {"portal"},
        portal = {
            target = "room_b",
            direction_hint = "north",
        },
        initial_state = "open",
        _state = "open",
        states = {
            open = { traversable = true },
        },
        transitions = {},
    }

    -- Set up two rooms with portal-based exits
    local room_a = {
        id = "room_a", name = "Room A",
        description = "Room A.", short_description = "Room A.",
        contents = { "portal-a-north" }, light_level = 1,
        exits = { north = { portal = "portal-a-north" } },
    }
    local room_b = {
        id = "room_b", name = "Room B",
        description = "Room B.", short_description = "Room B.",
        contents = {}, light_level = 1,
        exits = {},
    }

    local registry_store = {
        room_a = room_a, room_b = room_b,
        ["portal-a-north"] = portal_north,
    }
    local registry = {
        get = function(self, id) return registry_store[id] end,
        set = function(self, id, obj) registry_store[id] = obj end,
        all = function(self)
            local out = {}
            for _, obj in pairs(registry_store) do out[#out + 1] = obj end
            return out
        end,
    }

    local ctx = {
        registry = registry, current_room = room_a,
        rooms = { room_a = room_a, room_b = room_b },
        player = { hands = {}, worn = {}, skills = {}, location = "room_a", visited_rooms = { room_a = true } },
        verbs = {}, known_objects = {},
        last_object = nil, last_object_loc = nil,
        last_object_parent = nil, last_object_surface = nil,
        game_start_time = os.time(), time_offset = 4,
    }

    local ok, err = load_verbs(ctx)
    if not ok then error("Verb loading failed — " .. err) end

    -- Move north to Room B
    start_capture()
    ctx.verbs["north"](ctx, "")
    stop_capture()
    eq("room_b", ctx.current_room.id, "should be in Room B after moving north")

    -- Go back → should return to Room A
    start_capture()
    ctx.verbs["go"](ctx, "back")
    local output = stop_capture()
    eq("room_a", ctx.current_room.id, "'go back' should return to Room A")

    local retraced = false
    for _, line in ipairs(output) do
        if line:match("retrace") then retraced = true end
    end
    h.assert_truthy(retraced, "'go back' should say 'retrace your steps'")
end)

-------------------------------------------------------------------------------
-- Tier 4 Enhancement: Context Window Expansion (Prime Directive #106)
-- TDD RED PHASE: Tests NEW APIs on context.lua.
-- All tests below FAIL until the enhancements are implemented by Smithers.
--
-- New APIs being tested:
--   context_window.resolve_repeat(text) → table|nil
--   context_window.set_last_command(verb, noun, raw)
--   context_window.get_last_direction() → string|nil
--   context_window.set_last_direction(dir)
--   context_window.recency_score(obj_id) → number
--   context_window.resolve("the other one") → stack[2]
-------------------------------------------------------------------------------

h.suite("Tier 4 Expansion — Command repeat: 'do it again'")

test("set_last_command stores command", function()
    fresh()
    h.assert_truthy(type(context_window.set_last_command) == "function",
        "context_window.set_last_command() not yet implemented")
    context_window.set_last_command("examine", "candle", "examine the candle")
end)

test("resolve_repeat('again') returns last command", function()
    fresh()
    h.assert_truthy(type(context_window.resolve_repeat) == "function",
        "context_window.resolve_repeat() not yet implemented")
    context_window.set_last_command("examine", "candle", "examine the candle")
    local cmd = context_window.resolve_repeat("again")
    h.assert_truthy(cmd, "'again' should return last command")
    eq("examine", cmd.verb, "verb should be 'examine'")
    eq("candle", cmd.noun, "noun should be 'candle'")
end)

test("resolve_repeat('do it again') returns last command", function()
    fresh()
    h.assert_truthy(context_window.resolve_repeat,
        "context_window.resolve_repeat() not yet implemented")
    context_window.set_last_command("take", "match", "take the match")
    local cmd = context_window.resolve_repeat("do it again")
    h.assert_truthy(cmd, "'do it again' should return last command")
    eq("take", cmd.verb)
end)

test("resolve_repeat('repeat') returns last command", function()
    fresh()
    h.assert_truthy(context_window.resolve_repeat,
        "context_window.resolve_repeat() not yet implemented")
    context_window.set_last_command("open", "drawer", "open drawer")
    local cmd = context_window.resolve_repeat("repeat")
    h.assert_truthy(cmd, "'repeat' should return last command")
    eq("open", cmd.verb)
end)

test("resolve_repeat with no prior command returns nil", function()
    fresh()
    h.assert_truthy(context_window.resolve_repeat,
        "context_window.resolve_repeat() not yet implemented")
    local cmd = context_window.resolve_repeat("again")
    eq(nil, cmd, "'again' with no history should return nil")
end)

h.suite("Tier 4 Expansion — 'The other one' disambiguation")

test("'the other one' resolves to stack[2] (second most recent)", function()
    fresh()
    context_window.push({ id = "candle", name = "tallow candle" })
    context_window.push({ id = "mirror", name = "silver mirror" })
    -- Stack: [mirror, candle]. "the other one" should return candle.
    local obj = context_window.resolve("the other one")
    h.assert_truthy(obj, "'the other one' should resolve to second item in stack")
    eq("candle", obj.id, "should resolve to the PREVIOUS object, not the most recent")
end)

test("'the other one' returns nil with only one item in stack", function()
    fresh()
    context_window.push({ id = "candle", name = "tallow candle" })
    local obj = context_window.resolve("the other one")
    eq(nil, obj, "'the other one' should return nil with only one context item")
end)

h.suite("Tier 4 Expansion — Direction history")

test("set_last_direction stores direction", function()
    fresh()
    h.assert_truthy(type(context_window.set_last_direction) == "function",
        "context_window.set_last_direction() not yet implemented")
    context_window.set_last_direction("north")
end)

test("get_last_direction returns stored direction", function()
    fresh()
    h.assert_truthy(context_window.set_last_direction,
        "context_window.set_last_direction() not yet implemented")
    h.assert_truthy(context_window.get_last_direction,
        "context_window.get_last_direction() not yet implemented")
    context_window.set_last_direction("north")
    eq("north", context_window.get_last_direction())
end)

h.suite("Tier 4 Expansion — Recency scoring")

test("recency_score for recently pushed object > 0", function()
    fresh()
    h.assert_truthy(type(context_window.recency_score) == "function",
        "context_window.recency_score() not yet implemented")
    context_window.push({ id = "candle", name = "tallow candle" })
    local score = context_window.recency_score("candle")
    h.assert_truthy(score > 0, "recently pushed object should have positive recency")
end)

test("recency_score for unknown object = 0", function()
    fresh()
    h.assert_truthy(context_window.recency_score,
        "context_window.recency_score() not yet implemented")
    context_window.push({ id = "candle", name = "tallow candle" })
    local score = context_window.recency_score("elephant")
    eq(0, score, "unknown object should have zero recency")
end)

h.suite("Tier 4 Expansion — Context persists across 5+ interactions")

test("context stack persists across 5+ push operations", function()
    fresh()
    for i = 1, 6 do
        context_window.push({ id = "obj" .. i, name = "Object " .. i })
    end
    local stack = context_window.get_stack()
    h.assert_truthy(#stack >= 5, "stack should retain at least 5 entries")
    -- Most recent should be accessible
    local top = context_window.peek()
    eq("obj6", top.id, "most recent object should be on top")
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
