return {
    id = "window",
    name = "a leaded glass window",
    keywords = {"window", "glass", "pane", "leaded glass"},
    room_presence = "A tall leaded glass window is set deep in the stone of the far wall.",
    description = "A tall window of diamond-paned leaded glass, set deep in the stone wall. The glass is thick and uneven, warping the world outside into an impressionist fever dream. Through it, you can make out the vague shapes of rooftops and, beyond them, something that might be a forest or might be the edge of the world. The window is latched shut.",

    size = 5,
    weight = 20,
    categories = {"fixture", "glass", "fragile"},
    room_position = "is set deep in the stone of the far wall",
    portable = false,
    container = false,

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {
        open = {
            becomes = "window-open",
        },
    },
}
