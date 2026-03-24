-- rain-barrel.lua — FSM-managed water source (Courtyard)
-- States: full → half-full → empty
return {
    guid = "{ff526b60-83e1-4c82-9d5f-c303bac5bdf3}",
    template = "furniture",

    id = "rain-barrel",
    material = "wood",
    keywords = {"barrel", "rain barrel", "water barrel", "cask", "tub"},
    size = 5,
    weight = 40,
    categories = {"container", "wooden", "furniture"},
    portable = false,
    provides_tool = "water_source",

    name = "a rain barrel",
    description = "A large wooden barrel stands under a downspout, brimming with dark rainwater. Dead leaves float on the surface. The water reflects the stars.",
    room_presence = "A rain barrel stands against the wall under a downspout, dark water brimming at the top.",
    on_feel = "Wooden staves, iron hoops. The water inside is cold -- shockingly cold. Your hand breaks the surface and the chill runs up your arm.",
    on_smell = "Clean rainwater, old wood, a hint of iron from the hoops. Leaf decay.",
    on_listen = "Water sloshes against the sides when you touch the barrel.",

    location = nil,

    surfaces = {
        inside = {
            capacity = 1, max_item_size = 2, weight_capacity = 5,
            contents = {},
            accessible = true,
        },
    },

    initial_state = "full",
    _state = "full",

    states = {
        full = {
            name = "a rain barrel",
            description = "A large wooden barrel stands under a downspout, brimming with dark rainwater. Dead leaves float on the surface. The water reflects the stars.",
            room_presence = "A rain barrel stands against the wall under a downspout, dark water brimming at the top.",
            on_feel = "Wooden staves, iron hoops. The water inside is cold -- shockingly cold. Your hand breaks the surface and the chill runs up your arm.",
            on_smell = "Clean rainwater, old wood, a hint of iron from the hoops. Leaf decay.",
            on_listen = "Water sloshes against the sides when you touch the barrel.",
        },

        ["half-full"] = {
            name = "a half-full rain barrel",
            description = "The rain barrel is about half full. The water level has dropped, revealing a dark ring of algae on the inner staves.",
            on_feel = "Wooden staves. Water lower now -- you have to reach further in. Still cold.",
            on_smell = "Damp wood, stale water, faint algae.",
            on_listen = "A hollow slosh when bumped.",
        },

        empty = {
            name = "an empty rain barrel",
            description = "The rain barrel is empty. The inside is dark and slimy with old algae. Mosquito larvae twitch in a shallow puddle at the bottom.",
            on_feel = "Wooden staves, slimy inside. Damp at the bottom.",
            on_smell = "Stagnant water residue. Rot.",
            on_listen = "A hollow boom when tapped.",
        },
    },

    transitions = {
        {
            from = "full", to = "half-full", verb = "fill",
            aliases = {"scoop", "take water"},
            message = "You dip the container into the barrel. Cold water fills it, and the barrel's level drops noticeably.",
            mutate = {
                weight = function(w) return w - 15 end,
            },
        },
        {
            from = "half-full", to = "empty", verb = "fill",
            aliases = {"scoop", "take water"},
            message = "You scoop the last of the water from the barrel. It gurgles and drains to a shallow puddle at the bottom.",
            mutate = {
                weight = 10,
                keywords = { add = "empty" },
            },
        },
    },

    mutations = {},
}
