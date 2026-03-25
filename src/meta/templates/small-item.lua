-- template: small-item
-- Base template for tiny portable items (shards, coins, keys, pebbles, etc.)
-- Instances inherit these defaults and override as needed.

return {
    guid = "c2960f69-67a2-42e4-bcdc-dbc0254de113",
    id = "small-item",
    name = "a small item",
    keywords = {},
    description = "A small item.",

    size = 1,
    weight = 0.1,
    portable = true,
    material = "iron",

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {},

    mutations = {},
}
