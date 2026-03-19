return {
    template = "small-item",

    id = "pen",
    name = "an ink pen",
    keywords = {"pen", "ink pen", "quill", "writing pen", "nib", "fountain pen"},
    description = "A slender pen with a steel nib, stained permanently blue-black from years of use. The wooden barrel is smooth from handling, the brass clip tarnished but functional. A faint ink smell clings to it.",

    size = 1,
    weight = 0.1,
    categories = {"small", "tool", "writing"},
    portable = true,

    provides_tool = "writing_instrument",
    -- Pens do not consume charges. They last forever.
    -- No charges field = infinite uses.
    on_tool_use = {
        consumes_charge = false,
        use_message = "You uncap the pen and press nib to surface.",
    },

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
