return {
    guid = "a1043287-aeeb-4eb7-91c4-d0fcd11f86e3",
    template = "small-item",

    id = "poison-bottle",
    name = "a small glass bottle",
    keywords = {"bottle", "glass bottle", "poison", "vial", "potion", "flask", "small bottle"},
    room_presence = "A small glass bottle sits on the nightstand.",
    description = "A small glass bottle with a skull and crossbones label. The liquid inside is a deep, murky green, shifting like something alive. The cork stopper is wedged tight, but the label's warning is clear -- even to those who cannot read, the skull speaks volumes.",

    on_feel = "Smooth glass, cold to the touch. A cork stopper on top. The bottle is small enough to close your hand around.",
    on_smell = "Even through the cork, you detect something acrid and chemical. Dangerous.",
    on_taste = "BITTER! Searing fire courses down your throat. Your vision blurs...",
    on_taste_effect = "poison",
    on_listen = "Liquid sloshes gently when you tilt it.",

    size = 1,
    weight = 0.4,
    categories = {"small-item", "container", "dangerous", "glass", "fragile"},
    portable = true,

    location = nil,

    on_look = function(self)
        return self.description .. "\n\nThe skull on the label grins at you. This is not a beverage."
    end,

    mutations = {
        drink = {
            becomes = nil,
            requires_uncorked = false,
            message = "You pull the cork and raise the bottle to your lips. The liquid burns like liquid fire. Your vision swims, your knees buckle, and the world goes dark...",
            effect = "poison",
        },
        open = {
            becomes = "poison-bottle-open",
            message = "You pry the cork free with a soft pop. A wisp of sickly green vapor curls from the bottle's mouth.",
        },
    },
}
