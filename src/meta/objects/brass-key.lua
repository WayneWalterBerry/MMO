return {
    id = "brass-key",
    name = "a small brass key",
    keywords = {"key", "brass key", "small key", "brass"},
    description = "A small brass key, tarnished nearly black with age. Its bow is shaped like a grinning gargoyle, and its teeth are worn smooth. Whatever lock it opens, it has been waiting a long time to do so.",

    size = 1,
    weight = 1,
    categories = {"metal", "small"},
    portable = true,

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
