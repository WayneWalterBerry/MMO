-- healing-poultice.lua — Herbal poultice for treating serious wounds
-- States: sealed → applied → spent (terminal)
-- Stronger than a bandage: treats bleeding, crushing wounds, and minor cuts.
-- Works on infected/critical wounds where a bandage alone is insufficient.
return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{fcd722b7-27d2-42cb-baf5-86e66cf2fc07}",
    template = "small-item",
    id = "healing-poultice",
    name = "a herbal poultice",
    keywords = {"poultice", "herbal poultice", "healing poultice", "herb pack", "compress"},
    description = "A folded linen packet stuffed with crushed comfrey, yarrow, and calendula bound with beeswax. The herbs are still moist -- recently prepared. An apothecary's knot holds it shut.",

    -- ═══════════════════════════════════════════════════════════
    -- PHYSICAL PROPERTIES
    -- ═══════════════════════════════════════════════════════════
    size = 1,
    weight = 0.2,
    portable = true,
    material = "linen",
    categories = {"medical", "fabric", "consumable", "small"},

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    -- ═══════════════════════════════════════════════════════════
    -- TREATMENT PROPERTIES
    -- ═══════════════════════════════════════════════════════════
    is_consumable = true,
    consumable_type = "poultice",
    reusable = false,
    cures = {"bleeding", "crushing-wound", "minor-cut"},
    healing_boost = 4,

    -- ═══════════════════════════════════════════════════════════
    -- SENSORY (top-level defaults)
    -- ═══════════════════════════════════════════════════════════
    on_feel = "A soft linen packet, damp with herb juices. The contents shift like wet sand when squeezed.",
    on_smell = "Strong herbal scent -- yarrow, comfrey, and something sharply green. Medicinal.",
    on_listen = "A faint squelch when pressed. The herbs are moist.",
    on_taste = "Bitter herbs and beeswax through the linen. Not meant to be eaten.",
    room_presence = "A folded linen packet lies here, dark with herb stains.",

    -- ═══════════════════════════════════════════════════════════
    -- FSM
    -- ═══════════════════════════════════════════════════════════
    initial_state = "sealed",
    _state = "sealed",

    states = {
        sealed = {
            name = "a herbal poultice",
            description = "A folded linen packet stuffed with crushed herbs, sealed with an apothecary's knot. The cloth is damp with green-brown juices.",
            on_feel = "A soft linen packet, damp with herb juices. The contents shift like wet sand when squeezed.",
            on_smell = "Strong herbal scent -- yarrow, comfrey, and something sharply green. Medicinal.",
            on_taste = "Bitter herbs and beeswax through the linen.",
            on_listen = "A faint squelch when pressed.",
        },

        applied = {
            name = "an applied poultice",
            description = "The poultice is pressed against the wound, its herb paste drawing out infection. The linen is darkening with blood and fluid.",
            on_feel = "Warm, damp linen pressed tight against injured flesh. The herbs tingle against the wound.",
            on_smell = "Crushed herbs and blood. The medicinal scent is overpowering the copper.",
            on_taste = "You shouldn't put that in your mouth while it's on a wound.",
            on_listen = "Silent.",
            in_use = true,
        },

        spent = {
            name = "a spent poultice",
            description = "A used poultice, its herbs exhausted. The linen is stained dark with blood and dried herb paste. No healing left in it.",
            on_feel = "Stiff, crusted cloth. The herbs have dried to a brittle crust.",
            on_smell = "Stale herbs and old blood. The medicine is spent.",
            on_taste = "Dried herbs and grime. Useless.",
            on_listen = "A dry crackle when flexed.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "sealed", to = "applied",
            verb = "apply",
            aliases = {"use", "press", "place"},
            requires_target_injury = true,
            message = "You break the apothecary's knot and press the poultice against the wound. The crushed herbs spread across the injury, drawing a sharp sting, then a spreading coolness.",
            mutate = {
                keywords = {add = "applied"},
            },
        },
        {
            from = "applied", to = "spent",
            verb = "remove",
            aliases = {"peel", "take off", "unwrap"},
            message = "You peel the spent poultice away. The herbs have done their work -- the wound beneath looks markedly better.",
            mutate = {
                keywords = {add = "spent"},
            },
        },
    },

    prerequisites = {
        apply = {requires_state = "sealed", requires_target_injury = true},
    },

    mutations = {},
}
