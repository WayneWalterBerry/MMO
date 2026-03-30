-- iron-key.lua — Critical path key (Puzzle 009: unlocks iron door to Deep Cellar)
return {
    guid = "{438f3f05-00d9-4b5a-b50d-bd46012b27c7}",
    template = "small-item",

    id = "iron-key",
    material = "iron",
    keywords = {"key", "iron key", "heavy key", "black key", "iron", "rusty key"},
    size = 1,
    weight = 0.5,
    categories = {"metal", "small"},
    portable = true,
    provides_tool = "iron-key",

    name = "a heavy iron key",
    description = "A heavy iron key, nearly black with age and pitted with rust. The bow is a simple ring, large enough to thread a finger through. The bit is thick and crude -- clearly made for a heavy lock. This key means business.",
    on_feel = "Cold, heavy iron. Rough with pitting and slight rust. The ring bow is large -- you could wear it on a finger. The teeth are thick and blunt.",
    on_smell = "Iron and rust. A faint metallic tang.",
    on_taste = "Metallic. Blood-like. The sour bite of old iron. (Not recommended.)",

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
