local Class = require("com.class")

---@class Level : Class
---@overload fun(data): Level
local Level = Class:derive("Level")

local Ground = require("Ground")
local Player = require("Entities.Player")
local CloudGirl = require("Entities.CloudGirl")
local FishBoy = require("Entities.FishBoy")
local JumpyCloudy = require("Entities.JumpyCloudy")
local WaterDrop = require("Entities.WaterDrop")
local WaterGirl = require("Entities.WaterGirl")
local Shark = require("Entities.Shark")
local NPC = require("Entities.NPC")

function Level:new(data)
    self.data = data
    self:init()

    self.foregroundImg = data.foregroundImg
    self.foregroundScale = data.foregroundScale
    self.backgroundImg = data.backgroundImg
    self.backgroundScale = data.backgroundScale

    self.CAMERA_X_MAX = self.foregroundImg:getWidth() * self.foregroundScale
    self.CAMERA_Y_MAX = self.foregroundImg:getHeight() * self.foregroundScale
    self.cameraX = 0
    self.cameraY = 0

    self.endLevelCutscene = {
        {text = {{1, 1, 1}, "You're a ", {1, 1, 0}, "HUMAN", {1, 1, 1}, " now and you gotta fight like one!"}, img = _SPRITES.player.states.idle[1], side = "right"},
        {text = {{1, 1, 0}, "Congratulations! ", {1, 1, 1}, "You've beaten the first level!"}, img = _SPRITES.player.states.jump[5], side = "left"},
        {text = {{1, 1, 1}, "Now you can go to"}, img = _SPRITES.player.states.jump[5], side = "left"}
    }

    self.START_TIME = 1
    self.DEATH_DELAY = 2
    self.DEATH_TIME = 1
    self.DEATH_BLACKOUT_TIME = 1
    self.DEATH_RADIUS = 1600
end

function Level:init()
    if self.enemies then
        self:destroyEntities()
    end

	self.player = Player(self.data.playerSpawnX, self.data.playerSpawnY)
    self.grounds = {}
    for i, ground in ipairs(self.data.grounds) do
        self.grounds[i] = Ground(ground.x, ground.y, ground.w, ground.h, ground.topOnly)
    end
    self.enemies = {
        --WaterDrop(1400, 1625),
        --WaterDrop(1300, 1625),
        --WaterGirl(900, 1625),
        --Shark(1500, 1625),
        --Shark(2000, 1625, true),
        --FishBoy(500, 1625),
        --FishBoy(700, 1625, true),
        --CloudGirl(500, 1300)
    }
    for i, entity in ipairs(self.data.entities) do
        if entity.type == "WaterDrop" then
            self.enemies[i] = WaterDrop(entity.x, entity.y)
        elseif entity.type == "WaterGirl" then
            self.enemies[i] = WaterGirl(entity.x, entity.y)
        elseif entity.type == "JumpyCloudy" then
            self.enemies[i] = JumpyCloudy(entity.x, entity.y)
        elseif entity.type == "NPC" then
            self.enemies[i] = NPC(entity.x, entity.y, entity.name)
        end
    end

    self.cutsceneLaunched = false

    self.startTime = 0
    self.deathTime = 0
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
    if self.cameraX == self.CAMERA_X_MAX - w / 2 and not self.cutsceneLaunched then
        self.cutsceneLaunched = true
        _CUTSCENE:startCutscene(self.endLevelCutscene)
    end
    if self.startTime then
        self.startTime = self.startTime + dt
        if self.startTime >= self.START_TIME then
            self.startTime = nil
        end
    end
    if self.player.dead then
        self.deathTime = self.deathTime + dt
        if self.deathTime >= self.DEATH_DELAY + self.DEATH_TIME + self.DEATH_BLACKOUT_TIME then
            self:init()
        end
    end
end

function Level:keypressed(key)
    self.player:keypressed(key)
end

function Level:keyreleased(key)
    self.player:keyreleased(key)
end

function Level:destroyEntities()
    self.player:destroy()
    for i, enemy in ipairs(self.enemies) do
        enemy:destroy()
    end
end

function Level:draw()
    self:drawBackground()
    self:drawEntities()
    self:drawCircleVignette()
    self:drawDebug()
end

function Level:drawBackground()
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(_LEVEL_SKY)
    love.graphics.draw(self.backgroundImg, (-self.cameraX + w / 2) * 0.75, (-self.cameraY + h / 2 + 200) * 0.75, 0, self.backgroundScale)
    love.graphics.draw(self.foregroundImg, -self.cameraX + w / 2, -self.cameraY + h / 2, 0, self.foregroundScale)
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

function Level:drawCircleVignette()
    local radius
    if self.startTime then
        radius = _Utils.interpolate2Clamped(0, self.DEATH_RADIUS, 0, self.START_TIME, self.startTime)
    elseif self.deathTime >= self.DEATH_DELAY then
        radius = _Utils.interpolate2Clamped(self.DEATH_RADIUS, 0, self.DEATH_DELAY, self.DEATH_DELAY + self.DEATH_TIME, self.deathTime)
    end
    if not radius then
        return
    end
    local w, h = love.graphics.getDimensions()
    local x, y = self.player.x + self.player.WIDTH / 2 - self.cameraX + w / 2, self.player.y + self.player.HEIGHT / 2 - self.cameraY + h / 2
    love.graphics.stencil(function()
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", x, y, radius)
    end, "replace", 1)
    -- mark only these pixels as the pixels which can be affected
    love.graphics.setStencilTest("notequal", 1)
	love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setStencilTest()
end

function Level:drawDebug()
    love.graphics.setColor(0, 0, 0)
    local x, y = love.mouse.getPosition()
    local w, h = love.graphics.getDimensions()
    x = x + self.cameraX - w / 2
    y = y + self.cameraY - h / 2
    love.graphics.setFont(_FONT)
    love.graphics.print(string.format("(%.0f, %.0f)\n(%f, %f)\nhealth: %s", x, y, self.player.x, self.player.y, self.player.health))
end

return Level