-- territory-marker.lua — Invisible scent marker placed by wolves
-- Created at runtime by territorial creatures via creates_object behavior
-- Not findable by look/search — detectable via SMELL only (Q5 resolution)
return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{60189a1c-892c-478f-be8a-086fe8128cbb}",
    template = "small-item",

    id = "territory-marker",
    name = "a territorial scent",
    keywords = {"scent", "musk", "animal scent", "territorial scent"},
    description = "You can't see anything — but something was here.",

    -- ═══════════════════════════════════════════════════════════
    -- PHYSICAL PROPERTIES
    -- ═══════════════════════════════════════════════════════════
    material = nil,
    size = 0,
    weight = 0,
    portable = false,
    categories = {"invisible", "scent", "creature-made"},

    location = nil,

    -- ═══════════════════════════════════════════════════════════
    -- VISIBILITY
    -- ═══════════════════════════════════════════════════════════
    hidden = true,
    invisible = true,
    searchable = false,
    room_presence = nil,

    -- ═══════════════════════════════════════════════════════════
    -- SENSORY (on_feel REQUIRED — primary dark sense)
    -- ═══════════════════════════════════════════════════════════
    on_feel = "You can't feel anything unusual.",
    on_smell = "A musky, animal scent lingers here.",
    on_listen = "Silence.",
    on_taste = "Nothing to taste — just stale air.",

    -- ═══════════════════════════════════════════════════════════
    -- TERRITORIAL TRACKING
    -- ═══════════════════════════════════════════════════════════
    owner = nil,
    timestamp = nil,
    radius = 2,

    -- Structured subtable for engine/creatures/territorial.lua BFS queries
    territory = {
        owner = nil,
        radius = 2,
        timestamp = nil,
    },

    -- Creator tracking (set at runtime by create_object action)
    creator = nil,

    mutations = {},
}
