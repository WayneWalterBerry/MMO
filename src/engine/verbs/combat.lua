-- engine/verbs/combat.lua
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
local random_body_area = H.random_body_area
local parse_self_infliction = H.parse_self_infliction
local handle_self_infliction = H.handle_self_infliction

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
    -- Self-infliction: shared logic for stab/cut/slash self
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- STAB {target} WITH {tool}  /  STAB SELF
    ---------------------------------------------------------------------------
    handlers["stab"] = function(ctx, noun)
        if handle_self_infliction(ctx, noun, "stab", "on_stab") then return end
        -- Stab is only for self-infliction — there are no world objects to stab
        print("You can only stab yourself. (Try: stab self with <weapon>)")
    end
    handlers["jab"] = handlers["stab"]
    handlers["pierce"] = handlers["stab"]
    handlers["stick"] = handlers["stab"]

    ---------------------------------------------------------------------------
    -- HIT {body area}  /  PUNCH / STRIKE / BASH / BONK / SMASH / THUMP
    -- Self-infliction for blunt trauma: head → unconsciousness, limbs → bruise
    ---------------------------------------------------------------------------
    handlers["hit"] = function(ctx, noun)
        if noun == "" then
            print("Hit what?")
            return
        end

        local is_self, body_area, tool_word = parse_self_infliction(noun)
        if not is_self then
            -- Not self — in V1, hit is self-only
            print("You can only hit yourself right now. (Try: hit head)")
            return
        end

        -- Resolve body area (default to random if "self")
        if not body_area then
            body_area = random_body_area()
        end

        -- Load injury module
        local inj_ok, injury_mod = pcall(require, "engine.injuries")
        if not inj_ok then
            print("Something goes wrong.")
            return
        end

        -- Head hit → concussion (unconsciousness)
        if body_area == "head" then
            local base_duration = 5  -- bare fist: 5 turns

            -- Check for helmet (worn head armor) — reduces duration
            local helmet = nil
            if ctx.player.worn then
                for _, worn_id in ipairs(ctx.player.worn) do
                    local obj = ctx.registry and ctx.registry.get and ctx.registry:get(worn_id)
                    if not obj then
                        obj = _hobj(worn_id, ctx.registry)
                    end
                    if obj and (obj.wear_slot == "head" or obj.is_helmet) then
                        helmet = obj
                        break
                    end
                end
            end

            local reduction = 0
            if helmet then
                reduction = helmet.reduces_unconsciousness or 0.5
            end

            local final_duration = math.max(1, math.floor(base_duration * (1 - reduction)))

            -- Suppress inflict message (we print our own narration)
            local old_print = _G.print
            _G.print = function() end
            local instance = injury_mod.inflict(ctx.player, "concussion", "self-inflicted (bare fist, hit)", "head", 5)
            _G.print = old_print

            if not instance then
                print("You hit your head, but it doesn't seem to have much effect.")
                return
            end

            -- Trigger unconsciousness
            ctx.player.consciousness = ctx.player.consciousness or {}
            ctx.player.consciousness.state = "unconscious"
            ctx.player.consciousness.wake_timer = final_duration
            ctx.player.consciousness.cause = "blow-to-head"
            ctx.player.consciousness.unconscious_since = ctx.time_offset or 0

            if helmet then
                if final_duration <= 1 then
                    print("You punch your helmeted head. It clangs metallically. Your ears ring, but the helmet took most of the impact.")
                else
                    print("You slam your fist against your helmeted head. The impact rattles you even through the protection. Stars flash across your vision...")
                end
                -- Degrade worn head armor from the impact (#155)
                local armor_ok2, armor_mod = pcall(require, "engine.armor")
                if armor_ok2 and armor_mod.degrade_covering_armor then
                    armor_mod.degrade_covering_armor(ctx.player, "head", 5, "blunt")
                end
            else
                print("You slam your fist hard against the side of your head. Stars explode across your vision. The world tilts and fades...")
            end
            return
        end

        -- Non-head hit → bruise
        local old_print = _G.print
        _G.print = function() end
        local instance = injury_mod.inflict(ctx.player, "bruised", "self-inflicted (bare fist, hit)", body_area, 4)
        _G.print = old_print

        if not instance then
            print("You punch yourself, but it doesn't seem to have much effect.")
            return
        end

        -- Narration by body area
        local narrations = {
            ["left arm"]   = "You punch yourself in the left arm. Sharp pain blooms across the muscle.",
            ["right arm"]  = "You punch yourself in the right arm. Sharp pain blooms across the muscle.",
            ["left hand"]  = "You drive your fist into your left hand. The knuckles ache.",
            ["right hand"] = "You drive your fist into your right hand. The knuckles ache.",
            ["left leg"]   = "You drive your fist down against your left leg. Intense pain shoots through the limb.",
            ["right leg"]  = "You drive your fist down against your right leg. Intense pain shoots through the limb.",
            ["torso"]      = "You drive your fist into your ribs. Air explodes from your lungs.",
            ["stomach"]    = "You punch yourself in the stomach. You double over, gasping.",
        }
        print(narrations[body_area] or ("You punch your " .. body_area .. ". That hurt."))
    end
    handlers["punch"]  = handlers["hit"]
    handlers["bash"]   = handlers["hit"]
    handlers["bonk"]   = handlers["hit"]
    handlers["thump"]  = handlers["hit"]
    handlers["smack"]  = handlers["hit"]
    handlers["bang"]   = handlers["hit"]
    handlers["slap"]   = handlers["hit"]
    handlers["whack"]  = handlers["hit"]
    handlers["headbutt"] = handlers["hit"]
    handlers["toss"]   = handlers["drop"]
    handlers["throw"]  = handlers["drop"]

    ---------------------------------------------------------------------------
    -- CUT {target} WITH {tool}  /  CUT SELF WITH {tool}
    ---------------------------------------------------------------------------
    handlers["cut"] = function(ctx, noun)
        if noun == "" then
            print("Cut what? (Try: cut <thing> with <tool>)")
            return
        end

        -- Try self-infliction first
        if handle_self_infliction(ctx, noun, "cut", "on_cut") then return end

        -- CUT {object} — world object cutting (existing logic)
        local target_word, tool_word = noun:match("^(.+)%s+with%s+(.+)$")
        if not target_word then target_word = noun end

        if not has_some_light(ctx) then
            print("It is too dark to see what you're doing.")
            return
        end

        local obj = find_visible(ctx, target_word)
        if not obj then
            err_not_found(ctx)
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
    handlers["slice"] = handlers["cut"]
    handlers["nick"] = handlers["cut"]

    ---------------------------------------------------------------------------
    -- SLASH {target} WITH {tool}  /  SLASH SELF WITH {tool}
    ---------------------------------------------------------------------------
    handlers["slash"] = function(ctx, noun)
        if noun == "" then
            print("Slash what?")
            return
        end

        -- Try self-infliction first
        if handle_self_infliction(ctx, noun, "slash", "on_slash") then return end

        -- Fall through to cut logic for world objects
        handlers["cut"](ctx, noun)
    end
    handlers["carve"] = handlers["slash"]

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
            ctx.player.state.bleed_ticks = 8
            print("You prick your finger with " .. (tool.name or "the sharp point") .. ". A bead of blood forms.")
            print("Your hands are now bloody.")
            return
        end

        print("You can only prick yourself. (Try: prick self with <pin>)")
    end
end

return M
