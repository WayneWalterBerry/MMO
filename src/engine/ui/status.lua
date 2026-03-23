-- engine/ui/status.lua
-- Status bar updater for the split-screen terminal UI.
-- Owned by Smithers (UI Engineer). Pure formatting — no game mutations.

local presentation = require("engine.ui.presentation")

local status = {}

---------------------------------------------------------------------------
-- Level lookup: maps room IDs → { number, name }
-- Rooms don't yet carry a `level` field (see decision inbox note).
-- This table is the interim single source of truth until rooms declare
-- their own level. Moe should add `level = { number = 1, name = "..." }`
-- to each room .lua file; once that lands, this fallback can be removed.
---------------------------------------------------------------------------
status.LEVEL_MAP = {
    ["start-room"]     = { number = 1, name = "The Awakening" },
    ["cellar"]         = { number = 1, name = "The Awakening" },
    ["hallway"]        = { number = 1, name = "The Awakening" },
    ["storage-cellar"] = { number = 1, name = "The Awakening" },
    ["courtyard"]      = { number = 2, name = "The Courtyard" },
}

--- Returns the level info for a room: { number, name } or nil.
--- Prefers room.level (if Moe has added it), falls back to LEVEL_MAP.
function status.get_level(room)
    if room and room.level then
        return room.level
    end
    if room and room.id then
        return status.LEVEL_MAP[room.id]
    end
    return nil
end

--- Creates the update_status callback for the game context.
--- Returns a function(ctx) that updates the UI status bar each turn.
function status.create_updater()
    return function(ctx)
        if not ctx.ui then return end

        -- Compute game time
        local hour, minute = presentation.get_game_time(ctx)
        local time_str = presentation.format_time(hour, minute)

        -- Level + Room name
        local room_name = "UNKNOWN"
        if ctx.current_room and ctx.current_room.name then
            room_name = ctx.current_room.name:upper()
        end

        local level_info = status.get_level(ctx.current_room)
        local location_str
        if level_info then
            location_str = "Lv " .. level_info.number .. ": "
                         .. level_info.name .. " — " .. room_name
        else
            location_str = room_name
        end

        -- Right side: health status (if injured)
        local right_str = ""
        local p = ctx.player
        if p then
            local inj_ok, injury_mod = pcall(require, "engine.injuries")
            if inj_ok and injury_mod then
                local health = injury_mod.compute_health(p)
                local max_hp = p.max_health or 100
                if health < max_hp then
                    right_str = "Health: " .. health .. "/" .. max_hp .. " "
                end
            end
        end

        local left  = " " .. location_str .. "  " .. time_str
        ctx.ui.status(left, right_str)
    end
end

return status
