return {
    guid = "{46c2583c-2cec-4842-bfd3-5d56c737996d}",
    template = "creature",
    id = "cat",
    name = "a grey cat",
    keywords = {"cat", "feline", "grey cat", "creature"},
    description = "A lean grey cat with pale green eyes and a ragged ear. It moves with silent, liquid grace, every muscle coiled beneath a thin coat of dusty fur.",

    -- Physical properties
    size = "small",
    weight = 4.0,
    portable = false,
    material = "flesh",

    -- Animate
    animate = true,

    -- Sensory (on_feel is mandatory — primary dark sense)
    on_feel = "Short, coarse fur over warm muscle. The body tenses under your touch — claws flex against your skin.",
    on_smell = "Warm animal musk and something faintly metallic — old blood on its whiskers.",
    on_listen = "A low, rumbling purr that stops the instant you move. Then silence.",
    on_taste = "You'd lose a finger trying.",

    -- FSM
    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "A grey cat sits perfectly still, watching you with unblinking green eyes.",
            room_presence = "A grey cat crouches in the shadows, eyes gleaming.",
            on_listen = "A faint purr, barely audible. The soft pad of shifting weight.",
        },
        ["alive-wander"] = {
            description = "A grey cat slinks along the wall, pausing to sniff at cracks and corners.",
            room_presence = "A cat prowls the edges of the room.",
            on_listen = "The whisper of padded paws on stone.",
        },
        ["alive-flee"] = {
            description = "The cat bolts — a grey streak vanishing into the nearest shadow.",
            room_presence = "A panicked cat darts across the room.",
            on_listen = "Claws scrabbling on stone, a hiss of expelled air.",
        },
        ["alive-hunt"] = {
            description = "The cat is low to the ground, ears flat, tail twitching — locked onto prey.",
            room_presence = "A cat stalks something with predatory focus.",
            on_listen = "Nothing. The silence of a predator about to strike.",
        },
        dead = {
            description = "A dead cat lies on its side, eyes glassy and half-closed. Its fur is matted with blood.",
            room_presence = "A dead cat lies crumpled on the floor.",
            portable = true,
            animate = false,
            on_feel = "Cooling fur over a limp body. The claws are still extended.",
            on_smell = "Blood and warm fur. The musk is already fading.",
            on_listen = "Nothing. The purr is gone.",
            on_taste = "Fur and blood. No.",
        },
    },
    transitions = {
        { from = "alive-idle",   to = "alive-wander", verb = "_tick", condition = "wander_roll" },
        { from = "alive-wander", to = "alive-idle",   verb = "_tick", condition = "settle_roll" },
        { from = "alive-idle",   to = "alive-hunt",   verb = "_tick", condition = "prey_detected" },
        { from = "alive-wander", to = "alive-hunt",   verb = "_tick", condition = "prey_detected" },
        { from = "alive-hunt",   to = "alive-idle",   verb = "_tick", condition = "prey_lost" },
        { from = "alive-idle",   to = "alive-flee",   verb = "_tick", condition = "fear_high" },
        { from = "alive-wander", to = "alive-flee",   verb = "_tick", condition = "fear_high" },
        { from = "alive-hunt",   to = "alive-flee",   verb = "_tick", condition = "fear_high" },
        { from = "alive-flee",   to = "alive-idle",   verb = "_tick", condition = "fear_low" },
        { from = "*",            to = "dead",          verb = "_damage", condition = "health_zero" },
    },

    -- Behavior metadata
    behavior = {
        default = "idle",
        aggression = 40,
        flee_threshold = 50,
        wander_chance = 35,
        settle_chance = 50,
        territorial = false,
        nocturnal = true,
        home_room = nil,
        prey = {"rat"},
    },

    -- Drives
    drives = {
        hunger = {
            value = 40,
            decay_rate = 3,
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
            value = 50,
            decay_rate = 1,
            max = 80,
        },
    },

    -- Reactions
    reactions = {
        player_enters = {
            action = "evaluate",
            fear_delta = 20,
            message = "The cat freezes, ears swiveling toward you. Its tail tip flicks once.",
        },
        player_attacks = {
            action = "flee",
            fear_delta = 70,
            message = "The cat yowls — a savage, throaty scream — and bolts for cover!",
        },
        loud_noise = {
            action = "evaluate",
            fear_delta = 30,
            message = "The cat flattens its ears and drops into a crouch.",
        },
        light_change = {
            action = "evaluate",
            fear_delta = 10,
            message = "The cat's pupils contract to narrow slits in the sudden light.",
        },
    },

    -- Movement
    movement = {
        speed = 3,
        can_open_doors = false,
        can_climb = true,
        size_limit = 2,
    },

    -- Awareness
    awareness = {
        sight_range = 3,
        sound_range = 2,
        smell_range = 2,
    },

    -- Health
    health = 15,
    max_health = 15,
    alive = true,

    -- Body zones
    body_tree = {
        head = { size = 1, vital = true, tissue = { "hide", "flesh", "bone" } },
        body = { size = 3, vital = true, tissue = { "hide", "flesh", "bone", "organ" } },
        legs = { size = 2, vital = false, tissue = { "hide", "flesh", "bone" }, on_damage = { "reduced_movement" } },
        tail = { size = 1, vital = false, tissue = { "hide", "flesh" }, on_damage = { "balance_loss" } },
    },

    -- Combat metadata
    combat = {
        size = "small",
        speed = 7,
        natural_weapons = {
            { id = "claw", type = "slash", material = "keratin", zone = "legs", force = 3, target_pref = "arms", message = "rakes its claws across" },
            { id = "bite", type = "pierce", material = "tooth-enamel", zone = "head", force = 5, target_pref = "hands", message = "sinks its fangs into" },
        },
        natural_armor = nil,
        behavior = {
            aggression = "on_provoke",
            flee_threshold = 0.5,
            attack_pattern = "opportunistic",
            defense = "dodge",
            target_priority = "weakest",
            pack_size = 1,
        },
    },

    -- Death reshape (WAVE-1)
    death_state = {
        template = "small-item",
        name = "a dead cat",
        description = "A dead grey cat lies on its side, eyes glassy and half-closed. Its fur is matted with blood and its claws are still extended.",
        keywords = {"dead cat", "cat corpse", "cat carcass", "dead feline", "cat"},
        room_presence = "A dead cat lies crumpled on the floor.",

        -- Physical
        portable = true,
        size = "small",
        weight = 3.5,

        -- Sensory (on_feel mandatory — primary dark sense)
        on_feel = "Soft fur over a limp body, already cooling. The claws are still extended, pricking your fingers.",
        on_smell = "Blood and warm fur. The musk is already fading.",
        on_listen = "Nothing. The purr is gone.",
        on_taste = "Fur and blood. No.",

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
                becomes = "cooked-cat-meat",
                requires_tool = "fire_source",
                message = "You hold the cat over the flames. The fur blackens and curls away, leaving dark meat.",
                fail_message_no_tool = "You need a fire source to cook this.",
            },
        },

        -- Container (small corpse can hold 2 items)
        container = {
            capacity = 2,
            categories = { "tiny", "small" },
        },

        -- Spoilage FSM
        initial_state = "fresh",
        states = {
            fresh = {
                description = "A freshly killed cat. The blood is still wet on its grey fur.",
                room_presence = "A dead cat lies crumpled on the floor.",
                duration = 30,
            },
            bloated = {
                description = "The cat's body has swollen, its belly taut with gas. The fur is slick.",
                room_presence = "A bloated cat carcass lies on the floor, reeking.",
                on_smell = "The sweet, cloying stench of decay.",
                food = { cookable = false },
                duration = 40,
            },
            rotten = {
                description = "The cat is a matted ruin of fur and exposed tissue. Flies circle.",
                room_presence = "A rotting cat carcass festers on the floor.",
                on_smell = "Overwhelming rot. Your eyes water.",
                food = { cookable = false, edible = false },
                duration = 60,
            },
            bones = {
                description = "A scatter of cat bones, picked clean.",
                room_presence = "A pile of cat bones sits on the floor.",
                on_smell = "Nothing — just dry bone.",
                on_feel = "Slender, fragile bones. They shift under your touch.",
                food = nil,
            },
        },
        transitions = {
            { from = "fresh", to = "bloated", verb = "_tick", condition = "timer_expired" },
            { from = "bloated", to = "rotten", verb = "_tick", condition = "timer_expired" },
            { from = "rotten", to = "bones", verb = "_tick", condition = "timer_expired" },
        },

        transfer_contents = true,
    },
}
