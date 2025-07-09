_Utils = require("com.utils")

local Spritesheet = require("Spritesheet")
local Level = require("Level")
local DialogText = require("DialogText")

function love.load()
	-- Resources
	local spriteData = {
		player = {directory = "assets/Player/", states = {idle = 6, jump = 10, run = 16}},
		waterDrop = {directory = "assets/Water_Drop/", states = {defeat = 5, idle = 4, move = 4, rise = 5}},
		waterGirl = {directory = "assets/Water_Girl/", states = {attack = 13, defeat = 5, idle = 5}},
		sharkMan = {directory = "assets/Shark_Man/", states = {attack = 24, fly = 18, idle = 10}},
		sharkWoman = {directory = "assets/Shark_Woman/", states = {attack = 24, fly = 18, idle = 10}}
	}
	_SPRITES = {}
	for name, data in pairs(spriteData) do
		_SPRITES[name] = Spritesheet(data)
	end

	_FONT_TMP = love.graphics.newFont("assets/Lambda-Regular.ttf", 48)
	_WHITE_SHADER = love.graphics.newShader("assets/whiten.glsl")

	-- Game logic
	_WORLD = love.physics.newWorld()
	_WORLD:setCallbacks(_BeginContact, _EndContact)
	_LEVEL = Level()

	-- Tests
	_HITBOXES = false
	_TEXT = DialogText()
end

function love.update(dt)
	if love.keyboard.isDown("space") then
		dt = dt / 5
	end
	_WORLD:update(dt)
	_LEVEL:update(dt)
end

function love.keypressed(key)
	_LEVEL:keypressed(key)
	if key == "h" then
		_HITBOXES = not _HITBOXES
	end
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