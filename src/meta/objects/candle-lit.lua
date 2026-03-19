return {
    id = "candle-lit",
    name = "a lit tallow candle",
    keywords = {"candle", "tallow", "lit candle", "flame", "light", "fire"},
    description = "A stubby tallow candle gutters in its brass dish, throwing wild shadows that dance across the walls like drunken puppets. The flame is small but fierce, painting everything in shades of amber and coal.",

    on_feel = "Warm wax, softening near the flame. The brass dish beneath is hot to the touch — careful.",
    on_smell = "Burning wick and melting tallow. Thin smoke curls upward, acrid and animal.",
    on_listen = "A gentle crackling, and the soft hiss of melting wax. The flame whispers to itself.",

    size = 1,
    weight = 1,
    categories = {"light source", "lit", "hot"},
    casts_light = true,
    portable = true,

    location = nil,

    on_look = function(self)
        return self.description .. "\n\nThe flame shivers with each breath you take."
    end,

    mutations = {
        extinguish = {
            becomes = "candle",
        },
    },
}
