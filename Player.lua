local Class = require("com.class")

---@class Player : Class
---@overload fun(): Player
local Player = Class:derive("Player")

---Constructs the Player.
function Player:new()
    -- Parameters
    self.SCALE = 0.8
    self.MAX_SPEED = 600
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 2000
    self.JUMP_SPEED = -1000

    -- State
    self.x, self.y = 100, 600
    self.width, self.height = 168 * self.SCALE, 244 * self.SCALE
    self.speedX, self.speedY = 0, 0
    self.accX, self.accY = 0, 0
    self.direction = 1 -- Direction: -1 - left, 1 - right
    self.ground = nil

    -- Physics
    self.physics = {}
    self.physics.body = love.physics.newBody(_WORLD, self.x, self.y, "dynamic")
    self.physics.body:setFixedRotation(true)
    self.physics.shape = love.physics.newRectangleShape(self.width, self.height)
    self.physics.fixture = love.physics.newFixture(self.physics.body, self.physics.shape)

    -- Appearance
    self.SPRITE_STATES = {
        idle = {start = 1, frames = 6, framerate = 10},
        jumping = {start = 17, frames = 12, framerate = 10},
        running = {start = 33, frames = 16, framerate = 30}
    }
    self.sprites = _PLAYER_SPRITES
    self.state = "idle"
    self.stateTime = 0
end

---Updates the Player.
---@param dt number Time delta in seconds
function Player:update(dt)
    self:updatePhysics()
    self:move(dt)
    self:updateGravity(dt)
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
    self.accX = 0
    if left and not right then
        self.accX = -self.MAX_ACC
        self.direction = -1
    elseif right and not left then
        self.accX = self.MAX_ACC
        self.direction = 1
    end
    -- Apply the acceleration.
    self.speedX = self.speedX + self.accX * dt
    -- Apply drag when the player is not accelerating but still moving.
    if self.accX == 0 then
        self:applyDrag(dt)
    end
    -- Cap the speed.
    if self.speedX > self.MAX_SPEED then
        self.speedX = self.MAX_SPEED
    elseif self.speedX < -self.MAX_SPEED then
        self.speedX = -self.MAX_SPEED
    end
end

function Player:applyDrag(dt)
    if self.speedX > 0 then
        self.speedX = math.max(self.speedX - self.DRAG * dt, 0)
    else
        self.speedX = math.min(self.speedX + self.DRAG * dt, 0)
    end
end

function Player:updateGravity(dt)
    if self.ground then
        return
    end
    self.speedY = self.speedY + self.GRAVITY * dt
end

function Player:landOn(ground)
    self.ground = ground
    self.speedY = 0
end

function Player:updateSprite(dt)
    -- Update the animation state.
    if self.speedX == 0 or self.accX == 0 and math.abs(self.speedX) < 300 then
        self:setSpriteState("idle")
    else
        self:setSpriteState("running")
    end
    self.stateTime = self.stateTime + dt
end

---Sets a new sprite state for this player, unless we already have that state.
---@param state string The new state.
function Player:setSpriteState(state)
    if self.state == state then
        return
    end
    self.state = state
    self.stateTime = 0
end

---Executed when key is pressed.
---@param key string The keycode.
function Player:keypressed(key)
    if (key == "w" or key == "up") and self.ground then
        self.speedY = self.JUMP_SPEED
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
    local state = self.SPRITE_STATES[self.state]
    local frame = state.start + math.floor(self.stateTime * state.framerate) % state.frames
    self.sprites:drawFrame(frame, self.x - self.width / 2, self.y - self.height / 2 + 5, self.SCALE, self.direction == -1)

    love.graphics.rectangle("line", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height)
end

return Player