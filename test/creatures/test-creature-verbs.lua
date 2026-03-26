-- test/creatures/test-creature-verbs.lua
-- WAVE-3 TDD: Validates creature verb handlers — catch, room presence in look,
-- darkness visibility, injury-on-catch, hands-full guard, dead creature guard.
-- Must be run from repository root: lua test/creatures/test-creature-verbs.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

math.randomseed(42)

---------------------------------------------------------------------------
-- Load modules (pcall-guarded — TDD: some may not exist yet)
---------------------------------------------------------------------------
local ok_verbs_mod, verbs_mod = pcall(require, "engine.verbs")
if not ok_verbs_mod then
    print("WARNING: engine.verbs not found — verb tests will fail (TDD: expected)")
    verbs_mod = nil
end

local ok_creatures, creatures = pcall(require, "engine.creatures")
if not ok_creatures then
    print("WARNING: engine.creatures not found — creature tests will fail (TDD: expected)")
    creatures = nil
end

local ok_injuries, injuries = pcall(require, "engine.injuries")
if not ok_injuries then
    print("WARNING: engine.injuries not found — injury tests will fail (TDD: expected)")
    injuries = nil
end

---------------------------------------------------------------------------
-- Print capture utility — pcall-safe (always restores print)
---------------------------------------------------------------------------
local real_print = print

local function capture_call(fn, ...)
    local output = {}
    local old_print = print
    print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[#parts + 1] = tostring(select(i, ...))
        end
        output[#output + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn, ...)
    print = old_print
    return output, ok, err
end

local function output_contains(output, substring)
    for _, line in ipairs(output) do
        if line:find(substring, 1, true) then return true end
    end
    return false
end

local function output_matches_any(output, patterns)
    for _, line in ipairs(output) do
        local lower = line:lower()
        for _, pat in ipairs(patterns) do
            if lower:find(pat, 1, true) then return true end
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Mock helpers
---------------------------------------------------------------------------
local function make_mock_creature(overrides)
    local c = {
        guid = "{verb-creature-" .. tostring(math.random(99999)) .. "}",
        template = "creature",
        id = "mock-rat",
        name = "a brown rat",
        keywords = {"rat", "rodent", "vermin"},
        animate = true,
        alive = true,
        health = 5,
        max_health = 5,
        size = "tiny",
        weight = 0.3,
        material = "flesh",
        portable = false,
        location = "cellar",
        initial_state = "alive-idle",
        _state = "alive-idle",
        states = {
            ["alive-idle"] = {
                description = "A plump rat crouches motionless.",
                room_presence = "A rat crouches in the shadows near the wall.",
                on_listen = "Skittering claws on stone.",
            },
            ["alive-wander"] = {
                description = "A rat scurries across the floor.",
                room_presence = "A rat scurries along the baseboard.",
                on_listen = "Tiny claws clicking on stone.",
            },
            ["alive-flee"] = {
                description = "A panicked rat darts frantically.",
                room_presence = "A panicked rat zigzags across the floor.",
                on_listen = "Frantic scrabbling.",
            },
            ["dead"] = {
                description = "A dead rat lies motionless.",
                room_presence = "A dead rat lies on the ground.",
                animate = false,
                portable = true,
            },
        },
        behavior = {
            default = "idle",
            aggression = 5,
            flee_threshold = 30,
            wander_chance = 40,
        },
        drives = {
            hunger = { value = 50, decay_rate = 2, max = 100, min = 0 },
            fear   = { value = 0,  decay_rate = -10, max = 100, min = 0 },
            curiosity = { value = 30, decay_rate = 1, max = 60, min = 0 },
        },
        reactions = {
            player_enters  = { action = "evaluate", fear_delta = 35 },
            player_attacks = { action = "flee", fear_delta = 80 },
            loud_noise     = { action = "flee", fear_delta = 25 },
            light_change   = { action = "evaluate", fear_delta = 15 },
        },
        movement = {
            speed = 1, can_open_doors = false, can_climb = true, size_limit = 1,
        },
        awareness = {
            sight_range = 1, sound_range = 2, smell_range = 3,
        },
        on_feel = "Coarse, greasy fur over a warm, squirming body.",
        on_smell = "Musty rodent — damp fur and old nesting material.",
        on_listen = "Skittering claws on stone.",
        description = "A plump brown rat with matted fur.",
        room_presence = "A rat crouches in the shadows near the wall.",
    }
    if overrides then
        for k, v in pairs(overrides) do c[k] = v end
    end
    return c
end

local function make_mock_room(id, overrides)
    local r = {
        guid = "{room-" .. id .. "}",
        id = id,
        name = "Test Room",
        template = "room",
        description = "A test room with stone walls.",
        exits = {},
        contents = {},
    }
    if overrides then
        for k, v in pairs(overrides) do r[k] = v end
    end
    return r
end

local function make_mock_player(overrides)
    local p = {
        location = "cellar",
        left_hand = nil,
        right_hand = nil,
        injuries = {},
        max_health = 100,
        health = 100,
        visited_rooms = {},
        worn = {},
    }
    if overrides then
        for k, v in pairs(overrides) do p[k] = v end
    end
    return p
end

local function make_mock_registry(objects)
    local reg = {
        _objects = objects or {},
    }
    function reg:list()
        return self._objects
    end
    function reg:get(id)
        for _, obj in ipairs(self._objects) do
            if obj.guid == id or obj.id == id then return obj end
        end
        return nil
    end
    function reg:find_by_keyword(keyword)
        local kw = keyword:lower()
        for _, obj in ipairs(self._objects) do
            if type(obj.keywords) == "table" then
                for _, k in ipairs(obj.keywords) do
                    if k:lower() == kw then return obj end
                end
            end
            if obj.name and obj.name:lower() == kw then return obj end
        end
        return nil
    end
    return reg
end

local function make_mock_context(opts)
    local room = opts.room or make_mock_room("cellar")
    local player = opts.player or make_mock_player()
    local objects = opts.objects or {}
    local registry = opts.registry or make_mock_registry(objects)
    local rooms = {}
    if opts.rooms then
        for _, r in ipairs(opts.rooms) do rooms[r.id] = r end
    else
        rooms[room.id] = room
    end
    local ctx = {
        registry = registry,
        rooms = rooms,
        current_room = room,
        player = player,
        verbs = opts.verbs or {},
        headless = true,
    }
    return ctx
end

---------------------------------------------------------------------------
-- Try to create the verb handlers table
---------------------------------------------------------------------------
local handlers = nil
if verbs_mod then
    local ok_create, h_result = pcall(verbs_mod.create)
    if ok_create then
        handlers = h_result
    else
        print("WARNING: verbs.create() failed: " .. tostring(h_result))
    end
end

---------------------------------------------------------------------------
-- TESTS: catch verb — keyword resolution
---------------------------------------------------------------------------
suite("CREATURE VERBS: catch resolves creature (WAVE-3)")

test("1. catch verb handler exists in verb registry", function()
    h.assert_truthy(handlers, "verb registry not loaded (TDD red phase)")
    h.assert_truthy(handlers["catch"],
        "catch verb handler must exist — TDD: Smithers adds it in WAVE-3")
end)

test("2. catch resolves creature by keyword 'rat'", function()
    h.assert_truthy(handlers and handlers["catch"],
        "catch handler not available (TDD red phase)")
    local rat = make_mock_creature()
    local room = make_mock_room("cellar", { contents = { rat.guid } })
    local player = make_mock_player()
    local ctx = make_mock_context({
        room = room,
        player = player,
        objects = { rat, room },
        verbs = handlers,
    })

    math.randomseed(42)
    local output = capture_call(handlers["catch"], ctx, "rat")

    h.assert_truthy(#output > 0,
        "catch rat should produce output (catch message or escape message)")
end)

---------------------------------------------------------------------------
-- TESTS: catch — hands full
---------------------------------------------------------------------------
suite("CREATURE VERBS: catch hands-full guard (WAVE-3)")

test("3. catch with both hands full prints 'hands full' error", function()
    h.assert_truthy(handlers and handlers["catch"],
        "catch handler not available (TDD red phase)")
    local rat = make_mock_creature()
    local sword = { guid = "{sword-1}", id = "sword", name = "a sword", keywords = {"sword"} }
    local shield = { guid = "{shield-1}", id = "shield", name = "a shield", keywords = {"shield"} }
    local room = make_mock_room("cellar", { contents = { rat.guid } })
    local player = make_mock_player({
        left_hand = sword,
        right_hand = shield,
    })
    local ctx = make_mock_context({
        room = room,
        player = player,
        objects = { rat, room, sword, shield },
        verbs = handlers,
    })

    local output = capture_call(handlers["catch"], ctx, "rat")

    h.assert_truthy(
        output_matches_any(output, {"hand", "full", "free", "holding"}),
        "catch with full hands must mention hands/full/free — got: "
        .. table.concat(output, " | "))
end)

---------------------------------------------------------------------------
-- TESTS: catch — non-creature
---------------------------------------------------------------------------
suite("CREATURE VERBS: catch on non-creature (WAVE-3)")

test("4. catch on a non-creature object produces appropriate error", function()
    h.assert_truthy(handlers and handlers["catch"],
        "catch handler not available (TDD red phase)")
    local barrel = {
        guid = "{barrel-1}",
        id = "barrel",
        name = "a barrel",
        keywords = {"barrel"},
        template = "container",
        animate = nil,
    }
    local room = make_mock_room("cellar", { contents = { barrel.guid } })
    local player = make_mock_player()
    local ctx = make_mock_context({
        room = room,
        player = player,
        objects = { barrel, room },
        verbs = handlers,
    })

    local output = capture_call(handlers["catch"], ctx, "barrel")

    h.assert_truthy(
        output_matches_any(output, {
            "can't catch", "cannot catch", "not a creature",
            "catch that", "grab that", "not something",
            "can't grab", "cannot grab", "don't see",
        }),
        "catch on non-creature must produce an error message — got: "
        .. table.concat(output, " | "))
end)

---------------------------------------------------------------------------
-- TESTS: catch — fear increase
---------------------------------------------------------------------------
suite("CREATURE VERBS: catch triggers fear (WAVE-3)")

test("5. catch attempt increases creature's fear drive", function()
    h.assert_truthy(handlers and handlers["catch"],
        "catch handler not available (TDD red phase)")
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")

    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 0
    local room = make_mock_room("cellar", { contents = { rat.guid } })
    local player = make_mock_player()
    local ctx = make_mock_context({
        room = room,
        player = player,
        objects = { rat, room },
        verbs = handlers,
    })

    local fear_before = rat.drives.fear.value
    math.randomseed(42)
    capture_call(handlers["catch"], ctx, "rat")

    -- Catch attempt should emit stimulus which increases fear,
    -- or the handler directly increases fear
    -- After catch, creature tick processes the stimulus
    if creatures and creatures.tick then
        creatures.tick(ctx)
    end

    h.assert_truthy(rat.drives.fear.value > fear_before,
        "catch must increase creature fear — before: " .. fear_before
        .. " after: " .. rat.drives.fear.value)
end)

---------------------------------------------------------------------------
-- TESTS: catch — bite injury
---------------------------------------------------------------------------
suite("CREATURE VERBS: catch triggers bite injury (WAVE-3)")

test("6. successful catch inflicts bite injury on player", function()
    h.assert_truthy(handlers and handlers["catch"],
        "catch handler not available (TDD red phase)")

    -- Use flee_threshold = 0 so success threshold is 20 — very likely to succeed
    local rat = make_mock_creature({
        location = "cellar",
        behavior = {
            default = "idle", aggression = 5,
            flee_threshold = 0, wander_chance = 40,
        },
    })
    local room = make_mock_room("cellar", { contents = { rat.guid } })
    local player = make_mock_player()
    local ctx = make_mock_context({
        room = room,
        player = player,
        objects = { rat, room },
        verbs = handlers,
    })

    -- Try multiple seeds to find one that succeeds (random > 20)
    local injury_found = false
    for seed = 42, 60 do
        player.injuries = {}
        math.randomseed(seed)
        local output = capture_call(handlers["catch"], ctx, "rat")

        if #player.injuries > 0 then
            injury_found = true
            break
        end
        -- Also check output for bite/injury keywords
        if output_matches_any(output, {"bite", "injur", "cut", "teeth", "nip"}) then
            injury_found = true
            break
        end
    end

    h.assert_truthy(injury_found,
        "successful catch must inflict bite injury on player (injuries.inflict call)")
end)

---------------------------------------------------------------------------
-- TESTS: catch — dead creature
---------------------------------------------------------------------------
suite("CREATURE VERBS: catch on dead creature (WAVE-3)")

test("7. catch on dead creature suggests 'take' instead", function()
    h.assert_truthy(handlers and handlers["catch"],
        "catch handler not available (TDD red phase)")

    local dead_rat = make_mock_creature({
        _state = "dead",
        alive = false,
        animate = false,
        portable = true,
    })
    local room = make_mock_room("cellar", { contents = { dead_rat.guid } })
    local player = make_mock_player()
    local ctx = make_mock_context({
        room = room,
        player = player,
        objects = { dead_rat, room },
        verbs = handlers,
    })

    local output = capture_call(handlers["catch"], ctx, "rat")

    h.assert_truthy(
        output_matches_any(output, {
            "take", "pick up", "dead", "already", "lifeless",
        }),
        "catch on dead creature should suggest 'take' — got: "
        .. table.concat(output, " | "))
end)

---------------------------------------------------------------------------
-- TESTS: creature room presence in look
---------------------------------------------------------------------------
suite("CREATURE VERBS: room presence in look (WAVE-3)")

test("8. creature presence appears in look output when light available", function()
    h.assert_truthy(handlers and handlers["look"],
        "look handler not available")

    local rat = make_mock_creature()
    local candle = {
        guid = "{candle-lit}", id = "candle", name = "a lit candle",
        keywords = {"candle"}, _state = "lit",
        states = { lit = { casts_light = true } },
        casts_light = true,
    }
    local room = make_mock_room("cellar", {
        name = "The Cellar",
        description = "A cold, damp cellar.",
        contents = { rat.guid, candle.guid },
    })
    local player = make_mock_player()
    local reg = make_mock_registry({ rat, candle, room })
    local ctx = make_mock_context({
        room = room,
        player = player,
        registry = reg,
        verbs = handlers,
    })
    ctx.verbs = handlers

    local output = capture_call(handlers["look"], ctx, "")

    h.assert_truthy(
        output_contains(output, "rat"),
        "look should show creature room_presence when light is available — got: "
        .. table.concat(output, " | "))
end)

---------------------------------------------------------------------------
-- TESTS: creature NOT visible in darkness
---------------------------------------------------------------------------
suite("CREATURE VERBS: darkness hides creatures (WAVE-3)")

test("9. creature NOT visible in look output in darkness", function()
    h.assert_truthy(handlers and handlers["look"],
        "look handler not available")

    local rat = make_mock_creature()
    -- Dark room — no light source
    local room = make_mock_room("cellar", {
        name = "The Cellar",
        description = "A cold, damp cellar.",
        contents = { rat.guid },
    })
    local player = make_mock_player()
    local reg = make_mock_registry({ rat, room })
    local ctx = make_mock_context({
        room = room,
        player = player,
        registry = reg,
        verbs = handlers,
    })

    local output = capture_call(handlers["look"], ctx, "")

    -- In darkness, look should NOT show creature presence text
    local found_presence = output_matches_any(output,
        {"crouches in the shadows", "scurries along"})

    -- The "dark" message should appear instead
    local found_dark = output_matches_any(output,
        {"dark", "can't see", "cannot see"})

    h.assert_truthy(not found_presence,
        "creature room_presence must NOT appear in darkness — got: "
        .. table.concat(output, " | "))
    h.assert_truthy(found_dark,
        "darkness message should appear in dark room")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
