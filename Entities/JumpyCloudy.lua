local Entity = require("Entity")

---@class JumpyCloudy : Entity
---@overload fun(x, y): JumpyCloudy
local JumpyCloudy = Entity:derive("JumpyCloudy")

---Constructs the JumpyCloudy.
function JumpyCloudy:new(x, y)
    -- Parameters
    self.WIDTH, self.HEIGHT = 100, 120
    self.SCALE = 0.3125
    self.OFFSET_X, self.OFFSET_Y = 0, -60
    self.FLIP_AXIS_OFFSET = -45
    self.MAX_SPEED = 0
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 2500
    self.KNOCK_X, self.KNOCK_Y = 0, 0
    self.KNOCK_TIME_MAX = 10.3
    self.INVUL_TIME_MAX = 0
    ---@type table<string, SpriteState>
    self.STATES = {
        idle = {state = "idle", start = 1, frames = 5, framerate = 10},
        rise = {state = "rise", start = 1, frames = 16, framerate = 20, onFinish = "alert"},
        alert = {state = "idle2", start = 1, frames = 4, framerate = 10},
        attack = {state = "attack", start = 1, frames = 35, framerate = 20, onFinish = "idle"}
    }
    self.STARTING_STATE = self.STATES.idle
    self.SPRITES = _SPRITES.jumpyCloudy

    -- Water Girl exclusive parameters
    self.ATTACK_RANGE = 160 -- The width of attack hitboxes
    self.RISE_PROXIMITY = 600
    self.ATTACK_PROXIMITY = self.ATTACK_RANGE + self.WIDTH + 40 -- The amount of pixels in front of which she will attack

    -- Physics
    ---@type table<string, AttackArea>
    self.ATTACK_AREAS = {}

    -- Prepend default fields
    self.super.new(self, x, y)

    -- State
end

---Updates the JumpyCloudy.
---@param dt number Time delta in seconds
function JumpyCloudy:update(dt)
    self:updateAttack()
    self.super.update(self, dt)
end

function JumpyCloudy:updateAttack()
    local player = _GAME.level.player
    if self.state ~= self.STATES.idle then
        if self:collidesWith(player, "main", "main") then
            player:hurt(self.direction)
        end
    end
end

function JumpyCloudy:updateDirection()
    self.direction = self.x - _GAME.level.player.x > 0 and "left" or "right"
end

function JumpyCloudy:updateState()
    local proximity = self:getProximityToPlayer()
    local playerClose = proximity < self.RISE_PROXIMITY
    local playerCloser = proximity < self.ATTACK_PROXIMITY
    if self.state == self.STATES.idle then
        self:setState("rise", playerClose)
    elseif self.state == self.STATES.rise then
    elseif self.state == self.STATES.alert then
        self:setState("attack", playerCloser)
    elseif self.state == self.STATES.attack then
    end
end

return JumpyCloudy