return {
    guid = "{453600d7-1c85-4ada-a56d-c4b51f740133}",
    template = "small-item",

    id = "spider-fang",
    name = "a spider fang",
    keywords = {"spider fang", "fang", "spider tooth"},
    description = "A curved, hollow fang the length of a finger. The tip glistens with residual venom — a translucent bead that never quite dries.",

    material = "tooth-enamel",
    size = "tiny",
    weight = 0.02,
    portable = true,

    on_feel = "Smooth and hard, tapering to a needle-sharp point. A shallow groove runs its length — the venom channel.",
    on_smell = "A faint chemical sharpness, like vinegar left in the sun.",
    on_listen = "Silent.",
    on_taste = "Your tongue goes numb instantly. Bitter, metallic residue.",

    -- Poison component for weapon crafting
    crafting = {
        category = "poison-component",
        applies_to = { "blade", "arrow-tip" },
        effect = "spider-venom",
    },

    mutations = {},
}
