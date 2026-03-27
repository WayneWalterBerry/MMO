-- antidote-vial.lua — Glass vial of antidote, cures spider venom
-- Small-item, portable, consumable cure for envenomation.
return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{87ec6b50-d0eb-4a1c-ae34-8b200625ccd0}",
    template = "small-item",
    id = "antidote-vial",
    name = "a small glass vial",
    keywords = {"antidote", "vial", "cure", "antidote vial", "glass vial"},
    description = "A small glass vial filled with a murky green liquid. A faded label reads 'ANTIDOTE' in cramped script.",

    -- ═══════════════════════════════════════════════════════════
    -- PHYSICAL PROPERTIES
    -- ═══════════════════════════════════════════════════════════
    size = "tiny",
    portable = true,
    material = "glass",

    -- ═══════════════════════════════════════════════════════════
    -- SENSORY
    -- ═══════════════════════════════════════════════════════════
    on_feel = "Cool glass, smooth and stoppered with a cork.",
    on_smell = "Through the glass, nothing. But you suspect it would be pungent.",
    on_listen = "A faint slosh when tilted.",
    on_taste = "You haven't opened it yet.",
    room_presence = "A small glass vial sits here, its contents murky green.",

    -- ═══════════════════════════════════════════════════════════
    -- CURE PROPERTIES
    -- ═══════════════════════════════════════════════════════════
    is_consumable = true,
    consumable_type = "antidote",
    cures = {"spider-venom"},
}
