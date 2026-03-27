-- template: portal
-- Base template for traversable passage objects (doors, windows, gates, trapdoors, etc.)
-- Portal objects are first-class objects that replace inline exit tables.
-- Instances inherit these defaults and override as needed.
-- Decision: D-PORTAL-ARCHITECTURE (D2 — template name: portal)

return {
    guid = "d902e90d-ec66-45df-8b93-a8dd35a6aaca",
    id = "portal",
    name = "a passage",
    keywords = {},
    description = "A passage between rooms.",

    size = 5,
    weight = 100,
    portable = false,
    not_portable_reason = "You can't carry that.",
    material = "wood",

    -- Portal-specific metadata (engine-executed per Principle 8)
    portal = {
        target = nil,              -- destination room ID (required per instance)
        bidirectional_id = nil,    -- shared ID linking paired portal objects
        direction_hint = nil,      -- "north", "south", etc. for movement resolution
    },

    -- Passage constraints
    max_carry_size = nil,          -- nil = no limit
    max_carry_weight = nil,

    -- FSM defaults — simple open passage
    initial_state = "open",
    _state = "open",
    states = {
        open = {
            traversable = true,
            description = "An open passage.",
        },
    },
    transitions = {},

    -- Sensory defaults (on_feel required per Principle 6)
    on_feel = "A passage.",
    on_smell = nil,
    on_listen = nil,

    -- Standard object fields
    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {"portal"},

    mutations = {},
}
