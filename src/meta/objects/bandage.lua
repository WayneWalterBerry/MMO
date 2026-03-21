-- bandage.lua — Reusable treatment object with FSM
-- States: clean → applied (to injury) → soiled (after removal)
-- Cycle: clean → applied via APPLY, applied → soiled via REMOVE, soiled → clean via WASH
-- Reusable resource: attaches to one injury at a time, dual-binds with injury instance
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
    material = "fabric",
    categories = {"medical", "fabric", "small"},

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
            description = "A strip of clean cloth, suitable for bandaging wounds.",
            on_feel = "A rolled cloth strip, soft and tightly wound. It smells faintly of lye.",
            on_smell = "Clean linen. A trace of lye soap.",
            on_look = function(self)
                return self.description
            end,
        },

        -- ── APPLIED: Bound to a specific injury instance ──
        applied = {
            name = "an applied bandage",
            description = "This bandage is wrapped around a wound.",
            on_feel = "Taut cloth, damp where blood has seeped through.",
            on_smell = "Blood and linen.",
            in_use = true,
            on_look = function(self)
                return self.description
            end,
        },

        -- ── SOILED: Used, removable, washable ──
        soiled = {
            name = "a soiled bandage",
            description = "A used bandage, stained but still intact.",
            on_feel = "Damp, stiff cloth. Crusted with dried blood.",
            on_smell = "Old blood and sweat.",
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
