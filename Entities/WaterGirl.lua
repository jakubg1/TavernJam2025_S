local Entity = require("Entity")

---@class WaterGirl : Entity
---@overload fun(x, y): WaterGirl
local WaterGirl = Entity:derive("WaterGirl")

---Constructs the WaterGirl.
function WaterGirl:new(x, y)
    -- Parameters
    self.WIDTH, self.HEIGHT = 100, 160
    self.SCALE = 0.3125
    self.OFFSET_X, self.OFFSET_Y = 0, -60
    self.FLIP_AXIS_OFFSET = -45
    self.MAX_SPEED = 0
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 2500
    self.MAX_HEALTH = 2
    self.KNOCK_X, self.KNOCK_Y = 0, 0
    self.KNOCK_TIME_MAX = 10.3
    self.INVUL_TIME_MAX = 0
    ---@type table<string, SpriteState>
    self.STATES = {
        idle = {state = "idle", start = 1, frames = 5, framerate = 15},
        attack = {state = "attack", start = 1, frames = 13, framerate = 15, onFinish = "idle"},
        defeat = {state = "defeat", start = 1, frames = 5, framerate = 15, delOnFinish = true}
    }
    self.STARTING_STATE = self.STATES.idle
    self.SPRITES = _SPRITES.waterGirl

    -- Water Girl exclusive parameters
    self.ATTACK_RANGE = 160 -- The width of attack hitboxes
    self.ATTACK_PROXIMITY = self.ATTACK_RANGE + self.WIDTH + 40 -- The amount of pixels in front of which she will attack
    self.ATTACK_COOLDOWN_MIN = 1.5
    self.ATTACK_COOLDOWN_MAX = 2.5

    -- Physics
    ---@type table<string, AttackArea>
    self.ATTACK_AREAS = {
        attackLeft = {offsetX = -self.ATTACK_RANGE, width = self.ATTACK_RANGE},
        attackRight = {offsetX = self.WIDTH, width = self.ATTACK_RANGE}
    }

    -- Prepend default fields
    self.super.new(self, x, y)

    -- State
    self.attackCooldown = nil
end

---Updates the WaterGirl.
---@param dt number Time delta in seconds
function WaterGirl:update(dt)
    self:updateAttack()
    self:updateAttackCooldown(dt)
    self.super.update(self, dt)
end

function WaterGirl:updateAttack()
    local player = _LEVEL.player
    if self.state == self.STATES.attack and self.stateFrame >= 5 and self.stateFrame <= 9 then
        if self:collidesWith(player, "main", "main") or self:collidesWith(player, self.direction == "left" and "attackLeft" or "attackRight", "main") then
            player:hurt(self.direction)
        end
    end
end

function WaterGirl:updateAttackCooldown(dt)
    if self.state == self.STATES.attack then
        if self.attackCooldown then
            return
        end
        self.attackCooldown = self.ATTACK_COOLDOWN_MIN + math.random() * (self.ATTACK_COOLDOWN_MAX - self.ATTACK_COOLDOWN_MIN)
    elseif self.state == self.STATES.idle then
        if not self.attackCooldown then
            return
        end
        self.attackCooldown = math.max(self.attackCooldown - dt, 0)
        if self.attackCooldown == 0 then
            self.attackCooldown = nil
        end
    end
end

function WaterGirl:updateDirection()
    self.direction = self.x - _LEVEL.player.x > 0 and "left" or "right"
end

function WaterGirl:updateState()
    local playerClose = self:getProximityToPlayer() < self.ATTACK_PROXIMITY
    local canAttack = not self.attackCooldown
    local dead = self.dead
    if self.state == self.STATES.idle then
        self:setState("attack", playerClose and canAttack)
        self:setState("defeat", dead)
    elseif self.state == self.STATES.attack then
        self:setState("defeat", dead)
    elseif self.state == self.STATES.defeat then
    end
end

return WaterGirl