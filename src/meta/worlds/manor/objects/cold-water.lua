-- cold-water.lua — Splashable water for treating burns
-- States: full → empty (terminal)
-- Sourced from wells, rain barrels, or other water containers.
-- Single-use: splash on a burn to treat it.
return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{daef429e-d127-4c4c-867e-2b62a28e2644}",
    template = "small-item",
    id = "cold-water",
    name = "a cup of cold water",
    keywords = {"water", "cold water", "cup of water", "cup"},
    description = "A rough clay cup brimming with cold, clear water drawn from the well. Condensation beads on the outside.",

    -- ═══════════════════════════════════════════════════════════
    -- PHYSICAL PROPERTIES
    -- ═══════════════════════════════════════════════════════════
    size = 1,
    weight = 0.4,
    portable = true,
    material = "ceramic",
    categories = {"liquid", "consumable", "ceramic", "small"},

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    -- ═══════════════════════════════════════════════════════════
    -- TREATMENT PROPERTIES
    -- ═══════════════════════════════════════════════════════════
    is_consumable = true,
    consumable_type = "liquid",
    reusable = false,
    cures = {"burn"},
    healing_boost = 2,

    -- ═══════════════════════════════════════════════════════════
    -- SENSORY (top-level defaults)
    -- ═══════════════════════════════════════════════════════════
    on_feel = "A rough clay cup, cool and damp with condensation. The water inside is cold enough to numb your fingertips.",
    on_smell = "Clean. A faint mineral scent from the well — stone and earth.",
    on_listen = "A soft slosh when tilted. The water is still.",
    on_taste = "Cold, clean water with a faint mineral edge. Refreshing.",
    room_presence = "A cup of cold water sits here, condensation beading on its surface.",

    -- ═══════════════════════════════════════════════════════════
    -- FSM
    -- ═══════════════════════════════════════════════════════════
    initial_state = "full",
    _state = "full",

    states = {
        full = {
            name = "a cup of cold water",
            description = "A rough clay cup brimming with cold, clear water. Condensation beads on the outside.",
            on_feel = "A rough clay cup, cool and damp with condensation. The water inside is cold enough to numb your fingertips.",
            on_smell = "Clean. A faint mineral scent — stone and earth.",
            on_taste = "Cold, clean water with a faint mineral edge.",
            on_listen = "A soft slosh when tilted.",
        },

        empty = {
            name = "an empty clay cup",
            description = "A rough clay cup, drained empty. A few droplets cling to the inside.",
            on_feel = "Rough clay, damp inside but empty. Lighter now.",
            on_smell = "Faint dampness. The mineral scent fading.",
            on_taste = "A last cold drop. Nothing more.",
            on_listen = "A hollow tap when you flick the rim.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "full", to = "empty",
            verb = "splash",
            aliases = {"pour", "use", "apply", "douse"},
            requires_target_injury = true,
            message = "You splash the cold water over the burn. The relief is immediate — the searing heat fades as cool water washes over the angry skin.",
            effect = {
                type = "heal_injury",
                injury_type = "burn",
                source = "cold-water",
                message = "The cold water soothes the burn. The angry redness begins to fade.",
            },
            mutate = {
                weight = 0.15,
                is_consumable = false,
                keywords = {add = "empty"},
            },
        },
        {
            from = "full", to = "empty",
            verb = "drink",
            aliases = {"sip", "gulp", "quaff"},
            message = "You raise the cup and drink. The water is bracingly cold, tasting faintly of stone. Refreshing, but now the cup is empty.",
            mutate = {
                weight = 0.15,
                is_consumable = false,
                keywords = {add = "empty"},
            },
        },
    },

    prerequisites = {
        splash = {requires_state = "full", requires_target_injury = true},
        drink = {requires_state = "full"},
    },

    mutations = {},
}
