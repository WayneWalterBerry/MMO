-- game-adapter.lua
-- Three-layer web adapter: engine from compressed bundle, meta via JIT HTTP.
--
-- Architecture (see docs/architecture/web/jit-loader.md):
--   1. Engine modules loaded via package.preload (from engine.lua.gz bundle)
--   2. Asset files accessed via _G.__VFS (embedded in engine bundle)
--   3. Meta files (rooms, objects, templates, levels) fetched on demand via XHR
--   4. Coroutine-based game loop — io.read() yields, JS resumes with player input
--
-- JIT loading: rooms and their objects are fetched the first time the player
-- enters them. A metatable on the rooms table triggers transparent loading.

---------------------------------------------------------------------------
-- JavaScript bridge
---------------------------------------------------------------------------
local js = require "js"
local window = js.global
local document = window.document

local output_el  = document:getElementById("output")
local input_el   = document:getElementById("input")

---------------------------------------------------------------------------
-- Debug mode flag (mirrors JS window._debugMode, set by ?debug URL param)
---------------------------------------------------------------------------
local DEBUG_MODE = not not window._debugMode  -- coerce JS truthy to Lua boolean
_G.DEBUG_MODE = DEBUG_MODE

---------------------------------------------------------------------------
-- DOM output helpers
---------------------------------------------------------------------------
local function append_output(text)
    window:_appendOutput(text, nil)
end

local function append_error(text)
    window:_appendOutput(text, "error-line")
end

local function log_status(msg)
    window:_logStatus(msg)
end

local function log_debug(msg)
    if DEBUG_MODE then window:_logStatus(msg) end
end

-- Build version (embedded at build time)
local BUILD_TIMESTAMP = "2026-03-22 06:00"

local function format_size(bytes)
    if bytes >= 1048576 then
        return string.format("%.1f MB", bytes / 1048576)
    end
    return string.format("%.1f KB", bytes / 1024)
end

---------------------------------------------------------------------------
-- HTTP cache — stores content + ETag + Last-Modified per URL
---------------------------------------------------------------------------
local http_cache = {}  -- { [url] = { content, etag, last_modified } }

---------------------------------------------------------------------------
-- Cache-aware HTTP fetch via JS bridge (synchronous XHR)
-- First fetch: GET, store content + headers.
-- Subsequent: send If-None-Match / If-Modified-Since.
-- 304 → use cached content (zero bandwidth).
-- 200 → update cache with new content + headers.
-- Returns: (content, was_cached, err)
---------------------------------------------------------------------------
local function fetch_text(url)
    local entry = http_cache[url]
    local etag = entry and entry.etag or nil
    local last_modified = entry and entry.last_modified or nil

    local ok_fetch, content_or_err, was_cached = pcall(function()
        local resp = window:_cachedFetch(url, etag, last_modified)
        local status = tonumber(tostring(resp.status)) or 0
        if status == 304 and entry then
            return entry.content, true
        elseif status == 200 then
            local content = tostring(resp.content)
            local new_etag = resp.etag and tostring(resp.etag) or nil
            local new_lm   = resp.lastModified and tostring(resp.lastModified) or nil
            http_cache[url] = {
                content       = content,
                etag          = new_etag,
                last_modified = new_lm,
            }
            return content, false
        end
        return nil, false
    end)

    if not ok_fetch then
        return nil, false, "fetch error: " .. tostring(content_or_err)
    end
    return content_or_err, was_cached
end

---------------------------------------------------------------------------
-- Cache management API (web_loader.invalidate / web_loader.clear)
---------------------------------------------------------------------------
local function cache_invalidate(url)
    http_cache[url] = nil
end

local function cache_clear()
    http_cache = {}
end

---------------------------------------------------------------------------
-- VFS for embedded assets (from engine bundle's _G.__VFS table)
---------------------------------------------------------------------------
local function vfs_get(path)
    if _G.__VFS then
        local val = _G.__VFS[path]
        if val then return val end
    end
    return nil
end

---------------------------------------------------------------------------
-- Ensure io / os tables exist (Fengari does NOT provide them)
---------------------------------------------------------------------------
io = io or {}
os = os or {}

os.time = os.time or function()
    return math.floor(window.Date:now() / 1000)
end

os.clock = os.clock or function()
    return window.performance:now() / 1000
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

-- io.open → VFS reader (for engine assets like embedding-index.json)
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

-- io.popen → stub (meta files are JIT-loaded, not listed)
io.popen = function(cmd)
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
-- Package searcher: resolve require() against VFS (for asset files)
-- Engine modules already resolve via package.preload (set by engine bundle)
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
-- Boot the game (three-layer architecture)
---------------------------------------------------------------------------
local game_co  -- the coroutine running the game loop

local ok, err = pcall(function()
    -- Engine modules (resolved from package.preload via engine bundle)
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
    -- Shared state
    -------------------------------------------------------------------
    local reg = registry.new()
    local templates = {}
    local base_classes = {}
    local object_sources = {}
    local rooms = {}

    -------------------------------------------------------------------
    -- GUID normalization helper
    -------------------------------------------------------------------
    local function normalize_guid(guid)
        if type(guid) ~= "string" then return guid end
        return guid:gsub("^%{(.-)%}$", "%1")
    end

    -------------------------------------------------------------------
    -- Load templates (all 5, fetched at boot — small and required early)
    -------------------------------------------------------------------
    log_debug("Loading Templates...")
    local TEMPLATE_FILES = {
        "small-item.lua", "room.lua", "container.lua",
        "furniture.lua", "sheet.lua",
    }
    for _, fname in ipairs(TEMPLATE_FILES) do
        local source = fetch_text("meta/templates/" .. fname)
        if source then
            local tmpl, tmpl_err = loader.load_source(source)
            if tmpl then
                templates[tmpl.id] = tmpl
            end
        end
    end

    -------------------------------------------------------------------
    -- JIT loader: fetch and load a single object by GUID
    -- Returns (def, was_cached)
    -------------------------------------------------------------------
    local function load_object(guid)
        local normalized_guid = normalize_guid(guid)
        if base_classes[normalized_guid] then return base_classes[normalized_guid], true, 0 end
        local source, was_cached = fetch_text("meta/objects/" .. normalized_guid .. ".lua")
        if not source then return nil, false, 0 end
        local content_len = #source
        local def = loader.load_source(source)
        if not def then return nil, false, 0 end
        if def.template then
            def = loader.resolve_template(def, templates)
        end
        if def and def.guid then
            base_classes[normalize_guid(def.guid)] = def
            if def.id then object_sources[def.id] = source end
        end
        return def, was_cached, content_len
    end

    -------------------------------------------------------------------
    -- JIT loader: fetch and fully load a room + all its objects
    -------------------------------------------------------------------
    local function load_room(room_id)
        if rawget(rooms, room_id) then return rawget(rooms, room_id) end

        -- Friendly name for status message
        local name_hint = room_id:gsub("^start%-room$", "Bedroom")
        if name_hint == room_id then
            name_hint = room_id:gsub("%-", " "):gsub("(%a)([%w_']*)",
                function(a, b) return a:upper() .. b end)
        end

        local source, was_cached = fetch_text("meta/rooms/" .. room_id .. ".lua")
        if was_cached then
            log_debug("Loading Room: " .. name_hint .. "... (cached)")
        elseif source then
            log_debug("Loading Room: " .. name_hint .. "... (" .. format_size(#source) .. ")")
        else
            log_debug("Loading Room: " .. name_hint .. "...")
        end
        if not source then return nil end

        local rm = loader.load_source(source)
        if not rm then return nil end
        rm = loader.resolve_template(rm, templates)
        if not rm then return nil end

        -- Fetch all objects referenced by instances
        for _, inst in ipairs(rm.instances or {}) do
            if inst.type_id and not base_classes[normalize_guid(inst.type_id)] then
                local obj_def, obj_cached, obj_size = load_object(inst.type_id)
                local obj_label = inst.type or inst.id
                if obj_cached then
                    log_debug("Loading Object: " .. obj_label .. "... (cached)")
                elseif obj_size and obj_size > 0 then
                    log_debug("Loading Object: " .. obj_label .. "... (" .. format_size(obj_size) .. ")")
                else
                    log_debug("Loading Object: " .. obj_label .. "...")
                end
            end
        end

        -- Resolve instances and register
        for _, inst in ipairs(rm.instances or {}) do
            local resolved, inst_err = loader.resolve_instance(inst, base_classes, templates)
            if resolved then
                reg:register(inst.id, resolved)
            end
        end

        -- Wire containment for this room
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

        -- Initialize timed events for this room
        local fsm_ok2, fsm_mod = pcall(require, "engine.fsm")
        if fsm_ok2 and fsm_mod then
            fsm_mod.scan_room_timers(reg, rm)
        end

        rawset(rooms, room_id, rm)
        return rm
    end

    -- Metatable: transparent JIT loading when engine accesses rooms[id]
    setmetatable(rooms, {
        __index = function(t, room_id)
            return load_room(room_id)
        end
    })

    -------------------------------------------------------------------
    -- web_loader cache API (per architecture spec)
    -------------------------------------------------------------------
    local web_loader_api = {}

    -- Fetch with conditional headers, returns content
    function web_loader_api.fetch(meta_type, id)
        local url_map = {
            objects   = "meta/objects/"   .. id .. ".lua",
            rooms     = "meta/rooms/"     .. id .. ".lua",
            levels    = "meta/levels/"    .. id .. ".lua",
            templates = "meta/templates/" .. id .. ".lua",
        }
        local url = url_map[meta_type]
        if not url then return nil, false, "unknown type: " .. tostring(meta_type) end
        return fetch_text(url)
    end

    -- Force re-fetch on next access (clears stored headers)
    function web_loader_api.invalidate(meta_type, id)
        local url_map = {
            objects   = "meta/objects/"   .. id .. ".lua",
            rooms     = "meta/rooms/"     .. id .. ".lua",
            levels    = "meta/levels/"    .. id .. ".lua",
            templates = "meta/templates/" .. id .. ".lua",
        }
        local url = url_map[meta_type]
        if url then cache_invalidate(url) end
        -- Also clear parsed data so next access re-fetches
        if meta_type == "rooms" then rawset(rooms, id, nil) end
        if meta_type == "objects" then base_classes[id] = nil end
    end

    -- Clear all cached data
    function web_loader_api.clear()
        cache_clear()
        -- Clear parsed caches too
        for k in pairs(base_classes) do base_classes[k] = nil end
        for k in pairs(object_sources) do object_sources[k] = nil end
        for k in pairs(rooms) do rawset(rooms, k, nil) end
    end

    -------------------------------------------------------------------
    -- Load level and starting room
    -------------------------------------------------------------------
    log_debug("Loading Level 1...")
    local level_source = fetch_text("meta/levels/level-01.lua")
    local level = level_source and loader.load_source(level_source)

    local start_room_id = (level and level.start_room) or "start-room"
    local room = rooms[start_room_id]  -- triggers JIT load of starting room
    if not room then
        error("Starting room '" .. start_room_id .. "' not found")
    end

    -------------------------------------------------------------------
    -- Player state
    -------------------------------------------------------------------
    local player = {
        hands    = { nil, nil },
        worn     = {},
        skills   = {},
        location = start_room_id,
        state    = { bloody = false, poisoned = false, has_flame = 0 },
    }

    -------------------------------------------------------------------
    -- Parser
    -------------------------------------------------------------------
    local parser_instance = parser_mod.init("src/assets", false)

    -------------------------------------------------------------------
    -- Game context
    -------------------------------------------------------------------
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
        visited_rooms   = { [start_room_id] = true },
        -- JS bridge: open URL in a new browser tab (for "report bug")
        open_url        = function(url)
            window:_openUrl(url)
        end,
    }

    -------------------------------------------------------------------
    -- Post-command tick (flame, candle, bleed — from main.lua)
    -------------------------------------------------------------------
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
    log_debug("Starting Game...")
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
    log_status("Ready.")
    input_el.disabled = false
    input_el:focus()
    window._gameReady = true
end)

if not ok then
    append_error("Failed to load game: " .. tostring(err))
    window.console:error(tostring(err))
end
