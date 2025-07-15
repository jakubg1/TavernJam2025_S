local Entity = require("Entity")

---@class NPC : Entity
---@overload fun(x, y, name): NPC
local NPC = Entity:derive("NPC")

---Constructs the NPC.
function NPC:new(x, y, name)
    -- Parameters
    self.WIDTH, self.HEIGHT = 80, 160
    self.SCALE = 0.35
    self.IS_ENEMY = false
    self.MAX_SPEED = 0
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 2500
    self.SPRITES = _SPRITES["npc" .. name]
    if self.SPRITES.states.idleleft then
        self.OFFSET_X, self.OFFSET_Y = 0, -25
        self.FLIP_AXIS_OFFSET = 0
        ---@type table<string, SpriteState>
        self.STATES = {
            idle = {state = "idleright", flipState = "idleleft", start = 1, frames = 5, framerate = 10}
        }
    else
        self.OFFSET_X, self.OFFSET_Y = 0, -75
        self.FLIP_AXIS_OFFSET = -60
        ---@type table<string, SpriteState>
        self.STATES = {
            idle = {state = "idle", start = 1, frames = 5, framerate = 10}
        }
    end
    self.STARTING_STATE = self.STATES.idle

    -- NPC exclusive parameters
    self.PLAYER_DETECTION_RANGE = 800

    -- Physics
    ---@type table<string, AttackArea>
    self.ATTACK_AREAS = {}

    -- Prepend default fields
    self.super.new(self, x, y)

    -- State
end

---Updates the NPC.
---@param dt number Time delta in seconds
function NPC:update(dt)
    self:move(dt)
    self.super.update(self, dt)
end

function NPC:move(dt)
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

function NPC:updateDirection()
    if self.state ~= self.STATES.fly then
        self.direction = self.x - _GAME.level.player.x > 0 and "left" or "right"
    end
end

function NPC:updateState()
    if self.state == self.STATES.idle then
    elseif self.state == self.STATES.attack then
    end
end

return NPC