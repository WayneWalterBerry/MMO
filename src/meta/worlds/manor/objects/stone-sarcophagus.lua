-- stone-sarcophagus.lua — Openable container (Deep Cellar version)
-- States: closed → open
return {
    guid = "{3fd2ce07-0c8b-421e-8e56-fa4687c815de}",
    template = "furniture",

    id = "stone-sarcophagus",
    material = "stone",
    keywords = {"sarcophagus", "coffin", "stone coffin", "tomb", "stone box", "casket"},
    size = 6,
    weight = 500,
    categories = {"furniture", "stone", "container"},
    portable = false,

    name = "a stone sarcophagus",
    description = "A stone sarcophagus stands against the north wall, its massive lid carved with the effigy of a robed figure. The face is worn smooth by time -- only the suggestion of features remains. The lid must weigh as much as a man.",
    room_presence = "A stone sarcophagus stands against the north wall, its lid carved with a worn effigy.",
    on_feel = "Cold, rough stone. The lid has a carved figure -- you can trace the outline of robes, folded hands, a smooth featureless face. The seam between lid and base is tight.",
    on_smell = "Old stone and something sealed away -- dust, must, the faintest hint of decay.",
    on_listen = "Silence. Stone holds its secrets.",

    location = nil,

    surfaces = {
        inside = {
            capacity = 4, max_item_size = 3, weight_capacity = 30,
            contents = {},
            accessible = false,
        },
        top = {
            capacity = 2, max_item_size = 2, weight_capacity = 10,
            contents = {},
            accessible = true,
        },
    },

    prerequisites = {
        open = { requires = {"leverage"}, auto_steps = {"take crowbar"} },
    },

    initial_state = "closed",
    _state = "closed",

    states = {
        closed = {
            name = "a stone sarcophagus",
            description = "A stone sarcophagus stands against the north wall, its massive lid carved with the effigy of a robed figure. The face is worn smooth by time -- only the suggestion of features remains. The lid must weigh as much as a man.",
            room_presence = "A stone sarcophagus stands against the north wall, its lid carved with a worn effigy.",
            on_feel = "Cold, rough stone. The lid has a carved figure -- you can trace the outline of robes, folded hands, a smooth featureless face. The seam between lid and base is tight.",
            on_smell = "Old stone and something sealed away -- dust, must, the faintest hint of decay.",
            on_listen = "Silence. Stone holds its secrets.",
        },

        open = {
            name = "an open sarcophagus",
            description = "The sarcophagus lid has been pushed aside, revealing the interior. Inside, old bones rest on a bed of rotted fabric. The skull stares upward with empty sockets. Fragments of burial goods surround the remains.",
            room_presence = "An open sarcophagus reveals old bones and the glint of burial goods.",
            on_feel = "The lid is askew. Inside: dry bones, crumbling fabric, smooth objects among the remains. The interior stone is rougher than the exterior.",
            on_smell = "Dust and old death. Not unpleasant -- too old for that. Dry and mineral.",
        },
    },

    transitions = {
        {
            from = "closed", to = "open", verb = "push",
            aliases = {"open", "lift", "slide"},
            requires_tool = "leverage",
            message = "You brace yourself against the lid and push. The stone grinds against stone with a sound like a groan. Inch by inch, the lid slides aside, revealing the dark interior. Dust billows upward. Inside: old bones, rotted fabric, and the glint of metal.",
            fail_message = "The lid is impossibly heavy. You can't budge it with bare hands. You'd need a lever -- or something to pry with.",
            mutate = {
                keywords = { add = "open" },
            },
        },
    },

    mutations = {},
}
