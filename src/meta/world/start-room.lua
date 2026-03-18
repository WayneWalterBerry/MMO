return {
    id = "start-room",
    name = "The Bedroom",
    keywords = {"bedroom", "room", "chamber", "bedchamber"},
    description = "You stand in a dim bedchamber that smells of tallow, old wool, and the faintest ghost of lavender. The stone walls are bare save for the shadows that cling to them like ivy. A massive four-poster bed dominates the center, its heavy curtains hanging in moth-eaten folds. Pale grey light seeps through velvet drapes drawn across a window in the far wall.",

    size = nil,
    weight = nil,
    categories = {"room"},
    portable = false,
    container = true,
    capacity = 999,

    contents = {"bed", "nightstand", "vanity", "wardrobe", "rug", "window", "curtains", "chamber-pot"},
    location = nil,

    exits = {
        north = "hallway",
    },

    on_look = function(self)
        local text = self.description
        text = text .. "\n\n"
        text = text .. "A massive four-poster bed dominates the room, flanked by a small nightstand crusted with candle wax. "
        text = text .. "An oak vanity with an ornate mirror sits against one wall, and a towering wardrobe lurks in the corner like a dark sentinel. "
        text = text .. "A threadbare rug covers the cold stone floor. "
        text = text .. "Heavy curtains are drawn across a window in the far wall. "
        text = text .. "A ceramic chamber pot sits discreetly in the far corner."
        text = text .. "\n\nTo the north, a door stands ajar."
        return text
    end,

    on_enter = function(self)
        return "You step into the bedchamber. The floorboards creak beneath your feet, and the shadows seem to lean in closer."
    end,

    mutations = {},
}
