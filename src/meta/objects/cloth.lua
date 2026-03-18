return {
    template = "sheet",
    id = "cloth",
    name = "a piece of cloth",
    keywords = {"cloth", "fabric", "burlap", "scrap", "material"},
    description = "A rough square of burlap cloth, torn from a sack. The edges are frayed and uneven, but the weave is sturdy enough to be useful.",

    size = 1,
    weight = 0.2,
    portable = true,
    material = "fabric",

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {"fabric", "craftable"},

    on_look = function(self)
        return self.description
    end,

    mutations = {
        make_bandage = {
            becomes = "bandage",
        },
        make_rag = {
            becomes = "rag",
        },
    },

    crafting = {
        sew = {
            consumes = {"cloth", "cloth"},
            becomes = "terrible-jacket",
        },
    },
}
