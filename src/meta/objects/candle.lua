return {
    guid = "992df7f3-1b8e-4164-939a-3415f8f6ffe3",
    id = "candle",
    name = "a tallow candle",
    keywords = {"candle", "tallow", "candle stub", "light", "tallow candle"},
    description = "A stubby tallow candle, melted into a brass dish crusted with old wax. The wick is blackened but intact, curling like a burnt finger. It is not lit.",

    on_feel = "A smooth wax cylinder, slightly greasy. It tapers to a blackened wick at the top. The brass dish beneath is cold.",
    on_smell = "Faintly waxy -- old tallow and a memory of smoke.",

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
