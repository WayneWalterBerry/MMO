-- Triggers CREATURE-018: dead state should set animate = false
-- This creature has a dead state but it does NOT set animate = false.
return {
    guid = "{00000000-0000-0000-0000-00000000000c}",
    template = "creature",
    id = "sewer-leech",
    name = "a sewer leech",
    keywords = {"leech", "sewer leech", "creature"},
    description = "A fat, glistening leech the length of your forearm, undulating in filthy water.",

    size = "tiny",
    weight = 0.1,
    material = "flesh",

    animate = true,

    on_feel = "Slick, muscular flesh that suctions to your skin. It pulses.",
    on_smell = "Stale water and iron — blood.",
    on_listen = "A wet, rhythmic squelching.",

    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "The leech drifts in murky water, searching.",
            room_presence = "A fat leech undulates in the shallow water.",
        },
        -- NOTE: dead state does NOT set animate = false — triggers CREATURE-018
        dead = {
            description = "The leech lies limp in the water, deflated.",
            room_presence = "A dead leech floats in the murky water.",
            portable = true,
            -- animate = false is deliberately MISSING
        },
    },
    transitions = {
        { from = "*", to = "dead", verb = "_damage", condition = "health_zero" },
    },

    behavior = {
        default = "idle",
        aggression = 20,
        flee_threshold = 60,
    },

    drives = {
        hunger = { value = 70, weight = 0.6, decay_rate = 3, max = 100 },
    },

    reactions = {
        player_enters = {
            action = "evaluate",
            drive_deltas = { hunger = 10 },
            message = "The leech stretches toward you, sensing warmth.",
        },
    },

    health = 2,
    max_health = 2,
    alive = true,

    body_tree = {
        body = { size = 1, vital = true, tissue = { "flesh" } },
    },
}
