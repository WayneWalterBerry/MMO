-- engine/verbs/init.lua
-- Registry for verb handlers.

local verbs = {}

function verbs.create()
    local handlers = {}

    local sensory = require("engine.verbs.sensory")
    local acquisition = require("engine.verbs.acquisition")
    local containers = require("engine.verbs.containers")
    local destruction = require("engine.verbs.destruction")
    local fire = require("engine.verbs.fire")
    local combat = require("engine.verbs.combat")
    local crafting = require("engine.verbs.crafting")
    local equipment = require("engine.verbs.equipment")
    local survival = require("engine.verbs.survival")
    local movement = require("engine.verbs.movement")
    local meta = require("engine.verbs.meta")
    local traps = require("engine.verbs.traps")

    sensory.register(handlers)
    acquisition.register(handlers)
    containers.register(handlers)
    destruction.register(handlers)
    fire.register(handlers)
    combat.register(handlers)
    crafting.register(handlers)
    equipment.register(handlers)
    survival.register(handlers)
    movement.register(handlers)
    meta.register(handlers)
    traps.register(handlers)

    ---------------------------------------------------------------------------
    -- WAVE-3: CATCH / GRAB / SNATCH — creature interaction verb
    ---------------------------------------------------------------------------
    do
        local cr_ok, cr_mod = pcall(require, "engine.creatures")
        local inj_ok, injury_mod = pcall(require, "engine.injuries")

        local CATCHABLE_SIZES = { tiny = true, small = true }

        local function keyword_matches(obj, kw)
            if obj.id and obj.id:lower() == kw then return true end
            if type(obj.keywords) == "table" then
                for _, k in ipairs(obj.keywords) do
                    if k:lower() == kw then return true end
                end
            end
            if obj.name then
                local padded = " " .. obj.name:lower() .. " "
                if padded:find(" " .. kw .. " ", 1, true) then return true end
            end
            return false
        end

        local function find_creature_by_keyword(ctx, keyword)
            if not cr_ok or not cr_mod then return nil end
            local kw = keyword:lower()
                :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
            local room_id = type(ctx.current_room) == "table"
                and ctx.current_room.id or ctx.current_room
            local room_creatures = cr_mod.get_creatures_in_room(ctx.registry, room_id)
            for _, c in ipairs(room_creatures) do
                if keyword_matches(c, kw) then return c end
            end
            return nil
        end

        local function find_room_object_by_keyword(ctx, keyword)
            local kw = keyword:lower()
                :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
            local room = ctx.current_room
            for _, obj_id in ipairs(room.contents or {}) do
                local obj = ctx.registry:get(obj_id)
                if obj and keyword_matches(obj, kw) then return obj end
            end
            return nil
        end

        handlers["catch"] = function(ctx, noun)
            if noun == "" then
                print("Catch what?")
                return
            end

            local creature = find_creature_by_keyword(ctx, noun)

            if not creature then
                local obj = find_room_object_by_keyword(ctx, noun)
                if obj then
                    if obj._state == "dead" or obj.alive == false then
                        print("It's dead. You could try to take it.")
                    else
                        print("You can't grab that.")
                    end
                else
                    print("You don't see that here.")
                end
                return
            end

            if ctx.player.hands then
                if ctx.player.hands[1] ~= nil and ctx.player.hands[2] ~= nil then
                    print("Your hands are full.")
                    return
                end
            elseif ctx.player.left_hand ~= nil and ctx.player.right_hand ~= nil then
                print("Your hands are full.")
                return
            end

            if not CATCHABLE_SIZES[creature.size or "medium"] then
                print("You can't grab that.")
                return
            end

            -- Success: creature panics, player gets bitten
            print("You grab " .. (creature.name or "it") .. "! It squirms and bites!")

            if creature.drives and creature.drives.fear then
                creature.drives.fear.value = creature.drives.fear.max or 100
            end

            if cr_ok and cr_mod then
                local room_id = type(ctx.current_room) == "table"
                    and ctx.current_room.id or ctx.current_room
                cr_mod.emit_stimulus(room_id, "player_attacks", { target = creature.id })
            end

            -- Inflict bite injury (D-COMBAT-NPC-PHASE-SEQUENCING: simple direct call)
            if inj_ok and injury_mod then
                injury_mod.inflict(ctx.player, "minor-cut", creature.id or "creature", "arms", 2)
            end
        end
        local original_grab = handlers["grab"]
        handlers["grab"] = function(ctx, noun)
            if noun ~= "" then
                local creature = find_creature_by_keyword(ctx, noun)
                if creature then
                    return handlers["catch"](ctx, noun)
                end
            end
            if original_grab then
                return original_grab(ctx, noun)
            end
            return handlers["catch"](ctx, noun)
        end
        handlers["snatch"] = handlers["catch"]
    end

    -- Consciousness gate: block all verbs while the player is unconscious.
    -- Cache wrappers by original function to preserve alias identity
    -- (e.g., handlers["i"] == handlers["inventory"]).
    local raw = {}
    for k, v in pairs(handlers) do raw[k] = v end
    local wrapper_cache = {}
    for verb, fn in pairs(raw) do
        if not wrapper_cache[fn] then
            wrapper_cache[fn] = function(ctx, noun)
                if ctx.player and ctx.player.consciousness
                   and ctx.player.consciousness.state == "unconscious" then
                    print("You are unconscious.")
                    return
                end
                return fn(ctx, noun)
            end
        end
        handlers[verb] = wrapper_cache[fn]
    end

    return handlers
end

return verbs
