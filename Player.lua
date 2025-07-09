local Entity = require("Entity")

---@class Player : Entity
---@overload fun(x, y): Player
local Player = Entity:derive("Player")

---Constructs the Player.
function Player:new(x, y)
    -- Prepend default fields
    self.super:new(x, y)

    -- Parameters
    self.WIDTH, self.HEIGHT = 64, 128
    self.SCALE = 0.25
    self.MAX_SPEED = 600
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 2500
    self.JUMP_SPEED = -1000
    self.JUMP_DELAY_MAX = 1/15
    self.JUMP_GRACE_TIME_MAX = 0.1
    self.OFFSET_X, self.OFFSET_Y = 0, -28

    -- State
    self.x, self.y = x, y
    self.homeX, self.homeY = x, y
    self.speedX, self.speedY = 0, 0
    self.accX, self.accY = 0, 0
    self.direction = "right"
    self.ground = nil
    self.jumpDelay = nil
    self.jumpGraceTime = self.JUMP_GRACE_TIME_MAX

    -- Physics
    self.physics = {}
    self.physics.body = love.physics.newBody(_WORLD, self.x, self.y, "dynamic")
    self.physics.body:setFixedRotation(true)
    self.physics.shape = love.physics.newRectangleShape(self.WIDTH, self.HEIGHT)
    self.physics.fixture = love.physics.newFixture(self.physics.body, self.physics.shape)

    -- Appearance
    ---@type table<string, SpriteState>
    self.STATES = {
        idle = {state = "idle", start = 1, frames = 6, framerate = 15},
        run = {state = "run", start = 1, frames = 16, framerate = 30},
        jumpPrep = {state = "jump", start = 1, frames = 2, framerate = 30, onFinish = "jump"},
        jump = {state = "jump", start = 3, frames = 5, framerate = 15, onFinish = "fall"},
        fall = {state = "jump", start = 8, frames = 1, framerate = 15},
        land = {state = "jump", start = 9, frames = 2, framerate = 15, onFinish = "idle"}
    }
    self.state = self.STATES.idle
    self.sprites = _PLAYER_SPRITES
    self.stateFrame = 1
    self.stateTime = 0
end

---Updates the Player.
---@param dt number Time delta in seconds
function Player:update(dt)
    self:move(dt)
    self:updateJumpDelay(dt)
    self:updateJumpGrace(dt)
    -- Entity-related (this always needs to be here)
    self:updateDirection()
    self:updateGravity(dt)
    self:updatePhysics()
    self:updateState()
    self:updateAnimation(dt)
    self:updateFlash(dt)
end

function Player:move(dt)
    -- Calculate the current acceleration.
    local left = love.keyboard.isDown("a", "left")
    local right = love.keyboard.isDown("d", "right")
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

function Player:updateJumpDelay(dt)
    if not self.jumpDelay then
        return
    end
    self.jumpDelay = math.max(self.jumpDelay - dt, 0)
    if self.jumpDelay == 0 then
        self.ground = nil
        self.speedY = self.JUMP_SPEED
        self.jumpDelay = nil
    end
end

function Player:updateJumpGrace(dt)
    if self.ground then
        self.jumpGraceTime = self.JUMP_GRACE_TIME_MAX
    else
        self.jumpGraceTime = math.max(self.jumpGraceTime - dt, 0)
    end
end

function Player:jump()
    if (not self.ground and self.jumpGraceTime <= 0) or self.jumpDelay then
        return
    end
    self.jumpDelay = self.JUMP_DELAY_MAX
    self.jumpGraceTime = 0
end

function Player:landOn(ground)
    self.ground = ground
    self.speedY = 0
end

function Player:updateState()
    local moving = self.speedX ~= 0 and (self.accX ~= 0 or math.abs(self.speedX) > 300)
    local jumping = (not self.ground and self.speedY < 0) or self.jumpDelay ~= nil
    local falling = not self.ground and self.speedY > 0
    local landing = self.ground ~= nil and not self.jumpDelay
    if self.state == self.STATES.idle then
        self:setState("run", moving)
        self:setState("jumpPrep", jumping)
        self:setState("fall", falling)
    elseif self.state == self.STATES.run then
        self:setState("idle", not moving)
        self:setState("jumpPrep", jumping)
        self:setState("fall", falling)
    elseif self.state == self.STATES.jumpPrep then
        self:setState("land", landing)
    elseif self.state == self.STATES.jump then
        self:setState("land", landing)
    elseif self.state == self.STATES.fall then
        self:setState("land", landing)
    elseif self.state == self.STATES.land then
        self:setState("run", moving)
    end
end

---Executed when key is pressed.
---@param key string The keycode.
function Player:keypressed(key)
    if key == "w" or key == "up" then
        self:jump()
        self:flash()
    end
end

function Player:beginContact(a, b, collision)
    if self.ground then
        return
    end
    local nx, ny = collision:getNormal()
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

function Player:endContact(a, b, collision)
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

return Player