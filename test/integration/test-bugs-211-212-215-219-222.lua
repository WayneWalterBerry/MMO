-- test/integration/test-bugs-211-212-215-219-222.lua
-- TDD tests for high-impact gameplay bugs (batch 1)
-- Bugs: #211, #212, #215, #219, #222
-- Author: Smithers (UI Engineer)

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local tests_run = 0
local tests_passed = 0
local tests_failed = 0

local function test(description, fn)
    tests_run = tests_run + 1
    local status, err = pcall(fn)
    if status then
        tests_passed = tests_passed + 1
        print("  PASS " .. description)
    else
        tests_failed = tests_failed + 1
        print("  FAIL " .. description .. ": " .. tostring(err))
    end
end

local function assert_eq(expected, actual, message)
    if expected ~= actual then
        error(string.format(
            "%s\n  Expected: %s\n  Got:      %s",
            message or "Values not equal",
            tostring(expected),
            tostring(actual)
        ))
    end
end

local function assert_true(value, message)
    if not value then
        error(message or "Expected true, got false")
    end
end

local function assert_nil(value, message)
    if value ~= nil then
        error((message or "Expected nil") .. " — got: " .. tostring(value))
    end
end

local function capture_output(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error(err) end
    return table.concat(lines, "\n")
end

-- Load modules
local preprocess = require("engine.parser.preprocess")
local containment = require("engine.containment")
local presentation = require("engine.ui.presentation")

-- Mock registry factory
local function make_registry(objects)
    local reg = {
        _objects = objects or {},
    }
    function reg:get(id) return self._objects[id] end
    function reg:register(id, obj) self._objects[id] = obj end
    function reg:remove(id) self._objects[id] = nil end
    return reg
end

-- Mock player factory
local function make_player()
    return {
        hands = { nil, nil },
        worn = {},
        state = { hints_shown = {} },
        injuries = {},
        max_health = 100,
    }
end

---------------------------------------------------------------------------
-- BUG #211: 'get shard' after breaking window says wrong object
-- spawn_objects must set spawn_obj.id = actual_id
---------------------------------------------------------------------------
print("\n=== Bug #211: spawn_objects sets correct id on spawned objects ===")

-- We test the spawn_objects helper directly via the helpers module
local helpers_ok, H = pcall(require, "engine.verbs.helpers")

if helpers_ok and H.spawn_objects then
    test("#211: spawned object id matches registry key (no collision)", function()
        local reg = make_registry()
        local room = { id = "test-room", contents = {} }
        local loaded_obj = {
            id = "glass-shard",
            name = "a glass shard",
            keywords = {"shard", "glass"},
            size = 1,
            portable = true,
        }
        local ctx = {
            registry = reg,
            current_room = room,
            object_sources = {
                ["glass-shard"] = "return " .. string.format("%q", "dummy"),
            },
            loader = {
                load_source = function() return {
                    id = "glass-shard",
                    name = "a glass shard",
                    keywords = {"shard", "glass"},
                    size = 1,
                    portable = true,
                } end,
                resolve_template = function(obj) return obj end,
            },
            templates = {},
        }
        H.spawn_objects(ctx, {"glass-shard"})
        local spawned = reg:get("glass-shard")
        assert_true(spawned ~= nil, "Shard should be in registry")
        assert_eq("glass-shard", spawned.id, "Spawned object id should match registry key")
    end)

    test("#211: spawned object id updated when collision occurs", function()
        local existing = {
            id = "glass-shard",
            name = "a glass shard (existing)",
        }
        local reg = make_registry({ ["glass-shard"] = existing })
        local room = { id = "test-room", contents = {} }
        local ctx = {
            registry = reg,
            current_room = room,
            object_sources = {
                ["glass-shard"] = "return {}",
            },
            loader = {
                load_source = function() return {
                    id = "glass-shard",
                    name = "a glass shard",
                    keywords = {"shard", "glass"},
                    size = 1,
                    portable = true,
                } end,
                resolve_template = function(obj) return obj end,
            },
            templates = {},
        }
        H.spawn_objects(ctx, {"glass-shard"})
        local spawned = reg:get("glass-shard-2")
        assert_true(spawned ~= nil, "Second shard should be at glass-shard-2")
        assert_eq("glass-shard-2", spawned.id,
            "Spawned object id must be updated to match registry key")
    end)

    test("#211: two spawns from same source get unique ids", function()
        local reg = make_registry()
        local room = { id = "test-room", contents = {} }
        local spawn_count = 0
        local ctx = {
            registry = reg,
            current_room = room,
            object_sources = {
                ["glass-shard"] = "return {}",
            },
            loader = {
                load_source = function()
                    spawn_count = spawn_count + 1
                    return {
                        id = "glass-shard",
                        name = "a glass shard",
                        keywords = {"shard", "glass"},
                        size = 1,
                        portable = true,
                    }
                end,
                resolve_template = function(obj) return obj end,
            },
            templates = {},
        }
        H.spawn_objects(ctx, {"glass-shard", "glass-shard"})
        local shard1 = reg:get("glass-shard")
        local shard2 = reg:get("glass-shard-2")
        assert_true(shard1 ~= nil, "First shard should exist")
        assert_true(shard2 ~= nil, "Second shard should exist")
        assert_eq("glass-shard", shard1.id, "First shard id matches key")
        assert_eq("glass-shard-2", shard2.id, "Second shard id matches key")
        assert_true(shard1 ~= shard2, "Shards must be distinct objects")
    end)
else
    print("  SKIP #211 tests: helpers module not available or spawn_objects not exported")
end

---------------------------------------------------------------------------
-- BUG #212: 'look in mirror' parsed as bare 'look'
-- strip_decorative_prepositions must not strip "in mirror" from "look"
---------------------------------------------------------------------------
print("\n=== Bug #212: 'look in mirror' preserved through parser ===")

test("#212: 'look in mirror' not stripped to bare 'look'", function()
    local verb, noun = preprocess.natural_language("look in mirror")
    if verb == nil then
        verb, noun = preprocess.parse("look in mirror")
    end
    assert_eq("look", verb, "Verb should be 'look'")
    assert_true(noun ~= nil and noun ~= "",
        "Noun must not be empty — 'in mirror' is the functional target")
    assert_true(noun:find("mirror"),
        "Noun should contain 'mirror', got: " .. tostring(noun))
end)

test("#212: 'look in the mirror' not stripped to bare 'look'", function()
    local verb, noun = preprocess.natural_language("look in the mirror")
    if verb == nil then
        verb, noun = preprocess.parse("look in the mirror")
    end
    assert_eq("look", verb, "Verb should be 'look'")
    assert_true(noun ~= nil and noun ~= "",
        "Noun must not be empty for 'look in the mirror'")
    assert_true(noun:find("mirror"),
        "Noun should contain 'mirror', got: " .. tostring(noun))
end)

test("#212: 'examine yourself in the mirror' still strips 'in the mirror'", function()
    -- For non-look verbs, "in the mirror" IS decorative
    local stage = preprocess.stages.strip_decorative_prepositions
    local result = stage("examine yourself in the mirror")
    assert_eq("examine yourself", result,
        "Should strip 'in the mirror' from examine")
end)

test("#212: 'look in reflection' preserved", function()
    local verb, noun = preprocess.natural_language("look in reflection")
    if verb == nil then
        verb, noun = preprocess.parse("look in reflection")
    end
    assert_eq("look", verb)
    assert_true(noun ~= nil and noun ~= "" and noun:find("reflection"),
        "Noun should contain 'reflection', got: " .. tostring(noun))
end)

test("#212: strip_decorative_prepositions skips 'look' verb", function()
    local stage = preprocess.stages.strip_decorative_prepositions
    local result = stage("look in mirror")
    assert_eq("look in mirror", result,
        "Should not strip 'in mirror' from 'look' verb")
end)

---------------------------------------------------------------------------
-- BUG #215: 'get candle, get match' — second command resolves wrong
-- take handler must treat where=="container" same as where=="bag"
---------------------------------------------------------------------------
print("\n=== Bug #215: compound command container extraction ===")

if helpers_ok then
    test("#215: find_visible returns 'container' for nested surface items", function()
        -- Simulate: candle inside candle-holder on nightstand surface
        local candle = {
            id = "candle", name = "a tallow candle",
            keywords = {"candle", "tallow"}, portable = true, size = 1,
        }
        local holder = {
            id = "candle-holder", name = "a brass candle holder",
            keywords = {"holder"}, contents = {"candle"}, size = 2,
        }
        local nightstand = {
            id = "nightstand", name = "a small nightstand",
            keywords = {"nightstand"},
            surfaces = {
                top = { capacity = 3, contents = {"candle-holder"} },
            },
            contents = {},
        }
        local reg = make_registry({
            ["candle"] = candle,
            ["candle-holder"] = holder,
            ["nightstand"] = nightstand,
        })
        local room = { id = "test-room", contents = {"nightstand"} }
        local player = make_player()
        local ctx = {
            registry = reg,
            current_room = room,
            player = player,
            current_verb = "get",
            known_objects = {},
            last_object = nil,
        }
        local obj, where, parent = H.find_visible(ctx, "candle")
        assert_true(obj ~= nil, "Should find candle")
        assert_eq("candle", obj.id, "Should find the candle object")
        -- The location type should allow extraction from the container
        assert_true(where == "container" or where == "bag",
            "Location type should be 'container' or 'bag', got: " .. tostring(where))
        assert_true(parent ~= nil, "Parent container should be returned")
    end)
end

---------------------------------------------------------------------------
-- BUG #219: Taking candle holder kills room light
-- get_light_level must check contents of carried items
---------------------------------------------------------------------------
print("\n=== Bug #219: carried container contents provide light ===")

test("#219: light from candle inside carried holder", function()
    local candle = {
        id = "candle", casts_light = true, name = "a tallow candle",
    }
    -- Real candle-holder is NOT a container — it's a composite with parts
    local holder = {
        id = "candle-holder", name = "a brass candle holder",
        contents = {"candle"},
    }
    local reg = make_registry({
        ["candle"] = candle,
        ["candle-holder"] = holder,
    })
    local player = make_player()
    player.hands[1] = holder
    local ctx = {
        registry = reg,
        current_room = { id = "test-room", contents = {} },
        player = player,
        game_start_time = os.time(),
        time_offset = 20, -- nighttime
    }
    local level = presentation.get_light_level(ctx)
    assert_eq("lit", level,
        "Carrying holder with lit candle should give 'lit' light level")
end)

test("#219: light from item held directly (baseline)", function()
    local candle = {
        id = "candle", casts_light = true, name = "a tallow candle",
    }
    local reg = make_registry({ ["candle"] = candle })
    local player = make_player()
    player.hands[1] = candle
    local ctx = {
        registry = reg,
        current_room = { id = "test-room", contents = {} },
        player = player,
        game_start_time = os.time(),
        time_offset = 20,
    }
    local level = presentation.get_light_level(ctx)
    assert_eq("lit", level,
        "Holding a lit candle directly should give 'lit'")
end)

test("#219: no light when holder has unlit candle", function()
    local candle = {
        id = "candle", casts_light = false, name = "a tallow candle",
    }
    local holder = {
        id = "candle-holder", name = "a brass candle holder",
        contents = {"candle"},
    }
    local reg = make_registry({
        ["candle"] = candle,
        ["candle-holder"] = holder,
    })
    local player = make_player()
    player.hands[1] = holder
    local ctx = {
        registry = reg,
        current_room = { id = "test-room", contents = {} },
        player = player,
        game_start_time = os.time(),
        time_offset = 20,
    }
    local level = presentation.get_light_level(ctx)
    assert_eq("dark", level,
        "Holder with unlit candle should be 'dark'")
end)

test("#219: light from nested container in worn bag", function()
    local torch = {
        id = "torch", casts_light = true,
    }
    local bag = {
        id = "bag", container = true, contents = {"torch"},
    }
    local reg = make_registry({
        ["torch"] = torch,
        ["bag"] = bag,
    })
    local player = make_player()
    player.worn = {"bag"}
    local ctx = {
        registry = reg,
        current_room = { id = "test-room", contents = {} },
        player = player,
        game_start_time = os.time(),
        time_offset = 20,
    }
    local level = presentation.get_light_level(ctx)
    assert_eq("lit", level,
        "Torch inside worn bag should provide light")
end)

---------------------------------------------------------------------------
-- BUG #222: 'put candle on nightstand' says no room
-- Should redirect to reattach target when surface is full
---------------------------------------------------------------------------
print("\n=== Bug #222: put candle on nightstand redirects to holder ===")

test("#222: containment correctly reports surface full", function()
    local candle = { id = "candle", size = 1, weight = 0.5 }
    local holder = { id = "candle-holder", size = 2 }
    local bottle = { id = "poison-bottle", size = 1 }
    local nightstand = {
        id = "nightstand",
        name = "a small nightstand",
        surfaces = {
            top = { capacity = 3, max_item_size = 2, contents = {"candle-holder", "poison-bottle"} },
        },
    }
    local reg = make_registry({
        ["candle"] = candle,
        ["candle-holder"] = holder,
        ["poison-bottle"] = bottle,
        ["nightstand"] = nightstand,
    })
    local ok, reason = containment.can_contain(candle, nightstand, "top", reg)
    assert_true(not ok, "Surface should be full (cap 3 = holder 2 + bottle 1)")
    assert_true(reason:find("not enough room"),
        "Reason should mention no room, got: " .. tostring(reason))
end)

if helpers_ok then
    test("#222: put handler redirects to reattach when surface full", function()
        -- Setup: candle in hand, holder on nightstand, surface full
        local candle = {
            id = "candle", name = "a tallow candle", size = 1, weight = 0.5,
            keywords = {"candle"}, portable = true,
            reattach_to = "candle-holder",
        }
        local holder = {
            id = "candle-holder", name = "a brass candle holder", size = 2,
            keywords = {"holder", "candle holder"},
            parts = {
                candle = {
                    id = "candle", detachable = true, reversible = true,
                    keywords = {"candle"},
                },
            },
            _state = "empty",
            states = {
                empty = {}, with_candle = { contents = {"candle"} },
            },
            transitions = {
                {
                    from = "empty", to = "with_candle",
                    verb = "reattach_part", trigger = "reattach_part",
                    part_id = "candle",
                    message = "You press the candle into the brass socket.",
                },
            },
        }
        local bottle = {
            id = "poison-bottle", name = "a small bottle", size = 1,
            keywords = {"bottle"},
        }
        local nightstand = {
            id = "nightstand", name = "a small nightstand",
            keywords = {"nightstand"},
            surfaces = {
                top = {
                    capacity = 3, max_item_size = 2,
                    contents = {"candle-holder", "poison-bottle"},
                },
            },
        }
        local reg = make_registry({
            ["candle"] = candle,
            ["candle-holder"] = holder,
            ["poison-bottle"] = bottle,
            ["nightstand"] = nightstand,
        })
        local player = make_player()
        player.hands[1] = candle
        local ctx = {
            registry = reg,
            current_room = { id = "test-room", contents = {"nightstand"} },
            player = player,
            containment = containment,
            current_verb = "put",
            known_objects = {},
            last_object = nil,
        }

        -- Load verb handlers if possible
        local output = capture_output(function()
            local handlers = {}
            local verb_mods = {
                "engine.verbs.crafting",
            }
            for _, mod_name in ipairs(verb_mods) do
                local ok, mod = pcall(require, mod_name)
                if ok and mod.register then
                    mod.register(handlers)
                end
            end
            if handlers["put"] then
                handlers["put"](ctx, "candle on nightstand")
            else
                error("put handler not available")
            end
        end)
        -- Should NOT say "not enough room" — should redirect to holder
        assert_true(not output:find("not enough room"),
            "Should not reject with 'no room' — should redirect to holder. Got: " .. output)
    end)
end

-- Summary
print("\n--- Results ---")
print("  Passed: " .. tests_passed)
print("  Failed: " .. tests_failed)

os.exit(tests_failed > 0 and 1 or 0)
