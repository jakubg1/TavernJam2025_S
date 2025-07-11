local Class = require("com.class")

---@class Level : Class
---@overload fun(): Level
local Level = Class:derive("Level")

local Ground = require("Ground")
local Player = require("Entities.Player")
local CloudGirl = require("Entities.CloudGirl")
local FishBoy = require("Entities.FishBoy")
local WaterDrop = require("Entities.WaterDrop")
local WaterGirl = require("Entities.WaterGirl")
local Shark = require("Entities.Shark")

function Level:new()
    self.grounds = {
        Ground(0, 1675, 30000, 200),
        Ground(2275, 1515, 75, 1, true),
        Ground(2395, 1475, 105, 1, true),
        Ground(2495, 1400, 165, 1, true),
        Ground(2700, 1330, 960, 1, true),
        Ground(3655, 1275, 165, 1, true),
        Ground(3875, 1425, 100, 1, true),
        Ground(4075, 1490, 295, 1, true)
    }
	self.player = Player(100, 1625)
    self.enemies = {
        WaterDrop(2900, 1625),
        WaterDrop(3500, 1625),
        WaterGirl(5300, 1625),
        WaterDrop(5900, 1625),
        WaterGirl(6800, 1625),
        --WaterDrop(1400, 1625),
        --WaterDrop(1300, 1625),
        --WaterGirl(900, 1625),
        --Shark(1500, 1625),
        --Shark(2000, 1625, true),
        --FishBoy(500, 1625),
        --FishBoy(700, 1625, true),
        --CloudGirl(500, 1300)
    }

    self.FG_SCALE = 0.5
    self.BG_SCALE = self.FG_SCALE * 0.81
    self.CAMERA_X_MAX = _LEVEL_FG:getWidth() * self.FG_SCALE
    self.CAMERA_Y_MAX = _LEVEL_FG:getHeight() * self.FG_SCALE
    self.cameraX = 0
    self.cameraY = 0
end

function Level:update(dt)
    self.player:update(dt)
    for i, enemy in ipairs(self.enemies) do
        enemy:update(dt)
    end
    _Utils.removeDeadObjects(self.enemies)

    local w, h = love.graphics.getDimensions()
    self.cameraX = math.min(math.max(self.player.x, w / 2), self.CAMERA_X_MAX - w / 2)
    self.cameraY = math.min(math.max(self.player.y, h / 2), self.CAMERA_Y_MAX - h / 2)
end

function Level:keypressed(key)
    self.player:keypressed(key)
end

function Level:keyreleased(key)
    self.player:keyreleased(key)
end

function Level:draw()
    self:drawBackground()
    self:drawEntities()
    self:drawDebug()
end

function Level:drawBackground()
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(_LEVEL_SKY)
    love.graphics.draw(_LEVEL_BG, (-self.cameraX + w / 2) * 0.75, (-self.cameraY + h / 2 + 200) * 0.75, 0, self.BG_SCALE)
    love.graphics.draw(_LEVEL_FG, -self.cameraX + w / 2, -self.cameraY + h / 2, 0, self.FG_SCALE)
end

function Level:drawEntities()
    local w, h = love.graphics.getDimensions()
    love.graphics.push()
    love.graphics.translate(-self.cameraX + w / 2, -self.cameraY + h / 2)
    for i, ground in ipairs(self.grounds) do
        ground:draw()
    end
    self.player:draw()
    for i, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
    love.graphics.pop()
end

function Level:drawDebug()
    love.graphics.setColor(0, 0, 0)
    local x, y = love.mouse.getPosition()
    local w, h = love.graphics.getDimensions()
    x = x + self.cameraX - w / 2
    y = y + self.cameraY - h / 2
    love.graphics.setFont(_FONT_TMP)
    love.graphics.print(string.format("(%.0f, %.0f)\n(%f, %f)", x, y, self.player.x, self.player.y))
end

return Level