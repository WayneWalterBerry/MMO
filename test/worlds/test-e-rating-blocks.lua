-- test/worlds/test-e-rating-blocks.lua
-- TDD tests for E-rating enforcement at verb dispatch (WAVE-0).
-- Spec: projects/wyatt-world/plan.md §4.0.7
--
-- Two test tiers:
--   Tier 1 (spec validation): verifies the E-rating rule set from §4.0.7.
--     Uses a reference check function matching the spec. Passes now.
--   Tier 2 (dispatch integration): loads real verb handlers and verifies
--     that E-rated context blocks restricted verbs at dispatch time.
--     FAILS until Bart implements enforcement (TDD red→green).

package.path = "src/?.lua;src/?/init.lua;" .. package.path
local t = require("test.parser.test-helpers")

-----------------------------------------------------------------------
-- E-RATING SPEC (§4.0.7)
-----------------------------------------------------------------------

-- Verbs hard-blocked in rating="E" worlds (§4.0.7 + task spec)
local E_RESTRICTED_VERBS = {
    attack = true, fight = true, kill = true, stab = true,
    slash = true, punch = true, kick = true, hit = true,
    harm = true, hurt = true, injure = true, wound = true,
}

local BLOCK_MESSAGE = "That's not part of this world."

-- Verbs explicitly safe in E-rated worlds (§4.0.7 "NOT restricted")
local SAFE_VERBS = {
    "look", "feel", "take", "taste", "smell", "listen",
    "examine", "read", "drop", "put", "press", "open",
    "close", "go", "enter", "break", "smash",
}

local e_world = { id = "wyatt-world", rating = "E", name = "Wyatt's World" }
local m_world = { id = "world-1", rating = "M", name = "The Manor" }

-- Reference enforcement check (matches spec §4.0.7 pseudocode)
local function spec_check(world, verb)
    if world and world.rating == "E" and E_RESTRICTED_VERBS[verb] then
        return true, BLOCK_MESSAGE
    end
    return false, nil
end

-----------------------------------------------------------------------
-- Suite 1: combat verbs blocked in E-rated world
-----------------------------------------------------------------------
t.suite("E-rating — combat verbs blocked")

t.test("attack is blocked in E-rated world", function()
    local blocked, msg = spec_check(e_world, "attack")
    t.assert_truthy(blocked, "attack should be blocked")
    t.assert_eq(BLOCK_MESSAGE, msg)
end)

t.test("fight is blocked in E-rated world", function()
    t.assert_truthy(spec_check(e_world, "fight"), "fight should be blocked")
end)

t.test("stab is blocked in E-rated world", function()
    t.assert_truthy(spec_check(e_world, "stab"), "stab should be blocked")
end)

t.test("kill is blocked in E-rated world", function()
    t.assert_truthy(spec_check(e_world, "kill"), "kill should be blocked")
end)

-----------------------------------------------------------------------
-- Suite 2: harm/hurt verbs blocked
-----------------------------------------------------------------------
t.suite("E-rating — harm verbs blocked")

t.test("harm is blocked in E-rated world", function()
    t.assert_truthy(spec_check(e_world, "harm"), "harm should be blocked")
end)

t.test("hurt is blocked in E-rated world", function()
    t.assert_truthy(spec_check(e_world, "hurt"), "hurt should be blocked")
end)

t.test("injure is blocked in E-rated world", function()
    t.assert_truthy(spec_check(e_world, "injure"), "injure should be blocked")
end)

t.test("wound is blocked in E-rated world", function()
    t.assert_truthy(spec_check(e_world, "wound"), "wound should be blocked")
end)

-----------------------------------------------------------------------
-- Suite 3: hit/punch/kick blocked
-----------------------------------------------------------------------
t.suite("E-rating — physical verbs blocked")

t.test("hit is blocked in E-rated world", function()
    t.assert_truthy(spec_check(e_world, "hit"), "hit should be blocked")
end)

t.test("punch is blocked in E-rated world", function()
    t.assert_truthy(spec_check(e_world, "punch"), "punch should be blocked")
end)

t.test("kick is blocked in E-rated world", function()
    t.assert_truthy(spec_check(e_world, "kick"), "kick should be blocked")
end)

t.test("slash is blocked in E-rated world", function()
    t.assert_truthy(spec_check(e_world, "slash"), "slash should be blocked")
end)

-----------------------------------------------------------------------
-- Suite 4: safe verbs NOT blocked in E-rated world
-----------------------------------------------------------------------
t.suite("E-rating — safe verbs allowed in E-rated world")

for _, verb in ipairs(SAFE_VERBS) do
    t.test(verb .. " is NOT blocked in E-rated world", function()
        local blocked = spec_check(e_world, verb)
        t.assert_truthy(not blocked, verb .. " should not be blocked")
    end)
end

-----------------------------------------------------------------------
-- Suite 5: M-rated world — no blocking at all
-----------------------------------------------------------------------
t.suite("E-rating — M-rated world (no restrictions)")

t.test("attack NOT blocked in M-rated world", function()
    t.assert_truthy(not spec_check(m_world, "attack"), "M-rated: attack allowed")
end)

t.test("fight NOT blocked in M-rated world", function()
    t.assert_truthy(not spec_check(m_world, "fight"), "M-rated: fight allowed")
end)

t.test("kill NOT blocked in M-rated world", function()
    t.assert_truthy(not spec_check(m_world, "kill"), "M-rated: kill allowed")
end)

t.test("harm NOT blocked in M-rated world", function()
    t.assert_truthy(not spec_check(m_world, "harm"), "M-rated: harm allowed")
end)

t.test("stab NOT blocked in M-rated world", function()
    t.assert_truthy(not spec_check(m_world, "stab"), "M-rated: stab allowed")
end)

t.test("hit NOT blocked in M-rated world", function()
    t.assert_truthy(not spec_check(m_world, "hit"), "M-rated: hit allowed")
end)

-----------------------------------------------------------------------
-- Suite 6: edge cases — nil / missing rating
-----------------------------------------------------------------------
t.suite("E-rating — edge cases")

t.test("nil world does not block", function()
    t.assert_truthy(not spec_check(nil, "attack"), "nil world should not block")
end)

t.test("world without rating field does not block", function()
    t.assert_truthy(not spec_check({ id = "test" }, "attack"),
        "missing rating should not block")
end)

t.test("empty string rating does not block", function()
    t.assert_truthy(not spec_check({ rating = "" }, "attack"),
        "empty rating should not block")
end)

-----------------------------------------------------------------------
-- Suite 7: friendly message (not error, not shaming)
-----------------------------------------------------------------------
t.suite("E-rating — friendly block message")

t.test("blocked verb shows friendly message", function()
    local blocked, msg = spec_check(e_world, "attack")
    t.assert_truthy(blocked)
    t.assert_eq(BLOCK_MESSAGE, msg, "message should match spec")
end)

t.test("message does not contain 'error'", function()
    local _, msg = spec_check(e_world, "fight")
    t.assert_truthy(msg, "message should exist")
    t.assert_truthy(not msg:lower():find("error"), "message should not contain 'error'")
end)

t.test("message does not shame the player", function()
    local _, msg = spec_check(e_world, "kill")
    t.assert_truthy(msg)
    t.assert_truthy(not msg:lower():find("cannot"), "no 'cannot'")
    t.assert_truthy(not msg:lower():find("not allowed"), "no 'not allowed'")
    t.assert_truthy(not msg:lower():find("forbidden"), "no 'forbidden'")
end)

-----------------------------------------------------------------------
-- Suite 8: real world.lua files declare correct ratings
-----------------------------------------------------------------------
t.suite("E-rating — world file ratings")

local SEP = package.config:sub(1, 1)

local function load_world_file(path)
    local f = io.open(path, "r")
    if not f then return nil, "file not found" end
    local source = f:read("*a")
    f:close()
    local chunk, err
    if _VERSION == "Lua 5.1" then
        chunk, err = loadstring(source)
    else
        chunk, err = load(source)
    end
    if not chunk then return nil, err end
    local ok, result = pcall(chunk)
    if not ok then return nil, result end
    return result, nil
end

t.test("manor/world.lua declares rating M", function()
    local path = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "world.lua"
    local world, err = load_world_file(path)
    t.assert_truthy(world, "manor/world.lua should load: " .. tostring(err))
    t.assert_eq("M", world.rating, "manor rating should be M")
end)

t.test("wyatt-world/world.lua declares rating E", function()
    local path = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "wyatt-world" .. SEP .. "world.lua"
    local world, err = load_world_file(path)
    t.assert_truthy(world, "wyatt-world/world.lua should exist: " .. tostring(err))
    t.assert_eq("E", world.rating, "wyatt-world rating should be E")
    t.assert_eq("wyatt-world", world.id, "wyatt-world id")
end)

-----------------------------------------------------------------------
-- Suite 9: dispatch integration (Tier 2 — requires real implementation)
-----------------------------------------------------------------------
t.suite("E-rating — verb dispatch integration")

local handlers_loaded = false
local handlers = nil
local load_ok, load_err = pcall(function()
    local verbs_mod = require("engine.verbs")
    handlers = verbs_mod.create()
    handlers_loaded = true
end)

if handlers_loaded and type(handlers) == "table" then
    local captured = {}
    local original_print = print

    local function capture_start()
        captured = {}
        print = function(...)
            for _, v in ipairs({...}) do
                captured[#captured + 1] = tostring(v)
            end
        end
    end

    local function capture_stop()
        print = original_print
        return table.concat(captured, "\n")
    end

    local function output_has_block_msg(output)
        return output:find("not part of this world") ~= nil
    end

    local function make_e_context()
        captured = {}
        return {
            world = e_world,
            output = function(msg) captured[#captured + 1] = tostring(msg) end,
            player = {
                room = "test-room",
                hands = { left = nil, right = nil },
                consciousness = { state = "conscious" },
                injuries = {},
            },
            registry = {
                find_by_keyword = function() return nil end,
                find_all_by_keyword = function() return {} end,
            },
        }
    end

    t.test("dispatch: attack blocked in E-rated context", function()
        if not handlers["attack"] then
            error("SKIP: attack handler not registered")
        end
        capture_start()
        local ctx = make_e_context()
        pcall(handlers["attack"], ctx, "test-target")
        local output = capture_stop()
        t.assert_truthy(output_has_block_msg(output),
            "attack should be blocked at dispatch; got: " .. output)
    end)

    t.test("dispatch: look NOT blocked in E-rated context", function()
        if not handlers["look"] then
            error("SKIP: look handler not registered")
        end
        capture_start()
        local ctx = make_e_context()
        pcall(handlers["look"], ctx, nil)
        local output = capture_stop()
        t.assert_truthy(not output_has_block_msg(output),
            "look should not be blocked in E-rated world")
    end)

    t.test("dispatch: feel NOT blocked in E-rated context", function()
        if not handlers["feel"] then
            error("SKIP: feel handler not registered")
        end
        capture_start()
        local ctx = make_e_context()
        pcall(handlers["feel"], ctx, nil)
        local output = capture_stop()
        t.assert_truthy(not output_has_block_msg(output),
            "feel should not be blocked in E-rated world")
    end)
else
    t.test("dispatch: verb handlers load for integration test", function()
        error("PENDING: verb module could not load in test context: " .. tostring(load_err)
            .. " — dispatch tests run after Bart's implementation lands")
    end)
end

local exit_code = t.summary()
os.exit(exit_code > 0 and 1 or 0)
