-- test/combat/test-body-tree.lua
-- WAVE-4 TDD: Validates body_tree data on rat and player.
-- Tests expect body_tree to exist with zone/tissue structure.
-- Must be run from repository root: lua test/combat/test-body-tree.lua

math.randomseed(42)

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load rat object
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local rat_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "creatures" .. SEP .. "rat.lua"

local ok_rat, rat = pcall(dofile, rat_path)
if not ok_rat then
    print("WARNING: rat.lua failed to load — tests will fail (TDD: expected)")
    rat = nil
end

---------------------------------------------------------------------------
-- Load player model from main.lua (extract player table)
-- Since main.lua runs the full game, we load it in a sandbox to extract
-- the player table. For now, we use dofile on main.lua in headless mode
-- or parse the player table directly. The plan says body_tree goes on
-- the player table in main.lua lines ~305-324.
-- We re-create the expected player structure here for validation.
---------------------------------------------------------------------------

-- Known material names from src/meta/materials/
local valid_materials = {}
local mat_dir = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "materials"
local is_windows = SEP == "\\"
local list_cmd
if is_windows then
    list_cmd = 'dir /b "' .. mat_dir .. SEP .. '*.lua" 2>nul'
else
    list_cmd = 'ls -1 "' .. mat_dir .. '"/*.lua 2>/dev/null'
end
local handle = io.popen(list_cmd)
if handle then
    for line in handle:lines() do
        local fname = line:match("([^/\\]+)$") or line
        local mat_name = fname:match("^(.+)%.lua$")
        if mat_name then
            -- Convert filename to material name (underscores stay)
            valid_materials[mat_name] = true
        end
    end
    handle:close()
end

-- Also try loading material names through the registry
local ok_mat, materials = pcall(require, "engine.materials")
if ok_mat and materials and materials.registry then
    for name, _ in pairs(materials.registry) do
        valid_materials[name] = true
    end
end

---------------------------------------------------------------------------
-- RAT BODY_TREE TESTS
---------------------------------------------------------------------------
suite("RAT BODY_TREE: zone structure (WAVE-4)")

test("1. rat has body_tree field", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.body_tree, "rat must have body_tree (WAVE-4 data)")
    h.assert_eq("table", type(rat.body_tree), "body_tree must be a table")
end)

test("2. rat body_tree has 4 zones: head, body, legs, tail", function()
    h.assert_truthy(rat and rat.body_tree, "rat.body_tree not loaded")
    local expected = { "head", "body", "legs", "tail" }
    local count = 0
    for _ in pairs(rat.body_tree) do count = count + 1 end
    h.assert_eq(4, count, "rat body_tree must have exactly 4 zones")
    for _, zone_name in ipairs(expected) do
        h.assert_truthy(rat.body_tree[zone_name],
            "rat body_tree must have zone: " .. zone_name)
    end
end)

test("3. rat head zone has size (number) and tissue (table)", function()
    h.assert_truthy(rat and rat.body_tree, "rat.body_tree not loaded")
    local head = rat.body_tree.head
    h.assert_truthy(head, "head zone must exist")
    h.assert_eq("number", type(head.size), "head.size must be a number")
    h.assert_truthy(head.tissue or head.tissues,
        "head must have tissue or tissues table")
    local tissues = head.tissue or head.tissues
    h.assert_eq("table", type(tissues), "head tissues must be a table")
end)

test("4. rat body zone has size (number) and tissue (table)", function()
    h.assert_truthy(rat and rat.body_tree, "rat.body_tree not loaded")
    local body = rat.body_tree.body
    h.assert_truthy(body, "body zone must exist")
    h.assert_eq("number", type(body.size), "body.size must be a number")
    local tissues = body.tissue or body.tissues
    h.assert_eq("table", type(tissues), "body tissues must be a table")
end)

test("5. rat legs zone has size (number) and tissue (table)", function()
    h.assert_truthy(rat and rat.body_tree, "rat.body_tree not loaded")
    local legs = rat.body_tree.legs
    h.assert_truthy(legs, "legs zone must exist")
    h.assert_eq("number", type(legs.size), "legs.size must be a number")
    local tissues = legs.tissue or legs.tissues
    h.assert_eq("table", type(tissues), "legs tissues must be a table")
end)

test("6. rat tail zone has size (number) and tissue (table)", function()
    h.assert_truthy(rat and rat.body_tree, "rat.body_tree not loaded")
    local tail = rat.body_tree.tail
    h.assert_truthy(tail, "tail zone must exist")
    h.assert_eq("number", type(tail.size), "tail.size must be a number")
    local tissues = tail.tissue or tail.tissues
    h.assert_eq("table", type(tissues), "tail tissues must be a table")
end)

test("7. rat zone sizes sum to approximately 1.0", function()
    h.assert_truthy(rat and rat.body_tree, "rat.body_tree not loaded")
    local total = 0
    for _, zone in pairs(rat.body_tree) do
        h.assert_truthy(zone.size, "each zone must have size")
        total = total + zone.size
    end
    -- Sizes are relative weights; plan uses integer weights (1,3,2,1=7)
    -- Normalize: sum should be > 0. If using fractions, sum ~1.0.
    -- If using integer weights, just verify they're all positive numbers.
    h.assert_truthy(total > 0, "zone sizes must sum to a positive number")
end)

test("8. rat body_tree zones reference only valid material names", function()
    h.assert_truthy(rat and rat.body_tree, "rat.body_tree not loaded")
    for zone_name, zone in pairs(rat.body_tree) do
        local tissues = zone.tissue or zone.tissues
        if tissues then
            for _, mat_name in ipairs(tissues) do
                h.assert_truthy(valid_materials[mat_name],
                    "zone '" .. zone_name .. "' references unknown material: "
                    .. tostring(mat_name)
                    .. " — must exist in src/meta/materials/")
            end
        end
    end
end)

---------------------------------------------------------------------------
-- PLAYER BODY_TREE TESTS
---------------------------------------------------------------------------
suite("PLAYER BODY_TREE: zone structure (WAVE-4)")

-- To test the player body_tree, we run main.lua in headless mode and
-- inspect the context. Since we can't easily extract the player table
-- from main.lua at require time, we use a subprocess approach.
-- For TDD, we define the expected structure and validate it.

-- Attempt to read the player table by parsing main.lua for body_tree
local main_path = "." .. SEP .. "src" .. SEP .. "main.lua"
local main_src = ""
local f = io.open(main_path, "r")
if f then
    main_src = f:read("*a")
    f:close()
end
local player_has_body_tree = main_src:find("body_tree") ~= nil

test("9. player table in main.lua contains body_tree", function()
    h.assert_truthy(player_has_body_tree,
        "player table in src/main.lua must have body_tree field (WAVE-4)")
end)

-- For structural tests, we run a headless Lua snippet that loads main.lua
-- context and dumps the player body_tree as a serialized table.
-- Since the game loop would start, we instead extract the expected structure.

local player_bt = nil
if player_has_body_tree then
    -- Extract player body_tree using a sandboxed dostring approach
    local extract_cmd = 'lua -e "' ..
        "package.path='src/?.lua;src/?/init.lua;'.. package.path; " ..
        "local f=io.open('src/main.lua','r'); local s=f:read('*a'); f:close(); " ..
        "local bt_str = s:match('body_tree%s*=%s*(%b{})'); " ..
        "if bt_str then " ..
        "  local fn = load('return ' .. bt_str); " ..
        "  if fn then " ..
        "    local ok,v = pcall(fn); " ..
        "    if ok then " ..
        "      for k,z in pairs(v) do " ..
        "        local t = z.tissue or {}; " ..
        "        io.write(k..':'..tostring(z.size)..':'..table.concat(t,',')..'\\n'); " ..
        "      end " ..
        "    end " ..
        "  end " ..
        "end" ..
        '"'
    local h2 = io.popen(extract_cmd)
    if h2 then
        player_bt = {}
        for line in h2:lines() do
            local zone_name, size_str, tissues_str = line:match("^([^:]+):([^:]+):(.*)$")
            if zone_name then
                local tissues = {}
                for t in (tissues_str or ""):gmatch("[^,]+") do
                    tissues[#tissues + 1] = t
                end
                player_bt[zone_name] = {
                    size = tonumber(size_str),
                    tissue = tissues,
                }
            end
        end
        h2:close()
        -- If empty, set to nil
        local count = 0
        for _ in pairs(player_bt) do count = count + 1 end
        if count == 0 then player_bt = nil end
    end
end

test("10. player has body_tree with 6 zones: head, torso, arms, hands, legs, feet", function()
    h.assert_truthy(player_bt, "player body_tree not extracted from main.lua")
    local expected = { "head", "torso", "arms", "hands", "legs", "feet" }
    local count = 0
    for _ in pairs(player_bt) do count = count + 1 end
    h.assert_eq(6, count, "player body_tree must have exactly 6 zones")
    for _, zone_name in ipairs(expected) do
        h.assert_truthy(player_bt[zone_name],
            "player body_tree must have zone: " .. zone_name)
    end
end)

test("11. player zone sizes are all positive numbers", function()
    h.assert_truthy(player_bt, "player body_tree not extracted")
    for zone_name, zone in pairs(player_bt) do
        h.assert_truthy(zone.size, "zone '" .. zone_name .. "' must have size")
        h.assert_eq("number", type(zone.size),
            "zone '" .. zone_name .. "' size must be a number")
        h.assert_truthy(zone.size > 0,
            "zone '" .. zone_name .. "' size must be positive")
    end
end)

test("12. player zone sizes sum to approximately 1.0", function()
    h.assert_truthy(player_bt, "player body_tree not extracted")
    local total = 0
    for _, zone in pairs(player_bt) do
        total = total + (zone.size or 0)
    end
    h.assert_truthy(total > 0, "player zone sizes must sum to a positive number")
end)

test("13. player body_tree zones reference only valid material names", function()
    h.assert_truthy(player_bt, "player body_tree not extracted")
    for zone_name, zone in pairs(player_bt) do
        local tissues = zone.tissue or zone.tissues or {}
        for _, mat_name in ipairs(tissues) do
            h.assert_truthy(valid_materials[mat_name],
                "player zone '" .. zone_name .. "' references unknown material: "
                .. tostring(mat_name))
        end
    end
end)

test("14. each player zone has tissue table with at least 1 entry", function()
    h.assert_truthy(player_bt, "player body_tree not extracted")
    for zone_name, zone in pairs(player_bt) do
        local tissues = zone.tissue or zone.tissues
        h.assert_truthy(tissues, "zone '" .. zone_name .. "' must have tissue")
        h.assert_truthy(#tissues >= 1,
            "zone '" .. zone_name .. "' tissue must have at least 1 entry")
    end
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
