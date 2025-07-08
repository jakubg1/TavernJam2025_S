local Class = require("com.class")

---@class Level : Class
---@overload fun(): Level
local Level = Class:derive("Level")

local Ground = require("Ground")
local Player = require("Player")

function Level:new()
	self.ground = Ground()
	self.player = Player()
end

function Level:update(dt)
    self.player:update(dt)
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
end

function Level:beginContact(a, b, contact)
    self.player:beginContact(a, b, contact)
end

function Level:endContact(a, b, contact)
    self.player:endContact(a, b, contact)
end

return Level