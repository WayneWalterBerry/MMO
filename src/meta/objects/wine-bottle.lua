-- wine-bottle.lua — FSM-managed container (Puzzle 010: oil variant via instance override)
-- States: sealed → open → empty, any → broken (terminal)
return {
    guid = "fb17g5e6-8293-4c34-ef56-013278901234",
    template = "container",

    id = "wine-bottle",
    material = "glass",
    keywords = {"bottle", "wine bottle", "wine", "glass bottle", "dusty bottle"},
    size = 2,
    weight = 1.5,
    categories = {"container", "fragile", "glass", "bottle"},
    portable = true,

    name = "a dusty wine bottle",
    description = "A dark green glass bottle, sealed with a wax-dipped cork. Dust furs the shoulders. A faded label clings to the belly -- the text is illegible. Liquid sloshes when tilted.",
    on_feel = "Cool glass, smooth and heavy. Wax seal at the neck. Liquid shifts inside when tilted.",
    on_smell = "Faintly vinegary through the seal.",
    on_listen = "Liquid glugs when tilted.",

    location = nil,

    prerequisites = {
        pour = { requires_state = "open" },
    },

    initial_state = "sealed",
    _state = "sealed",

    states = {
        sealed = {
            name = "a dusty wine bottle",
            description = "A dark green glass bottle, sealed with a wax-dipped cork. Dust furs the shoulders. A faded label clings to the belly -- the text is illegible. Liquid sloshes when tilted.",
            on_feel = "Cool glass, smooth and heavy. Wax seal at the neck. Liquid shifts inside when tilted.",
            on_smell = "Faintly vinegary through the seal.",
            on_listen = "Liquid glugs when tilted.",
        },

        open = {
            name = "an open wine bottle",
            description = "An open wine bottle, the cork removed. Dark liquid is visible inside. The neck is stained with drips.",
            on_feel = "Cool glass, open top. Liquid weight still inside. Wine-sticky neck.",
            on_smell = "Sharp vinegar and old grape. The wine has long turned.",
            on_listen = "Quiet slosh if tilted.",
        },

        empty = {
            name = "an empty wine bottle",
            description = "An empty wine bottle. A few red-purple dregs stain the inside. The cork sits beside it.",
            on_feel = "Light glass, hollow. Sticky residue inside.",
            on_smell = "Stale wine residue.",
            on_listen = "Hollow ring when tapped.",
            terminal = true,
        },

        broken = {
            name = "a shattered wine bottle",
            description = "Shattered glass and spreading liquid on the stone floor.",
            on_feel = "Sharp glass fragments -- dangerous to touch!",
            on_smell = "Wine and wet stone.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "sealed", to = "open", verb = "open",
            aliases = {"uncork"},
            message = "You prise the wax seal and work the cork free with a hollow pop. The sharp smell of old wine rises from the neck.",
            mutate = {
                weight = function(w) return w - 0.05 end,
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "empty", verb = "pour",
            message = "You upend the bottle. Dark wine glugs out and splashes across the stone floor, staining it purple-black.",
            mutate = {
                weight = 0.4,
                keywords = { add = "empty" },
                categories = { remove = "container" },
            },
        },
        {
            from = "sealed", to = "broken", verb = "break",
            aliases = {"smash", "throw"},
            message = "The bottle shatters on the stone floor. Glass and wine spray across the flagstones.",
        },
        {
            from = "open", to = "broken", verb = "break",
            aliases = {"smash", "throw"},
            message = "The open bottle shatters. Glass and the dregs of wine scatter.",
        },
    },

    mutations = {},
}
