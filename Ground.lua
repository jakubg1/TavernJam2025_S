local Class = require("com.class")

---@class Ground : Class
---@overload fun(x, y, width, height, topOnly): Ground
local Ground = Class:derive("Ground")

function Ground:new(x, y, width, height, topOnly)
    self.x, self.y = x, y
    self.width, self.height = width, height
    self.topOnly = topOnly
    self.isGround = true

    _WORLD:add(self, x, y, width, height)
end

function Ground:draw()
    --self:drawRect()
    self:drawHitbox()
end

function Ground:drawRect()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", self.x + 2, self.y + 2, self.width, self.height)
    love.graphics.setColor(0.5, 0.7, 0.2)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

function Ground:drawHitbox()
    if not _HITBOXES then
        return
    end
    love.graphics.setColor(1, 0.5, 0)
    local x, y, w, h = _WORLD:getRect(self)
    love.graphics.rectangle("line", x, y, w, h)
end

return Ground