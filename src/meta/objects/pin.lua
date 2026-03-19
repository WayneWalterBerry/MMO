return {
    template = "small-item",

    id = "pin",
    name = "a sewing pin",
    keywords = {"pin", "sewing pin", "straight pin", "needle pin", "stick pin"},
    description = "A long steel pin with a tiny glass bead at one end, the kind used to hold fabric in place while sewing. The point is wickedly sharp — it pricks your thumb just looking at it.",

    size = 1,
    weight = 0.05,
    categories = {"small", "tool", "sharp", "metal", "sewing"},
    portable = true,

    -- SKILL-GATED TOOL: The pin's capabilities change based on player skills.
    -- Base capability: injury_source (prick self → blood)
    -- With lockpicking skill: adds "lockpick" capability (pick locks)
    --
    -- The engine checks player.skills when resolving provides_tool:
    --   1. Always provides "injury_source"
    --   2. If player has "lockpicking" skill, also provides "lockpick"
    provides_tool = "injury_source",
    skill_tools = {
        lockpicking = "lockpick",
    },
    on_tool_use = {
        consumes_charge = false,
        use_message = "You grip the tiny pin between thumb and forefinger.",
    },

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
