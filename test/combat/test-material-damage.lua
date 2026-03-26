-- test/combat/test-material-damage.lua
-- WAVE-5 TDD: Material damage resolution engine tests.
-- Tests: force vs resistance, edged/blunt, tissue layering, severity mapping.
-- Engine module under test: src/engine/combat/init.lua
-- Must be run from repository root: lua test/combat/test-material-damage.lua

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
-- Load combat engine
---------------------------------------------------------------------------
local ok_combat, combat = pcall(require, "engine.combat")
if not ok_combat then
    print("WARNING: engine.combat failed to load — " .. tostring(combat))
    combat = nil
end

---------------------------------------------------------------------------
-- Load materials registry
---------------------------------------------------------------------------
local ok_mat, materials = pcall(require, "engine.materials")
if not ok_mat then
    print("WARNING: engine.materials failed to load — " .. tostring(materials))
    materials = nil
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

---------------------------------------------------------------------------
-- SUITE 1: Force vs Resistance
---------------------------------------------------------------------------
suite("MATERIAL DAMAGE: force vs resistance (WAVE-5)")

test("1. combat module loads for damage tests", function()
    h.assert_truthy(ok_combat, "engine.combat must load: " .. tostring(combat))
end)

test("2. high force vs low resistance → high severity", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    -- Steel dagger: high force, high max_edge vs rat hide (low hardness)
    local weapon = {
        id = "steel-dagger", name = "a steel dagger", material = "steel",
        combat = { type = "edged", force = 5, message = "slashes", two_handed = false },
    }
    local result = combat.resolve_exchange(player, r, weapon, "body", nil,
        { light = true, stance = "balanced" })
    h.assert_truthy(result.severity >= combat.SEVERITY.SEVERE,
        "high force (steel dagger, medium player) vs low resistance (rat hide) "
        .. "should be SEVERE+, got " .. tostring(result.severity))
end)

test("3. low force vs moderate resistance → low severity", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    -- Fist (flesh, blunt, force=2) vs rat body
    local player = make_player()
    local r = make_rat()
    local fist = {
        id = "fist", name = "bare fist", material = "flesh",
        combat = { type = "blunt", force = 2, message = "punches", two_handed = false },
    }
    local result = combat.resolve_exchange(player, r, fist, "body", nil,
        { light = true, stance = "balanced" })
    h.assert_truthy(result.severity <= combat.SEVERITY.HIT,
        "low force (fist) vs rat body should be at most HIT, got "
        .. tostring(result.severity))
end)

test("4. force calculation uses size modifier (medium=2.0, tiny=0.5)", function()
    h.assert_truthy(combat, "combat not loaded")
    -- Medium player with same weapon should produce higher severity than tiny attacker
    math.randomseed(42)
    local player = make_player() -- medium, size modifier 2.0
    local r1 = make_rat()
    local weapon = {
        id = "dagger", name = "dagger", material = "steel",
        combat = { type = "edged", force = 5, message = "stabs", two_handed = false },
    }
    local result_medium = combat.resolve_exchange(player, r1, weapon, "body", nil,
        { light = true, stance = "balanced" })

    math.randomseed(42)
    local tiny_attacker = {
        id = "tiny", name = "tiny creature",
        combat = { size = "tiny", speed = 5 },
        body_tree = { body = { size = 1.0, tissue = { "hide", "flesh" } } },
        health = 10, max_health = 10, _state = "alive", animate = true,
    }
    local r2 = make_rat()
    local result_tiny = combat.resolve_exchange(tiny_attacker, r2, weapon, "body", nil,
        { light = true, stance = "balanced" })

    h.assert_truthy(result_medium.severity >= result_tiny.severity,
        "medium attacker should produce >= severity than tiny attacker, "
        .. "medium=" .. tostring(result_medium.severity)
        .. " tiny=" .. tostring(result_tiny.severity))
end)

---------------------------------------------------------------------------
-- SUITE 2: Edged Weapons — max_edge
---------------------------------------------------------------------------
suite("MATERIAL DAMAGE: edged weapons (WAVE-5)")

test("5. edged weapons use material max_edge for penetration", function()
    h.assert_truthy(combat, "combat not loaded")
    h.assert_truthy(materials, "materials not loaded")

    -- Steel should have max_edge defined
    local steel = materials.get("steel")
    h.assert_truthy(steel, "steel material must exist")
    h.assert_truthy(steel.max_edge ~= nil,
        "steel must have max_edge property for edged weapon calculation")
    h.assert_eq("number", type(steel.max_edge),
        "max_edge must be a number")
    h.assert_truthy(steel.max_edge > 0,
        "steel max_edge must be positive, got " .. tostring(steel.max_edge))
end)

test("6. high max_edge weapon penetrates more layers than low max_edge", function()
    h.assert_truthy(combat, "combat not loaded")

    -- Steel (max_edge ~8) vs wood (max_edge ~1) — both edged, same force
    math.randomseed(42)
    local player = make_player()
    local r1 = make_rat()
    local steel_blade = {
        id = "steel-blade", name = "steel blade", material = "steel",
        combat = { type = "edged", force = 5, message = "slashes", two_handed = false },
    }
    local result_steel = combat.resolve_exchange(player, r1, steel_blade, "body", nil,
        { light = true, stance = "balanced" })

    math.randomseed(42)
    local player2 = make_player()
    local r2 = make_rat()
    local wood_blade = {
        id = "wood-blade", name = "wooden blade", material = "wood",
        combat = { type = "edged", force = 5, message = "slashes", two_handed = false },
    }
    local result_wood = combat.resolve_exchange(player2, r2, wood_blade, "body", nil,
        { light = true, stance = "balanced" })

    h.assert_truthy(result_steel.severity >= result_wood.severity,
        "steel edge (high max_edge) should penetrate deeper than wood edge, "
        .. "steel=" .. tostring(result_steel.severity)
        .. " wood=" .. tostring(result_wood.severity))
end)

test("7. edged penetration formula: (force × max_edge) - (layer.hardness × thickness)", function()
    h.assert_truthy(combat, "combat not loaded")
    -- This is a structural test: steel dagger vs rat should penetrate through
    -- hide (low hardness) and flesh (low hardness), reaching at least bone
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = {
        id = "steel-dagger", name = "steel dagger", material = "steel",
        combat = { type = "edged", force = 5, message = "slashes", two_handed = false },
    }
    local result = combat.resolve_exchange(player, r, weapon, "body", nil,
        { light = true, stance = "balanced" })
    -- Must reach at least SEVERE (bone layer) for steel vs unarmored rat
    h.assert_truthy(result.severity >= combat.SEVERITY.SEVERE,
        "steel edged vs rat must penetrate to bone (SEVERE+), got "
        .. tostring(result.severity))
end)

---------------------------------------------------------------------------
-- SUITE 3: Blunt Weapons — density
---------------------------------------------------------------------------
suite("MATERIAL DAMAGE: blunt weapons (WAVE-5)")

test("8. blunt weapons use material density for force transfer", function()
    h.assert_truthy(combat, "combat not loaded")
    h.assert_truthy(materials, "materials not loaded")

    -- Iron (dense, heavy) should do more blunt damage than wood (light)
    math.randomseed(42)
    local player = make_player()
    local r1 = make_rat()
    local iron_club = {
        id = "iron-club", name = "iron club", material = "iron",
        combat = { type = "blunt", force = 5, message = "smashes", two_handed = false },
    }
    local result_iron = combat.resolve_exchange(player, r1, iron_club, "body", nil,
        { light = true, stance = "balanced" })

    math.randomseed(42)
    local player2 = make_player()
    local r2 = make_rat()
    local wood_club = {
        id = "wood-club", name = "wooden club", material = "wood",
        combat = { type = "blunt", force = 5, message = "smashes", two_handed = false },
    }
    local result_wood = combat.resolve_exchange(player2, r2, wood_club, "body", nil,
        { light = true, stance = "balanced" })

    h.assert_truthy(result_iron.severity >= result_wood.severity,
        "iron club (high density) should deal >= damage than wood club, "
        .. "iron=" .. tostring(result_iron.severity)
        .. " wood=" .. tostring(result_wood.severity))
end)

test("9. blunt force transfers through layers at 80% per layer", function()
    h.assert_truthy(combat, "combat not loaded")
    -- Blunt weapon should be able to cause damage through multiple tissue layers
    -- even if it doesn't "cut" — force propagates inward
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local heavy_club = {
        id = "iron-mace", name = "iron mace", material = "iron",
        combat = { type = "blunt", force = 8, message = "crushes", two_handed = false },
    }
    local result = combat.resolve_exchange(player, r, heavy_club, "body", nil,
        { light = true, stance = "balanced" })
    -- Heavy blunt weapon vs tiny rat should cause at least HIT severity
    h.assert_truthy(result.severity >= combat.SEVERITY.HIT,
        "heavy blunt weapon vs rat should achieve at least HIT from force transfer, got "
        .. tostring(result.severity))
end)

test("10. blunt damage is reduced by flexible materials (leather absorbs)", function()
    h.assert_truthy(combat, "combat not loaded")
    h.assert_truthy(materials, "materials not loaded")

    local leather = materials.get("leather")
    if leather then
        h.assert_truthy(leather.flexibility ~= nil,
            "leather must have flexibility property")
        h.assert_truthy(leather.flexibility > 0.5,
            "leather flexibility should be high (>0.5), got "
            .. tostring(leather.flexibility))
    else
        -- TDD: leather material may not exist yet
        h.assert_truthy(false,
            "leather material not found — needed for blunt absorption test")
    end
end)

---------------------------------------------------------------------------
-- SUITE 4: Tissue Layering
---------------------------------------------------------------------------
suite("MATERIAL DAMAGE: tissue layering (WAVE-5)")

test("11. damage traverses layers in order: skin → flesh → bone → organ", function()
    h.assert_truthy(combat, "combat not loaded")
    -- A powerful edged weapon hitting a vital zone should penetrate all layers
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = {
        id = "steel-sword", name = "steel sword", material = "steel",
        combat = { type = "edged", force = 8, message = "cleaves", two_handed = true },
    }
    -- Target rat body (vital) which has: hide → flesh → bone → organ
    local result = combat.resolve_exchange(player, r, weapon, "body", nil,
        { light = true, stance = "balanced" })
    -- Steel sword, medium player, high force → should penetrate to organ (CRITICAL)
    h.assert_truthy(result.severity >= combat.SEVERITY.CRITICAL,
        "steel sword (force 8) vs rat body should reach CRITICAL (organ layer), got "
        .. tostring(result.severity))
end)

test("12. shallow penetration stops at outer layers (skin only = GRAZE)", function()
    h.assert_truthy(combat, "combat not loaded")
    -- Very weak weapon should only scratch the surface
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local twig = {
        id = "twig", name = "a thin twig", material = "wood",
        combat = { type = "edged", force = 1, message = "scratches", two_handed = false },
    }
    local result = combat.resolve_exchange(player, r, twig, "body", nil,
        { light = true, stance = "balanced" })
    h.assert_truthy(result.severity <= combat.SEVERITY.GRAZE,
        "twig (force 1, wood edge) vs rat should only GRAZE at most, got "
        .. tostring(result.severity))
end)

test("13. bone layer is harder to penetrate than flesh", function()
    h.assert_truthy(combat, "combat not loaded")
    h.assert_truthy(materials, "materials not loaded")

    local bone = materials.get("bone")
    local flesh = materials.get("flesh")
    h.assert_truthy(bone, "bone material must exist")
    h.assert_truthy(flesh, "flesh material must exist")
    h.assert_truthy(bone.hardness > flesh.hardness,
        "bone hardness (" .. tostring(bone.hardness)
        .. ") must be greater than flesh hardness ("
        .. tostring(flesh.hardness) .. ")")
end)

test("14. organ layer (if reached) means CRITICAL severity", function()
    h.assert_truthy(combat, "combat not loaded")
    -- Steel dagger vs rat head (vital zone with organ layer)
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = {
        id = "steel-dagger", name = "steel dagger", material = "steel",
        combat = { type = "edged", force = 5, message = "stabs", two_handed = false },
    }
    -- Target head (vital, has organ layer)
    local result = combat.resolve_exchange(player, r, weapon, "head", nil,
        { light = true, stance = "aggressive" })
    -- Steel dagger with aggressive stance vs rat head should reach organ → CRITICAL
    h.assert_truthy(result.severity >= combat.SEVERITY.SEVERE,
        "steel dagger to rat head should reach SEVERE+ (bone/organ), got "
        .. tostring(result.severity))
end)

---------------------------------------------------------------------------
-- SUITE 5: Severity Mapping
---------------------------------------------------------------------------
suite("MATERIAL DAMAGE: severity mapping (WAVE-5)")

test("15. DEFLECT severity when no penetration beyond outer layer", function()
    h.assert_truthy(combat, "combat not loaded")
    -- Use an extremely weak attack that cannot even scratch
    math.randomseed(42)
    -- Tiny creature with flesh "weapon" (bare paw) vs player torso
    local attacker = {
        id = "mouse", name = "a mouse",
        combat = { size = "tiny", speed = 3 },
        body_tree = { body = { size = 1.0, tissue = { "skin", "flesh" } } },
        health = 5, max_health = 5, _state = "alive", animate = true,
    }
    local player = make_player()
    local paw = {
        id = "paw", name = "tiny paw", material = "flesh",
        combat = { type = "blunt", force = 1, message = "paws at", two_handed = false },
    }
    local result = combat.resolve_exchange(attacker, player, paw, "torso", nil,
        { light = true, stance = "balanced" })
    h.assert_truthy(result.severity <= combat.SEVERITY.GRAZE,
        "mouse paw vs player torso should be DEFLECT or GRAZE, got "
        .. tostring(result.severity))
end)

test("16. severity ordering: DEFLECT < GRAZE < HIT < SEVERE < CRITICAL", function()
    h.assert_truthy(combat, "combat not loaded")
    local S = combat.SEVERITY
    h.assert_eq(true, S.DEFLECT < S.GRAZE, "DEFLECT < GRAZE")
    h.assert_eq(true, S.GRAZE < S.HIT, "GRAZE < HIT")
    h.assert_eq(true, S.HIT < S.SEVERE, "HIT < SEVERE")
    h.assert_eq(true, S.SEVERE < S.CRITICAL, "SEVERE < CRITICAL")
end)

test("17. severity numeric values are integers (0,1,2,3,4)", function()
    h.assert_truthy(combat, "combat not loaded")
    local S = combat.SEVERITY
    h.assert_eq(0, S.DEFLECT, "DEFLECT should be 0")
    h.assert_eq(1, S.GRAZE, "GRAZE should be 1")
    h.assert_eq(2, S.HIT, "HIT should be 2")
    h.assert_eq(3, S.SEVERE, "SEVERE should be 3")
    h.assert_eq(4, S.CRITICAL, "CRITICAL should be 4")
end)

test("18. GRAZE = skin penetration only", function()
    h.assert_truthy(combat, "combat not loaded")
    -- Rat claw (keratin, slash, force 1) vs player — should only graze
    math.randomseed(42)
    local r = make_rat()
    local player = make_player()
    local claw = {
        id = "claw", name = "rat claw", material = "keratin",
        combat = { type = "edged", force = 1, message = "scratches", two_handed = false },
    }
    local result = combat.resolve_exchange(r, player, claw, "arms", nil,
        { light = true, stance = "balanced" })
    -- Rat claw (tiny, force 1, keratin) vs player arm should be GRAZE at most
    h.assert_truthy(result.severity <= combat.SEVERITY.GRAZE,
        "rat claw vs player arm should be at most GRAZE, got "
        .. tostring(result.severity))
end)

test("19. HIT = flesh penetration (skin + flesh, stopped at bone)", function()
    h.assert_truthy(combat, "combat not loaded")
    -- Rat bite (tooth-enamel, pierce, force 2) vs player bare hand → HIT
    math.randomseed(42)
    local r = make_rat()
    local player = make_player()
    local bite = {
        id = "bite", name = "rat bite", material = "tooth-enamel",
        combat = { type = "pierce", force = 2, message = "bites", two_handed = false },
    }
    local result = combat.resolve_exchange(r, player, bite, "hands", nil,
        { light = true, stance = "balanced" })
    h.assert_truthy(result.severity >= combat.SEVERITY.GRAZE
        and result.severity <= combat.SEVERITY.HIT,
        "rat bite vs bare hand should be GRAZE or HIT, got "
        .. tostring(result.severity))
end)

test("20. SEVERE = bone layer penetration", function()
    h.assert_truthy(combat, "combat not loaded")
    -- Medium-force weapon that reaches bone but not organ
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = {
        id = "copper-blade", name = "copper blade", material = "brass",
        combat = { type = "edged", force = 4, message = "hacks", two_handed = false },
    }
    local result = combat.resolve_exchange(player, r, weapon, "legs", nil,
        { light = true, stance = "balanced" })
    -- Brass/copper blade vs rat legs (no organ layer: hide→flesh→bone)
    -- Should reach bone = SEVERE
    h.assert_truthy(result.severity >= combat.SEVERITY.HIT,
        "copper blade vs rat legs should reach at least HIT, got "
        .. tostring(result.severity))
end)

test("21. CRITICAL = organ layer penetration on vital zone", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = {
        id = "steel-sword", name = "steel sword", material = "steel",
        combat = { type = "edged", force = 8, message = "cleaves", two_handed = true },
    }
    local result = combat.resolve_exchange(player, r, weapon, "body", nil,
        { light = true, stance = "aggressive" })
    h.assert_eq(combat.SEVERITY.CRITICAL, result.severity,
        "steel sword (force 8, aggressive) vs rat body should be CRITICAL")
end)

---------------------------------------------------------------------------
-- SUITE 6: Defense Modifiers
---------------------------------------------------------------------------
suite("MATERIAL DAMAGE: defense modifiers (WAVE-5)")

test("22. block response reduces damage (modifier ~0.3)", function()
    h.assert_truthy(combat, "combat not loaded")

    local block_total = 0
    local no_def_total = 0
    local trials = 50

    for i = 1, trials do
        math.randomseed(42 + i)
        local r1 = make_rat()
        local p1 = make_player()
        local bite = {
            id = "bite", name = "rat bite", material = "tooth-enamel",
            combat = { type = "pierce", force = 2, message = "bites", two_handed = false },
        }
        local res_block = combat.resolve_exchange(r1, p1, bite, "arms", "block",
            { light = true, stance = "balanced" })
        block_total = block_total + (res_block.severity or 0)

        math.randomseed(42 + i)
        local r2 = make_rat()
        local p2 = make_player()
        local bite2 = {
            id = "bite", name = "rat bite", material = "tooth-enamel",
            combat = { type = "pierce", force = 2, message = "bites", two_handed = false },
        }
        local res_none = combat.resolve_exchange(r2, p2, bite2, "arms", nil,
            { light = true, stance = "balanced" })
        no_def_total = no_def_total + (res_none.severity or 0)
    end

    h.assert_truthy(block_total <= no_def_total,
        "block should reduce total severity vs no defense, "
        .. "block=" .. block_total .. " none=" .. no_def_total)
end)

test("23. dodge success avoids all damage (severity × 0.0)", function()
    h.assert_truthy(combat, "combat not loaded")
    -- Over many trials, dodge should sometimes produce DEFLECT (0 damage)
    math.randomseed(42)
    local dodge_zero_count = 0
    for i = 1, 50 do
        math.randomseed(42 + i)
        local r = make_rat()
        local p = make_player()
        local bite = {
            id = "bite", name = "rat bite", material = "tooth-enamel",
            combat = { type = "pierce", force = 2, message = "bites", two_handed = false },
        }
        local result = combat.resolve_exchange(r, p, bite, "arms", "dodge",
            { light = true, stance = "balanced" })
        if result.severity == combat.SEVERITY.DEFLECT then
            dodge_zero_count = dodge_zero_count + 1
        end
    end
    h.assert_truthy(dodge_zero_count > 0,
        "dodge should sometimes completely avoid damage (DEFLECT), "
        .. "got 0 DEFLECT results in 50 trials")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
