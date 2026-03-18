return {
    id = "candle-lit",
    name = "a lit tallow candle",
    keywords = {"candle", "tallow", "lit candle", "flame", "light", "fire"},
    description = "A stubby tallow candle gutters in its brass dish, throwing wild shadows that dance across the walls like drunken puppets. The flame is small but fierce, painting everything in shades of amber and coal.",

    size = 1,
    weight = 1,
    categories = {"light source", "lit", "hot"},
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
