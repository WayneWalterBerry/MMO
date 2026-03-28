-- silk-bandage.lua — Craftable single-use healing item from spider silk
-- Crafted from 1x silk-bundle → yields 2 bandages
-- Dual-purpose: instant +5 HP AND stops active bleeding
-- Single-use (consumed on application)
-- FSM: unused → used (terminal, removed from inventory)
return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{7ffb6862-4cb1-4312-bfc0-ddd444abbd40}",
    template = "small-item",

    id = "silk-bandage",
    name = "a silk bandage",
    keywords = {"silk bandage", "silk dressing"},
    description = "A strip of spider silk, torn and folded into a makeshift bandage. The material is thin but dense — remarkably absorbent. It clings to itself without a knot.",

    -- ═══════════════════════════════════════════════════════════
    -- PHYSICAL PROPERTIES
    -- ═══════════════════════════════════════════════════════════
    material = "silk",
    size = 1,
    weight = 0.05,
    portable = true,
    categories = {"medical", "silk", "consumable", "crafted", "small"},

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    -- ═══════════════════════════════════════════════════════════
    -- TREATMENT PROPERTIES
    -- ═══════════════════════════════════════════════════════════
    is_consumable = true,
    consumable_type = "bandage",
    reusable = false,
    cures = {"bleeding"},
    healing_boost = 5,

    -- ═══════════════════════════════════════════════════════════
    -- CRAFTING SOURCE
    -- ═══════════════════════════════════════════════════════════
    crafted_from = {
        ingredients = { { id = "silk-bundle", quantity = 1 } },
        requires_tool = nil,
        result_quantity = 2,
        narration = "You tear the silk into strips suitable for bandaging wounds.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- SENSORY (on_feel REQUIRED — primary dark sense)
    -- ═══════════════════════════════════════════════════════════
    on_feel = "Thin, smooth silk that clings to your skin. It sticks to itself and to wound edges without a knot. Cool and slightly tacky.",
    on_smell = "Clean silk. A trace of cellar dust.",
    on_listen = "Silent.",
    on_taste = "Tasteless silk fibers. Faintly sticky on the tongue.",
    room_presence = "A folded strip of silk lies here, pale and thin.",

    -- ═══════════════════════════════════════════════════════════
    -- FSM
    -- ═══════════════════════════════════════════════════════════
    initial_state = "unused",
    _state = "unused",

    states = {
        unused = {
            name = "a silk bandage",
            description = "A strip of spider silk, folded neatly and ready for use. The material clings to itself, holding its shape without a knot.",
            on_feel = "Thin, smooth silk that clings to your skin. Cool and slightly tacky.",
            on_smell = "Clean silk. A trace of cellar dust.",
            on_listen = "Silent.",
            on_taste = "Tasteless silk fibers.",
        },

        used = {
            name = "a used silk bandage",
            description = "A blood-soaked strip of spider silk, its healing properties spent. The silk has bonded with the dried blood into a stiff, useless strip.",
            on_feel = "Stiff silk crusted with dried blood. No longer adhesive.",
            on_smell = "Old blood and spent silk.",
            on_listen = "A dry crackle when flexed.",
            on_taste = "Dried blood. Foul.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "unused", to = "used",
            verb = "apply",
            aliases = {"use", "wrap", "bind", "bandage"},
            requires_target_injury = true,
            message = "You press the silk bandage against the wound. It clings immediately, sealing the edges. Warmth spreads through the injury as the bleeding slows, then stops.",
            effect = {
                type = "heal",
                amount = 5,
                stops_bleeding = true,
                message = "The silk bandage stanches the bleeding. You feel a little stronger.",
            },
            mutate = {
                is_consumable = true,
                consumed = true,
            },
        },
    },

    prerequisites = {
        apply = { requires_state = "unused", requires_target_injury = true },
    },

    mutations = {},
}
