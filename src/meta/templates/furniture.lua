-- template: furniture
-- Base template for heavy non-portable objects (desks, beds, wardrobes, etc.)
-- Instances inherit these defaults and override as needed.

return {
    id = "furniture",
    name = "a piece of furniture",
    keywords = {},
    description = "A heavy piece of furniture.",

    size = 5,
    weight = 30,
    portable = false,
    material = "wood",

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {"furniture", "wooden"},

    mutations = {},
}
