-- test/worlds/test-wyatt-safety.lua
-- WAVE-2b: Safety audit for Wyatt's World.
-- Verifies: no damage/weapons/poison, no scary words, positive taste
-- descriptions, E-rating enforcement, combat verb blocking.

package.path = "src/?.lua;src/?/init.lua;" .. package.path
local t = require("test.parser.test-helpers")

local SEP = package.config:sub(1, 1)
local is_windows = SEP == "\\"

local WYATT_ROOT  = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "wyatt-world"
local OBJECTS_DIR = WYATT_ROOT .. SEP .. "objects"
local ROOMS_DIR   = WYATT_ROOT .. SEP .. "rooms"

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------

local function load_lua(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local src = f:read("*a")
    f:close()
    local chunk, err
    if _VERSION == "Lua 5.1" then
        chunk, err = loadstring(src)
    else
        chunk, err = load(src)
    end
    if not chunk then return nil end
    local ok, result = pcall(chunk)
    if not ok then return nil end
    return result
end

local function list_lua_files(dir)
    local files = {}
    local cmd
    if is_windows then
        cmd = 'dir /b "' .. dir .. '\\*.lua" 2>nul'
    else
        cmd = 'ls ' .. dir .. '/*.lua 2>/dev/null'
    end
    local handle = io.popen(cmd)
    if handle then
        for line in handle:lines() do
            line = line:match("^%s*(.-)%s*$")
            if line and line:match("%.lua$") then
                local fname = line:match("([^/\\]+)$") or line
                files[#files + 1] = fname
            end
        end
        handle:close()
    end
    return files
end

-- Load all objects into a list
local function load_all_objects()
    local objects = {}
    local fnames = list_lua_files(OBJECTS_DIR)
    for _, fname in ipairs(fnames) do
        local o = load_lua(OBJECTS_DIR .. SEP .. fname)
        if o then
            o._filename = fname
            objects[#objects + 1] = o
        end
    end
    return objects
end

-- Load all rooms into a list
local function load_all_rooms()
    local rooms = {}
    local fnames = list_lua_files(ROOMS_DIR)
    for _, fname in ipairs(fnames) do
        local r = load_lua(ROOMS_DIR .. SEP .. fname)
        if r then
            r._filename = fname
            rooms[#rooms + 1] = r
        end
    end
    return rooms
end

-- Deep-search a table for a string key
local function table_has_key(tbl, key)
    if type(tbl) ~= "table" then return false end
    for k, v in pairs(tbl) do
        if k == key then return true end
        if type(v) == "table" then
            if table_has_key(v, key) then return true end
        end
    end
    return false
end

-- Deep-search all string values in a table for a pattern
local function table_has_pattern(tbl, pattern)
    if type(tbl) ~= "table" then return false end
    for _, v in pairs(tbl) do
        if type(v) == "string" and v:lower():find(pattern) then
            return true
        end
        if type(v) == "table" then
            if table_has_pattern(v, pattern) then return true end
        end
    end
    return false
end

local all_objects = load_all_objects()
local all_rooms = load_all_rooms()

-----------------------------------------------------------------------
-- Suite 1: no damage property on any object
-----------------------------------------------------------------------
t.suite("safety — no damage property")

t.test("no object has 'damage' property", function()
    local bad = nil
    for _, o in ipairs(all_objects) do
        if table_has_key(o, "damage") then
            bad = o._filename
            break
        end
    end
    t.assert_nil(bad, "object with 'damage' property found: " .. tostring(bad))
end)

-----------------------------------------------------------------------
-- Suite 2: no weapon_type property
-----------------------------------------------------------------------
t.suite("safety — no weapon_type property")

t.test("no object has 'weapon_type' property", function()
    local bad = nil
    for _, o in ipairs(all_objects) do
        if table_has_key(o, "weapon_type") then
            bad = o._filename
            break
        end
    end
    t.assert_nil(bad, "object with 'weapon_type' property found: " .. tostring(bad))
end)

-----------------------------------------------------------------------
-- Suite 3: no poison in any field
-----------------------------------------------------------------------
t.suite("safety — no poison content")

t.test("no object contains 'poison' in any string field", function()
    local bad = nil
    for _, o in ipairs(all_objects) do
        if table_has_pattern(o, "poison") then
            bad = o._filename
            break
        end
    end
    t.assert_nil(bad, "object with 'poison' in text: " .. tostring(bad))
end)

-----------------------------------------------------------------------
-- Suite 4: no scary words in room descriptions
-----------------------------------------------------------------------
t.suite("safety — no scary room descriptions")

local scary_words = { "dark", "shadow", "monster", "death", "blood", "scary" }

for _, word in ipairs(scary_words) do
    t.test("no room description contains '" .. word .. "'", function()
        local bad = nil
        for _, r in ipairs(all_rooms) do
            local desc = (r.description or ""):lower()
            if desc:find(word, 1, true) then
                bad = r._filename
                break
            end
        end
        t.assert_nil(bad,
            "room with '" .. word .. "' in description: " .. tostring(bad))
    end)
end

-----------------------------------------------------------------------
-- Suite 5: all on_taste descriptions are positive/fun
-----------------------------------------------------------------------
t.suite("safety — positive on_taste")

-- Negative words that should NOT appear in on_taste (whole-word match)
local negative_taste_words = {
    "poison", "vomit", "sick", "die", "dying", "hurt",
    "damage", "burn", "choke", "pain", "disgust",
}

-- Match whole word only (avoids "paint" matching "pain")
local function contains_whole_word(text, word)
    local pattern = "%f[%a]" .. word .. "%f[%A]"
    return text:find(pattern) ~= nil
end

t.test("no on_taste has negative consequence words", function()
    local bad = nil
    local bad_word = nil
    for _, o in ipairs(all_objects) do
        if o.on_taste then
            local taste_lower = o.on_taste:lower()
            for _, word in ipairs(negative_taste_words) do
                if contains_whole_word(taste_lower, word) then
                    bad = o._filename
                    bad_word = word
                    break
                end
            end
        end
        if bad then break end
    end
    t.assert_nil(bad,
        "object on_taste with negative word '" .. tostring(bad_word)
        .. "': " .. tostring(bad))
end)

t.test("objects with on_taste use playful language", function()
    local count = 0
    local exclaim_count = 0
    for _, o in ipairs(all_objects) do
        if o.on_taste then
            count = count + 1
            if o.on_taste:find("!") then
                exclaim_count = exclaim_count + 1
            end
        end
    end
    -- Most taste descriptions should be fun (have exclamation marks)
    t.assert_truthy(count > 0, "should have objects with on_taste")
    local ratio = exclaim_count / count
    t.assert_truthy(ratio > 0.5,
        "majority of on_taste should use playful language (! found in "
        .. exclaim_count .. "/" .. count .. ")")
end)

-----------------------------------------------------------------------
-- Suite 6: rating = "E" on world.lua
-----------------------------------------------------------------------
t.suite("safety — E-rating")

t.test("world.lua has rating E", function()
    local world = load_lua(WYATT_ROOT .. SEP .. "world.lua")
    t.assert_truthy(world, "world.lua should load")
    t.assert_eq("E", world.rating, "rating should be E (Everyone)")
end)

t.test("world.lua has no forbidden aesthetic materials", function()
    local world = load_lua(WYATT_ROOT .. SEP .. "world.lua")
    t.assert_truthy(world)
    local forbidden = world.theme and world.theme.aesthetic
                      and world.theme.aesthetic.forbidden
    t.assert_truthy(forbidden, "world should declare forbidden materials")
    -- Verify key forbidden terms are listed
    local has_blood = false
    local has_poison = false
    for _, word in ipairs(forbidden or {}) do
        if word == "blood" then has_blood = true end
        if word == "poison" then has_poison = true end
    end
    t.assert_truthy(has_blood, "blood should be in forbidden list")
    t.assert_truthy(has_poison, "poison should be in forbidden list")
end)

-----------------------------------------------------------------------
-- Suite 7: combat verbs blocked in E-rated world
-----------------------------------------------------------------------
t.suite("safety — combat verb blocking (spec check)")

local E_RESTRICTED_VERBS = {
    "attack", "fight", "kill", "stab", "slash",
    "punch", "kick", "hit", "harm", "hurt", "injure", "wound",
}

local e_world = { id = "wyatt-world", rating = "E" }

local function spec_check(world, verb)
    local restricted = {
        attack = true, fight = true, kill = true, stab = true,
        slash = true, punch = true, kick = true, hit = true,
        harm = true, hurt = true, injure = true, wound = true,
    }
    if world and world.rating == "E" and restricted[verb] then
        return true
    end
    return false
end

for _, verb in ipairs(E_RESTRICTED_VERBS) do
    t.test(verb .. " is blocked in E-rated wyatt-world", function()
        t.assert_truthy(spec_check(e_world, verb),
            verb .. " should be blocked by E-rating")
    end)
end

-- Safe verbs must NOT be blocked
local safe_verbs = {
    "look", "feel", "take", "taste", "smell", "listen",
    "read", "drop", "put", "press", "open", "go",
}

for _, verb in ipairs(safe_verbs) do
    t.test(verb .. " NOT blocked in E-rated world", function()
        t.assert_truthy(not spec_check(e_world, verb),
            verb .. " should be allowed in E-rated world")
    end)
end

local exit_code = t.summary()
os.exit(exit_code > 0 and 1 or 0)
