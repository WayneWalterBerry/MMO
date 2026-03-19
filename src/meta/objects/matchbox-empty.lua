return {
    template = "small-item",

    id = "matchbox-empty",
    name = "an empty matchbox",
    keywords = {"matchbox", "matches", "match", "match box", "empty matchbox", "empty box"},
    description = "A battered little cardboard matchbox, its striking strip worn to a dark smear. It is empty — the faint ghost of sulphur is all that remains of its former usefulness.",

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
