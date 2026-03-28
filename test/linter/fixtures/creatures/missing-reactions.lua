-- Triggers CREATURE-009: reactions table must exist with >= 1 entry
-- This creature has no reactions table at all.
return {
    guid = "{00000000-0000-0000-0000-000000000009}",
    template = "creature",
    id = "blind-mole",
    name = "a blind mole",
    keywords = {"mole", "blind mole", "creature"},
    description = "A velvety mole with no visible eyes, digging blindly through loose soil.",

    size = "tiny",
    weight = 0.15,
    material = "flesh",

    animate = true,

    on_feel = "Incredibly soft fur, like touching velvet. Powerful little claws.",
    on_smell = "Fresh earth and roots.",
    on_listen = "Frantic scratching and snuffling.",

    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "The mole noses through loose soil, oblivious.",
            room_presence = "A small mound of dirt shifts as something burrows beneath it.",
        },
        dead = {
            description = "The mole lies on the dirt, paws outstretched.",
            room_presence = "A dead mole lies beside a small mound of earth.",
            animate = false,
            portable = true,
        },
    },

    behavior = {
        default = "idle",
        aggression = 0,
        flee_threshold = 70,
    },

    drives = {
        hunger = { value = 60, weight = 0.6, decay_rate = 3, max = 100 },
    },

    -- NOTE: reactions table is deliberately MISSING

    health = 2,
    max_health = 2,
    alive = true,

    body_tree = {
        body  = { size = 1, vital = true, tissue = { "flesh", "bone" } },
        claws = { size = 1, vital = false, tissue = { "keratin" } },
    },
}
