-- Triggers CREATURE-003: behavior must have >= 1 drive entry
-- This creature has an empty drives table.
return {
    guid = "{00000000-0000-0000-0000-000000000004}",
    template = "creature",
    id = "moss-slug",
    name = "a moss slug",
    keywords = {"slug", "moss slug", "creature"},
    description = "A fat green slug leaving a glistening trail across the stone.",

    size = "tiny",
    weight = 0.05,
    material = "flesh",

    animate = true,

    on_feel = "Cold, slimy flesh. It contracts at your touch.",
    on_smell = "Wet moss and a faint sourness.",
    on_listen = "A barely audible squelch.",

    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "The slug inches across a damp stone.",
            room_presence = "A slug oozes along the floor.",
        },
        dead = {
            description = "The slug lies in a puddle of its own slime.",
            room_presence = "A dead slug lies in a pool of slime.",
            animate = false,
            portable = true,
        },
    },

    behavior = {
        default = "idle",
        aggression = 0,
        flee_threshold = 100,
    },

    -- NOTE: drives table is deliberately EMPTY
    drives = {},

    reactions = {
        player_enters = {
            action = "evaluate",
            drive_deltas = { fear = 5 },
            message = "The slug retracts its eyestalks.",
        },
    },

    health = 1,
    max_health = 1,
    alive = true,

    body_tree = {
        body = { size = 1, vital = true, tissue = { "flesh" } },
    },
}
