-- engine/verbs/rest.lua
-- Sleep/rest/nap handlers, split from survival.lua in Phase 3 WAVE-0.
--
-- Ownership: Bart (Architect)

local H = require("engine.verbs.helpers")

local fsm_mod = H.fsm_mod

local DAYTIME_START = H.DAYTIME_START
local DAYTIME_END = H.DAYTIME_END

local _hid = H._hid
local get_game_time = H.get_game_time
local format_time = H.format_time
local time_of_day_desc = H.time_of_day_desc

local M = {}

function M.register(handlers)
    -- SLEEP / REST / NAP — clock-advance mechanic
    ---------------------------------------------------------------------------
    local function do_sleep(ctx, noun)
        -- Parse duration from noun
        local sleep_hours = nil

        if noun == "" or noun == nil then
            -- Default: 1 hour nap
            sleep_hours = 1
        else
            -- "for X hours" / "for X minutes" OR "X hours" / "X minutes" (optional "for")
            local num, unit = noun:match("for%s+(%d+)%s*(%a+)")
            if not num then
                -- Try without "for" keyword
                num, unit = noun:match("^(%d+)%s*(%a+)")
            end
            if num then
                num = tonumber(num)
                unit = unit:lower()
                if unit:match("^hour") then
                    sleep_hours = num
                elseif unit:match("^min") then
                    sleep_hours = num / 60
                else
                    sleep_hours = num  -- assume hours
                end
            end

            -- "until dawn" / "until morning"
            if not sleep_hours then
                if noun:match("until%s+dawn") or noun:match("until%s+morning") then
                    local cur_h, cur_m = get_game_time(ctx)
                    local cur_total = cur_h + cur_m / 60
                    local target = DAYTIME_START  -- 6:00 AM
                    if cur_total >= target and cur_total < DAYTIME_END then
                        -- BUG-069: It's already daytime — dawn has passed
                        print("It's already past dawn.")
                        return
                    elseif cur_total >= target then
                        -- Evening/night: wrap to next dawn
                        sleep_hours = (24 - cur_total) + target
                    else
                        sleep_hours = target - cur_total
                    end
                    if sleep_hours < 0.167 then
                        print("It's already nearly dawn — just wait a few minutes.")
                        return
                    end
                end
            end

            -- "until night" / "until dark" / "until dusk"
            if not sleep_hours then
                if noun:match("until%s+night") or noun:match("until%s+dark")
                   or noun:match("until%s+dusk") or noun:match("until%s+evening") then
                    local cur_h, cur_m = get_game_time(ctx)
                    local cur_total = cur_h + cur_m / 60
                    local target = DAYTIME_END  -- 6:00 PM
                    if cur_total >= target then
                        -- BUG-069: It's already nighttime
                        print("It's already nighttime.")
                        return
                    else
                        sleep_hours = target - cur_total
                    end
                    if sleep_hours < 0.167 then
                        print("It's already nighttime.")
                        return
                    end
                end
            end

            -- "for a bit" / "for a while"
            if not sleep_hours then
                if noun:match("a%s+bit") or noun:match("a%s+while") then
                    sleep_hours = 1
                elseif noun:match("a%s+long%s+time") then
                    sleep_hours = 4
                end
            end

            -- Couldn't parse
            if not sleep_hours then
                print("Sleep how long? Try 'sleep for 2 hours' or 'sleep until dawn'.")
                return
            end
        end

        -- Enforce limits
        if sleep_hours < 10 / 60 then
            print("That's barely a nap. You close your eyes for a moment, but don't really sleep.")
            return
        end
        if sleep_hours > 12 then
            print("You can't sleep that long. Try 12 hours or less.")
            return
        end

        -- Snapshot time before sleep
        local before_h, before_m = get_game_time(ctx)

        -- Advance game clock
        ctx.time_offset = (ctx.time_offset or 0) + sleep_hours

        -- Compute ticks to process (roughly 10 ticks per game hour)
        local sleep_ticks = math.floor(sleep_hours * 10)
        if sleep_ticks < 1 then sleep_ticks = 1 end

        -- Build tick targets (same logic as game loop)
        local reg = ctx.registry
        local room = ctx.current_room
        local tick_targets = {}
        for _, obj_id in ipairs(room and room.contents or {}) do
            tick_targets[#tick_targets + 1] = obj_id
            local obj = reg:get(obj_id)
            if obj and obj.surfaces then
                for _, zone in pairs(obj.surfaces) do
                    for _, item_id in ipairs(zone.contents or {}) do
                        tick_targets[#tick_targets + 1] = item_id
                    end
                end
            end
            if obj and obj.contents then
                for _, item_id in ipairs(obj.contents) do
                    tick_targets[#tick_targets + 1] = item_id
                end
            end
        end
        if ctx.player then
            for i = 1, 2 do
                if ctx.player.hands[i] then
                    tick_targets[#tick_targets + 1] = _hid(ctx.player.hands[i])
                end
            end
        end

        -- Tick all FSM objects for elapsed ticks, collecting messages
        local sleep_messages = {}
        -- Each sleep tick = 1/10 game hour = 360 game seconds
        local SLEEP_SECONDS_PER_TICK = 360
        for tick = 1, sleep_ticks do
            for _, obj_id in ipairs(tick_targets) do
                local obj = reg:get(obj_id)
                if obj and obj._state then
                    local msg = fsm_mod.tick(reg, obj_id)
                    if msg then
                        sleep_messages[#sleep_messages + 1] = msg
                    end
                end
            end
            -- Tick timed events engine during sleep
            local timer_msgs = fsm_mod.tick_timers(reg, SLEEP_SECONDS_PER_TICK)
            for _, entry in ipairs(timer_msgs) do
                sleep_messages[#sleep_messages + 1] = entry.message
            end
            -- Also fire on_tick for non-FSM burnables
            if ctx.on_tick then
                ctx.on_tick(ctx)
            end
            -- Tick blood
            local p = ctx.player
            if p and p.state and p.state.bloody and p.state.bleed_ticks then
                p.state.bleed_ticks = p.state.bleed_ticks - 1
                if p.state.bleed_ticks <= 0 then
                    p.state.bloody = false
                    p.state.bleed_ticks = nil
                    sleep_messages[#sleep_messages + 1] = "The bleeding stopped while you slept."
                end
            end
            -- Tick injuries during sleep (bleeding can kill you in your sleep)
            local sleep_inj_ok, sleep_injury_mod = pcall(require, "engine.injuries")
            if sleep_inj_ok and sleep_injury_mod and ctx.player
               and ctx.player.injuries and #ctx.player.injuries > 0 then
                local inj_msgs, died = sleep_injury_mod.tick(ctx.player)
                for _, msg in ipairs(inj_msgs or {}) do
                    sleep_messages[#sleep_messages + 1] = msg
                end
                if died then
                    -- Player bled out during sleep
                    print("")
                    print("You drift deeper into sleep. The pain fades. Everything fades.")
                    print("You never wake up.")
                    print("")
                    print("YOU HAVE DIED.")
                    ctx.game_over = true
                    return
                end
            end
        end

        -- Compute time after sleep
        local after_h, after_m = get_game_time(ctx)

        -- Format duration for display
        local dur_str
        local total_minutes = math.floor(sleep_hours * 60 + 0.5)
        if total_minutes >= 60 then
            local h = math.floor(total_minutes / 60)
            local m = total_minutes % 60
            if m == 0 then
                dur_str = h .. (h == 1 and " hour" or " hours")
            else
                dur_str = h .. (h == 1 and " hour" or " hours") .. " and " .. m .. " minutes"
            end
        else
            dur_str = total_minutes .. " minutes"
        end

        -- Opening text
        print("")
        print("You close your eyes and rest for " .. dur_str .. ".")

        -- Check for notable events during sleep
        local candle_died = false
        for _, msg in ipairs(sleep_messages) do
            if msg:lower():match("candle") and (msg:lower():match("out") or msg:lower():match("gutter")) then
                candle_died = true
            end
        end

        -- Daylight check: did we sleep past dawn with curtains open?
        local crossed_dawn = (before_h < DAYTIME_START or before_h >= DAYTIME_END) and
                             (after_h >= DAYTIME_START and after_h < DAYTIME_END)
        local curtains_open = false
        for _, obj_id in ipairs(room and room.contents or {}) do
            local obj = reg:get(obj_id)
            if obj and obj.allows_daylight then
                curtains_open = true
                break
            end
        end

        -- Wake-up flavor text
        local sky = room and room.sky_visible
        if candle_died then
            print("You drift off... When you wake, the candle has guttered out. Darkness surrounds you.")
        elseif crossed_dawn and curtains_open and sky then
            print("You wake to pale morning light filtering through the window.")
        elseif crossed_dawn and sky then
            print("You sense the world brightening beyond the curtains.")
        end

        -- Print time
        local sky = room and room.sky_visible
        local desc = time_of_day_desc(after_h, sky)
        if desc then
            print("It is now " .. format_time(after_h, after_m) .. ". " .. desc)
        else
            print("It is now " .. format_time(after_h, after_m) .. ".")
        end

        -- Update status bar
        if ctx.ui and ctx.ui.is_enabled() and ctx.update_status then
            ctx.update_status(ctx)
        end
    end

    handlers["sleep"] = do_sleep
    handlers["rest"]  = do_sleep
    handlers["nap"]   = do_sleep
end

return M
