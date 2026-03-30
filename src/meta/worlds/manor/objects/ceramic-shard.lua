-- ceramic-shard.lua — Debris from shattered ceramic objects
-- Spawned by on_drop fragility system when ceramic objects break.
-- See: Issue #56, docs/objects/chamber-pot.md
return {
    guid = "{c7d3a1f0-8e52-4b19-a6c1-3f9d0e7b5a24}",
    template = "small-item",
    id = "ceramic-shard",
    name = "a ceramic shard",
    material = "ceramic",
    keywords = {"shard", "ceramic", "ceramic shard", "fragment", "piece", "pottery"},
    description = "A jagged piece of glazed ceramic. The blue-and-white pattern is still visible on one side, though the edges are raw and sharp where it snapped.",

    on_feel = "Sharp edges where the glaze broke. Smooth on the painted side.",
    on_taste = "Dusty clay and old glaze. Not recommended.",

    size = 1,
    weight = 0.2,
    portable = true,
    categories = {"ceramic", "sharp", "fragile", "debris"},

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
