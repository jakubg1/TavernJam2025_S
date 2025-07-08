_Utils = require("com.utils")

local Spritesheet = require("Spritesheet")
local Level = require("Level")
local DialogText = require("DialogText")

function love.load()
	-- Resources
    local playerSprites = {
        directory = "assets/Player/",
        states = {idle = 6, jump = 12, run = 16}
    }
	_PLAYER_SPRITES = Spritesheet(playerSprites)
	local waterDropSprites = {
		directory = "assets/Water_Drop/",
		states = {defeat = 5, idle = 4, move = 4, rise = 5}
	}
	_WATER_DROP_SPRITES = Spritesheet(waterDropSprites)
	local waterGirlSprites = {
		directory = "assets/Water_Girl/",
		states = {attack = 13, defeat = 5, idle = 5}
	}
	_WATER_GIRL_SPRITES = Spritesheet(waterGirlSprites)

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