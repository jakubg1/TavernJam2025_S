local Class = require("com.class")

---@class Entity : Class
---@overload fun(x, y): Entity
local Entity = Class:derive("Entity")

local EntityAttackArea = require("EntityAttackArea")

---Constructs a new Entity.
---@param x number
---@param y number
function Entity:new(x, y)
    -- Default parameters
    --self.FLIP_AXIS_OFFSET = 0

    -- State
    self.x, self.y = x, y
    self.homeX, self.homeY = x, y
    self.speedX, self.speedY = 0, 0
    self.accX, self.accY = 0, 0
    self.direction = "right"
    self.ground = nil
    self.health = self.MAX_HEALTH
    self.dead = false
    self.knockTime = nil -- Makes the player ignore max speed and removes player control.
    self.invulTime = nil

    -- Physics
    _WORLD:add(self, self.x, self.y, self.WIDTH, self.HEIGHT)
    ---@alias AttackArea {offsetX: number?, offsetY: number?, width: number?, height: number?}
    ---@type table<string, EntityAttackArea>
    self.attackAreas = {}
    for name, area in pairs(self.ATTACK_AREAS) do
        self.attackAreas[name] = EntityAttackArea(self, area.offsetX or 0, area.offsetY or 0, area.width or self.WIDTH, area.height or self.HEIGHT)
    end

    -- Appearance
    ---@alias SpriteState {state: string, start: integer, frames: integer, framerate: number, onFinish: string?, delOnFinish: boolean?, reverse: boolean?}
    self.state = self.STARTING_STATE
    self.stateFrame = 1
    self.stateTime = 0
    self.flashTime = 0
end

---Updates the Entity. You must call `self.super.update(self, dt)` if you implement this function!
---@param dt number Time delta in seconds.
function Entity:update(dt)
    self:updateMovement(dt)
    self:updateDirection()
    self:updateGravity(dt)
    self:updatePhysics(dt)
    self:updateKnock(dt)
    self:updateInvulnerability(dt)
    self:updateState()
    self:updateAnimation(dt)
    self:updateFlash(dt)
end

-- Applies the acceleration and caps the speed.
---@param dt number Time delta in seconds.
function Entity:updateMovement(dt)
    self.speedX = self.speedX + self.accX * dt
    if not self.knockTime then
        self.speedX = math.min(math.max(self.speedX, -self.MAX_SPEED), self.MAX_SPEED)
    end
end

---Slows the entity down on horizontal axis based on the `self.DRAG` parameter.
---@param dt number Time delta in seconds.
function Entity:applyDrag(dt)
    if self.speedX > 0 then
        self.speedX = math.max(self.speedX - self.DRAG * dt, 0)
    else
        self.speedX = math.min(self.speedX + self.DRAG * dt, 0)
    end
end

---Sets the direction to `"right"` or `"left"`, depending on the entity speed.
function Entity:updateDirection()
    if self.accX > 0 then
        self.direction = "right"
    elseif self.accX < 0 then
        self.direction = "left"
    end
end

---Increases vertical speed if the entity is not on ground.
---@param dt number Time delta in seconds.
function Entity:updateGravity(dt)
    self.speedY = self.speedY + self.GRAVITY * dt
end

---Updates the entity state to match its physics body, and updates the physics body's speed to match the entity state.
---@param dt number Time delta in seconds.
function Entity:updatePhysics(dt)
    local goalX, goalY = self.x + self.speedX * dt, self.y + self.speedY * dt
    local filter = function(item, other)
        local collide = other.isGround and (not other.topOnly or item.ground == other)
        return collide and "slide" or "cross"
    end
    local x, y, cols, len = _WORLD:move(self, goalX, goalY, filter)
    local previousGround = self.ground
    self.ground = nil
    -- I am keeping the debug prints for now, because there still exists a weird glitch where the player
    -- is pushed out of a top-only platform if they land while moving left/right.
    --print(".")
    for i, col in ipairs(cols) do
        local other = col.other
        if other.isGround then
            --print(col.normal.x, col.normal.y, col.overlaps, previousGround)
        end
        if other.isGround and (not other.topOnly or col.normal.y < -1e-9 and (not col.overlaps or previousGround)) then
            self:landOn(other)
            --print("- Landed!")
        end
    end
    self.x, self.y = x, y
    for name, area in pairs(self.attackAreas) do
        area:updatePhysics()
    end
end

---Updates the knockout timer. While knocked and in air, the player cannot control the entity.
---@param dt number Time delta in seconds.
function Entity:updateKnock(dt)
    if not self.knockTime then
        return
    end
    self.knockTime = math.max(self.knockTime - dt, 0)
    if self.knockTime == 0 or self.ground then
        self.knockTime = nil
    end
end

---Updates the invulnerability timer. While invulnerable, the entity cannot be hurt.
---@param dt number Time delta in seconds.
function Entity:updateInvulnerability(dt)
    if not self.invulTime then
        return
    end
    self.invulTime = math.max(self.invulTime - dt, 0)
    if self.invulTime == 0 then
        self.invulTime = nil
    end
end

---Performs a simple state machine update and changes the state if certain conditions are met.
function Entity:updateState()
    -- Filled out by subclasses
end

---Updates the animation frame based on the current state.
---@param dt number Time delta in seconds.
function Entity:updateAnimation(dt)
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
            if self.state.delOnFinish then
                self:destroy()
            end
        end
    end
end

---Sets a new state for this entity, unless it already has that state.
---@param state string The new state.
---@param condition boolean? Optional condition. Must be satisfied to perform the change. Useful for compact code when you need to cram a lot of calls to this function in a row.
function Entity:setState(state, condition)
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

---Lands this Entity on the provided ground.
---@param ground love.Fixture The ground physics fixture.
function Entity:landOn(ground)
    self.ground = ground
    self.speedY = 0
end

---Updates the flash timer.
---@param dt number Time delta in seconds.
function Entity:updateFlash(dt)
    self.flashTime = math.max(self.flashTime - dt, 0)
end

---Flashes this Entity white.
---@param t number? Duration of flash.
function Entity:flash(t)
    self.flashTime = t or 0.1
end

---Knocks the entity in the specified vector and marks is as knocked.
---@param speedX number X speed in pixels per second.
---@param speedY number Y speed in pixels per second.
function Entity:knock(speedX, speedY)
    self.speedX = speedX
    self.speedY = speedY
    self.knockTime = self.KNOCK_TIME_MAX
    -- We need to reset ground here, because otherwise it would be reset in the next frame, causing the `knockTime` state to immediately reset.
    self.ground = nil
end

---Hurts the entity in the specified direction if not invulnerable.
---@param direction "left"|"right" The attack direction.
---@param damage integer? How many health points should be taken. `1` by default.
function Entity:hurt(direction, damage)
    damage = damage or 1
    if not self:canBeAttacked() or not self.health then
        return
    end
    self:knock(direction == "left" and -self.KNOCK_X or self.KNOCK_X, -self.KNOCK_Y)
    self:flash()
    self.health = math.max(self.health - damage, 0)
    if self.health == 0 then
        self.dead = true
    end
    self.invulTime = self.INVUL_TIME_MAX
end

---Returns `true` if the entity cannot be hurt.
---@return boolean
function Entity:canBeAttacked()
    -- The player cannot be attacked if they are invulnerable or have no health.
    if self.invulTime then
        return false
    end
    return true
end

---Destroys this Entity, its physics body and makes it ready to be removed.
function Entity:destroy()
    if self.delQueue then
        return
    end
    self.delQueue = true
    _WORLD:remove(self)
end

---Returns the horizontal distance to the player.
---@return number
function Entity:getProximityToPlayer()
    return math.abs(self.x - _LEVEL.player.x)
end

---Executed when key is pressed.
---@param key string The keycode.
function Entity:keypressed(key)
    -- Filled out by subclasses
end

---Executed when key is released.
---@param key string The keycode.
function Entity:keyreleased(key)
    -- Filled out by subclasses
end

---Checks if this entity's specified shape is colliding with the provided entity's body or attack area.
---@param other Entity The other entity to check whether we're colliding with.
---@param attackArea string? This entity's attack area to be checked. If not specified, main body collision will be checked.
---@param otherAttackArea string? The other entity's attack area to be checked. If not specified, main body collision will be checked.
---@return boolean
function Entity:collidesWith(other, attackArea, otherAttackArea)
    local a = attackArea and self.attackAreas[attackArea] or self
    local b = otherAttackArea and other.attackAreas[otherAttackArea] or other
    local x1, y1, w1, h1 = _WORLD:getRect(a)
    local x2, y2, w2, h2 = _WORLD:getRect(b)
    return _Utils.doBoxesIntersect(x1, y1, w1, h1, x2, y2, w2, h2)
end

---Draws the Entity on the screen.
function Entity:draw()
    self:drawSprite()
    self:drawHitbox()
end

function Entity:drawSprite()
    local frame = self.state.reverse and self.state.frames - self.stateFrame + 1 or self.stateFrame
    local img = self.SPRITES:getImage(self.state.state, frame)
    local flipped = self.direction == "left" and not self.state.noFlip
    local x = self.x + self.WIDTH / 2 + self.OFFSET_X + (flipped and self.FLIP_AXIS_OFFSET or -self.FLIP_AXIS_OFFSET)
    local y = self.y + self.HEIGHT / 2 + self.OFFSET_Y
    local scaleX = flipped and -self.SCALE or self.SCALE
    local scaleY = self.SCALE
    local width = self.SPRITES.imageWidth / 2
    local height = self.SPRITES.imageHeight / 2
    love.graphics.setColor(1, 1, 1)
    if self.invulTime then
        --love.graphics.setColor(1, 1, 1, 0.8)
    end
    if self.flashTime > 0 then
        love.graphics.setShader(_WHITE_SHADER)
    end
    love.graphics.draw(img, x, y, 0, scaleX, scaleY, width, height)
    if self.flashTime > 0 then
        love.graphics.setShader()
    end
end

function Entity:drawHitbox()
    if not _HITBOXES then
        return
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", self.x, self.y, self.WIDTH, self.HEIGHT)
    if self.invulTime then
        local t = self.invulTime / self.INVUL_TIME_MAX
        love.graphics.rectangle("fill", self.x, self.y - self.HEIGHT * (t - 1), self.WIDTH, self.HEIGHT * t)
    end
    for name, area in pairs(self.attackAreas) do
        area:drawHitbox()
    end
    love.graphics.setColor(1, 0.5, 0)
    local x, y, w, h = _WORLD:getRect(self)
    love.graphics.rectangle("line", x, y, w, h)
end

return Entity