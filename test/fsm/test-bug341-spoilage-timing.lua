-- test/fsm/test-bug341-spoilage-timing.lua
-- Bug #341: Corpse spoilage FSM advances through all states in 3 commands.
-- Root cause: timed_events delays (30, 40, 60 game-seconds) are smaller than
-- SECONDS_PER_TICK (360), so every timer expires on the very next command.
-- Fix: scale delays so spoilage takes multiple ticks.
-- TDD: Must FAIL before fix, PASS after.
-- Must be run from repository root: lua test/fsm/test-bug341-spoilage-timing.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

local fsm = require("engine.fsm")

---------------------------------------------------------------------------
-- Constants matching the game loop
---------------------------------------------------------------------------
local SECONDS_PER_TICK = 360

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[deep_copy(k)] = deep_copy(v) end
    return copy
end

local function make_mock_registry(objects)
    local reg = { _objects = {} }
    for _, obj in ipairs(objects) do
        reg._objects[obj.id or obj.guid] = obj
    end
    function reg:get(id) return self._objects[id] end
    function reg:register(id, obj) self._objects[id] = obj end
    function reg:list()
        local r = {}
        for _, obj in pairs(self._objects) do
            if type(obj) == "table" then r[#r + 1] = obj end
        end
        return r
    end
    return reg
end

-- Load the rat death_state from the actual creature file
local rat_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. "rat.lua"
local ok_rat, rat_def = pcall(dofile, rat_path)
if not ok_rat then
    print("WARNING: rat.lua not loadable — " .. tostring(rat_def))
    rat_def = nil
end

local function make_dead_rat()
    h.assert_truthy(rat_def and rat_def.death_state,
        "rat.lua must load with death_state")
    local ds = deep_copy(rat_def.death_state)
    local inst = {
        guid = "{dead-rat-341}",
        id = "dead-rat-341",
        template = "small-item",
        animate = false,
        name = ds.name,
        description = ds.description,
        on_feel = ds.on_feel,
        on_smell = ds.on_smell,
        states = ds.states,
        initial_state = ds.initial_state or "fresh",
        _state = ds.initial_state or "fresh",
        transitions = ds.transitions,
    }
    return inst
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("BUG #341: Corpse spoilage timing vs SECONDS_PER_TICK")

test("1. rat spoilage fresh delay must survive at least 1 tick", function()
    local rat = make_dead_rat()
    local fresh_state = rat.states.fresh
    h.assert_truthy(fresh_state, "fresh state must exist")
    h.assert_truthy(fresh_state.timed_events, "fresh state must have timed_events")
    local delay = fresh_state.timed_events[1].delay
    h.assert_truthy(delay > SECONDS_PER_TICK,
        "fresh delay (" .. delay .. ") must exceed SECONDS_PER_TICK (" ..
        SECONDS_PER_TICK .. ") so it survives at least 1 command")
end)

test("2. rat spoilage bloated delay must survive at least 1 tick", function()
    local rat = make_dead_rat()
    local bloated_state = rat.states.bloated
    h.assert_truthy(bloated_state and bloated_state.timed_events,
        "bloated state must have timed_events")
    local delay = bloated_state.timed_events[1].delay
    h.assert_truthy(delay > SECONDS_PER_TICK,
        "bloated delay (" .. delay .. ") must exceed SECONDS_PER_TICK (" ..
        SECONDS_PER_TICK .. ")")
end)

test("3. rat spoilage rotten delay must survive at least 1 tick", function()
    local rat = make_dead_rat()
    local rotten_state = rat.states.rotten
    h.assert_truthy(rotten_state and rotten_state.timed_events,
        "rotten state must have timed_events")
    local delay = rotten_state.timed_events[1].delay
    h.assert_truthy(delay > SECONDS_PER_TICK,
        "rotten delay (" .. delay .. ") must exceed SECONDS_PER_TICK (" ..
        SECONDS_PER_TICK .. ")")
end)

test("4. rat does NOT reach bones in 3 ticks via real FSM", function()
    local rat = make_dead_rat()
    local reg = make_mock_registry({ rat })

    -- Reset active timers
    fsm.active_timers = {}
    fsm.start_timer(reg, rat.id)

    -- Simulate 3 command ticks (the reported bug scenario)
    for _ = 1, 3 do
        fsm.tick_timers(reg, SECONDS_PER_TICK)
    end

    h.assert_truthy(rat._state ~= "bones",
        "rat must NOT reach bones in 3 ticks (state=" .. rat._state .. ")")
end)

test("5. rat stays fresh after 1 tick", function()
    local rat = make_dead_rat()
    local reg = make_mock_registry({ rat })

    fsm.active_timers = {}
    fsm.start_timer(reg, rat.id)

    fsm.tick_timers(reg, SECONDS_PER_TICK)

    h.assert_eq(rat._state, "fresh",
        "rat must remain fresh after 1 tick of " .. SECONDS_PER_TICK .. "s")
end)

test("6. spoilage progresses correctly over many ticks", function()
    local rat = make_dead_rat()
    local reg = make_mock_registry({ rat })

    fsm.active_timers = {}
    fsm.start_timer(reg, rat.id)

    -- Tick until fresh→bloated
    local ticks = 0
    while rat._state == "fresh" and ticks < 200 do
        fsm.tick_timers(reg, SECONDS_PER_TICK)
        ticks = ticks + 1
    end
    h.assert_eq(rat._state, "bloated", "rat should reach bloated (took " .. ticks .. " ticks)")
    h.assert_truthy(ticks > 1, "fresh→bloated must take more than 1 tick (took " .. ticks .. ")")

    -- Continue ticking until bloated→rotten
    local ticks2 = 0
    while rat._state == "bloated" and ticks2 < 200 do
        fsm.tick_timers(reg, SECONDS_PER_TICK)
        ticks2 = ticks2 + 1
    end
    h.assert_eq(rat._state, "rotten", "rat should reach rotten")
    h.assert_truthy(ticks2 > 1, "bloated→rotten must take more than 1 tick (took " .. ticks2 .. ")")

    -- Continue ticking until rotten→bones
    local ticks3 = 0
    while rat._state == "rotten" and ticks3 < 200 do
        fsm.tick_timers(reg, SECONDS_PER_TICK)
        ticks3 = ticks3 + 1
    end
    h.assert_eq(rat._state, "bones", "rat should reach bones")
    h.assert_truthy(ticks3 > 1, "rotten→bones must take more than 1 tick (took " .. ticks3 .. ")")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
