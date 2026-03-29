-- engine/creatures/actions.lua
-- Action scoring + execution for creature behavior engine.
-- Extracted from init.lua to keep module under 500 LOC ceiling.
--
-- Ownership: Bart (Architecture Lead)

local M = {}

local predator_prey = require("engine.creatures.predator-prey")
local respawn = require("engine.creatures.respawn")
local combat_ok, combat = pcall(require, "engine.combat")
if not combat_ok then combat = nil end

---------------------------------------------------------------------------
-- Behavior selection (utility scoring)
---------------------------------------------------------------------------

-- score_actions(creature, context, helpers) -> sorted array of { action, score }
-- helpers: { get_location, get_creatures_in_room }
function M.score_actions(creature, context, helpers)
    local behavior = creature.behavior or {}
    local drives = creature.drives or {}
    local scores = {}

    scores[#scores + 1] = { action = "idle", score = 10 }

    -- C14: Suppress wander during active combat
    local wander_score = 0
    if not (context and context.combat_active) then
        if drives.curiosity then
            wander_score = wander_score + (drives.curiosity.value or 0) * 0.3
        end
        wander_score = wander_score + (behavior.wander_chance or 0) * 0.2
    end
    scores[#scores + 1] = { action = "wander", score = wander_score }

    local fear_val = drives.fear and drives.fear.value or 0
    local flee_threshold = behavior.flee_threshold or 50
    if fear_val >= flee_threshold then
        scores[#scores + 1] = { action = "flee", score = fear_val * 1.5 }
    end

    local vocal_score = 0
    if fear_val > 10 and fear_val < flee_threshold then
        vocal_score = fear_val * 0.3
    end
    if drives.curiosity then
        vocal_score = vocal_score + (drives.curiosity.value or 0) * 0.1
    end
    scores[#scores + 1] = { action = "vocalize", score = vocal_score }

    -- Attack: score when prey is present in the same room
    if predator_prey.has_prey_in_room(creature, context, helpers.get_creatures_in_room, helpers.get_location) then
        local aggression = behavior.aggression or 0
        local hunger_val = drives.hunger and drives.hunger.value or 0
        local attack_score = aggression * 0.5 + hunger_val * 0.5
        -- Territorial boost: creature in home territory gets aggression bonus
        if behavior.territorial then
            local territory = behavior.territory or behavior.home_territory
            local loc = helpers.get_location(context.registry, creature)
            if territory and loc == territory then
                attack_score = attack_score + aggression * 0.3
            end
        end
        scores[#scores + 1] = { action = "attack", score = attack_score }
    end

    -- Create object: score when creature has creates_object behavior
    if behavior.creates_object then
        local create_score = behavior.creates_object.priority or 15
        scores[#scores + 1] = { action = "create_object", score = create_score }
    end

    -- Call pack: howl to summon allies when aggressive and pack_animal
    if behavior.pack_animal and creature._state == "alive-aggressive"
       and not creature._pack_called then
        scores[#scores + 1] = {
            action = "call_pack",
            score = (behavior.aggression or 0) * 0.4
        }
    end

    for _, entry in ipairs(scores) do
        entry.score = entry.score + math.random() * 2
    end

    table.sort(scores, function(a, b) return a.score > b.score end)
    return scores
end

---------------------------------------------------------------------------
-- Movement
---------------------------------------------------------------------------

-- move_creature(context, creature, target_room_id, helpers)
-- helpers: { get_location, get_room, set_location }
function M.move_creature(context, creature, target_room_id, helpers)
    local old_loc = helpers.get_location(context.registry, creature)

    -- Update room.contents arrays (real game uses these)
    local old_room = helpers.get_room(context, old_loc)
    if old_room and old_room.contents then
        for i = #old_room.contents, 1, -1 do
            if old_room.contents[i] == creature.id then
                table.remove(old_room.contents, i)
                break
            end
        end
    end
    local new_room = helpers.get_room(context, target_room_id)
    if new_room then
        new_room.contents = new_room.contents or {}
        new_room.contents[#new_room.contents + 1] = creature.id
    end

    -- Update location (both obj.location and mock registry tracker)
    helpers.set_location(context.registry, creature, target_room_id)
end

---------------------------------------------------------------------------
-- Food-as-bait behavior (Track 5C; R-5 boundary: no cooking/recipes/spoilage)
---------------------------------------------------------------------------

local function find_bait(ctx, room_id, cid, helpers)
    local r = {}
    for _, o in ipairs(helpers.list_objects(ctx.registry)) do
        if o.food and o.food.bait_targets and helpers.get_location(ctx.registry, o) == room_id then
            for _, t in ipairs(o.food.bait_targets) do if t == cid then r[#r+1]=o; break end end
        end
    end
    table.sort(r, function(a,b) return (a.food.bait_value or 0) > (b.food.bait_value or 0) end)
    return r
end

function M.try_bait(ctx, creature, helpers)
    local h = creature.drives and creature.drives.hunger
    if not h or (h.value or 0) < (h.satisfy_threshold or 80) then return nil end
    if ctx.combat_active or (combat and combat.find_fight_for_combatant and combat.find_fight_for_combatant(creature)) then return nil end
    local loc = helpers.get_location(ctx.registry, creature); if not loc then return nil end
    local cn = creature.name or "a creature"
    local pr, CN, msgs = helpers.get_player_room_id(ctx), cn:sub(1,1):upper()..cn:sub(2), {}
    local food = find_bait(ctx, loc, creature.id, helpers)
    if #food > 0 then
        ctx.registry:remove(food[1].id); h.value = h.min or 0
        if loc == pr then local m = CN.." scurries toward "..(food[1].name or "the food").." and devours it."; msgs[1] = m; print(m) end
        return msgs end
    local best, bv = nil, -1
    for _, ex in ipairs(helpers.get_valid_exits(ctx, loc, creature)) do
        local a = find_bait(ctx, ex.target, creature.id, helpers)
        if #a > 0 and (a[1].food.bait_value or 0) > bv then best, bv = ex.target, a[1].food.bait_value or 0 end end
    if not best then return nil end; M.move_creature(ctx, creature, best, helpers)
    if loc == pr then msgs[1] = CN.." scurries away, drawn by a scent." end
    if best == pr then msgs[1] = CN.." arrives, sniffing hungrily." end
    return msgs
end

---------------------------------------------------------------------------
-- Action execution
---------------------------------------------------------------------------

-- execute_action(context, creature, action, helpers) -> messages[]
-- helpers: { get_player_room_id, get_location, get_valid_exits, get_room,
--            emit_stimulus, handle_creature_death, attempt_flee }
function M.execute_action(context, creature, action, helpers)
    local messages = {}
    local player_room = helpers.get_player_room_id(context)
    local creature_loc = helpers.get_location(context.registry, creature)

    if action == "idle" then
        if creature._state and creature._state ~= "alive-idle"
           and creature._state ~= "dead" then
            creature._state = "alive-idle"
        end
        -- Re-hide: ambush creatures reset when player leaves room
        local ambush = (creature.behavior or {}).ambush
        if ambush and ambush.can_rehide and creature._ambush_sprung then
            if creature_loc ~= player_room then
                creature._ambush_sprung = false
                creature._ambush_bonus_used = false
                creature.hidden = true
            end
        end

    elseif action == "wander" then
        local exits = helpers.get_valid_exits(context, creature_loc, creature)

        -- Territory leash (#400): restrict wander to patrol_rooms or territory
        local behavior = creature.behavior or {}
        if behavior.territory then
            local patrol = behavior.patrol_rooms
            if not patrol then
                patrol = { behavior.territory }
            end
            local allowed = {}
            for _, ex in ipairs(exits) do
                for _, room_id in ipairs(patrol) do
                    if ex.target == room_id then
                        allowed[#allowed + 1] = ex
                        break
                    end
                end
            end
            exits = allowed
        end

        if #exits > 0 then
            local choice = exits[math.random(#exits)]
            local old_loc = creature_loc

            if creature._state and creature._state ~= "dead" then
                creature._state = "alive-wander"
            end

            M.move_creature(context, creature, choice.target, helpers)

            if old_loc == player_room then
                local name = creature.name or "a creature"
                local Name = name:sub(1,1):upper() .. name:sub(2)
                -- #401: Add prepositions for non-cardinal exit directions
                local CARDINAL = {
                    north=true, south=true, east=true, west=true,
                    up=true, down=true, northeast=true, northwest=true,
                    southeast=true, southwest=true,
                }
                local dir = choice.direction
                if CARDINAL[dir] then
                    messages[#messages + 1] = Name .. " scurries " .. dir .. "."
                else
                    messages[#messages + 1] = Name .. " scurries through the " .. dir .. "."
                end
            elseif choice.target == player_room then
                local name = creature.name or "a creature"
                local st = creature.states and creature.states[creature._state]
                local arrival = st and st.room_presence
                messages[#messages + 1] = arrival or
                    (name:sub(1,1):upper() .. name:sub(2) .. " arrives.")
            end
            creature._last_exit = choice.direction
        else
            if creature._state and creature._state ~= "dead" then
                creature._state = "alive-idle"
            end
        end

    elseif action == "flee" then
        local exits = helpers.get_valid_exits(context, creature_loc, creature)
        if #exits > 0 then
            local choice = exits[math.random(#exits)]
            local old_loc = creature_loc

            if creature._state and creature._state ~= "dead" then
                creature._state = "alive-flee"
            end

            M.move_creature(context, creature, choice.target, helpers)

            if old_loc == player_room then
                local name = creature.name or "a creature"
                messages[#messages + 1] = name:sub(1,1):upper() .. name:sub(2) ..
                    " bolts " .. choice.direction .. "!"
            elseif choice.target == player_room then
                local name = creature.name or "a creature"
                messages[#messages + 1] = name:sub(1,1):upper() .. name:sub(2) ..
                    " darts into the room, eyes wide with fear!"
            end
            creature._last_exit = choice.direction
        else
            if creature._state and creature._state ~= "dead" then
                creature._state = "alive-flee"
            end
        end

    elseif action == "vocalize" then
        if creature_loc == player_room then
            local st = creature.states and creature.states[creature._state]
            local sound = st and st.on_listen
            if sound then
                messages[#messages + 1] = sound
            end
        end

    elseif action == "create_object" then
        local obj_spec = (creature.behavior or {}).creates_object
        if obj_spec then
            -- Cooldown check (os.time-based; avoids coupling to presentation layer)
            if obj_spec.cooldown then
                local now = os.time()
                if creature._last_creation and (now - creature._last_creation) < obj_spec.cooldown then
                    obj_spec = nil
                end
            end
            if obj_spec then
                -- max_per_room cap (declarative metadata — Principle 8)
                local proceed = true
                if obj_spec.max_per_room and obj_spec.template then
                    local room = helpers.get_room(context, creature_loc)
                    if room and room.contents then
                        local tpl = obj_spec.template
                        local count = 0
                        for _, ref in ipairs(room.contents) do
                            local obj = context.registry and type(context.registry.get) == "function"
                                and context.registry:get(ref) or nil
                            if obj and obj.id and (obj.id == tpl or obj.id:sub(1, #tpl) == tpl) then
                                count = count + 1
                            end
                        end
                        if count >= obj_spec.max_per_room then
                            proceed = false
                        end
                    end
                end
                -- Custom condition check
                if proceed and obj_spec.condition then
                    proceed = obj_spec.condition(creature, context, helpers)
                end
                if proceed then
                    local instance
                    -- Prefer registry:instantiate(template) for proper deep-copy + GUID
                    if obj_spec.template and context.registry
                        and type(context.registry.instantiate) == "function" then
                        instance = context.registry:instantiate(obj_spec.template)
                    else
                        local spec = obj_spec.object_def or {}
                        instance = {}
                        for k, v in pairs(spec) do instance[k] = v end
                        local uid = (creature.id or "creature") .. "-obj-" .. tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
                        instance.id = instance.id and (instance.id .. "-" .. uid) or uid
                        -- Register manually when not using instantiate
                        if context.registry then
                            if type(context.registry.register) == "function" then
                                context.registry:register(instance.id, instance)
                            elseif type(context.registry.add) == "function" then
                                context.registry:add(instance)
                            end
                        end
                    end
                    instance.creator = creature.guid or creature.id
                    local room = helpers.get_room(context, creature_loc)
                    if room then
                        room.contents = room.contents or {}
                        room.contents[#room.contents + 1] = instance.guid or instance.id
                    end
                    instance.location = creature_loc
                    creature._last_creation = os.time()
                    -- Narration (only if player is present)
                    if obj_spec.narration and creature_loc == player_room then
                        messages[#messages + 1] = obj_spec.narration
                    end
                end
            end
        end

    elseif action == "attack" then
        local target = predator_prey.select_prey_target(
            context, creature, helpers.get_creatures_in_room, helpers.get_location)
        if target and combat then
            if creature._state and creature._state ~= "dead" then
                creature._state = "alive-hunt"
            end
            -- Surprise damage: ambush first-strike bonus (metadata-driven, Principle 8)
            local ambush_boosted = false
            if creature._ambush_sprung and not creature._ambush_bonus_used then
                local ambush = (creature.behavior or {}).ambush
                local multiplier = (ambush and ambush.damage_bonus) or 1.5
                local weapons = creature.combat and creature.combat.natural_weapons
                if weapons then
                    for _, w in ipairs(weapons) do
                        w._original_force = w.force
                        w.force = (w.force or 1) * multiplier
                    end
                    ambush_boosted = true
                end
                creature._ambush_bonus_used = true
            end
            local result = combat.run_combat(context, creature, target)
            -- Restore weapon forces after ambush strike
            if ambush_boosted then
                local weapons = creature.combat and creature.combat.natural_weapons
                if weapons then
                    for _, w in ipairs(weapons) do
                        if w._original_force then
                            w.force = w._original_force
                            w._original_force = nil
                        end
                    end
                end
            end
            local room_id = creature_loc or player_room
            -- Emit creature_attacked stimulus via helpers for testability
            if room_id then
                helpers.emit_stimulus(room_id, "creature_attacked", {
                    attacker_id = creature.id or creature.guid,
                    defender_id = target.id or target.guid,
                    attacker_name = creature.name,
                    defender_name = target.name,
                })
            end
            -- Creature death: register respawn, reshape, emit stimulus
            if result and result.defender_dead and room_id then
                local dead_name = target.name
                respawn.register(target)
                local death_room = helpers.get_room(context, room_id)
                helpers.handle_creature_death(target, context, death_room)
                helpers.emit_stimulus(room_id, "creature_died", {
                    creature_id = target.id or target.guid,
                    creature_name = dead_name,
                    killer_id = creature.id or creature.guid,
                    killer_name = creature.name,
                })
            end
            -- Narrate if player is in the same room
            if creature_loc == player_room then
                local atk_name = creature.name or "a creature"
                local def_name = target.name or "a creature"
                if result and result.text and result.text ~= "" then
                    messages[#messages + 1] = result.text
                else
                    messages[#messages + 1] = atk_name:sub(1,1):upper() ..
                        atk_name:sub(2) .. " attacks " .. def_name .. "!"
                end
                if result and result.death_narration then
                    messages[#messages + 1] = result.death_narration
                end
            end

            -- Track 3B: Morale check on the DEFENDER after combat resolves
            if result and not result.defender_dead then
                local morale_result = helpers.attempt_flee(context, target)
                if target._morale_message then
                    messages[#messages + 1] = target._morale_message
                    target._morale_message = nil
                end
                -- If defender fled, remove from any active fight
                if morale_result == "flee" and combat.find_fight_for_combatant then
                    local fight = combat.find_fight_for_combatant(target)
                    if fight then combat.remove_combatant(fight, target) end
                end
            end

            -- Track 3B: Morale check on the ATTACKER too
            helpers.attempt_flee(context, creature)
            if creature._morale_message then
                messages[#messages + 1] = creature._morale_message
                creature._morale_message = nil
            end
        end

    elseif action == "call_pack" then
        if creature.behavior and creature.behavior.pack_animal and creature_loc then
            helpers.emit_stimulus(creature_loc, "pack_call", {
                caller_id = creature.guid,
                caller_name = creature.name,
            })
            creature._pack_called = true
            if creature_loc == player_room then
                local name = creature.name or "a creature"
                messages[#messages + 1] = name:sub(1,1):upper() .. name:sub(2) ..
                    " raises its head and howls!"
            end
        end
    end

    return messages
end

return M
