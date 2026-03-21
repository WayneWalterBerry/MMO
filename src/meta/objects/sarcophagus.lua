-- sarcophagus.lua — FSM-managed container (Crypt, base for 5 instances)
-- States: closed → open
return {
    guid = "80grw50d-1b28-4531-7e4e-908c61456789",
    template = "furniture",

    id = "sarcophagus",
    material = "stone",
    keywords = {"sarcophagus", "coffin", "stone coffin", "tomb", "casket", "stone box"},
    size = 6,
    weight = 500,
    categories = {"furniture", "stone", "container"},
    portable = false,

    name = "a stone sarcophagus",
    description = "A stone sarcophagus, its massive lid carved with the effigy of a robed figure. The hands are crossed over the chest. The face is serene but worn -- features smoothed by time. Carved text runs along the base.",
    room_presence = "Five stone sarcophagi line the walls, their carved effigies staring upward in eternal repose.",
    on_feel = "Cold stone. The effigy's features are faint under your fingers -- robes, folded hands, a face worn nearly smooth. The seam between lid and base is sealed tight. You can trace carved letters along the base.",
    on_smell = "Sealed stone. Dust. The faintest suggestion of something old and dry beyond.",
    on_listen = "Stone holds silence like a prayer.",

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
            description = "A stone sarcophagus, its massive lid carved with the effigy of a robed figure. The hands are crossed over the chest. The face is serene but worn -- features smoothed by time. Carved text runs along the base.",
            room_presence = "Five stone sarcophagi line the walls, their carved effigies staring upward in eternal repose.",
            on_feel = "Cold stone. The effigy's features are faint under your fingers -- robes, folded hands, a face worn nearly smooth. The seam between lid and base is sealed tight. You can trace carved letters along the base.",
            on_smell = "Sealed stone. Dust. The faintest suggestion of something old and dry beyond.",
            on_listen = "Stone holds silence like a prayer.",
        },

        open = {
            name = "an open sarcophagus",
            description = "The sarcophagus lid has been pushed aside with great effort. Inside, old bones rest on a bed of rotted silk. The air that escapes is dry and impossibly old.",
            room_presence = "An open sarcophagus reveals old bones and the glint of burial goods.",
            on_feel = "The lid is askew. Inside: dry bones, crumbling fabric. The interior stone is rougher than the exterior.",
            on_smell = "Dry death. Not rot -- too old for that. Dust and mineral decay. Old fabric. And beneath it, a faint sweetness -- embalming herbs, still detectable after centuries.",
            on_listen = "A soft sigh of ancient air when opened. Then silence.",
        },
    },

    transitions = {
        {
            from = "closed", to = "open", verb = "push",
            aliases = {"open", "lift", "slide"},
            requires_tool = "leverage",
            message = "You brace against the lid and push. Stone grinds against stone -- a sound like the earth itself groaning. The lid shifts, slides, and comes to rest half-off. Ancient air exhales from the gap, carrying the scent of centuries.",
            fail_message = "The lid must weigh hundreds of pounds. You strain against it until your arms tremble, but it won't budge. You need a lever.",
            mutate = {
                keywords = { add = "open" },
            },
        },
    },

    mutations = {},
}
