return {
    guid = "4586b2cd-3240-46de-8fb8-5216ad9d4830",
    id = "brass-key",
    name = "a small brass key",
    keywords = {"key", "brass key", "small key", "brass"},
    description = "A small brass key, tarnished nearly black with age. Its bow is shaped like a grinning gargoyle, and its teeth are worn smooth. Whatever lock it opens, it has been waiting a long time to do so.",

    on_feel = "A small metal object, cold and heavy for its size. One end has teeth -- a key. The bow is shaped like a tiny grinning face.",
    on_taste = "Metallic. The sour tang of old brass coats your tongue. Not recommended.",

    size = 1,
    weight = 1,
    categories = {"metal", "small"},
    portable = true,
    material = "brass",

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
