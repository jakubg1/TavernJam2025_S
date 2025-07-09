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
    self.ATTACK_PROXIMITY = self.ATTACK_RANGE + 100 -- The amount of pixels in front of which she will attack
    self.ATTACK_COOLDOWN_MIN = 3
    self.ATTACK_COOLDOWN_MAX = 5
    ---@type table<string, PhysicsShape>
    self.PHYSICS_SHAPES = {
        main = {collidable = true},
        attackLeft = {offsetX = -self.ATTACK_RANGE / 2 - self.WIDTH / 2, width = self.ATTACK_RANGE},
        attackRight = {offsetX = self.ATTACK_RANGE / 2 + self.WIDTH / 2, width = self.ATTACK_RANGE}
    }

    -- Prepend default fields
    self.super.new(self, x, y)

    -- State
    self.attackCooldown = nil
end

---Updates the WaterGirl.
---@param dt number Time delta in seconds
function WaterGirl:update(dt)
    self:updateAttack()
    self:updateAttackCooldown(dt)
    self.super.update(self, dt)
end

function WaterGirl:updateAttack()
    local player = _LEVEL.player
    if self.state == self.STATES.attack and self.stateFrame >= 5 and self.stateFrame <= 9 then
        local shapes = self.physics.shapes
        local playerFixture = player.physics.shapes.main.fixture
        local leftCollision = shapes.main.collidingWith[playerFixture] or shapes.attackLeft.collidingWith[playerFixture]
        local rightCollision = shapes.main.collidingWith[playerFixture] or shapes.attackRight.collidingWith[playerFixture]
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
    local playerClose = self:getProximityToPlayer() < self.ATTACK_PROXIMITY
    local canAttack = not self.attackCooldown
    if self.state == self.STATES.idle then
        self:setState("attack", playerClose and canAttack)
    elseif self.state == self.STATES.attack then
    elseif self.state == self.STATES.defeat then
    end
end

return WaterGirl