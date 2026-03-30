-- wolf-hide.lua — Butchery product / crafting material (Phase 4 WAVE-1)
-- Product of butchering a dead wolf; crafting material for future armor repairs
return {
    guid = "{67c38c8b-53a6-4de9-85e9-24e9ffe86503}",
    template = "small-item",

    id = "wolf-hide",
    name = "a wolf hide",
    keywords = {"wolf hide", "animal skin", "pelt", "hide"},
    description = "A large piece of wolf hide, roughly cut from the carcass. The grey fur is thick and coarse on one side, the underside slick with fat and membrane. It reeks of blood and musk.",

    material = "hide",
    size = 2,
    weight = 2.0,
    portable = true,
    categories = {"small-item", "crafting-material"},

    on_feel = "Coarse, dense fur on one side — thick enough to turn a draught. The underside is slippery with fat and wet membrane. Heavy when folded.",
    on_smell = "Blood, wet fur, and the sharp territorial musk of wolf. Overpowering when held close.",
    on_listen = "Silent. The fur muffles sound when pressed against anything.",
    on_taste = "Salt and iron. Wet fur and animal fat. You spit immediately.",

    location = nil,

    mutations = {},
}
