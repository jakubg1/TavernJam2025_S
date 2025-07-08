_Utils = require("com.utils")

local Spritesheet = require("Spritesheet")
local Level = require("Level")
local DialogText = require("DialogText")

function love.load()
	-- Resources
	_PLAYER_SPRITES = Spritesheet("assets/player.png", 168, 244, 16, 3)
	_FONT_TMP = love.graphics.newFont("assets/Lambda-Regular.ttf", 48)

	-- Game logic
	_WORLD = love.physics.newWorld()
	_WORLD:setCallbacks(_BeginContact, _EndContact)
	_LEVEL = Level()

	-- Tests
	_TEXT = DialogText()
end

function love.update(dt)
	_WORLD:update(dt)
	_LEVEL:update(dt)
end

function love.keypressed(key)
	_LEVEL:keypressed(key)
end

function love.keyreleased(key)
	_LEVEL:keyreleased(key)
end

function love.draw()
	_LEVEL:draw()
	_TEXT:draw()
end

function _BeginContact(a, b, collision)
	_LEVEL:beginContact(a, b, collision)
end

function _EndContact(a, b, collision)
	_LEVEL:endContact(a, b, collision)
end