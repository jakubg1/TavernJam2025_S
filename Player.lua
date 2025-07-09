local Class = require("com.class")

---@class Player : Class
---@overload fun(x, y): Player
local Player = Class:derive("Player")

---Constructs the Player.
function Player:new(x, y)
    -- Parameters
    self.SCALE = 0.25
    self.MAX_SPEED = 600
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 2500
    self.JUMP_SPEED = -1000
    self.JUMP_GRACE_TIME_MAX = 0.1

    -- State
    self.x, self.y = x, y
    self.width, self.height = 64, 128
    self.speedX, self.speedY = 0, 0
    self.accX, self.accY = 0, 0
    self.direction = "right"
    self.ground = nil
    self.jumpGraceTime = self.JUMP_GRACE_TIME_MAX

    -- Physics
    self.physics = {}
    self.physics.body = love.physics.newBody(_WORLD, self.x, self.y, "dynamic")
    self.physics.body:setFixedRotation(true)
    self.physics.shape = love.physics.newRectangleShape(self.width, self.height)
    self.physics.fixture = love.physics.newFixture(self.physics.body, self.physics.shape)

    -- Appearance
    ---@alias SpriteState {state: string, start: integer, frames: integer, framerate: number, onFinish: string?, delOnFinish: boolean?}
    ---@type table<string, SpriteState>
    self.STATES = {
        idle = {state = "idle", start = 1, frames = 6, framerate = 15},
        run = {state = "run", start = 1, frames = 16, framerate = 30},
        jump = {state = "jump", start = 1, frames = 9, framerate = 15, onFinish = "fall"},
        fall = {state = "jump", start = 10, frames = 1, framerate = 15},
        land = {state = "jump", start = 11, frames = 2, framerate = 15, onFinish = "idle"}
    }
    self.sprites = _PLAYER_SPRITES
    self.state = self.STATES.idle
    self.stateFrame = 1
    self.stateTime = 0
end

---Updates the Player.
---@param dt number Time delta in seconds
function Player:update(dt)
    self:updatePhysics()
    self:move(dt)
    self:updateDirection()
    self:updateGravity(dt)
    self:updateJumpGrace(dt)
    self:updateSprite(dt)
end

function Player:updatePhysics()
    self.x, self.y = self.physics.body:getPosition()
    self.physics.body:setLinearVelocity(self.speedX, self.speedY)
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

function Player:applyDrag(dt)
    if self.speedX > 0 then
        self.speedX = math.max(self.speedX - self.DRAG * dt, 0)
    else
        self.speedX = math.min(self.speedX + self.DRAG * dt, 0)
    end
end

function Player:updateDirection()
    if self.accX > 0 then
        self.direction = "right"
    elseif self.accX < 0 then
        self.direction = "left"
    end
end

function Player:updateGravity(dt)
    if self.ground then
        return
    end
    self.speedY = self.speedY + self.GRAVITY * dt
end

function Player:updateJumpGrace(dt)
    if self.ground then
        self.jumpGraceTime = self.JUMP_GRACE_TIME_MAX
    else
        self.jumpGraceTime = self.jumpGraceTime - dt
    end
end

function Player:jump()
    if not self.ground and self.jumpGraceTime <= 0 then
        return
    end
    self.ground = nil
    self.speedY = self.JUMP_SPEED
    self.jumpGraceTime = 0
end

function Player:landOn(ground)
    self.ground = ground
    self.speedY = 0
end

function Player:updateSprite(dt)
    local moving = self.speedX ~= 0 and (self.accX ~= 0 or math.abs(self.speedX) > 300)
    local jumping = not self.ground and self.speedY < 0
    local falling = not self.ground and self.speedY > 0
    local landing = self.ground ~= nil
    if self.state == self.STATES.idle then
        self:setState("run", moving)
        self:setState("jump", jumping)
        self:setState("fall", falling)
    elseif self.state == self.STATES.run then
        self:setState("idle", not moving)
        self:setState("jump", jumping)
        self:setState("fall", falling)
    elseif self.state == self.STATES.jump then
        self:setState("land", landing)
    elseif self.state == self.STATES.fall then
        self:setState("land", landing)
    elseif self.state == self.STATES.land then
        self:setState("run", moving)
    end

    -- Update the animation frame.
    self.stateTime = self.stateTime + dt
    while self.stateTime > 1 / self.state.framerate do
        -- Advance to next frame.
        self.stateTime = self.stateTime - 1 / self.state.framerate
        if self.stateFrame < self.state.start + self.state.frames - 1 then
            self.stateFrame = self.stateFrame + 1
        else
            -- Loop or change to other state.
            if self.state.onFinish then
                self:setState(self.state.onFinish)
            else
                self.stateFrame = self.state.start
            end
        end
    end
end

---Sets a new state for this player, unless we already have that state.
---@param state string The new state.
---@param condition boolean? Optional condition. Must be satisfied to perform the change. Useful for compact code when you need to cram a lot of calls to this function in a row.
function Player:setState(state, condition)
    -- Fail immediately if the condition is not satisfied.
    if condition == false then
        return
    end
    -- Cannot transition into the same state.
    if self.state == self.STATES[state] then
        return
    end
    self.state = self.STATES[state]
    self.stateFrame = self.state.start
    self.stateTime = 0
end

---Executed when key is pressed.
---@param key string The keycode.
function Player:keypressed(key)
    if key == "w" or key == "up" then
        self:jump()
    end
end

---Executed when key is released.
---@param key string The keycode.
function Player:keyreleased(key)

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

---Draws the Player on the screen.
function Player:draw()
    love.graphics.setColor(1, 1, 1)
    local img = self.sprites:getImage(self.state.state, self.stateFrame)
    local horizontalScale = self.direction == "right" and self.SCALE or -self.SCALE
    love.graphics.draw(img, self.x, self.y - 28, 0, horizontalScale, self.SCALE, self.sprites.imageWidth / 2, self.sprites.imageHeight / 2)

    love.graphics.rectangle("line", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height)
end

return Player