return {
    template = "furniture",
    id = "desk-open",
    name = "a heavy oak desk (drawer open)",
    keywords = {"desk", "table", "oak desk", "drawer", "writing desk"},
    description = "A massive oak writing desk, scarred by years of use. Ink stains bloom across the surface like dark continents. The brass-handled drawer hangs open, its dark interior exposed.",

    size = 8,
    weight = 50,
    portable = false,
    material = "wood",

    categories = {"furniture", "wooden"},

    surfaces = {
        top = {
            capacity = 6,
            max_item_size = 4,
            weight_capacity = 30,
            contents = {},
        },
        inside = {
            capacity = 5,
            max_item_size = 2,
            weight_capacity = 15,
            accessible = true,
            contents = {},
        },
        underneath = {
            capacity = 3,
            max_item_size = 2,
            weight_capacity = 20,
            contents = {},
        },
    },

    location = nil,

    on_look = function(self)
        local inside = self.surfaces and self.surfaces.inside
        if not inside or not inside.contents or #inside.contents == 0 then
            return self.description .. "\n\nThe drawer yawns open. It is empty."
        end

        local lines = {self.description, "\nInside the drawer:"}
        for _, id in ipairs(inside.contents) do
            table.insert(lines, "  " .. id)
        end
        return table.concat(lines, "\n")
    end,

    mutations = {
        close = {
            becomes = "desk",
        },
    },
}
