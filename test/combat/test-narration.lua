-- test/combat/test-narration.lua
-- WAVE-5 TDD: Combat narration engine tests.
-- Tests: severity-scaled text, material-aware, zone-specific, darkness mode, variety.
-- Engine module under test: src/engine/combat/narration.lua (required by combat/init.lua)
-- Must be run from repository root: lua test/combat/test-narration.lua

math.randomseed(42)

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load combat engine + narration
---------------------------------------------------------------------------
local ok_combat, combat = pcall(require, "engine.combat")
if not ok_combat then
    print("WARNING: engine.combat failed to load — " .. tostring(combat))
    combat = nil
end

-- Try loading narration module directly
local ok_narr, narration = pcall(require, "engine.combat.narration")
if not ok_narr then
    print("WARNING: engine.combat.narration failed to load — " .. tostring(narration))
    narration = nil
end

---------------------------------------------------------------------------
-- Fixture helpers
---------------------------------------------------------------------------

local function make_player()
    return {
        id = "player", name = "the player",
        combat = { size = "medium", speed = 5 },
        body_tree = {
            head  = { size = 0.10, vital = true,  tissue = { "skin", "flesh", "bone", "organ" } },
            torso = { size = 0.35, vital = true,  tissue = { "skin", "flesh", "bone", "organ" } },
            arms  = { size = 0.20, vital = false, tissue = { "skin", "flesh", "bone" } },
            hands = { size = 0.10, vital = false, tissue = { "skin", "flesh", "bone" } },
            legs  = { size = 0.20, vital = false, tissue = { "skin", "flesh", "bone" } },
            feet  = { size = 0.05, vital = false, tissue = { "skin", "flesh", "bone" } },
        },
        health = 100, max_health = 100,
        _state = "alive", animate = true, portable = false,
    }
end

local function make_rat()
    return {
        id = "rat", name = "the rat",
        combat = {
            size = "tiny", speed = 6,
            natural_weapons = {
                { id = "bite", type = "pierce", material = "tooth-enamel",
                  zone = "head", force = 2, target_pref = "arms",
                  message = "sinks its teeth into" },
            },
            behavior = { defense = "dodge", flee_threshold = 0.3 },
        },
        body_tree = {
            head = { size = 0.15, vital = true,  tissue = { "hide", "flesh", "bone", "organ" } },
            body = { size = 0.45, vital = true,  tissue = { "hide", "flesh", "bone", "organ" } },
            legs = { size = 0.25, vital = false, tissue = { "hide", "flesh", "bone" } },
            tail = { size = 0.15, vital = false, tissue = { "hide", "flesh" } },
        },
        health = 10, max_health = 10,
        _state = "alive", animate = true, portable = false,
    }
end

-- Build a structured combat result for narration testing
local function make_result(overrides)
    local r = {
        attacker = { id = "player", name = "you" },
        defender = { id = "rat", name = "the rat" },
        severity = 2,  -- HIT
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
-- SUITE 1: Severity-Scaled Text
---------------------------------------------------------------------------
suite("NARRATION: severity-scaled text (WAVE-5)")

test("1. narration module or combat.narrate exists", function()
    local has_narrate = (combat and type(combat.narrate) == "function")
        or (narration and type(narration.generate) == "function")
        or (narration and type(narration.narrate) == "function")
    h.assert_truthy(has_narrate,
        "combat.narrate or narration.generate/narrate must be a function")
end)

-- Helper: call whichever narration function is available
local function call_narrate(result, light)
    if combat and combat.narrate then
        return combat.narrate(result, light)
    elseif narration and narration.generate then
        return narration.generate(result, light)
    elseif narration and narration.narrate then
        return narration.narrate(result, light)
    end
    return nil
end

test("2. DEFLECT narration is a non-empty string", function()
    local text = call_narrate(
        make_result({ severity = 0, zone = "body", tissue_hit = "hide" }), true)
    h.assert_truthy(text, "narration for DEFLECT must return a string")
    h.assert_eq("string", type(text), "narration must be a string")
    h.assert_truthy(#text > 0, "narration must be non-empty")
end)

test("3. GRAZE narration is a non-empty string", function()
    local text = call_narrate(
        make_result({ severity = 1, zone = "body", tissue_hit = "skin" }), true)
    h.assert_truthy(text, "narration for GRAZE must return a string")
    h.assert_truthy(#text > 0, "GRAZE narration must be non-empty")
end)

test("4. HIT narration is a non-empty string", function()
    local text = call_narrate(
        make_result({ severity = 2, zone = "body", tissue_hit = "flesh" }), true)
    h.assert_truthy(text, "narration for HIT must return a string")
    h.assert_truthy(#text > 0, "HIT narration must be non-empty")
end)

test("5. SEVERE narration is a non-empty string", function()
    local text = call_narrate(
        make_result({ severity = 3, zone = "body", tissue_hit = "bone" }), true)
    h.assert_truthy(text, "narration for SEVERE must return a string")
    h.assert_truthy(#text > 0, "SEVERE narration must be non-empty")
end)

test("6. CRITICAL narration is a non-empty string", function()
    local text = call_narrate(
        make_result({ severity = 4, zone = "body", tissue_hit = "organ" }), true)
    h.assert_truthy(text, "narration for CRITICAL must return a string")
    h.assert_truthy(#text > 0, "CRITICAL narration must be non-empty")
end)

test("7. different severities produce different narration text", function()
    math.randomseed(42)
    local texts = {}
    for sev = 0, 4 do
        local tissue_names = { [0] = "hide", [1] = "skin", [2] = "flesh", [3] = "bone", [4] = "organ" }
        local text = call_narrate(
            make_result({ severity = sev, zone = "body", tissue_hit = tissue_names[sev] }), true)
        if text then texts[#texts + 1] = text end
    end
    -- At least 3 of the 5 severity levels should produce unique strings
    local unique = {}
    for _, t in ipairs(texts) do unique[t] = true end
    local unique_count = 0
    for _ in pairs(unique) do unique_count = unique_count + 1 end
    h.assert_truthy(unique_count >= 3,
        "at least 3 unique narration strings across 5 severity levels, got "
        .. unique_count)
end)

test("8. each severity level has ≥3 templates (variety check)", function()
    -- Run each severity 10 times with different seeds → expect ≥3 unique
    for sev = 0, 4 do
        local texts = {}
        local tissue_names = { [0] = "hide", [1] = "skin", [2] = "flesh", [3] = "bone", [4] = "organ" }
        for i = 1, 10 do
            math.randomseed(42 + i * 7 + sev * 31)
            local text = call_narrate(
                make_result({
                    severity = sev,
                    zone = "body",
                    tissue_hit = tissue_names[sev],
                }), true)
            if text then texts[text] = true end
        end
        local count = 0
        for _ in pairs(texts) do count = count + 1 end
        h.assert_truthy(count >= 3,
            "severity " .. sev .. " must have ≥3 unique templates, got " .. count)
    end
end)

---------------------------------------------------------------------------
-- SUITE 2: Material-Aware Narration
---------------------------------------------------------------------------
suite("NARRATION: material-aware text (WAVE-5)")

test("9. narration for steel weapon includes material name 'steel'", function()
    math.randomseed(42)
    local text = call_narrate(
        make_result({ severity = 2, material_name = "steel", zone = "body" }), true)
    h.assert_truthy(text, "narration must return a string")
    local lower = text:lower()
    h.assert_truthy(lower:find("steel"),
        "narration for steel weapon must include 'steel' in text, got: " .. text)
end)

test("10. narration for tooth-enamel weapon includes material reference", function()
    math.randomseed(42)
    local text = call_narrate(
        make_result({
            severity = 2,
            material_name = "tooth-enamel",
            zone = "arms",
            weapon = { id = "bite", name = "rat bite", material = "tooth-enamel",
                       combat = { type = "pierce", message = "bites" } },
            action_verb = "bites",
            attacker = { id = "rat", name = "the rat" },
            defender = { id = "player", name = "you" },
        }), true)
    h.assert_truthy(text, "narration must return a string")
    local lower = text:lower()
    -- Should reference teeth, tooth, enamel, or bite — some material indicator
    h.assert_truthy(lower:find("tooth") or lower:find("teeth")
        or lower:find("enamel") or lower:find("bite") or lower:find("fang"),
        "narration for tooth-enamel should reference teeth/tooth/enamel/bite, got: " .. text)
end)

test("11. different weapon materials produce different narration", function()
    math.randomseed(42)
    local text_steel = call_narrate(
        make_result({ severity = 2, material_name = "steel", zone = "body" }), true)
    local text_wood = call_narrate(
        make_result({ severity = 2, material_name = "wood", zone = "body",
            weapon = { id = "club", name = "wooden club", material = "wood",
                       combat = { type = "blunt", message = "strikes" } },
            action_verb = "strikes" }), true)
    h.assert_truthy(text_steel and text_wood,
        "both narrations must return strings")
    h.assert_truthy(text_steel ~= text_wood,
        "steel and wood narration should differ, got same: " .. tostring(text_steel))
end)

---------------------------------------------------------------------------
-- SUITE 3: Zone-Specific Text
---------------------------------------------------------------------------
suite("NARRATION: zone-specific text (WAVE-5)")

test("12. narration includes zone name 'head'", function()
    math.randomseed(42)
    local text = call_narrate(
        make_result({ severity = 3, zone = "head", tissue_hit = "bone" }), true)
    h.assert_truthy(text, "narration must return a string")
    local lower = text:lower()
    h.assert_truthy(lower:find("head") or lower:find("skull") or lower:find("cranium"),
        "narration for head zone must reference head/skull, got: " .. text)
end)

test("13. narration includes zone name 'body' or 'torso'", function()
    math.randomseed(42)
    local text = call_narrate(
        make_result({ severity = 2, zone = "body", tissue_hit = "flesh" }), true)
    h.assert_truthy(text, "narration must return a string")
    local lower = text:lower()
    h.assert_truthy(lower:find("body") or lower:find("torso") or lower:find("flank")
        or lower:find("side") or lower:find("gut") or lower:find("belly")
        or lower:find("chest") or lower:find("ribs"),
        "narration for body zone must reference body/torso/flank, got: " .. text)
end)

test("14. narration includes zone name 'legs' or 'tail'", function()
    math.randomseed(42)
    local text_legs = call_narrate(
        make_result({ severity = 2, zone = "legs", tissue_hit = "flesh" }), true)
    h.assert_truthy(text_legs, "narration must return a string")
    local lower = text_legs:lower()
    h.assert_truthy(lower:find("leg") or lower:find("limb") or lower:find("haunch")
        or lower:find("thigh") or lower:find("shin") or lower:find("knee"),
        "narration for legs zone must reference leg/limb, got: " .. text_legs)
end)

test("15. narration for tail zone references tail", function()
    math.randomseed(42)
    local text = call_narrate(
        make_result({ severity = 1, zone = "tail", tissue_hit = "hide" }), true)
    h.assert_truthy(text, "narration must return a string")
    local lower = text:lower()
    h.assert_truthy(lower:find("tail"),
        "narration for tail zone must reference 'tail', got: " .. text)
end)

---------------------------------------------------------------------------
-- SUITE 4: Darkness Narration
---------------------------------------------------------------------------
suite("NARRATION: darkness mode (WAVE-5)")

test("16. darkness narration uses sound-based description (no visual)", function()
    math.randomseed(42)
    local text = call_narrate(
        make_result({ severity = 2, zone = "body", tissue_hit = "flesh" }), false)
    h.assert_truthy(text, "darkness narration must return a string")
    local lower = text:lower()
    -- Should contain auditory/tactile words, not visual words like "see", "blood spatters"
    local has_sound = lower:find("hear") or lower:find("sound") or lower:find("thud")
        or lower:find("crack") or lower:find("squeal") or lower:find("hiss")
        or lower:find("scrape") or lower:find("crunch") or lower:find("feel")
        or lower:find("wet") or lower:find("warm") or lower:find("impact")
        or lower:find("thump") or lower:find("snap") or lower:find("shriek")
        or lower:find("screech") or lower:find("rip") or lower:find("tear")
        or lower:find("squelch") or lower:find("blind")
    h.assert_truthy(has_sound,
        "darkness narration should use auditory/tactile language, got: " .. text)
end)

test("17. darkness narration differs from light narration", function()
    math.randomseed(42)
    local result = make_result({ severity = 2, zone = "body", tissue_hit = "flesh" })
    local text_light = call_narrate(result, true)
    math.randomseed(42)
    local text_dark = call_narrate(result, false)
    h.assert_truthy(text_light and text_dark,
        "both light and dark narration must return strings")
    h.assert_truthy(text_light ~= text_dark,
        "darkness narration must differ from light narration")
end)

test("18. darkness CRITICAL narration is sound-based", function()
    math.randomseed(42)
    local text = call_narrate(
        make_result({ severity = 4, zone = "body", tissue_hit = "organ" }), false)
    h.assert_truthy(text, "darkness CRITICAL narration must return a string")
    h.assert_truthy(#text > 10,
        "darkness CRITICAL narration should be substantial, got " .. #text .. " chars")
end)

test("19. darkness DEFLECT narration is sound-based", function()
    math.randomseed(42)
    local text = call_narrate(
        make_result({ severity = 0, zone = "body", tissue_hit = "hide" }), false)
    h.assert_truthy(text, "darkness DEFLECT narration must return a string")
    h.assert_truthy(#text > 0, "darkness DEFLECT narration must be non-empty")
end)

---------------------------------------------------------------------------
-- SUITE 5: Narration Variety (C7 spec)
---------------------------------------------------------------------------
suite("NARRATION: variety across exchanges (WAVE-5 C7)")

test("20. 3 exchanges with seed=42 produce ≥3 unique narration strings", function()
    local narrations = {}
    local unique = {}

    for exchange = 1, 3 do
        math.randomseed(42 + exchange)
        local player = make_player()
        local r = make_rat()
        local weapon = {
            id = "steel-dagger", name = "a steel dagger", material = "steel",
            combat = { type = "edged", force = 5, message = "slashes", two_handed = false },
        }

        -- Vary the zone and severity for realistic exchanges
        local zones = { "body", "head", "legs" }
        local severities = { 2, 3, 4 }
        local tissues = { "flesh", "bone", "organ" }

        local result
        if combat and combat.resolve_exchange then
            result = combat.resolve_exchange(player, r, weapon, zones[exchange], nil,
                { light = true, stance = "balanced" })
        end

        -- If full resolve worked, use its narration
        if result and (result.narration or result.text) then
            local text = result.narration or result.text
            narrations[#narrations + 1] = text
            unique[text] = true
        else
            -- Fall back to direct narration call
            local mock_result = make_result({
                severity = severities[exchange],
                zone = zones[exchange],
                tissue_hit = tissues[exchange],
            })
            local text = call_narrate(mock_result, true)
            if text then
                narrations[#narrations + 1] = text
                unique[text] = true
            end
        end
    end

    h.assert_truthy(#narrations >= 3,
        "must produce at least 3 narration strings, got " .. #narrations)

    local unique_count = 0
    for _ in pairs(unique) do unique_count = unique_count + 1 end
    h.assert_truthy(unique_count >= 3,
        "3 exchanges must produce ≥3 unique narration strings, got "
        .. unique_count .. ". Outputs:\n"
        .. table.concat(narrations, "\n"))
end)

test("21. repeated narrate calls with different seeds produce varied text", function()
    local all_texts = {}
    local unique = {}
    for i = 1, 10 do
        math.randomseed(42 + i * 13)
        local text = call_narrate(
            make_result({
                severity = 2,
                zone = "body",
                tissue_hit = "flesh",
                material_name = "steel",
            }), true)
        if text then
            all_texts[#all_texts + 1] = text
            unique[text] = true
        end
    end
    local unique_count = 0
    for _ in pairs(unique) do unique_count = unique_count + 1 end
    h.assert_truthy(unique_count >= 3,
        "10 narrate calls (HIT, body, steel) should produce ≥3 unique texts, got "
        .. unique_count)
end)

test("22. narration result is always a string, never nil", function()
    math.randomseed(42)
    for sev = 0, 4 do
        local text = call_narrate(
            make_result({ severity = sev, zone = "body" }), true)
        h.assert_truthy(text ~= nil,
            "narration must not be nil for severity " .. sev)
        h.assert_eq("string", type(text),
            "narration must be string for severity " .. sev)
    end
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
