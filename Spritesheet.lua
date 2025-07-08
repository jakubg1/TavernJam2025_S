local Class = require("com.class")

---@class Spritesheet : Class
---@overload fun(image, frameWidth, frameHeight, framesX, framesY): Spritesheet
local Spritesheet = Class:derive("Spritesheet")

---Constructs a new Spritesheet.
---@param image string The path to the image.
---@param frameWidth integer Width of a single frame.
---@param frameHeight integer Height of a single frame.
---@param framesX integer Amount of frames horizontally.
---@param framesY integer Amount of frames vertically.
function Spritesheet:new(image, frameWidth, frameHeight, framesX, framesY)
    self.image = love.graphics.newImage(image)
    self.frameWidth = frameWidth
    self.frameHeight = frameHeight
    self.framesX = framesX
    self.framesY = framesY

    -- Generate frame rects.
    self.frames = {}
    for y = 1, framesY do
        for x = 1, framesX do
            local rect = love.graphics.newQuad(self.frameWidth * (x - 1), self.frameHeight * (y - 1), self.frameWidth, self.frameHeight, self.image)
            table.insert(self.frames, rect)
        end
    end
end

---Draws a frame from this spritesheet.
---@param frame integer The frame index to be drawn.
---@param x number The X position of the frame.
---@param y number The Y position of the frame.
function Spritesheet:drawFrame(frame, x, y)
    love.graphics.draw(self.image, self.frames[frame], x, y)
end

return Spritesheet