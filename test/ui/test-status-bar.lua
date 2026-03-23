-- test/ui/test-status-bar.lua
-- Regression tests for the status bar (Issue #45).
-- Verifies: no inventory data shown, health shown only when injured,
-- room name and time always present.
--
-- Usage: lua test/ui/test-status-bar.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. package.path

local status_mod = require("engine.ui.status")

---------------------------------------------------------------------------
-- Test harness
---------------------------------------------------------------------------
local passed = 0
local failed = 0

local function assert_eq(actual, expected, label)
    if actual == expected then
        passed = passed + 1
        print("  PASS " .. label)
    else
        failed = failed + 1
        print("  FAIL " .. label)
        print("    expected: " .. tostring(expected))
        print("    actual:   " .. tostring(actual))
    end
end

local function assert_match(str, pattern, label)
    if str and str:match(pattern) then
        passed = passed + 1
        print("  PASS " .. label)
    else
        failed = failed + 1
        print("  FAIL " .. label)
        print("    expected pattern: " .. pattern)
        print("    actual string:    " .. tostring(str))
    end
end

local function assert_no_match(str, pattern, label)
    if not str or not str:match(pattern) then
        passed = passed + 1
        print("  PASS " .. label)
    else
        failed = failed + 1
        print("  FAIL " .. label)
        print("    should NOT match: " .. pattern)
        print("    actual string:    " .. tostring(str))
    end
end

---------------------------------------------------------------------------
-- Helpers — fake context
---------------------------------------------------------------------------
local function make_ctx(opts)
    opts = opts or {}
    local captured_left, captured_right
    return {
        game_start_time = os.time(),
        time_offset = 0,
        current_room = opts.room or { id = "start-room", name = "Dark Cellar" },
        player = opts.player or {
            hands = { nil, nil },
            worn = {},
            injuries = {},
            max_health = 100,
            state = {},
        },
        registry = {
            get = function(_, id)
                if opts.registry_objects then
                    return opts.registry_objects[id]
                end
                return nil
            end,
        },
        ui = {
            status = function(left, right)
                captured_left = left
                captured_right = right
            end,
        },
        get_left  = function() return captured_left end,
        get_right = function() return captured_right end,
    }
end

---------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------
print("== Status Bar Tests (Issue #45 regression) ==")

-- 1) No inventory keywords in the status bar at game start
do
    local ctx = make_ctx()
    local updater = status_mod.create_updater()
    updater(ctx)
    local left = ctx.get_left()
    local right = ctx.get_right()
    local combined = (left or "") .. (right or "")

    assert_no_match(combined, "[Mm]atch", "no 'match' in status bar at start")
    assert_no_match(combined, "[Cc]andle", "no 'candle' in status bar at start")
    assert_no_match(combined, "[Ii]nventory", "no 'inventory' in status bar at start")
end

-- 2) Room name appears in the status bar
do
    local ctx = make_ctx({ room = { id = "start-room", name = "Dark Cellar" } })
    local updater = status_mod.create_updater()
    updater(ctx)
    local left = ctx.get_left()

    assert_match(left, "DARK CELLAR", "room name shown (uppercased)")
end

-- 3) Level info appears for known rooms
do
    local ctx = make_ctx({ room = { id = "start-room", name = "Dark Cellar" } })
    local updater = status_mod.create_updater()
    updater(ctx)
    local left = ctx.get_left()

    assert_match(left, "Lv 1", "level number shown")
    assert_match(left, "The Awakening", "level name shown")
end

-- 4) Time appears in the status bar
do
    local ctx = make_ctx()
    local updater = status_mod.create_updater()
    updater(ctx)
    local left = ctx.get_left()

    assert_match(left, "%d+:%d+ [AP]M", "time shown in status bar")
end

-- 5) Health hidden when player is at full health
do
    local ctx = make_ctx({
        player = {
            hands = { nil, nil },
            worn = {},
            injuries = {},
            max_health = 100,
            state = {},
        },
    })
    local updater = status_mod.create_updater()
    updater(ctx)
    local right = ctx.get_right()

    assert_eq(right, "", "right side empty at full health")
end

-- 6) Health shown when player is injured
do
    local ctx = make_ctx({
        player = {
            hands = { nil, nil },
            worn = {},
            injuries = { { damage = 25, type = "cut", location = "arm" } },
            max_health = 100,
            state = {},
        },
    })
    local updater = status_mod.create_updater()
    updater(ctx)
    local right = ctx.get_right()

    assert_match(right, "Health: 75/100", "health shown when injured")
end

-- 7) Even with a matchbox in the registry, no match count shown
do
    local ctx = make_ctx({
        registry_objects = {
            matchbox = {
                id = "matchbox",
                container = true,
                contents = { "m1", "m2", "m3", "m4", "m5", "m6", "m7" },
                keywords = { "matchbox" },
            },
        },
    })
    local updater = status_mod.create_updater()
    updater(ctx)
    local right = ctx.get_right()
    local left = ctx.get_left()
    local combined = (left or "") .. (right or "")

    assert_no_match(combined, "7", "no '7' from matchbox contents in status bar")
    assert_no_match(combined, "[Mm]atch", "no 'match' even with matchbox in registry")
end

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
print("Results: " .. passed .. " passed, " .. failed .. " failed")
if failed > 0 then
    os.exit(1)
end
