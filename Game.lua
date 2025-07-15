local Class = require("com.class")

---@class Game : Class
---@overload fun(): Game
local Game = Class:derive("Game")

local Cutscene = require("Cutscene")
local Level = require("Level")

function Game:new()
    self.lives = 3
    self.level = nil
    self.cutscene = Cutscene()
end

function Game:update(dt)
    if not self.level then
        return
    end
    if not self.cutscene:isActive() then
        self.level:update(dt)
    end
    self.cutscene:update(dt)
end

function Game:startLevel(data)
    if self.level then
        self.level:unload()
    end
    self.level = Level(data)
end

function Game:unload()
    if not self.level then
        return
    end
    self.level:unload()
    self.level = nil
end

function Game:keypressed(key)
    if not self.level then
        return
    end
    if self.cutscene:isActive() then
        self.cutscene:keypressed(key)
    else
        self.level:keypressed(key)
    end
end

function Game:keyreleased(key)
    if not self.level then
        return
    end
    if not self.cutscene:isActive() then
        self.level:keyreleased(key)
    end
end

function Game:mousepressed(x, y, button)
    if not self.level then
        return
    end
    if self.cutscene:isActive() then
        self.cutscene:mousepressed(x, y, button)
    else
        self.level:mousepressed(x, y, button)
    end
end

function Game:draw()
    if not self.level then
        return
    end
    self.level:draw()
    self.cutscene:draw()
end

return Game