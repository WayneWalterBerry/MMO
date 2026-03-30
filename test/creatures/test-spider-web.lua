-- test/creatures/test-spider-web.lua
-- WAVE-4 TDD: Spider web creation, NPC obstacle blocking, player passability,
-- and max-web-per-room cap. Other agents building in parallel — tests from spec.
--
-- Must be run from repository root: lua test/creatures/test-spider-web.lua

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

---------------------------------------------------------------------------
-- Load spider-web object definition
---------------------------------------------------------------------------
local web_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "objects" .. SEP .. "spider-web.lua"
local web_ok, spider_web = pcall(dofile, web_path)
if not web_ok then
    print("WARNING: spider-web.lua not found — tests will fail (TDD: expected)")
    spider_web = nil
end

-- Load spider creature definition
local spider_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "creatures" .. SEP .. "spider.lua"
local spider_ok, spider_def = pcall(dofile, spider_path)
if not spider_ok then
    print("WARNING: spider.lua not found — some tests will fail (TDD: expected)")
    spider_def = nil
end

---------------------------------------------------------------------------
-- Mock helpers
---------------------------------------------------------------------------
local guid_counter = 0
local function next_guid()
    guid_counter = guid_counter + 1
    return "{test-web-" .. guid_counter .. "}"
end

local function deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[k] = deep_copy(v) end
    return copy
end

local function make_spider(overrides)
    local s = {
        guid = next_guid(),
        template = "creature",
        id = "spider",
        name = "a large cellar spider",
        animate = true,
        alive = true,
        health = 8,
        max_health = 8,
        size = "tiny",
        location = nil,
        initial_state = "alive-idle",
        _state = "alive-idle",
        _last_creation = nil,
        behavior = {
            default = "idle",
            aggression = 15,
            flee_threshold = 60,
            web_builder = true,
            creates_object = {
                template = "spider-web",
                cooldown = 30,  -- 30 game-minutes
                max_per_room = 2,
                narration = "The spider spins a web in the corner.",
            },
        },
        drives = {
            hunger = { value = 50, decay_rate = 1, max = 100, min = 0 },
            fear   = { value = 0, decay_rate = -5, max = 100, min = 0 },
        },
    }
    if overrides then
        for k, v in pairs(overrides) do s[k] = v end
    end
    return s
end

local function make_web(id_suffix)
    return {
        guid = next_guid(),
        template = "small-item",
        id = "spider-web" .. (id_suffix or ""),
        name = "a sticky spider web",
        keywords = {"web", "spider web", "cobweb", "silk"},
        material = "silk",
        on_feel = "Tacky, clinging strands.",
        obstacle = {
            blocks_npc_movement = true,
            player_passable = true,
            message_blocked = "Something skitters into the web and struggles.",
            message_destroyed = "The web tears apart.",
        },
        passable = true,
    }
end

local function make_rat(overrides)
    local r = {
        guid = next_guid(),
        template = "creature",
        id = "rat",
        name = "a scrawny rat",
        animate = true,
        alive = true,
        health = 5,
        max_health = 5,
        size = "tiny",
        location = nil,
        _state = "alive-wander",
        behavior = {
            default = "idle",
            aggression = 5,
            flee_threshold = 30,
        },
        movement = {
            speed = 1,
            can_open_doors = false,
        },
    }
    if overrides then
        for k, v in pairs(overrides) do r[k] = v end
    end
    return r
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
    function reg:find_by_template(template_id)
        local found = {}
        for _, obj in pairs(self._objects) do
            if obj.id == template_id or (obj.template == template_id) then
                found[#found + 1] = obj
            end
        end
        return found
    end
    function reg:instantiate(template_id)
        local tpl = self._objects[template_id]
        if tpl then
            local inst = deep_copy(tpl)
            inst.guid = next_guid()
            self:add(inst)
            return inst
        end
        local new_obj = {
            guid = next_guid(),
            id = template_id,
            template = "small-item",
            name = template_id,
            on_feel = "A " .. template_id .. ".",
        }
        self:add(new_obj)
        return new_obj
    end
    return reg
end

local function make_context(reg, room)
    return {
        registry = reg,
        rooms = { [room.id] = room },
        current_room = room,
        player = { location = room.id },
        game_time = 100,
        print = function() end,  -- suppress output
    }
end

-- Count webs in a room's contents
local function count_webs_in_room(reg, room)
    local count = 0
    for _, ref in ipairs(room.contents or {}) do
        local obj = reg:get(ref)
        if obj and (obj.id == "spider-web" or (obj.id and obj.id:match("^spider%-web"))) then
            count = count + 1
        end
    end
    return count
end

---------------------------------------------------------------------------
-- TESTS: Spider Web Creation
---------------------------------------------------------------------------
suite("SPIDER WEB: creation (WAVE-4 TDD)")

test("1. spider creates web — creates_object behavior produces spider-web in room after cooldown", function()
    h.assert_truthy(creatures, "engine.creatures must load (TDD red phase)")
    h.assert_truthy(creatures.tick or creatures.process_create_object,
        "engine.creatures must expose tick or process_create_object")

    local spider = make_spider({ location = "cellar" })
    spider._last_creation = nil  -- no prior creation → cooldown passed
    local room = make_room("cellar", {})
    local web_tpl = make_web()
    local reg = make_mock_registry({ spider, room, web_tpl })
    local ctx = make_context(reg, room)
    ctx.game_time = 100  -- well past any cooldown

    -- Tick the creature engine — spider should create a web
    if creatures.process_create_object then
        creatures.process_create_object(spider, ctx)
    else
        creatures.tick(ctx)
    end

    -- Verify: room should now contain a spider-web
    local found_web = false
    for _, ref in ipairs(room.contents or {}) do
        local obj = reg:get(ref)
        if obj and (obj.id == "spider-web" or obj.template == "spider-web") then
            found_web = true
            break
        end
    end
    -- Also check registry for any web objects not yet in room.contents
    if not found_web then
        for _, obj in ipairs(reg:list()) do
            if obj.id == "spider-web" and obj.creator == spider.guid then
                found_web = true
                break
            end
        end
    end
    h.assert_truthy(found_web, "spider must create a spider-web in room after cooldown")
end)

---------------------------------------------------------------------------
-- TESTS: Web Obstacle Mechanic
---------------------------------------------------------------------------
suite("SPIDER WEB: obstacle mechanics (WAVE-4 TDD)")

test("2. web blocks NPC movement — creature (rat) cannot pass through web obstacle", function()
    -- Validate the spider-web obstacle spec: blocks_npc_movement = true
    -- When a rat tries to move through a room containing a web, it should be blocked.

    -- First verify the spider-web definition has the obstacle property
    if spider_web then
        h.assert_truthy(spider_web.obstacle, "spider-web must have obstacle property")
        h.assert_eq(true, spider_web.obstacle.blocks_npc_movement,
            "spider-web obstacle must block NPC movement")
    end

    -- Engine-level test: if creatures module exposes movement checking
    if creatures and creatures.is_exit_passable_for_npc then
        local web = make_web()
        local room_a = make_room("room-a", { web.guid })
        local room_b = make_room("room-b", {})
        local rat = make_rat({ location = "room-a" })

        local reg = make_mock_registry({ web, room_a, room_b, rat })
        local ctx = make_context(reg, room_a)

        local can_pass = creatures.is_exit_passable_for_npc(rat, room_a, "north", ctx)
        h.assert_eq(false, can_pass, "rat must not pass through room with web obstacle")
    elseif creatures and creatures.check_obstacle then
        local web = make_web()
        local rat = make_rat()
        local blocked = creatures.check_obstacle(rat, web)
        h.assert_eq(true, blocked, "check_obstacle must block NPC at web")
    else
        -- Validate object definition contract
        h.assert_truthy(spider_web, "spider-web.lua must load (TDD red phase)")
        h.assert_truthy(spider_web.obstacle, "spider-web must have obstacle table")
        h.assert_eq(true, spider_web.obstacle.blocks_npc_movement,
            "obstacle.blocks_npc_movement must be true — NPCs cannot pass")
    end
end)

test("3. player passes through web — player can walk through (passable)", function()
    -- Validate: web is passable for the player
    if spider_web then
        h.assert_truthy(spider_web.obstacle, "spider-web must have obstacle property")
        h.assert_eq(true, spider_web.obstacle.player_passable,
            "spider-web obstacle.player_passable must be true")
        h.assert_eq(true, spider_web.passable,
            "spider-web top-level passable must be true")
    end

    -- Engine-level test if available
    if creatures and creatures.is_exit_passable_for_player then
        local web = make_web()
        local room = make_room("webbed-room", { web.guid })
        local reg = make_mock_registry({ web, room })
        local ctx = make_context(reg, room)

        local can_pass = creatures.is_exit_passable_for_player(room, "north", ctx)
        h.assert_eq(true, can_pass, "player must be able to walk through web")
    else
        -- Definition-level validation
        h.assert_truthy(spider_web, "spider-web.lua must load (TDD red phase)")
        h.assert_eq(true, spider_web.passable,
            "spider-web passable must be true for player")
        h.assert_eq(true, spider_web.obstacle.player_passable,
            "obstacle.player_passable must be true")
    end
end)

test("4. max 2 webs per room — spider doesn't create third web when 2 exist", function()
    h.assert_truthy(creatures, "engine.creatures must load (TDD red phase)")

    local spider = make_spider({ location = "cellar" })
    spider._last_creation = 0  -- cooldown long passed
    local web1 = make_web("-1")
    local web2 = make_web("-2")
    local room = make_room("cellar", { web1.guid, web2.guid })
    local reg = make_mock_registry({ spider, web1, web2, room })
    local ctx = make_context(reg, room)
    ctx.game_time = 9999  -- well past cooldown

    local initial_web_count = count_webs_in_room(reg, room)
    h.assert_eq(2, initial_web_count, "precondition: 2 webs already in room")

    -- Tick — spider should NOT create a third web
    if creatures.process_create_object then
        creatures.process_create_object(spider, ctx)
    else
        creatures.tick(ctx)
    end

    local final_web_count = count_webs_in_room(reg, room)
    -- Also count any web objects with creator tag added to registry
    local new_webs = 0
    for _, obj in ipairs(reg:list()) do
        if obj.creator == spider.guid then new_webs = new_webs + 1 end
    end

    h.assert_eq(2, final_web_count, "room must still have exactly 2 webs (max cap)")
    h.assert_eq(0, new_webs, "spider must not create new web when at max")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
