-- test/sound/test-sound-manager.lua
-- Unit tests for src/engine/sound/init.lua: construction, playback,
-- driver injection, volume, mute, scan_object, trigger, room transitions,
-- concurrency limits, and null-driver fallback.

package.path = "src/?.lua;src/?/init.lua;" .. package.path
local t = require("test.parser.test-helpers")

----------------------------------------------------------------------------
-- Module loading
----------------------------------------------------------------------------

t.suite("sound manager — module load")

local sound_mod = require("engine.sound")
local null_driver = require("engine.sound.null-driver")

t.test("module loads without error", function()
    t.assert_truthy(sound_mod, "sound module should load")
    t.assert_truthy(sound_mod.new, "new() exists")
end)

t.test("null driver loads without error", function()
    t.assert_truthy(null_driver, "null driver should load")
    t.assert_truthy(null_driver.play, "null driver has play()")
    t.assert_truthy(null_driver.stop, "null driver has stop()")
    t.assert_truthy(null_driver.load, "null driver has load()")
    t.assert_truthy(null_driver.stop_all, "null driver has stop_all()")
    t.assert_truthy(null_driver.set_master_volume, "null driver has set_master_volume()")
    t.assert_truthy(null_driver.unload, "null driver has unload()")
    t.assert_truthy(null_driver.fade, "null driver has fade()")
end)

----------------------------------------------------------------------------
-- Construction & lifecycle
----------------------------------------------------------------------------

t.suite("sound manager — construction")

t.test("new() creates instance with default state", function()
    local sm = sound_mod.new()
    t.assert_truthy(sm, "instance created")
    t.assert_eq(1.0, sm:get_volume(), "default volume is 1.0")
    t.assert_eq(false, sm:is_muted(), "not muted by default")
    t.assert_eq(true, sm:is_enabled(), "enabled by default")
    t.assert_nil(sm:get_driver(), "no driver by default")
end)

t.test("init() sets driver", function()
    local sm = sound_mod.new()
    sm:init(null_driver)
    t.assert_eq(null_driver, sm:get_driver(), "driver is set after init")
end)

t.test("init() with options sets volume and enabled", function()
    local sm = sound_mod.new()
    sm:init(null_driver, { volume = 0.5, enabled = false })
    t.assert_eq(0.5, sm:get_volume(), "volume set via options")
    t.assert_eq(false, sm:is_enabled(), "enabled set via options")
end)

t.test("shutdown() clears state without error", function()
    local sm = sound_mod.new()
    sm:init(null_driver)
    t.assert_no_error(function() sm:shutdown() end, "shutdown should not error")
    t.assert_nil(sm:get_driver(), "driver cleared after shutdown")
end)

----------------------------------------------------------------------------
-- Driver injection
----------------------------------------------------------------------------

t.suite("sound manager — driver injection")

t.test("set_driver() swaps driver", function()
    local sm = sound_mod.new()
    t.assert_nil(sm:get_driver(), "starts with nil driver")
    sm:set_driver(null_driver)
    t.assert_eq(null_driver, sm:get_driver(), "driver swapped to null_driver")
    sm:set_driver(nil)
    t.assert_nil(sm:get_driver(), "driver swapped back to nil")
end)

----------------------------------------------------------------------------
-- Play/stop with nil driver (no-op mode)
----------------------------------------------------------------------------

t.suite("sound manager — nil driver (no-op)")

t.test("play() with nil driver returns nil, no crash", function()
    local sm = sound_mod.new()
    t.assert_no_error(function()
        local result = sm:play("test.opus")
        t.assert_nil(result, "play returns nil with no driver")
    end, "play with nil driver should not crash")
end)

t.test("stop() with nil driver doesn't crash", function()
    local sm = sound_mod.new()
    t.assert_no_error(function() sm:stop(1) end, "stop should not crash")
end)

t.test("stop_by_owner() with nil driver doesn't crash", function()
    local sm = sound_mod.new()
    t.assert_no_error(function() sm:stop_by_owner("obj-1") end)
end)

t.test("trigger() with nil driver returns nil", function()
    local sm = sound_mod.new()
    local result = sm:trigger({ sounds = { on_verb_break = "break.opus" } }, "on_verb_break")
    t.assert_nil(result, "trigger returns nil with no driver")
end)

t.test("enter_room() with nil driver doesn't crash", function()
    local sm = sound_mod.new()
    t.assert_no_error(function() sm:enter_room({ id = "room-1" }) end)
end)

t.test("exit_room() with nil driver doesn't crash", function()
    local sm = sound_mod.new()
    t.assert_no_error(function() sm:exit_room({ id = "room-1" }) end)
end)

t.test("scan_object() with nil driver doesn't crash", function()
    local sm = sound_mod.new()
    t.assert_no_error(function() sm:scan_object({ id = "candle", sounds = { ambient = "drip.opus" } }) end)
end)

t.test("flush_queue() with nil driver doesn't crash", function()
    local sm = sound_mod.new()
    sm:scan_object({ id = "candle", sounds = { ambient = "drip.opus" } })
    t.assert_no_error(function() sm:flush_queue() end)
end)

----------------------------------------------------------------------------
-- Play/stop with mock driver
----------------------------------------------------------------------------

t.suite("sound manager — mock driver playback")

-- Mock driver that records all calls
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

t.test("play() calls driver.play()", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    local play_id = sm:play("door-creak.opus")
    t.assert_truthy(play_id, "play returns a play_id")
    -- Find the play call
    local found = false
    for _, c in ipairs(mock._calls) do
        if c.method == "play" and c.args[1] == "door-creak.opus" then
            found = true
        end
    end
    t.assert_truthy(found, "driver.play was called with correct filename")
end)

t.test("play() passes volume and loop to driver", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    sm:set_volume(0.7)
    sm:play("ambient.opus", { loop = true })
    local play_call = nil
    for _, c in ipairs(mock._calls) do
        if c.method == "play" then play_call = c end
    end
    t.assert_truthy(play_call, "play call found")
    t.assert_eq(true, play_call.args[2].loop, "loop option passed")
    t.assert_eq(0.7, play_call.args[2].volume, "volume passed to driver")
end)

t.test("stop() calls driver.stop()", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    local play_id = sm:play("test.opus")
    sm:stop(play_id)
    local found = false
    for _, c in ipairs(mock._calls) do
        if c.method == "stop" then found = true end
    end
    t.assert_truthy(found, "driver.stop was called")
end)

t.test("stop_by_owner() stops all sounds for an owner", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    sm:play("sound1.opus", { owner_id = "obj-a" })
    sm:play("sound2.opus", { owner_id = "obj-a" })
    sm:play("sound3.opus", { owner_id = "obj-b" })
    sm:stop_by_owner("obj-a")
    -- Count stop calls (should be 2 for obj-a)
    local stop_count = 0
    for _, c in ipairs(mock._calls) do
        if c.method == "stop" then stop_count = stop_count + 1 end
    end
    t.assert_eq(2, stop_count, "two sounds stopped for obj-a")
end)

----------------------------------------------------------------------------
-- Volume
----------------------------------------------------------------------------

t.suite("sound manager — volume")

t.test("set_volume() stores value", function()
    local sm = sound_mod.new()
    sm:set_volume(0.5)
    t.assert_eq(0.5, sm:get_volume(), "volume is 0.5")
end)

t.test("set_volume() clamps below 0.0", function()
    local sm = sound_mod.new()
    sm:set_volume(-0.5)
    t.assert_eq(0.0, sm:get_volume(), "volume clamped to 0.0")
end)

t.test("set_volume() clamps above 1.0", function()
    local sm = sound_mod.new()
    sm:set_volume(1.5)
    t.assert_eq(1.0, sm:get_volume(), "volume clamped to 1.0")
end)

t.test("set_volume() ignores non-number", function()
    local sm = sound_mod.new()
    sm:set_volume(0.8)
    sm:set_volume("loud")
    t.assert_eq(0.8, sm:get_volume(), "volume unchanged after non-number")
end)

t.test("set_volume() calls driver.set_master_volume()", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    sm:set_volume(0.6)
    local found = false
    for _, c in ipairs(mock._calls) do
        if c.method == "set_master_volume" and c.args[1] == 0.6 then
            found = true
        end
    end
    t.assert_truthy(found, "driver.set_master_volume called with 0.6")
end)

----------------------------------------------------------------------------
-- Mute / unmute
----------------------------------------------------------------------------

t.suite("sound manager — mute/unmute")

t.test("mute() sets muted state", function()
    local sm = sound_mod.new()
    sm:mute()
    t.assert_eq(true, sm:is_muted(), "muted after mute()")
end)

t.test("unmute() clears muted state", function()
    local sm = sound_mod.new()
    sm:mute()
    sm:unmute()
    t.assert_eq(false, sm:is_muted(), "not muted after unmute()")
end)

t.test("play() returns nil when muted", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    sm:mute()
    local result = sm:play("test.opus")
    t.assert_nil(result, "play returns nil when muted")
end)

t.test("mute preserves volume", function()
    local sm = sound_mod.new()
    sm:set_volume(0.7)
    sm:mute()
    t.assert_eq(0.7, sm:get_volume(), "volume preserved when muted")
    sm:unmute()
    t.assert_eq(0.7, sm:get_volume(), "volume still 0.7 after unmute")
end)

----------------------------------------------------------------------------
-- set_enabled
----------------------------------------------------------------------------

t.suite("sound manager — set_enabled")

t.test("set_enabled(false) disables sound", function()
    local sm = sound_mod.new()
    sm:set_enabled(false)
    t.assert_eq(false, sm:is_enabled(), "disabled after set_enabled(false)")
end)

t.test("play() returns nil when disabled", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    sm:set_enabled(false)
    local result = sm:play("test.opus")
    t.assert_nil(result, "play returns nil when disabled")
end)

----------------------------------------------------------------------------
-- scan_object
----------------------------------------------------------------------------

t.suite("sound manager — scan_object")

t.test("scan_object extracts sounds table", function()
    local sm = sound_mod.new()
    sm:init(null_driver)
    local obj = {
        guid = "abc-123",
        id = "candle",
        sounds = {
            on_verb_light = "candle-light.opus",
            ambient = "candle-crackle.opus",
        },
    }
    sm:scan_object(obj)
    -- Verify internal state
    t.assert_truthy(sm._object_sounds["abc-123"], "object sounds stored by guid")
    t.assert_eq("candle-light.opus", sm._object_sounds["abc-123"].on_verb_light)
    t.assert_eq("candle-crackle.opus", sm._object_sounds["abc-123"].ambient)
end)

t.test("scan_object no-ops on nil", function()
    local sm = sound_mod.new()
    t.assert_no_error(function() sm:scan_object(nil) end)
end)

t.test("scan_object no-ops on object without sounds", function()
    local sm = sound_mod.new()
    t.assert_no_error(function() sm:scan_object({ id = "rock" }) end)
end)

t.test("scan_object queues files for loading", function()
    local sm = sound_mod.new()
    sm:scan_object({ id = "candle", sounds = { ambient = "drip.opus" } })
    t.assert_eq(1, #sm._queue, "one file queued")
    t.assert_eq("drip.opus", sm._queue[1], "correct file queued")
end)

----------------------------------------------------------------------------
-- trigger (resolution chain)
----------------------------------------------------------------------------

t.suite("sound manager — trigger")

t.test("trigger resolves object-specific sound first", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    local obj = { id = "candle", sounds = { on_verb_light = "candle-ignite.opus" } }
    sm:trigger(obj, "on_verb_light")
    local found = false
    for _, c in ipairs(mock._calls) do
        if c.method == "play" and c.args[1] == "candle-ignite.opus" then
            found = true
        end
    end
    t.assert_truthy(found, "object-specific sound played")
end)

t.test("trigger falls back to defaults", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    local obj = { id = "door", sounds = {} }
    sm:trigger(obj, "on_verb_break")
    local found = false
    for _, c in ipairs(mock._calls) do
        if c.method == "play" and c.args[1] == "generic-break.opus" then
            found = true
        end
    end
    t.assert_truthy(found, "default fallback sound played")
end)

t.test("trigger returns nil for unknown event", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    local obj = { id = "rock", sounds = {} }
    local result = sm:trigger(obj, "on_verb_teleport")
    t.assert_nil(result, "unknown event returns nil (silent)")
end)

t.test("trigger handles nil obj gracefully", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    -- Falls back to defaults for on_verb_break
    local result = sm:trigger(nil, "on_verb_break")
    t.assert_truthy(result, "trigger with nil obj still uses defaults")
end)

t.test("trigger with nil event_key returns nil", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    local result = sm:trigger({ id = "test" }, nil)
    t.assert_nil(result, "nil event_key returns nil")
end)

----------------------------------------------------------------------------
-- Room transitions
----------------------------------------------------------------------------

t.suite("sound manager — room transitions")

t.test("enter_room starts ambient loop", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    local room = { id = "cellar", sounds = { ambient = "cellar-drip.opus" } }
    sm:enter_room(room)
    local found = false
    for _, c in ipairs(mock._calls) do
        if c.method == "play" and c.args[1] == "cellar-drip.opus" and c.args[2].loop == true then
            found = true
        end
    end
    t.assert_truthy(found, "ambient loop started on enter_room")
end)

t.test("exit_room stops room sounds", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    local room = { id = "cellar", sounds = { ambient = "cellar-drip.opus" } }
    sm:enter_room(room)
    sm:exit_room(room)
    local stop_count = 0
    for _, c in ipairs(mock._calls) do
        if c.method == "stop" then stop_count = stop_count + 1 end
    end
    t.assert_truthy(stop_count > 0, "sounds stopped on exit_room")
end)

t.test("enter_room with no sounds doesn't crash", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    t.assert_no_error(function() sm:enter_room({ id = "empty-room" }) end)
end)

t.test("enter_room with nil doesn't crash", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    t.assert_no_error(function() sm:enter_room(nil) end)
end)

----------------------------------------------------------------------------
-- Concurrency limits
----------------------------------------------------------------------------

t.suite("sound manager — concurrency limits")

t.test("5th one-shot evicts oldest", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    -- Fire 5 one-shots (max is 4)
    sm:play("s1.opus")
    sm:play("s2.opus")
    sm:play("s3.opus")
    sm:play("s4.opus")
    sm:play("s5.opus")
    -- Count active playing entries
    local active = 0
    for _ in pairs(sm._playing) do active = active + 1 end
    t.assert_eq(4, active, "only 4 one-shots active (oldest evicted)")
    -- Verify a stop was called (eviction)
    local stop_count = 0
    for _, c in ipairs(mock._calls) do
        if c.method == "stop" then stop_count = stop_count + 1 end
    end
    t.assert_truthy(stop_count >= 1, "at least one eviction stop call")
end)

t.test("4th ambient evicts oldest", function()
    local sm = sound_mod.new()
    local mock = make_mock_driver()
    sm:init(mock)
    -- Start 4 ambient loops (max is 3)
    sm:play("a1.opus", { loop = true })
    sm:play("a2.opus", { loop = true })
    sm:play("a3.opus", { loop = true })
    sm:play("a4.opus", { loop = true })
    local active_ambients = #sm._ambients
    t.assert_eq(3, active_ambients, "only 3 ambients active (oldest evicted)")
end)

----------------------------------------------------------------------------
-- Null driver integration
----------------------------------------------------------------------------

t.suite("sound manager — null driver integration")

t.test("full lifecycle with null driver", function()
    local sm = sound_mod.new()
    sm:init(null_driver)
    t.assert_no_error(function()
        sm:set_volume(0.5)
        sm:play("test.opus")
        sm:play("ambient.opus", { loop = true, owner_id = "room-1" })
        sm:stop_by_owner("room-1")
        sm:mute()
        sm:unmute()
        sm:trigger({ id = "obj", sounds = { on_verb_break = "b.opus" } }, "on_verb_break")
        sm:enter_room({ id = "room", sounds = { ambient = "a.opus" } })
        sm:exit_room({ id = "room" })
        sm:shutdown()
    end, "full lifecycle with null driver should not error")
end)

----------------------------------------------------------------------------
-- API surface verification (GATE-0 freeze)
----------------------------------------------------------------------------

t.suite("sound manager — GATE-0 API surface")

t.test("all frozen API methods exist", function()
    local sm = sound_mod.new()
    t.assert_truthy(sm.init, "init exists")
    t.assert_truthy(sm.shutdown, "shutdown exists")
    t.assert_truthy(sm.scan_object, "scan_object exists")
    t.assert_truthy(sm.flush_queue, "flush_queue exists")
    t.assert_truthy(sm.play, "play exists")
    t.assert_truthy(sm.stop, "stop exists")
    t.assert_truthy(sm.stop_by_owner, "stop_by_owner exists")
    t.assert_truthy(sm.enter_room, "enter_room exists")
    t.assert_truthy(sm.exit_room, "exit_room exists")
    t.assert_truthy(sm.unload_room, "unload_room exists")
    t.assert_truthy(sm.trigger, "trigger exists")
    t.assert_truthy(sm.set_volume, "set_volume exists")
    t.assert_truthy(sm.set_enabled, "set_enabled exists")
    t.assert_truthy(sm.mute, "mute exists")
    t.assert_truthy(sm.unmute, "unmute exists")
    t.assert_truthy(sm.set_driver, "set_driver exists")
    t.assert_truthy(sm.get_driver, "get_driver exists")
    t.assert_truthy(sm.get_volume, "get_volume exists")
    t.assert_truthy(sm.is_muted, "is_muted exists")
    t.assert_truthy(sm.is_enabled, "is_enabled exists")
end)

----------------------------------------------------------------------------

local exit_code = t.summary()
os.exit(exit_code == 0 and 0 or 1)
