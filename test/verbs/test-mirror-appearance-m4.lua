-- test/verbs/test-mirror-appearance-m4.lua
-- Phase M4: Mirror/Appearance Quality Regression Tests
-- Filed by Nelson (QA) — tests mirror output quality, completeness, and
-- composition for various player states.
--
-- Tracks issues: #90 (worn cloak invisible), #91 (double period),
--   #92 (duplicate injury collapse), #93 (severity not set),
--   #94 (hands grammar), #95 (overall double-and)
--
-- Usage: lua test/verbs/test-mirror-appearance-m4.lua
-- Must be run from repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite
local eq = h.assert_eq
local truthy = h.assert_truthy

local appearance = require("engine.player.appearance")

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function make_mock_registry(objects)
    return {
        _objects = objects or {},
        get = function(self, id) return self._objects[id] end,
        register = function(self, id, obj) self._objects[id] = obj end,
        remove = function(self, id) self._objects[id] = nil end,
    }
end

local function fresh_player(overrides)
    local p = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {},
        consciousness = { state = "conscious" },
        state = {},
    }
    if overrides then
        for k, v in pairs(overrides) do p[k] = v end
    end
    return p
end

local function make_injury(type_name, location, opts)
    opts = opts or {}
    return {
        type = type_name or "bleeding",
        location = location or "left arm",
        _state = opts._state or "active",
        severity = opts.severity,
        damage = opts.damage or 5,
        damage_per_tick = opts.damage_per_tick or 0,
        source = opts.source or "knife",
    }
end

---------------------------------------------------------------------------
-- TEST 1: Fresh player — no injuries, empty hands
---------------------------------------------------------------------------
suite("M4-T1: Fresh player (no injuries, no items)")

test("healthy player shows overall health description", function()
    local player = fresh_player()
    local desc = appearance.describe(player, nil)
    truthy(desc:find("healthy") or desc:find("alert") or desc:find("unremarkable"),
        "Fresh player should show healthy state, got: " .. desc)
end)

test("output starts with 'In the mirror' prefix", function()
    local player = fresh_player()
    local desc = appearance.describe(player, nil)
    truthy(desc:find("^In the mirror"),
        "Should start with mirror prefix, got: " .. desc)
end)

test("output ends with punctuation", function()
    local player = fresh_player()
    local desc = appearance.describe(player, nil)
    truthy(desc:match("[%.!?]$"),
        "Should end with punctuation, got: " .. desc)
end)

---------------------------------------------------------------------------
-- TEST 2: Injured player — single wound
---------------------------------------------------------------------------
suite("M4-T2: Single injury")

test("single arm injury appears in mirror", function()
    local player = fresh_player({
        injuries = { make_injury("bleeding", "left arm") },
    })
    local desc = appearance.describe(player, nil)
    truthy(desc:find("arm") or desc:find("gash") or desc:find("wound"),
        "Should show arm injury, got: " .. desc)
end)

test("injury location is mentioned", function()
    local player = fresh_player({
        injuries = { make_injury("bleeding", "left arm") },
    })
    local desc = appearance.describe(player, nil)
    truthy(desc:find("left arm"),
        "Should mention 'left arm', got: " .. desc)
end)

---------------------------------------------------------------------------
-- TEST 3: Bleeding player — blood state
---------------------------------------------------------------------------
suite("M4-T3: Bleeding player (bloody state)")

test("bloody state shows dried blood", function()
    local player = fresh_player({
        injuries = { make_injury("bleeding", "stomach") },
        state = { bloody = true },
    })
    local desc = appearance.describe(player, nil)
    truthy(desc:find("blood"),
        "Should mention blood, got: " .. desc)
end)

test("injury on stomach shows in torso layer", function()
    local player = fresh_player({
        injuries = { make_injury("bleeding", "stomach") },
    })
    local desc = appearance.describe(player, nil)
    truthy(desc:find("stomach"),
        "Should mention stomach injury, got: " .. desc)
end)

---------------------------------------------------------------------------
-- TEST 4: Wearing items
---------------------------------------------------------------------------
suite("M4-T4: Worn items")

test("worn helmet with appearance.worn_description shows custom text", function()
    local pot = {
        id = "chamber-pot",
        name = "a ceramic chamber pot",
        wear_slot = "head",
        is_helmet = true,
        appearance = {
            worn_description = "A ceramic chamber pot sits absurdly atop your head.",
        },
    }
    local player = fresh_player({ worn = { "chamber-pot" } })
    local reg = make_mock_registry({ ["chamber-pot"] = pot })
    local desc = appearance.describe(player, reg)
    truthy(desc:find("chamber pot") or desc:find("absurdly"),
        "Should show pot worn_description, got: " .. desc)
end)

test("worn helmet without custom text shows fallback", function()
    local helmet = {
        id = "iron-helm",
        name = "an iron helm",
        wear_slot = "head",
        is_helmet = true,
    }
    local player = fresh_player({ worn = { "iron-helm" } })
    local reg = make_mock_registry({ ["iron-helm"] = helmet })
    local desc = appearance.describe(player, reg)
    truthy(desc:find("iron helm") or desc:find("head"),
        "Should show helmet on head, got: " .. desc)
end)

-- Issue #90: worn cloak with wear.slot (not wear_slot) is invisible
test("[#90] worn item with wear.slot='torso' should show in mirror", function()
    local jacket = {
        id = "terrible-jacket",
        name = "a terrible burlap jacket",
        wear = { slot = "torso", layer = "outer" },
        -- NOTE: no top-level wear_slot field
    }
    local player = fresh_player({ worn = { "terrible-jacket" } })
    local reg = make_mock_registry({ ["terrible-jacket"] = jacket })
    local desc = appearance.describe(player, reg)
    truthy(desc:find("jacket") or desc:find("torso") or desc:find("wearing"),
        "#90 REGRESSION: wear.slot items should be visible, got: " .. desc)
end)

---------------------------------------------------------------------------
-- TEST 5: Holding items
---------------------------------------------------------------------------
suite("M4-T5: Held items")

test("knife in left hand shows in mirror", function()
    local knife = { id = "knife", name = "a small knife" }
    local player = fresh_player({ hands = { knife, nil } })
    local reg = make_mock_registry({ knife = knife })
    local desc = appearance.describe(player, reg)
    truthy(desc:find("knife"),
        "Should show held knife, got: " .. desc)
    truthy(desc:find("left hand"),
        "Should mention left hand, got: " .. desc)
end)

test("items in both hands shown", function()
    local knife = { id = "knife", name = "a small knife" }
    local matchbox = { id = "matchbox", name = "a small matchbox" }
    local player = fresh_player({ hands = { matchbox, knife } })
    local reg = make_mock_registry({ knife = knife, matchbox = matchbox })
    local desc = appearance.describe(player, reg)
    truthy(desc:find("knife"), "Should show knife, got: " .. desc)
    truthy(desc:find("matchbox"), "Should show matchbox, got: " .. desc)
end)

---------------------------------------------------------------------------
-- TEST 6: Multiple injuries — composition
---------------------------------------------------------------------------
suite("M4-T6: Multiple injuries")

test("two injuries at different locations both shown", function()
    local player = fresh_player({
        injuries = {
            make_injury("bleeding", "left arm"),
            make_injury("bleeding", "stomach"),
        },
    })
    local desc = appearance.describe(player, nil)
    truthy(desc:find("arm"), "Should show arm injury, got: " .. desc)
    truthy(desc:find("stomach"), "Should show stomach injury, got: " .. desc)
end)

-- Issue #92: duplicate injuries at same location collapsed
test("[#92] two injuries at same location should both be shown", function()
    local player = fresh_player({
        injuries = {
            make_injury("bleeding", "right hand"),
            make_injury("bleeding", "right hand"),
        },
    })
    local desc = appearance.describe(player, nil)
    -- Count occurrences of "gash" or "wound" to verify both appear
    local count = 0
    for _ in desc:gmatch("gash") do count = count + 1 end
    if count < 2 then
        for _ in desc:gmatch("wound") do count = count + 1 end
    end
    truthy(count >= 2,
        "#92 REGRESSION: two injuries at same spot should both show, got: " .. desc)
end)

---------------------------------------------------------------------------
-- TEST 7: Low health tiers
---------------------------------------------------------------------------
suite("M4-T7: Health tiers in mirror")

test("76-100% health shows healthy/alert", function()
    local player = fresh_player({
        injuries = { make_injury("bleeding", "left arm", { damage = 10 }) },
    })
    local desc = appearance.describe(player, nil)
    truthy(desc:find("healthy") or desc:find("alert"),
        "76-100% health should show healthy, got: " .. desc)
end)

test("51-75% health shows worn but standing", function()
    local player = fresh_player({
        injuries = { make_injury("bleeding", "torso", { damage = 40 }) },
    })
    local desc = appearance.describe(player, nil)
    truthy(desc:find("worn") or desc:find("standing"),
        "51-75% health should show worn/standing, got: " .. desc)
end)

test("26-50% health shows pale and unsteady", function()
    local player = fresh_player({
        injuries = { make_injury("bleeding", "torso", { damage = 60 }) },
    })
    local desc = appearance.describe(player, nil)
    truthy(desc:find("pale") or desc:find("unsteady"),
        "26-50% health should show pale/unsteady, got: " .. desc)
end)

test("0-25% health shows deathly pale", function()
    local player = fresh_player({
        injuries = { make_injury("bleeding", "torso", { damage = 80 }) },
    })
    local desc = appearance.describe(player, nil)
    truthy(desc:find("deathly") or desc:find("sunken"),
        "0-25% health should show deathly pale, got: " .. desc)
end)

---------------------------------------------------------------------------
-- TEST 8: Unconscious guard
---------------------------------------------------------------------------
suite("M4-T8: Unconscious player")

test("unconscious player gets rejection message", function()
    local player = fresh_player({
        consciousness = { state = "unconscious" },
    })
    local desc = appearance.describe(player, nil)
    truthy(desc:find("unconscious"),
        "Should mention unconsciousness, got: " .. desc)
    truthy(desc:find("can't") or desc:find("cannot"),
        "Should say can't examine, got: " .. desc)
end)

test("waking player also gets rejection", function()
    local player = fresh_player({
        consciousness = { state = "waking" },
    })
    local desc = appearance.describe(player, nil)
    truthy(desc:find("unconscious") or desc:find("can't"),
        "Waking player should be blocked, got: " .. desc)
end)

test("conscious player gets normal appearance", function()
    local player = fresh_player()
    local desc = appearance.describe(player, nil)
    truthy(not desc:find("unconscious"),
        "Conscious player should NOT see unconscious message, got: " .. desc)
end)

---------------------------------------------------------------------------
-- QUALITY: Punctuation checks
---------------------------------------------------------------------------
suite("M4-Q: Punctuation quality")

-- Issue #91: double period from worn_description trailing period
test("[#91] no double periods in output", function()
    local pot = {
        id = "chamber-pot",
        name = "a ceramic chamber pot",
        wear_slot = "head",
        is_helmet = true,
        appearance = {
            worn_description = "A ceramic chamber pot sits absurdly atop your head.",
        },
    }
    local player = fresh_player({ worn = { "chamber-pot" } })
    local reg = make_mock_registry({ ["chamber-pot"] = pot })
    local desc = appearance.describe(player, reg)
    truthy(not desc:find("%.%."),
        "#91 REGRESSION: should not have double period, got: " .. desc)
end)

test("sentences capitalize after period", function()
    local player = fresh_player({
        injuries = { make_injury("bleeding", "left arm") },
        state = { bloody = true },
    })
    local desc = appearance.describe(player, nil)
    -- Check that after ". " the next char is uppercase
    for before, after_char in desc:gmatch("(%.%s+)(%a)") do
        truthy(after_char == after_char:upper(),
            "Letter after period should be capitalized: '" .. before .. after_char .. "' in: " .. desc)
    end
end)

---------------------------------------------------------------------------
-- QUALITY: Composition naturalness
---------------------------------------------------------------------------
suite("M4-Q: Composition naturalness")

-- Issue #93: injury severity adjectives
test("[#93] injuries should have severity adjectives", function()
    local player = fresh_player({
        injuries = {
            make_injury("bleeding", "left arm", { severity = "moderate" }),
        },
    })
    local desc = appearance.describe(player, nil)
    truthy(desc:find("deep") or desc:find("nasty"),
        "#93: moderate injury should show 'deep' or 'nasty', got: " .. desc)
end)

-- Issue #95: overall "and" chain
test("[#95] health tier and blood state should not double-and", function()
    local player = fresh_player({
        injuries = { make_injury("bleeding", "left arm") },
        state = { bloody = true },
    })
    local desc = appearance.describe(player, nil)
    -- Check for "and ... and ... and" triple-and pattern
    local and_count = 0
    for _ in desc:gmatch(" and ") do and_count = and_count + 1 end
    -- "healthy and alert" is one use; "and dried blood" would be a second.
    -- Three or more "and"s in the overall section is awkward.
    local overall_part = desc:match("[Yy]ou appear.*$") or ""
    local overall_and = 0
    for _ in overall_part:gmatch(" and ") do overall_and = overall_and + 1 end
    truthy(overall_and <= 1,
        "#95: overall section has too many 'and' conjunctions (" .. overall_and .. "), got: " .. overall_part)
end)

-- Treated injury
test("treated injury shows bandage", function()
    local player = fresh_player({
        injuries = {
            make_injury("bleeding", "left arm", { _state = "treated" }),
        },
    })
    local desc = appearance.describe(player, nil)
    truthy(desc:find("bandage"),
        "Treated injury should mention bandage, got: " .. desc)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
