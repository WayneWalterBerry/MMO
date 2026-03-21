-- burial-jewelry.lua — Lore/treasure object (Crypt, Sarcophagus 1)
return {
    guid = "b3juz83g-4e51-4864-a171-c31f94789012",
    template = "small-item",

    id = "burial-jewelry",
    material = "silver",
    keywords = {"ring", "silver ring", "jewelry", "burial ring", "treasure", "band"},
    size = 1,
    weight = 0.05,
    categories = {"treasure", "metal", "small", "wearable"},
    portable = true,

    name = "a tarnished silver ring",
    description = "A silver ring, tarnished nearly black. It's a simple band with a small engraved symbol -- the same eye-and-triangle motif from the deep cellar altar. Inside the band, tiny letters are inscribed: \"CUSTOS\" -- Latin for \"guardian\" or \"keeper.\"",
    on_feel = "A thin metal band, smooth inside, with a raised engraving on the outside. Light. Cold. It fits your finger.",
    on_smell = "Tarnished silver -- faint, sweet-metallic.",

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
