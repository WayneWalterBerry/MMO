-- nightshade-antidote.lua — Cures nightshade poisoning when consumed
-- States: sealed → open → empty (terminal)
-- Counterpart to poison-bottle.lua (nightshade poison)
return {
    guid = "{eed24985-e242-4f95-8d78-bbdcca998ba8}",
    template = "small-item",

    id = "nightshade-antidote",
    material = "glass",
    keywords = {"antidote", "vial", "cure", "potion", "glass vial", "nightshade antidote", "remedy"},
    size = 1,
    weight = 0.25,
    categories = {"small-item", "medical", "consumable", "glass", "fragile", "liquid"},
    portable = true,

    effects_pipeline = true,
    is_consumable = true,
    consumable_type = "liquid",
    antidote_for = "nightshade",

    name = "a small glass vial",
    description = "A small glass vial filled with a clear, faintly amber liquid. A tiny cork stopper holds it sealed. Etched into the glass near the base is a crude leaf motif -- the apothecary's mark for antivenom. The liquid catches the light with an almost golden shimmer.",
    room_presence = "A small glass vial sits here, its amber contents catching the light.",
    on_feel = "A small glass vial with cool liquid inside. Smooth glass, slender enough to grip between two fingers. A tiny cork at the top.",
    on_smell = "Through the cork: nothing. The seal is tight.",
    on_listen = "A thin slosh when tilted. Light liquid -- not thick like oil.",

    location = nil,

    initial_state = "sealed",
    _state = "sealed",

    states = {
        sealed = {
            name = "a small glass vial",
            description = "A small glass vial filled with a clear, faintly amber liquid. A tiny cork stopper holds it sealed. Etched into the glass near the base is a crude leaf motif -- the apothecary's mark for antivenom. The liquid catches the light with an almost golden shimmer.",
            on_feel = "A small glass vial with cool liquid inside. Smooth glass, slender enough to grip between two fingers. A tiny cork at the top.",
            on_smell = "Through the cork: nothing. The seal is tight.",
            on_taste = "You lick the glass. Smooth, cold, and utterly uninformative. You'd need to open it first.",
            on_listen = "A thin slosh when tilted. Light liquid -- not thick like oil.",
        },

        open = {
            name = "an open glass vial",
            description = "A small glass vial, uncorked. The clear amber liquid inside gives off a faint, clean scent -- almost floral, with a bitter edge. The etched leaf motif near the base marks it as medicinal.",
            on_feel = "Smooth glass, open top. The liquid is cool and thin. Your fingertip comes away slightly tingling.",
            on_smell = "Clean and sharp -- dried flowers and something bitter, like willow bark. Medicinal.",
            on_taste = "Bitter but clean, with a faint honey sweetness underneath. Not unpleasant. Your tongue tingles.",
            on_listen = "A faint slosh. Nearly silent.",
        },

        empty = {
            name = "an empty glass vial",
            description = "A small glass vial, drained empty. A thin amber residue clings to the inside walls. The etched leaf motif remains -- the only evidence of what the vial once held.",
            on_feel = "Smooth glass, hollow and light. A faint sticky residue inside.",
            on_smell = "The ghost of dried flowers. Fading fast.",
            on_taste = "You tip the vial. A single bitter drop. Not enough to matter.",
            on_listen = "A thin, hollow ring when tapped.",
            terminal = true,
        },

        broken = {
            name = "a shattered glass vial",
            description = "Tiny shards of glass and a splash of amber liquid on the floor. The antidote is lost.",
            on_feel = "Needle-fine glass splinters -- dangerous to touch!",
            on_smell = "Floral bitterness and wet stone.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "sealed", to = "open", verb = "open",
            aliases = {"uncork", "unstop", "unseal"},
            requires_free_hands = true,
            message = "You pinch the tiny cork and pull it free with a soft pop. A clean, faintly floral scent rises from the vial.",
            mutate = {
                weight = function(w) return w - 0.02 end,
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "empty", verb = "drink",
            aliases = {"quaff", "sip", "gulp", "consume", "swallow"},
            message = "You raise the vial and tip it back. The liquid is cool and bitter, with a faint honey sweetness that lingers on your tongue. A spreading warmth moves through your chest, pushing back the cold grip of the poison.",
            effect = {
                type = "cure_injury",
                injury_type = "poisoned-nightshade",
                source = "nightshade-antidote",
                message = "The antidote takes hold. The burning in your veins fades. Your heartbeat steadies.",
            },
            pipeline_effects = {
                { type = "cure_injury", injury_type = "poisoned-nightshade",
                  source = "nightshade-antidote",
                  message = "The antidote takes hold. The burning in your veins fades. Your heartbeat steadies." },
                { type = "mutate", target = "self", field = "weight", value = 0.1 },
                { type = "mutate", target = "self", field = "is_consumable", value = false },
            },
            mutate = {
                weight = 0.1,
                is_consumable = false,
                keywords = { add = "empty" },
            },
        },
        {
            from = "open", to = "empty", verb = "pour",
            aliases = {"spill", "dump"},
            message = "You tip the vial. The amber liquid splashes across the stone floor and is gone. Wasted.",
            mutate = {
                weight = 0.1,
                is_consumable = false,
                keywords = { add = "empty" },
            },
        },
        {
            from = "sealed", to = "broken", verb = "break",
            aliases = {"smash", "throw", "shatter"},
            message = "The vial shatters into needle-fine splinters. The amber liquid splashes across the stone and soaks in. The antidote is lost.",
            mutate = {
                becomes = nil,
                spawns = {"glass-shard"},
            },
        },
        {
            from = "open", to = "broken", verb = "break",
            aliases = {"smash", "throw", "shatter"},
            message = "The open vial shatters. Glass splinters and the last of the amber liquid scatter across the stone.",
            mutate = {
                becomes = nil,
                spawns = {"glass-shard"},
            },
        },
    },

    prerequisites = {
        drink = { requires_state = "open" },
        pour = { requires_state = "open" },
        open = { requires_state = "sealed", requires_free_hands = true },
        uncork = { requires_state = "sealed", requires_free_hands = true },
    },

    mutations = {
        shatter = {
            becomes = nil,
            spawns = {"glass-shard"},
            narration = "The glass vial shatters into fine splinters, the amber liquid lost to the stone.",
        },
    },
}
