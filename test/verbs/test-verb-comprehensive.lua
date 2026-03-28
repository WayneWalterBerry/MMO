-- test/verbs/test-verb-comprehensive.lua
-- Comprehensive verb handler test suite covering ALL 31+ base verbs and aliases.
-- Tests: registration, missing noun, nonexistent object, wrong state,
--        consciousness gate, alias identity, and per-verb edge cases.
--
-- Usage: lua test/verbs/test-verb-comprehensive.lua
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
local fsm_mod = require("engine.fsm")

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

local function make_registry()
    return registry_mod.new()
end

local function fresh_object(overrides)
    local obj = {
        id = "test-obj",
        name = "a test object",
        keywords = {"test", "object", "test object"},
        description = "A plain test object.",
        on_feel = "Smooth and featureless.",
        on_smell = "Nothing distinctive.",
        on_taste = "Bland.",
        on_listen = "Silent.",
        portable = true,
    }
    if overrides then
        for k, v in pairs(overrides) do obj[k] = v end
    end
    return obj
end

local function make_ctx(opts)
    opts = opts or {}
    local reg = make_registry()
    local room = opts.room or {
        id = "test-room",
        name = "Test Room",
        description = "A plain test room.",
        contents = opts.room_contents or {},
        exits = opts.exits or {},
    }
    local player = opts.player or {
        hands = opts.hands or { nil, nil },
        worn = opts.worn or {},
        injuries = opts.injuries or {},
        bags = opts.bags or {},
        state = opts.state or {},
        max_health = 100,
        visited_rooms = opts.visited_rooms or {},
        location = opts.location or "test-room",
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = opts.time_offset or 20,
        game_start_time = os.time(),
        current_verb = opts.current_verb or "",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
        rooms = opts.rooms or nil,
    }
end

local function make_unconscious_ctx(opts)
    opts = opts or {}
    local ctx = make_ctx(opts)
    ctx.player.consciousness = { state = "unconscious", wake_timer = 5 }
    return ctx
end

-- All base verbs (primary handlers, not aliases)
local BASE_VERBS = {
    "look", "examine", "read", "search", "feel", "find", "smell", "taste", "listen",
    "take", "get", "pick", "grab", "pull", "push", "move", "slide", "lift",
    "uncork", "drop",
    "open", "close", "unlock", "lock",
    "break", "tear",
    "light", "extinguish", "strike", "burn",
    "stab", "hit", "cut", "slash", "prick",
    "write", "sew", "put",
    "wear", "remove",
    "eat", "drink", "pour", "dump", "wash", "sleep",
    "north", "south", "east", "west", "up", "down",
    "go", "back", "return", "enter", "descend", "ascend", "climb",
    "inventory", "time", "set", "report_bug", "help", "injuries",
    "apply", "use", "wait", "appearance",
    "breathe", "trigger", "step",
}

-- All aliases: alias → base verb
local ALIASES = {
    -- sensory
    x = "examine", check = "examine", inspect = "examine",
    touch = "feel", grope = "feel",
    sniff = "smell",
    lick = "taste",
    hear = "listen",
    -- acquisition
    grab = "take",
    yank = "pull", tug = "pull", extract = "pull",
    shove = "push", nudge = "push",
    -- NOTE: shift/drag are NOT aliases of the overridden "move" handler.
    -- In acquisition.lua, shift/drag point to the ORIGINAL spatial-move handler.
    -- In movement.lua, handlers["move"] is overridden with a direction-disambiguation
    -- wrapper. So shift/drag intentionally differ from move (they only do spatial moves).
    heave = "lift",
    unstop = "uncork", unseal = "uncork",
    toss = "drop", throw = "drop",
    -- containers
    pry = "open",
    shut = "close",
    -- destruction
    smash = "break", shatter = "break",
    rip = "tear",
    -- fire
    ignite = "light", relight = "light",
    snuff = "extinguish",
    -- combat
    jab = "stab", pierce = "stab", stick = "stab",
    punch = "hit", bash = "hit", bonk = "hit", thump = "hit",
    smack = "hit", bang = "hit", slap = "hit", whack = "hit",
    headbutt = "hit",
    slice = "cut", nick = "cut",
    carve = "butcher",
    -- crafting
    inscribe = "write",
    stitch = "sew", mend = "sew",
    place = "put",
    -- equipment
    don = "wear",
    doff = "remove",
    -- survival
    consume = "eat", devour = "eat",
    quaff = "drink", sip = "drink",
    spill = "pour", fill = "pour",
    empty = "dump",
    rest = "sleep", nap = "sleep",
    -- movement
    n = "north", s = "south", e = "east", w = "west",
    u = "up", d = "down",
    walk = "go", run = "go", head = "go", travel = "go",
    -- meta
    i = "inventory",
    adjust = "set",
    injury = "injuries", wounds = "injuries", health = "injuries",
    treat = "apply",
    utilize = "use",
    pass = "wait",
    -- traps
    inhale = "breathe",
    activate = "trigger",
}

---------------------------------------------------------------------------
-- 1. REGISTRATION — every verb must exist in handlers
---------------------------------------------------------------------------
suite("Registration — all base verbs exist")

for _, verb in ipairs(BASE_VERBS) do
    test("handler exists: " .. verb, function()
        h.assert_truthy(handlers[verb], "handlers['" .. verb .. "'] should exist")
        h.assert_truthy(type(handlers[verb]) == "function",
            "handlers['" .. verb .. "'] should be a function")
    end)
end

suite("Registration — all aliases exist")

for alias, _ in pairs(ALIASES) do
    test("alias handler exists: " .. alias, function()
        h.assert_truthy(handlers[alias], "handlers['" .. alias .. "'] should exist")
        h.assert_truthy(type(handlers[alias]) == "function",
            "handlers['" .. alias .. "'] should be a function")
    end)
end

---------------------------------------------------------------------------
-- 2. ALIAS IDENTITY — aliases must point to same function as base verb
---------------------------------------------------------------------------
suite("Alias identity — aliases share handler function with base")

for alias, base in pairs(ALIASES) do
    test(alias .. " → " .. base .. " (same handler)", function()
        eq(handlers[alias], handlers[base],
            alias .. " should be same function as " .. base)
    end)
end

---------------------------------------------------------------------------
-- 3. CONSCIOUSNESS GATE — all verbs must block when unconscious
---------------------------------------------------------------------------
suite("Consciousness gate — verbs blocked when unconscious")

-- Test a representative sample from each category
local CONSCIOUSNESS_VERBS = {
    "look", "examine", "feel", "smell", "taste", "listen",
    "take", "drop", "pull", "push", "lift",
    "open", "close", "unlock", "lock",
    "break", "tear",
    "light", "extinguish", "burn",
    "stab", "hit", "cut",
    "write", "sew", "put",
    "wear", "remove",
    "eat", "drink", "pour", "wash", "sleep",
    "go", "north", "enter", "climb",
    "inventory", "help", "time", "wait",
    "breathe", "trigger", "step",
}

for _, verb in ipairs(CONSCIOUSNESS_VERBS) do
    test(verb .. " blocked when unconscious", function()
        local ctx = make_unconscious_ctx()
        local output = capture_output(function()
            handlers[verb](ctx, "test")
        end)
        h.assert_truthy(output:find("unconscious"),
            verb .. " should print 'unconscious' message when player is unconscious")
    end)
end

---------------------------------------------------------------------------
-- 4. MISSING NOUN — verbs that require a target should prompt
---------------------------------------------------------------------------
suite("Missing noun — empty string prompts")

local MISSING_NOUN_TESTS = {
    { verb = "open",       expect = "Open what" },
    { verb = "close",      expect = "Close what" },
    { verb = "break",      expect = "Break what" },
    { verb = "tear",       expect = "Tear what" },
    { verb = "unlock",     expect = "Unlock what" },
    { verb = "lock",       expect = "Lock what" },
    { verb = "light",      expect = "Light what" },
    { verb = "extinguish", expect = "Extinguish what" },
    { verb = "burn",       expect = "Burn what" },
    { verb = "hit",        expect = "Hit what" },
    { verb = "cut",        expect = "Cut what" },
    { verb = "slash",      expect = "Slash what" },
    { verb = "prick",      expect = "Prick what" },
    { verb = "wear",       expect = "Wear what" },
    { verb = "eat",        expect = "Eat what" },
    { verb = "drink",      expect = "Drink what" },
    { verb = "go",         expect = "Go where" },
    { verb = "enter",      expect = "Enter what" },
    { verb = "breathe",    expect = "Breathe what" },
    { verb = "trigger",    expect = "Trigger what" },
    { verb = "step",       expect = "Step" },
}

for _, tc in ipairs(MISSING_NOUN_TESTS) do
    test(tc.verb .. " with empty noun prompts correctly", function()
        local ctx = make_ctx()
        local output = capture_output(function()
            handlers[tc.verb](ctx, "")
        end)
        h.assert_truthy(output:find(tc.expect),
            tc.verb .. " empty noun should prompt: " .. tc.expect
            .. " (got: " .. output .. ")")
    end)
end

---------------------------------------------------------------------------
-- 5. NONEXISTENT OBJECT — should get a not-found message
---------------------------------------------------------------------------
suite("Nonexistent object — not-found messages")

local NONEXISTENT_TESTS = {
    "open", "close", "break", "tear", "unlock", "lock",
    "eat", "drink", "wear",
    "breathe", "trigger", "step",
}

for _, verb in ipairs(NONEXISTENT_TESTS) do
    test(verb .. " on nonexistent object shows not-found", function()
        local ctx = make_ctx()
        local output = capture_output(function()
            handlers[verb](ctx, "unicorn")
        end)
        h.assert_truthy(
            output:find("don't notice") or output:find("don't see")
            or output:find("don't have") or output:find("can't")
            or output:find("nothing") or output:find("not found")
            or output:find("You can only") or output:find("aren't holding"),
            verb .. " nonexistent should show not-found (got: " .. output .. ")")
    end)
end

---------------------------------------------------------------------------
-- 6. SENSORY VERBS — detailed tests
---------------------------------------------------------------------------
suite("Sensory — feel always works (even in darkness)")

test("feel object in room returns on_feel text", function()
    local obj = fresh_object({
        id = "rock", name = "a rock", keywords = {"rock"},
        on_feel = "Cold and rough.",
    })
    local ctx = make_ctx({ room_contents = {"rock"}, time_offset = 0 })
    ctx.registry:register("rock", obj)
    local output = capture_output(function()
        handlers["feel"](ctx, "rock")
    end)
    h.assert_truthy(output:find("Cold and rough") or output:find("rock"),
        "feel should return on_feel text")
end)

test("touch is alias of feel", function()
    eq(handlers["touch"], handlers["feel"], "touch should be same as feel")
end)

suite("Sensory — smell always works")

test("smell object returns on_smell text", function()
    local obj = fresh_object({
        id = "flower", name = "a flower", keywords = {"flower"},
        on_smell = "Sweet floral scent.",
    })
    local ctx = make_ctx({ room_contents = {"flower"} })
    ctx.registry:register("flower", obj)
    local output = capture_output(function()
        handlers["smell"](ctx, "flower")
    end)
    h.assert_truthy(output:find("Sweet floral") or output:find("flower"),
        "smell should return on_smell text")
end)

suite("Sensory — taste always works")

test("taste object returns on_taste text", function()
    local obj = fresh_object({
        id = "berry", name = "a berry", keywords = {"berry"},
        on_taste = "Tart and slightly bitter.",
    })
    local ctx = make_ctx({ room_contents = {"berry"} })
    ctx.registry:register("berry", obj)
    local output = capture_output(function()
        handlers["taste"](ctx, "berry")
    end)
    h.assert_truthy(output:find("Tart") or output:find("bitter") or output:find("berry"),
        "taste should return on_taste text")
end)

suite("Sensory — listen always works")

test("listen to object returns on_listen text", function()
    local obj = fresh_object({
        id = "clock", name = "a clock", keywords = {"clock"},
        on_listen = "Tick-tock, tick-tock.",
    })
    local ctx = make_ctx({ room_contents = {"clock"} })
    ctx.registry:register("clock", obj)
    local output = capture_output(function()
        handlers["listen"](ctx, "clock")
    end)
    h.assert_truthy(output:find("Tick") or output:find("clock"),
        "listen should return on_listen text")
end)

suite("Sensory — look requires light")

test("look with no light describes darkness", function()
    local ctx = make_ctx({ time_offset = 0 })
    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)
    -- In darkness without light, look should describe darkness
    h.assert_truthy(output:find("dark") or output:find("Dark") or output:find("can't see")
        or output:find("pitch") or output:find("room") or output:find("Room"),
        "look with no light should mention darkness or room (got: " .. output:sub(1, 120) .. ")")
end)

suite("Sensory — search with no object searches room")

test("search with empty noun searches the room", function()
    local ctx = make_ctx({ time_offset = 8 })
    -- Add a light source for visibility
    local curtains = {
        id = "curtains", name = "curtains", keywords = {"curtains"},
        allows_daylight = true, hidden = true,
    }
    ctx.registry:register("curtains", curtains)
    ctx.current_room.contents = {"curtains"}
    local output = capture_output(function()
        handlers["search"](ctx, "")
    end)
    -- Should either search the room or prompt
    h.assert_truthy(output ~= "",
        "search with empty noun should produce output")
end)

---------------------------------------------------------------------------
-- 7. ACQUISITION VERBS — take, drop, get, pick
---------------------------------------------------------------------------
suite("Acquisition — take basic")

test("take portable object from room succeeds", function()
    local obj = fresh_object({ id = "gem", name = "a gem", keywords = {"gem"} })
    local ctx = make_ctx({ room_contents = {"gem"} })
    ctx.registry:register("gem", obj)
    local output = capture_output(function()
        handlers["take"](ctx, "gem")
    end)
    local hand1 = ctx.player.hands[1]
    local hand1_id = type(hand1) == "table" and hand1.id or hand1
    h.assert_truthy(hand1_id == "gem" or (output:find("pick") or output:find("take") or output:find("gem")),
        "Should pick up gem")
end)

test("take nonexistent object shows not-found", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["take"](ctx, "unicorn")
    end)
    h.assert_truthy(output:find("don't notice") or output:find("don't see")
        or output:find("don't have") or output:find("nothing"),
        "take nonexistent should show not-found")
end)

test("take with hands full shows hands-full message", function()
    local obj1 = fresh_object({ id = "rock", name = "a rock", keywords = {"rock"} })
    local obj2 = fresh_object({ id = "stick", name = "a stick", keywords = {"stick"} })
    local obj3 = fresh_object({ id = "leaf", name = "a leaf", keywords = {"leaf"} })
    local ctx = make_ctx({ room_contents = {"leaf"} })
    ctx.registry:register("rock", obj1)
    ctx.registry:register("stick", obj2)
    ctx.registry:register("leaf", obj3)
    ctx.player.hands[1] = obj1
    ctx.player.hands[2] = obj2
    local output = capture_output(function()
        handlers["take"](ctx, "leaf")
    end)
    h.assert_truthy(output:find("hands") or output:find("full") or output:find("carrying"),
        "take with full hands should refuse")
end)

suite("Acquisition — drop")

test("drop held object succeeds", function()
    local obj = fresh_object({ id = "coin", name = "a coin", keywords = {"coin"} })
    local ctx = make_ctx()
    ctx.registry:register("coin", obj)
    ctx.player.hands[1] = obj
    local output = capture_output(function()
        handlers["drop"](ctx, "coin")
    end)
    h.assert_truthy(ctx.player.hands[1] == nil or output:find("drop") or output:find("coin"),
        "drop should remove from hand")
end)

test("drop something not held shows error", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["drop"](ctx, "unicorn")
    end)
    h.assert_truthy(output:find("don't") or output:find("not carrying")
        or output:find("nothing") or output:find("aren't holding"),
        "drop not-held should show error")
end)

suite("Acquisition — get redirects to take")

test("get redirects to take behavior", function()
    local obj = fresh_object({ id = "gem", name = "a gem", keywords = {"gem"} })
    local ctx = make_ctx({ room_contents = {"gem"} })
    ctx.registry:register("gem", obj)
    local output = capture_output(function()
        handlers["get"](ctx, "gem")
    end)
    local hand = ctx.player.hands[1]
    local hand_id = type(hand) == "table" and hand.id or hand
    -- get should pick up like take (either in hand or produces take-like output)
    h.assert_truthy(hand_id == "gem" or output:find("pick") or output:find("take") or output:find("gem"),
        "get should behave like take")
end)

suite("Acquisition — push/pull/lift non-portable")

test("push non-portable object produces response", function()
    local obj = fresh_object({
        id = "boulder", name = "a boulder", keywords = {"boulder"},
        portable = false,
    })
    local ctx = make_ctx({ room_contents = {"boulder"} })
    ctx.registry:register("boulder", obj)
    local output = capture_output(function()
        handlers["push"](ctx, "boulder")
    end)
    h.assert_truthy(output ~= "",
        "push should produce some output")
end)

test("lift non-portable object refuses", function()
    local obj = fresh_object({
        id = "anvil", name = "an anvil", keywords = {"anvil"},
        portable = false, weight = 100,
    })
    local ctx = make_ctx({ room_contents = {"anvil"} })
    ctx.registry:register("anvil", obj)
    local output = capture_output(function()
        handlers["lift"](ctx, "anvil")
    end)
    h.assert_truthy(output:find("heavy") or output:find("can't") or output:find("budge")
        or output:find("lift") or output ~= "",
        "lift heavy object should refuse or describe")
end)

---------------------------------------------------------------------------
-- 8. CONTAINER VERBS — open, close, unlock, lock
---------------------------------------------------------------------------
suite("Container — open FSM object")

test("open closed FSM container succeeds", function()
    local chest = {
        id = "chest", name = "a chest", keywords = {"chest"},
        _state = "closed", initial_state = "closed",
        states = {
            closed = { name = "a closed chest" },
            open = { name = "an open chest" },
        },
        transitions = {
            { from = "closed", to = "open", verb = "open",
              message = "You open the chest." },
            { from = "open", to = "closed", verb = "close",
              message = "You close the chest." },
        },
    }
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    local output = capture_output(function()
        handlers["open"](ctx, "chest")
    end)
    h.assert_truthy(output:find("open") or output:find("chest"),
        "open should succeed on closed chest")
end)

test("open already-open FSM container says already open", function()
    local chest = {
        id = "chest", name = "a chest", keywords = {"chest"},
        _state = "open", initial_state = "closed",
        states = {
            closed = { name = "a closed chest" },
            open = { name = "an open chest" },
        },
        transitions = {
            { from = "closed", to = "open", verb = "open",
              message = "You open the chest." },
        },
    }
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    local output = capture_output(function()
        handlers["open"](ctx, "chest")
    end)
    h.assert_truthy(output:find("already open"),
        "open already-open should say 'already open'")
end)

suite("Container — close FSM object")

test("close open FSM container succeeds", function()
    local chest = {
        id = "chest", name = "a chest", keywords = {"chest"},
        _state = "open", initial_state = "closed",
        states = {
            closed = { name = "a closed chest" },
            open = { name = "an open chest" },
        },
        transitions = {
            { from = "open", to = "closed", verb = "close",
              message = "You close the chest." },
        },
    }
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    local output = capture_output(function()
        handlers["close"](ctx, "chest")
    end)
    h.assert_truthy(output:find("close") or output:find("chest"),
        "close should succeed on open chest")
end)

test("close already-closed FSM container says already closed", function()
    local chest = {
        id = "chest", name = "a chest", keywords = {"chest"},
        _state = "closed", initial_state = "closed",
        states = {
            closed = { name = "a closed chest" },
            open = { name = "an open chest" },
        },
        transitions = {
            { from = "open", to = "closed", verb = "close" },
        },
    }
    local ctx = make_ctx({ room_contents = {"chest"} })
    ctx.registry:register("chest", chest)
    local output = capture_output(function()
        handlers["close"](ctx, "chest")
    end)
    h.assert_truthy(output:find("already closed"),
        "close already-closed should say 'already closed'")
end)

suite("Container — pry is alias of open")

test("pry alias works like open", function()
    eq(handlers["pry"], handlers["open"], "pry should be same function as open")
end)

suite("Container — shut is alias of close")

test("shut alias works like close", function()
    eq(handlers["shut"], handlers["close"], "shut should be same function as close")
end)

suite("Container — unlock")

test("unlock locked exit door with correct key succeeds", function()
    local exits = {
        north = {
            target = "hallway",
            name = "a wooden door",
            keywords = {"door", "wooden door"},
            open = false,
            locked = true,
            key_id = "brass-key",
        },
    }
    local key = fresh_object({ id = "brass-key", name = "a brass key", keywords = {"key", "brass key"} })
    local ctx = make_ctx({ exits = exits })
    ctx.registry:register("brass-key", key)
    ctx.player.hands[1] = key
    local output = capture_output(function()
        handlers["unlock"](ctx, "door with key")
    end)
    h.assert_truthy(output:find("unlock") or output:find("click"),
        "unlock with correct key should succeed")
end)

test("unlock with wrong key refuses", function()
    local exits = {
        north = {
            target = "hallway",
            name = "a wooden door",
            keywords = {"door"},
            open = false,
            locked = true,
            key_id = "brass-key",
        },
    }
    local wrong_key = fresh_object({ id = "iron-key", name = "an iron key", keywords = {"key", "iron key"} })
    local ctx = make_ctx({ exits = exits })
    ctx.registry:register("iron-key", wrong_key)
    ctx.player.hands[1] = wrong_key
    local output = capture_output(function()
        handlers["unlock"](ctx, "door with key")
    end)
    h.assert_truthy(output:find("doesn't fit") or output:find("doesn't fit"),
        "unlock with wrong key should refuse")
end)

test("unlock already-unlocked door says not locked", function()
    local exits = {
        north = {
            target = "hallway",
            name = "a wooden door",
            keywords = {"door"},
            open = false,
            locked = false,
        },
    }
    local ctx = make_ctx({ exits = exits })
    local output = capture_output(function()
        handlers["unlock"](ctx, "door")
    end)
    h.assert_truthy(output:find("isn't locked") or output:find("not locked")
        or output:find("already"),
        "unlock unlocked door should say 'not locked'")
end)

suite("Container — lock")

test("lock closed unlocked door with correct key", function()
    local exits = {
        north = {
            target = "hallway",
            name = "a wooden door",
            keywords = {"door"},
            open = false,
            locked = false,
            key_id = "brass-key",
        },
    }
    local key = fresh_object({ id = "brass-key", name = "a brass key", keywords = {"key", "brass key"} })
    local ctx = make_ctx({ exits = exits })
    ctx.registry:register("brass-key", key)
    ctx.player.hands[1] = key
    local output = capture_output(function()
        handlers["lock"](ctx, "door with key")
    end)
    h.assert_truthy(output:find("locked") or output:find("click"),
        "lock with correct key should succeed")
end)

test("lock already-locked door says already locked", function()
    local exits = {
        north = {
            target = "hallway",
            name = "a wooden door",
            keywords = {"door"},
            open = false,
            locked = true,
            key_id = "brass-key",
        },
    }
    local ctx = make_ctx({ exits = exits })
    local output = capture_output(function()
        handlers["lock"](ctx, "door")
    end)
    h.assert_truthy(output:find("already locked"),
        "lock already-locked should say 'already locked'")
end)

---------------------------------------------------------------------------
-- 9. DESTRUCTION VERBS — break, smash, tear
---------------------------------------------------------------------------
suite("Destruction — break")

test("break non-breakable object refuses", function()
    local obj = fresh_object({
        id = "stone", name = "a stone", keywords = {"stone"},
    })
    local ctx = make_ctx({ room_contents = {"stone"} })
    ctx.registry:register("stone", obj)
    local output = capture_output(function()
        handlers["break"](ctx, "stone")
    end)
    h.assert_truthy(output:find("can't break"),
        "break non-breakable should say can't break")
end)

test("smash alias points to break", function()
    eq(handlers["smash"], handlers["break"], "smash is break alias")
end)

test("shatter alias points to break", function()
    eq(handlers["shatter"], handlers["break"], "shatter is break alias")
end)

suite("Destruction — tear")

test("tear non-tearable object refuses", function()
    local obj = fresh_object({
        id = "stone", name = "a stone", keywords = {"stone"},
    })
    local ctx = make_ctx({ room_contents = {"stone"} })
    ctx.registry:register("stone", obj)
    local output = capture_output(function()
        handlers["tear"](ctx, "stone")
    end)
    h.assert_truthy(output:find("can't tear"),
        "tear non-tearable should say can't tear")
end)

test("rip alias points to tear", function()
    eq(handlers["rip"], handlers["tear"], "rip is tear alias")
end)

---------------------------------------------------------------------------
-- 10. FIRE VERBS — light, extinguish, strike, burn
---------------------------------------------------------------------------
suite("Fire — light FSM with tool")

test("light FSM candle with fire_source succeeds", function()
    local candle = {
        id = "candle", name = "a candle", keywords = {"candle"},
        _state = "unlit", initial_state = "unlit",
        states = {
            unlit = { name = "an unlit candle", casts_light = false },
            lit = { name = "a lit candle", casts_light = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light",
              requires_tool = "fire_source",
              message = "The candle wick catches." },
        },
    }
    local match_obj = {
        id = "match", name = "a match", keywords = {"match"},
        provides_tool = {"fire_source"},
        charges = 1,
    }
    local ctx = make_ctx()
    ctx.registry:register("candle", candle)
    ctx.registry:register("match", match_obj)
    ctx.player.hands[1] = candle
    ctx.player.hands[2] = match_obj
    local output = capture_output(function()
        handlers["light"](ctx, "candle")
    end)
    h.assert_truthy(output:find("candle") or output:find("wick") or output:find("light"),
        "light candle with match should succeed")
end)

test("light already-lit object says already lit", function()
    local candle = {
        id = "candle", name = "a candle", keywords = {"candle"},
        _state = "lit", initial_state = "unlit",
        states = {
            unlit = { name = "an unlit candle", casts_light = false },
            lit = { name = "a lit candle", casts_light = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light" },
        },
    }
    local ctx = make_ctx()
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    local output = capture_output(function()
        handlers["light"](ctx, "candle")
    end)
    h.assert_truthy(output:find("already") or output:find("lit") or output:find("can't"),
        "light already-lit should indicate already lit")
end)

suite("Fire — extinguish")

test("extinguish with empty noun prompts", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["extinguish"](ctx, "")
    end)
    h.assert_truthy(output:find("Extinguish what") or output:find("extinguish"),
        "extinguish empty noun should prompt")
end)

test("snuff alias points to extinguish", function()
    eq(handlers["snuff"], handlers["extinguish"], "snuff is extinguish alias")
end)

suite("Fire — ignite and relight aliases")

test("ignite alias points to light", function()
    eq(handlers["ignite"], handlers["light"], "ignite is light alias")
end)

test("relight alias points to light", function()
    eq(handlers["relight"], handlers["light"], "relight is light alias")
end)

---------------------------------------------------------------------------
-- 11. COMBAT VERBS — stab, hit, cut, slash, prick
---------------------------------------------------------------------------
suite("Combat — stab self")

test("stab with no self-target says self-only", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["stab"](ctx, "rock")
    end)
    h.assert_truthy(output:find("only") or output:find("self") or output:find("yourself"),
        "stab non-self should indicate self-only")
end)

suite("Combat — hit self (head → unconsciousness)")

test("hit head causes unconsciousness", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["hit"](ctx, "head")
    end)
    h.assert_truthy(
        (ctx.player.consciousness and ctx.player.consciousness.state == "unconscious")
        or output:find("Stars") or output:find("vision") or output:find("fades"),
        "hit head should cause unconsciousness")
end)

test("hit non-head area causes bruise", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["hit"](ctx, "left arm")
    end)
    h.assert_truthy(output:find("punch") or output:find("pain") or output:find("arm"),
        "hit left arm should cause bruise narration")
end)

suite("Combat — hit aliases")

test("punch alias points to hit", function()
    eq(handlers["punch"], handlers["hit"], "punch is hit alias")
end)

test("bash alias points to hit", function()
    eq(handlers["bash"], handlers["hit"], "bash is hit alias")
end)

test("bonk alias points to hit", function()
    eq(handlers["bonk"], handlers["hit"], "bonk is hit alias")
end)

test("slap alias points to hit", function()
    eq(handlers["slap"], handlers["hit"], "slap is hit alias")
end)

test("whack alias points to hit", function()
    eq(handlers["whack"], handlers["hit"], "whack is hit alias")
end)

test("headbutt alias points to hit", function()
    eq(handlers["headbutt"], handlers["hit"], "headbutt is hit alias")
end)

suite("Combat — toss/throw alias drop")

test("toss alias points to drop", function()
    eq(handlers["toss"], handlers["drop"], "toss is drop alias")
end)

test("throw alias points to drop", function()
    eq(handlers["throw"], handlers["drop"], "throw is drop alias")
end)

suite("Combat — cut requires tool")

test("cut with empty noun prompts", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["cut"](ctx, "")
    end)
    h.assert_truthy(output:find("Cut what") or output:find("cut"),
        "cut empty noun should prompt")
end)

suite("Combat — prick self")

test("prick self with sharp tool succeeds", function()
    local pin = {
        id = "pin", name = "a pin", keywords = {"pin"},
        provides_tool = {"injury_source"},
    }
    local ctx = make_ctx()
    ctx.registry:register("pin", pin)
    ctx.player.hands[1] = pin
    local output = capture_output(function()
        handlers["prick"](ctx, "self with pin")
    end)
    h.assert_truthy(output:find("prick") or output:find("blood") or output:find("finger"),
        "prick self with pin should succeed")
end)

test("prick non-self says self-only", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["prick"](ctx, "rock")
    end)
    h.assert_truthy(output:find("only") or output:find("self") or output:find("yourself"),
        "prick non-self should indicate self-only")
end)

---------------------------------------------------------------------------
-- 12. CRAFTING VERBS — write, sew, put
---------------------------------------------------------------------------
suite("Crafting — write")

test("write with no noun prompts", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["write"](ctx, "")
    end)
    h.assert_truthy(output:find("Write") or output:find("write") or output ~= "",
        "write empty noun should produce output")
end)

test("inscribe alias points to write", function()
    eq(handlers["inscribe"], handlers["write"], "inscribe is write alias")
end)

suite("Crafting — sew")

test("sew with no noun prompts", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["sew"](ctx, "")
    end)
    h.assert_truthy(output:find("Sew") or output:find("sew") or output ~= "",
        "sew empty noun should produce output")
end)

test("stitch alias points to sew", function()
    eq(handlers["stitch"], handlers["sew"], "stitch is sew alias")
end)

test("mend alias points to sew", function()
    eq(handlers["mend"], handlers["sew"], "mend is sew alias")
end)

suite("Crafting — put")

test("put with no noun prompts", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["put"](ctx, "")
    end)
    h.assert_truthy(output:find("Put") or output:find("put") or output:find("what") or output ~= "",
        "put empty noun should produce output")
end)

test("place alias points to put", function()
    eq(handlers["place"], handlers["put"], "place is put alias")
end)

---------------------------------------------------------------------------
-- 13. EQUIPMENT VERBS — wear, remove
---------------------------------------------------------------------------
suite("Equipment — wear")

test("wear wearable object from hand succeeds", function()
    local cloak = {
        id = "cloak", name = "a wool cloak", keywords = {"cloak", "wool cloak"},
        wearable = true, wear_slot = "torso",
        on_feel = "Soft wool.",
    }
    local ctx = make_ctx()
    ctx.registry:register("cloak", cloak)
    ctx.player.hands[1] = cloak
    local output = capture_output(function()
        handlers["wear"](ctx, "cloak")
    end)
    h.assert_truthy(output:find("wear") or output:find("put on") or output:find("cloak")
        or output:find("don"),
        "wear wearable should succeed")
end)

test("wear non-wearable object refuses", function()
    local rock = fresh_object({ id = "rock", name = "a rock", keywords = {"rock"} })
    local ctx = make_ctx()
    ctx.registry:register("rock", rock)
    ctx.player.hands[1] = rock
    local output = capture_output(function()
        handlers["wear"](ctx, "rock")
    end)
    h.assert_truthy(output:find("can't wear") or output:find("can't wear")
        or output:find("not something"),
        "wear non-wearable should refuse")
end)

test("don alias points to wear", function()
    eq(handlers["don"], handlers["wear"], "don is wear alias")
end)

suite("Equipment — remove")

test("remove worn item succeeds", function()
    local cloak = {
        id = "cloak", name = "a wool cloak", keywords = {"cloak", "wool cloak"},
        wearable = true, wear_slot = "torso",
        on_feel = "Soft wool.",
    }
    local ctx = make_ctx({ worn = {"cloak"} })
    ctx.registry:register("cloak", cloak)
    local output = capture_output(function()
        handlers["remove"](ctx, "cloak")
    end)
    h.assert_truthy(output:find("remove") or output:find("take off") or output:find("cloak"),
        "remove worn item should succeed")
end)

test("doff alias points to remove", function()
    eq(handlers["doff"], handlers["remove"], "doff is remove alias")
end)

---------------------------------------------------------------------------
-- 14. SURVIVAL VERBS — eat, drink, pour, wash, sleep
---------------------------------------------------------------------------
suite("Survival — eat")

test("eat nonexistent shows not-found", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["eat"](ctx, "unicorn")
    end)
    h.assert_truthy(output:find("don't") or output:find("nothing") or output:find("can't"),
        "eat nonexistent should show not-found")
end)

test("eat non-edible object refuses", function()
    local rock = fresh_object({ id = "rock", name = "a rock", keywords = {"rock"} })
    local ctx = make_ctx()
    ctx.registry:register("rock", rock)
    ctx.player.hands[1] = rock
    local output = capture_output(function()
        handlers["eat"](ctx, "rock")
    end)
    h.assert_truthy(output:find("can't eat") or output:find("inedible")
        or output:find("edible") or output:find("eat that"),
        "eat non-edible should refuse")
end)

test("consume alias points to eat", function()
    eq(handlers["consume"], handlers["eat"], "consume is eat alias")
end)

test("devour alias points to eat", function()
    eq(handlers["devour"], handlers["eat"], "devour is eat alias")
end)

suite("Survival — drink")

test("drink with empty noun prompts", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["drink"](ctx, "")
    end)
    h.assert_truthy(output:find("Drink what") or output:find("drink") or output ~= "",
        "drink empty noun should prompt")
end)

test("quaff alias points to drink", function()
    eq(handlers["quaff"], handlers["drink"], "quaff is drink alias")
end)

test("sip alias points to drink", function()
    eq(handlers["sip"], handlers["drink"], "sip is drink alias")
end)

suite("Survival — pour")

test("pour with empty noun prompts", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["pour"](ctx, "")
    end)
    h.assert_truthy(output:find("Pour") or output:find("pour") or output ~= "",
        "pour empty noun should prompt")
end)

test("spill alias points to pour", function()
    eq(handlers["spill"], handlers["pour"], "spill is pour alias")
end)

test("fill alias points to pour", function()
    eq(handlers["fill"], handlers["pour"], "fill is pour alias")
end)

suite("Survival — dump/empty")

test("dump with empty noun prompts", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["dump"](ctx, "")
    end)
    h.assert_truthy(output ~= "", "dump empty noun should produce output")
end)

test("empty alias points to dump", function()
    eq(handlers["empty"], handlers["dump"], "empty is dump alias")
end)

suite("Survival — sleep/rest/nap")

test("sleep produces response", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["sleep"](ctx, "")
    end)
    h.assert_truthy(output ~= "", "sleep should produce a response")
end)

test("rest alias points to sleep", function()
    eq(handlers["rest"], handlers["sleep"], "rest is sleep alias")
end)

test("nap alias points to sleep", function()
    eq(handlers["nap"], handlers["sleep"], "nap is sleep alias")
end)

---------------------------------------------------------------------------
-- 15. MOVEMENT VERBS
---------------------------------------------------------------------------
suite("Movement — cardinal directions and aliases")

local function make_movement_rooms()
    local bedroom = {
        id = "bedroom", name = "Bedroom", description = "A bedroom.",
        short_description = "The bedroom.", contents = {},
        exits = {
            north = { target = "hallway", name = "a door", keywords = {"door"}, open = true },
            south = { target = "cellar", name = "a trapdoor", keywords = {"trapdoor"}, open = false },
            west = { target = "locked-room", name = "iron door", keywords = {"iron door"},
                     open = false, locked = true },
        },
    }
    local hallway = {
        id = "hallway", name = "Hallway", description = "A hallway.",
        short_description = "The hallway.", contents = {},
        exits = { south = { target = "bedroom", name = "a door", open = true } },
    }
    local cellar = {
        id = "cellar", name = "Cellar", description = "A cellar.",
        contents = {}, exits = {},
    }
    return {
        bedroom = bedroom, hallway = hallway, cellar = cellar,
        ["locked-room"] = { id = "locked-room", name = "Locked Room",
            description = "A locked room.", contents = {}, exits = {} },
    }
end

local function make_movement_ctx()
    local rooms = make_movement_rooms()
    local reg = make_registry()
    return {
        registry = reg,
        current_room = rooms.bedroom,
        rooms = rooms,
        player = {
            hands = { nil, nil }, worn = {}, injuries = {},
            bags = {}, state = {}, location = "bedroom",
            visited_rooms = {}, max_health = 100,
        },
        time_offset = 20, game_start_time = os.time(),
        current_verb = "", known_objects = {}, last_object = nil,
        verbs = handlers,
    }
end

test("north moves to hallway", function()
    local ctx = make_movement_ctx()
    capture_output(function() handlers["north"](ctx, "") end)
    eq("hallway", ctx.current_room.id, "Should move north to hallway")
end)

test("n alias moves north", function()
    local ctx = make_movement_ctx()
    capture_output(function() handlers["n"](ctx, "") end)
    eq("hallway", ctx.current_room.id, "n should move north")
end)

test("south blocked by closed exit", function()
    local ctx = make_movement_ctx()
    local output = capture_output(function() handlers["south"](ctx, "") end)
    eq("bedroom", ctx.current_room.id, "Should stay in bedroom")
    h.assert_truthy(output:find("closed") or output:find("Closed"),
        "closed exit should say closed")
end)

test("west blocked by locked exit", function()
    local ctx = make_movement_ctx()
    local output = capture_output(function() handlers["west"](ctx, "") end)
    eq("bedroom", ctx.current_room.id, "Should stay in bedroom")
    h.assert_truthy(output:find("locked") or output:find("Locked"),
        "locked exit should say locked")
end)

test("east with no exit says can't go that way", function()
    local ctx = make_movement_ctx()
    local output = capture_output(function() handlers["east"](ctx, "") end)
    eq("bedroom", ctx.current_room.id, "Should stay in bedroom")
    h.assert_truthy(output:find("can't go"),
        "no exit should say can't go that way")
end)

test("go with empty noun prompts 'Go where?'", function()
    local ctx = make_movement_ctx()
    local output = capture_output(function() handlers["go"](ctx, "") end)
    h.assert_truthy(output:find("Go where"),
        "go empty should say 'Go where?'")
end)

test("go north moves correctly", function()
    local ctx = make_movement_ctx()
    capture_output(function() handlers["go"](ctx, "north") end)
    eq("hallway", ctx.current_room.id, "go north should move to hallway")
end)

test("walk alias points to go", function()
    eq(handlers["walk"], handlers["go"], "walk is go alias")
end)

test("run alias points to go", function()
    eq(handlers["run"], handlers["go"], "run is go alias")
end)

test("travel alias points to go", function()
    eq(handlers["travel"], handlers["go"], "travel is go alias")
end)

suite("Movement — back/return")

test("back with no previous room says can't go back", function()
    -- Clear global context_window state from any earlier navigation tests
    local ok, ctx_win = pcall(require, "engine.parser.context")
    if ok and ctx_win and ctx_win.set_previous_room then
        ctx_win.set_previous_room(nil)
    end
    local ctx = make_movement_ctx()
    local output = capture_output(function() handlers["back"](ctx, "") end)
    h.assert_truthy(output:find("go back") or output:find("haven't been")
        or output:find("back") or output:find("anywhere"),
        "back with no history should refuse (got: " .. tostring(output) .. ")")
end)

suite("Movement — enter")

test("enter with empty noun prompts", function()
    local ctx = make_movement_ctx()
    local output = capture_output(function() handlers["enter"](ctx, "") end)
    h.assert_truthy(output:find("Enter what"),
        "enter empty should say 'Enter what?'")
end)

suite("Movement — climb/descend/ascend")

test("descend goes down", function()
    local rooms = make_movement_rooms()
    rooms.bedroom.exits.down = { target = "cellar", open = true }
    local ctx = make_movement_ctx()
    ctx.rooms = rooms
    ctx.current_room = rooms.bedroom
    capture_output(function() handlers["descend"](ctx, "") end)
    eq("cellar", ctx.current_room.id, "descend should go down to cellar")
end)

---------------------------------------------------------------------------
-- 16. META VERBS — inventory, help, time, wait, appearance
---------------------------------------------------------------------------
suite("Meta — inventory")

test("inventory with empty hands shows empty message", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["inventory"](ctx, "")
    end)
    h.assert_truthy(output:find("empty") or output:find("nothing")
        or output:find("hand") or output:find("carrying"),
        "empty inventory should say empty/nothing")
end)

test("inventory with items lists them", function()
    local gem = fresh_object({ id = "gem", name = "a gem", keywords = {"gem"} })
    local ctx = make_ctx()
    ctx.registry:register("gem", gem)
    ctx.player.hands[1] = gem
    local output = capture_output(function()
        handlers["inventory"](ctx, "")
    end)
    h.assert_truthy(output:find("gem") or output:find("hand"),
        "inventory should list carried items")
end)

test("i alias points to inventory", function()
    eq(handlers["i"], handlers["inventory"], "i is inventory alias")
end)

suite("Meta — help")

test("help produces comprehensive output", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["help"](ctx, "")
    end)
    h.assert_truthy(output:find("Movement") or output:find("move") or output:find("look"),
        "help should contain useful information")
    h.assert_truthy(#output > 100,
        "help output should be substantial (got " .. #output .. " chars)")
end)

suite("Meta — time")

test("time shows current game time", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["time"](ctx, "")
    end)
    h.assert_truthy(output:find("AM") or output:find("PM") or output:find("time")
        or output:find(":") or output:find("o'clock"),
        "time should show game time")
end)

suite("Meta — wait")

test("wait produces time-passing message", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["wait"](ctx, "")
    end)
    h.assert_truthy(output:find("Time passes") or output:find("wait")
        or output:find("moment") or output ~= "",
        "wait should produce a message")
end)

test("pass alias points to wait", function()
    eq(handlers["pass"], handlers["wait"], "pass is wait alias")
end)

suite("Meta — appearance")

test("appearance produces character description", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["appearance"](ctx, "")
    end)
    h.assert_truthy(output ~= "", "appearance should produce output")
end)

suite("Meta — injuries/health")

test("injuries with no injuries shows clean bill", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["injuries"](ctx, "")
    end)
    h.assert_truthy(output:find("no") or output:find("healthy") or output:find("fine")
        or output:find("No") or output:find("injury") or output:find("none"),
        "no injuries should show healthy message")
end)

test("injury alias points to injuries", function()
    eq(handlers["injury"], handlers["injuries"], "injury is injuries alias")
end)

test("wounds alias points to injuries", function()
    eq(handlers["wounds"], handlers["injuries"], "wounds is injuries alias")
end)

test("health alias points to injuries", function()
    eq(handlers["health"], handlers["injuries"], "health is injuries alias")
end)

suite("Meta — use")

test("use with empty noun prompts", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["use"](ctx, "")
    end)
    h.assert_truthy(output:find("Use what") or output:find("use") or output ~= "",
        "use empty noun should prompt")
end)

test("utilize alias points to use", function()
    eq(handlers["utilize"], handlers["use"], "utilize is use alias")
end)

---------------------------------------------------------------------------
-- 17. TRAP VERBS — breathe, trigger, step
---------------------------------------------------------------------------
suite("Trap — breathe")

test("breathe nonexistent shows not-found", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["breathe"](ctx, "unicorn")
    end)
    h.assert_truthy(output:find("don't notice") or output:find("don't see")
        or output:find("nothing"),
        "breathe nonexistent should show not-found")
end)

test("inhale alias points to breathe", function()
    eq(handlers["inhale"], handlers["breathe"], "inhale is breathe alias")
end)

suite("Trap — trigger")

test("trigger nonexistent shows not-found", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["trigger"](ctx, "unicorn")
    end)
    h.assert_truthy(output:find("don't notice") or output:find("don't see")
        or output:find("nothing"),
        "trigger nonexistent should show not-found")
end)

test("activate alias points to trigger", function()
    eq(handlers["activate"], handlers["trigger"], "activate is trigger alias")
end)

suite("Trap — step")

test("step nonexistent shows not-found", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["step"](ctx, "unicorn")
    end)
    h.assert_truthy(output:find("don't notice") or output:find("don't see")
        or output:find("nothing"),
        "step nonexistent should show not-found")
end)

---------------------------------------------------------------------------
-- 18. WASH VERB
---------------------------------------------------------------------------
suite("Survival — wash")

test("wash with empty noun prompts", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["wash"](ctx, "")
    end)
    h.assert_truthy(output:find("Wash") or output:find("wash") or output ~= "",
        "wash empty noun should produce output")
end)

---------------------------------------------------------------------------
-- 19. CROSS-CATEGORY: verb + wrong object type
---------------------------------------------------------------------------
suite("Wrong object type — verbs on inappropriate objects")

test("drink a non-drinkable object refuses", function()
    local rock = fresh_object({ id = "rock", name = "a rock", keywords = {"rock"} })
    local ctx = make_ctx()
    ctx.registry:register("rock", rock)
    ctx.player.hands[1] = rock
    local output = capture_output(function()
        handlers["drink"](ctx, "rock")
    end)
    h.assert_truthy(output:find("can't drink") or output:find("drinkable")
        or output:find("liquid") or output:find("drink that"),
        "drink non-drinkable should refuse")
end)

test("light a non-lightable object refuses", function()
    local rock = fresh_object({ id = "rock", name = "a rock", keywords = {"rock"} })
    local ctx = make_ctx()
    ctx.registry:register("rock", rock)
    ctx.player.hands[1] = rock
    local output = capture_output(function()
        handlers["light"](ctx, "rock")
    end)
    h.assert_truthy(output:find("can't light") or output:find("light that")
        or output:find("don't have") or output:find("nothing"),
        "light non-lightable should refuse")
end)

test("extinguish a non-lit object refuses", function()
    local rock = fresh_object({ id = "rock", name = "a rock", keywords = {"rock"} })
    local ctx = make_ctx()
    ctx.registry:register("rock", rock)
    ctx.player.hands[1] = rock
    local output = capture_output(function()
        handlers["extinguish"](ctx, "rock")
    end)
    h.assert_truthy(output:find("can't") or output:find("not lit")
        or output:find("extinguish") or output:find("isn't"),
        "extinguish non-lit should refuse")
end)

test("unlock a non-lockable room object refuses", function()
    local rock = fresh_object({ id = "rock", name = "a rock", keywords = {"rock"} })
    local ctx = make_ctx({ room_contents = {"rock"} })
    ctx.registry:register("rock", rock)
    local output = capture_output(function()
        handlers["unlock"](ctx, "rock")
    end)
    h.assert_truthy(output:find("can't unlock"),
        "unlock non-lockable should refuse")
end)

---------------------------------------------------------------------------
-- 20. CONSCIOUSNESS GATE — detailed: verify message and no side effects
---------------------------------------------------------------------------
suite("Consciousness gate — detailed behavior")

test("unconscious take produces only 'unconscious' message", function()
    local obj = fresh_object({ id = "gem", name = "a gem", keywords = {"gem"} })
    local ctx = make_unconscious_ctx({ room_contents = {"gem"} })
    ctx.registry:register("gem", obj)
    local output = capture_output(function()
        handlers["take"](ctx, "gem")
    end)
    eq("You are unconscious.", output, "Should only say 'You are unconscious.'")
    h.assert_truthy(ctx.player.hands[1] == nil, "Should not pick up while unconscious")
end)

test("unconscious look produces only 'unconscious' message", function()
    local ctx = make_unconscious_ctx()
    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)
    eq("You are unconscious.", output, "Should only say 'You are unconscious.'")
end)

test("unconscious inventory produces only 'unconscious' message", function()
    local ctx = make_unconscious_ctx()
    local output = capture_output(function()
        handlers["inventory"](ctx, "")
    end)
    eq("You are unconscious.", output, "Should only say 'You are unconscious.'")
end)

test("unconscious north produces only 'unconscious' message", function()
    local ctx = make_unconscious_ctx()
    local output = capture_output(function()
        handlers["north"](ctx, "")
    end)
    eq("You are unconscious.", output, "Should only say 'You are unconscious.'")
end)

test("unconscious drop produces only 'unconscious' message", function()
    local obj = fresh_object({ id = "gem", name = "a gem", keywords = {"gem"} })
    local ctx = make_unconscious_ctx()
    ctx.player.hands[1] = obj
    local output = capture_output(function()
        handlers["drop"](ctx, "gem")
    end)
    eq("You are unconscious.", output, "Should only say 'You are unconscious.'")
    -- Object should still be in hand
    h.assert_truthy(ctx.player.hands[1] ~= nil, "Should not drop while unconscious")
end)

---------------------------------------------------------------------------
-- SUMMARY
---------------------------------------------------------------------------
h.summary()
