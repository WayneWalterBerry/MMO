return {
    template = "small-item",
    id = "glass-shard",
    name = "a glass shard",
    keywords = {"shard", "glass", "glass shard", "sliver", "fragment"},
    description = "A long, wicked sliver of mirror glass. One side still holds a ghost of a reflection — a fragment of a face, perhaps yours. The edge is razor-sharp.",

    on_feel = "SHARP! The edge bites into your finger before you realize what you're holding. Smooth glass on the flat side, razor-keen at the edge.",
    on_feel_effect = "cut",
    on_taste = "DO NOT. Seriously. Glass and blood is not a flavor profile anyone should explore.",

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
