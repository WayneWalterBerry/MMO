-- Triggers CREATURE-017: FSM must include dead state
-- This creature has states but no "dead" key.
return {
    guid = "{00000000-0000-0000-0000-00000000000b}",
    template = "creature",
    id = "dust-moth",
    name = "a dust moth",
    keywords = {"moth", "dust moth", "creature"},
    description = "A large grey moth with powdery wings, circling a heat source.",

    size = "tiny",
    weight = 0.01,
    material = "chitin",

    animate = true,

    on_feel = "Papery wings that shed fine dust at the slightest touch.",
    on_smell = "Dry dust and the faint sweetness of scale powder.",
    on_listen = "A soft, erratic fluttering.",

    initial_state = "alive-idle",
    _state = "alive-idle",
    -- NOTE: no "dead" state — triggers CREATURE-017
    states = {
        ["alive-idle"] = {
            description = "The moth rests on the wall, wings folded flat.",
            room_presence = "A large moth clings to the wall, utterly still.",
        },
        ["alive-flutter"] = {
            description = "The moth circles in erratic loops, shedding wing dust.",
            room_presence = "A moth flutters near the ceiling.",
        },
    },
    transitions = {
        { from = "alive-idle",    to = "alive-flutter", verb = "_tick", condition = "light_detected" },
        { from = "alive-flutter", to = "alive-idle",    verb = "_tick", condition = "settle_roll" },
    },

    behavior = {
        default = "idle",
        aggression = 0,
        flee_threshold = 95,
    },

    drives = {
        curiosity = { value = 50, weight = 0.7, decay_rate = 2, max = 80 },
    },

    reactions = {
        light_change = {
            action = "evaluate",
            drive_deltas = { curiosity = 30 },
            message = "The moth stirs, drawn toward the light.",
        },
    },

    health = 1,
    max_health = 1,
    alive = true,

    body_tree = {
        body  = { size = 1, vital = true, tissue = { "chitin" } },
        wings = { size = 1, vital = false, tissue = { "chitin" } },
    },
}
