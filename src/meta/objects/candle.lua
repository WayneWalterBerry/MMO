return {
    id = "candle",
    name = "a tallow candle",
    keywords = {"candle", "tallow", "candle stub", "light", "tallow candle"},
    description = "A stubby tallow candle, melted into a brass dish crusted with old wax. The wick is blackened but intact, curling like a burnt finger. It is not lit.",

    size = 1,
    weight = 1,
    categories = {"light source"},
    portable = true,

    location = nil,

    on_look = function(self)
        return self.description .. "\n\nIt could be lit, if you had the means."
    end,

    mutations = {
        light = {
            becomes = "candle-lit",
            requires_tool = "fire_source",
            message = "The wick catches the flame and curls to life, throwing a warm amber glow across the room. Shadows retreat to the corners like startled cats.",
            fail_message = "You have nothing to light it with. The wick stares back at you, cold and uncooperative.",
        },
    },
}
