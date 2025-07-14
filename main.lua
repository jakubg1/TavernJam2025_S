_Utils = require("com.utils")

local bump = require("com.bump")
local Spritesheet = require("Spritesheet")
local Level = require("Level")
local DialogText = require("Cutscene")

function love.load()
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
	}
	---@type table<string, Spritesheet>
	_SPRITES = {}
	for name, data in pairs(spriteData) do
		_SPRITES[name] = Spritesheet(data)
	end

	_LEVEL_BG = love.graphics.newImage("assets/Level_Picnic/background.png")
	_LEVEL_FG = love.graphics.newImage("assets/Level_Picnic/foreground.png")
	_LEVEL_SKY = love.graphics.newImage("assets/Level_Picnic/sky.png")
	_LEVEL2_FG = love.graphics.newImage("assets/Level_2/foreground.png")

	_FONT = love.graphics.newFont("assets/Lambda-Regular.ttf", 48)
	_WHITE_SHADER = love.graphics.newShader("assets/whiten.glsl")

	_DIALOG = love.graphics.newImage("assets/dialog.png")
	_DIALOG_ARROW = love.graphics.newImage("assets/dialog_arrow.png")

	local levelData = {
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

	local level2Data = {
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
			{type = "NPC", x = 800, y = 125, name = "Clarissa"}
		},
		foregroundImg = _LEVEL2_FG,
		foregroundScale = 0.5,
		backgroundImg = _LEVEL_BG,
		backgroundScale = 0.5 * 0.81
	}

	-- Game logic
	_WORLD = bump.newWorld()
	_LEVEL = Level(levelData)
	_CUTSCENE = DialogText()

	-- Debug
	_HITBOXES = true
end

function love.update(dt)
	if love.keyboard.isDown("space") then
		dt = dt / 5
	end
	if not _CUTSCENE:isActive() then
		_LEVEL:update(dt)
	end
	_CUTSCENE:update(dt)
end

function love.keypressed(key)
	if _CUTSCENE:isActive() then
		_CUTSCENE:keypressed(key)
	else
		_LEVEL:keypressed(key)
	end
	if key == "h" then
		_HITBOXES = not _HITBOXES
	end
end

function love.keyreleased(key)
	if not _CUTSCENE:isActive() then
		_LEVEL:keyreleased(key)
	end
end

function love.mousepressed(x, y, button)
	if _CUTSCENE:isActive() then
		_CUTSCENE:mousepressed(x, y, button)
	end
end

function love.draw()
	_LEVEL:draw()
	_CUTSCENE:draw()
end