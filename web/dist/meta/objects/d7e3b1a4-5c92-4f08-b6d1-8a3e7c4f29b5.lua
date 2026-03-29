-- bear-trap.lua — Touch-triggered injury object with disarm mechanics
-- Decision: D-EFFECTS-PIPELINE, D-INJURY001, D-INJURY002
-- States: set (armed) → triggered (snapped) → disarmed (safe)
-- Contact pipeline: on_take/on_touch → inflict_injury → crushing-wound
-- Visible by default — teaches "observe first" pattern.
--
-- Effect routing (all paths via effects.process):
--   take (armed)  → trans.effect  → inflict_injury(crushing-wound, damage=15)
--   touch (armed) → trans.effect  → inflict_injury(crushing-wound, damage=15)
--   feel (armed)  → on_feel_effect → inflict_injury(crushing-wound, damage=15)
--   disarm         → guard blocks pipeline if skill check fails
return {
    guid = "{d7e3b1a4-5c92-4f08-b6d1-8a3e7c4f29b5}",
    template = "furniture",

    id = "bear-trap",
    material = "iron",
    keywords = {"trap", "bear trap", "bear-trap", "jaws", "metal trap", "rusted trap", "iron trap"},
    size = 3,
    weight = 4.5,
    categories = {"trap", "dangerous", "hazard", "metal", "spring-mechanism"},
    portable = false,
    room_position = "on the floor",

    -- Effects pipeline flag (D-EFFECTS-PIPELINE) — all effect declarations
    -- on this object are structured tables routed through effects.process().
    effects_pipeline = true,

    -- Trap metadata (drives contact pipeline)
    is_trap = true,
    is_armed = true,
    is_dangerous = true,
    trap_type = "spring-jaw",
    trap_injury_type = "crushing-wound",
    trap_damage_amount = 15,

    -- Initial state (set / armed)
    name = "a bear trap",
    description = "A rusted iron bear trap with powerful spring-loaded jaws. The teeth are serrated and slightly parted, the mechanism coiled tight with lethal patience. Rust flakes from the hinges, but the springs are sound. This thing could break bones.",
    room_presence = "A rusted bear trap lies on the floor, its iron jaws slightly parted.",
    on_feel = "SNAP! The jaws clamp shut on your hand with a sickening crack!",
    on_smell = "Rust and old blood. This trap has a history.",
    on_listen = "A faint metallic creak. The springs are straining, coiled tight.",

    -- Sound events (WAVE-1 Track 1A)
    sounds = {
        on_state_triggered = "trap-snap.opus",
        on_verb_disarm = "trap-disarm.opus",
    },

    location = nil,

    -- FSM
    initial_state = "set",
    _state = "set",

    states = {
        -- ── SET: Armed and dangerous ──
        set = {
            name = "a bear trap",
            description = "A rusted iron bear trap with powerful spring-loaded jaws. The teeth are serrated and slightly parted, the mechanism coiled tight with lethal patience. Rust flakes from the hinges, but the springs are sound. This thing could break bones.",
            room_presence = "A rusted bear trap lies on the floor, its iron jaws slightly parted.",

            on_feel = "SNAP! The jaws clamp shut on your hand with a sickening crack!",
            -- Pipeline-routed via effects.process() — contact injury on feel
            on_feel_effect = {
                type = "inflict_injury",
                injury_type = "crushing-wound",
                source = "bear-trap",
                location = "hand",
                damage = 15,
                message = "The trap's iron jaws crush your hand. Pain whites out your vision.",
                pipeline_routed = true,
            },

            on_smell = "Rust and old blood. This trap has a history.",
            on_listen = "A faint metallic creak. The springs are straining, coiled tight.",
            on_taste = "You are not putting your mouth near that.",

            on_look = function(self)
                return self.description .. "\n\nThe jaws are open and waiting. The coiled springs glint dully. Everything about this says: do not touch."
            end,

            is_dangerous = true,
            is_armed = true,
        },

        -- ── TRIGGERED: Snapped, already fired ──
        triggered = {
            name = "a sprung bear trap",
            description = "The bear trap has snapped shut with violent force. The serrated jaws are clamped together, and blood stains the rusted metal. The spring is now slack -- the trap has spent its energy.",
            room_presence = "A sprung bear trap lies on the floor, its jaws clamped shut. Blood stains the metal.",

            on_feel = "The mechanism is now slack. The spring has released its energy. The jaws won't snap again without being reset.",
            on_smell = "Blood and rust. The sharp tang of iron and injury.",
            on_listen = "Silence. The coiled tension is gone.",
            on_taste = "Blood and rust. Don't.",

            on_look = function(self)
                return self.description .. "\n\nThe jaws are locked together. Hair and blood are caught between the teeth. The spring is exhausted."
            end,

            is_dangerous = false,
            is_armed = false,
            is_sprung = true,
        },

        -- ── DISARMED: Safe to handle ──
        disarmed = {
            name = "a disarmed bear trap",
            description = "The bear trap has been carefully disarmed. The springs are neutralized and the jaws locked open. It is now a harmless piece of rusted iron.",
            room_presence = "A disarmed bear trap sits on the floor, its jaws locked safely open.",

            on_feel = "Completely inert. No tension. No danger. Just cold iron.",
            on_smell = "Rust and old metal. The blood smell is fading.",
            on_listen = "Silent. The mechanism is dead.",

            on_look = function(self)
                return self.description .. "\n\nThe springs have been removed or neutralized. You could carry this without fear."
            end,

            is_dangerous = false,
            is_armed = false,
            is_disarmed = true,
            portable = true,
        },
    },

    transitions = {
        -- ── Contact trigger: Player takes armed trap ──
        {
            from = "set", to = "triggered", verb = "take",
            aliases = {"grab", "pick up", "get"},
            message = "You reach for the trap. The moment your fingers touch the mechanism, the jaws SNAP shut with a violent CRACK! Pain shoots through your hand as iron teeth bite deep into flesh and bone.",
            -- Single structured effect for pipeline (effects.process normalizes)
            effect = {
                type = "inflict_injury",
                injury_type = "crushing-wound",
                source = "bear-trap",
                location = "hand",
                damage = 15,
                message = "The trap's iron jaws crush your hand. The pain is blinding.",
            },
            -- Full pipeline chain for atomic processing (D-EFFECTS-PIPELINE)
            -- Engine falls back to effect + mutate if pipeline_effects not consumed.
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "crushing-wound",
                  source = "bear-trap", location = "hand", damage = 15,
                  message = "The trap's iron jaws crush your hand. The pain is blinding." },
                { type = "narrate",
                  message = "Blood drips from between the rusted teeth. Your hand is trapped." },
                { type = "mutate", target = "self", field = "is_armed", value = false },
                { type = "mutate", target = "self", field = "is_sprung", value = true },
                { type = "mutate", target = "self", field = "is_dangerous", value = false },
            },
            -- FSM-level mutations (applied by fsm.transition → apply_mutations)
            mutate = {
                is_armed = false,
                is_sprung = true,
                is_dangerous = false,
                keywords = { add = "sprung", remove = "ready" },
                categories = { remove = "dangerous", add = "evidence" },
            },
        },

        -- ── Contact trigger: Player touches armed trap ──
        {
            from = "set", to = "triggered", verb = "touch",
            aliases = {"handle", "poke", "prod"},
            message = "You reach toward the trap. Your fingers barely brush the pressure plate when the jaws SNAP shut, crushing your hand in a vice of rusted iron. You scream.",
            -- Single structured effect for pipeline (effects.process normalizes)
            effect = {
                type = "inflict_injury",
                injury_type = "crushing-wound",
                source = "bear-trap",
                location = "hand",
                damage = 15,
                message = "Iron jaws clamp shut on your fingers with bone-breaking force.",
            },
            -- Full pipeline chain for atomic processing (D-EFFECTS-PIPELINE)
            -- Engine falls back to effect + mutate if pipeline_effects not consumed.
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "crushing-wound",
                  source = "bear-trap", location = "hand", damage = 15,
                  message = "Iron jaws clamp shut on your fingers with bone-breaking force." },
                { type = "narrate",
                  message = "The trap's teeth are buried in your flesh. You can feel the pressure on your bones." },
                { type = "mutate", target = "self", field = "is_armed", value = false },
                { type = "mutate", target = "self", field = "is_sprung", value = true },
                { type = "mutate", target = "self", field = "is_dangerous", value = false },
            },
            -- FSM-level mutations (applied by fsm.transition → apply_mutations)
            mutate = {
                is_armed = false,
                is_sprung = true,
                is_dangerous = false,
                keywords = { add = "sprung", remove = "ready" },
                categories = { remove = "dangerous", add = "evidence" },
            },
        },

        -- ── Disarm: Requires tool + skill ──
        {
            from = "triggered", to = "disarmed", verb = "disarm",
            aliases = {"disable", "defuse", "neutralize"},
            requires_tool = "thin_tool",
            guard = function(obj, context)
                return context and context.player
                    and context.player.has_skill
                    and context.player.has_skill("lockpicking")
            end,
            fail_message = "You examine the trap mechanism, but you don't understand how the springs connect. You need knowledge of locks and mechanisms to disarm this.",
            message = "You examine the trap's spring mechanism carefully. With your lockpick, you find the release pin and apply gentle pressure. The tension eases. The jaws go slack. The trap is disarmed.",
            mutate = {
                is_disarmed = true,
                portable = true,
                keywords = { add = "disarmed", remove = "sprung" },
                categories = { remove = "hazard", add = "trophy" },
            },
        },

        -- ── Safe take: Player takes triggered (non-dangerous) trap ──
        {
            from = "triggered", to = "triggered", verb = "take",
            aliases = {"grab", "pick up", "get"},
            message = "You carefully lift the sprung trap. It's heavy, and blood stains the jaws, but it won't bite again.",
            mutate = {
                portable = true,
            },
        },

        -- ── Safe take: Player takes disarmed trap ──
        {
            from = "disarmed", to = "disarmed", verb = "take",
            aliases = {"grab", "pick up", "get"},
            message = "You pick up the disarmed trap. It's just dead weight now -- rusted iron and slack springs.",
        },
    },

    -- GOAP prerequisites (for planner) — warns hints per D-EFFECTS-PIPELINE §3.6
    prerequisites = {
        disarm = {
            requires_state = "triggered",
            requires_skill = "lockpicking",
            requires_tool = "thin_tool",
        },
        take = {
            -- In "set" state: will trigger injury (trap fires)
            -- In "triggered" or "disarmed" state: safe to take
            warns = { "injury", "crushing-wound" },
        },
        touch = {
            warns = { "injury", "crushing-wound" },
        },
        feel = {
            warns = { "injury", "crushing-wound" },
        },
    },

    mutations = {},
}
