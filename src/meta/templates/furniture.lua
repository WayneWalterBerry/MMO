-- template: furniture
-- Base template for heavy non-portable objects (desks, beds, wardrobes, etc.)
-- Instances inherit these defaults and override as needed.

return {
    guid = "45a12525-ae7c-4ff1-ba22-4719e9144621",
    id = "furniture",
    name = "a piece of furniture",
    keywords = {},
    description = "A heavy piece of furniture.",

    size = 5,
    weight = 30,
    portable = false,
    not_portable_reason = "It's far too heavy to carry.",
    material = "wood",

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {"furniture", "wooden"},

    mutations = {},
}
