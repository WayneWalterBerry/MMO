-- test/objects/test-glass-shards.lua
-- Tests for Issue #136: Glass bottle break must spawn glass shards.
-- Validates wine-bottle.lua break transitions spawn glass-shard objects,
-- validates glass-shard.lua structure, and compares with ceramic-shard pattern.
-- Must be run from repository root: lua test/objects/test-glass-shards.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load objects
---------------------------------------------------------------------------
local bottle = dofile(script_dir .. "/../../src/meta/objects/wine-bottle.lua")
local shard = dofile(script_dir .. "/../../src/meta/objects/glass-shard.lua")
local ceramic_shard = dofile(script_dir .. "/../../src/meta/objects/ceramic-shard.lua")
local chamber_pot = dofile(script_dir .. "/../../src/meta/objects/chamber-pot.lua")

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function has_value(list, val)
    if not list then return false end
    for _, v in ipairs(list) do
        if v == val then return true end
    end
    return false
end

local function find_transition(obj, from, to)
    for _, t in ipairs(obj.transitions) do
        if t.from == from and t.to == to then return t end
    end
    return nil
end

---------------------------------------------------------------------------
-- GLASS SHARD: object structure
---------------------------------------------------------------------------
suite("GLASS SHARD: object structure")

test("1. glass-shard.lua loads without error", function()
    h.assert_truthy(shard, "glass-shard.lua must load")
end)

test("2. Object id is 'glass-shard'", function()
    h.assert_eq("glass-shard", shard.id, "object id")
end)

test("3. Has a valid GUID", function()
    h.assert_truthy(shard.guid, "guid must exist")
    h.assert_truthy(shard.guid:match("^{%x+%-%x+%-%x+%-%x+%-%x+}$"),
        "guid must be in brace format")
end)

test("4. Material is 'glass'", function()
    h.assert_eq("glass", shard.material, "material must be glass")
end)

test("5. Is portable", function()
    h.assert_eq(true, shard.portable, "portable must be true")
end)

test("6. Size is 1 (small item)", function()
    h.assert_eq(1, shard.size, "size must be 1")
end)

test("7. Has 'sharp' category", function()
    h.assert_truthy(has_value(shard.categories, "sharp"), "must include 'sharp'")
end)

test("8. Has 'fragile' category", function()
    h.assert_truthy(has_value(shard.categories, "fragile"), "must include 'fragile'")
end)

test("9. Keywords include 'glass shard'", function()
    h.assert_truthy(has_value(shard.keywords, "glass shard"), "must include 'glass shard'")
end)

test("10. Keywords include 'shard'", function()
    h.assert_truthy(has_value(shard.keywords, "shard"), "must include 'shard'")
end)

test("11. Has description", function()
    h.assert_truthy(shard.description, "description must exist")
    h.assert_truthy(#shard.description > 0, "description must not be empty")
end)

test("12. Has on_feel", function()
    h.assert_truthy(shard.on_feel, "on_feel must exist")
end)

---------------------------------------------------------------------------
-- GLASS SHARD: injury capability (effects pipeline)
---------------------------------------------------------------------------
suite("GLASS SHARD: injury capability")

test("13. Has on_cut with damage", function()
    h.assert_truthy(shard.on_cut, "on_cut must exist")
    h.assert_truthy(shard.on_cut.damage, "on_cut.damage must exist")
    h.assert_truthy(shard.on_cut.damage > 0, "on_cut.damage must be > 0")
end)

test("14. on_cut injury_type is 'minor-cut'", function()
    h.assert_eq("minor-cut", shard.on_cut.injury_type, "on_cut.injury_type")
end)

test("15. Has effects_pipeline flag", function()
    h.assert_eq(true, shard.effects_pipeline, "effects_pipeline must be true")
end)

test("16. Has on_feel_effect for contact injury", function()
    h.assert_truthy(shard.on_feel_effect, "on_feel_effect must exist")
    h.assert_eq("inflict_injury", shard.on_feel_effect.type, "on_feel_effect.type")
end)

test("17. provides_tool includes 'cutting_edge'", function()
    h.assert_truthy(shard.provides_tool, "provides_tool must exist")
    h.assert_truthy(has_value(shard.provides_tool, "cutting_edge"),
        "must include 'cutting_edge'")
end)

test("18. provides_tool includes 'injury_source'", function()
    h.assert_truthy(has_value(shard.provides_tool, "injury_source"),
        "must include 'injury_source'")
end)

---------------------------------------------------------------------------
-- WINE BOTTLE: break transitions spawn glass shards
---------------------------------------------------------------------------
suite("WINE BOTTLE: break spawns glass shards")

test("19. Wine bottle loads without error", function()
    h.assert_truthy(bottle, "wine-bottle.lua must load")
end)

test("20. Wine bottle material is 'glass'", function()
    h.assert_eq("glass", bottle.material, "material must be glass")
end)

test("21. Has 'broken' state", function()
    h.assert_truthy(bottle.states.broken, "broken state must exist")
end)

test("22. sealed->broken transition exists", function()
    local t = find_transition(bottle, "sealed", "broken")
    h.assert_truthy(t, "sealed -> broken transition must exist")
end)

test("23. sealed->broken transition has mutate.spawns", function()
    local t = find_transition(bottle, "sealed", "broken")
    h.assert_truthy(t.mutate, "sealed->broken must have mutate table")
    h.assert_truthy(t.mutate.spawns, "sealed->broken must have mutate.spawns")
end)

test("24. sealed->broken spawns glass-shard objects", function()
    local t = find_transition(bottle, "sealed", "broken")
    local count = 0
    for _, spawn_id in ipairs(t.mutate.spawns) do
        if spawn_id == "glass-shard" then count = count + 1 end
    end
    h.assert_truthy(count >= 2, "sealed->broken must spawn at least 2 glass-shard objects")
end)

test("25. open->broken transition exists", function()
    local t = find_transition(bottle, "open", "broken")
    h.assert_truthy(t, "open -> broken transition must exist")
end)

test("26. open->broken transition has mutate.spawns", function()
    local t = find_transition(bottle, "open", "broken")
    h.assert_truthy(t.mutate, "open->broken must have mutate table")
    h.assert_truthy(t.mutate.spawns, "open->broken must have mutate.spawns")
end)

test("27. open->broken spawns glass-shard objects", function()
    local t = find_transition(bottle, "open", "broken")
    local count = 0
    for _, spawn_id in ipairs(t.mutate.spawns) do
        if spawn_id == "glass-shard" then count = count + 1 end
    end
    h.assert_truthy(count >= 2, "open->broken must spawn at least 2 glass-shard objects")
end)

---------------------------------------------------------------------------
-- WINE BOTTLE: mutations.shatter (fragility system)
---------------------------------------------------------------------------
suite("WINE BOTTLE: mutations.shatter")

test("28. mutations table exists", function()
    h.assert_truthy(bottle.mutations, "mutations table must exist")
end)

test("29. mutations.shatter exists", function()
    h.assert_truthy(bottle.mutations.shatter, "mutations.shatter must exist")
end)

test("30. mutations.shatter.spawns includes glass-shard", function()
    local spawns = bottle.mutations.shatter.spawns
    h.assert_truthy(spawns, "mutations.shatter.spawns must exist")
    h.assert_truthy(has_value(spawns, "glass-shard"),
        "mutations.shatter.spawns must include 'glass-shard'")
end)

test("31. mutations.shatter.becomes is nil (object destroyed)", function()
    h.assert_eq(nil, bottle.mutations.shatter.becomes,
        "mutations.shatter.becomes must be nil (destroyed)")
end)

test("32. mutations.shatter has narration", function()
    h.assert_truthy(bottle.mutations.shatter.narration,
        "mutations.shatter must have narration")
    h.assert_truthy(#bottle.mutations.shatter.narration > 0,
        "narration must not be empty")
end)

---------------------------------------------------------------------------
-- PARITY: glass follows same pattern as ceramic
---------------------------------------------------------------------------
suite("MATERIAL PARITY: glass shards match ceramic shard pattern")

test("33. ceramic-shard.lua loads", function()
    h.assert_truthy(ceramic_shard, "ceramic-shard.lua must load")
end)

test("34. chamber-pot has mutations.shatter.spawns", function()
    h.assert_truthy(chamber_pot.mutations, "chamber-pot mutations must exist")
    h.assert_truthy(chamber_pot.mutations.shatter, "chamber-pot mutations.shatter must exist")
    h.assert_truthy(chamber_pot.mutations.shatter.spawns,
        "chamber-pot mutations.shatter.spawns must exist")
end)

test("35. Both shard types have same template", function()
    h.assert_eq(shard.template, ceramic_shard.template,
        "glass-shard and ceramic-shard should have same template")
end)

test("36. Both shard types are portable", function()
    h.assert_eq(true, shard.portable, "glass-shard must be portable")
    h.assert_eq(true, ceramic_shard.portable, "ceramic-shard must be portable")
end)

test("37. Both shard types are size 1", function()
    h.assert_eq(1, shard.size, "glass-shard must be size 1")
    h.assert_eq(1, ceramic_shard.size, "ceramic-shard must be size 1")
end)

test("38. Both shard types have 'sharp' category", function()
    h.assert_truthy(has_value(shard.categories, "sharp"), "glass-shard must be sharp")
    h.assert_truthy(has_value(ceramic_shard.categories, "sharp"), "ceramic-shard must be sharp")
end)

test("39. Wine bottle break pattern matches chamber pot break pattern", function()
    -- Both glass (wine-bottle) and ceramic (chamber-pot) should have:
    -- transitions with mutate.spawns that reference their respective shard type
    local wine_break = find_transition(bottle, "sealed", "broken")
    local pot_break = find_transition(chamber_pot, "cracked", "shattered")
    h.assert_truthy(wine_break.mutate.spawns, "wine bottle must have spawns")
    h.assert_truthy(pot_break.mutate.spawns, "chamber pot must have spawns")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
