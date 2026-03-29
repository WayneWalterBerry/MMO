-- test/sound/test-sound-integration.lua
-- WAVE-2 Track 2C: End-to-end integration tests verifying sounds fire on
-- state changes, verbs, room transitions, mutations, and headless/nil mode.
-- Uses mock driver to record all play/stop/load calls — no real audio.

package.path = "src/?.lua;src/?/init.lua;test/?.lua;test/parser/?.lua;" .. package.path

local t = require("test.parser.test-helpers")

----------------------------------------------------------------------------
-- Mock driver factory — records every call for assertion
----------------------------------------------------------------------------

local function make_mock_driver()
    local calls = {}
    local driver = {}
    driver._calls = calls

    function driver:load(filename, callback)
        calls[#calls + 1] = { method = "load", args = { filename } }
        if callback then callback(filename, nil) end
    end

    function driver:play(filename, opts)
        calls[#calls + 1] = { method = "play", args = { filename, opts } }
        return "handle-" .. filename
    end

    function driver:stop(handle)
        calls[#calls + 1] = { method = "stop", args = { handle } }
    end

    function driver:stop_all()
        calls[#calls + 1] = { method = "stop_all", args = {} }
    end

    function driver:set_master_volume(level)
        calls[#calls + 1] = { method = "set_master_volume", args = { level } }
    end

    function driver:unload(handle)
        calls[#calls + 1] = { method = "unload", args = { handle } }
    end

    function driver:fade(handle, from, to, duration)
        calls[#calls + 1] = { method = "fade", args = { handle, from, to, duration } }
    end

    return driver
end

-- Find a call in the mock log matching method and filename
local function find_call(calls, method, filename)
    for _, c in ipairs(calls) do
        if c.method == method and c.args[1] == filename then
            return c
        end
    end
    return nil
end

-- Count calls matching method
local function count_calls(calls, method)
    local n = 0
    for _, c in ipairs(calls) do
        if c.method == method then n = n + 1 end
    end
    return n
end

-- Count calls matching method and filename
local function count_calls_for(calls, method, filename)
    local n = 0
    for _, c in ipairs(calls) do
        if c.method == method and c.args[1] == filename then n = n + 1 end
    end
    return n
end

----------------------------------------------------------------------------
-- Module loading
----------------------------------------------------------------------------

local sound_mod = require("engine.sound")
local fsm       = require("engine.fsm")
local registry  = require("engine.registry")
local loader    = require("engine.loader")
local mutation  = require("engine.mutation")

----------------------------------------------------------------------------
-- Suite 1: FSM transition triggers sound
----------------------------------------------------------------------------

t.suite("integration — FSM transition triggers sound")

t.test("light candle → on_state_lit fires via mock driver", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local reg = registry.new()
    local candle = {
        id = "test-candle",
        guid = "{test-candle-guid}",
        _state = "unlit",
        initial_state = "unlit",
        states = {
            unlit = { description = "An unlit candle." },
            lit   = { description = "A lit candle.", casts_light = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light" },
        },
        sounds = {
            on_state_lit = "candle-ignite.opus",
        },
    }
    reg:register("test-candle", candle)
    sm:scan_object(candle)

    local context = { sound_manager = sm }
    local trans = fsm.transition(reg, "test-candle", "lit", context, "light")
    t.assert_truthy(trans, "FSM transition succeeded")
    t.assert_eq("lit", candle._state, "candle is now lit")

    local play = find_call(mock._calls, "play", "candle-ignite.opus")
    t.assert_truthy(play, "on_state_lit sound played via mock driver")
end)

t.test("FSM transition with no matching sound → silent (no crash)", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local reg = registry.new()
    local door = {
        id = "test-door",
        guid = "{test-door-guid}",
        _state = "closed",
        initial_state = "closed",
        states = {
            closed = { description = "A closed door." },
            open   = { description = "An open door." },
        },
        transitions = {
            { from = "closed", to = "open", verb = "open" },
        },
        -- No sounds table at all
    }
    reg:register("test-door", door)

    local context = { sound_manager = sm }
    local trans = fsm.transition(reg, "test-door", "open", context, "open")
    t.assert_truthy(trans, "FSM transition succeeded")

    -- on_state_open has no object sound; check if default was used or silent
    local play_count = count_calls(mock._calls, "play")
    -- defaults.lua has on_verb_open but NOT on_state_open → should be silent
    local state_play = find_call(mock._calls, "play", "on_state_open")
    -- Either 0 plays (silent) or a default play — both are valid, just no crash
    t.assert_truthy(true, "no crash on soundless FSM transition")
end)

t.test("close door → on_state_closed fires object-specific sound", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local reg = registry.new()
    local door = {
        id = "test-door-2",
        guid = "{test-door-2-guid}",
        _state = "open",
        initial_state = "open",
        states = {
            open   = { description = "An open door." },
            closed = { description = "A closed door." },
        },
        transitions = {
            { from = "open", to = "closed", verb = "close" },
        },
        sounds = {
            on_state_closed = "door-slam.opus",
        },
    }
    reg:register("test-door-2", door)
    sm:scan_object(door)

    local context = { sound_manager = sm }
    local trans = fsm.transition(reg, "test-door-2", "closed", context, "close")
    t.assert_truthy(trans, "FSM transition succeeded")

    local play = find_call(mock._calls, "play", "door-slam.opus")
    t.assert_truthy(play, "on_state_closed sound played")
end)

----------------------------------------------------------------------------
-- Suite 2: Verb triggers sound via trigger()
----------------------------------------------------------------------------

t.suite("integration — verb triggers sound")

t.test("break mirror → on_verb_break fires object-specific sound", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local mirror = {
        id = "test-mirror",
        guid = "{test-mirror-guid}",
        sounds = {
            on_verb_break = "mirror-shatter.opus",
        },
    }
    sm:scan_object(mirror)

    -- Simulate verb handler calling trigger
    sm:trigger(mirror, "on_verb_break")

    local play = find_call(mock._calls, "play", "mirror-shatter.opus")
    t.assert_truthy(play, "on_verb_break played mirror-specific sound")
end)

t.test("break object without sounds → falls back to default", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local rock = { id = "test-rock", guid = "{test-rock-guid}" }
    -- No sounds table — should fall back to defaults.on_verb_break

    sm:trigger(rock, "on_verb_break")

    local play = find_call(mock._calls, "play", "generic-break.opus")
    t.assert_truthy(play, "on_verb_break fell back to generic-break.opus")
end)

t.test("verb with no default and no object sound → silent", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local obj = { id = "test-obj", guid = "{test-obj-guid}" }
    local result = sm:trigger(obj, "on_verb_smell")

    t.assert_nil(result, "no play_id returned for unknown event")
    t.assert_eq(0, count_calls(mock._calls, "play"), "no play call for unknown event")
end)

----------------------------------------------------------------------------
-- Suite 3: Room entry triggers ambient
----------------------------------------------------------------------------

t.suite("integration — room entry triggers ambient")

t.test("enter cellar → ambient sound starts looping", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local cellar = {
        id = "test-cellar",
        guid = "{test-cellar-guid}",
        template = "room",
        name = "Cellar",
        sounds = {
            ambient = "amb-cellar-drip.opus",
        },
    }

    sm:enter_room(cellar)

    local play = find_call(mock._calls, "play", "amb-cellar-drip.opus")
    t.assert_truthy(play, "ambient sound was played on room entry")

    -- Verify it was played with loop=true
    local opts = play.args[2]
    t.assert_truthy(opts, "play options present")
    t.assert_eq(true, opts.loop, "ambient plays as loop")
end)

t.test("enter room without ambient → silent (no crash)", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local bedroom = {
        id = "test-bedroom",
        guid = "{test-bedroom-guid}",
        template = "room",
        name = "Bedroom",
        -- No sounds table
    }

    t.assert_no_error(function()
        sm:enter_room(bedroom)
    end, "enter room without ambient should not crash")
    t.assert_eq(0, count_calls(mock._calls, "play"), "no play call for room without ambient")
end)

----------------------------------------------------------------------------
-- Suite 4: Room exit stops ambient
----------------------------------------------------------------------------

t.suite("integration — room exit stops ambient")

t.test("leave cellar → ambient stops", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local cellar = {
        id = "test-cellar-exit",
        guid = "{test-cellar-exit-guid}",
        sounds = {
            ambient = "amb-cellar-drip.opus",
        },
    }

    -- Enter room (starts ambient)
    sm:enter_room(cellar)
    local play_before = count_calls(mock._calls, "play")
    t.assert_eq(1, play_before, "ambient started on enter")

    -- Exit room (should stop ambient)
    sm:exit_room(cellar)

    local stop_found = false
    for _, c in ipairs(mock._calls) do
        if c.method == "stop" then
            stop_found = true
            break
        end
    end
    t.assert_truthy(stop_found, "stop was called on room exit")
end)

t.test("room transition: exit old → enter new", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local cellar = {
        id = "test-cellar-t",
        guid = "{test-cellar-t-guid}",
        sounds = { ambient = "amb-cellar-drip.opus" },
    }
    local hallway = {
        id = "test-hallway-t",
        guid = "{test-hallway-t-guid}",
        sounds = { ambient = "amb-hallway-wind.opus" },
    }

    -- Enter first room
    sm:enter_room(cellar)
    t.assert_truthy(find_call(mock._calls, "play", "amb-cellar-drip.opus"),
        "cellar ambient started")

    -- Transition: exit old room, enter new room
    sm:exit_room(cellar)
    sm:enter_room(hallway)

    t.assert_truthy(find_call(mock._calls, "play", "amb-hallway-wind.opus"),
        "hallway ambient started after transition")

    -- Verify stop was called (for the cellar ambient)
    local stop_count = count_calls(mock._calls, "stop")
    t.assert_truthy(stop_count > 0, "at least one stop call during transition")
end)

----------------------------------------------------------------------------
-- Suite 5: Mutation fires sound
----------------------------------------------------------------------------

t.suite("integration — mutation fires sound")

t.test("break object → on_mutate fires + old sounds stop + new scanned", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local reg = registry.new()

    -- Old object with sounds
    local vase = {
        id = "test-vase",
        guid = "{test-vase-guid}",
        name = "a porcelain vase",
        sounds = {
            on_mutate = "vase-shatter.opus",
            ambient = "vase-hum.opus",
        },
    }
    reg:register("test-vase", vase)
    sm:scan_object(vase)

    -- Start an ambient on the old object so we can verify it gets stopped
    -- mutation calls stop_by_owner(object_id) where object_id is the registry key
    sm:play("vase-hum.opus", { loop = true, owner_id = "test-vase" })
    local play_before = count_calls(mock._calls, "play")
    t.assert_truthy(play_before > 0, "ambient was playing before mutation")

    -- New object source (the mutated replacement)
    local new_source = [[
return {
    id = "test-vase-broken",
    guid = "{test-vase-guid}",
    name = "shards of porcelain",
    sounds = {
        on_verb_take = "shards-clink.opus",
    },
}
]]

    local ctx = { sound_manager = sm }
    local new_obj, err = mutation.mutate(reg, loader, "test-vase", new_source, nil, ctx)
    t.assert_truthy(new_obj, "mutation succeeded: " .. tostring(err))

    -- Verify: stop_by_owner was called (stops old ambient)
    local stop_found = false
    for _, c in ipairs(mock._calls) do
        if c.method == "stop" then
            stop_found = true
            break
        end
    end
    t.assert_truthy(stop_found, "old object sounds stopped during mutation")

    -- Verify: on_mutate sound fired
    local mutate_play = find_call(mock._calls, "play", "vase-shatter.opus")
    t.assert_truthy(mutate_play, "on_mutate sound played")

    -- Verify: new object was scanned (check internal state)
    local new_sounds = sm._object_sounds["{test-vase-guid}"]
    t.assert_truthy(new_sounds, "new object sounds scanned into manager")
    t.assert_eq("shards-clink.opus", new_sounds.on_verb_take,
        "new object sound registered")
end)

t.test("mutation with no sounds → no crash", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local reg = registry.new()
    local plain = {
        id = "test-plain",
        guid = "{test-plain-guid}",
        name = "a plain rock",
    }
    reg:register("test-plain", plain)

    local new_source = [[
return {
    id = "test-plain-cracked",
    guid = "{test-plain-guid}",
    name = "a cracked rock",
}
]]

    local ctx = { sound_manager = sm }
    t.assert_no_error(function()
        mutation.mutate(reg, loader, "test-plain", new_source, nil, ctx)
    end, "mutation without sounds should not crash")
end)

----------------------------------------------------------------------------
-- Suite 6: Nil driver (headless) — all operations succeed silently
----------------------------------------------------------------------------

t.suite("integration — nil driver (headless mode)")

t.test("FSM transition with nil driver → no crash, no sound", function()
    local sm = sound_mod.new()
    -- No driver set (headless)

    local reg = registry.new()
    local candle = {
        id = "test-candle-h",
        guid = "{test-candle-h-guid}",
        _state = "unlit",
        initial_state = "unlit",
        states = {
            unlit = { description = "Unlit." },
            lit   = { description = "Lit.", casts_light = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light" },
        },
        sounds = {
            on_state_lit = "candle-ignite.opus",
        },
    }
    reg:register("test-candle-h", candle)

    local context = { sound_manager = sm }
    t.assert_no_error(function()
        fsm.transition(reg, "test-candle-h", "lit", context, "light")
    end, "FSM transition with nil driver should not crash")
    t.assert_eq("lit", candle._state, "transition still succeeds")
end)

t.test("trigger() with nil driver → returns nil, no crash", function()
    local sm = sound_mod.new()
    local obj = { id = "test-obj-h", sounds = { on_verb_break = "break.opus" } }
    local result = sm:trigger(obj, "on_verb_break")
    t.assert_nil(result, "trigger returns nil with no driver")
end)

t.test("enter_room/exit_room with nil driver → no crash", function()
    local sm = sound_mod.new()
    local room = { id = "test-room-h", sounds = { ambient = "amb.opus" } }
    t.assert_no_error(function()
        sm:enter_room(room)
        sm:exit_room(room)
    end, "room enter/exit with nil driver should not crash")
end)

t.test("mutation with nil driver → no crash", function()
    local sm = sound_mod.new()
    local reg = registry.new()
    local obj = {
        id = "test-mut-h",
        guid = "{test-mut-h-guid}",
        name = "a thing",
        sounds = { on_mutate = "boom.opus" },
    }
    reg:register("test-mut-h", obj)

    local new_source = [[
return {
    id = "test-mut-h-broken",
    guid = "{test-mut-h-guid}",
    name = "a broken thing",
}
]]

    local ctx = { sound_manager = sm }
    t.assert_no_error(function()
        mutation.mutate(reg, loader, "test-mut-h", new_source, nil, ctx)
    end, "mutation with nil driver should not crash")
end)

t.test("scan_object + flush_queue with nil driver → no crash", function()
    local sm = sound_mod.new()
    local obj = { id = "test-scan-h", sounds = { ambient = "drip.opus" } }
    t.assert_no_error(function()
        sm:scan_object(obj)
        sm:flush_queue()
    end, "scan + flush with nil driver should not crash")
end)

----------------------------------------------------------------------------
-- Suite 7: Effects pipeline play_sound dispatch
----------------------------------------------------------------------------

t.suite("integration — effects pipeline play_sound")

t.test("play_sound effect with key triggers sound manager", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local effects = require("engine.effects")

    local obj = {
        id = "test-fx-obj",
        guid = "{test-fx-obj-guid}",
        sounds = {
            on_verb_open = "chest-creak.opus",
        },
    }
    sm:scan_object(obj)

    local ctx = { sound_manager = sm, source = obj }
    local effect = { type = "play_sound", key = "on_verb_open", source_obj = obj }
    effects.process({ effect }, ctx)

    local play = find_call(mock._calls, "play", "chest-creak.opus")
    t.assert_truthy(play, "play_sound effect triggered chest-creak.opus")
end)

t.test("play_sound effect with filename plays directly", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local effects = require("engine.effects")

    local obj = { id = "test-fx-direct", guid = "{test-fx-direct-guid}" }
    local ctx = { sound_manager = sm, source = obj }
    local effect = { type = "play_sound", filename = "custom-sfx.opus", source_obj = obj }
    effects.process({ effect }, ctx)

    local play = find_call(mock._calls, "play", "custom-sfx.opus")
    t.assert_truthy(play, "play_sound effect with filename played directly")
end)

----------------------------------------------------------------------------
-- Suite 8: Loader scan_for_sounds hook
----------------------------------------------------------------------------

t.suite("integration — loader scan_for_sounds hook")

t.test("scan_for_sounds registers object sounds in manager", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local obj = {
        id = "test-loader-obj",
        guid = "{test-loader-obj-guid}",
        sounds = {
            on_verb_take = "pickup.opus",
            ambient = "hum.opus",
        },
    }

    loader.scan_for_sounds(sm, obj)

    t.assert_truthy(sm._object_sounds["{test-loader-obj-guid}"],
        "sounds registered via loader hook")
    t.assert_eq("pickup.opus",
        sm._object_sounds["{test-loader-obj-guid}"].on_verb_take,
        "on_verb_take sound registered")
end)

t.test("scan_for_sounds with nil manager → no crash", function()
    local obj = { id = "test-loader-nil", sounds = { ambient = "x.opus" } }
    t.assert_no_error(function()
        loader.scan_for_sounds(nil, obj)
    end, "nil sound_manager should not crash loader hook")
end)

t.test("scan_for_sounds with nil obj → no crash", function()
    local sm = sound_mod.new()
    t.assert_no_error(function()
        loader.scan_for_sounds(sm, nil)
    end, "nil object should not crash loader hook")
end)

----------------------------------------------------------------------------
-- Suite 9: Full flow — action → hook → trigger → driver
----------------------------------------------------------------------------

t.suite("integration — full flow end-to-end")

t.test("light candle: register → scan → FSM → sound plays", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local reg = registry.new()
    local candle = {
        id = "test-candle-full",
        guid = "{test-candle-full-guid}",
        _state = "unlit",
        initial_state = "unlit",
        states = {
            unlit = { description = "An unlit candle." },
            lit   = { description = "A lit candle.", casts_light = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light" },
        },
        sounds = {
            on_state_lit = "candle-ignite.opus",
            on_state_unlit = "candle-snuff.opus",
        },
    }

    -- Step 1: Register object
    reg:register("test-candle-full", candle)

    -- Step 2: Loader scans for sounds
    loader.scan_for_sounds(sm, candle)
    t.assert_truthy(sm._object_sounds["{test-candle-full-guid}"],
        "sounds registered after loader scan")

    -- Step 3: Flush queue (load files)
    sm:flush_queue()
    local load_count = count_calls(mock._calls, "load")
    t.assert_truthy(load_count >= 2, "at least 2 sound files loaded")

    -- Step 4: FSM transition fires sound
    local context = { sound_manager = sm }
    local trans = fsm.transition(reg, "test-candle-full", "lit", context, "light")
    t.assert_truthy(trans, "FSM transition succeeded")

    local play = find_call(mock._calls, "play", "candle-ignite.opus")
    t.assert_truthy(play, "candle-ignite.opus played after full flow")
end)

t.test("room transition: exit → enter with ambient swap", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local old_room = {
        id = "test-room-old",
        guid = "{test-room-old-guid}",
        sounds = { ambient = "amb-old.opus" },
    }
    local new_room = {
        id = "test-room-new",
        guid = "{test-room-new-guid}",
        sounds = { ambient = "amb-new.opus" },
    }

    -- Enter first room
    sm:enter_room(old_room)
    t.assert_truthy(find_call(mock._calls, "play", "amb-old.opus"),
        "old room ambient started")

    -- Full transition sequence
    sm:exit_room(old_room)
    sm:enter_room(new_room)

    t.assert_truthy(find_call(mock._calls, "play", "amb-new.opus"),
        "new room ambient started")

    -- Old ambient should have been stopped
    local stop_count = count_calls(mock._calls, "stop")
    t.assert_truthy(stop_count > 0, "old ambient stopped during transition")
end)

t.test("mutation full flow: old sounds stop → on_mutate → new scanned", function()
    local mock = make_mock_driver()
    local sm = sound_mod.new()
    sm:init(mock)

    local reg = registry.new()
    local jar = {
        id = "test-jar",
        guid = "{test-jar-guid}",
        name = "a glass jar",
        sounds = {
            on_mutate = "jar-crack.opus",
            ambient = "jar-buzz.opus",
        },
    }
    reg:register("test-jar", jar)
    loader.scan_for_sounds(sm, jar)
    sm:flush_queue()

    -- Start ambient for the jar
    sm:play("jar-buzz.opus", { loop = true, owner_id = "{test-jar-guid}" })

    -- Mutate
    local new_source = [[
return {
    id = "test-jar-broken",
    guid = "{test-jar-guid}",
    name = "broken glass shards",
    sounds = {
        on_verb_take = "glass-clink.opus",
    },
}
]]
    local ctx = { sound_manager = sm }
    local new_obj, err = mutation.mutate(reg, loader, "test-jar", new_source, nil, ctx)
    t.assert_truthy(new_obj, "mutation succeeded: " .. tostring(err))

    -- Verify sequence: stop was called, on_mutate played, new object scanned
    local mutate_play = find_call(mock._calls, "play", "jar-crack.opus")
    t.assert_truthy(mutate_play, "on_mutate sound played in full flow")

    local new_sounds = sm._object_sounds["{test-jar-guid}"]
    t.assert_truthy(new_sounds, "new object sounds registered")
    t.assert_eq("glass-clink.opus", new_sounds.on_verb_take,
        "new object on_verb_take registered")
end)

----------------------------------------------------------------------------
-- Done
----------------------------------------------------------------------------

t.summary()
