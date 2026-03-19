return {
    template = "small-item",

    id = "matchbox-empty",
    name = "an empty matchbox",
    keywords = {"matchbox", "matches", "match", "match box", "empty matchbox", "empty box"},
    description = "A battered little cardboard matchbox, its striking strip worn to a dark smear. It is empty — the faint ghost of sulphur is all that remains of its former usefulness.",

    on_feel = "A small cardboard box, crushed and light. The striker strip is worn to nothing. Empty.",
    on_smell = "The ghost of sulphur. A memory of fire, spent.",
    on_listen = "Silence. You shake it and hear nothing.",

    size = 1,
    weight = 0.1,
    categories = {"small", "junk"},
    portable = true,

    provides_tool = nil,
    charges = 0,

    location = nil,

    on_look = function(self)
        return self.description .. "\n\nIt is completely empty. You shake it and hear nothing. Worst. Fire source. Ever."
    end,

    mutations = {},
}
