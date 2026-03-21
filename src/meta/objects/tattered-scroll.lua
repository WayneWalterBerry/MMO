-- tattered-scroll.lua — Readable lore object (Deep Cellar, Puzzle 012 hint)
-- States: rolled → unrolled (readable)
return {
    guid = "840bgp4n-1b22-453d-784e-902c01890123",
    template = "small-item",

    id = "tattered-scroll",
    material = "paper",
    keywords = {"scroll", "tattered scroll", "parchment", "document", "text", "writing", "manuscript"},
    size = 1,
    weight = 0.1,
    categories = {"readable", "paper", "small"},
    portable = true,

    name = "a tattered scroll",
    description = "A scroll of yellowed parchment, tightly rolled and tied with a faded ribbon. The edges are frayed and spotted with age. It looks very old -- and very fragile.",
    on_feel = "Dry, brittle parchment rolled tight. A thin ribbon ties it closed -- silk, by the feel. The edges crumble slightly at your touch.",
    on_smell = "Old paper, dust, and a trace of iron-gall ink. Ancient.",

    location = nil,

    prerequisites = {
        read = { requires_state = "unrolled" },
    },

    initial_state = "rolled",
    _state = "rolled",

    states = {
        rolled = {
            name = "a tattered scroll",
            description = "A scroll of yellowed parchment, tightly rolled and tied with a faded ribbon. The edges are frayed and spotted with age. It looks very old -- and very fragile.",
            on_feel = "Dry, brittle parchment rolled tight. A thin ribbon ties it closed -- silk, by the feel. The edges crumble slightly at your touch.",
            on_smell = "Old paper, dust, and a trace of iron-gall ink. Ancient.",
        },

        unrolled = {
            name = "an unrolled scroll",
            description = "A sheet of yellowed parchment, covered in faded script. The handwriting is spidery and archaic, the ink brown with age. Much of the text is illegible, eaten by damp and time, but fragments remain.",
            on_feel = "Flat, brittle parchment. Crinkly and fragile -- it could tear at any moment. The surface is rough where ink has been applied.",
            on_smell = "Iron-gall ink, old vellum, must.",
            on_read = "\"...in the year of our Lord 1143, this cellar was consecrated to the keeping of the [illegible]... The family of [smudged] did build above, unknowing of what lay beneath... Let no hand disturb what is sealed here, for the [illegible] watches still... The key to the inner chamber rests with the guardian, behind the place of offering...\"",
        },
    },

    transitions = {
        {
            from = "rolled", to = "unrolled", verb = "read",
            aliases = {"open", "unroll", "untie"},
            message = "You carefully untie the ribbon and unroll the parchment. It crackles ominously but holds together. Faded script covers the page -- most is illegible, but fragments emerge from the decay...",
            mutate = {
                keywords = { add = "open" },
            },
        },
    },

    mutations = {},
}
