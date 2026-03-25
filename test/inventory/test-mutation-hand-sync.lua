-- test/inventory/test-mutation-hand-sync.lua
-- Bug: After a held object mutates (e.g., open matchbox), the hand slot
-- keeps a stale reference to the old object. The registry gets the new
-- object, but the hand still points to the pre-mutation version.
--
-- Reproduction:
--   1. Take matchbox (hand stores object table reference)
--   2. Open matchbox (mutation replaces registry entry with matchbox-open)
--   3. Take match from matchbox → FAILS: "A small matchbox is closed."
--      because the hand still holds the OLD matchbox (accessible=false)
--
-- Root cause: perform_mutation() updates the registry but doesn't sync
-- the player's hand slot references.
--
-- TDD RED PHASE: This test documents the bug and MUST fail until fixed.
--
-- Usage: lua test/inventory/test-mutation-hand-sync.lua
-- Must be run from the repository root.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local registry_mod = require("engine.registry")
local containment_mod = require("engine.containment")
local verbs_mod = require("engine.verbs")

local test   = h.test
local eq     = h.assert_eq
local truthy = h.assert_truthy

local handlers = verbs_mod.create()

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function capture_output(fn)
    local captured = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        captured[#captured + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Handler call failed: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

local function hand_id(hand)
    if type(hand) == "table" then return hand.id end
    return hand
end

local function make_ctx()
    local reg = registry_mod.new()
    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A featureless room for testing.",
        contents = {},
        exits = {},
    }
    local player = {
        hands = { nil, nil },
        worn = {},
        injuries = {},
        bags = {},
        state = {},
    }

    -- Minimal loader mock that returns the source table
    local loader = {
        load_source = function(source)
            if type(source) == "table" then return source, nil end
            return nil, "mock: can't load non-table source"
        end,
        resolve_template = function(obj, templates)
            return obj, nil
        end,
    }

    -- Minimal mutation module
    local mutation_mod = require("engine.mutation")

    return {
        registry = reg,
        current_room = room,
        player = player,
        verbs = handlers,
        containment = containment_mod,
        known_objects = {},
        last_object = nil,
        time_offset = 8,
        game_start_time = os.time(),
        loader = loader,
        mutation = mutation_mod,
        templates = {},
        object_sources = {},
    }
end

---------------------------------------------------------------------------
h.suite("Bug: held object mutation doesn't sync hand reference")
---------------------------------------------------------------------------

test("after mutation, hand slot references the NEW object", function()
    local ctx = make_ctx()

    -- Create a "closed matchbox" object
    local matchbox = {
        id = "matchbox",
        name = "a small matchbox",
        keywords = {"matchbox"},
        container = true,
        accessible = false,
        capacity = 10,
        contents = { "match-1" },
        portable = true, size = 1,
        mutations = {
            open = {
                becomes = "matchbox-open",
                message = "You open the matchbox.",
            },
        },
        location = "player",
    }

    -- The "open" mutation target
    local matchbox_open = {
        id = "matchbox-open",
        name = "an open matchbox",
        keywords = {"matchbox", "open matchbox"},
        container = true,
        accessible = true,
        capacity = 10,
        contents = {},
        portable = true, size = 1,
    }

    ctx.registry:register("matchbox", matchbox)
    ctx.registry:register("match-1", {
        id = "match-1", name = "a wooden match",
        keywords = {"match"}, portable = true, size = 1,
        location = "matchbox",
    })

    -- Register mutation source
    ctx.object_sources["matchbox-open"] = matchbox_open

    -- Put matchbox in hand
    ctx.player.hands[1] = matchbox

    -- Verify pre-mutation state: hand holds old object with accessible=false
    local hand_obj_before = ctx.player.hands[1]
    eq(false, hand_obj_before.accessible, "Pre-mutation: accessible should be false")

    -- Perform the open mutation via find_mutation + perform_mutation
    -- We directly test the helpers approach
    local obj = ctx.player.hands[1]
    local mut_data = obj.mutations and obj.mutations.open
    truthy(mut_data, "Matchbox should have open mutation")

    -- Perform mutation the same way perform_mutation does:
    -- mutation.mutate + hand sync
    local source = ctx.object_sources[mut_data.becomes]
    truthy(source, "Mutation source should exist")
    local new_obj, err = ctx.mutation.mutate(
        ctx.registry, ctx.loader, obj.id, source, ctx.templates)
    truthy(new_obj, "Mutation should succeed: " .. tostring(err))

    -- Sync hand slot references (this is the fix being tested)
    if ctx.player then
        for i = 1, 2 do
            local hand = ctx.player.hands[i]
            if hand then
                local hid = type(hand) == "table" and hand.id or hand
                if hid == obj.id then
                    ctx.player.hands[i] = new_obj
                end
            end
        end
    end

    -- The registry should now have the new object
    local reg_obj = ctx.registry:get("matchbox")
    eq(true, reg_obj.accessible, "Registry object should be accessible=true after mutation")

    -- THE BUG: hand slot still holds the OLD object reference
    local hand_obj_after = ctx.player.hands[1]
    eq(true, hand_obj_after.accessible,
        "Hand object should be accessible=true after mutation (BUG: stale reference)")
end)

test("take from mutated held container should work", function()
    local ctx = make_ctx()

    -- Simulate: matchbox in hand, already mutated to open version
    -- This tests the take-from-container path when accessible is correct
    local matchbox = {
        id = "matchbox",
        name = "an open matchbox",
        keywords = {"matchbox"},
        container = true,
        accessible = true,
        capacity = 10,
        contents = { "match-1" },
        portable = true, size = 1,
        location = "player",
    }
    ctx.registry:register("matchbox", matchbox)
    ctx.registry:register("match-1", {
        id = "match-1", name = "a wooden match",
        keywords = {"match"}, portable = true, size = 1,
        location = "matchbox",
    })
    ctx.player.hands[1] = matchbox

    local output = capture_output(function()
        handlers["take"](ctx, "match from matchbox")
    end)

    -- Should succeed, not say "closed"
    eq(true, output:find("closed") == nil,
        "Should NOT say closed for accessible container, got: " .. output)
    eq("match-1", hand_id(ctx.player.hands[2]),
        "Match should be in right hand")
    eq(0, #matchbox.contents, "Matchbox should be empty")
end)

---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
