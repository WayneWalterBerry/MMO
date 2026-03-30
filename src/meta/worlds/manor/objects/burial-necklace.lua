-- burial-necklace.lua — Burial treasure (Crypt, Sarcophagus 4)
return {
    guid = "{5e9b3c71-a284-4df6-8e13-7d0f4a5b2c89}",
    template = "small-item",

    id = "burial-necklace",
    material = "silver",
    keywords = {"necklace", "burial necklace", "chain", "pendant", "jewelry", "treasure", "silver necklace"},
    size = 1,
    weight = 0.08,
    categories = {"treasure", "metal", "small", "wearable"},
    portable = true,

    name = "a tarnished burial necklace",
    description = "A fine silver chain bearing a small pendant -- a disc stamped with the eye-and-triangle symbol that recurs throughout this place. The chain is blackened with tarnish, its links delicate and intricate. The pendant disc is heavy for its size, perhaps silver over lead. It was placed on the chest of the dead with care and intention.",
    on_feel = "A fine chain, each link smaller than a grain of rice. The pendant is a smooth disc, heavier than expected. The chain is intact -- good metalwork survives centuries.",
    on_smell = "Tarnished silver -- faint, sweet-metallic. Dust.",

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
