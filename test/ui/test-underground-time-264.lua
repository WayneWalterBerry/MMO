-- test/ui/test-underground-time-264.lua
-- Regression tests for Issue #264: underground rooms should NOT show
-- time-of-day sky descriptions (dawn, dusk, etc.) or receive daylight.
--
-- Usage: lua test/ui/test-underground-time-264.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. package.path

local presentation = require("engine.ui.presentation")

---------------------------------------------------------------------------
-- Test harness (matches project pattern)
---------------------------------------------------------------------------
local passed = 0
local failed = 0
local errors = {}

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        print("  PASS " .. name)
    else
        failed = failed + 1
        print("  FAIL " .. name .. ": " .. tostring(err))
        errors[#errors + 1] = { name = name, err = tostring(err) }
    end
end

local function assert_eq(actual, expected, label)
    if actual ~= expected then
        error((label or "") .. " — expected: " .. tostring(expected) .. " got: " .. tostring(actual))
    end
end

local function assert_nil(val, label)
    if val ~= nil then
        error((label or "") .. " — expected nil, got: " .. tostring(val))
    end
end

local function assert_not_nil(val, label)
    if val == nil then
        error((label or "") .. " — expected non-nil, got nil")
    end
end

---------------------------------------------------------------------------
-- time_of_day_desc: sky_visible gating
---------------------------------------------------------------------------
print("\n=== #264 — time_of_day_desc sky_visible gating ===")

local dawn_hours = {5, 6}
local day_hours = {7, 10, 14}
local dusk_hours = {17, 18}
local night_hours = {19, 20, 22, 2}
local all_hours = {}
for _, h in ipairs(dawn_hours) do all_hours[#all_hours + 1] = h end
for _, h in ipairs(day_hours) do all_hours[#all_hours + 1] = h end
for _, h in ipairs(dusk_hours) do all_hours[#all_hours + 1] = h end
for _, h in ipairs(night_hours) do all_hours[#all_hours + 1] = h end

test("sky_visible=false suppresses all time descriptions", function()
    for _, hour in ipairs(all_hours) do
        local desc = presentation.time_of_day_desc(hour, false)
        assert_nil(desc, "hour " .. hour .. " with sky_visible=false")
    end
end)

test("sky_visible=nil suppresses all time descriptions", function()
    for _, hour in ipairs(all_hours) do
        local desc = presentation.time_of_day_desc(hour, nil)
        assert_nil(desc, "hour " .. hour .. " with sky_visible=nil")
    end
end)

test("sky_visible=true shows time descriptions", function()
    for _, hour in ipairs(all_hours) do
        local desc = presentation.time_of_day_desc(hour, true)
        assert_not_nil(desc, "hour " .. hour .. " with sky_visible=true")
    end
end)

---------------------------------------------------------------------------
-- get_light_level: underground rooms and artificial light
---------------------------------------------------------------------------
print("\n=== #264 — get_light_level underground room behavior ===")

local function make_registry(objects)
    return {
        get = function(self, id)
            return objects[id]
        end
    }
end

local function make_ctx(room, objects, hour_offset)
    return {
        current_room = room,
        registry = make_registry(objects or {}),
        game_start_time = os.time(),
        time_offset = (hour_offset or 0),
        player = {
            hands = { nil, nil },
            worn = {},
        },
    }
end

test("underground room stays dark during daytime (no daylight objects)", function()
    local room = {
        id = "cellar",
        sky_visible = false,
        contents = {},
    }
    -- Set time to noon (10 hours past 2 AM start)
    local ctx = make_ctx(room, {}, 10)
    local level = presentation.get_light_level(ctx)
    assert_eq(level, "dark", "cellar at noon should be dark")
end)

test("artificial light works in underground rooms", function()
    local room = {
        id = "cellar",
        sky_visible = false,
        contents = { "torch-01" },
    }
    local objects = {
        ["torch-01"] = { id = "torch-01", casts_light = true },
    }
    local ctx = make_ctx(room, objects, 10)
    local level = presentation.get_light_level(ctx)
    assert_eq(level, "lit", "cellar with lit torch should be lit")
end)

test("carried light works in underground rooms", function()
    local room = {
        id = "cellar",
        sky_visible = false,
        contents = {},
    }
    local objects = {
        ["candle-01"] = { id = "candle-01", casts_light = true },
    }
    local ctx = make_ctx(room, objects, 10)
    ctx.player.hands[1] = "candle-01"
    local level = presentation.get_light_level(ctx)
    assert_eq(level, "lit", "cellar with carried candle should be lit")
end)

---------------------------------------------------------------------------
-- Room data: verify underground rooms have sky_visible = false
---------------------------------------------------------------------------
print("\n=== #264 — room file sky_visible verification ===")

local underground_rooms = { "cellar", "deep-cellar", "storage-cellar", "crypt" }
for _, room_name in ipairs(underground_rooms) do
    test(room_name .. " has sky_visible = false", function()
        local path = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "rooms" .. SEP .. room_name .. ".lua"
        local f = io.open(path, "r")
        if not f then error("cannot open " .. path) end
        local source = f:read("*a")
        f:close()
        assert_not_nil(source:match("sky_visible%s*=%s*false"), room_name .. " must have sky_visible = false")
    end)
end

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("\n--- Results ---")
print("  Passed: " .. passed)
print("  Failed: " .. failed)
if #errors > 0 then
    print("\nFailures:")
    for _, e in ipairs(errors) do
        print("  - " .. e.name .. ": " .. e.err)
    end
end
os.exit(failed > 0 and 1 or 0)
