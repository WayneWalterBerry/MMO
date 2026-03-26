return {
    guid = "{071e73f6-535e-42cb-b981-ebf85c27356f}",
    template = "creature",
    id = "rat",
    name = "a brown rat",
    keywords = {"rat", "rodent", "vermin", "brown rat", "creature"},
    description = "A plump brown rat with matted fur and a long, naked tail. Its beady black eyes dart nervously, and its whiskers twitch with constant, anxious energy.",

    -- Physical properties
    size = "tiny",
    weight = 0.3,
    portable = false,
    material = "flesh",

    -- Animate
    animate = true,

    -- Sensory (on_feel is mandatory — primary dark sense)
    on_feel = "Coarse, greasy fur over a warm, squirming body. A thick tail whips against your fingers. It bites.",
    on_smell = "Musty rodent — damp fur, old nesting material, and the faint ammonia of urine.",
    on_listen = "Skittering claws on stone. An occasional high-pitched squeak.",
    on_taste = "You'd have to catch it first. And then you'd regret it.",

    -- FSM
    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "A brown rat sits hunched near the baseboard, grooming itself with tiny pink paws.",
            room_presence = "A rat crouches in the shadows near the wall.",
            on_listen = "Quiet chittering. The soft rasp of fur being groomed.",
        },
        ["alive-wander"] = {
            description = "A brown rat scurries across the floor, nose working furiously.",
            room_presence = "A rat scurries along the baseboard.",
            on_listen = "The rapid click of tiny claws on stone.",
        },
        ["alive-flee"] = {
            description = "The rat is a blur of brown fur, darting frantically toward the nearest exit.",
            room_presence = "A panicked rat zigzags across the floor.",
            on_listen = "Frantic squeaking and the scrabble of claws.",
        },
        dead = {
            description = "A dead rat lies on its side, legs splayed. Its fur is matted with blood.",
            room_presence = "A dead rat lies crumpled on the floor.",
            portable = true,
            animate = false,
            on_feel = "Cooling fur over a limp body. The tail hangs like wet string.",
            on_smell = "Blood and musk. The sharp copper of death.",
            on_listen = "Nothing. Absolutely nothing.",
            on_taste = "Fur and blood. You immediately regret this decision.",
        },
    },
    transitions = {
        { from = "alive-idle",   to = "alive-wander", verb = "_tick", condition = "wander_roll" },
        { from = "alive-wander", to = "alive-idle",   verb = "_tick", condition = "settle_roll" },
        { from = "alive-idle",   to = "alive-flee",   verb = "_tick", condition = "fear_high" },
        { from = "alive-wander", to = "alive-flee",   verb = "_tick", condition = "fear_high" },
        { from = "alive-flee",   to = "alive-idle",   verb = "_tick", condition = "fear_low" },
        { from = "*",            to = "dead",          verb = "_damage", condition = "health_zero" },
    },

    -- Behavior metadata
    behavior = {
        default = "idle",
        aggression = 5,
        flee_threshold = 30,
        wander_chance = 40,
        settle_chance = 60,
        territorial = false,
        nocturnal = true,
        home_room = nil,
    },

    -- Drives (simplified DF needs)
    drives = {
        hunger = {
            value = 50,
            decay_rate = 2,
            max = 100,
            satisfy_action = "eat",
            satisfy_threshold = 80,
        },
        fear = {
            value = 0,
            decay_rate = -10,
            max = 100,
            min = 0,
        },
        curiosity = {
            value = 30,
            decay_rate = 1,
            max = 60,
        },
    },

    -- Reactions (stimulus -> response)
    reactions = {
        player_enters = {
            action = "evaluate",
            fear_delta = 35,
            message = "A rat freezes, beady eyes fixed on you. Its whiskers quiver.",
        },
        player_attacks = {
            action = "flee",
            fear_delta = 80,
            message = "The rat squeals — a piercing, desperate sound — and bolts!",
        },
        loud_noise = {
            action = "flee",
            fear_delta = 25,
            message = "The rat startles at the noise and scurries into the shadows.",
        },
        light_change = {
            action = "evaluate",
            fear_delta = 15,
            message = "The rat's eyes flash red in the sudden light. It flinches.",
        },
    },

    -- Movement
    movement = {
        speed = 1,
        can_open_doors = false,
        can_climb = true,
        size_limit = 1,
    },

    -- Awareness
    awareness = {
        sight_range = 1,
        sound_range = 2,
        smell_range = 3,
    },

    -- Health
    health = 5,
    max_health = 5,
    alive = true,

    -- Body zones (WAVE-4: combat data layer)
    body_tree = {
        head = { size = 1, vital = true, tissue = { "hide", "flesh", "bone" } },
        body = { size = 3, vital = true, tissue = { "hide", "flesh", "bone", "organ" } },
        legs = { size = 2, vital = false, tissue = { "hide", "flesh", "bone" }, on_damage = { "reduced_movement" } },
        tail = { size = 1, vital = false, tissue = { "hide", "flesh" }, on_damage = { "balance_loss" } },
    },

    -- Combat metadata (WAVE-4)
    combat = {
        size = "tiny",
        speed = 6,
        natural_weapons = {
            { id = "bite", type = "pierce", material = "tooth-enamel", zone = "head", force = 2, target_pref = "arms", message = "sinks its teeth into" },
            { id = "claw", type = "slash", material = "keratin", zone = "legs", force = 1, message = "rakes its claws across" },
        },
        natural_armor = nil,
        behavior = {
            aggression = "on_provoke",
            flee_threshold = 0.3,
            attack_pattern = "random",
            defense = "dodge",
            target_priority = "threatening",
            pack_size = 1,
        },
    },
}
