-- engine/verbs/init.lua
-- V1 verb handlers for the bedroom REPL.
-- Each handler has signature: function(context, noun)
-- Context is injected by the game loop at dispatch time.

local verbs = {}

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------
local GAME_SECONDS_PER_REAL_SECOND = 24
local GAME_START_HOUR = 6
local DAYTIME_START = 6
local DAYTIME_END = 18

---------------------------------------------------------------------------
-- Helper: keyword matching
---------------------------------------------------------------------------
local function matches_keyword(obj, kw)
    if not obj then return false end
    kw = kw:lower()
    if obj.id and obj.id:lower() == kw then return true end
    if obj.name and obj.name:lower():find(kw, 1, true) then return true end
    if type(obj.keywords) == "table" then
        for _, k in ipairs(obj.keywords) do
            if k:lower() == kw then return true end
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Helper: find an object the player can see or reach
-- Returns: obj, location_type, parent_obj, surface_name
--   location_type: "room" | "surface" | "inventory"
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
        -- Also search non-surface container contents
        if obj and not obj.surfaces and obj.container and obj.contents then
            for _, item_id in ipairs(obj.contents) do
                local item = reg:get(item_id)
                if item and matches_keyword(item, kw) then
                    return item, "container", obj, nil
                end
            end
        end
    end

    -- 3. Player inventory
    for _, obj_id in ipairs(ctx.player.inventory) do
        local obj = reg:get(obj_id)
        if obj and matches_keyword(obj, kw) then
            return obj, "inventory", nil, nil
        end
    end

    return nil
end

---------------------------------------------------------------------------
-- Helper: find object in inventory only
---------------------------------------------------------------------------
local function find_in_inventory(ctx, keyword)
    if not keyword or keyword == "" then return nil end
    local kw = keyword:lower()
        :gsub("^the%s+", "")
        :gsub("^a%s+", "")
        :gsub("^an%s+", "")
    for _, obj_id in ipairs(ctx.player.inventory) do
        local obj = ctx.registry:get(obj_id)
        if obj and matches_keyword(obj, kw) then
            return obj
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Helper: remove an object from wherever it currently lives
---------------------------------------------------------------------------
local function remove_from_location(ctx, obj)
    local room = ctx.current_room

    -- Room contents
    for i, id in ipairs(room.contents or {}) do
        if id == obj.id then
            table.remove(room.contents, i)
            return true
        end
    end

    -- Surface contents of room objects
    for _, parent_id in ipairs(room.contents or {}) do
        local parent = ctx.registry:get(parent_id)
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

    -- Inventory
    for i, id in ipairs(ctx.player.inventory) do
        if id == obj.id then
            table.remove(ctx.player.inventory, i)
            return true
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
-- Helper: light system — tri-state: "lit", "dim", "dark"
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
    for _, obj_id in ipairs(ctx.player.inventory) do
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
-- Helper: total inventory weight
---------------------------------------------------------------------------
local function inventory_weight(ctx)
    local total = 0
    for _, id in ipairs(ctx.player.inventory) do
        local obj = ctx.registry:get(id)
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
        -- Bare "look" — show room
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
                parts[#parts + 1] = "Dim light seeps through the curtains — enough to make out shapes, but details are lost in shadow."
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
            -- No matching surface — fall through to general examine
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
        handlers["look"](ctx, "at " .. noun)
    end
    handlers["x"] = handlers["examine"]
    handlers["find"] = handlers["examine"]
    handlers["search"] = function(ctx, noun)
        if noun == "" then
            handlers["look"](ctx, "")
        else
            handlers["look"](ctx, "at " .. noun)
        end
    end

    ---------------------------------------------------------------------------
    -- FEEL / TOUCH / GROPE — works even in total darkness
    ---------------------------------------------------------------------------
    handlers["feel"] = function(ctx, noun)
        if noun == "" then
            -- Feel around the room
            local room = ctx.current_room
            local found = {}
            for _, obj_id in ipairs(room.contents or {}) do
                local obj = ctx.registry:get(obj_id)
                if obj and not obj.hidden then
                    found[#found + 1] = obj.name or obj.id
                end
            end
            if #found > 0 then
                print("You reach out in the darkness, feeling around you...")
                print("Your hands find: " .. table.concat(found, ", ") .. ".")
            else
                print("You feel around but find nothing within reach.")
            end
            return
        end

        local obj = find_visible(ctx, noun)
        if not obj then
            print("You can't feel anything like that nearby.")
            return
        end

        if obj.touch_description then
            print(obj.touch_description)
        else
            print("You run your hands over " .. (obj.name or "it") ..
                ". " .. (obj.description or "It feels ordinary."))
        end
    end
    handlers["touch"] = handlers["feel"]
    handlers["grope"] = handlers["feel"]

    ---------------------------------------------------------------------------
    -- TAKE / GET / PICK UP
    ---------------------------------------------------------------------------
    handlers["take"] = function(ctx, noun)
        if noun == "" then print("Take what?") return end

        -- "pick up X"
        local target = noun:match("^up%s+(.+)") or noun

        if not has_some_light(ctx) then
            print("It is too dark to find anything.")
            return
        end

        local obj, where, parent, sname = find_visible(ctx, target)
        if not obj then
            print("You don't see that here.")
            return
        end

        if where == "inventory" then
            print("You already have that.")
            return
        end

        if not obj.portable then
            print("You can't carry " .. (obj.name or "that") .. ".")
            return
        end

        local max_weight = ctx.player.max_carry_weight or 20
        if inventory_weight(ctx) + (obj.weight or 0) > max_weight then
            print("You are carrying too much weight.")
            return
        end

        remove_from_location(ctx, obj)
        ctx.player.inventory[#ctx.player.inventory + 1] = obj.id
        obj.location = "player"

        print("You take " .. (obj.name or obj.id) .. ".")
    end

    handlers["get"] = handlers["take"]
    handlers["pick"] = handlers["take"]
    handlers["grab"] = handlers["take"]

    ---------------------------------------------------------------------------
    -- DROP
    ---------------------------------------------------------------------------
    handlers["drop"] = function(ctx, noun)
        if noun == "" then print("Drop what?") return end

        local obj = find_in_inventory(ctx, noun)
        if not obj then
            print("You aren't carrying that.")
            return
        end

        for i, id in ipairs(ctx.player.inventory) do
            if id == obj.id then
                table.remove(ctx.player.inventory, i)
                break
            end
        end

        ctx.current_room.contents[#ctx.current_room.contents + 1] = obj.id
        obj.location = ctx.current_room.id

        print("You drop " .. (obj.name or obj.id) .. ".")
    end

    ---------------------------------------------------------------------------
    -- OPEN
    ---------------------------------------------------------------------------
    handlers["open"] = function(ctx, noun)
        if noun == "" then print("Open what?") return end

        if not has_some_light(ctx) then
            print("It is too dark to see what you're doing.")
            return
        end

        -- Check room objects first
        local obj = find_visible(ctx, noun)
        if obj then
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

        if not has_some_light(ctx) then
            print("It is too dark to see what you're doing.")
            return
        end

        -- Check room objects first
        local obj = find_visible(ctx, noun)
        if obj then
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

        if not has_some_light(ctx) then
            print("It is too dark to see what you're doing.")
            return
        end

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

        if not has_some_light(ctx) then
            print("It is too dark to see what you're doing.")
            return
        end

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
    -- INVENTORY
    ---------------------------------------------------------------------------
    handlers["inventory"] = function(ctx, noun)
        if #ctx.player.inventory == 0 then
            print("You are carrying nothing.")
            return
        end
        print("You are carrying:")
        for _, id in ipairs(ctx.player.inventory) do
            local obj = ctx.registry:get(id)
            print("  " .. (obj and obj.name or id))
        end
        local w = inventory_weight(ctx)
        print(string.format("  (Total weight: %.1f / %d)",
            w, ctx.player.max_carry_weight or 20))
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
            print("You can't light " .. (obj.name or "that") .. ".")
            return
        end

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
    -- PUT X IN/ON Y
    ---------------------------------------------------------------------------
    handlers["put"] = function(ctx, noun)
        if noun == "" then
            print("Put what where? (Try: put <item> in/on <target>)")
            return
        end

        if not has_some_light(ctx) then
            print("It is too dark to see what you're doing.")
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

        -- Find item — prefer inventory
        local item = find_in_inventory(ctx, item_word)
        if not item then
            local found = find_visible(ctx, item_word)
            if found then
                print("You need to pick that up first.")
                return
            end
            print("You don't have " .. item_word .. ".")
            return
        end

        -- Find target
        local target = find_visible(ctx, target_word)
        if not target then
            print("You don't see " .. target_word .. " here.")
            return
        end

        -- Determine surface name
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
        remove_from_location(ctx, item)

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
        print("  find <thing>      - same as 'examine'")
        print("  feel              - grope around (works in darkness)")
        print("  feel <thing>      - feel an object by touch")
        print("  take <thing>      - pick something up")
        print("  drop <thing>      - drop something you're carrying")
        print("  open <thing>      - open a container or door")
        print("  close <thing>     - close something")
        print("  break <thing>     - break something breakable")
        print("  tear <thing>      - tear fabric apart")
        print("  light <thing>     - light a candle or torch")
        print("  extinguish <thing>- put out a flame")
        print("  put <x> in <y>    - put something in or on something")
        print("  inventory (i)     - see what you're carrying")
        print("  time              - check the time of day")
        print("  help              - show this list")
        print("  quit              - leave the game")
    end

    return handlers
end

return verbs
