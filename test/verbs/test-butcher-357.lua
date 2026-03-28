-- test/verbs/test-butcher-357.lua
-- Issue #357: Butcher error message misleading — "You need a knife" when holding one.
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

---------------------------------------------------------------------------
-- #357: Butcher error distinguishes "no tool" vs "wrong tool"
---------------------------------------------------------------------------
suite("#357: Butcher error message is capability-aware")

test("butcher with no knife says 'butchering tool'", function()
    local corpse = {
        id = "rat-corpse", name = "a dead rat",
        keywords = {"rat", "corpse", "dead rat"},
        alive = false,
        death_state = {
            butchery_products = {
                requires_tool = "butchering",
                products = { { id = "rat-meat", quantity = 1 } },
                narration = { start = "You begin butchering.", complete = "Done." },
            },
        },
    }
    local reg = make_mock_registry({ ["rat-corpse"] = corpse })
    local room = {
        id = "test-room", name = "Test Room",
        description = "A test room.", contents = { "rat-corpse" },
        exits = {}, light_level = 1,
    }
    local player = {
        max_health = 100, health = 100,
        injuries = {}, hands = { nil, nil },
        worn_items = {}, bags = {}, worn = {},
        state = {},
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = "butcher",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
    }
    local output = capture_output(function() handlers["butcher"](ctx, "rat") end)
    -- Error should mention "butchering" capability, not just "knife"
    h.assert_truthy(output:find("butcher") or output:find("cutting") or output:find("sharp") or output:find("tool"),
        "Error must mention the tool type needed, got: " .. output)
end)

test("butcher with knife that lacks 'butchering' capability gives specific error", function()
    local corpse = {
        id = "rat-corpse", name = "a dead rat",
        keywords = {"rat", "corpse", "dead rat"},
        alive = false,
        death_state = {
            butchery_products = {
                requires_tool = "butchering",
                products = { { id = "rat-meat", quantity = 1 } },
                narration = { start = "You begin butchering.", complete = "Done." },
            },
        },
    }
    -- A knife WITHOUT butchering capability (only cutting_edge)
    local knife = {
        id = "knife", name = "a small knife",
        keywords = {"knife", "blade"},
        portable = true,
        provides_tool = {"cutting_edge"},
    }
    local reg = make_mock_registry({ ["rat-corpse"] = corpse, knife = knife })
    local room = {
        id = "test-room", name = "Test Room",
        description = "A test room.", contents = { "rat-corpse" },
        exits = {}, light_level = 1,
    }
    local player = {
        max_health = 100, health = 100,
        injuries = {}, hands = { knife, nil },
        worn_items = {}, bags = {}, worn = {},
        state = {},
    }
    local ctx = {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = "butcher",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
    }
    local output = capture_output(function() handlers["butcher"](ctx, "rat") end)
    -- Should NOT just say "You need a knife" when player has a knife
    -- Should explain the knife isn't suitable for butchering
    h.assert_truthy(not output:find("You need a knife to butcher"),
        "Must NOT say 'You need a knife' when player already holds a knife, got: " .. output)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
