-- Auto-split from sensory.lua
local H = require("engine.verbs.helpers")

local find_visible = H.find_visible
local _hobj = H._hobj

local M = {}

function M.register(handlers)
    -- SMELL / SNIFF -- works in darkness AND light
    ---------------------------------------------------------------------------
    handlers["smell"] = function(ctx, noun)
        if noun == "" then
            -- Room-level smell sweep (like feel does for touch)
            local room = ctx.current_room
            if room.on_smell then
                print("You smell the air around you.")
                print(room.on_smell)
            else
                print("You smell the air around you. Dust and stillness.")
            end
            -- Sweep objects for individual smells
            local reg = ctx.registry
            local found = {}
            for _, obj_id in ipairs(room.contents or {}) do
                local obj = reg:get(obj_id)
                if obj and not obj.hidden and obj.on_smell then
                    found[#found + 1] = { name = obj.name or obj.id, smell = obj.on_smell }
                end
                if obj and obj.surfaces then
                    for _, zone in pairs(obj.surfaces) do
                        if zone.accessible ~= false then
                            for _, item_id in ipairs(zone.contents or {}) do
                                local item = reg:get(item_id)
                                if item and item.on_smell then
                                    found[#found + 1] = { name = item.name or item.id, smell = item.on_smell }
                                end
                            end
                        end
                    end
                end
            end
            -- Scan creatures in the room
            local cr_ok, cr_mod = pcall(require, "engine.creatures")
            if cr_ok and cr_mod and cr_mod.get_creatures_in_room then
                local room_creatures = cr_mod.get_creatures_in_room(reg, room.id)
                for _, creature in ipairs(room_creatures) do
                    if not creature.hidden then
                        local state_smell = creature.states and creature.states[creature._state]
                            and creature.states[creature._state].on_smell
                        local smell_text = state_smell or creature.on_smell
                        if smell_text then
                            found[#found + 1] = { name = creature.name or creature.id, smell = smell_text }
                        end
                    end
                end
            end
            -- Also check player hands
            for i = 1, 2 do
                local hand = ctx.player.hands[i]
                if hand then
                    local h_obj = _hobj(hand, reg)
                    if h_obj and h_obj.on_smell then
                        found[#found + 1] = { name = h_obj.name or h_obj.id, smell = h_obj.on_smell }
                    end
                end
            end
            if #found > 0 then
                print("Your nose picks up:")
                for _, entry in ipairs(found) do
                    print("  " .. entry.name .. " -- " .. entry.smell)
                end
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
end


return M
