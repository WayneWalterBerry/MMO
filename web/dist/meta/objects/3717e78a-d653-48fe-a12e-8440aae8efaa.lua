-- grain-handful.lua — Raw cookable ingredient (Phase 3 WAVE-3)
-- Not edible raw; must be cooked into flatbread via fire source
return {
    guid = "{3717e78a-d653-48fe-a12e-8440aae8efaa}",
    template = "small-item",

    id = "grain-handful",
    name = "a handful of grain",
    keywords = {"grain", "handful of grain", "barley", "raw grain"},
    description = "A loose handful of barley grain, golden-brown and dusty. The kernels are hard and dry -- inedible raw, but they could be ground or cooked into something.",

    material = "plant",
    size = 1,
    weight = 0.2,
    portable = true,
    categories = {"small-item", "ingredient"},

    on_feel = "Hard, dry kernels that shift between your fingers. Dusty husks scratch your palm.",
    on_smell = "Dry grain dust and a faint earthy sweetness. Wholesome, if raw.",
    on_listen = "The kernels rattle softly against each other, like tiny pebbles.",
    on_taste = "Hard and chalky. Barely any flavor -- just starch and dust. You can't eat this raw.",

    on_eat_reject = "You can't eat raw grain. Try cooking it first.",

    location = nil,

    food = {
        edible = false,
        raw = true,
    },
    cookable = true,

    crafting = {
        cook = {
            becomes = "flatbread",
            requires_tool = "fire_source",
            message = "You press the grain flat and bake it on the hot surface.",
            fail_message_no_tool = "You need a fire source to cook this.",
        },
    },

    mutations = {},
}
