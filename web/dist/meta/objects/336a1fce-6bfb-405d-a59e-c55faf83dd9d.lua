-- silver-key.lua — Optional path key (unlocks crypt archway)
return {
    guid = "{336a1fce-6bfb-405d-a59e-c55faf83dd9d}",
    template = "small-item",

    id = "silver-key",
    material = "silver",
    keywords = {"key", "silver key", "small key", "silver", "ornate key"},
    size = 1,
    weight = 0.3,
    categories = {"metal", "small", "treasure"},
    portable = true,

    name = "a small silver key",
    description = "A small key of tarnished silver, its bow wrought in the shape of a cross -- or perhaps a sword. The bit is delicate, almost ornamental, but the teeth are precisely cut. This is no common key -- it was made for a special lock.",
    on_feel = "Cool metal, lighter than iron. Smooth and finely made. The bow has a cross shape -- you can trace the arms. The teeth are sharp and precise.",
    on_smell = "Tarnished silver -- a faint, sweet metallic scent.",
    on_taste = "Clean metal. Slightly sweet, unlike the sour tang of iron or brass.",

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
