-- burial-coins.lua — Treasure object (Crypt, multiple sarcophagi)
return {
    guid = "c4kv094h-5f62-4975-b282-d42005890123",
    template = "small-item",

    id = "burial-coins",
    material = "silver",
    keywords = {"coins", "money", "gold coins", "silver coins", "treasure", "currency", "obol"},
    size = 1,
    weight = 0.3,
    categories = {"treasure", "metal", "small"},
    portable = true,

    name = "a handful of old coins",
    description = "A handful of old coins -- some silver, some copper, all tarnished and corroded. The faces stamped on them are unfamiliar -- no king or saint you recognize. The dates are illegible. These coins are ancient, from a currency that no longer exists. They might be worth something to a collector, if you ever find one.",
    on_feel = "Small, thin metal discs, rough with corrosion. Different sizes and weights. Some have raised designs -- faces, crosses, symbols. They clink together satisfyingly.",
    on_smell = "Tarnished metal -- copper and silver. A green patina on the copper ones.",
    on_taste = "Metallic. Sour copper and sweet silver. Old money tastes the same as new money -- disappointing.",

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
