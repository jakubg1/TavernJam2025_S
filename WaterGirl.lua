local Entity = require("Entity")

---@class WaterGirl : Entity
---@overload fun(x, y): WaterGirl
local WaterGirl = Entity:derive("WaterGirl")

---Constructs the WaterGirl.
function WaterGirl:new(x, y)
    -- Parameters
    self.WIDTH, self.HEIGHT = 80, 128
    self.SCALE = 0.25
    self.OFFSET_X, self.OFFSET_Y = 0, -48
    self.FLIP_AXIS_OFFSET = -45
    self.MAX_SPEED = 0
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 2500
    ---@type table<string, SpriteState>
    self.STATES = {
        idle = {state = "idle", start = 1, frames = 5, framerate = 10},
        attack = {state = "attack", start = 1, frames = 13, framerate = 10, onFinish = "idle"},
        defeat = {state = "defeat", start = 1, frames = 5, framerate = 10, delOnFinish = true}
    }
    self.STARTING_STATE = self.STATES.idle
    self.SPRITES = _WATER_GIRL_SPRITES

    -- Water Girl exclusive parameters
    self.ATTACK_RANGE = 100
    self.SLEEP_DELAY_MAX = 3
    self.SLEEP_SAFE_DISTANCE = 400

    -- Prepend default fields
    self.super.new(self, x, y)

    -- State
    self.sleepDelay = self.SLEEP_DELAY_MAX

    -- Physics
    self.physics = {}
    self.physics.body = love.physics.newBody(_WORLD, self.x, self.y, "dynamic")
    self.physics.body:setFixedRotation(true)
    self.physics.body:setMass(25)
    self.physics.shape = love.physics.newRectangleShape(self.WIDTH, self.HEIGHT)
    self.physics.fixture = love.physics.newFixture(self.physics.body, self.physics.shape)
end

---Updates the WaterGirl.
---@param dt number Time delta in seconds
function WaterGirl:update(dt)
    -- Entity-related (this always needs to be here)
    self:updateMovement(dt)
    self:updateDirection()
    self:updateGravity(dt)
    self:updatePhysics()
    self:updateState()
    self:updateAnimation(dt)
    self:updateFlash(dt)
end

function WaterGirl:updateDirection()
    self.direction = self.x - _LEVEL.player.x > 0 and "left" or "right"
end

function WaterGirl:updateState()
    local playerClose = self:getProximityToPlayer() < self.ATTACK_RANGE
    if self.state == self.STATES.idle then
        self:setState("attack", playerClose)
    elseif self.state == self.STATES.attack then
    elseif self.state == self.STATES.defeat then
    end
end

function WaterGirl:getProximityToPlayer()
    return math.abs(self.x - _LEVEL.player.x)
end

function WaterGirl:beginContact(a, b, collision)
    local nx, ny = collision:getNormal()
    -- Handle hurting the player.
    local player = _LEVEL.player
    if a == self.physics.fixture and b == player.physics.fixture then
        player:hurt(nx < 0 and "left" or "right")
    elseif a == player.physics.fixture and b == self.physics.fixture then
        player:hurt(nx > 0 and "left" or "right")
    end
    -- Handle ground contact.
    if self.ground then
        return
    end
    -- We can be either `a` or `b` in the collision.
    if a == self.physics.fixture then
        if ny > 0 then
            self:landOn(b)
        end
    elseif b == self.physics.fixture then
        if ny < 0 then
            self:landOn(a)
        end
    end
end

function WaterGirl:endContact(a, b, collision)
    if a == self.physics.fixture then
        if self.ground == b then
            self.ground = nil
        end
    elseif b == self.physics.fixture then
        if self.ground == a then
            self.ground = nil
        end
    end
end

return WaterGirl