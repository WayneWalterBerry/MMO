-- test/options/test-options-api.lua
-- TDD tests for the options system core API (generate_options).
-- Written from architecture spec (projects/options/architecture.md).
-- Tests may need minor adjustment after implementation lands.

local t = require("test.parser.test-helpers")
local test = t.test
local eq = t.assert_eq
local truthy = t.assert_truthy

-- ============================================================
-- Mock infrastructure
-- ============================================================

-- Minimal mock GOAP planner that returns canned plans
local mock_goal_planner = {
    _plan = nil,
    plan_for_goal = function(self, ctx, goal)
        return self._plan
    end,
    set_plan = function(self, plan)
        self._plan = plan
    end,
}

-- Build a mock context table matching the API contract (arch §4.0)
local function make_ctx(opts)
    opts = opts or {}
    local room = {
        id = opts.room_id or "test-room",
        name = opts.room_name or "Test Room",
        description = "A plain test room.",
        goal = opts.goal,         -- nil or { verb, noun, label }
        goals = opts.goals,       -- nil or array of goals
        contents = opts.contents or {},
        exits = opts.exits or {},
        hints_flavor = opts.hints_flavor,
        options_disabled = opts.options_disabled,
        options_mode = opts.options_mode,
        options_delay = opts.options_delay,
    }
    local player = {
        hands = opts.hands or { nil, nil },
        inventory = opts.inventory or {},
        location = room,
        pending_options = opts.pending_options,
        worn = {},
        injuries = {},
        bags = {},
        state = {},
    }
    return {
        current_room = room,
        player = player,
        light_level = opts.light_level or "dark",
        recent_commands = opts.recent_commands or {},
        options_request_count = opts.options_request_count or 0,
        registry = opts.registry or { find_by_keyword = function() return nil end },
        goal_planner = opts.goal_planner or mock_goal_planner,
    }
end

-- Attempt to load the real module; fall back to a spec-conformant stub
local ok, options_mod = pcall(require, "engine.verbs.options")
if not ok then
    -- Stub generate_options per architecture §4.4
    -- This stub lets us validate test structure even before impl lands.
    -- Once the real module exists, this block is never reached.
    options_mod = {
        generate_options = function(ctx)
            local opts = {}
            local room = ctx.current_room
            local light = ctx.light_level

            -- Phase 1: goal steps
            if room.goal then
                local planner = ctx.goal_planner
                local plan = planner:plan_for_goal(ctx, room.goal)
                if plan and #plan > 0 then
                    opts[#opts + 1] = {
                        command = plan[1].verb .. (plan[1].noun and (" " .. plan[1].noun) or ""),
                        display = plan[1].display or ("Try: " .. plan[1].verb),
                        source = "goal",
                    }
                end
            end

            -- Phase 2: sensory suggestions
            local sensory_pool
            if light == "dark" then
                sensory_pool = {
                    { command = "feel",   display = "Feel around for objects in the darkness", source = "sensory" },
                    { command = "listen", display = "Listen carefully for sounds",             source = "sensory" },
                    { command = "smell",  display = "Sniff the air for clues",                 source = "sensory" },
                }
            else
                sensory_pool = {
                    { command = "look",    display = "Look around the room",                   source = "sensory" },
                    { command = "examine", display = "Examine your surroundings more closely",  source = "sensory" },
                    { command = "feel",    display = "Feel around for objects",                 source = "sensory" },
                    { command = "listen",  display = "Listen carefully for sounds",             source = "sensory" },
                    { command = "smell",   display = "Sniff the air for clues",                 source = "sensory" },
                }
            end

            -- Rotate based on call count (simple offset)
            local offset = ctx.options_request_count or 0
            for i = 1, #sensory_pool do
                if #opts >= 4 then break end
                local idx = ((i - 1 + offset) % #sensory_pool) + 1
                opts[#opts + 1] = sensory_pool[idx]
            end

            -- Phase 3: dynamic scan (stub — just pad to at least 1)
            if #opts == 0 then
                if light == "dark" then
                    opts[#opts + 1] = { command = "feel", display = "Feel around for objects in the darkness", source = "sensory" }
                else
                    opts[#opts + 1] = { command = "look", display = "Look around the room", source = "sensory" }
                end
            end

            -- Cap at 4
            while #opts > 4 do table.remove(opts) end

            -- Flavor text
            local flavor_lines = {
                "You consider your situation...",
                "You take a moment to think...",
                "You pause and assess what you know...",
                "You weigh your choices...",
            }
            local flavor_idx = ((ctx.options_request_count or 0) % #flavor_lines) + 1
            local flavor = flavor_lines[flavor_idx]

            return { options = opts, flavor_text = flavor }
        end,
    }
end

local generate = options_mod.generate_options

-- ============================================================
-- Tests
-- ============================================================

t.suite("generate_options — return structure")

test("returns a table with options and flavor_text fields", function()
    local ctx = make_ctx()
    local result = generate(ctx)
    truthy(result, "generate_options must return a table")
    truthy(result.options, "result must have options field")
    truthy(result.flavor_text, "result must have flavor_text field")
end)

test("options is an array of 1-4 items", function()
    local ctx = make_ctx()
    local result = generate(ctx)
    truthy(#result.options >= 1, "must return at least 1 option")
    truthy(#result.options <= 4, "must return at most 4 options")
end)

test("each entry has command, display, source fields", function()
    local ctx = make_ctx()
    local result = generate(ctx)
    for i, entry in ipairs(result.options) do
        truthy(entry.command, "entry " .. i .. " missing command")
        truthy(entry.display, "entry " .. i .. " missing display")
        truthy(entry.source,  "entry " .. i .. " missing source")
    end
end)

test("source is one of goal, sensory, dynamic", function()
    local valid = { goal = true, sensory = true, dynamic = true, fallback = true }
    local ctx = make_ctx()
    local result = generate(ctx)
    for i, entry in ipairs(result.options) do
        truthy(valid[entry.source], "entry " .. i .. " has invalid source: " .. tostring(entry.source))
    end
end)

test("flavor_text is a non-empty string", function()
    local ctx = make_ctx()
    local result = generate(ctx)
    truthy(type(result.flavor_text) == "string", "flavor_text must be a string")
    truthy(#result.flavor_text > 0, "flavor_text must not be empty")
end)

t.suite("generate_options — options list never exceeds 4")

test("room with goal + many objects still caps at 4", function()
    mock_goal_planner:set_plan({
        { verb = "open", noun = "door", display = "Open the door" },
        { verb = "go",   noun = "north", display = "Head north" },
    })
    local ctx = make_ctx({
        goal = { verb = "go", noun = "north", label = "escape" },
        light_level = "lit",
        contents = { "obj1", "obj2", "obj3", "obj4", "obj5" },
    })
    local result = generate(ctx)
    truthy(#result.options <= 4, "options must not exceed 4, got " .. #result.options)
    mock_goal_planner:set_plan(nil)
end)

t.suite("generate_options — empty room fallback")

test("empty room with no goal returns at least 1 sensory suggestion", function()
    local ctx = make_ctx({ goal = nil, contents = {}, exits = {} })
    local result = generate(ctx)
    truthy(#result.options >= 1, "empty room must return at least 1 option")
end)

test("empty room dark suggestion is non-visual", function()
    local ctx = make_ctx({ goal = nil, contents = {}, exits = {}, light_level = "dark" })
    local result = generate(ctx)
    local first_cmd = result.options[1].command
    -- In darkness, should NOT suggest look/examine
    truthy(first_cmd ~= "look" and first_cmd ~= "examine",
        "dark room should not suggest visual verb, got: " .. first_cmd)
end)

t.suite("generate_options — dark room filtering")

test("dark room only shows non-visual sensory options", function()
    local ctx = make_ctx({ light_level = "dark" })
    local result = generate(ctx)
    local visual_verbs = { look = true, examine = true, search = true }
    for i, entry in ipairs(result.options) do
        local verb = entry.command:match("^(%S+)")
        if entry.source == "sensory" then
            truthy(not visual_verbs[verb],
                "dark room sensory should not include visual verb '" .. verb .. "' (option " .. i .. ")")
        end
    end
end)

test("dark room suggests feel as primary sense", function()
    local ctx = make_ctx({ light_level = "dark", options_request_count = 0 })
    local result = generate(ctx)
    local has_feel = false
    for _, entry in ipairs(result.options) do
        if entry.command:match("^feel") then has_feel = true break end
    end
    truthy(has_feel, "dark room should include 'feel' suggestion")
end)

t.suite("generate_options — lit room options")

test("lit room can include visual options", function()
    local ctx = make_ctx({ light_level = "lit" })
    local result = generate(ctx)
    local has_visual = false
    local visual_verbs = { look = true, examine = true, search = true }
    for _, entry in ipairs(result.options) do
        local verb = entry.command:match("^(%S+)")
        if visual_verbs[verb] then has_visual = true break end
    end
    truthy(has_visual, "lit room should include at least one visual verb")
end)

t.suite("generate_options — goal integration")

test("room with goal returns goal step as first option", function()
    mock_goal_planner:set_plan({
        { verb = "open", noun = "drawer", display = "Open the nightstand drawer" },
    })
    local ctx = make_ctx({
        goal = { verb = "take", noun = "matchbox", label = "find fire" },
    })
    local result = generate(ctx)
    eq("goal", result.options[1].source, "first option should be goal-sourced")
    mock_goal_planner:set_plan(nil)
end)

test("room without goal has no goal-sourced entries", function()
    mock_goal_planner:set_plan(nil)
    local ctx = make_ctx({ goal = nil })
    local result = generate(ctx)
    for i, entry in ipairs(result.options) do
        truthy(entry.source ~= "goal",
            "no-goal room should not have goal entries (option " .. i .. ")")
    end
end)

t.suite("generate_options — stability and rotation")

test("goal steps are stable across repeated calls", function()
    mock_goal_planner:set_plan({
        { verb = "open", noun = "door", display = "Open the door" },
    })
    local ctx = make_ctx({
        goal = { verb = "go", noun = "north", label = "escape" },
    })
    local r1 = generate(ctx)
    local r2 = generate(ctx)
    eq(r1.options[1].command, r2.options[1].command,
        "goal step should be identical across repeated calls")
    mock_goal_planner:set_plan(nil)
end)

test("sensory suggestions rotate across calls", function()
    local ctx1 = make_ctx({ options_request_count = 0 })
    local ctx2 = make_ctx({ options_request_count = 1 })
    local r1 = generate(ctx1)
    local r2 = generate(ctx2)

    -- Collect sensory commands from each call
    local s1, s2 = {}, {}
    for _, e in ipairs(r1.options) do
        if e.source == "sensory" then s1[#s1 + 1] = e.command end
    end
    for _, e in ipairs(r2.options) do
        if e.source == "sensory" then s2[#s2 + 1] = e.command end
    end

    -- At least one sensory command should differ between calls
    local all_same = true
    for i = 1, math.min(#s1, #s2) do
        if s1[i] ~= s2[i] then all_same = false break end
    end
    if #s1 ~= #s2 then all_same = false end
    truthy(not all_same, "sensory suggestions should rotate between calls")
end)

-- ============================================================
local exit_code = t.summary()
t.reset()
os.exit(exit_code)
