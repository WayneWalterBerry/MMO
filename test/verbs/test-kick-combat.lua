-- test/verbs/test-kick-combat.lua
-- WAVE-4 TDD: Validates that `kick` resolves through the combat pipeline
-- identically to `hit` — creature targeting, empty-noun error, alias parity.
--
-- Written to spec per npc-combat-implementation-phase3.md WAVE-4.
-- Usage: lua test/verbs/test-kick-combat.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

local ok_verbs, verbs_mod = pcall(require, "engine.verbs")
if not ok_verbs then
    print("WARNING: engine.verbs not found — tests will fail (TDD: expected)")
    verbs_mod = nil
end

local ok_inj, injury_mod = pcall(require, "engine.injuries")
if ok_inj and injury_mod.clear_cache then
    injury_mod.clear_cache()
end

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
    if not ok then return table.concat(captured, "\n"), err end
    return table.concat(captured, "\n"), nil
end

local function make_mock_creature(overrides)
    local c = {
        guid = "{kick-rat-" .. tostring(math.random(99999)) .. "}",
        template = "creature",
        id = "rat",
        name = "a rat",
        keywords = {"rat"},
        animate = true,
        alive = true,
        health = 5,
        max_health = 5,
        size = "tiny",
        location = "test-room",
        initial_state = "alive-idle",
        _state = "alive-idle",
        states = {
            ["alive-idle"] = { description = "Sitting." },
            ["dead"] = { description = "Dead.", animate = false },
        },
        behavior = { default = "idle", aggression = 5, flee_threshold = 30 },
        drives = {
            hunger = { value = 50, decay_rate = 2, max = 100, min = 0 },
            fear = { value = 0, decay_rate = -10, max = 100, min = 0 },
        },
        reactions = {
            player_attacks = { action = "flee", fear_delta = 80 },
        },
        body_tree = {
            { zone = "body", label = "body", hp = 5 },
        },
        combat = {
            natural_weapons = {
                { name = "bite", type = "piercing", force = 1, zone = "body" },
            },
        },
    }
    if overrides then
        for k, v in pairs(overrides) do c[k] = v end
    end
    return c
end

local function make_mock_registry(objects)
    return {
        _objects = objects or {},
        get = function(self, id)
            return self._objects[id]
        end,
        register = function(self, id, obj) self._objects[id] = obj end,
        remove = function(self, id) self._objects[id] = nil end,
        find_by_keyword = function(self, kw)
            local results = {}
            for _, obj in pairs(self._objects) do
                if obj.keywords then
                    for _, k in ipairs(obj.keywords) do
                        if k:lower() == kw:lower() then
                            results[#results + 1] = obj
                            break
                        end
                    end
                end
            end
            return results
        end,
        list = function(self)
            local t = {}
            for _, obj in pairs(self._objects) do t[#t + 1] = obj end
            return t
        end,
    }
end

local function fresh_player()
    return {
        max_health = 100,
        injuries = {},
        hands = { nil, nil },
        worn = {},
        worn_items = {},
        bags = {},
        state = {},
        consciousness = {},
    }
end

local function make_ctx(opts)
    opts = opts or {}
    local objs = opts.objects or {}
    local reg = make_mock_registry(objs)
    local player = opts.player or fresh_player()
    local room = opts.room or {
        id = "test-room",
        name = "Test Room",
        description = "A test room.",
        contents = {},
        exits = {},
        light_level = 0,
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 8,
        game_start_time = os.time(),
        current_verb = opts.verb or "kick",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
    }
end

---------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------
local handlers
if verbs_mod and verbs_mod.create then
    handlers = verbs_mod.create()
end

suite("KICK VERB: combat pipeline routing (WAVE-4)")

test("1. kick handler exists and is registered", function()
    h.assert_truthy(handlers, "verbs.create() must return handlers")
    h.assert_truthy(handlers["kick"], "kick handler must be registered")
end)

test("2. kick is aliased to the same function as hit", function()
    h.assert_truthy(handlers, "verbs.create() must return handlers")
    h.assert_truthy(handlers["kick"], "kick handler must exist")
    h.assert_truthy(handlers["hit"], "hit handler must exist")
    -- Both should be the same function reference (aliased)
    h.assert_eq(handlers["kick"], handlers["hit"],
        "kick must be aliased to hit (same function reference)")
end)

test("3. kick without target prints error message", function()
    h.assert_truthy(handlers, "verbs.create() must return handlers")
    local ctx = make_ctx({ verb = "kick" })
    local output = capture_output(function()
        handlers["kick"](ctx, "")
    end)
    h.assert_truthy(output and #output > 0,
        "kick with empty noun should produce error output")
    -- Should say "Hit what?" or similar error
    h.assert_truthy(
        output:lower():find("what") or output:lower():find("hit") or output:lower():find("kick"),
        "error message should indicate missing target, got: " .. tostring(output))
end)

test("4. kick with non-creature noun falls through to hit self-infliction path", function()
    h.assert_truthy(handlers, "verbs.create() must return handlers")
    -- "kick head" should route to self-infliction (same as "hit head")
    local ctx = make_ctx({ verb = "kick" })
    -- Register concussion injury for the self-infliction path
    local ok_inj2, inj2 = pcall(require, "engine.injuries")
    if ok_inj2 and inj2.register_definition then
        inj2.clear_cache()
        inj2.reset_id_counter()
        inj2.register_definition("concussion", {
            id = "concussion", name = "Concussion",
            category = "physical", damage_type = "one_time",
            initial_state = "active",
            on_inflict = { initial_damage = 5, damage_per_tick = 0,
                message = "Your head rings." },
            states = {
                active = { name = "concussion", damage_per_tick = 0 },
                healed = { terminal = true },
            },
        })
        inj2.register_definition("bruised", {
            id = "bruised", name = "Bruise",
            category = "physical", damage_type = "one_time",
            initial_state = "active",
            on_inflict = { initial_damage = 4, damage_per_tick = 0,
                message = "A bruise forms." },
            states = {
                active = { name = "bruise", damage_per_tick = 0 },
                healed = { terminal = true },
            },
        })
    end
    local output = capture_output(function()
        handlers["kick"](ctx, "head")
    end)
    -- Self-infliction to head produces unconsciousness narration
    h.assert_truthy(output and #output > 0,
        "kick head should produce self-infliction output, got: " .. tostring(output))
    h.assert_truthy(
        output:find("head") or output:find("slam") or output:find("stars")
            or output:find("vision") or output:find("hit"),
        "kick head should trigger head-hit self-infliction, got: " .. output)
end)

test("5. kick shares identity with punch/bash/hit aliases", function()
    h.assert_truthy(handlers, "verbs.create() must return handlers")
    local kick_fn = handlers["kick"]
    local punch_fn = handlers["punch"]
    local bash_fn = handlers["bash"]
    local hit_fn = handlers["hit"]
    -- All blunt aliases should be the same function
    h.assert_eq(kick_fn, hit_fn, "kick must equal hit")
    h.assert_eq(punch_fn, hit_fn, "punch must equal hit")
    h.assert_eq(bash_fn, hit_fn, "bash must equal hit")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code)
