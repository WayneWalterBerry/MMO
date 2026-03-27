-- cooked-bat-meat.lua — Cooked food item (Phase 3 WAVE-3)
-- Product of cooking a dead bat over a fire source
-- 10% food-poisoning risk even when cooked (bat carries disease)
return {
    guid = "{59f5622f-c3aa-4471-8137-b04f20a9c46d}",
    template = "small-item",

    id = "cooked-bat-meat",
    name = "a piece of cooked bat meat",
    keywords = {"cooked bat", "bat meat", "cooked meat", "meat"},
    description = "A thin strip of dark, leathery meat, charred at the edges. The wing membrane has crisped into brittle flakes. There isn't much here.",

    material = "meat",
    size = 1,
    weight = 0.1,
    portable = true,
    categories = {"small-item", "food", "consumable"},

    on_feel = "Thin and dry. The meat is stringy, stretched over tiny fragile bones. Bits of crisped membrane crumble off at the touch.",
    on_smell = "Smoky with a sharp, musky undertone. Something slightly off beneath the char -- a sourness you can't quite place.",
    on_listen = "Silent. The crisped membrane crackles faintly if squeezed.",
    on_taste = "Thin and stringy, with a bitter, musty aftertaste. Your tongue tells you this isn't quite right, but hunger doesn't care.",

    location = nil,

    food = {
        edible = true,
        nutrition = 10,
        risk = "food-poisoning",
        risk_chance = 0.10,
        effects = {
            { type = "heal", amount = 2 },
            { type = "narrate", message = "The bat meat is thin and stringy." },
        },
    },

    mutations = {},
}
