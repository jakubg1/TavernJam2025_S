local Entity = require("Entity")

---@class CloudGirl : Entity
---@overload fun(x, y): CloudGirl
local CloudGirl = Entity:derive("CloudGirl")

---Constructs the FishBoy.
function CloudGirl:new(x, y)
    -- Parameters
    self.WIDTH, self.HEIGHT = 128, 80
    self.SCALE = 0.25
    self.OFFSET_X, self.OFFSET_Y = 0, 0
    self.FLIP_AXIS_OFFSET = -50
    self.MAX_SPEED = 700
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 0
    ---@type table<string, SpriteState>
    self.STATES = {
        idle = {state = "idle", start = 1, frames = 9, framerate = 20}
    }
    self.STARTING_STATE = self.STATES.idle
    self.SPRITES = _SPRITES.cloudGirl

    -- Water Drop exclusive parameters
    self.PLAYER_DETECTION_RANGE = 800

    -- Physics
    ---@type table<string, AttackArea>
    self.ATTACK_AREAS = {}

    -- Prepend default fields
    self.super.new(self, x, y)

    -- State
end

---Updates the CloudGirl.
---@param dt number Time delta in seconds
function CloudGirl:update(dt)
    self:move(dt)
    --self:updateAttack()
    self.super.update(self, dt)
end

function CloudGirl:move(dt)
    -- Calculate the current acceleration.
    local left, right
    if left and not right then
        self.accX = -self.MAX_ACC
    elseif right and not left then
        self.accX = self.MAX_ACC
    else
        self.accX = 0
        self:applyDrag(dt)
    end
end

function CloudGirl:updateAttack()
    local player = _LEVEL.player
    if self.state == self.STATES.fly then
        if self:collidesWith(player, "main", "main") then
            player:hurt(self.direction)
        end
    end
end

function CloudGirl:updateDirection()
    if self.state ~= self.STATES.fly then
        self.direction = self.x - _LEVEL.player.x > 0 and "left" or "right"
    end
end

function CloudGirl:updateState()
    if self.state == self.STATES.idle then
    elseif self.state == self.STATES.attack then
    end
end

return CloudGirl