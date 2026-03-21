-- silver-dagger.lua — Tool/weapon/treasure (Crypt, Sarcophagus 2)
return {
    guid = "e6mx2b6j-7184-4b97-d4a4-f64227012345",
    template = "small-item",

    id = "silver-dagger",
    material = "silver",
    keywords = {"dagger", "silver dagger", "knife", "blade", "weapon", "ceremonial dagger"},
    size = 2,
    weight = 0.5,
    categories = {"weapon", "tool", "metal", "treasure", "sharp"},
    portable = true,

    name = "a silver dagger",
    description = "A silver dagger, tarnished but sharp. The blade is leaf-shaped and double-edged, about eight inches long. The hilt is wrapped in wire and set with a small dark stone -- garnet, perhaps. Symbols are etched along the blade -- the same recurring motifs from the altar and walls. This is a ceremonial weapon, not a battlefield one. But it would still cut.",
    on_feel = "Cold metal, smooth. The blade has edges -- sharp, even after centuries. The wire-wrapped hilt fits your hand well. The pommel stone is smooth and cool. Lighter than an iron knife but well-balanced.",
    on_smell = "Tarnished silver. A faint, sweet metallic scent -- different from the iron of the crowbar or the brass of the key.",
    on_listen = "A faint ring when tapped -- silver sings.",

    location = nil,

    provides_tool = {"cutting_edge", "injury_source", "ritual_blade"},

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
