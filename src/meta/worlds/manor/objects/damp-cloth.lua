-- damp-cloth.lua — Wet cloth compress for treating burns
-- States: damp → dry (terminal after use)
-- A cloth soaked in water, pressed against burns to cool them.
-- Reusable if re-wetted, but for now single-use until wash verb integration.
return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{9f74aea7-3b3c-446c-b837-f88d8e52ea83}",
    template = "small-item",
    id = "damp-cloth",
    name = "a damp cloth",
    keywords = {"damp cloth", "wet cloth", "compress", "damp rag", "wet rag", "cool cloth"},
    description = "A square of linen soaked in cold water, wrung out just enough to stop dripping. It's cool to the touch and faintly smells of well water.",

    -- ═══════════════════════════════════════════════════════════
    -- PHYSICAL PROPERTIES
    -- ═══════════════════════════════════════════════════════════
    size = 1,
    weight = 0.15,
    portable = true,
    material = "linen",
    categories = {"medical", "fabric", "small"},

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    -- ═══════════════════════════════════════════════════════════
    -- TREATMENT PROPERTIES
    -- ═══════════════════════════════════════════════════════════
    is_consumable = false,
    consumable_type = "compress",
    reusable = true,
    cures = {"burn"},
    healing_boost = 2,

    -- ═══════════════════════════════════════════════════════════
    -- SENSORY (top-level defaults)
    -- ═══════════════════════════════════════════════════════════
    on_feel = "Cool, damp linen. The water has soaked through evenly — it's pleasantly cold against the skin.",
    on_smell = "Well water and clean linen. A faint mineral tang.",
    on_listen = "A soft drip if you squeeze it. Otherwise silent.",
    on_taste = "Wet linen. Mineral water and fabric fiber. Not appetizing.",
    room_presence = "A damp cloth lies here, darkened with water.",

    -- ═══════════════════════════════════════════════════════════
    -- FSM
    -- ═══════════════════════════════════════════════════════════
    initial_state = "damp",
    _state = "damp",

    states = {
        damp = {
            name = "a damp cloth",
            description = "A square of linen soaked in cold water, wrung out just enough to stop dripping. Cool to the touch.",
            on_feel = "Cool, damp linen. The water has soaked through evenly — pleasantly cold against the skin.",
            on_smell = "Well water and clean linen. A faint mineral tang.",
            on_taste = "Wet linen and mineral water.",
            on_listen = "A soft drip if you squeeze it.",
        },

        applied = {
            name = "an applied damp cloth",
            description = "The damp cloth is pressed against the burn, its cool moisture drawing out the heat. The linen is warming from the injured skin.",
            on_feel = "Warm now — the cloth has absorbed the heat from the burn. Still damp, but less cool.",
            on_smell = "Warm, wet linen and a hint of scorched skin.",
            on_taste = "You shouldn't put that in your mouth while it's on a wound.",
            on_listen = "Silent.",
            in_use = true,
        },

        dry = {
            name = "a dry cloth",
            description = "A square of linen, now dry and stiff from use. It could be re-wetted to serve again.",
            on_feel = "Dry, slightly stiff linen. The water has evaporated.",
            on_smell = "Faint mineral residue. Mostly just dry cloth.",
            on_taste = "Dry fiber and a whisper of mineral salt.",
            on_listen = "A dry rustle when handled.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "damp", to = "applied",
            verb = "apply",
            aliases = {"use", "press", "place"},
            requires_target_injury = true,
            message = "You press the cool, damp cloth against the burn. The relief is immediate — the searing heat drains into the wet linen.",
            effect = {
                type = "heal_injury",
                injury_type = "burn",
                source = "damp-cloth",
                message = "The cool compress draws the heat from the burn. The angry redness begins to fade.",
            },
        },
        {
            from = "applied", to = "dry",
            verb = "remove",
            aliases = {"peel", "take off", "lift"},
            message = "You lift the cloth away. It's warm and nearly dry now, having absorbed the heat from the burn. The skin beneath looks better.",
            mutate = {
                keywords = {add = "dry"},
            },
        },
    },

    prerequisites = {
        apply = {requires_state = "damp", requires_target_injury = true},
    },

    mutations = {},
}
