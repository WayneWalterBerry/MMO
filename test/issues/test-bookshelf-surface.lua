-- test/issues/test-bookshelf-surface.lua
-- Test Issue #514: Bookshelf surface error on load

local t = require("test.parser.test-helpers")

-- Load the objects
local bookshelf = require("src.meta.worlds.wyatt-world.objects.bookshelf")
local backwards_book = require("src.meta.worlds.wyatt-world.objects.backwards-book")

t.test("bookshelf defines a top surface", function()
    -- The bookshelf should have a surfaces table with a top surface
    -- OR it should be designed to hold books in contents, not on_top
    t.assert_truthy(bookshelf.surfaces, "Bookshelf should have surfaces defined")
    t.assert_truthy(bookshelf.surfaces.top, "Bookshelf should have a 'top' surface")
end)

t.test("bookshelf top surface has capacity", function()
    if bookshelf.surfaces and bookshelf.surfaces.top then
        t.assert_truthy(bookshelf.surfaces.top.capacity, "Top surface should have capacity")
        t.assert_eq("number", type(bookshelf.surfaces.top.capacity), "Capacity should be a number")
        t.assert_truthy(bookshelf.surfaces.top.capacity > 0, "Capacity should be positive")
    end
end)

t.test("backwards-book has size and weight for placement", function()
    -- The book must have size/weight for containment validation
    t.assert_truthy(backwards_book.size, "Backwards book should have size")
    t.assert_truthy(backwards_book.weight, "Backwards book should have weight")
    t.assert_eq("number", type(backwards_book.size), "Size should be a number")
    t.assert_eq("number", type(backwards_book.weight), "Weight should be a number")
end)

t.summary()
