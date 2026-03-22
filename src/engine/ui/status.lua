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

        -- Right side: match / candle status (best-effort from game state)
        -- BUG-092: Find the actual matchbox wherever it lives — player hands
        -- first (where contents get modified), then surfaces/room, then registry.
        local match_count = "?"
        local candle_icon = "o"
        local p = ctx.player
        if p then
            local matchbox = nil
            -- 1) Check player hands for matchbox
            for i = 1, 2 do
                local hand = p.hands and p.hands[i]
                if hand then
                    local obj = type(hand) == "table" and hand
                        or ctx.registry:get(hand)
                    if obj and obj.container and obj.contents then
                        local kws = obj.keywords or {}
                        for _, k in ipairs(kws) do
                            if k == "matchbox" then matchbox = obj; break end
                        end
                    end
                    if matchbox then break end
                end
            end
            -- 2) Check visible containers in the room (surfaces, room contents)
            if not matchbox and ctx.current_room then
                local room = ctx.current_room
                local reg = ctx.registry
                for _, obj_id in ipairs(room.contents or {}) do
                    local obj = reg:get(obj_id)
                    if obj then
                        if obj.surfaces then
                            for _, zone in pairs(obj.surfaces) do
                                for _, item_id in ipairs(zone.contents or {}) do
                                    local item = reg:get(item_id)
                                    if item and item.container and item.contents then
                                        local kws = item.keywords or {}
                                        for _, k in ipairs(kws) do
                                            if k == "matchbox" then matchbox = item; break end
                                        end
                                    end
                                    if matchbox then break end
                                end
                                if matchbox then break end
                            end
                        end
                        if not matchbox and obj.container and obj.contents then
                            local kws = obj.keywords or {}
                            for _, k in ipairs(kws) do
                                if k == "matchbox" then matchbox = obj; break end
                            end
                        end
                    end
                    if matchbox then break end
                end
            end
            -- 3) Fall back to registry lookup
            if not matchbox then
                matchbox = ctx.registry:get("matchbox")
            end
            if matchbox and matchbox.contents then
                match_count = tostring(#matchbox.contents)
            end
            if p.state.has_flame and p.state.has_flame > 0 then
                candle_icon = "*"
            end
        end

        local left  = " " .. location_str .. "  " .. time_str
        local right = "Matches: " .. match_count .. "  Candle: " .. candle_icon .. " "
        ctx.ui.status(left, right)
    end
end

return status
