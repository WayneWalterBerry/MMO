-- template: container
-- Base template for generic containers (bags, boxes, chests, etc.)
-- Instances inherit these defaults and override as needed.

return {
    guid = "f1596a51-4e1f-4f9a-a6d0-93b279066910",
    id = "container",
    name = "a container",
    keywords = {},
    description = "A basic container.",

    size = 2,
    weight = 0.5,
    portable = true,
    material = "wood",

    container = true,
    capacity = 4,
    weight_capacity = 10,
    contents = {},
    location = nil,

    categories = {"container"},

    mutations = {},
}
