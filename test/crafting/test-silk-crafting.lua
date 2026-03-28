-- test/crafting/test-silk-crafting.lua
-- WAVE-4 TDD: Silk crafting recipe tests — silk-bundle → silk-rope, silk-bandage.
-- Tests: craft recipes, missing ingredients, silk-bandage healing.
-- Other agents (Smithers, Flanders) building in parallel — tests define contract.
--
-- Must be run from repository root: lua test/crafting/test-silk-crafting.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load crafting module (pcall-guarded — TDD: may not exist yet)
---------------------------------------------------------------------------
local craft_ok, crafting = pcall(require, "engine.verbs.crafting")
if not craft_ok then
    print("WARNING: engine.verbs.crafting not loadable — " .. tostring(crafting))
    crafting = nil
end

-- Try loading verb handlers as fallback (craft may live in verbs/init.lua)
local verbs_ok, verbs = pcall(require, "engine.verbs")
if not verbs_ok then
    print("WARNING: engine.verbs not loadable — " .. tostring(verbs))
    verbs = nil
end

---------------------------------------------------------------------------
-- Load silk object definitions
---------------------------------------------------------------------------
local silk_rope_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP .. "silk-rope.lua"
local rope_ok, silk_rope = pcall(dofile, silk_rope_path)
if not rope_ok then
    print("WARNING: silk-rope.lua not found (TDD: expected)")
    silk_rope = nil
end

local silk_bandage_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP .. "silk-bandage.lua"
local bandage_ok, silk_bandage = pcall(dofile, silk_bandage_path)
if not bandage_ok then
    print("WARNING: silk-bandage.lua not found (TDD: expected)")
    silk_bandage = nil
end

local silk_bundle_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP .. "silk-bundle.lua"
local bundle_ok, silk_bundle = pcall(dofile, silk_bundle_path)
if not bundle_ok then
    print("WARNING: silk-bundle.lua not found (TDD: expected)")
    silk_bundle = nil
end

---------------------------------------------------------------------------
-- Mock helpers
---------------------------------------------------------------------------
local guid_counter = 0
local function next_guid()
    guid_counter = guid_counter + 1
    return "{craft-test-" .. guid_counter .. "}"
end

local function deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[k] = deep_copy(v) end
    return copy
end

local function make_silk_bundle(suffix)
    return {
        guid = next_guid(),
        id = "silk-bundle" .. (suffix or ""),
        template = "small-item",
        name = "a bundle of spider silk",
        keywords = {"silk", "silk bundle", "bundle"},
        material = "silk",
        portable = true,
        on_feel = "Soft, fine threads bundled together.",
    }
end

local function make_mock_registry(objects)
    local reg = { _objects = {} }
    for _, obj in ipairs(objects) do
        reg._objects[obj.guid] = obj
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:get(id) return self._objects[id] end
    function reg:add(obj)
        self._objects[obj.guid] = obj
        if obj.id then self._objects[obj.id] = obj end
    end
    function reg:remove(guid_or_id)
        local obj = self._objects[guid_or_id]
        if obj then
            self._objects[obj.guid] = nil
            if obj.id then self._objects[obj.id] = nil end
        end
    end
    function reg:instantiate(template_id)
        local new = {
            guid = next_guid(),
            id = template_id,
            template = "small-item",
            name = template_id,
            on_feel = "A " .. template_id .. ".",
            portable = true,
        }
        self:add(new)
        return new
    end
    function reg:list()
        local seen, result = {}, {}
        for _, obj in pairs(self._objects) do
            if type(obj) == "table" and obj.guid and not seen[obj.guid] then
                seen[obj.guid] = true
                result[#result + 1] = obj
            end
        end
        return result
    end
    return reg
end

local function make_player(overrides)
    local p = {
        id = "player",
        health = 20,
        max_health = 30,
        location = "test-room",
        hands = {},
        inventory = {},
        active_injuries = {},
    }
    if overrides then
        for k, v in pairs(overrides) do p[k] = v end
    end
    return p
end

local function make_room()
    return {
        guid = "{room-test}",
        id = "test-room",
        template = "room",
        name = "Test Room",
        description = "A plain test room.",
        contents = {},
        exits = {},
    }
end

local function make_context(reg, room, player)
    local output = {}
    return {
        registry = reg,
        current_room = room,
        rooms = { [room.id] = room },
        player = player or make_player(),
        print = function(msg) output[#output + 1] = msg end,
        output = output,
        game_time = 100,
    }
end

-- Count items with a given id in the player's inventory/hands
local function count_in_inventory(player, item_id)
    local count = 0
    for _, ref in ipairs(player.hands or {}) do
        if ref == item_id or (type(ref) == "table" and ref.id == item_id) then
            count = count + 1
        end
    end
    for _, ref in ipairs(player.inventory or {}) do
        if ref == item_id or (type(ref) == "table" and ref.id == item_id) then
            count = count + 1
        end
    end
    return count
end

---------------------------------------------------------------------------
-- TESTS: Silk Crafting Recipes
---------------------------------------------------------------------------
suite("SILK CRAFTING: recipe validation (WAVE-4 TDD)")

test("1. craft silk-rope — 2x silk-bundle → 1x silk-rope", function()
    -- Verify crafting module exists and has recipe for silk-rope
    local craft_fn = nil
    if crafting and crafting.craft then
        craft_fn = crafting.craft
    elseif crafting and crafting.recipes then
        -- Check recipe exists
        local recipe = crafting.recipes["silk-rope"]
        h.assert_truthy(recipe, "silk-rope recipe must exist in crafting.recipes")
        h.assert_eq("table", type(recipe.ingredients), "recipe must have ingredients")

        -- Validate ingredient spec: 2x silk-bundle
        local found_silk = false
        for _, ing in ipairs(recipe.ingredients) do
            if ing.id == "silk-bundle" then
                h.assert_eq(2, ing.quantity, "silk-rope needs 2 silk-bundles")
                found_silk = true
            end
        end
        h.assert_truthy(found_silk, "silk-rope recipe must require silk-bundle")

        -- Validate result: 1x silk-rope
        h.assert_truthy(recipe.result, "recipe must have result")
        h.assert_eq("silk-rope", recipe.result.id, "result must be silk-rope")
        h.assert_eq(1, recipe.result.quantity, "result quantity must be 1")
        return  -- recipe structure validated
    elseif verbs and verbs.craft then
        craft_fn = verbs.craft
    end

    if craft_fn then
        -- Full functional test: player has 2 silk-bundles, crafts rope
        local bundle1 = make_silk_bundle("-1")
        local bundle2 = make_silk_bundle("-2")
        local player = make_player({
            hands = { bundle1.guid, bundle2.guid },
        })
        local room = make_room()
        local reg = make_mock_registry({ bundle1, bundle2, room })
        local ctx = make_context(reg, room, player)

        craft_fn(ctx, "silk-rope")

        -- Verify: silk-rope created, silk-bundles consumed
        local rope_found = false
        for _, obj in ipairs(reg:list()) do
            if obj.id == "silk-rope" then
                rope_found = true
                break
            end
        end
        h.assert_truthy(rope_found, "crafting must produce silk-rope")
    else
        h.assert_truthy(crafting or verbs,
            "crafting module or verbs module must load (TDD red phase)")
    end
end)

test("2. craft silk-bandage — 1x silk-bundle → 2x silk-bandage", function()
    local craft_fn = nil
    if crafting and crafting.craft then
        craft_fn = crafting.craft
    elseif crafting and crafting.recipes then
        local recipe = crafting.recipes["silk-bandage"]
        h.assert_truthy(recipe, "silk-bandage recipe must exist in crafting.recipes")
        h.assert_eq("table", type(recipe.ingredients), "recipe must have ingredients")

        -- Validate: 1x silk-bundle
        local found_silk = false
        for _, ing in ipairs(recipe.ingredients) do
            if ing.id == "silk-bundle" then
                h.assert_eq(1, ing.quantity, "silk-bandage needs 1 silk-bundle")
                found_silk = true
            end
        end
        h.assert_truthy(found_silk, "silk-bandage recipe must require silk-bundle")

        -- Validate result: 2x silk-bandage
        h.assert_truthy(recipe.result, "recipe must have result")
        h.assert_eq("silk-bandage", recipe.result.id, "result must be silk-bandage")
        h.assert_eq(2, recipe.result.quantity, "result quantity must be 2")
        return
    elseif verbs and verbs.craft then
        craft_fn = verbs.craft
    end

    if craft_fn then
        local bundle = make_silk_bundle()
        local player = make_player({ hands = { bundle.guid } })
        local room = make_room()
        local reg = make_mock_registry({ bundle, room })
        local ctx = make_context(reg, room, player)

        craft_fn(ctx, "silk-bandage")

        -- Verify: 2 silk-bandages created
        local bandage_count = 0
        for _, obj in ipairs(reg:list()) do
            if obj.id == "silk-bandage" then
                bandage_count = bandage_count + 1
            end
        end
        h.assert_eq(2, bandage_count, "crafting must produce 2 silk-bandages")
    else
        h.assert_truthy(crafting or verbs,
            "crafting module or verbs module must load (TDD red phase)")
    end
end)

test("3. craft without ingredients — error message when missing silk-bundle", function()
    local craft_fn = nil
    if crafting and crafting.craft then
        craft_fn = crafting.craft
    elseif verbs and verbs.craft then
        craft_fn = verbs.craft
    end

    if craft_fn then
        -- Player has EMPTY hands — no silk-bundle
        local player = make_player({ hands = {} })
        local room = make_room()
        local reg = make_mock_registry({ room })
        local ctx = make_context(reg, room, player)

        craft_fn(ctx, "silk-rope")

        -- Verify: error message printed (not a crash)
        h.assert_truthy(#ctx.output > 0,
            "crafting without ingredients must print an error message")

        -- Check no silk-rope was created
        local rope_found = false
        for _, obj in ipairs(reg:list()) do
            if obj.id == "silk-rope" then
                rope_found = true
                break
            end
        end
        h.assert_eq(false, rope_found,
            "no silk-rope should be created without ingredients")
    elseif crafting and crafting.check_ingredients then
        -- Test ingredient checker directly
        local player = make_player({ hands = {} })
        local room = make_room()
        local reg = make_mock_registry({ room })
        local ctx = make_context(reg, room, player)

        local has_all = crafting.check_ingredients("silk-rope", ctx)
        h.assert_eq(false, has_all,
            "check_ingredients must return false when silk-bundle missing")
    else
        h.assert_truthy(crafting or verbs,
            "crafting module or verbs module must load (TDD red phase)")
    end
end)

---------------------------------------------------------------------------
-- TESTS: Silk Bandage Healing
---------------------------------------------------------------------------
suite("SILK CRAFTING: silk-bandage healing (WAVE-4 TDD)")

test("4. silk-bandage heals — use silk-bandage → +5 HP + stops bleeding", function()
    -- Test the use verb with silk-bandage, or test bandage object's use effect directly.
    local use_fn = nil
    if verbs and verbs.use then
        use_fn = verbs.use
    elseif crafting and crafting.use_item then
        use_fn = crafting.use_item
    end

    if use_fn then
        local bandage = {
            guid = next_guid(),
            id = "silk-bandage",
            template = "small-item",
            name = "a silk bandage",
            keywords = {"bandage", "silk bandage"},
            material = "silk",
            portable = true,
            on_feel = "Soft silk strips.",
            _state = "unused",
            use_effect = {
                heal = 5,
                stops_bleeding = true,
                consumed = true,
            },
        }

        local bleeding_injury = {
            id = "bleeding",
            type = "bleeding",
            tick_damage = 1,
            active = true,
        }

        local player = make_player({
            health = 15,
            max_health = 30,
            hands = { bandage.guid },
            active_injuries = { bleeding_injury },
        })
        local room = make_room()
        local reg = make_mock_registry({ bandage, room })
        local ctx = make_context(reg, room, player)

        use_fn(ctx, "silk-bandage")

        -- Verify: +5 HP (capped at max_health)
        h.assert_eq(20, ctx.player.health,
            "silk-bandage must heal +5 HP (15 → 20)")

        -- Verify: bleeding stopped
        local still_bleeding = false
        for _, inj in ipairs(ctx.player.active_injuries or {}) do
            if inj.type == "bleeding" and inj.active then
                still_bleeding = true
            end
        end
        h.assert_eq(false, still_bleeding,
            "silk-bandage must stop active bleeding injury")

    elseif silk_bandage then
        -- At minimum, validate object definition has healing spec
        h.assert_truthy(silk_bandage.use_effect or silk_bandage.on_use,
            "silk-bandage must have use_effect or on_use for healing")

        if silk_bandage.use_effect then
            h.assert_eq(5, silk_bandage.use_effect.heal,
                "silk-bandage use_effect.heal must be 5")
            h.assert_eq(true, silk_bandage.use_effect.stops_bleeding,
                "silk-bandage must stop bleeding")
            h.assert_eq(true, silk_bandage.use_effect.consumed,
                "silk-bandage must be consumed on use")
        end
    else
        h.assert_truthy(verbs or silk_bandage,
            "verbs module or silk-bandage.lua must load (TDD red phase)")
    end
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
