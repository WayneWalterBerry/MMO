-- engine/ui/presentation.lua
-- Presentation helpers: time formatting, light level, vision checks.
-- Owned by Smithers (UI Engineer). These read game state to produce
-- display-ready values. No mutations — pure queries.
--
-- Shared constants (single source of truth for time calculations):
--   GAME_SECONDS_PER_REAL_SECOND, GAME_START_HOUR, DAYTIME_START, DAYTIME_END

local presentation = {}

---------------------------------------------------------------------------
-- Constants (authoritative — remove duplicates from verbs/init.lua, main.lua)
---------------------------------------------------------------------------
presentation.GAME_SECONDS_PER_REAL_SECOND = 24
presentation.GAME_START_HOUR = 2
presentation.DAYTIME_START = 6
presentation.DAYTIME_END = 18

---------------------------------------------------------------------------
-- Carried items utility (needed by get_light_level)
---------------------------------------------------------------------------

--- Returns flat list of all object IDs the player is carrying
--- (hands + held bag contents + worn items + worn bag contents)
function presentation.get_all_carried_ids(ctx)
    local ids = {}
    local reg = ctx.registry
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local hand_id = type(hand) == "table" and hand.id or hand
            ids[#ids + 1] = hand_id
            local obj = type(hand) == "table" and hand or reg:get(hand)
            if obj and obj.container and obj.contents then
                for _, item_id in ipairs(obj.contents) do
                    ids[#ids + 1] = item_id
                end
            end
        end
    end
    for _, worn_id in ipairs(ctx.player.worn or {}) do
        ids[#ids + 1] = worn_id
        local obj = reg:get(worn_id)
        if obj and obj.container and obj.contents then
            for _, item_id in ipairs(obj.contents) do
                ids[#ids + 1] = item_id
            end
        end
    end
    return ids
end

---------------------------------------------------------------------------
-- Time
---------------------------------------------------------------------------

--- Returns game hour and minute from real-time clock.
function presentation.get_game_time(ctx)
    local real_elapsed = os.time() - ctx.game_start_time
    local total_game_hours = (real_elapsed * presentation.GAME_SECONDS_PER_REAL_SECOND) / 3600
    local absolute_hour = presentation.GAME_START_HOUR + total_game_hours + (ctx.time_offset or 0)
    local hour = math.floor(absolute_hour % 24)
    local minute = math.floor((absolute_hour * 60) % 60)
    return hour, minute
end

--- Returns true if the game clock is between DAYTIME_START and DAYTIME_END.
function presentation.is_daytime(ctx)
    local hour = presentation.get_game_time(ctx)
    return hour >= presentation.DAYTIME_START and hour < presentation.DAYTIME_END
end

--- Formats hour+minute into "H:MM AM/PM".
function presentation.format_time(hour, minute)
    local period = hour >= 12 and "PM" or "AM"
    local display_hour = hour % 12
    if display_hour == 0 then display_hour = 12 end
    return string.format("%d:%02d %s", display_hour, minute, period)
end

--- Returns a prose description of the time of day.
function presentation.time_of_day_desc(hour)
    if hour >= 5 and hour < 7 then return "Dawn breaks on the horizon."
    elseif hour >= 7 and hour < 10 then return "Morning light fills the sky."
    elseif hour >= 10 and hour < 14 then return "The sun stands high overhead."
    elseif hour >= 14 and hour < 17 then return "The afternoon sun angles westward."
    elseif hour >= 17 and hour < 19 then return "Dusk gathers at the edges of the world."
    elseif hour >= 19 and hour < 21 then return "Night has fallen."
    else return "Deep night. The world sleeps."
    end
end

---------------------------------------------------------------------------
-- Light system — tri-state: "lit", "dim", "dark"
--   "lit"  = full light (open curtains + daytime, or artificial light)
--   "dim"  = filtered daylight through closed curtains during daytime
--   "dark" = no light at all (nighttime, no candle)
-- Dim light is enough to see and interact; descriptions note the dimness.
---------------------------------------------------------------------------

function presentation.get_light_level(ctx)
    local room = ctx.current_room
    local reg = ctx.registry

    -- Artificial light always gives full "lit" (candle, torch, etc.)
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = reg:get(obj_id)
        if obj and obj.casts_light then return "lit" end
        if obj and obj.surfaces then
            for _, zone in pairs(obj.surfaces) do
                for _, item_id in ipairs(zone.contents or {}) do
                    local item = reg:get(item_id)
                    -- Check contents of surface items (e.g., candle inside holder)
                    if item and item.contents then
                        for _, inner_id in ipairs(item.contents) do
                            local inner = reg:get(inner_id)
                            if inner and inner.casts_light then return "lit" end
                        end
                    end
                    if item and item.casts_light then return "lit" end
                end
            end
        end
    end
    for _, obj_id in ipairs(presentation.get_all_carried_ids(ctx)) do
        local obj = reg:get(obj_id)
        if obj and obj.casts_light then return "lit" end
        -- #219: Check contents of carried items (e.g., candle inside holder)
        -- even for non-container composites that have a contents list.
        if obj and obj.contents then
            for _, inner_id in ipairs(obj.contents) do
                local inner = reg:get(inner_id)
                if inner and inner.casts_light then return "lit" end
            end
        end
    end

    -- Daylight: open curtains = "lit", closed curtains = "dim"
    if presentation.is_daytime(ctx) then
        local has_filter = false
        for _, obj_id in ipairs(room.contents or {}) do
            local obj = reg:get(obj_id)
            if obj and obj.allows_daylight then return "lit" end
            if obj and obj.filters_daylight then has_filter = true end
        end
        if has_filter then return "dim" end
    end

    return "dark"
end

--- Convenience: can the player see enough to interact?
function presentation.has_some_light(ctx)
    return presentation.get_light_level(ctx) ~= "dark"
end

---------------------------------------------------------------------------
-- Vision check
---------------------------------------------------------------------------

--- Returns true, blocker_obj if player's vision is blocked by a worn item.
function presentation.vision_blocked_by_worn(ctx)
    local reg = ctx.registry
    for _, worn_id in ipairs(ctx.player.worn or {}) do
        local obj = reg:get(worn_id)
        if obj and obj.wear and obj.wear.blocks_vision then
            return true, obj
        end
    end
    return false, nil
end

return presentation
