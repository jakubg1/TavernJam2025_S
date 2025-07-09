local Class = require("com.class")

---@class Level : Class
---@overload fun(): Level
local Level = Class:derive("Level")

local Ground = require("Ground")
local Player = require("Player")
local WaterDrop = require("WaterDrop")

function Level:new()
	self.ground = Ground()
	self.player = Player(100, 800)
    self.enemies = {
        WaterDrop(1000, 800),
        WaterDrop(900, 800),
        WaterDrop(800, 800)
    }

    self.cameraX = 0
end

function Level:update(dt)
    self.player:update(dt)
    for i, enemy in ipairs(self.enemies) do
        enemy:update(dt)
    end
    _Utils.removeDeadObjects(self.enemies)

    self.cameraX = self.player.x
end

function Level:keypressed(key)
    self.player:keypressed(key)
end

function Level:keyreleased(key)
    self.player:keyreleased(key)
end

function Level:draw()
    love.graphics.setColor(0.8, 0.7, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.push()
    love.graphics.translate(-self.cameraX + love.graphics.getWidth() / 2, 0)
    self.ground:draw()
    self.player:draw()
    for i, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
    love.graphics.pop()
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