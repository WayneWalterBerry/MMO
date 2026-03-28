-- engine/verbs/butchery.lua
-- Butcher verb handler: converts large corpses into portable meat/bone/hide.
-- Split from crafting.lua for Phase 4 WAVE-1.
--
-- Ownership: Smithers (UI Engineer)

local H = require("engine.verbs.helpers")

local err_not_found = H.err_not_found
local find_visible = H.find_visible
local find_tool_in_inventory = H.find_tool_in_inventory
local find_visible_tool = H.find_visible_tool
local show_hint = H.show_hint
local _hid = H._hid

local fsm_mod = H.fsm_mod

local M = {}

function M.register(handlers)
    ---------------------------------------------------------------------------
    -- BUTCHER {corpse} — processes large corpses into portable resources.
    -- Requires a tool with "butchering" capability (e.g., knife).
    -- Products declared on corpse's death_state.butchery_products (Principle 8).
    -- Advances game time by 5 minutes (Option B, per D-BUTCHERY-TIME).
    ---------------------------------------------------------------------------
    handlers["butcher"] = function(ctx, noun)
        if noun == "" then
            print("Butcher what?")
            return
        end

        -- Resolve target (corpses are room-floor objects after death reshape)
        local target = find_visible(ctx, noun)
        if not target then
            err_not_found(ctx)
            return
        end

        -- Must be a dead creature (alive == false set by reshape_instance)
        if target.alive ~= false and not target.death_state then
            print("You can't butcher that.")
            return
        end

        -- Must have butchery_products declared in death_state
        local butch = target.death_state and target.death_state.butchery_products
        if not butch then
            print("There's nothing useful to carve from this corpse.")
            return
        end

        -- Tool check: player needs a tool with the required capability
        local tool = find_tool_in_inventory(ctx, butch.requires_tool)
        if not tool then
            tool = find_visible_tool(ctx, butch.requires_tool)
        end
        if not tool then
            print("You need a knife to butcher this.")
            return
        end

        -- Start narration
        print(butch.narration.start)

        -- Advance game time: 5 minutes = 5/60 hours
        -- Follows rest.lua pattern: ctx.time_offset is in game hours
        local BUTCHER_HOURS = 5 / 60
        ctx.time_offset = (ctx.time_offset or 0) + BUTCHER_HOURS

        -- Tick FSMs for elapsed time (1 tick ≈ 6 minutes, close enough for 5 min)
        local reg = ctx.registry
        local room = ctx.current_room
        local tick_targets = {}
        for _, obj_id in ipairs(room and room.contents or {}) do
            tick_targets[#tick_targets + 1] = obj_id
            local obj = reg:get(obj_id)
            if obj and obj.surfaces then
                for _, zone in pairs(obj.surfaces) do
                    for _, item_id in ipairs(zone.contents or {}) do
                        tick_targets[#tick_targets + 1] = item_id
                    end
                end
            end
        end
        -- Include held items (candles burning in hand)
        if ctx.player then
            for i = 1, 2 do
                if ctx.player.hands[i] then
                    tick_targets[#tick_targets + 1] = _hid(ctx.player.hands[i])
                end
            end
        end

        for _, obj_id in ipairs(tick_targets) do
            local obj = reg:get(obj_id)
            if obj and obj._state then
                fsm_mod.tick(reg, obj_id)
            end
        end
        if ctx.on_tick then
            ctx.on_tick(ctx)
        end

        -- Instantiate products into room
        local spawns = {}
        for _, prod in ipairs(butch.products) do
            for i = 1, prod.quantity do
                spawns[#spawns + 1] = prod.id
            end
        end

        -- Use object_sources + loader when available (production engine),
        -- fall back to spawn_objects helper or skip gracefully.
        if ctx.object_sources and ctx.loader then
            local room = ctx.current_room
            for _, spawn_id in ipairs(spawns) do
                local source = ctx.object_sources[spawn_id]
                if source then
                    local spawn_obj, err = ctx.loader.load_source(source)
                    if spawn_obj and ctx.templates then
                        spawn_obj = ctx.loader.resolve_template(spawn_obj, ctx.templates)
                    end
                    if spawn_obj then
                        local actual_id = spawn_id
                        if reg:get(spawn_id) then
                            local n = 2
                            while reg:get(spawn_id .. "-" .. n) do n = n + 1 end
                            actual_id = spawn_id .. "-" .. n
                        end
                        spawn_obj.id = actual_id
                        spawn_obj.location = room.id
                        reg:register(actual_id, spawn_obj)
                        room.contents[#room.contents + 1] = actual_id
                    end
                end
            end
        end

        -- Remove corpse if specified
        if butch.removes_corpse then
            -- Remove from room contents (match by id or guid for robustness)
            local room_contents = room.contents or {}
            for i = #room_contents, 1, -1 do
                local entry = room_contents[i]
                if entry == target.id or entry == target.guid then
                    table.remove(room_contents, i)
                    break
                end
            end
            reg:remove(target.id)
        end

        -- Completion narration
        print(butch.narration.complete)

        -- WAVE-3: Trauma hook — butchery is gory, player witnesses gore
        local inj_ok, inj_mod = pcall(require, "engine.injuries")
        if inj_ok and inj_mod and inj_mod.add_stress then
            inj_mod.add_stress(ctx.player, "witness_gore")
        end

        show_hint(ctx, "butcher", "Butchering large creatures yields meat, bones, and hides you can use.")
    end

    -- Verb aliases
    handlers["carve"]   = handlers["butcher"]
    handlers["skin"]    = handlers["butcher"]
    handlers["fillet"]  = handlers["butcher"]
    handlers["dissect"] = handlers["butcher"]
    handlers["gut"]     = handlers["butcher"]
end

return M
