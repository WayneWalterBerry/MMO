-- Golden fixture: passes ALL CREATURE-* rules (zero violations expected)
return {
    guid = "{00000000-0000-0000-0000-000000000001}",
    template = "creature",
    id = "test-beast",
    name = "a test beast",
    keywords = {"beast", "test beast", "creature"},
    description = "A compact beast with bristled fur and watchful eyes. It shifts its weight from paw to paw.",

    -- Physical properties
    size = "small",
    weight = 4.0,
    material = "flesh",

    -- Animate
    animate = true,

    -- Sensory (on_feel mandatory — primary dark sense)
    on_feel = "Coarse fur over warm muscle. A heartbeat pulses under your hand.",
    on_smell = "Musky animal scent — damp fur and dry earth.",
    on_listen = "A low, steady breathing. The faint click of claws.",
    on_taste = "You think better of it.",

    -- FSM
    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "The beast sits on its haunches, ears swiveling.",
            room_presence = "A small beast watches you from the corner.",
            on_listen = "Quiet breathing.",
        },
        ["alive-alert"] = {
            description = "The beast stands rigid, hackles raised.",
            room_presence = "A beast stands alert, nostrils flaring.",
        },
        ["*"] = {
            description = "A beast in an undefined state.",
        },
        dead = {
            description = "The beast lies still, eyes glassy.",
            room_presence = "A dead beast lies on the floor.",
            portable = true,
            animate = false,
            on_feel = "Cooling fur. The heartbeat is gone.",
            on_smell = "Blood and musk.",
            on_listen = "Nothing.",
        },
    },
    transitions = {
        { from = "alive-idle",  to = "alive-alert", verb = "_tick", condition = "threat_detected" },
        { from = "alive-alert", to = "alive-idle",  verb = "_tick", condition = "threat_gone" },
        { from = "*",           to = "dead",         verb = "_damage", condition = "health_zero" },
    },

    -- Behavior metadata
    behavior = {
        default = "idle",
        aggression = 20,
        flee_threshold = 50,
        wander_chance = 30,
        settle_chance = 60,
        territorial = false,
        nocturnal = false,
        home_room = nil,
    },

    -- Drives
    drives = {
        hunger = {
            value = 40,
            weight = 0.4,
            decay_rate = 2,
            max = 100,
        },
        fear = {
            value = 0,
            weight = 0.3,
            decay_rate = -5,
            max = 100,
            min = 0,
        },
    },

    -- Reactions
    reactions = {
        player_enters = {
            action = "evaluate",
            drive_deltas = { fear = 20 },
            message = "The beast tenses, eyes locked on you.",
        },
        player_attacks = {
            action = "flee",
            drive_deltas = { fear = 60 },
            message = "The beast yelps and scrambles away!",
        },
        loud_noise = {
            action = "evaluate",
            drive_deltas = { fear = 15 },
            message = "The beast flinches at the sound.",
        },
    },

    -- Health
    health = 12,
    max_health = 12,
    alive = true,

    -- Body zones
    body_tree = {
        head = { size = 1, vital = true, tissue = { "flesh", "bone" },
            names = { "head", "skull" } },
        body = { size = 3, vital = true, tissue = { "flesh", "bone", "organ" },
            names = { "body", "flank", "belly" } },
        legs = { size = 2, vital = false, tissue = { "flesh", "bone" },
            names = { "leg", "hind leg", "foreleg" } },
    },
}
