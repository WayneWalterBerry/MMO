-- Auto-split from sensory.lua
local H = require("engine.verbs.helpers")

local find_visible = H.find_visible
local _hobj = H._hobj

local M = {}

function M.register(handlers)
    -- LISTEN / HEAR -- works in darkness AND light
    ---------------------------------------------------------------------------
    handlers["listen"] = function(ctx, noun)
        if noun == "" then
            -- Room-level listen sweep (like feel does for touch)
            local room = ctx.current_room
            if room.on_listen then
                print(room.on_listen)
            else
                print("You hold your breath and listen. Silence -- save for your own heartbeat.")
            end
            -- Sweep objects for individual sounds
            local reg = ctx.registry
            local found = {}
            for _, obj_id in ipairs(room.contents or {}) do
                local obj = reg:get(obj_id)
                if obj and not obj.hidden and obj.on_listen then
                    found[#found + 1] = { name = obj.name or obj.id, sound = obj.on_listen }
                end
                if obj and obj.surfaces then
                    for _, zone in pairs(obj.surfaces) do
                        if zone.accessible ~= false then
                            for _, item_id in ipairs(zone.contents or {}) do
                                local item = reg:get(item_id)
                                if item and item.on_listen then
                                    found[#found + 1] = { name = item.name or item.id, sound = item.on_listen }
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
                        local state_listen = creature.states and creature.states[creature._state]
                            and creature.states[creature._state].on_listen
                        local listen_text = state_listen or creature.on_listen
                        if listen_text then
                            found[#found + 1] = { name = creature.name or creature.id, sound = listen_text }
                        end
                    end
                end
            end
            for i = 1, 2 do
                local hand = ctx.player.hands[i]
                if hand then
                    local h_obj = _hobj(hand, reg)
                    if h_obj and h_obj.on_listen then
                        found[#found + 1] = { name = h_obj.name or h_obj.id, sound = h_obj.on_listen }
                    end
                end
            end
            if #found > 0 then
                print("You catch faint sounds:")
                for _, entry in ipairs(found) do
                    print("  " .. entry.name .. " -- " .. entry.sound)
                end
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
end


return M
