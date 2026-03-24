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
        -- Strip common prepositions
        local clean = direction:lower()
            :gsub("^through%s+", "")
            :gsub("^to%s+the%s+", "")
            :gsub("^to%s+", "")
            :gsub("^into%s+", "")
            :gsub("^towards?%s+", "")
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
            ctx.player.location = prev_id
            ctx.current_room = prev_room
            ctx.visited_rooms = ctx.visited_rooms or {}
            ctx.visited_rooms[prev_id] = true
            print("")
            print("You retrace your steps.")
            print("**" .. (prev_room.name or "Unnamed room") .. "**")
            if prev_room.short_description then
                print(prev_room.short_description)
            end
            return
        end

        -- Resolve direction alias
        local dir = DIRECTION_ALIASES[clean]

        -- If not a known direction, search exits by keyword
        if not dir then
            local room = ctx.current_room
            for d, exit in pairs(room.exits or {}) do
                if type(exit) == "table" and exit_matches(exit, d, clean) then
                    dir = d
                    break
                end
            end
        end
        if not dir then
            print("You can't go that way.")
            return
        end

        local room = ctx.current_room
        local exit = room.exits and room.exits[dir]
        if not exit then
            print("You can't go that way.")
            return
        end

        if type(exit) == "table" then
            if exit.hidden then
                print("You can't go that way.")
                return
            end
            if not exit.open then
                if exit.locked then
                    print((exit.name or "The way") .. " is locked.")
                else
                    print((exit.name or "The exit") .. " is closed.")
                end
                return
            end
        end

        local target_id = type(exit) == "table" and exit.target or exit
        local target_room = ctx.rooms and ctx.rooms[target_id]
        if not target_room then
            print("That way leads somewhere you cannot yet reach.")
            return
        end

        -- Fire on_traverse exit effects BEFORE moving the player
        traverse_effects.process(exit, ctx)

        -- Tier 4: record current room before moving (for "go back")
        if context_window and ctx.current_room then
            context_window.set_previous_room(ctx.current_room.id)
        end

        -- Move player
        ctx.player.location = target_id
        ctx.current_room = target_room

        -- Track visited rooms for short-description-on-revisit
        ctx.visited_rooms = ctx.visited_rooms or {}
        local first_visit = not ctx.visited_rooms[target_id]
        ctx.visited_rooms[target_id] = true

        -- Print arrival
        print("")
        if target_room.on_enter then
            print(target_room.on_enter(target_room))
        else
            print("You arrive at " .. (target_room.name or "a new area") .. ".")
        end

        -- First visit: full auto-look; revisit: short description only
        if first_visit then
            ctx.verbs["look"](ctx, "")
        else
            print("**" .. (target_room.name or "Unnamed room") .. "**")
            if target_room.short_description then
                print(target_room.short_description)
            end
        end
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
end

return M
