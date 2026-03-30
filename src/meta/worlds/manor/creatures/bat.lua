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

    -- Sound events (WAVE-1 Track 1A)
    sounds = {
        ambient_loop = "bat-chitter.opus",
        ["on_state_alive-flying"] = "bat-wings.opus",
        ["on_state_alive-flee"] = "bat-screech.opus",
    },

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
        ["alive-idle"] = {
            description = "A small bat hangs quietly, at rest.",
            room_presence = "A bat clings to the ceiling.",
        },
        ["alive-wander"] = {
            description = "A bat flutters about.",
            room_presence = "A bat flutters through the air.",
        },
        ["*"] = {
            description = "A bat in an undefined state.",
        },
        dead = {
            description = "A dead bat lies on the floor, wings crumpled and splayed. Its tiny mouth hangs open.",
            room_presence = "A dead bat lies on the floor, wings spread like crumpled parchment.",
            portable = true,
            animate = false,
            on_feel = "Papery wings, already stiffening. The fur is impossibly soft. No heartbeat.",
            on_smell = "Guano and cooling flesh.",
            on_listen = "The bat is motionless. No breath, no sound.",
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
        head  = { size = 1, vital = true,  tissue = { "hide", "flesh", "bone" },
            names = { "head", "skull" } },
        body  = { size = 1, vital = true,  tissue = { "hide", "flesh", "bone", "organ" },
            names = { "body", "torso" } },
        wings = { size = 2, vital = false, tissue = { "hide", "flesh" }, on_damage = { "grounded" },
            names = { "wing", "wing membrane", "outstretched wing" } },
        legs  = { size = 1, vital = false, tissue = { "hide", "flesh", "bone" }, on_damage = { "reduced_movement" },
            names = { "leg", "claw", "hind leg" } },
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

    -- Respawn metadata (WAVE-5)
    respawn = {
        timer = 60,
        home_room = "crypt",
        max_population = 3,
    },

    -- Death reshape (WAVE-1)
    death_state = {
        template = "small-item",
        name = "a dead bat",
        description = "A dead bat lies on the floor, wings crumpled and splayed like torn parchment. Its tiny mouth hangs open, revealing needle-thin fangs.",
        keywords = {"dead bat", "bat corpse", "bat carcass", "bat"},
        room_presence = "A dead bat lies on the floor, wings spread like crumpled parchment.",

        -- Physical
        portable = true,
        size = "tiny",
        weight = 0.15,

        -- Sensory (on_feel mandatory — primary dark sense)
        on_feel = "Papery wings, already stiffening. The fur is impossibly soft. No heartbeat.",
        on_smell = "Guano and cooling flesh. A faint musk.",
        on_listen = "The bat is motionless. No breath, no sound.",
        on_taste = "Thin fur and tiny bones. Bitter.",

        -- Food properties
        food = {
            category = "meat",
            raw = true,
            edible = false,
            cookable = true,
        },

        -- Cooking recipe (read by cook verb)
        crafting = {
            cook = {
                becomes = "cooked-bat-meat",
                requires_tool = "fire_source",
                message = "You singe the bat's leathery wings over the fire. The meat underneath is thin but edible.",
                fail_message_no_tool = "You need a fire source to cook this.",
            },
        },

        -- Spoilage FSM
        initial_state = "fresh",
        states = {
            fresh = {
                description = "A freshly killed bat. The wings are still pliable.",
                room_presence = "A dead bat lies on the floor, wings spread like crumpled parchment.",
                timed_events = { { delay = 25, event = "timer_expired", to_state = "bloated" } },
            },
            bloated = {
                description = "The bat's tiny body has swollen, wings stretched taut over distended flesh.",
                room_presence = "A bloated bat carcass lies on the floor.",
                on_smell = "The sweet stench of tiny decay.",
                food = { cookable = false },
                timed_events = { { delay = 35, event = "timer_expired", to_state = "rotten" } },
            },
            rotten = {
                description = "The bat is a shriveled husk, wings torn and matted with decay.",
                room_presence = "A rotting bat carcass shrivels on the floor.",
                on_smell = "A concentrated, sour rot.",
                food = { cookable = false, edible = false },
                timed_events = { { delay = 50, event = "timer_expired", to_state = "bones" } },
            },
            bones = {
                description = "A tiny scatter of bat bones, thin as needles.",
                room_presence = "A scattering of tiny bat bones sits on the floor.",
                on_smell = "Nothing — just dry bone.",
                on_feel = "Needle-thin bones, impossibly fragile. They snap at a touch.",
                food = nil,
            },
        },
        transitions = {
            { from = "fresh", to = "bloated", trigger = "auto", condition = "timer_expired" },
            { from = "bloated", to = "rotten", trigger = "auto", condition = "timer_expired" },
            { from = "rotten", to = "bones", trigger = "auto", condition = "timer_expired" },
        },
    },
}
