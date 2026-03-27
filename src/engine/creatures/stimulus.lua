-- engine/creatures/stimulus.lua
-- Stimulus queue management: emission, processing, and clearing.
-- Extracted from creatures/init.lua for WAVE-0 module split (Phase 2).
--
-- Ownership: Bart (Architecture Lead)

local M = {}

-- Stimulus queue: array of { room_id, stimulus_type, data }
local stimulus_queue = {}

---------------------------------------------------------------------------
-- emit(room_id, stimulus_type, data)
-- Queues a stimulus for creatures to process on the next tick.
---------------------------------------------------------------------------
function M.emit(room_id, stimulus_type, data)
    stimulus_queue[#stimulus_queue + 1] = {
        room_id = room_id,
        stimulus_type = stimulus_type,
        data = data or {},
    }
end

---------------------------------------------------------------------------
-- clear()
-- Drains the stimulus queue (called after tick processes all stimuli).
---------------------------------------------------------------------------
function M.clear()
    stimulus_queue = {}
end

---------------------------------------------------------------------------
-- process(context, creature, helpers) -> messages[]
-- Matches queued stimuli against creature's reactions table, applies drive
-- deltas.  `helpers` must provide:
--   helpers.get_location(registry, creature)  -> room_id
--   helpers.get_room_distance(context, from_id, to_id) -> number
---------------------------------------------------------------------------
function M.process(context, creature, helpers)
    local messages = {}
    if type(creature.reactions) ~= "table" then return messages end
    local creature_loc = helpers.get_location(context.registry, creature)

    for _, stimulus in ipairs(stimulus_queue) do
        local dist = 999
        if creature_loc == stimulus.room_id then
            dist = 0
        else
            dist = helpers.get_room_distance(context, creature_loc, stimulus.room_id)
        end

        -- Only same-room and adjacent creatures react
        if dist <= 1 then
            local reaction = creature.reactions[stimulus.stimulus_type]
            if reaction then
                if reaction.fear_delta and creature.drives and creature.drives.fear then
                    local scale = dist == 0 and 1.0 or 0.5
                    local delta = reaction.fear_delta * scale
                    local fear = creature.drives.fear
                    fear.value = (fear.value or 0) + delta
                    local max_val = fear.max or 100
                    local min_val = fear.min or 0
                    if fear.value > max_val then fear.value = max_val end
                    if fear.value < min_val then fear.value = min_val end
                end
                if dist == 0 and reaction.message then
                    messages[#messages + 1] = reaction.message
                end
            end
        end
    end
    return messages
end

return M
