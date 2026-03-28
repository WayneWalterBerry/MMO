-- Triggers CREATURE-001: animate = true must exist
-- This creature is missing the animate field entirely.
return {
    guid = "{00000000-0000-0000-0000-000000000002}",
    template = "creature",
    id = "stone-beetle",
    name = "a stone beetle",
    keywords = {"beetle", "stone beetle", "creature"},
    description = "A dull grey beetle the size of a fist, with a pitted carapace.",

    size = "tiny",
    weight = 0.2,
    material = "chitin",

    -- NOTE: animate = true is deliberately MISSING

    on_feel = "A hard, ridged shell. Cold as stone.",
    on_smell = "Damp earth and mineral dust.",
    on_listen = "A faint clicking of mandibles.",

    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "The beetle sits motionless on the stone.",
            room_presence = "A grey beetle clings to the wall.",
        },
        dead = {
            description = "The beetle lies on its back, legs curled.",
            room_presence = "A dead beetle lies upside-down.",
            animate = false,
            portable = true,
        },
    },

    behavior = {
        default = "idle",
        aggression = 0,
        flee_threshold = 90,
    },

    drives = {
        hunger = { value = 10, weight = 0.5, decay_rate = 1, max = 100 },
    },

    reactions = {
        player_enters = {
            action = "evaluate",
            drive_deltas = { fear = 10 },
            message = "The beetle's antennae twitch.",
        },
    },

    health = 2,
    max_health = 2,
    alive = true,

    body_tree = {
        carapace = { size = 1, vital = true, tissue = { "chitin" } },
        legs     = { size = 1, vital = false, tissue = { "chitin" } },
    },
}
