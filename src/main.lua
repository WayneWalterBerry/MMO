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
                files[#files + 1] = line
            end
        end
        p:close()
    end
    return files
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
                    base_classes[def.guid] = def
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

---------------------------------------------------------------------------
-- Load the start room
---------------------------------------------------------------------------
local room_path = meta_root .. SEP .. "world" .. SEP .. "start-room.lua"
local room_source = read_file(room_path)
if not room_source then
    io.stderr:write("Fatal: cannot read " .. room_path .. "\n")
    os.exit(1)
end

local room, err = loader.load_source(room_source)
if not room then
    io.stderr:write("Fatal: " .. tostring(err) .. "\n")
    os.exit(1)
end
room, err = loader.resolve_template(room, templates)
if not room then
    io.stderr:write("Fatal: " .. tostring(err) .. "\n")
    os.exit(1)
end

---------------------------------------------------------------------------
-- Create the registry and populate from room instances
---------------------------------------------------------------------------
local reg = registry.new()

-- Phase 1: Resolve all instances against their base classes and register
for _, inst in ipairs(room.instances or {}) do
    local resolved, inst_err = loader.resolve_instance(inst, base_classes, templates)
    if resolved then
        reg:register(inst.id, resolved)
    else
        io.stderr:write("Warning: " .. tostring(inst_err) .. "\n")
    end
end

-- Phase 2: Build containment tree from instance locations
room.contents = {}
for _, inst in ipairs(room.instances or {}) do
    local loc = inst.location
    local obj = reg:get(inst.id)

    if loc == "room" then
        -- Top-level room object
        room.contents[#room.contents + 1] = inst.id
        if obj then obj.location = room.id end
    else
        local parent_id, surface_name = loc:match("^(.-)%.(.+)$")
        if parent_id and surface_name then
            -- Surface location: "parent.surface"
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
            -- Container location: just a parent id (e.g., "matchbox", "sack")
            local parent = reg:get(loc)
            if parent then
                parent.contents = parent.contents or {}
                parent.contents[#parent.contents + 1] = inst.id
            else
                io.stderr:write("Warning: container '" .. loc .. "' not found for instance '" .. inst.id .. "'\n")
            end
            if obj then obj.location = loc end
        end
    end
end

---------------------------------------------------------------------------
-- Player state
---------------------------------------------------------------------------
local player = {
    hands = { nil, nil },    -- two hand slots (object IDs)
    worn = {},               -- worn items (backpack, cloak — don't use hand slots)
    skills = {},             -- learned skills (future use)
    location = "start-room",
    state = {
        bloody = false,
        poisoned = false,
        has_flame = 0,       -- ticks remaining for a struck match (0 = no flame)
    },
}

---------------------------------------------------------------------------
-- Build the game context
---------------------------------------------------------------------------
local assets_root = script_dir .. SEP .. "assets"
local parser_instance = parser_mod.init(assets_root)

local context = {
    registry       = reg,
    current_room   = room,
    player         = player,
    templates      = templates,
    base_classes   = base_classes,
    object_sources = object_sources,
    loader         = loader,
    mutation       = mutation,
    containment    = containment,
    parser         = parser_instance,
    game_start_time = os.time(),
    game_start_hour = 2,
}

---------------------------------------------------------------------------
-- Post-command tick: match flame, candle burn
---------------------------------------------------------------------------
context.on_tick = function(ctx)
    local p = ctx.player

    -- Match flame countdown
    if p.state.has_flame and p.state.has_flame > 0 then
        p.state.has_flame = p.state.has_flame - 1
        if p.state.has_flame <= 0 then
            p.state.has_flame = 0
            print("")
            print("The match sputters and dies.")
        end
    end

    -- Candle burn tick — check room, surfaces, and player hands
    local room = ctx.current_room
    local reg = ctx.registry

    local function tick_burnable(obj, obj_id, remove_fn)
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
        local hand_id = p.hands[i]
        if hand_id then
            local obj = reg:get(hand_id)
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
-- Welcome
---------------------------------------------------------------------------
print("================================================================")
print("  THE BEDROOM — A Text Adventure")
print("  V1 Playtest")
print("================================================================")
print("")
print("You wake with a start. The darkness is absolute.")
print("You can feel rough linen beneath your fingers.")
print("")
print("Type 'help' for commands. Try 'feel' to explore the darkness.")
print("")

---------------------------------------------------------------------------
-- Run
---------------------------------------------------------------------------
loop.run(context)
