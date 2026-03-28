-- mismatched-direction.lua — Test fixture: direction_hint disagrees with room exit key (triggers EXIT-04)
-- The portal says direction_hint = "north", but the room exit using it is keyed as "south".
-- Used by: test/linter/test_exit_rules.py
return {
    guid = "{00000000-0000-0000-0000-000000000040}",
    template = "portal",

    id = "test-mismatched-direction",
    name = "a warped wooden door",
    keywords = {"door", "warped door", "wooden door"},
    size = 6,
    weight = 70,
    portable = false,
    categories = {"architecture", "wooden", "portal"},

    portal = {
        target = "test-room-elsewhere",
        bidirectional_id = "{00000000-0000-0000-0000-000000000041}",
        -- Says "north" but the room exit referencing this portal uses key "south" (EXIT-04)
        direction_hint = "north",
    },

    description = "A warped wooden door that doesn't quite fit its frame.",
    on_feel = "Splintery wood, swollen with damp. The door is warped in its frame.",
    on_smell = "Mildew and wet wood.",
    on_listen = "Air whistles through the gaps where the door doesn't meet the frame.",

    initial_state = "closed",
    _state = "closed",

    states = {
        closed = {
            traversable = false,
            name = "a warped door",
            description = "A warped wooden door, jammed in its frame.",
            on_feel = "Damp, splintery wood. Jammed shut.",
        },
        open = {
            traversable = true,
            name = "an open warped door",
            description = "The warped door hangs open at an angle.",
            on_feel = "The door leans awkwardly on bent hinges.",
        },
    },

    transitions = {
        {
            from = "closed", to = "open", verb = "open",
            message = "You wrench the warped door open with a splintering crack.",
        },
        {
            from = "open", to = "closed", verb = "close",
            message = "You shove the door back into its frame. It sticks.",
        },
    },

    on_traverse = {},
    mutations = {},
}
