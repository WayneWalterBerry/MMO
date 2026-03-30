-- butcher-knife.lua — Tool with butchering + cutting capabilities (Phase 4 WAVE-1)
-- Primary tool for butchering large creature corpses
return {
    guid = "{9e8ab074-0888-42ab-b871-af7e39e59598}",
    template = "small-item",

    id = "butcher-knife",
    name = "a butcher knife",
    keywords = {"butcher knife", "carving knife", "butchering knife"},
    description = "A broad-bladed knife with a heavy, curved edge and a worn wooden handle. The blade is wide enough to carve through joint and sinew in a single stroke. Dark stains discolour the steel near the tang.",

    material = "steel",
    size = 2,
    weight = 0.6,
    portable = true,
    categories = {"small-item", "tool", "weapon", "sharp", "metal"},

    on_feel = "A thick wooden handle, worn smooth by use. The blade is wide and heavy — the edge catches your thumb when you test it. This is a working tool, not a weapon, but it could serve as both.",
    on_smell = "Old blood and oiled steel. The wooden handle smells of sweat and animal fat.",
    on_listen = "A low ring when tapped — heavier and duller than a fine knife.",
    on_taste = "Iron and stale blood. The handle tastes of sweat-soaked wood.",

    location = nil,

    provides_tool = {"butchering", "cutting_edge"},
    capabilities = {"butchering", "cutting"},
    on_tool_use = {
        consumes_charge = false,
        use_message = "You grip the worn handle and draw the heavy blade.",
    },

    combat = {
        type = "edged",
        force = 4,
        message = "hacks",
        two_handed = false,
    },

    mutations = {},
}
