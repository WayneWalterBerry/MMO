-- engine/sound/web-driver.lua
-- Web Audio API platform driver. Bridges the Lua sound manager to the
-- JavaScript audio engine (web/audio-driver.js) via Fengari's `js` global.
--
-- Follows the same driver interface contract as null-driver.lua so the
-- sound manager never needs to special-case platform logic.
--
-- Requires: web/audio-driver.js loaded before game-adapter.lua executes.
-- Owner: Gil (Web Engineer)

local js = require("js")
local window = js.global

local M = {}
M.name = "web-audio"

--- Async load: fetch + decode an audio file (with synthetic fallback).
-- @param filename  Sound filename (e.g. "generic-creak.opus")
-- @param callback  function(handle, err) called when ready
function M:load(filename, callback)
    local ok, err = pcall(function()
        window:_soundLoad(filename, function(handle, load_err)
            if callback then
                if load_err then
                    callback(nil, tostring(load_err))
                else
                    callback(tostring(handle), nil)
                end
            end
        end)
    end)
    if not ok then
        if callback then callback(nil, tostring(err)) end
    end
end

--- Play a sound file. Returns a numeric handle for stop/fade.
-- @param filename  Sound filename
-- @param opts      { volume=0-1, loop=bool, fade_in_ms=number }
-- @return handle (number) or nil
function M:play(filename, opts)
    opts = opts or {}
    local ok, result = pcall(function()
        local js_opts = {
            volume = opts.volume or 1.0,
            loop = opts.loop or false,
            fade_in_ms = opts.fade_in_ms or 0,
        }
        return tonumber(tostring(window:_soundPlay(filename, js_opts))) or 0
    end)
    if ok and result and result > 0 then
        return result
    end
    return nil
end

--- Stop a specific playing sound by handle.
-- @param handle  Handle returned from play()
function M:stop(handle)
    if not handle then return end
    pcall(function()
        window:_soundStop(handle)
    end)
end

--- Stop all currently playing sounds.
function M:stop_all()
    pcall(function()
        window:_soundStopAll()
    end)
end

--- Set master volume (0.0–1.0).
-- @param level  Volume level
function M:set_master_volume(level)
    pcall(function()
        window:_soundSetMasterVolume(level or 1.0)
    end)
end

--- Release a cached audio buffer.
-- @param handle  Filename string used as cache key
function M:unload(handle)
    if not handle then return end
    pcall(function()
        window:_soundUnload(handle)
    end)
end

--- Crossfade a playing sound.
-- @param handle    Handle returned from play()
-- @param from      Start volume (0.0–1.0)
-- @param to        End volume (0.0–1.0)
-- @param duration  Fade duration in ms
function M:fade(handle, from, to, duration)
    if not handle then return end
    pcall(function()
        window:_soundFade(handle, from or 1.0, to or 0.0, duration or 1000)
    end)
end

return M
