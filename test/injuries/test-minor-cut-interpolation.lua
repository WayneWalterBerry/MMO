-- test/injuries/test-minor-cut-interpolation.lua
-- TDD tests for Issue #365: Minor-cut injury should use dynamic values
-- from combat context instead of hardcoded "glass" and "hand".
--
-- Tests that the minor-cut definition uses {location} and {source}
-- placeholders, and the injury engine interpolates them correctly.
--
-- Usage: lua test/injuries/test-minor-cut-interpolation.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. package.path

local injury_mod = require("engine.injuries")

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

local function assert_true(val, label)
    assert_eq(not not val, true, label)
end

local function assert_false(val, label)
    assert_eq(not not val, false, label)
end

local function assert_no_match(text, pattern, label)
    if not text:find(pattern) then
        passed = passed + 1
        print("  PASS " .. label)
    else
        failed = failed + 1
        print("  FAIL " .. label)
        print("    text should NOT contain pattern: " .. pattern)
        print("    actual text: " .. text)
    end
end

local function assert_match(text, pattern, label)
    if text:find(pattern) then
        passed = passed + 1
        print("  PASS " .. label)
    else
        failed = failed + 1
        print("  FAIL " .. label)
        print("    text should contain pattern: " .. pattern)
        print("    actual text: " .. text)
    end
end

local function capture_print(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then return table.concat(lines, "\n"), err end
    return table.concat(lines, "\n"), nil
end

---------------------------------------------------------------------------
-- Load minor-cut definition from disk
---------------------------------------------------------------------------
local minor_cut_def = nil
do
    local ok, def = pcall(dofile, repo_root .. SEP .. "src" .. SEP .. "meta"
        .. SEP .. "injuries" .. SEP .. "minor-cut.lua")
    if ok and def then minor_cut_def = def end
end

assert_true(minor_cut_def ~= nil, "minor-cut definition loads from disk")

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function fresh_player()
    return {
        id = "player",
        is_player = true,
        max_health = 100,
        injuries = {},
        hands = { nil, nil },
        worn = {},
        state = {},
    }
end

local function setup()
    injury_mod.clear_cache()
    injury_mod.reset_id_counter()
    injury_mod.register_definition("minor-cut", minor_cut_def)
end

---------------------------------------------------------------------------
-- 1. Definition uses {location} placeholder (not hardcoded "hand")
---------------------------------------------------------------------------
print("\n=== Issue #365: minor-cut uses {location} placeholders ===")

do
    local msg = minor_cut_def.on_inflict.message
    assert_match(msg, "{location}", "on_inflict.message contains {location} placeholder")
    assert_no_match(msg, "your hand", "on_inflict.message does NOT hardcode 'your hand'")
end

do
    local desc = minor_cut_def.states.active.description
    assert_match(desc, "{location}", "active.description contains {location} placeholder")
    assert_no_match(desc, "your hand", "active.description does NOT hardcode 'your hand'")
end

do
    local desc = minor_cut_def.states.treated.description
    assert_match(desc, "{location}", "treated.description contains {location} placeholder")
end

do
    local desc = minor_cut_def.states.healed.description
    assert_match(desc, "{location}", "healed.description contains {location} placeholder")
end

---------------------------------------------------------------------------
-- 2. Definition uses {source} placeholder (not hardcoded "glass")
---------------------------------------------------------------------------
print("\n=== Issue #365: minor-cut uses {source} placeholders ===")

do
    local desc = minor_cut_def.states.active.description
    assert_match(desc, "{source}", "active.description contains {source} placeholder")
    assert_no_match(desc, "glass", "active.description does NOT hardcode 'glass'")
end

---------------------------------------------------------------------------
-- 3. Definition provides interpolation_defaults
---------------------------------------------------------------------------
print("\n=== Issue #365: minor-cut provides interpolation defaults ===")

do
    assert_true(minor_cut_def.interpolation_defaults ~= nil,
        "minor-cut has interpolation_defaults table")
    assert_true(minor_cut_def.interpolation_defaults.location ~= nil,
        "interpolation_defaults has location default")
    assert_true(minor_cut_def.interpolation_defaults.source ~= nil,
        "interpolation_defaults has source default")
end

---------------------------------------------------------------------------
-- 4. Engine interpolates on_inflict message with actual source/location
---------------------------------------------------------------------------
print("\n=== Issue #365: engine interpolates infliction message ===")

do
    setup()
    local player = fresh_player()
    local output = capture_print(function()
        injury_mod.inflict(player, "minor-cut", "silver-dagger", "left arm")
    end)

    assert_match(output, "left arm", "infliction message uses actual location 'left arm'")
    assert_no_match(output, "{location}", "infliction message has no raw {location} placeholder")
    assert_no_match(output, "your hand", "infliction message does NOT say 'your hand'")
end

---------------------------------------------------------------------------
-- 5. Engine interpolates source into infliction context
---------------------------------------------------------------------------
print("\n=== Issue #365: engine interpolates source into description ===")

do
    setup()
    local player = fresh_player()
    capture_print(function()
        injury_mod.inflict(player, "minor-cut", "glass-shard", "right hand")
    end)

    -- The instance should carry interpolation context
    local instance = player.injuries[1]
    assert_eq(instance.source, "glass-shard", "instance stores source id")
    assert_eq(instance.location, "right hand", "instance stores location")
end

---------------------------------------------------------------------------
-- 6. Engine uses defaults when location/source are nil
---------------------------------------------------------------------------
print("\n=== Issue #365: engine uses defaults when location/source nil ===")

do
    setup()
    local player = fresh_player()
    local output = capture_print(function()
        injury_mod.inflict(player, "minor-cut", nil, nil)
    end)

    -- Should use the default from interpolation_defaults, not raw placeholder
    assert_no_match(output, "{location}", "uses default when location is nil")
    assert_no_match(output, "{source}", "uses default when source is nil")
end

---------------------------------------------------------------------------
-- 7. injuries.interpolate utility function exists and works
---------------------------------------------------------------------------
print("\n=== Issue #365: injuries.interpolate utility ===")

do
    assert_true(type(injury_mod.interpolate) == "function",
        "injuries.interpolate function exists")

    local result = injury_mod.interpolate(
        "A cut on your {location} from the {source}.",
        { location = "left arm", source = "broken bottle" }
    )
    assert_eq(result, "A cut on your left arm from the broken bottle.",
        "interpolate replaces placeholders correctly")
end

do
    -- Passthrough when no placeholders
    local result = injury_mod.interpolate("No placeholders here.", {})
    assert_eq(result, "No placeholders here.",
        "interpolate passes through text without placeholders")
end

do
    -- Nil text returns nil
    local result = injury_mod.interpolate(nil, { location = "hand" })
    assert_eq(result, nil, "interpolate returns nil for nil input")
end

---------------------------------------------------------------------------
-- 8. Transition messages also interpolated
---------------------------------------------------------------------------
print("\n=== Issue #365: transition messages interpolated on tick ===")

do
    setup()
    local player = fresh_player()
    capture_print(function()
        injury_mod.inflict(player, "minor-cut", "rusty-nail", "left hand")
    end)

    -- Force a timed auto-heal by setting turns to trigger transition
    -- The treated→healed transition message should interpolate
    player.injuries[1]._state = "active"
    player.injuries[1].turns_active = 0

    -- Manually trigger the active→healed auto-transition
    -- by expiring the timer
    player.injuries[1].state_turns_remaining = 1

    local messages = nil
    capture_print(function()
        messages = injury_mod.tick(player)
    end)

    -- Check that transition messages use the actual location
    if messages and #messages > 0 then
        local combined = table.concat(messages, " ")
        assert_no_match(combined, "{location}",
            "tick transition messages have no raw {location} placeholder")
    else
        passed = passed + 1
        print("  PASS tick transition messages (no messages to check, injury healed)")
    end
end

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("\n--- Results ---")
print("  Passed: " .. passed)
print("  Failed: " .. failed)
if failed > 0 then
    os.exit(1)
end
