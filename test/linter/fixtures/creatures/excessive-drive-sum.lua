-- Triggers CREATURE-008: drive weights must sum to <= 1.0
-- This creature has drive weights summing to 1.3 (0.5 + 0.5 + 0.3).
return {
    guid = "{00000000-0000-0000-0000-000000000008}",
    template = "creature",
    id = "feral-cat",
    name = "a feral cat",
    keywords = {"cat", "feral cat", "creature"},
    description = "A lean, scarred cat with torn ears and mismatched eyes.",

    size = "small",
    weight = 3.5,
    material = "flesh",

    animate = true,

    on_feel = "Wiry fur over taut muscle. It hisses at the contact.",
    on_smell = "Stale urine and old prey.",
    on_listen = "A guttural yowl, low and threatening.",

    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "The cat crouches low, tail lashing.",
            room_presence = "A feral cat watches you from a ledge.",
        },
        dead = {
            description = "The cat lies curled on its side, eyes half-open.",
            room_presence = "A dead cat lies on the floor.",
            animate = false,
            portable = true,
        },
    },

    behavior = {
        default = "idle",
        aggression = 30,
        flee_threshold = 50,
    },

    -- NOTE: weights sum to 1.3 (0.5 + 0.5 + 0.3) — triggers CREATURE-008
    drives = {
        hunger    = { value = 60, weight = 0.5, decay_rate = 2, max = 100 },
        fear      = { value = 10, weight = 0.5, decay_rate = -5, max = 100, min = 0 },
        curiosity = { value = 20, weight = 0.3, decay_rate = 1, max = 50 },
    },

    reactions = {
        player_enters = {
            action = "evaluate",
            drive_deltas = { fear = 20 },
            message = "The cat freezes, pupils dilating.",
        },
    },

    health = 8,
    max_health = 8,
    alive = true,

    body_tree = {
        head = { size = 1, vital = true, tissue = { "flesh", "bone" } },
        body = { size = 2, vital = true, tissue = { "flesh", "bone", "organ" } },
        legs = { size = 2, vital = false, tissue = { "flesh", "bone" } },
        tail = { size = 1, vital = false, tissue = { "flesh" } },
    },
}
