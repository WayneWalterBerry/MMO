-- cobblestone.lua — Static tool/weapon object (Courtyard)
return {
    guid = "{4388e944-50e3-4382-9068-646421c0741f}",
    template = "small-item",

    id = "cobblestone",
    material = "stone",
    keywords = {"cobblestone", "stone", "rock", "paving stone", "cobble", "loose stone"},
    size = 2,
    weight = 2,
    categories = {"tool", "stone", "weapon"},
    portable = true,

    name = "a loose cobblestone",
    description = "A cobblestone has worked loose from the courtyard floor, leaving a dark gap in the paving. It's roughly the size of your fist -- rounded on top, flat on the bottom, worn smooth by feet and weather. Heavy for its size.",
    room_presence = "One cobblestone near the well has worked loose, leaving a dark gap.",
    on_feel = "Smooth on top from centuries of foot traffic. Rough and flat on the bottom. Heavy, dense stone -- it fills your palm solidly. Cool and slightly damp.",
    on_smell = "Wet stone and earth.",

    location = nil,

    provides_tool = {"blunt_weapon", "weight", "hammer"},

    combat = {
        type = "blunt",
        force = 3,
        message = "bashes",
        two_handed = false,
    },

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
