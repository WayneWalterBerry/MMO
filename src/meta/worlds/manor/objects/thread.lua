return {
    guid = "{8a7edb7e-9dff-4587-a104-4710cb270058}",
    template = "small-item",

    id = "thread",
    name = "a spool of thread",
    keywords = {"thread", "spool", "cotton", "string", "cotton thread", "sewing thread", "spool of thread"},
    description = "A small wooden spool wound tight with cream-coloured cotton thread. The thread is fine but strong -- the kind used for mending clothes or stitching wounds. A loose end trails from the spool like a pale worm.",

    on_feel = "A thin, smooth strand. Thread or string.",
    on_smell = "Faintly of cotton and old wood.",

    size = 1,
    weight = 0.05,
    categories = {"small", "crafting-material", "sewing"},
    portable = true,
    material = "cotton",

    -- Sewing material: used WITH needle for sewing/crafting.
    -- The needle provides sewing_tool; thread provides sewing_material.
    -- Both are required for the SEW verb (compound tool pattern).
    provides_tool = "sewing_material",

    location = nil,

    on_look = function(self)
        return self.description .. "\n\nUseful for mending, if you had a needle."
    end,

    mutations = {},
}
