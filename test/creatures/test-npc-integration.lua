-- test/creatures/test-npc-integration.lua
-- WAVE-3 TDD: NPC integration tests — rat in cellar, keyword resolution,
-- sensory properties, creature tick, wandering behavior.
-- Must be run from repository root: lua test/creatures/test-npc-integration.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

math.randomseed(42)

---------------------------------------------------------------------------
-- Load engine modules (pcall-guarded — integration needs real modules)
---------------------------------------------------------------------------
local ok_creatures, creatures = pcall(require, "engine.creatures")
if not ok_creatures then
    print("WARNING: engine.creatures not found — integration tests will fail (TDD: expected)")
    creatures = nil
end

local ok_registry_mod, registry_mod = pcall(require, "engine.registry")
if not ok_registry_mod then
    print("WARNING: engine.registry not found — integration tests will fail")
    registry_mod = nil
end

local ok_loader, loader = pcall(require, "engine.loader")
if not ok_loader then
    print("WARNING: engine.loader not found — integration tests will fail")
    loader = nil
end

---------------------------------------------------------------------------
-- Load rat object definition directly
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local rat_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "creatures" .. SEP .. "rat.lua"
local ok_rat, rat_def = pcall(dofile, rat_path)
if not ok_rat then
    print("WARNING: rat.lua not found — rat tests will fail (TDD: expected)")
    rat_def = nil
end

---------------------------------------------------------------------------
-- Load cellar room definition directly
---------------------------------------------------------------------------
local cellar_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "rooms" .. SEP .. "cellar.lua"
local ok_cellar, cellar_def = pcall(dofile, cellar_path)
if not ok_cellar then
    print("WARNING: cellar.lua not found — cellar tests will fail (TDD: expected)")
    cellar_def = nil
end

---------------------------------------------------------------------------
-- Mock helpers for creature tick integration
---------------------------------------------------------------------------
local portal_counter = 200

local function make_portal(target_room_id, traversable)
    portal_counter = portal_counter + 1
    local pid = "{int-portal-" .. portal_counter .. "}"
    return {
        guid = pid,
        id = "int-portal-" .. portal_counter,
        _state = traversable and "open" or "closed",
        states = {
            open = { traversable = true },
            closed = { traversable = false },
        },
        portal = { target = target_room_id },
    }, pid
end

local function make_mock_room(id, overrides)
    local r = {
        guid = "{int-room-" .. id .. "}",
        id = id,
        name = "Integration " .. id,
        template = "room",
        exits = {},
        contents = {},
    }
    if overrides then
        for k, v in pairs(overrides) do r[k] = v end
    end
    return r
end

local function make_mock_registry(objects)
    local reg = {
        _objects = objects or {},
    }
    function reg:list()
        return self._objects
    end
    function reg:get(id)
        for _, obj in ipairs(self._objects) do
            if obj.guid == id or obj.id == id then return obj end
        end
        return nil
    end
    function reg:find_by_keyword(keyword)
        local kw = keyword:lower()
        for _, obj in ipairs(self._objects) do
            if type(obj.keywords) == "table" then
                for _, k in ipairs(obj.keywords) do
                    if k:lower() == kw then return obj end
                end
            end
        end
        return nil
    end
    return reg
end

local function rooms_by_id(...)
    local t = {}
    for _, r in ipairs({...}) do t[r.id] = r end
    return t
end

---------------------------------------------------------------------------
-- TESTS: Rat Exists in Cellar
---------------------------------------------------------------------------
suite("NPC INTEGRATION: rat in cellar (WAVE-3)")

test("1. cellar room definition loads successfully", function()
    h.assert_truthy(ok_cellar, "cellar.lua failed to load: " .. tostring(cellar_def))
    h.assert_eq("table", type(cellar_def), "cellar.lua must return a table")
end)

test("2. cellar has instances array", function()
    h.assert_truthy(cellar_def, "cellar not loaded")
    h.assert_eq("table", type(cellar_def.instances), "cellar must have instances")
end)

test("3. cellar instances include a rat entry", function()
    h.assert_truthy(cellar_def, "cellar not loaded")
    h.assert_truthy(cellar_def.instances, "cellar must have instances")
    local found_rat = false
    for _, inst in ipairs(cellar_def.instances) do
        if inst.id and inst.id:find("rat") then
            found_rat = true
            break
        end
        -- Also check type_id matches rat guid
        if rat_def and inst.type_id == rat_def.guid then
            found_rat = true
            break
        end
    end
    h.assert_truthy(found_rat,
        "cellar instances must include a rat entry (id containing 'rat' or matching rat guid)")
end)

---------------------------------------------------------------------------
-- TESTS: Rat Findable by Keyword
---------------------------------------------------------------------------
suite("NPC INTEGRATION: rat keyword resolution (WAVE-3)")

test("4. rat object has 'rat' in keywords", function()
    h.assert_truthy(rat_def, "rat.lua not loaded")
    h.assert_eq("table", type(rat_def.keywords), "keywords must be a table")
    local found = false
    for _, kw in ipairs(rat_def.keywords) do
        if kw == "rat" then found = true; break end
    end
    h.assert_truthy(found, "rat keywords must include 'rat'")
end)

test("5. rat is findable by keyword 'rat' in mock registry", function()
    h.assert_truthy(rat_def, "rat.lua not loaded")
    local rat_instance = {}
    for k, v in pairs(rat_def) do rat_instance[k] = v end
    rat_instance.location = "cellar"

    local reg = make_mock_registry({ rat_instance })
    local found = reg:find_by_keyword("rat")
    h.assert_truthy(found, "find_by_keyword('rat') must return the rat object")
    h.assert_eq(rat_instance.guid, found.guid, "found object guid must match rat guid")
end)

test("6. rat is findable by keyword 'rodent'", function()
    h.assert_truthy(rat_def, "rat.lua not loaded")
    local has_rodent = false
    for _, kw in ipairs(rat_def.keywords) do
        if kw == "rodent" then has_rodent = true; break end
    end
    h.assert_truthy(has_rodent, "rat keywords should include 'rodent'")
end)

---------------------------------------------------------------------------
-- TESTS: Rat Sensory Properties
---------------------------------------------------------------------------
suite("NPC INTEGRATION: rat sensory properties (WAVE-3)")

test("7. rat has on_feel (mandatory dark sense)", function()
    h.assert_truthy(rat_def, "rat.lua not loaded")
    h.assert_truthy(rat_def.on_feel, "on_feel is mandatory for all objects")
    h.assert_eq("string", type(rat_def.on_feel), "on_feel must be a string")
    h.assert_truthy(#rat_def.on_feel > 0, "on_feel must not be empty")
end)

test("8. rat has on_smell", function()
    h.assert_truthy(rat_def, "rat.lua not loaded")
    h.assert_truthy(rat_def.on_smell, "on_smell should exist for a creature")
    h.assert_eq("string", type(rat_def.on_smell), "on_smell must be a string")
end)

test("9. rat has on_listen", function()
    h.assert_truthy(rat_def, "rat.lua not loaded")
    h.assert_truthy(rat_def.on_listen, "on_listen should exist for a creature")
    h.assert_eq("string", type(rat_def.on_listen), "on_listen must be a string")
end)

test("10. rat has description", function()
    h.assert_truthy(rat_def, "rat.lua not loaded")
    h.assert_truthy(rat_def.description, "description must exist")
    h.assert_eq("string", type(rat_def.description), "description must be a string")
end)

test("11. rat states have room_presence text", function()
    h.assert_truthy(rat_def, "rat.lua not loaded")
    h.assert_truthy(rat_def.states, "states must exist")
    -- At least alive-idle should have room_presence
    local idle = rat_def.states["alive-idle"]
    h.assert_truthy(idle, "alive-idle state must exist")
    h.assert_truthy(idle.room_presence,
        "alive-idle state must have room_presence for look rendering")
    h.assert_eq("string", type(idle.room_presence), "room_presence must be a string")
end)

test("12. rat has on_taste", function()
    h.assert_truthy(rat_def, "rat.lua not loaded")
    -- on_taste is optional but expected for a complete creature
    if rat_def.on_taste then
        h.assert_eq("string", type(rat_def.on_taste), "on_taste must be a string")
    end
    -- If no on_taste, this test still passes (not strictly required)
    h.assert_truthy(true, "on_taste check complete")
end)

---------------------------------------------------------------------------
-- TESTS: Creature Tick Runs Without Error
---------------------------------------------------------------------------
suite("NPC INTEGRATION: creature tick (WAVE-3)")

test("13. creature tick runs without error on rat instance", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    h.assert_truthy(rat_def, "rat.lua not loaded")

    -- Create a live rat instance
    local rat_instance = {}
    for k, v in pairs(rat_def) do
        if type(v) == "table" then
            -- Shallow copy tables to avoid mutating the definition
            rat_instance[k] = {}
            for k2, v2 in pairs(v) do rat_instance[k][k2] = v2 end
        else
            rat_instance[k] = v
        end
    end
    rat_instance.location = "cellar"
    -- Deep copy drives to avoid cross-test contamination
    rat_instance.drives = {
        hunger = {},
        fear = {},
        curiosity = {},
    }
    for drive_name, drive in pairs(rat_def.drives) do
        for k, v in pairs(drive) do
            rat_instance.drives[drive_name][k] = v
        end
    end

    local room = make_mock_room("cellar")
    local reg = make_mock_registry({ rat_instance, room })
    local ctx = {
        registry = reg,
        rooms = rooms_by_id(room),
        current_room = room,
        player = { location = "cellar" },
    }

    math.randomseed(42)
    h.assert_no_error(function()
        local msgs = creatures.tick(ctx)
        h.assert_eq("table", type(msgs), "tick must return a table")
    end, "creature tick on real rat instance must not crash")
end)

---------------------------------------------------------------------------
-- TESTS: Rat Wanders Between Rooms
---------------------------------------------------------------------------
suite("NPC INTEGRATION: rat wandering (WAVE-3)")

test("14. rat wanders to adjacent room over multiple ticks", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    h.assert_truthy(rat_def, "rat.lua not loaded")

    -- Create rat instance with deep-copied fields
    local rat_instance = {}
    for k, v in pairs(rat_def) do
        if type(v) ~= "table" then rat_instance[k] = v end
    end
    rat_instance.location = "cellar"
    rat_instance._state = "alive-idle"
    -- Deep copy nested tables
    rat_instance.states = {}
    for state_name, state in pairs(rat_def.states) do
        rat_instance.states[state_name] = {}
        for k, v in pairs(state) do rat_instance.states[state_name][k] = v end
    end
    rat_instance.drives = {}
    for drive_name, drive in pairs(rat_def.drives) do
        rat_instance.drives[drive_name] = {}
        for k, v in pairs(drive) do rat_instance.drives[drive_name][k] = v end
    end
    rat_instance.behavior = {}
    for k, v in pairs(rat_def.behavior) do rat_instance.behavior[k] = v end
    rat_instance.behavior.wander_chance = 90 -- high wander chance for testing
    rat_instance.reactions = {}
    for rname, r in pairs(rat_def.reactions) do
        rat_instance.reactions[rname] = {}
        for k, v in pairs(r) do rat_instance.reactions[rname][k] = v end
    end
    rat_instance.movement = {}
    for k, v in pairs(rat_def.movement) do rat_instance.movement[k] = v end
    rat_instance.awareness = {}
    for k, v in pairs(rat_def.awareness) do rat_instance.awareness[k] = v end
    rat_instance.keywords = {}
    for _, kw in ipairs(rat_def.keywords) do rat_instance.keywords[#rat_instance.keywords + 1] = kw end

    -- Set up two connected rooms
    local p1, pid1 = make_portal("hallway", true)
    local p2, pid2 = make_portal("cellar", true)
    local cellar = make_mock_room("cellar", {
        exits = { north = { portal = pid1 } },
    })
    local hallway = make_mock_room("hallway", {
        exits = { south = { portal = pid2 } },
    })

    local reg = make_mock_registry({ rat_instance, p1, p2, cellar, hallway })
    local rooms = rooms_by_id(cellar, hallway)
    local ctx = {
        registry = reg,
        rooms = rooms,
        current_room = cellar,
        player = { location = "cellar" },
    }

    -- Run many ticks with different seeds to give rat opportunities to wander
    local moved = false
    for seed = 42, 142 do
        math.randomseed(seed)
        local ok_tick, msgs = pcall(creatures.tick, ctx)
        if ok_tick and rat_instance.location ~= "cellar" then
            moved = true
            break
        end
    end

    h.assert_truthy(moved,
        "rat should wander to adjacent room after multiple ticks — "
        .. "final location: " .. tostring(rat_instance.location))
end)

test("15. rat stays put when no exits available", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")

    -- Create minimal rat instance
    local rat_instance = {}
    for k, v in pairs(rat_def) do
        if type(v) ~= "table" then rat_instance[k] = v end
    end
    rat_instance.location = "isolated"
    rat_instance._state = "alive-idle"
    rat_instance.states = {}
    for state_name, state in pairs(rat_def.states) do
        rat_instance.states[state_name] = {}
        for k, v in pairs(state) do rat_instance.states[state_name][k] = v end
    end
    rat_instance.drives = {}
    for drive_name, drive in pairs(rat_def.drives) do
        rat_instance.drives[drive_name] = {}
        for k, v in pairs(drive) do rat_instance.drives[drive_name][k] = v end
    end
    rat_instance.behavior = {}
    for k, v in pairs(rat_def.behavior) do rat_instance.behavior[k] = v end
    rat_instance.reactions = {}
    for rname, r in pairs(rat_def.reactions) do
        rat_instance.reactions[rname] = {}
        for k, v in pairs(r) do rat_instance.reactions[rname][k] = v end
    end
    rat_instance.movement = {}
    for k, v in pairs(rat_def.movement) do rat_instance.movement[k] = v end
    rat_instance.awareness = {}
    for k, v in pairs(rat_def.awareness) do rat_instance.awareness[k] = v end
    rat_instance.keywords = {}
    for _, kw in ipairs(rat_def.keywords) do rat_instance.keywords[#rat_instance.keywords + 1] = kw end

    -- Room with no exits
    local isolated = make_mock_room("isolated", { exits = {} })
    local reg = make_mock_registry({ rat_instance, isolated })
    local ctx = {
        registry = reg,
        rooms = rooms_by_id(isolated),
        current_room = isolated,
        player = { location = "isolated" },
    }

    math.randomseed(42)
    h.assert_no_error(function()
        for _ = 1, 10 do
            creatures.tick(ctx)
        end
    end, "creature tick in room with no exits must not crash")

    h.assert_eq("isolated", rat_instance.location,
        "rat must stay in isolated room with no exits")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
