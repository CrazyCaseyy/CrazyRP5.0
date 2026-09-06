return {
    enableClient = true, -- disable to create your own client interface
    engineOn = true, -- If true, the engine will be on upon taking the vehicle out.
    debugPoly = false,

    --- called every frame when player is near the garage and there is a separate drop off marker
    --- No-op - the red ground marker this used to draw is gone; the [E]
    --- text prompt (lib.showTextUI, client/main.lua) is the only on-screen
    --- indicator for a parking spot now.
    ---@param coords vector3
    ---@param radius? number
    drawDropOffMarker = function(coords, radius) end,

    --- called every frame when player is near the garage to draw the garage marker
    --- No-op - the green ground marker this used to draw is gone, same
    --- reasoning as drawDropOffMarker above.
    ---@param coords vector3
    ---@param radius? number
    drawGarageMarker = function(coords, radius) end,
}
