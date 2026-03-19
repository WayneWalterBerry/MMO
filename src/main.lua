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
-- Load all object sources (indexed by id for mutation lookup)
---------------------------------------------------------------------------
local object_sources = {}
local object_dir = meta_root .. SEP .. "objects"
local object_files = list_lua_files(object_dir)
for _, fname in ipairs(object_files) do
    local path = object_dir .. SEP .. fname
    local source = read_file(path)
    if source then
        local def, err = loader.load_source(source)
        if def and def.id then
            object_sources[def.id] = source
        else
            io.stderr:write("Warning: failed to load object " .. fname .. ": " .. tostring(err or "no id") .. "\n")
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
-- Create the registry and populate the world
---------------------------------------------------------------------------
local reg = registry.new()

-- Register and resolve a single object from stored sources.
local function register_object(id)
    local source = object_sources[id]
    if not source then
        io.stderr:write("Warning: no source for object '" .. id .. "'\n")
        return nil
    end
    local obj, load_err = loader.load_source(source)
    if not obj then
        io.stderr:write("Warning: " .. tostring(load_err) .. "\n")
        return nil
    end
    obj, load_err = loader.resolve_template(obj, templates)
    if not obj then
        io.stderr:write("Warning: " .. tostring(load_err) .. "\n")
        return nil
    end
    reg:register(id, obj)
    return obj
end

-- Phase 1: register room-level objects
for _, obj_id in ipairs(room.contents) do
    local obj = register_object(obj_id)
    if obj then
        obj.location = room.id
    end
end

-- Phase 2: register objects inside surfaces of room-level objects
for _, obj_id in ipairs(room.contents) do
    local obj = reg:get(obj_id)
    if obj and obj.surfaces then
        for _, zone in pairs(obj.surfaces) do
            for _, item_id in ipairs(zone.contents or {}) do
                if not reg:get(item_id) then
                    local item = register_object(item_id)
                    if item then
                        item.location = obj_id
                    end
                end
            end
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
local context = {
    registry       = reg,
    current_room   = room,
    player         = player,
    templates      = templates,
    object_sources = object_sources,
    loader         = loader,
    mutation       = mutation,
    containment    = containment,
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
