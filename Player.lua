local Class = require("com.class")

---@class Player : Class
---@overload fun(): Player
local Player = Class:derive("Player")

---Constructs the Player.
function Player:new()
    self.x, self.y = 100, 600
    self.speedX, self.speedY = 0, 0
    self.accX, self.accY = 0, 0
    self.MAX_SPEED = 600
    self.MAX_ACC = 4000
    self.DRAG = 1000
    self.direction = 1 -- Direction: -1 - left, 1 - right

    self.sprites = _PLAYER_SPRITES
    self.SPRITE_STATES = {
        idle = {start = 1, frames = 6, framerate = 10},
        jumping = {start = 17, frames = 12, framerate = 10},
        running = {start = 33, frames = 16, framerate = 30}
    }
    self.state = "idle"
    self.stateTime = 0
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

---Updates the Player.
---@param dt number Time delta in seconds
function Player:update(dt)
    -- Calculate the current acceleration.
    local left = love.keyboard.isDown("left")
    local right = love.keyboard.isDown("right")
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
        if self.speedX > 0 then
            self.speedX = math.max(self.speedX - self.DRAG * dt, 0)
        else
            self.speedX = math.min(self.speedX + self.DRAG * dt, 0)
        end
    end
    -- Cap the speed.
    if self.speedX > self.MAX_SPEED then
        self.speedX = self.MAX_SPEED
    elseif self.speedX < -self.MAX_SPEED then
        self.speedX = -self.MAX_SPEED
    end
    -- Update the position.
    self.x = self.x + self.speedX * dt

    -- Update the animation state.
    if self.speedX == 0 or self.accX == 0 and math.abs(self.speedX) < 500 then
        self:setSpriteState("idle")
    else
        self:setSpriteState("running")
    end
    self.stateTime = self.stateTime + dt
end

---Draws the Player on the screen.
function Player:draw()
    local state = self.SPRITE_STATES[self.state]
    local frame = state.start + math.floor(self.stateTime * state.framerate) % state.frames
    self.sprites:drawFrame(frame, self.x, self.y, self.direction == -1)
end

---Executed when key is pressed.
---@param key string The keycode.
function Player:keypressed(key)
end

---Executed when key is released.
---@param key string The keycode.
function Player:keyreleased(key)
end

return Player