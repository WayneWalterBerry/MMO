-- engine/verbs/meta.lua
local H = require("engine.verbs.helpers")

local fsm_mod = H.fsm_mod
local presentation = H.presentation
local preprocess = H.preprocess
local traverse_effects = H.traverse_effects
local effects = H.effects
local materials = H.materials
local context_window = H.context_window
local fuzzy = H.fuzzy

local GAME_SECONDS_PER_REAL_SECOND = H.GAME_SECONDS_PER_REAL_SECOND
local GAME_START_HOUR = H.GAME_START_HOUR
local DAYTIME_START = H.DAYTIME_START
local DAYTIME_END = H.DAYTIME_END

local next_instance_id = H.next_instance_id
local _hid = H._hid
local _hobj = H._hobj
local err_not_found = H.err_not_found
local err_cant_do_that = H.err_cant_do_that
local err_nothing_happens = H.err_nothing_happens
local matches_keyword = H.matches_keyword
local interaction_verbs = H.interaction_verbs
local hands_full = H.hands_full
local first_empty_hand = H.first_empty_hand
local which_hand = H.which_hand
local get_all_carried_ids = H.get_all_carried_ids
local count_hands_used = H.count_hands_used
local find_part = H.find_part
local detach_part = H.detach_part
local reattach_part = H.reattach_part
local _fv_room = H._fv_room
local _fv_surfaces = H._fv_surfaces
local _fv_parts = H._fv_parts
local _fv_hands = H._fv_hands
local _fv_bags = H._fv_bags
local _fv_worn = H._fv_worn
local find_visible = H.find_visible
local find_in_inventory = H.find_in_inventory
local find_tool_in_inventory = H.find_tool_in_inventory
local provides_capability = H.provides_capability
local find_visible_tool = H.find_visible_tool
local consume_tool_charge = H.consume_tool_charge
local remove_from_location = H.remove_from_location
local container_contents_accessible = H.container_contents_accessible
local find_mutation = H.find_mutation
local exit_matches = H.exit_matches
local spawn_objects = H.spawn_objects
local perform_mutation = H.perform_mutation
local inventory_weight = H.inventory_weight
local move_spatial_object = H.move_spatial_object

local get_game_time = H.get_game_time
local is_daytime = H.is_daytime
local format_time = H.format_time
local time_of_day_desc = H.time_of_day_desc
local get_light_level = H.get_light_level
local has_some_light = H.has_some_light
local vision_blocked_by_worn = H.vision_blocked_by_worn

local M = {}

function M.register(handlers)
    ---------------------------------------------------------------------------
    -- INVENTORY -- shows hands, worn items, and bag contents
    ---------------------------------------------------------------------------
    handlers["inventory"] = function(ctx, noun)
        local reg = ctx.registry

        -- Hands
        for i = 1, 2 do
            local hand = ctx.player.hands[i]
            if hand then
                local obj = _hobj(hand, reg)
                local label = (i == 1) and "Left hand" or "Right hand"
                print("  " .. label .. ": " .. (obj and obj.name or _hid(hand)))
                -- Show bag contents
                if obj and obj.container and obj.contents and #obj.contents > 0 then
                    print("    (contains:)")
                    for _, item_id in ipairs(obj.contents) do
                        local item = reg:get(item_id)
                        print("      " .. (item and item.name or item_id))
                    end
                end
            else
                local label = (i == 1) and "Left hand" or "Right hand"
                print("  " .. label .. ": (empty)")
            end
        end

        -- Worn items (grouped by slot when wear metadata is available)
        if #(ctx.player.worn or {}) > 0 then
            print("  Worn:")
            for _, worn_id in ipairs(ctx.player.worn) do
                local obj = reg:get(worn_id)
                local label = obj and obj.name or worn_id
                if obj and obj.wear and obj.wear.slot then
                    label = label .. " (" .. obj.wear.slot .. ")"
                end
                print("    " .. label)
                if obj and obj.container and obj.contents and #obj.contents > 0 then
                    print("    (contains:)")
                    for _, item_id in ipairs(obj.contents) do
                        local item = reg:get(item_id)
                        print("      " .. (item and item.name or item_id))
                    end
                end
            end
        end

        -- Flame status
        if ctx.player.state.has_flame and ctx.player.state.has_flame > 0 then
            print("")
            print("  You hold a flickering match flame.")
        end
    end

    handlers["i"] = handlers["inventory"]

    -- TIME
    ---------------------------------------------------------------------------
    handlers["time"] = function(ctx, noun)
        local hour, minute = get_game_time(ctx)
        print(time_of_day_desc(hour))
        print("It is " .. format_time(hour, minute) .. ".")
    end

    ---------------------------------------------------------------------------
    -- SET / ADJUST — advance adjustable clocks (puzzle mechanic)
    ---------------------------------------------------------------------------
    handlers["set"] = function(ctx, noun)
        if noun == "" then print("Set what?") return end

        -- Find the target object (room or inventory)
        local obj = find_visible(ctx, noun)
        if not obj then obj = find_in_inventory(ctx, noun) end
        if not obj then
            print("You don't see any " .. noun .. " to set.")
            return
        end

        -- Only adjustable clocks respond to SET
        if not obj.adjustable then
            print("You can't set that.")
            return
        end

        -- Must have light to fiddle with clock hands
        if not has_some_light(ctx) then
            print("It is too dark to see the clock face.")
            return
        end

        -- Extract current hour from state name (hour_N)
        local cur_hour = obj._state and tonumber(obj._state:match("hour_(%d+)"))
        if not cur_hour then
            print("You can't figure out how to set that.")
            return
        end

        -- Advance to next hour
        local next_hour = (cur_hour % 24) + 1
        local next_state = "hour_" .. next_hour

        -- Apply the state change directly (manual adjustment, not timed)
        local fsm_set = require("engine.fsm")
        fsm_set.stop_timer(obj.id or "wall-clock")
        local old_state = obj._state
        if obj.states and obj.states[next_state] then
            -- Apply new state properties
            if obj.states[old_state] then
                for k in pairs(obj.states[old_state]) do
                    if k ~= "on_tick" and k ~= "terminal" and k ~= "timed_events" then
                        obj[k] = nil
                    end
                end
            end
            for k, v in pairs(obj.states[next_state]) do
                if k ~= "on_tick" and k ~= "terminal" and k ~= "timed_events" then
                    obj[k] = v
                end
            end
            obj._state = next_state
        end

        -- Restart the hourly timer for the new state
        fsm_set.start_timer(ctx.registry, obj.id or "wall-clock")

        -- Display the new hour
        local display_h = ((next_hour - 1) % 12) + 1
        local number_words = {
            "one", "two", "three", "four", "five", "six",
            "seven", "eight", "nine", "ten", "eleven", "twelve",
        }
        print("You turn the clock hands. The clock now reads " .. number_words[display_h] .. " o'clock.")

        -- Check if puzzle target_hour is reached
        if obj.target_hour and next_hour == obj.target_hour then
            if obj.on_correct_time then
                obj.on_correct_time(obj, ctx)
            end
        end
    end
    handlers["adjust"] = handlers["set"]

    ---------------------------------------------------------------------------
    -- REPORT BUG — opens a pre-filled GitHub issue URL
    ---------------------------------------------------------------------------
    handlers["report_bug"] = function(ctx, noun)
        -- Build transcript text from recent output (last 50 exchanges)
        local transcript = ctx.transcript or {}
        local lines = {}
        for _, entry in ipairs(transcript) do
            lines[#lines + 1] = "> " .. entry.input
            lines[#lines + 1] = entry.output
            lines[#lines + 1] = ""
        end
        local transcript_text = table.concat(lines, "\n")

        -- Level name (stored on room object as level = { number, name })
        local level_name = "Unknown"
        if ctx.current_room and ctx.current_room.level then
            local lv = ctx.current_room.level
            if lv.number and lv.name then
                level_name = "Level " .. lv.number .. ": " .. lv.name
            elseif lv.name then
                level_name = lv.name
            end
        end

        -- Room name
        local room_name = "Unknown"
        if ctx.current_room then
            room_name = ctx.current_room.name or ctx.current_room.id or "Unknown"
        end

        -- Build timestamp (read from src/.build-timestamp if available)
        local build_timestamp = "dev"
        local ts_file = io.open("src/.build-timestamp", "r")
        if ts_file then
            local content = ts_file:read("*a")
            ts_file:close()
            if content and #content > 0 then
                build_timestamp = content:match("^%s*(.-)%s*$") or "dev"
            end
        end

        -- URL-encode helper
        local function url_encode(str)
            str = str:gsub("\r\n", "\n")
            str = str:gsub("([^%w%-%.%_%~ ])", function(c)
                return string.format("%%%02X", string.byte(c))
            end)
            str = str:gsub(" ", "+")
            return str
        end

        local timestamp = os.date and os.date("%Y-%m-%d %H:%M") or "unknown"
        local title = "[Bug Report] " .. room_name .. " - " .. timestamp
        local body = "## Bug Report\n\n"
            .. "**Level:** " .. level_name .. "\n"
            .. "**Room:** " .. room_name .. "\n"
            .. "**Build:** " .. build_timestamp .. "\n\n"
            .. "### What happened?\n"
            .. "_[Please describe the bug here]_\n\n"
            .. "### Session Transcript (last " .. #transcript .. " lines)\n\n"
            .. "```\n" .. transcript_text .. "```\n"

        local url = "https://github.com/WayneWalterBerry/MMO-Issues/issues/new"
            .. "?title=" .. url_encode(title)
            .. "&body=" .. url_encode(body)

        -- Try web bridge first (opens in new tab), fall back to printing URL
        if ctx.open_url then
            ctx.open_url(url)
            print("Opening bug report in a new tab...")
        else
            print("To report a bug, open this URL:")
            print(url)
        end
        print("Thank you for helping improve the game!")
    end
    ---------------------------------------------------------------------------
    -- HELP
    ---------------------------------------------------------------------------
    handlers["help"] = function(ctx, noun)
        print("== Movement ==")
        print("  north/south/east/west    Move in a direction (n/s/e/w)")
        print("  up/down                  Move up or down (u/d)")
        print("  go <direction>           Move (go north, go through door)")
        print("  enter <thing>            Enter through an exit")
        print("  climb up/down            Climb stairs or ladders")
        print("")
        print("== Observation ==")
        print("  look                     Look around the room (vision only, needs light)")
        print("  look at <thing>          Examine something closely (needs light)")
        print("  look in/on/under         Inspect a surface (needs light)")
        print("  search                   Search around (all senses, works in darkness)")
        print("  search <thing>           Search for something (all senses)")
        print("  find <thing>             Find something (all senses, works in darkness)")
        print("  read <thing>             Read text on an object (may teach skills)")
        print("  feel                     Grope around (works in darkness)")
        print("  feel <thing>             Feel an object by touch")
        print("  smell                    Smell the air (works in darkness)")
        print("  smell <thing>            Smell a specific object")
        print("  taste <thing>            Taste something (risky! works in darkness)")
        print("  listen                   Listen to ambient sounds (works in darkness)")
        print("  listen to <thing>        Listen closely to something")
        print("")
        print("== Item Interaction ==")
        print("  take <thing>             Pick something up (needs a free hand)")
        print("  get <x> from <y>         Take something from a bag or container")
        print("  drop <thing>             Drop something you're holding")
        print("  put <x> in <y>           Put something in a container")
        print("  put <x> on <y>           Put something on a surface")
        print("  open <thing>             Open a container or door")
        print("  close <thing>            Close something")
        print("  unlock <thing>           Unlock a locked door")
        print("  pull <thing>             Pull a part free (drawer, cork, etc.)")
        print("")
        print("== Equipment ==")
        print("  wear <thing>             Put on a wearable item (cloak, hat, armor)")
        print("  remove <thing>           Take off a worn item")
        print("  inventory (i)            See what you're carrying / wearing")
        print("")
        print("== Tools & Crafting ==")
        print("  break <thing>            Break something breakable")
        print("  tear <thing>             Tear fabric apart")
        print("  cut <thing> with <tool>  Cut something (or 'cut self' for blood)")
        print("  prick self with <tool>   Prick yourself with something sharp")
        print("  strike match on <x>      Strike a match")
        print("  light <thing>            Light a candle or torch (needs fire)")
        print("  extinguish <thing>       Put out a flame")
        print("  write <text> on <thing>  Write on a writable surface")
        print("  sew <thing> with <tool>  Sew materials together (requires skill)")
        print("")
        print("== Combat ==")
        print("  stab <target>            Attack with a stabbing weapon")
        print("  slash <target>           Attack with a slashing weapon")
        print("")
        print("== Health & Survival ==")
        print("  health                   Check your injuries and health")
        print("  injuries                 List your injuries")
        print("  apply <item>             Apply a healing item to an injury")
        print("  eat <thing>              Eat something edible")
        print("  drink <thing>            Drink from a container")
        print("  pour <thing>             Pour out a liquid")
        print("  burn <thing>             Set something flammable on fire")
        print("  sleep                    Sleep for 1 hour (or: sleep for 2 hours)")
        print("")
        print("== Information ==")
        print("  time                     Check the time of day")
        print("  help                     Show this list")
        print("  report bug               Report a bug (opens GitHub issue)")
        print("  quit                     Leave the game")
    end
    ---------------------------------------------------------------------------
    -- INJURIES -- examine active injuries and derived health
    ---------------------------------------------------------------------------
    handlers["injuries"] = function(ctx, noun)
        local inj_ok, injury_mod = pcall(require, "engine.injuries")
        if not inj_ok then
            print("You feel fine.")
            return
        end

        injury_mod.list(ctx.player)

        -- Show derived health
        local health = injury_mod.compute_health(ctx.player)
        local max = ctx.player.max_health or 100
        if ctx.player.injuries and #ctx.player.injuries > 0 then
            print("")
            print("Health: " .. health .. "/" .. max)
        end
    end
    handlers["injury"] = handlers["injuries"]
    handlers["wounds"] = handlers["injuries"]
    handlers["health"] = handlers["injuries"]

    ---------------------------------------------------------------------------
    -- APPLY -- apply a healing item to an injury ("apply bandage", "apply bandage to wound")
    -- Supports bandage dual-binding via injury_targeting + injury_treatment
    ---------------------------------------------------------------------------
    handlers["apply"] = function(ctx, noun)
        if noun == "" then
            print("Apply what? Try 'examine' to check what you're carrying.")
            return
        end

        local inj_ok, injury_mod = pcall(require, "engine.injuries")
        if not inj_ok then
            err_cant_do_that()
            return
        end

        if not ctx.player.injuries or #ctx.player.injuries == 0 then
            print("You don't have any injuries to treat.")
            return
        end

        -- Parse "apply X to Y" or just "apply X"
        local item_kw = noun
        local target_kw = nil
        local to_match = noun:match("^(.-)%s+to%s+(.+)$")
        if to_match then
            item_kw = noun:match("^(.-)%s+to%s+")
            target_kw = noun:match("%s+to%s+(.+)$")
        end

        -- Strip articles
        item_kw = item_kw:lower():gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        if target_kw then
            target_kw = target_kw:lower():gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", ""):gsub("^my%s+", "")
        end

        -- Find healing item in inventory (hands, worn, etc.)
        local obj = find_in_inventory(ctx, item_kw)
        if not obj then
            print("You don't have " .. item_kw .. ".")
            return
        end

        -- Check if this is a bandage-type item with cures list and FSM
        if obj.cures and obj._state then
            -- Bandage-style treatment: use dual-binding system
            if obj.applied_to then
                print((obj.name or "That") .. " is already applied to a wound.")
                return
            end

            -- Resolve which injury to target
            local injury, err = injury_mod.resolve_target(ctx.player, target_kw, obj.cures)
            if not injury then
                print(err)
                return
            end

            -- Apply the treatment (dual binding)
            injury_mod.apply_treatment(ctx.player, obj, injury)

            -- Find and print the transition message from the bandage's transitions
            local msg = nil
            if obj.transitions then
                for _, t in ipairs(obj.transitions) do
                    if t.verb == "apply" and t.to == "applied" then
                        msg = t.message
                        break
                    end
                end
            end
            if not msg then
                msg = "You apply " .. (obj.name or item_kw) .. " to the wound."
            end
            print(msg)
            return
        end

        -- Fallback: legacy healing via on_apply/on_use/on_drink
        local healing_effect = nil
        local healing_verb = nil
        for _, v in ipairs({"apply", "use", "drink"}) do
            local eff = obj["on_" .. v]
            if eff and eff.cures then
                healing_effect = eff
                healing_verb = v
                break
            end
        end

        if not healing_effect then
            print("You can't use " .. (obj.name or item_kw) .. " to treat injuries.")
            return
        end

        -- Attempt healing
        local healed = injury_mod.try_heal(ctx.player, obj, healing_verb)
        if healed and healing_effect.consumable then
            -- Consume the item from hands
            for i = 1, 2 do
                local hand = ctx.player.hands[i]
                if hand then
                    local hand_id = type(hand) == "table" and hand.id or hand
                    if hand_id == obj.id then
                        ctx.player.hands[i] = nil
                        break
                    end
                end
            end
        end
    end
    handlers["treat"] = handlers["apply"]

    -- #39: "wait" — pass a turn without acting (BUG-131)
    -- Post-command injury tick and time advance happen automatically in the loop.
    handlers["wait"] = function(ctx, noun)
        print("Time passes.")
    end
    handlers["pass"] = handlers["wait"]

    -- #39/#37: "appearance" — show player appearance description (BUG-131/BUG-129)
    handlers["appearance"] = function(ctx, noun)
        local app_ok, app_mod = pcall(require, "engine.player.appearance")
        if app_ok and app_mod then
            print(app_mod.describe(ctx.player, ctx.registry))
        else
            print("You can't see yourself without a mirror.")
        end
    end
end

return M
