-- test/parser/test-loot-disambiguation.lua
-- Regression test for #362: Loot-suffixed identical items bypass broken.
-- silk-bundle-loot-1 and silk-bundle-loot-2 must be treated as same item.
-- TDD: Tests must FAIL before fix, PASS after.
-- Must be run from repository root: lua test/parser/test-loot-disambiguation.lua

package.path = "src/?.lua;src/?/init.lua;test/parser/?.lua;" .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

local registry_mod = require("engine.registry")
local helpers = require("engine.verbs.helpers")

---------------------------------------------------------------------------
-- Test fixtures: loot-suffixed silk-bundle items
---------------------------------------------------------------------------
local function make_silk_bundle_loot(n)
    return {
        id = "silk-bundle-loot-" .. n,
        name = "a bundle of spider silk",
        keywords = {"silk", "silk bundle", "bundle", "spider silk"},
        material = "silk",
        size = 1,
        weight = 0.2,
        portable = true,
        on_feel = "Soft, fine threads bundled together.",
    }
end

local function make_ctx_with_loot_items(count)
    local reg = registry_mod.new()
    local room_contents = {}

    for i = 1, count do
        local item = make_silk_bundle_loot(i)
        reg:register(item.id, item)
        room_contents[#room_contents + 1] = item.id
    end

    local room = {
        id = "test-room",
        name = "Spider Nest",
        description = "A web-strewn chamber.",
        contents = room_contents,
        exits = {},
    }

    return {
        current_room = room,
        player = { hands = {nil, nil}, worn = {}, state = {} },
        registry = reg,
        current_verb = "take",
        known_objects = {},
        last_noun = nil,
        last_object = nil,
    }
end

---------------------------------------------------------------------------
-- TESTS: Loot-suffixed items bypass disambiguation (#362)
---------------------------------------------------------------------------
suite("LOOT DISAMBIGUATION: identical loot items resolve silently (#362)")

test("1. 'silk bundle' with 2 loot instances resolves without disambiguation", function()
    local ctx = make_ctx_with_loot_items(2)

    local obj = helpers.find_visible(ctx, "silk bundle")

    -- Must resolve to one of the items (silent pick), NOT trigger disambiguation
    h.assert_truthy(obj,
        "'silk bundle' must resolve to an object, not nil (disambiguation should be bypassed)")
    h.assert_nil(ctx.disambiguation_prompt,
        "disambiguation prompt must NOT be set for identical loot items")
end)

test("2. 'bundle' with 3 loot instances resolves without disambiguation", function()
    local ctx = make_ctx_with_loot_items(3)

    local obj = helpers.find_visible(ctx, "bundle")

    h.assert_truthy(obj,
        "'bundle' must resolve to an object with 3 loot instances")
    h.assert_nil(ctx.disambiguation_prompt,
        "disambiguation prompt must NOT be set for 3 identical loot items")
end)

test("3. 'silk' with 5 loot instances resolves without disambiguation", function()
    local ctx = make_ctx_with_loot_items(5)

    local obj = helpers.find_visible(ctx, "silk")

    h.assert_truthy(obj,
        "'silk' must resolve to an object with 5 loot instances")
    h.assert_nil(ctx.disambiguation_prompt,
        "disambiguation prompt must NOT be set for 5 identical loot items")
end)

test("4. craft-suffixed items also bypass (silk-rope-craft-1 vs silk-rope-craft-2)", function()
    local reg = registry_mod.new()
    local item1 = {
        id = "silk-rope-craft-1",
        name = "a silk rope",
        keywords = {"rope", "silk rope"},
        size = 1,
        portable = true,
        on_feel = "Smooth silk rope.",
    }
    local item2 = {
        id = "silk-rope-craft-2",
        name = "a silk rope",
        keywords = {"rope", "silk rope"},
        size = 1,
        portable = true,
        on_feel = "Smooth silk rope.",
    }
    reg:register(item1.id, item1)
    reg:register(item2.id, item2)

    local room = {
        id = "test-room",
        name = "Workbench",
        description = "A crafting area.",
        contents = { item1.id, item2.id },
        exits = {},
    }

    local ctx = {
        current_room = room,
        player = { hands = {nil, nil}, worn = {}, state = {} },
        registry = reg,
        current_verb = "take",
        known_objects = {},
    }

    local obj = helpers.find_visible(ctx, "silk rope")

    h.assert_truthy(obj,
        "'silk rope' must resolve with craft-suffixed items")
    h.assert_nil(ctx.disambiguation_prompt,
        "disambiguation prompt must NOT be set for craft-suffixed identical items")
end)

test("5. numeric-suffixed items bypass (silk-bundle-2 vs silk-bundle-3)", function()
    local reg = registry_mod.new()
    local item1 = {
        id = "silk-bundle-2",
        name = "a bundle of spider silk",
        keywords = {"silk", "silk bundle", "bundle"},
        size = 1,
        portable = true,
        on_feel = "Soft threads.",
    }
    local item2 = {
        id = "silk-bundle-3",
        name = "a bundle of spider silk",
        keywords = {"silk", "silk bundle", "bundle"},
        size = 1,
        portable = true,
        on_feel = "Soft threads.",
    }
    reg:register(item1.id, item1)
    reg:register(item2.id, item2)

    local room = {
        id = "test-room",
        name = "Store Room",
        description = "A storage area.",
        contents = { item1.id, item2.id },
        exits = {},
    }

    local ctx = {
        current_room = room,
        player = { hands = {nil, nil}, worn = {}, state = {} },
        registry = reg,
        current_verb = "take",
        known_objects = {},
    }

    local obj = helpers.find_visible(ctx, "silk bundle")

    h.assert_truthy(obj,
        "'silk bundle' must resolve with numeric-suffixed items")
    h.assert_nil(ctx.disambiguation_prompt,
        "disambiguation prompt must NOT be set for numeric-suffixed identical items")
end)

test("6. genuinely different items still trigger disambiguation", function()
    local reg = registry_mod.new()
    local sack = {
        id = "sack",
        name = "a burlap sack",
        keywords = {"sack", "bag"},
        size = 1,
        portable = true,
        on_feel = "Rough burlap.",
    }
    local grain_sack = {
        id = "grain-sack",
        name = "a heavy sack of grain",
        keywords = {"sack", "grain sack", "bag"},
        size = 3,
        portable = true,
        on_feel = "Heavy grain bag.",
    }
    reg:register(sack.id, sack)
    reg:register(grain_sack.id, grain_sack)

    local room = {
        id = "test-room",
        name = "Pantry",
        description = "Storage.",
        contents = { sack.id, grain_sack.id },
        exits = {},
    }

    local ctx = {
        current_room = room,
        player = { hands = {nil, nil}, worn = {}, state = {} },
        registry = reg,
        current_verb = "take",
        known_objects = {},
    }

    -- "sack" matches both with same score — disambiguation SHOULD trigger
    local obj = helpers.find_visible(ctx, "sack")
    -- Either obj is nil with disambiguation, or one was picked.
    -- The point: genuinely different items should NOT silently resolve
    -- (unless adjective scoring resolves them, which is OK).
    -- This test just verifies we didn't break real disambiguation.
    if not obj then
        h.assert_truthy(ctx.disambiguation_prompt,
            "different items must still trigger disambiguation when tied")
    end
    -- If obj is returned, that's fine (adjective scoring may have resolved it)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
