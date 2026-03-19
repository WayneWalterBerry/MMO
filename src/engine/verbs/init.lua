-- engine/verbs/init.lua
-- V1 verb handlers for the bedroom REPL.
-- Each handler has signature: function(context, noun)
-- Context is injected by the game loop at dispatch time.

local verbs = {}

local fsm_mod = require("engine.fsm")

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------
local GAME_SECONDS_PER_REAL_SECOND = 24
local GAME_START_HOUR = 2
local DAYTIME_START = 6
local DAYTIME_END = 18

---------------------------------------------------------------------------
-- Helper: keyword matching
---------------------------------------------------------------------------
local function matches_keyword(obj, kw)
    if not obj then return false end
    kw = kw:lower()
    if obj.id and obj.id:lower() == kw then return true end
    -- Exact keyword match first (highest priority)
    if type(obj.keywords) == "table" then
        for _, k in ipairs(obj.keywords) do
            if k:lower() == kw then return true end
        end
    end
    -- Word-boundary match on name (avoids "match" matching "matchbox")
    if obj.name then
        local padded = " " .. obj.name:lower() .. " "
        if padded:find(" " .. kw .. " ", 1, true) then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- Hand inventory helpers
---------------------------------------------------------------------------
local function hands_full(ctx)
    return ctx.player.hands[1] ~= nil and ctx.player.hands[2] ~= nil
end

local function first_empty_hand(ctx)
    if ctx.player.hands[1] == nil then return 1 end
    if ctx.player.hands[2] == nil then return 2 end
    return nil
end

local function which_hand(ctx, obj_id)
    if ctx.player.hands[1] == obj_id then return 1 end
    if ctx.player.hands[2] == obj_id then return 2 end
    return nil
end

-- Returns flat list of all object IDs the player is carrying
-- (hands + held bag contents + worn items + worn bag contents)
local function get_all_carried_ids(ctx)
    local ids = {}
    local reg = ctx.registry
    for i = 1, 2 do
        local hand_id = ctx.player.hands[i]
        if hand_id then
            ids[#ids + 1] = hand_id
            local obj = reg:get(hand_id)
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
-- Helper: find an object the player can see or reach
-- Returns: obj, location_type, parent_obj, surface_name
--   location_type: "room" | "surface" | "hand" | "bag" | "worn"
---------------------------------------------------------------------------
local function find_visible(ctx, keyword)
    if not keyword or keyword == "" then return nil end
    local room = ctx.current_room
    local reg = ctx.registry
    local kw = keyword:lower()
        :gsub("^the%s+", "")
        :gsub("^a%s+", "")
        :gsub("^an%s+", "")

    -- 1. Room contents
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = reg:get(obj_id)
        if obj and not obj.hidden and matches_keyword(obj, kw) then
            return obj, "room", nil, nil
        end
    end

    -- 2. Accessible surface contents of room objects
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = reg:get(obj_id)
        if obj and obj.surfaces then
            for sname, zone in pairs(obj.surfaces) do
                if zone.accessible ~= false then
                    for _, item_id in ipairs(zone.contents or {}) do
                        local item = reg:get(item_id)
                        if item and matches_keyword(item, kw) then
                            return item, "surface", obj, sname
                        end
                    end
                end
            end
        end
        -- Also search non-surface container contents (if accessible)
        if obj and not obj.surfaces and obj.container and obj.contents
            and obj.accessible ~= false then
            for _, item_id in ipairs(obj.contents) do
                local item = reg:get(item_id)
                if item and matches_keyword(item, kw) then
                    return item, "container", obj, nil
                end
            end
        end
    end

    -- 3. Player hands (direct items first, then bag contents)
    for i = 1, 2 do
        local hand_id = ctx.player.hands[i]
        if hand_id then
            local obj = reg:get(hand_id)
            if obj and matches_keyword(obj, kw) then
                return obj, "hand", nil, nil
            end
        end
    end
    for i = 1, 2 do
        local hand_id = ctx.player.hands[i]
        if hand_id then
            local obj = reg:get(hand_id)
            if obj and obj.container and obj.contents then
                for _, item_id in ipairs(obj.contents) do
                    local item = reg:get(item_id)
                    if item and matches_keyword(item, kw) then
                        return item, "bag", obj, nil
                    end
                end
            end
        end
    end

    -- 4. Worn items and worn bag contents
    for _, worn_id in ipairs(ctx.player.worn or {}) do
        local obj = reg:get(worn_id)
        if obj and matches_keyword(obj, kw) then
            return obj, "worn", nil, nil
        end
        if obj and obj.container and obj.contents then
            for _, item_id in ipairs(obj.contents) do
                local item = reg:get(item_id)
                if item and matches_keyword(item, kw) then
                    return item, "bag", obj, nil
                end
            end
        end
    end

    return nil
end

-- Wrap find_visible with pronoun resolution ("it", "one", "that") and
-- last-object tracking for compound command support.
do
    local _find_visible = find_visible
    find_visible = function(ctx, keyword)
        if not keyword or keyword == "" then return nil end
        local kw = keyword:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        if (kw == "it" or kw == "one" or kw == "that") and ctx.last_object then
            return ctx.last_object, ctx.last_object_loc or "room",
                   ctx.last_object_parent, ctx.last_object_surface
        end
        local obj, loc, parent, surface = _find_visible(ctx, keyword)
        if obj then
            ctx.last_object = obj
            ctx.last_object_loc = loc
            ctx.last_object_parent = parent
            ctx.last_object_surface = surface
        end
        return obj, loc, parent, surface
    end
end

---------------------------------------------------------------------------
-- Helper: find object in player's carried items (hands + bags + worn)
---------------------------------------------------------------------------
local function find_in_inventory(ctx, keyword)
    if not keyword or keyword == "" then return nil end
    local kw = keyword:lower()
        :gsub("^the%s+", "")
        :gsub("^a%s+", "")
        :gsub("^an%s+", "")
    local reg = ctx.registry
    -- Hands
    for i = 1, 2 do
        local hand_id = ctx.player.hands[i]
        if hand_id then
            local obj = reg:get(hand_id)
            if obj and matches_keyword(obj, kw) then return obj end
        end
    end
    -- Held bag contents
    for i = 1, 2 do
        local hand_id = ctx.player.hands[i]
        if hand_id then
            local bag = reg:get(hand_id)
            if bag and bag.container and bag.contents then
                for _, item_id in ipairs(bag.contents) do
                    local item = reg:get(item_id)
                    if item and matches_keyword(item, kw) then return item end
                end
            end
        end
    end
    -- Worn items
    for _, worn_id in ipairs(ctx.player.worn or {}) do
        local obj = reg:get(worn_id)
        if obj and matches_keyword(obj, kw) then return obj end
    end
    -- Worn bag contents
    for _, worn_id in ipairs(ctx.player.worn or {}) do
        local bag = reg:get(worn_id)
        if bag and bag.container and bag.contents then
            for _, item_id in ipairs(bag.contents) do
                local item = reg:get(item_id)
                if item and matches_keyword(item, kw) then return item end
            end
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Helper: find a tool in carried items that provides a given capability.
-- Also checks blood as writing instrument when player has bloody state.
---------------------------------------------------------------------------
local function find_tool_in_inventory(ctx, required_capability)
    local reg = ctx.registry
    local all_ids = get_all_carried_ids(ctx)
    for _, obj_id in ipairs(all_ids) do
        local obj = reg:get(obj_id)
        if obj and obj.provides_tool then
            local provides = obj.provides_tool
            if type(provides) == "string" and provides == required_capability then
                return obj
            elseif type(provides) == "table" then
                for _, cap in ipairs(provides) do
                    if cap == required_capability then
                        return obj
                    end
                end
            end
        end
    end
    -- Blood as writing instrument when player is injured
    if required_capability == "writing_instrument" then
        local state = ctx.player.state or {}
        if state.bloody then
            return {
                id = "blood", name = "your blood",
                provides_tool = "writing_instrument",
                _is_blood = true,
                on_tool_use = {
                    consumes_charge = false,
                    use_message = "You press your bleeding finger to the surface, leaving dark crimson marks.",
                },
            }
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Helper: check if an object provides a specific tool capability
---------------------------------------------------------------------------
local function provides_capability(obj, capability)
    if not obj or not obj.provides_tool then return false end
    local provides = obj.provides_tool
    if type(provides) == "string" then return provides == capability end
    if type(provides) == "table" then
        for _, cap in ipairs(provides) do
            if cap == capability then return true end
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Helper: find a tool that is visible (in room/surfaces) but not carried
---------------------------------------------------------------------------
local function find_visible_tool(ctx, required_capability)
    local room = ctx.current_room
    local reg = ctx.registry
    -- Room contents
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = reg:get(obj_id)
        if obj and obj.provides_tool then
            if provides_capability(obj, required_capability) then
                return obj
            end
        end
    end
    -- Surface contents
    for _, obj_id in ipairs(room.contents or {}) do
        local obj = reg:get(obj_id)
        if obj and obj.surfaces then
            for _, zone in pairs(obj.surfaces) do
                if zone.accessible ~= false then
                    for _, item_id in ipairs(zone.contents or {}) do
                        local item = reg:get(item_id)
                        if item and provides_capability(item, required_capability) then
                            return item
                        end
                    end
                end
            end
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Helper: consume a charge from a tool, mutate to depleted if empty
---------------------------------------------------------------------------
local function consume_tool_charge(ctx, tool)
    if not tool or not tool.on_tool_use or not tool.on_tool_use.consumes_charge then
        return
    end
    if not tool.charges then return end
    tool.charges = tool.charges - 1
    if tool.charges <= 0 and tool.on_tool_use.when_depleted then
        if tool.on_tool_use.depleted_message then
            print(tool.on_tool_use.depleted_message)
        end
        local source = ctx.object_sources[tool.on_tool_use.when_depleted]
        if source then
            ctx.mutation.mutate(ctx.registry, ctx.loader, tool.id, source, ctx.templates)
        end
    end
end

---------------------------------------------------------------------------
-- Helper: remove an object from wherever it currently lives
---------------------------------------------------------------------------
local function remove_from_location(ctx, obj)
    local room = ctx.current_room
    local reg = ctx.registry

    -- Player hands
    for i = 1, 2 do
        if ctx.player.hands[i] == obj.id then
            ctx.player.hands[i] = nil
            return true
        end
    end

    -- Bags in player's hands
    for i = 1, 2 do
        local hand_id = ctx.player.hands[i]
        if hand_id then
            local bag = reg:get(hand_id)
            if bag and bag.container and bag.contents then
                for j, item_id in ipairs(bag.contents) do
                    if item_id == obj.id then
                        table.remove(bag.contents, j)
                        return true
                    end
                end
            end
        end
    end

    -- Worn items
    for i, worn_id in ipairs(ctx.player.worn or {}) do
        if worn_id == obj.id then
            table.remove(ctx.player.worn, i)
            return true
        end
    end

    -- Worn bag contents
    for _, worn_id in ipairs(ctx.player.worn or {}) do
        local bag = reg:get(worn_id)
        if bag and bag.container and bag.contents then
            for j, item_id in ipairs(bag.contents) do
                if item_id == obj.id then
                    table.remove(bag.contents, j)
                    return true
                end
            end
        end
    end

    -- Room contents
    for i, id in ipairs(room.contents or {}) do
        if id == obj.id then
            table.remove(room.contents, i)
            return true
        end
    end

    -- Surface contents of room objects
    for _, parent_id in ipairs(room.contents or {}) do
        local parent = reg:get(parent_id)
        if parent and parent.surfaces then
            for _, zone in pairs(parent.surfaces) do
                for i, id in ipairs(zone.contents or {}) do
                    if id == obj.id then
                        table.remove(zone.contents, i)
                        return true
                    end
                end
            end
        end
        -- Non-surface container contents
        if parent and not parent.surfaces and parent.container and parent.contents then
            for i, id in ipairs(parent.contents) do
                if id == obj.id then
                    table.remove(parent.contents, i)
                    return true
                end
            end
        end
    end

    return false
end

---------------------------------------------------------------------------
-- Helper: game time from real clock
---------------------------------------------------------------------------
local function get_game_time(ctx)
    local real_elapsed = os.time() - ctx.game_start_time
    local total_game_hours = (real_elapsed * GAME_SECONDS_PER_REAL_SECOND) / 3600
    local absolute_hour = GAME_START_HOUR + total_game_hours
    local hour = math.floor(absolute_hour % 24)
    local minute = math.floor((absolute_hour * 60) % 60)
    return hour, minute
end

local function is_daytime(ctx)
    local hour = get_game_time(ctx)
    return hour >= DAYTIME_START and hour < DAYTIME_END
end

local function format_time(hour, minute)
    local period = hour >= 12 and "PM" or "AM"
    local display_hour = hour % 12
    if display_hour == 0 then display_hour = 12 end
    return string.format("%d:%02d %s", display_hour, minute, period)
end

local function time_of_day_desc(hour)
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
-- Helper: light system -- tri-state: "lit", "dim", "dark"
--   "lit"  = full light (open curtains + daytime, or artificial light)
--   "dim"  = filtered daylight through closed curtains during daytime
--   "dark" = no light at all (nighttime, no candle)
-- Dim light is enough to see and interact; descriptions note the dimness.
---------------------------------------------------------------------------
local function get_light_level(ctx)
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
                    if item and item.casts_light then return "lit" end
                end
            end
        end
    end
    for _, obj_id in ipairs(get_all_carried_ids(ctx)) do
        local obj = reg:get(obj_id)
        if obj and obj.casts_light then return "lit" end
    end

    -- Daylight: open curtains = "lit", closed curtains = "dim"
    if is_daytime(ctx) then
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

-- Convenience: can the player see enough to interact?
local function has_some_light(ctx)
    return get_light_level(ctx) ~= "dark"
end

---------------------------------------------------------------------------
-- Helper: find a mutation entry on an object for a given verb
-- Checks exact match first, then verb_* patterns (e.g. "break" → "break_mirror")
---------------------------------------------------------------------------
local function find_mutation(obj, verb)
    if not obj or not obj.mutations then return nil end
    if obj.mutations[verb] then return obj.mutations[verb] end
    for key, mut in pairs(obj.mutations) do
        if key:sub(1, #verb + 1) == verb .. "_" then
            return mut
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Helper: match an exit by keyword
---------------------------------------------------------------------------
local function exit_matches(exit, dir, keyword)
    local kw = keyword:lower()
    if dir:lower() == kw then return true end
    if type(exit) ~= "table" then return false end
    if exit.name and exit.name:lower():find(kw, 1, true) then return true end
    if exit.keywords then
        for _, k in ipairs(exit.keywords) do
            if k:lower() == kw or k:lower():find(kw, 1, true) then return true end
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Helper: spawn objects from a mutation's spawns list
---------------------------------------------------------------------------
local function spawn_objects(ctx, spawns)
    local room = ctx.current_room
    for _, spawn_id in ipairs(spawns) do
        local source = ctx.object_sources[spawn_id]
        if source then
            local spawn_obj, err = ctx.loader.load_source(source)
            if spawn_obj then
                spawn_obj, err = ctx.loader.resolve_template(spawn_obj, ctx.templates)
                if spawn_obj then
                    local actual_id = spawn_id
                    if ctx.registry:get(spawn_id) then
                        local n = 2
                        while ctx.registry:get(spawn_id .. "-" .. n) do n = n + 1 end
                        actual_id = spawn_id .. "-" .. n
                    end
                    spawn_obj.location = room.id
                    ctx.registry:register(actual_id, spawn_obj)
                    room.contents[#room.contents + 1] = actual_id
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Helper: perform an object mutation (swap or destroy + spawn)
---------------------------------------------------------------------------
local function perform_mutation(ctx, obj, mut_data)
    if mut_data.becomes then
        local source = ctx.object_sources[mut_data.becomes]
        if not source then
            print("Something strange happens, but nothing changes.")
            return false
        end
        local new_obj, err = ctx.mutation.mutate(
            ctx.registry, ctx.loader, obj.id, source, ctx.templates)
        if not new_obj then
            print("Error: " .. tostring(err))
            return false
        end
    elseif mut_data.spawns then
        -- Destruction: object ceases to exist, spawns replace it
        remove_from_location(ctx, obj)
        ctx.registry:remove(obj.id)
    end

    if mut_data.spawns then
        spawn_objects(ctx, mut_data.spawns)
    end

    return true
end

---------------------------------------------------------------------------
-- Helper: total carried weight (hands + worn)
---------------------------------------------------------------------------
local function inventory_weight(ctx)
    local total = 0
    local reg = ctx.registry
    for _, id in ipairs(get_all_carried_ids(ctx)) do
        local obj = reg:get(id)
        if obj then total = total + (obj.weight or 0) end
    end
    return total
end

---------------------------------------------------------------------------
-- Verb handler creation
---------------------------------------------------------------------------
function verbs.create()
    local handlers = {}

    ---------------------------------------------------------------------------
    -- LOOK (room view) / LOOK AT / LOOK IN / LOOK UNDER / EXAMINE
    ---------------------------------------------------------------------------
    handlers["look"] = function(ctx, noun)
        -- Bare "look" -- show room
        if noun == "" then
            local light = get_light_level(ctx)
            if light == "dark" then
                print(ctx.current_room.name or "Unknown room")
                print("\nIt is too dark to see. You need a light source.")
                print("(Try 'feel' to grope around in the darkness.)")
                local hour, minute = get_game_time(ctx)
                print("\n" .. time_of_day_desc(hour) .. " It is " .. format_time(hour, minute) .. ".")
                return
            end

            local room = ctx.current_room
            local parts = {}

            -- Dim light preamble
            if light == "dim" then
                parts[#parts + 1] = "Dim light seeps through the curtains -- enough to make out shapes, but details are lost in shadow."
            end

            -- Room description (permanent features)
            parts[#parts + 1] = room.description or ""

            -- Object presences
            local presences = {}
            for _, obj_id in ipairs(room.contents or {}) do
                local obj = ctx.registry:get(obj_id)
                if obj and not obj.hidden then
                    presences[#presences + 1] = obj.room_presence
                        or ("There is " .. (obj.name or obj.id) .. " here.")
                end
            end
            if #presences > 0 then
                parts[#parts + 1] = table.concat(presences, " ")
            end

            -- Exits
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
                parts[#parts + 1] = "Exits:\n" .. table.concat(exit_lines, "\n")
            end

            -- Time
            local hour, minute = get_game_time(ctx)
            parts[#parts + 1] = time_of_day_desc(hour) ..
                " It is " .. format_time(hour, minute) .. "."

            print(room.name or "Unnamed room")
            print("")
            print(table.concat(parts, "\n\n"))
            return
        end

        -- "look at X" → examine
        local target = noun:match("^at%s+(.+)")
        if target then
            if not has_some_light(ctx) then
                print("It is too dark to see anything.")
                return
            end
            local obj = find_visible(ctx, target)
            if not obj then
                print("You don't see that here.")
                return
            end
            if obj.on_look then
                print(obj.on_look(obj))
            else
                print(obj.description or "You see nothing special.")
            end
            return
        end

        -- "look in/under/on X" → inspect surface
        local prep, surface_target = noun:match("^(under)%s+(.+)$")
        if not prep then prep, surface_target = noun:match("^(in)%s+(.+)$") end
        if not prep then prep, surface_target = noun:match("^(on)%s+(.+)$") end
        if not prep then prep, surface_target = noun:match("^(behind)%s+(.+)$") end

        if prep and surface_target then
            if not has_some_light(ctx) then
                print("It is too dark to see anything.")
                return
            end
            local obj = find_visible(ctx, surface_target)
            if not obj then
                print("You don't see that here.")
                return
            end
            if obj.surfaces then
                local surface_name =
                    (prep == "under" or prep == "underneath") and "underneath"
                    or (prep == "in" or prep == "inside") and "inside"
                    or (prep == "on" or prep == "top") and "top"
                    or (prep == "behind") and "behind"
                    or nil
                local zone = surface_name and obj.surfaces[surface_name]
                if zone then
                    if zone.accessible == false then
                        print("You can't see " .. prep .. " " .. (obj.name or obj.id) .. " right now.")
                        return
                    end
                    if #(zone.contents or {}) == 0 then
                        print("There is nothing " .. prep .. " " .. (obj.name or obj.id) .. ".")
                    else
                        print("You find " .. prep .. " " .. (obj.name or obj.id) .. ":")
                        for _, id in ipairs(zone.contents) do
                            local item = ctx.registry:get(id)
                            print("  " .. (item and item.name or id))
                        end
                    end
                    return
                end
            end
            -- No matching surface -- fall through to general examine
            if obj.on_look then
                print(obj.on_look(obj))
            else
                print(obj.description or "You see nothing special.")
            end
            return
        end

        -- "look X" → examine (shorthand for "look at X")
        if not has_some_light(ctx) then
            print("It is too dark to see anything.")
            return
        end
        local obj = find_visible(ctx, noun)
        if not obj then
            print("You don't see that here.")
            return
        end
        if obj.on_look then
            print(obj.on_look(obj))
        else
            print(obj.description or "You see nothing special.")
        end
    end

    handlers["examine"] = function(ctx, noun)
        if noun == "" then print("Examine what?") return end
        if has_some_light(ctx) then
            handlers["look"](ctx, "at " .. noun)
        else
            -- Dark: fall back to feel description
            local obj = find_visible(ctx, noun)
            if not obj then
                print("You can't find anything like that in the darkness.")
                return
            end
            if obj.on_feel then
                print("It's too dark to see, but you feel: " .. obj.on_feel)
            elseif obj.touch_description then
                print("It's too dark to see, but you feel: " .. obj.touch_description)
            else
                print("It's too dark to see, and you can't make out much by touch.")
            end
        end
    end
    handlers["x"] = handlers["examine"]
    handlers["find"] = handlers["examine"]
    handlers["check"] = handlers["examine"]
    handlers["inspect"] = handlers["examine"]
    handlers["read"] = function(ctx, noun)
        if noun == "" then print("Read what?") return end
        if not has_some_light(ctx) then
            print("It is too dark to read anything.")
            return
        end
        handlers["look"](ctx, "at " .. noun)
    end
    handlers["search"] = function(ctx, noun)
        if noun == "" then
            handlers["look"](ctx, "")
        else
            handlers["examine"](ctx, noun)
        end
    end

    ---------------------------------------------------------------------------
    -- FEEL / TOUCH / GROPE -- works even in total darkness
    ---------------------------------------------------------------------------
    handlers["feel"] = function(ctx, noun)
        -- Treat "around", "room", "here" the same as bare feel (room sweep)
        local sweep_words = { [""] = true, ["around"] = true, ["room"] = true, ["here"] = true,
                              ["around me"] = true, ["surroundings"] = true }
        if sweep_words[noun] then
            -- Feel around the room
            local room = ctx.current_room
            local found = {}
            for _, obj_id in ipairs(room.contents or {}) do
                local obj = ctx.registry:get(obj_id)
                if obj and not obj.hidden then
                    local desc = obj.name or obj.id
                    found[#found + 1] = desc
                end
            end
            if #found > 0 then
                print("You reach out in the darkness, feeling around you...")
                for _, entry in ipairs(found) do
                    print("  " .. entry)
                end
            else
                print("You feel around but find nothing within reach.")
            end
            return
        end

        -- Handle "feel in/inside {container}" prepositional phrases
        local container_noun = noun:match("^in%s+(.+)") or noun:match("^inside%s+(.+)")
        -- Bare "feel inside" / "feel in" → use last-interacted container
        if not container_noun and (noun == "inside" or noun == "in") then
            if ctx.last_object and (ctx.last_object.surfaces or (ctx.last_object.container and ctx.last_object.contents)) then
                container_noun = ctx.last_object.id
            else
                print("Feel inside what?")
                return
            end
        end
        if container_noun then
            local cobj = find_visible(ctx, container_noun)
            if not cobj then
                print("You can't feel anything like that nearby.")
                return
            end
            local found_anything = false
            -- Check surface contents (e.g., nightstand "inside" zone)
            if cobj.surfaces then
                for zone_name, zone in pairs(cobj.surfaces) do
                    if zone.accessible ~= false and #(zone.contents or {}) > 0 then
                        local items = {}
                        for _, id in ipairs(zone.contents) do
                            local item = ctx.registry:get(id)
                            items[#items + 1] = item and item.name or id
                        end
                        print("Your fingers find " .. zone_name .. ":")
                        for _, item_name in ipairs(items) do
                            print("  " .. item_name)
                        end
                        found_anything = true
                    end
                end
            end
            -- Check simple container contents
            if cobj.container and cobj.contents and #cobj.contents > 0 then
                local items = {}
                for _, id in ipairs(cobj.contents) do
                    local item = ctx.registry:get(id)
                    items[#items + 1] = item and item.name or id
                end
                print("Inside you feel:")
                for _, item_name in ipairs(items) do
                    print("  " .. item_name)
                end
                found_anything = true
            end
            if not found_anything then
                if cobj.surfaces then
                    local any_inaccessible = false
                    for _, zone in pairs(cobj.surfaces) do
                        if zone.accessible == false then any_inaccessible = true; break end
                    end
                    if any_inaccessible then
                        print("You can't reach inside " .. (cobj.name or "that") .. ". It seems closed.")
                    else
                        print("You feel around inside " .. (cobj.name or "that") .. " but find nothing.")
                    end
                else
                    print("You can't feel inside " .. (cobj.name or "that") .. ".")
                end
            end
            return
        end

        local obj = find_visible(ctx, noun)
        if not obj then
            print("You can't feel anything like that nearby.")
            return
        end

        -- Prefer on_feel (rich sensory), fall back to touch_description, then generic
        if obj.on_feel then
            print(obj.on_feel)
        elseif obj.touch_description then
            print(obj.touch_description)
        else
            print("You run your hands over " .. (obj.name or "it") ..
                ". " .. (obj.description or "It feels ordinary."))
        end

        -- Enumerate accessible surface contents by touch
        if obj.surfaces then
            for zone_name, zone in pairs(obj.surfaces) do
                if zone.accessible ~= false and #(zone.contents or {}) > 0 then
                    local items = {}
                    for _, id in ipairs(zone.contents) do
                        local item = ctx.registry:get(id)
                        items[#items + 1] = item and item.name or id
                    end
                    print("Your fingers find " .. zone_name .. ":")
                    for _, item_name in ipairs(items) do
                        print("  " .. item_name)
                    end
                end
            end
        end

        -- Enumerate simple container contents by touch
        if obj.container and obj.contents and #obj.contents > 0 then
            local items = {}
            for _, id in ipairs(obj.contents) do
                local item = ctx.registry:get(id)
                items[#items + 1] = item and item.name or id
            end
            print("Inside you feel:")
            for _, item_name in ipairs(items) do
                print("  " .. item_name)
            end
        end
    end
    handlers["touch"] = handlers["feel"]
    handlers["grope"] = handlers["feel"]

    ---------------------------------------------------------------------------
    -- SMELL / SNIFF -- works in darkness AND light
    ---------------------------------------------------------------------------
    handlers["smell"] = function(ctx, noun)
        if noun == "" then
            -- Ambient room smell
            local room = ctx.current_room
            if room.on_smell then
                print("You smell the air around you.")
                print(room.on_smell)
            else
                print("You smell the air around you. Dust and stillness.")
            end
            return
        end

        local obj = find_visible(ctx, noun)
        if not obj then
            print("You can't find anything like that to smell.")
            return
        end

        if obj.on_smell then
            print(obj.on_smell)
        else
            print("You don't smell anything distinctive.")
        end
    end
    handlers["sniff"] = handlers["smell"]

    ---------------------------------------------------------------------------
    -- TASTE / LICK -- works in darkness AND light (DANGEROUS)
    ---------------------------------------------------------------------------
    handlers["taste"] = function(ctx, noun)
        if noun == "" then
            print("You're not going to lick the floor... are you?")
            return
        end

        local obj = find_visible(ctx, noun)
        if not obj then
            print("You can't find anything like that to taste.")
            return
        end

        if obj.on_taste then
            print(obj.on_taste)
        else
            print("You give " .. (obj.name or "it") .. " a cautious lick. Nothing remarkable.")
        end

        -- Check for taste effects AFTER printing the taste description
        if obj.on_taste_effect then
            if obj.on_taste_effect == "poison" then
                print("")
                print("Fire courses through your veins. Your throat constricts.")
                print("The world tilts. Your knees buckle.")
                print("A spreading numbness crawls from your stomach to your fingertips.")
                print("")
                print("You collapse to the floor. The darkness -- already absolute -- becomes eternal.")
                print("")
                print("*** YOU HAVE DIED ***")
                ctx.player.state = ctx.player.state or {}
                ctx.player.state.poisoned = true
                ctx.player.state.dead = true
                os.exit(0)
            elseif obj.on_taste_effect == "nausea" then
                print("")
                print("Your stomach lurches. A wave of nausea washes over you.")
                print("You retch, gasping. The taste lingers, foul and insistent.")
                ctx.player.state = ctx.player.state or {}
                ctx.player.state.nauseated = true
            end
        end
    end
    handlers["lick"] = handlers["taste"]

    ---------------------------------------------------------------------------
    -- LISTEN / HEAR -- works in darkness AND light
    ---------------------------------------------------------------------------
    handlers["listen"] = function(ctx, noun)
        if noun == "" then
            -- Ambient room sounds
            local room = ctx.current_room
            if room.on_listen then
                print(room.on_listen)
            else
                print("You hold your breath and listen. Silence -- save for your own heartbeat.")
            end
            return
        end

        -- "listen to X"
        local target = noun:match("^to%s+(.+)") or noun

        local obj = find_visible(ctx, target)
        if not obj then
            print("You can't hear anything like that.")
            return
        end

        if obj.on_listen then
            print(obj.on_listen)
        else
            print("You listen closely. " .. (obj.name or "It") .. " makes no sound.")
        end
    end
    handlers["hear"] = handlers["listen"]

    ---------------------------------------------------------------------------
    -- TAKE / GET / PICK UP / GET X FROM Y
    ---------------------------------------------------------------------------
    handlers["take"] = function(ctx, noun)
        if noun == "" then print("Take what?") return end

        -- "pick up X"
        local target = noun:match("^up%s+(.+)") or noun

        -- "get X from Y" -- extract from a bag/container the player holds
        local from_item, from_container = target:match("^(.+)%s+from%s+(.+)$")
        if from_item then
            local bag = find_in_inventory(ctx, from_container)
            if not bag then
                print("You don't have " .. from_container .. ".")
                return
            end
            if not bag.container or not bag.contents then
                print((bag.name or "That") .. " is not a container.")
                return
            end
            local kw = from_item:lower()
                :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
            local found_idx, found_id
            for i, item_id in ipairs(bag.contents) do
                local item = ctx.registry:get(item_id)
                if item and matches_keyword(item, kw) then
                    found_idx = i
                    found_id = item_id
                    break
                end
            end
            if not found_id then
                print("There is no " .. from_item .. " in " .. (bag.name or "that") .. ".")
                return
            end
            local slot = first_empty_hand(ctx)
            if not slot then
                print("Your hands are full. Drop something first.")
                return
            end
            table.remove(bag.contents, found_idx)
            ctx.player.hands[slot] = found_id
            local item = ctx.registry:get(found_id)
            item.location = "player"
            print("You take " .. (item and item.name or found_id) .. " from " .. (bag.name or "the container") .. ".")
            return
        end

        local obj, where, parent, sname = find_visible(ctx, target)
        if not obj then
            print("You don't see that here.")
            return
        end

        if where == "hand" or where == "worn" then
            print("You already have that.")
            return
        end

        -- "bag" means item is inside a container the player is holding.
        -- Allow extracting it to a free hand (e.g., pulling a match from a matchbox).
        if where == "bag" and parent then
            if not obj.portable then
                print("You can't carry " .. (obj.name or "that") .. ".")
                return
            end
            local slot = first_empty_hand(ctx)
            if not slot then
                print("Your hands are full. Drop something first.")
                return
            end
            if parent.contents then
                for i, cid in ipairs(parent.contents) do
                    if cid == obj.id then
                        table.remove(parent.contents, i)
                        break
                    end
                end
            end
            ctx.player.hands[slot] = obj.id
            obj.location = "player"
            print("You take " .. (obj.name or obj.id) .. " from " .. (parent.name or "the container") .. ".")
            return
        end

        if not obj.portable then
            print("You can't carry " .. (obj.name or "that") .. ".")
            return
        end

        local slot = first_empty_hand(ctx)
        if not slot then
            print("Your hands are full. Drop something first.")
            return
        end

        remove_from_location(ctx, obj)
        ctx.player.hands[slot] = obj.id
        obj.location = "player"

        print("You take " .. (obj.name or obj.id) .. ".")
    end

    handlers["get"] = function(ctx, noun)
        -- "get X from Y" and regular get both go through take
        handlers["take"](ctx, noun)
    end
    handlers["pick"] = function(ctx, noun)
        -- "pick lock" → lockpicking (stub)
        if noun:match("^lock") then
            print("You don't know how to pick locks.")
            return
        end
        -- Otherwise fall through to take ("pick up X", "pick X")
        handlers["take"](ctx, noun)
    end
    handlers["grab"] = handlers["take"]

    ---------------------------------------------------------------------------
    -- DROP
    ---------------------------------------------------------------------------
    handlers["drop"] = function(ctx, noun)
        if noun == "" then print("Drop what?") return end

        -- Only drop items directly in hands (not bag contents or worn)
        local obj = nil
        local hand_slot = nil
        local kw = noun:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        for i = 1, 2 do
            local hand_id = ctx.player.hands[i]
            if hand_id then
                local candidate = ctx.registry:get(hand_id)
                if candidate and matches_keyword(candidate, kw) then
                    obj = candidate
                    hand_slot = i
                    break
                end
            end
        end

        if not obj then
            -- Check if it's in a bag -- give a helpful message
            local bag_item = find_in_inventory(ctx, noun)
            if bag_item then
                print("You'll need to get that out of the bag first, or drop the bag itself.")
            else
                print("You aren't holding that.")
            end
            return
        end

        ctx.player.hands[hand_slot] = nil
        ctx.current_room.contents[#ctx.current_room.contents + 1] = obj.id
        obj.location = ctx.current_room.id

        print("You drop " .. (obj.name or obj.id) .. ".")
    end

    ---------------------------------------------------------------------------
    -- OPEN
    ---------------------------------------------------------------------------
    handlers["open"] = function(ctx, noun)
        if noun == "" then print("Open what?") return end

        -- Check room objects first
        local obj = find_visible(ctx, noun)
        if obj then
            -- FSM path: object managed by FSM engine
            if obj._fsm_id then
                local transitions = fsm_mod.get_transitions(obj)
                local target_state
                for _, t in ipairs(transitions) do
                    if t.verb == "open" then target_state = t.to; break end
                end
                if target_state then
                    local trans, err = fsm_mod.transition(ctx.registry, obj.id, target_state, {})
                    if trans then
                        print(trans.message or ("You open " .. (obj.name or obj.id) .. "."))
                    else
                        print("You can't open " .. (obj.name or "that") .. ".")
                    end
                else
                    if obj._state == "open" then
                        print("It is already open.")
                    else
                        print("You can't open " .. (obj.name or "that") .. ".")
                    end
                end
                return
            end

            local mut_data = find_mutation(obj, "open")
            if mut_data then
                if perform_mutation(ctx, obj, mut_data) then
                    local mutated = ctx.registry:get(obj.id)
                    print(mut_data.message
                        or ("You open " .. (mutated and mutated.name or obj.id) .. "."))
                end
                return
            end
        end

        -- Check exits (doors, etc.)
        local room = ctx.current_room
        for dir, exit in pairs(room.exits or {}) do
            if type(exit) == "table" and exit_matches(exit, dir, noun) then
                if not exit.mutations or not exit.mutations.open then
                    -- Already open or not openable
                    if exit.open then
                        print("It is already open.")
                    else
                        print("You can't open that.")
                    end
                    return
                end
                if exit.open then
                    print("It is already open.")
                    return
                end
                if exit.locked then
                    print("It is locked.")
                    return
                end
                local mut = exit.mutations.open
                if mut.condition and not mut.condition(exit) then
                    print("You can't open that right now.")
                    return
                end
                if mut.becomes_exit then
                    for k, v in pairs(mut.becomes_exit) do
                        exit[k] = v
                    end
                end
                print(mut.message or "You open it.")
                return
            end
        end

        if obj then
            print("You can't open " .. (obj.name or "that") .. ".")
        else
            print("You don't see that here.")
        end
    end

    ---------------------------------------------------------------------------
    -- CLOSE
    ---------------------------------------------------------------------------
    handlers["close"] = function(ctx, noun)
        if noun == "" then print("Close what?") return end

        -- Check room objects first
        local obj = find_visible(ctx, noun)
        if obj then
            -- FSM path
            if obj._fsm_id then
                local transitions = fsm_mod.get_transitions(obj)
                local target_state
                for _, t in ipairs(transitions) do
                    if t.verb == "close" then target_state = t.to; break end
                end
                if target_state then
                    local trans, err = fsm_mod.transition(ctx.registry, obj.id, target_state, {})
                    if trans then
                        print(trans.message or ("You close " .. (obj.name or obj.id) .. "."))
                    else
                        print("You can't close " .. (obj.name or "that") .. ".")
                    end
                else
                    if obj._state == "closed" then
                        print("It is already closed.")
                    else
                        print("You can't close " .. (obj.name or "that") .. ".")
                    end
                end
                return
            end

            local mut_data = find_mutation(obj, "close")
            if mut_data then
                if perform_mutation(ctx, obj, mut_data) then
                    local mutated = ctx.registry:get(obj.id)
                    print(mut_data.message
                        or ("You close " .. (mutated and mutated.name or obj.id) .. "."))
                end
                return
            end
        end

        -- Check exits
        local room = ctx.current_room
        for dir, exit in pairs(room.exits or {}) do
            if type(exit) == "table" and exit_matches(exit, dir, noun) then
                if not exit.mutations or not exit.mutations.close then
                    if exit.open == false then
                        print("It is already closed.")
                    else
                        print("You can't close that.")
                    end
                    return
                end
                if exit.open == false then
                    print("It is already closed.")
                    return
                end
                local mut = exit.mutations.close
                if mut.becomes_exit then
                    for k, v in pairs(mut.becomes_exit) do
                        exit[k] = v
                    end
                end
                print(mut.message or "You close it.")
                return
            end
        end

        if obj then
            print("You can't close " .. (obj.name or "that") .. ".")
        else
            print("You don't see that here.")
        end
    end

    handlers["shut"] = handlers["close"]

    ---------------------------------------------------------------------------
    -- BREAK
    ---------------------------------------------------------------------------
    handlers["break"] = function(ctx, noun)
        if noun == "" then print("Break what?") return end

        -- Check objects first
        local obj = find_visible(ctx, noun)
        if obj then
            local mut_data = find_mutation(obj, "break")
            if mut_data then
                if perform_mutation(ctx, obj, mut_data) then
                    print(mut_data.message
                        or ("You break " .. (obj.name or obj.id) .. "."))
                end
                return
            end
        end

        -- Check exits
        local room = ctx.current_room
        for dir, exit in pairs(room.exits or {}) do
            if type(exit) == "table" and exit_matches(exit, dir, noun) then
                if exit.broken then
                    print("It is already broken.")
                    return
                end
                if not exit.breakable then
                    print("You can't break that.")
                    return
                end
                if not exit.mutations or not exit.mutations["break"] then
                    print("You can't break that.")
                    return
                end
                local mut = exit.mutations["break"]
                if mut.becomes_exit then
                    for k, v in pairs(mut.becomes_exit) do
                        exit[k] = v
                    end
                end
                if mut.spawns then
                    spawn_objects(ctx, mut.spawns)
                end
                print(mut.message or "You break it.")
                return
            end
        end

        if obj then
            print("You can't break " .. (obj.name or "that") .. ".")
        else
            print("You don't see that here.")
        end
    end

    handlers["smash"] = handlers["break"]
    handlers["shatter"] = handlers["break"]

    ---------------------------------------------------------------------------
    -- TEAR
    ---------------------------------------------------------------------------
    handlers["tear"] = function(ctx, noun)
        if noun == "" then print("Tear what?") return end

        local obj = find_visible(ctx, noun)
        if not obj then
            print("You don't see that here.")
            return
        end

        local mut_data = find_mutation(obj, "tear")
        if not mut_data then
            print("You can't tear " .. (obj.name or "that") .. ".")
            return
        end

        local obj_name = obj.name or obj.id
        if perform_mutation(ctx, obj, mut_data) then
            print(mut_data.message
                or ("You tear " .. obj_name .. " apart."))
        end
    end

    handlers["rip"] = handlers["tear"]

    ---------------------------------------------------------------------------
    -- INVENTORY -- shows hands, worn items, and bag contents
    ---------------------------------------------------------------------------
    handlers["inventory"] = function(ctx, noun)
        local reg = ctx.registry

        -- Hands
        for i = 1, 2 do
            local hand_id = ctx.player.hands[i]
            if hand_id then
                local obj = reg:get(hand_id)
                local label = (i == 1) and "Left hand" or "Right hand"
                print("  " .. label .. ": " .. (obj and obj.name or hand_id))
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

        -- Worn items
        if #(ctx.player.worn or {}) > 0 then
            print("  Worn:")
            for _, worn_id in ipairs(ctx.player.worn) do
                local obj = reg:get(worn_id)
                print("    " .. (obj and obj.name or worn_id))
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

    ---------------------------------------------------------------------------
    -- LIGHT
    ---------------------------------------------------------------------------
    handlers["light"] = function(ctx, noun)
        if noun == "" then print("Light what?") return end

        -- Allow lighting things even in darkness (you can feel what you hold)
        local obj = find_in_inventory(ctx, noun)
        if not obj then
            obj = find_visible(ctx, noun)
        end
        if not obj then
            print("You don't have anything like that.")
            return
        end

        local mut_data = find_mutation(obj, "light")
        if not mut_data then
            -- FSM path: check for a "strike" or "light" transition (e.g., match)
            if obj._fsm_id then
                local transitions = fsm_mod.get_transitions(obj)
                for _, t in ipairs(transitions) do
                    if t.verb == "strike" or t.verb == "light" then
                        handlers["strike"](ctx, noun)
                        return
                    end
                    if t.aliases then
                        for _, alias in ipairs(t.aliases) do
                            if alias == "light" then
                                handlers["strike"](ctx, noun)
                                return
                            end
                        end
                    end
                end
            end
            print("You can't light " .. (obj.name or "that") .. ".")
            return
        end

        -- Tool check: does this mutation require a fire source?
        if mut_data.requires_tool then
            -- Check struck match flame first
            if ctx.player.state.has_flame and ctx.player.state.has_flame > 0 then
                print("You touch the match flame to the wick...")
                ctx.player.state.has_flame = 0  -- match consumed
                if perform_mutation(ctx, obj, mut_data) then
                    local mutated = ctx.registry:get(obj.id)
                    print(mut_data.message
                        or ("You light " .. (mutated and mutated.name or obj.id) .. ". It casts a warm glow."))
                    print("The match, spent, curls into ash between your fingers.")
                end
                return
            end

            -- Fall through to tool search
            local tool = find_tool_in_inventory(ctx, mut_data.requires_tool)
            if not tool then
                print(mut_data.fail_message or "You have nothing to light it with.")
                return
            end
            if tool.on_tool_use and tool.on_tool_use.use_message then
                print(tool.on_tool_use.use_message)
            end
            if perform_mutation(ctx, obj, mut_data) then
                consume_tool_charge(ctx, tool)
                local mutated = ctx.registry:get(obj.id)
                print(mut_data.message
                    or ("You light " .. (mutated and mutated.name or obj.id) .. ". It casts a warm glow."))
            end
            return
        end

        -- No tool required -- original behavior
        if perform_mutation(ctx, obj, mut_data) then
            local mutated = ctx.registry:get(obj.id)
            print(mut_data.message
                or ("You light " .. (mutated and mutated.name or obj.id) .. ". It casts a warm glow."))
        end
    end

    handlers["ignite"] = handlers["light"]

    ---------------------------------------------------------------------------
    -- EXTINGUISH
    ---------------------------------------------------------------------------
    handlers["extinguish"] = function(ctx, noun)
        if noun == "" then print("Extinguish what?") return end

        local obj = find_in_inventory(ctx, noun)
        if not obj then obj = find_visible(ctx, noun) end
        if not obj then
            print("You don't see that here.")
            return
        end

        -- FSM path
        if obj._fsm_id then
            local transitions = fsm_mod.get_transitions(obj)
            local target_state
            for _, t in ipairs(transitions) do
                if t.verb == "extinguish" then target_state = t.to; break end
            end
            if target_state then
                local trans, err = fsm_mod.transition(ctx.registry, obj.id, target_state, {})
                if trans then
                    print(trans.message or ("You extinguish " .. (obj.name or obj.id) .. "."))
                else
                    print("You can't extinguish " .. (obj.name or "that") .. ".")
                end
            else
                print("You can't extinguish " .. (obj.name or "that") .. ".")
            end
            return
        end

        local mut_data = find_mutation(obj, "extinguish")
        if not mut_data then
            print("You can't extinguish " .. (obj.name or "that") .. ".")
            return
        end

        if perform_mutation(ctx, obj, mut_data) then
            print(mut_data.message
                or ("You extinguish " .. (obj.name or obj.id) .. "."))
        end
    end

    handlers["snuff"] = handlers["extinguish"]

    ---------------------------------------------------------------------------
    -- WRITE {text} ON {target} [WITH {tool}]
    -- Dynamic mutation: generates new Lua source at runtime with the
    -- player's words baked into the object definition. This is the first
    -- true runtime code-generation in the engine.
    ---------------------------------------------------------------------------
    handlers["write"] = function(ctx, noun)
        if noun == "" then
            print("Write what? (Try: write <text> on <paper> with <pen>)")
            return
        end

        if not has_some_light(ctx) then
            print("It is too dark to see what you're writing.")
            return
        end

        -- Parse: "write {text} on {target} with {tool}"
        local text, target_word, tool_word
        text, target_word, tool_word = noun:match("^(.+)%s+on%s+(.+)%s+with%s+(.+)$")
        if not text then
            -- "write on {target} with {tool}" (no text)
            target_word, tool_word = noun:match("^on%s+(.+)%s+with%s+(.+)$")
        end
        if not target_word then
            -- "write {text} on {target}" (no tool specified)
            text, target_word = noun:match("^(.+)%s+on%s+(.+)$")
        end
        if not target_word then
            -- "write on {target}" (no text, no tool)
            target_word = noun:match("^on%s+(.+)$")
        end

        if not target_word then
            print("Write on what? (Try: write <text> on <paper>)")
            return
        end

        -- Find target -- check visible objects and inventory
        local target = find_visible(ctx, target_word)
        if not target then
            target = find_in_inventory(ctx, target_word)
        end
        if not target then
            print("You don't see that here.")
            return
        end

        if not target.writable then
            print("You can't write on " .. (target.name or "that") .. ".")
            return
        end

        if not text or text == "" then
            print("What do you want to write?")
            return
        end

        -- Find writing instrument
        local tool = nil
        if tool_word then
            tool = find_in_inventory(ctx, tool_word)
            if not tool then
                -- Check if they specified "blood"
                if tool_word:match("blood") and ctx.player.state and ctx.player.state.bloody then
                    tool = find_tool_in_inventory(ctx, "writing_instrument")
                    if tool and not tool._is_blood then tool = nil end
                end
                if not tool then
                    print("You don't have " .. tool_word .. ".")
                    return
                end
            end
            if not provides_capability(tool, "writing_instrument") and not (tool._is_blood) then
                print("You can't write with " .. (tool.name or "that") .. ".")
                return
            end
        else
            -- Auto-find writing instrument in inventory
            tool = find_tool_in_inventory(ctx, "writing_instrument")
            if not tool then
                local mut_data = find_mutation(target, "write")
                print(mut_data and mut_data.fail_message or "You have nothing to write with.")
                return
            end
        end

        -- Print tool use message
        if tool.on_tool_use and tool.on_tool_use.use_message then
            print(tool.on_tool_use.use_message)
        end

        -- Build the new written text (append if paper already has writing)
        local written = text
        if target.written_text then
            written = target.written_text .. " " .. text
        end

        -- DYNAMIC MUTATION: generate new Lua source with written text baked in.
        -- This is runtime code generation -- the paper's definition is rewritten
        -- to include the player's words as part of the object's identity.
        local esc_written = string.format("%q", written)
        local new_source = string.format(
            "return {\n"
         .. "    id = %q,\n"
         .. "    name = \"a sheet of paper with writing\",\n"
         .. "    keywords = {\"paper\", \"sheet\", \"page\", \"written paper\", \"note\", \"parchment\"},\n"
         .. "    description = \"A sheet of cream-coloured paper. Words have been written across it in careful strokes.\",\n"
         .. "    writable = true,\n"
         .. "    written_text = %s,\n"
         .. "    size = 1,\n"
         .. "    weight = 0.1,\n"
         .. "    categories = {\"small\", \"writable\", \"flammable\"},\n"
         .. "    portable = true,\n"
         .. "    location = nil,\n"
         .. "    on_look = function(self)\n"
         .. "        if self.written_text then\n"
         .. "            return \"A sheet of paper with writing on it. It reads:\\n\\n  \\\"\" .. self.written_text .. \"\\\"\"\n"
         .. "        end\n"
         .. "        return self.description\n"
         .. "    end,\n"
         .. "    mutations = {\n"
         .. "        write = {\n"
         .. "            requires_tool = \"writing_instrument\",\n"
         .. "            dynamic = true,\n"
         .. "            mutator = \"write_on_surface\",\n"
         .. "            message = \"You add more words to the paper.\",\n"
         .. "            fail_message = \"You have nothing to write with.\",\n"
         .. "        },\n"
         .. "    },\n"
         .. "}\n",
            target.id, esc_written)

        -- Perform the mutation
        local had_writing = target.written_text ~= nil
        local new_obj, err = ctx.mutation.mutate(
            ctx.registry, ctx.loader, target.id, new_source, ctx.templates)
        if not new_obj then
            print("Something goes wrong -- the ink smears illegibly.")
            return
        end

        -- Store new source for future mutations
        ctx.object_sources[target.id] = new_source

        -- Consume tool charge (if applicable)
        consume_tool_charge(ctx, tool)

        -- Success message
        if had_writing then
            print("You add more words to the paper.")
        else
            local mut_data = find_mutation(target, "write")
            print(mut_data and mut_data.message
                or "You write carefully on the paper. The words appear in steady strokes.")
        end
    end

    handlers["inscribe"] = handlers["write"]

    ---------------------------------------------------------------------------
    -- CUT {target} WITH {tool}  /  CUT SELF WITH {tool}
    ---------------------------------------------------------------------------
    handlers["cut"] = function(ctx, noun)
        if noun == "" then
            print("Cut what? (Try: cut <thing> with <tool>)")
            return
        end

        local target_word, tool_word = noun:match("^(.+)%s+with%s+(.+)$")
        if not target_word then target_word = noun end

        -- CUT SELF -- self-injury with a blade
        if target_word == "self" or target_word == "myself"
           or target_word == "me" or target_word == "hand"
           or target_word == "palm" then

            local tool = nil
            if tool_word then
                tool = find_in_inventory(ctx, tool_word)
                if not tool then
                    print("You don't have " .. tool_word .. ".")
                    return
                end
                if not provides_capability(tool, "cutting_edge") then
                    print("You can't cut yourself with " .. (tool.name or "that") .. ". You need a proper blade.")
                    return
                end
            else
                tool = find_tool_in_inventory(ctx, "cutting_edge")
                if not tool then
                    print("You have nothing sharp enough to cut with.")
                    return
                end
            end

            ctx.player.state = ctx.player.state or {}
            ctx.player.state.bloody = true
            print("You draw the blade across your palm. Blood wells up, dark and warm.")
            print("Your hands are now bloody.")
            return
        end

        -- CUT {object}
        if not has_some_light(ctx) then
            print("It is too dark to see what you're doing.")
            return
        end

        local obj = find_visible(ctx, target_word)
        if not obj then
            print("You don't see that here.")
            return
        end

        local mut_data = find_mutation(obj, "cut")
        if mut_data then
            if mut_data.requires_tool then
                local tool = nil
                if tool_word then
                    tool = find_in_inventory(ctx, tool_word)
                    if not tool then
                        print("You don't have " .. tool_word .. ".")
                        return
                    end
                    if not provides_capability(tool, mut_data.requires_tool) then
                        print(mut_data.fail_message or "That tool won't work for cutting this.")
                        return
                    end
                else
                    tool = find_tool_in_inventory(ctx, mut_data.requires_tool)
                    if not tool then
                        print(mut_data.fail_message or "You have nothing to cut with.")
                        return
                    end
                end
            end
            if perform_mutation(ctx, obj, mut_data) then
                print(mut_data.message or "You cut " .. (obj.name or "that") .. ".")
            end
            return
        end

        print("You can't cut " .. (obj.name or "that") .. ".")
    end

    handlers["slash"] = handlers["cut"]

    ---------------------------------------------------------------------------
    -- PRICK SELF WITH {tool}
    ---------------------------------------------------------------------------
    handlers["prick"] = function(ctx, noun)
        if noun == "" then
            print("Prick what? (Try: prick self with <pin>)")
            return
        end

        local target_word, tool_word = noun:match("^(.+)%s+with%s+(.+)$")
        if not target_word then target_word = noun end

        -- PRICK SELF -- minor self-injury with any sharp point
        if target_word == "self" or target_word == "myself"
           or target_word == "me" or target_word == "finger"
           or target_word == "thumb" then

            local tool = nil
            if tool_word then
                tool = find_in_inventory(ctx, tool_word)
                if not tool then
                    print("You don't have " .. tool_word .. ".")
                    return
                end
                if not provides_capability(tool, "injury_source") then
                    print("You can't prick yourself with " .. (tool.name or "that") .. ".")
                    return
                end
            else
                tool = find_tool_in_inventory(ctx, "injury_source")
                if not tool then
                    print("You have nothing sharp enough to prick yourself with.")
                    return
                end
            end

            ctx.player.state = ctx.player.state or {}
            ctx.player.state.bloody = true
            print("You prick your finger with " .. (tool.name or "the sharp point") .. ". A bead of blood forms.")
            print("Your hands are now bloody.")
            return
        end

        print("You can only prick yourself. (Try: prick self with <pin>)")
    end

    ---------------------------------------------------------------------------
    -- SEW {material} WITH {tool} -- STUB (requires future skill system)
    ---------------------------------------------------------------------------
    handlers["sew"] = function(ctx, noun)
        print("You don't know how to sew. Perhaps you could learn this skill somehow.")
    end

    handlers["stitch"] = handlers["sew"]
    handlers["mend"] = handlers["sew"]

    ---------------------------------------------------------------------------
    -- PUT X IN/ON Y -- supports furniture surfaces AND held/worn bags
    ---------------------------------------------------------------------------
    handlers["put"] = function(ctx, noun)
        if noun == "" then
            print("Put what where? (Try: put <item> in/on <target>)")
            return
        end

        -- Parse "X in Y" or "X on Y"
        local item_word, prep, target_word
        item_word, target_word = noun:match("^(.+)%s+in%s+(.+)$")
        if item_word then
            prep = "in"
        else
            item_word, target_word = noun:match("^(.+)%s+on%s+(.+)$")
            if item_word then
                prep = "on"
            end
        end

        if not item_word or not target_word then
            print("Put what where? (Try: put <item> in/on <target>)")
            return
        end

        -- Find item -- must be in hands
        local item = nil
        local item_hand = nil
        local kw = item_word:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        for i = 1, 2 do
            local hand_id = ctx.player.hands[i]
            if hand_id then
                local candidate = ctx.registry:get(hand_id)
                if candidate and matches_keyword(candidate, kw) then
                    item = candidate
                    item_hand = i
                    break
                end
            end
        end

        if not item then
            local found = find_visible(ctx, item_word)
            if found then
                print("You need to be holding that to put it somewhere.")
                return
            end
            print("You don't have " .. item_word .. ".")
            return
        end

        -- Find target -- could be a held bag, worn bag, or room object
        local target = find_visible(ctx, target_word)
        if not target then
            print("You don't see " .. target_word .. " here.")
            return
        end

        -- If target is a held/worn bag (simple container, no surfaces)
        if target.container and not target.surfaces then
            local ok, reason = ctx.containment.can_contain(
                item, target, nil, ctx.registry)
            if not ok then
                print(reason or "You can't put that there.")
                return
            end
            ctx.player.hands[item_hand] = nil
            target.contents = target.contents or {}
            target.contents[#target.contents + 1] = item.id
            item.location = target.id
            print("You put " .. (item.name or item.id) ..
                " " .. prep .. " " .. (target.name or target.id) .. ".")
            return
        end

        -- Determine surface name (furniture)
        local surface_name = nil
        if target.surfaces then
            if prep == "on" and target.surfaces.top then
                surface_name = "top"
            elseif prep == "in" and target.surfaces.inside then
                surface_name = "inside"
            elseif prep == "on" then
                for sname, _ in pairs(target.surfaces) do
                    surface_name = sname
                    break
                end
            elseif prep == "in" then
                for sname, _ in pairs(target.surfaces) do
                    surface_name = sname
                    break
                end
            end
        end

        -- Validate with containment engine
        local ok, reason = ctx.containment.can_contain(
            item, target, surface_name, ctx.registry)
        if not ok then
            print(reason or "You can't put that there.")
            return
        end

        -- Move
        ctx.player.hands[item_hand] = nil

        if surface_name and target.surfaces and target.surfaces[surface_name] then
            local zone = target.surfaces[surface_name]
            zone.contents = zone.contents or {}
            zone.contents[#zone.contents + 1] = item.id
        elseif target.contents then
            target.contents[#target.contents + 1] = item.id
        else
            target.contents = { item.id }
        end

        item.location = target.id

        print("You put " .. (item.name or item.id) ..
            " " .. prep .. " " .. (target.name or target.id) .. ".")
    end

    handlers["place"] = handlers["put"]

    ---------------------------------------------------------------------------
    -- STRIKE {A} ON {B} -- compound tool verb for fire-making
    -- FSM path: A is a match with _fsm_id, B is something with has_striker.
    -- Legacy path: matchbox with fire_source charges.
    ---------------------------------------------------------------------------
    handlers["strike"] = function(ctx, noun)
        if noun == "" then
            print("Strike what? (Try: strike match on matchbox)")
            return
        end

        -- Parse "strike A on B"
        local a_word, b_word = noun:match("^(.+)%s+on%s+(.+)$")
        if not a_word then a_word = noun end

        -- Find the object to strike (A) -- check carried then visible
        local match_obj = find_in_inventory(ctx, a_word)
        if not match_obj then
            match_obj = find_visible(ctx, a_word)
        end

        -- FSM path: A is an FSM object with a "strike" transition
        if match_obj and match_obj._fsm_id then
            local transitions = fsm_mod.get_transitions(match_obj)
            local strike_trans
            for _, t in ipairs(transitions) do
                if t.verb == "strike" then strike_trans = t; break end
            end

            if not strike_trans then
                if match_obj._state == "spent" then
                    print("The match is spent. It cannot be relit.")
                elseif match_obj._state == "lit" then
                    print("The match is already lit.")
                else
                    print("You can't strike " .. (match_obj.name or "that") .. ".")
                end
                return
            end

            -- Find the striker surface (B)
            local striker
            if b_word then
                striker = find_in_inventory(ctx, b_word)
                if not striker then striker = find_visible(ctx, b_word) end
            else
                -- Auto-find: search carried then visible for has_striker
                for _, id in ipairs(get_all_carried_ids(ctx)) do
                    local o = ctx.registry:get(id)
                    if o and o.has_striker then striker = o; break end
                end
                if not striker then
                    local room = ctx.current_room
                    for _, obj_id in ipairs(room.contents or {}) do
                        local o = ctx.registry:get(obj_id)
                        if o and o.has_striker then striker = o; break end
                        if o and o.surfaces then
                            for _, zone in pairs(o.surfaces) do
                                if zone.accessible ~= false then
                                    for _, item_id in ipairs(zone.contents or {}) do
                                        local item = ctx.registry:get(item_id)
                                        if item and item.has_striker then striker = item; break end
                                    end
                                end
                                if striker then break end
                            end
                        end
                        if striker then break end
                    end
                end
            end

            if not striker then
                print(strike_trans.fail_message or "You need a rough surface to strike it on. A matchbox striker, perhaps.")
                return
            end

            local trans, err = fsm_mod.transition(
                ctx.registry, match_obj.id, strike_trans.to, { target = striker })
            if trans then
                print(trans.message)
            elseif err == "requires_property" then
                print("You can't strike a match on " .. (striker.name or "that") .. ".")
            elseif err == "terminal" then
                print("The match is spent. It cannot be relit.")
            else
                print("You can't strike " .. (match_obj.name or "that") .. ".")
            end
            return
        end

        -- Legacy path: matchbox with fire_source charges
        local matchbox = nil
        if b_word then
            matchbox = find_in_inventory(ctx, b_word)
            if not matchbox then
                matchbox = find_visible(ctx, b_word)
            end
        else
            matchbox = find_in_inventory(ctx, a_word)
            if not matchbox or not provides_capability(matchbox, "fire_source") then
                matchbox = find_visible(ctx, a_word)
                if not matchbox or not provides_capability(matchbox, "fire_source") then
                    matchbox = find_tool_in_inventory(ctx, "fire_source")
                    if not matchbox then
                        matchbox = find_visible_tool(ctx, "fire_source")
                    end
                end
            end
        end

        if not matchbox then
            print("You don't see anything to strike against.")
            return
        end

        if not provides_capability(matchbox, "fire_source") then
            print("You can't strike a match on " .. (matchbox.name or "that") .. ".")
            return
        end

        if matchbox.charges and matchbox.charges <= 0 then
            print((matchbox.name or "The matchbox") .. " is empty. No matches remain.")
            return
        end

        if matchbox.on_tool_use and matchbox.on_tool_use.use_message then
            print(matchbox.on_tool_use.use_message)
        else
            print("You strike a match. It flares to life with a hiss of sulphur.")
        end

        consume_tool_charge(ctx, matchbox)
        ctx.player.state.has_flame = 3
        print("You hold the small flame carefully. It won't last long.")
    end

    ---------------------------------------------------------------------------
    -- WEAR / PUT ON -- equip an item from hand to worn slot
    ---------------------------------------------------------------------------
    handlers["wear"] = function(ctx, noun)
        if noun == "" then
            print("Wear what?")
            return
        end

        -- Find item in hands
        local obj = nil
        local hand_slot = nil
        local kw = noun:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        for i = 1, 2 do
            local hand_id = ctx.player.hands[i]
            if hand_id then
                local candidate = ctx.registry:get(hand_id)
                if candidate and matches_keyword(candidate, kw) then
                    obj = candidate
                    hand_slot = i
                    break
                end
            end
        end

        if not obj then
            print("You aren't holding that.")
            return
        end

        if not obj.wearable then
            print("You can't wear " .. (obj.name or "that") .. ".")
            return
        end

        ctx.player.hands[hand_slot] = nil
        ctx.player.worn[#ctx.player.worn + 1] = obj.id
        obj.location = "player"
        print("You put on " .. (obj.name or obj.id) .. ".")
    end

    handlers["don"] = handlers["wear"]

    ---------------------------------------------------------------------------
    -- REMOVE / TAKE OFF -- move worn item to hand
    ---------------------------------------------------------------------------
    handlers["remove"] = function(ctx, noun)
        if noun == "" then
            print("Remove what?")
            return
        end

        local kw = noun:lower()
            :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
        local obj = nil
        local worn_idx = nil
        for i, worn_id in ipairs(ctx.player.worn or {}) do
            local candidate = ctx.registry:get(worn_id)
            if candidate and matches_keyword(candidate, kw) then
                obj = candidate
                worn_idx = i
                break
            end
        end

        if not obj then
            print("You aren't wearing that.")
            return
        end

        local slot = first_empty_hand(ctx)
        if not slot then
            print("Your hands are full. Drop something first.")
            return
        end

        table.remove(ctx.player.worn, worn_idx)
        ctx.player.hands[slot] = obj.id
        print("You remove " .. (obj.name or obj.id) .. ".")
    end

    ---------------------------------------------------------------------------
    -- EAT -- stub for consumables
    ---------------------------------------------------------------------------
    handlers["eat"] = function(ctx, noun)
        if noun == "" then
            print("Eat what?")
            return
        end

        local obj = find_in_inventory(ctx, noun)
        if not obj then
            obj = find_visible(ctx, noun)
        end
        if not obj then
            print("You don't see that here.")
            return
        end

        if obj.edible then
            print("You eat " .. (obj.name or "it") .. ".")
            if obj.on_eat_message then
                print(obj.on_eat_message)
            end
            remove_from_location(ctx, obj)
            ctx.registry:remove(obj.id)
        else
            print("You can't eat " .. (obj.name or "that") .. ".")
        end
    end

    handlers["consume"] = handlers["eat"]
    handlers["devour"] = handlers["eat"]

    ---------------------------------------------------------------------------
    -- BURN -- stub for consumables
    ---------------------------------------------------------------------------
    handlers["burn"] = function(ctx, noun)
        if noun == "" then
            print("Burn what?")
            return
        end

        local obj = find_in_inventory(ctx, noun)
        if not obj then
            obj = find_visible(ctx, noun)
        end
        if not obj then
            print("You don't see that here.")
            return
        end

        -- Need a flame
        local has_fire = (ctx.player.state.has_flame and ctx.player.state.has_flame > 0)
            or find_tool_in_inventory(ctx, "fire_source") ~= nil
        if not has_fire then
            print("You have no flame to burn anything with.")
            return
        end

        if obj.flammable or (obj.categories and type(obj.categories) == "table") then
            local is_flammable = obj.flammable
            if not is_flammable and obj.categories then
                for _, cat in ipairs(obj.categories) do
                    if cat == "flammable" then is_flammable = true break end
                end
            end
            if is_flammable then
                print("You hold the flame to " .. (obj.name or "it") .. ". It catches fire and burns away to ash.")
                remove_from_location(ctx, obj)
                ctx.registry:remove(obj.id)
                return
            end
        end

        print("You can't burn " .. (obj.name or "that") .. ".")
    end

    ---------------------------------------------------------------------------
    -- TIME
    ---------------------------------------------------------------------------
    handlers["time"] = function(ctx, noun)
        local hour, minute = get_game_time(ctx)
        print(time_of_day_desc(hour))
        print("It is " .. format_time(hour, minute) .. ".")
    end

    ---------------------------------------------------------------------------
    -- HELP
    ---------------------------------------------------------------------------
    handlers["help"] = function(ctx, noun)
        print("Available commands:")
        print("  look              - look around the room")
        print("  look at <thing>   - examine something closely")
        print("  look in/on/under  - inspect a surface")
        print("  examine <thing>   - same as 'look at'")
        print("  read <thing>      - read text on an object")
        print("  find <thing>      - same as 'examine'")
        print("  feel              - grope around (works in darkness)")
        print("  feel <thing>      - feel an object by touch")
        print("  smell             - smell the air (works in darkness)")
        print("  smell <thing>     - smell a specific object")
        print("  taste <thing>     - taste something (risky! works in darkness)")
        print("  listen            - listen to ambient sounds (works in darkness)")
        print("  listen to <thing> - listen closely to something")
        print("  take <thing>      - pick something up (needs a free hand)")
        print("  get <x> from <y>  - take something from a bag or container")
        print("  drop <thing>      - drop something you're holding")
        print("  put <x> in <y>    - put something in a bag or container")
        print("  put <x> on <y>    - put something on a surface")
        print("  open <thing>      - open a container or door")
        print("  close <thing>     - close something")
        print("  break <thing>     - break something breakable")
        print("  tear <thing>      - tear fabric apart")
        print("  strike match on <x>  - strike a match (compound tool)")
        print("  light <thing>     - light a candle or torch (needs fire)")
        print("  extinguish <thing>- put out a flame")
        print("  cut <thing> with <tool>  - cut something (or 'cut self' for blood)")
        print("  prick self with <tool>   - prick yourself with something sharp")
        print("  write <text> on <thing>  - write on a writable surface")
        print("  sew <thing> with <tool>  - sew materials together (requires skill)")
        print("  wear <thing>      - put on a wearable item (backpack, cloak)")
        print("  remove <thing>    - take off a worn item")
        print("  eat <thing>       - eat something edible")
        print("  burn <thing>      - set something flammable on fire")
        print("  inventory (i)     - see what you're carrying / wearing")
        print("  time              - check the time of day")
        print("  help              - show this list")
        print("  quit              - leave the game")
    end

    return handlers
end

return verbs
