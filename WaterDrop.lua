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
    self.FLIP_AXIS_OFFSET = 0
    self.MAX_SPEED = 100
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 2500
    ---@type table<string, SpriteState>
    self.STATES = {
        idle = {state = "idle", start = 1, frames = 4, framerate = 10, noFlip = true},
        rise = {state = "rise", start = 1, frames = 5, framerate = 10, onFinish = "move"},
        move = {state = "move", start = 1, frames = 4, framerate = 10},
        defeat = {state = "defeat", start = 1, frames = 5, framerate = 10, delOnFinish = true},
        sleep = {state = "rise", start = 1, frames = 5, framerate = 10, onFinish = "idle", reverse = true}
    }
    self.STARTING_STATE = self.STATES.idle
    self.SPRITES = _WATER_DROP_SPRITES

    -- Water Drop exclusive parameters
    self.STRAFE_RANGE = 100
    self.PLAYER_DETECTION_RANGE = 200
    self.SLEEP_DELAY_MAX = 3
    self.SLEEP_SAFE_DISTANCE = 400

    -- Prepend default fields
    self.super.new(self, x, y)

    -- State
    self.targetDirection = "left" -- Used when idling to strafe left and right
    self.sleepDelay = self.SLEEP_DELAY_MAX

    -- Physics
    self.physics = {}
    self.physics.body = love.physics.newBody(_WORLD, self.x, self.y, "dynamic")
    self.physics.body:setFixedRotation(true)
    self.physics.body:setMass(25)
    self.physics.shape = love.physics.newRectangleShape(self.WIDTH, self.HEIGHT)
    self.physics.colliderFixture = love.physics.newFixture(self.physics.body, self.physics.shape)
    self.physics.colliderFixture:setCategory(2)
    self.physics.colliderFixture:setMask(2)
    self.physics.sensorFixture = love.physics.newFixture(self.physics.body, self.physics.shape)
    self.physics.sensorFixture:setSensor(true)
end

---Updates the WaterDrop.
---@param dt number Time delta in seconds
function WaterDrop:update(dt)
    self:move(dt)
    self:updateSleep(dt)
    -- Entity-related (this always needs to be here)
    self:updateMovement(dt)
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
    if self.state == self.STATES.idle then
        self:setState("rise", playerClose)
    elseif self.state == self.STATES.rise then
    elseif self.state == self.STATES.move then
        self:setState("sleep", sleep)
    elseif self.state == self.STATES.defeat then
    elseif self.state == self.STATES.sleep then
    end
end

function WaterDrop:getProximityToPlayer()
    return math.abs(self.x - _LEVEL.player.x)
end

function WaterDrop:beginContact(a, b, collision)
    -- Update collisions.
    if a == self.physics.sensorFixture then
        self.collidingWith[b] = true
    elseif b == self.physics.sensorFixture then
        self.collidingWith[a] = true
    end

    local nx, ny = collision:getNormal()
    -- Handle hurting the player.
    local player = _LEVEL.player
    if a == self.physics.sensorFixture and b == player.physics.sensorFixture then
        player:hurt(player.x < self.x and "left" or "right")
    elseif a == player.physics.sensorFixture and b == self.physics.sensorFixture then
        player:hurt(player.x < self.x and "left" or "right")
    end
    -- Handle ground contact.
    if self.ground then
        return
    end
    -- We can be either `a` or `b` in the collision.
    if a == self.physics.colliderFixture then
        if ny > 0 then
            self:landOn(b)
        end
    elseif b == self.physics.colliderFixture then
        if ny < 0 then
            self:landOn(a)
        end
    end
end

function WaterDrop:endContact(a, b, collision)
    -- Update collisions.
    if a == self.physics.sensorFixture then
        self.collidingWith[b] = nil
    elseif b == self.physics.sensorFixture then
        self.collidingWith[a] = nil
    end

    if a == self.physics.colliderFixture then
        if self.ground == b then
            self.ground = nil
        end
    elseif b == self.physics.colliderFixture then
        if self.ground == a then
            self.ground = nil
        end
    end
end

return WaterDrop