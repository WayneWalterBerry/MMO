-- silk-rope.lua — Craftable tool from spider silk
-- Crafted from 2x silk-bundle (no tool required)
-- Immediate Level 1 use: tie rope to hook (courtyard well puzzle)
-- Also usable for binding (Phase 5+)
return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{47571952-19a9-4b7b-9b6d-744c842f1bc2}",
    template = "small-item",

    id = "silk-rope",
    name = "a silk rope",
    keywords = {"silk rope", "spider rope"},
    description = "A braided rope of spider silk, surprisingly thin yet strong. The pale strands are twisted tight, with a faint oily sheen that catches the light. About ten feet of it, light as a scarf.",

    -- ═══════════════════════════════════════════════════════════
    -- PHYSICAL PROPERTIES
    -- ═══════════════════════════════════════════════════════════
    material = "silk",
    size = 2,
    weight = 0.4,
    portable = true,
    categories = {"tool", "silk", "crafted"},

    location = nil,

    -- ═══════════════════════════════════════════════════════════
    -- TOOL CAPABILITIES
    -- ═══════════════════════════════════════════════════════════
    provides_tool = {"rope", "binding"},

    -- ═══════════════════════════════════════════════════════════
    -- CRAFTING SOURCE
    -- ═══════════════════════════════════════════════════════════
    crafted_from = {
        ingredients = { { id = "silk-bundle", quantity = 2 } },
        requires_tool = nil,
        narration = "You twist the silk bundles together into a strong, lightweight rope.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- SENSORY (on_feel REQUIRED — primary dark sense)
    -- ═══════════════════════════════════════════════════════════
    on_feel = "Smooth, thin braids of silk, cool and slightly tacky. The rope is surprisingly strong — it flexes without fraying when you pull.",
    on_smell = "Faintly musty. The same cellar-silk smell as the spider's web.",
    on_listen = "Silent. A faint hiss when drawn through your fingers.",
    on_taste = "Tasteless silk. The fibers stick to your tongue.",
    room_presence = "A coil of pale silk rope lies here.",

    mutations = {},
}
