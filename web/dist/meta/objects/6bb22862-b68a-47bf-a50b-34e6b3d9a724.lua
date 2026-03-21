return {
    guid = "6bb22862-b68a-47bf-a50b-34e6b3d9a724",
    template = "sheet",

    id = "bed-sheets",
    name = "rumpled bed sheets",
    keywords = {"sheets", "bed sheets", "bedsheets", "linen", "bedding"},
    description = "Fine cotton bed sheets, once white, now the color of old cream. They are hopelessly rumpled, twisted into shapes that suggest either restless sleep or a hasty departure. Still faintly warm.",

    on_feel = "Smooth cotton, finely woven but hopelessly rumpled. Still faintly warm.",

    size = 3,
    weight = 2,
    categories = {"fabric", "soft", "warm"},
    material = "cotton",

    location = nil,

    on_look = function(self)
        return self.description
    end,
}
