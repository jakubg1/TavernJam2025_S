local Class = require("com.class")

---@class Level : Class
---@overload fun(): Level
local Level = Class:derive("Level")

local Ground = require("Ground")
local Player = require("Player")
local WaterDrop = require("WaterDrop")

function Level:new()
	self.ground = Ground()
	self.player = Player()
    self.enemies = {
        WaterDrop(),
        WaterDrop(),
        WaterDrop()
    }
end

function Level:update(dt)
    self.player:update(dt)
    for i, enemy in ipairs(self.enemies) do
        enemy:update(dt)
    end
    _Utils.removeDeadObjects(self.enemies)
end

function Level:keypressed(key)
    self.player:keypressed(key)
end

function Level:keyreleased(key)
    self.player:keyreleased(key)
end

function Level:draw()
    self.ground:draw()
    self.player:draw()
    for i, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
end

function Level:beginContact(a, b, contact)
    self.player:beginContact(a, b, contact)
    for i, enemy in ipairs(self.enemies) do
        enemy:beginContact(a, b, contact)
    end
end

function Level:endContact(a, b, contact)
    self.player:endContact(a, b, contact)
    for i, enemy in ipairs(self.enemies) do
        enemy:endContact(a, b, contact)
    end
end

return Level