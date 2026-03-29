-- engine/verbs/movement.lua
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
local spawn_objects = H.spawn_objects
local perform_mutation = H.perform_mutation
local inventory_weight = H.inventory_weight
local move_spatial_object = H.move_spatial_object
local find_portal_by_keyword = H.find_portal_by_keyword
local sync_bidirectional_portal = H.sync_bidirectional_portal
local find_exit_by_keyword = H.find_exit_by_keyword

local get_game_time = H.get_game_time
local is_daytime = H.is_daytime
local format_time = H.format_time
local time_of_day_desc = H.time_of_day_desc
local get_light_level = H.get_light_level
local has_some_light = H.has_some_light
local vision_blocked_by_worn = H.vision_blocked_by_worn

-- Creature stimulus emission (guarded — module may not be loaded)
local function emit_player_enters(room_id)
    local ok, creatures = pcall(require, "engine.creatures")
    if ok and creatures and creatures.emit_stimulus then
        creatures.emit_stimulus(room_id, "player_enters", { source = "player" })
    end
end

local M = {}

function M.register(handlers)
    -- MOVEMENT -- direction commands, go, enter, descend, ascend, climb
    ---------------------------------------------------------------------------
    local DIRECTION_ALIASES = {
        n = "north", s = "south", e = "east", w = "west",
        u = "up",    d = "down",
        north = "north", south = "south", east = "east", west = "west",
        up = "up", down = "down",
        upstairs = "up", downstairs = "down",
        above = "up", below = "down",
    }

    local function handle_movement(ctx, direction)
        -- WAVE-3: Stress movement_penalty — chance of stumbling when stressed
        local inj_ok, inj_mod = pcall(require, "engine.injuries")
        if inj_ok and inj_mod and inj_mod.get_stress_effects then
            local effects = inj_mod.get_stress_effects(ctx.player)
            local penalty = effects.movement_penalty or 0
            if penalty > 0 and math.random() < penalty then
                print("Your legs buckle under the weight of panic. You can't move.")
                return
            end
        end

        -- Strip common prepositions
        local clean = direction:lower()
            :gsub("^through%s+", "")
            :gsub("^to%s+the%s+", "")
            :gsub("^to%s+", "")
            :gsub("^into%s+", "")
            :gsub("^towards?%s+", "")
            :gsub("^out%s+of%s+", "")
            :gsub("^out%s+", "")
        if clean == "" then
            print("Go where?")
            return
        end

        -- Tier 4: "go back" → return to previous room
        if clean == "back" or clean == "back to where i was" then
            if not context_window then
                print("You can't go back — you haven't been anywhere else.")
                return
            end
            local prev_id = context_window.get_previous_room()
            if not prev_id then
                print("You can't go back — you haven't been anywhere else.")
                return
            end
            local prev_room = ctx.rooms and ctx.rooms[prev_id]
            if not prev_room then
                print("You can't go back — that place is no longer accessible.")
                return
            end
            -- Record current room as previous before moving
            if context_window and ctx.current_room then
                context_window.set_previous_room(ctx.current_room.id)
            end
            -- on_exit_room hook: fire before leaving current room
            if ctx.current_room.on_exit_room and type(ctx.current_room.on_exit_room) == "function" then
                ctx.current_room.on_exit_room(ctx.current_room, ctx)
            end
            if ctx.current_room.event_output and ctx.current_room.event_output["on_exit_room"] then
                print(ctx.current_room.event_output["on_exit_room"])
                ctx.current_room.event_output["on_exit_room"] = nil
            end
            -- Sound: exit old room (stop ambients before transition text)
            if ctx.sound_manager then ctx.sound_manager:exit_room(ctx.current_room) end
            ctx.player.location = prev_id
            ctx.current_room = prev_room
            ctx.player.visited_rooms = ctx.player.visited_rooms or {}
            ctx.player.visited_rooms[prev_id] = true
            -- on_enter_room hook: fire after entering new room
            if prev_room.on_enter_room and type(prev_room.on_enter_room) == "function" then
                prev_room.on_enter_room(prev_room, ctx)
            end
            if prev_room.event_output and prev_room.event_output["on_enter_room"] then
                print(prev_room.event_output["on_enter_room"])
                prev_room.event_output["on_enter_room"] = nil
            end
            emit_player_enters(prev_id)
            print("")
            print("You retrace your steps.")
            print("**" .. (prev_room.name or "Unnamed room") .. "**")
            if prev_room.short_description then
                print(prev_room.short_description)
            end
            -- Sound: enter new room (start ambients after text)
            if ctx.sound_manager then ctx.sound_manager:enter_room(prev_room) end
            return
        end

        -- Resolve direction alias
        local dir = DIRECTION_ALIASES[clean]

        -- If not a known direction, try portal keyword
        if not dir then
            local room = ctx.current_room
            local portal = find_portal_by_keyword(ctx, clean)
            if portal and portal.portal and portal.portal.direction_hint then
                dir = portal.portal.direction_hint
            end
        end
        -- If still not a direction, try exit keyword match
        if not dir then
            local exit_match, exit_dir = find_exit_by_keyword(ctx, clean)
            if exit_match then
                dir = exit_dir
            end
        end
        if not dir then
            print("You can't go that way.")
            return
        end

        local room = ctx.current_room
        local exit = room.exits and room.exits[dir]

        -----------------------------------------------------------------
        -- Portal resolution path (D-PORTAL-ARCHITECTURE)
        -- 1. Thin exit reference: exit.portal points to a portal object ID
        -- 2. Direct search: find portal in room by direction_hint
        -- Falls through to legacy exit handling if no portal found
        -----------------------------------------------------------------
        local portal_obj = nil

        -- Thin reference: exit = { portal = "some-portal-id" }
        if exit and type(exit) == "table" and exit.portal then
            portal_obj = ctx.registry:get(exit.portal)
        end

        -- Fallback: search room for portal with matching direction_hint
        if not portal_obj then
            portal_obj = find_portal_by_keyword(ctx, dir)
        end

        if portal_obj and portal_obj.portal then
            local state = portal_obj.states and portal_obj.states[portal_obj._state]
            if not state or not state.traversable then
                if state and state.blocked_message then
                    print(state.blocked_message)
                elseif portal_obj._state == "locked" then
                    print((portal_obj.name or "The way") .. " is locked.")
                elseif portal_obj._state == "barred" then
                    print((portal_obj.name or "The way") .. " is barred.")
                elseif portal_obj._state == "closed" or portal_obj._state == "unbarred" then
                    print((portal_obj.name or "The way") .. " is closed.")
                else
                    print((portal_obj.name or "The way") .. " blocks your path.")
                end
                return
            end

            local target_id = portal_obj.portal.target
            local target_room = ctx.rooms and ctx.rooms[target_id]
            if not target_room then
                print("That way leads somewhere you cannot yet reach.")
                return
            end

            -- Fire on_traverse effects from the portal object
            if portal_obj.on_traverse then
                traverse_effects.process(portal_obj, ctx)
            end

            -- on_exit_room hook
            local old_room = ctx.current_room
            if old_room.on_exit_room and type(old_room.on_exit_room) == "function" then
                old_room.on_exit_room(old_room, ctx)
            end
            if old_room.event_output and old_room.event_output["on_exit_room"] then
                print(old_room.event_output["on_exit_room"])
                old_room.event_output["on_exit_room"] = nil
            end
            -- Sound: exit old room
            if ctx.sound_manager then ctx.sound_manager:exit_room(old_room) end

            -- Record previous room for "go back"
            if context_window and ctx.current_room then
                context_window.set_previous_room(ctx.current_room.id)
            end

            -- Move player
            ctx.player.location = target_id
            ctx.current_room = target_room

            ctx.player.visited_rooms = ctx.player.visited_rooms or {}
            local first_visit = not ctx.player.visited_rooms[target_id]
            ctx.player.visited_rooms[target_id] = true

            -- on_enter_room hook
            if target_room.on_enter_room and type(target_room.on_enter_room) == "function" then
                target_room.on_enter_room(target_room, ctx)
            end
            if target_room.event_output and target_room.event_output["on_enter_room"] then
                print(target_room.event_output["on_enter_room"])
                target_room.event_output["on_enter_room"] = nil
            end

            emit_player_enters(target_id)

            -- Print arrival
            print("")
            if target_room.on_enter then
                print(target_room.on_enter(target_room))
            else
                print("You arrive at " .. (target_room.name or "a new area") .. ".")
            end

            if first_visit then
                ctx.verbs["look"](ctx, "")
            else
                print("**" .. (target_room.name or "Unnamed room") .. "**")
                if target_room.short_description then
                    print(target_room.short_description)
                end
            end
            -- Sound: enter new room (start ambients after text)
            if ctx.sound_manager then ctx.sound_manager:enter_room(target_room) end
            return
        end

        -----------------------------------------------------------------
        -- Legacy exit handling (non-portal exits in room.exits)
        -----------------------------------------------------------------
        if exit and type(exit) == "table" and not exit.portal then
            -- Hidden exits are not traversable
            if exit.hidden then
                print("You can't go that way.")
                return
            end
            -- Locked exits
            if exit.locked then
                print((exit.name or ("The way " .. dir)) .. " is locked.")
                return
            end
            -- Closed exits
            if exit.open == false then
                print((exit.name or ("The way " .. dir)) .. " is closed.")
                return
            end

            local target_id = exit.target
            local target_room = ctx.rooms and ctx.rooms[target_id]
            if not target_room then
                print("That way leads somewhere you cannot yet reach.")
                return
            end

            -- Fire traverse effects
            if exit.on_traverse and traverse_effects then
                traverse_effects.process(exit, ctx)
            end

            -- on_exit_room hook
            local old_room = ctx.current_room
            if old_room.on_exit_room and type(old_room.on_exit_room) == "function" then
                old_room.on_exit_room(old_room, ctx)
            end
            if old_room.event_output and old_room.event_output["on_exit_room"] then
                print(old_room.event_output["on_exit_room"])
                old_room.event_output["on_exit_room"] = nil
            end
            -- Sound: exit old room
            if ctx.sound_manager then ctx.sound_manager:exit_room(old_room) end

            -- Record previous room for "go back"
            if context_window and ctx.current_room then
                context_window.set_previous_room(ctx.current_room.id)
            end

            -- Move player
            ctx.player.location = target_id
            ctx.current_room = target_room

            ctx.player.visited_rooms = ctx.player.visited_rooms or {}
            local first_visit = not ctx.player.visited_rooms[target_id]
            ctx.player.visited_rooms[target_id] = true

            -- on_enter_room hook
            if target_room.on_enter_room and type(target_room.on_enter_room) == "function" then
                target_room.on_enter_room(target_room, ctx)
            end
            if target_room.event_output and target_room.event_output["on_enter_room"] then
                print(target_room.event_output["on_enter_room"])
                target_room.event_output["on_enter_room"] = nil
            end

            emit_player_enters(target_id)

            -- Print arrival
            print("")
            if first_visit then
                if ctx.verbs and ctx.verbs["look"] then
                    ctx.verbs["look"](ctx, "")
                else
                    print("**" .. (target_room.name or "Unnamed room") .. "**")
                    if target_room.description then
                        print(target_room.description)
                    end
                end
            else
                print("**" .. (target_room.name or "Unnamed room") .. "**")
                if target_room.short_description then
                    print(target_room.short_description)
                end
            end
            -- Sound: enter new room (start ambients after text)
            if ctx.sound_manager then ctx.sound_manager:enter_room(target_room) end
            return
        end

        -- No portal found for this direction
        print("You can't go that way.")
    end

    -- Cardinal and vertical directions
    for _, dir in ipairs({"north", "south", "east", "west", "up", "down"}) do
        handlers[dir] = function(ctx, noun) handle_movement(ctx, dir) end
    end
    handlers["n"] = handlers["north"]
    handlers["s"] = handlers["south"]
    handlers["e"] = handlers["east"]
    handlers["w"] = handlers["west"]
    handlers["u"] = handlers["up"]
    handlers["d"] = handlers["down"]

    -- GO {direction}
    handlers["go"] = function(ctx, noun)
        if noun == "" then
            print("Go where?")
            return
        end
        handle_movement(ctx, noun)
    end
    handlers["walk"]   = handlers["go"]
    handlers["run"]    = handlers["go"]
    handlers["head"]   = handlers["go"]
    handlers["travel"] = handlers["go"]
    handlers["leave"]  = handlers["go"]
    handlers["exit"]   = handlers["go"]

    -- BUG-124 (#32): "move" must disambiguate between navigation and object interaction.
    -- If the noun is a direction, treat as "go"; otherwise delegate to the spatial move handler.
    local _move_object = handlers["move"]  -- spatial handler defined earlier (line ~2617)
    handlers["move"] = function(ctx, noun)
        if noun == "" then print("Move what?") return end
        local clean = noun:lower()
            :gsub("^through%s+", "")
            :gsub("^to%s+the%s+", "")
            :gsub("^to%s+", "")
            :gsub("^into%s+", "")
            :gsub("^towards?%s+", "")
            :gsub("^out%s+of%s+", "")
            :gsub("^out%s+", "")
        if DIRECTION_ALIASES[clean] or clean == "back" then
            handle_movement(ctx, noun)
        else
            _move_object(ctx, noun)
        end
    end

    -- Tier 4: "back" and "return" as standalone verbs
    handlers["back"] = function(ctx, noun)
        handle_movement(ctx, "back")
    end
    handlers["return"] = function(ctx, noun)
        if noun == "" then
            handle_movement(ctx, "back")
        else
            handle_movement(ctx, noun)
        end
    end

    -- ENTER {thing} -- move through an exit matched by keyword
    handlers["enter"] = function(ctx, noun)
        if noun == "" then
            print("Enter what?")
            return
        end
        handle_movement(ctx, noun)
    end

    -- DESCEND / ASCEND / CLIMB
    handlers["descend"] = function(ctx, noun) handle_movement(ctx, "down") end
    handlers["ascend"]  = function(ctx, noun) handle_movement(ctx, "up") end
    handlers["climb"]   = function(ctx, noun)
        local n = (noun or ""):lower()
        if n == "down" or n == "downstairs" or n:match("down%s+") then
            handle_movement(ctx, "down")
        elseif n == "up" or n == "upstairs" or n:match("up%s+") or n == "" then
            handle_movement(ctx, "up")
        else
            handle_movement(ctx, noun)
        end
    end

    ---------------------------------------------------------------------------
    -- TELEPORT {room-id} — admin/debug teleport command (#368)
    ---------------------------------------------------------------------------
    handlers["teleport"] = function(ctx, noun)
        if not noun or noun == "" then
            print("Teleport where? Usage: teleport <room-name>")
            return
        end

        local target_id = noun:lower():gsub("^%s+", ""):gsub("%s+$", "")
        local target_room = ctx.rooms and ctx.rooms[target_id]

        -- #287: Fall back to keyword/name search across all rooms
        if not target_room and ctx.rooms then
            for rid, room in pairs(ctx.rooms) do
                local rname = (room.name or ""):lower()
                if rname == target_id or rname:find(target_id, 1, true) then
                    target_id = rid
                    target_room = room
                    break
                end
                if room.keywords then
                    for _, kw in ipairs(room.keywords) do
                        if kw:lower() == target_id then
                            target_id = rid
                            target_room = room
                            break
                        end
                    end
                    if target_room then break end
                end
            end
        end

        if not target_room then
            print("No room called '" .. noun .. "' exists.")
            return
        end

        -- Record previous room for "go back"
        if context_window and ctx.current_room then
            context_window.set_previous_room(ctx.current_room.id)
        end

        -- on_exit_room hook
        if ctx.current_room and ctx.current_room.on_exit_room
           and type(ctx.current_room.on_exit_room) == "function" then
            ctx.current_room.on_exit_room(ctx.current_room, ctx)
        end
        if ctx.current_room and ctx.current_room.event_output
           and ctx.current_room.event_output["on_exit_room"] then
            print(ctx.current_room.event_output["on_exit_room"])
            ctx.current_room.event_output["on_exit_room"] = nil
        end
        -- Sound: exit old room
        if ctx.sound_manager then ctx.sound_manager:exit_room(ctx.current_room) end

        -- Move player
        ctx.player.location = target_id
        ctx.current_room = target_room

        ctx.player.visited_rooms = ctx.player.visited_rooms or {}
        local first_visit = not ctx.player.visited_rooms[target_id]
        ctx.player.visited_rooms[target_id] = true

        -- on_enter_room hook
        if target_room.on_enter_room and type(target_room.on_enter_room) == "function" then
            target_room.on_enter_room(target_room, ctx)
        end
        if target_room.event_output and target_room.event_output["on_enter_room"] then
            print(target_room.event_output["on_enter_room"])
            target_room.event_output["on_enter_room"] = nil
        end

        emit_player_enters(target_id)

        print("You materialize in " .. (target_room.name or target_id) .. ".")
        if first_visit then
            ctx.verbs["look"](ctx, "")
        else
            print("**" .. (target_room.name or "Unnamed room") .. "**")
            if target_room.short_description then
                print(target_room.short_description)
            end
        end
        -- Sound: enter new room (start ambients after text)
        if ctx.sound_manager then ctx.sound_manager:enter_room(target_room) end
    end
    handlers["goto"] = handlers["teleport"]

    ---------------------------------------------------------------------------
    -- EXITS — list available exits from the current room (#318)
    ---------------------------------------------------------------------------
    handlers["exits"] = function(ctx, noun)
        local room = ctx.current_room
        local exit_lines = {}
        for dir, exit in pairs(room.exits or {}) do
            local e = type(exit) == "string"
                and { name = dir, hidden = false }
                or exit
            if not e.hidden then
                local state = ""
                if e.open == false and e.locked then
                    state = " (locked)"
                elseif e.open == false then
                    state = " (closed)"
                end
                exit_lines[#exit_lines + 1] =
                    "  " .. dir .. ": " .. (e.name or dir) .. state
            end
        end
        if #exit_lines > 0 then
            table.sort(exit_lines)
            print("Exits:")
            print(table.concat(exit_lines, "\n"))
        else
            print("There are no visible exits.")
        end
    end
end

return M
