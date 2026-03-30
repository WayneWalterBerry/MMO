-- wolf-bone.lua — Butchery product / improvised weapon (Phase 4 WAVE-1)
-- Product of butchering a dead wolf; usable as blunt improvised weapon
return {
    guid = "{7e7a979b-57bc-4661-838d-074fcb49ce4c}",
    template = "small-item",

    id = "wolf-bone",
    name = "a wolf bone",
    keywords = {"wolf bone", "fresh bone", "long bone"},
    description = "A heavy leg bone from a wolf, freshly stripped of meat. Pale yellow-white, with shreds of sinew still clinging to the joints. Dense and solid — it has weight to it.",

    material = "bone",
    size = 2,
    weight = 0.5,
    portable = true,
    categories = {"small-item", "weapon", "crafting-material"},

    on_feel = "Hard, smooth bone — still warm. Knobs at each end where the joints were. Sinew clings in wet strips. Heavy for its size.",
    on_smell = "Marrow and blood. A rich, meaty undertone beneath the mineral scent of bone.",
    on_listen = "Silent. Tapping it produces a dull, dense thud — solid through and through.",
    on_taste = "Salty marrow and blood. The surface is smooth and mineral.",

    location = nil,

    provides_tool = "blunt_weapon",

    combat = {
        type = "blunt",
        force = 3,
        message = "clubs",
        two_handed = false,
    },

    mutations = {},
}
