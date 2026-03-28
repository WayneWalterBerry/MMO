-- test/search/test-compound-search-get.lua
-- Issue #135: Compound `find X, get X` corrupts context — subsequent get fails
-- Issue #132: `find match and get it` compound command failure
--
-- TDD tests written FIRST before the fix.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local eq   = h.assert_eq
local truthy = h.assert_truthy

local search = require("engine.search")
local registry_mod = require("engine.registry")
local containers = require("engine.search.containers")
local preprocess = require("engine.parser.preprocess")

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function capture_print(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error(err) end
    return table.concat(lines, "\n")
end

local function run_search_to_completion(ctx, max_steps)
    max_steps = max_steps or 50
    local step_count = 0
    local continues = true
    local all_output = {}
    while continues and step_count < max_steps do
        local output = capture_print(function()
            continues = search.tick(ctx)
        end)
        if output ~= "" then
            all_output[#all_output + 1] = output
        end
        step_count = step_count + 1
    end
    return table.concat(all_output, "\n"), step_count
end

local function full_search(ctx, target, scope, max_steps)
    if search.is_searching() then search.abort(ctx) end
    capture_print(function()
        search.search(ctx, target, scope)
    end)
    return run_search_to_completion(ctx, max_steps)
end

local function full_find(ctx, target, scope)
    if search.is_searching() then search.abort(ctx) end
    capture_print(function()
        search.find(ctx, target, scope)
    end)
    return run_search_to_completion(ctx)
end

---------------------------------------------------------------------------
-- Context builder: room with a matchbox containing matches
-- Mirrors the real game: matchbox is a closed container with accessible=false.
---------------------------------------------------------------------------

local function make_matchbox_room()
    local reg = registry_mod.new()

    local room = {
        id = "test-room",
        name = "A Simple Room",
        description = "A room with a table.",
        contents = {},
        exits = {},
        light_level = 0,
    }

    -- Matchbox: closed container (accessible=false), like the real game object
    local matchbox = {
        id = "matchbox",
        name = "a small matchbox",
        keywords = {"matchbox", "match box"},
        description = "A battered little cardboard matchbox.",
        container = true,
        accessible = false,
        is_open = false,
        capacity = 10,
        max_item_size = 1,
        contents = {"match-1"},
        categories = {"small", "container"},
        has_striker = true,
    }

    local match1 = {
        id = "match-1",
        name = "a wooden match",
        keywords = {"match", "matchstick", "wooden match"},
        description = "A small wooden match.",
        size = 1,
        portable = true,
        categories = {"small"},
    }

    reg:register("matchbox", matchbox)
    reg:register("match-1", match1)

    room.contents = {"matchbox"}
    room.proximity_list = {"matchbox"}

    local ctx = {
        registry = reg,
        current_room = room,
        player = { hands = {nil, nil}, worn = {}, state = {} },
        time_offset = 0,
        last_noun = nil,
    }

    return ctx, reg, room, matchbox, match1
end

---------------------------------------------------------------------------
-- Suite 1: containers.open must set accessible = true
---------------------------------------------------------------------------

h.suite("1. containers.open sets accessible flag (#135 root cause)")

test("containers.open sets accessible = true on plain container", function()
    local reg = registry_mod.new()
    local box = {
        id = "box",
        name = "a box",
        container = true,
        accessible = false,
        is_open = false,
        contents = {"item-1"},
    }
    reg:register("box", box)
    local ctx = { registry = reg }

    containers.open(ctx, box)

    truthy(box.accessible == true,
        "accessible must be true after containers.open; got: " .. tostring(box.accessible))
    truthy(box.is_open == true,
        "is_open must be true after containers.open")
end)

test("containers.open on already-open container does not break accessible", function()
    local reg = registry_mod.new()
    local box = {
        id = "box",
        name = "a box",
        container = true,
        accessible = true,
        is_open = true,
        contents = {"item-1"},
    }
    reg:register("box", box)
    local ctx = { registry = reg }

    containers.open(ctx, box)

    truthy(box.accessible == true,
        "accessible should remain true; got: " .. tostring(box.accessible))
end)

---------------------------------------------------------------------------
-- Suite 2: Search results persist — container accessible after search
---------------------------------------------------------------------------

h.suite("2. Search results persist in registry (#135)")

test("matchbox becomes accessible after search finds match inside", function()
    local ctx, reg, room, matchbox = make_matchbox_room()

    full_find(ctx, "match")

    truthy(matchbox.accessible == true or matchbox.accessible ~= false,
        "matchbox must be accessible after search found match inside; got: " .. tostring(matchbox.accessible))
end)

test("matchbox accessible after search enters it", function()
    local ctx, reg, room, matchbox = make_matchbox_room()

    full_find(ctx, "match")

    -- #384: Search peeks — container stays closed but accessible
    eq(false, containers.is_open(matchbox),
        "matchbox should stay closed after search peek")
    truthy(matchbox.accessible == true,
        "matchbox must be accessible after search entered it")
end)

test("ctx.last_noun set to found item's id after search", function()
    local ctx = make_matchbox_room()

    full_find(ctx, "match")

    truthy(ctx.last_noun ~= nil,
        "ctx.last_noun should be set after search finds a match")
    eq("match-1", ctx.last_noun,
        "ctx.last_noun should be the found item's id")
end)

---------------------------------------------------------------------------
-- Suite 3: find then get (separate commands) works
---------------------------------------------------------------------------

h.suite("3. Separate find + get works (#135 baseline)")

test("find match then get match — match findable via accessible container", function()
    local ctx, reg, room, matchbox, match1 = make_matchbox_room()

    -- Step 1: find match (completes search)
    full_find(ctx, "match")

    -- Step 2: verify the match is now accessible to find_visible
    -- The matchbox should be accessible=true after search opened it
    truthy(matchbox.accessible == true,
        "matchbox.accessible must be true so get can find the match; got: " .. tostring(matchbox.accessible))

    -- The match should still be in the matchbox's contents
    local found = false
    for _, id in ipairs(matchbox.contents) do
        if id == "match-1" then found = true; break end
    end
    truthy(found, "match-1 must still be in matchbox.contents after find")
end)

---------------------------------------------------------------------------
-- Suite 4: Compound "find X, get X" with comma
---------------------------------------------------------------------------

h.suite("4. Compound comma split (#135)")

test("split_commands splits 'find match, get match' into two parts", function()
    local parts = preprocess.split_commands("find match, get match")
    eq(2, #parts, "should split into 2 commands")
    eq("find match", parts[1])
    eq("get match", parts[2])
end)

test("split_commands splits 'find match, get match' preserves both nouns", function()
    local parts = preprocess.split_commands("find match, get match")
    local v1, n1 = preprocess.parse(parts[1])
    local v2, n2 = preprocess.parse(parts[2])
    eq("find", v1)
    eq("match", n1)
    eq("get", v2)
    eq("match", n2)
end)

---------------------------------------------------------------------------
-- Suite 5: Compound "find X and get it" with "and" + pronoun
---------------------------------------------------------------------------

h.suite("5. Compound 'and' split + pronoun resolution (#132)")

test("'find match and get it' splits on ' and '", function()
    -- The loop splits on " and " after comma/semicolon splitting
    -- "find match and get it" has no comma → single part from split_commands
    local parts = preprocess.split_commands("find match and get it")
    -- split_commands does NOT split on "and" — the loop does that
    eq(1, #parts, "split_commands should not split on 'and'")

    -- Simulate the loop's " and " splitting
    local sub_commands = {}
    local remaining = parts[1]
    while true do
        local before, after = remaining:match("^(.-)%s+and%s+(.+)$")
        if before and after then
            local b = before:match("^%s*(.-)%s*$")
            if b ~= "" then sub_commands[#sub_commands + 1] = b end
            remaining = after
        else
            local r = remaining:match("^%s*(.-)%s*$")
            if r ~= "" then sub_commands[#sub_commands + 1] = r end
            break
        end
    end
    eq(2, #sub_commands, "should split into 2 sub-commands on ' and '")
    eq("find match", sub_commands[1])
    eq("get it", sub_commands[2])
end)

test("pronoun 'it' resolves from context.last_noun set by search", function()
    local ctx = make_matchbox_room()

    -- After find, last_noun should be the found item
    full_find(ctx, "match")

    -- Simulate pronoun resolution as the loop does it
    local PRONOUNS = { it = true, them = true, that = true, this = true }
    local noun = "it"
    if PRONOUNS[noun] and ctx.last_noun then
        noun = ctx.last_noun
    end
    eq("match-1", noun,
        "pronoun 'it' should resolve to match-1 via ctx.last_noun")
end)

---------------------------------------------------------------------------
-- Suite 6: State not corrupted — get works on next turn after failure
---------------------------------------------------------------------------

h.suite("6. No state corruption across turns (#135 critical)")

test("matchbox stays accessible after search even without get", function()
    local ctx, reg, room, matchbox = make_matchbox_room()

    -- Find the match
    full_find(ctx, "match")

    -- Verify matchbox accessible
    truthy(matchbox.accessible == true,
        "matchbox must remain accessible; got: " .. tostring(matchbox.accessible))

    -- Simulate "next turn" — accessible flag should persist
    truthy(matchbox.accessible == true,
        "matchbox accessible flag must persist across turns")
end)

test("match-1 contents remain in matchbox after find (no removal)", function()
    local ctx, reg, room, matchbox = make_matchbox_room()

    full_find(ctx, "match")

    local count = 0
    for _, id in ipairs(matchbox.contents) do
        if id == "match-1" then count = count + 1 end
    end
    eq(1, count, "match-1 must remain exactly once in matchbox.contents")
end)

---------------------------------------------------------------------------
-- Suite 7: search.find does not destroy contents
---------------------------------------------------------------------------

h.suite("7. Search integrity (#135 safety)")

test("search.find for nonexistent item still leaves container accessible", function()
    local ctx, reg, room, matchbox = make_matchbox_room()

    -- Search for something that doesn't exist
    full_find(ctx, "diamond")

    -- #384: Search peeks — container stays closed but accessible
    eq(false, containers.is_open(matchbox),
        "matchbox should stay closed after search peek")
    truthy(matchbox.accessible == true,
        "matchbox should be accessible after search traversed it; got: " .. tostring(matchbox.accessible))
end)

test("search.find does not duplicate items in container", function()
    local ctx, reg, room, matchbox = make_matchbox_room()

    full_find(ctx, "match")

    eq(1, #matchbox.contents,
        "matchbox should still have exactly 1 item after search")
    eq("match-1", matchbox.contents[1],
        "item should still be match-1")
end)

local failed = h.summary()
os.exit(failed > 0 and 1 or 0)
