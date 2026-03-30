-- bandage.lua — Reusable treatment object with FSM
-- States: clean → applied (to injury) → soiled (after removal) → clean (after wash)
-- Cycle: clean → applied via APPLY, applied → soiled via REMOVE, soiled → clean via WASH
-- Reusable resource: attaches to one injury at a time, dual-binds with injury instance
-- Wash verb (#112) returns soiled bandage to clean state via water_source
return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{5869a474-8d70-4efb-85d3-108e46325907}",
    template = "small-item",
    id = "bandage",
    name = "a clean linen bandage",
    keywords = {"bandage", "wrap", "dressing", "cloth wrap", "linen"},
    description = "A strip of clean cloth, suitable for bandaging wounds.",

    -- ═══════════════════════════════════════════════════════════
    -- PHYSICAL PROPERTIES
    -- ═══════════════════════════════════════════════════════════
    size = 1,
    weight = 0.1,
    portable = true,
    material = "linen",
    categories = {"medical", "fabric", "linen", "small"},

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    -- ═══════════════════════════════════════════════════════════
    -- TREATMENT PROPERTIES
    -- ═══════════════════════════════════════════════════════════
    reusable = true,
    cures = { "bleeding", "minor-cut" },
    healing_boost = 2,
    applied_to = nil,

    -- ═══════════════════════════════════════════════════════════
    -- FSM
    -- ═══════════════════════════════════════════════════════════
    initial_state = "clean",
    _state = "clean",

    states = {
        -- ── CLEAN: Ready to apply ──
        clean = {
            name = "a clean linen bandage",
            description = "A strip of white linen cloth, tightly rolled and ready for use.",
            on_feel = "A rolled cloth strip, soft and tightly wound. The weave is fine and even.",
            on_smell = "Clean linen. A trace of lye soap.",
            on_listen = "Silent.",
            on_taste = "Dry cloth fiber, faintly bitter from lye.",
            on_look = function(self)
                return self.description
            end,
        },

        -- ── APPLIED: Bound to a specific injury instance ──
        applied = {
            name = "an applied bandage",
            description = "This bandage is wrapped tightly around a wound, pressing firm against the skin.",
            on_feel = "Taut cloth under tight pressure. Damp where blood has seeped through the weave.",
            on_smell = "Copper tang of fresh blood through linen.",
            on_listen = "Silent.",
            on_taste = "You shouldn't put that in your mouth while it's on a wound.",
            in_use = true,
            on_look = function(self)
                return self.description
            end,
        },

        -- ── SOILED: Used, removable, washable ──
        soiled = {
            name = "a soiled bandage",
            description = "A blood-stained bandage, damp and discolored but still intact.",
            on_feel = "Damp, sticky cloth. Crusted with dried blood at the edges, tacky in the center.",
            on_smell = "Strong smell of old blood. Iron and sweat.",
            on_listen = "Silent.",
            on_taste = "Metallic, foul. Blood and grime.",
            on_look = function(self)
                return self.description
            end,
        },
    },

    transitions = {
        -- ── clean → applied: Player applies bandage to an injury ──
        {
            from = "clean", to = "applied",
            verb = "apply",
            aliases = {"use", "wrap", "bind", "bandage"},
            requires_target_injury = true,
            message = "You press the bandage firmly against the wound and wrap it tight. The bleeding slows.",
            mutate = {
                applied_to = "target_injury_instance_id",
            },
        },

        -- ── applied → soiled: Player removes bandage from injury ──
        {
            from = "applied", to = "soiled",
            verb = "remove",
            aliases = {"unwrap", "take off", "peel"},
            message = "You carefully unwrap the bandage. It comes away stained with blood.",
            mutate = {
                applied_to = nil,
            },
        },

        -- ── soiled → clean: Player washes the bandage ──
        {
            from = "soiled", to = "clean",
            verb = "wash",
            aliases = {"clean", "rinse", "launder"},
            requires_tool = "water_source",
            message = "You rinse the bandage in the water. The blood washes out, leaving the cloth damp but clean.",
            fail_message = "You need water to wash this.",
        },
    },

    mutations = {},
}
