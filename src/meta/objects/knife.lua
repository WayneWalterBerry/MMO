return {
    template = "small-item",

    id = "knife",
    name = "a small knife",
    keywords = {"knife", "blade", "small knife", "dagger", "shiv", "paring knife"},
    description = "A small knife with a bone handle and a blade no longer than your finger. The edge is still keen — it nicks the air when you turn it. The kind of knife used for peeling apples, cutting twine, or less wholesome things.",

    size = 1,
    weight = 0.3,
    categories = {"small", "tool", "weapon", "sharp", "metal"},
    portable = true,

    -- Multi-capability tool: provides both cutting and injury capabilities.
    -- The engine resolves which capability to use by verb context:
    --   CUT <object> WITH knife  → cutting_edge
    --   CUT SELF WITH knife      → injury_source
    --   PRICK SELF WITH knife    → injury_source
    provides_tool = {"cutting_edge", "injury_source"},
    on_tool_use = {
        consumes_charge = false,
        use_message = "You grip the bone handle and draw the blade.",
    },

    location = nil,

    on_look = function(self)
        return self.description .. "\n\nThe edge catches the light. It could cut almost anything — including you, if you were desperate enough."
    end,

    mutations = {},
}
