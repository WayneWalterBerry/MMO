-- skull.lua — Static atmospheric object (Crypt)
return {
    guid = "a2ity72f-3d40-4753-9060-b20e83678901",
    template = "small-item",

    id = "skull",
    material = "bone",
    keywords = {"skull", "head", "bone", "bones", "cranium", "death's head"},
    size = 2,
    weight = 0.5,
    categories = {"bone", "small", "macabre"},
    portable = true,

    name = "a human skull",
    description = "A human skull, yellowed with age and missing the lower jaw. The cranium is smooth and intact. Empty eye sockets stare at nothing. The teeth in the upper jaw are mostly intact -- worn but present. It weighs less than you'd expect.",
    on_feel = "Smooth bone, cool and dry. The dome of the skull fits in your palm. Eye sockets -- smooth-edged, hollow. Teeth: small, hard bumps along the upper jaw. A crack runs along the left temple. Light. Fragile.",
    on_smell = "Dry bone. Dust. Nothing organic remains -- this skull is very, very old.",
    on_taste = "Dry, chalky, slightly gritty. This is the taste of mortality. Please stop.",

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
