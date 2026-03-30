-- wolf-meat.lua — Raw butchery product (Phase 4 WAVE-1)
-- Product of butchering a dead wolf; cookable into cooked-wolf-meat
return {
    guid = "{c2027139-6127-4020-9272-f707333290c9}",
    template = "small-item",

    id = "wolf-meat",
    name = "a cut of raw wolf meat",
    keywords = {"wolf meat", "raw wolf meat", "raw meat", "meat"},
    description = "A thick slab of dark red meat, roughly carved from a wolf carcass. Streaks of white fat run through the muscle. Blood still seeps from the cut edges.",

    material = "meat",
    size = 1,
    weight = 0.8,
    portable = true,
    categories = {"small-item", "food", "ingredient"},

    on_feel = "Cold, slippery flesh with a gamey odor. The surface is wet with blood and the fat is waxy under your fingers.",
    on_smell = "Raw meat and iron blood. A wild, gamey musk — unmistakably predator, not prey.",
    on_listen = "Silent. The blood drips faintly onto the floor.",
    on_taste = "Raw and metallic. The flesh is tough and gamey. Your stomach turns.",

    on_eat_reject = "You can't eat raw wolf meat. Try cooking it first.",

    location = nil,

    food = {
        category = "meat",
        edible = false,
        raw = true,
    },
    cookable = true,

    crafting = {
        cook = {
            becomes = "cooked-wolf-meat",
            requires_tool = "fire_source",
            message = "You hold the wolf meat over the flames. Fat sizzles and drips, and the flesh darkens to a rich brown.",
            fail_message_no_tool = "You need a fire source to cook this.",
        },
    },

    mutations = {},
}
