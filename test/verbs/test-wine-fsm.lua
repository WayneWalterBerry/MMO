-- test/verbs/test-wine-fsm.lua
-- Regression tests for BUG-061: Wine bottle FSM transitions.
-- Tests: sealed→open, open→empty (drink/pour), sealed→broken, open→broken.
-- Also tests: drinking sealed bottle fails, type_id matches GUID.
--
-- Usage: lua test/verbs/test-wine-fsm.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local fsm_mod = require("engine.fsm")
local registry_mod = require("engine.registry")

local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function fresh_wine_bottle()
    return {
        id = "wine-bottle",
        name = "a dusty wine bottle",
        keywords = {"bottle", "wine bottle", "wine", "glass bottle"},
        size = 2, weight = 1.5,
        portable = true,
        material = "glass",

        prerequisites = {
            pour = { requires_state = "open" },
            drink = { requires_state = "open" },
        },

        initial_state = "sealed",
        _state = "sealed",

        states = {
            sealed = {
                name = "a dusty wine bottle",
                description = "Sealed with wax-dipped cork.",
                on_feel = "Cool glass, smooth and heavy. Wax seal at the neck. Liquid shifts inside when tilted.",
                on_smell = "Faintly vinegary through the seal.",
                on_taste = "You lick the wax seal. It tastes of dust, old wax, and nothing useful.",
            },
            open = {
                name = "an open wine bottle",
                description = "An open wine bottle.",
                on_feel = "Cool glass, open top. Liquid weight still inside. Wine-sticky neck.",
                on_smell = "Sharp vinegar and old grape.",
                on_taste = "Sour, acidic, old -- but recognizably wine, not poison.",
            },
            empty = {
                name = "an empty wine bottle",
                description = "An empty wine bottle.",
                on_feel = "Light glass, hollow and dry inside. Sticky residue where the wine was.",
                on_smell = "Stale wine residue.",
                on_taste = "You tip the bottle. A single drop of sour dregs.",
                terminal = true,
            },
            broken = {
                name = "a shattered wine bottle",
                description = "Shattered glass.",
                on_feel = "Sharp glass fragments -- dangerous to touch!",
                terminal = true,
            },
        },

        transitions = {
            {
                from = "sealed", to = "open", verb = "open",
                aliases = {"uncork"},
                message = "You pull the cork free with a soft pop.",
                mutate = {
                    weight = function(w) return w - 0.05 end,
                    keywords = { add = "open" },
                },
            },
            {
                from = "open", to = "empty", verb = "drink",
                aliases = {"quaff", "sip", "swig"},
                message = "You take a swig. Sour, old wine.",
                mutate = {
                    contains = nil,
                    weight = 0.5,
                    keywords = { add = "empty" },
                },
            },
            {
                from = "open", to = "empty", verb = "pour",
                message = "Wine glugs out onto the floor.",
                mutate = {
                    contains = nil,
                    weight = 0.4,
                    keywords = { add = "empty" },
                },
            },
            {
                from = "sealed", to = "broken", verb = "break",
                aliases = {"smash", "throw"},
                message = "The bottle shatters.",
            },
            {
                from = "open", to = "broken", verb = "break",
                aliases = {"smash", "throw"},
                message = "The open bottle shatters.",
            },
        },

        mutations = {},
    }
end

local function make_registry_with(obj)
    local reg = registry_mod.new()
    reg:register(obj.id, obj)
    return reg
end

---------------------------------------------------------------------------
-- FSM state management tests
---------------------------------------------------------------------------
suite("wine FSM — initial state")

test("wine bottle starts in sealed state", function()
    local wine = fresh_wine_bottle()
    h.assert_eq("sealed", wine._state, "Initial state should be sealed")
    h.assert_eq("sealed", wine.initial_state, "initial_state field should be sealed")
end)

test("wine bottle has valid FSM structure", function()
    local wine = fresh_wine_bottle()
    local def = fsm_mod.load(wine)
    h.assert_truthy(def, "fsm.load should recognize wine bottle as FSM object")
end)

---------------------------------------------------------------------------
-- sealed → open (verb: open / uncork)
---------------------------------------------------------------------------
suite("wine FSM — sealed → open")

test("open transitions sealed bottle to open state", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    local trans = fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    h.assert_truthy(trans, "Open transition should succeed")
    h.assert_eq("open", wine._state, "State should be open after transition")
end)

test("open transition returns correct message", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    local trans = fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    h.assert_truthy(trans.message:find("cork"), "Message should mention cork")
end)

test("open transition applies weight mutation", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    local original_weight = wine.weight
    fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    h.assert_truthy(wine.weight < original_weight, "Weight should decrease (cork removed)")
end)

test("open transition adds 'open' keyword", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    local found = false
    for _, kw in ipairs(wine.keywords) do
        if kw == "open" then found = true; break end
    end
    h.assert_truthy(found, "Keywords should include 'open' after opening")
end)

test("uncork alias works for open transition", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    local trans = fsm_mod.transition(reg, "wine-bottle", "open", {}, "uncork")
    h.assert_truthy(trans, "Uncork alias should trigger open transition")
    h.assert_eq("open", wine._state, "State should be open after uncork")
end)

---------------------------------------------------------------------------
-- open → empty (verb: drink)
---------------------------------------------------------------------------
suite("wine FSM — open → empty (drink)")

test("drink transitions open bottle to empty state", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    local trans = fsm_mod.transition(reg, "wine-bottle", "empty", {}, "drink")
    h.assert_truthy(trans, "Drink transition should succeed from open state")
    h.assert_eq("empty", wine._state, "State should be empty after drinking")
end)

test("drink transition sets weight to 0.5", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    fsm_mod.transition(reg, "wine-bottle", "empty", {}, "drink")
    h.assert_eq(0.5, wine.weight, "Weight should be 0.5 after drinking")
end)

test("drink transition adds 'empty' keyword", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    fsm_mod.transition(reg, "wine-bottle", "empty", {}, "drink")
    local found = false
    for _, kw in ipairs(wine.keywords) do
        if kw == "empty" then found = true; break end
    end
    h.assert_truthy(found, "Keywords should include 'empty' after drinking")
end)

---------------------------------------------------------------------------
-- BLOCKED: drink from sealed bottle
---------------------------------------------------------------------------
suite("wine FSM — drink from sealed (should fail)")

test("drink from sealed bottle returns no_transition", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    local trans, err = fsm_mod.transition(reg, "wine-bottle", "empty", {}, "drink")
    h.assert_nil(trans, "Should NOT be able to drink from sealed bottle")
    h.assert_eq("no_transition", err, "Error should be no_transition")
    h.assert_eq("sealed", wine._state, "State should remain sealed")
end)

---------------------------------------------------------------------------
-- open → empty (verb: pour)
---------------------------------------------------------------------------
suite("wine FSM — open → empty (pour)")

test("pour transitions open bottle to empty", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    local trans = fsm_mod.transition(reg, "wine-bottle", "empty", {}, "pour")
    h.assert_truthy(trans, "Pour transition should succeed")
    h.assert_eq("empty", wine._state, "State should be empty after pour")
end)

test("pour sets weight to 0.4 (lighter than drink)", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    fsm_mod.transition(reg, "wine-bottle", "empty", {}, "pour")
    h.assert_eq(0.4, wine.weight, "Weight should be 0.4 after pouring")
end)

---------------------------------------------------------------------------
-- sealed → broken (verb: break/smash/throw)
---------------------------------------------------------------------------
suite("wine FSM — sealed → broken")

test("break transitions sealed bottle to broken", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    local trans = fsm_mod.transition(reg, "wine-bottle", "broken", {}, "break")
    h.assert_truthy(trans, "Break transition should succeed from sealed")
    h.assert_eq("broken", wine._state, "State should be broken")
end)

test("smash alias works for break transition", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    local trans = fsm_mod.transition(reg, "wine-bottle", "broken", {}, "smash")
    h.assert_truthy(trans, "Smash alias should trigger break transition")
    h.assert_eq("broken", wine._state, "State should be broken after smash")
end)

---------------------------------------------------------------------------
-- open → broken
---------------------------------------------------------------------------
suite("wine FSM — open → broken")

test("break transitions open bottle to broken", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    local trans = fsm_mod.transition(reg, "wine-bottle", "broken", {}, "break")
    h.assert_truthy(trans, "Break transition should succeed from open")
    h.assert_eq("broken", wine._state, "State should be broken")
end)

---------------------------------------------------------------------------
-- Terminal states block further transitions
---------------------------------------------------------------------------
suite("wine FSM — terminal states")

test("empty bottle blocks further transitions", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    fsm_mod.transition(reg, "wine-bottle", "empty", {}, "drink")
    local trans, err = fsm_mod.transition(reg, "wine-bottle", "broken", {}, "break")
    h.assert_nil(trans, "Should not transition from terminal state")
    h.assert_eq("terminal", err, "Error should be terminal")
end)

test("broken bottle blocks further transitions", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    fsm_mod.transition(reg, "wine-bottle", "broken", {}, "break")
    local trans, err = fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    h.assert_nil(trans, "Should not transition from broken")
    h.assert_eq("terminal", err, "Error should be terminal")
end)

---------------------------------------------------------------------------
-- BUG-061 regression: type_id matches GUID
---------------------------------------------------------------------------
suite("BUG-061 regression — wine bottle instance data")

test("storage-cellar wine-bottle type_id matches wine-bottle.lua GUID", function()
    -- Load the storage cellar room definition
    local cellar_path = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "rooms" .. SEP .. "storage-cellar.lua"
    local f = io.open(cellar_path, "r")
    h.assert_truthy(f, "storage-cellar.lua should exist")
    local content = f:read("*a")
    f:close()

    -- Load the wine bottle object definition
    local wine_path = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "objects" .. SEP .. "wine-bottle.lua"
    f = io.open(wine_path, "r")
    h.assert_truthy(f, "wine-bottle.lua should exist")
    local wine_content = f:read("*a")
    f:close()

    -- Extract GUID from wine-bottle.lua (with braces)
    local wine_guid = wine_content:match('guid%s*=%s*"({[^"]+})"')
    h.assert_truthy(wine_guid, "wine-bottle.lua should have a guid field")

    -- Normalize: strip braces
    local normalized_guid = wine_guid:gsub("^{", ""):gsub("}$", "")

    -- Extract type_id for wine-bottle from storage-cellar.lua
    local type_id = content:match('id%s*=%s*"wine%-bottle".-type_id%s*=%s*"([^"]+)"')
    h.assert_truthy(type_id, "storage-cellar should have wine-bottle instance with type_id")

    -- They must match (BUG-061 was a type_id mismatch)
    h.assert_eq(normalized_guid, type_id,
        "BUG-061: wine-bottle type_id must match wine-bottle.lua GUID")
end)

test("storage-cellar wine-bottle is nested inside wine-rack contents", function()
    local cellar_path = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "rooms" .. SEP .. "storage-cellar.lua"
    local f = io.open(cellar_path, "r")
    h.assert_truthy(f, "storage-cellar.lua should exist")
    local content = f:read("*a")
    f:close()

    -- Deep nesting: wine-bottle must NOT have a flat location field
    local location = content:match('id%s*=%s*"wine%-bottle".-location%s*=%s*"([^"]+)"')
    h.assert_eq(nil, location,
        "BUG-061: wine-bottle should use deep nesting, not flat location")

    -- Verify wine-bottle appears inside wine-rack's contents block
    local rack_block = content:match('id%s*=%s*"wine%-rack"(.-)%},%s*%}')
    h.assert_truthy(rack_block, "wine-rack block should exist in storage-cellar")
    h.assert_truthy(rack_block:find('contents'), "wine-rack should have contents table")
    h.assert_truthy(rack_block:find('"wine%-bottle"'), "wine-bottle should be nested in wine-rack contents")
end)

test("wine-rack surfaces.inside.contents includes wine-bottle", function()
    local rack_path = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "objects" .. SEP .. "wine-rack.lua"
    local f = io.open(rack_path, "r")
    h.assert_truthy(f, "wine-rack.lua should exist")
    local content = f:read("*a")
    f:close()

    h.assert_truthy(content:find('"wine%-bottle"'),
        "wine-rack contents should reference wine-bottle")
end)

---------------------------------------------------------------------------
-- FSM get_transitions from different states
---------------------------------------------------------------------------
suite("wine FSM — get_transitions")

test("sealed state offers open and break transitions", function()
    local wine = fresh_wine_bottle()
    local transitions = fsm_mod.get_transitions(wine)
    local verbs = {}
    for _, t in ipairs(transitions) do verbs[t.verb] = true end
    h.assert_truthy(verbs["open"], "Sealed state should offer open")
    h.assert_truthy(verbs["break"], "Sealed state should offer break")
    h.assert_truthy(not verbs["drink"], "Sealed state should NOT offer drink")
    h.assert_truthy(not verbs["pour"], "Sealed state should NOT offer pour")
end)

test("open state offers drink, pour, and break transitions", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    local transitions = fsm_mod.get_transitions(wine)
    local verbs = {}
    for _, t in ipairs(transitions) do verbs[t.verb] = true end
    h.assert_truthy(verbs["drink"], "Open state should offer drink")
    h.assert_truthy(verbs["pour"], "Open state should offer pour")
    h.assert_truthy(verbs["break"], "Open state should offer break")
    h.assert_truthy(not verbs["open"], "Open state should NOT offer open")
end)

---------------------------------------------------------------------------
-- BUG-061 regression: sensory descriptions change with state
---------------------------------------------------------------------------
suite("BUG-061 regression — sensory per state")

test("sealed state has wax-seal on_feel", function()
    local wine = fresh_wine_bottle()
    local state_data = wine.states[wine._state]
    h.assert_truthy(state_data.on_feel:find("Wax seal"), "Sealed feel should mention wax seal")
end)

test("open state has open-top on_feel", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    local state_data = wine.states[wine._state]
    h.assert_truthy(state_data.on_feel:find("open top"), "Open feel should mention open top")
end)

test("sealed on_smell differs from open on_smell", function()
    local wine = fresh_wine_bottle()
    local sealed_smell = wine.states["sealed"].on_smell
    local open_smell = wine.states["open"].on_smell
    h.assert_truthy(sealed_smell ~= open_smell, "Smell should change after opening")
end)

test("open state on_taste confirms wine not poison", function()
    local wine = fresh_wine_bottle()
    local taste = wine.states["open"].on_taste
    h.assert_truthy(taste:find("not poison"), "Open taste should distinguish wine from poison")
end)

test("empty state on_feel is hollow and dry", function()
    local wine = fresh_wine_bottle()
    local feel = wine.states["empty"].on_feel
    h.assert_truthy(feel:find("hollow"), "Empty feel should mention hollow")
end)

---------------------------------------------------------------------------
-- BUG-061 regression: pour from sealed blocked
---------------------------------------------------------------------------
suite("BUG-061 regression — pour from sealed blocked")

test("pour from sealed bottle returns no_transition", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    local trans, err = fsm_mod.transition(reg, "wine-bottle", "empty", {}, "pour")
    h.assert_nil(trans, "Should NOT be able to pour from sealed bottle")
    h.assert_eq("no_transition", err, "Error should be no_transition")
    h.assert_eq("sealed", wine._state, "State should remain sealed")
end)

---------------------------------------------------------------------------
-- BUG-061 regression: drink aliases (quaff, sip, swig)
---------------------------------------------------------------------------
suite("BUG-061 regression — drink aliases")

test("quaff alias transitions open bottle to empty", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    local trans = fsm_mod.transition(reg, "wine-bottle", "empty", {}, "quaff")
    h.assert_truthy(trans, "Quaff should trigger drink transition")
    h.assert_eq("empty", wine._state, "State should be empty after quaff")
end)

test("sip alias transitions open bottle to empty", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    local trans = fsm_mod.transition(reg, "wine-bottle", "empty", {}, "sip")
    h.assert_truthy(trans, "Sip should trigger drink transition")
    h.assert_eq("empty", wine._state, "State should be empty after sip")
end)

test("swig alias transitions open bottle to empty", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    local trans = fsm_mod.transition(reg, "wine-bottle", "empty", {}, "swig")
    h.assert_truthy(trans, "Swig should trigger drink transition")
    h.assert_eq("empty", wine._state, "State should be empty after swig")
end)

---------------------------------------------------------------------------
-- BUG-061 regression: throw alias for break
---------------------------------------------------------------------------
suite("BUG-061 regression — throw alias")

test("throw alias breaks sealed bottle", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)
    local trans = fsm_mod.transition(reg, "wine-bottle", "broken", {}, "throw")
    h.assert_truthy(trans, "Throw should trigger break transition")
    h.assert_eq("broken", wine._state, "State should be broken after throw")
end)

---------------------------------------------------------------------------
-- BUG-061 regression: full puzzle chain (sealed→open→empty)
---------------------------------------------------------------------------
suite("BUG-061 regression — full puzzle chain")

test("complete wine puzzle: sealed → open → empty", function()
    local wine = fresh_wine_bottle()
    local reg = make_registry_with(wine)

    h.assert_eq("sealed", wine._state, "Start sealed")

    local t1 = fsm_mod.transition(reg, "wine-bottle", "open", {}, "open")
    h.assert_truthy(t1, "Open should succeed")
    h.assert_eq("open", wine._state, "Now open")

    local t2 = fsm_mod.transition(reg, "wine-bottle", "empty", {}, "drink")
    h.assert_truthy(t2, "Drink should succeed")
    h.assert_eq("empty", wine._state, "Now empty")
    h.assert_eq(0.5, wine.weight, "Final weight 0.5")

    local t3, err = fsm_mod.transition(reg, "wine-bottle", "broken", {}, "break")
    h.assert_nil(t3, "Cannot break from terminal empty")
    h.assert_eq("terminal", err, "Terminal blocks further transitions")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
