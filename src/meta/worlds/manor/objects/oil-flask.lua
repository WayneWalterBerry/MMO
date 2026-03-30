-- oil-flask.lua — Consumable fuel source (Storage Cellar)
-- Used to fuel the oil lantern (Puzzle 010: Light Upgrade)
return {
    guid = "{ae5df831-7c42-4b19-8e60-f9a3c7d21b54}",
    template = "small-item",

    id = "oil-flask",
    material = "ceramic",
    keywords = {"flask", "oil flask", "oil", "lamp oil", "fuel", "ceramic flask"},
    size = 1,
    weight = 0.8,
    categories = {"consumable", "fuel", "small"},
    portable = true,

    name = "a small ceramic oil flask",
    description = "A small ceramic flask, stoppered with a cork and sealed with old wax. When you tilt it, liquid sloshes inside -- thick, heavy, unmistakably oil. The flask is glazed dark brown, cool and smooth to the touch. A label once pasted to the side has long since crumbled away, leaving only a ghost of glue.",
    room_presence = "A small ceramic flask sits on a shelf, dark and unassuming.",
    on_feel = "Smooth ceramic, cool and heavy for its size. A cork stopper sealed with old wax. Liquid shifts inside when you tilt it -- thick and sluggish. Oil.",
    on_smell = "Through the wax seal: nothing. But the cork is old. Break the seal and you'd smell lamp oil.",
    on_listen = "A thick slosh when shaken. Heavy liquid -- oil, not water.",

    location = nil,

    provides_tool = "lamp-oil",

    on_drink_reject = "You gag on the thick, acrid oil. That's lamp fuel, not drink. You spit it out, grimacing.",

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
