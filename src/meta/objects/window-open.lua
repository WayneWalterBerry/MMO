return {
    id = "window-open",
    name = "an open leaded glass window",
    keywords = {"window", "glass", "pane", "leaded glass", "open window"},
    description = "The tall leaded window stands open, its iron latch thrown back. Cool air drifts in, carrying the smell of rain and chimney smoke from the rooftops below. The sounds of a distant city — or perhaps a distant age — filter through: a cart wheel on cobblestone, a dog barking, the low murmur of lives being lived.",

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
