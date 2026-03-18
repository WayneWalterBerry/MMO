return {
    id = "chamber-pot",
    name = "a ceramic chamber pot",
    keywords = {"chamber pot", "pot", "ceramic pot", "toilet", "chamberpot", "privy"},
    description = "A squat ceramic chamber pot sits in the corner with the quiet dignity of an object that knows exactly what it is for. It is mercifully empty, glazed in a chipped blue-and-white pattern that suggests someone once thought aesthetics mattered even here.",

    size = 2,
    weight = 3,
    categories = {"ceramic", "container", "fragile"},
    portable = true,
    container = true,
    capacity = 2,

    contents = {},
    location = nil,

    on_look = function(self)
        if self.contents and #self.contents > 0 then
            local text = self.description .. "\n\nInexplicably, it contains:"
            for _, id in ipairs(self.contents) do
                text = text .. "\n  " .. id
            end
            return text
        end
        return self.description .. "\n\nIt is, thankfully, empty."
    end,

    mutations = {},
}
