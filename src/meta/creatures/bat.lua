return {
    guid = "{52e32931-84dc-4a3d-a2cf-04cf79d61f4c}",
    template = "creature",
    id = "bat",
    name = "a small brown bat",
    keywords = {"bat", "brown bat", "creature"},
    description = "A small brown bat clings to the ceiling by hooked claws, leathery wings folded tight against its body. Its tiny eyes are shut, ears twitching.",

    -- Physical properties
    size = "tiny",
    weight = 0.02,
    portable = false,
    material = "flesh",

    -- Animate
    animate = true,

    -- Sensory (on_feel is mandatory — primary dark sense)
    on_feel = "Delicate, papery wings stretched over thin bone. The tiny body trembles — a rapid heartbeat under warm, velvety fur.",
    on_smell = "Musky and faintly sour. Guano and warm fur.",
    on_listen = "High-pitched chittering, almost beyond hearing. The soft flutter of restless wings.",
    on_taste = "You'd have to catch it mid-flight. You can't.",

    -- FSM
    initial_state = "alive-roosting",
    _state = "alive-roosting",
    states = {
        ["alive-roosting"] = {
            description = "A small bat hangs upside-down from the ceiling, wings folded, perfectly still except for the twitch of its ears.",
            room_presence = "A bat clings to the ceiling overhead.",
            on_listen = "Faint, rhythmic breathing. The occasional click of echolocation.",
        },
        ["alive-flying"] = {
            description = "The bat swoops through the air in erratic arcs, leathery wings snapping with each turn.",
            room_presence = "A bat circles the room in rapid, darting loops.",
            on_listen = "The snap of leathery wings and high-pitched squeaking.",
        },
        ["alive-flee"] = {
            description = "The bat shrieks and spirals toward the ceiling, desperately seeking an exit.",
            room_presence = "A panicked bat careens wildly through the air.",
            on_listen = "Frantic squeaking and the frenzied beat of wings.",
        },
        dead = {
            description = "A dead bat lies on the floor, wings crumpled and splayed. Its tiny mouth hangs open.",
            room_presence = "A dead bat lies on the floor, wings spread like crumpled parchment.",
            portable = true,
            animate = false,
            on_feel = "Papery wings, already stiffening. The fur is impossibly soft. No heartbeat.",
            on_smell = "Guano and cooling flesh.",
            on_listen = "Nothing. The chittering has stopped.",
            on_taste = "Thin fur and tiny bones. Bitter.",
        },
    },
    transitions = {
        { from = "alive-roosting", to = "alive-flying", verb = "_tick", condition = "wander_roll" },
        { from = "alive-flying",   to = "alive-roosting", verb = "_tick", condition = "settle_roll" },
        { from = "alive-roosting", to = "alive-flee",   verb = "_tick", condition = "fear_high" },
        { from = "alive-flying",   to = "alive-flee",   verb = "_tick", condition = "fear_high" },
        { from = "alive-flee",     to = "alive-roosting", verb = "_tick", condition = "fear_low" },
        { from = "*",              to = "dead",          verb = "_damage", condition = "health_zero" },
    },

    -- Behavior metadata
    behavior = {
        default = "roosting",
        aggression = 5,
        flee_threshold = 40,
        wander_chance = 20,
        settle_chance = 60,
        territorial = false,
        nocturnal = true,
        home_room = nil,
        light_reactive = true,
        roosting_position = "ceiling",
    },

    -- Drives
    drives = {
        hunger = {
            value = 30,
            decay_rate = 2,
            max = 100,
            satisfy_action = "eat",
            satisfy_threshold = 80,
        },
        fear = {
            value = 20,
            decay_rate = -10,
            max = 100,
            min = 0,
        },
        curiosity = {
            value = 15,
            decay_rate = 1,
            max = 40,
        },
    },

    -- Reactions
    reactions = {
        player_enters = {
            action = "evaluate",
            fear_delta = 20,
            message = "The bat's ears swivel toward you. Its claws tighten on the ceiling.",
        },
        player_attacks = {
            action = "flee",
            fear_delta = 80,
            message = "The bat shrieks — a piercing ultrasonic screech — and takes flight!",
        },
        loud_noise = {
            action = "flee",
            fear_delta = 40,
            message = "The bat drops from the ceiling and erupts into panicked flight.",
        },
        light_change = {
            action = "flee",
            fear_delta = 60,
            message = "The bat screeches and launches from the ceiling, wings flailing against the sudden light!",
        },
    },

    -- Movement
    movement = {
        speed = 4,
        can_open_doors = false,
        can_climb = true,
        size_limit = 1,
    },

    -- Awareness
    awareness = {
        sight_range = 1,
        sound_range = 5,
        smell_range = 1,
    },

    -- Health
    health = 3,
    max_health = 3,
    alive = true,

    -- Body zones
    body_tree = {
        head  = { size = 1, vital = true,  tissue = { "hide", "flesh", "bone" } },
        body  = { size = 1, vital = true,  tissue = { "hide", "flesh", "bone", "organ" } },
        wings = { size = 2, vital = false, tissue = { "hide", "flesh" }, on_damage = { "grounded" } },
        legs  = { size = 1, vital = false, tissue = { "hide", "flesh", "bone" }, on_damage = { "reduced_movement" } },
    },

    -- Combat metadata
    combat = {
        size = "tiny",
        speed = 9,
        natural_weapons = {
            { id = "bite", type = "pierce", material = "tooth-enamel", zone = "head", force = 1, target_pref = "head", message = "sinks its tiny fangs into" },
        },
        natural_armor = nil,
        behavior = {
            aggression = "passive",
            flee_threshold = 0.4,
            attack_pattern = "hit_and_run",
            defense = "dodge",
            target_priority = "closest",
            pack_size = 1,
        },
    },
}
