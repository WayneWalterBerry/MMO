return {
    template = "small-item",

    id = "matchbox",
    name = "a small matchbox",
    keywords = {"matchbox", "matches", "match", "match box", "box of matches", "tinderbox", "lucifers"},
    description = "A battered little cardboard matchbox, its striking strip worn nearly smooth. Through a tear in the side you can see the pale wooden heads of the matches within. It rattles faintly when shaken.",

    on_feel = "A small cardboard box, light and hollow. One side has a rough striker strip that catches your thumb.",
    on_listen = "Wooden matches rattle inside when you tilt it. A promising sound.",

    size = 1,
    weight = 0.2,
    categories = {"small", "tool", "fire_source"},
    portable = true,

    -- Tool convention: this object provides a capability to the verb system.
    -- Any mutation with requires_tool = "fire_source" can be fulfilled by this object.
    provides_tool = "fire_source",
    charges = 3,
    on_tool_use = {
        consumes_charge = true,
        when_depleted = "matchbox-empty",
        use_message = "You slide the matchbox open and strike a match against the worn strip. It sputters once, twice, then catches with a sharp hiss and a curl of sulphur smoke.",
        depleted_message = "That was your last match.",
    },

    location = nil,

    on_look = function(self)
        if self.charges == 1 then
            return self.description .. "\n\nOnly one match remains. Use it wisely."
        elseif self.charges > 1 then
            return self.description .. "\n\nThere are " .. self.charges .. " matches left."
        end
        return self.description
    end,

    mutations = {},
}
