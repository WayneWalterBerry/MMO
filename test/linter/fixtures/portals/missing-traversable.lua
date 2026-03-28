-- missing-traversable.lua — Test fixture: FSM states lack traversable field (triggers EXIT-02)
-- Used by: test/linter/test_exit_rules.py
return {
    guid = "{00000000-0000-0000-0000-000000000020}",
    template = "portal",

    id = "test-missing-traversable",
    name = "a rusty gate",
    keywords = {"gate", "rusty gate"},
    size = 5,
    weight = 90,
    portable = false,
    categories = {"architecture", "portal"},

    portal = {
        target = "test-room-south",
        bidirectional_id = "{00000000-0000-0000-0000-000000000021}",
        direction_hint = "south",
    },

    description = "A rusty iron gate blocks the passage south.",
    on_feel = "Flaking rust and cold iron bars.",
    on_smell = "Rust and damp.",
    on_listen = "The gate creaks faintly in a draught.",

    initial_state = "closed",
    _state = "closed",

    states = {
        closed = {
            -- traversable intentionally omitted (EXIT-02)
            name = "a closed rusty gate",
            description = "A rusty gate, firmly shut.",
            on_feel = "Cold iron, flaking rust.",
        },
        open = {
            -- traversable intentionally omitted (EXIT-02)
            name = "an open rusty gate",
            description = "The rusty gate stands open.",
            on_feel = "Rust flakes off under your fingers.",
        },
    },

    transitions = {
        {
            from = "closed", to = "open", verb = "open",
            message = "The gate screeches open on rusted hinges.",
        },
        {
            from = "open", to = "closed", verb = "close",
            message = "You force the gate shut.",
        },
    },

    on_traverse = {},
    mutations = {},
}
