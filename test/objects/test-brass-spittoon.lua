-- test/objects/test-brass-spittoon.lua
-- Tests for the brass-spittoon.lua object (Phase D3).
-- Validates data structure, helmet wear metadata, container behavior,
-- FSM states, material registry linkage, weight, and sensory properties.
-- Must be run from repository root: lua test/objects/test-brass-spittoon.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load the spittoon object and materials registry
---------------------------------------------------------------------------
local spittoon = dofile(script_dir .. "/../../src/meta/objects/brass-spittoon.lua")
local materials = require("engine.materials")

---------------------------------------------------------------------------
-- Helper: check if a value is in a list
---------------------------------------------------------------------------
local function has_value(list, val)
    if not list then return false end
    for _, v in ipairs(list) do
        if v == val then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- IDENTITY & DATA STRUCTURE
---------------------------------------------------------------------------
suite("BRASS SPITTOON: identity and structure")

test("1. Object loads without error", function()
    h.assert_truthy(spittoon, "brass-spittoon.lua must load")
end)

test("2. Object id is 'brass-spittoon'", function()
    h.assert_eq("brass-spittoon", spittoon.id, "object id")
end)

test("3. Has a valid GUID in brace format", function()
    h.assert_truthy(spittoon.guid, "guid must exist")
    h.assert_truthy(spittoon.guid:match("^{%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x}$"),
        "guid must be in {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx} format")
end)

test("4. Template is 'container'", function()
    h.assert_eq("container", spittoon.template, "template")
end)

test("5. Material is 'brass'", function()
    h.assert_eq("brass", spittoon.material, "material")
end)

test("6. Has a name", function()
    h.assert_truthy(spittoon.name, "name must exist")
    h.assert_truthy(#spittoon.name > 0, "name must not be empty")
end)

test("7. Is portable", function()
    h.assert_eq(true, spittoon.portable, "portable must be true")
end)

test("8. Has a description", function()
    h.assert_truthy(spittoon.description, "description must exist")
    h.assert_truthy(#spittoon.description > 0, "description must not be empty")
end)

test("9. Has room_presence", function()
    h.assert_truthy(spittoon.room_presence, "room_presence must exist")
end)

---------------------------------------------------------------------------
-- KEYWORDS
---------------------------------------------------------------------------
suite("BRASS SPITTOON: keywords")

test("10. Keywords table exists and is non-empty", function()
    h.assert_truthy(spittoon.keywords, "keywords must exist")
    h.assert_truthy(#spittoon.keywords > 0, "keywords must not be empty")
end)

test("11. Keywords include 'spittoon'", function()
    h.assert_truthy(has_value(spittoon.keywords, "spittoon"), "must include 'spittoon'")
end)

test("12. Keywords include 'brass spittoon'", function()
    h.assert_truthy(has_value(spittoon.keywords, "brass spittoon"), "must include 'brass spittoon'")
end)

test("13. Keywords must NOT include 'brass bowl' (collision fix #153)", function()
    h.assert_truthy(not has_value(spittoon.keywords, "brass bowl"),
        "'brass bowl' must be removed — it collides with candle holder via fuzzy material match")
end)

test("14. Keywords include 'cuspidor'", function()
    h.assert_truthy(has_value(spittoon.keywords, "cuspidor"), "must include 'cuspidor'")
end)

test("15. Keywords include 'spit bowl'", function()
    h.assert_truthy(has_value(spittoon.keywords, "spit bowl"), "must include 'spit bowl'")
end)

test("16. Keywords include 'helmet'", function()
    h.assert_truthy(has_value(spittoon.keywords, "helmet"), "must include 'helmet'")
end)

---------------------------------------------------------------------------
-- HELMET / WEAR METADATA
---------------------------------------------------------------------------
suite("BRASS SPITTOON: helmet and wear metadata")

test("17. is_helmet is true", function()
    h.assert_eq(true, spittoon.is_helmet, "is_helmet must be true")
end)

test("18. wear_slot is 'head'", function()
    h.assert_eq("head", spittoon.wear_slot, "wear_slot must be 'head'")
end)

test("19. wear table exists", function()
    h.assert_truthy(spittoon.wear, "wear table must exist")
end)

test("20. wear.slot is 'head'", function()
    h.assert_eq("head", spittoon.wear.slot, "wear.slot")
end)

test("21. wear.layer is 'outer'", function()
    h.assert_eq("outer", spittoon.wear.layer, "wear.layer")
end)

test("22. wear.coverage is a number between 0 and 1", function()
    h.assert_truthy(type(spittoon.wear.coverage) == "number", "coverage must be a number")
    h.assert_truthy(spittoon.wear.coverage > 0, "coverage must be > 0")
    h.assert_truthy(spittoon.wear.coverage <= 1, "coverage must be <= 1")
end)

test("23. wear.fit is 'makeshift'", function()
    h.assert_eq("makeshift", spittoon.wear.fit, "wear.fit")
end)

test("24. reduces_unconsciousness is set", function()
    h.assert_truthy(spittoon.reduces_unconsciousness, "reduces_unconsciousness must be set")
end)

test("25. Appearance table exists with worn_description", function()
    h.assert_truthy(spittoon.appearance, "appearance table must exist")
    h.assert_truthy(spittoon.appearance.worn_description,
        "appearance.worn_description must exist")
    h.assert_truthy(#spittoon.appearance.worn_description > 0,
        "worn_description must not be empty")
end)

---------------------------------------------------------------------------
-- CONTAINER BEHAVIOR
---------------------------------------------------------------------------
suite("BRASS SPITTOON: container behavior")

test("26. container flag is true", function()
    h.assert_eq(true, spittoon.container, "container must be true")
end)

test("27. capacity is 2", function()
    h.assert_eq(2, spittoon.capacity, "capacity must be 2")
end)

test("28. contents table exists", function()
    h.assert_truthy(spittoon.contents, "contents table must exist")
    h.assert_truthy(type(spittoon.contents) == "table", "contents must be a table")
end)

test("29. contents starts empty", function()
    h.assert_eq(0, #spittoon.contents, "contents must start empty")
end)

test("30. size is 2", function()
    h.assert_eq(2, spittoon.size, "size must be 2")
end)

---------------------------------------------------------------------------
-- FSM STATES
---------------------------------------------------------------------------
suite("BRASS SPITTOON: FSM states")

test("31. initial_state is 'clean'", function()
    h.assert_eq("clean", spittoon.initial_state, "initial_state")
end)

test("32. _state matches initial_state", function()
    h.assert_eq(spittoon.initial_state, spittoon._state, "_state must match initial_state")
end)

test("33. states table exists", function()
    h.assert_truthy(spittoon.states, "states table must exist")
end)

test("34. Has 'clean' state", function()
    h.assert_truthy(spittoon.states.clean, "clean state must exist")
end)

test("35. Has 'stained' state", function()
    h.assert_truthy(spittoon.states.stained, "stained state must exist")
end)

test("36. Has 'dented' state", function()
    h.assert_truthy(spittoon.states.dented, "dented state must exist")
end)

test("37. Each state has name, description, room_presence", function()
    for _, state_name in ipairs({"clean", "stained", "dented"}) do
        local state = spittoon.states[state_name]
        h.assert_truthy(state.name, state_name .. ".name must exist")
        h.assert_truthy(state.description, state_name .. ".description must exist")
        h.assert_truthy(state.room_presence, state_name .. ".room_presence must exist")
    end
end)

test("38. Each state has sensory fields (on_feel, on_smell, on_listen)", function()
    for _, state_name in ipairs({"clean", "stained", "dented"}) do
        local state = spittoon.states[state_name]
        h.assert_truthy(state.on_feel, state_name .. ".on_feel must exist")
        h.assert_truthy(state.on_smell, state_name .. ".on_smell must exist")
        h.assert_truthy(state.on_listen, state_name .. ".on_listen must exist")
    end
end)

---------------------------------------------------------------------------
-- FSM TRANSITIONS
---------------------------------------------------------------------------
suite("BRASS SPITTOON: FSM transitions")

test("39. Transitions table exists and is non-empty", function()
    h.assert_truthy(spittoon.transitions, "transitions must exist")
    h.assert_truthy(#spittoon.transitions > 0, "transitions must not be empty")
end)

local function find_transition(from, to)
    for _, t in ipairs(spittoon.transitions) do
        if t.from == from and t.to == to then return t end
    end
    return nil
end

test("40. Has clean -> stained transition", function()
    h.assert_truthy(find_transition("clean", "stained"),
        "clean -> stained transition must exist")
end)

test("41. Has stained -> dented transition", function()
    h.assert_truthy(find_transition("stained", "dented"),
        "stained -> dented transition must exist")
end)

test("42. Has clean -> dented transition (direct dent)", function()
    h.assert_truthy(find_transition("clean", "dented"),
        "clean -> dented transition must exist")
end)

test("43. All transitions have messages", function()
    for _, t in ipairs(spittoon.transitions) do
        h.assert_truthy(t.message,
            "transition " .. t.from .. " -> " .. t.to .. " must have a message")
        h.assert_truthy(#t.message > 0,
            "transition " .. t.from .. " -> " .. t.to .. " message must not be empty")
    end
end)

test("44. Dent transitions mention brass doesn't shatter", function()
    local t = find_transition("clean", "dented")
    h.assert_truthy(t.message:lower():find("brass") or t.message:lower():find("hold")
        or t.message:lower():find("dent"),
        "dent transition should reference brass durability")
end)

---------------------------------------------------------------------------
-- MATERIAL REGISTRY LINKAGE
---------------------------------------------------------------------------
suite("BRASS SPITTOON: material registry")

test("45. 'brass' exists in materials registry", function()
    local brass = materials.get and materials.get("brass") or materials.materials and materials.materials.brass or materials.brass
    h.assert_truthy(brass, "brass must exist in materials registry")
end)

test("46. Brass hardness is 6", function()
    local brass = materials.get and materials.get("brass") or materials.materials and materials.materials.brass or materials.brass
    h.assert_eq(6, brass.hardness, "brass hardness")
end)

test("47. Brass density is 8500", function()
    local brass = materials.get and materials.get("brass") or materials.materials and materials.materials.brass or materials.brass
    h.assert_eq(8500, brass.density, "brass density")
end)

test("48. Brass fragility is 0.1", function()
    local brass = materials.get and materials.get("brass") or materials.materials and materials.materials.brass or materials.brass
    h.assert_eq(0.1, brass.fragility, "brass fragility")
end)

test("49. Brass flexibility is 0.1", function()
    local brass = materials.get and materials.get("brass") or materials.materials and materials.materials.brass or materials.brass
    h.assert_eq(0.1, brass.flexibility, "brass flexibility")
end)

---------------------------------------------------------------------------
-- WEIGHT VALIDATION
---------------------------------------------------------------------------
suite("BRASS SPITTOON: weight")

test("50. Weight field exists and is a number", function()
    h.assert_truthy(spittoon.weight, "weight must exist")
    h.assert_truthy(type(spittoon.weight) == "number", "weight must be a number")
end)

test("51. Weight is reasonable for brass (heavier than ceramic pot)", function()
    -- Brass density = 8500, ceramic = 2300 → brass object should be heavier
    -- Ceramic pot weighs ~1. Brass spittoon should be heavier.
    h.assert_truthy(spittoon.weight > 1, "brass spittoon must weigh more than 1 (ceramic pot range)")
end)

test("52. Weight is not absurdly high (< 20)", function()
    h.assert_truthy(spittoon.weight < 20, "weight must be reasonable (< 20)")
end)

---------------------------------------------------------------------------
-- SENSORY PROPERTIES (all five senses + description)
---------------------------------------------------------------------------
suite("BRASS SPITTOON: sensory properties")

test("53. Has on_feel", function()
    h.assert_truthy(spittoon.on_feel, "on_feel must exist")
    h.assert_truthy(#spittoon.on_feel > 0, "on_feel must not be empty")
end)

test("54. on_feel mentions brass or heavy", function()
    h.assert_truthy(spittoon.on_feel:lower():find("brass") or spittoon.on_feel:lower():find("heavy"),
        "on_feel should reference brass material or weight")
end)

test("55. Has on_smell", function()
    h.assert_truthy(spittoon.on_smell, "on_smell must exist")
    h.assert_truthy(#spittoon.on_smell > 0, "on_smell must not be empty")
end)

test("56. on_smell mentions tobacco", function()
    h.assert_truthy(spittoon.on_smell:lower():find("tobacco"),
        "on_smell should reference tobacco")
end)

test("57. Has on_listen", function()
    h.assert_truthy(spittoon.on_listen, "on_listen must exist")
    h.assert_truthy(#spittoon.on_listen > 0, "on_listen must not be empty")
end)

test("58. Has on_taste", function()
    h.assert_truthy(spittoon.on_taste, "on_taste must exist")
    h.assert_truthy(#spittoon.on_taste > 0, "on_taste must not be empty")
end)

test("59. on_taste mentions metallic or brass", function()
    h.assert_truthy(spittoon.on_taste:lower():find("metallic") or spittoon.on_taste:lower():find("brass")
        or spittoon.on_taste:lower():find("pennies"),
        "on_taste should reference metallic flavor")
end)

test("60. Has description (top-level)", function()
    h.assert_truthy(spittoon.description, "description must exist")
    h.assert_truthy(#spittoon.description > 20, "description must be substantive")
end)

test("61. Description mentions brass", function()
    h.assert_truthy(spittoon.description:lower():find("brass"),
        "description should mention brass")
end)

test("62. Has on_smell_worn (worn helmet smell)", function()
    h.assert_truthy(spittoon.on_smell_worn, "on_smell_worn must exist")
    h.assert_truthy(#spittoon.on_smell_worn > 0, "on_smell_worn must not be empty")
end)

test("63. on_smell_worn mentions brass or smell-related content", function()
    local lower = spittoon.on_smell_worn:lower()
    h.assert_truthy(lower:find("brass") or lower:find("tobacco") or lower:find("smell")
        or lower:find("tarnish") or lower:find("expectorat"),
        "on_smell_worn should reference brass, tobacco, or smell-related content")
end)

---------------------------------------------------------------------------
-- CATEGORIES
---------------------------------------------------------------------------
suite("BRASS SPITTOON: categories")

test("64. Categories table exists", function()
    h.assert_truthy(spittoon.categories, "categories must exist")
    h.assert_truthy(#spittoon.categories > 0, "categories must not be empty")
end)

test("65. Categories include 'brass'", function()
    h.assert_truthy(has_value(spittoon.categories, "brass"), "must include 'brass'")
end)

test("66. Categories include 'container'", function()
    h.assert_truthy(has_value(spittoon.categories, "container"), "must include 'container'")
end)

test("67. Categories include 'metal'", function()
    h.assert_truthy(has_value(spittoon.categories, "metal"), "must include 'metal'")
end)

test("68. Categories include 'wearable'", function()
    h.assert_truthy(has_value(spittoon.categories, "wearable"), "must include 'wearable'")
end)

---------------------------------------------------------------------------
-- on_look FUNCTION
---------------------------------------------------------------------------
suite("BRASS SPITTOON: on_look behavior")

test("69. on_look exists and is callable", function()
    h.assert_truthy(spittoon.on_look, "on_look must exist")
    h.assert_truthy(type(spittoon.on_look) == "function", "on_look must be a function")
end)

test("70. on_look with empty contents mentions 'empty'", function()
    spittoon.contents = {}
    local result = spittoon:on_look()
    h.assert_truthy(result:lower():find("empty"), "on_look with no contents should mention 'empty'")
end)

test("71. on_look with contents lists them", function()
    spittoon.contents = {"a small coin"}
    local result = spittoon:on_look()
    h.assert_truthy(result:lower():find("contains") or result:lower():find("coin"),
        "on_look with contents should list items")
    spittoon.contents = {} -- reset
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
