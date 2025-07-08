local Vec2 = require("Vector2")
local Spritesheet = require("Spritesheet")
_Utils = require("com.utils")

-- Globals
_TEXT = "Let's write some code!"
_POS = Vec2(100, 50)
_PLAYER_SPRITES = Spritesheet("assets/player.png", 168, 244, 16, 3)
_FRAME = 1

function love.load()
end

function love.update(dt)
	_FRAME = (_FRAME + dt * 10) % 6
end

function love.draw()
	love.graphics.print(_TEXT, _POS.x, _POS.y)
	_PLAYER_SPRITES:drawFrame(math.floor(_FRAME) + 1, 100, 300)
end