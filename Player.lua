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
    self.MAX_HEALTH = 4
    self.KNOCK_X, self.KNOCK_Y = 600, 600
    self.KNOCK_TIME_MAX = 10.3
    self.INVUL_TIME_MAX = 1
    ---@type table<string, SpriteState>
    self.STATES = {
        idle = {state = "idle", start = 1, frames = 6, framerate = 15},
        run = {state = "run", start = 1, frames = 16, framerate = 30},
        jumpPrep = {state = "jump", start = 1, frames = 2, framerate = 30, onFinish = "jump"},
        jump = {state = "jump", start = 3, frames = 5, framerate = 15, onFinish = "fall"},
        fall = {state = "jump", start = 8, frames = 1, framerate = 15},
        land = {state = "jump", start = 9, frames = 2, framerate = 15, onFinish = "idle"},
        punchLeft = {state = "leftpunch", start = 1, frames = 7, framerate = 30, onFinish = "idle"},
        punchRight = {state = "rightpunch", start = 1, frames = 7, framerate = 30, onFinish = "idle"}
    }
    self.STARTING_STATE = self.STATES.idle
    self.SPRITES = _SPRITES.player

    -- Player exclusive parameters
    self.JUMP_SPEED = -1000
    self.JUMP_DELAY_MAX = 1/15
    self.JUMP_GRACE_TIME_MAX = 0.1
    self.ATTACK_DELAY = 0.15
    self.ATTACK_RANGE = 80 -- The width of attack hitboxes

    -- Physics
    ---@type table<string, PhysicsShape>
    self.PHYSICS_SHAPES = {
        main = {collidable = true},
        attackLeft = {offsetX = -self.ATTACK_RANGE / 2 - self.WIDTH / 2, width = self.ATTACK_RANGE},
        attackRight = {offsetX = self.ATTACK_RANGE / 2 + self.WIDTH / 2, width = self.ATTACK_RANGE}
    }

    -- Prepend default fields
    self.super.new(self, x, y)

    -- State
    self.jumpDelay = nil
    self.jumpGraceTime = self.JUMP_GRACE_TIME_MAX
    self.attackTime = nil
    self.nextPunchRight = false
end

---Updates the Player.
---@param dt number Time delta in seconds
function Player:update(dt)
    self:move(dt)
    self:updateJumpDelay(dt)
    self:updateJumpGrace(dt)
    self:updateAttack(dt)
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

function Player:updateAttack(dt)
    if not self.attackTime then
        return
    end
    self.attackTime = math.max(self.attackTime - dt, 0)
    if self.attackTime == 0 then
        self.attackTime = nil
        -- Hurt at most one enemy.
        for i, enemy in ipairs(_LEVEL.enemies) do
            local attackHitbox = self.direction == "left" and self.physics.shapes.attackLeft or self.physics.shapes.attackRight
            if attackHitbox.collidingWith[enemy.physics.shapes.main.fixture] then
                enemy:hurt(self.direction)
                break
            end
        end
    end
end

function Player:jump()
    if (not self.ground and self.jumpGraceTime <= 0) or self.jumpDelay then
        return
    end
    self.jumpDelay = self.JUMP_DELAY_MAX
    self.jumpGraceTime = 0
end

function Player:attack()
    if self.attackTime then
        return
    end
    if self.state == self.STATES.idle or self.state == self.STATES.run or self.state == self.STATES.punchLeft or self.state == self.STATES.punchRight then
        self.attackTime = self.ATTACK_DELAY
        self.nextPunchRight = not self.nextPunchRight
    end
end

function Player:updateState()
    local moving = self.speedX ~= 0 and (self.accX ~= 0 or math.abs(self.speedX) > 300)
    local jumping = (not self.ground and self.speedY < 0) or self.jumpDelay ~= nil
    local falling = not self.ground and self.speedY > 0
    local landing = self.ground ~= nil and not self.jumpDelay
    local attacking = self.attackTime ~= nil
    local attackRight = self.nextPunchRight
    if self.state == self.STATES.idle then
        self:setState("run", moving)
        self:setState("jumpPrep", jumping)
        self:setState("fall", falling)
        self:setState("punchLeft", attacking and not attackRight)
        self:setState("punchRight", attacking and attackRight)
    elseif self.state == self.STATES.run then
        self:setState("idle", not moving)
        self:setState("jumpPrep", jumping)
        self:setState("fall", falling)
        self:setState("punchLeft", attacking and not attackRight)
        self:setState("punchRight", attacking and attackRight)
    elseif self.state == self.STATES.jumpPrep then
        self:setState("land", landing)
    elseif self.state == self.STATES.jump then
        self:setState("land", landing)
    elseif self.state == self.STATES.fall then
        self:setState("land", landing)
    elseif self.state == self.STATES.land then
        self:setState("run", moving)
    elseif self.state == self.STATES.punchLeft then
        self:setState("punchRight", attacking and attackRight)
    elseif self.state == self.STATES.punchRight then
        self:setState("punchLeft", attacking and not attackRight)
    end
end

---Executed when key is pressed.
---@param key string The keycode.
function Player:keypressed(key)
    if key == "w" or key == "up" then
        self:jump()
    elseif key == "z" then
        self:attack()
    end
end

return Player