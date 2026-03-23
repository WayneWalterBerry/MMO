-- poison-bottle.lua — Composite FSM-managed consumable with effects pipeline
-- Decision: D-EFFECTS-PIPELINE, D-INJURY001
-- States: sealed → open → empty (terminal)
-- Parts: cork (detachable), label (readable, non-detachable)
--
-- Effect routing (all paths via effects.process):
--   drink  → trans.effect  → inflict_injury(poisoned-nightshade, damage=10)
--   taste  → on_taste_effect → inflict_injury(poisoned-nightshade, damage=5)
--   pour   → (no effect — safe disposal path)
--
-- The cork is a PART that becomes an independent object when removed.
return {
    guid = "{a1043287-aeeb-4eb7-91c4-d0fcd11f86e3}",
    template = "small-item",

    id = "poison-bottle",
    material = "glass",
    keywords = {"bottle", "glass bottle", "poison", "vial", "potion", "flask", "small bottle", "poison bottle", "poison-bottle"},
    size = 1,
    weight = 0.4,
    categories = {"small-item", "container", "dangerous", "glass", "fragile", "consumable", "liquid", "poison"},
    portable = true,

    -- Effects pipeline flag (D-EFFECTS-PIPELINE) — all effect declarations
    -- on this object are structured tables routed through effects.process().
    effects_pipeline = true,

    -- Consumable metadata (drives consumption pipeline)
    is_consumable = true,
    consumable_type = "liquid",
    poison_type = "nightshade",
    poison_severity = "lethal",

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
            on_smell = "Acrid fumes rise from the uncorked bottle. Chemical, and unmistakably poisonous. Your eyes water.",
            on_taste = "BITTER! Searing fire courses down your throat. Your vision blurs...",
            -- Pipeline-routed via effects.process() — sub-lethal warning dose
            on_taste_effect = {
                type = "inflict_injury",
                injury_type = "poisoned-nightshade",
                source = "poison-bottle",
                damage = 5,
                message = "The taste alone is enough. Burning sweetness sears your tongue and throat.",
                pipeline_routed = true,
            },
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
            requires_free_hands = true,
            message = "You pry the cork free with a soft pop. A wisp of sickly green vapor curls from the bottle's mouth.",
            mutate = {
                weight = function(w) return w - 0.05 end,
                keywords = { add = "uncorked" },
            },
        },
        -- Detach cork (sealed state) — creates cork object
        {
            from = "sealed", to = "open", verb = "detach_part",
            trigger = "detach_part",
            part_id = "cork",
            requires_free_hands = true,
            message = "You twist and pull the cork free with a soft pop. A wisp of sickly green vapor curls from the bottle's mouth.",
            mutate = {
                weight = function(w) return w - 0.05 end,
                keywords = { add = "uncorked" },
            },
        },
        {
            from = "open", to = "empty", verb = "drink",
            aliases = {"quaff", "sip", "gulp", "consume"},
            message = "You raise the bottle to your lips. The liquid burns like liquid fire. Your vision swims, your knees buckle, and the world tilts sideways...",
            -- Single structured effect for pipeline (effects.process normalizes)
            effect = {
                type = "inflict_injury",
                injury_type = "poisoned-nightshade",
                source = "poison-bottle",
                damage = 10,
                message = "A bitter, almost sweet taste burns down your throat. Your heart begins to race.",
            },
            -- Full pipeline chain for atomic processing (D-EFFECTS-PIPELINE)
            -- Engine falls back to effect + mutate if pipeline_effects not consumed.
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "poisoned-nightshade",
                  source = "poison-bottle", damage = 10,
                  message = "A bitter, almost sweet taste burns down your throat. Your heart begins to race." },
                { type = "mutate", target = "self", field = "weight", value = 0.1 },
                { type = "mutate", target = "self", field = "is_consumable", value = false },
            },
            -- FSM-level mutations (applied by fsm.transition → apply_mutations)
            mutate = {
                weight = 0.1,
                is_consumable = false,
                categories = { remove = "dangerous" },
                keywords = { add = "empty" },
            },
        },
        {
            from = "open", to = "empty", verb = "pour",
            aliases = {"spill", "dump"},
            message = "You tip the bottle. The green liquid pours out, hissing where it touches the stone floor. A thin vapor rises, and then it is gone.",
            mutate = {
                weight = 0.1,
                is_consumable = false,
                categories = { remove = "dangerous" },
                keywords = { add = "empty" },
            },
        },
    },

    -- GOAP prerequisites (for planner) — warns hints per D-EFFECTS-PIPELINE §3.6
    prerequisites = {
        drink = { requires_state = "open", warns = { "injury", "poisoned-nightshade" } },
        pour = { requires_state = "open" },
        open = { requires_state = "sealed", requires_free_hands = true },
        uncork = { requires_state = "sealed", requires_free_hands = true },
        taste = { warns = { "injury", "poisoned-nightshade" } },
    },

    -- === COMPOSITE PARTS ===
    parts = {
        cork = {
            id = "poison-cork",
            detachable = true,
            reversible = false,
            keywords = {"cork", "cork stopper", "stopper", "plug", "bottle cork"},
            name = "a cork stopper",
            description = "A small cork stopper, slightly stained from the bottle's contents. It smells faintly of chemicals.",
            size = 0.5,
            weight = 0.05,
            categories = {"small-item"},
            portable = true,
            carries_contents = false,
            on_feel = "Cork -- rough, slightly compressed, light as air.",
            on_smell = "Wine-soaked cork with a chemical tang.",
            detach_verbs = {"pull", "remove", "uncork", "unstop", "unseal", "yank", "extract", "pop"},
            detach_message = "You twist and pull the cork free with a soft pop. A wisp of sickly green vapor curls from the bottle's mouth.",

            factory = function(parent)
                return {
                    guid = "cork-inst-" .. math.random(100000, 999999),
                    id = "poison-cork",
                    keywords = {"cork", "cork stopper", "stopper", "plug"},
                    name = "a cork stopper",
                    description = "A small cork stopper, slightly stained. It's roughly cylindrical, about an inch long. Watertight -- could be useful for plugging something.",
                    size = 0.5,
                    weight = 0.05,
                    categories = {"small-item"},
                    portable = true,
                    on_feel = "Cork -- rough, slightly compressed, light as air.",
                    on_smell = "Wine-soaked cork with a faint chemical tang.",
                    on_taste = "Cork. Slightly bitter. You've tasted worse.",
                    on_listen = "Silence. It's a cork.",
                    on_look = function(self)
                        return self.description
                    end,
                    location = parent.location,
                }
            end,
        },

        label = {
            id = "poison-label",
            detachable = false,
            readable = true,
            keywords = {"label", "writing", "text", "warning", "warning text", "skull", "crossbones"},
            name = "a label",
            description = "A small paper label pasted to the bottle. A skull and crossbones is printed above cramped text.",
            readable_text = "POISON -- Belladonna extract. Lethal if ingested. No known antidote in common supply. Handle with extreme care. If consumed, seek the nightshade-specific antidote immediately.",
            on_feel = "Thin paper, slightly damp from condensation. The edges curl.",
            on_smell = "Paper and old glue.",
            read_verbs = {"read", "examine"},
        },
    },
}
