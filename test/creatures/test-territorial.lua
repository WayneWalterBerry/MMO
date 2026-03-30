-- test/creatures/test-territorial.lua
-- WAVE-5 TDD: Territorial marking — wolf marks territory, BFS radius,
-- own-territory patrol, foreign-territory response, smell detection (Q5).
-- Q5 resolved: player detects markers via SMELL only, NOT via LOOK.
-- Must be run from repository root: lua test/creatures/test-territorial.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

math.randomseed(42)

---------------------------------------------------------------------------
-- Load engine modules (pcall-guarded — TDD: may not exist yet)
---------------------------------------------------------------------------
local creatures_ok, creatures = pcall(require, "engine.creatures")
if not creatures_ok then
    print("WARNING: engine.creatures not loadable — " .. tostring(creatures))
    creatures = nil
end

local terr_ok, territorial = pcall(require, "engine.creatures.territorial")
if not terr_ok then
    print("WARNING: engine.creatures.territorial not loadable — " .. tostring(territorial))
    territorial = nil
end

---------------------------------------------------------------------------
-- Load wolf and territory-marker definitions
---------------------------------------------------------------------------
local wolf_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "creatures" .. SEP .. "wolf.lua"
local ok_wolf, wolf_def = pcall(dofile, wolf_path)
if not ok_wolf then
    print("WARNING: wolf.lua not found — some tests use fallback mock")
    wolf_def = nil
end

local marker_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "objects" .. SEP .. "territory-marker.lua"
local ok_marker, marker_def = pcall(dofile, marker_path)
if not ok_marker then
    print("WARNING: territory-marker.lua not found — tests use mock (TDD: expected)")
    marker_def = nil
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local guid_counter = 0
local function next_guid()
    guid_counter = guid_counter + 1
    return "{test-terr-" .. guid_counter .. "}"
end

local function deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[k] = deep_copy(v) end
    return copy
end

local function make_wolf(overrides)
    local base = wolf_def and deep_copy(wolf_def) or {
        template = "creature",
        id = "wolf",
        name = "a grey wolf",
        animate = true,
        alive = true,
        health = 25,
        max_health = 25,
        size = "medium",
        initial_state = "alive-idle",
        _state = "alive-idle",
        behavior = {
            default = "idle",
            aggression = 70,
            flee_threshold = 20,
            territorial = true,
            territory = "hallway",
            pack_animal = true,
        },
        drives = {
            hunger = { value = 50, decay_rate = 1, max = 100, min = 0 },
            fear   = { value = 0, decay_rate = -5, max = 100, min = 0 },
        },
    }
    base.guid = next_guid()
    if overrides then
        for k, v in pairs(overrides) do base[k] = v end
    end
    return base
end

local function make_marker(owner_guid, room_id, overrides)
    local m = marker_def and deep_copy(marker_def) or {
        template = "small-item",
        id = "territory-marker",
        name = "a territorial scent mark",
        keywords = { "scent", "mark", "territory marker" },
        material = "organic",
        portable = false,
        visible = false,
        on_feel = "You feel nothing unusual.",
        on_smell = "You catch a musky animal scent.",
        on_look = nil,
        description = nil,
        territory = {
            owner = owner_guid,
            radius = 2,
        },
    }
    m.guid = next_guid()
    m.location = room_id
    if m.territory then
        m.territory.owner = owner_guid
    end
    if overrides then
        for k, v in pairs(overrides) do m[k] = v end
    end
    return m
end

local function make_room(id, contents, exits)
    return {
        guid = "{room-" .. id .. "}",
        id = id,
        template = "room",
        name = id,
        description = "A test room.",
        contents = contents or {},
        exits = exits or {},
    }
end

local function make_mock_registry(objects)
    local reg = { _objects = {} }
    for _, obj in ipairs(objects) do
        reg._objects[obj.guid] = obj
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:get(id) return self._objects[id] end
    function reg:list()
        local seen, result = {}, {}
        for _, obj in pairs(self._objects) do
            if not seen[obj.guid] then
                seen[obj.guid] = true
                result[#result + 1] = obj
            end
        end
        return result
    end
    function reg:add(obj)
        self._objects[obj.guid] = obj
        if obj.id then self._objects[obj.id] = obj end
    end
    function reg:find_in_room(room_id, filter_fn)
        local found = {}
        for _, obj in pairs(self._objects) do
            if obj.location == room_id and (not filter_fn or filter_fn(obj)) then
                found[#found + 1] = obj
            end
        end
        return found
    end
    return reg
end

local function make_context(reg, room, rooms_map)
    return {
        registry = reg,
        rooms = rooms_map or { [room.id] = room },
        current_room = room,
        player = { location = room.id, health = 50, max_health = 50, hands = { nil, nil } },
        game_time = 100,
        headless = true,
        print = function() end,
    }
end

---------------------------------------------------------------------------
-- TESTS: Territorial Marking
---------------------------------------------------------------------------
suite("TERRITORIAL: wolf territory marking + detection (WAVE-5 TDD)")

test("1. wolf marks territory — wolf enters room → territory-marker placed", function()
    local terr_mod = territorial or (creatures and creatures.territorial)
        or (creatures and creatures._test and creatures._test.territorial)
    h.assert_truthy(terr_mod, "territorial module must be loadable (TDD red phase)")

    local mark_territory = terr_mod.mark_territory
        or terr_mod.place_marker
        or terr_mod.create_marker
    h.assert_truthy(mark_territory, "mark_territory function must exist")

    local wolf = make_wolf({ location = "hallway" })
    local room = make_room("hallway", { wolf.guid })
    local reg  = make_mock_registry({ wolf, room })
    local ctx  = make_context(reg, room)

    mark_territory(wolf, ctx)

    -- Verify: a territory-marker object should now exist in the room
    local found_marker = false
    for _, obj in ipairs(reg:list()) do
        if (obj.id == "territory-marker" or (type(obj.id) == "string" and obj.id:find("^territory%-marker")))
            and (obj.location == "hallway" or obj.territory) then
            found_marker = true
            -- Verify marker is owned by this wolf
            if obj.territory then
                h.assert_eq(wolf.guid, obj.territory.owner,
                    "marker must be owned by the wolf that placed it")
            end
            break
        end
    end
    -- Also check room contents
    if not found_marker then
        for _, ref in ipairs(room.contents or {}) do
            local obj = reg:get(ref)
            if obj and (obj.id == "territory-marker" or (type(obj.id) == "string" and obj.id:find("^territory%-marker"))) then
                found_marker = true
                break
            end
        end
    end
    h.assert_truthy(found_marker, "wolf must place a territory-marker in the room")
end)

test("2. territory BFS radius — marker with radius 2 affects rooms within 2 exits", function()
    local terr_mod = territorial or (creatures and creatures.territorial)
        or (creatures and creatures._test and creatures._test.territorial)
    h.assert_truthy(terr_mod, "territorial module must be loadable (TDD red phase)")

    local get_territory_rooms = terr_mod.get_territory_rooms
        or terr_mod.bfs_territory
        or terr_mod.territory_range
    h.assert_truthy(get_territory_rooms, "get_territory_rooms/bfs_territory function must exist")

    -- Build a 3-room chain: A -- B -- C
    local room_a = make_room("room-a", {}, { east = { target = "room-b" } })
    local room_b = make_room("room-b", {}, {
        west = { target = "room-a" },
        east = { target = "room-c" },
    })
    local room_c = make_room("room-c", {}, { west = { target = "room-b" } })
    local room_d = make_room("room-d", {}, {})  -- disconnected, outside range

    local rooms_map = {
        ["room-a"] = room_a,
        ["room-b"] = room_b,
        ["room-c"] = room_c,
        ["room-d"] = room_d,
    }

    local wolf = make_wolf({ location = "room-a" })
    local marker = make_marker(wolf.guid, "room-a", { territory = { owner = wolf.guid, radius = 2 } })
    local reg = make_mock_registry({ wolf, marker, room_a, room_b, room_c, room_d })
    local ctx = make_context(reg, room_a, rooms_map)

    local affected = get_territory_rooms(marker, ctx)

    h.assert_truthy(affected, "get_territory_rooms must return a table")
    h.assert_eq("table", type(affected), "result must be a table")

    -- room-a (distance 0), room-b (distance 1), room-c (distance 2) should be affected
    local has_a, has_b, has_c, has_d = false, false, false, false
    for _, rid in ipairs(affected) do
        if rid == "room-a" then has_a = true end
        if rid == "room-b" then has_b = true end
        if rid == "room-c" then has_c = true end
        if rid == "room-d" then has_d = true end
    end

    h.assert_truthy(has_a, "room-a (distance 0) must be in territory")
    h.assert_truthy(has_b, "room-b (distance 1) must be in territory")
    h.assert_truthy(has_c, "room-c (distance 2) must be in territory")
    h.assert_truthy(not has_d, "room-d (disconnected) must NOT be in territory")
end)

test("3. own territory patrol — wolf encountering own marker stays (patrol)", function()
    local terr_mod = territorial or (creatures and creatures.territorial)
        or (creatures and creatures._test and creatures._test.territorial)
    h.assert_truthy(terr_mod, "territorial module must be loadable (TDD red phase)")

    local evaluate_marker = terr_mod.evaluate_marker
        or terr_mod.respond_to_marker
        or terr_mod.on_marker_found
    h.assert_truthy(evaluate_marker, "evaluate_marker function must exist")

    local wolf = make_wolf({ location = "hallway" })
    local marker = make_marker(wolf.guid, "hallway")  -- wolf's OWN marker
    local room = make_room("hallway", { wolf.guid, marker.guid })
    local reg  = make_mock_registry({ wolf, marker, room })
    local ctx  = make_context(reg, room)

    local response = evaluate_marker(wolf, marker, ctx)

    h.assert_truthy(response, "evaluate_marker must return a response")
    -- Response should be "patrol" or "stay" — wolf patrols own territory
    local action = response.action or response
    h.assert_truthy(action == "patrol" or action == "stay" or action == "guard",
        "wolf encountering own marker should patrol/stay/guard, got: " .. tostring(action))
end)

test("4. foreign territory response — high aggression challenges, low aggression avoids", function()
    local terr_mod = territorial or (creatures and creatures.territorial)
        or (creatures and creatures._test and creatures._test.territorial)
    h.assert_truthy(terr_mod, "territorial module must be loadable (TDD red phase)")

    local evaluate_marker = terr_mod.evaluate_marker
        or terr_mod.respond_to_marker
        or terr_mod.on_marker_found
    h.assert_truthy(evaluate_marker, "evaluate_marker function must exist")

    -- High-aggression wolf encountering foreign marker → challenge
    local wolf_aggressive = make_wolf({ location = "cellar" })
    if wolf_aggressive.behavior then
        wolf_aggressive.behavior.aggression = 90
    end
    local foreign_marker = make_marker("{some-other-wolf}", "cellar")
    local room = make_room("cellar", { wolf_aggressive.guid, foreign_marker.guid })
    local reg  = make_mock_registry({ wolf_aggressive, foreign_marker, room })
    local ctx  = make_context(reg, room)

    local response_agg = evaluate_marker(wolf_aggressive, foreign_marker, ctx)
    h.assert_truthy(response_agg, "evaluate_marker must return a response for aggressive wolf")
    local action_agg = response_agg.action or response_agg
    h.assert_truthy(action_agg == "challenge" or action_agg == "attack" or action_agg == "mark",
        "high-aggression wolf should challenge/attack/mark foreign territory, got: " .. tostring(action_agg))

    -- Low-aggression wolf encountering foreign marker → avoid
    local wolf_timid = make_wolf({ location = "cellar" })
    if wolf_timid.behavior then
        wolf_timid.behavior.aggression = 10
    end
    local reg2 = make_mock_registry({ wolf_timid, foreign_marker, room })
    local ctx2 = make_context(reg2, room)

    local response_timid = evaluate_marker(wolf_timid, foreign_marker, ctx2)
    h.assert_truthy(response_timid, "evaluate_marker must return a response for timid wolf")
    local action_timid = response_timid.action or response_timid
    h.assert_truthy(action_timid == "avoid" or action_timid == "flee" or action_timid == "retreat",
        "low-aggression wolf should avoid/flee foreign territory, got: " .. tostring(action_timid))
end)

test("5. smell detection — Q5: player detects marker via smell, NOT via look", function()
    -- Q5 resolved: markers detectable via smell only. look fails.
    -- This test validates the territory-marker object definition contract.

    local marker = marker_def and deep_copy(marker_def) or make_marker("{owner}", "test-room")

    -- on_smell MUST exist and be non-empty (sensory detection)
    h.assert_truthy(marker.on_smell, "territory-marker must have on_smell")
    h.assert_eq("string", type(marker.on_smell), "on_smell must be a string")
    h.assert_truthy(#marker.on_smell > 0, "on_smell must be non-empty")

    -- Verify smell mentions musky/animal scent (per Q5 decision)
    local smell_lower = marker.on_smell:lower()
    h.assert_truthy(
        smell_lower:find("musky") or smell_lower:find("animal") or smell_lower:find("scent"),
        "on_smell should reference musky/animal scent per Q5, got: " .. marker.on_smell
    )

    -- look/description should NOT reveal the marker
    -- Either nil, empty, or explicitly hidden
    local look_hidden = (marker.description == nil or marker.description == "")
        or (marker.visible == false)
        or (marker.on_look == nil or marker.on_look == "")
    h.assert_truthy(look_hidden,
        "territory-marker must NOT be detectable via look (Q5: smell only). "
        .. "visible=" .. tostring(marker.visible)
        .. " description=" .. tostring(marker.description)
        .. " on_look=" .. tostring(marker.on_look))
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
