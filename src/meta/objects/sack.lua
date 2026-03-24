return {
    guid = "{4720ace5-baed-4133-b5db-977257f5b680}",
    template = "container",
    id = "sack",
    name = "a burlap sack",
    keywords = {"sack", "bag", "burlap sack", "burlap", "pouch"},
    description = "A rough burlap sack, cinched at the top with a length of fraying rope. It smells faintly of grain and old earth. Something small and hard rattles inside.",

    on_feel = "Rough burlap, cinched with fraying rope. Something small and hard shifts inside when you squeeze.",
    on_smell = "Grain and old earth. The honest smell of a storeroom.",

    size = 1,
    weight = 0.3,
    portable = true,
    material = "fabric",

    container = true,
    container_preposition = "in",
    capacity = 8,
    max_item_size = 2,
    weight_capacity = 10,
    contents = {"needle", "thread"},
    location = nil,

    categories = {"fabric", "container", "wearable"},

    -- Wearable: defaults to back (backpack), can also be worn on head
    wear = {
        slot = "back",
        layer = "outer",
        blocks_vision = false,
        container_access_when_worn = true,
        wear_quality = "makeshift",
    },

    -- Alternate wear mode: pulling it over your head blocks vision
    wear_alternate = {
        head = {
            slot = "head",
            layer = "outer",
            blocks_vision = true,
            container_access_when_worn = false,
        },
    },

    on_look = function(self, registry)
        if #self.contents == 0 then
            return self.description .. "\n\nIt is empty."
        end

        local lines = {self.description, "\nInside the sack:"}
        for _, id in ipairs(self.contents) do
            local item = registry and registry:get(id)
            table.insert(lines, "  " .. (item and item.name or id))
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
