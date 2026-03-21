return {
    guid = "ef5c4c6d-5ce4-4f49-9cf6-48d5394e7ad5",
    template = "sheet",
    id = "terrible-jacket",
    name = "a terrible burlap jacket",
    keywords = {"jacket", "coat", "burlap jacket", "terrible jacket", "garment"},
    description = "Three pieces of burlap sewn together with more optimism than skill. The seams are crooked, one arm is longer than the other, and it smells like a root cellar. But it is, technically, a jacket.",

    on_feel = "Rough burlap, poorly sewn. The seams are crooked and scratch against your skin. One arm is noticeably longer than the other.",
    on_smell = "Stale. Root cellar and old burlap. Wearing this is a commitment.",

    size = 2,
    weight = 0.5,
    portable = true,
    material = "fabric",

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {"fabric", "wearable"},

    wear = {
        slot = "torso",
        layer = "outer",
        wear_quality = "makeshift",
    },

    on_look = function(self)
        return self.description
    end,

    mutations = {
        tear = {
            becomes = nil,
            spawns = {"cloth", "cloth", "cloth"},
        },
    },
}
