-- template: small-item
-- Base template for tiny portable items (shards, coins, keys, pebbles, etc.)
-- Instances inherit these defaults and override as needed.

return {
    id = "small-item",
    name = "a small item",
    keywords = {},
    description = "A small item.",

    size = 1,
    weight = 0.1,
    portable = true,
    material = "generic",

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {},

    mutations = {},
}
