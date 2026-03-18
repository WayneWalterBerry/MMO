return {
    template = "sheet",
    id = "rag",
    name = "a dirty rag",
    keywords = {"rag", "cloth", "wipe", "scrap"},
    description = "A shapeless wad of burlap, good for wiping things down or stuffing into cracks. It has the dignity of a fallen napkin.",

    size = 1,
    weight = 0.1,
    portable = true,
    material = "fabric",

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {"fabric"},

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
