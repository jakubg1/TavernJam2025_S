local Class = require("com.class")

---@class Ground : Class
---@overload fun(): Ground
local Ground = Class:derive("Ground")

---Temporary ground until we have proper Tiled support.
function Ground:new()
    self.x, self.y = 600, 800
    self.width, self.height = 1000, 10

    self.physics = {}
    self.physics.body = love.physics.newBody(_WORLD, self.x, self.y, "static")
    self.physics.shape = love.physics.newRectangleShape(self.width, self.height)
    self.physics.fixture = love.physics.newFixture(self.physics.body, self.physics.shape)
end

function Ground:draw()
    love.graphics.setColor(0, 0.5, 0)
    love.graphics.rectangle("fill", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height)
end

return Ground