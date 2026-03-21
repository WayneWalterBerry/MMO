-- rat.lua — Atmospheric ambient creature
-- States: hidden → visible → fleeing → gone (terminal)
return {
    guid = "4067cl0j-d7e8-4189-340a-5687cd456789",
    template = "furniture",

    id = "rat",
    keywords = {"rat", "rodent", "mouse", "vermin", "creature"},
    size = 1,
    weight = 0.3,
    categories = {"creature", "small", "ambient"},
    portable = false,

    name = "a brown rat",
    on_feel = "Something small and warm darts away from your fingers.",
    on_smell = "A rank, musky animal smell. Something lives here.",
    on_listen = "Scratching in the walls. Small claws on stone. Something is moving behind the shelves.",

    location = nil,

    initial_state = "hidden",
    _state = "hidden",

    states = {
        hidden = {
            name = "a brown rat",
            on_feel = "Something small and warm darts away from your fingers.",
            on_smell = "A rank, musky animal smell. Something lives here.",
            on_listen = "Scratching in the walls. Small claws on stone. Something is moving behind the shelves.",
        },

        visible = {
            name = "a brown rat",
            description = "A large brown rat perches on a broken shelf, watching you with bright black eyes. Its whiskers twitch. It's not afraid -- not yet.",
            room_presence = "A brown rat watches you from a broken shelf.",
            on_feel = "Coarse, greasy fur brushes past your hand. The rat squeaks and twitches away.",
            on_smell = "Rank musk. Close.",
            on_listen = "A low chittering. Claws clicking on wood.",
        },

        fleeing = {
            name = "a brown rat",
            description = "The rat bolts -- a brown blur along the baseboard, vanishing behind a crate.",
            on_listen = "Frantic scrabbling, then silence.",
        },

        gone = {
            name = "a brown rat",
            on_smell = "Fading musk. The rat smell lingers.",
            on_listen = "Silence. The scratching has stopped.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "hidden", to = "visible", trigger = "auto",
            condition = "player_enters",
            message = "Something moves on the shelf -- a large brown rat sits up on its haunches, watching you with bead-black eyes.",
        },
        {
            from = "visible", to = "fleeing", trigger = "auto",
            condition = "loud_action_nearby",
            message = "The rat bolts. It's a brown streak along the baseboard, gone behind the crates in an instant.",
        },
        {
            from = "visible", to = "gone", trigger = "auto",
            condition = "timer_expired",
            message = "The rat loses interest and slips away between the stones. The scratching fades.",
        },
        {
            from = "fleeing", to = "gone", trigger = "auto",
            message = "",
        },
    },

    mutations = {},
}
