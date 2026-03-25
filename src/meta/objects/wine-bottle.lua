-- wine-bottle.lua — FSM-managed drinkable bottle (Puzzle 010 + Puzzle 016)
-- States: sealed → open → empty, any → broken (terminal)
-- Puzzle 010: SMELL distinguishes wine from oil
-- Puzzle 016: DRINK teaches the verb, contrasts with Puzzle 002 poison
return {
    guid = "{1143ab52-ba47-4610-bd1f-6c9aa6167287}",
    template = "small-item",

    id = "wine-bottle",
    material = "glass",
    keywords = {"wine bottle", "wine", "dusty bottle"},
    size = 2,
    weight = 1.5,
    categories = {"small-item", "fragile", "glass", "bottle"},
    portable = true,

    name = "a dusty wine bottle",
    description = "A dark green glass bottle, sealed with a wax-dipped cork. Dust furs the shoulders. A faded label clings to the belly -- the text is illegible. Liquid sloshes when tilted.",
    on_feel = "Cool glass, smooth and heavy. Wax seal at the neck. Liquid shifts inside when tilted.",
    on_smell = "Faintly vinegary through the seal.",
    on_listen = "Liquid glugs when tilted.",

    location = nil,

    prerequisites = {
        pour = { requires_state = "open" },
        drink = { requires_state = "open" },
    },

    initial_state = "sealed",
    _state = "sealed",

    states = {
        sealed = {
            name = "a dusty wine bottle",
            description = "A dark green glass bottle, sealed with a wax-dipped cork. Dust furs the shoulders. A faded label clings to the belly -- the text is illegible. Liquid sloshes when tilted.",
            on_feel = "Cool glass, smooth and heavy. Wax seal at the neck. Liquid shifts inside when tilted.",
            on_smell = "Faintly vinegary through the seal.",
            on_taste = "You lick the wax seal. It tastes of dust, old wax, and nothing useful. You'd need to open it first.",
            on_listen = "Liquid glugs when tilted.",
        },

        open = {
            name = "an open wine bottle",
            description = "An open wine bottle, the cork removed. Dark liquid is visible inside. The neck is stained with drips.",
            on_feel = "Cool glass, open top. Liquid weight still inside. Wine-sticky neck.",
            on_smell = "Sharp vinegar and old grape. The wine has long turned.",
            on_taste = "Sour, acidic, old -- but recognizably wine, not poison. Your tongue puckers at the vinegar tang.",
            on_listen = "Quiet slosh if tilted.",
        },

        empty = {
            name = "an empty wine bottle",
            description = "An empty wine bottle, stained dark inside. A few red-purple dregs cling to the glass. The cork sits beside it.",
            on_feel = "Light glass, hollow and dry inside. Sticky residue where the wine was.",
            on_smell = "Stale wine residue.",
            on_taste = "You tip the bottle. A single drop of sour dregs. Not worth the effort.",
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
            message = "You peel away the crumbling wax seal and pull the cork free with a soft pop. A sharp, vinegary smell rises from the bottle.",
            mutate = {
                weight = function(w) return w - 0.05 end,
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "empty", verb = "drink",
            aliases = {"quaff", "sip", "swig"},
            message = "You raise the bottle and take a swig. The wine is sour and old -- turned halfway to vinegar years ago. It's rough, harsh on the throat, and tastes of dust and neglect. But it's unmistakably wine, and it's unmistakably not poison. It warms your belly despite the cellar's chill. You've had worse.",
            mutate = {
                contains = nil,
                weight = 0.5,
                keywords = { add = "empty" },
            },
        },
        {
            from = "open", to = "empty", verb = "pour",
            message = "You upend the bottle. Dark wine glugs out and splashes across the stone floor, staining it purple-black.",
            mutate = {
                contains = nil,
                weight = 0.4,
                keywords = { add = "empty" },
            },
        },
        {
            from = "sealed", to = "broken", verb = "break",
            aliases = {"smash", "throw"},
            message = "The bottle shatters on the stone floor. Glass and wine spray across the flagstones, sharp shards skittering in every direction.",
            mutate = {
                becomes = nil,
                spawns = {"glass-shard", "glass-shard"},
            },
        },
        {
            from = "open", to = "broken", verb = "break",
            aliases = {"smash", "throw"},
            message = "The open bottle shatters. Glass and the dregs of wine scatter, leaving razor-sharp shards on the stone.",
            mutate = {
                becomes = nil,
                spawns = {"glass-shard", "glass-shard"},
            },
        },
    },

    mutations = {
        shatter = {
            becomes = nil,
            spawns = {"glass-shard", "glass-shard"},
            narration = "The glass bottle shatters on impact, sending wicked shards of green glass skittering across the stone floor.",
        },
    },
}
