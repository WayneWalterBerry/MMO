-- wall-clock.lua — 24-state cyclic FSM clock with breakable stopped state
-- States: hour_1 through hour_24 (working), stopped (broken via break/smash/hit/strike)
-- Standard FSM object — no special engine code required.
-- The clock chimes on each hour transition. Cyclic: hour_24 wraps to hour_1.

local number_words = {
    "one", "two", "three", "four", "five", "six",
    "seven", "eight", "nine", "ten", "eleven", "twelve",
}

local time_flavor = {
    [1]  = "The dead of night.",
    [2]  = "Deep in the small hours.",
    [3]  = "The darkest hour before dawn.",
    [4]  = "The world holds its breath before dawn.",
    [5]  = "The first grey hint of morning.",
    [6]  = "Dawn approaches.",
    [7]  = "Early morning light.",
    [8]  = "Morning strengthens.",
    [9]  = "Mid-morning.",
    [10] = "The morning wears on.",
    [11] = "Late morning.",
    [12] = "High noon.",
    [13] = "Early afternoon.",
    [14] = "The afternoon stretches ahead.",
    [15] = "Mid-afternoon.",
    [16] = "The afternoon wanes.",
    [17] = "Late afternoon shadows lengthen.",
    [18] = "Evening draws near.",
    [19] = "Dusk settles over the world.",
    [20] = "The evening deepens.",
    [21] = "Night falls.",
    [22] = "The night is well underway.",
    [23] = "Late in the evening.",
    [24] = "The witching hour approaches.",
}

-- Build chime transition messages (for arriving at each hour)
local function chime_message(hour)
    local display = ((hour - 1) % 12) + 1
    local word = number_words[display]

    if hour == 12 then
        return "The clock strikes twelve -- a deep, resonant tolling that fills the room. Noon."
    elseif hour == 24 then
        return "The clock strikes twelve -- a deep, resonant tolling that fills the room. Midnight."
    elseif display == 1 then
        return "The clock strikes once."
    else
        return "The clock strikes " .. word .. "."
    end
end

-- Generate states programmatically
local states = {}
for h = 1, 24 do
    local display = ((h - 1) % 12) + 1
    local word = number_words[display]
    local next_h = (h % 24) + 1

    states["hour_" .. h] = {
        name = "a wooden wall clock",
        description = "A wooden wall clock with Roman numerals on a brass face. The hands point to "
            .. word .. ". The pendulum swings steadily behind a small glass door. "
            .. time_flavor[h],
        room_presence = "The clock reads " .. word .. " o'clock. " .. time_flavor[h],
        on_listen = "Tick... tock... tick... tock. Steady and reliable, marking time whether anyone cares or not.",
        on_feel = "Smooth wooden case, cool to the touch. You can feel the faint vibration of the mechanism through the wood. The brass face is cold and slightly dusty.",

        timed_events = {
            { event = "transition", delay = 3600, to_state = "hour_" .. next_h },
        },
    }
end

-- Stopped state (clock is broken)
states["stopped"] = {
    name = "a stopped wall clock",
    description = "A wooden wall clock with Roman numerals on a tarnished brass face. The pendulum hangs motionless behind cracked glass. The hands are frozen in place, pointing nowhere meaningful.",
    room_presence = "A wooden wall clock hangs on the wall, its pendulum still and silent.",
    on_listen = "Nothing. The clock is silent -- no tick, no tock. Just dead air where rhythm used to be.",
    on_feel = "Smooth wooden case, cool to the touch. The mechanism is still -- no vibration. The glass face has a crack running diagonally across it.",
    on_smell = "Old wood and clock oil. A faint hint of dust.",
}

-- Generate transitions programmatically
local transitions = {}
for h = 1, 24 do
    local next_h = (h % 24) + 1
    transitions[#transitions + 1] = {
        from = "hour_" .. h, to = "hour_" .. next_h,
        trigger = "auto",
        condition = "timer_expired",
        message = chime_message(next_h),
    }
    -- Break transition from each hour to stopped
    transitions[#transitions + 1] = {
        from = "hour_" .. h, to = "stopped",
        verb = "break",
        aliases = {"smash", "hit", "strike"},
        message = "You strike the clock. The glass cracks, the pendulum shudders to a halt, and the ticking stops. Silence fills the space where time used to be.",
        mutate = {
            keywords = { add = "broken" },
            categories = { add = "broken" },
        },
    }
end

return {
    guid = "{c5bae682-b7ee-451d-b1cf-ceeb74d6b83d}",
    template = "furniture",

    id = "wall-clock",
    keywords = {"clock", "wall clock", "timepiece", "grandfather clock"},
    size = 5,
    weight = 12,
    categories = {"furniture", "fixture", "wooden"},
    portable = false,
    material = "wood",

    name = "a wooden wall clock",
    description = "A wooden wall clock with Roman numerals on a tarnished brass face. The pendulum swings steadily behind a small glass door, counting out the seconds with mechanical indifference.",
    room_presence = "A wooden wall clock hangs on the wall, its pendulum swinging steadily.",
    on_feel = "Smooth wooden case, cool to the touch. You can feel the faint vibration of the mechanism through the wood. The brass face is cold and slightly dusty.",
    on_smell = "Old wood and clock oil -- a faint, mechanical sweetness.",
    on_listen = "Tick... tock... tick... tock. Steady and reliable, marking time whether anyone cares or not.",

    location = nil,

    -- Game starts at 2 AM
    initial_state = "hour_2",
    _state = "hour_2",

    -- Puzzle support: instance-level overrides for misset clocks
    -- time_offset: hours the clock is ahead/behind game time (default 0 = correct)
    -- initial_hour: derived from game time + offset on room load (nil = use _state)
    -- adjustable: if true, SET verb advances clock to next hour (default false)
    -- target_hour: when reached via SET, fires on_correct_time (nil = no puzzle)
    -- on_correct_time: callback fired when clock is manually set to target_hour
    time_offset = 0,
    adjustable = false,
    target_hour = nil,
    on_correct_time = nil,

    states = states,
    transitions = transitions,

    on_look = function(self)
        local state = self.states and self.states[self._state]
        if state then
            return state.description
        end
        return self.description
    end,

    mutations = {},
}
