-- wall-sconce.lua — Container for light sources (Deep Cellar)
-- States: empty ↔ occupied
return {
    guid = "{fd0fb6ed-a643-4b1a-96fd-ad1d520e4f75}",
    template = "furniture",

    id = "wall-sconce",
    material = "iron",
    keywords = {"sconce", "wall sconce", "torch holder", "bracket", "iron bracket", "light fixture"},
    size = 2,
    weight = 2,
    categories = {"furniture", "metal"},
    portable = false,

    name = "an iron wall sconce",
    description = "An iron wall sconce, a simple cup-and-arm bracket bolted into the stone. Empty -- whatever torch or candle it held has long since burned away. Soot stains the stone above it in a dark tongue.",
    room_presence = "Iron sconces line the walls, all dark and empty.",
    on_feel = "Cold iron bracket jutting from the wall. A cup shape at the top -- empty. Soot crumbles under your fingers on the stone above.",
    on_smell = "Old soot and cold iron.",

    location = nil,

    surfaces = {
        inside = {
            capacity = 1, max_item_size = 2, weight_capacity = 3,
            contents = {},
            accessible = true,
            accepts = {"light source"},
        },
    },

    initial_state = "empty",
    _state = "empty",

    states = {
        empty = {
            name = "an iron wall sconce",
            description = "An iron wall sconce, a simple cup-and-arm bracket bolted into the stone. Empty -- whatever torch or candle it held has long since burned away. Soot stains the stone above it in a dark tongue.",
            room_presence = "Iron sconces line the walls, all dark and empty.",
            on_feel = "Cold iron bracket jutting from the wall. A cup shape at the top -- empty. Soot crumbles under your fingers on the stone above.",
            on_smell = "Old soot and cold iron.",
        },

        occupied = {
            name = "an occupied wall sconce",
            description = "An iron wall sconce holding a light source. The flame casts dancing shadows across the vaulted ceiling and illuminates the carved symbols on the walls.",
            room_presence = "A light source burns in a wall sconce, casting flickering light across the carved stone.",
            on_feel = "Warm iron bracket. The light source above radiates heat.",
            on_smell = "Burning wax and warm iron.",
        },
    },

    transitions = {
        {
            from = "empty", to = "occupied", verb = "put",
            aliases = {"place", "insert"},
            message = "You set the light source into the iron cup. The flame steadies, and light fills the alcove.",
        },
        {
            from = "occupied", to = "empty", verb = "take",
            aliases = {"remove"},
            message = "You lift the light source from the sconce.",
        },
    },

    mutations = {},
}
