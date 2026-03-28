-- missing-target.lua — Test fixture: portal WITHOUT portal.target (triggers EXIT-01)
-- Used by: test/linter/test_exit_rules.py
return {
    guid = "{00000000-0000-0000-0000-000000000010}",
    template = "portal",

    id = "test-missing-target",
    name = "a doorway with no destination",
    keywords = {"doorway", "broken doorway"},
    size = 6,
    weight = 80,
    portable = false,
    categories = {"architecture", "portal"},

    portal = {
        -- target intentionally omitted (EXIT-01)
        bidirectional_id = "{00000000-0000-0000-0000-000000000011}",
        direction_hint = "east",
    },

    description = "A doorway leading nowhere in particular.",
    on_feel = "Rough stone edges frame the doorway.",
    on_smell = "Stale air.",
    on_listen = "Nothing.",

    initial_state = "open",
    _state = "open",

    states = {
        open = {
            traversable = true,
            name = "an open doorway",
            description = "An open doorway.",
            on_feel = "Rough stone edges.",
        },
    },

    transitions = {},
    on_traverse = {},
    mutations = {},
}
