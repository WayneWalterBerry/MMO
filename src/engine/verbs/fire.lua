-- engine/verbs/fire.lua
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
local parse_self_infliction = H.parse_self_infliction
local show_hint = H.show_hint

local get_game_time = H.get_game_time
local is_daytime = H.is_daytime
local format_time = H.format_time
local time_of_day_desc = H.time_of_day_desc
local get_light_level = H.get_light_level
local has_some_light = H.has_some_light
local vision_blocked_by_worn = H.vision_blocked_by_worn

local M = {}

function M.register(handlers)
    -- Burnability threshold (shared by light and burn handlers)
    local BURN_THRESHOLD = 0.3

    -- #169: Check if any state of an object provides a given tool capability.
    -- Returns the state name that provides it, or nil.
    local function has_capable_state(obj, capability)
        if not obj or not obj.states then return nil end
        for state_name, state in pairs(obj.states) do
            local pt = state.provides_tool
            if pt then
                if type(pt) == "string" and pt == capability then return state_name end
                if type(pt) == "table" then
                    for _, cap in ipairs(pt) do
                        if cap == capability then return state_name end
                    end
                end
            end
        end
        return nil
    end

    -- #169: Auto-ignite an object to a target state (force transition for fire-making).
    -- Used when a match is auto-struck to serve as a fire source.
    -- #178: Must use FSM timer system so timed_events (e.g. burn-out) fire correctly.
    local function auto_ignite(ctx, obj, target_state_name)
        local old_state = obj._state
        -- Stop any existing timer for the old state
        fsm_mod.stop_timer(obj.id)
        if old_state and obj.states[old_state] then
            for k in pairs(obj.states[old_state]) do
                if k ~= "on_tick" and k ~= "terminal" then
                    obj[k] = nil
                end
            end
        end
        local new_state = obj.states[target_state_name]
        if new_state then
            for k, v in pairs(new_state) do
                if k ~= "on_tick" and k ~= "terminal" then
                    obj[k] = v
                end
            end
        end
        obj._state = target_state_name
        -- Start timer for the new state (e.g. match lit→spent burn-out)
        fsm_mod.start_timer(ctx.registry, obj.id)
    end

    -- #169: find fire source — explicit tool_noun, then hand scan, then inventory.
    -- Also detects objects whose states provide the capability (e.g., unlit match)
    -- and auto-ignites them before returning.
    -- exclude_obj: the object being lit (don't use it as its own fire source)
    local function find_fire_source(ctx, required_tool, exclude_obj)
        -- 1. Explicit tool_noun ("light candle with match")
        if ctx.tool_noun then
            local tool_obj = find_in_inventory(ctx, ctx.tool_noun)
            if tool_obj and tool_obj ~= exclude_obj then
                if provides_capability(tool_obj, required_tool) or tool_obj.has_striker then
                    return tool_obj
                end
                local cap_state = has_capable_state(tool_obj, required_tool)
                -- #361: Don't auto-ignite tools in terminal state (spent match)
                local cur_state = tool_obj._state and tool_obj.states and tool_obj.states[tool_obj._state]
                if cap_state and tool_obj._state ~= cap_state and not (cur_state and cur_state.terminal) then
                    auto_ignite(ctx, tool_obj, cap_state)
                    return tool_obj
                end
            end
        end

        -- 2. Scan hands for fire_source or has_striker (same pattern as stab weapon inference)
        for i = 1, 2 do
            local hand = ctx.player.hands[i]
            if hand then
                local obj = _hobj(hand, ctx.registry)
                if obj and obj ~= exclude_obj and (provides_capability(obj, required_tool) or obj.has_striker) then
                    return obj
                end
            end
        end

        -- 3. Scan hands for objects with a state that provides capability (auto-ignite)
        for i = 1, 2 do
            local hand = ctx.player.hands[i]
            if hand then
                local obj = _hobj(hand, ctx.registry)
                if obj and obj ~= exclude_obj then
                    -- #361: Skip objects in terminal state (spent matches)
                    local cur_state = obj._state and obj.states and obj.states[obj._state]
                    if not (cur_state and cur_state.terminal) then
                        local cap_state = has_capable_state(obj, required_tool)
                        if cap_state and obj._state ~= cap_state then
                            auto_ignite(ctx, obj, cap_state)
                            return obj
                        end
                    end
                end
            end
        end

        -- 4. Fall back to full inventory + visible search
        local tool = find_tool_in_inventory(ctx, required_tool)
        if not tool then
            tool = find_visible_tool(ctx, required_tool)
        end
        return tool
    end

    -- #260: Find name of an unlit fire source the player has, for helpful hints.
    local function find_unlit_source_name(ctx)
        local function is_unlit_and_lightable(obj)
            if not obj then return false end
            if provides_capability(obj, "fire_source") then return false end
            if obj._state and obj.states and obj.states[obj._state]
                and obj.states[obj._state].terminal then return false end
            return has_capable_state(obj, "fire_source") ~= nil
        end
        if ctx.tool_noun then
            local tool_obj = find_in_inventory(ctx, ctx.tool_noun)
            if tool_obj and is_unlit_and_lightable(tool_obj) then
                return tool_obj.id or ctx.tool_noun
            end
        end
        for i = 1, 2 do
            local hand = ctx.player.hands[i]
            if hand then
                local hand_obj = _hobj(hand, ctx.registry)
                if hand_obj and is_unlit_and_lightable(hand_obj) then
                    return hand_obj.id
                end
            end
        end
        return nil
    end

    ---------------------------------------------------------------------------
    -- LIGHT
    ---------------------------------------------------------------------------
    handlers["light"] = function(ctx, noun)
        if noun == "" then print("Light what?") return end

        -- #313: helper to check if object has a lightable FSM transition
        local function is_lightable(o)
            if not o then return false end
            if o.states and o.transitions then
                for _, t in ipairs(o.transitions) do
                    if t.verb == "light" then return true end
                    if t.verb == "strike" then return true end
                    if t.aliases then
                        for _, a in ipairs(t.aliases) do
                            if a == "light" then return true end
                        end
                    end
                end
            end
            if type(o.mutations) == "table" then
                for k, _ in pairs(o.mutations) do
                    if k == "light" then return true end
                end
            end
            return false
        end

        -- Allow lighting things even in darkness (you can feel what you hold)
        local obj = find_in_inventory(ctx, noun)
        if not obj then
            obj = find_visible(ctx, noun)
        end

        -- #313: If found object is not lightable, check parts for a nested lightable item
        -- e.g. "light candle" finds candle-holder (name contains "candle") but the
        -- actual candle is a part — redirect to the nested candle
        if obj and not is_lightable(obj) then
            local kw = noun:lower()
                :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
            -- Check parts of the found object itself
            if obj.parts then
                for _, part in pairs(obj.parts) do
                    if matches_keyword(part, kw) then
                        local live = part.id and ctx.registry:get(part.id)
                        if live and is_lightable(live) then
                            obj = live; break
                        end
                    end
                end
            end
            -- Also check parts of other held items
            if not is_lightable(obj) then
                for i = 1, 2 do
                    local hand = ctx.player.hands[i]
                    if hand then
                        local held = _hobj(hand, ctx.registry)
                        if held and held ~= obj and held.parts then
                            for _, part in pairs(held.parts) do
                                if matches_keyword(part, kw) then
                                    local live = part.id and ctx.registry:get(part.id)
                                    if live and is_lightable(live) then
                                        obj = live; break
                                    end
                                end
                            end
                        end
                        if is_lightable(obj) then break end
                    end
                end
            end
        end

        -- #313: Also check parts of held items when no object found at all
        if not obj then
            local kw = noun:lower()
                :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
            for i = 1, 2 do
                local hand = ctx.player.hands[i]
                if hand then
                    local held = _hobj(hand, ctx.registry)
                    if held and held.parts then
                        for _, part in pairs(held.parts) do
                            if matches_keyword(part, kw) then
                                local live = part.id and ctx.registry:get(part.id)
                                if live then obj = live; break end
                            end
                        end
                    end
                    if obj then break end
                end
            end
        end

        if not obj then
            print("You don't have anything like that.")
            return
        end

        -- Issue #15: Check if already lit (Prime Directive — describe world state)
        if obj._state and obj.states then
            local cur = obj.states[obj._state]
            if cur and cur.casts_light then
                local desc = cur.description or ""
                local short = desc:match("^([^.]+%.)") or desc
                if short ~= "" then
                    print(short)
                else
                    print((obj.name or "It") .. " is already alight.")
                end
                return
            end
        end

        -- Issue #119: terminal state (spent match, etc.) — can't relight
        if obj._state and obj.states then
            local cur = obj.states[obj._state]
            if cur and cur.terminal then
                print("The " .. (obj.id or "object") .. " is spent. You can't relight it.")
                return
            end
        end

        local mut_data = find_mutation(obj, "light")
        if not mut_data then
            -- FSM path: check for "light" or "strike" transitions
            if obj.states then
                local transitions = fsm_mod.get_transitions(obj)
                local found_trans
                for _, t in ipairs(transitions) do
                    if t.verb == "light" then found_trans = t; break end
                    if t.verb == "strike" then found_trans = t; break end
                    if t.aliases then
                        for _, alias in ipairs(t.aliases) do
                            if alias == "light" then found_trans = t; break end
                        end
                        if found_trans then break end
                    end
                end

                if found_trans then
                    -- "strike" verb → redirect to STRIKE handler (match-on-matchbox)
                    if found_trans.verb == "strike" then
                        handlers["strike"](ctx, noun)
                        return
                    end

                    -- "light" verb → direct FSM transition (candle, etc.)
                    if found_trans.requires_tool then
                        -- Check player flame first (legacy struck match)
                        if ctx.player.state.has_flame and ctx.player.state.has_flame > 0 then
                            ctx.player.state.has_flame = 0
                            local trans = fsm_mod.transition(ctx.registry, obj.id, found_trans.to, {})
                            if trans then
                                print("You touch the match flame to the wick...")
                                print(trans.message or ("You light " .. (obj.name or obj.id) .. "."))
                                show_hint(ctx, "extinguish", "You can extinguish flames with 'extinguish' or 'blow out'.")
                                show_hint(ctx, "burn", "You can burn flammable objects with 'burn [item]' while holding a flame.")
                            end
                            return
                        end

                        -- #169: Find fire_source tool (explicit tool, hand scan, inventory)
                        local tool = find_fire_source(ctx, found_trans.requires_tool, obj)
                        if not tool then
                            if found_trans.fail_message then
                                print(found_trans.fail_message)
                            else
                                local hint = find_unlit_source_name(ctx)
                                if hint then
                                    print("The " .. hint .. " isn't lit. Try 'light " .. hint .. "' first.")
                                else
                                    print("You'll need a flame to light that.")
                                end
                            end
                            return
                        end

                        local trans = fsm_mod.transition(ctx.registry, obj.id, found_trans.to, {})
                        if trans then
                            print(trans.message or ("You light " .. (obj.name or obj.id) .. "."))
                            show_hint(ctx, "extinguish", "You can extinguish flames with 'extinguish' or 'blow out'.")
                            show_hint(ctx, "burn", "You can burn flammable objects with 'burn [item]' while holding a flame.")
                        else
                            print("You can't light " .. (obj.name or "that") .. ".")
                        end
                        return
                    end

                    -- No tool required
                    local trans = fsm_mod.transition(ctx.registry, obj.id, found_trans.to, {})
                    if trans then
                        print(trans.message or ("You light " .. (obj.name or obj.id) .. "."))
                        show_hint(ctx, "extinguish", "You can extinguish flames with 'extinguish' or 'blow out'.")
                        show_hint(ctx, "burn", "You can burn flammable objects with 'burn [item]' while holding a flame.")
                    else
                        print("You can't light " .. (obj.name or "that") .. ".")
                    end
                    return
                end
            end
            -- #172: flammable objects without light states → redirect to burn
            local mat = obj.material and materials.get(obj.material)
            local flammability = mat and mat.flammability or 0
            if flammability >= BURN_THRESHOLD then
                handlers["burn"](ctx, noun)
                return
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
                    show_hint(ctx, "extinguish", "You can extinguish flames with 'extinguish' or 'blow out'.")
                    show_hint(ctx, "burn", "You can burn flammable objects with 'burn [item]' while holding a flame.")
                end
                return
            end

            -- #169: Find fire_source tool (explicit tool, hand scan, inventory)
            local tool = find_fire_source(ctx, mut_data.requires_tool, obj)
            if not tool then
                if mut_data.fail_message then
                    print(mut_data.fail_message)
                else
                    local hint = find_unlit_source_name(ctx)
                    if hint then
                        print("The " .. hint .. " isn't lit. Try 'light " .. hint .. "' first.")
                    else
                        print("You'll need a flame to light that.")
                    end
                end
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
                show_hint(ctx, "extinguish", "You can extinguish flames with 'extinguish' or 'blow out'.")
                show_hint(ctx, "burn", "You can burn flammable objects with 'burn [item]' while holding a flame.")
            end
            return
        end

        -- No tool required -- original behavior
        if perform_mutation(ctx, obj, mut_data) then
            local mutated = ctx.registry:get(obj.id)
            print(mut_data.message
                or ("You light " .. (mutated and mutated.name or obj.id) .. ". It casts a warm glow."))
            show_hint(ctx, "extinguish", "You can extinguish flames with 'extinguish' or 'blow out'.")
            show_hint(ctx, "burn", "You can burn flammable objects with 'burn [item]' while holding a flame.")
        end
    end

    handlers["ignite"] = handlers["light"]
    handlers["relight"] = handlers["light"]

    ---------------------------------------------------------------------------
    -- EXTINGUISH
    ---------------------------------------------------------------------------
    handlers["extinguish"] = function(ctx, noun)
        if noun == "" then
            print("Extinguish what? Try 'extinguish [item]' to put out a flame.")
            return
        end

        local obj = find_in_inventory(ctx, noun)
        if not obj then obj = find_visible(ctx, noun) end
        if not obj then
            err_not_found(ctx)
            return
        end

        -- FSM path
        if obj.states then
            local transitions = fsm_mod.get_transitions(obj)
            local target_trans
            for _, t in ipairs(transitions) do
                if t.verb == "extinguish" then target_trans = t; break end
                if t.aliases then
                    for _, alias in ipairs(t.aliases) do
                        if alias == "extinguish" then target_trans = t; break end
                    end
                    if target_trans then break end
                end
            end
            if target_trans then
                local trans, err = fsm_mod.transition(ctx.registry, obj.id, target_trans.to, {})
                if trans then
                    print(trans.message or ("You extinguish " .. (obj.name or obj.id) .. "."))
                else
                    print("You can't extinguish " .. (obj.name or "that") .. ".")
                end
            else
                -- BUG-106b: Check if object CAN be extinguished but just isn't lit
                local has_extinguish = false
                for _, t in ipairs(obj.transitions or {}) do
                    if t.verb == "extinguish" then has_extinguish = true; break end
                    if t.aliases then
                        for _, a in ipairs(t.aliases) do
                            if a == "extinguish" or a == "blow" or a == "put out" or a == "snuff" then
                                has_extinguish = true; break
                            end
                        end
                    end
                    if has_extinguish then break end
                end
                if has_extinguish then
                    local display = (obj.name or "that"):gsub("^a%s+", ""):gsub("^an%s+", "")
                    print("The " .. display .. " isn't lit.")
                else
                    print("You can't extinguish " .. (obj.name or "that") .. ".")
                end
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
    -- STRIKE {A} ON {B} -- compound tool verb for fire-making
    -- Also handles "strike head", "strike arm" as hit synonyms.
    -- FSM path: A is a match with inline states, B is something with has_striker.
    -- Legacy path: matchbox with fire_source charges.
    ---------------------------------------------------------------------------
    handlers["strike"] = function(ctx, noun)
        if noun == "" then
            print("Strike what? (Try: strike match on matchbox)")
            return
        end

        -- Try body area self-hit first (e.g., "strike arm", "strike head")
        local is_self, body_area = parse_self_infliction(noun)
        if is_self and body_area then
            handlers["hit"](ctx, noun)
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
        if match_obj and match_obj.states then
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
    -- BURN — material-derived burnability (#120)
    -- Burnability is determined by the object's material flammability property.
    -- Threshold: flammability >= 0.3 → burnable.
    -- Objects with burn FSM states use those transitions; others get destroyed.
    ---------------------------------------------------------------------------
    handlers["burn"] = function(ctx, noun)
        if noun == "" then
            print("Burn what? Try 'burn [item]' on something flammable while you have a flame.")
            return
        end

        local obj = find_in_inventory(ctx, noun)
        if not obj then
            obj = find_visible(ctx, noun)
        end
        if not obj then
            err_not_found(ctx)
            return
        end

        -- If the object has a "light" FSM transition, redirect to the light handler
        if obj.states then
            local transitions = fsm_mod.get_transitions(obj)
            for _, t in ipairs(transitions) do
                if t.from == obj._state and (t.verb == "light" or t.verb == "ignite") then
                    handlers["light"](ctx, noun)
                    return
                end
            end
        end

        -- Need a flame
        local has_fire = (ctx.player.state.has_flame and ctx.player.state.has_flame > 0)
            or find_tool_in_inventory(ctx, "fire_source") ~= nil
        if not has_fire then
            local hint = find_unlit_source_name(ctx)
            if hint then
                print("The " .. hint .. " isn't lit. Try 'light " .. hint .. "' first.")
            else
                print("You'll need a flame. You could light a match, if you had one.")
            end
            return
        end

        -- Derive burnability from material flammability (Principle 9: material consistency)
        local mat = obj.material and materials.get(obj.material)
        local flammability = mat and mat.flammability or 0

        if flammability < BURN_THRESHOLD then
            print("You can't burn " .. (obj.name or "that") .. ".")
            return
        end

        -- FSM path: check for "burn" transition (intact → burning → burnt/ash)
        if obj.states then
            local transitions = fsm_mod.get_transitions(obj)
            local burn_trans
            for _, t in ipairs(transitions) do
                if t.verb == "burn" then burn_trans = t; break end
                if t.aliases then
                    for _, alias in ipairs(t.aliases) do
                        if alias == "burn" then burn_trans = t; break end
                    end
                    if burn_trans then break end
                end
            end
            if burn_trans then
                local trans, err = fsm_mod.transition(ctx.registry, obj.id, burn_trans.to, {})
                if trans then
                    print(trans.message or ("You hold the flame to " .. (obj.name or "it") .. ". It catches fire."))
                    if trans.spawns then spawn_objects(ctx, trans.spawns) end
                else
                    print("You can't burn " .. (obj.name or "that") .. " right now.")
                end
                return
            end
        end

        -- Mutation path: check for "burn" mutation
        local mut_data = find_mutation(obj, "burn")
        if mut_data then
            if perform_mutation(ctx, obj, mut_data) then
                print(mut_data.message or ("You hold the flame to " .. (obj.name or "it") .. ". It catches fire and burns away to ash."))
            end
            return
        end

        -- Generic destruction: flammable material, no custom burn behavior
        print("You hold the flame to " .. (obj.name or "it") .. ". It catches fire and burns away to ash.")
        remove_from_location(ctx, obj)
        ctx.registry:remove(obj.id)
    end
end

return M
