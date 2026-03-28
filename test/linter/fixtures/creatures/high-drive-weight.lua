-- Triggers CREATURE-007: drive weights must each be 0.0–1.0
-- This creature has a drive with weight = 1.5 (exceeds maximum).
return {
    guid = "{00000000-0000-0000-0000-000000000007}",
    template = "creature",
    id = "starving-hound",
    name = "a starving hound",
    keywords = {"hound", "starving hound", "dog", "creature"},
    description = "A gaunt hound with visible ribs, driven mad by hunger.",

    size = "medium",
    weight = 18.0,
    material = "flesh",

    animate = true,

    on_feel = "Jutting ribs under thin, dry fur. The body trembles.",
    on_smell = "Sour hunger-sweat and old blood.",
    on_listen = "A whimpering growl, low and desperate.",

    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "The hound paces in tight circles, whimpering.",
            room_presence = "A starving hound paces restlessly.",
        },
        dead = {
            description = "The hound lies still, ribs no longer heaving.",
            room_presence = "A dead hound lies on its side.",
            animate = false,
            portable = true,
        },
    },

    behavior = {
        default = "idle",
        aggression = 60,
        flee_threshold = 30,
    },

    drives = {
        -- NOTE: weight of 1.5 exceeds the 0.0–1.0 range — triggers CREATURE-007
        hunger = { value = 90, weight = 1.5, decay_rate = 5, max = 100 },
        fear   = { value = 10, weight = 0.2, decay_rate = -3, max = 100, min = 0 },
    },

    reactions = {
        player_enters = {
            action = "aggressive",
            drive_deltas = { hunger = -10, fear = 5 },
            message = "The hound snarls, drool hanging from cracked lips.",
        },
    },

    health = 15,
    max_health = 15,
    alive = true,

    body_tree = {
        head = { size = 2, vital = true, tissue = { "flesh", "bone" } },
        body = { size = 4, vital = true, tissue = { "flesh", "bone", "organ" } },
        legs = { size = 2, vital = false, tissue = { "flesh", "bone" } },
    },
}
