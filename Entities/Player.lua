local Entity = require("Entity")

---@class Player : Entity
---@overload fun(x, y): Player
local Player = Entity:derive("Player")

---Constructs the Player.
function Player:new(x, y)
    -- Parameters
    self.WIDTH, self.HEIGHT = 80, 160
    self.SCALE = 0.3125
    self.OFFSET_X, self.OFFSET_Y = 0, -35
    self.FLIP_AXIS_OFFSET = 0
    self.IS_ENEMY = false
    self.MAX_SPEED = 700
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 2500
    self.MAX_HEALTH = 12
    self.KNOCK_X, self.KNOCK_Y = 600, 600
    self.KNOCK_TIME_MAX = 10.3
    self.INVUL_TIME_MAX = 0.5
    ---@type table<string, SpriteState>
    self.STATES = {
        idle = {state = "idle", start = 1, frames = 6, framerate = 15},
        run = {state = "run", start = 1, frames = 16, framerate = 30},
        jumpPrep = {state = "jump", start = 1, frames = 2, framerate = 30, onFinish = "jump"},
        jump = {state = "jump", start = 3, frames = 6, framerate = 15, onFinish = "fall"},
        fall = {state = "fall", start = 1, frames = 2, framerate = 15},
        land = {state = "jump", start = 9, frames = 2, framerate = 15, onFinish = "idle"},
        slideStart = {state = "walljump", start = 1, frames = 4, framerate = 15, offsetX = 25, onFinish = "slide"},
        slide = {state = "walljump", start = 5, frames = 2, framerate = 15, offsetX = 25},
        punchLeft = {state = "leftpunch", start = 1, frames = 7, framerate = 30, onFinish = "idle"},
        punchRight = {state = "rightpunch", start = 1, frames = 7, framerate = 30, onFinish = "idle"},
        dropKick = {state = "dropkick", start = 1, frames = 6, framerate = 15, onFinish = "fall"},
        defeat = {state = "ko", start = 1, frames = 8, framerate = 10, onFinish = "dead"},
        dead = {state = "ko", start = 8, frames = 1, framerate = 15}
    }
    self.STARTING_STATE = self.STATES.idle
    self.SPRITES = _SPRITES.player

    -- Player exclusive parameters
    self.JUMP_SPEED = -1000
    self.JUMP_DELAY_MAX = 1/15
    self.JUMP_GRACE_TIME_MAX = 0.1
    self.WALL_JUMP_SPEED_X = 1000
    self.WALL_JUMP_SPEED_Y = -1000
    self.WALL_JUMP_DIRECTION_HANDICAP_TIME_MAX = 0.1 -- How long should the player automatically be held the opposite direction button so they don't instantly snap to wall again
    self.ATTACK_DELAY = 0.15
    self.ATTACK_RANGE = 80 -- The width of attack hitboxes
    self.DROP_ATTACK_SPEED = -700
    self.DROP_ATTACK_RANGE = 80

    -- Physics
    ---@type table<string, AttackArea>
    self.ATTACK_AREAS = {
        attackLeft = {offsetX = -self.ATTACK_RANGE, width = self.ATTACK_RANGE},
        attackRight = {offsetX = self.WIDTH, width = self.ATTACK_RANGE},
        attackDrop = {offsetX = -self.WIDTH * 0.5, offsetY = self.HEIGHT, width = self.WIDTH * 2, height = self.DROP_ATTACK_RANGE}
    }

    -- Prepend default fields
    self.super.new(self, x, y)

    -- State
    self.jumpDelay = nil
    self.jumpGraceTime = self.JUMP_GRACE_TIME_MAX
    self.wallJumpDirectionHandicapTime = nil
    self.lastWallJumpDirection = nil
    self.attackTime = nil
    self.nextPunchRight = false
end

---Updates the Player.
---@param dt number Time delta in seconds
function Player:update(dt)
    self:move(dt)
    self:updateJumpDelay(dt)
    self:updateJumpGrace(dt)
    self:updateWallJumpDirectionHandicapTime(dt)
    self:updateWallJumpLastDirection()
    self:updateAttack(dt)
    self.super.update(self, dt)
end

function Player:move(dt)
    -- Calculate the current acceleration.
    local left = love.keyboard.isDown("a", "left") and not self.dead
    local right = love.keyboard.isDown("d", "right") and not self.dead
    -- Overwrite currently held controls if wall jump handicap is active.
    if self.wallJumpDirectionHandicapTime then
        left = self.lastWallJumpDirection == "right"
        right = self.lastWallJumpDirection == "left"
    end
    if self.knockTime then
        self.accX = 0
    elseif left and not right then
        self.accX = -self.MAX_ACC
        self.direction = "left"
    elseif right and not left then
        self.accX = self.MAX_ACC
        self.direction = "right"
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
        -- We need to reset ground here, because otherwise it would be reset in the next frame, causing the `jumpPrep` state to repeat.
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

function Player:updateWallJumpDirectionHandicapTime(dt)
    if self.wallJumpDirectionHandicapTime then
        self.wallJumpDirectionHandicapTime = math.max(self.wallJumpDirectionHandicapTime - dt, 0)
        if self.wallJumpDirectionHandicapTime == 0 then
            self.wallJumpDirectionHandicapTime = nil
        end
    end
end

function Player:updateWallJumpLastDirection()
    if self.ground then
        self.lastWallJumpDirection = nil
    end
end

function Player:updateAttack(dt)
    if not self.attackTime then
        return
    end
    self.attackTime = math.max(self.attackTime - dt, 0)
    if self.attackTime == 0 then
        self.attackTime = nil
        local dropKick = self.state == self.STATES.dropKick
        local attackHitbox
        if dropKick then
            attackHitbox = "attackDrop"
        else
            attackHitbox = self.direction == "left" and "attackLeft" or "attackRight"
        end
        local enemyFound = false
        -- Hurt at most one enemy.
        for i, enemy in ipairs(_GAME.level.entities) do
            if self:collidesWith(enemy, attackHitbox, "main") then
                enemy:hurt(self.direction, dropKick and 2 or 1)
                enemyFound = true
                break
            end
        end
        if enemyFound and dropKick then
            self.speedY = self.DROP_ATTACK_SPEED
        end
    end
end

function Player:jump()
    if self.dead or self.knockTime or self.jumpDelay then
        return
    end
    if self.ground or self.jumpGraceTime > 0 then
        self.jumpDelay = self.JUMP_DELAY_MAX
        self.jumpGraceTime = 0
    elseif self.sliding and self.direction ~= self.lastWallJumpDirection then
        if self.direction == "left" then
            self.speedX = self.WALL_JUMP_SPEED_X
        elseif self.direction == "right" then
            self.speedX = -self.WALL_JUMP_SPEED_X
        end
        self.speedY = self.WALL_JUMP_SPEED_Y
        self.lastWallJumpDirection = self.direction
        self.wallJumpDirectionHandicapTime = self.WALL_JUMP_DIRECTION_HANDICAP_TIME_MAX
    end
end

function Player:attack()
    if self.dead or self.knockTime or self.attackTime then
        return
    end
    if self.state == self.STATES.idle or self.state == self.STATES.run or self.state == self.STATES.punchLeft or self.state == self.STATES.punchRight then
        self.attackTime = self.ATTACK_DELAY
        self.nextPunchRight = not self.nextPunchRight
    elseif self.state == self.STATES.fall then
        self.attackTime = self.ATTACK_DELAY
    end
end

function Player:canBeAttacked()
    -- The player cannot be attacked if they are invulnerable.
    if self.invulTime or self.dead then
        return false
    end
    -- The player cannot be attacked if they are performing a drop kick.
    if self.attackTime or self.state == self.STATES.dropKick then
        return false
    end
    return true
end

function Player:updateState()
    local moving = self.speedX ~= 0 and (self.accX ~= 0 or math.abs(self.speedX) > 300)
    local jumping = (not self.ground and self.speedY < 0) or self.jumpDelay ~= nil
    local falling = not self.ground and self.speedY > 0
    local landing = self.ground ~= nil and not self.jumpDelay
    local sliding = self.sliding
    local attacking = self.attackTime ~= nil
    local attackRight = self.nextPunchRight
    local dead = self.dead
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
        self:setState("slideStart", sliding)
    elseif self.state == self.STATES.fall then
        self:setState("land", landing)
        self:setState("dropKick", attacking)
        self:setState("slideStart", sliding)
    elseif self.state == self.STATES.land then
        self:setState("run", moving)
    elseif self.state == self.STATES.slideStart then
        self:setState("idle", landing)
        self:setState("fall", not sliding)
    elseif self.state == self.STATES.slide then
        self:setState("idle", landing)
        self:setState("fall", not sliding)
    elseif self.state == self.STATES.punchLeft then
        self:setState("punchRight", attacking and attackRight)
    elseif self.state == self.STATES.punchRight then
        self:setState("punchLeft", attacking and not attackRight)
    elseif self.state == self.STATES.dropKick then
        self:setState("land", landing)
    end
    if self.state ~= self.STATES.dead then
        self:setState("defeat", dead)
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