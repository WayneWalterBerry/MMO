-- engine/sound/init.lua
-- Platform-agnostic sound manager. Provides play/stop/volume/mute with
-- injected platform drivers (Web Audio, terminal, null). No-op when no
-- driver is present — sound is opt-in (Principle 8).
--
-- Public API frozen at GATE-0 (v1.1):
--   new(), init(), shutdown(), scan_object(), flush_queue(),
--   play(), stop(), stop_by_owner(), enter_room(), exit_room(),
--   unload_room(), trigger(), set_volume(), set_enabled(),
--   mute(), unmute(), set_driver()

local defaults = require("engine.sound.defaults")

local M = {}
M.__index = M

-- Concurrency caps
local MAX_ONESHOTS = 4
local MAX_AMBIENTS = 3

----------------------------------------------------------------------------
-- Construction
----------------------------------------------------------------------------

--- Create a new sound manager instance.
-- @return SoundManager
function M.new()
    local self = setmetatable({}, M)
    self._driver = nil
    self._volume = 1.0       -- master volume 0.0–1.0
    self._enabled = true      -- global enable flag
    self._muted = false       -- mute toggle (preserves volume)
    self._queue = {}          -- filenames pending load
    self._loaded = {}         -- filename → driver handle
    self._playing = {}        -- play_id → { filename, handle, loop, owner_id }
    self._oneshots = {}       -- ordered list of active one-shot play_ids
    self._ambients = {}       -- ordered list of active ambient play_ids
    self._object_sounds = {}  -- obj_id → { event_key → filename }
    self._next_id = 1         -- monotonic play-id counter
    self._debug = false       -- debug logging flag
    return self
end

--- Initialize with a platform driver and options.
-- @param driver  Driver table (nil = no-op mode)
-- @param options Optional config table (reserved for future use)
function M:init(driver, options)
    self._driver = driver
    if options then
        if options.volume ~= nil then
            self:set_volume(options.volume)
        end
        if options.enabled ~= nil then
            self._enabled = options.enabled
        end
        if options.debug then
            self._debug = true
        end
    end
    if self._debug then
        local dname = "nil (headless)"
        if driver then
            dname = driver.name or "unknown"
        end
        print("[sound] driver: " .. dname)
        print("[sound] init: manager ready")
    end
end

--- Shut down: stop all sounds, release resources.
function M:shutdown()
    if self._driver and self._driver.stop_all then
        pcall(self._driver.stop_all, self._driver)
    end
    self._driver = nil
    self._playing = {}
    self._oneshots = {}
    self._ambients = {}
    self._loaded = {}
    self._queue = {}
    self._object_sounds = {}
end

----------------------------------------------------------------------------
-- Driver injection
----------------------------------------------------------------------------

--- Hot-swap the platform driver.
-- @param driver  New driver table (nil reverts to no-op)
function M:set_driver(driver)
    self._driver = driver
end

--- Return the current driver (or nil).
function M:get_driver()
    return self._driver
end

----------------------------------------------------------------------------
-- Object scanning (called by loader after registry registration)
----------------------------------------------------------------------------

--- Extract an object's `sounds` table and queue its files for loading.
-- Safe to call on any object — no-op if `sounds` is absent.
function M:scan_object(obj)
    if not obj or type(obj.sounds) ~= "table" then
        return
    end
    local id = obj.guid or obj.id
    if not id then return end
    local map = {}
    local count = 0
    for key, filename in pairs(obj.sounds) do
        map[key] = filename
        count = count + 1
        if not self._loaded[filename] then
            self._queue[#self._queue + 1] = filename
        end
    end
    self._object_sounds[id] = map
    if self._debug then
        local label = obj.id or id
        print("[sound] scan: " .. label .. " → " .. count .. " sound keys")
    end
end

--- Trigger async load for all queued files.
function M:flush_queue()
    if not self._driver or not self._driver.load then
        self._queue = {}
        return
    end
    for _, filename in ipairs(self._queue) do
        if not self._loaded[filename] then
            pcall(self._driver.load, self._driver, filename, function(handle, err)
                if handle and not err then
                    self._loaded[filename] = handle
                end
            end)
        end
    end
    self._queue = {}
end

----------------------------------------------------------------------------
-- Playback
----------------------------------------------------------------------------

local function _alloc_id(self)
    local id = self._next_id
    self._next_id = id + 1
    return id
end

--- Evict the oldest one-shot when at capacity.
local function _evict_oneshot(self)
    if #self._oneshots < MAX_ONESHOTS then return end
    local oldest_id = table.remove(self._oneshots, 1)
    local entry = self._playing[oldest_id]
    if entry and self._driver and self._driver.stop then
        pcall(self._driver.stop, self._driver, entry.handle)
    end
    self._playing[oldest_id] = nil
end

--- Evict the lowest-priority ambient when at capacity.
local function _evict_ambient(self)
    if #self._ambients < MAX_AMBIENTS then return end
    local oldest_id = table.remove(self._ambients, 1)
    local entry = self._playing[oldest_id]
    if entry and self._driver and self._driver.stop then
        pcall(self._driver.stop, self._driver, entry.handle)
    end
    self._playing[oldest_id] = nil
end

--- Play a sound file.
-- @param filename  Sound filename (e.g. "door-creak.opus")
-- @param opts      Optional table: { loop=bool, owner_id=string,
--                    fade_in_ms=number, fade_out_ms=number }
-- @return play_id or nil
function M:play(filename, opts)
    if not self._driver or not self._enabled or self._muted then
        return nil
    end
    if not self._driver.play then return nil end

    if self._debug then
        print("[sound] play: " .. tostring(filename))
    end

    opts = opts or {}
    local is_loop = opts.loop or false

    -- Enforce concurrency limits
    if is_loop then
        _evict_ambient(self)
    else
        _evict_oneshot(self)
    end

    local driver_opts = {
        volume = self._volume,
        loop = is_loop,
        fade_in_ms = opts.fade_in_ms,
        fade_out_ms = opts.fade_out_ms,
    }

    local ok, handle = pcall(self._driver.play, self._driver, filename, driver_opts)
    if not ok or not handle then return nil end

    local play_id = _alloc_id(self)
    self._playing[play_id] = {
        filename = filename,
        handle = handle,
        loop = is_loop,
        owner_id = opts.owner_id,
    }

    if is_loop then
        self._ambients[#self._ambients + 1] = play_id
    else
        self._oneshots[#self._oneshots + 1] = play_id
    end

    return play_id
end

--- Stop a specific playing sound by play_id.
function M:stop(play_id)
    local entry = self._playing[play_id]
    if not entry then return end
    if self._driver and self._driver.stop then
        pcall(self._driver.stop, self._driver, entry.handle)
    end
    self._playing[play_id] = nil
    -- Remove from tracking lists
    for i, id in ipairs(self._oneshots) do
        if id == play_id then table.remove(self._oneshots, i); break end
    end
    for i, id in ipairs(self._ambients) do
        if id == play_id then table.remove(self._ambients, i); break end
    end
end

--- Stop all sounds owned by a specific object.
function M:stop_by_owner(owner_id)
    if not owner_id then return end
    local to_stop = {}
    for play_id, entry in pairs(self._playing) do
        if entry.owner_id == owner_id then
            to_stop[#to_stop + 1] = play_id
        end
    end
    for _, play_id in ipairs(to_stop) do
        self:stop(play_id)
    end
end

----------------------------------------------------------------------------
-- Room transitions
----------------------------------------------------------------------------

--- Start room ambients and object ambients when entering a room.
function M:enter_room(room)
    if not room or not self._driver then return end
    if self._debug then
        local rid = room.id or room.guid or "?"
        local amb = (room.sounds and room.sounds.ambient) or "(no ambient)"
        print("[sound] enter_room: " .. rid .. " → " .. amb)
    end
    if room.sounds and room.sounds.ambient then
        self:play(room.sounds.ambient, { loop = true, owner_id = room.guid or room.id })
    end
end

--- Stop non-portable sounds when exiting a room.
function M:exit_room(room)
    if not room then return end
    if self._debug then
        local rid = room.id or room.guid or "?"
        print("[sound] exit_room: " .. rid)
    end
    local room_id = room.guid or room.id
    if room_id then
        self:stop_by_owner(room_id)
    end
end

--- Free audio handles for a room's objects.
function M:unload_room(room_id)
    if not room_id then return end
    -- Stop any sounds owned by objects in this room
    self:stop_by_owner(room_id)
    -- Unload cached handles for objects that belonged to the room
    if self._driver and self._driver.unload then
        local obj_map = self._object_sounds[room_id]
        if obj_map then
            for _, filename in pairs(obj_map) do
                local handle = self._loaded[filename]
                if handle then
                    pcall(self._driver.unload, self._driver, handle)
                    self._loaded[filename] = nil
                end
            end
        end
    end
end

----------------------------------------------------------------------------
-- Event dispatch
----------------------------------------------------------------------------

--- Resolve a sound key for an object and play it.
-- Resolution chain (v1.1 C6):
--   1. obj.sounds[event_key] → object-specific (always wins)
--   2. defaults[event_key]   → generic fallback
--   3. nil                   → silent (no sound)
-- State-qualified ambient: checks ambient_{state} before ambient.
function M:trigger(obj, event_key)
    if not self._driver or not self._enabled or self._muted then
        return nil
    end
    if not event_key then return nil end

    local filename = nil
    local owner_id = nil
    local obj_label = (obj and (obj.id or obj.guid)) or "nil"
    local source = nil -- tracks resolution path for debug

    -- Step 1: object-specific sound
    if obj and obj.sounds and obj.sounds[event_key] then
        filename = obj.sounds[event_key]
        owner_id = obj.guid or obj.id
        source = "object"
    end

    -- Step 1b: state-qualified ambient lookup
    if not filename and obj and obj._state and obj.sounds then
        local state_key = "ambient_" .. obj._state
        if obj.sounds[state_key] then
            filename = obj.sounds[state_key]
            owner_id = obj.guid or obj.id
            source = "object-state"
        end
    end

    -- Step 2: defaults fallback
    if not filename then
        filename = defaults[event_key]
        if filename then source = "default" end
    end

    -- Step 3: silent
    if not filename then
        if self._debug then
            print("[sound] trigger: " .. obj_label .. " " .. event_key .. " → (silent)")
        end
        return nil
    end

    if self._debug then
        if source == "default" then
            print("[sound] trigger: " .. obj_label .. " " .. event_key .. " → default: " .. filename)
        else
            print("[sound] trigger: " .. obj_label .. " " .. event_key .. " → " .. filename)
        end
    end

    local is_loop = event_key:find("^ambient") ~= nil
    return self:play(filename, { loop = is_loop, owner_id = owner_id })
end

----------------------------------------------------------------------------
-- Settings
----------------------------------------------------------------------------

--- Set master volume (0.0–1.0, clamped).
function M:set_volume(level)
    if type(level) ~= "number" then return end
    self._volume = math.max(0.0, math.min(1.0, level))
    if self._driver and self._driver.set_master_volume then
        pcall(self._driver.set_master_volume, self._driver, self._volume)
    end
end

--- Get current master volume.
function M:get_volume()
    return self._volume
end

--- Enable or disable all sound globally.
function M:set_enabled(enabled)
    self._enabled = enabled and true or false
    if not self._enabled then
        self:_stop_all()
    end
end

--- Mute (preserves volume setting).
function M:mute()
    self._muted = true
end

--- Unmute.
function M:unmute()
    self._muted = false
end

--- Return true if currently muted.
function M:is_muted()
    return self._muted
end

--- Return true if enabled.
function M:is_enabled()
    return self._enabled
end

----------------------------------------------------------------------------
-- Internal helpers
----------------------------------------------------------------------------

--- Stop all currently playing sounds.
function M:_stop_all()
    if self._driver and self._driver.stop_all then
        pcall(self._driver.stop_all, self._driver)
    end
    self._playing = {}
    self._oneshots = {}
    self._ambients = {}
end

return M
