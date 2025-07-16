local Entity = require("Entity")

---@class Shark : Entity
---@overload fun(x, y, isFemale): Shark
local Shark = Entity:derive("Shark")

---Constructs the Shark.
function Shark:new(x, y, isFemale)
    -- Parameters
    self.WIDTH, self.HEIGHT = 160, 120
    self.SCALE = 0.625
    self.OFFSET_X, self.OFFSET_Y = -37, -75
    self.FLIP_AXIS_OFFSET = 0
    self.IS_ENEMY = true
    self.MAX_SPEED = 700
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 0
    ---@type table<string, SpriteState>
    self.STATES = {
        idle = {state = "idle", start = 1, frames = 10, framerate = 20},
        attack = {state = "attack", start = 1, frames = 24, framerate = 20, onFinish = "fly"},
        fly = {state = "fly", start = 1, frames = 18, framerate = 20}
    }
    self.STARTING_STATE = self.STATES.idle
    self.SPRITES = isFemale and _SPRITES.sharkWoman or _SPRITES.sharkMan

    -- Water Drop exclusive parameters
    self.PLAYER_DETECTION_RANGE = 800
    self.INSTANT_FLY_RANGE = 300

    -- Physics
    ---@type table<string, AttackArea>
    self.ATTACK_AREAS = {}

    -- Prepend default fields
    self.super.new(self, x, y)

    -- State
end

---Updates the Shark.
---@param dt number Time delta in seconds
function Shark:update(dt)
    self:move(dt)
    self:updateAttack()
    self.super.update(self, dt)
end

function Shark:move(dt)
    -- Calculate the current acceleration.
    local left, right
    if self.state == self.STATES.fly then
        left = self.direction == "left"
        right = self.direction == "right"
    end
    if left and not right then
        self.accX = -self.MAX_ACC
    elseif right and not left then
        self.accX = self.MAX_ACC
    else
        self.accX = 0
        self:applyDrag(dt)
    end
end

function Shark:updateAttack()
    local player = _GAME.level.player
    if self.state == self.STATES.fly then
        if self:collidesWith(player, "main", "main") then
            player:hurt(self.direction, 4, true)
        end
    end
end

function Shark:updateDirection()
    if self.state ~= self.STATES.fly then
        self.direction = self.x - _GAME.level.player.x > 0 and "left" or "right"
    end
end

function Shark:updateState()
    local playerClose = self:getProximityToPlayer() < self.PLAYER_DETECTION_RANGE
    local playerTooClose = self:getProximityToPlayer() < self.INSTANT_FLY_RANGE
    if self.state == self.STATES.idle then
        self:setState("attack", playerClose)
    elseif self.state == self.STATES.attack then
        self:setState("fly", playerTooClose)
    elseif self.state == self.STATES.fly then
    end
end

return Shark