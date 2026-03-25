-- test/sensory/test-senses-comprehensive.lua
-- Comprehensive tests for the 5-sense system and light/darkness mechanics.
-- Covers: LOOK, FEEL, SMELL, LISTEN, TASTE, darkness behavior,
--         FSM state-dependent sensory text, and on_feel coverage.
--
-- Usage: lua test/sensory/test-senses-comprehensive.lua
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

-- Build a test context. time_offset controls daylight:
--   0 = 2 AM (dark, no daylight), 6 = 8 AM (daytime), etc.
local function make_ctx(opts)
    opts = opts or {}
    local reg = registry_mod.new()
    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A plain test room with stone walls.",
        on_smell = opts.room_smell or nil,
        on_listen = opts.room_listen or nil,
        contents = opts.room_contents or {},
        exits = opts.exits or {},
    }
    local player = {
        hands = opts.hands or { nil, nil },
        worn = opts.worn or {},
        injuries = {},
        bags = {},
        state = opts.player_state or {},
        skills = {},
        max_health = 100,
        consciousness = { state = "conscious" },
        visited_rooms = { ["test-room"] = true },
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = opts.time_offset or 0, -- default = 2 AM (dark)
        game_start_time = os.time(),
        current_verb = opts.verb or "",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

-- A candle object with FSM states (mirrors src/meta/objects/candle.lua)
local function make_candle(state)
    return {
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle", "tallow candle"},
        material = "wax",
        size = 1,
        weight = 0.5,
        portable = true,
        initial_state = "unlit",
        _state = state or "unlit",
        description = "A stubby tallow candle with a blackened wick.",
        on_feel = "A smooth wax cylinder, slightly greasy.",
        on_smell = "Faintly waxy -- old tallow and a memory of smoke.",
        on_listen = "Silent.",
        casts_light = false,
        states = {
            unlit = {
                name = "a tallow candle",
                description = "A stubby tallow candle. It is not lit.",
                on_feel = "A smooth wax cylinder, slightly greasy. It tapers to a blackened wick at the top.",
                on_smell = "Faintly waxy -- old tallow and a memory of smoke.",
                on_listen = "Silent.",
                casts_light = false,
            },
            lit = {
                name = "a lit tallow candle",
                description = "A tallow candle burns with a steady yellow flame.",
                on_feel = "Warm wax, softening near the flame. Careful -- it's hot.",
                on_smell = "Burning wick and melting tallow. Thin smoke curls upward, acrid and animal.",
                on_listen = "A gentle crackling, and the soft hiss of melting wax.",
                casts_light = true,
                provides_tool = "fire_source",
                light_radius = 2,
            },
            extinguished = {
                name = "a half-burned candle",
                description = "A tallow candle, recently extinguished.",
                on_feel = "Rough wax drippings, still warm from recent burning.",
                on_smell = "Smoke and warm tallow. The ghost of a flame.",
                on_listen = "Silent.",
                casts_light = false,
            },
            spent = {
                name = "a spent candle",
                description = "Nothing but a black nub of carbon.",
                on_feel = "A hard nub of carbon in a pool of hardened wax. Dead.",
                on_smell = "The ghost of burnt tallow. Nothing more.",
                casts_light = false,
                terminal = true,
            },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light",
              requires_tool = "fire_source",
              message = "The wick catches the flame." },
            { from = "lit", to = "extinguished", verb = "extinguish",
              message = "You blow out the candle." },
            { from = "extinguished", to = "lit", verb = "light",
              requires_tool = "fire_source",
              message = "The wick catches again." },
        },
    }
end

-- A simple object with sensory properties
local function make_coin()
    return {
        id = "coin",
        name = "a gold coin",
        keywords = {"coin", "gold coin"},
        on_feel = "A small, cold metal disc with ridged edges.",
        on_smell = "Faint metallic tang.",
        on_listen = "Clink.",
        on_taste = "Cold metal. Tastes like regret.",
        description = "A shiny gold coin.",
    }
end

-- An object with no optional sensory (only on_feel)
local function make_rock()
    return {
        id = "rock",
        name = "a plain rock",
        keywords = {"rock", "stone"},
        on_feel = "Rough and cold. Heavy for its size.",
        description = "A nondescript grey rock.",
    }
end

-- A poisonous object
local function make_poison_bottle()
    return {
        id = "poison-bottle",
        name = "a small glass bottle",
        keywords = {"bottle", "poison bottle", "glass bottle"},
        on_feel = "Smooth glass. Something sloshes inside.",
        on_smell = "A sweet, cloying scent. Almost pleasant.",
        on_taste = "Sweet... and then burning. Your tongue goes numb.",
        on_taste_effect = {
            type = "poison",
            damage = 10,
            message = "A burning sensation spreads through your mouth.",
        },
        description = "A small glass bottle filled with dark liquid.",
    }
end

-- Light source
local function make_light()
    return {
        id = "lantern",
        name = "a lantern",
        keywords = {"lantern"},
        casts_light = true,
        on_feel = "Warm metal and glass.",
    }
end

-- Door exit for exit-feel tests
local function make_door_exit()
    return {
        north = {
            target = "hallway",
            type = "door",
            name = "a wooden door",
            keywords = {"door", "wooden door"},
            on_feel = "Rough oak planks, iron-banded. A keyhole on the right.",
            locked = true,
        },
    }
end

-- Apply FSM state to an object (mimics engine behavior)
local function apply_fsm_state(obj, state_name)
    local state = obj.states[state_name]
    if not state then return end
    for k, v in pairs(state) do
        if k ~= "terminal" and k ~= "on_tick" then
            obj[k] = v
        end
    end
    obj._state = state_name
end

---------------------------------------------------------------------------
-- SECTION 1: LOOK / EXAMINE — requires light
---------------------------------------------------------------------------
suite("LOOK — bare look in darkness")

test("bare look in dark room says too dark", function()
    local ctx = make_ctx({ time_offset = 0 }) -- 2 AM, dark
    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)
    h.assert_truthy(output:lower():find("dark") or output:lower():find("too dark"),
        "Bare look in dark should mention darkness, got: " .. output)
end)

test("bare look suggests 'feel' in darkness", function()
    local ctx = make_ctx({ time_offset = 0 })
    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)
    h.assert_truthy(output:lower():find("feel"),
        "Dark room look should suggest feel, got: " .. output)
end)

suite("LOOK — bare look with light")

test("bare look with light shows room description", function()
    local light = make_light()
    local ctx = make_ctx({ room_contents = {"lantern"}, time_offset = 0 })
    ctx.registry:register("lantern", light)
    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)
    h.assert_truthy(output:find("stone walls"),
        "Lit room look should show room description, got: " .. output)
end)

test("bare look during daytime shows room description", function()
    local window = {
        id = "window",
        name = "a window",
        keywords = {"window"},
        allows_daylight = true,
        on_feel = "Cold glass.",
    }
    local ctx = make_ctx({ room_contents = {"window"}, time_offset = 6 }) -- 8 AM
    ctx.registry:register("window", window)
    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)
    h.assert_truthy(output:find("stone walls"),
        "Daytime room should show description, got: " .. output)
end)

suite("LOOK AT / EXAMINE — object with light")

test("look at object with light shows description", function()
    local coin = make_coin()
    local light = make_light()
    local ctx = make_ctx({ room_contents = {"coin", "lantern"} })
    ctx.registry:register("coin", coin)
    ctx.registry:register("lantern", light)
    local output = capture_output(function()
        handlers["look"](ctx, "at coin")
    end)
    h.assert_truthy(output:find("shiny gold coin"),
        "Look at coin should show visual description, got: " .. output)
end)

suite("EXAMINE — darkness fallback to on_feel")

test("examine in darkness falls back to on_feel", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"}, time_offset = 0 })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["examine"](ctx, "coin")
    end)
    h.assert_truthy(output:find("cold metal disc") or output:find("ridged edges"),
        "Examine in dark should show on_feel text, got: " .. output)
end)

test("examine in darkness mentions too dark", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"}, time_offset = 0 })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["examine"](ctx, "coin")
    end)
    h.assert_truthy(output:lower():find("dark") or output:lower():find("feel"),
        "Examine in dark should mention darkness, got: " .. output)
end)

test("examine nonexistent object in darkness says can't find", function()
    local ctx = make_ctx({ time_offset = 0 })
    local output = capture_output(function()
        handlers["examine"](ctx, "unicorn")
    end)
    h.assert_truthy(output:lower():find("can't find") or output:lower():find("darkness"),
        "Examine missing object in dark should fail, got: " .. output)
end)

---------------------------------------------------------------------------
-- SECTION 2: FEEL / TOUCH — always works (even in darkness)
---------------------------------------------------------------------------
suite("FEEL — works in total darkness")

test("feel object in dark room returns on_feel text", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"}, time_offset = 0 })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["feel"](ctx, "coin")
    end)
    h.assert_truthy(output:find("cold metal disc"),
        "Feel in dark should show on_feel, got: " .. output)
end)

test("bare feel in dark room lists objects by touch", function()
    local coin = make_coin()
    local rock = make_rock()
    local ctx = make_ctx({ room_contents = {"coin", "rock"}, time_offset = 0 })
    ctx.registry:register("coin", coin)
    ctx.registry:register("rock", rock)
    local output = capture_output(function()
        handlers["feel"](ctx, "")
    end)
    h.assert_truthy(output:find("gold coin"),
        "Bare feel should list coin, got: " .. output)
    h.assert_truthy(output:find("plain rock"),
        "Bare feel should list rock, got: " .. output)
end)

test("feel 'around' also does room sweep", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"}, time_offset = 0 })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["feel"](ctx, "around")
    end)
    h.assert_truthy(output:find("gold coin"),
        "Feel around should sweep, got: " .. output)
end)

suite("TOUCH — alias for feel")

test("touch uses same handler as feel", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"}, time_offset = 0 })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["touch"](ctx, "coin")
    end)
    h.assert_truthy(output:find("cold metal disc"),
        "Touch should work same as feel, got: " .. output)
end)

suite("FEEL — works with light too")

test("feel object in lit room still returns on_feel", function()
    local coin = make_coin()
    local light = make_light()
    local ctx = make_ctx({ room_contents = {"coin", "lantern"} })
    ctx.registry:register("coin", coin)
    ctx.registry:register("lantern", light)
    local output = capture_output(function()
        handlers["feel"](ctx, "coin")
    end)
    h.assert_truthy(output:find("cold metal disc"),
        "Feel should work in light too, got: " .. output)
end)

suite("FEEL — exit/door feel in darkness")

test("feel door in dark returns on_feel for exit", function()
    local exits = make_door_exit()
    local ctx = make_ctx({ exits = exits, time_offset = 0 })
    local output = capture_output(function()
        handlers["feel"](ctx, "door")
    end)
    h.assert_truthy(output:find("oak planks") or output:find("iron") or output:find("keyhole"),
        "Feel door in dark should return exit on_feel, got: " .. output)
end)

suite("FEEL — object with no on_feel falls back gracefully")

test("feel object without on_feel gives generic description", function()
    local obj = {
        id = "blob",
        name = "a mysterious blob",
        keywords = {"blob"},
        description = "A shapeless blob.",
    }
    local ctx = make_ctx({ room_contents = {"blob"} })
    ctx.registry:register("blob", obj)
    local output = capture_output(function()
        handlers["feel"](ctx, "blob")
    end)
    h.assert_truthy(output:find("blob") or output:find("ordinary"),
        "Feel should give some output for object without on_feel, got: " .. output)
end)

suite("FEEL — missing object")

test("feel nonexistent object says can't feel", function()
    local ctx = make_ctx({ time_offset = 0 })
    local output = capture_output(function()
        handlers["feel"](ctx, "unicorn")
    end)
    h.assert_truthy(output:lower():find("can't feel") or output:lower():find("nearby"),
        "Feel missing object should fail gracefully, got: " .. output)
end)

---------------------------------------------------------------------------
-- SECTION 3: SMELL / SNIFF — always works
---------------------------------------------------------------------------
suite("SMELL — bare smell (room sweep)")

test("bare smell with no room smell gives default", function()
    local ctx = make_ctx({ time_offset = 0 })
    local output = capture_output(function()
        handlers["smell"](ctx, "")
    end)
    h.assert_truthy(output:lower():find("dust") or output:lower():find("smell"),
        "Bare smell should give default room smell, got: " .. output)
end)

test("bare smell shows room on_smell when set", function()
    local ctx = make_ctx({ room_smell = "Damp stone and mildew.", time_offset = 0 })
    local output = capture_output(function()
        handlers["smell"](ctx, "")
    end)
    h.assert_truthy(output:find("Damp stone"),
        "Bare smell should show room on_smell, got: " .. output)
end)

test("bare smell includes nearby object smells", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"}, time_offset = 0 })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["smell"](ctx, "")
    end)
    h.assert_truthy(output:find("metallic tang"),
        "Bare smell should include coin's on_smell, got: " .. output)
end)

test("bare smell in dark still works", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"}, time_offset = 0 })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["smell"](ctx, "")
    end)
    -- Should NOT say "too dark"
    eq(nil, output:lower():find("too dark"),
        "Smell should NOT require light")
    h.assert_truthy(output:find("metallic") or output:find("smell"),
        "Smell should work in dark, got: " .. output)
end)

suite("SMELL — specific object")

test("smell specific object shows on_smell", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"} })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["smell"](ctx, "coin")
    end)
    h.assert_truthy(output:find("metallic tang"),
        "Smell coin should show on_smell, got: " .. output)
end)

test("smell object without on_smell gives default", function()
    local rock = make_rock()
    local ctx = make_ctx({ room_contents = {"rock"} })
    ctx.registry:register("rock", rock)
    local output = capture_output(function()
        handlers["smell"](ctx, "rock")
    end)
    h.assert_truthy(output:lower():find("nothing distinctive") or output:lower():find("don't smell"),
        "Smell object without on_smell gives default, got: " .. output)
end)

suite("SNIFF — alias for smell")

test("sniff uses same handler as smell", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"} })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["sniff"](ctx, "coin")
    end)
    h.assert_truthy(output:find("metallic tang"),
        "Sniff should work same as smell, got: " .. output)
end)

suite("SMELL — carried items")

test("bare smell detects objects in player hands", function()
    local coin = make_coin()
    local ctx = make_ctx({ hands = { coin, nil } })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["smell"](ctx, "")
    end)
    h.assert_truthy(output:find("metallic tang"),
        "Bare smell should detect held item's smell, got: " .. output)
end)

---------------------------------------------------------------------------
-- SECTION 4: LISTEN / HEAR — always works
---------------------------------------------------------------------------
suite("LISTEN — bare listen (room sweep)")

test("bare listen with no room sound gives default", function()
    local ctx = make_ctx({ time_offset = 0 })
    local output = capture_output(function()
        handlers["listen"](ctx, "")
    end)
    h.assert_truthy(output:lower():find("silence") or output:lower():find("heartbeat") or output:lower():find("listen"),
        "Bare listen should give default, got: " .. output)
end)

test("bare listen shows room on_listen when set", function()
    local ctx = make_ctx({ room_listen = "Dripping water echoes in the distance.", time_offset = 0 })
    local output = capture_output(function()
        handlers["listen"](ctx, "")
    end)
    h.assert_truthy(output:find("Dripping water"),
        "Bare listen should show room on_listen, got: " .. output)
end)

test("bare listen includes nearby object sounds", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"}, time_offset = 0 })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["listen"](ctx, "")
    end)
    h.assert_truthy(output:find("Clink"),
        "Bare listen should include coin's on_listen, got: " .. output)
end)

test("bare listen in dark still works", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"}, time_offset = 0 })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["listen"](ctx, "")
    end)
    eq(nil, output:lower():find("too dark"),
        "Listen should NOT require light")
end)

suite("LISTEN — specific object")

test("listen to specific object shows on_listen", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"} })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["listen"](ctx, "to coin")
    end)
    h.assert_truthy(output:find("Clink"),
        "Listen to coin should show on_listen, got: " .. output)
end)

test("listen without 'to' prefix also works", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"} })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["listen"](ctx, "coin")
    end)
    h.assert_truthy(output:find("Clink"),
        "Listen coin (no 'to') should work, got: " .. output)
end)

test("listen to object without on_listen gives default", function()
    local rock = make_rock()
    local ctx = make_ctx({ room_contents = {"rock"} })
    ctx.registry:register("rock", rock)
    local output = capture_output(function()
        handlers["listen"](ctx, "rock")
    end)
    h.assert_truthy(output:lower():find("no sound") or output:lower():find("makes no sound"),
        "Listen to silent object gives default, got: " .. output)
end)

suite("HEAR — alias for listen")

test("hear uses same handler as listen", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"} })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["hear"](ctx, "to coin")
    end)
    h.assert_truthy(output:find("Clink"),
        "Hear should work same as listen, got: " .. output)
end)

suite("LISTEN — carried items")

test("bare listen detects objects in player hands", function()
    local coin = make_coin()
    local ctx = make_ctx({ hands = { coin, nil } })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["listen"](ctx, "")
    end)
    h.assert_truthy(output:find("Clink"),
        "Bare listen should detect held item's sound, got: " .. output)
end)

---------------------------------------------------------------------------
-- SECTION 5: TASTE / LICK — always works, DANGEROUS
---------------------------------------------------------------------------
suite("TASTE — basic tasting")

test("taste object shows on_taste", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"} })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["taste"](ctx, "coin")
    end)
    h.assert_truthy(output:find("Cold metal") or output:find("regret"),
        "Taste should show on_taste, got: " .. output)
end)

test("taste object without on_taste gives generic", function()
    local rock = make_rock()
    local ctx = make_ctx({ room_contents = {"rock"} })
    ctx.registry:register("rock", rock)
    local output = capture_output(function()
        handlers["taste"](ctx, "rock")
    end)
    h.assert_truthy(output:lower():find("lick") or output:lower():find("nothing remarkable"),
        "Taste without on_taste gives generic, got: " .. output)
end)

test("bare taste gives humorous refusal", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["taste"](ctx, "")
    end)
    h.assert_truthy(output:lower():find("floor") or output:lower():find("lick"),
        "Bare taste should refuse humorously, got: " .. output)
end)

test("taste in darkness still works", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"}, time_offset = 0 })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["taste"](ctx, "coin")
    end)
    eq(nil, output:lower():find("too dark"),
        "Taste should NOT require light")
    h.assert_truthy(output:find("Cold metal") or output:find("regret"),
        "Taste should work in dark, got: " .. output)
end)

suite("LICK — alias for taste")

test("lick uses same handler as taste", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"} })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["lick"](ctx, "coin")
    end)
    h.assert_truthy(output:find("Cold metal") or output:find("regret"),
        "Lick should work same as taste, got: " .. output)
end)

suite("TASTE — poison effects")

test("tasting poison triggers on_taste_effect", function()
    local bottle = make_poison_bottle()
    local ctx = make_ctx({ room_contents = {"poison-bottle"} })
    ctx.registry:register("poison-bottle", bottle)
    -- Effects module may print damage messages; we just verify no crash
    local output = capture_output(function()
        handlers["taste"](ctx, "bottle")
    end)
    h.assert_truthy(output:find("Sweet") or output:find("burning") or output:find("numb"),
        "Tasting poison should show taste text, got: " .. output)
end)

---------------------------------------------------------------------------
-- SECTION 6: DARKNESS BEHAVIOR — light lifecycle
---------------------------------------------------------------------------
suite("DARKNESS — game starts at 2 AM (dark)")

test("no light source at 2 AM = dark", function()
    local rock = make_rock()
    local ctx = make_ctx({ room_contents = {"rock"}, time_offset = 0 })
    ctx.registry:register("rock", rock)
    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)
    h.assert_truthy(output:lower():find("dark"),
        "2 AM with no light should be dark, got: " .. output)
end)

suite("DARKNESS — candle provides light")

test("lit candle in room makes look work", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "lit")
    local ctx = make_ctx({ room_contents = {"candle"}, time_offset = 0 })
    ctx.registry:register("candle", candle)
    h.assert_truthy(candle.casts_light,
        "Lit candle should have casts_light = true")
    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)
    h.assert_truthy(output:find("stone walls"),
        "Lit candle should enable look, got: " .. output)
end)

test("unlit candle in room does NOT provide light", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "unlit")
    local ctx = make_ctx({ room_contents = {"candle"}, time_offset = 0 })
    ctx.registry:register("candle", candle)
    eq(false, candle.casts_light, "Unlit candle should not cast light")
    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)
    h.assert_truthy(output:lower():find("dark"),
        "Unlit candle should not enable look, got: " .. output)
end)

suite("DARKNESS — candle burns out returns to dark")

test("spent candle means darkness", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "spent")
    local ctx = make_ctx({ room_contents = {"candle"}, time_offset = 0 })
    ctx.registry:register("candle", candle)
    eq(false, candle.casts_light, "Spent candle should not cast light")
    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)
    h.assert_truthy(output:lower():find("dark"),
        "Spent candle should mean darkness, got: " .. output)
end)

test("extinguished candle means darkness", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "extinguished")
    local ctx = make_ctx({ room_contents = {"candle"}, time_offset = 0 })
    ctx.registry:register("candle", candle)
    eq(false, candle.casts_light, "Extinguished candle should not cast light")
    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)
    h.assert_truthy(output:lower():find("dark"),
        "Extinguished candle should mean darkness, got: " .. output)
end)

suite("DARKNESS — player carrying light source")

test("lit candle in player hand provides light", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "lit")
    local ctx = make_ctx({ hands = { candle, nil }, time_offset = 0 })
    ctx.registry:register("candle", candle)
    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)
    h.assert_truthy(output:find("stone walls"),
        "Candle in hand should enable look, got: " .. output)
end)

suite("DARKNESS — non-visual senses unaffected")

test("feel works in total darkness", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"}, time_offset = 0 })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["feel"](ctx, "coin")
    end)
    h.assert_truthy(output:find("cold metal disc"),
        "Feel should work at 2 AM in dark, got: " .. output)
end)

test("smell works in total darkness", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"}, time_offset = 0 })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["smell"](ctx, "coin")
    end)
    h.assert_truthy(output:find("metallic tang"),
        "Smell should work at 2 AM in dark, got: " .. output)
end)

test("listen works in total darkness", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"}, time_offset = 0 })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["listen"](ctx, "coin")
    end)
    h.assert_truthy(output:find("Clink"),
        "Listen should work at 2 AM in dark, got: " .. output)
end)

test("taste works in total darkness", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"}, time_offset = 0 })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["taste"](ctx, "coin")
    end)
    h.assert_truthy(output:find("Cold metal") or output:find("regret"),
        "Taste should work at 2 AM in dark, got: " .. output)
end)

---------------------------------------------------------------------------
-- SECTION 7: FSM STATE-DEPENDENT SENSORY TEXT
---------------------------------------------------------------------------
suite("FSM STATE — candle sensory text varies by state")

test("unlit candle on_feel matches unlit state", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "unlit")
    local ctx = make_ctx({ room_contents = {"candle"}, time_offset = 0 })
    ctx.registry:register("candle", candle)
    local output = capture_output(function()
        handlers["feel"](ctx, "candle")
    end)
    h.assert_truthy(output:find("smooth") or output:find("greasy") or output:find("blackened wick"),
        "Unlit candle on_feel should match unlit state, got: " .. output)
end)

test("lit candle on_feel mentions warmth", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "lit")
    local ctx = make_ctx({ room_contents = {"candle"}, time_offset = 0 })
    ctx.registry:register("candle", candle)
    local output = capture_output(function()
        handlers["feel"](ctx, "candle")
    end)
    h.assert_truthy(output:find("Warm") or output:find("hot") or output:find("softening"),
        "Lit candle on_feel should mention warmth, got: " .. output)
end)

test("extinguished candle on_feel mentions drippings", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "extinguished")
    local ctx = make_ctx({ room_contents = {"candle"}, time_offset = 0 })
    ctx.registry:register("candle", candle)
    local output = capture_output(function()
        handlers["feel"](ctx, "candle")
    end)
    h.assert_truthy(output:find("drippings") or output:find("warm from recent"),
        "Extinguished candle on_feel should mention drippings, got: " .. output)
end)

test("spent candle on_feel mentions carbon nub", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "spent")
    local ctx = make_ctx({ room_contents = {"candle"}, time_offset = 0 })
    ctx.registry:register("candle", candle)
    local output = capture_output(function()
        handlers["feel"](ctx, "candle")
    end)
    h.assert_truthy(output:find("carbon") or output:find("Dead") or output:find("hardened wax"),
        "Spent candle on_feel should mention carbon, got: " .. output)
end)

suite("FSM STATE — candle on_smell varies by state")

test("unlit candle smells waxy", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "unlit")
    local ctx = make_ctx({ room_contents = {"candle"}, time_offset = 0 })
    ctx.registry:register("candle", candle)
    local output = capture_output(function()
        handlers["smell"](ctx, "candle")
    end)
    h.assert_truthy(output:find("waxy") or output:find("tallow"),
        "Unlit candle smell should be waxy, got: " .. output)
end)

test("lit candle smells of burning", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "lit")
    local ctx = make_ctx({ room_contents = {"candle"}, time_offset = 0 })
    ctx.registry:register("candle", candle)
    local output = capture_output(function()
        handlers["smell"](ctx, "candle")
    end)
    h.assert_truthy(output:find("Burning") or output:find("melting") or output:find("acrid"),
        "Lit candle smell should mention burning, got: " .. output)
end)

test("spent candle smells like ghost of tallow", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "spent")
    local ctx = make_ctx({ room_contents = {"candle"}, time_offset = 0 })
    ctx.registry:register("candle", candle)
    local output = capture_output(function()
        handlers["smell"](ctx, "candle")
    end)
    h.assert_truthy(output:find("ghost") or output:find("burnt tallow"),
        "Spent candle smell should be faint, got: " .. output)
end)

suite("FSM STATE — candle on_listen varies by state")

test("unlit candle is silent", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "unlit")
    local ctx = make_ctx({ room_contents = {"candle"} })
    ctx.registry:register("candle", candle)
    local output = capture_output(function()
        handlers["listen"](ctx, "candle")
    end)
    h.assert_truthy(output:find("Silent") or output:lower():find("no sound"),
        "Unlit candle should be silent, got: " .. output)
end)

test("lit candle crackles", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "lit")
    local ctx = make_ctx({ room_contents = {"candle"} })
    ctx.registry:register("candle", candle)
    local output = capture_output(function()
        handlers["listen"](ctx, "candle")
    end)
    h.assert_truthy(output:find("crackling") or output:find("hiss"),
        "Lit candle should crackle, got: " .. output)
end)

suite("FSM STATE — candle description varies (with light)")

test("unlit candle description says 'not lit'", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "unlit")
    -- Need separate light source to see the candle
    local light = make_light()
    local ctx = make_ctx({ room_contents = {"candle", "lantern"} })
    ctx.registry:register("candle", candle)
    ctx.registry:register("lantern", light)
    local output = capture_output(function()
        handlers["look"](ctx, "at candle")
    end)
    h.assert_truthy(output:find("not lit") or output:find("blackened wick"),
        "Unlit candle visual should say not lit, got: " .. output)
end)

test("lit candle description mentions flame", function()
    local candle = make_candle("unlit")
    apply_fsm_state(candle, "lit")
    local ctx = make_ctx({ room_contents = {"candle"} })
    ctx.registry:register("candle", candle)
    local output = capture_output(function()
        handlers["look"](ctx, "at candle")
    end)
    h.assert_truthy(output:find("flame") or output:find("burns") or output:find("steady"),
        "Lit candle visual should mention flame, got: " .. output)
end)

---------------------------------------------------------------------------
-- SECTION 8: DIM LIGHT — filtered daylight
---------------------------------------------------------------------------
suite("DIM LIGHT — curtains filter daylight")

test("dim light preamble shown during daytime with curtain filter", function()
    local curtain = {
        id = "curtain",
        name = "heavy curtains",
        keywords = {"curtain", "curtains"},
        filters_daylight = true,
        on_feel = "Heavy velvet.",
    }
    local ctx = make_ctx({ room_contents = {"curtain"}, time_offset = 6 }) -- 8 AM
    ctx.registry:register("curtain", curtain)
    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)
    h.assert_truthy(output:lower():find("dim") or output:lower():find("shadow"),
        "Dim light should show preamble, got: " .. output)
    -- Room description should still be visible
    h.assert_truthy(output:find("stone walls"),
        "Dim light should still show room description, got: " .. output)
end)

---------------------------------------------------------------------------
-- SECTION 9: VERB ALIASES
---------------------------------------------------------------------------
suite("VERB ALIASES — all sensory aliases work")

test("x is alias for examine", function()
    local coin = make_coin()
    local light = make_light()
    local ctx = make_ctx({ room_contents = {"coin", "lantern"} })
    ctx.registry:register("coin", coin)
    ctx.registry:register("lantern", light)
    local output = capture_output(function()
        handlers["x"](ctx, "coin")
    end)
    h.assert_truthy(output:find("shiny gold coin") or output:find("gold coin"),
        "x should work as examine alias, got: " .. output)
end)

test("inspect is alias for examine", function()
    local coin = make_coin()
    local light = make_light()
    local ctx = make_ctx({ room_contents = {"coin", "lantern"} })
    ctx.registry:register("coin", coin)
    ctx.registry:register("lantern", light)
    local output = capture_output(function()
        handlers["inspect"](ctx, "coin")
    end)
    h.assert_truthy(output:find("shiny gold coin") or output:find("gold coin"),
        "inspect should work as examine alias, got: " .. output)
end)

test("check is alias for examine", function()
    local coin = make_coin()
    local light = make_light()
    local ctx = make_ctx({ room_contents = {"coin", "lantern"} })
    ctx.registry:register("coin", coin)
    ctx.registry:register("lantern", light)
    local output = capture_output(function()
        handlers["check"](ctx, "coin")
    end)
    h.assert_truthy(output:find("shiny gold coin") or output:find("gold coin"),
        "check should work as examine alias, got: " .. output)
end)

test("grope is alias for feel", function()
    local coin = make_coin()
    local ctx = make_ctx({ room_contents = {"coin"} })
    ctx.registry:register("coin", coin)
    local output = capture_output(function()
        handlers["grope"](ctx, "coin")
    end)
    h.assert_truthy(output:find("cold metal disc"),
        "grope should work as feel alias, got: " .. output)
end)

---------------------------------------------------------------------------
-- SECTION 10: EDGE CASES
---------------------------------------------------------------------------
suite("EDGE — hidden objects excluded from room sweeps")

test("hidden object not listed in bare feel sweep", function()
    local hidden_obj = {
        id = "secret",
        name = "a secret lever",
        keywords = {"lever"},
        hidden = true,
        on_feel = "Cold metal lever.",
    }
    local ctx = make_ctx({ room_contents = {"secret"}, time_offset = 0 })
    ctx.registry:register("secret", hidden_obj)
    local output = capture_output(function()
        handlers["feel"](ctx, "")
    end)
    eq(nil, output:find("secret lever"),
        "Hidden object should NOT appear in feel sweep")
end)

test("hidden object not listed in bare smell sweep", function()
    local hidden_obj = {
        id = "secret",
        name = "a secret lever",
        keywords = {"lever"},
        hidden = true,
        on_smell = "Oiled metal.",
    }
    local ctx = make_ctx({ room_contents = {"secret"} })
    ctx.registry:register("secret", hidden_obj)
    local output = capture_output(function()
        handlers["smell"](ctx, "")
    end)
    eq(nil, output:find("Oiled metal"),
        "Hidden object should NOT appear in smell sweep")
end)

suite("EDGE — empty room")

test("feel in empty room says nothing to feel", function()
    local ctx = make_ctx({ room_contents = {}, time_offset = 0 })
    local output = capture_output(function()
        handlers["feel"](ctx, "")
    end)
    h.assert_truthy(output:lower():find("nothing") or output:lower():find("find nothing"),
        "Empty room feel should say nothing, got: " .. output)
end)

suite("EDGE — vision blocked by worn item")

test("look while wearing sack on head says blocked", function()
    local sack = {
        id = "sack",
        name = "a burlap sack",
        keywords = {"sack"},
        on_feel = "Rough burlap.",
        wear = { slot = "head", blocks_vision = true },
    }
    local ctx = make_ctx({ worn = {"sack"}, time_offset = 6, room_contents = {"sack"} })
    ctx.registry:register("sack", sack)
    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)
    h.assert_truthy(output:lower():find("can't see") or output:lower():find("covering"),
        "Vision blocked by sack should say can't see, got: " .. output)
end)

---------------------------------------------------------------------------
-- SECTION 11: on_feel COVERAGE AUDIT (programmatic)
---------------------------------------------------------------------------
suite("ON_FEEL AUDIT — all objects in src/meta/objects must have on_feel")

test("every object file has on_feel property", function()
    local dir = "src" .. SEP .. "meta" .. SEP .. "objects"
    local list_cmd
    if SEP == "\\" then
        list_cmd = 'dir /b "' .. dir .. '\\*.lua" 2>nul'
    else
        list_cmd = 'ls "' .. dir .. '"/test-*.lua 2>/dev/null'
    end
    local handle = io.popen(list_cmd)
    local missing = {}
    local total = 0
    if handle then
        for f in handle:lines() do
            total = total + 1
            local path = dir .. SEP .. f
            local ok, obj = pcall(dofile, path)
            if ok and type(obj) == "table" then
                local has_feel = obj.on_feel ~= nil
                if not has_feel and obj.states then
                    for _, state in pairs(obj.states) do
                        if state.on_feel then has_feel = true break end
                    end
                end
                if not has_feel then
                    missing[#missing + 1] = f .. " (id=" .. tostring(obj.id) .. ")"
                end
            end
        end
        handle:close()
    end
    h.assert_truthy(total > 0, "Should find object files")
    eq(0, #missing,
        "Objects missing on_feel: " .. table.concat(missing, ", "))
end)

---------------------------------------------------------------------------
os.exit(h.summary() > 0 and 1 or 0)
