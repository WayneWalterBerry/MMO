return {
    guid = "07e76701-ebb5-4b5d-adc0-c8012e7ff809",
    template = "small-item",

    id = "pencil",
    name = "a graphite pencil",
    keywords = {"pencil", "graphite", "lead pencil", "writing pencil", "drawing pencil"},
    description = "A short pencil of cedar wood, sharpened to a fine point with a knife at some point. The graphite core leaves faint grey smudges on your fingers. Someone has chewed the end.",

    on_feel = "A wooden shaft, hexagonal, with a pointed graphite tip. One end is chewed. Leaves grey smudges on your fingers.",

    size = 1,
    weight = 0.1,
    categories = {"small", "tool", "writing"},
    portable = true,
    material = "wood",

    provides_tool = "writing_instrument",
    -- Pencils do not consume charges. Infinite uses.
    -- Future mechanic: pencil writing is ERASABLE (pen writing is not).
    -- For now, both behave identically.
    erasable = true,
    on_tool_use = {
        consumes_charge = false,
        use_message = "You press the pencil to the surface, graphite whispering against the grain.",
    },

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
