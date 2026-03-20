-- poison-bottle.lua — FSM-managed consumable
-- States: sealed → open → empty (terminal)
return {
    guid = "a1043287-aeeb-4eb7-91c4-d0fcd11f86e3",

    id = "poison-bottle",
    keywords = {"bottle", "glass bottle", "poison", "vial", "potion", "flask", "small bottle", "poison bottle", "poison-bottle"},
    size = 1,
    weight = 0.4,
    categories = {"small-item", "container", "dangerous", "glass", "fragile"},
    portable = true,

    -- Initial state (sealed)
    name = "a small glass bottle",
    description = "A small glass bottle with a skull and crossbones label. The liquid inside is a deep, murky green, shifting like something alive. The cork stopper is wedged tight, but the label's warning is clear -- even to those who cannot read, the skull speaks volumes.",
    room_presence = "A small glass bottle sits on the nightstand.",
    on_feel = "Smooth glass, cold to the touch. A cork stopper on top. The bottle is small enough to close your hand around.",
    on_smell = "Even through the cork, you detect something acrid and chemical. Dangerous.",
    on_listen = "Liquid sloshes gently when you tilt it.",

    location = nil,

    -- FSM
    initial_state = "sealed",
    _state = "sealed",

    states = {
        sealed = {
            name = "a small glass bottle",
            description = "A small glass bottle with a skull and crossbones label. The liquid inside is a deep, murky green, shifting like something alive. The cork stopper is wedged tight, but the label's warning is clear -- even to those who cannot read, the skull speaks volumes.",
            room_presence = "A small glass bottle sits on the nightstand.",
            on_feel = "Smooth glass, cold to the touch. A cork stopper on top. The bottle is small enough to close your hand around.",
            on_smell = "Even through the cork, you detect something acrid and chemical. Dangerous.",
            on_taste = "You lick the outside of the bottle. Glass. Not helpful.",
            on_listen = "Liquid sloshes gently when you tilt it.",

            on_look = function(self)
                return self.description .. "\n\nThe skull on the label grins at you. This is not a beverage."
            end,
        },

        open = {
            name = "an open glass bottle",
            description = "A small glass bottle, its cork removed. The murky green liquid inside swirls lazily, releasing thin wisps of sickly vapor. The skull and crossbones label grins up at you.",
            room_presence = "An uncorked glass bottle sits here, wisps of green vapor curling from its mouth.",
            on_feel = "Smooth glass, cold to the touch. The mouth of the bottle is open. Your fingers tingle where the vapor touches them.",
            on_smell = "Acrid, chemical, and unmistakably poisonous. Your eyes water.",
            on_taste = "BITTER! Searing fire courses down your throat. Your vision blurs...",
            on_taste_effect = "poison",
            on_listen = "A faint hissing from the liquid, as if it were breathing.",

            on_look = function(self)
                return self.description .. "\n\nGreen vapor curls from the open mouth. Everything about this screams: do not drink."
            end,
        },

        empty = {
            name = "an empty glass bottle",
            description = "A small glass bottle, empty now. A residue of sickly green clings to the inside walls, and the skull label seems to smirk at the bottle's emptiness.",
            room_presence = "An empty glass bottle lies here.",
            on_feel = "Smooth glass, slightly sticky inside. Empty.",
            on_smell = "A faint chemical residue. The danger has passed -- or been consumed.",
            on_listen = "Silence. Nothing sloshes.",
            terminal = true,

            on_look = function(self)
                return self.description
            end,
        },
    },

    transitions = {
        {
            from = "sealed", to = "open", verb = "open",
            aliases = {"uncork", "unstop"},
            message = "You pry the cork free with a soft pop. A wisp of sickly green vapor curls from the bottle's mouth.",
        },
        {
            from = "open", to = "empty", verb = "drink",
            aliases = {"quaff", "sip", "gulp"},
            message = "You raise the bottle to your lips. The liquid burns like liquid fire. Your vision swims, your knees buckle, and the world goes dark...",
            effect = "poison",
        },
        {
            from = "open", to = "empty", verb = "pour",
            aliases = {"spill", "dump"},
            message = "You tip the bottle. The green liquid pours out, hissing where it touches the stone floor. A thin vapor rises, and then it is gone.",
        },
    },
}
