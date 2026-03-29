-- engine/sound/null-driver.lua
-- Null platform driver: all operations are no-ops.
-- Used in terminal/headless mode where no audio output is available.
-- Satisfies the full driver interface contract so the sound manager
-- never needs to nil-check individual methods.

local M = {}

function M:load(filename, callback)
    if callback then callback(filename, nil) end
end

function M:play(handle, opts)
    return handle
end

function M:stop(playback_id)
end

function M:stop_all()
end

function M:set_master_volume(level)
end

function M:unload(handle)
end

function M:fade(handle, from, to, duration)
end

return M
