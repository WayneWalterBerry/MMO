-- test/butchery/test-butchery-products.lua
-- WAVE-1 TDD: Validates butchery_products metadata on creature definitions
-- and butcher-knife tool capability.
-- Flanders is adding butchery_products in parallel — tests define the contract.
--
-- Must be run from repository root: lua test/butchery/test-butchery-products.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load creature definitions via dofile (pcall-guarded — TDD)
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local function creature_path(name)
    return "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. name .. ".lua"
end

local function object_path(name)
    return "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP .. name .. ".lua"
end

local ok_wolf, wolf = pcall(dofile, creature_path("wolf"))
if not ok_wolf then
    print("WARNING: wolf.lua failed to load — " .. tostring(wolf))
    wolf = nil
end

local ok_spider, spider = pcall(dofile, creature_path("spider"))
if not ok_spider then
    print("WARNING: spider.lua failed to load — " .. tostring(spider))
    spider = nil
end

local ok_knife, butcher_knife = pcall(dofile, object_path("butcher-knife"))
if not ok_knife then
    print("WARNING: butcher-knife.lua failed to load — " .. tostring(butcher_knife))
    butcher_knife = nil
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function contains(tbl, val)
    if type(tbl) ~= "table" then return false end
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

local function find_product(products, id)
    if type(products) ~= "table" then return nil end
    for _, p in ipairs(products) do
        if p.id == id then return p end
    end
    return nil
end

---------------------------------------------------------------------------
-- TESTS: Wolf butchery_products
---------------------------------------------------------------------------
suite("WOLF BUTCHERY PRODUCTS: death_state metadata (WAVE-1 TDD)")

test("1. wolf death_state has butchery_products field", function()
    h.assert_truthy(wolf, "wolf.lua must load")
    h.assert_truthy(wolf.death_state, "wolf must have death_state")
    h.assert_truthy(wolf.death_state.butchery_products,
        "wolf.death_state must have butchery_products")
    h.assert_eq("table", type(wolf.death_state.butchery_products),
        "butchery_products must be a table")
end)

test("2. wolf butchery_products: 3 wolf-meat, 2 wolf-bone, 1 wolf-hide", function()
    h.assert_truthy(wolf, "wolf.lua must load")
    h.assert_truthy(wolf.death_state and wolf.death_state.butchery_products,
        "butchery_products must exist")

    local bp = wolf.death_state.butchery_products
    h.assert_truthy(bp.products, "butchery_products must have products list")
    h.assert_eq("table", type(bp.products), "products must be a table")

    local meat = find_product(bp.products, "wolf-meat")
    h.assert_truthy(meat, "wolf-meat must be in products")
    h.assert_eq(3, meat.quantity, "wolf-meat quantity must be 3")

    local bone = find_product(bp.products, "wolf-bone")
    h.assert_truthy(bone, "wolf-bone must be in products")
    h.assert_eq(2, bone.quantity, "wolf-bone quantity must be 2")

    local hide = find_product(bp.products, "wolf-hide")
    h.assert_truthy(hide, "wolf-hide must be in products")
    h.assert_eq(1, hide.quantity, "wolf-hide quantity must be 1")
end)

test("3. wolf butchery_products requires_tool is 'butchering'", function()
    h.assert_truthy(wolf, "wolf.lua must load")
    h.assert_truthy(wolf.death_state and wolf.death_state.butchery_products,
        "butchery_products must exist")

    local bp = wolf.death_state.butchery_products
    h.assert_eq("butchering", bp.requires_tool,
        "requires_tool must be 'butchering' (capability, not object ID)")
end)

test("4. wolf butchery_products removes_corpse is true", function()
    h.assert_truthy(wolf, "wolf.lua must load")
    h.assert_truthy(wolf.death_state and wolf.death_state.butchery_products,
        "butchery_products must exist")

    h.assert_eq(true, wolf.death_state.butchery_products.removes_corpse,
        "removes_corpse must be true — corpse disappears after butchering")
end)

---------------------------------------------------------------------------
-- TESTS: Spider butchery_products
---------------------------------------------------------------------------
suite("SPIDER BUTCHERY PRODUCTS: death_state metadata (WAVE-1 TDD)")

test("5. spider death_state has butchery_products field", function()
    h.assert_truthy(spider, "spider.lua must load")
    h.assert_truthy(spider.death_state, "spider must have death_state")
    h.assert_truthy(spider.death_state.butchery_products,
        "spider.death_state must have butchery_products")
    h.assert_eq("table", type(spider.death_state.butchery_products),
        "butchery_products must be a table")
end)

test("6. spider butchery_products include spider-meat and silk-bundle", function()
    h.assert_truthy(spider, "spider.lua must load")
    h.assert_truthy(spider.death_state and spider.death_state.butchery_products,
        "butchery_products must exist")

    local bp = spider.death_state.butchery_products
    h.assert_truthy(bp.products, "butchery_products must have products list")

    local meat = find_product(bp.products, "spider-meat")
    h.assert_truthy(meat, "spider-meat must be in products")
    h.assert_eq(1, meat.quantity, "spider-meat quantity must be 1")

    local silk = find_product(bp.products, "silk-bundle")
    h.assert_truthy(silk, "silk-bundle must be in products")
    h.assert_eq(1, silk.quantity, "silk-bundle quantity must be 1")
end)

---------------------------------------------------------------------------
-- TESTS: Butcher knife tool
---------------------------------------------------------------------------
suite("BUTCHER KNIFE: tool capability (WAVE-1 TDD)")

test("7. butcher-knife.lua loads and has butchering capability", function()
    h.assert_truthy(butcher_knife, "butcher-knife.lua must load")
    h.assert_eq("table", type(butcher_knife), "butcher-knife must return a table")

    local caps = butcher_knife.capabilities or butcher_knife.provides_tool or {}
    h.assert_truthy(contains(caps, "butchering"),
        "butcher-knife must have 'butchering' capability")
end)

test("8. butcher-knife has required object fields", function()
    h.assert_truthy(butcher_knife, "butcher-knife.lua must load")
    h.assert_truthy(butcher_knife.id, "must have id")
    h.assert_truthy(butcher_knife.name, "must have name")
    h.assert_truthy(butcher_knife.keywords, "must have keywords")
    h.assert_truthy(butcher_knife.on_feel, "must have on_feel (mandatory)")
    h.assert_eq(true, butcher_knife.portable, "butcher-knife must be portable")

    h.assert_truthy(contains(butcher_knife.keywords, "knife") or
                    contains(butcher_knife.keywords, "butcher knife"),
        "keywords must include 'knife' or 'butcher knife'")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
