return {
    template = "small-item",
    id = "glass-shard",
    name = "a glass shard",
    keywords = {"shard", "glass", "glass shard", "sliver", "fragment"},
    description = "A long, wicked sliver of mirror glass. One side still holds a ghost of a reflection — a fragment of a face, perhaps yours. The edge is razor-sharp.",

    size = 1,
    weight = 0.1,
    portable = true,
    material = "glass",

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {"sharp", "fragile", "reflective"},

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
