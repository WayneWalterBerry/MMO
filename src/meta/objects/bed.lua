return {
    id = "bed",
    name = "a large four-poster bed",
    keywords = {"bed", "four-poster", "poster bed", "four poster", "mattress", "bedframe"},
    description = "A massive four-poster bed dominates the room, its dark wooden frame carved with twisting vines and half-seen faces. The mattress is stuffed thick with straw and wool, sagging slightly in the middle where countless sleepers have left their impression. Heavy curtains hang from the posts, moth-eaten but still grand.",

    size = 10,
    weight = 80,
    categories = {"furniture", "wooden", "large"},
    portable = false,

    surfaces = {
        top = { capacity = 8, max_item_size = 5, contents = {"pillow", "bed-sheets", "blanket"} },
        underneath = { capacity = 4, max_item_size = 3, contents = {} },
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
            text = text .. "\n\nPeeking out from underneath:"
            for _, id in ipairs(self.surfaces.underneath.contents) do
                text = text .. "\n  " .. id
            end
        end
        return text
    end,

    mutations = {},
}
