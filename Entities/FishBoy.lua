local Entity = require("Entity")

---@class FishBoy : Entity
---@overload fun(x, y, isGold): FishBoy
local FishBoy = Entity:derive("FishBoy")

---Constructs the FishBoy.
function FishBoy:new(x, y, isGold)
    -- Parameters
    self.WIDTH, self.HEIGHT = 80, 160
    self.SCALE = 0.25
    self.OFFSET_X, self.OFFSET_Y = 0, -30
    self.FLIP_AXIS_OFFSET = -50
    self.IS_ENEMY = true
    self.MAX_SPEED = 700
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 2500
    ---@type table<string, SpriteState>
    self.STATES = {
        idle = {state = "idle", start = 1, frames = 10, framerate = 20},
        attack = {state = "attack", start = 1, frames = 21, framerate = 20, onFinish = "idle"}
    }
    self.STARTING_STATE = self.STATES.idle
    self.SPRITES = isGold and _RES.sprites.fishBoyGold or _RES.sprites.fishBoy

    -- Water Drop exclusive parameters
    self.PLAYER_DETECTION_RANGE = 800

    -- Physics
    ---@type table<string, AttackArea>
    self.ATTACK_AREAS = {}

    -- Prepend default fields
    self.super.new(self, x, y)

    -- State
end

---Updates the FishBoy.
---@param dt number Time delta in seconds
function FishBoy:update(dt)
    self:move(dt)
    --self:updateAttack()
    self.super.update(self, dt)
end

function FishBoy:move(dt)
    -- Calculate the current acceleration.
    local left, right
    if left and not right then
        self.accX = -self.MAX_ACC
    elseif right and not left then
        self.accX = self.MAX_ACC
    else
        self.accX = 0
        self:applyDrag(dt)
    end
end

function FishBoy:updateAttack()
    local player = _GAME.level.player
    if self.state == self.STATES.fly then
        if self:collidesWith(player, "main", "main") then
            player:hurt(self.direction)
        end
    end
end

function FishBoy:updateDirection()
    if self.state ~= self.STATES.fly then
        self.direction = self.x - _GAME.level.player.x > 0 and "left" or "right"
    end
end

function FishBoy:updateState()
    if self.state == self.STATES.idle then
    elseif self.state == self.STATES.attack then
    end
end

return FishBoy