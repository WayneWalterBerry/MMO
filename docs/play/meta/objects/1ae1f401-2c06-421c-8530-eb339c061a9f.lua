-- vase.lua — Breakable decorative object (Hallway)
-- States: intact → broken (terminal)
return {
    guid = "{1ae1f401-2c06-421c-8530-eb339c061a9f}",
    template = "small-item",

    id = "vase",
    material = "ceramic",
    keywords = {"vase", "ceramic vase", "pot", "flower vase", "urn"},
    size = 2,
    weight = 2,
    categories = {"decorative", "fragile", "ceramic", "container"},
    portable = true,

    name = "a ceramic vase",
    description = "A tall ceramic vase, glazed deep blue with gold bands around the neck. Dry flowers -- lavender and baby's breath -- sprout from the top in a dusty bouquet. The glaze catches the torchlight.",
    on_feel = "Smooth, cool ceramic. Rounded belly, narrow neck. Dry flowers bristle at the top -- papery and brittle. The glaze is glass-smooth under your fingers.",
    on_smell = "Dried lavender -- faint but still present after all this time. Dust.",

    location = nil,

    initial_state = "intact",
    _state = "intact",

    states = {
        intact = {
            name = "a ceramic vase",
            description = "A tall ceramic vase, glazed deep blue with gold bands around the neck. Dry flowers -- lavender and baby's breath -- sprout from the top in a dusty bouquet. The glaze catches the torchlight.",
            on_feel = "Smooth, cool ceramic. Rounded belly, narrow neck. Dry flowers bristle at the top -- papery and brittle. The glaze is glass-smooth under your fingers.",
            on_smell = "Dried lavender -- faint but still present after all this time. Dust.",
        },

        broken = {
            name = "a shattered vase",
            description = "Shattered ceramic and scattered dry flowers litter the floor. Blue and gold shards, petals, and dust.",
            on_feel = "Sharp ceramic edges -- careful! Dry flower petals crumble between your fingers.",
            on_smell = "Lavender, stronger now that the flowers are crushed. Ceramic dust.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "intact", to = "broken", verb = "break",
            aliases = {"smash", "drop", "throw", "knock"},
            message = "The vase hits the floor and shatters. Blue and gold shards skitter across the polished oak, trailing dry lavender petals. The flowers' scent releases one last time, stronger in death.",
            mutate = {
                weight = 0,
                categories = { remove = "container" },
            },
        },
    },

    mutations = {},
}
