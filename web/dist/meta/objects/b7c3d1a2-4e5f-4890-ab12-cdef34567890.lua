-- large-crate.lua — FSM-managed container (Puzzle 009: Crate Puzzle)
-- States: sealed → pried-open → broken (terminal)
return {
    guid = "b7c3d1a2-4e5f-4890-ab12-cdef34567890",
    template = "furniture",

    id = "large-crate",
    material = "wood",
    keywords = {"crate", "large crate", "wooden crate", "box", "shipping crate"},
    size = 5,
    weight = 25,
    categories = {"container", "wooden", "furniture", "breakable"},
    portable = false,

    name = "a large wooden crate",
    description = "A large wooden crate, roughly four feet on a side. The lid is nailed shut with iron nails, rusted but firm. Stenciled letters on one side read \"PROVISIONS\" in faded ink. Dust lies thick on the top.",
    room_presence = "A large wooden crate sits against the east wall, its lid nailed firmly shut.",
    on_feel = "Heavy wooden planks, rough-sawn. Iron nail-heads along the seams, prickly with rust. The lid doesn't budge when you push -- nailed fast.",
    on_smell = "Old wood and dust. Faintly sour, like grain gone stale.",
    on_listen = "Silent. Something shifts faintly inside when you thump it.",

    location = nil,

    surfaces = {
        top = {
            capacity = 3, max_item_size = 3, weight_capacity = 15,
            contents = {},
            accessible = true,
        },
        inside = {
            capacity = 6, max_item_size = 4, weight_capacity = 30,
            contents = {"grain-sack-1"},
            accessible = false,
        },
    },

    prerequisites = {
        open = { requires = {"prying_tool"}, auto_steps = {"take crowbar"} },
    },

    initial_state = "sealed",
    _state = "sealed",

    states = {
        sealed = {
            name = "a large wooden crate",
            description = "A large wooden crate, roughly four feet on a side. The lid is nailed shut with iron nails, rusted but firm. Stenciled letters on one side read \"PROVISIONS\" in faded ink. Dust lies thick on the top.",
            room_presence = "A large wooden crate sits against the east wall, its lid nailed firmly shut.",
            on_feel = "Heavy wooden planks, rough-sawn. Iron nail-heads along the seams, prickly with rust. The lid doesn't budge when you push -- nailed fast.",
            on_smell = "Old wood and dust. Faintly sour, like grain gone stale.",
            on_listen = "Silent. Something shifts faintly inside when you thump it.",
            surfaces = {
                top = {
                    capacity = 3, max_item_size = 3, weight_capacity = 15,
                    contents = {},
                    accessible = true,
                },
                inside = {
                    capacity = 6, max_item_size = 4, weight_capacity = 30,
                    contents = {},
                    accessible = false,
                },
            },
        },

        ["pried-open"] = {
            name = "a pried-open crate",
            description = "The crate's lid has been wrenched off, splintered around the nail holes. Inside, a heavy sack of grain slumps against the walls, half-buried in straw packing and wood shavings.",
            room_presence = "A pried-open crate sits against the east wall, its lid torn free.",
            on_feel = "Splintered wood edges around the opening. Inside: coarse fabric of a sack, loose straw, wood shavings.",
            on_smell = "Stale grain, sawdust, and the musty smell of long storage.",
            on_listen = "Faint rustling from the straw.",
            surfaces = {
                top = {
                    capacity = 3, max_item_size = 3, weight_capacity = 15,
                    contents = {},
                    accessible = true,
                },
                inside = {
                    capacity = 6, max_item_size = 4, weight_capacity = 30,
                    contents = {},
                    accessible = true,
                },
            },
        },

        broken = {
            name = "a broken crate",
            description = "The crate has been smashed apart. Splintered planks and bent nails litter the floor around a burst grain sack.",
            room_presence = "Splintered remains of a crate litter the floor by the east wall.",
            on_feel = "Splinters and broken planks. Sharp nail-ends -- careful.",
            on_smell = "Grain dust, sawdust, damp wood.",
            on_listen = "Nothing.",
            terminal = true,
            surfaces = {
                top = {
                    capacity = 3, max_item_size = 3, weight_capacity = 15,
                    contents = {},
                    accessible = true,
                },
                inside = {
                    capacity = 6, max_item_size = 4, weight_capacity = 30,
                    contents = {},
                    accessible = true,
                },
            },
        },
    },

    transitions = {
        {
            from = "sealed", to = "pried-open", verb = "pry",
            aliases = {"open"},
            requires_tool = "prying_tool",
            message = "You jam the crowbar under the lid and heave. Nails shriek as they pull free, and the lid comes away in a shower of splinters and rust. Inside: a heavy sack nestled in straw packing.",
            fail_message = "The lid is nailed shut. You'd need something to pry it open.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "pried-open", to = "broken", verb = "break",
            aliases = {"smash"},
            requires_tool = "prying_tool",
            message = "You bring the crowbar down hard. The crate shatters into splintered planks and bent nails. The contents spill across the floor.",
            mutate = {
                weight = 5,
                keywords = { add = "broken" },
                categories = { remove = "container" },
            },
        },
    },

    mutations = {},
}
