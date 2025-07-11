local Entity = require("Entity")

---@class WaterDrop : Entity
---@overload fun(x, y): WaterDrop
local WaterDrop = Entity:derive("WaterDrop")

---Constructs the WaterDrop.
function WaterDrop:new(x, y)
    -- Parameters
    self.WIDTH, self.HEIGHT = 80, 100
    self.SCALE = 0.3125
    self.OFFSET_X, self.OFFSET_Y = 0, -88
    self.FLIP_AXIS_OFFSET = 0
    self.MAX_SPEED = 150
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 2500
    self.MAX_HEALTH = 2
    self.KNOCK_X, self.KNOCK_Y = 600, 600
    self.KNOCK_TIME_MAX = 10.3
    self.INVUL_TIME_MAX = 0
    ---@type table<string, SpriteState>
    self.STATES = {
        idle = {state = "idle", start = 1, frames = 4, framerate = 10, noFlip = true},
        rise = {state = "rise", start = 1, frames = 5, framerate = 10, onFinish = "move"},
        move = {state = "move", start = 1, frames = 4, framerate = 10},
        defeat = {state = "defeat", start = 1, frames = 5, framerate = 10, delOnFinish = true},
        sleep = {state = "rise", start = 1, frames = 5, framerate = 10, onFinish = "idle", reverse = true}
    }
    self.STARTING_STATE = self.STATES.idle
    self.SPRITES = _SPRITES.waterDrop

    -- Water Drop exclusive parameters
    self.STRAFE_RANGE = 200
    self.PLAYER_DETECTION_RANGE = 300
    self.SLEEP_DELAY_MAX = 3
    self.SLEEP_SAFE_DISTANCE = 500

    -- Physics
    ---@type table<string, AttackArea>
    self.ATTACK_AREAS = {}

    -- Prepend default fields
    self.super.new(self, x, y)

    -- State
    self.targetDirection = "left" -- Used when idling to strafe left and right
    self.sleepDelay = self.SLEEP_DELAY_MAX
end

---Updates the WaterDrop.
---@param dt number Time delta in seconds
function WaterDrop:update(dt)
    self:move(dt)
    self:updateAttack()
    self:updateSleep(dt)
    self.super.update(self, dt)
end

function WaterDrop:move(dt)
    -- Calculate the current acceleration.
    local left, right
    if self.state == self.STATES.idle then
        if self.targetDirection == "left" and self.homeX - self.x > self.STRAFE_RANGE then
            self.targetDirection = "right"
        elseif self.targetDirection == "right" and self.x - self.homeX > self.STRAFE_RANGE then
            self.targetDirection = "left"
        end
        left = self.targetDirection == "left"
        right = self.targetDirection == "right"
    elseif self.state == self.STATES.move then
        local proximity = self:getProximityToPlayer()
        left = proximity > 40 and self.x > _LEVEL.player.x
        right = proximity > 40 and self.x < _LEVEL.player.x
    end
    if self.knockTime then
        self.accX = 0
    elseif left and not right then
        self.accX = -self.MAX_ACC
    elseif right and not left then
        self.accX = self.MAX_ACC
    else
        self.accX = 0
        self:applyDrag(dt)
    end
end

function WaterDrop:updateAttack()
    local player = _LEVEL.player
    if self.state == self.STATES.move then
        if self:collidesWith(player, "main", "main") then
            player:hurt(player.x < self.x and "left" or "right")
        end
    end
end

function WaterDrop:updateSleep(dt)
    if self.state ~= self.STATES.move or self:getProximityToPlayer() < self.SLEEP_SAFE_DISTANCE then
        self.sleepDelay = self.SLEEP_DELAY_MAX
    end
    self.sleepDelay = math.max(self.sleepDelay - dt, 0)
end

function WaterDrop:updateState()
    local playerClose = self:getProximityToPlayer() < self.PLAYER_DETECTION_RANGE
    local sleep = self.sleepDelay == 0
    local dead = self.dead
    if self.state == self.STATES.idle then
        self:setState("rise", playerClose)
    elseif self.state == self.STATES.rise then
    elseif self.state == self.STATES.move then
        self:setState("sleep", sleep)
        self:setState("defeat", dead)
    elseif self.state == self.STATES.defeat then
    elseif self.state == self.STATES.sleep then
    end
end

return WaterDrop