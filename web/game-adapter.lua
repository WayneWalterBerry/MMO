-- game-adapter.lua
-- Fengari adapter: runs the MMO text adventure in the browser.
--
-- Architecture:
--   1. Builds a virtual file system from game-bundle.js (all Lua/JSON sources)
--   2. Overrides io.open/io.popen/io.read for browser environment
--   3. Installs a custom package.searcher so require() finds engine modules
--   4. Loads game data (templates, objects, rooms) exactly like main.lua
--   5. Wraps the game loop in a coroutine — io.read() yields, JS resumes
--
-- The coroutine trick means we reuse the EXISTING game loop code unchanged.
-- When the loop calls io.read(), the coroutine suspends. When the player
-- types a command, JavaScript resumes the coroutine with their input.

---------------------------------------------------------------------------
-- JavaScript bridge
---------------------------------------------------------------------------
local js = require "js"
local window = js.global
local document = window.document

local output_el  = document:getElementById("output")
local input_el   = document:getElementById("input")
local loading_el = document:getElementById("loading")

---------------------------------------------------------------------------
-- DOM output helpers
---------------------------------------------------------------------------
local function append_output(text)
    window:_appendOutput(text, nil)
end

local function append_error(text)
    window:_appendOutput(text, "error-line")
end

---------------------------------------------------------------------------
-- Virtual File System (backed by game-bundle.js)
---------------------------------------------------------------------------
local function vfs_get(path)
    if not window.GAME_FILES then return nil end
    local val = window.GAME_FILES[path]
    if val == nil or val == js.null then return nil end
    return tostring(val)
end

local function vfs_list(dir_prefix)
    local files = {}
    if not window.GAME_FILE_KEYS then return files end
    local keys = window.GAME_FILE_KEYS
    for i = 0, keys.length - 1 do
        local key = tostring(keys[i])
        if key:sub(1, #dir_prefix) == dir_prefix then
            local rest = key:sub(#dir_prefix + 1)
            -- Only direct children (no further slashes)
            if not rest:find("/") and #rest > 0 then
                files[#files + 1] = rest
            end
        end
    end
    return files
end

---------------------------------------------------------------------------
-- Override standard library for browser environment
---------------------------------------------------------------------------

-- print → DOM output
local original_print = print
_G.print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(select(i, ...))
    end
    local text = table.concat(parts, "\t")
    append_output(text)
end

-- io.open → VFS reader
io.open = function(path, mode)
    if mode and (mode:find("w") or mode:find("a")) then
        return nil, "write not supported in browser"
    end
    path = path:gsub("\\", "/"):gsub("^%./", "")
    local content = vfs_get(path) or vfs_get("src/" .. path)
    if not content then
        return nil, "file not found: " .. path
    end
    local pos = 1
    local closed = false
    return {
        read = function(self, fmt)
            if closed or pos > #content then return nil end
            if fmt == "*a" or fmt == "*all" then
                local result = content:sub(pos)
                pos = #content + 1
                return result
            end
            -- Default: read one line
            local nl = content:find("\n", pos)
            if nl then
                local line = content:sub(pos, nl - 1)
                pos = nl + 1
                return line
            else
                local line = content:sub(pos)
                pos = #content + 1
                return line
            end
        end,
        close = function(self)
            closed = true
            return true
        end,
        lines = function(self)
            return function()
                if closed or pos > #content then return nil end
                return self:read("*l")
            end
        end,
    }
end

-- io.popen → parse dir/ls commands against VFS
io.popen = function(cmd)
    local dir = cmd:match('dir /b "(.+)\\%*%.lua"')
              or cmd:match('ls %-1 "(.+)"/%*%.lua')
    if dir then
        dir = dir:gsub("\\", "/"):gsub("^%./", "")
        local prefix = dir .. "/"
        if not prefix:match("^src/") then
            prefix = "src/" .. prefix
        end
        local files = vfs_list(prefix)
        local content = table.concat(files, "\n")
        if #content == 0 then content = "" end
        local pos = 1
        return {
            lines = function(self)
                return function()
                    if pos > #content then return nil end
                    local nl = content:find("\n", pos)
                    if nl then
                        local line = content:sub(pos, nl - 1)
                        pos = nl + 1
                        return line
                    else
                        local line = content:sub(pos)
                        pos = #content + 1
                        return line
                    end
                end
            end,
            close = function() return true end,
        }
    end
    return nil, "io.popen not available in browser"
end

-- io.read → coroutine yield (event-driven input)
io.read = function()
    return coroutine.yield("need_input")
end

-- Suppress prompt writes (browser has its own prompt)
io.write = function() end
io.flush = function() end

-- io.stderr → browser console
io.stderr = {
    write = function(self, ...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        window.console:warn(table.concat(parts))
    end
}

-- os.exit → no-op (can't exit a browser tab)
os.exit = function(code)
    if code and code ~= 0 then
        append_error("[Game exited with code " .. tostring(code) .. "]")
    end
end

---------------------------------------------------------------------------
-- Package searcher: resolve require() against VFS
---------------------------------------------------------------------------
table.insert(package.searchers, 2, function(modname)
    local path = modname:gsub("%.", "/")
    local src = vfs_get("src/" .. path .. ".lua")
              or vfs_get("src/" .. path .. "/init.lua")
    if src then
        local fn, err = load(src, "@" .. modname)
        if fn then return fn end
        return "\n\tVFS load error: " .. tostring(err)
    end
    return "\n\tno VFS file 'src/" .. path .. ".lua'"
end)

-- Stub the terminal UI module (the browser IS our UI)
package.loaded["engine.ui"] = {
    init       = function() return false end,
    is_enabled = function() return false end,
    output     = function(text) append_output(text) end,
    input      = function() return coroutine.yield("need_input") end,
    cleanup    = function() end,
    status     = function() end,
    handle_scroll = function() return false end,
    get_width  = function() return 78 end,
}

---------------------------------------------------------------------------
-- Boot the game
---------------------------------------------------------------------------
local game_co  -- the coroutine running the game loop

local ok, err = pcall(function()
    -- Engine modules (loaded via VFS searcher)
    local registry     = require("engine.registry")
    local loader       = require("engine.loader")
    local mutation     = require("engine.mutation")
    local containment  = require("engine.containment")
    local verbs_mod    = require("engine.verbs")
    local parser_mod   = require("engine.parser")
    local display      = require("engine.display")
    local ui_status    = require("engine.ui.status")
    local presentation = require("engine.ui.presentation")
    local loop         = require("engine.loop")

    -- Install word-wrapping (wraps our DOM print — adds line-break logic)
    display.install()

    -------------------------------------------------------------------
    -- Load game data (mirrors main.lua initialization)
    -------------------------------------------------------------------
    local meta_root = "src/meta"

    local function read_file(path)
        local f = io.open(path, "r")
        if not f then return nil end
        local content = f:read("*a")
        f:close()
        return content
    end

    local function list_lua_files(dir)
        dir = dir:gsub("\\", "/")
        if not dir:match("/$") then dir = dir .. "/" end
        if not dir:match("^src/") then dir = "src/" .. dir end
        return vfs_list(dir)
    end

    -- Templates
    local templates = {}
    local template_dir = meta_root .. "/templates"
    for _, fname in ipairs(list_lua_files(template_dir)) do
        local source = read_file(template_dir .. "/" .. fname)
        if source then
            local tmpl, tmpl_err = loader.load_source(source)
            if tmpl then templates[tmpl.id] = tmpl end
        end
    end

    -- Objects (base classes)
    local object_sources = {}
    local base_classes = {}
    local object_dir = meta_root .. "/objects"
    for _, fname in ipairs(list_lua_files(object_dir)) do
        local source = read_file(object_dir .. "/" .. fname)
        if source then
            local def, def_err = loader.load_source(source)
            if def then
                if def.template then
                    def, def_err = loader.resolve_template(def, templates)
                end
                if def then
                    if def.guid then base_classes[def.guid] = def end
                    if def.id then object_sources[def.id] = source end
                end
            end
        end
    end

    -- Rooms
    local rooms = {}
    local room_dir = meta_root .. "/world"
    for _, fname in ipairs(list_lua_files(room_dir)) do
        local source = read_file(room_dir .. "/" .. fname)
        if source then
            local rm, rm_err = loader.load_source(source)
            if rm then
                rm, rm_err = loader.resolve_template(rm, templates)
                if rm then rooms[rm.id] = rm end
            end
        end
    end

    -- Starting room
    local start_room_id = "start-room"
    local room = rooms[start_room_id]
    if not room then
        error("Starting room '" .. start_room_id .. "' not found")
    end

    -- Registry
    local reg = registry.new()

    -- Phase 1: resolve all instances across all rooms
    for _, rm in pairs(rooms) do
        for _, inst in ipairs(rm.instances or {}) do
            local resolved, inst_err = loader.resolve_instance(inst, base_classes, templates)
            if resolved then
                reg:register(inst.id, resolved)
            end
        end
    end

    -- Phase 2: build containment trees
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
                    end
                    if obj then obj.location = parent_id end
                else
                    local parent = reg:get(loc)
                    if parent then
                        parent.contents = parent.contents or {}
                        parent.contents[#parent.contents + 1] = inst.id
                    end
                    if obj then obj.location = loc end
                end
            end
        end
    end

    -- Player state
    local player = {
        hands    = { nil, nil },
        worn     = {},
        skills   = {},
        location = start_room_id,
        state    = { bloody = false, poisoned = false, has_flame = 0 },
    }

    -- Parser
    local parser_instance = parser_mod.init("src/assets", false)

    -- Game context
    local context = {
        registry        = reg,
        current_room    = room,
        rooms           = rooms,
        player          = player,
        templates       = templates,
        base_classes    = base_classes,
        object_sources  = object_sources,
        loader          = loader,
        mutation        = mutation,
        containment     = containment,
        parser          = parser_instance,
        game_start_time = os.time(),
        game_start_hour = presentation.GAME_START_HOUR,
        ui              = nil,
    }

    -- FSM timer init
    local fsm_ok, fsm_mod = pcall(require, "engine.fsm")
    if fsm_ok and fsm_mod then
        fsm_mod.scan_room_timers(reg, room)
    end

    -- Post-command tick (flame, candle, bleed — from main.lua)
    context.on_tick = function(ctx)
        local p = ctx.player
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
        if p.state.has_flame and p.state.has_flame > 0 then
            p.state.has_flame = p.state.has_flame - 1
            if p.state.has_flame <= 0 then
                p.state.has_flame = 0
                print("")
                print("The match sputters and dies.")
            end
        end
        local rm = ctx.current_room
        local r = ctx.registry
        local function tick_burnable(obj, obj_id, remove_fn)
            if obj and obj.states then return false end
            if obj and obj.casts_light and obj.burn_remaining then
                obj.burn_remaining = obj.burn_remaining - 1
                if obj.burn_remaining <= 0 then
                    print("")
                    print("The candle gutters and goes out, plunging the room into darkness.")
                    remove_fn()
                    r:remove(obj_id)
                    return true
                elseif obj.burn_remaining == 5 then
                    print("")
                    print("The candle flame flickers dangerously low. It won't last much longer.")
                end
            end
            return false
        end
        for i = #(rm.contents or {}), 1, -1 do
            tick_burnable(r:get(rm.contents[i]), rm.contents[i], function()
                table.remove(rm.contents, i)
            end)
        end
        for _, parent_id in ipairs(rm.contents or {}) do
            local parent = r:get(parent_id)
            if parent and parent.surfaces then
                for _, zone in pairs(parent.surfaces) do
                    for i = #(zone.contents or {}), 1, -1 do
                        tick_burnable(r:get(zone.contents[i]), zone.contents[i], function()
                            table.remove(zone.contents, i)
                        end)
                    end
                end
            end
        end
        for i = 1, 2 do
            local hid = p.hands[i]
            if hid then
                tick_burnable(r:get(hid), hid, function() p.hands[i] = nil end)
            end
        end
    end

    -- Wire verb handlers
    context.verbs = verbs_mod.create()
    context.update_status = function() end  -- no status bar in browser

    -------------------------------------------------------------------
    -- Welcome
    -------------------------------------------------------------------
    print("================================================================")
    print("  THE BEDROOM \xe2\x80\x94 A Text Adventure")
    print("  V1 Web Playtest")
    print("================================================================")
    print("")
    print("You wake with a start. The darkness is absolute.")
    print("You can feel rough linen beneath your fingers.")
    print("")
    print("Type 'help' for commands. Try 'feel' to explore the darkness.")
    print("")

    -------------------------------------------------------------------
    -- Start game loop in a coroutine
    -------------------------------------------------------------------
    game_co = coroutine.create(function()
        loop.run(context)
    end)

    -- First resume: runs until the loop hits io.read() and yields
    local co_ok, co_err = coroutine.resume(game_co)
    if not co_ok then
        append_error("Loop error: " .. tostring(co_err))
    end

    -------------------------------------------------------------------
    -- Expose command handler to JavaScript
    -------------------------------------------------------------------
    -- Fengari calling convention: when JS calls window.func(arg),
    -- Lua may receive (self, arg) or (arg). We handle both.
    window._gameProcessCommand = function(a, b)
        local text
        if b ~= nil then
            text = tostring(b)
        else
            text = tostring(a)
        end
        if not game_co then
            append_error("Game not initialized")
            return
        end
        if coroutine.status(game_co) == "dead" then
            append_output("")
            append_output("Game has ended. Refresh the page to play again.")
            return
        end
        if coroutine.status(game_co) == "suspended" then
            local co_ok, co_err = coroutine.resume(game_co, text)
            if not co_ok then
                append_error("Error: " .. tostring(co_err))
            end
        end
    end

    -- Enable input
    loading_el.className = "hidden"
    input_el.disabled = false
    input_el:focus()
    window._gameReady = true
end)

if not ok then
    append_error("Failed to load game: " .. tostring(err))
    window.console:error(tostring(err))
    loading_el.textContent = "Failed to load game engine."
    loading_el.className = "error-line"
end
