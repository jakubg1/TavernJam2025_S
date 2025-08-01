local Class = require("com.class")

---Holds all resources in the game.
---@class Resources : Class
---@overload fun(): Resources
local Resources = Class:derive("Resources")

local Spritesheet = require("Spritesheet")

function Resources:new()
    -- Sprites
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
	self.sprites = {}
	for name, data in pairs(spriteData) do
		self.sprites[name] = Spritesheet(data)
	end

    ---@type table<string, love.Image>
    self.images = {
        menuBg = love.graphics.newImage("assets/Menu/title.png"),
        menuSlider = love.graphics.newImage("assets/Menu/slider.png"),
        menuSliderNotch = love.graphics.newImage("assets/Menu/slider_notch.png"),
        menuCheckbox = love.graphics.newImage("assets/Menu/checkbox.png"),
        menuCheckboxSelected = love.graphics.newImage("assets/Menu/checkbox_selected.png"),
        dialog = love.graphics.newImage("assets/dialog.png"),
        dialogArrow = love.graphics.newImage("assets/dialog_arrow.png"),
        levelBg = love.graphics.newImage("assets/Level_Picnic/background.png"),
        levelFg = love.graphics.newImage("assets/Level_Picnic/foreground.png"),
        levelSky = love.graphics.newImage("assets/Level_Picnic/sky.png"),
        --level2Fg = love.graphics.newImage("assets/Level_2/foreground.png"),
        levelWtFg = love.graphics.newImage("assets/Level_Water_Tower/foreground.png")
    }
	for i = 0, 4 do
		self.images["hearts_" .. i] = love.graphics.newImage("assets/HUD/heart_" .. i .. ".png")
	end
	for i = 1, 10 do
		self.images["lives_" .. i] = love.graphics.newImage("assets/HUD/lives_" .. i .. ".png")
	end

	-- Sounds
	---@type table<string, love.Source>
	self.sounds = {
		ui_back = love.audio.newSource("assets/Sounds/ui_back.wav", "static"),
		ui_hover = love.audio.newSource("assets/Sounds/ui_hover.wav", "static"),
		ui_select = love.audio.newSource("assets/Sounds/ui_select.wav", "static")
	}

	self.font = love.graphics.newFont("assets/Lambda-Regular.ttf", 48)
	self.fontSmall = love.graphics.newFont("assets/Lambda-Regular.ttf", 24)
	self.whiteShader = love.graphics.newShader("assets/whiten.glsl")

	self.levels = {
		picnic = {
			playerSpawnX = 100,
			playerSpawnY = 1675,
			grounds = {
				{x = 0, y = 1675, w = 20000, h = 1},
				{x = 0, y = 0, w = 1, h = 7000, nonslidable = true},
				{x = 2275, y = 1515, w = 75, h = 1, topOnly = true},
				{x = 2395, y = 1475, w = 105, h = 1, topOnly = true},
				{x = 2495, y = 1400, w = 165, h = 1, topOnly = true},
				{x = 2700, y = 1330, w = 960, h = 1, topOnly = true},
				{x = 3655, y = 1275, w = 165, h = 1, topOnly = true},
				{x = 3875, y = 1425, w = 100, h = 1, topOnly = true},
				{x = 4075, y = 1490, w = 295, h = 1, topOnly = true}
			},
			entities = {
				{type = "CloudGirl", x = 4500, y = 1025},
				{type = "JumpyCloudy", x = 3200, y = 1330},
				{type = "Shark", x = 5000, y = 1675},
				{type = "WaterDrop", x = 2900, y = 1675},
				{type = "WaterDrop", x = 3200, y = 1675},
				{type = "WaterDrop", x = 3500, y = 1675},
				{type = "WaterGirl", x = 4300, y = 1675},
				{type = "WaterDrop", x = 4900, y = 1675},
				{type = "NPC", x = 6400, y = 1675, name = "Waiter"},
				{type = "NPC", x = 6600, y = 1675, name = "Tiffania"}
			},
			foregroundImg = self.images.levelFg,
			foregroundScale = 0.5,
			backgroundImg = self.images.levelBg,
			backgroundScale = 0.5 * 0.81,
			music = "picnic",
			cutscenes = {
				endLevel = {
					{text = {{1, 1, 1}, "Hold up hero, where do you think you're going?"}, img = self.sprites.npcTiffania.states.idle[1], side = "right"},
					{text = {{1, 1, 1}, "I've gotta find the ones responsible for all these monsters!"}, img = self.sprites.player.states.idle[1], side = "left"},
					{text = {{1, 1, 1}, "Have you cleared the area?"}, img = self.sprites.npcWaiter.states.idle[1], side = "right"},
					-- condition
					{text = {{1, 1, 1}, "Of course!"}, img = self.sprites.player.states.idle[1], side = "left"},
					{text = {{1, 1, 1}, "Hmm... there was a girl with blue hair that ran by me. If you go now, maybe you can catch her!"}, img = self.sprites.npcTiffania.states.idle[1], side = "right"},
					{text = {{1, 1, 1}, "Girl with blue hair? Alright, I'll keep a look out for her!"}, img = self.sprites.player.states.idle[1], side = "left"},
				}
			}
		},
		lvl2 = {
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
			--foregroundImg = self.images.level2Bg,
			foregroundScale = 0.5,
			backgroundImg = self.images.levelBg,
			backgroundScale = 0.5 * 0.81
		},
		watertower = {
			playerSpawnX = 200,
			playerSpawnY = 3859,
			grounds = {
				{x = 0, y = 3859, w = 2000, h = 1, nonslidable = true},
				{x = 0, y = 0, w = 1, h = 7000, nonslidable = true},
				{x = 2050, y = 0, w = 1, h = 7000, nonslidable = true},
				{x = 1743, y = 3757, w = 113, h = 1, topOnly = true},
				{x = 1640, y = 3661, w = 100, h = 1, topOnly = true},
				{x = 1839, y = 3556, w = 146, h = 1, topOnly = true},
				{x = 1371, y = 3415, w = 449, h = 1, topOnly = true},
				{x = 1644, y = 3200, w = 202, h = 1, topOnly = true},
				{x = 1642, y = 3037, w = 204, h = 1, topOnly = true},
				{x = 2007, y = 1014, w = 1, h = 2487},
				{x = 1644, y = 2881, w = 217, h = 1, topOnly = true},
				{x = 1643, y = 2740, w = 212, h = 1, topOnly = true},
				{x = 1113, y = 2894, w = 268, h = 1, nonslidable = true},
				{x = 958, y = 2764, w = 90, h = 1, nonslidable = true},
				{x = 1078, y = 2773, w = 1, h = 117, nonslidable = true},
				{x = 534, y = 2911, w = 245, h = 1, topOnly = true},
				{x = 107, y = 3090, w = 1387, h = 1},
				{x = 105, y = 2893, w = 103, h = 1, topOnly = true},
				{x = 53, y = 0, w = 1, h = 3089},
				{x = 349, y = 2264, w = 1, h = 267},
				{x = 352, y = 2256, w = 1566, h = 1, nonslidable = true},
				{x = 1730, y = 1710, w = 1, h = 365},
				{x = 1668, y = 1481, w = 1, h = 211},
				{x = 62, y = 1480, w = 1606, h = 1, nonslidable = true},
				{x = 218, y = 1209, w = 251, h = 1, topOnly = true},
				{x = 212, y = 1039, w = 272, h = 1, topOnly = true},
				{x = 215, y = 849, w = 255, h = 1, topOnly = true},
				{x = 228, y = 692, w = 264, h = 1, topOnly = true},
				{x = 592, y = 695, w = 1587, h = 1, topOnly = true},
				{x = 1542, y = 529, w = 38, h = 1, topOnly = true},
				{x = 1543, y = 387, w = 38, h = 1, topOnly = true},
				{x = 1546, y = 215, w = 35, h = 1, topOnly = true},
				{x = 1673, y = 0, w = 1, h = 689, nonslidable = true},
			},
			entities = {
				{type = "WaterDrop", x = 1500, y = 3415},
				{type = "JumpyCloudy", x = 400, y = 3200},
				{type = "Shark", x = 1500, y = 2250, female = true},
				{type = "WaterDrop", x = 700, y = 2250},
				{type = "WaterDrop", x = 800, y = 2250},
				{type = "WaterDrop", x = 900, y = 2250},
				{type = "WaterGirl", x = 1200, y = 1470},
				{type = "WaterGirl", x = 800, y = 1470},
			},
			foregroundImg = self.images.levelWtFg,
			foregroundScale = 0.5,
			backgroundImg = self.images.levelBg,
			backgroundScale = 0.5 * 0.81,
			music = "water"
		}
	}
end

function Resources:setSoundVolume(volume)
	for name, sound in pairs(self.sounds) do
		sound:setVolume(volume)
	end
end

function Resources:getHeartImage(n)
    n = _Utils.clamp(n, 0, 4)
    return self.images["hearts_" .. n]
end

function Resources:getLivesImage(n)
    n = _Utils.clamp(n, 1, 10)
    return self.images["lives_" .. n]
end

return Resources