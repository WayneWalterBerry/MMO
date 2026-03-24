-- test/verbs/test-spatial-verbs.lua
-- #111: PUSH/LIFT/SLIDE/MOVE verb coverage for furniture and heavy objects.
-- Tests spatial movement, covering reveal, underneath surfaces, on_move callbacks,
-- and all aliases (shove, heave, drag, nudge, shift).
--
-- Usage: lua test/verbs/test-spatial-verbs.lua

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

local function make_reg()
    return registry_mod.new()
end

local function make_movable_object(id, overrides)
    local obj = {
        guid = "{test-" .. id .. "}",
        id = id,
        name = "a " .. id,
        keywords = {id},
        movable = true,
        moved = false,
        portable = false,
        weight = 40,
        size = 6,
    }
    if overrides then
        for k, v in pairs(overrides) do obj[k] = v end
    end
    return obj
end

local function make_room(reg, objects)
    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A test room.",
        contents = {},
        exits = {},
    }
    for _, obj in ipairs(objects or {}) do
        reg:register(obj.id, obj)
        room.contents[#room.contents + 1] = obj.id
    end
    return room
end

local function make_ctx(reg, room)
    return {
        registry = reg,
        current_room = room,
        rooms = { [room.id] = room },
        player = {
            hands = { nil, nil },
            worn = {},
            injuries = {},
            bags = {},
            state = {},
            location = room.id,
            visited_rooms = {},
        },
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = "",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- 1. PUSH — basic movable object
---------------------------------------------------------------------------
suite("Spatial — push")

test("push movable object sets moved=true", function()
    local reg = make_reg()
    local bed = make_movable_object("bed", {
        push_message = "You shove the bed aside with a grinding shriek.",
    })
    local room = make_room(reg, {bed})
    local ctx = make_ctx(reg, room)

    local output = capture_output(function()
        handlers["push"](ctx, "bed")
    end)

    eq(true, bed.moved, "bed should be marked as moved")
    h.assert_truthy(output:find("grinding shriek"), "Should print push_message")
end)

test("push non-movable object is blocked", function()
    local reg = make_reg()
    local wall = make_movable_object("wall", { movable = false, weight = 200 })
    local room = make_room(reg, {wall})
    local ctx = make_ctx(reg, room)

    local output = capture_output(function()
        handlers["push"](ctx, "wall")
    end)

    eq(false, wall.moved, "wall should not be moved")
    h.assert_truthy(output:find("too heavy"), "Should mention too heavy")
end)

test("push non-movable light object says can't move", function()
    local reg = make_reg()
    local lamp = make_movable_object("lamp", { movable = false, weight = 5 })
    local room = make_room(reg, {lamp})
    local ctx = make_ctx(reg, room)

    local output = capture_output(function()
        handlers["push"](ctx, "lamp")
    end)

    h.assert_truthy(output:find("can't move"), "Should say can't move")
end)

test("push already-moved object says already moved", function()
    local reg = make_reg()
    local bed = make_movable_object("bed")
    bed.moved = true
    local room = make_room(reg, {bed})
    local ctx = make_ctx(reg, room)

    local output = capture_output(function()
        handlers["push"](ctx, "bed")
    end)

    h.assert_truthy(output:find("already moved"), "Should say already moved")
end)

test("push strips trailing 'aside'", function()
    local reg = make_reg()
    local crate = make_movable_object("crate")
    local room = make_room(reg, {crate})
    local ctx = make_ctx(reg, room)

    capture_output(function()
        handlers["push"](ctx, "crate aside")
    end)

    eq(true, crate.moved, "push crate aside should move the crate")
end)

test("push with empty noun asks what", function()
    local output = capture_output(function()
        handlers["push"]({}, "")
    end)
    h.assert_truthy(output:find("Push what"), "Should ask Push what?")
end)

test("push unknown object gives not found", function()
    local reg = make_reg()
    local room = make_room(reg, {})
    local ctx = make_ctx(reg, room)

    local output = capture_output(function()
        handlers["push"](ctx, "unicorn")
    end)

    h.assert_truthy(output:find("see") or output:find("don't") or output:find("not"),
        "Should report object not found")
end)

---------------------------------------------------------------------------
-- 2. PUSH — reveals underneath surfaces and covering
---------------------------------------------------------------------------
suite("Spatial — push reveals hidden items")

test("push covering object reveals hidden object underneath", function()
    local reg = make_reg()
    local trap_door = {
        guid = "{test-trap-door}",
        id = "trap-door",
        name = "a trap door",
        keywords = {"trap door"},
        hidden = true,
        discovery_message = "Beneath the rug, you see a trap door set into the stone floor!",
    }
    local rug = make_movable_object("rug", {
        covering = {"trap-door"},
        move_message = "You pull the rug aside.",
    })
    reg:register(trap_door.id, trap_door)
    local room = make_room(reg, {rug})
    local ctx = make_ctx(reg, room)

    local output = capture_output(function()
        handlers["push"](ctx, "rug")
    end)

    eq(true, rug.moved, "rug should be moved")
    eq(false, trap_door.hidden, "trap door should no longer be hidden")
    h.assert_truthy(output:find("trap door"), "Should mention trap door discovery")
end)

test("push covering object dumps underneath surface contents to floor", function()
    local reg = make_reg()
    local key = {
        guid = "{test-key}",
        id = "brass-key",
        name = "a brass key",
        keywords = {"key"},
        location = nil,
    }
    reg:register(key.id, key)
    local rug = make_movable_object("rug", {
        covering = true,
        surfaces = {
            underneath = { capacity = 3, contents = {"brass-key"}, accessible = false },
        },
    })
    -- covering must be truthy (table for object IDs, or boolean for surface-only)
    rug.covering = {}
    local room = make_room(reg, {rug})
    local ctx = make_ctx(reg, room)

    -- Manually set covering flag for surface dump logic
    rug.covering = {}

    local output = capture_output(function()
        handlers["push"](ctx, "rug")
    end)

    eq(true, rug.moved, "rug should be moved")
    -- Surface contents should be emptied and items added to room
    eq(true, rug.surfaces.underneath.accessible, "underneath should be accessible")
end)

test("push object blocked by resting object", function()
    local reg = make_reg()
    local bed = make_movable_object("bed")
    local cat = make_movable_object("cat", { resting_on = "bed" })
    local room = make_room(reg, {bed, cat})
    local ctx = make_ctx(reg, room)

    local output = capture_output(function()
        handlers["push"](ctx, "bed")
    end)

    eq(false, bed.moved, "bed should not move (cat resting on it)")
    h.assert_truthy(output:find("sitting on") or output:find("need to move"),
        "Should mention something is on the bed")
end)

---------------------------------------------------------------------------
-- 3. PUSH — updates room_presence/description on move
---------------------------------------------------------------------------
suite("Spatial — push updates state")

test("push updates room_presence and description", function()
    local reg = make_reg()
    local bed = make_movable_object("bed", {
        room_presence = "A bed sits in the center.",
        moved_room_presence = "The bed has been shoved aside.",
        description = "A big bed.",
        moved_description = "The bed is now against the wall.",
        on_feel = "Soft mattress.",
        moved_on_feel = "Shoved against the wall.",
    })
    local room = make_room(reg, {bed})
    local ctx = make_ctx(reg, room)

    capture_output(function()
        handlers["push"](ctx, "bed")
    end)

    eq("The bed has been shoved aside.", bed.room_presence)
    eq("The bed is now against the wall.", bed.description)
    eq("Shoved against the wall.", bed.on_feel)
end)

---------------------------------------------------------------------------
-- 4. LIFT — movable, portable, and heavy
---------------------------------------------------------------------------
suite("Spatial — lift")

test("lift movable object uses move_spatial_object with 'lift' verb", function()
    local reg = make_reg()
    local rug = make_movable_object("rug", {
        lift_message = "You heave the rug up and toss it aside.",
    })
    local room = make_room(reg, {rug})
    local ctx = make_ctx(reg, room)

    local output = capture_output(function()
        handlers["lift"](ctx, "rug")
    end)

    eq(true, rug.moved, "rug should be moved")
    h.assert_truthy(output:find("heave the rug"), "Should print lift_message")
end)

test("lift portable object delegates to take", function()
    local reg = make_reg()
    local coin = {
        guid = "{test-coin}",
        id = "coin",
        name = "a gold coin",
        keywords = {"coin"},
        portable = true,
        movable = false,
        weight = 1,
        size = 1,
    }
    local room = make_room(reg, {coin})
    local ctx = make_ctx(reg, room)

    local output = capture_output(function()
        handlers["lift"](ctx, "coin")
    end)

    -- Should delegate to take handler (pick up)
    -- Exact behavior depends on take handler, but it shouldn't error
    h.assert_truthy(output ~= "", "Should produce some output (take delegation)")
end)

test("lift heavy non-movable object says too heavy", function()
    local reg = make_reg()
    local anvil = make_movable_object("anvil", { movable = false, weight = 100 })
    local room = make_room(reg, {anvil})
    local ctx = make_ctx(reg, room)

    local output = capture_output(function()
        handlers["lift"](ctx, "anvil")
    end)

    h.assert_truthy(output:find("too heavy"), "Should say too heavy")
end)

test("lift light non-movable non-portable says can't lift", function()
    local reg = make_reg()
    local post = make_movable_object("post", { movable = false, weight = 10, portable = false })
    local room = make_room(reg, {post})
    local ctx = make_ctx(reg, room)

    local output = capture_output(function()
        handlers["lift"](ctx, "post")
    end)

    h.assert_truthy(output:find("can't lift"), "Should say can't lift")
end)

test("lift strips trailing 'up'", function()
    local reg = make_reg()
    local rug = make_movable_object("rug")
    local room = make_room(reg, {rug})
    local ctx = make_ctx(reg, room)

    capture_output(function()
        handlers["lift"](ctx, "rug up")
    end)

    eq(true, rug.moved, "lift rug up should move the rug")
end)

test("lift with empty noun asks what", function()
    local output = capture_output(function()
        handlers["lift"]({}, "")
    end)
    h.assert_truthy(output:find("Lift what"), "Should ask Lift what?")
end)

---------------------------------------------------------------------------
-- 5. SLIDE — distinct verb narrative
---------------------------------------------------------------------------
suite("Spatial — slide")

test("slide movable object uses 'slide' verb in message", function()
    local reg = make_reg()
    local wardrobe = make_movable_object("wardrobe")
    local room = make_room(reg, {wardrobe})
    local ctx = make_ctx(reg, room)

    local output = capture_output(function()
        handlers["slide"](ctx, "wardrobe")
    end)

    eq(true, wardrobe.moved, "wardrobe should be moved")
    h.assert_truthy(output:find("slide"), "Should use 'slide' in the fallback message")
end)

test("slide uses slide_message if object declares one", function()
    local reg = make_reg()
    local wardrobe = make_movable_object("wardrobe", {
        slide_message = "The wardrobe scrapes across the floor, revealing a passage.",
    })
    local room = make_room(reg, {wardrobe})
    local ctx = make_ctx(reg, room)

    local output = capture_output(function()
        handlers["slide"](ctx, "wardrobe")
    end)

    h.assert_truthy(output:find("scrapes across"), "Should print slide_message")
end)

test("slide strips trailing 'aside'", function()
    local reg = make_reg()
    local shelf = make_movable_object("shelf")
    local room = make_room(reg, {shelf})
    local ctx = make_ctx(reg, room)

    capture_output(function()
        handlers["slide"](ctx, "shelf aside")
    end)

    eq(true, shelf.moved, "slide shelf aside should move it")
end)

test("slide with empty noun asks what", function()
    local output = capture_output(function()
        handlers["slide"]({}, "")
    end)
    h.assert_truthy(output:find("Slide what"), "Should ask Slide what?")
end)

---------------------------------------------------------------------------
-- 6. MOVE — general spatial
---------------------------------------------------------------------------
suite("Spatial — move")

test("move movable object works", function()
    local reg = make_reg()
    local box = make_movable_object("box")
    local room = make_room(reg, {box})
    local ctx = make_ctx(reg, room)

    local output = capture_output(function()
        handlers["move"](ctx, "box")
    end)

    eq(true, box.moved, "box should be moved")
    h.assert_truthy(output:find("move"), "Should use 'move' in message")
end)

test("move with empty noun asks what", function()
    local output = capture_output(function()
        handlers["move"]({}, "")
    end)
    h.assert_truthy(output:find("Move what"), "Should ask Move what?")
end)

---------------------------------------------------------------------------
-- 7. ALIASES — shove, heave, drag, nudge, shift
---------------------------------------------------------------------------
suite("Spatial — verb aliases")

test("shove delegates to push", function()
    local reg = make_reg()
    local crate = make_movable_object("crate")
    local room = make_room(reg, {crate})
    local ctx = make_ctx(reg, room)

    capture_output(function()
        handlers["shove"](ctx, "crate")
    end)

    eq(true, crate.moved, "shove should move the crate (push alias)")
end)

test("heave delegates to lift", function()
    local reg = make_reg()
    local rug = make_movable_object("rug")
    local room = make_room(reg, {rug})
    local ctx = make_ctx(reg, room)

    capture_output(function()
        handlers["heave"](ctx, "rug")
    end)

    eq(true, rug.moved, "heave should move the rug (lift alias)")
end)

test("drag delegates to move", function()
    local reg = make_reg()
    local sack = make_movable_object("sack")
    local room = make_room(reg, {sack})
    local ctx = make_ctx(reg, room)

    capture_output(function()
        handlers["drag"](ctx, "sack")
    end)

    eq(true, sack.moved, "drag should move the sack (move alias)")
end)

test("nudge delegates to push", function()
    local reg = make_reg()
    local barrel = make_movable_object("barrel")
    local room = make_room(reg, {barrel})
    local ctx = make_ctx(reg, room)

    capture_output(function()
        handlers["nudge"](ctx, "barrel")
    end)

    eq(true, barrel.moved, "nudge should move the barrel (push alias)")
end)

test("shift delegates to move", function()
    local reg = make_reg()
    local trunk = make_movable_object("trunk")
    local room = make_room(reg, {trunk})
    local ctx = make_ctx(reg, room)

    capture_output(function()
        handlers["shift"](ctx, "trunk")
    end)

    eq(true, trunk.moved, "shift should move the trunk (move alias)")
end)

---------------------------------------------------------------------------
-- 8. on_move CALLBACK
---------------------------------------------------------------------------
suite("Spatial — on_move callback")

test("on_move callback fires when object is moved", function()
    local reg = make_reg()
    local callback_fired = false
    local callback_verb = nil
    local box = make_movable_object("box", {
        on_move = function(self, ctx, verb)
            callback_fired = true
            callback_verb = verb
        end,
    })
    local room = make_room(reg, {box})
    local ctx = make_ctx(reg, room)

    capture_output(function()
        handlers["push"](ctx, "box")
    end)

    eq(true, callback_fired, "on_move callback should fire")
    eq("push", callback_verb, "callback should receive the verb used")
end)

test("on_move callback receives correct verb for slide", function()
    local reg = make_reg()
    local callback_verb = nil
    local panel = make_movable_object("panel", {
        on_move = function(self, ctx, verb)
            callback_verb = verb
        end,
    })
    local room = make_room(reg, {panel})
    local ctx = make_ctx(reg, room)

    capture_output(function()
        handlers["slide"](ctx, "panel")
    end)

    eq("slide", callback_verb, "callback should receive 'slide' as verb")
end)

test("on_move callback receives correct verb for lift", function()
    local reg = make_reg()
    local callback_verb = nil
    local mat = make_movable_object("mat", {
        on_move = function(self, ctx, verb)
            callback_verb = verb
        end,
    })
    local room = make_room(reg, {mat})
    local ctx = make_ctx(reg, room)

    capture_output(function()
        handlers["lift"](ctx, "mat")
    end)

    eq("lift", callback_verb, "callback should receive 'lift' as verb")
end)

---------------------------------------------------------------------------
-- 9. FULL PUZZLE CHAIN — bed → rug → trap door
---------------------------------------------------------------------------
suite("Spatial — puzzle chain (bed/rug/trap-door)")

test("push bed reveals rug, lift rug reveals trap door", function()
    local reg = make_reg()

    local trap_door = {
        guid = "{test-td}",
        id = "trap-door",
        name = "a trap door",
        keywords = {"trap door"},
        hidden = true,
        discovery_message = "Beneath the rug, a trap door is set into the stone floor!",
    }
    local rug = make_movable_object("rug", {
        covering = {"trap-door"},
        move_message = "You pull the threadbare rug aside.",
        resting_on = nil,
    })
    local bed = make_movable_object("bed", {
        push_message = "The bed scrapes aside with a grinding shriek.",
        resting_on = "rug",
    })

    reg:register(trap_door.id, trap_door)
    local room = make_room(reg, {bed, rug})
    local ctx = make_ctx(reg, room)

    -- Step 1: Try to push rug — bed is resting on it
    -- (This relies on the resting_on check in move_spatial_object)
    -- Actually, the resting_on check looks for items resting on the TARGET,
    -- not the other way around. bed.resting_on = "rug" means bed rests on rug.
    -- The check scans room.contents for other.resting_on == obj.id.
    -- So pushing rug should see bed.resting_on == "rug" → blocked.
    local output1 = capture_output(function()
        handlers["push"](ctx, "rug")
    end)
    eq(false, rug.moved, "rug should not move (bed on top)")

    -- Step 2: Push bed first
    local output2 = capture_output(function()
        handlers["push"](ctx, "bed")
    end)
    eq(true, bed.moved, "bed should be moved")
    h.assert_truthy(output2:find("grinding shriek"), "Should print bed push_message")

    -- Step 3: Now lift rug — reveals trap door
    local output3 = capture_output(function()
        handlers["lift"](ctx, "rug")
    end)
    eq(true, rug.moved, "rug should be moved")
    eq(false, trap_door.hidden, "trap door should be revealed")
    h.assert_truthy(output3:find("trap door"), "Should mention trap door")
end)

---------------------------------------------------------------------------
-- 10. PREPROCESS — gerunds and compound patterns
---------------------------------------------------------------------------
suite("Spatial — preprocess patterns")

-- Load preprocess module
local preprocess = require("engine.parser.preprocess")

test("lifting gerund maps to lift", function()
    local v, n = preprocess.natural_language("lifting rug")
    eq("lift", v, "lifting → lift")
    eq("rug", n, "noun should be rug")
end)

test("sliding gerund maps to slide", function()
    local v, n = preprocess.natural_language("sliding panel")
    eq("slide", v, "sliding → slide")
    eq("panel", n, "noun should be panel")
end)

test("shoving gerund maps to shove", function()
    local v, n = preprocess.natural_language("shoving crate")
    eq("shove", v, "shoving → shove")
    eq("crate", n, "noun should be crate")
end)

test("heaving gerund maps to heave", function()
    local v, n = preprocess.natural_language("heaving rock")
    eq("heave", v, "heaving → heave")
    eq("rock", n, "noun should be rock")
end)

test("dragging gerund maps to drag", function()
    local v, n = preprocess.natural_language("dragging sack")
    eq("drag", v, "dragging → drag")
    eq("sack", n, "noun should be sack")
end)

test("nudging gerund maps to nudge", function()
    local v, n = preprocess.natural_language("nudging barrel")
    eq("nudge", v, "nudging → nudge")
    eq("barrel", n, "noun should be barrel")
end)

test("heave X up → lift X", function()
    local v, n = preprocess.natural_language("heave rock up")
    eq("lift", v, "heave X up → lift")
    eq("rock", n, "noun should be rock")
end)

test("heave up X → lift X", function()
    local v, n = preprocess.natural_language("heave up stone")
    eq("lift", v, "heave up X → lift")
    eq("stone", n, "noun should be stone")
end)

test("drag X across → move X", function()
    local v, n = preprocess.natural_language("drag barrel across")
    eq("move", v, "drag X across → move")
    eq("barrel", n, "noun should be barrel")
end)

test("drag X along → move X", function()
    local v, n = preprocess.natural_language("drag sack along")
    eq("move", v, "drag X along → move")
    eq("sack", n, "noun should be sack")
end)

test("shove X aside → push X", function()
    local v, n = preprocess.natural_language("shove crate aside")
    eq("push", v, "shove X aside → push")
    eq("crate", n, "noun should be crate")
end)

test("nudge X aside → push X", function()
    local v, n = preprocess.natural_language("nudge barrel aside")
    eq("push", v, "nudge X aside → push")
    eq("barrel", n, "noun should be barrel")
end)

-- Existing patterns still work
test("slide X under Y → put X under Y", function()
    local v, n = preprocess.natural_language("slide knife under bed")
    eq("put", v, "slide X under Y → put")
    h.assert_truthy(n:find("knife") and n:find("under") and n:find("bed"),
        "noun should contain knife under bed")
end)

test("push X back → put X in X", function()
    local v, n = preprocess.natural_language("push drawer back")
    eq("put", v, "push X back → put")
    h.assert_truthy(n:find("drawer") and n:find("in"),
        "noun should contain drawer in drawer")
end)

---------------------------------------------------------------------------
h.summary()
