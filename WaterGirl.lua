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
        idle = {state = "idle", start = 1, frames = 5, framerate = 15},
        attack = {state = "attack", start = 1, frames = 13, framerate = 15, onFinish = "idle"},
        defeat = {state = "defeat", start = 1, frames = 5, framerate = 15, delOnFinish = true}
    }
    self.STARTING_STATE = self.STATES.idle
    self.SPRITES = _WATER_GIRL_SPRITES

    -- Water Girl exclusive parameters
    self.ATTACK_RANGE = 135 -- The width of attack hitboxes
    self.ATTACK_RANGE_ADVANCE = 100 -- The additional amount of pixels in front of which she will attack
    self.ATTACK_COOLDOWN_MIN = 3
    self.ATTACK_COOLDOWN_MAX = 5

    -- Prepend default fields
    self.super.new(self, x, y)

    -- State
    self.attackCooldown = nil
    self.leftCollidingWith = {}
    self.rightCollidingWith = {}

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
    self.physics.attackLeftShape = love.physics.newRectangleShape(-self.ATTACK_RANGE / 2 - self.WIDTH / 2, 0, self.ATTACK_RANGE, self.HEIGHT)
    self.physics.attackLeftFixture = love.physics.newFixture(self.physics.body, self.physics.attackLeftShape)
    self.physics.attackLeftFixture:setSensor(true)
    self.physics.attackRightShape = love.physics.newRectangleShape(self.ATTACK_RANGE / 2 + self.WIDTH / 2, 0, self.ATTACK_RANGE, self.HEIGHT)
    self.physics.attackRightFixture = love.physics.newFixture(self.physics.body, self.physics.attackRightShape)
    self.physics.attackRightFixture:setSensor(true)
end

---Updates the WaterGirl.
---@param dt number Time delta in seconds
function WaterGirl:update(dt)
    self:updateAttack()
    self:updateAttackCooldown(dt)
    -- Entity-related (this always needs to be here)
    self:updateMovement(dt)
    self:updateDirection()
    self:updateGravity(dt)
    self:updatePhysics()
    self:updateState()
    self:updateAnimation(dt)
    self:updateFlash(dt)
end

function WaterGirl:updateAttack()
    local player = _LEVEL.player
    if self.state == self.STATES.attack and self.stateFrame > 4 then
        local leftCollision = self.collidingWith[player.physics.sensorFixture] or self.leftCollidingWith[player.physics.sensorFixture]
        local rightCollision = self.collidingWith[player.physics.sensorFixture] or self.rightCollidingWith[player.physics.sensorFixture]
        if self.direction == "left" and leftCollision or self.direction == "right" and rightCollision then
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
    local playerClose = self:getProximityToPlayer() < self.ATTACK_RANGE + self.ATTACK_RANGE_ADVANCE
    local canAttack = not self.attackCooldown
    if self.state == self.STATES.idle then
        self:setState("attack", playerClose and canAttack)
    elseif self.state == self.STATES.attack then
    elseif self.state == self.STATES.defeat then
    end
end

function WaterGirl:getProximityToPlayer()
    return math.abs(self.x - _LEVEL.player.x)
end

function WaterGirl:beginContact(a, b, collision)
    -- Update collisions.
    if a == self.physics.sensorFixture then
        self.collidingWith[b] = true
    elseif b == self.physics.sensorFixture then
        self.collidingWith[a] = true
    end

    if a == self.physics.attackLeftFixture then
        self.leftCollidingWith[b] = true
    elseif b == self.physics.attackLeftFixture then
        self.leftCollidingWith[a] = true
    end

    if a == self.physics.attackRightFixture then
        self.rightCollidingWith[b] = true
    elseif b == self.physics.attackRightFixture then
        self.rightCollidingWith[a] = true
    end

    local nx, ny = collision:getNormal()
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

function WaterGirl:endContact(a, b, collision)
    -- Update collisions.
    if a == self.physics.sensorFixture then
        self.collidingWith[b] = nil
    elseif b == self.physics.sensorFixture then
        self.collidingWith[a] = nil
    end

    if a == self.physics.attackLeftFixture then
        self.leftCollidingWith[b] = nil
    elseif b == self.physics.attackLeftFixture then
        self.leftCollidingWith[a] = nil
    end

    if a == self.physics.attackRightFixture then
        self.rightCollidingWith[b] = nil
    elseif b == self.physics.attackRightFixture then
        self.rightCollidingWith[a] = nil
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

return WaterGirl