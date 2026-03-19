return {
    guid = "adfd6688-bbd0-4cd5-9b3b-dfb1b12d37e0",
    template = "small-item",
    id = "bandage",
    name = "a crude bandage",
    keywords = {"bandage", "wrap", "dressing", "cloth wrap"},
    description = "A strip of burlap torn and folded into a rough bandage. It won't win any medical awards, but it might stop the bleeding.",

    on_feel = "A rolled cloth strip, rough but tightly wound. Functional, if not exactly sterile.",

    size = 1,
    weight = 0.1,
    portable = true,
    material = "fabric",

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {"medical", "fabric"},

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
