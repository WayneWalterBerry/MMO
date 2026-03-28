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
        local original_take = handlers["take"]
        handlers["take"] = function(ctx, noun)
            if noun ~= "" then
                local creature = find_creature_by_keyword(ctx, noun)
                if creature then
                    return handlers["catch"](ctx, noun)
                end
            end
            if original_take then
                return original_take(ctx, noun)
            end
            return handlers["catch"](ctx, noun)
        end
        handlers["grab"] = handlers["take"]
        handlers["snatch"] = handlers["catch"]
    end

    ---------------------------------------------------------------------------
    -- WAVE-6: ATTACK verb → combat FSM trigger + stance prompt + flee
    -- Wires combat engine (Bart's src/engine/combat/init.lua) into verb layer.
    ---------------------------------------------------------------------------
    do
        local combat_ok, combat_mod = pcall(require, "engine.combat")
        local cr_ok, cr_mod = pcall(require, "engine.creatures")
        local inj_ok, injury_mod = pcall(require, "engine.injuries")
        local pres_ok, pres_mod = pcall(require, "engine.ui.presentation")

        local function kw_match(obj, kw)
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

        local function find_creature(ctx, keyword)
            if not cr_ok or not cr_mod then return nil end
            local kw = keyword:lower()
                :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
            local room_id = type(ctx.current_room) == "table"
                and ctx.current_room.id or ctx.current_room
            local creatures = cr_mod.get_creatures_in_room(ctx.registry, room_id)
            -- #344: Collect all matching creatures for disambiguation
            local matches = {}
            for _, c in ipairs(creatures) do
                if kw_match(c, kw) then matches[#matches + 1] = c end
            end
            if #matches == 0 then return nil end
            if #matches == 1 then return matches[1] end
            -- All same base id → fungible, return first
            local all_same = true
            for i = 2, #matches do
                if matches[i].id ~= matches[1].id then
                    all_same = false; break
                end
            end
            if all_same then return matches[1] end
            -- Different creatures: prompt disambiguation
            local names = {}
            for _, c in ipairs(matches) do
                names[#names + 1] = c.name or c.id
            end
            print("Which one? " .. table.concat(names, ", ") .. "?")
            ctx.disambiguation_prompt = names
            return nil
        end

        local function emit_combat_stimulus(ctx, target_id)
            local room_id = ctx.current_room and ctx.current_room.id
                or ctx.player and ctx.player.location
            if not room_id then return end
            if cr_ok and cr_mod and cr_mod.emit_stimulus then
                cr_mod.emit_stimulus(room_id, "player_attacks", {
                    source = "player", target = target_id,
                })
            end
        end

        local function find_held_weapon(ctx)
            if not ctx.player or not ctx.player.hands then return nil end
            for i = 1, 2 do
                local hand = ctx.player.hands[i]
                if hand then
                    local obj = type(hand) == "table" and hand
                        or (ctx.registry and ctx.registry.get and ctx.registry:get(hand))
                    if obj and obj.combat then return obj end
                end
            end
            return nil
        end

        local function get_traversable_exits(ctx)
            local exits = {}
            local room = ctx.current_room
            if not room or not room.exits then return exits end
            for dir, exit_data in pairs(room.exits) do
                local portal_obj = nil
                if type(exit_data) == "table" and exit_data.portal then
                    portal_obj = ctx.registry:get(exit_data.portal)
                end
                if portal_obj and portal_obj.portal then
                    local state = portal_obj.states and portal_obj.states[portal_obj._state]
                    if state and state.traversable then
                        exits[#exits + 1] = dir
                    end
                else
                    exits[#exits + 1] = dir
                end
            end
            return exits
        end

        local function has_light(ctx)
            if pres_ok and pres_mod and pres_mod.has_some_light then
                return pres_mod.has_some_light(ctx)
            end
            return true
        end

        local INTERRUPT_MSG = {
            weapon_break = "Your weapon cracks!",
            armor_fail = "Your armor fails!",
            stance_ineffective = "Your stance isn't working!",
        }

        local function prompt_stance(ctx, is_interrupt, interrupt_reason)
            -- WAVE-3: Stress flee_bias — in headless mode, stress can auto-select flee
            if ctx.headless then
                local inj_ok, inj_mod = pcall(require, "engine.injuries")
                if inj_ok and inj_mod and inj_mod.get_stress_effects then
                    local effects = inj_mod.get_stress_effects(ctx.player)
                    local flee_bias = effects.flee_bias or 0
                    if flee_bias > 0 and math.random() < flee_bias then
                        return "flee"
                    end
                end
                return "balanced"
            end
            if is_interrupt and interrupt_reason then
                print("[INTERRUPT: " .. (INTERRUPT_MSG[interrupt_reason] or interrupt_reason) .. "]")
            end
            -- WAVE-3: Stress flee hint in interactive mode
            local stress_hint = ""
            local inj_ok2, inj_mod2 = pcall(require, "engine.injuries")
            if inj_ok2 and inj_mod2 and inj_mod2.get_stress_effects then
                local effects = inj_mod2.get_stress_effects(ctx.player)
                if effects.flee_bias and effects.flee_bias > 0 then
                    stress_hint = " (your instincts scream to flee!)"
                end
            end
            if is_interrupt then
                io.write("Combat stance? > aggressive | defensive | balanced | flee" .. stress_hint .. "\n> ")
            else
                io.write("Combat stance? > aggressive | defensive | balanced" .. stress_hint .. "\n> ")
            end
            io.flush()
            local input = io.read()
            if not input then return "balanced" end
            input = input:lower():gsub("^%s+", ""):gsub("%s+$", "")
            if input == "aggressive" or input == "defensive" or input == "balanced" then
                return input
            end
            if input == "flee" or input:match("^flee") or input == "run" then
                return "flee"
            end
            return "balanced"
        end

        -- Forward declarations
        local attempt_flee, run_combat_encounter

        attempt_flee = function(ctx, creature, light)
            local player = ctx.player
            local player_speed = player.combat and player.combat.speed or 3
            local creature_speed = creature.combat and creature.combat.speed or 3

            -- Leg injury modifier
            if player.injuries then
                for _, inj in ipairs(player.injuries) do
                    local z = inj.location or inj.zone or ""
                    if z:match("leg") or z:match("feet") or z:match("ankle") then
                        player_speed = player_speed * 0.7
                        break
                    end
                end
            end

            -- WAVE-3: Stress movement_penalty reduces flee speed
            local inj_ok3, inj_mod3 = pcall(require, "engine.injuries")
            if inj_ok3 and inj_mod3 and inj_mod3.get_stress_effects then
                local effects = inj_mod3.get_stress_effects(player)
                local penalty = effects.movement_penalty or 0
                if penalty > 0 then
                    player_speed = player_speed * (1.0 - penalty)
                end
            end

            local flee_chance = player_speed / (player_speed + creature_speed)
            if math.random() <= flee_chance then
                -- Success: partial damage (GRAZE via "flee" response)
                if combat_ok and combat_mod then
                    local graze = combat_mod.resolve_exchange(
                        creature, player, nil, nil, "flee",
                        { light = light, stance = "balanced" }
                    )
                    if graze.narration and graze.narration ~= "" then
                        print(graze.narration)
                    end
                end
                local exits = get_traversable_exits(ctx)
                if #exits > 0 then
                    local dir = exits[math.random(#exits)]
                    print("You break free and run " .. dir .. "!")
                    handlers["go"](ctx, dir)
                else
                    print("You break free but there's nowhere to run!")
                end
                return true
            else
                print("You try to flee but " .. (creature.name or "the creature") .. " blocks your escape!")
                return false
            end
        end

        run_combat_encounter = function(ctx, creature, target_zone)
            if not combat_ok or not combat_mod then
                print("Something goes wrong.")
                return
            end

            local player = ctx.player
            local light = has_light(ctx)

            if not light then
                print("You can't see well — attacks will be less accurate.")
            end

            local weapon = find_held_weapon(ctx)
            local weapon_name = weapon and (weapon.name or weapon.id) or "bare fists"
            print("You engage " .. (creature.name or "the creature") .. " with " .. weapon_name .. "!")

            local stance = prompt_stance(ctx, false, nil)
            if stance == "flee" then
                attempt_flee(ctx, creature, light)
                return
            end

            local combat_state = { deflect_streak = 0 }
            local MAX_ROUNDS = 20

            for round = 1, MAX_ROUNDS do
                -- Re-check weapon each round (may have broken)
                local round_weapon = find_held_weapon(ctx) or weapon

                -- Creature defensive behavior
                local creature_response = "dodge"
                if creature.combat and creature.combat.defense then
                    creature_response = creature.combat.defense
                end

                -- Player attacks creature
                local result = combat_mod.resolve_exchange(
                    player, creature, round_weapon, target_zone,
                    creature_response,
                    { light = light, stance = stance }
                )

                if result.narration and result.narration ~= "" then
                    print(result.narration)
                end

                -- Creature death
                if result.defender_dead or (creature.health and creature.health <= 0) then
                    local cr_ok2, cr_mod = pcall(require, "engine.creatures")
                    local room = type(ctx.current_room) == "table" and ctx.current_room or nil
                    if not (cr_ok2 and cr_mod.handle_creature_death
                            and cr_mod.handle_creature_death(creature, ctx, room)) then
                        creature._state = "dead"
                        creature.animate = false
                        creature.portable = true
                        creature.alive = false
                    end
                    -- #345/#370: Use "The" + id for death message (capitalized, definite article)
                    local death_id = creature.id or "creature"
                    print("The " .. death_id .. " is dead!")
                    return
                end

                -- Creature counter-attack
                if creature.combat and creature.combat.natural_weapons then
                    local player_response = "dodge"
                    if stance == "defensive" then
                        player_response = "block"
                    end

                    local counter = combat_mod.resolve_exchange(
                        creature, player, nil, nil, player_response,
                        { light = light, stance = stance }
                    )
                    if counter.narration and counter.narration ~= "" then
                        print(counter.narration)
                    end

                    if player.health and player.health <= 0 then
                        print("You collapse from your wounds!")
                        return
                    end
                end

                -- Interrupt check (headless: never interrupt, run to completion)
                if not ctx.headless then
                    local interrupt = combat_mod.interrupt_check(result, combat_state)
                    if interrupt then
                        stance = prompt_stance(ctx, true, interrupt)
                        if stance == "flee" then
                            if attempt_flee(ctx, creature, light) then return end
                            print("You fail to escape! The creature presses its attack!")
                            stance = "balanced"
                        end
                        combat_state.deflect_streak = 0
                    end
                end

                -- Creature morale break / flee threshold
                local flee_threshold = creature.combat and creature.combat.behavior
                    and creature.combat.behavior.flee_threshold
                if flee_threshold then
                    local max_hp = creature.max_health or creature.health or 10
                    local hp_pct = (creature.health or 10) / max_hp
                    if hp_pct <= flee_threshold then
                        print((creature.name or "The creature") .. " turns and flees!")
                        creature._state = "fled"
                        if cr_ok and cr_mod and cr_mod.emit_stimulus then
                            local room_id = type(ctx.current_room) == "table"
                                and ctx.current_room.id or ctx.current_room
                            cr_mod.emit_stimulus(room_id, "creature_fled", {
                                creature = creature.id,
                            })
                        end
                        return
                    end
                end
            end

            print("The combat reaches a stalemate. Both combatants back off, wary.")
        end

        -- Save original hit handler (self-infliction from combat.lua)
        local original_hit = handlers["hit"]

        handlers["attack"] = function(ctx, noun)
            if noun == "" then
                print("Attack what?")
                return
            end

            -- Parse "attack <creature> <zone>"
            local words = {}
            for w in noun:gmatch("%S+") do words[#words + 1] = w end

            local creature_word = words[1]
            local target_zone = words[2]

            local creature = find_creature(ctx, creature_word)
            if not creature and not ctx.disambiguation_prompt then
                -- Try full noun as creature name (multi-word: "giant rat")
                creature = find_creature(ctx, noun)
                target_zone = nil
            end

            -- #344: If disambiguation was triggered, return early
            if ctx.disambiguation_prompt then
                return
            end

            if creature then
                if creature._state == "dead" or creature.alive == false then
                    print("It's already dead.")
                    return
                end
                emit_combat_stimulus(ctx, creature.id)
                run_combat_encounter(ctx, creature, target_zone)
                return
            end

            -- #331: Check for dead creatures matching keyword before "don't see" message
            local room_id = type(ctx.current_room) == "table"
                and ctx.current_room.id or ctx.current_room
            local room = type(ctx.current_room) == "table" and ctx.current_room or nil
            if room and room.contents then
                local kw = noun:lower()
                    :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
                for _, obj_id in ipairs(room.contents) do
                    local obj = ctx.registry and ctx.registry.get and ctx.registry:get(obj_id)
                    if obj and (obj._state == "dead" or obj.alive == false) and kw_match(obj, kw) then
                        print("It's already dead.")
                        return
                    end
                end
            end

            print("You don't see that here to attack.")
        end
        handlers["fight"]  = handlers["attack"]
        handlers["kill"]   = handlers["attack"]
        handlers["slay"]   = handlers["attack"]
        handlers["murder"] = handlers["attack"]

        -- #331: Helper to check for dead creatures in room contents
        local function check_dead_creature(ctx, keyword)
            local room = type(ctx.current_room) == "table" and ctx.current_room or nil
            if not room or not room.contents then return false end
            local kw = keyword:lower()
                :gsub("^the%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
            for _, obj_id in ipairs(room.contents) do
                local obj = ctx.registry and ctx.registry.get and ctx.registry:get(obj_id)
                if obj and (obj._state == "dead" or obj.alive == false) and kw_match(obj, kw) then
                    return true
                end
            end
            return false
        end

        -- #358: Extend stab/jab/pierce: try creature combat first, fall through to self-infliction
        local original_stab = handlers["stab"]
        handlers["stab"] = function(ctx, noun)
            if noun ~= "" then
                local first_word = noun:match("^(%S+)")
                local creature = find_creature(ctx, first_word)
                if creature and creature.alive ~= false and creature._state ~= "dead" then
                    return handlers["attack"](ctx, noun)
                end
                -- #331: dead creature check before falling through
                if check_dead_creature(ctx, first_word) then
                    print("It's already dead.")
                    return
                end
            end
            if original_stab then return original_stab(ctx, noun) end
            print("Stab what?")
        end
        handlers["jab"]    = handlers["stab"]
        handlers["pierce"] = handlers["stab"]
        handlers["stick"]  = handlers["stab"]

        -- Extend hit/strike/swing: try creature combat first, fall through
        handlers["hit"] = function(ctx, noun)
            if noun ~= "" then
                local first_word = noun:match("^(%S+)")
                local creature = find_creature(ctx, first_word)
                if creature and creature.alive ~= false and creature._state ~= "dead" then
                    return handlers["attack"](ctx, noun)
                end
                -- #331: dead creature check before falling through
                if check_dead_creature(ctx, first_word) then
                    print("It's already dead.")
                    return
                end
            end
            if original_hit then return original_hit(ctx, noun) end
            print("Hit what?")
        end
        -- Re-sync aliases set by combat.lua so identity checks pass
        handlers["punch"]    = handlers["hit"]
        handlers["bash"]     = handlers["hit"]
        handlers["bonk"]     = handlers["hit"]
        handlers["thump"]    = handlers["hit"]
        handlers["smack"]    = handlers["hit"]
        handlers["bang"]     = handlers["hit"]
        handlers["slap"]     = handlers["hit"]
        handlers["whack"]    = handlers["hit"]
        handlers["headbutt"] = handlers["hit"]
        handlers["kick"]     = handlers["hit"]
        handlers["stomp"]    = handlers["hit"]
        handlers["trample"]  = handlers["hit"]
        handlers["stamp"]    = handlers["hit"]
        handlers["squash"]   = handlers["hit"]
        handlers["crush"]    = handlers["hit"]
        handlers["squish"]   = handlers["hit"]

        -- strike: preserve fire.lua match-striking, add creature combat fallback
        local original_strike = handlers["strike"]
        handlers["strike"] = function(ctx, noun)
            if noun ~= "" then
                local first_word = noun:match("^(%S+)")
                local creature = find_creature(ctx, first_word)
                if creature and creature.alive ~= false and creature._state ~= "dead" then
                    return handlers["attack"](ctx, noun)
                end
                -- #331: dead creature check before falling through
                if check_dead_creature(ctx, first_word) then
                    print("It's already dead.")
                    return
                end
            end
            if original_strike then return original_strike(ctx, noun) end
            print("Strike what?")
        end

        handlers["swing"] = function(ctx, noun)
            if noun ~= "" then
                local first_word = noun:match("^(%S+)")
                local creature = find_creature(ctx, first_word)
                if creature and creature.alive ~= false and creature._state ~= "dead" then
                    return handlers["attack"](ctx, noun)
                end
                -- #331: dead creature check before falling through
                if check_dead_creature(ctx, first_word) then
                    print("It's already dead.")
                    return
                end
            end
            print("Swing at what?")
        end

        -- FLEE verb (standalone — works in and out of combat)
        handlers["flee"] = function(ctx, noun)
            -- Strip "away" — "flee away" / "run away" are just flee
            if noun == "away" then noun = "" end

            if not cr_ok or not cr_mod then
                print("There's nothing to flee from.")
                return
            end
            local room_id = type(ctx.current_room) == "table"
                and ctx.current_room.id or ctx.current_room
            local room_creatures = cr_mod.get_creatures_in_room(ctx.registry, room_id)
            local threat = nil
            for _, c in ipairs(room_creatures) do
                if c.alive ~= false and c._state ~= "dead" and c._state ~= "fled" then
                    threat = c
                    break
                end
            end
            if not threat then
                if noun ~= "" then
                    handlers["go"](ctx, noun)
                else
                    print("There's nothing to flee from.")
                end
                return
            end
            local light = has_light(ctx)
            if not attempt_flee(ctx, threat, light) then
                print("You're still here, facing " .. (threat.name or "the creature") .. ".")
            end
        end

        -- #330: "run" checks for threats first (flee), falls back to movement
        handlers["run"] = handlers["flee"]
        handlers["escape"] = handlers["flee"]
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
