-- valid-portal.lua — Test fixture: fully valid portal (no EXIT-* violations)
-- Used by: test/linter/test_exit_rules.py
return {
    guid = "{00000000-0000-0000-0000-000000000001}",
    template = "portal",

    id = "test-valid-portal",
    name = "a test door",
    keywords = {"door", "test door"},
    size = 6,
    weight = 100,
    portable = false,
    categories = {"architecture", "portal"},

    portal = {
        target = "test-room-north",
        bidirectional_id = "{00000000-0000-0000-0000-000000000002}",
        direction_hint = "north",
    },

    description = "A sturdy test door in the north wall.",
    on_feel = "Solid wood under your hand. The door is heavy and well-fitted.",
    on_smell = "Old wood and dust.",
    on_listen = "Silence from beyond.",

    initial_state = "closed",
    _state = "closed",

    states = {
        closed = {
            traversable = false,
            name = "a closed test door",
            description = "A sturdy door, firmly shut.",
            on_feel = "Solid wood. The door does not budge.",
        },
        open = {
            traversable = true,
            name = "an open test door",
            description = "The door stands open.",
            on_feel = "The open door edge, cool air beyond.",
        },
    },

    transitions = {
        {
            from = "closed", to = "open", verb = "open",
            message = "You push the door open.",
        },
        {
            from = "open", to = "closed", verb = "close",
            message = "You pull the door shut.",
        },
    },

    on_traverse = {},
    mutations = {},
}
