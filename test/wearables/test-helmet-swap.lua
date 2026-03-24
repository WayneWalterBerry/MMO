-- test/wearables/test-helmet-swap.lua
-- Phase C1: Helmet conflict and swap tests (ceramic pot + brass spittoon).
--
-- Tests the wear/remove/swap cycle for two head-slot items, verifying:
--   1. Wear ceramic pot → on head, provides protection
--   2. Try to wear brass spittoon WHILE pot is worn → rejection
--   3. Remove pot → head is free
--   4. Wear spittoon → on head
--   5. Full swap cycle: pot on → pot off → spittoon on → spittoon off → pot on
--   6. Different protection values (brass vs ceramic)
--   7. Brass spittoon does NOT shatter on head hit (low fragility 0.1)
--   8. Ceramic pot DOES crack on strong head hit (high fragility 0.7)
--
-- Usage: lua test/wearables/test-helmet-swap.lua
-- Must be run from the repository root.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../../test/parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")

-- Armor + materials for protection / fragility tests
local armor_ok, armor = pcall(require, "engine.armor")
local effects_ok, effects = pcall(require, "engine.effects")
local injuries_ok, injuries = pcall(require, "engine.injuries")
local materials_ok, materials = pcall(require, "engine.materials")

local test   = h.test
local eq     = h.assert_eq
local truthy = h.assert_truthy

local handlers = verbs_mod.create()

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function capture_output(fn)
    local captured = {}
    local old_print = print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        captured[#captured + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Handler call failed: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

local function suppress_print(fn)
    local old_print = _G.print
    _G.print = function() end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error(err, 2) end
end

local function make_registry(objects)
    return {
        _objects = objects,
        get = function(self, id) return self._objects[id] end,
        remove = function(self, id) self._objects[id] = nil end,
    }
end

local function make_pot()
    return {
        id = "chamber-pot",
        name = "a ceramic chamber pot",
        material = "ceramic",
        keywords = {"chamber pot", "pot", "ceramic pot", "helmet"},
        portable = true, size = 2, weight = 3,
        container = true, capacity = 2, contents = {},
        wear_slot = "head", is_helmet = true,
        wear = {
            slot = "head", layer = "outer",
            coverage = 0.8, fit = "makeshift",
            wear_quality = "makeshift",
        },
        event_output = { on_wear = "This is going to smell worse than I thought." },
        _state = "intact",
        location = "player",
    }
end

local function make_spittoon()
    return {
        id = "brass-spittoon",
        name = "a brass spittoon",
        material = "brass",
        keywords = {"spittoon", "brass spittoon", "brass bowl", "helmet"},
        portable = true, size = 2, weight = 4,
        container = true, capacity = 2, contents = {},
        wear_slot = "head", is_helmet = true,
        reduces_unconsciousness = 1,
        wear = {
            slot = "head", layer = "outer",
            coverage = 0.7, fit = "makeshift",
            provides_armor = 2, wear_quality = "makeshift",
        },
        _state = "clean",
        location = "player",
    }
end

local function make_ctx(objects, room_contents)
    local reg = make_registry(objects)
    return {
        registry = reg,
        current_room = {
            id = "test-room", name = "Test Room",
            description = "A room for testing helmet swaps.",
            contents = room_contents or {},
            exits = {},
        },
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, bags = {}, worn_items = {} },
        injuries = {},
    }
end

local function is_worn(ctx, obj_id)
    for _, id in ipairs(ctx.player.worn or {}) do
        if id == obj_id then return true end
    end
    return false
end

local function worn_on_slot(ctx, slot)
    local reg = ctx.registry
    for _, id in ipairs(ctx.player.worn or {}) do
        local obj = reg:get(id)
        if obj and obj.wear and obj.wear.slot == slot then
            return obj
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Suite 1: Wear ceramic pot
---------------------------------------------------------------------------
h.suite("Helmet Swap: Wear ceramic pot")

test("wear ceramic pot → equipped on head", function()
    local pot = make_pot()
    local ctx = make_ctx({ ["chamber-pot"] = pot })
    ctx.player.hands[1] = pot

    capture_output(function() handlers["wear"](ctx, "pot") end)

    truthy(is_worn(ctx, "chamber-pot"),
        "ceramic pot should be in player.worn")
    local head_item = worn_on_slot(ctx, "head")
    truthy(head_item and head_item.id == "chamber-pot",
        "ceramic pot should occupy the head slot")
end)

test("wear ceramic pot → hand is freed", function()
    local pot = make_pot()
    local ctx = make_ctx({ ["chamber-pot"] = pot })
    ctx.player.hands[1] = pot

    capture_output(function() handlers["wear"](ctx, "pot") end)

    eq(nil, ctx.player.hands[1],
        "hand should be empty after wearing pot")
end)

test("wear ceramic pot → provides makeshift armor message", function()
    local pot = make_pot()
    local ctx = make_ctx({ ["chamber-pot"] = pot })
    ctx.player.hands[1] = pot

    local output = capture_output(function() handlers["wear"](ctx, "pot") end)
    local lower = output:lower()

    truthy(lower:find("helmet") or lower:find("head") or lower:find("tougher") or lower:find("put"),
        "should mention wearing on head. Output: " .. output)
end)

---------------------------------------------------------------------------
-- Suite 2: Slot conflict — second helmet rejected
---------------------------------------------------------------------------
h.suite("Helmet Swap: Slot conflict rejection")

test("wear spittoon while pot is worn → rejection", function()
    local pot = make_pot()
    local spittoon = make_spittoon()
    local ctx = make_ctx({
        ["chamber-pot"] = pot,
        ["brass-spittoon"] = spittoon,
    })
    ctx.player.hands[1] = pot
    capture_output(function() handlers["wear"](ctx, "pot") end)

    -- Now put spittoon in hand and try to wear
    ctx.player.hands[1] = spittoon
    spittoon.location = "player"
    local output = capture_output(function()
        handlers["wear"](ctx, "spittoon")
    end)

    local lower = output:lower()
    truthy(lower:find("already wearing") or lower:find("remove"),
        "should reject with 'already wearing' or 'remove it first'. Output: " .. output)
    truthy(not is_worn(ctx, "brass-spittoon"),
        "spittoon should NOT be in player.worn")
end)

test("wear pot while spittoon is worn → rejection", function()
    local pot = make_pot()
    local spittoon = make_spittoon()
    local ctx = make_ctx({
        ["chamber-pot"] = pot,
        ["brass-spittoon"] = spittoon,
    })
    ctx.player.hands[1] = spittoon
    capture_output(function() handlers["wear"](ctx, "spittoon") end)

    ctx.player.hands[1] = pot
    pot.location = "player"
    local output = capture_output(function()
        handlers["wear"](ctx, "pot")
    end)

    local lower = output:lower()
    truthy(lower:find("already wearing") or lower:find("remove"),
        "should reject with 'already wearing'. Output: " .. output)
    truthy(not is_worn(ctx, "chamber-pot"),
        "pot should NOT be in player.worn")
end)

---------------------------------------------------------------------------
-- Suite 3: Remove → head free
---------------------------------------------------------------------------
h.suite("Helmet Swap: Remove frees head slot")

test("remove pot → head is free", function()
    local pot = make_pot()
    local ctx = make_ctx({ ["chamber-pot"] = pot })
    ctx.player.hands[1] = pot
    capture_output(function() handlers["wear"](ctx, "pot") end)
    capture_output(function() handlers["remove"](ctx, "pot") end)

    truthy(not is_worn(ctx, "chamber-pot"),
        "pot should not be in player.worn after remove")
    eq(nil, worn_on_slot(ctx, "head"),
        "head slot should be free after remove")
end)

test("remove pot → pot returns to hand", function()
    local pot = make_pot()
    local ctx = make_ctx({ ["chamber-pot"] = pot })
    ctx.player.hands[1] = pot
    capture_output(function() handlers["wear"](ctx, "pot") end)
    capture_output(function() handlers["remove"](ctx, "pot") end)

    local in_hand = (ctx.player.hands[1] and ctx.player.hands[1].id == "chamber-pot")
                 or (ctx.player.hands[2] and ctx.player.hands[2].id == "chamber-pot")
    truthy(in_hand, "pot should be in a hand after remove")
end)

---------------------------------------------------------------------------
-- Suite 4: Wear spittoon after removal
---------------------------------------------------------------------------
h.suite("Helmet Swap: Wear spittoon after pot removed")

test("wear spittoon after pot removed → on head", function()
    local pot = make_pot()
    local spittoon = make_spittoon()
    local ctx = make_ctx({
        ["chamber-pot"] = pot,
        ["brass-spittoon"] = spittoon,
    })

    -- Wear pot
    ctx.player.hands[1] = pot
    capture_output(function() handlers["wear"](ctx, "pot") end)

    -- Remove pot
    capture_output(function() handlers["remove"](ctx, "pot") end)

    -- Drop pot to free hand for spittoon
    capture_output(function() handlers["drop"](ctx, "pot") end)

    -- Wear spittoon
    ctx.player.hands[1] = spittoon
    spittoon.location = "player"
    capture_output(function() handlers["wear"](ctx, "spittoon") end)

    truthy(is_worn(ctx, "brass-spittoon"),
        "spittoon should be in player.worn")
    local head_item = worn_on_slot(ctx, "head")
    truthy(head_item and head_item.id == "brass-spittoon",
        "spittoon should occupy head slot")
end)

---------------------------------------------------------------------------
-- Suite 5: Full swap cycle
---------------------------------------------------------------------------
h.suite("Helmet Swap: Full cycle (pot→off→spittoon→off→pot)")

test("full swap cycle completes without error", function()
    local pot = make_pot()
    local spittoon = make_spittoon()
    local ctx = make_ctx({
        ["chamber-pot"] = pot,
        ["brass-spittoon"] = spittoon,
    })

    -- Step 1: Wear pot
    ctx.player.hands[1] = pot
    capture_output(function() handlers["wear"](ctx, "pot") end)
    truthy(is_worn(ctx, "chamber-pot"), "step 1: pot should be worn")

    -- Step 2: Remove pot
    capture_output(function() handlers["remove"](ctx, "pot") end)
    truthy(not is_worn(ctx, "chamber-pot"), "step 2: pot should be removed")

    -- Drop pot to free hand
    capture_output(function() handlers["drop"](ctx, "pot") end)

    -- Step 3: Wear spittoon
    ctx.player.hands[1] = spittoon
    spittoon.location = "player"
    capture_output(function() handlers["wear"](ctx, "spittoon") end)
    truthy(is_worn(ctx, "brass-spittoon"), "step 3: spittoon should be worn")

    -- Step 4: Remove spittoon
    capture_output(function() handlers["remove"](ctx, "spittoon") end)
    truthy(not is_worn(ctx, "brass-spittoon"), "step 4: spittoon should be removed")

    -- Drop spittoon to free hand
    capture_output(function() handlers["drop"](ctx, "spittoon") end)

    -- Step 5: Wear pot again
    ctx.player.hands[1] = pot
    pot.location = "player"
    capture_output(function() handlers["wear"](ctx, "pot") end)
    truthy(is_worn(ctx, "chamber-pot"), "step 5: pot should be worn again")
end)

---------------------------------------------------------------------------
-- Suite 6: Different protection values
---------------------------------------------------------------------------
h.suite("Helmet Swap: Material-based protection values")

if armor_ok and materials_ok then

test("brass and ceramic have different material hardness", function()
    local brass_mat = materials.get("brass")
    local ceramic_mat = materials.get("ceramic")
    truthy(brass_mat, "brass material should exist in registry")
    truthy(ceramic_mat, "ceramic material should exist in registry")
    truthy(brass_mat.hardness ~= ceramic_mat.hardness,
        "brass (hardness=" .. brass_mat.hardness ..
        ") and ceramic (hardness=" .. ceramic_mat.hardness ..
        ") should have different hardness values")
end)

test("brass and ceramic have different fragility", function()
    local brass_mat = materials.get("brass")
    local ceramic_mat = materials.get("ceramic")
    truthy(brass_mat.fragility < ceramic_mat.fragility,
        "brass (fragility=" .. brass_mat.fragility ..
        ") should be less fragile than ceramic (fragility=" .. ceramic_mat.fragility .. ")")
end)

test("ceramic has higher hardness than brass", function()
    local brass_mat = materials.get("brass")
    local ceramic_mat = materials.get("ceramic")
    -- Ceramic hardness=7, brass hardness=6
    truthy(ceramic_mat.hardness > brass_mat.hardness,
        "ceramic (hardness=" .. ceramic_mat.hardness ..
        ") should have higher hardness than brass (hardness=" .. brass_mat.hardness .. ")")
end)

test("brass has higher density than ceramic", function()
    local brass_mat = materials.get("brass")
    local ceramic_mat = materials.get("ceramic")
    -- Brass density=8500, ceramic density=2300
    truthy(brass_mat.density > ceramic_mat.density,
        "brass (density=" .. brass_mat.density ..
        ") should have higher density than ceramic (density=" .. ceramic_mat.density .. ")")
end)

end -- armor_ok and materials_ok

---------------------------------------------------------------------------
-- Suite 7: Brass spittoon does NOT shatter (low fragility)
---------------------------------------------------------------------------
h.suite("Helmet Swap: Brass durability (low fragility)")

if armor_ok and effects_ok and injuries_ok and materials_ok then

local test_injury_def = {
    id = "test-bruise",
    name = "Test Bruise",
    category = "impact",
    damage_type = "instant",
    initial_state = "active",
    on_inflict = { initial_damage = 0, damage_per_tick = 0, message = "" },
    states = {
        active  = { name = "bruise", symptom = "A bruise.", description = "Bruised.", damage_per_tick = 0 },
        healed  = { name = "healed bruise", description = "Healed.", terminal = true },
    },
}

local function armor_setup()
    injuries.clear_cache()
    injuries.reset_id_counter()
    injuries.register_definition("test-bruise", test_injury_def)
    effects.clear_interceptors()
    if armor.register then armor.register(effects) end
end

local function make_armor_item(overrides)
    local item = {
        id = "test-helmet",
        name = "test helmet",
        covers = { "head" },
        fit = "makeshift",
        _state = "intact",
        layer = "outer",
    }
    if overrides then
        for k, v in pairs(overrides) do item[k] = v end
    end
    return item
end

test("brass spittoon stays intact after moderate head hit", function()
    armor_setup()
    local spittoon_armor = make_armor_item({
        id = "brass-spittoon", name = "a brass spittoon",
        material = "brass", fit = "makeshift",
        _state = "clean",  -- brass uses "clean" as initial state
    })
    local player = {
        max_health = 100, injuries = {},
        hands = {nil, nil}, worn = { spittoon_armor }, state = {},
    }

    -- Force degradation check to always trigger (random returns 0)
    -- brass fragility = 0.1, damage=10: break_chance = 0.1 * (10/20) * 1.0 = 0.05
    -- With random() = 0.1 > 0.05, should NOT crack
    local old_random = math.random
    math.random = function() return 0.1 end

    local eff = {
        type = "inflict_injury", injury_type = "test-bruise",
        source = "test-hit", location = "head", damage = 10,
    }
    suppress_print(function()
        effects.process(eff, { player = player, source_id = eff.source })
    end)
    math.random = old_random

    -- brass _state should remain "clean" (not cracked/shattered)
    truthy(spittoon_armor._state == "clean" or spittoon_armor._state == "intact",
        "brass spittoon should not crack on moderate hit, state=" .. tostring(spittoon_armor._state))
end)

test("brass spittoon survives heavy hit (no shatter)", function()
    armor_setup()
    local spittoon_armor = make_armor_item({
        id = "brass-spittoon", name = "a brass spittoon",
        material = "brass", fit = "makeshift", _state = "intact",
    })
    local player = {
        max_health = 100, injuries = {},
        hands = {nil, nil}, worn = { spittoon_armor }, state = {},
    }

    -- Even with random() returning 0 (always degrades), brass fragility is 0.1
    -- break_chance = 0.1 * (20/20) * 1.0 = 0.1 → random 0.0 < 0.1 → cracks to next state
    -- But from intact→cracked, NOT shattered
    local old_random = math.random
    math.random = function() return 0.0 end

    local eff = {
        type = "inflict_injury", injury_type = "test-bruise",
        source = "test-hit", location = "head", damage = 20,
    }
    suppress_print(function()
        effects.process(eff, { player = player, source_id = eff.source })
    end)
    math.random = old_random

    truthy(spittoon_armor._state ~= "shattered",
        "brass spittoon should NOT shatter even on heavy hit, state=" .. tostring(spittoon_armor._state))
end)

---------------------------------------------------------------------------
-- Suite 8: Ceramic pot DOES crack on strong head hit
---------------------------------------------------------------------------
h.suite("Helmet Swap: Ceramic fragility (cracks on impact)")

test("ceramic pot cracks on strong head hit", function()
    armor_setup()
    local pot_armor = make_armor_item({
        id = "ceramic-pot", name = "a ceramic chamber pot",
        material = "ceramic", fit = "makeshift", _state = "intact",
    })
    local player = {
        max_health = 100, injuries = {},
        hands = {nil, nil}, worn = { pot_armor }, state = {},
    }

    -- ceramic fragility = 0.7, damage=15: break_chance = 0.7 * (15/20) * 1.0 = 0.525
    -- With random() = 0.0 (always below threshold) → cracks
    local old_random = math.random
    math.random = function() return 0.0 end

    local eff = {
        type = "inflict_injury", injury_type = "test-bruise",
        source = "test-hit", location = "head", damage = 15,
    }
    suppress_print(function()
        effects.process(eff, { player = player, source_id = eff.source })
    end)
    math.random = old_random

    eq("cracked", pot_armor._state,
        "ceramic pot should crack on strong head hit")
end)

test("ceramic pot shatters after second strong hit", function()
    armor_setup()
    local pot_armor = make_armor_item({
        id = "ceramic-pot", name = "a ceramic chamber pot",
        material = "ceramic", fit = "makeshift", _state = "cracked",
    })
    local player = {
        max_health = 100, injuries = {},
        hands = {nil, nil}, worn = { pot_armor }, state = {},
    }

    local old_random = math.random
    math.random = function() return 0.0 end

    local eff = {
        type = "inflict_injury", injury_type = "test-bruise",
        source = "test-hit", location = "head", damage = 15,
    }
    suppress_print(function()
        effects.process(eff, { player = player, source_id = eff.source })
    end)
    math.random = old_random

    eq("shattered", pot_armor._state,
        "cracked ceramic pot should shatter on second strong hit")
end)

test("ceramic is much more fragile than brass", function()
    local brass_mat = materials.get("brass")
    local ceramic_mat = materials.get("ceramic")
    -- brass fragility=0.1, ceramic fragility=0.7
    truthy(ceramic_mat.fragility >= brass_mat.fragility * 5,
        "ceramic fragility (" .. ceramic_mat.fragility ..
        ") should be at least 5x brass fragility (" .. brass_mat.fragility .. ")")
end)

end -- armor_ok and effects_ok and injuries_ok and materials_ok

--- Results
os.exit(h.summary() > 0 and 1 or 0)
