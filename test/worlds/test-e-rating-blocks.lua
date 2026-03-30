-- test/worlds/test-e-rating-blocks.lua
-- Tests E-rating enforcement: combat/harm verbs blocked in E-rated worlds,
-- all verbs work in non-E worlds, safe verbs always work.

package.path = "src/?.lua;src/?/init.lua;" .. package.path
local t = require("test.parser.test-helpers")

-- We test the E-rating check by simulating what loop/init.lua does:
-- check context.world.rating == "E" against the restricted verb table.

local E_RESTRICTED_VERBS = {
    attack = true, fight = true, kill = true, stab = true,
    slash = true, punch = true, kick = true,
    harm = true, hurt = true, injure = true, wound = true,
}

local function is_blocked(world, verb)
    return world and world.rating == "E" and E_RESTRICTED_VERBS[verb] == true
end

t.suite("E-rating — blocked verbs in E-rated world")

local e_world = { id = "wyatt-world", rating = "E" }

local blocked_verbs = { "attack", "fight", "kill", "stab", "slash", "punch", "kick", "harm", "hurt", "injure", "wound" }
for _, verb in ipairs(blocked_verbs) do
    t.test(verb .. " is blocked in E-rated world", function()
        t.assert_truthy(is_blocked(e_world, verb), verb .. " should be blocked")
    end)
end

t.suite("E-rating — safe verbs in E-rated world")

local safe_verbs = { "look", "feel", "smell", "listen", "taste", "examine", "read", "take", "drop", "put", "open", "close", "go", "break", "smash", "press", "enter" }
for _, verb in ipairs(safe_verbs) do
    t.test(verb .. " is allowed in E-rated world", function()
        t.assert_eq(false, is_blocked(e_world, verb), verb .. " should NOT be blocked")
    end)
end

t.suite("E-rating — M-rated world allows all verbs")

local m_world = { id = "world-1", rating = "M" }

for _, verb in ipairs(blocked_verbs) do
    t.test(verb .. " is allowed in M-rated world", function()
        t.assert_eq(false, is_blocked(m_world, verb), verb .. " should work in M-rated world")
    end)
end

t.suite("E-rating — nil world allows all verbs (backward compat)")

for _, verb in ipairs(blocked_verbs) do
    t.test(verb .. " is allowed when no world set", function()
        t.assert_eq(true, not is_blocked(nil, verb), verb .. " should work with nil world")
    end)
end

t.suite("E-rating — wyatt-world.lua has rating E")

t.test("wyatt-world.lua declares rating E", function()
    local SEP = package.config:sub(1, 1)
    local path = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "wyatt-world" .. SEP .. "world.lua"
    local f = io.open(path, "r")
    t.assert_truthy(f, "wyatt-world/world.lua should exist")
    local source = f:read("*a")
    f:close()
    local chunk, err
    if _VERSION == "Lua 5.1" then
        chunk, err = loadstring(source)
    else
        chunk, err = load(source)
    end
    t.assert_truthy(chunk, "world.lua should parse: " .. tostring(err))
    local ok, world = pcall(chunk)
    t.assert_truthy(ok, "world.lua should execute")
    t.assert_eq("E", world.rating, "wyatt-world rating should be E")
    t.assert_eq("wyatt-world", world.id, "wyatt-world id should be wyatt-world")
end)

t.suite("E-rating — manor world.lua has rating M")

t.test("manor/world.lua declares rating M", function()
    local SEP = package.config:sub(1, 1)
    local path = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "world.lua"
    local f = io.open(path, "r")
    t.assert_truthy(f, "manor/world.lua should exist")
    local source = f:read("*a")
    f:close()
    local chunk, err
    if _VERSION == "Lua 5.1" then
        chunk, err = loadstring(source)
    else
        chunk, err = load(source)
    end
    t.assert_truthy(chunk, "world.lua should parse: " .. tostring(err))
    local ok, world = pcall(chunk)
    t.assert_truthy(ok, "world.lua should execute")
    t.assert_eq("M", world.rating, "manor rating should be M")
end)

local exit_code = t.summary()
os.exit(exit_code > 0 and 1 or 0)
