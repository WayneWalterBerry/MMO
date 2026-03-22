-- test/parser/test-goap-tier6.lua
-- Tier 6 — Generalized GOAP unit tests.
-- Tests property-based goal matching, multi-step backward chaining,
-- light requirement planning, key retrieval planning, and safety limits.
--
-- Usage: lua test/parser/test-goap-tier6.lua
-- Must be run from the repository root.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local goal_planner = require("engine.parser.goal_planner")

local test = h.test
local eq   = h.assert_eq

---------------------------------------------------------------------------
-- Mock registry: minimal object store
---------------------------------------------------------------------------
local function make_registry(objects)
    local store = {}
    for id, obj in pairs(objects or {}) do
        obj.id = obj.id or id
        store[id] = obj
    end
    return {
        get = function(self, id)
            return store[id]
        end,
        register = function(self, id, obj)
            store[id] = obj
        end,
        remove = function(self, id)
            store[id] = nil
        end,
        _store = store,
    }
end

---------------------------------------------------------------------------
-- Helper: build a minimal game context
-- opts.dark = true → nighttime, no light sources
-- opts.dark = false/nil → has a lit candle for light (or time-based)
---------------------------------------------------------------------------
local function make_ctx(opts)
    opts = opts or {}
    local reg = make_registry(opts.objects or {})
    local room = opts.room or { id = "test-room", contents = opts.room_contents or {} }
    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = opts.hands or { nil, nil },
            worn = {},
            state = opts.player_state or {},
            skills = {},
        },
        known_objects = {},
        verbs = opts.verbs or {},
        -- Presentation module needs game_start_time for light-level checks
        game_start_time = os.time(),
        time_offset = opts.time_offset or 0,
    }
    return ctx
end

---------------------------------------------------------------------------
-- Helper: capture print output
---------------------------------------------------------------------------
local function capture(fn, ...)
    local lines = {}
    local old = _G.print
    _G.print = function(msg) lines[#lines + 1] = tostring(msg) end
    fn(...)
    _G.print = old
    return table.concat(lines, "\n")
end

---------------------------------------------------------------------------
-- Helper: make a candle (FSM lightable object)
---------------------------------------------------------------------------
local function make_candle(state)
    state = state or "unlit"
    local c = {
        id = "candle",
        name = "a tallow candle",
        keywords = { "candle" },
        _state = state,
        states = {
            unlit = { casts_light = false },
            lit = { casts_light = true, light_radius = 2, provides_tool = "fire_source" },
            extinguished = { casts_light = false },
            spent = { terminal = true, casts_light = false },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light", requires_tool = "fire_source" },
            { from = "lit", to = "extinguished", verb = "extinguish" },
            { from = "extinguished", to = "lit", verb = "light", requires_tool = "fire_source" },
        },
    }
    -- Simulate FSM state merge: copy current state properties to top level
    local state_data = c.states[state]
    if state_data then
        for k, v in pairs(state_data) do c[k] = v end
    end
    return c
end

local function make_match(state, id)
    state = state or "unlit"
    local m = {
        id = id or "match-1",
        name = "a wooden match",
        keywords = { "match" },
        _state = state,
        states = {
            unlit = {},
            lit = { provides_tool = "fire_source", casts_light = true },
            spent = { terminal = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "strike" },
        },
    }
    -- Simulate FSM state merge
    local state_data = m.states[state]
    if state_data then
        for k, v in pairs(state_data) do m[k] = v end
    end
    return m
end

local function make_matchbox()
    return {
        id = "matchbox",
        name = "a matchbox",
        keywords = { "matchbox" },
        has_striker = true,
        container = true,
        accessible = true,
        contents = {},
    }
end

local function make_key(id, kw)
    return {
        id = id,
        name = "a " .. (kw or "brass") .. " key",
        keywords = { kw or "key", id },
    }
end

---------------------------------------------------------------------------
h.suite("Tier 6 — find_lightable: discovers lightable objects")
---------------------------------------------------------------------------

test("finds candle in room", function()
    local candle = make_candle("unlit")
    local ctx = make_ctx({
        objects = { candle = candle },
        room_contents = { "candle" },
    })
    local cands = goal_planner._find_lightable(ctx)
    eq(1, #cands, "should find one lightable candidate")
    eq("candle", cands[1].obj.id, "candidate should be the candle")
    eq("lit", cands[1].transition.to, "transition target should be lit")
end)

test("does not find already-lit candle", function()
    local candle = make_candle("lit")
    local ctx = make_ctx({
        objects = { candle = candle },
        room_contents = { "candle" },
    })
    local cands = goal_planner._find_lightable(ctx)
    eq(0, #cands, "lit candle should not appear as lightable")
end)

test("does not find spent candle", function()
    local candle = make_candle("spent")
    local ctx = make_ctx({
        objects = { candle = candle },
        room_contents = { "candle" },
    })
    local cands = goal_planner._find_lightable(ctx)
    eq(0, #cands, "spent candle should not appear as lightable")
end)

test("finds candle on surface", function()
    local candle = make_candle("unlit")
    local nightstand = {
        id = "nightstand", name = "nightstand", keywords = { "nightstand" },
        surfaces = {
            top = { accessible = true, contents = { "candle" } },
        },
    }
    local ctx = make_ctx({
        objects = { candle = candle, nightstand = nightstand },
        room_contents = { "nightstand" },
    })
    local cands = goal_planner._find_lightable(ctx)
    eq(1, #cands, "should find candle on surface")
    eq("surface", cands[1].entry.where, "entry should be from surface")
end)

test("finds candle in player hand", function()
    local candle = make_candle("unlit")
    local ctx = make_ctx({
        objects = { candle = candle },
        hands = { candle, nil },
    })
    local cands = goal_planner._find_lightable(ctx)
    eq(1, #cands, "should find candle in hand")
    eq("hand", cands[1].entry.where, "entry should be from hand")
end)

---------------------------------------------------------------------------
h.suite("Tier 6 — find_by_id: exact ID search across locations")
---------------------------------------------------------------------------

test("finds object by ID in room", function()
    local key = make_key("brass-key", "key")
    local ctx = make_ctx({
        objects = { ["brass-key"] = key },
        room_contents = { "brass-key" },
    })
    local entries = goal_planner._find_by_id(ctx, "brass-key")
    eq(1, #entries, "should find key in room")
    eq("room", entries[1].where, "entry should be from room")
end)

test("finds object in closed container", function()
    local key = make_key("iron-key", "key")
    local chest = {
        id = "chest", name = "a wooden chest", keywords = { "chest" },
        container = true, accessible = false,
        contents = { "iron-key" },
    }
    local ctx = make_ctx({
        objects = { ["iron-key"] = key, chest = chest },
        room_contents = { "chest" },
    })
    local entries = goal_planner._find_by_id(ctx, "iron-key")
    eq(1, #entries, "should find key inside chest")
    eq("container", entries[1].where, "entry should be from container")
    eq(false, entries[1].accessible, "container should be inaccessible")
end)

test("finds object in hand", function()
    local key = make_key("brass-key", "key")
    local ctx = make_ctx({
        objects = { ["brass-key"] = key },
        hands = { key, nil },
    })
    local entries = goal_planner._find_by_id(ctx, "brass-key")
    eq(1, #entries, "should find key in hand")
    eq("hand", entries[1].where, "should be in hand")
end)

test("finds object on inaccessible surface", function()
    local key = make_key("brass-key", "key")
    local cabinet = {
        id = "cabinet", name = "a wooden cabinet", keywords = { "cabinet" },
        surfaces = {
            inside = { accessible = false, contents = { "brass-key" } },
        },
    }
    local ctx = make_ctx({
        objects = { ["brass-key"] = key, cabinet = cabinet },
        room_contents = { "cabinet" },
    })
    local entries = goal_planner._find_by_id(ctx, "brass-key")
    eq(1, #entries, "should find key on surface")
    eq("surface", entries[1].where)
    eq(false, entries[1].surface_accessible, "surface should be inaccessible")
end)

test("returns empty for missing object", function()
    local ctx = make_ctx({ room_contents = {} })
    local entries = goal_planner._find_by_id(ctx, "nonexistent")
    eq(0, #entries, "should find nothing")
end)

---------------------------------------------------------------------------
h.suite("Tier 6 — plan_for_light: backward-chain light planning")
---------------------------------------------------------------------------

test("returns nil when no lightable object exists", function()
    local ctx = make_ctx({ room_contents = {} })
    local steps = goal_planner._plan_for_light(ctx)
    eq(nil, steps, "no way to get light → nil")
end)

test("plans fire_source + light candle when match+striker available", function()
    local candle = make_candle("unlit")
    local match = make_match("unlit", "match-1")
    local matchbox = make_matchbox()
    matchbox.contents = { "match-1" }
    local ctx = make_ctx({
        objects = {
            candle = candle,
            ["match-1"] = match,
            matchbox = matchbox,
        },
        room_contents = { "candle", "matchbox" },
    })
    local steps = goal_planner._plan_for_light(ctx)
    h.assert_truthy(steps, "should produce a plan")
    h.assert_truthy(#steps >= 2, "plan should have at least 2 steps")
    -- Last step should be lighting the candle
    eq("light", steps[#steps].verb, "last step should be light")
    eq("candle", steps[#steps].noun, "last step should target candle")
end)

test("returns nil when candle exists but no fire_source available", function()
    local candle = make_candle("unlit")
    local ctx = make_ctx({
        objects = { candle = candle },
        room_contents = { "candle" },
    })
    local steps = goal_planner._plan_for_light(ctx)
    eq(nil, steps, "no fire source → nil")
end)

test("plans for extinguished candle (relight)", function()
    local candle = make_candle("extinguished")
    local match = make_match("unlit", "match-1")
    local matchbox = make_matchbox()
    matchbox.contents = { "match-1" }
    local ctx = make_ctx({
        objects = {
            candle = candle,
            ["match-1"] = match,
            matchbox = matchbox,
        },
        room_contents = { "candle", "matchbox" },
    })
    local steps = goal_planner._plan_for_light(ctx)
    h.assert_truthy(steps, "should produce a plan for relighting")
    eq("light", steps[#steps].verb, "last step should relight candle")
end)

---------------------------------------------------------------------------
h.suite("Tier 6 — plan_for_key: key retrieval planning")
---------------------------------------------------------------------------

test("returns empty when key already in hand", function()
    local key = make_key("brass-key", "key")
    local ctx = make_ctx({
        objects = { ["brass-key"] = key },
        hands = { key, nil },
    })
    local steps = goal_planner._plan_for_key("brass-key", ctx)
    h.assert_truthy(steps, "should return a plan")
    eq(0, #steps, "already held → no steps needed")
end)

test("plans take when key is in room", function()
    local key = make_key("brass-key", "key")
    local ctx = make_ctx({
        objects = { ["brass-key"] = key },
        room_contents = { "brass-key" },
    })
    local steps = goal_planner._plan_for_key("brass-key", ctx)
    h.assert_truthy(steps, "should return a plan")
    eq(1, #steps, "should have 1 step")
    eq("take", steps[1].verb, "step should be take")
end)

test("plans open + take when key is in closed container", function()
    local key = make_key("iron-key", "key")
    local chest = {
        id = "chest", name = "a chest", keywords = { "chest" },
        container = true, accessible = false,
        contents = { "iron-key" },
    }
    local ctx = make_ctx({
        objects = { ["iron-key"] = key, chest = chest },
        room_contents = { "chest" },
    })
    local steps = goal_planner._plan_for_key("iron-key", ctx)
    h.assert_truthy(steps, "should return a plan")
    eq(2, #steps, "should have 2 steps (open + take)")
    eq("open", steps[1].verb, "first step: open container")
    eq("chest", steps[1].noun, "open the chest")
    eq("take", steps[2].verb, "second step: take key")
end)

test("plans open surface + take when key on inaccessible surface", function()
    local key = make_key("brass-key", "key")
    local cabinet = {
        id = "cabinet", name = "a cabinet", keywords = { "cabinet" },
        surfaces = {
            drawer = { accessible = false, contents = { "brass-key" } },
        },
    }
    local ctx = make_ctx({
        objects = { ["brass-key"] = key, cabinet = cabinet },
        room_contents = { "cabinet" },
    })
    local steps = goal_planner._plan_for_key("brass-key", ctx)
    h.assert_truthy(steps, "should return a plan")
    eq(2, #steps, "should have 2 steps (open + take)")
    eq("open", steps[1].verb, "first step: open cabinet")
    eq("take", steps[2].verb, "second step: take key")
end)

test("returns nil when key does not exist", function()
    local ctx = make_ctx({ room_contents = {} })
    local steps = goal_planner._plan_for_key("nonexistent-key", ctx)
    eq(nil, steps, "key not found → nil")
end)

---------------------------------------------------------------------------
h.suite("Tier 6 — plan() verb-level: read in dark")
---------------------------------------------------------------------------

test("plan returns light steps when reading in dark with candle+match available", function()
    local candle = make_candle("unlit")
    local match = make_match("unlit", "match-1")
    local matchbox = make_matchbox()
    matchbox.contents = { "match-1" }
    local book = {
        id = "book", name = "a leather book", keywords = { "book" },
        categories = { "readable" },
    }
    local ctx = make_ctx({
        objects = {
            candle = candle,
            ["match-1"] = match,
            matchbox = matchbox,
            book = book,
        },
        room_contents = { "candle", "matchbox", "book" },
    })
    -- Darkness: no casts_light, no daylight
    -- The presentation module checks light level; in our mock ctx there's no
    -- light source in the room, so has_some_light should return false.
    local steps = goal_planner.plan("read", "book", ctx)
    h.assert_truthy(steps, "should produce a plan for light")
    h.assert_truthy(#steps >= 2, "plan should have at least 2 steps")
    eq("light", steps[#steps].verb, "last step should light something")
end)

test("plan returns nil for read when room already has light", function()
    local candle = make_candle("lit")
    local book = {
        id = "book", name = "a leather book", keywords = { "book" },
        categories = { "readable" },
    }
    local ctx = make_ctx({
        objects = {
            candle = candle,
            book = book,
        },
        room_contents = { "candle", "book" },
    })
    local steps = goal_planner.plan("read", "book", ctx)
    eq(nil, steps, "room already lit → no planning needed")
end)

---------------------------------------------------------------------------
h.suite("Tier 6 — plan() verb-level: unlock with key retrieval")
---------------------------------------------------------------------------

test("plan returns key retrieval steps for locked exit", function()
    local key = make_key("brass-key", "key")
    local chest = {
        id = "chest", name = "a chest", keywords = { "chest" },
        container = true, accessible = false,
        contents = { "brass-key" },
    }
    local room = {
        id = "test-room",
        contents = { "chest" },
        exits = {
            north = {
                name = "cellar door",
                keywords = { "door", "cellar" },
                locked = true,
                key_id = "brass-key",
            },
        },
    }
    local ctx = make_ctx({
        objects = { ["brass-key"] = key, chest = chest },
        room = room,
    })
    local steps = goal_planner.plan("unlock", "door", ctx)
    h.assert_truthy(steps, "should produce a plan for key retrieval")
    eq(2, #steps, "should have 2 steps (open chest + take key)")
    eq("open", steps[1].verb, "first step: open chest")
    eq("take", steps[2].verb, "second step: take key")
end)

test("plan returns nil for unlock when key already held", function()
    local key = make_key("brass-key", "key")
    local room = {
        id = "test-room",
        contents = {},
        exits = {
            north = {
                name = "cellar door",
                keywords = { "door", "cellar" },
                locked = true,
                key_id = "brass-key",
            },
        },
    }
    local ctx = make_ctx({
        objects = { ["brass-key"] = key },
        hands = { key, nil },
        room = room,
    })
    local steps = goal_planner.plan("unlock", "door", ctx)
    eq(nil, steps, "key already held → no planning needed")
end)

test("plan returns nil for unlock when exit not locked", function()
    local room = {
        id = "test-room",
        contents = {},
        exits = {
            north = {
                name = "cellar door",
                keywords = { "door", "cellar" },
                locked = false,
            },
        },
    }
    local ctx = make_ctx({ room = room })
    local steps = goal_planner.plan("unlock", "door", ctx)
    eq(nil, steps, "not locked → no planning needed")
end)

test("plan returns nil for unlock when key not accessible anywhere", function()
    local room = {
        id = "test-room",
        contents = {},
        exits = {
            north = {
                name = "cellar door",
                keywords = { "door" },
                locked = true,
                key_id = "mystery-key",
            },
        },
    }
    local ctx = make_ctx({ room = room })
    local steps = goal_planner.plan("unlock", "door", ctx)
    eq(nil, steps, "key not found → nil")
end)

---------------------------------------------------------------------------
h.suite("Tier 6 — plan() object-level: fire_source still works (regression)")
---------------------------------------------------------------------------

test("plan for light candle with match in matchbox", function()
    local candle = make_candle("unlit")
    local match = make_match("unlit", "match-1")
    local matchbox = make_matchbox()
    matchbox.contents = { "match-1" }
    local ctx = make_ctx({
        objects = {
            candle = candle,
            ["match-1"] = match,
            matchbox = matchbox,
        },
        room_contents = { "candle", "matchbox" },
    })
    local steps = goal_planner.plan("light", "candle", ctx)
    h.assert_truthy(steps, "should produce fire_source plan")
    -- Should include take match + strike match on matchbox
    local has_take = false
    local has_strike = false
    for _, s in ipairs(steps) do
        if s.verb == "take" then has_take = true end
        if s.verb == "strike" then has_strike = true end
    end
    h.assert_truthy(has_take, "plan should include taking the match")
    h.assert_truthy(has_strike, "plan should include striking the match")
end)

test("plan returns nil when match already provides fire_source", function()
    local candle = make_candle("unlit")
    local match = make_match("lit", "match-1")
    match.provides_tool = "fire_source"
    local ctx = make_ctx({
        objects = {
            candle = candle,
            ["match-1"] = match,
        },
        room_contents = { "candle" },
        hands = { match, nil },
    })
    local steps = goal_planner.plan("light", "candle", ctx)
    -- Already have fire_source → empty plan or nil
    if steps then
        eq(0, #steps, "already have fire → no steps")
    end
end)

---------------------------------------------------------------------------
h.suite("Tier 6 — plan_for_tool: generic tool resolution")
---------------------------------------------------------------------------

test("generic tool: in room → already accessible, no steps needed", function()
    local knife = {
        id = "knife", name = "a sharp knife", keywords = { "knife" },
        provides_tool = "cutting_edge",
    }
    local ctx = make_ctx({
        objects = { knife = knife },
        room_contents = { "knife" },
    })
    local steps = goal_planner._plan_for_tool("cutting_edge", ctx)
    h.assert_truthy(steps, "should return a plan")
    -- Tool is in room — has_tool() sees room contents as accessible
    eq(0, #steps, "tool in room → verb handler finds it, no plan needed")
end)

test("generic tool: already held → empty plan", function()
    local knife = {
        id = "knife", name = "a sharp knife", keywords = { "knife" },
        provides_tool = "cutting_edge",
    }
    local ctx = make_ctx({
        objects = { knife = knife },
        hands = { knife, nil },
    })
    local steps = goal_planner._plan_for_tool("cutting_edge", ctx)
    h.assert_truthy(steps, "should return a plan")
    eq(0, #steps, "already held → no steps")
end)

test("generic tool: finds tool in closed container", function()
    local knife = {
        id = "knife", name = "a sharp knife", keywords = { "knife" },
        provides_tool = "cutting_edge",
    }
    local box = {
        id = "box", name = "a box", keywords = { "box" },
        container = true, accessible = false,
        contents = { "knife" },
    }
    local ctx = make_ctx({
        objects = { knife = knife, box = box },
        room_contents = { "box" },
    })
    local steps = goal_planner._plan_for_tool("cutting_edge", ctx)
    h.assert_truthy(steps, "should produce a plan")
    eq(2, #steps, "should have 2 steps (open + take)")
    eq("open", steps[1].verb, "first step: open box")
    eq("take", steps[2].verb, "second step: take knife")
end)

test("generic tool: finds tool on inaccessible surface", function()
    local knife = {
        id = "knife", name = "a sharp knife", keywords = { "knife" },
        provides_tool = "cutting_edge",
    }
    local cabinet = {
        id = "cabinet", name = "a cabinet", keywords = { "cabinet" },
        surfaces = {
            drawer = { accessible = false, contents = { "knife" } },
        },
    }
    local ctx = make_ctx({
        objects = { knife = knife, cabinet = cabinet },
        room_contents = { "cabinet" },
    })
    local steps = goal_planner._plan_for_tool("cutting_edge", ctx)
    h.assert_truthy(steps, "should produce a plan")
    eq(2, #steps, "should have 2 steps")
    eq("open", steps[1].verb, "first step: open cabinet")
    eq("take", steps[2].verb, "second step: take knife")
end)

test("generic tool: returns nil when tool not found", function()
    local ctx = make_ctx({ room_contents = {} })
    local steps = goal_planner._plan_for_tool("nonexistent_tool", ctx)
    eq(nil, steps, "tool not found → nil")
end)

---------------------------------------------------------------------------
h.suite("Tier 6 — Safety limits")
---------------------------------------------------------------------------

test("MAX_DEPTH is 7", function()
    eq(7, goal_planner._MAX_DEPTH, "safety limit should be 7")
end)

test("execute rejects plans exceeding MAX_PLAN_STEPS", function()
    local steps = {}
    for i = 1, 25 do
        steps[i] = { verb = "take", noun = "thing" .. i }
    end
    local ctx = make_ctx({ verbs = { take = function() end } })
    local output = capture(function()
        local ok = goal_planner.execute(steps, ctx)
        h.assert_eq(false, ok, "should return false for too-long plan")
    end)
    h.assert_truthy(output:find("too many steps") or output:find("limit"),
        "should mention step limit in message")
end)

test("execute succeeds for valid plan", function()
    local executed = {}
    local verbs = {
        take = function(ctx, noun) executed[#executed + 1] = "take:" .. noun end,
        open = function(ctx, noun) executed[#executed + 1] = "open:" .. noun end,
    }
    local steps = {
        { verb = "open", noun = "chest" },
        { verb = "take", noun = "key" },
    }
    local ctx = make_ctx({ verbs = verbs })
    local output = capture(function()
        local ok = goal_planner.execute(steps, ctx)
        h.assert_truthy(ok, "should succeed")
    end)
    eq(2, #executed, "should have executed 2 steps")
    eq("open:chest", executed[1], "first executed step")
    eq("take:key", executed[2], "second executed step")
    h.assert_truthy(output:find("prepare"), "should narrate preparation")
end)

test("execute handles empty plan gracefully", function()
    local ok = goal_planner.execute({}, make_ctx())
    h.assert_truthy(ok, "empty plan should succeed")
end)

---------------------------------------------------------------------------
h.suite("Tier 6 — Multi-step chains: read in dark with nested deps")
---------------------------------------------------------------------------

test("read book in dark: full chain (match → strike → light candle → read)", function()
    local candle = make_candle("unlit")
    local match = make_match("unlit", "match-1")
    local matchbox = make_matchbox()
    matchbox.contents = { "match-1" }
    local book = {
        id = "book", name = "a dusty tome", keywords = { "book", "tome" },
        categories = { "readable" },
    }
    local ctx = make_ctx({
        objects = {
            candle = candle,
            ["match-1"] = match,
            matchbox = matchbox,
            book = book,
        },
        room_contents = { "candle", "matchbox", "book" },
    })
    local steps = goal_planner.plan("read", "book", ctx)
    h.assert_truthy(steps, "should produce full chain")
    -- Verify the chain ends with lighting the candle
    eq("light", steps[#steps].verb, "final step should light the candle")
    eq("candle", steps[#steps].noun, "should light the candle specifically")
    -- Verify chain includes match handling
    local has_strike = false
    for _, s in ipairs(steps) do
        if s.verb == "strike" then has_strike = true end
    end
    h.assert_truthy(has_strike, "chain should include striking match")
    -- Verify total depth is reasonable
    h.assert_truthy(#steps <= 7, "chain should be within safety limit (got " .. #steps .. ")")
end)

---------------------------------------------------------------------------
h.suite("Tier 6 — Unlock door: full chain with key in container")
---------------------------------------------------------------------------

test("unlock door: finds key in room chest", function()
    local key = make_key("brass-key", "key")
    local chest = {
        id = "chest", name = "a wooden chest", keywords = { "chest" },
        container = true, accessible = false,
        contents = { "brass-key" },
    }
    local room = {
        id = "test-room",
        contents = { "chest" },
        exits = {
            north = {
                name = "heavy oak door",
                keywords = { "door", "oak door" },
                locked = true,
                key_id = "brass-key",
            },
        },
    }
    local ctx = make_ctx({
        objects = { ["brass-key"] = key, chest = chest },
        room = room,
    })
    local steps = goal_planner.plan("unlock", "door", ctx)
    h.assert_truthy(steps, "should produce a plan")
    -- open chest + take key
    eq("open", steps[1].verb, "first step: open chest")
    eq("take", steps[2].verb, "second step: take key")
    h.assert_truthy(#steps <= 7, "within safety limit")
end)

test("unlock by direction keyword matches exit", function()
    local key = make_key("brass-key", "key")
    local room = {
        id = "test-room",
        contents = { "brass-key" },
        exits = {
            north = {
                name = "cellar door",
                keywords = { "door" },
                locked = true,
                key_id = "brass-key",
            },
        },
    }
    local ctx = make_ctx({
        objects = { ["brass-key"] = key },
        room = room,
    })
    -- "unlock north" should match the exit
    local steps = goal_planner.plan("unlock", "north", ctx)
    h.assert_truthy(steps, "should match exit by direction")
    eq("take", steps[1].verb, "should plan to take key from room")
end)

---------------------------------------------------------------------------
h.suite("Tier 6 — Edge cases")
---------------------------------------------------------------------------

test("plan returns nil for unknown verb", function()
    local ctx = make_ctx({ room_contents = {} })
    local steps = goal_planner.plan("frobnicate", "widget", ctx)
    eq(nil, steps, "unknown verb → nil")
end)

test("plan returns nil for empty noun", function()
    local ctx = make_ctx({})
    local steps = goal_planner.plan("read", "", ctx)
    eq(nil, steps, "empty noun → nil")
end)

test("plan returns nil for nil context", function()
    local steps = goal_planner.plan("read", "book", nil)
    eq(nil, steps, "nil context → nil")
end)

test("write verb also triggers light requirement", function()
    local candle = make_candle("unlit")
    local match = make_match("unlit", "match-1")
    local matchbox = make_matchbox()
    matchbox.contents = { "match-1" }
    local ctx = make_ctx({
        objects = {
            candle = candle,
            ["match-1"] = match,
            matchbox = matchbox,
        },
        room_contents = { "candle", "matchbox" },
    })
    local steps = goal_planner.plan("write", "hello on paper", ctx)
    -- write needs light just like read
    h.assert_truthy(steps, "write should trigger light planning in dark")
    eq("light", steps[#steps].verb, "should plan to light candle")
end)

test("key in nested container (container on surface)", function()
    local key = make_key("silver-key", "key")
    local box = {
        id = "box", name = "a small box", keywords = { "box" },
        container = true, accessible = false,
        contents = { "silver-key" },
    }
    local table_obj = {
        id = "table", name = "a table", keywords = { "table" },
        surfaces = {
            top = { accessible = true, contents = { "box" } },
        },
    }
    local room = {
        id = "test-room",
        contents = { "table" },
        exits = {
            east = {
                name = "iron gate",
                keywords = { "gate" },
                locked = true,
                key_id = "silver-key",
            },
        },
    }
    local ctx = make_ctx({
        objects = { ["silver-key"] = key, box = box, table = table_obj },
        room = room,
    })
    local steps = goal_planner.plan("unlock", "gate", ctx)
    h.assert_truthy(steps, "should find key in nested container")
    -- Should include opening the box and taking the key
    local has_open = false
    local has_take = false
    for _, s in ipairs(steps) do
        if s.verb == "open" then has_open = true end
        if s.verb == "take" then has_take = true end
    end
    h.assert_truthy(has_open, "should plan to open the box")
    h.assert_truthy(has_take, "should plan to take the key")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("\n=== Tier 6 GOAP tests complete ===")
os.exit(h.summary())
