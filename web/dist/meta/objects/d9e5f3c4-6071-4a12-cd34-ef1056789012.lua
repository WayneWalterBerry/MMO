-- grain-sack.lua — Nested container (Puzzle 009: hides iron-key)
-- States: tied → untied (by hand) OR tied → cut-open (with knife)
return {
    guid = "{d9e5f3c4-6071-4a12-cd34-ef1056789012}",
    template = "container",

    id = "grain-sack",
    material = "burlap",
    keywords = {"sack", "grain sack", "grain", "burlap sack", "bag", "feed sack", "heavy sack"},
    size = 3,
    weight = 15,
    categories = {"container", "fabric"},
    portable = true,

    name = "a heavy sack of grain",
    description = "A heavy burlap sack, cinched tight with twine at the neck. The weave bulges with grain -- you can feel individual kernels through the fabric. A faded stamp reads \"BARLEY\" in block letters.",
    on_feel = "Rough burlap, coarse weave. Hard lumps underneath -- grain. The neck is tied tightly with scratchy twine. Heavy. Very heavy.",
    on_smell = "Stale grain, dusty burlap. A hint of mildew.",

    location = nil,

    surfaces = {
        inside = {
            capacity = 2, max_item_size = 1, weight_capacity = 5,
            contents = {"iron-key-1"},
            accessible = false,
        },
    },

    prerequisites = {
        cut = { requires = {"cutting_edge"}, auto_steps = {"take knife"} },
    },

    initial_state = "tied",
    _state = "tied",

    states = {
        tied = {
            name = "a heavy sack of grain",
            description = "A heavy burlap sack, cinched tight with twine at the neck. The weave bulges with grain -- you can feel individual kernels through the fabric. A faded stamp reads \"BARLEY\" in block letters.",
            on_feel = "Rough burlap, coarse weave. Hard lumps underneath -- grain. The neck is tied tightly with scratchy twine. Heavy. Very heavy.",
            on_smell = "Stale grain, dusty burlap. A hint of mildew.",
        },

        untied = {
            name = "an open sack of grain",
            description = "The burlap sack's neck hangs loose, twine dangling. Golden-brown barley fills it nearly to the top. You could reach inside.",
            on_feel = "Rough burlap, open top. Grain shifts under your fingers -- dry, cool kernels.",
            on_smell = "Barley and dust. Stronger now that it's open.",
        },

        ["cut-open"] = {
            name = "a slashed sack of grain",
            description = "The sack has been slashed open. Barley spills across the floor in a golden drift, and something glints among the kernels.",
            on_feel = "Rough burlap, torn edges. Grain everywhere -- on the floor, in the sack. Something hard and metallic in the grain.",
            on_smell = "Barley dust, sharp and ticklish in the nose.",
        },
    },

    transitions = {
        {
            from = "tied", to = "untied", verb = "untie",
            aliases = {"open"},
            message = "You work the twine loose with your fingers -- it takes a while, the knot is tight and old. The neck of the sack falls open, revealing barley grain nearly to the brim.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "tied", to = "cut-open", verb = "cut",
            requires_tool = "cutting_edge",
            message = "You slash the sack with the knife. Burlap parts easily, and barley pours out in a rush, scattering across the floor. Something metallic clinks among the kernels.",
            mutate = {
                weight = 3,
                keywords = { add = "cut" },
            },
        },
    },

    mutations = {},
}
