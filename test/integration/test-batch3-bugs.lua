-- test/integration/test-batch3-bugs.lua
-- TDD tests for gameplay bugs batch 3: Issues #230-#240
-- Written by Smithers (UI Engineer) — covers parser, verb, and object fixes.
--
-- Usage: lua test/integration/test-batch3-bugs.lua
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

local test   = h.test
local suite  = h.suite
local eq     = h.assert_eq

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
    local room = opts.room or {
        id = "test-room",
        name = "Test Room",
        description = "A plain test room.",
        contents = opts.room_contents or {},
        exits = opts.exits or {},
    }
    local player = {
        hands = opts.hands or { nil, nil },
        worn = {},
        worn_items = {},
        injuries = {},
        bags = {},
        state = opts.state or {},
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
    }
end

-- Create a lit context (candle in hand provides light)
local function make_lit_ctx(opts)
    opts = opts or {}
    local candle = {
        id = "candle",
        name = "a lit tallow candle",
        keywords = {"candle"},
        _state = "lit",
        casts_light = true,
        states = {
            lit = { casts_light = true },
            unlit = { casts_light = false },
        },
    }
    local reg = registry_mod.new()
    reg:register("candle", candle)
    local room = opts.room or {
        id = "test-room",
        name = "Test Room",
        description = "A plain test room.",
        contents = opts.room_contents or {},
        exits = opts.exits or {},
    }
    local player = {
        hands = opts.hands or { candle, nil },
        worn = {},
        worn_items = {},
        injuries = {},
        bags = {},
        state = opts.state or { has_flame = 1 },
    }
    -- Register any additional objects
    if opts.objects then
        for id, obj in pairs(opts.objects) do
            reg:register(id, obj)
        end
    end
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
    }
end

---------------------------------------------------------------------------
-- #230: 'feel around' says 'in the darkness' when room is lit
---------------------------------------------------------------------------
suite("#230 — feel around in lit room")

test("#230: feel around in lit room should NOT say 'in the darkness'", function()
    local nightstand = {
        id = "nightstand",
        name = "a nightstand",
        keywords = {"nightstand"},
    }
    local ctx = make_lit_ctx({
        room_contents = { "nightstand" },
        objects = { nightstand = nightstand },
    })
    ctx.current_verb = "feel"
    local output = capture_output(function()
        handlers["feel"](ctx, "around")
    end)
    h.assert_truthy(not output:find("darkness", 1, true),
        "#230: feel around in lit room says 'darkness'; got: " .. output)
    h.assert_truthy(output:find("nightstand", 1, true),
        "#230: feel around should still list objects; got: " .. output)
end)

test("#230: feel around in dark room SHOULD say darkness", function()
    local nightstand = {
        id = "nightstand",
        name = "a nightstand",
        keywords = {"nightstand"},
    }
    local ctx = make_ctx({
        room_contents = { "nightstand" },
        current_verb = "feel",
    })
    ctx.registry:register("nightstand", nightstand)
    local output = capture_output(function()
        handlers["feel"](ctx, "around")
    end)
    h.assert_truthy(output:find("darkness", 1, true),
        "#230: feel around in dark room should say darkness; got: " .. output)
end)

---------------------------------------------------------------------------
-- #231: Missing article in 'You don't have needle' error
---------------------------------------------------------------------------
suite("#231 — missing article in error messages")

test("#231: 'stab self with needle' error includes article", function()
    local ctx = make_ctx({ current_verb = "stab" })
    local output = capture_output(function()
        handlers["stab"](ctx, "self with needle")
    end)
    -- Should say "You don't have a needle" not "You don't have needle"
    h.assert_truthy(output:find("don't have a needle", 1, true)
        or output:find("don't have the needle", 1, true),
        "#231: error should include article; got: " .. output)
end)

test("#231: 'prick self with pin' error includes article", function()
    local ctx = make_ctx({ current_verb = "prick" })
    local output = capture_output(function()
        handlers["prick"](ctx, "self with pin")
    end)
    h.assert_truthy(output:find("don't have a pin", 1, true)
        or output:find("don't have the pin", 1, true),
        "#231: prick error should include article; got: " .. output)
end)

---------------------------------------------------------------------------
-- #232: 'stab door' says 'You can only stab yourself'
---------------------------------------------------------------------------
suite("#232 — stab should allow stabbing objects")

test("#232: 'stab door' should NOT say 'only stab yourself'", function()
    local door = {
        id = "door",
        name = "a heavy oak door",
        keywords = {"door", "oak door"},
    }
    local knife = {
        id = "knife",
        name = "a small knife",
        keywords = {"knife"},
        provides_tool = {"cutting_edge", "injury_source"},
        on_stab = { damage = 5, injury_type = "bleeding",
                    description = "You stab the knife into your %s." },
    }
    local ctx = make_ctx({
        room_contents = { "door" },
        hands = { knife, nil },
        current_verb = "stab",
    })
    ctx.registry:register("door", door)
    ctx.registry:register("knife", knife)
    local output = capture_output(function()
        handlers["stab"](ctx, "door")
    end)
    h.assert_truthy(not output:find("can only stab yourself", 1, true),
        "#232: should not say 'can only stab yourself'; got: " .. output)
end)

---------------------------------------------------------------------------
-- #233: Crowbar phantom — crate references non-existent crowbar
---------------------------------------------------------------------------
suite("#233 — phantom crowbar in crate")

test("#233: large-crate should not reference 'crowbar' in auto_steps", function()
    local ok, crate = pcall(dofile, "src/meta/objects/large-crate.lua")
    h.assert_truthy(ok, "#233: large-crate.lua should load")
    local auto = crate.prerequisites and crate.prerequisites.open
                 and crate.prerequisites.open.auto_steps
    if auto then
        for _, step in ipairs(auto) do
            h.assert_truthy(not step:find("crowbar", 1, true),
                "#233: auto_steps should not reference crowbar; found: " .. step)
        end
    end
end)

test("#233: large-crate transition message should not mention crowbar specifically", function()
    local ok, crate = pcall(dofile, "src/meta/objects/large-crate.lua")
    h.assert_truthy(ok, "#233: large-crate.lua should load")
    for _, trans in ipairs(crate.transitions or {}) do
        if trans.verb == "pry" or (trans.aliases and trans.aliases[1] == "open") then
            -- Message should describe prying generically, not mention "crowbar"
            if trans.message then
                h.assert_truthy(not trans.message:find("crowbar", 1, true),
                    "#233: transition message should not say 'crowbar'; got: " .. trans.message)
            end
        end
    end
end)

---------------------------------------------------------------------------
-- #234: Chamber pot wearable easter egg
---------------------------------------------------------------------------
suite("#234 — chamber pot wearable as easter egg")

test("#234: chamber pot should have wear properties", function()
    local ok, pot = pcall(dofile, "src/meta/objects/chamber-pot.lua")
    h.assert_truthy(ok, "#234: chamber-pot.lua should load")
    h.assert_truthy(pot.wear, "#234: chamber pot should have wear table")
    eq("head", pot.wear.slot, "#234: chamber pot wear slot should be head")
end)

test("#234: chamber pot should have funny on_wear event_output", function()
    local ok, pot = pcall(dofile, "src/meta/objects/chamber-pot.lua")
    h.assert_truthy(ok, "#234: chamber-pot.lua should load")
    h.assert_truthy(pot.event_output and pot.event_output.on_wear,
        "#234: chamber pot needs on_wear event_output")
    -- The message should be humorous
    local msg = pot.event_output.on_wear
    h.assert_truthy(#msg > 20,
        "#234: on_wear message should be a substantial humorous message; got: " .. msg)
end)

---------------------------------------------------------------------------
-- #235: 'dump out grain' fails — strip 'out' particle
---------------------------------------------------------------------------
suite("#235 — dump out grain")

test("#235: 'dump out grain' should find grain sack", function()
    local sack = {
        id = "grain-sack",
        name = "a heavy sack of grain",
        keywords = {"sack", "grain sack", "grain", "burlap sack"},
        container = true,
        contents = {"iron-key-1"},
        _state = "untied",
    }
    local key = {
        id = "iron-key-1",
        name = "an iron key",
        keywords = {"key"},
    }
    local ctx = make_ctx({
        room_contents = { "grain-sack" },
        current_verb = "dump",
    })
    ctx.registry:register("grain-sack", sack)
    ctx.registry:register("iron-key-1", key)
    ctx.player.hands[1] = sack
    local output = capture_output(function()
        handlers["dump"](ctx, "out grain")
    end)
    h.assert_truthy(output:find("dump", 1, true) or output:find("iron key", 1, true)
        or output:find("out of", 1, true),
        "#235: 'dump out grain' should succeed; got: " .. output)
    h.assert_truthy(not output:find("notice anything", 1, true)
        and not output:find("don't see", 1, true),
        "#235: should not say 'not found'; got: " .. output)
end)

---------------------------------------------------------------------------
-- #236: 'open locked door' in darkness — exits findable for physical verbs
---------------------------------------------------------------------------
suite("#236 — open exit in darkness")

test("#236: open door should find exit even in darkness", function()
    local ctx = make_ctx({
        exits = {
            north = {
                target = "hallway",
                type = "door",
                name = "a heavy oak door",
                keywords = {"door", "oak door"},
                open = false,
                locked = true,
            },
        },
        current_verb = "open",
    })
    local output = capture_output(function()
        handlers["open"](ctx, "door")
    end)
    -- Should at least attempt to interact with the exit (even if locked)
    h.assert_truthy(output:find("locked", 1, true)
        or output:find("open", 1, true)
        or output:find("can't", 1, true),
        "#236: should find exit in darkness; got: " .. output)
    h.assert_truthy(not output:find("notice anything", 1, true),
        "#236: should not say 'not found'; got: " .. output)
end)

---------------------------------------------------------------------------
-- #237: 'put X' returns verb=don instead of verb=put
---------------------------------------------------------------------------
suite("#237 — put verb in embedding index")

test("#237: embedding index should have 'put candle' with verb='put'", function()
    local f = io.open("src/assets/parser/embedding-index.json", "r")
    h.assert_truthy(f, "#237: embedding-index.json should exist")
    local content = f:read("*a")
    f:close()
    -- Check for "put" verb phrases (not just "set" which map to put)
    h.assert_truthy(content:find('"put a', 1, true) or content:find('"place a', 1, true),
        "#237: embedding index should have 'put/place X' phrases with verb='put'")
    -- Verify they map to verb=put not verb=don
    local found_put = content:find('"put a.-"verb":"put"') or content:find('"place.-"verb":"put"')
    h.assert_truthy(found_put,
        "#237: 'put X' phrases should have verb='put', not verb='don'")
end)

---------------------------------------------------------------------------
-- #238: 'break mirror' matches vanity-mirror-broken, no base phrase
---------------------------------------------------------------------------
suite("#238 — break mirror in embedding index")

test("#238: embedding index should have 'break mirror' phrase for base mirror", function()
    local f = io.open("src/assets/parser/embedding-index.json", "r")
    h.assert_truthy(f, "#238: embedding-index.json should exist")
    local content = f:read("*a")
    f:close()
    -- Should have a phrase like "break mirror" with noun="mirror" (not "vanity-mirror-broken")
    h.assert_truthy(content:find('"break.-mirror"') or content:find('"break a.-mirror"'),
        "#238: embedding index should have 'break mirror' phrase")
    -- And it should NOT map to the broken variant
    -- Find the specific entry and check noun
    local found_base = content:find('"break.-mirror.-"noun":"mirror"')
        or content:find('"break.-mirror.-"noun": "mirror"')
        or content:find('"noun":"mirror"')
    h.assert_truthy(found_base,
        "#238: 'break mirror' should map to noun='mirror', not 'vanity-mirror-broken'")
end)

---------------------------------------------------------------------------
-- #239: 'hear curtains' tagged as curtains-open in index
---------------------------------------------------------------------------
suite("#239 — hear curtains tagging")

test("#239: 'hear curtains' should map to noun='curtains' not 'curtains-open'", function()
    local f = io.open("src/assets/parser/embedding-index.json", "r")
    h.assert_truthy(f, "#239: embedding-index.json should exist")
    local content = f:read("*a")
    f:close()
    -- Find the exact "hear curtains" entry (not "hear heavy velvet curtains")
    -- Pattern: "hear curtains","verb":"hear","noun":"X"
    local noun = content:match('"hear curtains","verb":"hear","noun":"([^"]+)"')
    h.assert_truthy(noun, "#239: should have 'hear curtains' entry")
    eq("curtains", noun,
        "#239: 'hear curtains' should map to noun='curtains', got: " .. tostring(noun))
end)

---------------------------------------------------------------------------
-- #240: 'burn curtain' with lit match says can't burn
---------------------------------------------------------------------------
suite("#240 — burn velvet curtains")

test("#240: curtains.lua should have burn FSM transitions", function()
    local ok, curtains = pcall(dofile, "src/meta/objects/curtains.lua")
    h.assert_truthy(ok, "#240: curtains.lua should load")
    h.assert_truthy(curtains.states and curtains.states.burning,
        "#240: curtains should have 'burning' state")
    local has_burn_trans = false
    for _, t in ipairs(curtains.transitions or {}) do
        if t.verb == "burn" then has_burn_trans = true; break end
    end
    h.assert_truthy(has_burn_trans,
        "#240: curtains should have burn transition")
end)

test("#240: burn curtains with flame should succeed (velvet is flammable)", function()
    local curtains = {
        id = "curtains",
        name = "heavy velvet curtains",
        keywords = {"curtains", "curtain", "drapes", "velvet"},
        material = "velvet",
        initial_state = "closed",
        _state = "closed",
        states = {
            closed = { description = "Heavy curtains..." },
            open = { description = "Curtains pulled aside." },
            burning = { description = "The curtains are on fire!" },
        },
        transitions = {
            { from = "closed", to = "open", verb = "open" },
            { from = "open", to = "closed", verb = "close" },
            { from = "closed", to = "burning", verb = "burn",
              message = "You hold the flame to the heavy velvet. The dusty fabric catches immediately — fire races up the curtains." },
            { from = "open", to = "burning", verb = "burn",
              message = "You hold the flame to the bunched velvet. The dusty fabric catches immediately." },
        },
        mutations = {
            tear = { becomes = nil, spawns = {"cloth", "cloth", "rag"} },
        },
    }
    local ctx = make_lit_ctx({
        room_contents = { "curtains" },
        objects = { curtains = curtains },
        current_verb = "burn",
    })
    ctx.current_verb = "burn"
    local output = capture_output(function()
        handlers["burn"](ctx, "curtains")
    end)
    h.assert_truthy(not output:find("can't burn", 1, true),
        "#240: should not say 'can't burn'; got: " .. output)
    h.assert_truthy(output:find("fire") or output:find("catches") or output:find("burn"),
        "#240: should describe curtains catching fire; got: " .. output)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
h.summary()
