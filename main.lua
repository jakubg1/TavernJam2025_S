_Utils = require("com.utils")

local Spritesheet = require("Spritesheet")
local Player = require("Player")

-- Globals
_PLAYER_SPRITES = Spritesheet("assets/player.png", 168, 244, 16, 3)
_PLAYER = Player()

function love.load()
end

function love.update(dt)
	_PLAYER:update(dt)
end

function love.draw()
	_PLAYER:draw()
end

function love.keypressed(key)
	_PLAYER:keypressed(key)
end

function love.keyreleased(key)
	_PLAYER:keyreleased(key)
end