-- main.lua
-- Entry point for the V1 bedroom REPL.
-- Wires engine modules together, loads content, starts game loop.

---------------------------------------------------------------------------
-- Path setup
---------------------------------------------------------------------------
local script_dir = arg and arg[0] and arg[0]:match("(.+)[/\\]") or "."
package.path = script_dir .. "/?.lua;"
            .. script_dir .. "/?/init.lua;"
            .. package.path

-- Parse command-line flags
local debug_mode = false
local no_ui = false
local headless = false
local start_room_override = nil
local list_rooms = false
do
    local args = arg or {}
    local i = 1
    while i <= #args do
        local a = args[i]
        if a == "--debug" then debug_mode = true
        elseif a == "--trace" then _G.TRACE = true
        elseif a == "--no-ui" then no_ui = true
        elseif a == "--headless" then headless = true; no_ui = true
        elseif a == "--list-rooms" then list_rooms = true
        elseif a == "--room" or a == "--start-room" then
            i = i + 1
            start_room_override = args[i]
        end
        i = i + 1
    end
end

---------------------------------------------------------------------------
-- Engine modules
---------------------------------------------------------------------------
local registry    = require("engine.registry")
local loader      = require("engine.loader")
local mutation    = require("engine.mutation")
local containment = require("engine.containment")
local loop        = require("engine.loop")
local verbs_mod   = require("engine.verbs")
local parser_mod  = require("engine.parser")
local display     = require("engine.display")
local ui          = require("engine.ui")
local ui_status   = require("engine.ui.status")
local presentation = require("engine.ui.presentation")

-- Install word-wrapping print before any game output
display.install()

-- Initialise the split-screen terminal UI (unless --no-ui)
local ui_active = false
if not no_ui then
    ui_active = ui.init()
    if ui_active then
        display.ui = ui   -- route print() through the UI output window
        display.WIDTH = ui.get_width()  -- sync wrap width with terminal
    end
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

local SEP = package.config:sub(1, 1)  -- "\" on Windows, "/" elsewhere

local function list_lua_files(dir)
    local files = {}
    local cmd
    if SEP == "\\" then
        cmd = 'dir /b "' .. dir .. '\\*.lua" 2>nul'
    else
        cmd = 'ls -1 "' .. dir .. '"/*.lua 2>/dev/null'
    end
    local p = io.popen(cmd)
    if p then
        for line in p:lines() do
            line = line:match("^%s*(.-)%s*$")  -- trim
            if line and line:match("%.lua$") then
                -- ls returns full paths; dir /b returns filenames only — normalize
                local fname = line:match("([^/\\]+)$") or line
                files[#files + 1] = fname
            end
        end
        p:close()
    end
    return files
end

-- normalize_guid(guid) -> string
-- Strips braces from GUIDs to handle both "{abc-123}" and "abc-123" formats.
local function normalize_guid(guid)
    if type(guid) ~= "string" then return guid end
    return guid:gsub("^%{(.-)%}$", "%1")
end

---------------------------------------------------------------------------
-- Load templates
---------------------------------------------------------------------------
local meta_root = script_dir .. SEP .. "meta"

local templates = {}
local template_dir = meta_root .. SEP .. "templates"
local template_files = list_lua_files(template_dir)
for _, fname in ipairs(template_files) do
    local path = template_dir .. SEP .. fname
    local source = read_file(path)
    if source then
        local tmpl, err = loader.load_source(source)
        if tmpl then
            templates[tmpl.id] = tmpl
        else
            io.stderr:write("Warning: failed to load template " .. fname .. ": " .. tostring(err) .. "\n")
        end
    end
end

---------------------------------------------------------------------------
-- Load all object sources and build base class index (GUID -> definition)
---------------------------------------------------------------------------
local object_sources = {}
local base_classes = {}
local object_dir = meta_root .. SEP .. "objects"
local object_files = list_lua_files(object_dir)
for _, fname in ipairs(object_files) do
    local path = object_dir .. SEP .. fname
    local source = read_file(path)
    if source then
        local def, err = loader.load_source(source)
        if def then
            -- Resolve template so base classes are fully materialized
            if def.template then
                def, err = loader.resolve_template(def, templates)
                if not def then
                    io.stderr:write("Warning: failed to resolve template for " .. fname .. ": " .. tostring(err) .. "\n")
                end
            end
            if def then
                if def.guid then
                    base_classes[normalize_guid(def.guid)] = def
                end
                if def.id then
                    object_sources[def.id] = source
                end
            end
        else
            io.stderr:write("Warning: failed to load object " .. fname .. ": " .. tostring(err) .. "\n")
        end
    end
end

local creatures_dir = meta_root .. SEP .. "creatures"
local creature_files = list_lua_files(creatures_dir)
for _, fname in ipairs(creature_files) do
    local path = creatures_dir .. SEP .. fname
    local source = read_file(path)
    if source then
        local def, err = loader.load_source(source)
        if def then
            -- Resolve template so base classes are fully materialized
            if def.template then
                def, err = loader.resolve_template(def, templates)
                if not def then
                    io.stderr:write("Warning: failed to resolve template for " .. fname .. ": " .. tostring(err) .. "\n")
                end
            end
            if def then
                if def.guid then
                    base_classes[normalize_guid(def.guid)] = def
                end
                if def.id then
                    object_sources[def.id] = source
                end
            end
        else
            io.stderr:write("Warning: failed to load creature " .. fname .. ": " .. tostring(err) .. "\n")
        end
    end
end

---------------------------------------------------------------------------
-- Load all rooms from meta/rooms/
---------------------------------------------------------------------------
local rooms = {}
local room_dir = meta_root .. SEP .. "rooms"
local room_files = list_lua_files(room_dir)
for _, fname in ipairs(room_files) do
    local path = room_dir .. SEP .. fname
    local source = read_file(path)
    if source then
        local rm, rm_err = loader.load_source(source)
        if rm then
            rm, rm_err = loader.resolve_template(rm, templates)
            if rm then
                rooms[rm.id] = rm
            else
                io.stderr:write("Warning: failed to resolve room " .. fname .. ": " .. tostring(rm_err) .. "\n")
            end
        else
            io.stderr:write("Warning: failed to load room " .. fname .. ": " .. tostring(rm_err) .. "\n")
        end
    end
end

---------------------------------------------------------------------------
-- Load level data (intro text, completion criteria, etc.)
---------------------------------------------------------------------------
local level = nil
local level_dir = meta_root .. SEP .. "levels"
local level_source = read_file(level_dir .. SEP .. "level-01.lua")
if level_source then
    local lv, lv_err = loader.load_source(level_source)
    if lv then
        level = lv
    else
        io.stderr:write("Warning: failed to load level-01: " .. tostring(lv_err) .. "\n")
    end
end

---------------------------------------------------------------------------
-- Handle --list-rooms
---------------------------------------------------------------------------
if list_rooms then
    local ids = {}
    for id in pairs(rooms) do ids[#ids + 1] = id end
    table.sort(ids)
    print("Available rooms:")
    for _, id in ipairs(ids) do
        local label = (id == "start-room") and " (default)" or ""
        print("  " .. id .. label)
    end
    os.exit(0)
end

---------------------------------------------------------------------------
-- Select starting room (supports --room override for testing)
---------------------------------------------------------------------------
local start_room_id = start_room_override or "start-room"
local room = rooms[start_room_id]
if not room then
    io.stderr:write("Error: room '" .. start_room_id .. "' not found.\n")
    io.stderr:write("Available rooms:\n")
    local ids = {}
    for id in pairs(rooms) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        io.stderr:write("  " .. id .. "\n")
    end
    os.exit(1)
end

if start_room_override then
    print("=== DEBUG: Starting in room '" .. start_room_id .. "' (not the normal start) ===")
    print("")
end

---------------------------------------------------------------------------
-- Create the registry and populate from all room instances
---------------------------------------------------------------------------
local reg = registry.new()

-- Phase 0: Flatten deep-nested instance trees into flat lists with .location
for _, rm in pairs(rooms) do
    rm.instances = loader.flatten_instances(rm.instances or {})
end

-- Phase 1: Resolve all instances across all rooms
for _, rm in pairs(rooms) do
    for _, inst in ipairs(rm.instances or {}) do
        local resolved, inst_err = loader.resolve_instance(inst, base_classes, templates)
        if resolved then
            reg:register(inst.id, resolved)
        else
            io.stderr:write("Warning: " .. tostring(inst_err) .. "\n")
        end
    end
end

-- Phase 2: Build containment trees for all rooms
for _, rm in pairs(rooms) do
    rm.contents = {}
    for _, inst in ipairs(rm.instances or {}) do
        local loc = inst.location
        local obj = reg:get(inst.id)

        if loc == "room" then
            rm.contents[#rm.contents + 1] = inst.id
            if obj then obj.location = rm.id end
        else
            local parent_id, surface_name = loc:match("^(.-)%.(.+)$")
            if parent_id and surface_name then
                local parent = reg:get(parent_id)
                if parent and parent.surfaces and parent.surfaces[surface_name] then
                    local zone = parent.surfaces[surface_name]
                    zone.contents = zone.contents or {}
                    zone.contents[#zone.contents + 1] = inst.id
                else
                    io.stderr:write("Warning: surface '" .. loc .. "' not found for instance '" .. inst.id .. "'\n")
                end
                if obj then obj.location = parent_id end
            else
                local parent = reg:get(loc)
                if parent then
                    -- If parent has an "inside" surface, route there
                    if parent.surfaces and parent.surfaces.inside then
                        local zone = parent.surfaces.inside
                        zone.contents = zone.contents or {}
                        zone.contents[#zone.contents + 1] = inst.id
                    else
                        parent.contents = parent.contents or {}
                        parent.contents[#parent.contents + 1] = inst.id
                    end
                else
                    io.stderr:write("Warning: container '" .. loc .. "' not found for instance '" .. inst.id .. "'\n")
                end
                if obj then obj.location = loc end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Player state
---------------------------------------------------------------------------
local player = {
    hands = { nil, nil },    -- two hand slots (object IDs)
    worn = {},               -- worn items (backpack, cloak -- don't use hand slots)
    skills = {},             -- learned skills (future use)
    location = start_room_id,
    max_health = 100,        -- base maximum health
    health = 100,            -- current health (combat decrements; injuries also derive from max_health)
    injuries = {},           -- active injury instances (health is derived from this)
    consciousness = {        -- consciousness state machine (conscious/unconscious/waking)
        state = "conscious",
        wake_timer = 0,
        cause = nil,
        unconscious_since = nil,
    },
    state = {
        bloody = false,
        poisoned = false,
        has_flame = 0,       -- ticks remaining for a struck match (0 = no flame)
    },
    visited_rooms = { [start_room_id] = true },  -- canonical visited-rooms tracking (#104)
    -- Body zones (WAVE-4: combat data layer)
    body_tree = {
        head  = { size = 1, vital = true,  tissue = { "skin", "flesh", "bone" } },
        torso = { size = 4, vital = true,  tissue = { "skin", "flesh", "bone", "organ" } },
        arms  = { size = 2, vital = false, tissue = { "skin", "flesh", "bone" }, on_damage = { "weapon_drop", "reduced_attack" } },
        hands = { size = 1, vital = false, tissue = { "skin", "flesh", "bone" }, on_damage = { "weapon_drop" } },
        legs  = { size = 2, vital = false, tissue = { "skin", "flesh", "bone" }, on_damage = { "reduced_movement", "prone" } },
        feet  = { size = 1, vital = false, tissue = { "skin", "flesh", "bone" }, on_damage = { "reduced_movement" } },
    },
    -- Combat metadata (WAVE-4)
    combat = {
        size = "medium",
        speed = 4,
        natural_weapons = {
            { id = "punch", type = "blunt", material = "bone", zone = "arms", force = 2, message = "punches" },
            { id = "kick", type = "blunt", material = "bone", zone = "legs", force = 3, message = "kicks" },
        },
        natural_armor = nil,
    },
}

---------------------------------------------------------------------------
-- Build the game context
---------------------------------------------------------------------------
local assets_root = script_dir .. SEP .. "assets"
local parser_instance = parser_mod.init(assets_root, debug_mode)
if debug_mode then
    parser_instance.diagnostic = true
end

local context = {
    registry       = reg,
    current_room   = room,
    rooms          = rooms,
    player         = player,
    templates      = templates,
    base_classes   = base_classes,
    object_sources = object_sources,
    loader         = loader,
    mutation       = mutation,
    containment    = containment,
    parser         = parser_instance,
    game_start_time = os.time(),
    game_start_hour = presentation.GAME_START_HOUR,
    ui             = ui_active and ui or nil,
    headless       = headless,
    debug          = debug_mode,
}

---------------------------------------------------------------------------
-- Initialize timed events for all objects in the starting room
---------------------------------------------------------------------------
local fsm_init_ok, fsm_init = pcall(require, "engine.fsm")
if fsm_init_ok and fsm_init then
    fsm_init.scan_room_timers(reg, room)
end

---------------------------------------------------------------------------
-- Post-command tick: match flame, candle burn
---------------------------------------------------------------------------
context.on_tick = function(ctx)
    local p = ctx.player

    -- Blood tick-down: wound stops bleeding after N turns
    if p.state.bloody and p.state.bleed_ticks then
        p.state.bleed_ticks = p.state.bleed_ticks - 1
        if p.state.bleed_ticks <= 0 then
            p.state.bloody = false
            p.state.bleed_ticks = nil
            print("")
            print("The bleeding has stopped. The blood on your hands is drying.")
        elseif p.state.bleed_ticks == 2 then
            print("")
            print("Your wound is still bleeding, but it's slowing.")
        end
    end

    -- Match flame countdown (legacy -- FSM objects handle their own tick)
    if p.state.has_flame and p.state.has_flame > 0 then
        p.state.has_flame = p.state.has_flame - 1
        if p.state.has_flame <= 0 then
            p.state.has_flame = 0
            print("")
            print("The match sputters and dies.")
        end
    end

    -- Candle burn tick (candle is not yet FSM-managed)
    local room = ctx.current_room
    local reg = ctx.registry

    local function tick_burnable(obj, obj_id, remove_fn)
        -- Skip FSM-managed objects (they handle their own tick)
        if obj and obj.states then return false end
        if obj and obj.casts_light and obj.burn_remaining then
            obj.burn_remaining = obj.burn_remaining - 1
            if obj.burn_remaining <= 0 then
                print("")
                print("The candle gutters and goes out, plunging the room into darkness.")
                remove_fn()
                reg:remove(obj_id)
                return true
            elseif obj.burn_remaining == 5 then
                print("")
                print("The candle flame flickers dangerously low. It won't last much longer.")
            end
        end
        return false
    end

    -- Room contents
    for i = #(room.contents or {}), 1, -1 do
        local obj_id = room.contents[i]
        local obj = reg:get(obj_id)
        tick_burnable(obj, obj_id, function()
            table.remove(room.contents, i)
        end)
    end

    -- Surface contents of room objects
    for _, parent_id in ipairs(room.contents or {}) do
        local parent = reg:get(parent_id)
        if parent and parent.surfaces then
            for _, zone in pairs(parent.surfaces) do
                for i = #(zone.contents or {}), 1, -1 do
                    local item_id = zone.contents[i]
                    local item = reg:get(item_id)
                    tick_burnable(item, item_id, function()
                        table.remove(zone.contents, i)
                    end)
                end
            end
        end
    end

    -- Player hands
    for i = 1, 2 do
        local hand = p.hands[i]
        if hand then
            local hand_id = type(hand) == "table" and hand.id or hand
            local obj = type(hand) == "table" and hand or reg:get(hand)
            tick_burnable(obj, hand_id, function()
                p.hands[i] = nil
            end)
        end
    end
end

---------------------------------------------------------------------------
-- Wire verb handlers
---------------------------------------------------------------------------
context.verbs = verbs_mod.create()

---------------------------------------------------------------------------
-- Status bar updater (Smithers owns — see engine/ui/status.lua)
---------------------------------------------------------------------------
context.update_status = ui_status.create_updater()

---------------------------------------------------------------------------
-- Welcome (reads intro text from level data)
---------------------------------------------------------------------------
local intro = level and level.intro
if not headless then
    local title = (intro and intro.title) or "THE BEDROOM \xe2\x80\x94 A Text Adventure"
    local subtitle = (intro and intro.subtitle) or "V1 Playtest"
    print("================================================================")
    print("  " .. title)
    print("  " .. subtitle)
    print("================================================================")
    print("")
end
if intro and intro.narrative then
    for _, line in ipairs(intro.narrative) do
        print(line)
    end
else
    print("You wake with a start. The darkness is absolute.")
    print("You can feel rough linen beneath your fingers.")
end
print("")
if not headless then
    local help = (intro and intro.help) or "Type 'help' for commands. Try 'feel' to explore the darkness."
    print(help)
    print("")
end
if headless then
    io.write("---END---\n")
    io.flush()
end

---------------------------------------------------------------------------
-- Run (with cleanup on exit)
---------------------------------------------------------------------------
local ok, err = pcall(loop.run, context)

-- Restore terminal before printing any error
if ui_active then
    display.ui = nil
    ui.cleanup()
end

if not ok then
    io.stderr:write("Fatal: " .. tostring(err) .. "\n")
    os.exit(1)
end
