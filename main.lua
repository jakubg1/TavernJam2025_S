_Utils = require("com.utils")

local Spritesheet = require("Spritesheet")
local Player = require("Player")

-- Globals
_PLAYER_SPRITES = Spritesheet("assets/player.png", 168, 244, 16, 3)
_PLAYER = Player()

_FONT_TMP = love.graphics.newFont("assets/Lambda-Regular.ttf", 48)

function love.load()
end

function love.update(dt)
	_PLAYER:update(dt)
end

function love.draw()
	_PLAYER:draw()

	local x, y = love.mouse.getPosition()
	love.graphics.rectangle("line", 100, 100, x - 100, y - 100)
	love.graphics.setFont(_FONT_TMP)
	love.graphics.printf({{1, 1, 1}, "You're a ", {1, 1, 0}, "HUMAN", {1, 1, 1}, " now and you gotta fight like one!"}, _FONT_TMP, 100, 100, x - 100)
end

function love.keypressed(key)
	_PLAYER:keypressed(key)
end

function love.keyreleased(key)
	_PLAYER:keyreleased(key)
end