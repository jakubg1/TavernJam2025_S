local Class = require("com.class")

---@class Ground : Class
---@overload fun(x, y, width, height): Ground
local Ground = Class:derive("Ground")

---Temporary ground until we have proper Tiled support.
function Ground:new(x, y, width, height)
    self.x, self.y = x, y
    self.width, self.height = width, height

    self.physics = {}
    self.physics.body = love.physics.newBody(_WORLD, self.x, self.y, "static")
    self.physics.shape = love.physics.newRectangleShape(self.width, self.height)
    self.physics.fixture = love.physics.newFixture(self.physics.body, self.physics.shape)
end

function Ground:draw()
    love.graphics.setColor(0.5, 0.7, 0.2)
    love.graphics.rectangle("fill", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height)
end

return Ground