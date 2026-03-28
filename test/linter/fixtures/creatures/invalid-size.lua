-- Triggers CREATURE-011: size must be string enum (tiny, small, medium, large, huge)
-- This creature has size = "giant" which is not a valid enum value.
return {
    guid = "{00000000-0000-0000-0000-00000000000a}",
    template = "creature",
    id = "cellar-centipede",
    name = "a cellar centipede",
    keywords = {"centipede", "cellar centipede", "creature"},
    description = "An impossibly long centipede with glistening segments and too many legs.",

    -- NOTE: "giant" is NOT a valid size enum — triggers CREATURE-011
    size = "giant",
    weight = 0.3,
    material = "chitin",

    animate = true,

    on_feel = "Hundreds of tiny legs ripple across your skin. Hard, segmented shell.",
    on_smell = "A sharp chemical tang, like crushed ants.",
    on_listen = "The dry rustle of a hundred legs on stone.",

    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "The centipede coils in the corner, antennae twitching.",
            room_presence = "A long centipede coils in the shadows.",
        },
        dead = {
            description = "The centipede lies in a loose spiral, legs curled inward.",
            room_presence = "A dead centipede lies curled on the floor.",
            animate = false,
            portable = true,
        },
    },

    behavior = {
        default = "idle",
        aggression = 15,
        flee_threshold = 70,
    },

    drives = {
        hunger = { value = 40, weight = 0.5, decay_rate = 2, max = 100 },
    },

    reactions = {
        player_enters = {
            action = "flee",
            drive_deltas = { fear = 40 },
            message = "The centipede uncoils and races toward a crack in the wall.",
        },
    },

    health = 3,
    max_health = 3,
    alive = true,

    body_tree = {
        head     = { size = 1, vital = true, tissue = { "chitin", "flesh" } },
        segments = { size = 2, vital = true, tissue = { "chitin", "flesh" } },
        legs     = { size = 1, vital = false, tissue = { "chitin" } },
    },
}
