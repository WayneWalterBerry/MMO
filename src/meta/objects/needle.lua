return {
    guid = "07b9daaf-ee36-408e-8c66-d794bc175ed1",
    template = "small-item",

    id = "needle",
    name = "a sewing needle",
    keywords = {"needle", "sewing needle", "steel needle", "darning needle"},
    description = "A fine steel sewing needle, slightly curved from long use. The eye is just large enough to thread, and the point could pierce leather. Someone took good care of this -- there is not a spot of rust on it.",

    on_feel = "Thin metal, slightly curved. A sharp point at one end, a tiny eye at the other. No rust -- smooth and well-kept.",

    size = 1,
    weight = 0.05,
    categories = {"small", "tool", "sharp", "metal", "sewing"},
    portable = true,

    -- Sewing tool: used with SEW verb to transform materials into products.
    -- Pattern: SEW <material> WITH needle (requires sewing skill)
    -- This is the first CRAFTING mechanic: skill + tool + material → product.
    provides_tool = "sewing_tool",
    on_tool_use = {
        consumes_charge = false,
        use_message = "You thread the needle and begin to work.",
    },

    location = nil,

    on_look = function(self)
        return self.description .. "\n\nWith the right skill and materials, this could make something useful."
    end,

    mutations = {},
}
