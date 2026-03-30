-- test/issues/test-riddle-board-disambiguation.lua
-- Test Issue #512: Riddle boards not individually examinable

local t = require("test.parser.test-helpers")

-- Load the objects
local board_one = require("src.meta.worlds.wyatt-world.objects.riddle-board-one")
local board_two = require("src.meta.worlds.wyatt-world.objects.riddle-board-two")
local board_three = require("src.meta.worlds.wyatt-world.objects.riddle-board-three")

t.test("riddle board one has distinct keywords", function()
    -- Must have unique identifiers
    local has_first = false
    local has_one = false
    for _, kw in ipairs(board_one.keywords) do
        if kw:match("first") or kw:match("1") or kw:match("one") then
            has_first = true
        end
        if kw == "board one" or kw == "first board" or kw == "board 1" then
            has_one = true
        end
    end
    t.assert_truthy(has_first, "Board one should have 'first' or 'one' or '1' in keywords")
    t.assert_truthy(has_one, "Board one should have 'board one' or 'first board' or 'board 1' as keyword")
end)

t.test("riddle board two has distinct keywords", function()
    local has_second = false
    local has_two = false
    for _, kw in ipairs(board_two.keywords) do
        if kw:match("second") or kw:match("2") or kw:match("two") then
            has_second = true
        end
        if kw == "board two" or kw == "second board" or kw == "board 2" then
            has_two = true
        end
    end
    t.assert_truthy(has_second, "Board two should have 'second' or 'two' or '2' in keywords")
    t.assert_truthy(has_two, "Board two should have 'board two' or 'second board' or 'board 2' as keyword")
end)

t.test("riddle board three has distinct keywords", function()
    local has_third = false
    local has_three = false
    for _, kw in ipairs(board_three.keywords) do
        if kw:match("third") or kw:match("3") or kw:match("three") then
            has_third = true
        end
        if kw == "board three" or kw == "third board" or kw == "board 3" then
            has_three = true
        end
    end
    t.assert_truthy(has_third, "Board three should have 'third' or 'three' or '3' in keywords")
    t.assert_truthy(has_three, "Board three should have 'board three' or 'third board' or 'board 3' as keyword")
end)

t.test("riddle boards have no overlapping unique keywords", function()
    -- Check that unique identifiers don't overlap
    local one_unique = {}
    local two_unique = {}
    local three_unique = {}
    
    -- Extract unique identifiers
    for _, kw in ipairs(board_one.keywords) do
        if kw:match("first") or kw:match("one") or kw:match("1") then
            one_unique[kw] = true
        end
    end
    for _, kw in ipairs(board_two.keywords) do
        if kw:match("second") or kw:match("two") or kw:match("2") then
            two_unique[kw] = true
        end
    end
    for _, kw in ipairs(board_three.keywords) do
        if kw:match("third") or kw:match("three") or kw:match("3") then
            three_unique[kw] = true
        end
    end
    
    -- Check no overlaps
    for kw, _ in pairs(one_unique) do
        if two_unique[kw] then
            error("Board one keyword '" .. kw .. "' overlaps with board two")
        end
        if three_unique[kw] then
            error("Board one keyword '" .. kw .. "' overlaps with board three")
        end
    end
    for kw, _ in pairs(two_unique) do
        if three_unique[kw] then
            error("Board two keyword '" .. kw .. "' overlaps with board three")
        end
    end
end)

t.test("each board description contains its riddle text", function()
    t.assert_truthy(board_one.description:match("hands"), "Board one should contain riddle about hands")
    t.assert_truthy(board_one.description:match("face"), "Board one should contain riddle about face")
    
    t.assert_truthy(board_two.description:match("keys"), "Board two should contain riddle about keys")
    t.assert_truthy(board_two.description:match("door"), "Board two should contain riddle about door")
    
    t.assert_truthy(board_three.description:match("take"), "Board three should contain riddle about taking")
    t.assert_truthy(board_three.description:match("bigger"), "Board three should contain riddle about getting bigger")
end)

t.summary()
