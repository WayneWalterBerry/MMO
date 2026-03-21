-- window.lua — FSM-managed leaded glass window
-- States: closed <-> open (reversible)
return {
    guid = "4ecd1058-5cbe-4601-a98e-c994631f7d6b",
    id = "window",
    material = "glass",
    keywords = {"window", "glass", "pane", "leaded glass"},
    room_presence = "A tall leaded glass window is set deep in the stone of the far wall.",

    on_feel = "Cold glass pane, thick and uneven. Lead strips divide it into diamond shapes. An iron latch holds it shut.",
    on_listen = "Faint sounds from outside -- muffled by glass. Wind, maybe. A distant city, maybe.",

    size = 5,
    weight = 20,
    categories = {"fixture", "glass", "fragile"},
    room_position = "is set deep in the stone of the far wall",
    portable = false,
    container = false,

    location = nil,

    -- FSM
    initial_state = "closed",
    _state = "closed",

    states = {
        closed = {
            name = "a leaded glass window",
            description = "A tall window of diamond-paned leaded glass, set deep in the stone wall. The glass is thick and uneven, warping the world outside into an impressionist fever dream. Through it, you can make out the vague shapes of rooftops and, beyond them, something that might be a forest or might be the edge of the world. The window is latched shut.",
            room_presence = "A tall leaded glass window is set deep in the stone of the far wall.",
            on_feel = "Cold glass pane, thick and uneven. Lead strips divide it into diamond shapes. An iron latch holds it shut.",
            on_listen = "Faint sounds from outside -- muffled by glass. Wind, maybe. A distant city, maybe.",

            on_look = function(self)
                return self.description
            end,
        },

        open = {
            name = "an open leaded glass window",
            description = "The tall leaded window stands open, its iron latch thrown back. Cool air drifts in, carrying the smell of rain and chimney smoke from the rooftops below. The sounds of a distant city -- or perhaps a distant age -- filter through: a cart wheel on cobblestone, a dog barking, the low murmur of lives being lived.",
            room_presence = "A tall leaded window stands open in the stone wall, letting cool air drift in from outside.",
            on_feel = "Cold glass pane swung open. Cool air drifts past your hand. The stone sill is damp.",
            on_smell = "Rain and chimney smoke from outside. Fresh air -- a relief from the stuffiness within.",
            on_listen = "Wind whistles through the opening. Distant sounds: a cart wheel on cobblestone, a dog barking, the murmur of lives being lived.",

            on_look = function(self)
                return self.description .. "\n\nA cold breeze whispers through the opening."
            end,
        },
    },

    transitions = {
        {
            from = "closed", to = "open", verb = "open",
            message = "You unlatch the iron catch and push the window open. Cool air rushes in, carrying the smell of rain and chimney smoke.",
            mutate = {
                keywords = { add = "open" },
                categories = { add = "ventilation" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            message = "You pull the window shut and latch it. The sounds of the outside world are muffled once more.",
            mutate = {
                keywords = { remove = "open" },
                categories = { remove = "ventilation" },
            },
        },
    },

    -- Base on_look for initial load (overridden by state on_look)
    name = "a leaded glass window",
    description = "A tall window of diamond-paned leaded glass, set deep in the stone wall. The glass is thick and uneven, warping the world outside into an impressionist fever dream. Through it, you can make out the vague shapes of rooftops and, beyond them, something that might be a forest or might be the edge of the world. The window is latched shut.",

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
