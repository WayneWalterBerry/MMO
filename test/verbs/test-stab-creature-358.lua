-- test/verbs/test-stab-creature-358.lua
-- Issue #358: 'stab' verb only targets self — should allow creature targeting.
-- TDD: Tests written before fix.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")
local test = h.test
local suite = h.suite

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

local function make_mock_registry(objects)
    return {
        _objects = objects or {},
        get = function(self, id) return self._objects[id] end,
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
    }
end

local function fresh_knife()
    return {
        id = "knife",
        name = "a small knife",
        keywords = {"knife", "blade", "small knife"},
        categories = {"small", "tool", "weapon", "sharp", "metal"},
        portable = true,
        provides_tool = {"cutting_edge", "injury_source"},
        on_stab = {
            damage = 5,
            injury_type = "bleeding",
            description = "You stab the knife into your %s. It hurts more than you expected.",
        },
        mutations = {},
    }
end

---------------------------------------------------------------------------
-- #358: stab <creature> should NOT print self-only message
---------------------------------------------------------------------------
suite("#358: stab verb allows creature targeting")

test("'stab rat' does NOT say 'You can only stab yourself'", function()
    local knife = fresh_knife()
    local rat = {
        id = "rat", name = "the rat",
        keywords = {"rat"},
        animate = true, alive = true,
        _state = "alive",
        health = 10, max_health = 10,
        location = "test-room",
        combat = {
            size = "tiny", speed = 6,
            natural_weapons = {
                { id = "bite", type = "pierce", material = "tooth-enamel",
                  zone = "head", force = 2, message = "bites" },
            },
        },
        body_tree = {
            head = { size = 0.15, vital = true, tissue = { "hide", "flesh" } },
            body = { size = 0.45, vital = true, tissue = { "hide", "flesh" } },
        },
    }
    local reg = make_mock_registry({ knife = knife, rat = rat })
    local room = {
        id = "test-room", name = "Test Room",
        description = "A test room.", contents = { "rat" },
        exits = {}, light_level = 1,
    }
    local player = {
        max_health = 100, health = 100,
        injuries = {}, hands = { knife, nil },
        worn_items = {}, bags = {}, worn = {},
        state = {}, location = "test-room",
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = "stab",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
        headless = true,
    }
    local output = capture_output(function() handlers["stab"](ctx, "rat") end)
    h.assert_truthy(not output:find("only stab yourself"),
        "'stab rat' must NOT say 'You can only stab yourself', got: " .. output)
end)

test("'stab self' still works for self-infliction", function()
    local knife = fresh_knife()
    local reg = make_mock_registry({ knife = knife })
    local room = {
        id = "test-room", name = "Test Room",
        description = "A test room.", contents = {},
        exits = {}, light_level = 0,
    }
    local player = {
        max_health = 100, health = 100,
        injuries = {}, hands = { knife, nil },
        worn_items = {}, bags = {}, worn = {},
        state = {}, location = "test-room",
    }
    -- Need injury module for self-infliction
    local inj_ok, injury_mod = pcall(require, "engine.injuries")
    if inj_ok and injury_mod.register_definition then
        injury_mod.clear_cache()
        injury_mod.reset_id_counter()
        injury_mod.register_definition("bleeding", {
            id = "bleeding", name = "Bleeding Wound",
            category = "physical", damage_type = "over_time",
            initial_state = "active",
            on_inflict = { initial_damage = 5, damage_per_tick = 5, message = "Blood wells." },
            states = {
                active = { name = "bleeding", damage_per_tick = 5 },
                treated = { name = "bandaged", damage_per_tick = 0 },
                healed = { name = "healed", terminal = true },
            },
            healing_interactions = {},
        })
    end
    local ctx = {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = "stab",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
    }
    local output = capture_output(function() handlers["stab"](ctx, "self") end)
    -- Self-infliction should still work (either creates injury or finds no weapon)
    h.assert_truthy(output and #output > 0,
        "'stab self' should produce some output")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
