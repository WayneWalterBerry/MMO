-- engine/ui/status.lua
-- Status bar updater for the split-screen terminal UI.
-- Owned by Smithers (UI Engineer). Pure formatting — no game mutations.

local presentation = require("engine.ui.presentation")

local status = {}

--- Creates the update_status callback for the game context.
--- Returns a function(ctx) that updates the UI status bar each turn.
function status.create_updater()
    return function(ctx)
        if not ctx.ui then return end

        -- Compute game time
        local hour, minute = presentation.get_game_time(ctx)
        local time_str = presentation.format_time(hour, minute)

        -- Room name
        local room_name = "UNKNOWN"
        if ctx.current_room and ctx.current_room.name then
            room_name = ctx.current_room.name:upper()
        end

        -- Right side: match / candle status (best-effort from game state)
        local match_count = "?"
        local candle_icon = "o"
        local p = ctx.player
        if p then
            local matchbox = ctx.registry:get("matchbox")
            if matchbox and matchbox.contents then
                match_count = tostring(#matchbox.contents)
            end
            if p.state.has_flame and p.state.has_flame > 0 then
                candle_icon = "*"
            end
        end

        local left  = " " .. room_name .. "  " .. time_str
        local right = "Matches: " .. match_count .. "  Candle: " .. candle_icon .. " "
        ctx.ui.status(left, right)
    end
end

return status
