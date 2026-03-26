-- template: creature
-- Base template for animate beings (animals, monsters, eventually humanoids).
-- Creatures are objects with behavior metadata evaluated by the creature tick.

return {
    guid = "{bf9f9d4d-7b6d-4f99-801d-f6921a2687cd}",
    id = "creature",
    name = "a creature",
    keywords = {},
    description = "A living creature.",

    -- Object properties
    size = "small",
    weight = 1.0,
    portable = false,
    material = "flesh",
    container = false,
    capacity = 0,
    contents = {},
    location = nil,
    categories = {"creature"},
    mutations = {},

    -- Creature extension (Principle 0a)
    animate = true,

    -- Required sensory (on_feel is mandatory per engine rules)
    on_feel = "Warm, alive.",
    on_smell = "An animal smell.",
    on_listen = "Quiet breathing.",
    on_taste = nil,

    -- FSM: creatures use the same FSM engine as objects
    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "Standing still, alert.",
        },
        ["alive-wander"] = {
            description = "Wandering aimlessly.",
        },
        ["alive-flee"] = {
            description = "Fleeing in panic.",
        },
        ["dead"] = {
            description = "Lying motionless on the ground.",
            animate = false,
            portable = true,
        },
    },
    transitions = {},

    -- Behavior metadata (engine evaluates generically)
    behavior = {
        default = "idle",
        aggression = 0,
        flee_threshold = 50,
        wander_chance = 0,
        territorial = false,
        nocturnal = false,
        home_room = nil,
    },

    -- Drives (Dwarf Fortress needs system, simplified)
    drives = {},

    -- Reactions: stimulus -> response mapping (metadata-driven)
    reactions = {},

    -- Movement rules
    movement = {
        speed = 1,
        can_open_doors = false,
        can_climb = false,
        size_limit = nil,
    },

    -- Awareness
    awareness = {
        sight_range = 1,
        sound_range = 2,
        smell_range = 1,
    },

    -- Health/mortality
    health = 10,
    max_health = 10,
    alive = true,
}
