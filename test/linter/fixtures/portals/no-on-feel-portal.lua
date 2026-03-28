-- no-on-feel-portal.lua — Test fixture: portal without on_feel (triggers EXIT-07)
-- Violates P6 darkness requirement: every object must have on_feel.
-- Used by: test/linter/test_exit_rules.py
return {
    guid = "{00000000-0000-0000-0000-000000000070}",
    template = "portal",

    id = "test-no-on-feel-portal",
    name = "a curtained archway",
    keywords = {"archway", "curtain", "curtained archway"},
    size = 5,
    weight = 10,
    portable = false,
    categories = {"architecture", "portal"},

    portal = {
        target = "test-room-beyond",
        bidirectional_id = "{00000000-0000-0000-0000-000000000071}",
        direction_hint = "east",
    },

    description = "A stone archway draped with a heavy curtain.",
    -- on_feel intentionally omitted (EXIT-07)
    on_smell = "Dust and old fabric.",
    on_listen = "The curtain stirs faintly.",

    initial_state = "curtained",
    _state = "curtained",

    states = {
        curtained = {
            traversable = false,
            name = "a curtained archway",
            description = "A heavy curtain blocks the archway.",
        },
        open = {
            traversable = true,
            name = "an open archway",
            description = "The archway stands open, the curtain pulled aside.",
        },
    },

    transitions = {
        {
            from = "curtained", to = "open", verb = "open",
            aliases = {"pull", "move"},
            message = "You pull the heavy curtain aside, revealing the passage beyond.",
        },
        {
            from = "open", to = "curtained", verb = "close",
            aliases = {"drop"},
            message = "You let the curtain fall back across the archway.",
        },
    },

    on_traverse = {},
    mutations = {},
}
