-- Triggers CREATURE-005: health and max_health must be numbers
-- This creature has health = "full" (string instead of number).
return {
    guid = "{00000000-0000-0000-0000-000000000006}",
    template = "creature",
    id = "cellar-toad",
    name = "a cellar toad",
    keywords = {"toad", "cellar toad", "creature"},
    description = "A warty brown toad squatting in a puddle, throat pulsing.",

    size = "tiny",
    weight = 0.4,
    material = "flesh",

    animate = true,

    on_feel = "Bumpy, damp skin. It inflates in alarm.",
    on_smell = "Wet earth and a sharp, acrid secretion.",
    on_listen = "A deep, resonant croak.",

    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "The toad sits half-submerged, blinking slowly.",
            room_presence = "A fat toad squats in a puddle.",
        },
        dead = {
            description = "The toad lies belly-up in the water.",
            room_presence = "A dead toad floats in the puddle.",
            animate = false,
            portable = true,
        },
    },

    behavior = {
        default = "idle",
        aggression = 0,
        flee_threshold = 80,
    },

    drives = {
        hunger = { value = 30, weight = 0.5, decay_rate = 1, max = 60 },
    },

    reactions = {
        player_enters = {
            action = "evaluate",
            drive_deltas = { fear = 15 },
            message = "The toad puffs up, throat bulging.",
        },
    },

    -- NOTE: health is a STRING, not a number — triggers CREATURE-005
    health = "full",
    max_health = "full",
    alive = true,

    body_tree = {
        body = { size = 1, vital = true, tissue = { "flesh" } },
        legs = { size = 1, vital = false, tissue = { "flesh", "bone" } },
    },
}
