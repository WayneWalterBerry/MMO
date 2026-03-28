-- test/combat/test-narration-366-363.lua
-- Issue #366: Combat narration uses "Someone" instead of "You"
-- Issue #363: Combat grammar errors — subject-verb disagreement
-- TDD: Tests written before fixes.

math.randomseed(42)

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

local ok_narr, narration = pcall(require, "engine.combat.narration")
if not ok_narr then
    print("FATAL: engine.combat.narration failed to load — " .. tostring(narration))
    os.exit(1)
end

local function call_narrate(result, light)
    return narration.generate(result, light)
end

local function make_result(overrides)
    local r = {
        attacker = { id = "player", name = "the player" },
        defender = { id = "rat", name = "the rat" },
        severity = 2,
        zone = "body",
        weapon = { id = "steel-dagger", name = "a steel dagger", material = "steel",
                   combat = { type = "edged", message = "slashes" } },
        material_name = "steel",
        tissue_hit = "flesh",
        action_verb = "slashes",
    }
    if overrides then
        for k, v in pairs(overrides) do r[k] = v end
    end
    return r
end

---------------------------------------------------------------------------
-- Issue #366: "Someone" → "You" for player attacks
---------------------------------------------------------------------------
suite("#366: Combat narration uses 'You' for player attacks")

test("nil attacker defaults to 'You' (player is implied)", function()
    -- Run many seeds — at least one template must include the attacker name
    local found_you = false
    local found_someone = false
    for i = 1, 30 do
        math.randomseed(42 + i * 13)
        local result = make_result({ attacker = nil })
        local text = call_narrate(result, true)
        if text then
            if text:find("You ") then found_you = true end
            if text:lower():find("someone") then found_someone = true end
        end
    end
    h.assert_truthy(not found_someone,
        "nil attacker must NEVER produce 'Someone'")
    h.assert_truthy(found_you,
        "nil attacker should produce 'You' in at least one template")
end)

test("player attacker produces 'You' (not 'Someone' or 'The player')", function()
    local found_you = false
    local found_bad = false
    for i = 1, 30 do
        math.randomseed(42 + i * 7)
        local result = make_result({ attacker = { id = "player", name = "the player" } })
        local text = call_narrate(result, true)
        if text then
            if text:find("You ") then found_you = true end
            if text:lower():find("someone") or text:find("The player") then found_bad = true end
        end
    end
    h.assert_truthy(not found_bad,
        "player attacker must NEVER produce 'Someone' or 'The player'")
    h.assert_truthy(found_you,
        "player attacker should produce 'You' in at least one template")
end)

test("player with is_player flag produces 'You'", function()
    local found_you = false
    for i = 1, 30 do
        math.randomseed(42 + i * 11)
        local result = make_result({ attacker = { id = "hero", is_player = true } })
        local text = call_narrate(result, true)
        if text and text:find("You ") then found_you = true end
    end
    h.assert_truthy(found_you,
        "is_player attacker should produce 'You' in at least one template")
end)

test("NPC attacker still gets its name (not 'You')", function()
    local found_rat = false
    local found_you_as_attacker = false
    for i = 1, 30 do
        math.randomseed(42 + i * 3)
        local result = make_result({
            attacker = { id = "rat", name = "the rat" },
            defender = { id = "player", name = "you" },
        })
        local text = call_narrate(result, true)
        if text then
            if text:find("The rat") then found_rat = true end
        end
    end
    h.assert_truthy(found_rat,
        "NPC attacker must show 'The rat' in at least one template")
end)

---------------------------------------------------------------------------
-- Issue #363: Grammar — plural nouns with correct verb agreement
---------------------------------------------------------------------------
suite("#363: Combat grammar — no subject-verb disagreement")

test("tissue 'organ' is singular (not 'organs')", function()
    math.randomseed(100)
    -- Generate many narrations with organ tissue to check grammar
    local found_plural = false
    for i = 1, 20 do
        math.randomseed(42 + i * 7)
        local result = make_result({
            severity = 4,
            tissue_hit = "organ",
            zone = "body",
        })
        local text = call_narrate(result, true)
        if text and text:lower():find("organs") then
            -- Check if it's used with a singular verb (grammar error)
            if text:lower():find("organs gives") or text:lower():find("organs cracks")
               or text:lower():find("organs fractures") then
                found_plural = true
            end
        end
    end
    h.assert_truthy(not found_plural,
        "organ tissue must not cause 'organs gives/cracks/fractures' grammar errors")
end)

test("tooth-enamel material uses singular or grammatically correct forms", function()
    local found_grammar_error = false
    for i = 1, 20 do
        math.randomseed(42 + i * 11)
        local result = make_result({
            severity = 2,
            material_name = "tooth-enamel",
            tissue_hit = "hide",
            zone = "body",
            action_verb = "bites",
        })
        local text = call_narrate(result, true)
        if text then
            -- "teeth bites" and "fangs bites" are grammar errors
            if text:lower():find("teeth bites") or text:lower():find("fangs bites")
               or text:lower():find("teeth slashes") or text:lower():find("fangs slashes") then
                found_grammar_error = true
            end
        end
    end
    h.assert_truthy(not found_grammar_error,
        "tooth-enamel material must not cause 'teeth bites' or 'fangs slashes' grammar errors")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
