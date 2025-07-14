local Class = require("com.class")

---@class Spritesheet : Class
---@overload fun(data): Spritesheet
local Spritesheet = Class:derive("Spritesheet")

function Spritesheet:new(data)
    self.imageWidth, self.imageHeight = 0, 0
    self.states = {}
    for state, frames in pairs(data.states) do
        self.states[state] = {}
        for i = 1, frames do
            local img = love.graphics.newImage(data.directory .. state .. "_" .. i .. ".png")
            self.states[state][i] = img
            self.imageWidth, self.imageHeight = img:getDimensions()
        end
    end
end

function Spritesheet:getImage(state, frame)
    return assert(self.states[state][frame], string.format("Tried to obtain an illegal frame: %s %s", state, frame))
end

return Spritesheet