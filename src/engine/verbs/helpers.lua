-- engine/verbs/helpers.lua
-- V1 verb handlers for the bedroom REPL.
-- Each handler has signature: function(context, noun)
-- Context is injected by the game loop at dispatch time.
--
-- Ownership:
--   Smithers (UI Engineer): Text presentation, sensory verb output, help,
--     error message wording, pronoun resolution, light-level-aware display.
--   Bart (Architect): Game state mutations, FSM interactions, containment,
--     tool resolution, core verb logic (take, put, open, close, crafting, etc.)

local H = {}

local core = require("engine.verbs.helpers.core")
local inventory = require("engine.verbs.helpers.inventory")
local search = require("engine.verbs.helpers.search")
local tools = require("engine.verbs.helpers.tools")
local mutation = require("engine.verbs.helpers.mutation")
local combat = require("engine.verbs.helpers.combat")
local portal = require("engine.verbs.helpers.portal")

-- Prime Directive: Helpful error messages
local function err_not_found(ctx)
    -- Tier 5: Show disambiguation prompt if fuzzy matching found multiple candidates
    if ctx and ctx.disambiguation_prompt then
        print(ctx.disambiguation_prompt)
        ctx.disambiguation_prompt = nil
        return
    end
    
    -- WAVE-2a: Kid-friendly messages for E-rated worlds (Wyatt's World)
    if ctx and ctx.world and ctx.world.rating == "E" then
        print("Hmm, try looking around for clues!")
        return
    end
    
    print("You don't notice anything called that nearby. Try 'search around' to discover what's here.")
end

local function err_cant_do_that()
    -- WAVE-2a: Kid-friendly messages for E-rated worlds
    if _G._context and _G._context.world and _G._context.world.rating == "E" then
        print("That's not something you can do here. Try reading the signs!")
        return
    end
    
    print("That doesn't seem to work. Maybe try examining it first, or type 'help' for ideas.")
end

local function err_nothing_happens(obj)
    -- WAVE-2a: Kid-friendly messages for E-rated worlds
    if _G._context and _G._context.world and _G._context.world.rating == "E" then
        print("That didn't work. What else could you try?")
        return
    end
    
    print("Nothing obvious happens. Try examining it more closely, or try a different approach.")
end

-- One-shot tutorial hint — shows once per player session, tracked in player.state.
local function show_hint(ctx, hint_id, message)
    if not ctx.player or not ctx.player.state then return false end
    if not ctx.player.state.hints_shown then
        ctx.player.state.hints_shown = {}
    end
    if ctx.player.state.hints_shown[hint_id] then return false end
    ctx.player.state.hints_shown[hint_id] = true
    -- Suppress tutorial hints in headless mode (automated testing)
    if ctx.headless then return true end
    print("(Hint: " .. message .. ")")
    return true
end

H.fsm_mod = core.fsm_mod
H.presentation = core.presentation
H.preprocess = core.preprocess
H.traverse_effects = core.traverse_effects
H.effects = core.effects
H.materials = core.materials
H.context_window = core.context_window
H.fuzzy = core.fuzzy
H.GAME_SECONDS_PER_REAL_SECOND = core.GAME_SECONDS_PER_REAL_SECOND
H.GAME_START_HOUR = core.GAME_START_HOUR
H.DAYTIME_START = core.DAYTIME_START
H.DAYTIME_END = core.DAYTIME_END
H.interaction_verbs = search.interaction_verbs
H.get_all_carried_ids = core.get_all_carried_ids
H.next_instance_id = inventory.next_instance_id
H._hid = inventory._hid
H._hobj = inventory._hobj
H.err_not_found = err_not_found
H.err_cant_do_that = err_cant_do_that
H.err_nothing_happens = err_nothing_happens
H.show_hint = show_hint
H.matches_keyword = search.matches_keyword
H.hands_full = inventory.hands_full
H.first_empty_hand = inventory.first_empty_hand
H.which_hand = inventory.which_hand
H.count_hands_used = inventory.count_hands_used
H.find_part = inventory.find_part
H.detach_part = inventory.detach_part
H.reattach_part = inventory.reattach_part
H._fv_room = search._fv_room
H._fv_surfaces = search._fv_surfaces
H._fv_parts = search._fv_parts
H._fv_hands = function(kw, reg, player) return search._fv_hands(kw, reg, player, H._hobj) end
H._fv_bags = function(kw, reg, player) return search._fv_bags(kw, reg, player, H._hobj) end
H._fv_worn = search._fv_worn
H.find_visible = search.find_visible
H.find_in_inventory = search.find_in_inventory
H.find_tool_in_inventory = tools.find_tool_in_inventory
H.provides_capability = tools.provides_capability
H.find_visible_tool = tools.find_visible_tool
H.consume_tool_charge = tools.consume_tool_charge
H.remove_from_location = inventory.remove_from_location
H.container_contents_accessible = mutation.container_contents_accessible
H.find_mutation = mutation.find_mutation
H.spawn_objects = mutation.spawn_objects
H.perform_mutation = mutation.perform_mutation
H.inventory_weight = inventory.inventory_weight
H.move_spatial_object = mutation.move_spatial_object
H.random_body_area = combat.random_body_area
H.parse_self_infliction = combat.parse_self_infliction
H.handle_self_infliction = combat.handle_self_infliction
H.get_game_time = core.get_game_time
H.is_daytime = core.is_daytime
H.format_time = core.format_time
H.time_of_day_desc = core.time_of_day_desc
H.get_light_level = core.get_light_level
H.has_some_light = core.has_some_light
H.vision_blocked_by_worn = core.vision_blocked_by_worn
H.try_fsm_verb = combat.try_fsm_verb
H.find_portal_by_keyword = portal.find_portal_by_keyword
H.sync_bidirectional_portal = portal.sync_bidirectional_portal
H.find_exit_by_keyword = search.find_exit_by_keyword

return H
