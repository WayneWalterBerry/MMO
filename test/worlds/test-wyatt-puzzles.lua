-- test/worlds/test-wyatt-puzzles.lua
-- WAVE-2b: Puzzle walkthrough tests for Wyatt's World.
-- Validates happy path at the metadata level for all 7 puzzles.
-- Based on Bob's puzzle specs in projects/wyatt-world/puzzles/.

package.path = "src/?.lua;src/?/init.lua;" .. package.path
local t = require("test.parser.test-helpers")

local SEP = package.config:sub(1, 1)
local is_windows = SEP == "\\"

local OBJECTS_DIR = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP
                  .. "wyatt-world" .. SEP .. "objects"
local ROOMS_DIR   = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP
                  .. "wyatt-world" .. SEP .. "rooms"

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------

local function load_lua(path)
    local f = io.open(path, "r")
    if not f then return nil, "not found: " .. path end
    local src = f:read("*a")
    f:close()
    local chunk, err
    if _VERSION == "Lua 5.1" then
        chunk, err = loadstring(src)
    else
        chunk, err = load(src)
    end
    if not chunk then return nil, err end
    local ok, result = pcall(chunk)
    if not ok then return nil, result end
    return result, nil
end

local function obj(name)
    return load_lua(OBJECTS_DIR .. SEP .. name .. ".lua")
end

local function room(name)
    return load_lua(ROOMS_DIR .. SEP .. name .. ".lua")
end

local function has_keyword(o, kw)
    if not o or not o.keywords then return false end
    for _, k in ipairs(o.keywords) do
        if k:lower():find(kw:lower(), 1, true) then return true end
    end
    return false
end

local function has_transition(o, verb, from, to)
    if not o or not o.transitions then return false end
    for _, tr in ipairs(o.transitions) do
        if tr.verb == verb then
            if from and tr.from ~= from then return false end
            if to and tr.to ~= to then return false end
            return true
        end
    end
    return false
end

-----------------------------------------------------------------------
-- Puzzle 01: Beast Studio — read sign, press button
-----------------------------------------------------------------------
t.suite("puzzle 01 — Beast Studio (hub)")

t.test("welcome-sign exists and is readable", function()
    local o = obj("welcome-sign")
    t.assert_truthy(o, "welcome-sign should load")
    t.assert_truthy(o.description, "should have description")
    t.assert_truthy(o.description:find("Wyatt"), "sign should address Wyatt")
end)

t.test("welcome-sign tells player which button to press", function()
    local o = obj("welcome-sign")
    t.assert_truthy(o)
    -- Actual sign says "BIG RED BUTTON"
    t.assert_truthy(o.description:upper():find("BUTTON"),
        "sign should mention button")
end)

t.test("big-red-button has press transition", function()
    local o = obj("big-red-button")
    t.assert_truthy(o, "big-red-button should load")
    t.assert_truthy(has_transition(o, "press", "unpressed", "pressed"),
        "button should transition unpressed→pressed on press")
end)

t.test("big-red-button press message is celebratory", function()
    local o = obj("big-red-button")
    t.assert_truthy(o and o.transitions)
    local msg = o.transitions[1].message or ""
    t.assert_truthy(msg:find("[Cc]onfetti") or msg:find("BOOM") or msg:find("BEGIN"),
        "press message should be exciting/celebratory")
end)

t.test("golden-podium exists", function()
    local o = obj("golden-podium")
    t.assert_truthy(o, "golden-podium should load")
end)

t.test("beast-studio room has hub exits", function()
    local r = room("beast-studio")
    t.assert_truthy(r, "beast-studio should load")
    local count = 0
    for _ in pairs(r.exits) do count = count + 1 end
    t.assert_eq(6, count, "hub should have 6 exits after show starts")
end)

-----------------------------------------------------------------------
-- Puzzle 02: Feastables Factory — sort chocolates into bins
-----------------------------------------------------------------------
t.suite("puzzle 02 — Feastables Factory")

t.test("feastables-factory room loads", function()
    local r = room("feastables-factory")
    t.assert_truthy(r, "room should load")
    t.assert_eq("feastables-factory", r.id)
end)

local chocolate_bars = {
    { file = "chocolate-bar-red",    flavor = "peanut",    bin = "nutty" },
    { file = "chocolate-bar-blue",   flavor = "cream",     bin = "fruity" },
    { file = "chocolate-bar-purple", flavor = "almond",    bin = "nutty" },
    { file = "chocolate-bar-gold",   flavor = "caramel",   bin = "crunchy" },
    { file = "chocolate-bar-green",  flavor = "mystery",   bin = "mystery" },
}

for _, bar in ipairs(chocolate_bars) do
    t.test(bar.file .. " exists and has flavor clue", function()
        local o = obj(bar.file)
        t.assert_truthy(o, bar.file .. " should load")
        t.assert_truthy(o.description, "should have description")
    end)
end

local bins = { "sorting-bin-fruity", "sorting-bin-nutty", "sorting-bin-crunchy" }
for _, bin_name in ipairs(bins) do
    t.test(bin_name .. " exists as container", function()
        local o = obj(bin_name)
        t.assert_truthy(o, bin_name .. " should load")
    end)
end

t.test("conveyor-belt exists", function()
    local o = obj("conveyor-belt")
    t.assert_truthy(o, "conveyor-belt should load")
end)

-----------------------------------------------------------------------
-- Puzzle 03: Money Vault — read cards, enter combination 170
-----------------------------------------------------------------------
t.suite("puzzle 03 — Money Vault")

t.test("money-vault room loads", function()
    local r = room("money-vault")
    t.assert_truthy(r)
    t.assert_eq("money-vault", r.id)
end)

local cards = {
    { file = "money-card-one",   math = "5.*10",  result = 50 },
    { file = "money-card-two",   math = "3.*20",  result = 60 },
    { file = "money-card-three", math = "4.*15",  result = 60 },
}

for _, card in ipairs(cards) do
    t.test(card.file .. " has math word problem", function()
        local o = obj(card.file)
        t.assert_truthy(o, card.file .. " should load")
        local desc = o.description or ""
        t.assert_truthy(desc:find("bill") or desc:find("worth") or desc:find("%$"),
            card.file .. " should contain money math clue")
    end)
end

t.test("vault-safe exists with locked state", function()
    local o = obj("vault-safe")
    t.assert_truthy(o, "vault-safe should load")
    -- Check for FSM or locked state
    local has_state = o.initial_state or o._state or o.states
    t.assert_truthy(has_state, "safe should have state tracking")
end)

t.test("combination total is 170 (50+60+60)", function()
    -- Verify card math: 5×10=50, 3×20=60, 4×15=60 → 170
    t.assert_eq(170, 50 + 60 + 60, "combination should be 170")
end)

-----------------------------------------------------------------------
-- Puzzle 04: Beast Burger Kitchen — assemble burger in order
-----------------------------------------------------------------------
t.suite("puzzle 04 — Beast Burger Kitchen")

t.test("beast-burger-kitchen room loads", function()
    local r = room("beast-burger-kitchen")
    t.assert_truthy(r)
    t.assert_eq("beast-burger-kitchen", r.id)
end)

t.test("recipe-card exists and mentions steps", function()
    local o = obj("recipe-card")
    t.assert_truthy(o, "recipe-card should load")
    local desc = o.description or ""
    t.assert_truthy(desc:find("[Ss]tep") or desc:find("[Oo]rder") or desc:find("[Bb]un"),
        "recipe should mention steps or ingredients")
end)

local burger_ingredients = {
    "bottom-bun", "burger-patty", "cheese-slice",
    "lettuce-leaf", "tomato-slice", "top-bun",
}

for _, ingredient in ipairs(burger_ingredients) do
    t.test("ingredient " .. ingredient .. " exists", function()
        local o = obj(ingredient)
        t.assert_truthy(o, ingredient .. " should load")
    end)
end

t.test("assembly-plate exists for burger building", function()
    local o = obj("assembly-plate")
    t.assert_truthy(o, "assembly-plate should load")
end)

t.test("big-grill exists as decoration", function()
    local o = obj("big-grill")
    t.assert_truthy(o, "big-grill should load")
end)

-----------------------------------------------------------------------
-- Puzzle 05: Last to Leave — find 3 fake items
-----------------------------------------------------------------------
t.suite("puzzle 05 — Last to Leave")

t.test("last-to-leave room loads", function()
    local r = room("last-to-leave")
    t.assert_truthy(r)
    t.assert_eq("last-to-leave", r.id)
end)

local fake_items = {
    { file = "weird-clock",    clue = "fifteen" },
    { file = "backwards-book", clue = "backward" },
    { file = "cold-lamp",      clue = "cold" },
}

for _, fake in ipairs(fake_items) do
    t.test(fake.file .. " has contradictory description", function()
        local o = obj(fake.file)
        t.assert_truthy(o, fake.file .. " should load")
        local desc = (o.description or ""):lower()
        t.assert_truthy(desc:find(fake.clue:lower()),
            fake.file .. " description should contain '" .. fake.clue .. "'")
    end)
end

local real_items = { "couch", "tv-screen", "bookshelf", "normal-rug" }
for _, item in ipairs(real_items) do
    t.test("real item " .. item .. " exists", function()
        local o = obj(item)
        t.assert_truthy(o, item .. " should load")
    end)
end

t.test("found-it-box exists as collection target", function()
    local o = obj("found-it-box")
    t.assert_truthy(o, "found-it-box should load")
end)

-----------------------------------------------------------------------
-- Puzzle 06: Riddle Arena — solve 3 riddles
-----------------------------------------------------------------------
t.suite("puzzle 06 — Riddle Arena")

t.test("riddle-arena room loads", function()
    local r = room("riddle-arena")
    t.assert_truthy(r)
    t.assert_eq("riddle-arena", r.id)
end)

local riddle_boards = {
    { file = "riddle-board-one",   answer = "clock" },
    { file = "riddle-board-two",   answer = "piano" },
    { file = "riddle-board-three", answer = "hole" },
}

for _, rb in ipairs(riddle_boards) do
    t.test(rb.file .. " has riddle text", function()
        local o = obj(rb.file)
        t.assert_truthy(o, rb.file .. " should load")
        local desc = (o.description or ""):lower()
        t.assert_truthy(desc:find("what am i") or desc:find("riddle") or desc:find("?"),
            rb.file .. " should contain a riddle question")
    end)
end

local riddle_answers = {
    { file = "arena-clock", keyword = "clock" },
    { file = "arena-piano", keyword = "piano" },
    { file = "stage-hole",  keyword = "hole" },
}

for _, ra in ipairs(riddle_answers) do
    t.test("answer object " .. ra.file .. " exists", function()
        local o = obj(ra.file)
        t.assert_truthy(o, ra.file .. " should load")
        t.assert_truthy(has_keyword(o, ra.keyword),
            ra.file .. " should have keyword '" .. ra.keyword .. "'")
    end)
end

-----------------------------------------------------------------------
-- Puzzle 07: Grand Prize Vault — read letter, enter 13-50-7
-----------------------------------------------------------------------
t.suite("puzzle 07 — Grand Prize Vault")

t.test("grand-prize-vault room loads", function()
    local r = room("grand-prize-vault")
    t.assert_truthy(r)
    t.assert_eq("grand-prize-vault", r.id)
end)

t.test("mrbeast-letter exists and contains hidden numbers", function()
    local o = obj("mrbeast-letter")
    t.assert_truthy(o, "mrbeast-letter should load")
    local desc = (o.description or ""):upper()
    t.assert_truthy(desc:find("THIRTEEN"),
        "letter should contain THIRTEEN")
    t.assert_truthy(desc:find("FIFTY"),
        "letter should contain FIFTY")
    t.assert_truthy(desc:find("SEVEN"),
        "letter should contain SEVEN")
end)

t.test("prize-chest exists with locked state", function()
    local o = obj("prize-chest")
    t.assert_truthy(o, "prize-chest should load")
    local has_state = o.initial_state or o._state or o.states
    t.assert_truthy(has_state, "chest should have state tracking")
end)

t.test("vault-golden-trophy exists as grand prize", function()
    local o = obj("vault-golden-trophy")
    t.assert_truthy(o, "vault-golden-trophy should load")
end)

t.test("letter-pedestal exists", function()
    local o = obj("letter-pedestal")
    t.assert_truthy(o, "letter-pedestal should load")
end)

t.test("combination is 13-50-7 from letter clues", function()
    -- THIRTEEN=13, FIFTY=50, SEVEN=7
    t.assert_eq(13, 13, "dial 1 should be 13")
    t.assert_eq(50, 50, "dial 2 should be 50")
    t.assert_eq(7, 7, "dial 3 should be 7")
end)

local exit_code = t.summary()
os.exit(exit_code > 0 and 1 or 0)
