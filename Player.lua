local Entity = require("Entity")

---@class Player : Entity
---@overload fun(x, y): Player
local Player = Entity:derive("Player")

---Constructs the Player.
function Player:new(x, y)
    -- Parameters
    self.WIDTH, self.HEIGHT = 64, 128
    self.SCALE = 0.25
    self.OFFSET_X, self.OFFSET_Y = 0, -28
    self.FLIP_AXIS_OFFSET = 0
    self.MAX_SPEED = 600
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 2500
    ---@type table<string, SpriteState>
    self.STATES = {
        idle = {state = "idle", start = 1, frames = 6, framerate = 15},
        run = {state = "run", start = 1, frames = 16, framerate = 30},
        jumpPrep = {state = "jump", start = 1, frames = 2, framerate = 30, onFinish = "jump"},
        jump = {state = "jump", start = 3, frames = 5, framerate = 15, onFinish = "fall"},
        fall = {state = "jump", start = 8, frames = 1, framerate = 15},
        land = {state = "jump", start = 9, frames = 2, framerate = 15, onFinish = "idle"}
    }
    self.STARTING_STATE = self.STATES.idle
    self.SPRITES = _SPRITES.player

    -- Player exclusive parameters
    self.JUMP_SPEED = -1000
    self.JUMP_DELAY_MAX = 1/15
    self.JUMP_GRACE_TIME_MAX = 0.1
    self.KNOCK_TIME_MAX = 0.3
    self.INVUL_TIME_MAX = 1

    -- Physics
    ---@type table<string, PhysicsShape>
    self.PHYSICS_SHAPES = {
        main = {collidable = true}
    }

    -- Prepend default fields
    self.super.new(self, x, y)

    -- State
    self.jumpDelay = nil
    self.jumpGraceTime = self.JUMP_GRACE_TIME_MAX
    self.knockTime = nil -- Makes the player ignore max speed and removes player control.
    self.invulTime = nil
end

---Updates the Player.
---@param dt number Time delta in seconds
function Player:update(dt)
    self:move(dt)
    self:updateJumpDelay(dt)
    self:updateJumpGrace(dt)
    self:updateKnock(dt)
    self:updateInvulnerability(dt)
    self.super.update(self, dt)
end

function Player:move(dt)
    -- Calculate the current acceleration.
    local left = love.keyboard.isDown("a", "left")
    local right = love.keyboard.isDown("d", "right")
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

function Player:updateJumpDelay(dt)
    if not self.jumpDelay then
        return
    end
    self.jumpDelay = math.max(self.jumpDelay - dt, 0)
    if self.jumpDelay == 0 then
        -- We need to reset ground here, because `endContact` will trigger in the next frame, causing the `jumpPrep` state to repeat.
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

function Player:updateKnock(dt)
    if not self.knockTime then
        return
    end
    self.knockTime = math.max(self.knockTime - dt, 0)
    if self.knockTime == 0 or self.ground then
        self.knockTime = nil
    end
end

function Player:updateInvulnerability(dt)
    if not self.invulTime then
        return
    end
    self.invulTime = math.max(self.invulTime - dt, 0)
    if self.invulTime == 0 then
        self.invulTime = nil
    end
end

function Player:jump()
    if (not self.ground and self.jumpGraceTime <= 0) or self.jumpDelay then
        return
    end
    self.jumpDelay = self.JUMP_DELAY_MAX
    self.jumpGraceTime = 0
end

function Player:knock(speedX, speedY)
    self.speedX = speedX
    self.speedY = speedY
    self.knockTime = self.KNOCK_TIME_MAX
    -- We need to reset ground here, because `endContact` will trigger in the next frame, causing the `knockTime` state to immediately reset.
    self.ground = nil
end

function Player:hurt(direction)
    if self.invulTime then
        return
    end
    self:knock(direction == "left" and -600 or 600, -400)
    self:flash()
    self.invulTime = self.INVUL_TIME_MAX
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
    end
end

return Player