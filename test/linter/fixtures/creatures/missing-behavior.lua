-- Triggers CREATURE-002: behavior table must exist
-- This creature has no behavior table at all.
return {
    guid = "{00000000-0000-0000-0000-000000000003}",
    template = "creature",
    id = "cave-newt",
    name = "a pale cave newt",
    keywords = {"newt", "cave newt", "creature"},
    description = "A translucent newt with milky eyes and moist, rubbery skin.",

    size = "tiny",
    weight = 0.1,
    material = "flesh",

    animate = true,

    on_feel = "Slick, cool skin. It wriggles feebly.",
    on_smell = "Damp stone and a faint biological mustiness.",
    on_listen = "A wet, quiet shuffling.",

    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "The newt clings to a damp stone.",
            room_presence = "A pale newt sits on a wet rock.",
        },
        dead = {
            description = "The newt lies belly-up, limbs splayed.",
            room_presence = "A dead newt lies on the stones.",
            animate = false,
            portable = true,
        },
    },

    -- NOTE: behavior table is deliberately MISSING

    drives = {
        hunger = { value = 20, weight = 0.6, decay_rate = 1, max = 50 },
    },

    reactions = {
        player_enters = {
            action = "evaluate",
            drive_deltas = { fear = 30 },
            message = "The newt goes very still.",
        },
    },

    health = 1,
    max_health = 1,
    alive = true,

    body_tree = {
        body = { size = 1, vital = true, tissue = { "flesh" } },
        tail = { size = 1, vital = false, tissue = { "flesh" } },
    },
}
