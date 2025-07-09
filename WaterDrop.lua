local Entity = require("Entity")

---@class WaterDrop : Entity
---@overload fun(x, y): WaterDrop
local WaterDrop = Entity:derive("WaterDrop")

---Constructs the WaterDrop.
function WaterDrop:new(x, y)
    -- Parameters
    self.WIDTH, self.HEIGHT = 64, 80
    self.SCALE = 0.25
    self.OFFSET_X, self.OFFSET_Y = 0, -70
    self.MAX_SPEED = 100
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 2500
    self.STRAFE_RANGE = 100
    self.PLAYER_DETECTION_RANGE = 200
    ---@type table<string, SpriteState>
    self.STATES = {
        idle = {state = "idle", start = 1, frames = 4, framerate = 10, noFlip = true},
        rise = {state = "rise", start = 1, frames = 5, framerate = 10, onFinish = "move"},
        move = {state = "move", start = 1, frames = 4, framerate = 10},
        defeat = {state = "defeat", start = 1, frames = 5, framerate = 10, delOnFinish = true}
    }
    self.STARTING_STATE = self.STATES.idle
    self.SPRITES = _WATER_DROP_SPRITES

    -- Prepend default fields
    self.super:new(x, y)

    -- State
    self.x, self.y = x, y
    self.homeX, self.homeY = x, y
    self.speedX, self.speedY = 0, 0
    self.accX, self.accY = 0, 0
    self.direction = "right"
    self.ground = nil
    self.targetDirection = "left" -- Used when idling to strafe left and right

    -- Physics
    self.physics = {}
    self.physics.body = love.physics.newBody(_WORLD, self.x, self.y, "dynamic")
    self.physics.body:setFixedRotation(true)
    self.physics.body:setMass(25)
    self.physics.shape = love.physics.newRectangleShape(self.WIDTH, self.HEIGHT)
    self.physics.fixture = love.physics.newFixture(self.physics.body, self.physics.shape)

    -- Appearance
    self.state = self.STARTING_STATE
    self.stateFrame = 1
    self.stateTime = 0
end

---Updates the WaterDrop.
---@param dt number Time delta in seconds
function WaterDrop:update(dt)
    self:move(dt)
    -- Entity-related (this always needs to be here)
    self:updateDirection()
    self:updateGravity(dt)
    self:updatePhysics()
    self:updateState()
    self:updateAnimation(dt)
    self:updateFlash(dt)
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
    if left and not right then
        self.accX = -self.MAX_ACC
    elseif right and not left then
        self.accX = self.MAX_ACC
    else
        self.accX = 0
        self:applyDrag(dt)
    end
    -- Apply the acceleration and cap the speed.
    self.speedX = math.min(math.max(self.speedX + self.accX * dt, -self.MAX_SPEED), self.MAX_SPEED)
end

function WaterDrop:landOn(ground)
    self.ground = ground
    self.speedY = 0
end

function WaterDrop:updateState()
    local playerClose = self:getProximityToPlayer() < self.PLAYER_DETECTION_RANGE
    if self.state == self.STATES.idle then
        self:setState("rise", playerClose)
    elseif self.state == self.STATES.rise then
    elseif self.state == self.STATES.move then
    elseif self.state == self.STATES.defeat then
    end
end

function WaterDrop:getProximityToPlayer()
    return math.abs(self.x - _LEVEL.player.x)
end

function WaterDrop:beginContact(a, b, collision)
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

function WaterDrop:endContact(a, b, collision)
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

return WaterDrop