-- spider-meat.lua — Butchery product with venom risk (Phase 4 WAVE-1)
-- Product of butchering a dead spider; edible but carries venom risk
return {
    guid = "{6b7c8bb2-71b1-4ac6-a57e-8a23536d3054}",
    template = "small-item",

    id = "spider-meat",
    name = "a lump of spider meat",
    keywords = {"spider meat", "pale meat", "arachnid meat"},
    description = "A small lump of pale, translucent meat extracted from a spider's abdomen. It glistens with moisture and has a faintly chemical smell. The texture is disturbingly soft.",

    material = "meat",
    size = 1,
    weight = 0.1,
    portable = true,
    categories = {"small-item", "food", "consumable"},

    on_feel = "Soft, wet, and disturbingly warm. The texture is like a raw oyster — your fingers sink into it. A faint tingling where it touches bare skin.",
    on_smell = "A sharp chemical bitterness beneath the smell of raw meat. Faintly acrid, like vinegar and rust.",
    on_listen = "Silent.",
    on_taste = "Bitter and metallic. Your tongue goes numb almost immediately. The aftertaste is chemical and wrong.",

    location = nil,

    food = {
        edible = true,
        nutrition = 8,
        risk = "spider-venom",
        risk_chance = 0.30,
        effects = {
            { type = "heal", amount = 2 },
            { type = "narrate", message = "The spider meat is foul but fills a corner of your stomach. Your lips tingle." },
        },
    },

    mutations = {},
}
