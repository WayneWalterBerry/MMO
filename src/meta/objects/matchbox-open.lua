return {
    guid = "a7f1c3d9-6e24-4b8a-9f52-1d3e7a8b4c60",
    template = "small-item",

    id = "matchbox-open",
    name = "an open matchbox",
    keywords = {"matchbox", "match box", "box of matches", "tinderbox", "lucifers", "open matchbox"},
    description = "A battered little cardboard matchbox, its sliding tray pulled open. Inside, wooden matches lie in a neat row. One long side bears a rough brown striker strip, worn but functional.",

    on_feel = "A small cardboard box, tray slid open. You can feel the match heads inside — bulbous and slightly rough.",
    on_smell = "Faintly sulfurous — the promise of fire, now within easy reach.",
    on_listen = "Silence. The matches wait.",

    size = 1,
    weight = 0.3,
    categories = {"small", "container"},
    portable = true,

    container = true,
    accessible = true,
    capacity = 10,
    max_item_size = 1,
    weight_capacity = 1,
    contents = {"match-1", "match-2", "match-3", "match-4", "match-5", "match-6", "match-7"},

    has_striker = true,

    location = nil,

    on_look = function(self)
        if #self.contents == 0 then
            return self.description:gsub("Inside, wooden matches lie in a neat row. ", "")
                .. "\n\nIt is empty. Not a single match remains."
        end
        local text = self.description
        text = text .. "\n\nInside: " .. #self.contents .. " wooden matches."
        return text
    end,

    mutations = {
        close = {
            becomes = "matchbox",
            message = "You slide the matchbox tray shut with a soft click.",
        },
    },
}
