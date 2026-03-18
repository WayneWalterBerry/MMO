return {
    template = "sheet",
    id = "terrible-jacket",
    name = "a terrible burlap jacket",
    keywords = {"jacket", "coat", "burlap jacket", "terrible jacket", "garment"},
    description = "Three pieces of burlap sewn together with more optimism than skill. The seams are crooked, one arm is longer than the other, and it smells like a root cellar. But it is, technically, a jacket.",

    size = 2,
    weight = 0.5,
    portable = true,
    material = "fabric",

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {"fabric", "wearable"},

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
