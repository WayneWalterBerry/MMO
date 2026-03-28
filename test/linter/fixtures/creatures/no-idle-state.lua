-- Triggers CREATURE-004: behavior.states must include "idle" key
-- This creature has "alert" and "dead" states but no "idle" variant.
return {
    guid = "{00000000-0000-0000-0000-000000000005}",
    template = "creature",
    id = "tunnel-snake",
    name = "a tunnel snake",
    keywords = {"snake", "tunnel snake", "creature"},
    description = "A sleek black snake coiled in the shadows, tongue flickering.",

    size = "small",
    weight = 1.5,
    material = "flesh",

    animate = true,

    on_feel = "Dry, smooth scales over dense muscle. It tenses at your touch.",
    on_smell = "A dry, reptilian musk.",
    on_listen = "A low, sustained hiss.",

    initial_state = "alive-alert",
    _state = "alive-alert",
    -- NOTE: no "alive-idle" or "idle" state — only "alert" and "dead"
    states = {
        ["alive-alert"] = {
            description = "The snake is coiled tight, hood flared.",
            room_presence = "A black snake watches you, hood raised.",
            on_listen = "A steady, threatening hiss.",
        },
        dead = {
            description = "The snake lies uncoiled, jaw slack.",
            room_presence = "A dead snake lies stretched on the floor.",
            animate = false,
            portable = true,
        },
    },
    transitions = {
        { from = "*", to = "dead", verb = "_damage", condition = "health_zero" },
    },

    behavior = {
        default = "alert",
        aggression = 40,
        flee_threshold = 60,
    },

    drives = {
        hunger = { value = 50, weight = 0.5, decay_rate = 1, max = 100 },
        fear   = { value = 0,  weight = 0.3, decay_rate = -5, max = 100, min = 0 },
    },

    reactions = {
        player_enters = {
            action = "aggressive",
            drive_deltas = { fear = 10 },
            message = "The snake raises its head and hisses.",
        },
    },

    health = 6,
    max_health = 6,
    alive = true,

    body_tree = {
        head = { size = 1, vital = true, tissue = { "flesh", "bone" } },
        body = { size = 3, vital = true, tissue = { "flesh", "bone" } },
    },
}
