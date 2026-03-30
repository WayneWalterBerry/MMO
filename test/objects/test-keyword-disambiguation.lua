-- test/objects/test-keyword-disambiguation.lua
-- Fix #153: Verify brass-spittoon and candle-holder resolve uniquely.
-- "brass bowl" was removed from spittoon keywords to eliminate collision.
-- Must be run from repository root: lua test/objects/test-keyword-disambiguation.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load objects
---------------------------------------------------------------------------
local objects_dir = script_dir .. "/../../src/meta/worlds/manor/objects/"
local spittoon = dofile(objects_dir .. "brass-spittoon.lua")
local holder   = dofile(objects_dir .. "candle-holder.lua")

---------------------------------------------------------------------------
-- Helper: check if value exists in a list
---------------------------------------------------------------------------
local function has_value(list, val)
    if not list then return false end
    for _, v in ipairs(list) do
        if v == val then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- Helper: exact keyword match (mirrors engine matches_keyword logic)
---------------------------------------------------------------------------
local function matches_keyword(obj, kw)
    if not obj then return false end
    kw = kw:lower()
    if obj.id and obj.id:lower() == kw then return true end
    if type(obj.keywords) == "table" then
        for _, k in ipairs(obj.keywords) do
            if k:lower() == kw then return true end
        end
    end
    if obj.name then
        local padded = " " .. obj.name:lower() .. " "
        if padded:find(" " .. kw .. " ", 1, true) then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- UNIQUE RESOLUTION
---------------------------------------------------------------------------
suite("KEYWORD DISAMBIGUATION: brass-spittoon vs candle-holder (#153)")

test("1. 'spittoon' matches brass-spittoon", function()
    h.assert_truthy(matches_keyword(spittoon, "spittoon"),
        "'spittoon' must match brass-spittoon")
end)

test("2. 'spittoon' does NOT match candle-holder", function()
    h.assert_truthy(not matches_keyword(holder, "spittoon"),
        "'spittoon' must not match candle-holder")
end)

test("3. 'candle holder' matches candle-holder", function()
    h.assert_truthy(matches_keyword(holder, "candle holder"),
        "'candle holder' must match candle-holder")
end)

test("4. 'candle holder' does NOT match brass-spittoon", function()
    h.assert_truthy(not matches_keyword(spittoon, "candle holder"),
        "'candle holder' must not match brass-spittoon")
end)

test("5. 'brass spittoon' resolves uniquely to spittoon", function()
    h.assert_truthy(matches_keyword(spittoon, "brass spittoon"),
        "'brass spittoon' must match spittoon")
    h.assert_truthy(not matches_keyword(holder, "brass spittoon"),
        "'brass spittoon' must not match candle-holder")
end)

test("6. 'brass holder' resolves uniquely to candle-holder", function()
    h.assert_truthy(matches_keyword(holder, "brass holder"),
        "'brass holder' must match candle-holder")
    h.assert_truthy(not matches_keyword(spittoon, "brass holder"),
        "'brass holder' must not match spittoon")
end)

test("7. 'brass bowl' no longer matches brass-spittoon", function()
    h.assert_truthy(not has_value(spittoon.keywords, "brass bowl"),
        "'brass bowl' must be removed from spittoon keywords")
end)

test("8. 'brass bowl' does not match candle-holder", function()
    h.assert_truthy(not matches_keyword(holder, "brass bowl"),
        "'brass bowl' must not match candle-holder")
end)

test("9. 'cuspidor' resolves uniquely to spittoon", function()
    h.assert_truthy(matches_keyword(spittoon, "cuspidor"),
        "'cuspidor' must match spittoon")
    h.assert_truthy(not matches_keyword(holder, "cuspidor"),
        "'cuspidor' must not match candle-holder")
end)

test("10. 'candlestick' resolves uniquely to candle-holder", function()
    h.assert_truthy(matches_keyword(holder, "candlestick"),
        "'candlestick' must match candle-holder")
    h.assert_truthy(not matches_keyword(spittoon, "candlestick"),
        "'candlestick' must not match spittoon")
end)

test("11. No keyword overlap between spittoon and candle-holder", function()
    local overlap = {}
    for _, sk in ipairs(spittoon.keywords) do
        for _, hk in ipairs(holder.keywords) do
            if sk:lower() == hk:lower() then
                overlap[#overlap + 1] = sk
            end
        end
    end
    h.assert_eq(0, #overlap,
        "no keywords should overlap, but found: " .. table.concat(overlap, ", "))
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
