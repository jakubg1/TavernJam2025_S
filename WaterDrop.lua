local Class = require("com.class")

---@class WaterDrop : Class
---@overload fun(): WaterDrop
local WaterDrop = Class:derive("WaterDrop")

---Constructs the WaterDrop.
function WaterDrop:new()
    -- Parameters
    self.SCALE = 0.25
    self.MAX_SPEED = 100
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 2500

    -- State
    self.x, self.y = 1000, 600
    self.width, self.height = 64, 80
    self.speedX, self.speedY = 0, 0
    self.accX, self.accY = 0, 0
    self.direction = "right"
    self.ground = nil

    -- Physics
    self.physics = {}
    self.physics.body = love.physics.newBody(_WORLD, self.x, self.y, "dynamic")
    self.physics.body:setFixedRotation(true)
    self.physics.shape = love.physics.newRectangleShape(self.width, self.height)
    self.physics.fixture = love.physics.newFixture(self.physics.body, self.physics.shape)

    -- Appearance
    ---@type table<string, SpriteState>
    self.STATES = {
        idle = {state = "idle", start = 1, frames = 4, framerate = 10},
        rise = {state = "rise", start = 1, frames = 5, framerate = 10, onFinish = "move"},
        move = {state = "move", start = 1, frames = 4, framerate = 10},
        defeat = {state = "defeat", start = 1, frames = 5, framerate = 10, delOnFinish = true}
    }
    self.sprites = _WATER_DROP_SPRITES
    self.state = self.STATES.idle
    self.stateFrame = 1
    self.stateTime = 0
end

---Updates the WaterDrop.
---@param dt number Time delta in seconds
function WaterDrop:update(dt)
    self:updatePhysics()
    self:move(dt)
    self:updateDirection()
    self:updateGravity(dt)
    self:updateSprite(dt)
end

function WaterDrop:updatePhysics()
    self.x, self.y = self.physics.body:getPosition()
    self.physics.body:setLinearVelocity(self.speedX, self.speedY)
end

function WaterDrop:move(dt)
    -- Calculate the current acceleration.
    local proximity = self:getProximityToPlayer()
    local left = proximity > 40 and self.state == self.STATES.move and self.x > _LEVEL.player.x
    local right = proximity > 40 and self.state == self.STATES.move and self.x < _LEVEL.player.x
    if left and not right then
        self.accX = -self.MAX_ACC
    elseif right and not left then
        self.accX = self.MAX_ACC
    else
        self.accX = 0
        self:applyDrag(dt)
    end
    -- Apply the acceleration and cap the speed.
    self.speedX = math.min(math.max(self.speedX + self.accX * dt, -self.MAX_SPEED), self.MAX_SPEED)
end

function WaterDrop:applyDrag(dt)
    if self.speedX > 0 then
        self.speedX = math.max(self.speedX - self.DRAG * dt, 0)
    else
        self.speedX = math.min(self.speedX + self.DRAG * dt, 0)
    end
end

function WaterDrop:updateDirection()
    if self.accX > 0 then
        self.direction = "right"
    elseif self.accX < 0 then
        self.direction = "left"
    end
end

function WaterDrop:updateGravity(dt)
    if self.ground then
        return
    end
    self.speedY = self.speedY + self.GRAVITY * dt
end

function WaterDrop:landOn(ground)
    self.ground = ground
    self.speedY = 0
end

function WaterDrop:updateSprite(dt)
    local playerClose = self:getProximityToPlayer() < 200
    if self.state == self.STATES.idle then
        self:setState("rise", playerClose)
    elseif self.state == self.STATES.rise then
    elseif self.state == self.STATES.move then
        self:setState("defeat", math.random() < 0.01)
    elseif self.state == self.STATES.defeat then
    end

    -- Update the animation frame.
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
                self.delQueue = true
            end
        end
    end
end

---Sets a new state for this WaterDrop, unless we already have that state.
---@param state string The new state.
---@param condition boolean? Optional condition. Must be satisfied to perform the change. Useful for compact code when you need to cram a lot of calls to this function in a row.
function WaterDrop:setState(state, condition)
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

function WaterDrop:getProximityToPlayer()
    return math.abs(self.x - _LEVEL.player.x)
end

---Executed when key is pressed.
---@param key string The keycode.
function WaterDrop:keypressed(key)

end

---Executed when key is released.
---@param key string The keycode.
function WaterDrop:keyreleased(key)

end

function WaterDrop:beginContact(a, b, collision)
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

function WaterDrop:endContact(a, b, collision)
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

---Draws the WaterDrop on the screen.
function WaterDrop:draw()
    love.graphics.setColor(1, 1, 1)
    local img = self.sprites:getImage(self.state.state, self.stateFrame)
    local horizontalScale = self.direction == "right" and self.SCALE or -self.SCALE
    love.graphics.draw(img, self.x, self.y - 70, 0, horizontalScale, self.SCALE, self.sprites.imageWidth / 2, self.sprites.imageHeight / 2)

    love.graphics.rectangle("line", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height)
end

return WaterDrop