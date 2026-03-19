return {
    guid = "41eb8a2f-972f-4245-a1fb-bbfdcaad4868",
    template = "small-item",

    id = "matchbox",
    name = "a small matchbox",
    keywords = {"matchbox", "match box", "box of matches", "tinderbox", "lucifers"},
    description = "A battered little cardboard matchbox of thin cardboard. The sliding tray is closed. One long side bears a rough brown striker strip, worn but functional.",

    on_feel = "A small cardboard box. One side is rough — a striker strip.",
    on_smell = "Faintly sulfurous — the promise of fire, dormant.",
    on_listen = "Something rattles inside — small wooden sticks.",

    size = 1,
    weight = 0.3,
    categories = {"small", "container"},
    portable = true,

    -- The matchbox is a CONTAINER holding individual match objects.
    -- It also has a striker surface required for the STRIKE compound action.
    container = true,
    capacity = 10,
    max_item_size = 1,
    weight_capacity = 1,
    contents = {"match-1", "match-2", "match-3", "match-4", "match-5", "match-6", "match-7"},

    has_striker = true,

    location = nil,

    on_look = function(self)
        if #self.contents == 0 then
            return self.description .. "\n\nIt is empty. Not a single match remains."
        end
        local text = self.description
        text = text .. "\n\nInside: " .. #self.contents .. " wooden matches."
        return text
    end,

    mutations = {},
}
