_Utils = require("com.utils")

local bump = require("com.bump")
local Resources = require("Resources")
local MainMenu = require("MainMenu")
local Game = require("Game")
local Credits = require("Credits")
local Settings = require("Settings")
local Jukebox = require("Jukebox")

-- makelove: 12 799 045 B max

function love.load()
	_PRODUCTION = false

	-- Resources
	_SETTINGS = Settings()
	_RES = Resources()
	_JUKEBOX = Jukebox()

	-- Game logic
	_WORLD = bump.newWorld()
	_MENU = MainMenu()
	_GAME = Game()
	_CREDITS = Credits()

	-- Debug
	_HITBOXES = true and not _PRODUCTION
end

function love.update(dt)
	if love.keyboard.isDown("space") and not _PRODUCTION then
		dt = dt / 5
	end
	_MENU:update(dt)
	_GAME:update(dt)
	_CREDITS:update(dt)
end

function love.keypressed(key)
	_GAME:keypressed(key)
	if key == "h" and not _PRODUCTION then
		_HITBOXES = not _HITBOXES
	end
end

function love.keyreleased(key)
	_GAME:keyreleased(key)
end

function love.mousepressed(x, y, button)
	_MENU:mousepressed(x, y, button)
	_GAME:mousepressed(x, y, button)
	_CREDITS:mousepressed(x, y, button)
end

function love.draw()
	_MENU:draw()
	_GAME:draw()
	_CREDITS:draw()
end