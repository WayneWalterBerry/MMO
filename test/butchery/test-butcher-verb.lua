-- test/butchery/test-butcher-verb.lua
-- WAVE-1 TDD: Butcher verb handler tests.
-- Tests: butcher with knife, without knife, living creature, non-creature.
-- Implementation by Smithers (verb handler) and Flanders (objects) may not
-- exist yet — TDD: tests define the contract, failures are expected.
--
-- Must be run from repository root: lua test/butchery/test-butcher-verb.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load engine modules (pcall-guarded — TDD: may not exist yet)
---------------------------------------------------------------------------
local verbs_ok, verbs_mod = pcall(require, "engine.verbs")
if not verbs_ok then
    print("WARNING: engine.verbs not loadable — " .. tostring(verbs_mod))
    verbs_mod = nil
end

local handlers
if verbs_mod and verbs_mod.create then
    handlers = verbs_mod.create()
end

---------------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------------
local function deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[deep_copy(k)] = deep_copy(v) end
    return copy
end

local function capture_output(fn)
    local captured = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        captured[#captured + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Handler error: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

---------------------------------------------------------------------------
-- Mock factories (match patterns from test-combat-verbs.lua, test-cook-verb.lua)
---------------------------------------------------------------------------
local function make_mock_registry(objects)
    local reg = { _objects = {} }
    for _, obj in ipairs(objects) do
        reg._objects[obj.guid or obj.id] = obj
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:list()
        local result, seen = {}, {}
        for _, obj in pairs(self._objects) do
            local key = obj.guid or obj.id
            if not seen[key] then
                seen[key] = true
                result[#result + 1] = obj
            end
        end
        return result
    end
    reg.all = reg.list
    function reg:get(id) return self._objects[id] end
    function reg:remove(id)
        local obj = self._objects[id]
        self._objects[id] = nil
        return obj
    end
    function reg:add(obj)
        self._objects[obj.guid or obj.id] = obj
        if obj.id then self._objects[obj.id] = obj end
    end
    function reg:instantiate(type_id)
        -- Stub: create a minimal object from a type_id
        return {
            guid = "{inst-" .. type_id .. "-" .. tostring(math.random(9999)) .. "}",
            id = type_id,
            template = "small-item",
            name = type_id,
            keywords = { type_id },
            portable = true,
        }
    end
    function reg:deregister(guid)
        self._objects[guid] = nil
    end
    function reg:find_by_keyword(kw)
        local results = {}
        for _, obj in pairs(self._objects) do
            if obj.keywords then
                for _, k in ipairs(obj.keywords) do
                    if k:lower() == kw:lower() then
                        results[#results + 1] = obj
                        break
                    end
                end
            end
        end
        return results
    end
    return reg
end

local function make_butcher_knife()
    return {
        guid = "{test-butcher-knife-001}",
        id = "butcher-knife",
        template = "small-item",
        name = "a butcher knife",
        keywords = {"knife", "butcher knife", "carving knife"},
        description = "A broad-bladed knife with a worn wooden handle.",
        on_feel = "Heavy blade, smooth wooden handle.",
        portable = true,
        size = "small",
        weight = 0.8,
        capabilities = { "butchering", "cutting" },
        provides_tool = { "butchering", "cutting" },
    }
end

local function make_wolf_corpse()
    return {
        guid = "{dead-wolf-001}",
        id = "wolf",
        template = "furniture",
        name = "a dead wolf",
        keywords = {"dead wolf", "wolf corpse", "wolf carcass", "wolf"},
        description = "The wolf lies on its side, tongue lolling.",
        on_feel = "Coarse fur, already cooling.",
        animate = false,
        alive = false,
        portable = false,
        is_corpse = true,
        death_state = {
            template = "furniture",
            portable = false,
            butchery_products = {
                requires_tool = "butchering",
                duration = "5 minutes",
                products = {
                    { id = "wolf-meat", quantity = 3 },
                    { id = "wolf-bone", quantity = 2 },
                    { id = "wolf-hide", quantity = 1 },
                },
                narration = {
                    start = "You begin carving the wolf carcass...",
                    complete = "You finish butchering the wolf. Meat, bones, and hide lie at your feet.",
                },
                removes_corpse = true,
            },
        },
    }
end

local function make_living_wolf()
    return {
        guid = "{live-wolf-001}",
        id = "wolf",
        template = "creature",
        name = "a wolf",
        keywords = {"wolf"},
        description = "A large grey wolf stares you down.",
        on_feel = "You'd rather not.",
        animate = true,
        alive = true,
        portable = false,
        is_corpse = false,
    }
end

local function make_chair()
    return {
        guid = "{test-chair-001}",
        id = "chair",
        template = "furniture",
        name = "a wooden chair",
        keywords = {"chair", "wooden chair"},
        description = "A plain wooden chair.",
        on_feel = "Smooth wood.",
        portable = false,
        is_corpse = false,
    }
end

local function make_player(opts)
    opts = opts or {}
    local p = {
        max_health = 100,
        health = 100,
        injuries = {},
        hands = { nil, nil },
        worn_items = {},
        bags = {},
        worn = {},
        state = {},
    }
    -- find_tool_with_capability scans hands for matching capability
    function p:find_tool_with_capability(cap)
        for _, item in ipairs(self.hands) do
            if item then
                local caps = item.capabilities or item.provides_tool or {}
                for _, c in ipairs(caps) do
                    if c == cap then return item end
                end
            end
        end
        return nil
    end
    return p
end

local function make_room(objects)
    local contents = {}
    for _, obj in ipairs(objects or {}) do
        contents[#contents + 1] = obj.guid or obj.id
    end
    local room = {
        id = "test-room",
        name = "Test Room",
        template = "room",
        description = "A plain test room.",
        contents = contents,
        exits = {},
    }
    function room:add_object(obj)
        self.contents[#self.contents + 1] = obj.guid or obj.id
    end
    function room:remove_object(obj)
        for i, c in ipairs(self.contents) do
            if c == (obj.guid or obj.id) then
                table.remove(self.contents, i)
                return
            end
        end
    end
    return room
end

local function make_context(opts)
    opts = opts or {}
    local room_objects = opts.room_objects or {}
    local reg = make_mock_registry(room_objects)
    local room = make_room(room_objects)
    local player = opts.player or make_player()

    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 8,
        game_start_time = os.time(),
        current_verb = "butcher",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
        print = function(msg) print(msg) end,
    }
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("BUTCHER VERB: handler tests (WAVE-1 TDD)")

-- Test 1: butcher wolf corpse with knife → produces products, removes corpse
test("1. butcher wolf corpse with knife produces wolf-meat (x3), wolf-bone (x2), wolf-hide (x1)", function()
    h.assert_truthy(handlers, "engine.verbs must load and create handlers")
    h.assert_truthy(handlers["butcher"], "butcher verb handler must exist")

    math.randomseed(42)
    local knife = make_butcher_knife()
    local corpse = make_wolf_corpse()
    local player = make_player()
    player.hands[1] = knife

    local ctx = make_context({
        room_objects = { corpse, knife },
        player = player,
    })

    local output = capture_output(function()
        handlers["butcher"](ctx, "wolf")
    end)

    -- Should mention carving/butchering narration
    h.assert_truthy(output:find("carving") or output:find("butcher") or output:find("Meat"),
        "Output should contain butchery narration")

    -- Corpse should be removed from room
    local corpse_still_present = false
    for _, c in ipairs(ctx.current_room.contents) do
        if c == corpse.guid then
            corpse_still_present = true
            break
        end
    end
    h.assert_truthy(not corpse_still_present,
        "Wolf corpse should be removed from room after butchering")
end)

-- Test 2: butcher wolf without knife → error
test("2. butcher wolf without knife says 'You need a knife'", function()
    h.assert_truthy(handlers, "engine.verbs must load and create handlers")
    h.assert_truthy(handlers["butcher"], "butcher verb handler must exist")

    local corpse = make_wolf_corpse()
    local player = make_player()
    -- No knife in hands

    local ctx = make_context({
        room_objects = { corpse },
        player = player,
    })

    local output = capture_output(function()
        handlers["butcher"](ctx, "wolf")
    end)

    h.assert_truthy(output:lower():find("knife") or output:lower():find("need"),
        "Should mention needing a knife — got: " .. output)
end)

-- Test 3: butcher living creature → error
test("3. butcher living creature says 'You can't butcher that'", function()
    h.assert_truthy(handlers, "engine.verbs must load and create handlers")
    h.assert_truthy(handlers["butcher"], "butcher verb handler must exist")

    local wolf = make_living_wolf()
    local knife = make_butcher_knife()
    local player = make_player()
    player.hands[1] = knife

    local ctx = make_context({
        room_objects = { wolf, knife },
        player = player,
    })

    local output = capture_output(function()
        handlers["butcher"](ctx, "wolf")
    end)

    h.assert_truthy(output:lower():find("can't butcher") or output:lower():find("cannot butcher"),
        "Should reject butchering a living creature — got: " .. output)
end)

-- Test 4: butcher non-creature (chair) → error
test("4. butcher non-creature (chair) says 'You can't butcher that'", function()
    h.assert_truthy(handlers, "engine.verbs must load and create handlers")
    h.assert_truthy(handlers["butcher"], "butcher verb handler must exist")

    local chair = make_chair()
    local knife = make_butcher_knife()
    local player = make_player()
    player.hands[1] = knife

    local ctx = make_context({
        room_objects = { chair, knife },
        player = player,
    })

    local output = capture_output(function()
        handlers["butcher"](ctx, "chair")
    end)

    h.assert_truthy(output:lower():find("can't butcher") or output:lower():find("cannot butcher"),
        "Should reject butchering a chair — got: " .. output)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
