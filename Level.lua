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

    self.HEALTH_CHANGE_TIME_MAX = 0.5

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
    self.GAME_OVER_TIME = 10
end

function Level:init()
    if self.enemies then
        self:destroyEntities()
    end

	self.player = Player(self.data.playerSpawnX, self.data.playerSpawnY)
    self.grounds = {}
    for i, ground in ipairs(self.data.grounds) do
        self.grounds[i] = Ground(ground.x, ground.y, ground.w, ground.h, ground.topOnly, ground.nonslidable)
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

    self.healthMeter = self.player.MAX_HEALTH
    self.healthChangeTime = nil

    self.cutsceneLaunched = false

    self.startTime = 0
    self.deathTime = 0
    self.gameOverTime = nil
end

function Level:update(dt)
    self:updateEntities(dt)
    self:updateCamera()
    self:updateHealthMeter(dt)
    self:updateCutscene()
    self:updateStartDeath(dt)
    self:updateGameOver(dt)
end

function Level:updateEntities(dt)
    self.player:update(dt)
    for i, enemy in ipairs(self.enemies) do
        enemy:update(dt)
    end
    _Utils.removeDeadObjects(self.enemies)
end

function Level:updateCamera()
    local w, h = love.graphics.getDimensions()
    self.cameraX = math.min(math.max(self.player.x, w / 2), self.CAMERA_X_MAX - w / 2)
    self.cameraY = math.min(math.max(self.player.y, h / 2), self.CAMERA_Y_MAX - h / 2)
end

function Level:updateHealthMeter(dt)
    if self.healthMeter ~= self.player.health then
        self.healthMeter = self.player.health
        self.healthChangeTime = self.HEALTH_CHANGE_TIME_MAX
    end
    if self.healthChangeTime then
        self.healthChangeTime = math.max(self.healthChangeTime - dt, 0)
        if self.healthChangeTime == 0 then
            self.healthChangeTime = nil
        end
    end
end

function Level:updateCutscene()
    local w, h = love.graphics.getDimensions()
    if self.cameraX == self.CAMERA_X_MAX - w / 2 and not self.cutsceneLaunched then
        self.cutsceneLaunched = true
        _GAME.cutscene:startCutscene(self.endLevelCutscene)
    end
end

function Level:updateStartDeath(dt)
    if self.gameOverTime then
        return
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
            _GAME.lives = _GAME.lives - 1
            if _GAME.lives >= 1 then
                self:init()
            else
                self.gameOverTime = 0
            end
        end
    end
end

function Level:updateGameOver(dt)
    if not self.gameOverTime then
        return
    end
    self.gameOverTime = math.min(self.gameOverTime + dt, self.GAME_OVER_TIME)
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
    self:drawHUD()
    self:drawGameOver()
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
    if self.deathTime >= self.DEATH_DELAY then
        x = x + (self.player.direction == "left" and 60 or -60)
        y = y + 30
    end
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

function Level:drawHUD()
    local alpha = self.gameOverTime and _Utils.interpolateClamped(1, 0, self.gameOverTime * 2)
    if alpha == 0 then
        return
    end
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(_LIVES[math.max(_GAME.lives, 1)], 0, 0, 0, 0.2)
    local flash = self.healthChangeTime and self.healthChangeTime % 0.25 >= 0.125
    if flash then
        love.graphics.setShader(_WHITE_SHADER)
    end
    for i = 1, math.ceil(self.player.MAX_HEALTH / 4) do
        local sprite = _HEARTS[math.min(math.max(self.healthMeter - (i - 1) * 4, 0), 4)]
        love.graphics.draw(sprite, 150 + (i - 1) * 70, 25, 0, 0.12)
    end
    if flash then
        love.graphics.setShader()
    end
end

function Level:drawGameOver()
    if not self.gameOverTime then
        return
    end
    local w, h = love.graphics.getDimensions()
    local x = w / 2 - _FONT:getWidth("Game Over") / 2
    local y = h / 2 - _FONT:getHeight() / 2
    local alpha = _Utils.interpolate2Clamped(0, 1, 0.5, 2, self.gameOverTime)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print("Game Over", x, y)
end

function Level:drawDebug()
    if not _HITBOXES then
        return
    end
    love.graphics.setColor(0, 0, 0)
    local x, y = love.mouse.getPosition()
    local w, h = love.graphics.getDimensions()
    x = x + self.cameraX - w / 2
    y = y + self.cameraY - h / 2
    love.graphics.setFont(_FONT)
    love.graphics.print(string.format("(%.0f, %.0f)\n(%f, %f)\nhealth: %s", x, y, self.player.x, self.player.y, self.player.health))
end

return Level