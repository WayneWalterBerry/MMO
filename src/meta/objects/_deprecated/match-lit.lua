return {
    guid = "5483cf3e-8612-4f00-9871-c6e0691beb4d",
    template = "small-item",

    id = "match-lit",
    name = "a lit match",
    keywords = {"match", "lit match", "flame", "fire", "burning match", "matchstick"},
    description = "A small wooden match, burning with a flickering flame. The fire creeps slowly down the stick, consuming it. You have seconds before it reaches your fingers.",
    room_presence = "A match burns with a tiny, wavering flame.",

    on_feel = "HOT! You burn your fingers.",
    on_feel_effect = "burn",
    on_smell = "Burning sulfur and wood.",
    on_listen = "A faint crackling hiss as the wood burns.",
    on_look = "A small match, burning with a flickering flame.",

    size = 1,
    weight = 0.01,
    categories = {"small", "consumable", "lit", "hot", "fire_source"},
    portable = true,

    -- The lit match provides fire_source capability for lighting candles, etc.
    provides_tool = "fire_source",
    casts_light = true,
    light_radius = 1,

    -- Consumable: the match burns out after ~30 game seconds, or is consumed
    -- after one LIGHT action on a target.
    consumable = true,
    burn_remaining = 30,
    on_consumed = {
        message = "The match flame reaches your fingers and you drop it with a hiss. It gutters out on the cold stone floor.",
        becomes = nil,
    },

    location = nil,

    on_look_fn = function(self)
        if self.burn_remaining and self.burn_remaining <= 10 then
            return self.description .. "\n\nThe flame is dangerously close to your fingers. Hurry!"
        end
        return self.description
    end,

    mutations = {
        extinguish = {
            becomes = nil,
            message = "You pinch the flame out. A thin ribbon of smoke rises from the blackened tip, then nothing. Darkness returns.",
        },
    },
}
