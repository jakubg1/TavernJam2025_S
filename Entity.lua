local Class = require("com.class")

---@class Entity : Class
---@overload fun(x, y): Entity
local Entity = Class:derive("Entity")

---Constructs a new Entity.
---@param x number
---@param y number
function Entity:new(x, y)
    -- State
    self.x, self.y = x, y
    self.homeX, self.homeY = x, y
    self.speedX, self.speedY = 0, 0
    self.accX, self.accY = 0, 0
    self.direction = "right"
    self.ground = nil

    -- Appearance
    self.state = self.STARTING_STATE
    self.stateFrame = 1
    self.stateTime = 0
    ---@alias SpriteState {state: string, start: integer, frames: integer, framerate: number, onFinish: string?, delOnFinish: boolean?, reverse: boolean?}
    self.flashTime = 0
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
    if self.ground then
        return
    end
    self.speedY = self.speedY + self.GRAVITY * dt
end

---Updates the entity state to match its physics body, and updates the physics body's speed to match the entity state.
function Entity:updatePhysics()
    self.x, self.y = self.physics.body:getPosition()
    self.physics.body:setLinearVelocity(self.speedX, self.speedY)
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

---Destroys this Entity, its physics body and makes it ready to be removed.
function Entity:destroy()
    if self.delQueue then
        return
    end
    self.delQueue = true
    self.physics.body:destroy()
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

---Draws the Entity on the screen.
function Entity:draw()
    self:drawSprite()
    self:drawHitbox()
end

function Entity:drawSprite()
    love.graphics.setColor(1, 1, 1)
    local frame = self.state.reverse and self.state.frames - self.stateFrame + 1 or self.stateFrame
    local img = self.SPRITES:getImage(self.state.state, frame)
    local x = self.x + self.OFFSET_X
    local y = self.y + self.OFFSET_Y
    local scaleX = (self.direction == "right" or self.state.noFlip) and self.SCALE or -self.SCALE
    local scaleY = self.SCALE
    local width = self.SPRITES.imageWidth / 2
    local height = self.SPRITES.imageHeight / 2
    if self.flashTime > 0 then
        love.graphics.setShader(_WHITE_SHADER)
    end
    love.graphics.draw(img, x, y, 0, scaleX, scaleY, width, height)
    if self.flashTime > 0 then
        love.graphics.setShader()
    end
end

function Entity:drawHitbox()
    love.graphics.rectangle("line", self.x - self.WIDTH / 2, self.y - self.HEIGHT / 2, self.WIDTH, self.HEIGHT)
end

return Entity