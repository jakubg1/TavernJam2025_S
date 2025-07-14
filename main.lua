_Utils = require("com.utils")

local bump = require("com.bump")
local Spritesheet = require("Spritesheet")
local MainMenu = require("MainMenu")
local Game = require("Game")
local Settings = require("Settings")

function love.load()
	_PRODUCTION = false

	-- Resources
	local spriteData = {
		player = {directory = "assets/Player/", states = {idle = 6, jump = 10, run = 16, leftpunch = 7, rightpunch = 7, dropkick = 6, fall = 2, walljump = 6, ko = 8}},
		cloudGirl = {directory = "assets/Cloud_Girl/", states = {idle = 9}},
		jumpyCloudy = {directory = "assets/Jumpy_Cloudy/", states = {idle = 5, rise = 16, idle2 = 4, attack = 35}},
		fishBoy = {directory = "assets/Fish_Boy/", states = {attack = 21, idle = 10}},
		fishBoyGold = {directory = "assets/Fish_Boy_Gold/", states = {attack = 21, idle = 10}},
		waterDrop = {directory = "assets/Water_Drop/", states = {defeat = 5, idle = 4, move = 4, rise = 5}},
		waterGirl = {directory = "assets/Water_Girl/", states = {attack = 13, defeat = 5, idle = 5}},
		sharkMan = {directory = "assets/Shark_Man/", states = {attack = 24, fly = 18, idle = 10}},
		sharkWoman = {directory = "assets/Shark_Woman/", states = {attack = 24, fly = 18, idle = 10}},
		npcClarissa = {directory = "assets/Clarissa/", states = {idleleft = 5, idleright = 5}},
		npcHoney = {directory = "assets/Honey/", states = {idleleft = 5, idleright = 5}},
		npcJeremy = {directory = "assets/Jeremy/", states = {idleleft = 5, idleright = 5}},
		npcMila = {directory = "assets/Mila/", states = {idleleft = 5, idleright = 5}},
		npcCrystal = {directory = "assets/Crystal/", states = {idle = 5}},
		npcLaeyna = {directory = "assets/Laeyna/", states = {idle = 5}},
		npcSterren = {directory = "assets/Sterren/", states = {idle = 5}},
		npcTiffania = {directory = "assets/Tiffania/", states = {idle = 5}},
		npcWaiter = {directory = "assets/Waiter/", states = {idle = 5}},

		menuSelect = {directory = "assets/Menu/", states = {select = 10}},
		menuWindow = {directory = "assets/Menu/Window/", states = {idle = 28, open = 12}}
	}
	---@type table<string, Spritesheet>
	_SPRITES = {}
	for name, data in pairs(spriteData) do
		_SPRITES[name] = Spritesheet(data)
	end

	_MENU_BG = love.graphics.newImage("assets/Menu/title.png")
	_MENU_SLIDER = love.graphics.newImage("assets/Menu/slider.png")
	_MENU_SLIDER_NOTCH = love.graphics.newImage("assets/Menu/slider_notch.png")
	_MENU_CHECKBOX = love.graphics.newImage("assets/Menu/checkbox.png")
	_MENU_CHECKBOX_SELECTED = love.graphics.newImage("assets/Menu/checkbox_selected.png")

	_LEVEL_BG = love.graphics.newImage("assets/Level_Picnic/background.png")
	_LEVEL_FG = love.graphics.newImage("assets/Level_Picnic/foreground.png")
	_LEVEL_SKY = love.graphics.newImage("assets/Level_Picnic/sky.png")
	_LEVEL2_FG = love.graphics.newImage("assets/Level_2/foreground.png")
	_LEVEL_WT_FG = love.graphics.newImage("assets/Level_Water_Tower/foreground.png")

	_HEARTS = {}
	for i = 0, 4 do
		_HEARTS[i] = love.graphics.newImage("assets/HUD/heart_" .. i .. ".png")
	end
	_LIVES = {}
	for i = 1, 10 do
		_LIVES[i] = love.graphics.newImage("assets/HUD/lives_" .. i .. ".png")
	end

	_FONT = love.graphics.newFont("assets/Lambda-Regular.ttf", 48)
	_FONT_S = love.graphics.newFont("assets/Lambda-Regular.ttf", 24)
	_WHITE_SHADER = love.graphics.newShader("assets/whiten.glsl")

	_DIALOG = love.graphics.newImage("assets/dialog.png")
	_DIALOG_ARROW = love.graphics.newImage("assets/dialog_arrow.png")

	_LEVEL_DATA = {
		playerSpawnX = 100,
		playerSpawnY = 1625,
		grounds = {
			{x = 0, y = 1675, w = 20000, h = 1},
			{x = 2275, y = 1515, w = 75, h = 1, topOnly = true},
			{x = 2395, y = 1475, w = 105, h = 1, topOnly = true},
			{x = 2495, y = 1400, w = 165, h = 1, topOnly = true},
			{x = 2700, y = 1330, w = 960, h = 1, topOnly = true},
			{x = 3655, y = 1275, w = 165, h = 1, topOnly = true},
			{x = 3875, y = 1425, w = 100, h = 1, topOnly = true},
			{x = 4075, y = 1490, w = 295, h = 1, topOnly = true}
		},
		entities = {
			{type = "JumpyCloudy", x = 1000, y = 1625},
			{type = "WaterDrop", x = 2900, y = 1625},
			{type = "WaterDrop", x = 3500, y = 1625},
			{type = "WaterGirl", x = 5300, y = 1625},
			{type = "WaterDrop", x = 5900, y = 1625},
			{type = "WaterGirl", x = 6800, y = 1625}
		},
		foregroundImg = _LEVEL_FG,
		foregroundScale = 0.5,
		backgroundImg = _LEVEL_BG,
		backgroundScale = 0.5 * 0.81
	}

	_LEVEL_2_DATA = {
		playerSpawnX = 100,
		playerSpawnY = 125,
		grounds = {
			{x = 800, y = 500, w = 120, h = 1, topOnly = true},
			{x = 0, y = 1670, w = 20000, h = 1},
			{x = 0, y = 0, w = 1, h = 2000, nonslidable = true},
			{x = 0, y = 675, w = 2810, h = 1},
			{x = 285, y = 1220, w = 2870, h = 1},
			{x = 3285, y = 1565, w = 345, h = 1},
			{x = 3685, y = 1445, w = 460, h = 1},
			{x = 4210, y = 1295, w = 540, h = 1},
			{x = 4645, y = 1055, w = 120, h = 1, topOnly = true},
			{x = 4645, y = 865, w = 120, h = 1, topOnly = true},
			{x = 3260, y = 1005, w = 525, h = 1},
			{x = 3205, y = 0, w = 1, h = 1265},
			{x = 2285, y = 720, w = 1, h = 250},
			{x = 1525, y = 720, w = 1, h = 250},
			{x = 4800, y = 860, w = 1, h = 810}
		},
		entities = {
			{type = "NPC", x = 500, y = 125, name = "Mila"},
			{type = "NPC", x = 600, y = 125, name = "Jeremy"},
			{type = "NPC", x = 700, y = 125, name = "Honey"},
			{type = "NPC", x = 800, y = 125, name = "Clarissa"},
			{type = "NPC", x = 900, y = 125, name = "Crystal"},
			{type = "NPC", x = 1000, y = 125, name = "Waiter"}
		},
		foregroundImg = _LEVEL2_FG,
		foregroundScale = 0.5,
		backgroundImg = _LEVEL_BG,
		backgroundScale = 0.5 * 0.81
	}

	_LEVEL_WT_DATA = {
		playerSpawnX = 100,
		playerSpawnY = 125,
		grounds = {
			{x = 0, y = 6940, w = 2000, h = 1},
			{x = 0, y = 0, w = 1, h = 7000, nonslidable = true},
			{x = 2120, y = 0, w = 1, h = 7000, nonslidable = true},
			{x = 1743, y = 6838, w = 113, h = 1, topOnly = true},
			{x = 1640, y = 6742, w = 100, h = 1, topOnly = true},
			{x = 1839, y = 6637, w = 146, h = 1, topOnly = true},
			{x = 1371, y = 6496, w = 449, h = 1, topOnly = true},
			{x = 1644, y = 6281, w = 202, h = 1, topOnly = true},
			{x = 1642, y = 6118, w = 204, h = 1, topOnly = true},
			{x = 1986, y = 4595, w = 1, h = 1987},
			{x = 1644, y = 5962, w = 217, h = 1, topOnly = true},
			{x = 1643, y = 5821, w = 212, h = 1, topOnly = true},
			{x = 1113, y = 5975, w = 268, h = 1},
			{x = 958, y = 5845, w = 90, h = 1},
			{x = 1078, y = 5854, w = 1, h = 117, nonslidable = true},
			{x = 534, y = 5992, w = 245, h = 1, topOnly = true},
			{x = 107, y = 6171, w = 1387, h = 1},
			{x = 105, y = 5974, w = 103, h = 1, topOnly = true},
			{x = 70, y = 4613, w = 1, h = 1557},
			{x = 339, y = 5405, w = 1, h = 207},
			{x = 502, y = 5337, w = 1416, h = 1},
		},
		entities = {},
		foregroundImg = _LEVEL_WT_FG,
		foregroundScale = 0.5,
		backgroundImg = _LEVEL_BG,
		backgroundScale = 0.5 * 0.81
	}

	_SETTINGS = Settings()

	-- Game logic
	_WORLD = bump.newWorld()
	_MENU = MainMenu()
	_GAME = Game()

	-- Debug
	_HITBOXES = true and not _PRODUCTION
end

function love.update(dt)
	if love.keyboard.isDown("space") and not _PRODUCTION then
		dt = dt / 5
	end
	_MENU:update(dt)
	_GAME:update(dt)
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
end

function love.draw()
	_MENU:draw()
	_GAME:draw()
end