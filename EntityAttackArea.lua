local Class = require("com.class")

---@class EntityAttackArea : Class
---@overload fun(entity, offsetX, offsetY, width, height): EntityAttackArea
local EntityAttackArea = Class:derive("EntityAttackArea")

function EntityAttackArea:new(entity, offsetX, offsetY, width, height)
    self.offsetX, self.offsetY = offsetX, offsetY
    self.width, self.height = width, height
    self.x, self.y = entity.x + offsetX, entity.y + offsetY
    self.entity = entity

    self.isAttackArea = true
    _WORLD:add(self, self.x, self.y, width, height)
end

function EntityAttackArea:updatePhysics()
    self.x = self.entity.x + self.offsetX
    self.y = self.entity.y + self.offsetY
    _WORLD:update(self, self.x, self.y, self.width, self.height)
end

function EntityAttackArea:drawHitbox()
    love.graphics.setColor(1, 0, 1)
    local x, y, w, h = _WORLD:getRect(self)
    love.graphics.rectangle("line", x, y, w, h)
end

return EntityAttackArea