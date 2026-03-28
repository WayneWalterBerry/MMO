-- orphan-bidirectional.lua — Test fixture: bidirectional_id with no matching partner (triggers EXIT-03)
-- Used by: test/linter/test_exit_rules.py
return {
    guid = "{00000000-0000-0000-0000-000000000030}",
    template = "portal",

    id = "test-orphan-bidirectional",
    name = "a one-way passage",
    keywords = {"passage", "one-way passage"},
    size = 6,
    weight = 0,
    portable = false,
    categories = {"architecture", "portal"},

    portal = {
        target = "test-room-west",
        -- This GUID has no matching partner file anywhere (EXIT-03)
        bidirectional_id = "{DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF}",
        direction_hint = "west",
    },

    description = "A narrow passage cut through the rock.",
    on_feel = "Rough-hewn stone walls, barely wide enough to squeeze through.",
    on_smell = "Damp stone and earth.",
    on_listen = "Dripping water from somewhere ahead.",

    initial_state = "open",
    _state = "open",

    states = {
        open = {
            traversable = true,
            name = "a narrow passage",
            description = "A narrow passage leading west.",
            on_feel = "Rough stone walls press close.",
        },
    },

    transitions = {},
    on_traverse = {},
    mutations = {},
}
