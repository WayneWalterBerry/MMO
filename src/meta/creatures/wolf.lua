return {
    guid = "{e69fc5e8-ce63-4b26-b5b2-faa2ff85d12c}",
    template = "creature",
    id = "wolf",
    name = "a grey wolf",
    keywords = {"wolf", "grey wolf", "canine", "creature"},
    description = "A large grey wolf with amber eyes and a thick, scarred coat. Its lips are drawn back over yellowed fangs, and a low growl vibrates in its chest.",

    -- Physical properties
    size = "medium",
    weight = 35.0,
    portable = false,
    material = "flesh",

    -- Animate
    animate = true,

    -- Sensory (on_feel is mandatory — primary dark sense)
    on_feel = "Coarse, dense fur over solid muscle. The body is hot — feverishly warm. You feel the growl before you hear it.",
    on_smell = "Wet dog and old meat. A predator's musk, sharp and territorial.",
    on_listen = "A low, sustained growl. The click of claws on stone. Measured breathing.",
    on_taste = "It would taste you first.",

    -- FSM
    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "A grey wolf stands motionless, amber eyes fixed on you with unnerving intelligence.",
            room_presence = "A wolf watches from the far side of the room, utterly still.",
            on_listen = "Slow, deliberate breathing. The faint click of shifting claws.",
        },
        ["alive-wander"] = {
            description = "The wolf paces in a wide circuit, nose to the ground, reading scents.",
            room_presence = "A wolf paces the room, sniffing the air.",
            on_listen = "Padded footfalls and the wet sound of sniffing.",
        },
        ["alive-patrol"] = {
            description = "The wolf moves with purpose along its territory's boundary, marking and guarding.",
            room_presence = "A wolf patrols the passage, hackles raised.",
            on_listen = "A low, rhythmic growl — a warning to trespassers.",
        },
        ["alive-aggressive"] = {
            description = "The wolf's hackles are raised, lips peeled back. It advances, snarling.",
            room_presence = "A snarling wolf blocks the way, fangs bared.",
            on_listen = "A deep, rumbling snarl that vibrates the air. Claws scraping stone.",
        },
        ["alive-flee"] = {
            description = "The wolf breaks and runs, tail tucked, a grey blur retreating into darkness.",
            room_presence = "A wounded wolf limps toward the exit.",
            on_listen = "Rapid panting and the scramble of claws on stone.",
        },
        dead = {
            description = "The wolf lies on its side, tongue lolling. Its amber eyes stare at nothing. Blood pools beneath the thick coat.",
            room_presence = "A dead wolf sprawls across the floor.",
            portable = false,
            animate = false,
            on_feel = "Coarse fur, already cooling. The massive jaw hangs slack. The growl is gone.",
            on_smell = "Blood and wet fur. The territorial musk is fading.",
            on_listen = "Nothing. The growl has stopped.",
            on_taste = "Rank meat and matted fur.",
        },
    },
    transitions = {
        { from = "alive-idle",       to = "alive-wander",     verb = "_tick", condition = "wander_roll" },
        { from = "alive-wander",     to = "alive-idle",       verb = "_tick", condition = "settle_roll" },
        { from = "alive-idle",       to = "alive-patrol",     verb = "_tick", condition = "territory_check" },
        { from = "alive-wander",     to = "alive-patrol",     verb = "_tick", condition = "territory_check" },
        { from = "alive-patrol",     to = "alive-idle",       verb = "_tick", condition = "patrol_complete" },
        { from = "alive-idle",       to = "alive-aggressive", verb = "_tick", condition = "threat_detected" },
        { from = "alive-patrol",     to = "alive-aggressive", verb = "_tick", condition = "threat_detected" },
        { from = "alive-wander",     to = "alive-aggressive", verb = "_tick", condition = "threat_detected" },
        { from = "alive-aggressive", to = "alive-idle",       verb = "_tick", condition = "threat_gone" },
        { from = "alive-aggressive", to = "alive-flee",       verb = "_tick", condition = "fear_high" },
        { from = "alive-idle",       to = "alive-flee",       verb = "_tick", condition = "fear_high" },
        { from = "alive-flee",       to = "alive-idle",       verb = "_tick", condition = "fear_low" },
        { from = "*",                to = "dead",             verb = "_damage", condition = "health_zero" },
    },

    -- Behavior metadata
    behavior = {
        default = "idle",
        aggression = 70,
        flee_threshold = 20,
        wander_chance = 25,
        settle_chance = 40,
        territorial = true,
        territory = "hallway",
        nocturnal = false,
        home_room = nil,
        prey = {"rat", "cat", "bat"},
    },

    -- Drives
    drives = {
        hunger = {
            value = 30,
            decay_rate = 1,
            max = 100,
            satisfy_action = "eat",
            satisfy_threshold = 80,
        },
        fear = {
            value = 0,
            decay_rate = -5,
            max = 100,
            min = 0,
        },
        curiosity = {
            value = 20,
            decay_rate = 1,
            max = 40,
        },
    },

    -- Reactions
    reactions = {
        player_enters = {
            action = "aggressive",
            fear_delta = 0,
            message = "The wolf's head snaps toward you. A deep growl fills the passage.",
        },
        player_attacks = {
            action = "aggressive",
            fear_delta = 10,
            message = "The wolf snarls and lunges, fangs bared!",
        },
        loud_noise = {
            action = "evaluate",
            fear_delta = 5,
            message = "The wolf's ears flatten. It lowers its head, growling louder.",
        },
        light_change = {
            action = "evaluate",
            fear_delta = 5,
            message = "The wolf's amber eyes flash in the sudden light. It does not flinch.",
        },
    },

    -- Movement
    movement = {
        speed = 3,
        can_open_doors = false,
        can_climb = false,
        size_limit = 3,
    },

    -- Awareness
    awareness = {
        sight_range = 3,
        sound_range = 4,
        smell_range = 5,
    },

    -- Health
    health = 40,
    max_health = 40,
    alive = true,

    -- Body zones
    body_tree = {
        head     = { size = 2, vital = true,  tissue = { "hide", "flesh", "bone" } },
        body     = { size = 5, vital = true,  tissue = { "hide", "flesh", "bone", "organ" } },
        forelegs = { size = 3, vital = false, tissue = { "hide", "flesh", "bone" }, on_damage = { "reduced_movement" } },
        hindlegs = { size = 3, vital = false, tissue = { "hide", "flesh", "bone" }, on_damage = { "reduced_movement" } },
        tail     = { size = 1, vital = false, tissue = { "hide", "flesh" } },
    },

    -- Combat metadata
    combat = {
        size = "medium",
        speed = 7,
        natural_weapons = {
            { id = "bite", type = "pierce", material = "tooth-enamel", zone = "head", force = 8, target_pref = "arms", message = "clamps its jaws onto" },
            { id = "claw", type = "slash", material = "keratin", zone = "forelegs", force = 4, message = "rakes its claws across" },
        },
        natural_armor = {
            { material = "hide", coverage = { "body", "head" }, thickness = 2 },
        },
        behavior = {
            aggression = "territorial",
            flee_threshold = 0.2,
            attack_pattern = "sustained",
            defense = "counter",
            target_priority = "threatening",
            pack_size = 1,
        },
    },
}
