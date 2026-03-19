return {
    guid = "a105e31f-394a-441e-907a-4d5c0338b434",
    id = "window-open",
    name = "an open leaded glass window",
    keywords = {"window", "glass", "pane", "leaded glass", "open window"},
    room_presence = "A tall leaded window stands open in the stone wall, letting cool air drift in from outside.",
    description = "The tall leaded window stands open, its iron latch thrown back. Cool air drifts in, carrying the smell of rain and chimney smoke from the rooftops below. The sounds of a distant city -- or perhaps a distant age -- filter through: a cart wheel on cobblestone, a dog barking, the low murmur of lives being lived.",

    on_feel = "Cold glass pane swung open. Cool air drifts past your hand. The stone sill is damp.",
    on_smell = "Rain and chimney smoke from outside. Fresh air -- a relief from the stuffiness within.",
    on_listen = "Wind whistles through the opening. Distant sounds: a cart wheel on cobblestone, a dog barking, the murmur of lives being lived.",

    size = 5,
    weight = 20,
    categories = {"fixture", "glass"},
    portable = false,
    container = false,

    location = nil,

    on_look = function(self)
        return self.description .. "\n\nA cold breeze whispers through the opening."
    end,

    mutations = {
        close = {
            becomes = "window",
        },
    },
}
