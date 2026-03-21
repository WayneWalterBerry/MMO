return {
    guid = "b8e37cb6-cba7-48a6-bec9-5bca5f53b73c",
    template = "furniture",
    id = "bed",
    material = "wood",
    name = "a large four-poster bed",
    keywords = {"bed", "four-poster", "poster bed", "four poster", "mattress", "bedframe"},
    room_presence = "A massive four-poster bed dominates the center of the room, its heavy curtains hanging in moth-eaten folds.",
    description = "A massive four-poster bed with a dark wooden frame carved with twisting vines and half-seen faces. The mattress is stuffed thick with straw and wool, sagging slightly in the middle where countless sleepers have left their impression. Heavy curtains hang from the posts, moth-eaten but still grand.",

    on_feel = "A soft mattress beneath thick coverings, warm even in this cold room. The wooden frame is smooth and carved -- your fingers trace twisting vines and half-seen faces in the dark.",
    on_smell = "Musty linen and old straw, with a ghost of lavender from the pillow.",

    size = 10,
    weight = 80,
    categories = {"furniture", "wooden", "large"},
    room_position = "dominates the center of the room",
    portable = false,

    -- Spatial properties
    movable = true,
    moved = false,
    resting_on = "rug",
    push_message = "You brace yourself against the heavy bedframe and push. The four-poster bed scrapes across the flagstones with a grinding shriek of wood on stone, sliding off the threadbare rug.",
    moved_room_presence = "A massive four-poster bed has been shoved to one side of the room, its heavy curtains still swaying.",

    surfaces = {
        top = { capacity = 8, max_item_size = 5, contents = {"pillow", "bed-sheets", "blanket"} },
        underneath = { capacity = 4, max_item_size = 3, contents = {"knife"} },
    },

    location = nil,

    on_look = function(self)
        local text = self.description
        if #self.surfaces.top.contents > 0 then
            text = text .. "\n\nOn the bed:"
            for _, id in ipairs(self.surfaces.top.contents) do
                text = text .. "\n  " .. id
            end
        end
        if #self.surfaces.underneath.contents > 0 then
            text = text .. "\n\nThe bedskirt hangs unevenly, as if something is wedged beneath the mattress."
        end
        return text
    end,

    mutations = {},
}
