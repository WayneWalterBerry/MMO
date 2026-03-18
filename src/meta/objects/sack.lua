return {
    template = "container",
    id = "sack",
    name = "a burlap sack",
    keywords = {"sack", "bag", "burlap sack", "burlap", "pouch"},
    description = "A rough burlap sack, cinched at the top with a length of fraying rope. It smells faintly of grain and old earth.",

    size = 1,
    weight = 0.3,
    portable = true,
    material = "fabric",

    container = true,
    capacity = 4,
    max_item_size = 2,
    weight_capacity = 10,
    contents = {},
    location = nil,

    categories = {"fabric", "container"},

    on_look = function(self)
        if #self.contents == 0 then
            return self.description .. "\n\nIt is empty."
        end

        local lines = {self.description, "\nInside the sack:"}
        for _, id in ipairs(self.contents) do
            table.insert(lines, "  " .. id)
        end
        return table.concat(lines, "\n")
    end,

    mutations = {
        tear = {
            becomes = nil,
            spawns = {"cloth", "cloth", "cloth"},
        },
    },
}
