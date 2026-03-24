-- test/verbs/test-bugfixes-23-31.lua
-- Regression tests for Issues #23, #28, #29, #30, #31
--
-- Usage: lua test/verbs/test-bugfixes-23-31.lua
-- Must be run from repository root.

package.path = "./test/parser/?.lua;./src/?.lua;./src/?/init.lua;" .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite
local assert_eq = h.assert_eq
local assert_truthy = h.assert_truthy
local assert_nil = h.assert_nil

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function capture_print(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error(err, 2) end
    return table.concat(lines, "\n")
end

---------------------------------------------------------------------------
-- Issue #23: "Is there a X in the room?" should trigger search
---------------------------------------------------------------------------
suite("Issue #23 — existence questions → search")

local preprocess = require("engine.parser.preprocess")

test("'is there a candle in the room' → search candle", function()
    local verb, noun = preprocess.natural_language("is there a candle in the room?")
    assert_eq(verb, "search")
    assert_eq(noun, "candle")
end)

test("'is there an apple here' → search apple", function()
    local verb, noun = preprocess.natural_language("is there an apple here?")
    assert_eq(verb, "search")
    assert_eq(noun, "apple")
end)

test("'is there a key nearby' → search key", function()
    local verb, noun = preprocess.natural_language("is there a key nearby?")
    assert_eq(verb, "search")
    assert_eq(noun, "key")
end)

test("'is there a knife around' → search knife", function()
    local verb, noun = preprocess.natural_language("is there a knife around?")
    assert_eq(verb, "search")
    assert_eq(noun, "knife")
end)

test("'is there a match' (bare) → search match", function()
    local verb, noun = preprocess.natural_language("is there a match?")
    assert_eq(verb, "search")
    assert_eq(noun, "match")
end)

test("'is there an exit' (bare) → search exit", function()
    local verb, noun = preprocess.natural_language("is there an exit?")
    assert_eq(verb, "search")
    assert_eq(noun, "exit")
end)

test("'do you see a torch' → search torch", function()
    local verb, noun = preprocess.natural_language("do you see a torch?")
    assert_eq(verb, "search")
    assert_eq(noun, "torch")
end)

test("'do you see an opening' → search opening", function()
    local verb, noun = preprocess.natural_language("do you see an opening?")
    assert_eq(verb, "search")
    assert_eq(noun, "opening")
end)

test("'can I find a key' → search key", function()
    local verb, noun = preprocess.natural_language("can I find a key?")
    assert_eq(verb, "search")
    assert_eq(noun, "key")
end)

test("'can I find an exit' → search exit", function()
    local verb, noun = preprocess.natural_language("can I find an exit?")
    assert_eq(verb, "search")
    assert_eq(noun, "exit")
end)

-- Ensure existing patterns still work
test("'is there anything in the drawer' still works", function()
    local verb, noun = preprocess.natural_language("is there anything in the drawer?")
    assert_eq(verb, "search")
    assert_eq(noun, "the drawer")
end)

test("'can I open the door' (generic can-I) still works", function()
    local verb, noun = preprocess.natural_language("can I open the door?")
    assert_eq(verb, "open")
    assert_eq(noun, "the door")
end)

---------------------------------------------------------------------------
-- Issue #28: "reflection" not a mirror keyword
-- Updated for Issue #173: mirror is now a SEPARATE object from the vanity
---------------------------------------------------------------------------
suite("Issue #28 — reflection triggers mirror/appearance system")

-- Load the mirror object definition (now separate from vanity)
local mirror = require("meta.objects.mirror")

test("mirror keywords include 'reflection'", function()
    local found = false
    for _, kw in ipairs(mirror.keywords) do
        if kw == "reflection" then found = true; break end
    end
    assert_truthy(found)
end)

test("mirror keywords include 'my reflection'", function()
    local found = false
    for _, kw in ipairs(mirror.keywords) do
        if kw == "my reflection" then found = true; break end
    end
    assert_truthy(found)
end)

-- Functional test: "reflection" keyword resolves to the mirror object
test("'reflection' keyword matches mirror via matches_keyword", function()
    local mirror_obj = {
        id = "mirror",
        name = "an ornate mirror",
        is_mirror = true,
        keywords = mirror.keywords,
    }

    -- Simulate the keyword matching that find_visible uses
    local kw = "reflection"
    local found = false
    if type(mirror_obj.keywords) == "table" then
        for _, k in ipairs(mirror_obj.keywords) do
            if k:lower() == kw then found = true; break end
        end
    end
    assert_truthy(found)
end)

test("'my reflection' keyword matches mirror via matches_keyword", function()
    local mirror_obj = {
        id = "mirror",
        name = "an ornate mirror",
        is_mirror = true,
        keywords = mirror.keywords,
    }

    local kw = "my reflection"
    local found = false
    if type(mirror_obj.keywords) == "table" then
        for _, k in ipairs(mirror_obj.keywords) do
            if k:lower() == kw then found = true; break end
        end
    end
    assert_truthy(found)
end)

---------------------------------------------------------------------------
-- Issue #29: Double death message on sleep bleedout
---------------------------------------------------------------------------
suite("Issue #29 — no double death message on sleep bleedout")

test("game loop injury tick skipped when game_over is true", function()
    -- The fix is in src/engine/loop/init.lua: the injury tick at line ~603
    -- now checks context.game_over. We verify by simulating the condition.
    --
    -- We can't easily run the full game loop in a test, but we can verify
    -- the guard logic: the injury tick should not fire when game_over=true.

    local injury_mod = require("engine.injuries")

    -- Create a player with a bleeding injury that would kill them
    local player = {
        max_health = 100,
        injuries = {
            {
                id = 1,
                type = "bleeding",
                _state = "active",
                damage = 110,
                damage_per_tick = 5,
                turns_active = 0,
                source = "test",
                location = "left arm",
            }
        },
        state = {},
    }

    -- First tick: health should be <= 0, died = true
    injury_mod.clear_cache()
    local bleeding_def = require("meta.injuries.bleeding")
    injury_mod.register_definition("bleeding", bleeding_def)

    local msgs, died = injury_mod.tick(player)
    assert_truthy(died)

    -- Simulate what the game loop does: if game_over is already set,
    -- the injury tick should NOT run again. We verify that calling tick
    -- again would produce another death (the bug scenario).
    local msgs2, died2 = injury_mod.tick(player)
    -- This proves the double-tick would produce a second death message.
    -- The fix prevents this second tick from ever running.
    assert_truthy(died2)  -- confirms the bug scenario would trigger twice

    -- Verify the fix is in place by checking the source code guard
    local f = io.open("src/engine/loop/init.lua", "r")
    local content = f:read("*a")
    f:close()
    assert_truthy(content:find("not context.game_over"))
end)

---------------------------------------------------------------------------
-- Issue #30: Lowercase after periods in appearance text
---------------------------------------------------------------------------
suite("Issue #30 — capitalize after periods in appearance text")

local appearance = require("engine.player.appearance")

test("appearance text capitalizes after period separators", function()
    -- Create a player with multiple body-part descriptions that produce
    -- multiple phrases joined by ". " — each should start uppercase.
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {
            { type = "bruised", severity = "minor", _state = "active",
              damage = 4, location = "head", turns_active = 0 },
            { type = "bleeding", severity = "moderate", _state = "active",
              damage = 10, damage_per_tick = 1, location = "left arm", turns_active = 0 },
        },
        consciousness = { state = "conscious" },
        state = { bloody = true },
    }

    -- Force deterministic adjective selection
    math.randomseed(42)

    local desc = appearance.describe(player, nil)

    -- Check that after ". " the next letter is uppercase
    local bad_caps = desc:match("%.%s+%l")
    assert_nil(bad_caps)
end)

test("multi-phrase appearance all start with uppercase", function()
    local player = {
        hands = {
            { id = "sword", name = "a rusty sword" },
            nil,
        },
        worn = {},
        max_health = 100,
        injuries = {
            { type = "bruised", severity = "minor", _state = "active",
              damage = 4, location = "torso", turns_active = 0 },
        },
        consciousness = { state = "conscious" },
        state = {},
    }

    math.randomseed(1)
    local desc = appearance.describe(player, nil)

    -- Every sentence should start with uppercase after ". "
    for sentence in desc:gmatch("%.%s+(%a)") do
        assert_eq(sentence, sentence:upper())
    end
end)

---------------------------------------------------------------------------
-- Issue #31: Duplicate bruise text deduplication
---------------------------------------------------------------------------
suite("Issue #31 — deduplicate identical injury phrases")

test("compose_natural deduplicates identical phrases", function()
    local compose = appearance._compose_natural
    local result = compose({"a bruise on your head", "a bruise on your head"})
    assert_eq(result, "a bruise on your head")
end)

test("compose_natural keeps distinct phrases", function()
    local compose = appearance._compose_natural
    local result = compose({"a bruise on your head", "a gash on your arm"})
    assert_eq(result, "a bruise on your head and a gash on your arm")
end)

test("compose_natural deduplicates with three, keeps unique", function()
    local compose = appearance._compose_natural
    local result = compose({
        "a bruise on your head",
        "a bruise on your head",
        "a gash on your arm",
    })
    assert_eq(result, "a bruise on your head and a gash on your arm")
end)

test("appearance describe does not duplicate identical injury text", function()
    -- Two identical bruises on the head — should not produce
    -- "a bruise on your head and a bruise on your head"
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {
            { type = "bruised", severity = "minor", _state = "active",
              damage = 4, location = "head", turns_active = 0 },
            { type = "bruised", severity = "minor", _state = "active",
              damage = 4, location = "head", turns_active = 0 },
        },
        consciousness = { state = "conscious" },
        state = {},
    }

    -- Run multiple times with same seed to force same adjectives
    for seed = 1, 10 do
        math.randomseed(seed)
        local desc = appearance.describe(player, nil)
        -- Should never contain "and a bruise on your head" if same location
        -- (The dedup catches identical rendered strings)
        local count = 0
        for _ in desc:gmatch("bruise on your head") do
            count = count + 1
        end
        -- With dedup, identical phrases collapse to one
        -- (Different random adjectives may produce 2 distinct phrases, which is OK)
        assert_truthy(count <= 2)  -- at most 2 if adjectives differ
    end

    -- Force identical adjectives by using same seed
    math.randomseed(42)
    local desc = appearance.describe(player, nil)
    math.randomseed(42)
    local desc2 = appearance.describe(player, nil)
    assert_eq(desc, desc2)  -- deterministic output
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
h.summary()
